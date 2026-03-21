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
