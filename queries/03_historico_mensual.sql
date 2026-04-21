-- ============================================================
-- 03 · Histórico mensual de precio y ventas
-- ============================================================
-- Una fila por proyecto × tipología × mes con precio m² y ventas.
-- Se usa para calcular promedios ponderados mensuales por segmento
-- (Saviia, No-VIS zona, VIS zona).

-- 3.1 · Solo Saviia
SELECT
  area,
  FORMAT_DATE('%Y-%m-%d', DATE(PARSE_DATE('%Y/%m/%d', variable))) AS mes,
  ROUND(preciom2) AS precio_m2,
  numventas AS unidades_vendidas
FROM `complete-verve-362421.lgi.bogota_def_Def_12-25_trends`
WHERE codproyecto = 500465
ORDER BY mes ASC, area ASC;
-- → 111 filas (mes × tipología activa)

-- 3.2 · Histórico de TODOS los proyectos en 2 km (Saviia + 20 competidores)
WITH saviia AS (
  SELECT latitud AS lat0, longitud AS lng0
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva`
  WHERE codproyecto = 500465
),
proys_2km AS (
  SELECT c.codproyecto, c.proyecto, c.vis_novis,
    ROUND(ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0))) AS dist_m
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva` c, saviia s
  WHERE ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0)) <= 2000
    AND c.fecha_ultima_venta_proyecto >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
)
SELECT
  p.codproyecto, p.proyecto, p.vis_novis, p.dist_m,
  FORMAT_DATE('%Y-%m-%d', DATE(PARSE_DATE('%Y/%m/%d', t.variable))) AS mes,
  t.area,
  ROUND(t.preciom2) AS precio_m2,
  t.numventas AS unidades_vendidas
FROM proys_2km p
JOIN `complete-verve-362421.lgi.bogota_def_Def_12-25_trends` t USING(codproyecto)
ORDER BY p.proyecto, mes, t.area;
-- → 1420 filas (después se agregan en Python por mes × segmento)

-- 3.3 · Promedio mensual ponderado agrupado por segmento (Saviia / VIS / No-VIS)
-- Esta query devuelve directamente lo que muestra la sección 3 del informe.
WITH saviia AS (
  SELECT latitud AS lat0, longitud AS lng0
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva`
  WHERE codproyecto = 500465
),
proys_2km AS (
  SELECT c.codproyecto, c.vis_novis
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva` c, saviia s
  WHERE ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0)) <= 2000
    AND c.fecha_ultima_venta_proyecto >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
),
trends_zona AS (
  SELECT
    p.codproyecto,
    CASE
      WHEN p.codproyecto = 500465 THEN 'Saviia'
      WHEN p.vis_novis = 'Vis' THEN 'VIS_zona'
      ELSE 'NoVIS_zona'
    END AS segmento,
    DATE(PARSE_DATE('%Y/%m/%d', t.variable)) AS mes,
    t.preciom2,
    t.numventas
  FROM proys_2km p
  JOIN `complete-verve-362421.lgi.bogota_def_Def_12-25_trends` t USING(codproyecto)
)
SELECT
  segmento,
  mes,
  ROUND(SUM(preciom2 * numventas) / NULLIF(SUM(numventas), 0)) AS precio_m2_ponderado,
  SUM(numventas) AS unidades_totales
FROM trends_zona
GROUP BY segmento, mes
ORDER BY mes, segmento;
