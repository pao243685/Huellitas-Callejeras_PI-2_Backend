-- Fix: use age range mode for global adoption profile

CREATE OR REPLACE FUNCTION get_adoption_profile_global()
RETURNS TABLE (datos TEXT, historico TEXT, actual TEXT, resultado TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad_total        INT;
    v_min_historial          INT;
    v_total_adoptados        INT;

    v_rango_moda_edad        TEXT;
    v_activos_cachorros      INT;
    v_activos_jovenes        INT;
    v_activos_adultos        INT;
    v_adoptados_cachorros    INT;
    v_adoptados_jovenes      INT;
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

    SELECT COUNT(*) INTO v_activos_cachorros
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND edad < 12;

    SELECT COUNT(*) INTO v_activos_jovenes
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND edad BETWEEN 12 AND 36;

    SELECT COUNT(*) INTO v_activos_adultos
    FROM animales
    WHERE estado IN ('adopcion', 'recuperacion')
      AND edad > 36;

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_cachorros
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad < 12 AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_jovenes
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad BETWEEN 12 AND 36 AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    SELECT COUNT(DISTINCT a.id_animal) INTO v_adoptados_adultos
    FROM animales a JOIN movimientos m ON m.animal_id = a.id_animal
    WHERE a.edad > 36 AND a.estado = 'adoptado'
      AND m.motivo = 'adopcion' AND m.tipo_movimiento = 'salida';

    WITH rango_moda AS (
        SELECT 'cachorro' AS rango, v_adoptados_cachorros AS total
        UNION ALL SELECT 'joven', v_adoptados_jovenes
        UNION ALL SELECT 'adulto', v_adoptados_adultos
    )
    SELECT rango INTO v_rango_moda_edad
    FROM rango_moda
    ORDER BY total DESC
    LIMIT 1;

    IF v_total_adoptados >= v_min_historial THEN
        RETURN QUERY SELECT
            'Edad'::TEXT,
            FORMAT('Moda: %s (cachorro:<12m, joven:12-36m, adulto:>36m) - Adoptados: C:%s, J:%s, A:%s',
                   v_rango_moda_edad, v_adoptados_cachorros, v_adoptados_jovenes, v_adoptados_adultos),
            FORMAT('Cachorros(<12m): %s, Jóvenes(12-36m): %s, Adultos(>36m): %s',
                   v_activos_cachorros, v_activos_jovenes, v_activos_adultos),
            CASE
                WHEN v_rango_moda_edad = 'cachorro'
                 AND v_activos_cachorros >= GREATEST(v_activos_jovenes, v_activos_adultos) THEN 'Alto'
                WHEN v_rango_moda_edad = 'joven'
                 AND v_activos_jovenes >= GREATEST(v_activos_cachorros, v_activos_adultos) THEN 'Alto'
                WHEN v_rango_moda_edad = 'adulto'
                 AND v_activos_adultos >= GREATEST(v_activos_cachorros, v_activos_jovenes) THEN 'Alto'
                WHEN (v_rango_moda_edad = 'cachorro' AND v_activos_cachorros = v_activos_jovenes)
                  OR (v_rango_moda_edad = 'joven' AND v_activos_jovenes = v_activos_adultos)
                  OR (v_rango_moda_edad = 'adulto' AND v_activos_adultos = v_activos_cachorros) THEN 'Medio'
                ELSE 'Bajo'
            END;
    ELSE
        RETURN QUERY SELECT
            'Edad'::TEXT,
            FORMAT('Sin historial suficiente (predefinido: priorizar cachorros <12 meses)'),
            FORMAT('Cachorros(<12m): %s, Jóvenes(12-36m): %s, Adultos(>36m): %s',
                   v_activos_cachorros, v_activos_jovenes, v_activos_adultos),
            CASE
                WHEN v_activos_cachorros > v_activos_jovenes AND v_activos_cachorros > v_activos_adultos THEN 'Alto'
                WHEN v_activos_cachorros = v_activos_jovenes OR v_activos_cachorros = v_activos_adultos THEN 'Medio'
                ELSE 'Bajo'
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
