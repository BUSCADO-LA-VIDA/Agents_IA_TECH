# Data Model: 009-mcp-update-lifecycle

## Entidades

### `.bootstrap-state.json`
- **lastUpdate**: string ISO8601
- **tools**: object
  - `context-mode`: { version, path, updated }
  - `codebase-memory-mcp`: { version, path, updated }
  - `markitdown`: { version, path, updated }
  - `tokenslayer`: { version, path, updated }
  - `graphify`: { version, path, updated }

Validación: `lastUpdate` debe ser parseable. `tools` opcional.

### `.env.mcp`
- **CONTEXT_MODE_CMD**: string ruta
- **CODEBASE_MEMORY_CMD**: string ruta
- **MARKITDOWN_CMD**: string ruta
- **PYTHON_CMD**: string ruta

Validación: rutas deben existir o ser vacías.

### `scripts/update-mcp.ps1` parámetros
- `-Force`: switch
- `-Tools`: string[] opcional
- `-DryRun`: switch

## Relaciones
`.bootstrap-state.json` refleja estado de herramientas listadas en `.env.mcp`.
