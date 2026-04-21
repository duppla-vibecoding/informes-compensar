-- ============================================================
-- 05 · Fair Market Price (FMP) por tipología · Sección 6
-- ============================================================
-- FMP = mediana del precio m² de tipologías comparables (±7 m² de área)
-- en los proyectos competidores en 2 km.
-- Se compara contra el precio negociado por Duppla para cada tipología.

WITH saviia AS (
  SELECT latitud AS lat0, longitud AS lng0
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva`
  WHERE codproyecto = 500465
),
proys_2km AS (
  SELECT c.codproyecto
  FROM `complete-verve-362421.eval_inmuebles.comportamiento_vivienda_nueva` c, saviia s
  WHERE ST_DISTANCE(ST_GEOGPOINT(c.longitud, c.latitud), ST_GEOGPOINT(s.lng0, s.lat0)) <= 2000
    AND c.fecha_ultima_venta_proyecto >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
    AND c.codproyecto != 500465  -- excluye Saviia
),
-- Tipologías de competencia con precio m² (precio total / área)
tipologias_zona AS (
  SELECT
    d.area,
    d.precultmes / d.area AS precio_m2
  FROM proys_2km p
  JOIN `complete-verve-362421.lgi.bogota_def_Def_12-25_detalle` d USING(codproyecto)
  WHERE d.precultmes > 0 AND d.area > 0
)
-- Para cada tipología Saviia, match con tipologías de área similar (±7 m²)
SELECT
  s.tipo_saviia,
  s.area_saviia,
  COUNT(*) AS comparables,
  ROUND(MIN(precio_m2)) AS p_min,
  ROUND(APPROX_QUANTILES(precio_m2, 100)[OFFSET(25)]) AS p25,
  ROUND(APPROX_QUANTILES(precio_m2, 100)[OFFSET(50)]) AS FMP_mediana,
  ROUND(APPROX_QUANTILES(precio_m2, 100)[OFFSET(75)]) AS p75,
  ROUND(MAX(precio_m2)) AS p_max,
  ROUND(AVG(precio_m2)) AS promedio
FROM tipologias_zona t
CROSS JOIN UNNEST([
  STRUCT('Tipo C' AS tipo_saviia, 63.7 AS area_saviia),
  STRUCT('Tipo B' AS tipo_saviia, 70.5 AS area_saviia),
  STRUCT('Tipo E' AS tipo_saviia, 74.1 AS area_saviia)
]) AS s
WHERE ABS(t.area - s.area_saviia) <= 7
GROUP BY tipo_saviia, area_saviia
ORDER BY area_saviia;

-- Resultado:
-- Tipo C 63.7 → FMP $4,226,069 (24 comparables) · Negociado $5,649,295 → +33.7%
-- Tipo B 70.5 → FMP $4,592,971 (29 comparables) · Negociado $5,059,844 → +10.2%
-- Tipo E 74.1 → FMP $4,173,331 (25 comparables) · Negociado $5,629,286 → +34.9%

-- Total ponderado: FMP $4,242,308/m² · Negociado $5,569,248/m² → +31.3%
-- Sobreprecio total: ~$11,070 millones sobre los 8,342 m² ofertados
