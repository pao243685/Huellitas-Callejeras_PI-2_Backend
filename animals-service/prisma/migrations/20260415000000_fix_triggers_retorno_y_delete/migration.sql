
-- la validacion del retorno estaba despues del check de entrada duplicada
-- no se validaba que el primer movimiento fuera rescate permitiendo registrar retorno en animales sin historial
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
            'El animal "%" falleció (defuncion). No se pueden registrar más movimientos.',
            v_nombre_animal;
    END IF;

    IF NEW.tipo_movimiento = 'entrada' AND NEW.motivo = 'retorno' THEN
        IF v_estado_actual NOT IN ('adoptado', 'extraviado') THEN
            RAISE EXCEPTION
                'El motivo "retorno" solo aplica para animales con estado "adoptado" o "extraviado". '
                'Estado actual de "%": %.',
                v_nombre_animal, v_estado_actual;
        END IF;
        RETURN NEW;
    END IF;

    IF v_estado_actual IN ('adoptado', 'extraviado') THEN
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

    IF v_ultimo_tipo IS NULL AND NEW.tipo_movimiento = 'entrada' AND NEW.motivo != 'rescate' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene ningún movimiento previo. '
            'El primer movimiento debe ser una entrada con motivo "rescate".',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo IS NULL AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene ningún movimiento previo. '
            'El primer movimiento siempre debe ser una entrada.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo = 'entrada' AND NEW.tipo_movimiento = 'entrada' THEN
        RAISE EXCEPTION
            'El animal "%" ya tiene una entrada activa. '
            'Debe registrar su salida antes de registrar un nuevo ingreso.',
            v_nombre_animal;
    END IF;

    IF v_ultimo_tipo = 'salida' AND NEW.tipo_movimiento = 'salida' THEN
        RAISE EXCEPTION
            'El animal "%" no tiene una entrada activa. '
            'No se puede registrar una salida sin una entrada previa.',
            v_nombre_animal;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_movimiento ON movimientos;
CREATE TRIGGER trg_validar_movimiento
BEFORE INSERT ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_validar_movimiento();



-- al borrar la única entrada, el estado quedaba adopcion pero con historial vacío, permitiendo retorno inválido después.

CREATE OR REPLACE FUNCTION fn_reversar_estado_en_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_ultimo_tipo   TEXT;
    v_ultimo_motivo TEXT;
    v_nuevo_estado  "EstadoAnimal";
BEGIN
    IF OLD.motivo = 'defuncion' THEN
        RETURN OLD;
    END IF;

    SELECT tipo_movimiento::TEXT, motivo::TEXT
    INTO v_ultimo_tipo, v_ultimo_motivo
    FROM movimientos
    WHERE animal_id = OLD.animal_id
    ORDER BY fecha_movimiento DESC
    LIMIT 1;

    IF v_ultimo_tipo IS NULL THEN
        UPDATE animales
        SET estado = 'adopcion'::"EstadoAnimal", "updatedAt" = NOW()
        WHERE id_animal = OLD.animal_id;
        RETURN OLD;
    END IF;

    v_nuevo_estado := CASE
        WHEN v_ultimo_tipo = 'entrada'                               THEN 'adopcion'::"EstadoAnimal"
        WHEN v_ultimo_tipo = 'salida' AND v_ultimo_motivo = 'adopcion' THEN 'adoptado'::"EstadoAnimal"
        WHEN v_ultimo_tipo = 'salida' AND v_ultimo_motivo = 'extravio' THEN 'extraviado'::"EstadoAnimal"
        ELSE 'adopcion'::"EstadoAnimal"
    END;

    UPDATE animales
    SET estado = v_nuevo_estado, "updatedAt" = NOW()
    WHERE id_animal = OLD.animal_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reversar_estado_delete ON movimientos;
CREATE TRIGGER trg_reversar_estado_delete
AFTER DELETE ON movimientos
FOR EACH ROW EXECUTE FUNCTION fn_reversar_estado_en_delete();