
-- Consulta 1: get_adoption_profile_global
-- Jusficación
-- Esta consulta te da un perfil global de adopción usando el histórico total de la base de datos.
-- Primero toma información de "animales", "movimientos" y "refugios" para construir indicadores
-- de edad, sexo, tamaño, discapacidad, agresividad y enfermedad no tratable,
-- luego compara lo histórico adoptado contra los animales actualmente activos,
-- y con eso devuelve prioridades de decisión (Alto, Medio o Bajo) para liberar espacios.
--
-- Si hay historial suficiente, el resultado refleja comportamiento real de adopción.
-- Si no hay historial suficiente, aplica reglas predefinidas para no dejar al rescatista sin guía.
-- Esto sirve para la hipótesis porque entrega estadísticas por edad y sexo que ayudan a prever
-- liberación de espacios y decidir si se pueden recibir más animales con base en registros históricos.

CREATE OR REPLACE FUNCTION get_adoption_profile_global()
RETURNS TABLE (
    datos        TEXT,
    historico    TEXT,
    actual       TEXT,
    resultado    TEXT
)
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
    WHERE estado IN ('adopcion', 'recuperacion')
      AND edad < 12;

    SELECT COUNT(*) INTO v_activos_adultos
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND edad >= 12;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_cachorros
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad < 12
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_adultos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad >= 12
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
    SELECT a.sexo::TEXT
    INTO v_sexo_moda
    FROM animales a
    JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida'
    GROUP BY a.sexo
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT COUNT(*) INTO v_activos_machos
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND sexo = 'Macho';

    SELECT COUNT(*) INTO v_activos_hembras
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND sexo = 'Hembra';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_machos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.sexo = 'Macho'
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_hembras
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.sexo = 'Hembra'
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
    WHERE a.estado = 'adoptado'
      AND m.motivo = 'adopcion'
      AND m.tipo_movimiento = 'salida'
    GROUP BY a.tamano
    ORDER BY COUNT(*) DESC
    LIMIT 1;

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
    WHERE a.tamano IN ('miniatura','pequeño','mediano')
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_grande_tam
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.tamano IN ('grande','gigante')
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
                 AND v_activos_pref_tam <  v_activos_grande_tam  THEN 'Medio'
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
    WHERE estado IN ('adopcion', 'recuperacion')
      AND discapacidad = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.discapacidad = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_discap
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.discapacidad = FALSE
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
                WHEN v_activos_discap = 0                                                 THEN 'Alto'
                WHEN (v_adoptados_discap::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2  THEN 'Bajo'
                ELSE                                                                           'Medio'
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
    WHERE estado IN ('adopcion', 'recuperacion')
      AND es_agresivo = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.es_agresivo = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_agresivo
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.es_agresivo = FALSE
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
                WHEN v_activos_agresivo = 0                                                  THEN 'Alto'
                WHEN (v_adoptados_agresivo::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.2   THEN 'Bajo'
                ELSE                                                                              'Medio'
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
    WHERE estado IN ('adopcion', 'recuperacion')
      AND enfermedad_no_tratable = TRUE;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.enfermedad_no_tratable = TRUE
      AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_sin_enferm
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.enfermedad_no_tratable = FALSE
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
                WHEN v_activos_enferm = 0                                                  THEN 'Alto'
                WHEN (v_adoptados_enferm::NUMERIC / NULLIF(v_total_adoptados, 0)) < 0.1   THEN 'Bajo'
                ELSE                                                                            'Medio'
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




-- Consulta 2: get_movimientos_grafica_global
-- Jusficación
-- Esta consulta te da la evolución temporal de ocupación para cada refugio.
-- Primero cruza "movimientos" con "animales" y agrupa por periodos de fecha,
-- luego acumula entradas, adopciones, defunciones y extravíos,
-- y con eso calcula la ocupación estimada en cada punto del tiempo.
--
-- Si se usa modo semana, permite seguimiento fino día a día.
-- Si se usa modo mes, permite ver tendencia y comportamiento general por semanas.
-- Esto sirve para la hipótesis porque convierte los registros históricos en indicadores claros
-- para anticipar liberación de espacios y respaldar la decisión de aceptar más animales.


CREATE OR REPLACE FUNCTION get_movimientos_grafica_global(
    p_fecha_ini   TIMESTAMP,
    p_fecha_fin   TIMESTAMP,
    p_modo        TEXT        
)
RETURNS TABLE (
    refugio_id        UUID,
    nombre_refugio    TEXT,
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
    v_intervalo   INTERVAL;

    r_refugio     RECORD;
    v_punto       TIMESTAMP;
    v_etiqueta    TEXT;
    v_entradas    INT;
    v_adopciones  INT;
    v_defunciones INT;
    v_extravios   INT;
    v_ocupacion   INT;
BEGIN

    IF p_modo NOT IN ('semana', 'mes') THEN
        RAISE EXCEPTION 'El modo debe ser "semana" o "mes"';
    END IF;

    IF p_modo = 'semana' THEN
        v_intervalo := INTERVAL '1 day';
    ELSE
        v_intervalo := INTERVAL '1 week';
    END IF;

    FOR r_refugio IN
        SELECT id_refugio, nombre FROM refugios ORDER BY nombre
    LOOP

        v_punto := p_fecha_ini;

        WHILE v_punto <= p_fecha_fin LOOP

            IF p_modo = 'semana' THEN
                v_etiqueta := TO_CHAR(v_punto, 'Dy DD Mon');
            ELSE
                v_etiqueta := CONCAT(
                    'Semana ',
                    CEIL(EXTRACT(DAY FROM v_punto) / 7.0)::TEXT
                );
            END IF;

            SELECT COUNT(*) INTO v_entradas
            FROM movimientos m
            JOIN animales a ON a.id_animal = m.animal_id
            WHERE a.refugio_id = r_refugio.id_refugio
              AND m.tipo_movimiento = 'entrada'
              AND m.fecha_movimiento <= v_punto;

            SELECT COUNT(*) INTO v_adopciones
            FROM movimientos m
            JOIN animales a ON a.id_animal = m.animal_id
            WHERE a.refugio_id = r_refugio.id_refugio
              AND m.tipo_movimiento = 'salida'
              AND m.motivo = 'adopcion'
              AND m.fecha_movimiento <= v_punto;

            SELECT COUNT(*) INTO v_defunciones
            FROM movimientos m
            JOIN animales a ON a.id_animal = m.animal_id
            WHERE a.refugio_id = r_refugio.id_refugio
              AND m.tipo_movimiento = 'salida'
              AND m.motivo = 'defuncion'
              AND m.fecha_movimiento <= v_punto;


            SELECT COUNT(*) INTO v_extravios
            FROM movimientos m
            JOIN animales a ON a.id_animal = m.animal_id
            WHERE a.refugio_id = r_refugio.id_refugio
              AND m.tipo_movimiento = 'salida'
              AND m.motivo = 'extravio'
              AND m.fecha_movimiento <= v_punto;

            v_ocupacion := v_entradas - v_adopciones - v_defunciones - v_extravios;

            RETURN QUERY SELECT
                r_refugio.id_refugio,
                r_refugio.nombre::TEXT,
                v_etiqueta,
                v_punto,
                v_ocupacion,
                v_entradas,
                v_adopciones,
                v_defunciones,
                v_extravios;

            v_punto := v_punto + v_intervalo;

        END LOOP;

    END LOOP;

END;
$$;



-- Jusficación
-- Esta consulta te muestra cómo cambia el tiempo de estancia según la cantidad de indicadores de riesgo.
-- Primero usa "animales" y "movimientos" para calcular días entre entrada y salida de cada egreso,
-- luego agrupa por número de indicadores presentes (enfermedad no tratable, agresividad y discapacidad),
-- y con eso obtiene promedio, mínimo y máximo de días por nivel de complejidad.
--
-- Si el promedio sube cuando aumentan indicadores, confirma que los casos complejos ocupan espacio más tiempo.
-- Si no sube, la hipótesis debe revisarse con más datos o ajustes de segmentación.
-- Esto aporta a la hipótesis porque permite relacionar condiciones del animal con la liberación de espacios,
-- dando evidencia útil para decidir capacidad de recepción en el refugio.

SELECT
    (CASE WHEN a.enfermedad_no_tratable = TRUE THEN 1 ELSE 0 END +
     CASE WHEN a.es_agresivo = TRUE THEN 1 ELSE 0 END +
     CASE WHEN a.discapacidad = TRUE THEN 1 ELSE 0 END) AS num_indicadores,
    COUNT(*) AS total_egresados,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento)) / 86400
    )::numeric, 1) AS promedio_dias,
    ROUND(MIN(
        EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento)) / 86400
    )::numeric, 1) AS min_dias,
    ROUND(MAX(
        EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento)) / 86400
    )::numeric, 1) AS max_dias
FROM animales a
JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal
    AND m_ent.tipo_movimiento = 'entrada'
JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal
    AND m_sal.tipo_movimiento = 'salida'
WHERE a.estado IN ('adoptado', 'defuncion', 'extraviado')
GROUP BY num_indicadores
ORDER BY num_indicadores ASC;


-- Jusficación
-- Esta consulta te da un resumen estadístico detallado por cada indicador del refugio.
-- Primero cruza "animales" y "movimientos" para calcular días de estancia en egresos,
-- luego separa resultados por condición (enfermedad, agresividad, discapacidad),
-- por sexo, por tamaño y por rangos de edad,
-- y con eso muestra total de casos, promedio, dispersión, mínimos, máximos y variabilidad.
--
-- Esto aporta a la hipótesis porque convierte registros históricos en indicadores claros,
-- especialmente por edad y sexo, para anticipar capacidad disponible y apoyar la decisión de recibir más animales.

SELECT indicador, total, promedio_dias, desviacion_std, min_dias, max_dias, coef_variacion_pct
FROM (


  SELECT 'Enf. no tratable' AS indicador,
    COUNT(*) FILTER (WHERE a.enfermedad_no_tratable = TRUE) AS total,
    ROUND(AVG(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE)::numeric,1) AS promedio_dias,
    ROUND(STDDEV(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE)::numeric,1) AS desviacion_std,
    ROUND(MIN(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE)::numeric,1) AS min_dias,
    ROUND(MAX(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE)::numeric,1) AS max_dias,
    ROUND((STDDEV(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE) /
      NULLIF(AVG(dias) FILTER (WHERE a.enfermedad_no_tratable = TRUE),0)*100)::numeric,1) AS coef_variacion_pct
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (
    SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias
  ) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Agresivo',
    COUNT(*) FILTER (WHERE a.es_agresivo = TRUE),
    ROUND(AVG(dias) FILTER (WHERE a.es_agresivo = TRUE)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.es_agresivo = TRUE)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.es_agresivo = TRUE)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.es_agresivo = TRUE)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.es_agresivo = TRUE)/NULLIF(AVG(dias) FILTER (WHERE a.es_agresivo = TRUE),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Discapacidad',
    COUNT(*) FILTER (WHERE a.discapacidad = TRUE),
    ROUND(AVG(dias) FILTER (WHERE a.discapacidad = TRUE)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.discapacidad = TRUE)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.discapacidad = TRUE)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.discapacidad = TRUE)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.discapacidad = TRUE)/NULLIF(AVG(dias) FILTER (WHERE a.discapacidad = TRUE),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Sexo: Macho',
    COUNT(*) FILTER (WHERE a.sexo = 'Macho'),
    ROUND(AVG(dias) FILTER (WHERE a.sexo = 'Macho')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.sexo = 'Macho')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.sexo = 'Macho')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.sexo = 'Macho')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.sexo = 'Macho')/NULLIF(AVG(dias) FILTER (WHERE a.sexo = 'Macho'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Sexo: Hembra',
    COUNT(*) FILTER (WHERE a.sexo = 'Hembra'),
    ROUND(AVG(dias) FILTER (WHERE a.sexo = 'Hembra')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.sexo = 'Hembra')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.sexo = 'Hembra')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.sexo = 'Hembra')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.sexo = 'Hembra')/NULLIF(AVG(dias) FILTER (WHERE a.sexo = 'Hembra'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  -- Tamaño
  UNION ALL SELECT 'Tamaño: miniatura',
    COUNT(*) FILTER (WHERE a.tamano = 'miniatura'),
    ROUND(AVG(dias) FILTER (WHERE a.tamano = 'miniatura')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.tamano = 'miniatura')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.tamano = 'miniatura')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.tamano = 'miniatura')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.tamano = 'miniatura')/NULLIF(AVG(dias) FILTER (WHERE a.tamano = 'miniatura'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Tamaño: pequeño',
    COUNT(*) FILTER (WHERE a.tamano = 'pequeño'),
    ROUND(AVG(dias) FILTER (WHERE a.tamano = 'pequeño')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.tamano = 'pequeño')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.tamano = 'pequeño')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.tamano = 'pequeño')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.tamano = 'pequeño')/NULLIF(AVG(dias) FILTER (WHERE a.tamano = 'pequeño'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Tamaño: mediano',
    COUNT(*) FILTER (WHERE a.tamano = 'mediano'),
    ROUND(AVG(dias) FILTER (WHERE a.tamano = 'mediano')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.tamano = 'mediano')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.tamano = 'mediano')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.tamano = 'mediano')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.tamano = 'mediano')/NULLIF(AVG(dias) FILTER (WHERE a.tamano = 'mediano'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Tamaño: grande',
    COUNT(*) FILTER (WHERE a.tamano = 'grande'),
    ROUND(AVG(dias) FILTER (WHERE a.tamano = 'grande')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.tamano = 'grande')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.tamano = 'grande')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.tamano = 'grande')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.tamano = 'grande')/NULLIF(AVG(dias) FILTER (WHERE a.tamano = 'grande'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Tamaño: gigante',
    COUNT(*) FILTER (WHERE a.tamano = 'gigante'),
    ROUND(AVG(dias) FILTER (WHERE a.tamano = 'gigante')::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.tamano = 'gigante')::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.tamano = 'gigante')::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.tamano = 'gigante')::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.tamano = 'gigante')/NULLIF(AVG(dias) FILTER (WHERE a.tamano = 'gigante'),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Edad: cachorro (< 1 año)',
    COUNT(*) FILTER (WHERE a.edad < 1),
    ROUND(AVG(dias) FILTER (WHERE a.edad < 1)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.edad < 1)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.edad < 1)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.edad < 1)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.edad < 1)/NULLIF(AVG(dias) FILTER (WHERE a.edad < 1),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Edad: joven (1–3 años)',
    COUNT(*) FILTER (WHERE a.edad BETWEEN 1 AND 3),
    ROUND(AVG(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3)/NULLIF(AVG(dias) FILTER (WHERE a.edad BETWEEN 1 AND 3),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Edad: adulto (4–7 años)',
    COUNT(*) FILTER (WHERE a.edad BETWEEN 4 AND 7),
    ROUND(AVG(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7)/NULLIF(AVG(dias) FILTER (WHERE a.edad BETWEEN 4 AND 7),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Edad: senior (> 7 años)',
    COUNT(*) FILTER (WHERE a.edad > 7),
    ROUND(AVG(dias) FILTER (WHERE a.edad > 7)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.edad > 7)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.edad > 7)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.edad > 7)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.edad > 7)/NULLIF(AVG(dias) FILTER (WHERE a.edad > 7),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

  UNION ALL SELECT 'Sin ningún indicador',
    COUNT(*) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE),
    ROUND(AVG(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE)::numeric,1),
    ROUND(STDDEV(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE)::numeric,1),
    ROUND(MIN(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE)::numeric,1),
    ROUND(MAX(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE)::numeric,1),
    ROUND((STDDEV(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE)/
      NULLIF(AVG(dias) FILTER (WHERE a.enfermedad_no_tratable = FALSE AND a.es_agresivo = FALSE AND a.discapacidad = FALSE),0)*100)::numeric,1)
  FROM animales a
  JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal AND m_ent.tipo_movimiento = 'entrada' AND m_ent.motivo = 'rescate'
  JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal AND m_sal.tipo_movimiento = 'salida'
  CROSS JOIN LATERAL (SELECT EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento))/86400 AS dias) d
  WHERE a.estado IN ('adoptado','defuncion','extraviado')

) sub
ORDER BY promedio_dias DESC;


-- Jusficación
-- Esta consulta evalúa la precisión del modelo de estimación de estancia a nivel de perfil animal.
-- Primero toma animales con entrada y salida y calcula su estancia real en días,
-- luego compara ese valor contra una estancia estimada basada en edad, sexo, tamaño y condiciones clínicas,
-- y con eso calcula error promedio, error porcentual y una etiqueta de precisión.
--
-- Esto se alinea con la hipótesis porque prueba si los indicadores por edad y sexo realmente
-- ayudan al rescatista a decidir, con base en evidencia histórica del refugio.

WITH estadias AS (
    SELECT
        a.id_animal,
        a.nombre,
        a.especie,
        a.sexo,
        a.tamano,
        a.edad,
        a.es_agresivo,
        a.discapacidad,
        a.enfermedad_no_tratable,
        ROUND(
            EXTRACT(EPOCH FROM (m_sal.fecha_movimiento - m_ent.fecha_movimiento)) / 86400
        )::integer AS dias_real,
        CASE
            WHEN a.enfermedad_no_tratable = TRUE AND a.edad > 12  THEN 174
            WHEN a.enfermedad_no_tratable = TRUE AND a.edad <= 12 THEN 155
            WHEN a.es_agresivo = TRUE AND a.edad > 12             THEN 130
            WHEN a.es_agresivo = TRUE AND a.edad <= 12            THEN 97
            WHEN a.discapacidad = TRUE AND a.edad > 12            THEN 110
            WHEN a.discapacidad = TRUE AND a.edad <= 12           THEN 80
            WHEN a.edad > 12                                      THEN 65
            ELSE                                                       19
        END AS dias_estimado,
        CASE
            WHEN a.edad <= 12 THEN 'Menor o igual a 1 año'
            ELSE                   'Mayor a 1 año'
        END AS rango_edad
    FROM animales a
    JOIN movimientos m_ent ON m_ent.animal_id = a.id_animal
        AND m_ent.tipo_movimiento = 'entrada'
        AND m_ent.motivo = 'rescate'
    JOIN movimientos m_sal ON m_sal.animal_id = a.id_animal
        AND m_sal.tipo_movimiento = 'salida'
    WHERE a.estado IN ('adoptado', 'defuncion', 'extraviado')
)
SELECT
    especie,
    sexo,
    tamano,
    edad,
    rango_edad,
    es_agresivo,
    discapacidad,
    enfermedad_no_tratable,
    COUNT(*)                                                          AS total_animales,
    ROUND(AVG(dias_real), 1)                                          AS promedio_real,
    ROUND(AVG(dias_estimado), 1)                                      AS promedio_estimado,
    ROUND(AVG(ABS(dias_real - dias_estimado)), 1)                     AS error_promedio_dias,
    ROUND(
        AVG(ABS(dias_real - dias_estimado)) /
        NULLIF(AVG(dias_real), 0) * 100
    , 1)                                                              AS error_porcentual,
    CASE
        WHEN AVG(ABS(dias_real - dias_estimado)) /
             NULLIF(AVG(dias_real), 0) * 100 <= 20 THEN 'Muy precisa'
        WHEN AVG(ABS(dias_real - dias_estimado)) /
             NULLIF(AVG(dias_real), 0) * 100 <= 40 THEN 'Aceptable'
        ELSE                                            'Mejorable'
    END AS precision_modelo
FROM estadias
GROUP BY especie, sexo, tamano, edad, rango_edad,
         es_agresivo, discapacidad, enfermedad_no_tratable
ORDER BY error_porcentual ASC;

