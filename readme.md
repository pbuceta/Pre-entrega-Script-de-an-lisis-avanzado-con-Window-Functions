# Pre-entrega: Análisis Avanzado con Window Functions y CTEs

Este proyecto contiene la solución a la pre-entrega de análisis avanzado de ventas, donde se integran **Common Table Expressions (CTEs)**, **Funciones de Ventana (Window Functions)** y **Lógica Condicional (`CASE WHEN`)** sobre una base de datos **PostgreSQL**.

---

## 📌 Propósito del Proyecto

El objetivo principal de este desarrollo es construir un reporte de rendimiento comercial categorizado a nivel mensual. Mediante la combinación de CTEs y funciones analíticas de ventana, se logra resolver un problema de negocio complejo en tres etapas claras:

1. **Normalización y Agregación**: Consolidación de ventas por mes y categoría de producto.
2. **Cálculo de Métricas Analíticas**: Generación de rankings mensuales y totales acumulados (*Running Totals*).
3. **Clasificación de Desempeño**: Comparación del comportamiento mensual frente al promedio histórico por categoría.

---

## 📁 Estructura del Repositorio

```text
├── modulo_4/
│   └── pre-entrega-modulo4.sql
└── modulo_5/
    ├── preentrega_analisis_avanzado.sql   # Script principal de la entrega
    └── README.md                           # Documentación técnica
```

---

## 🛠️ Requisitos e Instalación

### Base de Datos Requerida
El script se ejecuta sobre la base de datos `entrega_4` en PostgreSQL, asegurando la existencia de las siguientes tablas relacionales:
* `categorias` (`id_categoria`, `nombre_categoria`)
* `productos` (`id_producto`, `nombre_producto`, `precio`, `id_categoria`)
* `ventas` (`id_venta`, `id_cliente`, `id_producto`, `cantidad`, `fecha_venta`)

---

## 💻 Código de la Consulta (`preentrega_analisis_avanzado.sql`)

```sql
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
```

---

## 🔍 Explicación Técnica de la Solución

### 1. CTE `ventas_mensuales`
* **Normalización Temporal**: Utiliza `DATE_TRUNC('month', v.fecha_venta)` para unificar cualquier día del mes al primer día del período correspondientes (`YYYY-MM-01`).
* **Métrica Base**: Multiplica `cantidad * precio` dentro de un `SUM()` para obtener el ingreso bruto por mes y categoría.

### 2. CTE `metricas_ventana`
* **`RANK() OVER (PARTITION BY mes ORDER BY venta_total DESC)`**: Reinicia el ranking en cada mes para ordenar las categorías de mayor a menor facturación.
* **`SUM(venta_total) OVER (PARTITION BY categoria ORDER BY mes)`**: Calcula el *Running Total*. La cláusula `ORDER BY mes` dentro del `OVER` asegura que la suma sea progresiva a lo largo de los meses y no un total estático.

### 3. Consulta Principal (`CASE WHEN`)
* **`AVG(venta_total) OVER (PARTITION BY categoria)`**: Calcula dinámicamente el promedio mensual de cada categoría.
* **Evaluación Condicional**: Retorna exactamente `'Exitoso'` si la venta del mes alcanza o supera el promedio, o `'Bajo el promedio'` en caso contrario, cumpliendo al 100% las especificaciones de negocio.

---

## 📊 Ejemplo de Resultados

| mes | categoria | venta_total | ranking_mensual | venta_acumulada | desempeño_categoria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **2026-01-01** | Perifericos | 300.00 | 1 | 300.00 | Bajo el promedio |
| **2026-02-01** | Tecnologia | 8000.00 | 1 | 8000.00 | Exitoso |
| **2026-02-01** | Perifericos | 500.00 | 2 | 800.00 | Exitoso |
| **2026-03-01** | Mobiliario | 250.00 | 1 | 250.00 | Exitoso |
| **2026-03-01** | Perifericos | 200.00 | 2 | 1000.00 | Bajo el promedio |

---

## ✅ Cumplimiento de Rúbrica

* **Nombres de CTEs requeridos**: `ventas_mensuales` y `metricas_ventana`.
* **Etiquetas de salida exactas**: `'Exitoso'` y `'Bajo el promedio'`.
* **Uso de Window Functions**: `RANK()`, `SUM() OVER(...)` y `AVG() OVER(...)`.
* **Sintaxis y Estilo**: Código limpio, indentado y documentado en PostgreSQL.