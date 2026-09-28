# Implementación 009 - Normalización de rutas MCP a forward slashes

## Resumen
Se normalizaron todas las rutas MCP a forward slashes `/` en `scripts/plataformador-bootstrap.ps1` para evitar `InvalidEscapeCharacter` en `opencode.json` y garantizar portabilidad Windows/macOS/Linux.

## Cambios realizados

### 1. Normalización rutas MCP al resolver
**Ubicación:** `Ensure-OpenCodeMcp` → bloque de re-resolución de tokens
- Antes: `$entry.Value.command = @($real)`
- Después:
  ```powershell
  $realNorm = $real -replace '\\','/'
  $entry.Value.command = @($realNorm)
  ```
- Impacto: rutas de `context-mode`, `codebase-memory-mcp`, `markitdown` se escriben con `/`.

### 2. Normalización tokenslayer
**Ubicación:** `Ensure-OpenCodeMcp` → registro tokenslayer
- `$nodeCmd.Source = $nodeCmd.Source -replace '\\','/'`
- `$indexCanonTokNorm = $indexCanonTok -replace '\\','/'`
- `$tokenslayerEntry.command = @($nodeCmd.Source, $indexCanonTokNorm)`
- Impacto: comando Node y ruta `proyect_ext/tokenslayer/mcp-server/build/index.js` con `/`.

### 3. Normalización graphify
**Ubicación:** `Configure-Graphify`
- `$pythonCmd.Source = $pythonCmd.Source -replace '\\','/'`
- `$graphCanonG = $graphCanonG -replace '\\','/'` tras containment-check
- Uso en `opencode.json` y `.vscode/mcp.json` con rutas normalizadas
- Impacto: `python -m graphify.serve <ruta>` portable.

## Validación
- JSON se valida con round-trip `ConvertTo-Json` → `ConvertFrom-Json` antes de escribir `opencode.json`.
- No se modificó lógica de containment-check, resolución de tokens ni degradación.
- Rutas en `.env.mcp` mantienen valores resueltos normalizados.

## Archivos modificados
- `C:\Proyectos\Agents_IA_TECH\scripts\plataformador-bootstrap.ps1`

## Tareas completadas
- T001 Identificar puntos de asignación
- T002 Normalización MCP
- T003 Normalización tokenslayer
- T004 Normalización graphify
- T005 Validación JSON

Fecha: 2026-09-28
