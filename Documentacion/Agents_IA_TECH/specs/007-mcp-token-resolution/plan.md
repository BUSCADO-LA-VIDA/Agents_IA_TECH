# Implementation Plan: [007-mcp-token-resolution] — Resolución de tokens MCP + `.env.mcp` por proyecto + upgrade de herramientas + self-update + activación en el kit maestro

**Branch**: `007-mcp-token-resolution` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-mcp-token-resolution/spec.md`

**Note**: This plan is produced by the `/speckit-plan` command. Implementation is single-file: `scripts/plataformador-bootstrap.ps1` (PowerShell 7+, 2840 líneas) + `opencode.json` + `.gitignore`.

---

## Summary

El bootstrap `scripts/plataformador-bootstrap.ps1` promete (vía `_note` en la plantilla) que los tokens MCP `__CONTEXT_MODE_CMD__`, `__CODEBASE_MEMORY_CMD__`, `__MARKITDOWN_CMD__` se re-resuelven a rutas locales en runtime. La promesa **no se cumple**: la re-resolución vive dentro del bloque `else` de creación del `mcp` (L395-414) y por tanto solo corre cuando la sección `mcp` **no existía** o con `-Force`; con una sección `mcp` presente y sin `-Force` se emite "se conserva" (L359-360) y los tokens quedan intactos y `enabled: false`.

La solución es un conjunto de 7 parches quirúrgicos y aditivos sobre el bootstrap:

1. **D1** — Mover la re-resolución de tokens (L395-414) **fuera** del `if/else` de creación, para que corra **siempre**, preservando el resto del JSON (parche por entrada: solo `command` y `enabled`).
2. **D2** — Fuente de rutas portable por proyecto: `Ensure-McpEnvFile` crea `<root>/.env.mcp` (gitignored) con `CONTEXT_MODE_CMD`/`CODEBASE_MEMORY_CMD`/`MARKITDOWN_CMD`; `opencode.json` referencia `{env:...}`; se agrega al cuadro resumen.
3. **D3** — `-ForceUpgradeTools`: reinstala/actualiza las herramientas externas, fail-open.
4. **D4** — `Update-Self` ya existe (L1721-1799) y se invoca antes del paso 1 (L2681-2684); se refuerza/valida el contrato (auto-skip en el kit, `-SkipSelfUpdate`, fail-open).
5. **D5** — Modo kit seguro `-SkipSync` para resolver MCPs en el kit maestro sin disparar `Sync-TransversalKit`.
6. **D6** — graphify: si `python -m graphify.serve --help` falla, no registrar + WARN (la lógica ya existe en `Configure-Graphify` L2523-2530; se homogeneiza el patrón en `Ensure-OpenCodeMcp`).
7. **D7** — Reporte final: imprimir el bloque `mcp` resultante + estado `enabled` y razón por entrada.

**Enfoque técnico**: parches aditivos minimizando el diff. Sin nuevas dependencias. El bootstrap sigue siendo idempotente y fail-open. La fuente versionada no contiene rutas absolutas; las rutas resueltas viven en `.env.mcp` (gitignored) y/o en el `opencode.json` local (patrón actual retrocompatible).

### Ajustes del análisis arquitectónico aplicados (A1-A5)

> Provenientes de `analyze.md` §5. Se aplican **en este plan y en `tasks.md`** (endurecimiento), **sin modificar `spec.md`** (fuente aprobada). Trazabilidad completa en `converge.md`.

| # | Severidad | Ajuste | Dónde | Tareas |
|---|:---------:|--------|-------|--------|
| A1 | MEDIO-ALTO | **Ajustar el guard del sync** sobre `opencode.json` (merge del bloque `mcp` o exclusión del overwrite) — no solo documentar; cierra RF-06 en consumidores, no solo en el kit | §D5, R3, §Cambios por archivo #13 | T604 |
| A2 | MEDIO | Fijar orden: `Ensure-McpEnvFile` incondicional **antes** del primer `Ensure-OpenCodeMcp` (evita no-idempotencia por doble invocación L2713/L2735) | §D2 | T301, T306, T203 |
| A3 | BAJO | Plantilla versionada `enabled: false`; runtime la promueve a `true` (el commit NO fuerza `true` en la plantilla) | §D2, §Cambios por archivo (`opencode.json` #2) | T304, T307, T603 |
| A4 | BAJO | Ruta ÚNICA de revert del commit `4a13718` (`git revert` selectivo; NO editar además el mismo contenido) | §D5, §Cambios por archivo #4 | T003, T602 |
| A5 | BAJO | `{env:...}` con var vacía = NO resuelto → sustitución obligatoria por ruta real/`environment` | §D2 | T103, T305 |

---

## Technical Context

**Language/Version**: PowerShell 7+ (`pwsh`). Script único `scripts/plataformador-bootstrap.ps1` (2840 líneas).

**Primary Dependencies**: `git` (clone shallow para self-update/sync), `npm` (`context-mode`, `codebase-memory-mcp`), `python`/`pip`/`markitdown`, `uv` (`graphifyy[mcp]`), `node` (tokenslayer MCP server). Todas opcionales — el bootstrap degrada con WARN.

**Storage**: Archivos de configuración JSON/`.env` por proyecto:
- `opencode.json` (plantilla versionada con `{env:...}`; resuelto localmente).
- `<root>/.env.mcp` (por proyecto, gitignored).
- `.gitignore` (agrega `.env.mcp`).
- `.vscode/mcp.json` (registro MCP para Copilot; fuera del alcance de este cambio salvo consistencia de patrón).

**Testing**: Sin framework de tests en el repo (kit de configuración, no app). Validación por escenarios manuales/idempotencia (ver "Estrategia de pruebas"): ejecutar el bootstrap N veces y comparar el bloque `mcp`; `git check-ignore .env.mcp`; `DryRun`; corrida en kit vs consumidor.

**Target Platform**: Windows (`win32`) con PowerShell 7+; el kit es portable (paths resueltos en runtime).

**Project Type**: Tooling / script de plataforma (no app). Fuente única: `scripts/plataformador-bootstrap.ps1`.

**Performance Goals**: N/A (script de setup). Objetivo cualitativo: corrida idempotente y sub-segundo en la parte de resolución de MCP (excluye clones/upgrades).

**Constraints**:
- NO commitear rutas absolutas de la PC (RNF-01).
- Fail-open: self-update, upgrade y registro de MCPs nunca abortan (RNF-04).
- Retrocompatibilidad: no romper proyectos ya resueltos (RNF-02).
- Containment de tokenslayer: ruta bajo `<root>/proyect_ext/tokenslayer/`, sin `..` (RNF-07).
- Prohibido ejecutar `npm install` de terceros automáticamente (solo instrucciones) — salvo `-ForceUpgradeTools`, que instala paquetes publicados conocidos.

**Scale/Scope**: 1 script + 2 archivos de config. ~7 parches. Sin agentes nuevos.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación | Estado |
|-----------|-----------|--------|
| I. Modular Agent Design | No se crean agentes. El bootstrap es tooling de plataforma. | ✅ PASS |
| II. Orchestrator Pattern | Cambio de tooling, sin tocar orquestación de agentes. | ✅ PASS |
| III. Specification-Driven Development | Spec `007` existe y precede a la implementación; este plan deriva de ella. | ✅ PASS |
| IV. Copilot/Opencode Compatibility | Mantiene paridad de patrones entre `.opencode`/`opencode.json` y `.vscode/mcp.json`; no introduce divergencia. | ✅ PASS |
| V. Observability and Monitoring | D7 (reporte final `mcp` + estado/razón) y `$script:Warnings`/`$script:Errors` refuerzan observabilidad. | ✅ PASS |
| VI. proyect_ext / Dependencias Externas | `graphify` (graphifyy) y tokenslayer se mantienen bajo `proyect_ext/`; containment intacto. | ✅ PASS |
| Quality Gates (80% coverage) | No aplica test-framework (repo sin runtime). Se sustituye por escenarios de validación reproducibles. Ver "Complexity Tracking". | ⚠️ JUSTIFIED |

**Sin violaciones que bloqueen.** El único desvío (cobertura) se justifica por la naturaleza del repo (kit sin runtime de tests) y se compensa con una matriz de validación determinista.

---

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/
├── spec.md              # Spec de entrada (/speckit-specify)
├── plan.md              # Este archivo (/speckit-plan)
├── research.md          # Phase 0 (/speckit-plan) — decisiones y hallazgos
├── data-model.md        # Phase 1 (/speckit-plan) — entidades de config
├── quickstart.md        # Phase 1 (/speckit-plan) — guía de validación
└── tasks.md             # Phase 2 (/speckit-tasks — NO creado por /speckit-plan)
```

### Source Code (repository root)

```text
scripts/
└── plataformador-bootstrap.ps1   # ÚNICO archivo de código modificado (2840 líneas)

opencode.json                     # Plantilla versionada -> {env:...}
.gitignore                        # Agrega .env.mcp

Documentacion/Agents_IA_TECH/
└── specs/007-mcp-token-resolution/   # Artefactos de este plan (solo doc)
```

**Structure Decision**: Proyecto único de tooling. No hay `src/`, `tests/`, frontend ni backend. Todos los cambios de código caen en `scripts/plataformador-bootstrap.ps1`; los cambios de datos en `opencode.json` y `.gitignore`. Los artefactos del plan viven aislados en la carpeta de la spec.

---

## Contexto

### Puntos de anclaje verificados (estado actual del script)

| Elemento | Líneas | Estado |
|----------|--------|--------|
| `Resolve-McpCommand` | L337-343 | `Get-Command $ToolName` → `$found.Source` o `$null` + WARN |
| `Ensure-OpenCodeMcp` (def.) | L345-486 | Función objetivo principal |
| Guard `opencode.json` inexistente | L349-353 | WARN + `return` |
| **BUG** "se conserva" | L358-360 | `if ($existing.mcp -and -not $Force) { Write-OK "se conserva" }` → salta re-resolución |
| Plantilla con tokens | L362-394 | `$mcpConfig` con `__*_CMD__` + `enabled=$false`; `Add-Member mcp` solo dentro del `else` |
| Re-resolución de tokens | L395-414 | **Dentro del `if/else`** (bug de alcance) — solo corre si se creó el bloque o con `-Force` |
| Registro tokenslayer | L416-469 | `node` vía `Get-Command`; containment-check; `mcp-server/build/index.js`; WARN si falta |
| Plugin context-mode | L471-481 | Agrega `"context-mode"` a `plugin[]` |
| Persistencia JSON | L483-485 | `ConvertTo-Json -Depth 10 \| Set-Content -Encoding UTF8` |
| `Configure-Graphify` | L2480-2666 | **Ya** implementa RF-07 (WARN si `python -m graphify.serve --help` falla); MCP stdio |
| `Sync-TransversalKit` | L1801-1900+ | `$transversalFiles` L1851-1857 (`.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`) — **NO** incluye `scripts/plataformador-bootstrap.ps1` |
| `Update-Self` | L1721-1799 | **Ya implementado**: fail-open, allowlist de URL, auto-skip kit, SHA256, re-ejecución con `@script:PSBoundParameters` |
| Llamada `Update-Self` | L2681-2684 | Antes del paso 1, gated por `-SkipSelfUpdate` |
| `param()` | L31-53 | Ya declara `-SkipSelfUpdate` (L52); falta `-ForceUpgradeTools`, `-SkipSync` |
| `$script:Warnings`/`Errors` | L57-59 | Cuadro resumen F5 |
| `Write-WarnOnce` | L71 | Dedup (paso 1/paso 4) |
| `Show-ExecutionSummary` | L78-91 | Cuadro resumen final |
| MAIN pasos 1-4 | L2708-2736 | 1 `Ensure-OpenCodeMcp` (L2713); 2 `Ensure-Command` × 6 (L2717-2729); 3 `Sync-TransversalKit` (L2732); 4 `Ensure-OpenCodeMcp` (L2735) |

### Comportamiento de OpenCode verificado (docs oficiales)

- `{env:VARIABLE_NAME}` en `opencode.json` sustituye variables de entorno; si no está seteada → string vacío. Ya se usa `{env:NVIDIA_API_KEY}`.
- MCP local admite `command: [...]`, `environment: { VAR: value }`, `enabled`, `cwd`, `timeout`.
- OpenCode **no** expone en la doc una carga automática de `.env.mcp` para el bloque `mcp` — solo interpolación `{env:...}` desde el **entorno del proceso**. Conclusión: el `.env.mcp` es la **fuente de verdad portable/legible**, pero el bootstrap debe además **garantizar la resolución efectiva** (fallback: escribir rutas reales o inyectar `environment`). Ver D2.

---

## Decisiones de diseño

### D1 — Fix de re-resolución (RF-01 / RF-02)

**Problema**: el bloque L395-414 está dentro del `if/else` de creación; con `mcp` existente y sin `-Force` no corre.

**Decisión**: Extraer el bloque de re-resolución a una fase **incondicional** que corre siempre (fuera del `if/else` y fuera de `if (-not $DryRun -and ($null -ne $existing.mcp))` en su forma actual), con guardas:
- Solo actúa si `$null -ne $existing.mcp`.
- Por entrada: resuelve si el `command[0]` es un token `__*_CMD__` **o** `{env:*}` sin valor efectivo.
- Parche **quirúrgico**: modifica únicamente `entry.Value.command` y `entry.Value.enabled`; conserva `type`, `environment` y cualquier otra clave.
- No toca entradas `enabled: true` con ruta real ya válida.
- `DryRun`: informa sin escribir.

**Archivos/líneas**: `scripts/plataformador-bootstrap.ps1` — mover L395-414 a un bloque incondicional tras el `if/else` (≈ tras L393, antes de L416).

**Criterios cubiertos**: RF-01, RF-02, SC-001, SC-002.

---

### D2 — `.env.mcp` por proyecto (RF-03)

> **A2 (MEDIO) aplicado — orden fijado**: `Ensure-McpEnvFile` se invoca **incondicionalmente ANTES** del primer `Ensure-OpenCodeMcp` (MAIN paso 1, L2713). Esto evita la no-idempotencia por doble invocación (pasos 1 y 4, L2713/L2735): sin este orden, la primera resolución podría correr sin `.env.mcp` (`{env:...}` vacío → ruta real) y la segunda con `.env.mcp` (resultado distinto), violando RF-02/SC-002.

> **A3 (BAJO) aplicado — plantilla `enabled: false` / runtime `true`**: la **plantilla versionada** `opencode.json` queda con `enabled: false` (seguro por defecto, sin entorno). La **resolución local en runtime** (vía `.env.mcp`/ruta real de D1) la **promueve a `enabled: true`**. El `opencode.json` del kit commitea la plantilla (`enabled: false`) + su `.env.mcp` local (gitignored) que la habilita en runtime — **el commit NO fuerza `enabled: true` en la plantilla versionada**.

> **A5 (BAJO) aplicado — `{env:...}` vacío = no resuelto**: un `{env:*}` cuya variable esté vacía/ausente del entorno del proceso del MCP cuenta como **NO resuelto** → dispara la sustitución obligatoria por ruta real/`environment`. Nunca se persiste un `{env:...}` irresoluble (alineado con guardrail 3 del ADR-0006 y CN-3 del threat model).

**Problema**: se necesita una fuente de rutas portable que no se versione y que sobreviva al sync.

**Decisión**:
- Nueva función `Ensure-McpEnvFile -RootPath [-DryRun] [-Force]`:
  - Resuelve cada herramienta vía `Resolve-McpCommand` (`context-mode`, `codebase-memory-mcp`, `markitdown`).
  - Si `<root>/.env.mcp` **no** existe → lo crea con formato `NAME=value` (`CONTEXT_MODE_CMD=`, `CODEBASE_MEMORY_CMD=`, `MARKITDOWN_CMD=`). Las que no resuelven se escriben vacías + WARN.
  - Si **ya existe** → se conserva (idempotente); con `-Force` se re-escribe.
  - Agrega `.env.mcp` a `.gitignore` si no está (append idempotente, con guard).
- `opencode.json` (plantilla y resuelto) referencia `{env:CONTEXT_MODE_CMD}` etc. en `command`.

**OpenCode y `.env.mcp` — resolución del riesgo**:
OpenCode interpola `{env:...}` desde el **entorno del proceso del servidor**; la doc no garantiza la lectura automática de un `.env.mcp` ad-hoc. Por lo tanto se implementa un **fallback explícito y portable**:

> **Fallback**: el bootstrap, tras crear `.env.mcp`, registra también las rutas efectivas usando el campo `environment` del MCP local
> (`"environment": { "CONTEXT_MODE_CMD": "<ruta real>" }`) **o** escribe las rutas reales en `command` (comportamiento actual retrocompatible), además de mantener `.env.mcp` como fuente de verdad legible/portable.
> El `command` puede quedar como `["{env:CONTEXT_MODE_CMD}"]` cuando la var esté disponible en el entorno; si no, se usa la ruta real. En ningún caso queda un token `__*_CMD__` sin resolver (D1).

Decisión final: **`.env.mcp` es la fuente de verdad + `environment`/ruta real como mecanismo efectivo**. Documentar en `quickstart.md` el contrato de carga (exportar vars o confiar en `environment`).

**Archivos/líneas**: nuevo `Ensure-McpEnvFile` (≈ tras `Resolve-McpCommand`, L343); invocación **incondicional antes del paso 1** (`Ensure-OpenCodeMcp` L2713, A2); `.gitignore` (agregar `.env.mcp`); `Show-ExecutionSummary` (listar `.env.mcp`).

**Criterios cubiertos**: RF-03, RNF-01, SC-003.

---

### D3 — `-ForceUpgradeTools` (RF-04)

**Decisión**: nuevo switch `-ForceUpgradeTools`. En MAIN (paso 2), gated:
- `npm install -g context-mode@latest`
- `npm install -g codebase-memory-mcp@latest`
- `python -m pip install --upgrade 'markitdown[all]'`
- `uv tool install "graphifyy[mcp]" --force`
- tokenslayer: **build** (`cd proyect_ext/tokenslayer/mcp-server && npm install && npm run build`) — **fail-open** y solo si el clon existe (no clona terceros).
- **Fail-open**: cada paso en `try/catch`, exit code ≠ 0 → `Write-Warn` + continuar. Sin el flag, no se intenta nada.

**Archivos/líneas**: `param()` (L31-53, agregar switch); MAIN paso 2 (L2715-2731).

**Criterios cubiertos**: RF-04, RNF-04.

---

### D4 — `Update-Self` (RF-05) — reforzar contrato

**Hallazgo**: `Update-Self` **ya existe** (L1721-1799) e **ya se invoca** antes del paso 1 (L2681-2684), con: `-SkipSelfUpdate`, allowlist `Test-TrustedGithubUrl`, auto-skip si `origin == RepoUrl`, SHA256, `Copy-Item` + `& $PSCommandPath @script:PSBoundParameters` + `exit`. Cumple RF-05 en su mayor parte.

**Decisión**: NO reimplementar. Tareas de endurecimiento:
- Verificar que la ruta comparada es `scripts/plataformador-bootstrap.ps1` en ambos lados (ya lo es, L1772-1773).
- Asegurar idempotencia del temp dir (`agents-selfupdate-temp`) y limpieza en todos los `return` (revisar L1776, L1783, L1794).
- `DryRun`: solo informa (ya, L1727-1730).
- Documentar en `quickstart.md` el ciclo de re-ejecución.

**Archivos/líneas**: `Update-Self` L1721-1799 (solo si la verificación detecta gaps); MAIN L2681-2684.

**Criterios cubiertos**: RF-05, SC-006, RNF-04.

---

### D5 — Modo kit seguro (RF-06) + ajuste del guard del sync

> **A1 (MEDIO-ALTO) aplicado**: el sync `Sync-TransversalKit` **SÍ sobrescribe `opencode.json`** en consumidores (copia plana vía `$transversalItems` L1897). Documentarlo **no elimina el bug** en consumo normal (donde el sync corre). El guard DEBE **ajustarse** (merge del bloque `mcp` o exclusión de `opencode.json` del overwrite), no solo documentarse. Esto está dentro del "Fuera de Alcance permitido" de la spec ("excluir/ajustar el manejo de `opencode.json`"). Sin este ajuste, RF-06 se cumple solo en el kit (vía `-SkipSync`) y el bug persiste en consumidores.

**Problema**: en el kit maestro el bootstrap nunca corre porque el paso 3 (`Sync-TransversalKit`, L2732) clonaría el maestro y se sobrescribiría a sí mismo (`opencode.json` incluido). En consumidores, el sync pisa el bloque `mcp` resuelto con la plantilla de tokens.

**Decisión**: nuevo switch `-SkipSync` (alias documentado `-KitMode`). En MAIN:
- `-SkipSync` **salta** el paso 3 (`Sync-TransversalKit`) pero ejecuta el resto (D1 resolución MCP, D2 `.env.mcp`, D6, D7).
- `Update-Self` ya se auto-salta en el kit por detección de `origin` (L1753-1756); `-SkipSync` no lo altera.
- Permite activar los MCPs en el kit: `.\scripts\plataformador-bootstrap.ps1 -SkipSync` → MCPs `enabled: true`.
- Complementario a RF-06: revertir `4a13718` (plantilla con `{env:...}`), crear `.env.mcp` local gitignored.

**Ajuste del guard del sync (A1)** — `Sync-TransversalKit` sobre `opencode.json` (L1897, `Type = "File"`):
- **Elegido**: tratar `opencode.json` de forma especial en `$transversalItems` → **preservar el bloque `mcp` local resuelto** (merge selectivo: leer el `mcp` del `opencode.json` local, copiar el resto de la plantilla del maestro y reinsertar el `mcp` local) **o** **excluir `opencode.json` del overwrite** cuando ya exista local (fallback).
- Debe ser **idempotente** y **fail-open**: si el parseo falla, se conserva el local + WARN (nunca corromper la config).
- Criterio: correr el sync en un consumidor con `mcp` resuelto NO degrada `enabled: true` → tokens.

**A4 aplicado — ruta ÚNICA del revert `4a13718`**: el commit está **aislado a `opencode.json`** (verificado: 1 archivo, +8/-7). Ruta elegida = **`git revert 4a13718`** (revert selectivo). **NO** se ejecuta además la edición de T602/T307 sobre el mismo contenido (T307 queda subsumida por el revert; fallback documentado `git checkout 4a13718^ -- opencode.json` solo si el revert no aplica limpio por cambios posteriores).

**Archivos/líneas**: `param()` (L31-53, agregar `-SkipSync`); MAIN paso 3 (L2730-2732, gate); `Sync-TransversalKit` L1891-1900 (`$transversalItems`) — guard del `opencode.json`.

**Criterios cubiertos**: RF-06, SC-004, RNF-02, A1, A4.

---

### D6 — graphify y tokenslayer ausentes (RF-07)

**Hallazgo**: `Configure-Graphify` (L2480-2666) **ya** cumple: si `python -m graphify.serve --help` falla (L2523-2530) → WARN con `uv tool install "graphifyy[mcp]"` y **no** registra. tokenslayer (L449-452) **ya** WARN-ea si falta `mcp-server/build/index.js` con instrucciones de clonado+build.

**Decisión**: homogeneizar y reforzar:
- `Ensure-OpenCodeMcp` no debe dejar entradas rotas: si una entrada `mcp` queda con `enabled: false`, siempre acompañarla de causa (D7).
- Confirmar el patrón fail-open en ambos y que graphify no sea registrado por `Ensure-OpenCodeMcp` (graphify se registra en `Configure-Graphify`, paso 8). Documentar la separación.

**Archivos/líneas**: `Configure-Graphify` L2523-2530 (validar); tokenslayer L449-452 (validar); `Ensure-OpenCodeMcp` (garantizar no-registro de entradas rotas).

**Criterios cubiertos**: RF-07, SC-005, RNF-04.

---

### D7 — Reporte final (RF-08)

**Decisión**: al final de `Ensure-OpenCodeMcp` (tras L483-485), imprimir:
- El bloque `mcp` resultante (JSON serializado, sin secretos — solo rutas, que ya son locales).
- Por entrada: `name` + `enabled: true|false` + razón (`ruta resuelta`, `token sin resolver`, `herramienta ausente`, `{env} resuelto`, etc.).
- En `DryRun`: imprimir el bloque que **resultaría**.
- Integrar con `Show-ExecutionSummary` (L78-91): agregar línea "Rutas MCP en `.env.mcp` — consultá ese archivo".

**Criterios cubiertos**: RF-08, SC-007, Principio V.

---

## Cambios por archivo

### `scripts/plataformador-bootstrap.ps1`

| # | Zona (líneas aprox.) | Cambio | Decisión |
|---|----------------------|--------|----------|
| 1 | L31-53 `param()` | Agregar `[switch]$ForceUpgradeTools`, `[switch]$SkipSync` | D3, D5 |
| 2 | L337-343 (tras `Resolve-McpCommand`) | Nueva función `Ensure-McpEnvFile -RootPath [-DryRun] [-Force]` | D2 |
| 3 | L358-360 | **Eliminar/neutralizar** el early "se conserva"; la re-resolución pasa a correr siempre | D1 |
| 4 | L362-394 | Plantilla `$mcpConfig`: `command` con `{env:CONTEXT_MODE_CMD}` (en lugar de `__*_CMD__`), mantiene `enabled=$false` inicial | D2 |
| 5 | L395-414 | **Mover** fuera del `if/else` → bloque incondicional de re-resolución; parche por entrada (`command`, `enabled`); soporta token y `{env:...}` | D1 |
| 6 | L416-469 | Sin cambio funcional; validar WARN de tokenslayer | D6 |
| 7 | L483-485 (tras persistir) | Bloque de reporte final `mcp` + estado/razón | D7 |
| 8 | L2713 / L2735 | Invocar `Ensure-McpEnvFile` **incondicional ANTES** del primer `Ensure-OpenCodeMcp` (paso 1, L2713); el paso 4 es no-op sobre `mcp` ya resuelto (A2) | D2, A2 |
| 9 | L2715-2731 (paso 2) | Gate `-ForceUpgradeTools` con upgrades fail-open | D3 |
| 10 | L2730-2732 (paso 3) | Gate `-SkipSync` para saltar `Sync-TransversalKit` | D5 |
| 11 | L78-91 `Show-ExecutionSummary` | Línea `.env.mcp` | D2, D7 |
| 12 | L1721-1799 `Update-Self` | Solo endurecimiento si la verificación detecta gaps (limpieza temp) | D4 |
| 13 | L1891-1900 `Sync-TransversalKit` (`$transversalItems`) | **Guard del `opencode.json`**: preservar bloque `mcp` local (merge) o excluirlo del overwrite; idempotente + fail-open | **A1** |

### `opencode.json`

| # | Cambio | Decisión |
|---|--------|----------|
| 1 | `mcp.<name>.command` → `["{env:CONTEXT_MODE_CMD}"]` y análogos (plantilla versionada) | D2 |
| 2 | **Plantilla versionada: `enabled: false`** (seguro por defecto). La resolución local en runtime la promueve a `enabled: true` — el commit NO fuerza `true` en la plantilla | D1, **A3** |
| 3 | Sin rutas absolutas versionadas (RNF-01) | D2 |
| 4 | Ruta ÚNICA del revert del commit `4a13718`: `git revert 4a13718` (aislado a este archivo); NO editar además el mismo contenido (T307 subsumida) | **A4** |

### `.gitignore`

| # | Cambio | Decisión |
|---|--------|----------|
| 1 | Agregar `.env.mcp` (bajo la sección secrets) | D2, RNF-01 |

---

## Estrategia de pruebas

> El repo no tiene test-framework. La validación es por **escenarios reproducibles** (detallados en `quickstart.md`). Documentar cada uno con comando exacto y resultado esperado.

### T-01 — Idempotencia (RF-02 / SC-002)
1. Correr el bootstrap en un proyecto con `opencode.json` sin sección `mcp`.
2. Capturar el bloque `mcp` resultante (`ConvertFrom-Json`).
3. Correr de nuevo; capturar otra vez.
4. **Esperado**: bloques equivalentes (mismas claves, mismas rutas, 0 duplicados).

### T-02 — Re-resolución sobre `mcp` existente (RF-01 / SC-001)
1. Proyecto con `opencode.json` que ya tiene `mcp` con tokens `__*_CMD__` y `enabled: false`.
2. Correr bootstrap **sin** `-Force`.
3. **Esperado**: tokens re-resueltos a rutas reales / `{env:...}`; `enabled: true` para instalados; claves `providers`/`permission`/`model`/`region`/`plugin` inalteradas.

### T-03 — Preservación de claves (RF-01 / RNF-02)
1. `opencode.json` con `providers`, `permission`, `model`, `region`, `plugin`.
2. Correr bootstrap.
3. **Esperado**: el resto del JSON permanece idéntico (diff solo en el bloque `mcp`).

### T-03b — `{env:...}` vacío = no resuelto (A5 / CN-3)
1. `opencode.json` con `command: ["{env:CONTEXT_MODE_CMD}"]` y la variable ausente/vacía del entorno del proceso.
2. Correr bootstrap.
3. **Esperado**: el `{env:...}` vacío se trata como no resuelto → se sustituye por ruta real/`environment`; nunca queda un `{env:...}` irresoluble.

### T-04 — `.env.mcp` (RF-03 / SC-003)
1. Proyecto sin `.env.mcp`; correr bootstrap.
2. **Esperado**: `.env.mcp` creado con las 3 variables; `.gitignore` contiene `.env.mcp`; `git check-ignore .env.mcp` → exit 0; cuadro resumen lista `.env.mcp`.
3. Correr de nuevo → `.env.mcp` conservado sin cambios.

### T-04b — Orden `Ensure-McpEnvFile` antes del primer `Ensure-OpenCodeMcp` (A2)
1. Proyecto sin `.env.mcp`.
2. Correr bootstrap; comparar el bloque `mcp` resultante del paso 1 (L2713) y del paso 4 (L2735).
3. **Esperado**: `.env.mcp` existe antes de la primera resolución; ambos bloques son equivalentes (0 diferencias) → idempotencia garantizada.

### T-05 — `-Force` no deja tokens (RF-02)
1. Proyecto con `mcp` resuelto; correr con `-Force`.
2. **Esperado**: el bloque `mcp` no contiene `__*_CMD__` ni `{env:...}` sin resolver.

### T-06 — `-ForceUpgradeTools` (RF-04)
1. Correr con `-ForceUpgradeTools` con red → OK/WARN por herramienta.
2. Simular fallo (herramienta sin red) → WARN + no aborta.
3. Sin el flag → no se intenta upgrade.

### T-07 — Self-update (RF-05 / SC-006)
1. Proyecto consumidor con bootstrap desactualizado + red → se actualiza y re-ejecuta con los mismos args.
2. Kit maestro o `-SkipSelfUpdate` → no se intenta.
3. Sin red → WARN + continúa local.

### T-08 — Kit seguro vs consumidor (RF-06 / SC-004)
1. Kit maestro con `-SkipSync` → MCPs `enabled: true`, `Sync-TransversalKit` NO ejecutado.
2. Proyecto consumidor sin el flag → sync ejecutado normalmente.

### T-08b — Guard del sync sobre `opencode.json` (A1 / SC-004)
1. Proyecto consumidor con `opencode.json` ya resuelto (bloque `mcp` con `enabled: true`).
2. Correr el sync transversal (paso 3, sin `-SkipSync`).
3. **Esperado**: el bloque `mcp` resuelto localmente se **preserva** (merge) o `opencode.json` no se sobrescribe; NO se degrada a tokens/`enabled: false`. Idempotente y fail-open (parseo roto → conserva local + WARN).

### T-09 — Herramientas ausentes (RF-07 / SC-005)
1. graphify ausente → no registra + WARN con `uv tool install "graphifyy[mcp]"`.
2. tokenslayer sin `build/index.js` → no registra + instrucciones; bootstrap continúa.

### T-10 — Reporte final (RF-08 / SC-007)
1. Correr bootstrap.
2. **Esperado**: salida con bloque `mcp` + `enabled`/razón por entrada; toda entrada `false` con causa.

### T-11 — DryRun
1. Correr con `-DryRun` → informa todas las acciones sin escribir `opencode.json`/`.env.mcp`.

---

## Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|--------|---------|------------|
| R1 | OpenCode no lee `.env.mcp` automáticamente → `{env:...}` = string vacío | MCP no arranca | **Fallback D2**: usar `environment`/ruta real; `.env.mcp` como fuente de verdad; documentar contrato de carga |
| R2 | `-ForceUpgradeTools` ejecuta instalaciones de terceros | Seguridad/supply-chain | Solo paquetes conocidos y publicados; fail-open; excluido por defecto |
| R3 | El sync sobrescribe `opencode.json` resuelto (RF-06 punto 4) | Regresión del bug | `-SkipSync` en kit **+ A1: ajuste del guard** (merge del bloque `mcp` o exclusión de `opencode.json` del overwrite, idempotente y fail-open) — cierra el bug también en consumidores |
| R4 | Re-resolución incondicional corrompe JSON existente | Config rota | Parche por entrada (`command`/`enabled`); `ConvertTo-Json -Depth 10`; tests T-02/T-03 |
| R5 | Self-update clona repo no confiable | Seguridad | Allowlist `Test-TrustedGithubUrl` (ya existe); `-SkipSelfUpdate`; auto-skip kit |
| R6 | tokenslayer fuera de containment | Seguridad | Containment-check existente (L436-445); RNF-07 |
| R7 | Doble corrida de `Ensure-OpenCodeMcp` (pasos 1 y 4) | WARNs duplicados / doble escritura | `Write-WarnOnce` existente; verificar idempotencia T-01 |

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp` (L345), `Resolve-McpCommand` (L337), `Update-Self` (L1721), `Sync-TransversalKit` (L1801), `Configure-Graphify` (L2480), `Show-ExecutionSummary` (L78).
- `opencode.json` — plantilla `{env:...}`.
- `.gitignore` — `.env.mcp`.
- `dependencias-manifest.yml` — entradas de herramientas externas (`tokenslayer-mcp-server`, `graphify`).
- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — diseño base del bootstrap.
- `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` — re-indexación y memoria.
- Commit `4a13718` — a revertir (RF-06, `opencode.json` con tokens versionados).
- Docs OpenCode — interpolación `{env:VAR}` y MCP local (`environment`).

---

## Fases de implementación

### Fase 0 — Research (salida: `research.md`)
- Confirmar contrato de carga de `.env.mcp` por OpenCode (R1) y elegir fallback definitivo (`environment` vs ruta real).
- Confirmar precedencia y comportamiento del sync sobre `opencode.json` (R3).
- Confirmar que `Update-Self` cumple RF-05 con los endurecimientos listados.

### Fase 1 — Design (salida: `data-model.md`, `quickstart.md`)
- `data-model.md`: entidades `opencode.json`, `.env.mcp`, `.gitignore`, `param()` switches, bloque `mcp`.
- `quickstart.md`: escenarios T-01…T-11 con comandos exactos.
- Re-evaluar Constitution Check post-diseño.

### Fase 2 — Tasks (salida: `tasks.md`, `/speckit-tasks`)
- Descomponer D1-D7 en tareas ordenadas por dependencia (D1 y D2 son bloqueantes; D3-D5 aditivos; D6-D7 reporte).

### Fase 3 — Implement (fuera de `/speckit-plan`)
- Aplicar los parches en `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`.
- Ejecutar la matriz de validación.
- Conventional commits (`fix(bootstrap):`, `feat(bootstrap):`).

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Cobertura 80% (Quality Gate) | El repo no tiene runtime ni framework de tests (kit de configuración). | Añadir un framework de tests (Pester) al kit excede el alcance y las dependencias del proyecto; se sustituye por escenarios deterministas T-01…T-11 + `DryRun`. |
