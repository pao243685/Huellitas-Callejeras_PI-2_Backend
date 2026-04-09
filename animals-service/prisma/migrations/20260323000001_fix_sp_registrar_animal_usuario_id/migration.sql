-- Fix: Recreate sp_registrar_animal_completo with p_usuario_id parameter
-- The original procedure was missing this parameter

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
    p_usuario_id             UUID,
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

    RAISE NOTICE
        'Animal "%" registrado con id=%. Ocupacion actual: %/%.',
        p_nombre, p_id_animal_creado,
        (v_ocupacion_actual + 1), v_capacidad_max;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE
            'Error al crear animal. Transaccion revertida. Detalle: %',
            SQLERRM;
        RAISE;
END;
$$;
