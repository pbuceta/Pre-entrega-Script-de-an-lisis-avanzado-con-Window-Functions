/* ============================================================================
   PRE-ENTREGA: SCRIPT DE ANÁLISIS AVANZADO CON WINDOW FUNCTIONS
   Archivo: preentrega_analisis_avanzado.sql
   Motor de Base de Datos: PostgreSQL
   ============================================================================ */

-- 1. PRIMERA CTE: Normalización temporal y agregación de ventas por mes y categoría
WITH ventas_mensuales AS (
    SELECT 
        DATE_TRUNC('month', v.fecha_venta)::DATE AS mes,
        cat.nombre_categoria AS categoria,
        SUM(v.cantidad * p.precio) AS venta_total
    FROM ventas AS v
    INNER JOIN productos AS p 
        ON v.id_producto = p.id_producto
    INNER JOIN categorias AS cat 
        ON p.id_categoria = cat.id_categoria
    GROUP BY DATE_TRUNC('month', v.fecha_venta), cat.nombre_categoria
),

-- 2. SEGUNDA CTE: Cálculo de métricas avanzadas con Window Functions
metricas_ventana AS (
    SELECT 
        mes,
        categoria,
        venta_total,
        -- Ranking de categorías por nivel de ventas dentro de cada mes
        RANK() OVER (
            PARTITION BY mes 
            ORDER BY venta_total DESC
        ) AS ranking_mensual,
        -- Acumulado progresivo (Running Total) de ventas por categoría a lo largo del tiempo
        SUM(venta_total) OVER (
            PARTITION BY categoria 
            ORDER BY mes 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS venta_acumulada
    FROM ventas_mensuales
)

-- 3. CONSULTA PRINCIPAL: Lógica de negocio comparando contra el promedio histórico
SELECT 
    mes,
    categoria,
    venta_total,
    ranking_mensual,
    venta_acumulada,
    -- Comparación del mes actual contra el promedio histórico de la categoría
    CASE 
        WHEN venta_total >= AVG(venta_total) OVER (PARTITION BY categoria) 
            THEN 'Exitoso'
        ELSE 'Bajo el promedio'
    END AS desempeño_categoria
FROM metricas_ventana
ORDER BY mes ASC, ranking_mensual ASC;