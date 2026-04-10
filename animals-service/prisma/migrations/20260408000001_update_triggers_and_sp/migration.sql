-- =====================================================
-- CAMBIO 1: Trigger fn_validar_movimiento
-- =====================================================
CREATE OR REPLACE FUNCTION fn_validar_movimiento()
RETURNS TRIGGER AS $$
DECLARE
    v_estado_actual   TEXT;
    v_ultimo_tipo     TEXT;
    v_nombre_animal   TEXT;
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

    -- Solo defuncion es terminal absoluto
    IF v_estado_actual = 'defuncion' THEN
        RAISE EXCEPTION
            'El animal "%" falleció (defuncion). '
            'No se pueden registrar más movimientos sobre este expediente.',
            v_nombre_animal;
    END IF;

    -- adoptado y extraviado solo aceptan una entrada con motivo retorno
    IF v_estado_actual IN ('adoptado', 'extraviado') AND NOT (
        NEW.tipo_movimiento = 'entrada' AND NEW.motivo = 'retorno'
    ) THEN
        RAISE EXCEPTION
            'El animal "%" tiene estado %. '
            'Solo se puede registrar una entrada con motivo "retorno".',
            v_nombre_animal, v_estado_actual;
    END IF;

    SELECT tipo_movimiento::TEXT
    INTO v_ultimo_tipo
    FROM movimientos
    WHERE animal_id = NEW.animal_id
    ORDER BY fecha_movimiento DESC
    LIMIT 1;

    IF v_ultimo_tipo = 'entrada' AND NEW.tipo_movimiento = 'entrada' THEN
        RAISE EXCEPTION
            'El animal "%" ya tiene una entrada activa registrada. '
            'Debe registrar su salida antes de registrar un nuevo ingreso.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo = 'salida' AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene una entrada activa. '
            'No se puede registrar una salida sin una entrada previa.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo IS NULL AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene ningún movimiento previo. '
            'El primer movimiento de un animal siempre debe ser una entrada.',
            v_nombre_animal;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_movimiento ON movimientos;
CREATE TRIGGER trg_validar_movimiento
BEFORE INSERT ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_validar_movimiento();

-- =====================================================
-- CAMBIO 2: Trigger fn_sincronizar_estado_animal
-- =====================================================
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
            'Estado del animal % actualizado automáticamente a "%" '
            'por movimiento de salida (motivo: %).',
            NEW.animal_id, v_nuevo_estado, NEW.motivo;
    END IF;

    -- Entradas: UPDATE incondicional (se quitó el WHERE estado NOT IN)
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

-- =====================================================
-- CAMBIO 3: Nuevo trigger BEFORE DELETE para reversión
-- =====================================================
CREATE OR REPLACE FUNCTION fn_reversar_estado_en_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_estado_actual TEXT;
BEGIN
    -- Solo actuar si se borra una salida por adopcion o extravio
    IF OLD.tipo_movimiento = 'salida' AND OLD.motivo IN ('adopcion', 'extravio') THEN

        SELECT estado::TEXT INTO v_estado_actual
        FROM animales WHERE id_animal = OLD.animal_id;

        -- Solo revertir si el estado coincide con lo que esa salida habría puesto
        IF (OLD.motivo = 'adopcion' AND v_estado_actual = 'adoptado') OR
           (OLD.motivo = 'extravio' AND v_estado_actual = 'extraviado') THEN

            UPDATE animales
            SET estado = 'adopcion'::"EstadoAnimal", "updatedAt" = NOW()
            WHERE id_animal = OLD.animal_id;

        END IF;
    END IF;

    -- defuncion: nunca se revierte
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reversar_estado_delete ON movimientos;
CREATE TRIGGER trg_reversar_estado_delete
BEFORE DELETE ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_reversar_estado_en_delete();

-- =====================================================
-- CAMBIO 4: sp_registrar_animal_completo (agregar usuario_id)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_registrar_animal_completo;

CREATE PROCEDURE sp_registrar_animal_completo(
    p_nombre                 VARCHAR(100),
    p_especie                VARCHAR(100),
    p_raza                   VARCHAR(100),
    p_edad                   INTEGER,
    p_peso                   DECIMAL(10,2),
    p_sexo                   TEXT,
    p_tamano                 TEXT,
    p_enfermedad_no_tratable BOOLEAN,
    p_discapacidad           BOOLEAN,
    p_es_agresivo            BOOLEAN,
    p_lugar                  TEXT,
    p_descripcion            TEXT,
    p_refugio_id             UUID,
    p_usuario_id             UUID,
    INOUT p_id_animal_creado UUID DEFAULT NULL,
    p_url_imagen             TEXT DEFAULT NULL,
    p_fecha_rescate          TIMESTAMP DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad_max    INT;
    v_ocupacion_actual INT;
BEGIN
    SELECT capacidad_max INTO v_capacidad_max
    FROM refugios WHERE id_refugio = p_refugio_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El refugio % no existe.', p_refugio_id;
    END IF;

    SELECT COUNT(*) INTO v_ocupacion_actual
    FROM animales
    WHERE refugio_id = p_refugio_id AND estado = 'adopcion';

    IF v_ocupacion_actual >= v_capacidad_max THEN
        RAISE EXCEPTION
            'El refugio ha alcanzado su capacidad maxima (% / %).',
            v_ocupacion_actual, v_capacidad_max;
    END IF;

    INSERT INTO animales (
        nombre, estado, especie, raza, edad, peso, sexo, tamano,
        enfermedad_no_tratable, discapacidad, es_agresivo,
        lugar, descripcion, usuario_id, refugio_id
    )
    VALUES (
        p_nombre, 'adopcion', p_especie, p_raza, p_edad, p_peso,
        p_sexo::"sexo_animal", p_tamano::"tamano_lista",
        p_enfermedad_no_tratable, p_discapacidad, p_es_agresivo,
        p_lugar, p_descripcion, p_usuario_id, p_refugio_id
    )
    RETURNING id_animal INTO p_id_animal_creado;

    IF p_url_imagen IS NOT NULL AND TRIM(p_url_imagen) <> '' THEN
        INSERT INTO animal_imagen (imagen, animal_id)
        VALUES (p_url_imagen, p_id_animal_creado);
    END IF;

    INSERT INTO movimientos (tipo_movimiento, fecha_movimiento, motivo, animal_id)
    VALUES ('entrada', p_fecha_rescate, 'rescate', p_id_animal_creado);
END;
$$;