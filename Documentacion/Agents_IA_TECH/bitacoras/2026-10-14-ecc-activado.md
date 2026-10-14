# Bitacora 2026-10-14 — ECC activado (status=active)

## Flujo ejecutado (spec 013)
- `ecc-orchestrator.ps1 --action update`: fetch + reset a `origin/main` (767 archivos, HEAD `b92f181`).
- Marker `.ecc-levanta` escrito: `levantado=2026-10-14T15:40:07 action=update mcp=ecc`.
- `status` -> `ok detail=active`. Validacion ecc-sync: rules/skills/mcp-configs True.

## Bug corregido en `scripts/ecc-sync.ps1`
- Acciones `update` y `update-indexes` asignaban `$state.lastToolUpdate/lastIndexUpdate` directo: falla si el state viejo no tiene la propiedad (`parentesco` de installs antiguos).
- Fix: `Add-Member -NotePropertyName ... -Force` (aditivo, no rompe states viejos ni nuevos). Sin este fix el orquestador nunca escribia el marker (exit != 0).

## Estado agentes
- 32/32 agentes ya traian el bloque ECC (namespace/orquestador/estados): ahora apunta a un ECC activo real.
