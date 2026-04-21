-- ============================================================
-- 04 · Resumen agregado VIS vs No-VIS · Sección 5 (rotación)
-- ============================================================
-- Métricas agregadas por categoría (VIS vs No-VIS) de los proyectos
-- competidores en 2 km: inventario, ventas, precio promedio, ritmo
-- y rotación (meses para agotar inventario).

WITH saviia AS (
  SELECT latitud AS lat0, longitud AS lng0
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva`
  WHERE codproyecto = 500465
),
proys_2km AS (
  SELECT c.*
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva` c, saviia s
  WHERE ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0)) <= 2000
    AND c.fecha_ultima_venta_proyecto >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
)
SELECT
  vis_novis,
  COUNT(*) AS num_proyectos,
  SUM(inventario_inicial) AS inventario_total,
  SUM(unidades_vendidas) AS vendidas_total,
  SUM(unidades_disponibles) AS disponibles_total,
  ROUND(AVG(precio_m2_promedio_proyecto)) AS precio_m2_avg,
  ROUND(AVG(SAFE_DIVIDE(
    unidades_vendidas,
    DATE_DIFF(fecha_ultima_venta_proyecto, fecha_inicio_ventas, MONTH) + 1
  )), 2) AS ritmo_mes_avg,
  ROUND(AVG(SAFE_DIVIDE(
    unidades_disponibles,
    SAFE_DIVIDE(unidades_vendidas, DATE_DIFF(fecha_ultima_venta_proyecto, fecha_inicio_ventas, MONTH) + 1)
  )), 2) AS rotacion_meses_avg
FROM proys_2km
GROUP BY vis_novis
ORDER BY vis_novis;

-- Resultado:
-- VIS    · 9 proys  · 6,389 inv · 2,578 disp · $4,313,039 avg · 13.6 u/mes · 45.4 m rotación
-- No VIS · 12 proys · 4,893 inv · 1,487 disp · $4,765,083 avg · 6.6 u/mes  · 34.6 m rotación
-- Saviia · 1 proy   · 418 inv   · 143 disp   · $5,955,259      · 5.5 u/mes · 26.0 m rotación
