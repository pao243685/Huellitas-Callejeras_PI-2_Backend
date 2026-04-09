-- Jusficación
-- Esta vista te da un resumen agregado por refugio y por nivel de adoptabilidad.
-- Primero identifica animales “activos”, los que sí tienen una entrada y no tienen una salida posterior, 
-- luego construye un “perfil histórico” del refugio usando animales adoptados,
-- edad promedio, sexo y tamaño más frecuentes, tasas de discapacidad, agresividad y enfermedad degenerativa,
-- y con eso asigna una puntuación a cada animal activo.

-- Si el refugio no tiene suficiente historial de adopciones, el nivel sale como “Sin historial suficiente”.
-- Si sí tiene historial, clasifica en Fácil, Moderada o Difícil según el puntaje.


CREATE OR REPLACE VIEW vw_resumen_adoptabilidad AS

    WITH ultimo_ingreso AS (
        SELECT DISTINCT ON (animal_id)
            animal_id,
            fecha_movimiento AS fecha_entrada
        FROM movimientos
        WHERE tipo_movimiento = 'entrada'
        ORDER BY animal_id, fecha_movimiento DESC
    ),
    activos AS (
        SELECT
            a.id_animal,
            a.especie,
            a.sexo,
            a.tamano,
            a.edad,
            a.enfermedad_no_tratable,
            a.discapacidad,
            a.es_agresivo,
            a.refugio_id
        FROM animales a
        JOIN ultimo_ingreso ui ON ui.animal_id = a.id_animal
        WHERE NOT EXISTS (
            SELECT 1 FROM movimientos sal
            WHERE sal.animal_id       = a.id_animal
            AND sal.tipo_movimiento  = 'salida'
            AND sal.fecha_movimiento > ui.fecha_entrada
        )
    ),
    adoptados AS (
        SELECT
            a.id_animal,
            a.refugio_id,
            a.sexo,
            a.tamano,
            a.edad,
            a.discapacidad,
            a.es_agresivo,
            a.enfermedad_no_tratable
        FROM animales a
        JOIN movimientos m ON m.animal_id = a.id_animal
        WHERE a.estado          = 'adoptado'
        AND m.tipo_movimiento = 'salida'
        AND m.motivo          = 'adopcion'
    ),
    perfil_refugio AS (
        SELECT
            ad.refugio_id,
            COUNT(*)                                                         AS total_adoptados,
            CEIL(MAX(r.capacidad_max) * 1.5)                                 AS min_historial,
            ROUND(AVG(ad.edad), 1)                                           AS edad_prom_adoptados,
            MODE() WITHIN GROUP (ORDER BY ad.sexo)                           AS sexo_mas_adoptado,
            MODE() WITHIN GROUP (ORDER BY ad.tamano)                         AS tamano_mas_adoptado,
            AVG(CASE WHEN ad.discapacidad           THEN 1.0 ELSE 0 END)     AS tasa_discap,
            AVG(CASE WHEN ad.es_agresivo            THEN 1.0 ELSE 0 END)     AS tasa_agresivo,
            AVG(CASE WHEN ad.enfermedad_no_tratable THEN 1.0 ELSE 0 END)     AS tasa_enferm
        FROM adoptados ad
        JOIN refugios r ON r.id_refugio = ad.refugio_id
        GROUP BY ad.refugio_id
    ),
    puntuacion AS (
        SELECT
            ac.id_animal,
            ac.especie,
            ac.refugio_id,
            CASE
                WHEN pr.total_adoptados IS NULL
                OR pr.total_adoptados < pr.min_historial
                THEN NULL
                ELSE (
                    CASE WHEN ABS(ac.edad - pr.edad_prom_adoptados) <= 24  THEN 1 ELSE -1 END +
                    CASE WHEN ac.sexo   = pr.sexo_mas_adoptado            THEN 1 ELSE -1 END +
                    CASE WHEN ac.tamano = pr.tamano_mas_adoptado           THEN 1 ELSE -1 END +
                    CASE
                        WHEN pr.tasa_discap < 0.2 AND ac.discapacidad  = FALSE THEN  1
                        WHEN pr.tasa_discap < 0.2 AND ac.discapacidad  = TRUE  THEN -1
                        ELSE 0
                    END +
                    CASE
                        WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = FALSE THEN  1
                        WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = TRUE  THEN -1
                        ELSE 0
                    END +
                    CASE
                        WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = FALSE THEN  1
                        WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = TRUE  THEN -1
                        ELSE 0
                    END
                )
            END                                                              AS puntos
        FROM activos ac
        LEFT JOIN perfil_refugio pr ON pr.refugio_id = ac.refugio_id
    )
    SELECT
        p.refugio_id,
        CASE
            WHEN p.puntos IS NULL THEN 'Sin historial suficiente'
            WHEN p.puntos >= 4   THEN 'Fácil'
            WHEN p.puntos >= 1   THEN 'Moderada'
            ELSE                      'Difícil'
        END                                                       AS nivel_adoptabilidad,
        COUNT(*)                                                  AS total_animales,
        COUNT(*) FILTER (WHERE p.especie = 'Perro')               AS perros,
        COUNT(*) FILTER (WHERE p.especie = 'Gato')                AS gatos,
        ROUND(
            100.0 * COUNT(*)
            / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY p.refugio_id), 0)
        , 1)                                                      AS pct_sobre_total,

        SUM(CASE
            WHEN p.puntos IS NULL OR p.puntos < 1 THEN 1
            ELSE 0
        END)                                                      AS espacios_en_riesgo

    FROM puntuacion p
    GROUP BY
        p.refugio_id,
        nivel_adoptabilidad,
        CASE
            WHEN p.puntos IS NULL THEN 4
            WHEN p.puntos >= 4   THEN 0
            WHEN p.puntos >= 1   THEN 1
            ELSE                      2
        END
    ORDER BY
        p.refugio_id ASC,
        CASE
            WHEN p.puntos IS NULL THEN 4
            WHEN p.puntos >= 4   THEN 0
            WHEN p.puntos >= 1   THEN 1
            ELSE                      2
        END ASC;


    -- Jusficación
    -- Esta vista te muestra el detalle de animales activos con un nivel de adoptabilidad por animal.
    -- Primero identifica animales “activos”, los que sí tienen una entrada y no tienen una salida posterior,
    -- luego calcula un “perfil histórico” del refugio usando animales adoptados,
    -- edad promedio, sexo y tamaño más frecuentes, tasas de discapacidad, agresividad y enfermedad degenerativa,
    -- y con eso asigna una puntuación individual a cada animal.

    -- Si el refugio no tiene suficiente historial de adopciones, el resultado sale como “Sin historial suficiente”.
    -- Si sí tiene historial, cada animal se clasifica en Fácil, Moderada o Difícil según el puntaje.
    -- Además, incluye días en refugio y fecha de ingreso para priorizar casos en operación diaria.


CREATE OR REPLACE VIEW vw_animales_activos AS

    WITH ultimo_ingreso AS (
        SELECT DISTINCT ON (animal_id)
            animal_id,
            fecha_movimiento AS fecha_entrada
        FROM movimientos
        WHERE tipo_movimiento = 'entrada'
        ORDER BY animal_id, fecha_movimiento DESC
    ),
    activos AS (
        SELECT
            a.id_animal,
            a.nombre,
            a.especie,
            a.sexo,
            a.tamano,
            a.edad,
            a.enfermedad_no_tratable,
            a.discapacidad,
            a.es_agresivo,
            a.estado,
            a.refugio_id,
            EXTRACT(DAY FROM (NOW() - ui.fecha_entrada))::INT     AS dias_en_refugio,
            ui.fecha_entrada::DATE                                AS fecha_ingreso
        FROM animales a
        JOIN ultimo_ingreso ui ON ui.animal_id = a.id_animal
        WHERE NOT EXISTS (
            SELECT 1 FROM movimientos sal
            WHERE sal.animal_id       = a.id_animal
            AND sal.tipo_movimiento  = 'salida'
            AND sal.fecha_movimiento > ui.fecha_entrada
        )
    ),
    adoptados AS (
        SELECT
            a.id_animal,
            a.refugio_id,
            a.sexo,
            a.tamano,
            a.edad,
            a.discapacidad,
            a.es_agresivo,
            a.enfermedad_no_tratable
        FROM animales a
        JOIN movimientos m ON m.animal_id = a.id_animal
        WHERE a.estado          = 'adoptado'
        AND m.tipo_movimiento = 'salida'
        AND m.motivo          = 'adopcion'
    ),
    perfil_refugio AS (
        SELECT
            ad.refugio_id,
            COUNT(*)                                                         AS total_adoptados,
            CEIL(MAX(r.capacidad_max) * 1.5)                                 AS min_historial,
            ROUND(AVG(ad.edad), 1)                                           AS edad_prom_adoptados,
            MODE() WITHIN GROUP (ORDER BY ad.sexo)                           AS sexo_mas_adoptado,
            MODE() WITHIN GROUP (ORDER BY ad.tamano)                         AS tamano_mas_adoptado,
            AVG(CASE WHEN ad.discapacidad           THEN 1.0 ELSE 0 END)     AS tasa_discap,
            AVG(CASE WHEN ad.es_agresivo            THEN 1.0 ELSE 0 END)     AS tasa_agresivo,
            AVG(CASE WHEN ad.enfermedad_no_tratable THEN 1.0 ELSE 0 END)     AS tasa_enferm
        FROM adoptados ad
        JOIN refugios r ON r.id_refugio = ad.refugio_id
        GROUP BY ad.refugio_id
    ),
    puntuacion AS (
        SELECT
            ac.id_animal,
            ac.nombre,
            ac.especie,
            ac.sexo,
            ac.tamano,
            ac.edad,
            ac.enfermedad_no_tratable,
            ac.discapacidad,
            ac.es_agresivo,
            ac.estado,
            ac.refugio_id,
            ac.dias_en_refugio,
            ac.fecha_ingreso,
            pr.total_adoptados,
            pr.min_historial,
            CASE
                WHEN pr.total_adoptados IS NULL
                OR pr.total_adoptados < pr.min_historial
                THEN NULL
                ELSE (
                    CASE WHEN ABS(ac.edad - pr.edad_prom_adoptados) <= 24  THEN 1 ELSE -1 END +
                    CASE WHEN ac.sexo   = pr.sexo_mas_adoptado            THEN 1 ELSE -1 END +
                    CASE WHEN ac.tamano = pr.tamano_mas_adoptado           THEN 1 ELSE -1 END +
                    CASE
                        WHEN pr.tasa_discap < 0.2 AND ac.discapacidad  = FALSE THEN  1
                        WHEN pr.tasa_discap < 0.2 AND ac.discapacidad  = TRUE  THEN -1
                        ELSE 0
                    END +
                    CASE
                        WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = FALSE THEN  1
                        WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = TRUE  THEN -1
                        ELSE 0
                    END +
                    CASE
                        WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = FALSE THEN  1
                        WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = TRUE  THEN -1
                        ELSE 0
                    END
                )
            END                                                              AS puntos
        FROM activos ac
        LEFT JOIN perfil_refugio pr ON pr.refugio_id = ac.refugio_id
    )
    SELECT
        p.refugio_id,
        p.id_animal,
        p.nombre                                                  AS animal,
        p.especie,
        p.sexo,
        p.tamano,
        p.edad,
        p.enfermedad_no_tratable,
        p.discapacidad,
        p.es_agresivo,
        p.estado,
        p.dias_en_refugio,
        p.fecha_ingreso,
        CASE
            WHEN p.puntos IS NULL      THEN 'Sin historial suficiente'
            WHEN p.puntos >= 4         THEN 'Fácil'
            WHEN p.puntos >= 1         THEN 'Moderada'
            ELSE                            'Difícil'
        END                                                       AS nivel_adoptabilidad,
        CASE
            WHEN p.puntos IS NULL      THEN 'sin datos'
            ELSE                            'historico'
        END                                                       AS nivel_confianza
    FROM puntuacion p
    ORDER BY
        p.refugio_id         ASC,
        p.dias_en_refugio DESC;

    -- Jusficación
    -- Esta vista te genera alertas operativas sobre animales con eventos sensibles distintos a una adopción estable.
    -- Primero resume entradas y salidas por animal, identifica su último movimiento y detecta si fue devuelto,
    -- además calcula cuántas veces ha regresado al refugio y cuánto tiempo lleva en estancia actual.
    -- También construye un score interno de riesgo considerando agresividad, discapacidad,
    -- enfermedad degenerativa, edad y reincidencia de retorno.

    -- Con ese análisis clasifica cada caso en tipo de alerta y nivel de riesgo.
    -- El resultado ayuda a priorizar seguimiento, intervención y toma de decisiones por refugio.

CREATE OR REPLACE VIEW vw_alertas_movimientos_no_adopcion AS

    WITH conteo_entradas AS (
        SELECT
            animal_id,
            COUNT(*)              AS total_entradas,
            MIN(fecha_movimiento) AS primera_entrada,
            MAX(fecha_movimiento) AS ultima_entrada
        FROM movimientos
        WHERE tipo_movimiento = 'entrada'
        GROUP BY animal_id
    ),
    resumen_salidas AS (
        SELECT
            animal_id,
            SUM(CASE WHEN motivo = 'adopcion'  THEN 1 ELSE 0 END) AS salidas_adopcion,
            SUM(CASE WHEN motivo = 'defuncion' THEN 1 ELSE 0 END) AS salidas_defuncion,
            SUM(CASE WHEN motivo = 'extravio'  THEN 1 ELSE 0 END) AS salidas_extravio,
            MAX(fecha_movimiento)                                  AS ultima_salida
        FROM movimientos
        WHERE tipo_movimiento = 'salida'
        GROUP BY animal_id
    ),

    ultimo_mov AS (
        SELECT DISTINCT ON (animal_id)
            animal_id,
            tipo_movimiento  AS ultimo_tipo,
            fecha_movimiento AS ultima_fecha
        FROM movimientos
        ORDER BY animal_id, fecha_movimiento DESC
    ),
    estado_actual AS (
        SELECT
            a.id_animal,
            a.nombre,
            a.especie,
            a.estado                                               AS estado_registro,
            a.refugio_id,
            a.es_agresivo,
            a.discapacidad,
            a.enfermedad_no_tratable,
            a.edad,
            ce.primera_entrada,
            ce.ultima_entrada,
            ce.total_entradas,
            rs.ultima_salida,
            rs.salidas_adopcion,
            rs.salidas_defuncion,
            rs.salidas_extravio,
            um.ultimo_tipo                                         AS ultimo_movimiento,

            CASE
                WHEN rs.salidas_adopcion >= 1
                AND ce.ultima_entrada > (
                    SELECT MAX(m_ad.fecha_movimiento)
                    FROM movimientos m_ad
                    WHERE m_ad.animal_id       = a.id_animal
                    AND m_ad.tipo_movimiento = 'salida'
                    AND m_ad.motivo          = 'adopcion'
                )
                THEN TRUE ELSE FALSE
            END                                                    AS fue_devuelto,

            GREATEST(ce.total_entradas - 1, 0)                    AS veces_regresado,


            CASE
                WHEN um.ultimo_tipo = 'entrada'
                THEN EXTRACT(DAY FROM (NOW() - ce.ultima_entrada))::INT
                ELSE NULL
            END                                                    AS dias_estancia_actual,

            
            (
                (CASE WHEN a.es_agresivo            THEN 2 ELSE 0 END) +
                (CASE WHEN a.discapacidad           THEN 1 ELSE 0 END) +
                (CASE WHEN a.enfermedad_no_tratable THEN 2 ELSE 0 END) +
                (CASE WHEN a.edad > 84               THEN 1 ELSE 0 END) +
                (CASE WHEN rs.salidas_adopcion >= 1
                    AND ce.ultima_entrada > (
                        SELECT MAX(m2.fecha_movimiento)
                        FROM movimientos m2
                        WHERE m2.animal_id       = a.id_animal
                            AND m2.tipo_movimiento = 'salida'
                            AND m2.motivo          = 'adopcion'
                    ) THEN 3 ELSE 0 END) +
                (CASE WHEN GREATEST(ce.total_entradas - 1, 0) >= 2 THEN 2 ELSE 0 END)
            )                                                      AS score_interno

        FROM animales a
        LEFT JOIN conteo_entradas ce ON ce.animal_id = a.id_animal
        LEFT JOIN resumen_salidas  rs ON rs.animal_id = a.id_animal
        LEFT JOIN ultimo_mov       um ON um.animal_id = a.id_animal
    )

    SELECT
        
        CASE
            WHEN ea.fue_devuelto AND ea.veces_regresado >= 2
                THEN 'Reincidente: regresó 2+ veces'
            WHEN ea.fue_devuelto
                THEN 'Devuelto: regresó tras adopción'
            WHEN ea.salidas_defuncion >= 1
                THEN 'Defunción registrada'
            WHEN ea.salidas_extravio >= 1
                THEN 'Extravío registrado'
            WHEN ea.ultimo_movimiento = 'entrada'
            AND ea.dias_estancia_actual > 180
                THEN 'Larga estancia: más de 6 meses'
            WHEN ea.ultimo_movimiento = 'entrada'
            AND ea.dias_estancia_actual > 90
                THEN 'Estancia prolongada: más de 3 meses'
            ELSE 'Sin alertas'
        END                                                        AS tipo_alerta,

        CASE
            WHEN ea.score_interno >= 4 THEN 'Alto'
            WHEN ea.score_interno >= 2 THEN 'Medio'
            ELSE                           'Bajo'
        END                                                        AS nivel_riesgo,
        ea.refugio_id,
        ea.id_animal,
        ea.nombre                                                  AS animal,
        ea.especie,
        ea.estado_registro,
        ea.fue_devuelto,
        ea.veces_regresado,

        ea.primera_entrada::DATE                                   AS fecha_primer_ingreso,
        ea.ultima_salida::DATE                                     AS fecha_ultima_salida

    FROM estado_actual ea
    WHERE ea.primera_entrada IS NOT NULL
    AND (
        ea.fue_devuelto                          = TRUE
        OR ea.salidas_defuncion                     > 0
        OR ea.salidas_extravio                      > 0
        OR (ea.ultimo_movimiento = 'entrada' AND ea.dias_estancia_actual > 90)
        OR ea.ultimo_movimiento  = 'entrada'
    )
    ORDER BY
        ea.refugio_id                ASC,
        ea.score_interno             DESC,
        ea.dias_estancia_actual      DESC NULLS LAST;




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

  DROP TRIGGER IF EXISTS trg_updated_at_refugios ON refugios;
  CREATE TRIGGER trg_updated_at_refugios
  BEFORE UPDATE ON refugios
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger asegura que cualquier cambio en roles conserve un historial temporal confiable.
  -- Primero se activa antes de cada UPDATE en la tabla de roles,
  -- luego aplica la función fn_set_updated_at para refrescar updatedAt en la fila afectada,
  -- y con eso garantiza que cada edición administrativa quede fechada correctamente.
  
  DROP TRIGGER IF EXISTS trg_updated_at_roles ON roles;
  CREATE TRIGGER trg_updated_at_roles
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger protege la integridad temporal de los datos de usuarios al actualizar updatedAt de forma automática.
  -- Primero intercepta las operaciones UPDATE en usuarios,
  -- después reutiliza fn_set_updated_at para asignar la hora actual al registro editado,
  -- y con eso centraliza la lógica de auditoría sin duplicarla en múltiples consultas o servicios.
  
  DROP TRIGGER IF EXISTS trg_updated_at_usuarios ON usuarios;
  CREATE TRIGGER trg_updated_at_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger mantiene actualizada la marca de tiempo de animales cada vez que cambia su información.
  -- Primero se activa ante un UPDATE en la tabla animales,
  -- luego ejecuta fn_set_updated_at para establecer updatedAt con NOW(),
  -- y con eso permite rastrear cuándo se ajustaron datos críticos como estado, ubicación o condiciones del animal.

  DROP TRIGGER IF EXISTS trg_updated_at_animales ON animales;
  CREATE TRIGGER trg_updated_at_animales
  BEFORE UPDATE ON animales
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger conserva la trazabilidad de los movimientos al registrar automáticamente su última modificación.
  -- Primero identifica cada UPDATE en movimientos,
  -- luego llama a fn_set_updated_at para escribir la fecha y hora actual en updatedAt,
  -- y con eso facilita validar correcciones o ajustes posteriores en eventos de entrada y salida.

  DROP TRIGGER IF EXISTS trg_updated_at_movimientos ON movimientos;
  CREATE TRIGGER trg_updated_at_movimientos
  BEFORE UPDATE ON movimientos
  FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

  -- Jusficación
  -- Este trigger garantiza que los cambios en etiquetas queden reflejados con una marca temporal uniforme.
  -- Primero se ejecuta antes de cada UPDATE en la tabla etiquetas,
  -- luego aplica fn_set_updated_at para actualizar updatedAt en la fila modificada,
  -- y con eso mantiene coherencia con el resto del modelo en control de cambios.

  DROP TRIGGER IF EXISTS trg_updated_at_etiquetas ON etiquetas;
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

    DROP TRIGGER IF EXISTS trg_validar_movimiento ON movimientos;
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

  DROP TRIGGER IF EXISTS trg_sincronizar_estado_animal ON movimientos;
  CREATE TRIGGER trg_sincronizar_estado_animal
  AFTER INSERT ON movimientos
  FOR EACH ROW EXECUTE FUNCTION fn_sincronizar_estado_animal();


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


-- Jusficación
-- Esta función te da un perfil agregado de adopción para un refugio específico.
-- Primero analiza el historial de adopciones en "animales" y "movimientos",
-- luego compara ese histórico con los animales activos del mismo refugio,
-- considerando edad en meses, sexo, tamaño, discapacidad, agresividad y enfermedad no tratable,
-- y con eso asigna un resultado de prioridad (Alto, Medio o Bajo) para cada criterio.
--
-- Si el refugio no tiene suficiente historial de adopciones, la función usa reglas predefinidas.
-- Si sí tiene historial suficiente, usa el comportamiento real del refugio para priorizar.
-- Esto aplica directamente a la base de datos porque cruza tablas operativas y devuelve un resumen listo para decisión.

CREATE OR REPLACE FUNCTION get_adoption_profile(p_refugio_id UUID)
RETURNS TABLE (
    datos        TEXT,
    historico    TEXT,
    actual       TEXT,
    resultado    TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad_max          INT;
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

    SELECT capacidad_max
    INTO v_capacidad_max
    FROM refugios
    WHERE id_refugio = p_refugio_id;


    v_min_historial := CEIL(v_capacidad_max * 1.5);

    SELECT COUNT(DISTINCT a.id_animal)
    INTO v_total_adoptados
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida';



    SELECT ROUND(AVG(a.edad), 1)
    INTO v_edad_promedio
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida';

    SELECT COUNT(*) INTO v_activos_cachorros
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND edad < 12;

    SELECT COUNT(*) INTO v_activos_adultos
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND edad >= 12;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_cachorros
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.edad < 12
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_adultos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.edad >= 12
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Edad'::TEXT,
          CONCAT(v_edad_promedio::TEXT, ' meses'),
          FORMAT('%s menores de 12 meses, %s de 12 meses o más', v_activos_cachorros, v_activos_adultos),
            CASE
                WHEN v_edad_promedio < 12  THEN 'Alto'
                WHEN v_edad_promedio <= 36 THEN 'Medio'
                ELSE                          'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Edad'::TEXT,
          FORMAT('Sin historial suficiente (predefinido: <12 meses)'),
          FORMAT('%s menores de 12 meses, %s de 12 meses o más', v_activos_cachorros, v_activos_adultos),
            CASE
                WHEN v_activos_cachorros > v_activos_adultos THEN 'Alto'
                WHEN v_activos_cachorros = v_activos_adultos THEN 'Medio'
                ELSE                                              'Bajo'
            END;
    END IF;


    SELECT a.sexo::TEXT
    INTO v_sexo_moda
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida'
    GROUP BY a.sexo
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT COUNT(*) INTO v_activos_machos
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND sexo = 'Macho';

    SELECT COUNT(*) INTO v_activos_hembras
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND sexo = 'Hembra';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_machos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.sexo = 'Macho'
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_hembras
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.sexo = 'Hembra'
      AND a.estado = 'adoptado'
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

    SELECT a.tamano::TEXT
    INTO v_tamano_moda
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida'
    GROUP BY a.tamano
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT COUNT(*) INTO v_activos_pref_tam
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND tamano IN ('miniatura','pequeño','mediano');

    SELECT COUNT(*) INTO v_activos_grande_tam
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND tamano IN ('grande','gigante');

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_pref_tam
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.tamano IN ('miniatura','pequeño','mediano')
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_grande_tam
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id
      AND a.tamano IN ('grande','gigante')
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Tamaño'::TEXT,
            COALESCE(v_tamano_moda, 'Sin datos'),
            FORMAT('%s miniatura/pequeño/mediano, %s grande/gigante',
                v_activos_pref_tam, v_activos_grande_tam),
            CASE
                WHEN v_tamano_moda IN ('miniatura','pequeño','mediano')
                 AND v_activos_pref_tam >= v_activos_grande_tam  THEN 'Alto'
                WHEN v_tamano_moda IN ('miniatura','pequeño','mediano')
                 AND v_activos_pref_tam < v_activos_grande_tam   THEN 'Medio'
                WHEN v_tamano_moda IN ('grande','gigante')
                 AND v_activos_grande_tam >= v_activos_pref_tam  THEN 'Alto'
                ELSE                                                  'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Tamaño'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Mediano)'),
            FORMAT('%s miniatura/pequeño/mediano, %s grande/gigante',
                v_activos_pref_tam, v_activos_grande_tam),
            CASE
                WHEN v_activos_pref_tam > v_activos_grande_tam  THEN 'Alto'
                WHEN v_activos_pref_tam = v_activos_grande_tam  THEN 'Medio'
                ELSE                                                 'Bajo'
            END;
    END IF;

    
    SELECT COUNT(*) INTO v_activos_discap
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND discapacidad = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.discapacidad = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.discapacidad = FALSE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Discapacidad'::TEXT,
            CASE
                WHEN v_adoptados_sin_discap >= v_adoptados_discap THEN 'Sin discapacidad'
                ELSE 'Con discapacidad'
            END,
            FORMAT('%s con discapacidad activos', v_activos_discap),
            CASE
                WHEN v_activos_discap = 0                                                    THEN 'Alto'
                WHEN (v_adoptados_discap::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2     THEN 'Bajo'
                ELSE                                                                              'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Discapacidad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Sin discapacidad)'),
            FORMAT('%s con discapacidad activos', v_activos_discap),
            CASE
                WHEN v_activos_discap = 0 THEN 'Alto'
                ELSE                          'Bajo'
            END;
    END IF;

    
    SELECT COUNT(*) INTO v_activos_agresivo
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND es_agresivo = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.es_agresivo = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.es_agresivo = FALSE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Agresividad'::TEXT,
            CASE
                WHEN v_adoptados_sin_agresivo >= v_adoptados_agresivo THEN 'No agresivo'
                ELSE 'Agresivo'
            END,
            FORMAT('%s agresivos activos', v_activos_agresivo),
            CASE
                WHEN v_activos_agresivo = 0                                                   THEN 'Alto'
                WHEN (v_adoptados_agresivo::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2    THEN 'Bajo'
                ELSE                                                                               'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Agresividad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: No agresivo)'),
            FORMAT('%s agresivos activos', v_activos_agresivo),
            CASE
                WHEN v_activos_agresivo = 0 THEN 'Alto'
                ELSE                            'Bajo'
            END;
    END IF;

    
    SELECT COUNT(*) INTO v_activos_enferm
    FROM animales
    WHERE refugio_id = p_refugio_id
      AND estado IN ('adopcion', 'recuperacion')
      AND enfermedad_no_tratable = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.enfermedad_no_tratable = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.refugio_id = p_refugio_id AND a.enfermedad_no_tratable = FALSE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Enfermedades'::TEXT,
            CASE
                WHEN v_adoptados_sin_enferm >= v_adoptados_enferm THEN 'Sin enfermedad'
                ELSE 'Con enfermedad'
            END,
            FORMAT('%s con enfermedad no tratable activos', v_activos_enferm),
            CASE
                WHEN v_activos_enferm = 0                                                   THEN 'Alto'
                WHEN (v_adoptados_enferm::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.1    THEN 'Bajo'
                ELSE                                                                             'Medio'
            END;
    ELSE
        RETURN QUERY SELECT
            'Enfermedades'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: Sin enfermedad)'),
            FORMAT('%s con enfermedad no tratable activos', v_activos_enferm),
            CASE
                WHEN v_activos_enferm = 0 THEN 'Alto'
                ELSE                          'Bajo'
            END;
    END IF;

END;
$$;


-- Jusficación
-- Esta función te da un resumen temporal de ocupación y movimientos de un refugio.
-- Primero recorre un rango de fechas y en cada punto consulta "movimientos" junto con "animales",
-- luego acumula entradas y salidas por motivo (adopción, defunción y extravío),
-- y con eso calcula la ocupación total en cada fecha para formar la serie de la gráfica.
--
-- Si el modo es "semana", genera puntos diarios.
-- Si el modo es "mes", genera puntos semanales para ver tendencia.
-- Esto aplica directamente a la base de datos porque convierte eventos transaccionales en indicadores cronológicos para monitoreo.

CREATE OR REPLACE FUNCTION get_movimientos_grafica(
    p_refugio_id  UUID,
    p_fecha_ini   TIMESTAMP,
    p_fecha_fin   TIMESTAMP,
    p_modo        TEXT  
)
RETURNS TABLE (
    periodo           TEXT,       
    fecha_punto       TIMESTAMP, 
    ocupacion_total   INT,       
    entradas_acum     INT,       
    salidas_adopcion  INT,       
    salidas_defuncion INT,       
    salidas_extravio  INT        
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_punto        TIMESTAMP;
    v_intervalo    INTERVAL;
    v_formato      TEXT;

    v_entradas     INT;
    v_adopciones   INT;
    v_defunciones  INT;
    v_extravios    INT;
    v_ocupacion    INT;
    v_etiqueta     TEXT;

    
    
    v_entradas_previas    INT;
    v_salidas_previas     INT;
BEGIN

    
    IF p_modo NOT IN ('semana', 'mes') THEN
        RAISE EXCEPTION 'El modo debe ser "semana" o "mes"';
    END IF;

    
    IF p_modo = 'semana' THEN
        v_intervalo := INTERVAL '1 day';
    
    ELSE
        v_intervalo := INTERVAL '1 week';
    
    END IF;

    SELECT COUNT(*) INTO v_entradas_previas
    FROM movimientos m
    JOIN animales a ON a.id_animal = m.animal_id
    WHERE a.refugio_id = p_refugio_id
      AND m.tipo_movimiento = 'entrada'
      AND m.fecha_movimiento < p_fecha_ini;

    SELECT COUNT(*) INTO v_salidas_previas
    FROM movimientos m
    JOIN animales a ON a.id_animal = m.animal_id
    WHERE a.refugio_id = p_refugio_id
      AND m.tipo_movimiento = 'salida'
      AND m.fecha_movimiento < p_fecha_ini;

    v_punto := p_fecha_ini;

    WHILE v_punto <= p_fecha_fin LOOP

    
        IF p_modo = 'semana' THEN
    
            v_etiqueta := TO_CHAR(v_punto, 'Dy DD Mon');
        ELSE
    
            v_etiqueta := CONCAT(
                'Semana ',
                CEIL(
                    EXTRACT(DAY FROM v_punto) / 7.0
                )::TEXT
            );
        END IF;

    
        SELECT COUNT(*) INTO v_entradas
        FROM movimientos m
        JOIN animales a ON a.id_animal = m.animal_id
        WHERE a.refugio_id = p_refugio_id
          AND m.tipo_movimiento = 'entrada'
          AND m.fecha_movimiento <= v_punto;

    
        SELECT COUNT(*) INTO v_adopciones
        FROM movimientos m
        JOIN animales a ON a.id_animal = m.animal_id
        WHERE a.refugio_id = p_refugio_id
          AND m.tipo_movimiento = 'salida'
          AND m.motivo = 'adopcion'
          AND m.fecha_movimiento <= v_punto;


        SELECT COUNT(*) INTO v_defunciones
        FROM movimientos m
        JOIN animales a ON a.id_animal = m.animal_id
        WHERE a.refugio_id = p_refugio_id
          AND m.tipo_movimiento = 'salida'
          AND m.motivo = 'defuncion'
          AND m.fecha_movimiento <= v_punto;

        SELECT COUNT(*) INTO v_extravios
        FROM movimientos m
        JOIN animales a ON a.id_animal = m.animal_id
        WHERE a.refugio_id = p_refugio_id
          AND m.tipo_movimiento = 'salida'
          AND m.motivo = 'extravio'
          AND m.fecha_movimiento <= v_punto;

        v_ocupacion := v_entradas - v_adopciones - v_defunciones - v_extravios;

        RETURN QUERY SELECT
            v_etiqueta,
            v_punto,
            v_ocupacion,
            v_entradas,
            v_adopciones,
            v_defunciones,
            v_extravios;

        v_punto := v_punto + v_intervalo;

    END LOOP;

END;
$$;


