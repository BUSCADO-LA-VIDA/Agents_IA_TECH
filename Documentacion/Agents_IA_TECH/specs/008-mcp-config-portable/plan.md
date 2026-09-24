# Implementation Plan: [008-mcp-config-portable] — Configuración dinámica y portable de MCPs en OpenCode (eliminación de `.opencode/config.json` y uso de memoria segura)

**Branch**: `008-mcp-config-portable` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-mcp-config-portable/spec.md`

**Note**: Este plan lo produce el comando `/speckit-plan`. Implementación single-file: `scripts/plataformador-bootstrap.ps1` (PowerShell 7+, ~2840 líneas) + `opencode.json` + `.gitignore`. **No hay `src/`** (proyecto kit, no app). Los artefactos viven en `Documentacion/Agents_IA_TECH/specs/008-mcp-config-portable/`.

---

## Summary

La feature 008 **cierra el ciclo** iniciado en la 007 (ADR-0006): elimina el mecanismo obsoleto de gestión de secrets (`.opencode/config.json` con placeholders) y convierte al bootstrap en un **registro central / inventario dinámico de rutas de MCPs** (FR-004) que garantiza que **todos los arneses** (opencode, Copilot, etc.) usen **las mismas rutas**, de forma **dinámica y portable** (sin rutas absolutas versionadas), y que **opencode pueda arrancar** (el arnés que está fallando).

El plan se estructura en **7 decisiones de diseño (D1-D7)** que reutilizan y amplían lo ya implementado en la 007:

1. **D1 — Inventario central de rutas = `.env.mcp` ampliado** (FR-004, FR-004a/b/c): el `.env.mcp` (raíz, gitignored) deja de ser solo "fuente de verdad portable" y pasa a ser el **inventario central dinámico** de rutas de MCPs. Se amplía con las variables de los MCPs adicionales (`TOKENSLayer_CMD`, `GRAPHIFY_CMD`) y se le dota de **ciclo de vida**: capturar al instalar (FR-004a), validar/actualizar al actualizar (FR-004b), borrar al desinstalar (FR-004c). **Reutiliza** el archivo existente (Ponytail: no crear un archivo nuevo cuando ya existe la fuente de verdad).
2. **D2 — Funciones de inventario** (FR-004a/b/c): `Register-McpPath` (capturar), `Update-McpPath` (validar/actualizar), `Remove-McpPath` (borrar). Operan sobre `.env.mcp` de forma idempotente y fail-open.
3. **D3 — Config dinámica portable en `opencode.json`** (FR-005, SC-003/SC-004): el bootstrap genera la config de MCPs resolviendo desde el inventario `.env.mcp` usando el **mecanismo efectivo** del ADR-0006 (campo `environment` o ruta real en `command`). Se añade la entrada **`context-mode`** que falta en `mcp` (solo está en `plugin`). Nunca se persiste un `{env:...}` ni `__*_CMD__` irresoluble.
4. **D4 — Eliminación de `.opencode/config.json`** (FR-001/002/003, US1): se elimina `Ensure-OpenCodeConfig` (RF-17 obsoleto) y se reemplaza por `Migrate-OpenCodeSecrets` que: detecta el archivo, si tiene solo placeholders lo elimina (FR-002), si tiene valores reales avisa cómo migrar sin borrar (FR-003), y siempre instruye a usar `opencode auth login` (FR-006). Mantiene la detección defensiva de secrets versionados (FR-007).
5. **D5 — Tokens en memoria segura** (FR-006, US4): el kit instruye a usar `opencode auth login`; no ofrece la alternativa riesgosa de placeholders. Se documenta en `quickstart.md`.
6. **D6 — Arranque de opencode** (SC-003e): al resolver todas las rutas con `enabled: true` y sin entradas rotas, opencode arranca. Se verifica con `opencode` que los MCPs responden.
7. **D7 — Exclusión del sync y gitignore** (FR-008): se confirma que `.opencode/config.json` y `.env.mcp` quedan excluidos del sync transversal y del control de versiones.

**Enfoque técnico**: parches aditivos minimizando el diff, reutilizando las piezas de la 007 (`Resolve-McpCommand`, `Ensure-McpEnvFile`, `Ensure-OpenCodeMcp`). Sin nuevas dependencias. Idempotente y fail-open. La fuente versionada no contiene rutas absolutas; las rutas resueltas viven en `.env.mcp` (gitignored) y/o en el `opencode.json` local.

---

## Technical Context

**Language/Version**: PowerShell 7+ (`pwsh`). Script único `scripts/plataformador-bootstrap.ps1` (~2840 líneas).

**Primary Dependencies**: `git` (clone shallow para self-update/sync), `npm` (`context-mode`, `codebase-memory-mcp`), `python`/`pip`/`markitdown`, `uv` (`graphifyy[mcp]`), `node` (tokenslayer MCP server). Todas opcionales — el bootstrap degrada con WARN.

**Storage**: Archivos de configuración JSON/`.env` por proyecto:
- `opencode.json` (plantilla versionada con `{env:...}`; resuelto localmente por el bootstrap).
- `<root>/.env.mcp` (por proyecto, gitignored) — **inventario central de rutas de MCPs** (D1).
- `.gitignore` (agrega `.env.mcp` y `.opencode/config.json`).
- `.vscode/mcp.json` (registro MCP para Copilot; se mantiene consistente con el inventario).
- `.opencode/config.json` (OBSOLETO — se elimina/migra en D4).

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
- **Nunca borrar a ciegas** un `.opencode/config.json` con valores reales (FR-003).
- **Nunca persistir** un `{env:...}` ni `__*_CMD__` irresoluble (guardrail 3 del ADR-0006).

**Scale/Scope**: 1 script + 2 archivos de config. ~7 decisiones. Sin agentes nuevos.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación | Estado |
|-----------|-----------|--------|
| I. Modular Agent Design | No se crean agentes. El bootstrap es tooling de plataforma. | ✅ PASS |
| II. Orchestrator Pattern | Cambio de tooling, sin tocar orquestación de agentes. | ✅ PASS |
| III. Specification-Driven Development | Spec `008` existe y precede a la implementación; este plan deriva de ella. | ✅ PASS |
| IV. Copilot/Opencode Compatibility | El inventario central garantiza **las mismas rutas** en todos los arneses (FR-004); `.vscode/mcp.json` (Copilot) y `opencode.json` (OpenCode) se mantienen consistentes. | ✅ PASS |
| V. Observability and Monitoring | Reporte final `mcp` + estado/razón por entrada (heredado de 007 D7) + reporte de migración de secrets. | ✅ PASS |
| VI. proyect_ext / Dependencias Externas | `graphify` (graphifyy) y tokenslayer se mantienen bajo `proyect_ext/`; containment intacto. | ✅ PASS |
| Quality Gates (80% coverage) | No aplica test-framework (repo sin runtime). Se sustituye por escenarios de validación reproducibles. Ver "Complexity Tracking". | ⚠️ JUSTIFIED |

**Sin violaciones que bloqueen.** El único desvío (cobertura) se justifica por la naturaleza del repo (kit sin runtime de tests) y se compensa con una matriz de validación determinista.

---

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/008-mcp-config-portable/
├── spec.md              # Spec de entrada (/speckit-specify)
├── plan.md              # Este archivo (/speckit-plan)
└── tasks.md             # Phase 2 (/speckit-tasks — NO creado por /speckit-plan)
```

### Source Code (repository root)

```text
scripts/
└── plataformador-bootstrap.ps1   # ÚNICO archivo de código modificado (~2840 líneas)

opencode.json                     # Plantilla versionada -> {env:...} + entrada context-mode
.gitignore                        # Agrega .env.mcp y .opencode/config.json

Documentacion/Agents_IA_TECH/
└── specs/008-mcp-config-portable/   # Artefactos de este plan (solo doc)
```

**Structure Decision**: Proyecto único de tooling. No hay `src/`, `tests/`, frontend ni backend. Todos los cambios de código caen en `scripts/plataformador-bootstrap.ps1`; los cambios de datos en `opencode.json` y `.gitignore`. Los artefactos del plan viven aislados en la carpeta de la spec.

---

## Contexto

### Puntos de anclaje verificados (estado actual del script)

| Elemento | Líneas | Estado |
|----------|--------|--------|
| `Resolve-McpCommand` | L345 | `Get-Command $ToolName` → `$found.Source` o `$null` + WARN |
| `Ensure-McpEnvFile` | L359 | Crea `<root>/.env.mcp` con `CONTEXT_MODE_CMD`/`CODEBASE_MEMORY_CMD`/`MARKITDOWN_CMD`; idempotente; agrega a `.gitignore` |
| `Add-McpEnvGitignore` | L~410 | Append idempotente de `.env.mcp` a `.gitignore` |
| `Ensure-OpenCodeMcp` | L431 | Re-resolución incondicional de tokens; registra `context-mode`, `codebase-memory-mcp`, `markitdown`, `tokenslayer`; plugin `context-mode` |
| `Ensure-OpenCodeConfig` | L713 | **OBSOLETO (RF-17)**: crea `.opencode/config.json` con placeholders `__PEGAR_AQUI_TU_...__`. **Se elimina/migra en D4** |
| MAIN paso 1 | L2951-2956 | `Ensure-McpEnvFile` + `Ensure-OpenCodeMcp` |
| MAIN paso 4 | L3031-3032 | `Ensure-OpenCodeMcp` + `Ensure-OpenCodeConfig` (esta última se elimina en D4) |
| `opencode.json` `mcp` | — | **Falta `context-mode`** (solo está en `plugin`). `tokenslayer`/`graphify` usan rutas relativas (portables) |

### Comportamiento de OpenCode verificado (docs oficiales + ADR-0006)

- `{env:VARIABLE_NAME}` en `opencode.json` sustituye variables de entorno; si no está seteada → string vacío. Ya se usa `{env:NVIDIA_API_KEY}`.
- MCP local admite `command: [...]`, `environment: { VAR: value }`, `enabled`, `cwd`, `timeout`.
- OpenCode **no** expone en la doc una carga automática de `.env.mcp` para el bloque `mcp` — solo interpolación `{env:...}` desde el **entorno del proceso**. Conclusión (ADR-0006): el `.env.mcp` es la **fuente de verdad portable/legible**, pero el bootstrap debe además **garantizar la resolución efectiva** (fallback: escribir rutas reales o inyectar `environment`).
- **`opencode auth login`** ofrece **memoria segura** (secure storage) para API keys fuera del control de versiones. Es el destino de los secrets (FR-006, US4).

---

## Decisiones de diseño

### D1 — Inventario central de rutas = `.env.mcp` ampliado (FR-004, FR-004a/b/c)

**Problema**: la feature 007 creó `.env.mcp` como "fuente de verdad portable" de rutas MCP, pero **solo** para `context-mode`, `codebase-memory-mcp` y `markitdown`. No cubre `tokenslayer` ni `graphify`, y **no tiene ciclo de vida** (capturar/validar/actualizar/borrar). El usuario quiere que el bootstrap actúe como **registro central / inventario dinámico** de rutas de MCPs (actuales y futuros) para que **todos los arneses** usen las mismas rutas.

**Decisión**: **reutilizar y ampliar `.env.mcp`** como inventario central (Ponytail: no crear un archivo nuevo cuando ya existe la fuente de verdad). El `.env.mcp` pasa a ser el **inventario central dinámico de rutas de MCPs**:

- **Ampliar las variables** para cubrir todos los MCPs del kit:
  - `CONTEXT_MODE_CMD` (existente)
  - `CODEBASE_MEMORY_CMD` (existente)
  - `MARKITDOWN_CMD` (existente)
  - `TOKENSLayer_CMD` (nueva — ruta del binario `mcp-server/build/index.js` de tokenslayer)
  - `GRAPHIFY_CMD` (nueva — comando `python -m graphify.serve <repo>/graphify-out/graph.json`)
- **Formato**: `NAME=value`, una por línea (compatible `.env`). Sin secretos — solo rutas.
- **Fuente única**: `opencode.json` (OpenCode) y `.vscode/mcp.json` (Copilot) **consumen las mismas rutas** desde este inventario → consistencia entre arneses (FR-004).
- **Ciclo de vida** (FR-004a/b/c) implementado por las funciones de D2.

**Archivos/líneas**: `Ensure-McpEnvFile` (L359) — ampliar el mapa de herramientas; `.gitignore` (ya cubre `.env.mcp`).

**Criterios cubiertos**: FR-004, SC-003a.

---

### D2 — Funciones de inventario: capturar / validar / borrar (FR-004a/b/c)

**Problema**: no existe ninguna función que gestione el **ciclo de vida** de las rutas en el inventario. El usuario quiere: capturar al instalar (FR-004a), validar/actualizar al actualizar (FR-004b), borrar al desinstalar (FR-004c).

**Decisión**: tres funciones modulares que operan sobre `.env.mcp` de forma **idempotente** y **fail-open**:

- **`Register-McpPath -Name <var> -Value <ruta>`** (FR-004a): captura la ruta de un MCP al instalarlo y la escribe en `.env.mcp`. Si la variable ya existe con el mismo valor → no-op (idempotente). Si existe con valor distinto → la actualiza (WARN informativo). `-DryRun` informa sin escribir.
- **`Update-McpPath -Name <var> -Value <ruta>`** (FR-004b): valida la ruta de un MCP al actualizarlo (nueva versión/ubicación) y la actualiza en `.env.mcp` si cambió. Reutiliza `Resolve-McpCommand` para re-resolver la ruta real. Si la ruta nueva difiere de la almacenada → la actualiza + WARN. Si es igual → no-op.
- **`Remove-McpPath -Name <var>`** (FR-004c): borra la ruta de un MCP del inventario al desinstalarlo, para que no queden **rutas huérfanas** que causen fallos al arrancar opencode u otro arnés. Si la variable no existe → no-op. `-DryRun` informa sin escribir.

**Integración**: estas funciones se invocan desde los puntos de instalación/actualización/desinstalación del bootstrap (paso 2 `Ensure-Command`, `-ForceUpgradeTools`, y un nuevo flujo de desinstalación). El `Ensure-McpEnvFile` (D1) las usa para poblar el inventario inicial.

**Archivos/líneas**: nuevas funciones tras `Ensure-McpEnvFile` (L~410); invocación en MAIN paso 2 y `-ForceUpgradeTools`.

**Criterios cubiertos**: FR-004a, FR-004b, FR-004c, SC-003b, SC-003c, SC-003d.

---

### D3 — Config dinámica portable en `opencode.json` (FR-005, SC-003/SC-004)

**Problema**: `opencode.json` versionado usa `{env:...}` con `enabled: true`, pero OpenCode **no lee `.env.mcp`** → strings vacíos → MCPs rotos. Además **falta la entrada `context-mode`** en `mcp` (solo está en `plugin`). El usuario quiere que el bootstrap genere la config dinámica portable con el **mecanismo efectivo** (campo `environment` o ruta real en `command`).

**Decisión**: el bootstrap genera la config de MCPs en `opencode.json` resolviendo desde el inventario `.env.mcp` (D1) usando el **mecanismo efectivo** del ADR-0006:

- **Añadir la entrada `context-mode`** al bloque `mcp` de `opencode.json` (falta hoy). Se resuelve igual que las demás.
- **Mecanismo efectivo por entrada**:
  - Si la variable del inventario está disponible en el entorno del proceso → se conserva `{env:...}` y `enabled: true`.
  - Si no → se escribe la **ruta real** en `command` (o se inyecta el campo `environment`) y `enabled: true`.
  - **Nunca** se persiste un `{env:...}` ni `__*_CMD__` irresoluble (guardrail 3 del ADR-0006).
- **Portabilidad**: `opencode.json` versionado **no contiene rutas absolutas** (solo `{env:...}`/rutas relativas como `proyect_ext/tokenslayer/...`). Las rutas reales se resuelven en runtime por el bootstrap.
- **Reutiliza** la re-resolución incondicional de `Ensure-OpenCodeMcp` (007 D1) — solo se amplía el mapa de herramientas y se añade `context-mode`.

**Archivos/líneas**: `Ensure-OpenCodeMcp` (L431) — ampliar `$tokenMap` con `context-mode`, `tokenslayer`, `graphify`; `opencode.json` — añadir entrada `context-mode` en `mcp`.

**Criterios cubiertos**: FR-005, SC-003, SC-004.

---

### D4 — Eliminación de `.opencode/config.json` (FR-001/002/003, US1)

**Problema**: `Ensure-OpenCodeConfig` (RF-17, L713) crea `.opencode/config.json` con placeholders `__PEGAR_AQUI_TU_...__` que el usuario debe rellenar a mano. Este mecanismo es **obsoleto y riesgoso** (fuga de secrets por commit accidental). Los tokens viven en la memoria segura de opencode (`opencode auth login`).

**Decisión**: **eliminar `Ensure-OpenCodeConfig`** y reemplazarla por **`Migrate-OpenCodeSecrets`** que:

- **FR-001**: deja de crear `.opencode/config.json` con placeholders en proyectos nuevos.
- **FR-002**: si el archivo existe y contiene **solo placeholders** → lo **elimina** (o lo marca obsoleto con WARN) e instruye a usar `opencode auth login`.
- **FR-003**: si el archivo existe y contiene **valores reales** (no placeholders) → **NO lo borra a ciegas** (podría perder credenciales); emite WARN con instrucciones de migración a `opencode auth login` sin destruir datos.
- **FR-006**: siempre instruye a usar `opencode auth login` (memoria segura).
- **FR-007**: mantiene la **detección defensiva** de secrets versionados (WARN con `git rm --cached` + rotar keys) si el archivo aparece trackeado por git.
- **FR-008**: confirma que `.opencode/config.json` queda excluido del sync transversal y del control de versiones.

**Migración de la invocación**: en MAIN paso 4 (L3032), se reemplaza `Ensure-OpenCodeConfig -RootPath $resolvedRoot` por `Migrate-OpenCodeSecrets -RootPath $resolvedRoot`.

**Archivos/líneas**: eliminar `Ensure-OpenCodeConfig` (L713-~790); nueva `Migrate-OpenCodeSecrets`; MAIN paso 4 (L3032).

**Criterios cubiertos**: FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, SC-001, SC-002, SC-005, SC-006.

---

### D5 — Tokens en memoria segura (FR-006, US4)

**Problema**: el kit no instruye de forma consistente a usar `opencode auth login`; el mecanismo de placeholders invita al error.

**Decisión**: el kit **no ofrece la alternativa riesgosa** de placeholders. Se documenta en `quickstart.md` el flujo de configuración de secrets:
- `opencode auth login` → guarda las API keys (NVIDIA, DeepInfra, etc.) en la **memoria segura** de opencode.
- `opencode.json` referencia `{env:NVIDIA_API_KEY}` / `{env:DEEPINFRA_API_KEY}` que se resuelven desde la memoria segura (o el entorno del proceso), **no** desde un archivo versionado.
- El bootstrap, en `Migrate-OpenCodeSecrets` (D4), instruye este flujo.

**Archivos/líneas**: `quickstart.md` (documentación); `Migrate-OpenCodeSecrets` (D4).

**Criterios cubiertos**: FR-006, SC-005.

---

### D6 — Arranque de opencode (SC-003e)

**Problema**: opencode está fallando por MCPs rotos (strings vacíos de `{env:...}` sin resolver, falta `context-mode`).

**Decisión**: al resolver todas las rutas con `enabled: true` y sin entradas rotas (D3), opencode puede arrancar. Se añade una **verificación de arranque**:
- Tras generar la config (D3), se verifica que cada MCP instalado queda `enabled: true` con ruta válida (reporte final heredado de 007 D7).
- Se confirma que **no hay entradas rotas** (ninguna `enabled: false` sin causa).
- Se documenta en `quickstart.md` el comando de verificación (`opencode` arranca y los MCPs responden).

**Archivos/líneas**: `Ensure-OpenCodeMcp` (reporte final); `quickstart.md`.

**Criterios cubiertos**: SC-003e.

---

### D7 — Exclusión del sync y gitignore (FR-008)

**Problema**: el sync transversal (`Sync-TransversalKit`) podría copiar `.opencode/config.json` del maestro, y `.env.mcp`/`.opencode/config.json` deben quedar fuera del control de versiones.

**Decisión**:
- **Confirmar** que `.opencode/config.json` y `.env.mcp` están **excluidos** del sync transversal (`$transversalFiles` en `Sync-TransversalKit` no los incluye).
- **Confirmar** que `.gitignore` cubre ambos (`.env.mcp` ya está; `.opencode/config.json` debe verificarse).
- Si el sync copiara `.opencode/config.json` → excluirlo explícitamente (FR-008).

**Archivos/líneas**: `Sync-TransversalKit` (`$transversalFiles`); `.gitignore`.

**Criterios cubiertos**: FR-008, SC-006.

---

## Cambios por archivo

### `scripts/plataformador-bootstrap.ps1`

| # | Zona (líneas aprox.) | Cambio | Decisión |
|---|----------------------|--------|----------|
| 1 | L359 `Ensure-McpEnvFile` | Ampliar el mapa de herramientas con `TOKENSLayer_CMD` y `GRAPHIFY_CMD` | D1 |
| 2 | Tras `Ensure-McpEnvFile` (L~410) | Nuevas funciones `Register-McpPath`, `Update-McpPath`, `Remove-McpPath` | D2 |
| 3 | L431 `Ensure-OpenCodeMcp` | Ampliar `$tokenMap` con `context-mode`, `tokenslayer`, `graphify`; añadir entrada `context-mode` al bloque `mcp` | D3 |
| 4 | L713-~790 `Ensure-OpenCodeConfig` | **Eliminar** (RF-17 obsoleto); reemplazar por `Migrate-OpenCodeSecrets` | D4 |
| 5 | L3032 MAIN paso 4 | Reemplazar `Ensure-OpenCodeConfig` por `Migrate-OpenCodeSecrets` | D4 |
| 6 | MAIN paso 2 / `-ForceUpgradeTools` | Invocar `Register-McpPath`/`Update-McpPath` al instalar/actualizar; `Remove-McpPath` al desinstalar | D2 |
| 7 | `Sync-TransversalKit` (`$transversalFiles`) | Confirmar/excluir `.opencode/config.json` y `.env.mcp` del sync | D7 |

### `opencode.json`

| # | Cambio | Decisión |
|---|--------|----------|
| 1 | Añadir entrada `context-mode` al bloque `mcp` (falta hoy; solo está en `plugin`) | D3 |
| 2 | `mcp.<name>.command` → `["{env:...}"]` o ruta relativa (portable); sin rutas absolutas versionadas | D3, RNF-01 |
| 3 | Plantilla versionada: `enabled: false` (seguro por defecto). La resolución local en runtime la promueve a `enabled: true` | D3, A3 (heredado 007) |

### `.gitignore`

| # | Cambio | Decisión |
|---|--------|----------|
| 1 | Confirmar `.env.mcp` (ya está) | D1, RNF-01 |
| 2 | Confirmar/agregar `.opencode/config.json` | D4, FR-008 |

---

## Estrategia de pruebas

> El repo no tiene test-framework. La validación es por **escenarios reproducibles**. Documentar cada uno con comando exacto y resultado esperado.

### T-01 — Inventario central ampliado (FR-004 / SC-003a)
1. Correr el bootstrap en un proyecto nuevo.
2. **Esperado**: `.env.mcp` contiene `CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`, `TOKENSLayer_CMD`, `GRAPHIFY_CMD` (las que resuelven). `opencode.json` y `.vscode/mcp.json` usan las mismas rutas.

### T-02 — Capturar al instalar (FR-004a / SC-003b)
1. Instalar un MCP (p. ej. `context-mode`).
2. Correr el bootstrap.
3. **Esperado**: la ruta queda registrada en `.env.mcp` (`Register-McpPath`).

### T-03 — Validar/actualizar al actualizar (FR-004b / SC-003c)
1. Actualizar un MCP (nueva versión/ubicación).
2. Correr el bootstrap con `-ForceUpgradeTools`.
3. **Esperado**: la ruta se re-resuelve y se actualiza en `.env.mcp` si cambió (`Update-McpPath`).

### T-04 — Borrar al desinstalar (FR-004c / SC-003d)
1. Desinstalar un MCP.
2. Correr el bootstrap.
3. **Esperado**: la ruta se borra de `.env.mcp` (`Remove-McpPath`); no quedan rutas huérfanas.

### T-05 — Config dinámica portable (FR-005 / SC-003 / SC-004)
1. Correr el bootstrap.
2. **Esperado**: `opencode.json` versionado no contiene rutas absolutas; cada MCP instalado queda `enabled: true` con ruta resuelta (vía `environment` o ruta real); sin `__*_CMD__` ni `{env:...}` irresolubles.

### T-06 — Entrada `context-mode` presente (D3)
1. Correr el bootstrap.
2. **Esperado**: `opencode.json` `mcp` incluye `context-mode` (además de `codebase-memory-mcp`, `markitdown`, `tokenslayer`, `graphify`).

### T-07 — Eliminación de `.opencode/config.json` (FR-001/002/003 / SC-001/002)
1. Proyecto nuevo → **Esperado**: NO se crea `.opencode/config.json`.
2. Proyecto con `.opencode/config.json` de solo placeholders → **Esperado**: se elimina (o marca obsoleto con WARN) + instrucción `opencode auth login`.
3. Proyecto con `.opencode/config.json` con valores reales → **Esperado**: NO se borra; WARN con instrucciones de migración sin destruir credenciales.

### T-08 — Tokens en memoria segura (FR-006 / SC-005)
1. Verificar que el kit no crea ningún archivo de secrets con placeholders.
2. **Esperado**: la documentación y el bootstrap instruyen a usar `opencode auth login`.

### T-09 — Detección defensiva de secrets versionados (FR-007 / SC-006)
1. Simular `.opencode/config.json` trackeado por git.
2. Correr el bootstrap.
3. **Esperado**: WARN con `git rm --cached` + rotar keys.

### T-10 — Arranque de opencode (SC-003e)
1. Correr el bootstrap.
2. **Esperado**: opencode arranca; los MCPs quedan con rutas válidas, sin entradas rotas que impidan el arranque.

### T-11 — Exclusión del sync y gitignore (FR-008)
1. Correr el sync transversal.
2. **Esperado**: `.opencode/config.json` y `.env.mcp` no se copian del maestro; `git check-ignore .env.mcp` → exit 0.

### T-12 — Idempotencia (RNF-02)
1. Correr el bootstrap 2 veces + 1 con `-Force`.
2. **Esperado**: bloques `mcp` idénticos; `.env.mcp` conservado sin cambios (salvo `-Force`).

### T-13 — DryRun
1. Correr con `-DryRun`.
2. **Esperado**: informa todas las acciones sin escribir `opencode.json`/`.env.mcp`/`.opencode/config.json`.

---

## Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|--------|---------|------------|
| R1 | OpenCode no lee `.env.mcp` automáticamente → `{env:...}` = string vacío | MCP no arranca | **D3**: usar `environment`/ruta real; `.env.mcp` como inventario; nunca persistir `{env:...}` irresoluble (heredado ADR-0006) |
| R2 | Borrar `.opencode/config.json` con valores reales | Pérdida de credenciales | **D4/FR-003**: no borrar a ciegas; WARN + instrucciones de migración |
| R3 | El sync sobrescribe `opencode.json` resuelto | Regresión del bug | **D7**: excluir/ajustar el sync sobre `opencode.json` (heredado 007 A1) |
| R4 | Re-resolución incondicional corrompe JSON existente | Config rota | Parche por entrada (`command`/`enabled`); `ConvertTo-Json -Depth 10`; tests T-05/T-12 |
| R5 | `-ForceUpgradeTools` ejecuta instalaciones de terceros | Seguridad/supply-chain | Solo paquetes conocidos y publicados; fail-open; excluido por defecto |
| R6 | tokenslayer fuera de containment | Seguridad | Containment-check existente; RNF-07 |
| R7 | Rutas huérfanas tras desinstalar un MCP | Fallo al arrancar opencode | **D2/FR-004c**: `Remove-McpPath` borra la ruta del inventario |

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp` (L431), `Ensure-McpEnvFile` (L359), `Resolve-McpCommand` (L345), `Ensure-OpenCodeConfig` (L713, a eliminar), `Sync-TransversalKit`, `Show-ExecutionSummary`.
- `opencode.json` — plantilla `{env:...}` + entrada `context-mode`.
- `.gitignore` — `.env.mcp` y `.opencode/config.json`.
- `dependencias-manifest.yml` — entradas de herramientas externas (`tokenslayer-mcp-server`, `graphify`).
- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — diseño base del bootstrap (RF-03, RF-16, RF-17).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0006-mcp-token-resolution.md` — mecanismo efectivo de resolución (feature 007).
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/` — plan/data-model de la 007 (base reutilizada).
- Docs OpenCode — interpolación `{env:VAR}`, MCP local (`environment`), `opencode auth login` (memoria segura).

---

## Fases de implementación

### Fase 0 — Research (salida: `research.md`)
- Confirmar el contrato de carga de `.env.mcp` por OpenCode (R1) y el mecanismo efectivo (heredado ADR-0006).
- Confirmar el comportamiento del sync sobre `opencode.json` y `.opencode/config.json` (R3, D7).
- Confirmar que `opencode auth login` es el mecanismo de memoria segura (FR-006).

### Fase 1 — Design (salida: `data-model.md`, `quickstart.md`)
- `data-model.md`: entidades `.env.mcp` (inventario ampliado), `opencode.json` (bloque `mcp` + `context-mode`), `.opencode/config.json` (obsoleto), funciones de inventario.
- `quickstart.md`: escenarios T-01…T-13 con comandos exactos + flujo de secrets con `opencode auth login`.
- Re-evaluar Constitution Check post-diseño.

### Fase 2 — Tasks (salida: `tasks.md`, `/speckit-tasks`)
- Descomponer D1-D7 en tareas ordenadas por dependencia (D1 y D2 son bloqueantes; D3-D7 aditivos).

### Fase 3 — Implement (fuera de `/speckit-plan`)
- Aplicar los parches en `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`.
- Ejecutar la matriz de validación.
- Conventional commits (`fix(bootstrap):`, `feat(bootstrap):`, `docs(bootstrap):`).

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Cobertura 80% (Quality Gate) | El repo no tiene runtime ni framework de tests (kit de configuración). | Añadir un framework de tests (Pester) al kit excede el alcance y las dependencias del proyecto; se sustituye por escenarios deterministas T-01…T-13 + `DryRun`. |
| Ampliar `.env.mcp` en lugar de crear un inventario nuevo | Reutilizar la fuente de verdad existente (Ponytail ladder: reutilizar, no crear). | Crear un archivo de inventario separado añadiría una segunda fuente de rutas que habría que sincronizar con `.env.mcp`, violando el principio de fuente única (FR-004). |
