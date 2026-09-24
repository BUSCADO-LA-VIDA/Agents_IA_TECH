# Quickstart: 007-mcp-token-resolution

**Feature**: `007-mcp-token-resolution`
**Date**: 2026-09-24

Guía de validación end-to-end. Prerrequisito: PowerShell 7+ (`pwsh`) y `git` en el PATH. Ejecutar desde la raíz del proyecto (o del kit).

> Sustituir `<root>` por la ruta del proyecto bajo prueba. En el kit maestro, `<root>` = `C:\Proyectos\Agents_IA_TECH`.

---

## Prerrequisitos

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'   # >= 7
git --version
Get-Command context-mode, codebase-memory-mcp, markitdown -ErrorAction SilentlyContinue
```

Herramientas opcionales (su ausencia debe degradar con WARN, no romper): `node`, `graphify`, `uv`.

---

## T-01 — Idempotencia (RF-02 / SC-002)

```powershell
# Estado previo limpio: sin sección mcp
# 1) primera corrida
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
$b1 = (Get-Content opencode.json -Raw | ConvertFrom-Json).mcp
# 2) segunda corrida
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
$b2 = (Get-Content opencode.json -Raw | ConvertFrom-Json).mcp
```

**Esperado**: `$b1` y `$b2` equivalentes (mismas claves, mismas rutas, 0 duplicados).

---

## T-02 — Re-resolución sobre `mcp` existente (RF-01 / SC-001)

```powershell
# Proyecto con opencode.json con mcp.{context-mode,codebase-memory-mcp,markitdown}.command = ["__*_CMD__"] y enabled=false
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
$m = (Get-Content opencode.json -Raw | ConvertFrom-Json).mcp
$m.'context-mode' | ConvertTo-Json
```

**Esperado**: `command[0]` re-resuelto (ruta real o `{env:...}`); `enabled: true` para instalados; sin `__*_CMD__` pendientes.

---

## T-03 — Preservación de claves (RF-01 / RNF-02)

```powershell
$before = Get-Content opencode.json -Raw | ConvertFrom-Json
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
$after = Get-Content opencode.json -Raw | ConvertFrom-Json
$before.provider  -eq $after.provider
$before.permission -eq $after.permission
$before.model     -eq $after.model
$before.region    -eq $after.region
$before.plugin    -eq $after.plugin
```

**Esperado**: los 5 comparativos → `True` (diff solo en `mcp`).

---

## T-04 — `.env.mcp` (RF-03 / SC-003)

```powershell
Remove-Item .env.mcp -ErrorAction SilentlyContinue
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
Test-Path .env.mcp
Get-Content .env.mcp
git check-ignore .env.mcp; "exit=$LASTEXITCODE"
Select-String -Path .gitignore -Pattern '^\.env\.mcp$'
```

**Esperado**: `.env.mcp` creado con `CONTEXT_MODE_CMD=`, `CODEBASE_MEMORY_CMD=`, `MARKITDOWN_CMD=`; `exit=0`; `.gitignore` contiene `.env.mcp`; cuadro resumen lista `.env.mcp`.
**Segunda corrida** → `.env.mcp` conservado sin cambios.

> **Contrato de carga (R-01)**: OpenCode **no** carga `.env.mcp` automáticamente. El bootstrap garantiza la resolución efectiva vía `environment` del MCP local (o ruta real en `command`). Si el usuario quiere confiar en `{env:...}`, debe exportar las vars:
> ```powershell
> Get-Content .env.mcp | Where-Object { $_ -match '=' } | ForEach-Object {
>   $k,$v = $_ -split '=',2; [Environment]::SetEnvironmentVariable($k,$v)
> }
> ```

---

## T-05 — `-Force` no deja tokens (RF-02)

```powershell
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing -Force
$raw = Get-Content opencode.json -Raw
$raw -match '__(CONTEXT_MODE|CODEBASE_MEMORY|MARKITDOWN)_CMD__'
```

**Esperado**: `False` (ningún token en el bloque `mcp`).

---

## T-06 — `-ForceUpgradeTools` (RF-04)

```powershell
# con red
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -ForceUpgradeTools -SkipIndexing -SkipSync
# sin red (simular desconectando) -> debe WARN y continuar
```

**Esperado**: OK/WARN por herramienta (`context-mode`, `codebase-memory-mcp`, `markitdown`, `graphifyy[mcp]`, tokenslayer build); ante fallo → WARN, no aborta. Sin el flag → no se intenta upgrade.

---

## T-07 — Self-update (RF-05 / SC-006)

```powershell
# Kit maestro: debe auto-saltarse
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing
# Salida esperada: "Repo local es el kit maestro ... self-update omitido."

# Escape explícito
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipSelfUpdate -SkipIndexing
```

**Esperado**: en consumidor desactualizado con red → se actualiza y re-ejecuta con los mismos args; en kit o `-SkipSelfUpdate` → no se intenta; sin red → WARN + continúa.

---

## T-08 — Kit seguro vs consumidor (RF-06 / SC-004)

```powershell
# Kit maestro en modo seguro: MCPs activos, sin sync
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipSync -SkipIndexing
$m = (Get-Content opencode.json -Raw | ConvertFrom-Json).mcp
$m.PSObject.Properties | ForEach-Object { "$($_.Name): enabled=$($_.Value.enabled)" }
```

**Esperado**: MCPs `enabled: true`; salida **sin** "Sincronizando kit transversal"; `Sync-TransversalKit` no ejecutado.

---

## T-09 — Herramientas ausentes (RF-07 / SC-005)

```powershell
# Sin graphify en PATH
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing -SkipSync 2>&1 |
  Select-String -Pattern 'graphifyy\[mcp\]'
# tokenslayer sin build/index.js
Test-Path proyect_ext/tokenslayer/mcp-server/build/index.js
```

**Esperado**: graphify ausente → no registrado + WARN con el comando exacto; tokenslayer sin build → no registrado + instrucciones; el bootstrap continúa.

---

## T-10 — Reporte final (RF-08 / SC-007)

```powershell
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -SkipIndexing -SkipSync
```

**Esperado**: salida con el bloque `mcp` resultante + `enabled`/razón por entrada; toda entrada `false` con causa. Cuadro resumen incluye `.env.mcp`.

---

## T-11 — DryRun (no escribe)

```powershell
$hashBefore = (Get-FileHash opencode.json).Hash
pwsh -NoProfile -File scripts/plataformador-bootstrap.ps1 -ProjectRoot . -DryRun
$hashAfter = (Get-FileHash opencode.json).Hash
$hashBefore -eq $hashAfter
```

**Esperado**: `True` (no se escribió nada); la salida informa las acciones que se harían (incluye `.env.mcp` y re-resolución).

---

## Criterio de aceptación global

Corridas T-01 y T-02 en un proyecto consumidor dejan el 100% de los MCPs instalados en `enabled: true` con rutas válidas o `{env:...}` resoluble, sin conservar tokens, preservando el resto del `opencode.json`, y con `.env.mcp` gitignored (SC-001…SC-007).
