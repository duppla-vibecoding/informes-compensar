-- ============================================================
-- 05 · Fair Market Price (FMP) por tipología · Sección 5
-- ============================================================
-- FMP = promedio ponderado por ventas 2025 del precio m² de
-- tipologías comparables (±7 m² de área) en proyectos competidores
-- en 2 km DEL MISMO SEGMENTO (VIS o No-VIS) que el proyecto evaluado.
--
-- IMPORTANTE (regla metodológica):
-- 1. Filtrar por `vis_novis` según el segmento del proyecto evaluado.
--    Saviia es No-VIS → solo comparar contra No-VIS.
--    Si el proyecto fuera VIS, filtrar por `vis_novis = 'Vis'`.
-- 2. Usar `trends.preciom2` (precios efectivos de venta) ponderado
--    por `trends.numventas`, NO `detalle.precultmes / area`
--    (precios de lista, no efectivos y no ponderados por ventas).
-- 3. Filtrar por año reciente (2025) para reflejar el mercado actual.

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
    AND c.codproyecto != 500465      -- excluye Saviia
    AND c.vis_novis = 'No Vis'       -- MISMO SEGMENTO que el proyecto evaluado
),
-- Ventas 2025 del trends en proyectos del mismo segmento
trends_2025 AS (
  SELECT t.area, t.preciom2, t.numventas
  FROM proys_2km p
  JOIN `complete-verve-362421.lgi.bogota_def_Def_12-25_trends` t USING(codproyecto)
  WHERE EXTRACT(YEAR FROM PARSE_DATE('%Y/%m/%d', t.variable)) = 2025
    AND t.preciom2 > 0 AND t.numventas > 0
)
-- Por cada tipología Saviia, promedio ponderado por ventas de tipologías ±7 m²
SELECT
  s.tipo_saviia,
  s.area_saviia,
  SUM(t.numventas) AS ventas_comparables,
  ROUND(SUM(t.preciom2 * t.numventas) / SUM(t.numventas)) AS fmp_ponderado_2025
FROM trends_2025 t
CROSS JOIN UNNEST([
  STRUCT('Tipo C' AS tipo_saviia, 63.7 AS area_saviia),
  STRUCT('Tipo B' AS tipo_saviia, 70.5 AS area_saviia),
  STRUCT('Tipo E' AS tipo_saviia, 74.1 AS area_saviia)
]) AS s
WHERE ABS(t.area - s.area_saviia) <= 7
GROUP BY tipo_saviia, area_saviia
ORDER BY area_saviia;

-- Resultado (solo No-VIS, trends 2025 ponderado):
-- Tipo C 63.7 → FMP $4,731,175 (218 ventas comparables) · Negociado $5,649,295 → +19.4%
-- Tipo B 70.5 → FMP $4,642,915 (248 ventas comparables) · Negociado $5,059,844 → +9.0%
-- Tipo E 74.1 → FMP $4,779,013 (186 ventas comparables) · Negociado $5,629,286 → +17.8%

-- Total ponderado por (área × cantidad) de las 120 apts Saviia:
-- FMP $4,745,378/m² · Negociado $5,569,248/m² → +17.4%
-- Sobreprecio absoluto: ~$6,870 millones sobre los 8,342 m² ofertados

-- ============================================================
-- NOTA METODOLÓGICA IMPORTANTE:
-- La versión anterior de este query usaba `detalle.precultmes / d.area`
-- (precios de lista del último mes) y mediana. Eso subestimaba el FMP
-- porque:
--   a) Mediana ignora ponderación por ventas → tipologías con muchas
--      unidades pero pocas ventas pesan igual que las más vendidas.
--   b) `precultmes` es precio de lista, no precio efectivo de cierre.
--   c) Incluía datos de años anteriores (no solo 2025).
-- Resultado erróneo anterior: FMP $4,263,760/m² y sobreprecio +30.6%.
-- Resultado correcto (actual): FMP $4,745,378/m² y sobreprecio +17.4%.
-- ============================================================
