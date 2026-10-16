# Bitacora 2026-10-16 — ECC integrado por COPIA (correccion de modelo)

## Cambio de modelo (decision del usuario)
- ANTES (erroneo): punteros `## Profundidad ECC` -> `proyect_ext/ECC/...` (obligaba a llevar el externo a todos lados).
- AHORA: el externo es cache de descarga (`proyect_ext/`, gitignored); el script integra COPIANDO al KIT; lo integrado viaja en git a los demas proyectos.

## Ejecutado
- 76 fachadas: seccion puntero eliminada (0 restantes), contenido ECC anexado con cabecera de trazabilidad (`integrada b92f181b, 2026-10-16` + nota de cache).
- Fachada SSD propia intacta arriba; profundidad ECC debajo. `.github/skills` total 1.1 MB.
- Rules ecc-common/ecc-python: tag de origen `KIT ECC-integrado b92f181b` (16 archivos).
- Placeholders: 11 hits, todos contenido legitimo ECC (ejemplos sk-proj-xxxxx, todo!() Rust, patrones grep). Sin trabajo incompleto.

## Pendiente a futuro
- Script de re-integracion (re-copiar tras `ecc update`): encaja en spec 021 T012 `externals/` (hoy dice "sin copia"; actualizar la spec).
