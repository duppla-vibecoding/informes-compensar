-- ============================================================
-- 02 · Competidores en radio 2 km
-- ============================================================
-- Usa ST_DISTANCE de BigQuery para encontrar todos los proyectos
-- a 2 km de Saviia, con sus métricas de inventario, ritmo y rotación.
-- Filtro temporal: solo proyectos con venta en último año.

WITH saviia AS (
  SELECT latitud AS lat0, longitud AS lng0
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva`
  WHERE codproyecto = 500465
)
SELECT
  c.codproyecto,
  c.proyecto,
  c.vendedor,
  c.vis_novis,
  c.estado_proyecto,
  c.inventario_inicial,
  c.unidades_vendidas,
  c.unidades_disponibles,
  ROUND(c.precio_m2_promedio_proyecto) AS precio_m2,
  ROUND(ST_DISTANCE(
    ST_GEOGPOINT(c.longitud, c.latitud),
    ST_GEOGPOINT(s.lng0, s.lat0)
  )) AS dist_metros,
  c.fecha_inicio_ventas,
  c.fecha_ultima_venta_proyecto,
  DATE_DIFF(c.fecha_ultima_venta_proyecto, c.fecha_inicio_ventas, MONTH) + 1 AS meses_activos,
  -- Velocidad mensual de ventas
  ROUND(SAFE_DIVIDE(
    c.unidades_vendidas,
    DATE_DIFF(c.fecha_ultima_venta_proyecto, c.fecha_inicio_ventas, MONTH) + 1
  ), 2) AS ritmo_mes,
  -- Rotación: meses para agotar inventario al ritmo actual
  ROUND(SAFE_DIVIDE(
    c.unidades_disponibles,
    SAFE_DIVIDE(
      c.unidades_vendidas,
      DATE_DIFF(c.fecha_ultima_venta_proyecto, c.fecha_inicio_ventas, MONTH) + 1
    )
  ), 2) AS rotacion_meses
FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva` c, saviia s
WHERE ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0)) <= 2000
  AND c.fecha_ultima_venta_proyecto >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
ORDER BY dist_metros;
-- → 21 proyectos (incluye Saviia): 9 VIS · 12 No-VIS
