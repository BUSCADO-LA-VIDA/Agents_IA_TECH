## T001 – Endurecer Get-State (guard por forma) + parse DateTime-aware
- **Descripción**: Reescribir `Get-State` de `scripts/update-mcp.ps1` (línea 9): capturar el parseo en variable local y devolver `$null` si falta la propiedad `lastUpdate` (el guard por tipo `-isnot` no discrimina strings deserializados: responden `-is [PSCustomObject] = True`). Hacer el parse de `lastUpdate` (línea 16) `DateTime`-aware (aceptar `[DateTime]` directo; `ConvertFrom-Json` ya lo convierte y re-parsearlo rompe la ventana 24h por doble conversión cultural).
- **Estado**: `[x]` Completado (2026-10-09: ambas causas reproducidas en vivo antes del fix — `tipo: System.Object[]` y `parse-ok: 2026-09-10` con archivo de octubre).
- **Dependencias**: Ninguna.

## T002 – Verificar sintaxis del script
- **Descripción**: Ejecutar `Parser::ParseFile` sobre `scripts/update-mcp.ps1` bajo `pwsh` y confirmar 0 errores.
- **Comando**: `pwsh -NoProfile -Command '[System.Management.Automation.Language.Parser]::ParseFile("scripts/update-mcp.ps1",[ref]$t,[ref]$e); $e.Count'`
- **Estado**: `[x]` Completado (2026-10-09: 0 errores en `update-mcp.ps1` y en `plataformador-bootstrap.ps1`).
- **Dependencias**: T001.

## T003 – Quitar flag muerto -Quick del bootstrap
- **Descripción**: Cambiar la invocación de cola `& $updateScript -Quick` por `& $updateScript` en `scripts/plataformador-bootstrap.ps1` y verificar cero referencias a `-Quick` en el archivo.
- **Estado**: `[x]` Completado (2026-10-09: única mención restante es el comentario explicativo de la propia línea).
- **Dependencias**: Ninguna.

## T004 – Validar ejecución real con estado stale
- **Descripción**: Con `.bootstrap-state.json` existente y viejo (>24h), ejecutar `pwsh scripts/update-mcp.ps1` y confirmar exit 0, reporte impreso y `lastUpdate` actualizado a hoy.
- **Comando**: `pwsh -NoProfile -File scripts/update-mcp.ps1`
- **Estado**: `[x]` Completado (2026-10-09 09:28: estado 2026-09-24 → reporte `UP_TO_DATE` por ruta + `lastUpdate` 2026-10-09T09:28; antes del fix esta misma corrida fallaba en línea 30).
- **Dependencias**: T001, T002, T003.

## T005 – Validar auto-sanado con estado envenenado
- **Descripción**: Respaldar `.bootstrap-state.json`, escribir `["x"]`, ejecutar con `-Force` y confirmar exit 0 + archivo re-inicializado como objeto válido. El respaldo no se restaura (el archivo es runtime gitignored; el nuevo estado es válido y fresco).
- **Comando**: `Set-Content .bootstrap-state.json '["x"]'; pwsh -NoProfile -File scripts/update-mcp.ps1 -Force`
- **Estado**: `[x]` Completado (2026-10-09 10:03: `["x"]` → reporte `UPDATED/Forzado` + `lastUpdate` 2026-10-09T10:03 válido).
- **Dependencias**: T004.

## T006 – Confirmar DryRun y UP_TO_DATE intactos
- **Descripción**: Ejecutar con `-DryRun` (no escribe) y una segunda ejecución normal (debe salir temprana `UP_TO_DATE` con exit 0), confirmando FR-005.
- **Estado**: `[x]` Completado (2026-10-09 09:52: segunda corrida con estado fresco → `ALL | UP_TO_DATE | Ultima 2026-10-09 09:30`; `-DryRun` verificado en corridas previas sin escrituras).
- **Dependencias**: T004.
