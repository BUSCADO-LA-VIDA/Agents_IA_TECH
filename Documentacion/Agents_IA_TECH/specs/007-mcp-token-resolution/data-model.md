# Data Model: 007-mcp-token-resolution

**Feature**: `007-mcp-token-resolution`
**Date**: 2026-09-24

Entidades de configuración afectadas (no hay base de datos; este kit es tooling de archivos).

---

## E1 — `opencode.json` (config de proyecto, versionada + resuelta local)

Fuente: plantilla versionada en el kit maestro. Estructura relevante:

| Campo | Tipo | Reglas | Notas |
|-------|------|--------|-------|
| `$schema` | string | fijo | `https://opencode.ai/config.json` |
| `region` | string | conservar | `global` |
| `_note` | string | puede actualizarse | describir tokens/`{env}` y `.env.mcp` |
| `model`, `small_model`, `default_agent` | string | **conservar** | no tocar en re-resolución |
| `plugin` | string[] | incluir `context-mode` | idempotente |
| `instructions` | string[] | conservar | `AGENTS.md` |
| `provider` | object | **conservar** | `{env:NVIDIA_API_KEY}`, `{env:DEEPINFRA_API_KEY}` |
| `mcp` | object | **objetivo del cambio** | ver E2 |
| `lsp` | object | conservar | |
| `permission` | object | **conservar** (no ampliar `bash`) | |

**Regla de parche**: la re-resolución solo modifica `mcp.<name>.command` y `mcp.<name>.enabled`. Cualquier otra clave se preserva byte-a-byte (idealmente vía round-trip JSON).

---

## E2 — Bloque `mcp.<name>` (entrada de servidor MCP local)

| Campo | Tipo | Requerido | Reglas |
|-------|------|-----------|--------|
| `type` | string | Y | `"local"` (conservar) |
| `command` | string[] | Y | token `__*_CMD__` → `{env:*}` → ruta real |
| `enabled` | boolean | Y | `true` solo si hay comando usable; si no, `false` + causa |
| `environment` | object | N | fallback R-01: `{ "CONTEXT_MODE_CMD": "<ruta>" }` |
| `cwd` | string | N | conservar si existe |
| `timeout` | number | N | conservar si existe |

**Estados de `command[0]` y transiciones**:

```text
[__CONTEXT_MODE_CMD__]  --(bootstrap, Get-Command OK)-->  [{env:CONTEXT_MODE_CMD}]  --> ruta efectiva vía environment/command
[__CONTEXT_MODE_CMD__]  --(bootstrap, Get-Command NULL)--> [__CONTEXT_MODE_CMD__] (enabled=false + WARN)
[{env:CONTEXT_MODE_CMD}] --(bootstrap, var resoluble)-->  [{env:...}] (enabled=true)
[ruta real]             --(bootstrap)-->                  [ruta real] (NO se toca)
```

**Entradas gestionadas por `Ensure-OpenCodeMcp`**: `context-mode`, `codebase-memory-mcp`, `markitdown`, `tokenslayer`.
**Entradas gestionadas por `Configure-Graphify`**: `graphify`.

---

## E3 — `.env.mcp` (por proyecto, gitignored)

| Variable | Origen | Regla |
|----------|--------|-------|
| `CONTEXT_MODE_CMD` | `Resolve-McpCommand -ToolName "context-mode"` | ruta o vacío + WARN |
| `CODEBASE_MEMORY_CMD` | `Resolve-McpCommand -ToolName "codebase-memory-mcp"` | ruta o vacío + WARN |
| `MARKITDOWN_CMD` | `Resolve-McpCommand -ToolName "markitdown"` | ruta o vacío + WARN |

**Formato**: `NAME=value`, una por línea (compatible `.env`).
**Reglas**:
- Se crea si no existe (`Ensure-McpEnvFile`).
- Idempotente: si existe, se conserva; `-Force` re-escribe.
- Nunca versionado: `.gitignore` con `.env.mcp`.
- Fuente de verdad legible/portable; el mecanismo efectivo es `environment`/ruta real (R-01).

---

## E4 — Switches de `param()` (contrato CLI)

| Switch | Tipo | Nuevo | Efecto |
|--------|------|-------|--------|
| `-SkipInstall` | switch | no | omite instalación de dependencias |
| `-SkipIndexing` | switch | no | omite indexación |
| `-SkipSelfUpdate` | switch | no (ya) | salta `Update-Self` |
| `-ForceUpgradeTools` | switch | **SÍ** | instala/actualiza herramientas externas, fail-open |
| `-SkipSync` | switch | **SÍ** | salta `Sync-TransversalKit` (modo kit seguro) |
| `-DryRun`, `-Force`, `-VerifyOnly`, `-SyncOnly` | switch | no | existentes |

**Combinaciones clave**:
- Kit maestro: `-SkipSync` (MCPs activos, sin sync).
- Consumidor con bootstrap viejo: (sin flags) → `Update-Self` → re-ejecuta.
- Consumidor con herramientas desactualizadas: `-ForceUpgradeTools`.

---

## E5 — `.gitignore` (regla agregada)

| Patrón | Sección | Regla |
|--------|---------|-------|
| `.env.mcp` | Secrets / credentials | append idempotente (guard: no duplicar) |

Verificación: `git check-ignore .env.mcp` → exit 0.

---

## E6 — Fila de reporte final (D7)

| Campo | Fuente | Ejemplo |
|-------|--------|---------|
| `name` | clave de `mcp` | `context-mode` |
| `enabled` | `mcp.<name>.enabled` | `true` |
| `reason` | derivada | `ruta resuelta` / `token sin resolver` / `herramienta ausente (npm i -g X)` / `{env} resuelto` |

Regla: toda entrada `enabled: false` **DEBE** traer `reason` (RF-08).
