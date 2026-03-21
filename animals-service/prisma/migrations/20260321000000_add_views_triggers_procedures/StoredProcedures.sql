-- SP-1: sp_registrar_animal_completo
-- PROPOSITO
--   Registrar un animal nuevo de forma integral y consistente,
--   contemplando en una sola operacion su expediente, su imagen
--   inicial (si existe) y su primer movimiento de entrada.
--
-- JUSTIFICACION
--   Este procedimiento relaciona directamente tres tablas clave:
--   "animales", "animal_imagen" y "movimientos", ademas
--   de validar capacidad real en "refugios".
--
--   Su funcion principal es evitar registros incompletos: un animal
--   sin movimiento inicial o sin coherencia con la ocupacion real.
--   Frente al enfoque tradicional de ejecutar varias sentencias por
--   separado, este SP es mejor porque aplica todo como una sola
--   unidad: o se guarda todo correctamente o no se guarda nada.

CREATE OR REPLACE PROCEDURE sp_registrar_animal_completo(
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
    SELECT capacidad_max
    INTO v_capacidad_max
    FROM refugios
    WHERE id_refugio = p_refugio_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El refugio % no existe.', p_refugio_id;
    END IF;

    SELECT COUNT(*)
    INTO v_ocupacion_actual
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado = 'adopcion';

    IF v_ocupacion_actual >= v_capacidad_max THEN
        RAISE EXCEPTION
            'El refugio ha alcanzado su capacidad maxima (% / %). No se puede registrar un nuevo animal.',
            v_ocupacion_actual, v_capacidad_max;
    END IF;

    INSERT INTO animales (
        nombre, estado, especie, raza, edad, peso, sexo, tamano,
        enfermedad_no_tratable, discapacidad, es_agresivo,
        lugar, descripcion, refugio_id
    )
    VALUES (
        p_nombre, 'adopcion', p_especie, p_raza, p_edad, p_peso,
        p_sexo::"sexo_animal", p_tamano::"tamano_lista",
        p_enfermedad_no_tratable, p_discapacidad, p_es_agresivo,
        p_lugar, p_descripcion, p_refugio_id
    )
    RETURNING id_animal INTO p_id_animal_creado;

    IF p_url_imagen IS NOT NULL AND TRIM(p_url_imagen) <> '' THEN
        INSERT INTO animal_imagen (imagen, animal_id)
        VALUES (p_url_imagen, p_id_animal_creado);
    END IF;

    INSERT INTO movimientos (tipo_movimiento, fecha_movimiento, motivo, animal_id)
    VALUES ('entrada', p_fecha_rescate, 'rescate', p_id_animal_creado);

    RAISE NOTICE
        'Animal "%" registrado con id=%. Ocupacion actual: %/%.',
        p_nombre, p_id_animal_creado,
        v_ocupacion_actual + 1, v_capacidad_max;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al registrar animal. Transaccion revertida: %', SQLERRM;
        RAISE;
END;
$$;

-- SP-2: sp_dar_baja_animal
-- PROPOSITO
--   Procesar de forma controlada la salida definitiva de un animal
--   por adopcion, defuncion o extravio, dejando el historial de
--   movimientos y el estado del expediente completamente alineados.
--
-- JUSTIFICACION
--   Este procedimiento coordina "animales" y "movimientos":
--   registra la salida con su motivo y, al mismo tiempo, actualiza
--   el estado terminal del animal, incluyendo una nota historica
--   en la descripcion para trazabilidad administrativa.
--
--   Su funcion es asegurar que la baja tenga evidencia operativa y
--   estado consistente en el expediente. Comparado con hacerlo de
--   forma tradicional, este SP reduce errores de sincronizacion
--   y evita que un animal quede con salida registrada pero con
--   estado incorrecto, o al reves.

CREATE OR REPLACE PROCEDURE sp_dar_baja_animal(
    p_animal_id UUID,
    p_motivo    TEXT,
    p_fecha     TIMESTAMP DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ultimo_tipo   TEXT;
    v_estado_actual TEXT;
    v_nombre_animal TEXT;
    v_nuevo_estado  "EstadoAnimal";
    v_nota          TEXT;
BEGIN
    IF p_motivo NOT IN ('adopcion', 'defuncion', 'extravio') THEN
        RAISE EXCEPTION
            'El motivo "%" no es un motivo de baja valido. Use: adopcion, defuncion o extravio.', p_motivo;
    END IF;

    SELECT nombre, estado::TEXT
    INTO v_nombre_animal, v_estado_actual
    FROM animales
    WHERE id_animal = p_animal_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Animal con id % no encontrado.', p_animal_id;
    END IF;

    IF v_estado_actual IN ('adoptado', 'defuncion', 'extraviado') THEN
        RAISE EXCEPTION
            'El animal "%" (%) ya tiene un estado terminal: %. No se puede dar de baja nuevamente.',
            v_nombre_animal, p_animal_id, v_estado_actual;
    END IF;

    SELECT tipo_movimiento::TEXT
    INTO v_ultimo_tipo
    FROM movimientos
    WHERE animal_id = p_animal_id
    ORDER BY fecha_movimiento DESC
    LIMIT 1;

    IF v_ultimo_tipo IS DISTINCT FROM 'entrada' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene una entrada activa registrada. Verifique el historial de movimientos.',
            v_nombre_animal;
    END IF;

    v_nuevo_estado := CASE p_motivo
        WHEN 'adopcion'  THEN 'adoptado'::"EstadoAnimal"
        WHEN 'defuncion' THEN 'defuncion'::"EstadoAnimal"
        WHEN 'extravio'  THEN 'extraviado'::"EstadoAnimal"
    END;

    INSERT INTO movimientos (tipo_movimiento, fecha_movimiento, motivo, animal_id)
    VALUES ('salida', p_fecha, p_motivo::"movimiento_motivo", p_animal_id);

    v_nota := FORMAT(
        ' | Baja por %s el %s',
        UPPER(p_motivo),
        TO_CHAR(p_fecha, 'DD/MM/YYYY HH24:MI')
    );

    UPDATE animales
    SET estado = v_nuevo_estado,
        descripcion = descripcion || v_nota,
        "updatedAt" = NOW()
    WHERE id_animal = p_animal_id;

    RAISE NOTICE
        'Animal "%" dado de baja. Motivo: %. Nuevo estado: %.',
        v_nombre_animal, p_motivo, v_nuevo_estado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al dar de baja. Transaccion revertida: %', SQLERRM;
        RAISE;
END;
$$;

-- SP-3: sp_crear_refugio_completo
-- PROPOSITO
--   Dar de alta un refugio listo para operar desde el primer momento,
--   creando en la misma operacion su estructura base de seguridad:
--   rol propietario y usuario administrador inicial.
--
-- JUSTIFICACION
--   Este procedimiento une "refugios", "roles" y "usuarios" en un
--   mismo flujo de alta. Primero crea el refugio, luego su rol
--   principal y finalmente el usuario responsable, devolviendo los
--   IDs generados para continuidad del proceso.
--
--   Su funcion es evitar refugios incompletos o sin administracion.
--   Frente al esquema tradicional de insertar en pasos separados,
--   este SP es mejor porque protege la consistencia: si falla una
--   parte, por ejemplo un correo duplicado, no queda nada a medias
--   y se conserva integra la relacion entre las tres tablas.

CREATE OR REPLACE PROCEDURE sp_crear_refugio_completo(
    p_nombre_refugio VARCHAR(100),
    p_capacidad_max  INTEGER,
    p_estado         VARCHAR(100),
    p_municipio      VARCHAR(100),
    p_colonia        TEXT,
    p_calle          TEXT,
    p_nombre_usuario VARCHAR(100),
    p_apellido_p     VARCHAR(100),
    p_apellido_m     VARCHAR(100),
    p_email          TEXT,
    p_contrasena     TEXT,
    INOUT p_id_refugio UUID DEFAULT NULL,
    INOUT p_id_rol     UUID DEFAULT NULL,
    INOUT p_id_usuario UUID DEFAULT NULL,
    p_num_exterior   INTEGER DEFAULT NULL,
    p_num_interior   INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_email_existe BOOLEAN;
    v_nombre_rol   TEXT;
BEGIN
    IF p_capacidad_max <= 0 THEN
        RAISE EXCEPTION
            'La capacidad maxima debe ser mayor a 0. Valor recibido: %.', p_capacidad_max;
    END IF;

    IF p_contrasena IS NULL OR TRIM(p_contrasena) = '' THEN
        RAISE EXCEPTION 'La contrasena no puede estar vacia.';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM usuarios WHERE email = LOWER(TRIM(p_email))
    ) INTO v_email_existe;

    IF v_email_existe THEN
        RAISE EXCEPTION
            'El correo "%" ya esta registrado en el sistema. Use un correo diferente para el propietario.',
            LOWER(TRIM(p_email));
    END IF;

    INSERT INTO refugios (
        nombre, capacidad_max, estado, municipio,
        colonia, calle, num_exterior, num_interior
    )
    VALUES (
        TRIM(p_nombre_refugio),
        p_capacidad_max,
        TRIM(p_estado),
        TRIM(p_municipio),
        TRIM(p_colonia),
        TRIM(p_calle),
        p_num_exterior,
        p_num_interior
    )
    RETURNING id_refugio INTO p_id_refugio;

    v_nombre_rol := 'Propietario - ' || TRIM(p_nombre_refugio);

    INSERT INTO roles (nombre, refugio_id)
    VALUES (v_nombre_rol, p_id_refugio)
    RETURNING id_roles INTO p_id_rol;

    INSERT INTO usuarios (
        nombre, apellido_p, apellido_m,
        contrasena, email,
        activo, aceptacion_term,
        rol_id, refugio_id
    )
    VALUES (
        TRIM(p_nombre_usuario),
        TRIM(p_apellido_p),
        TRIM(p_apellido_m),
        p_contrasena,
        LOWER(TRIM(p_email)),
        TRUE,
        TRUE,
        p_id_rol,
        p_id_refugio
    )
    RETURNING id_usuario INTO p_id_usuario;

    RAISE NOTICE
        'Refugio registrado exitosamente: refugio=% | rol=% | usuario=%',
        p_id_refugio, p_id_rol, p_id_usuario;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE
            'Error al crear refugio. Todas las inserciones fueron revertidas. Detalle: %',
            SQLERRM;
        RAISE;
END;
$$;
