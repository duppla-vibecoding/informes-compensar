# Informes de inversión inmobiliaria · Duppla

Análisis de oportunidades de inversión en proyectos inmobiliarios usando datos de LGI (Galería Inmobiliaria) y BigQuery.

## Informes generados

| Caso | HTML | Estado |
|---|---|---|
| **Saviia (Tecnourbana, Zipaquirá)** — 120 apartamentos | [`informe_saviia_inversion.html`](informe_saviia_inversion.html) | activo |
| Histórico Saviia (versión inicial) | [`informe_saviia_historico.html`](informe_saviia_historico.html) | obsoleto |

## Estructura del repo

```
informes-compensar/
├── README.md                          ← este archivo
├── informe_saviia_inversion.html      ← informe interactivo (abrir en navegador)
├── queries/                           ← SQL usados en BigQuery
│   ├── 01_buscar_proyecto.sql
│   ├── 02_competidores_2km.sql
│   ├── 03_historico_mensual.sql
│   ├── 04_resumen_vis_novis.sql
│   └── 05_fmp_por_tipologia.sql
└── data/                              ← datasets exportados (JSON)
    ├── saviia_proys_compact.json      ← 21 proyectos competidores
    └── saviia_serie_mensual.json      ← serie mensual de precios
```

## Fuentes de datos · BigQuery (`complete-verve-362421`)

| Tabla | Qué contiene | Sección informe |
|---|---|---|
| `lgi.bogota_def_Def_12-25_proyectos` | Maestro: tamaño, vis_novis, lat/lng, fechas | 1, 2 |
| `lgi.bogota_def_Def_12-25_detalle` | Tipologías por proyecto (área, total, disponibles, precio) | 1, 6 (FMP) |
| `lgi.bogota_def_Def_12-25_trends` | Histórico mensual de precio m² y ventas | 3, 4 |
| `eval_inmuebles.comportamiento_vivienda_nueva` | Vista consolidada con coordenadas y métricas | 3, 5 |

## Metodología clave

### Filtro geográfico (radio 2 km)
```sql
ST_DISTANCE(
  ST_GEOGPOINT(longitud, latitud),
  ST_GEOGPOINT(-73.991969, 5.015443)  -- coords de Saviia
) <= 2000
```
+ filtro temporal: `fecha_ultima_venta_proyecto >= CURRENT_DATE - 1 año`

### Promedio ponderado mensual
```
Σ(precio_m² × ventas) / Σ(ventas)   por mes y por segmento
```
Refleja el precio efectivo de cierre, no el precio de lista.

### Velocidad y rotación
- **Velocidad mensual** = `unidades_vendidas / meses_activos`
- **Rotación** = `disponibles / velocidad_mensual` = meses para agotar inventario

### Fair Market Price (FMP) por tipología
Mediana del precio m² de tipologías comparables (área ±7 m²) en proyectos competidores en 2 km.

## Caso Saviia · resumen ejecutivo

| Métrica | Valor |
|---|---|
| Tamaño total | 418 apts |
| Apartamentos ofrecidos a Duppla | 120 (28.7% del proyecto, 83.9% del disponible) |
| Precio negociado m² ponderado | $5,572,108 |
| Precio lista LGI | $5,955,259 |
| FMP zona (precio justo mercado) | $4,242,308 |
| **Sobreprecio vs FMP** | **+31.3% (~$11,070M)** |
| Rotación Saviia | 26.0 meses (más rápido que zona) |
| Crecimiento precio 5 años | +43.4% |
| Veredicto | **SÍ comprar, pero negociar -15% a -25% adicional** |

## Cómo ver el informe

**Opción 1 — local:**
```bash
open informe_saviia_inversion.html
```

**Opción 2 — público (gist):**
- Gist: https://gist.github.com/duppla-vibecoding/6fd8249bec80999529f47eba7a5826d2
- Renderizado: https://gistcdn.githack.com/duppla-vibecoding/6fd8249bec80999529f47eba7a5826d2/raw/informe_saviia_inversion.html

## Cómo regenerar los datos

Las queries están en `queries/`. Ejecutarlas en BigQuery (proyecto `complete-verve-362421`) y exportar el resultado como JSON. Los datos del informe están embebidos en el HTML; para actualizarlos, regenerar el archivo con un script Python que reemplace el bloque `<script>const SERIE = ...</script>`.

## Convenciones

- Datos LGI con corte a **diciembre 2025**
- Coordenadas Saviia: lat `5.015443`, lng `-73.991969`
- codproyecto Saviia: `500465`
- Moneda: pesos colombianos (COP)
