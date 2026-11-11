# Bitácora: 2026-11-11 — MCP caídos tras el reinicio (context-mode y markitdown)

**Invocado por**: usuario ("mis MCP siguen sin funcionar todos")
**Entorno**: OpenCode 2, Windows, `context-mode` 2.1.0, `markitdown-mcp` 0.0.1a8, `mcp` 1.30.0

## 1. Diagnóstico

Los logs (`opencode.log`, run del 2026-11-11 06:57) dieron la causa exacta de cada servidor, sin ambigüedad:

| MCP | Error real | Causa |
|---|---|---|
| `context-mode` | `Cannot find module '...\context-mode\build\cli.js'` | El paquete 2.1.0 ya no tiene `build/cli.js`: expone `cli.mjs` (`bin`) y `server.mjs` (servidor MCP) |
| `markitdown` | `ModuleNotFoundError: No module named 'mcp.server.mcpserver'` | `markitdown-mcp 0.0.1a8` exige `mcp>=2.1.1,<3`; instalado `mcp 1.30.0` |
| `graphify` | `failed to list MCP resource templates: Method not found` | Aviso benigno: el servidor no implementa ese método; el resto funciona |

**Ningún MCP estaba caído por los cambios de portabilidad.** `opencode.json` seguía intacto desde el 2026-11-06. Las dos causas son de versión/layout de las herramientas, ya registradas como deuda en la spec 038 (context-mode declarado contra `build/cli.js` inexistente).

Descartado también: `Edit`, `Bash` y las consultas GitHub nunca estuvieron bloqueadas por el hook (solo `Read` > 16 KB).

## 2. Solución aplicada

### 2.1 context-mode

`context-mode doctor` daba la reparación oficial y su plan era seguro (`--dry-run`):

```powershell
node <NPM_GLOBAL>/context-mode/cli.mjs setup --agents opencode -y --no-input
```

Resultado: `opencode: PASS` (parse, list, mcp, hook-registered, hook-runs, skills). Escribió la configuración **global** `~/.config/opencode/opencode.json` con:

- `mcp.context-mode` → `node .../context-mode/server.mjs --agent opencode`
- `plugin` → ruta del paquete

Además se corrigió la entrada del proyecto (`opencode.json`, untracked) que apuntaba a `build/cli.js`:

```json
"command": [
  "<NODE_HOME>/node.exe",
  "<HOME>/AppData/Roaming/npm/node_modules/context-mode/server.mjs",
  "--agent",
  "opencode"
]
```

Verificación: el catálogo del arnés ya expone las herramientas `ctx_*` de `context-mode`.

### 2.2 markitdown

Conflicto de dependencias real: `gptme 0.36.0` exige `mcp<2,>=1.28.1`; `markitdown-mcp 0.0.1a8` exige `mcp>=2.1.1,<3`. No pueden convivir.

Se instaló la versión que el propio kit fija (`scripts/sync/mcp/install.ps1` menciona `0.0.1a3`), que resuelve con `mcp 1.30.0`:

```powershell
python -m pip install markitdown-mcp==0.0.1a3
```

Verificación: `markitdown-mcp.exe` arranca y queda esperando stdin (MCP OK). Requiere reiniciar el arnés para que se levante en la sesión.

## 3. Estado

| MCP | Estado |
|---|---|
| `context-mode` | **OK** (herramientas `ctx_*` disponibles) |
| `markitdown` | **OK** tras reinicio |
| `codebase-memory-mcp`, `github`, `playwright`, `tokenslayer`, `context7`, `graphify` | OK (presentes en el catálogo; `graphify` con aviso benigno) |
| `semgrep` | No declarado en `opencode.json` (solo en `.mcp.json`) |

## 4. Riesgo pendiente detectado

`.mcp.json` (VS Code / Copilot) sigue con comandos que **no se pueden spawnear en Windows**: `context-mode`, `npx` y `${workspaceFolder}`. Se comprobó con un spawn real: `context-mode` y `npx` devuelven `ENOENT`; solo los `.exe` resuelven por `PATH`.

Consecuencia: si se usa el arnés de VS Code, sus MCP seguirán caídos. `.mcp.json` es configuración resuelta por máquina, igual que `opencode.json`; la corrección correcta es plantilla + generación local (spec 046), no nombres de comando portables.

## 5. Rollback

```powershell
# context-mode: deshacer el setup (restaura cada archivo tocado)
node <NPM_GLOBAL>/context-mode/cli.mjs setup --remove

# config global previa (no existía antes del setup): eliminarla si se quiere volver al estado inicial
Remove-Item "$env:USERPROFILE\.config\opencode\opencode.json" -Force -ErrorAction SilentlyContinue

# entrada del proyecto
Copy-Item opencode.json.bak-20261111 opencode.json -Force

# markitdown
python -m pip install markitdown-mcp==0.0.1a8
```
