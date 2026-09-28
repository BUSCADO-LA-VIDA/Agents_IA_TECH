---

description: "Task list for feature 007-mcp-token-resolution"
---

# Tasks: [007-mcp-token-resolution] — Resolución de tokens MCP + `.env.mcp` por proyecto + upgrade de herramientas + self-update + activación en el kit maestro

**Input**: Design documents from `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: El repo no tiene framework de tests (kit de configuración, sin runtime). No se generan tareas de test automatizado; la validación se realiza por **escenarios reproducibles** (T-01…T-11 de `plan.md`/`quickstart.md`) convertidos en tareas de verificación explícitas.

**Organization**: Las tareas se agrupan por requisito funcional (RF-01…RF-08), equivalentes a las user stories del flujo SSD. RF-01 (re-resolución) es el MVP. D1 y D2 son bloqueantes; D3-D5 son aditivos; D6-D7 son reporte/degradación.

**Ajustes del análisis (A1-A5)**: las tareas marcadas con `[A1]`…`[A5]` incorporan los 5 ajustes de `analyze.md` §5. Detalle en `converge.md`. **Ninguno modifica `spec.md`.**

- **A1 (MEDIO-ALTO)** — T604: ajustar el guard del sync sobre `opencode.json` (merge/exclusión), no solo documentar.
- **A2 (MEDIO)** — T301, T306, T203: orden `Ensure-McpEnvFile` incondicional antes del primer `Ensure-OpenCodeMcp`.
- **A3 (BAJO)** — T304, T307, T603: plantilla `enabled: false`; runtime la promueve a `true`.
- **A4 (BAJO)** — T003, T602: ruta ÚNICA de revert de `4a13718` (revert selectivo).
- **A5 (BAJO)** — T103, T305: `{env:...}` con var vacía = no resuelto → sustitución obligatoria.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (distintos archivos, sin dependencias pendientes)
- **[Story]**: RF al que pertenece la tarea (US1→RF-01, US2→RF-02, …, US8→RF-08)
- Cada descripción incluye la ruta exacta del archivo afectado

## Path Conventions

Proyecto único de tooling (sin `src/`/`tests/`):

- `scripts/plataformador-bootstrap.ps1` — único archivo de código (2840 líneas)
- `opencode.json` — plantilla versionada con tokens / `{env:...}`
- `.gitignore` — regla `.env.mcp`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Anclajes del contrato CLI y lectura de líneas exactas antes de tocar nada.

- [x] T001 Verificar líneas de anclaje en `scripts/plataformador-bootstrap.ps1`: `param()` (L31-53), `Resolve-McpCommand` (L337-343), `Ensure-OpenCodeMcp` (L345-486), bug "se conserva" (L358-360), re-resolución (L395-414), tokenslayer (L416-469), persistencia JSON (L483-485), `Show-ExecutionSummary` (L78-91), `Update-Self` (L1721-1799), llamada `Update-Self` (L2681-2684), `Sync-TransversalKit` (L1801-1900+, `$transversalItems` L1891-1900), MAIN pasos 1-4 (L2708-2736). Criterio done: cada anclaje confirmado con su línea actual (o delta documentado en `research.md`).
- [x] T002 [P] Confirmar estado de la plantilla `opencode.json` (tokens `__CONTEXT_MODE_CMD__`/`__CODEBASE_MEMORY_CMD__`/`__MARKITDOWN_CMD__`, `enabled: false`) y que `.gitignore` NO contiene `.env.mcp`. Criterio done: estado fijado; base para T101/T102/T201/T202.
- [x] T003 [P] Confirmar el commit a revertir (`4a13718`) en `opencode.json` (RF-06) y registrar el hash corto. Criterio done: `git show --stat 4a13718` revisado — **verificado aislado a `opencode.json` (1 archivo, +8/-7)**; alcance del revert delimitado a la plantilla `opencode.json`; **ruta ÚNICA elegida = `git revert 4a13718`** (no edición manual adicional). [A4]

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestructura compartida que DEBE existir antes de cualquier RF. Ninguna user story puede empezar sin esta fase.

**⚠️ CRITICAL**: D1 y D2 son bloqueantes; D3-D5 dependen de `param()`.

- [x] T004 Agregar switches `[switch]$ForceUpgradeTools` y `[switch]$SkipSync` al `param()` en `scripts/plataformador-bootstrap.ps1` (L31-53, junto a `-SkipSelfUpdate` L52). Criterio done: ambos switches declarados, `-SkipSync` documentado como alias lógico de "modo kit seguro", sintaxis PowerShell válida. [D3, D5 — E4]
- [x] T005 [P] Extender la estructura de reporte con campo de razón por entrada MCP (fuente: `$script:Warnings`/`$script:Errors` L57-59; `Write-WarnOnce` L71) para uso de D7. Criterio done: existe un mecanismo para acumular `name`/`enabled`/`reason` sin duplicar WARNs. [D7 — E6]

**Checkpoint**: `param()` y el canal de razones listos — la re-resolución (D1) y `.env.mcp` (D2) pueden implementarse.

---

## Phase 3: User Story 1 — Re-resolución de tokens SIEMPRE (Priority: P1) 🎯 MVP

**Goal**: Que la re-resolución de tokens MCP corra en toda corrida de `Ensure-OpenCodeMcp`, preservando el resto de `opencode.json`.

**Independent Test**: T-02 + T-03 (plan.md) — un `opencode.json` con sección `mcp` (tokens + `enabled: false`), sin `-Force`, queda con tokens re-resueltos y las claves `provider`/`permission`/`model`/`region`/`plugin` intactas.

### Implementation for User Story 1

- [x] T101 [US1] Neutralizar el early "se conserva" en `scripts/plataformador-bootstrap.ps1` (L358-360): eliminar/reescribir el `if ($existing.mcp -and -not $Force) { Write-OK "...se conserva..." }` para que NO impida la fase de re-resolución. Criterio done: con `mcp` presente y sin `-Force`, el flujo alcanza el bloque de re-resolución. [D1]
- [x] T102 [US1] Extraer la re-resolución de `scripts/plataformador-bootstrap.ps1` (L395-414) a un bloque **incondicional** tras el `if/else` de creación (≈ tras L393, antes de L416), con guarda `if ($null -ne $existing.mcp)`. Criterio done: el bloque ya no está dentro del `else` de creación; corre siempre que exista `mcp`. [D1]
- [x] T103 [US1] Modificar la condición de resolución por entrada (en el bloque de T102) para disparar cuando `command[0]` sea token `__*_CMD__` **o** `{env:*}` **con variable vacía/ausente del entorno del proceso (cuenta como NO resuelto)** **o** ruta vacía. Criterio done: un `{env:...}` vacío se trata como NO resuelto y dispara la sustitución; nunca se persiste un `{env:...}` irresoluble. [D1 — A5, E2 transiciones]
- [x] T104 [US1] Hacer el parche **quirúrgico por entrada**: modificar solo `entry.Value.command` y `entry.Value.enabled`; preservar `type`, `environment`, `cwd`, `timeout` y toda clave ajena. Criterio done: round-trip JSON preserva el resto de `opencode.json` byte-a-byte (salvo el bloque `mcp` tocado). [D1 — E1/E2]
- [x] T105 [US1] Asegurar que entradas `enabled: true` con ruta real válida NO se toquen (retrocompatibilidad). Criterio done: T-03 pasa; una entrada resuelta queda idéntica. [D1 — RNF-02]
- [x] T106 [US1] En `DryRun`, informar el bloque que **resultaría** sin escribir `opencode.json`. Criterio done: `-DryRun` no modifica el archivo y muestra el resultado previsto. [D1 — T-11]
- [x] T107 [US1] Verificar la corrección de `Ensure-OpenCodeMcp` tras los parches (`pwsh -NoProfile -Command "& { . ./scripts/plataformador-bootstrap.ps1 -WhatIf }"` no aplica; validar parseo con `[System.Management.Automation.Language.Parser]::ParseFile`). **[BUG-3 documental]: el parseo DEBE ejecutarse bajo `pwsh` (PowerShell 7+) y NO bajo Windows PowerShell 5.1** — el script es UTF-8 sin BOM y 5.1 lo decodifica en codepage legacy produciendo 92 errores espurios. Comando exacto: `pwsh -NoProfile -Command '[System.Management.Automation.Language.Parser]::ParseFile("scripts/plataformador-bootstrap.ps1",[ref]$t,[ref]$e); $e.Count'` → 0 errores. Criterio done: script parsea sin errores de sintaxis bajo `pwsh`.

**Checkpoint**: RF-01 cubierto de forma aislada — tokens re-resueltos sobre `mcp` existente, claves preservadas.

---

## Phase 4: User Story 2 — Idempotencia (Priority: P1)

**Goal**: Correr el bootstrap N veces produce un bloque `mcp` estable (sin duplicados ni corrupción).

**Independent Test**: T-01 + T-05 (plan.md) — dos corridas consecutivas → bloques equivalentes; con `-Force` no queda token sin resolver.

### Implementation for User Story 2

- [x] T201 [US2] Verificar idempotencia del bloque `mcp` tras D1: correr el bootstrap 2 veces sobre un proyecto sin `mcp` y comparar los bloques serializados (`ConvertFrom-Json | ConvertTo-Json -Depth 10`). Criterio done: 0 claves nuevas, 0 duplicados, rutas idénticas. [RF-02 — T-01]
- [x] T202 [US2] Verificar que `-Force` (que copia la plantilla) NO deja `__*_CMD__` tras la corrida gracias a T102-T103. Criterio done: el bloque `mcp` resultante no contiene ningún token `__*_CMD__`. [RF-02 — T-05]
- [x] T203 [US2] Verificar que la doble invocación de `Ensure-OpenCodeMcp` (MAIN pasos 1 y 4, L2713 y L2735) no genera doble escritura ni WARNs duplicados (apoyarse en `Write-WarnOnce`) **y comparar el bloque `mcp` resultante del paso 1 vs el del paso 4 (deben ser equivalentes)**. Criterio done: salida con WARNs únicos y bloque final consistente tras paso 4; 0 diferencias entre paso 1 y paso 4 (con `Ensure-McpEnvFile` ya corrido antes del paso 1). [R7 — A2]

**Checkpoint**: RF-02 cubierto — idempotencia demostrada con evidencia serializada.

---

## Phase 5: User Story 3 — `.env.mcp` por proyecto (Priority: P1) 🎯 MVP extendido

**Goal**: Crear `<root>/.env.mcp` (gitignored) con las rutas resueltas y referenciar `{env:...}` en `opencode.json`, con fallback efectivo.

**Independent Test**: T-04 (plan.md) — sin `.env.mcp`, la corrida lo crea con 3 variables, lo agrega a `.gitignore`, `git check-ignore` da 0 y el cuadro resumen lo lista.

### Implementation for User Story 3

- [x] T301 [US3] Implementar la función `Ensure-McpEnvFile -RootPath [-DryRun] [-Force]` en `scripts/plataformador-bootstrap.ps1` (≈ tras `Resolve-McpCommand`, L343): resolver `context-mode`, `codebase-memory-mcp`, `markitdown` vía `Resolve-McpCommand`; crear `<root>/.env.mcp` con `CONTEXT_MODE_CMD=`, `CODEBASE_MEMORY_CMD=`, `MARKITDOWN_CMD=` (vacío + WARN si no resuelve). Criterio done: función crea el archivo con formato `NAME=value`. **[A2: se invoca incondicionalmente antes del paso 1 — ver T306]** [D2 — E3, A2]
- [x] T302 [US3] Hacer `Ensure-McpEnvFile` idempotente: si `.env.mcp` existe, conservarlo; con `-Force`, re-escribirlo. Criterio done: segunda corrida no altera el archivo. [D2 — E3]
- [x] T303 [US3] Agregar `.env.mcp` a `.gitignore` desde `Ensure-McpEnvFile` con append idempotente (guard anti-duplicado). Criterio done: `.gitignore` contiene `.env.mcp` una sola vez. [D2 — E5]
- [x] T304 [US3] Cambiar la plantilla `$mcpConfig` en `scripts/plataformador-bootstrap.ps1` (L362-394) para que `command` use `{env:CONTEXT_MODE_CMD}` y análogos en lugar de `__*_CMD__` (mantener `enabled=$false` inicial). Criterio done: plantilla sin tokens `__*_CMD__` y sin rutas absolutas; **la plantilla versionada queda `enabled: false` (el runtime la promueve a `true`)**. [D2 — RNF-01, A3]
- [x] T305 [US3] Implementar el **fallback R-01 / A5**: al resolver, registrar el mecanismo efectivo (campo `environment` del MCP local `{"CONTEXT_MODE_CMD": "<ruta>"}` y/o ruta real en `command`) además de mantener `.env.mcp` como fuente de verdad; un `{env:...}` con **variable vacía/ausente cuenta como NO resuelto** → **sustitución obligatoria** por ruta real/`environment`. Criterio done: en ningún caso queda token `__*_CMD__` ni `{env:...}` irresoluble (alineado con CN-3). [D2 — R1/R-01, A5]
- [x] T306 [US3] Invocar `Ensure-McpEnvFile` **incondicionalmente ANTES del primer `Ensure-OpenCodeMcp`** (MAIN paso 1, L2713) para garantizar disponibilidad de `.env.mcp` antes de persistir `opencode.json`; el paso 4 (L2735) es no-op sobre `mcp` ya resuelto. Criterio done: `.env.mcp` existe antes de la primera resolución; ambos pasos producen el mismo bloque (idempotencia). [D2 — A2]
- [x] T307 [P] [US3] Actualizar la plantilla versionada `opencode.json`: `mcp.<name>.command` → `["{env:CONTEXT_MODE_CMD}"]` y análogos; **la plantilla versionada mantiene `enabled: false`** (el runtime la promueve a `enabled: true`; el commit NO fuerza `true` en la plantilla); sin rutas absolutas. Criterio done: `opencode.json` versionado sin rutas absolutas ni tokens `__*_CMD__`, con `enabled: false`. [D2, D1 — RNF-01, A3]
- [x] T308 [P] [US3] Documentar `.env.mcp` en `_note` de `opencode.json`. Criterio done: `_note` describe tokens/`{env}` + `.env.mcp`. [E1]

**Checkpoint**: RF-03 cubierto — `.env.mcp` creado, gitignored, referenciado por `{env:...}`, con fallback efectivo.

---

## Phase 6: User Story 4 — Forzar upgrade de herramientas externas (Priority: P2)

**Goal**: Flag `-ForceUpgradeTools` que re-instala/actualiza herramientas externas, fail-open.

**Independent Test**: T-06 (plan.md) — con el flag, intenta cada upgrade y reporta OK/WARN; sin flag, no intenta nada.

### Implementation for User Story 4

- [x] T401 [US4] Implementar el gate `-ForceUpgradeTools` en MAIN paso 2 (`scripts/plataformador-bootstrap.ps1`, L2715-2731): `npm install -g context-mode@latest`, `npm install -g codebase-memory-mcp@latest`, `python -m pip install --upgrade 'markitdown[all]'`, `uv tool install "graphifyy[mcp]" --force`, y build de tokenslayer (`proyect_ext/tokenslayer/mcp-server`: `npm install && npm run build`) solo si el clon existe. Criterio done: sin el flag no se ejecuta ninguna instalación. [D3 — RF-04]
- [x] T402 [US4] Envolver cada upgrade en `try/catch` fail-open: exit code ≠ 0 → `Write-Warn` + continuar; nunca abortar el bootstrap. Criterio done: fallo de red/permisos → WARN y el script sigue. [D3 — RNF-04]
- [x] T403 [US4] Reportar OK/WARN por herramienta (usar canal de T005). Criterio done: salida enumera resultado por cada una de las 5 herramientas. [D3]

**Checkpoint**: RF-04 cubierto — upgrades forzables y fail-open.

---

## Phase 7: User Story 5 — Self-update del bootstrap (Priority: P2)

**Goal**: `Update-Self` (ya existente L1721-1799) cumple RF-05 con endurecimientos.

**Independent Test**: T-07 (plan.md) — consumidor desactualizado + red se actualiza y re-ejecuta; kit/`-SkipSelfUpdate` no lo intenta; sin red → WARN.

### Implementation for User Story 5

- [x] T501 [US5] **Validar** (NO reimplementar) `Update-Self` en `scripts/plataformador-bootstrap.ps1` (L1721-1799): confirmar allowlist `Test-TrustedGithubUrl`, auto-skip kit por `origin == RepoUrl` (L1753-1756), SHA256 local vs clon (L1779-1785), comparación de `scripts/plataformador-bootstrap.ps1` en ambos lados (L1772-1773), re-ejecución con `@script:PSBoundParameters` (L1788-1798). Criterio done: checklist de contrato RF-05 completo. [D4]
- [x] T502 [US5] Endurecer limpieza del temp dir `agents-selfupdate-temp` en **todos** los `return` del flujo (revisar L1776, L1783, L1794) y garantizar idempotencia del temp entre corridas. Criterio done: no quedan temp dirs huérfanos en ninguna ruta de salida. [D4]
- [x] T503 [US5] Confirmar que `DryRun` en `Update-Self` solo informa (L1727-1730) y que la invocación gated por `-SkipSelfUpdate` (L2681-2684) permanece intacta. Criterio done: `-DryRun` y `-SkipSelfUpdate` no disparan clon. [D4 — T-07]

**Checkpoint**: RF-05 cubierto — self-update verificado y limpio.

---

## Phase 8: User Story 6 — Activar MCPs en el kit maestro (Priority: P2)

**Goal**: Modo kit seguro (`-SkipSync`) que resuelve/activa MCPs en el kit sin disparar el sync que se sobrescribiría.

**Independent Test**: T-08 (plan.md) — kit con `-SkipSync` → MCPs `enabled: true` y `Sync-TransversalKit` NO ejecutado; consumidor sin el flag → sync normal.

### Implementation for User Story 6

- [x] T601 [US6] Implementar el gate `-SkipSync` en MAIN paso 3 (`scripts/plataformador-bootstrap.ps1`, L2730-2732) para saltar `Sync-TransversalKit` conservando el resto (D1 resolución, D2 `.env.mcp`, D6, D7). Criterio done: con `-SkipSync`, el paso 3 no corre; sin el flag, corre normal. [D5 — RF-06]
- [x] T602 [US6] Revertir el commit `4a13718` en `opencode.json` (**ruta ÚNICA elegida = `git revert 4a13718`**, selectivo, ya que el commit está aislado a este archivo; **NO** ejecutar además la edición de T307 sobre el mismo contenido). Criterio done: `opencode.json` versionado sin rutas absolutas; commit de revert trazable; fallback documentado `git checkout 4a13718^ -- opencode.json` solo si el revert no aplica limpio. [RF-06, A4]
- [x] T603 [US6] Crear `.env.mcp` local en el kit maestro (gitignored) y dejar `opencode.json` del kit con `{env:...}`; **el commit commitea la plantilla con `enabled: false`** y el runtime la promueve a `true` (no forzar `true` en la plantilla versionada). Criterio done: corrida `.\scripts\plataformador-bootstrap.ps1 -SkipSync` deja los MCPs `enabled: true` y `Sync-TransversalKit` NO se ejecuta. [D5 — SC-004, A3]
- [x] T604 [US6] **AJUSTAR el guard del sync** (no solo documentar) de `Sync-TransversalKit` respecto a `opencode.json` en `scripts/plataformador-bootstrap.ps1` (`$transversalItems`, L1891-1900): al copiar `opencode.json` desde el maestro, **preservar el bloque `mcp` resuelto localmente** (merge selectivo: leer `mcp` local, copiar el resto y reinsertar `mcp`) **o excluir `opencode.json` del overwrite** cuando ya exista local. Debe ser idempotente y fail-open (parseo roto → conservar local + WARN). Criterio done: correr el sync en un consumidor con `mcp` resuelto NO degrada `enabled: true` → tokens (`-SkipSync` ya no es la única defensa). [D5 — R3, **A1**]

**Checkpoint**: RF-06 cubierto — kit maestro con MCPs activos sin auto-sobrescritura.

---

## Phase 9: User Story 7 — Manejo de graphify y tokenslayer ausentes (Priority: P3)

**Goal**: No registrar entradas rotas; WARN accionable con comando exacto de instalación.

**Independent Test**: T-09 (plan.md) — graphify ausente → no registra + WARN con `uv tool install "graphifyy[mcp]"`; tokenslayer sin `build/index.js` → no registra + instrucciones; bootstrap continúa.

### Implementation for User Story 7

- [x] T701 [US7] **Validar** el guard de `Configure-Graphify` (`scripts/plataformador-bootstrap.ps1`, L2523-2530): si `python -m graphify.serve --help` falla → WARN con `uv tool install "graphifyy[mcp]"` y NO registra la entrada. Criterio done: patrón confirmado; graphify NO se registra desde `Ensure-OpenCodeMcp`. [D6 — RF-07]
- [x] T702 [US7] **Validar** el guard de tokenslayer (`scripts/plataformador-bootstrap.ps1`, L449-452): si falta `mcp-server/build/index.js` → `Write-WarnOnce` con instrucciones de clonado+build y NO registra. Criterio done: patrón confirmado; containment-check (L436-445) intacto. [D6 — RF-07/RNF-07]
- [x] T703 [US7] Homogeneizar el patrón fail-open de ambos guards y garantizar que `Ensure-OpenCodeMcp` NO deja entradas `enabled: false` sin causa asociada (coordinado con D7). Criterio done: ninguna entrada rota sin razón registrada. [D6]

**Checkpoint**: RF-07 cubierto — degradación con WARN accionable, sin entradas rotas.

---

## Phase 10: User Story 8 — Verificación y reporte final (Priority: P3)

**Goal**: Imprimir el bloque `mcp` resultante + estado `enabled`/razón por entrada.

**Independent Test**: T-10 (plan.md) — la salida incluye bloque `mcp` y toda entrada `false` con causa.

### Implementation for User Story 8

- [x] T801 [US8] Implementar el bloque de reporte final en `Ensure-OpenCodeMcp` (tras persistir JSON, L483-485): imprimir el bloque `mcp` serializado (sin secretos, solo rutas locales) y, por entrada, `name` + `enabled: true|false` + `reason`. Criterio done: salida con bloque `mcp` y razones. [D7 — RF-08/E6]
- [x] T802 [US8] En `DryRun`, imprimir el bloque `mcp` que **resultaría** sin escribir. Criterio done: `-DryRun` muestra el resultado previsto. [D7 — T-11]
- [x] T803 [P] [US8] Integrar con `Show-ExecutionSummary` (`scripts/plataformador-bootstrap.ps1`, L78-91): agregar línea "Rutas MCP en `.env.mcp` — consultá ese archivo". Criterio done: el cuadro resumen lista `.env.mcp`. [D7, D2 — RF-03/RF-08]

**Checkpoint**: RF-08 cubierto — reporte completo y trazable.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Validación end-to-end, seguridad e idempotencia final.

- [x] T901 [P] Ejecutar la matriz completa T-01…T-11 de `quickstart.md`/`plan.md` y registrar evidencia por escenario. Criterio done: cada escenario con resultado esperado vs obtenido.
- [x] T902 [P] Verificar `git check-ignore .env.mcp` → exit 0 y que la plantilla `opencode.json` versionada no contiene rutas absolutas de la PC (`Select-String -Pattern 'C:\\|/Users/'`). Criterio done: SC-003 cumplido. [RNF-01]
- [x] T903 [P] Verificar idempotencia final end-to-end (2 corridas consecutivas + 1 con `-Force`) en un proyecto consumidor genérico. Criterio done: SC-002 cumplido. [RNF-03]
- [x] T904 [P] Verificar cierre de seguridad: `.env.mcp` y `.opencode/config.json` gitignored; sin credenciales en la plantilla; Allowlist de `Update-Self` intacta. Criterio done: `npx ecc-agentshield scan` sin hallazgos nuevos en archivos tocados. [RNF-01]
- [x] T905 Actualizar `quickstart.md` con el contrato de carga de `.env.mcp` (exportar vars o confiar en `environment`) y el ciclo de re-ejecución de `Update-Self`. Criterio done: contrato documentado. [D2/R-01, D4]
- [x] T906 Verificar paridad `.github/` ↔ `.opencode/` si algún cambio afecta agentes/reglas (Regla 3) — para esta feature probablemente N/A. Criterio done: paridad confirmada o N/A justificado. [RNF-05]
- [x] T907 Conventional commits (`fix(bootstrap): resolver tokens MCP siempre`, `feat(bootstrap): .env.mcp`, `feat(bootstrap): flags -ForceUpgradeTools/-SkipSync`) al cerrar cada grupo lógico. Criterio done: historial con conventional commits. [RNF-06]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias — inicia de inmediato.
- **Foundational (Phase 2)**: Depende de Setup — BLOQUEA todas las user stories.
- **User Stories (Phase 3+)**: Dependen de Foundational.
- **D1 (US1) antes de D2 (US3) y D7 (US8)** — la re-resolución es el cimiento.
- **D2 (`Ensure-McpEnvFile`) incondicional ANTES del primer `Ensure-OpenCodeMcp`** (A2) — orden determinista que garantiza idempotencia.
- **D5 (US6) antes de probar en el kit maestro** — sin `-SkipSync` el sync se autosobrescribe.
- **A1 (T604) cierra RF-06 en consumidores** — el guard del sync debe ajustarse, no solo documentarse.
- Resto de RF pueden avanzar en paralelo una vez resuelto el cimiento.
- **Polish (Phase 11)**: Depende de todas las user stories completadas.

### User Story Dependencies

- **US1 (RF-01, P1)**: Bloqueante; base de US2, US3, US8.
- **US2 (RF-02, P1)**: Depende de US1 (idempotencia de la re-resolución).
- **US3 (RF-03, P1)**: Depende de US1 (T102-T103); converge con T307.
- **US4 (RF-04, P2)**: Independiente tras Foundational (solo `param()` + MAIN paso 2).
- **US5 (RF-05, P2)**: Independiente tras Foundational (verificación de código existente).
- **US6 (RF-06, P2)**: Depende de US3 (`.env.mcp`/`{env:...}`) y US1; bloquea la validación en el kit.
- **US7 (RF-07, P3)**: Independiente tras Foundational (validación de guards existentes).
- **US8 (RF-08, P3)**: Depende de US1 y US3 (necesita el bloque resultante y `.env.mcp`).

### Within Each User Story

- Setup → Foundational → US1 (bloqueante) → resto.
- Parche de código antes de la verificación.
- Cada story es un incremento completo y verificable de forma independiente.

### Parallel Opportunities

- **Setup**: T002 y T003 en paralelo (tras T001).
- **Foundational**: T005 puede ir en paralelo con T004 (archivos/zonas distintas).
- **US3**: T307 y T308 en paralelo (plantilla `opencode.json` + `_note`).
- **US8**: T803 en paralelo con T801/T802.
- **Polish**: T901, T902, T903, T904 en paralelo (verificaciones independientes).

---

## Parallel Example: Foundational + US3

```bash
# Foundational (en paralelo):
Task: "T004 Agregar ->ForceUpgradeTools/->SkipSync al param() en scripts/plataformador-bootstrap.ps1"
Task: "T005 Extender estructura de razones en $script:Warnings/Write-WarnOnce"

# US3 (en paralelo, tras D1):
Task: "T307 Actualizar plantilla opencode.json -> {env:CONTEXT_MODE_CMD}"
Task: "T308 Documentar .env.mcp en _note de opencode.json"
```

---

## Implementation Strategy

### MVP First (RF-01 + RF-03)

1. Phase 1 Setup → Phase 2 Foundational.
2. Phase 3 US1 (RF-01, re-resolución incondicional) — **VALIDAR T-02/T-03**.
3. Phase 5 US3 (RF-03, `.env.mcp`) — **VALIDAR T-04**.
4. **STOP and VALIDATE**: un proyecto consumidor con tokens queda con MCPs `enabled: true`.
   → MVP entregable: el bug de tokens sin resolver está cerrado.

### Incremental Delivery

1. Setup + Foundational → base lista.
2. US1 + US3 → MVP (re-resolución + `.env.mcp`).
3. US2 → idempotencia probada.
4. US4 + US5 → upgrades + self-update.
5. US6 → kit maestro activado (depende de US3).
6. US7 + US8 → degradación + reporte.
7. Polish → matriz completa + seguridad + commits.

### Parallel Team Strategy

Con capacidad múltiple (tras Foundational):

- Dev A: US1 → US2 (camino crítico D1/D2).
- Dev B: US4 + US5 (parche `param()`/MAIN paso 2 + verificación `Update-Self`).
- Dev C: US7 (validación guards) + US8 (reporte) tras US1/US3.

---

## Notes

- [P] = tareas sobre zonas/archivos distintos sin dependencias pendientes.
- [Story] mapea la tarea a RF-01…RF-08 para trazabilidad.
- `[A1]`…`[A5]` marcan las tareas que cubren los ajustes del análisis (`analyze.md` §5); detalle en `converge.md`.
- `[US1]`/`[US3]` conforman el MVP mínimo verificable.
- No hay framework de tests: la validación es por escenarios T-01…T-11 (evidencia reproducible) — ver T-03b (A5), T-04b (A2) y T-08b (A1) agregados en `plan.md`.
- Cada grupo lógico cierra con conventional commit.
- Alcance estricto: SOLO `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`. No se tocan `.opencode/config.json` ni `Documentacion/<AppName>/` de otros proyectos.

---

## Estado de implementación

- **Fecha de cierre**: 2026-09-24
- **Estado**: **IMPLEMENTADA + QA APTO**
- **Bugs resueltos**:
  - **BUG-1** — `scripts/plataformador-bootstrap.ps1` L519: uso incorrecto de `-is [IDictionary]` corregido.
  - **BUG-2** — `scripts/plataformador-bootstrap.ps1` L677-681: enumeración por `Keys` corregida.
  - **BUG-3** (documental) — T107 fijado a **`pwsh` (PowerShell 7+)**; NO ejecutar bajo Windows PowerShell 5.1 (UTF-8 sin BOM → 92 errores espurios).
- **Evidencia**: `qa-report.md` — sección "Re-verificación (2026-09-24, post-fix)".
- **Estado del kit maestro**: `.env.mcp` creado con 3 rutas resueltas; MCPs `context-mode`, `codebase-memory-mcp` y `markitdown` con `enabled: true`; `tokenslayer` y `graphify` con `enabled: false` (pendientes de compilar/grafo).
