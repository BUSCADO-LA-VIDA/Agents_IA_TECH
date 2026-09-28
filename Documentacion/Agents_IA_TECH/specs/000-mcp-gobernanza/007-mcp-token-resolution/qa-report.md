# QA Report — Feature 007 `007-mcp-token-resolution`

**Agente**: `qa-senior`
**Fecha**: 2026-09-24
**Artefacto bajo prueba**: `scripts/plataformador-bootstrap.ps1` (+ `opencode.json`, `.gitignore`)
**Alcance**: Matriz T-01..T-11 de `quickstart.md`/`plan.md` + D1-D7 + A1-A5 + CN-1..CN-11.
**Método**: inspección de código (AST/lectura) + ejecución de las funciones reales extraídas por AST sobre fixtures en `$env:TEMP` (sin ejecutar el bootstrap completo ni tocar el repo).
**Regla de oro**: genérico para cualquier proyecto consumidor; sin referencias a otros proyectos.

---

## Entorno

| Item | Valor |
|------|-------|
| `pwsh` (runtime requerido por plan.md) | **7.6.6** |
| Windows PowerShell (5.1) presente | 5.1.26100.9444 |
| Script | 2824 líneas lógicas (3115 físicas reportadas por Read) |
| Encoding script | **UTF-8 sin BOM** |

---

## Matriz T-01..T-11

| ID | Escenario | Resultado | Evidencia (comando / resultado) |
|----|-----------|:---------:|--------------------------------|
| **T-01** | Idempotencia (bloque `mcp` estable en 2 corridas) | **FAIL** | Con `mcp` **pre-existente** (PSCustomObject): `b1==b2 → True`. Con `mcp` **ausente (creación fresca, caso consumidor)**: `RUN1 enabled=false/{env:...}` vs `RUN2 enabled=true` → `b1==b2 → False`. No idempotente en el path de creación. |
| **T-02** | Re-resolución sobre `mcp` existente | **PASS** | Fixture con `mcp` en tokens + `enabled:false`: `MCP 'context-mode' re-resuelto`, `enabled=True`, `command[0]=C:\...\context-mode.ps1`. `quedan __*_CMD__: False`. |
| **T-03** | Preservación de claves | **PASS** | `provider/permission/model/region/plugin` → **5/5 True** (diff solo en `mcp`). |
| **T-03b (A5)** | `{env:VAR}` vacío/ausente → no resuelto | **PASS** | `command[0]` tras A5 = ruta real; `queda {env:...} irresoluble: False`; `comando vacío: False`. |
| **T-04** | `.env.mcp` + `.gitignore` | **PASS** | Creado con `CONTEXT_MODE_CMD`/`CODEBASE_MEMORY_CMD`/`MARKITDOWN_CMD`; `.gitignore` con `.env.mcp` **exactamente 1 vez**; 2ª corrida conserva hash (`True`), sin duplicar. |
| **T-05** | `-Force` no deja tokens | **PASS*** | `sin __*_CMD__: True`. *Asterisco: ver Hallazgo BUG-1 — con `-Force` en archivo sin `mcp`, la entrada queda `enabled:false` + `{env:...}` (aunque sin token literal). |
| **T-06** | `-ForceUpgradeTools` | **N/A (parcial)** | Estático: gate `if ($ForceUpgradeTools)`, 4 upgrades + build tokenslayer, fail-open (`catch`→WARN), sin flag no instala. No se ejecutó install real (requiere red + efecto de host; fuera de la restricción de solo-lectura). |
| **T-07** | Self-update | **PASS (estático)** | Auto-skip kit (`Repo local es el kit maestro ... self-update omitido`), `DryRun` solo informa, allowlist `Test-TrustedGithubUrl`, `try/finally` limpia temp (L1987-1991, verificado por lectura). |
| **T-08** | Kit seguro vs consumidor (`-SkipSync`) | **PASS (estático)** | `-SkipSync` → `Sync-TransversalKit OMITIDO (-SkipSync: modo kit seguro)`; sin flag → sync normal. |
| **T-08b (A1)** | Guard del sync preserva `mcp` local | **PASS** | Merge verbatim replicado: `mcp enabled:true conservado: True`, `ruta real conservada: True`, `permission/provider/model preservados: True`; parseo roto → `fail-open no corrompe local: True`. |
| **T-09** | graphify/tokenslayer ausentes | **PASS (estático)** | graphify: WARN con `uv tool install "graphifyy[mcp]"` + no registra. tokenslayer: `elseif (-not (Test-Path ...index.js))` → WARN con instrucciones + no registra; bootstrap continúa. |
| **T-10** | Reporte final | **FAIL (parcial)** | Bloque `mcp` + `enabled`/razón presentes (`True`), `.env.mcp` en resumen (`True`). **PERO** en creación fresca imprime `Count/IsReadOnly/Keys/Values/...` en vez de las entradas `mcp` (BUG-2). |
| **T-11** | DryRun no escribe | **PASS** | `opencode.json` hash sin cambios: `True`; `.env.mcp` NO creado: `True`; informa acciones previstas. |
| **T-107** | Parseo sin errores | **PASS** | `pwsh` 7.6.6 `ParseFile` → **0 errores**. (Ver Hallazgo BUG-3: 92 errores espurios bajo Windows PowerShell 5.1.) |

**Resumen**: PASS 9 · FAIL 3 (T-01, T-10, T-05*) · N/A-parcial 1 (T-06) · PASS-estático 3.

---

## Bloqueantes D1-D7 / A1-A5 / CN

| Control | Estado | Evidencia |
|---------|:------:|-----------|
| D1 (RF-01) — re-resolución SIEMPRE | **PASS parcial** | L447 reemplazado por `Write-Info` (sin `return`); bloque incondicional L512-568 con guard `$null -ne $existing.mcp`. Correcto para `mcp` PSCustomObject; **falla** en `mcp` OrderedDictionary recién creado (BUG-1). |
| D2 (RF-03) — `.env.mcp` + fallback | **PASS** | `Ensure-McpEnvFile` idempotente + `Add-McpEnvGitignore` (guard anti-duplicado). Fallback `{env}`/ruta + `environment` conforme A5. |
| D3 (RF-04) — `-ForceUpgradeTools` | **PASS (estático)** | Gate + fail-open. No ejecutado (red/host). |
| D4 (RF-05) — `Update-Self` | **PASS (estático)** | try/finally, allowlist, auto-skip, re-ejecución con `@script:PSBoundParameters`. |
| D5 (RF-06) — `-SkipSync` + guard sync | **PASS** | Gate presente; A1 merge verificado. |
| D6 (RF-07) — guards ausentes | **PASS (estático)** | Patrón fail-open homogéneo. |
| D7 (RF-08) — reporte final | **PASS parcial** | Presente, **pero** roto en creación fresca (BUG-2). |
| A1 — guard sync `opencode.json` | **PASS** | Merge selectivo + fail-open probados. |
| A2 — orden `Ensure-McpEnvFile` antes de paso 1 | **PASS** | MAIN L2930 invocado incondicional antes de L2935 `Ensure-OpenCodeMcp`. |
| A3 — plantilla `enabled:false` / runtime `true` | **PASS** | `opencode.json` versionado `enabled:false`; runtime promueve a `true` (path PSCustomObject). |
| A4 — revert único `8787bea` | **PASS** | `git revert` de `4a13718`, **aislado a 1 archivo** (`opencode.json`, +7/-8). |
| A5 — `{env}` vacío = no resuelto | **PASS** | Sustitución obligatoria verificada. |
| CN-1 — `.env.mcp`/`config.json` gitignored | **PASS** | `.gitignore` con `.env.mcp` + `.opencode`; `git check-ignore .env.mcp` → **exit 0**. |
| CN-2 — plantilla sin rutas absolutas | **PASS** | Sin `C:\`/`/Users/`; sin `__*_CMD__`. |
| CN-3 — sin token irresoluble | **FAIL parcial** | Se cumple en path PSCustomObject; **violado** en creación fresca (BUG-1: queda `{env:...}` + `enabled:false`). |
| CN-4/CN-5 — fuentes exactas + fail-open | **PASS (estático)** | Nombres oficiales exactos; `try/catch`. |
| CN-6/CN-7 — allowlist + skip | **PASS (estático)** | `Test-TrustedGithubUrl`; auto-skip kit; `-SkipSelfUpdate`. |
| CN-8 — parche quirúrgico | **PASS** | Retrocompat: `cwd`/`timeout`/ruta real/enabled intactos. Validación JSON pre-escritura presente (`ConvertFrom-Json -ErrorAction Stop`). |
| CN-9 — idempotencia | **FAIL parcial** | Idempotente sobre `mcp` existente; **no** en creación fresca (BUG-1). |
| CN-10 — containment tokenslayer | **PASS** | `StartsWith($baseCanonTok + $sepTok)` presente. |
| CN-11 — reporte sin secretos | **PASS** | Solo nombre/rutas/`enabled`/razón; sin `apiKey`/secretos. |

---

## Hallazgos / Bugs

### BUG-1 (P1 · ALTO) — La re-resolución NO corre cuando `mcp` se crea en la misma corrida
- **Archivo**: `scripts/plataformador-bootstrap.ps1:514`
- **Causa raíz (probada)**: al crear la sección, `$existing.mcp` es un `[ordered]@{}` (**`IDictionary`**). `$existing.mcp.PSObject.Properties[$name]` sobre un `OrderedDictionary` **devuelve `$null`** (expone meta-propiedades `Count/Keys/Values/...`), por lo que el loop L513-568 hace `continue` en toda entrada y **nunca resuelve**. Sobre un `PSCustomObject` (leído de JSON) sí funciona.
  ```
  OD  .PSObject.Properties['context-mode'] is null: True
  PSO .PSObject.Properties['context-mode'] is null: False
  ```
- **Impacto**: en el **caso consumidor típico** (primer `bootstrap` sobre un `opencode.json` sin `mcp`), el archivo queda `command:["{env:...}"]` + `enabled:false` → **la feature no cumple RF-01/SC-001 ni CN-3 en su escenario primario**, y **no es idempotente** (RUN1≠RUN2 → viola RF-02/SC-002/CN-9).
- **Reproducción**: fixture `{"model":"m"}` → `Ensure-McpEnvFile` + `Ensure-OpenCodeMcp`; RUN1 `enabled=False cmd={env:CONTEXT_MODE_CMD}`, RUN2 `enabled=True`.
- **Fix propuesto**: usar indexado compatible con diccionario, p.ej.
  `$entry = if ($existing.mcp -is [System.Collections.IDictionary]) { if ($existing.mcp.Contains($name)) { [pscustomobject]@{ Value = $existing.mcp[$name] } } else { $null } } else { $existing.mcp.PSObject.Properties[$name] }`
  (el propio script ya aplica el patrón `-is [IDictionary]` para tokenslayer en L614).

### BUG-2 (P2 · MEDIO) — Reporte final imprime meta-propiedades del diccionario
- **Archivo**: `scripts/plataformador-bootstrap.ps1:661`
- **Causa**: `foreach ($prop in @($existing.mcp.PSObject.Properties))` sobre un `OrderedDictionary` itera `Count, IsReadOnly, Keys, Values, IsFixedSize, SyncRoot, IsSynchronized` en vez de las entradas `mcp`.
- **Impacto**: en creación fresca el bloque "MCPs en opencode.json (estado por entrada)" lista basura y **omite las 3 entradas reales** → incumple RF-08/SC-007 y la trazabilidad (Principio V).
- **Fix propuesto**: iterar de forma agnóstica (p.ej. sobre `$existing.mcp.Keys` cuando `-is [IDictionary]`, o normalizar a `PSCustomObject` antes de reportar).

### BUG-3 (P3 · BAJO · documental) — Verificación `ParseFile` depende del runtime
- **Observación**: T-107 (`tasks.md`) indica `[Parser]::ParseFile(...)` sin especificar intérprete. Bajo **`pwsh` 7.6.6 → 0 errores**; bajo **Windows PowerShell 5.1 → 92 errores espurios** (el script es UTF-8 **sin BOM** y 5.1 lo decodifica en codepage legacy → mojibake → falsos errores de sintaxis).
- **Impacto**: si un revisor ejecuta T-107 con `powershell.exe` (5.1) concluirá (erróneamente) que el script no parsea.
- **Fix propuesto**: fijar el comando de verificación a `pwsh` (p.ej. `pwsh -NoProfile -Command '[Parser]::ParseFile(...)'`) y/o agregar BOM UTF-8 al `.ps1`. No es un defecto del código.

### HALLAZGO-4 (P3 · estado) — Trabajo sin commitear / `.env.mcp` ausente en el kit
- `git status`: `opencode.json`, `.gitignore`, `scripts/plataformador-bootstrap.ps1` **modificados sin commitear**. El commit `8787bea` solo restaura `__*_CMD__`; la migración a `{env:...}` + `enabled:false` de tokenslayer/graphify vive **solo en el working tree**.
- `.env.mcp` **NO existe** en el kit (`Test-Path → False`) → T-603 (crearlo localmente para activar los MCPs del kit en runtime) **no está aplicado**. Coherente con A3 (la plantilla versionada va con `enabled:false`), pero el escenario T-08 del quickstart no puede validarse end-to-end hasta crear `.env.mcp`.
- Acción: cerrar con conventional commits y decidir explícitamente si `.env.mcp` local se genera al correr `-SkipSync` en el kit.

---

## Re-verificación (2026-09-24, post-fix)

**Agente**: `qa-senior` · **Método**: extracción de las funciones reales por AST (`Resolve-McpCommand`, `Add-McpEnvGitignore`, `Ensure-McpEnvFile`, `Ensure-OpenCodeMcp`) + ejecución sobre fixtures en `$env:TEMP`, con stubs de `Write-Info/Write-OK/Write-Warn/Write-WarnOnce` y `$DryRun=$false; $Force=$false`. No se ejecutó el bootstrap completo.

### Fixes aplicados (working tree)

- **BUG-1** — `scripts/plataformador-bootstrap.ps1:519` (bloque L512-580):
  `$mcpIsDict = $existing.mcp -is [System.Collections.IDictionary]` + acceso por indexer (`$existing.mcp.Contains($name)` / `$existing.mcp[$name]`) cuando es diccionario, `PSObject.Properties[$name]` cuando es PSCustomObject.
- **BUG-2** — `scripts/plataformador-bootstrap.ps1:677-681` (reporte L672-695):
  `if ($existing.mcp -is [System.Collections.IDictionary]) { $mcpEntries = @($existing.mcp.Keys | ForEach-Object { [pscustomobject]@{ Name = $_; Value = $existing.mcp[$_] } }) } else { ... PSObject.Properties ... }`.

### Matriz actualizada

| ID | Escenario | Resultado | Evidencia (comando / resultado) |
|----|-----------|:---------:|--------------------------------|
| **T-01** | Idempotencia (bloque `mcp` estable en 2 corridas) | **PASS** | Creación fresca (fixture `{"model":"m"}` sin `mcp`): `RUN1==RUN2 → True`. `enabled` de las 3 entradas = `true` en RUN1 y RUN2. |
| **T-05** | `-Force` no deja tokens | **PASS** | Creación fresca: `sin __*_CMD__: True`; las 3 entradas quedan `enabled=true` (ya no `enabled:false`). |
| **T-10** | Reporte final | **PASS** | Lista las **3 entradas reales** (`context-mode`, `codebase-memory-mcp`, `markitdown`) con `enabled=True`; **ninguna** meta-propiedad (`Count`/`Keys`/`Values`/`IsReadOnly`/`IsFixedSize`/`SyncRoot`/`IsSynchronized` ausentes del output). |
| **T-03b (A5)** | `{env:VAR}` vacío/ausente → no resuelto | **PASS** | Fixture con `mcp` en `{env:...}` + `.env.mcp` con `CONTEXT_MODE_CMD=` (vacío) → `command[0]=C:\Users\tomas\AppData\Roaming\npm\context-mode.ps1` (ruta real), `enabled=True`, `0 {env:}` irresoluble. |
| **T-107** | Parseo sin errores | **PASS** | `pwsh -NoProfile -Command '[Parser]::ParseFile("scripts/plataformador-bootstrap.ps1",[ref]$t,[ref]$e); $e.Count'` → **0 errores**. |
| **CN-1** | `.env.mcp`/`config.json` gitignored | **PASS** | `git check-ignore .env.mcp` → **exit 0**; `git check-ignore .opencode/config.json` → **exit 0**. |
| **CN-3** | Sin token irresoluble | **PASS** | Tras crear en frío, todo `{env:...}` remanente está respaldado por `.env.mcp` (valor no vacío) → resoluble. **0 tokens irresolubles**. |
| **CN-9** | Idempotencia | **PASS** | `RUN1==RUN2 → True` en el path de creación fresca (era el fallo de BUG-1). |

**Resumen re-verificación**: PASS 8/8 (T-01, T-05, T-10, T-03b/A5, T-107, CN-1, CN-3, CN-9). Sin hallazgos nuevos.

### Evidencia textual de comandos

**T-01 / CN-3 / CN-9** (harnés AST, fixture `{"model":"m"}` sin `mcp`):
```
RUN1==RUN2: True
RUN1 enabled all true: True
.env.mcp → CONTEXT_MODE_CMD=C:\...\npm\context-mode.ps1
           CODEBASE_MEMORY_CMD=C:\Users\tomas\.local\bin\codebase-memory-mcp.exe
           MARKITDOWN_CMD=C:\Python314\Scripts\markitdown.exe
{env:CONTEXT_MODE_CMD} -> .env.mcp value "C:\\...\\context-mode.ps1" resolvable=true
{env:CODEBASE_MEMORY_CMD} -> ... resolvable=true
{env:MARKITDOWN_CMD} -> ... resolvable=true
ALL {env:} resolvable via .env.mcp: true
```
> Nota: en el path de creación fresca el `command` conserva `{env:<VAR>}` (mecanismo portable de RF-03) y se promueve a `enabled=true` (var respaldada por `.env.mcp`); en el path A5 (var **vacía**) sustituye por la ruta real. Ambos casos cumplen CN-3 (0 irresolubles).

**T-03b / A5** (`.env.mcp` con var vacía):
```
context-mode command[0]=C:\Users\tomas\AppData\Roaming\npm\context-mode.ps1
context-mode enabled=True
A5 command resolved to real path: True
```

**T-10 / BUG-2** (salida del reporte en creación fresca):
```
--- MCPs en opencode.json (estado por entrada) ---
  - context-mode: enabled=True (env resuelto (CONTEXT_MODE_CMD))
  - codebase-memory-mcp: enabled=True (env resuelto (CODEBASE_MEMORY_CMD))
  - markitdown: enabled=True (env resuelto (MARKITDOWN_CMD))
REAL ENTRY listed (context-mode): True
REAL ENTRY listed (codebase-memory-mcp): True
REAL ENTRY listed (markitdown): True
(META-PROPERTY LISTED: ninguno)
```

**T-107**: `ParseFile errors: 0`.
**CN-1**: `git check-ignore .env.mcp` → `.env.mcp` / `exit=0`.

### Estado real del kit

- `.env.mcp` **existe** (`Test-Path → True`) con las 3 rutas resueltas (ver arriba).
- `opencode.json`: `context-mode`, `codebase-memory-mcp`, `markitdown` → `enabled: true`; `tokenslayer`, `graphify` → `enabled: false`. `plugin: ["context-mode"]`.
- Todos los `{env:...}` de las 3 entradas resuelven a valores no vacíos en `.env.mcp`.

### Estado de los bugs

| Bug | Estado | Línea del fix |
|-----|:------:|---------------|
| **BUG-1 (P1)** | **RESUELTO** | `scripts/plataformador-bootstrap.ps1:519` — `$mcpIsDict = $existing.mcp -is [System.Collections.IDictionary]` (+ indexer L521-526) |
| **BUG-2 (P2)** | **RESUELTO** | `scripts/plataformador-bootstrap.ps1:677-681` — enumeración `-is [IDictionary]` por `Keys` |
| **BUG-3 (P3, documental)** | **PENDIENTE (documental)** | No es defecto de código: `pwsh` → **0 errores**. Acción de cierre: fijar T-107 a `pwsh` en `tasks.md` (o añadir BOM UTF-8 al `.ps1`). |
| **HALLAZGO-4 (P3, estado)** | **PENDIENTE** | Working tree sin commitear (ver `git status`); `.env.mcp` ahora **sí existe** en el kit. Acción: cerrar con conventional commits. |

---

## Veredicto

**APTO para commit.**

Los fixes de **BUG-1** y **BUG-2** quedan verificados con ejecución real de las funciones extraídas por AST: el path de creación fresca (escenario primario del consumidor) ahora produce bloque `mcp` idempotente (`RUN1==RUN2`), con las 3 entradas `enabled=true` y **0 tokens `{env:...}` irresolubles** (RF-01/RF-02/CN-3/CN-9/SC-001/SC-002), y el reporte final lista las 3 entradas reales sin meta-propiedades (RF-08/SC-007). **BUG-3** se resuelve como documental fijando T-107 a `pwsh` (verificado: 0 errores; bajo PS 5.1 son espurios por UTF-8 sin BOM). **HALLAZGO-4** es de estado (commit pendiente), no bloqueante de calidad.

**Condición de cierre (no bloqueante)**: (1) fijar T-107 a `pwsh`; (2) commitear el working tree (`opencode.json`, `.gitignore`, `scripts/plataformador-bootstrap.ps1`, docs de feature 007).

---

## Veredicto (histórico, pre-fix — 2026-09-24)

**NO APTO para commit.**

La implementación es sólida en gran parte de los ejes (preservación quirúrgica de claves, idempotencia sobre `mcp` existente, `.env.mcp` idempotente + gitignored, guard A1 del sync, A2/A3/A4/A5, CN-1/2/6/8/10/11), pero **BUG-1 (P1)** rompe el **escenario primario del consumidor** (primer bootstrap sin sección `mcp`): deja `enabled:false` + `{env:...}` sin resolver, incumpliendo **RF-01, RF-02, CN-3, CN-9, SC-001 y SC-002**, con **BUG-2** degradando además el reporte (RF-08/SC-007).

**Condición de aprobación**: corregir BUG-1 y BUG-2 (mismo patrón `-is [IDictionary]`, ya usado en L614), re-ejecutar T-01 (ambos paths: creación y existente), T-05, T-10 y confirmar 0 tokens/`{env}` irresolubles. BUG-3 y HALLAZGO-4 son no bloqueantes (documental/estado) pero deben resolverse antes del cierre de la feature.
