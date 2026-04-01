-- Fix: recrear vistas usando refugio_id (UUID) en lugar de nombre
DROP VIEW IF EXISTS vw_alertas_movimientos_no_adopcion CASCADE;
DROP VIEW IF EXISTS vw_animales_activos CASCADE;
DROP VIEW IF EXISTS vw_resumen_adoptabilidad CASCADE;

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
            a.id_animal, a.especie, a.sexo, a.tamano, a.edad,
            a.enfermedad_no_tratable, a.discapacidad, a.es_agresivo, a.refugio_id
        FROM animales a
        JOIN ultimo_ingreso ui ON ui.animal_id = a.id_animal
        WHERE NOT EXISTS (
            SELECT 1 FROM movimientos sal
            WHERE sal.animal_id = a.id_animal
            AND sal.tipo_movimiento = 'salida'
            AND sal.fecha_movimiento > ui.fecha_entrada
        )
    ),
    adoptados AS (
        SELECT a.id_animal, a.refugio_id, a.sexo, a.tamano, a.edad,
               a.discapacidad, a.es_agresivo, a.enfermedad_no_tratable
        FROM animales a
        JOIN movimientos m ON m.animal_id = a.id_animal
        WHERE a.estado = 'adoptado'
        AND m.tipo_movimiento = 'salida'
        AND m.motivo = 'adopcion'
    ),
    perfil_refugio AS (
        SELECT
            ad.refugio_id,
            COUNT(*) AS total_adoptados,
            CEIL(MAX(r.capacidad_max) * 1.5) AS min_historial,
            ROUND(AVG(ad.edad), 1) AS edad_prom_adoptados,
            MODE() WITHIN GROUP (ORDER BY ad.sexo) AS sexo_mas_adoptado,
            MODE() WITHIN GROUP (ORDER BY ad.tamano) AS tamano_mas_adoptado,
            AVG(CASE WHEN ad.discapacidad THEN 1.0 ELSE 0 END) AS tasa_discap,
            AVG(CASE WHEN ad.es_agresivo THEN 1.0 ELSE 0 END) AS tasa_agresivo,
            AVG(CASE WHEN ad.enfermedad_no_tratable THEN 1.0 ELSE 0 END) AS tasa_enferm
        FROM adoptados ad
        JOIN refugios r ON r.id_refugio = ad.refugio_id
        GROUP BY ad.refugio_id
    ),
    puntuacion AS (
        SELECT
            ac.id_animal, ac.especie, ac.refugio_id,
            CASE
                WHEN pr.total_adoptados IS NULL OR pr.total_adoptados < pr.min_historial THEN NULL
                ELSE (
                    CASE WHEN ABS(ac.edad - pr.edad_prom_adoptados) <= 24 THEN 1 ELSE -1 END +
                    CASE WHEN ac.sexo = pr.sexo_mas_adoptado THEN 1 ELSE -1 END +
                    CASE WHEN ac.tamano = pr.tamano_mas_adoptado THEN 1 ELSE -1 END +
                    CASE WHEN pr.tasa_discap < 0.2 AND ac.discapacidad = FALSE THEN 1
                         WHEN pr.tasa_discap < 0.2 AND ac.discapacidad = TRUE THEN -1 ELSE 0 END +
                    CASE WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = FALSE THEN 1
                         WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = TRUE THEN -1 ELSE 0 END +
                    CASE WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = FALSE THEN 1
                         WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = TRUE THEN -1 ELSE 0 END
                )
            END AS puntos
        FROM activos ac
        LEFT JOIN perfil_refugio pr ON pr.refugio_id = ac.refugio_id
    )
    SELECT
        p.refugio_id,
        CASE
            WHEN p.puntos IS NULL THEN 'Sin historial suficiente'
            WHEN p.puntos >= 4 THEN 'Fácil'
            WHEN p.puntos >= 1 THEN 'Moderada'
            ELSE 'Difícil'
        END AS nivel_adoptabilidad,
        COUNT(*) AS total_animales,
        COUNT(*) FILTER (WHERE p.especie = 'Perro') AS perros,
        COUNT(*) FILTER (WHERE p.especie = 'Gato') AS gatos,
        ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY p.refugio_id), 0), 1) AS pct_sobre_total,
        SUM(CASE WHEN p.puntos IS NULL OR p.puntos < 1 THEN 1 ELSE 0 END) AS espacios_en_riesgo
    FROM puntuacion p
    GROUP BY p.refugio_id, nivel_adoptabilidad,
        CASE WHEN p.puntos IS NULL THEN 4 WHEN p.puntos >= 4 THEN 0 WHEN p.puntos >= 1 THEN 1 ELSE 2 END
    ORDER BY p.refugio_id ASC,
        CASE WHEN p.puntos IS NULL THEN 4 WHEN p.puntos >= 4 THEN 0 WHEN p.puntos >= 1 THEN 1 ELSE 2 END ASC;

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
            a.id_animal, a.nombre, a.especie, a.sexo, a.tamano, a.edad,
            a.enfermedad_no_tratable, a.discapacidad, a.es_agresivo, a.estado, a.refugio_id,
            EXTRACT(DAY FROM (NOW() - ui.fecha_entrada))::INT AS dias_en_refugio,
            ui.fecha_entrada::DATE AS fecha_ingreso
        FROM animales a
        JOIN ultimo_ingreso ui ON ui.animal_id = a.id_animal
        WHERE NOT EXISTS (
            SELECT 1 FROM movimientos sal
            WHERE sal.animal_id = a.id_animal
            AND sal.tipo_movimiento = 'salida'
            AND sal.fecha_movimiento > ui.fecha_entrada
        )
    ),
    adoptados AS (
        SELECT a.id_animal, a.refugio_id, a.sexo, a.tamano, a.edad,
               a.discapacidad, a.es_agresivo, a.enfermedad_no_tratable
        FROM animales a
        JOIN movimientos m ON m.animal_id = a.id_animal
        WHERE a.estado = 'adoptado'
        AND m.tipo_movimiento = 'salida'
        AND m.motivo = 'adopcion'
    ),
    perfil_refugio AS (
        SELECT
            ad.refugio_id,
            COUNT(*) AS total_adoptados,
            CEIL(MAX(r.capacidad_max) * 1.5) AS min_historial,
            ROUND(AVG(ad.edad), 1) AS edad_prom_adoptados,
            MODE() WITHIN GROUP (ORDER BY ad.sexo) AS sexo_mas_adoptado,
            MODE() WITHIN GROUP (ORDER BY ad.tamano) AS tamano_mas_adoptado,
            AVG(CASE WHEN ad.discapacidad THEN 1.0 ELSE 0 END) AS tasa_discap,
            AVG(CASE WHEN ad.es_agresivo THEN 1.0 ELSE 0 END) AS tasa_agresivo,
            AVG(CASE WHEN ad.enfermedad_no_tratable THEN 1.0 ELSE 0 END) AS tasa_enferm
        FROM adoptados ad
        JOIN refugios r ON r.id_refugio = ad.refugio_id
        GROUP BY ad.refugio_id
    ),
    puntuacion AS (
        SELECT
            ac.id_animal, ac.nombre, ac.especie, ac.sexo, ac.tamano, ac.edad,
            ac.enfermedad_no_tratable, ac.discapacidad, ac.es_agresivo, ac.estado,
            ac.refugio_id, ac.dias_en_refugio, ac.fecha_ingreso,
            pr.total_adoptados, pr.min_historial,
            CASE
                WHEN pr.total_adoptados IS NULL OR pr.total_adoptados < pr.min_historial THEN NULL
                ELSE (
                    CASE WHEN ABS(ac.edad - pr.edad_prom_adoptados) <= 24 THEN 1 ELSE -1 END +
                    CASE WHEN ac.sexo = pr.sexo_mas_adoptado THEN 1 ELSE -1 END +
                    CASE WHEN ac.tamano = pr.tamano_mas_adoptado THEN 1 ELSE -1 END +
                    CASE WHEN pr.tasa_discap < 0.2 AND ac.discapacidad = FALSE THEN 1
                         WHEN pr.tasa_discap < 0.2 AND ac.discapacidad = TRUE THEN -1 ELSE 0 END +
                    CASE WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = FALSE THEN 1
                         WHEN pr.tasa_agresivo < 0.2 AND ac.es_agresivo = TRUE THEN -1 ELSE 0 END +
                    CASE WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = FALSE THEN 1
                         WHEN pr.tasa_enferm < 0.1 AND ac.enfermedad_no_tratable = TRUE THEN -1 ELSE 0 END
                )
            END AS puntos
        FROM activos ac
        LEFT JOIN perfil_refugio pr ON pr.refugio_id = ac.refugio_id
    )
    SELECT
        p.refugio_id, p.id_animal,
        p.nombre AS animal,
        p.especie, p.sexo, p.tamano, p.edad,
        p.enfermedad_no_tratable, p.discapacidad, p.es_agresivo, p.estado,
        p.dias_en_refugio, p.fecha_ingreso,
        CASE
            WHEN p.puntos IS NULL THEN 'Sin historial suficiente'
            WHEN p.puntos >= 4 THEN 'Fácil'
            WHEN p.puntos >= 1 THEN 'Moderada'
            ELSE 'Difícil'
        END AS nivel_adoptabilidad,
        CASE WHEN p.puntos IS NULL THEN 'sin datos' ELSE 'historico' END AS nivel_confianza
    FROM puntuacion p
    ORDER BY p.refugio_id ASC, p.dias_en_refugio DESC;

CREATE OR REPLACE VIEW vw_alertas_movimientos_no_adopcion AS
    WITH conteo_entradas AS (
        SELECT animal_id,
            COUNT(*) AS total_entradas,
            MIN(fecha_movimiento) AS primera_entrada,
            MAX(fecha_movimiento) AS ultima_entrada
        FROM movimientos
        WHERE tipo_movimiento = 'entrada'
        GROUP BY animal_id
    ),
    resumen_salidas AS (
        SELECT animal_id,
            SUM(CASE WHEN motivo = 'adopcion' THEN 1 ELSE 0 END) AS salidas_adopcion,
            SUM(CASE WHEN motivo = 'defuncion' THEN 1 ELSE 0 END) AS salidas_defuncion,
            SUM(CASE WHEN motivo = 'extravio' THEN 1 ELSE 0 END) AS salidas_extravio,
            MAX(fecha_movimiento) AS ultima_salida
        FROM movimientos
        WHERE tipo_movimiento = 'salida'
        GROUP BY animal_id
    ),
    ultimo_mov AS (
        SELECT DISTINCT ON (animal_id)
            animal_id,
            tipo_movimiento AS ultimo_tipo,
            fecha_movimiento AS ultima_fecha
        FROM movimientos
        ORDER BY animal_id, fecha_movimiento DESC
    ),
    estado_actual AS (
        SELECT
            a.id_animal, a.nombre, a.especie,
            a.estado AS estado_registro,
            a.refugio_id, a.es_agresivo, a.discapacidad, a.enfermedad_no_tratable, a.edad,
            ce.primera_entrada, ce.ultima_entrada, ce.total_entradas,
            rs.ultima_salida, rs.salidas_adopcion, rs.salidas_defuncion, rs.salidas_extravio,
            um.ultimo_tipo AS ultimo_movimiento,
            CASE
                WHEN rs.salidas_adopcion >= 1
                AND ce.ultima_entrada > (
                    SELECT MAX(m_ad.fecha_movimiento) FROM movimientos m_ad
                    WHERE m_ad.animal_id = a.id_animal
                    AND m_ad.tipo_movimiento = 'salida' AND m_ad.motivo = 'adopcion'
                ) THEN TRUE ELSE FALSE
            END AS fue_devuelto,
            GREATEST(ce.total_entradas - 1, 0) AS veces_regresado,
            CASE
                WHEN um.ultimo_tipo = 'entrada'
                THEN EXTRACT(DAY FROM (NOW() - ce.ultima_entrada))::INT
                ELSE NULL
            END AS dias_estancia_actual,
            (
                (CASE WHEN a.es_agresivo THEN 2 ELSE 0 END) +
                (CASE WHEN a.discapacidad THEN 1 ELSE 0 END) +
                (CASE WHEN a.enfermedad_no_tratable THEN 2 ELSE 0 END) +
                (CASE WHEN a.edad > 84 THEN 1 ELSE 0 END) +
                (CASE WHEN rs.salidas_adopcion >= 1
                    AND ce.ultima_entrada > (
                        SELECT MAX(m2.fecha_movimiento) FROM movimientos m2
                        WHERE m2.animal_id = a.id_animal
                        AND m2.tipo_movimiento = 'salida' AND m2.motivo = 'adopcion'
                    ) THEN 3 ELSE 0 END) +
                (CASE WHEN GREATEST(ce.total_entradas - 1, 0) >= 2 THEN 2 ELSE 0 END)
            ) AS score_interno
        FROM animales a
        LEFT JOIN conteo_entradas ce ON ce.animal_id = a.id_animal
        LEFT JOIN resumen_salidas rs ON rs.animal_id = a.id_animal
        LEFT JOIN ultimo_mov um ON um.animal_id = a.id_animal
    )
    SELECT
        CASE
            WHEN ea.fue_devuelto AND ea.veces_regresado >= 2 THEN 'Reincidente: regresó 2+ veces'
            WHEN ea.fue_devuelto THEN 'Devuelto: regresó tras adopción'
            WHEN ea.salidas_defuncion >= 1 THEN 'Defunción registrada'
            WHEN ea.salidas_extravio >= 1 THEN 'Extravío registrado'
            WHEN ea.ultimo_movimiento = 'entrada' AND ea.dias_estancia_actual > 180 THEN 'Larga estancia: más de 6 meses'
            WHEN ea.ultimo_movimiento = 'entrada' AND ea.dias_estancia_actual > 90 THEN 'Estancia prolongada: más de 3 meses'
            ELSE 'Sin alertas'
        END AS tipo_alerta,
        CASE
            WHEN ea.score_interno >= 4 THEN 'Alto'
            WHEN ea.score_interno >= 2 THEN 'Medio'
            ELSE 'Bajo'
        END AS nivel_riesgo,
        ea.refugio_id, ea.id_animal,
        ea.nombre AS animal,
        ea.especie, ea.estado_registro, ea.fue_devuelto, ea.veces_regresado,
        ea.primera_entrada::DATE AS fecha_primer_ingreso,
        ea.ultima_salida::DATE AS fecha_ultima_salida
    FROM estado_actual ea
    WHERE ea.primera_entrada IS NOT NULL
    AND (
        ea.fue_devuelto = TRUE
        OR ea.salidas_defuncion > 0
        OR ea.salidas_extravio > 0
        OR (ea.ultimo_movimiento = 'entrada' AND ea.dias_estancia_actual > 90)
        OR ea.ultimo_movimiento = 'entrada'
    )
    ORDER BY ea.refugio_id ASC, ea.score_interno DESC, ea.dias_estancia_actual DESC NULLS LAST;