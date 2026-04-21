-- ============================================================
-- 01 · Buscar proyecto y obtener datos básicos
-- ============================================================
-- Sirve para encontrar el codproyecto y validar info maestra
-- (nombre, constructora, lat/lng, tamaño, fechas, vis_novis).

-- 1.1 · Buscar codproyecto por nombre
SELECT
  codproyecto,
  nomproyecto,
  nomconstructor,
  zona,
  barrio,
  subzona
FROM `complete-verve-362421.lgi.bogota_def_Def_12-25_proyectos`
WHERE LOWER(nomproyecto) LIKE '%saviia%';
-- → codproyecto = 500465

-- 1.2 · Info maestra completa del proyecto
SELECT
  nomproyecto,
  nomconstructor,
  vis_novis,
  tipoinmueble,
  numunidades,            -- 418 (tamaño total)
  ventaunidades,          -- 275 (vendidas)
  ventasanteriores,
  estado,
  fechainicio,            -- 2021/11/01
  fechaentrega,           -- 2028/12/01
  fecha_ultima_venta_proyecto,
  estrato,
  lat_lng,
  zona, barrio, subzona, direccion
FROM `complete-verve-362421.lgi.bogota_def_Def_12-25_proyectos`
WHERE codproyecto = 500465;

-- 1.3 · Composición por tipología (4 tipos: 63.7 / 70.5 / 74.1 / 85.35 m²)
SELECT
  codinmueble,
  tipo,
  area,
  numunidades,            -- total por tipología
  ventasacumuladas,       -- vendidas
  disponibles,            -- inventario actual
  precultmes              -- precio último mes (precio total por unidad)
FROM `complete-verve-362421.lgi.bogota_def_Def_12-25_detalle`
WHERE codproyecto = 500465;
