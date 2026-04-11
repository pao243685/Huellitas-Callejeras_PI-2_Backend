--sincronización de artefactos aplicados directamente en la base de datos sin registrar migración.
-- Cambios:
--   1. fn_registrar_animal_completo  (renombrado antes era sp_registrar_animal_completo)
--   2. fn_validar_movimiento         (lógica de estados actualizada)
--   3. fn_sincronizar_estado_animal  (entrada incondicional)
--   4. fn_reversar_estado_en_delete  
--   5. fn_validar_etiqueta_mismo_refugio 
--   6. fn_validar_rol_mismo_refugio   
--   7. get_adoption_profile_global 



DROP FUNCTION IF EXISTS sp_registrar_animal_completo(
    VARCHAR(100), VARCHAR(100), VARCHAR(100), INTEGER, NUMERIC,
    TEXT, TEXT, BOOLEAN, BOOLEAN, BOOLEAN, TEXT, TEXT, UUID, UUID,
    TEXT, TEXT, TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_registrar_animal_completo(
    p_nombre                 VARCHAR(100),
    p_especie                VARCHAR(100),
    p_raza                   VARCHAR(100),
    p_edad                   INTEGER,
    p_peso                   NUMERIC,
    p_sexo                   TEXT,
    p_tamano                 TEXT,
    p_enfermedad_no_tratable BOOLEAN,
    p_discapacidad           BOOLEAN,
    p_es_agresivo            BOOLEAN,
    p_lugar                  TEXT,
    p_descripcion            TEXT,
    p_refugio_id             UUID,
    p_usuario_id             UUID,
    p_estado                 TEXT,
    p_url_imagen             TEXT    DEFAULT NULL,
    p_fecha_rescate          TIMESTAMP DEFAULT NOW()
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad_max    INT;
    v_ocupacion_actual INT;
    v_id_animal_creado UUID;
BEGIN
    IF p_estado NOT IN ('adopcion', 'recuperacion') THEN
        RAISE EXCEPTION 'Estado inválido: %. Use "adopcion" o "recuperacion"', p_estado;
    END IF;

    SELECT capacidad_max INTO v_capacidad_max
    FROM refugios WHERE id_refugio = p_refugio_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El refugio % no existe.', p_refugio_id;
    END IF;

    SELECT COUNT(*) INTO v_ocupacion_actual
    FROM animales
    WHERE refugio_id = p_refugio_id AND estado IN ('adopcion', 'recuperacion');

    IF v_ocupacion_actual >= v_capacidad_max THEN
        RAISE EXCEPTION 'Refugio lleno. Capacidad: %/%', v_ocupacion_actual, v_capacidad_max;
    END IF;

    INSERT INTO animales (
        nombre, estado, especie, raza, edad, peso, sexo, tamano,
        enfermedad_no_tratable, discapacidad, es_agresivo,
        lugar, descripcion, usuario_id, refugio_id
    )
    VALUES (
        p_nombre, p_estado::"EstadoAnimal", p_especie, p_raza, p_edad, p_peso,
        p_sexo::"sexo_animal", p_tamano::"tamano_lista",
        p_enfermedad_no_tratable, p_discapacidad, p_es_agresivo,
        p_lugar, p_descripcion, p_usuario_id, p_refugio_id
    )
    RETURNING id_animal INTO v_id_animal_creado;

    IF p_url_imagen IS NOT NULL AND TRIM(p_url_imagen) <> '' THEN
        INSERT INTO animal_imagen (imagen, animal_id)
        VALUES (p_url_imagen, v_id_animal_creado);
    END IF;

    INSERT INTO movimientos (tipo_movimiento, fecha_movimiento, motivo, animal_id)
    VALUES ('entrada', p_fecha_rescate, 'rescate', v_id_animal_creado);

    RETURN v_id_animal_creado;
END;
$$;



CREATE OR REPLACE FUNCTION fn_validar_movimiento()
RETURNS TRIGGER AS $$
DECLARE
    v_estado_actual TEXT;
    v_ultimo_tipo   TEXT;
    v_nombre_animal TEXT;
BEGIN
    SELECT nombre, estado::TEXT
    INTO v_nombre_animal, v_estado_actual
    FROM animales
    WHERE id_animal = NEW.animal_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No existe un animal con id %. No se puede registrar el movimiento.',
            NEW.animal_id;
    END IF;

    IF v_estado_actual = 'defuncion' THEN
        RAISE EXCEPTION
            'El animal "%" falleció (defuncion). No se pueden registrar más movimientos sobre este expediente.',
            v_nombre_animal;
    END IF;

    IF v_estado_actual IN ('adoptado', 'extraviado') AND NOT (
        NEW.tipo_movimiento = 'entrada' AND NEW.motivo = 'retorno'
    ) THEN
        RAISE EXCEPTION
            'El animal "%" tiene estado %. Solo se puede registrar una entrada con motivo "retorno".',
            v_nombre_animal, v_estado_actual;
    END IF;

    SELECT tipo_movimiento::TEXT
    INTO v_ultimo_tipo
    FROM movimientos
    WHERE animal_id = NEW.animal_id
    ORDER BY fecha_movimiento DESC
    LIMIT 1;

    IF NEW.tipo_movimiento = 'entrada' AND NEW.motivo = 'retorno'
       AND v_estado_actual IN ('adoptado', 'extraviado') THEN
        RETURN NEW;
    END IF;

    IF v_ultimo_tipo = 'entrada' AND NEW.tipo_movimiento = 'entrada' THEN
        RAISE EXCEPTION
            'El animal "%" ya tiene una entrada activa registrada. Debe registrar su salida antes de registrar un nuevo ingreso.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo = 'salida' AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene una entrada activa. No se puede registrar una salida sin una entrada previa.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo IS NULL AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene ningún movimiento previo. El primer movimiento de un animal siempre debe ser una entrada.',
            v_nombre_animal;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_movimiento ON movimientos;
CREATE TRIGGER trg_validar_movimiento
BEFORE INSERT ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_validar_movimiento();



CREATE OR REPLACE FUNCTION fn_sincronizar_estado_animal()
RETURNS TRIGGER AS $$
DECLARE
    v_nuevo_estado "EstadoAnimal";
BEGIN
    IF NEW.tipo_movimiento = 'salida' AND NEW.motivo IN ('adopcion', 'defuncion', 'extravio') THEN
        v_nuevo_estado := CASE NEW.motivo
            WHEN 'adopcion'  THEN 'adoptado'::"EstadoAnimal"
            WHEN 'defuncion' THEN 'defuncion'::"EstadoAnimal"
            WHEN 'extravio'  THEN 'extraviado'::"EstadoAnimal"
        END;

        UPDATE animales
        SET
            estado      = v_nuevo_estado,
            "updatedAt" = NOW()
        WHERE id_animal = NEW.animal_id;

        RAISE NOTICE
            'Estado del animal % actualizado automáticamente a "%" por movimiento de salida (motivo: %).',
            NEW.animal_id, v_nuevo_estado, NEW.motivo;
    END IF;

    IF NEW.tipo_movimiento = 'entrada' AND NEW.motivo IN ('rescate', 'retorno') THEN
        UPDATE animales
        SET
            estado      = 'adopcion'::"EstadoAnimal",
            "updatedAt" = NOW()
        WHERE id_animal = NEW.animal_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sincronizar_estado_animal ON movimientos;
CREATE TRIGGER trg_sincronizar_estado_animal
AFTER INSERT ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_sincronizar_estado_animal();



CREATE OR REPLACE FUNCTION fn_reversar_estado_en_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_estado_actual TEXT;
BEGIN
    IF OLD.tipo_movimiento = 'salida' AND OLD.motivo IN ('adopcion', 'extravio') THEN

        SELECT estado::TEXT INTO v_estado_actual
        FROM animales WHERE id_animal = OLD.animal_id;

        IF (OLD.motivo = 'adopcion'  AND v_estado_actual = 'adoptado') OR
           (OLD.motivo = 'extravio'  AND v_estado_actual = 'extraviado') THEN

            UPDATE animales
            SET estado = 'adopcion'::"EstadoAnimal", "updatedAt" = NOW()
            WHERE id_animal = OLD.animal_id;

        END IF;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reversar_estado_delete ON movimientos;
CREATE TRIGGER trg_reversar_estado_delete
BEFORE DELETE ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_reversar_estado_en_delete();



CREATE OR REPLACE FUNCTION fn_validar_etiqueta_mismo_refugio()
RETURNS TRIGGER AS $$
DECLARE
    v_refugio_animal   UUID;
    v_refugio_etiqueta UUID;
BEGIN
    SELECT refugio_id INTO v_refugio_animal
    FROM animales WHERE id_animal = NEW.animal_id;

    SELECT refugio_id INTO v_refugio_etiqueta
    FROM etiquetas WHERE id_etiqueta = NEW.etiqueta_id;

    IF v_refugio_animal IS DISTINCT FROM v_refugio_etiqueta THEN
        RAISE EXCEPTION
            'La etiqueta no pertenece al mismo refugio que el animal. Solo se pueden asignar etiquetas del propio refugio.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_etiqueta_mismo_refugio ON etiqueta_animal;
CREATE TRIGGER trg_validar_etiqueta_mismo_refugio
BEFORE INSERT ON etiqueta_animal
FOR EACH ROW EXECUTE FUNCTION fn_validar_etiqueta_mismo_refugio();


-- 6. fn_validar_rol_mismo_refugio — sin trigger aún valida que el rol asignado al usuario pertenezca al mismo refugio que el usuario.

CREATE OR REPLACE FUNCTION fn_validar_rol_mismo_refugio()
RETURNS TRIGGER AS $$
DECLARE
    v_refugio_rol UUID;
BEGIN
    SELECT refugio_id INTO v_refugio_rol
    FROM roles WHERE id_roles = NEW.rol_id;

    IF v_refugio_rol IS DISTINCT FROM NEW.refugio_id THEN
        RAISE EXCEPTION
            'El rol asignado pertenece a un refugio diferente al del usuario. El rol y el usuario deben pertenecer al mismo refugio.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_rol_mismo_refugio ON usuarios;
CREATE TRIGGER trg_validar_rol_mismo_refugio
BEFORE INSERT OR UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION fn_validar_rol_mismo_refugio();


-- -------------------------------------------------------------
-- 7. get_adoption_profile_global — nueva función global
--    Igual que get_adoption_profile pero sin filtrar por refugio,
--    analiza el historial de adopciones de toda la plataforma.
-- -------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_adoption_profile_global()
RETURNS TABLE (datos TEXT, historico TEXT, actual TEXT, resultado TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad_total        INT;
    v_min_historial          INT;
    v_total_adoptados        INT;

    v_edad_promedio          NUMERIC;
    v_activos_cachorros      INT;
    v_activos_adultos        INT;
    v_adoptados_cachorros    INT;
    v_adoptados_adultos      INT;

    v_sexo_moda              TEXT;
    v_activos_machos         INT;
    v_activos_hembras        INT;
    v_adoptados_machos       INT;
    v_adoptados_hembras      INT;

    v_tamano_moda            TEXT;
    v_activos_pref_tam       INT;
    v_activos_grande_tam     INT;
    v_adoptados_pref_tam     INT;
    v_adoptados_grande_tam   INT;

    v_activos_discap         INT;
    v_adoptados_discap       INT;
    v_adoptados_sin_discap   INT;

    v_activos_agresivo       INT;
    v_adoptados_agresivo     INT;
    v_adoptados_sin_agresivo INT;

    v_activos_enferm         INT;
    v_adoptados_enferm       INT;
    v_adoptados_sin_enferm   INT;

BEGIN
    SELECT COALESCE(SUM(capacidad_max), 0)
    INTO v_capacidad_total
    FROM refugios;

    v_min_historial := CEIL(v_capacidad_total * 1.5);

    SELECT COUNT(DISTINCT a.id_animal)
    INTO v_total_adoptados
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida';

    SELECT ROUND(AVG(a.edad), 1)
    INTO v_edad_promedio
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida';

    SELECT COUNT(*) INTO v_activos_cachorros
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion') AND edad < 12;

    SELECT COUNT(*) INTO v_activos_adultos
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion') AND edad >= 12;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_cachorros
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad < 12 AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_adultos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad >= 12 AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Edad'::TEXT,
            CONCAT(v_edad_promedio::TEXT, ' meses'),
            FORMAT('%s menores de 12 meses, %s de 12 meses o más', v_activos_cachorros, v_activos_adultos),
            CASE
                WHEN v_edad_promedio < 12  THEN 'Alto'
                WHEN v_edad_promedio <= 36 THEN 'Medio'
                ELSE                           'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Edad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: <12 meses)'),
            FORMAT('%s menores de 12 meses, %s de 12 meses o más', v_activos_cachorros, v_activos_adultos),
            CASE
                WHEN v_activos_cachorros > v_activos_adultos THEN 'Alto'
                WHEN v_activos_cachorros = v_activos_adultos THEN 'Medio'
                ELSE                                             'Bajo'
            END;
    END IF;

    SELECT a.sexo::TEXT INTO v_sexo_moda
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.estado = 'adoptado' AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida'
    GROUP BY a.sexo ORDER BY COUNT(*) DESC LIMIT 1;

    SELECT COUNT(*) INTO v_activos_machos
    FROM animales WHERE estado IN ('adopcion', 'recuperacion') AND sexo = 'Macho';

    SELECT COUNT(*) INTO v_activos_hembras
    FROM animales WHERE estado IN ('adopcion', 'recuperacion') AND sexo = 'Hembra';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_machos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.sexo = 'Macho' AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_hembras
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.sexo = 'Hembra' AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Sexo'::TEXT,
            COALESCE(v_sexo_moda, 'Sin datos'),
            FORMAT('%s machos, %s hembras', v_activos_machos, v_activos_hembras),
            CASE
                WHEN v_sexo_moda = 'Macho'  AND v_activos_machos  >= v_activos_hembras THEN 'Alto'
                WHEN v_sexo_moda = 'Hembra' AND v_activos_hembras >= v_activos_machos  THEN 'Alto'
                WHEN v_activos_machos = v_activos_hembras                              THEN 'Medio'
                ELSE                                                                        'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Sexo'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Macho)'),
            FORMAT('%s machos, %s hembras', v_activos_machos, v_activos_hembras),
            CASE
                WHEN v_activos_machos > v_activos_hembras THEN 'Alto'
                WHEN v_activos_machos = v_activos_hembras THEN 'Medio'
                ELSE                                          'Bajo'
            END;
    END IF;

    SELECT a.tamano::TEXT INTO v_tamano_moda
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.estado = 'adoptado' AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida'
    GROUP BY a.tamano ORDER BY COUNT(*) DESC LIMIT 1;

    SELECT COUNT(*) INTO v_activos_pref_tam
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND tamano IN ('miniatura','pequeño','mediano');

    SELECT COUNT(*) INTO v_activos_grande_tam
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND tamano IN ('grande','gigante');

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_pref_tam
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.tamano IN ('miniatura','pequeño','mediano') AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_grande_tam
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.tamano IN ('grande','gigante') AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Tamaño'::TEXT,
            COALESCE(v_tamano_moda, 'Sin datos'),
            FORMAT('%s miniatura/pequeño/mediano, %s grande/gigante', v_activos_pref_tam, v_activos_grande_tam),
            CASE
                WHEN v_tamano_moda IN ('miniatura','pequeño','mediano') AND v_activos_pref_tam >= v_activos_grande_tam THEN 'Alto'
                WHEN v_tamano_moda IN ('miniatura','pequeño','mediano') AND v_activos_pref_tam <  v_activos_grande_tam THEN 'Medio'
                WHEN v_tamano_moda IN ('grande','gigante') AND v_activos_grande_tam >= v_activos_pref_tam             THEN 'Alto'
                ELSE                                                                                                       'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Tamaño'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Mediano)'),
            FORMAT('%s miniatura/pequeño/mediano, %s grande/gigante', v_activos_pref_tam, v_activos_grande_tam),
            CASE
                WHEN v_activos_pref_tam > v_activos_grande_tam THEN 'Alto'
                WHEN v_activos_pref_tam = v_activos_grande_tam THEN 'Medio'
                ELSE                                                'Bajo'
            END;
    END IF;

    SELECT COUNT(*) INTO v_activos_discap
    FROM animales WHERE estado IN ('adopcion', 'recuperacion') AND discapacidad = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.discapacidad = TRUE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.discapacidad = FALSE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Discapacidad'::TEXT,
            CASE WHEN v_adoptados_sin_discap >= v_adoptados_discap THEN 'Sin discapacidad' ELSE 'Con discapacidad' END,
            FORMAT('%s con discapacidad activos', v_activos_discap),
            CASE
                WHEN v_activos_discap = 0                                                THEN 'Alto'
                WHEN (v_adoptados_discap::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2 THEN 'Bajo'
                ELSE                                                                          'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Discapacidad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Sin discapacidad)'),
            FORMAT('%s con discapacidad activos', v_activos_discap),
            CASE WHEN v_activos_discap = 0 THEN 'Alto' ELSE 'Bajo' END;
    END IF;

    SELECT COUNT(*) INTO v_activos_agresivo
    FROM animales WHERE estado IN ('adopcion', 'recuperacion') AND es_agresivo = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.es_agresivo = TRUE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.es_agresivo = FALSE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Agresividad'::TEXT,
            CASE WHEN v_adoptados_sin_agresivo >= v_adoptados_agresivo THEN 'No agresivo' ELSE 'Agresivo' END,
            FORMAT('%s agresivos activos', v_activos_agresivo),
            CASE
                WHEN v_activos_agresivo = 0                                                THEN 'Alto'
                WHEN (v_adoptados_agresivo::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2 THEN 'Bajo'
                ELSE                                                                            'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Agresividad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: No agresivo)'),
            FORMAT('%s agresivos activos', v_activos_agresivo),
            CASE WHEN v_activos_agresivo = 0 THEN 'Alto' ELSE 'Bajo' END;
    END IF;

    SELECT COUNT(*) INTO v_activos_enferm
    FROM animales WHERE estado IN ('adopcion', 'recuperacion') AND enfermedad_no_tratable = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.enfermedad_no_tratable = TRUE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.enfermedad_no_tratable = FALSE AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Enfermedades'::TEXT,
            CASE WHEN v_adoptados_sin_enferm >= v_adoptados_enferm THEN 'Sin enfermedad' ELSE 'Con enfermedad' END,
            FORMAT('%s con enfermedad no tratable activos', v_activos_enferm),
            CASE
                WHEN v_activos_enferm = 0                                                THEN 'Alto'
                WHEN (v_adoptados_enferm::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.1 THEN 'Bajo'
                ELSE                                                                          'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Enfermedades'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Sin enfermedad)'),
            FORMAT('%s con enfermedad no tratable activos', v_activos_enferm),
            CASE WHEN v_activos_enferm = 0 THEN 'Alto' ELSE 'Bajo' END;
    END IF;

END;
$$;