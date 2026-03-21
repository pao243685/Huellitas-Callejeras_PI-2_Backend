  CREATE OR REPLACE FUNCTION fn_set_updated_at()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW."updatedAt" = NOW();
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;


  -- Jusficación
  -- Este trigger mantiene trazabilidad de cambios en refugios actualizando automáticamente el campo updatedAt.
  -- Primero detecta cuando se ejecuta un UPDATE sobre la tabla de refugios,
  -- luego invoca la función fn_set_updated_at para colocar la fecha y hora actual,
  -- y con eso evita depender de que la aplicación recuerde llenar ese campo manualmente.

  CREATE TRIGGER trg_updated_at_refugios
  BEFORE UPDATE ON refugios
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger asegura que cualquier cambio en roles conserve un historial temporal confiable.
  -- Primero se activa antes de cada UPDATE en la tabla de roles,
  -- luego aplica la función fn_set_updated_at para refrescar updatedAt en la fila afectada,
  -- y con eso garantiza que cada edición administrativa quede fechada correctamente.
  CREATE TRIGGER trg_updated_at_roles
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger protege la integridad temporal de los datos de usuarios al actualizar updatedAt de forma automática.
  -- Primero intercepta las operaciones UPDATE en usuarios,
  -- después reutiliza fn_set_updated_at para asignar la hora actual al registro editado,
  -- y con eso centraliza la lógica de auditoría sin duplicarla en múltiples consultas o servicios.
  CREATE TRIGGER trg_updated_at_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger mantiene actualizada la marca de tiempo de animales cada vez que cambia su información.
  -- Primero se activa ante un UPDATE en la tabla animales,
  -- luego ejecuta fn_set_updated_at para establecer updatedAt con NOW(),
  -- y con eso permite rastrear cuándo se ajustaron datos críticos como estado, ubicación o condiciones del animal.

  CREATE TRIGGER trg_updated_at_animales
  BEFORE UPDATE ON animales
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger conserva la trazabilidad de los movimientos al registrar automáticamente su última modificación.
  -- Primero identifica cada UPDATE en movimientos,
  -- luego llama a fn_set_updated_at para escribir la fecha y hora actual en updatedAt,
  -- y con eso facilita validar correcciones o ajustes posteriores en eventos de entrada y salida.

  CREATE TRIGGER trg_updated_at_movimientos
  BEFORE UPDATE ON movimientos
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger garantiza que los cambios en etiquetas queden reflejados con una marca temporal uniforme.
  -- Primero se ejecuta antes de cada UPDATE en la tabla etiquetas,
  -- luego aplica fn_set_updated_at para actualizar updatedAt en la fila modificada,
  -- y con eso mantiene coherencia con el resto del modelo en control de cambios.

  CREATE TRIGGER trg_updated_at_etiquetas
  BEFORE UPDATE ON etiquetas
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


  -- Justificación
  -- Este trigger protege la integridad del historial de movimientos
  -- rechazando automáticamente registros inconsistentes con el estado real del animal.
  -- Primero se ejecuta antes de cada INSERT en la tabla movimientos,
  -- luego verifica si el animal tiene un estado terminal (adoptado, defuncion o extraviado)
  -- o si ya tiene una entrada activa sin salida correspondiente cuando se intenta registrar otra entrada,
  -- y con eso garantiza que ningún expediente quede con movimientos contradictorios
  -- que distorsionen las métricas de ocupación y los indicadores de liberación de espacio
  -- calculados por las vistas vw_resumen_adoptabilidad y vw_animales_activos.

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

    
      IF v_estado_actual IN ('adoptado', 'defuncion', 'extraviado') THEN
          RAISE EXCEPTION
              'El animal "%" tiene estado terminal (%). '
              'No se pueden registrar más movimientos sobre este expediente. '
              'Use sp_registrar_animal_completo si el animal reingresó al refugio.',
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


  CREATE TRIGGER trg_validar_movimiento
  BEFORE INSERT ON movimientos
  FOR EACH ROW EXECUTE FUNCTION fn_validar_movimiento();



  -- Justificación
  -- Este trigger mantiene el estado del expediente del animal sincronizado
  -- automáticamente con cada movimiento de salida que se registra en el sistema.
  -- Primero se ejecuta después de cada INSERT en la tabla movimientos,
  -- luego evalúa si el movimiento es una salida definitiva (adopcion, defuncion o extravio)
  -- y actualiza el campo estado del animal al valor terminal correspondiente,
  -- y con eso asegura que las vistas vw_resumen_adoptabilidad y vw_animales_activos
  -- siempre reflejen el estado real del animal sin depender de que
  -- la capa de aplicación recuerde hacer el UPDATE por separado.

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

      IF NEW.tipo_movimiento = 'entrada' AND NEW.motivo IN ('rescate', 'retorno') THEN

          UPDATE animales
          SET
              estado      = 'adopcion'::"EstadoAnimal",
              "updatedAt" = NOW()
          WHERE id_animal = NEW.animal_id
            AND estado NOT IN ('adopcion', 'recuperacion');

      END IF;

      RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;


  CREATE TRIGGER trg_sincronizar_estado_animal
  AFTER INSERT ON movimientos
  FOR EACH ROW EXECUTE FUNCTION fn_sincronizar_estado_animal();