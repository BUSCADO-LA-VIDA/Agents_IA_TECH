# Analyze: [008-mcp-config-portable] — Análisis cross-artifact de consistencia y calidad

**Feature**: `008-mcp-config-portable`
**Branch**: `008-mcp-config-portable`
**Date**: 2026-09-24
**Version**: 1.0.0
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Tasks**: [tasks.md](./tasks.md)
**Comando**: `/speckit-analyze` (ejecutado por Agent-SSD, Fase 4 del pipeline)

---

## 1. Consistencia entre artefactos (spec → plan → tasks)

### 1.1 Matriz de trazabilidad FR → Decisión → Task

| Requisito | Decisión (plan) | Task (tasks.md) | Estado |
|-----------|-----------------|-----------------|:------:|
| FR-001 (dejar de crear `.opencode/config.json`) | D4 | Task 5 | ✅ |
| FR-002 (eliminar/marcar obsoleto con placeholders) | D4 | Task 5 | ✅ |
| FR-003 (no borrar a ciegas valores reales) | D4 | Task 5 | ✅ |
| FR-004 (inventario central de rutas) | D1 | Task 1 | ✅ |
| FR-004a (capturar ruta al instalar) | D2 | Task 2 | ✅ |
| FR-004b (validar/actualizar ruta) | D2 | Task 2 | ✅ |
| FR-004c (borrar ruta al desinstalar) | D2 | Task 2 | ✅ |
| FR-005 (mecanismo efectivo de resolución) | D3 | Task 3 | ✅ |
| FR-006 (instruir `opencode auth login`) | D5 | Task 6 | ✅ |
| FR-007 (detección defensiva de secrets versionados) | D4 | Task 5 | ✅ |
| FR-008 (exclusión sync + gitignore) | D7 | Task 8 | ✅ |

**Cobertura FR: 11/11 (100%)** — sin requisitos huérfanos.

### 1.2 Matriz de trazabilidad SC → Decisión → Task

| Success Criterion | Decisión (plan) | Task (tasks.md) | Estado |
|-------------------|-----------------|-----------------|:------:|
| SC-001 (no crear config.json en proyectos nuevos) | D4 | Task 5 | ✅ |
| SC-002 (eliminar config.json con placeholders) | D4 | Task 5 | ✅ |
| SC-003 (opencode.json sin rutas absolutas) | D3 | Task 3 | ✅ |
| SC-003a (registro central, mismas rutas en arneses) | D1 | Task 1, Task 4 | ✅ |
| SC-003b (capturar al instalar) | D2 | Task 2 | ✅ |
| SC-003c (validar/actualizar al actualizar) | D2 | Task 2 | ✅ |
| SC-003d (borrar al desinstalar) | D2 | Task 2 | ✅ |
| SC-003e (opencode arranca) | D6 | Task 7 | ✅ |
| SC-004 (MCPs `enabled: true` con ruta resuelta) | D3 | Task 3 | ✅ |
| SC-005 (instruir `opencode auth login`) | D5 | Task 6 | ✅ |
| SC-006 (ningún secrets trackeado) | D7 | Task 8 | ✅ |

**Cobertura SC: 11/11 (100%)** — sin criterios huérfanos.

### 1.3 Matriz de trazabilidad US → Decisión → Task

| User Story | Decisión (plan) | Task (tasks.md) | Estado |
|------------|-----------------|-----------------|:------:|
| US1 (eliminar config.json + memoria segura) | D4 | Task 5 | ✅ |
| US2 (config dinámica portable de MCPs) | D1, D3 | Task 1, Task 3, Task 4 | ✅ |
| US3 (mecanismo efectivo de resolución) | D3 | Task 3 | ✅ |
| US4 (tokens en memoria segura) | D5 | Task 6 | ✅ |

**Cobertura US: 4/4 (100%)** — sin historias huérfanas.

### 1.4 Consistencia de decisiones D1-D7 en tasks

| Decisión (plan) | Task(s) que la implementan | Estado |
|-----------------|----------------------------|:------:|
| D1 — Inventario central = `.env.mcp` ampliado | Task 1 | ✅ |
| D2 — Funciones de inventario (Register/Update/Remove) | Task 2 | ✅ |
| D3 — Config dinámica portable + `context-mode` | Task 3 | ✅ |
| D3b — Consistencia entre arneses | Task 4 | ⚠️ **ver hallazgo H1** |
| D4 — Eliminación de `.opencode/config.json` | Task 5 | ✅ |
| D5 — Tokens en memoria segura | Task 6 | ⚠️ **ver hallazgo H2** |
| D6 — Arranque de opencode | Task 7 | ✅ |
| D7 — Exclusión del sync y gitignore | Task 8 | ✅ |
| (Validación integral) | Task 9 | ⚠️ **ver hallazgo H3** |

### 1.5 Hallazgos de consistencia

#### H1 — Nomenclatura `D3b` no definida en el plan (⚠️ MEDIA)
La **Task 4** introduce la decisión **`D3b`** ("Consistencia entre arneses"), pero el plan define **solo D1-D7** y no existe `D3b`. La consistencia entre arneses (`.vscode/mcp.json` ↔ `opencode.json`) se menciona dentro de **D1** (FR-004) y en el **Constitution Check Art.IV**, pero no tiene una decisión de diseño propia numerada.

**Impacto**: rompe la trazabilidad plan ↔ tasks; un implementador que busque "D3b" en el plan no la encontrará.

**Recomendación**: renombrar la Task 4 para referirse a **D1/FR-004** (consistencia entre arneses) en lugar de `D3b`, **o** añadir `D3b` como decisión explícita en el plan. Se recomienda la primera (menor diff, Ponytail).

#### H2 — Ubicación de la documentación D5 ambigua (⚠️ BAJA)
El plan **D5** dice "Se documenta en `quickstart.md`". La **Task 6** dice "`Documentacion/Agents_IA_TECH/README.md` **o** `quickstart.md` si existe". Hay ambigüedad sobre el archivo destino.

**Impacto**: el implementador podría documentar en un archivo distinto al previsto.

**Recomendación**: fijar el destino. Si `quickstart.md` no existe en el repo, crearlo (o documentar en `README.md`). Verificar existencia antes de implementar.

#### H3 — Task 9 no referencia la matriz de tests T-01..T-13 (⚠️ BAJA)
El plan define una matriz de **13 tests reproducibles (T-01..T-13)**. La **Task 9** (Validación integral) es genérica ("FR-001 a FR-008 se cumplen, SC-001 a SC-006 pasan") y **no referencia T-01..T-13**.

**Impacto**: el QA podría no ejecutar la matriz completa del plan.

**Recomendación**: que la Task 9 referencie explícitamente la matriz T-01..T-13 del plan como checklist de validación.

#### H4 — `enabled: true` en plantilla vs `enabled: false` del plan (⚠️ MEDIA)
El plan **D3** (cambio 3 en `opencode.json`) establece: *"Plantilla versionada: `enabled: false` (seguro por defecto). La resolución local en runtime la promueve a `enabled: true`"*. Sin embargo, el **`opencode.json` actual** tiene `enabled: true` en todas las entradas `mcp` (`codebase-memory-mcp`, `markitdown`, `tokenslayer`, `graphify`).

**Impacto**: contradicción entre el plan y el estado real del archivo. Si la plantilla versionada queda `enabled: true` con `{env:...}` sin resolver, opencode intentará arrancar MCPs con strings vacíos (el bug que la feature 008 busca cerrar).

**Recomendación**: alinear el plan con la realidad. Se recomienda que la plantilla versionada use `enabled: false` (seguro por defecto) y que el runtime la promueva a `enabled: true` solo cuando la ruta esté resuelta — coherente con el ADR-0006 (guardrail 3: un token sin resolver solo puede quedar `enabled: false` con causa). Esto debe confirmarse en Fase 0/1.

#### H5 — `context-mode` ausente en `mcp` (✅ CONFIRMADO)
El plan D3 afirma que falta la entrada `context-mode` en el bloque `mcp` de `opencode.json` (solo está en `plugin`). **Verificado**: el `opencode.json` actual tiene `context-mode` solo en `plugin`, no en `mcp`. La decisión D3 es correcta.

#### H6 — `.gitignore` ya cubre ambos archivos (✅ CONFIRMADO)
El plan D7 pide confirmar que `.gitignore` cubre `.env.mcp` y `.opencode/config.json`. **Verificado**: `.gitignore` línea 7 (`config.json` bajo `.opencode/`) y línea 10 (`.env.mcp`). La decisión D7 es correcta; solo resta confirmar la exclusión del sync transversal.

---

## 2. Análisis de seguridad (foco Art.V de la constitución)

> **Principio V — Observability and Monitoring**: toda interacción, decisión y error debe ser observable. En el contexto de esta feature, la observabilidad se traduce en: reporte final por entrada MCP (`name`/`enabled`/`reason`), WARN accionables, y detección defensiva de secrets versionados.

### 2.1 Threat Model STRIDE

| Threat | Descripción | Afecta | Severidad | Mitigación |
|--------|-------------|--------|:---------:|------------|
| **S**poofing | Un `.opencode/config.json` con placeholders rellenado a mano podría suplantar la identidad del usuario si se commitea con keys reales | FR-001/002/003 | 🔴 Alta | D4: eliminar el archivo; `opencode auth login` como única vía; detección defensiva FR-007 |
| **T**ampering | `opencode.json` versionado con rutas absolutas de la PC podría ser manipulado para apuntar a binarios maliciosos | FR-004, RNF-01 | 🟠 Media | D3: plantilla sin rutas absolutas; rutas resueltas en runtime desde `.env.mcp` gitignored |
| **R**epudiation | Sin reporte por entrada, no se puede auditar qué MCP quedó `enabled` y por qué | Art.V | 🟠 Media | D6/ADR-0006 D7: reporte final `name`/`enabled`/`reason` |
| **I**nformation Disclosure | **Fuga de secrets por commit accidental** de `.opencode/config.json` con keys reales | FR-001/007 | 🔴 **Alta** | D4/FR-007: WARN + `git rm --cached` + rotar keys; `.gitignore` ya lo cubre |
| **I**nformation Disclosure | **Rutas absolutas versionadas** en `opencode.json` revelan estructura del filesystem del usuario | FR-004, RNF-01 | 🟠 Media | D3: plantilla sin rutas absolutas; solo `{env:...}`/relativas |
| **D**enial of Service | **Rutas huérfanas de MCPs** (tras desinstalar) causan fallos al arrancar opencode | FR-004c | 🟠 Media | D2/FR-004c: `Remove-McpPath` borra la ruta del inventario |
| **D**enial of Service | `{env:...}` irresoluble → string vacío → MCP roto → opencode no arranca | FR-005 | 🟠 Media | D3/ADR-0006: nunca persistir `{env:...}` irresoluble; fallback `environment`/ruta real |
| **E**levation of Privilege | `-ForceUpgradeTools` ejecuta instalaciones de terceros (supply-chain) | R5 | 🟠 Media | Solo paquetes conocidos/publicados; fail-open; excluido por defecto |

### 2.2 Riesgos de seguridad etiquetados

#### `security-risk: SEC-01` — Fuga de secrets por commit accidental (🔴 ALTA)
**Descripción**: `.opencode/config.json` con placeholders (`__PEGAR_AQUI_TU_NVIDIA_API_KEY__`, etc.) invita al usuario a rellenarlo con keys reales y commitearlo por accidente. Es el vector de fuga más crítico (documentado en `seguridad/kit-gaps.md` §1.1 y `seguridad/blindaje-git.md` §1.1).

**Mitigación (ya en plan)**: D4 elimina el archivo como mecanismo; FR-007 mantiene la detección defensiva (WARN + `git rm --cached` + rotar keys); `.gitignore` ya lo cubre (verificado H6).

**Validación adicional**: confirmar en Fase 0 que la detección defensiva FR-007 se mantiene tras eliminar `Ensure-OpenCodeConfig` (el plan D4 lo afirma; debe verificarse en el código).

#### `security-risk: SEC-02` — Rutas absolutas versionadas en `opencode.json` (🟠 MEDIA)
**Descripción**: si `opencode.json` versionado contiene rutas absolutas de la PC, se revela estructura del filesystem y se rompe la portabilidad (RNF-01).

**Mitigación (ya en plan)**: D3 mantiene la plantilla sin rutas absolutas; rutas resueltas en runtime desde `.env.mcp` gitignored. Verificado: el `opencode.json` actual usa `{env:...}` y rutas relativas (`proyect_ext/tokenslayer/...`). ✅

#### `security-risk: SEC-03` — Rutas huérfanas de MCPs que causan fallos (🟠 MEDIA)
**Descripción**: tras desinstalar un MCP, si su ruta queda en el inventario, opencode (u otro arnés) intenta arrancar una entrada rota.

**Mitigación (ya en plan)**: D2/FR-004c `Remove-McpPath` borra la ruta del inventario al desinstalar. ✅

#### `security-risk: SEC-04` — `opencode auth login` como mecanismo de secrets (🟠 MEDIA — validar asunción)
**Descripción**: la spec asume (Assumptions) que `opencode auth login` ofrece memoria segura y que `{env:NVIDIA_API_KEY}` / `{env:DEEPINFRA_API_KEY}` se resuelven desde esa memoria. **Sin embargo**, el ADR-0006 establece que `{env:...}` se resuelve desde el **entorno del proceso**, no necesariamente desde el keychain de `opencode auth`. Si `opencode auth login` guarda en un keychain que **no** se exporta como variable de entorno del proceso, entonces `{env:NVIDIA_API_KEY}` podría seguir resolviéndose a string vacío → provider roto.

**Impacto**: la asunción de la spec (que la eliminación de `.opencode/config.json` no rompe la resolución de `{env:...}` porque "se resuelven desde la memoria segura") **puede ser incorrecta**. Es una brecha entre "memoria segura de opencode" y "variables de entorno del proceso".

**Mitigación**: **validar en Fase 0 (Research)** cómo `opencode auth login` expone las keys al proceso (¿exporta variables de entorno? ¿las inyecta opencode al resolver `{env:...}`?). Si no las expone, la feature 008 debe documentar el mecanismo real (p. ej. setear las variables en el entorno del proceso, o usar el campo `environment` del provider). **No asumir** que la memoria segura resuelve `{env:...}` automáticamente.

#### `security-risk: SEC-05` — Borrado a ciegas de secrets reales (🔴 ALTA)
**Descripción**: si el bootstrap borra `.opencode/config.json` con valores reales (no placeholders), se pierden credenciales del usuario.

**Mitigación (ya en plan)**: FR-003/D4 — no borrar a ciegas; WARN + instrucciones de migración sin destruir datos. ✅

#### `security-risk: SEC-06` — Supply-chain por `-ForceUpgradeTools` (🟠 MEDIA)
**Descripción**: `-ForceUpgradeTools` ejecuta instalaciones de terceros (`npm`, `pip`, `uv`).

**Mitigación (ya en plan)**: R5 — solo paquetes conocidos/publicados; fail-open; excluido por defecto. ✅

### 2.3 Conclusión de seguridad

El plan aborda correctamente los riesgos de fuga de secrets (SEC-01, SEC-05) y rutas (SEC-02, SEC-03). El **único riesgo no resuelto** es **SEC-04** (la asunción de que `opencode auth login` resuelve `{env:...}`), que debe validarse en Fase 0. Se recomienda **no cerrar la feature 008 sin validar SEC-04**, porque afecta directamente a la resolución de los API keys de los providers (NVIDIA, DeepInfra).

---

## 3. Análisis arquitectónico (foco Art.I, Art.IV, Art.VIII)

> **Art.I — Modular Agent Design**: cada agente autocontenido, testeable, propósito claro. **Art.IV — Copilot/Opencode Compatibility**: funcionar con ambos arneses, patrones tool-agnostic. **Art.VIII — Gestión de Dependencias Externas / proyect_ext**: estructura y protocolo de `proyect_ext/`.

### 3.1 Evaluación de decisiones D1-D7 contra la constitución

| Decisión | Principio | Evaluación | Veredicto |
|----------|-----------|------------|:---------:|
| **D1** — Reutilizar `.env.mcp` como inventario central | Art.IV, Ponytail | Reutiliza la fuente de verdad existente (feature 007) en lugar de crear un archivo nuevo. Correcto: no hay abstracción innecesaria. Garantiza mismas rutas en arneses (Art.IV). | ✅ **Correcta** |
| **D2** — Funciones de inventario (Register/Update/Remove) | Art.I | Tres funciones modulares, idempotentes, fail-open. Cada una con propósito claro. Cumple Art.I. | ✅ **Correcta** |
| **D3** — Config dinámica portable + `context-mode` | Art.IV, RNF-01 | Plantilla sin rutas absolutas; resolución runtime. Correcto. **Pendiente**: alinear `enabled` (H4). | ⚠️ **Correcta con ajuste H4** |
| **D4** — Eliminar `Ensure-OpenCodeConfig` → `Migrate-OpenCodeSecrets` | Art.V, seguridad | Elimina el mecanismo obsoleto y riesgoso. Correcto. Mantiene detección defensiva (FR-007). | ✅ **Correcta y segura** |
| **D5** — Tokens en memoria segura | Art.V | Instruye `opencode auth login`. Correcto, pero depende de SEC-04 (validar). | ⚠️ **Correcta con riesgo SEC-04** |
| **D6** — Arranque de opencode | Art.V | Verificación final de arranque + reporte por entrada. Cumple observabilidad. | ✅ **Correcta** |
| **D7** — Exclusión del sync y gitignore | Art.IV, Art.VIII | Confirma exclusión de `.env.mcp`/`.opencode/config.json` del sync y git. Correcto. | ✅ **Correcta** |

### 3.2 ¿Es D1 (reutilizar `.env.mcp`) correcto?

**Sí, es correcto.** El `.env.mcp` ya existe como fuente de verdad portable de rutas MCP (feature 007/ADR-0006). Reutilizarlo como inventario central (ampliando variables y añadiendo ciclo de vida) es la opción de menor diff y mayor coherencia (Ponytail: no crear un archivo nuevo cuando ya existe la fuente de verdad). No introduce abstracciones innecesarias.

**Matiz**: el `.env.mcp` pasa a tener **doble rol** (fuente de verdad portable + inventario dinámico con ciclo de vida). Esto es aceptable, pero debe documentarse claramente en `quickstart.md` para evitar confusión (el ADR-0006 ya advierte de la "doble fuente de rutas").

### 3.3 ¿Es D4 (eliminar `Ensure-OpenCodeConfig`) seguro?

**Sí, es seguro** siempre que se respete FR-003 (no borrar a ciegas un archivo con valores reales). El plan lo contempla explícitamente. La eliminación del mecanismo de placeholders cierra el vector de fuga de secrets de raíz (SEC-01). La sustitución por `Migrate-OpenCodeSecrets` mantiene la detección defensiva (FR-007).

**Único matiz**: la eliminación de `Ensure-OpenCodeConfig` no debe romper la resolución de `{env:NVIDIA_API_KEY}` / `{env:DEEPINFRA_API_KEY}`. Esto depende de SEC-04 (validar cómo `opencode auth` expone las keys al proceso). Si la resolución dependía del archivo eliminado, habría regresión.

### 3.4 ¿Hay abstracciones innecesarias?

**No se detectan abstracciones innecesarias.** Las tres funciones de inventario (D2) son necesarias para el ciclo de vida (capturar/validar/borrar). No se crean archivos nuevos (D1 reutiliza `.env.mcp`). No se añaden dependencias. El plan es aditivo y mínimo.

**Posible simplificación (ponytail:)**: `Register-McpPath` y `Update-McpPath` son funcionalmente similares (ambas escriben/actualizan una variable en `.env.mcp`). Podrían unificarse en una sola función con un flag `-Validate`, pero la separación refleja intenciones distintas (instalar vs actualizar) y mejora la legibilidad. Se mantiene la separación como está (no es una abstracción innecesaria, es claridad de intención).

### 3.5 Cumplimiento Art.VIII (proyect_ext)

El plan mantiene `graphify` y `tokenslayer` bajo `proyect_ext/` con containment intacto (RNF-07). No se clonan terceros automáticamente (solo `-ForceUpgradeTools` con paquetes conocidos). Cumple Art.VIII. ✅

---

## 4. Guardrails (restricciones que el código debe cumplir)

> Definidos para la fase de implementación. Todo agente que implemente la feature 008 debe respetarlos. Heredan y amplían los guardrails del ADR-0006.

1. **Nunca persistir `{env:...}` ni `__*_CMD__` irresoluble**: si la variable no está en el entorno del proceso del MCP, se usa la ruta real o el campo `environment`. Un token sin resolver solo puede quedar con `enabled: false` **y causa explícita** (heredado ADR-0006 guardrail 3).
2. **Nunca borrar a ciegas secrets reales**: un `.opencode/config.json` con valores reales (no placeholders) NO se borra; se emite WARN con instrucciones de migración a `opencode auth login` sin destruir credenciales (FR-003).
3. **Idempotencia**: correr el bootstrap N veces produce el mismo bloque `mcp` y conserva `.env.mcp` (solo `-Force` lo re-escribe). Sin duplicados ni corrupción (T-12).
4. **Fail-open en todo lo externo**: self-update, upgrade de herramientas y registro de MCPs degradan con WARN y **nunca** abortan el bootstrap (RNF-04).
5. **Plantilla versionada sin rutas absolutas**: `opencode.json` commiteado usa solo tokens/`{env:...}`/rutas relativas. `.env.mcp` gitignored. Verificable con `git check-ignore .env.mcp` (exit 0).
6. **Parche por entrada, no reescritura del JSON**: la re-resolución modifica solo `command` y `enabled`; el resto de `opencode.json` se preserva byte-a-byte (round-trip `ConvertFrom-Json | ConvertTo-Json -Depth 10`).
7. **Containment de tokenslayer**: rutas bajo `<root>/proyect_ext/tokenslayer/`, sin `..` ni rutas externas (RNF-07).
8. **Sin `npm install` de terceros automático**: prohibido salvo `-ForceUpgradeTools` (excepción acotada a paquetes publicados conocidos); tokenslayer solo se **construye** si el clon existe, nunca se clona.
9. **Observabilidad obligatoria**: toda entrada `enabled: false` lleva causa; el reporte final lista `name`/`enabled`/`reason` por entrada (Art.V).
10. **Frontera de responsabilidad**: el cambio toca SOLO `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore` y documentación (`quickstart.md`/`README.md`). **Nunca** `.opencode/config.json`, ni `Documentacion/<AppName>/` de otra app, ni código de aplicación.
11. **Conventional commits**: `fix(bootstrap):`, `feat(bootstrap):`, `docs(bootstrap):` por grupo lógico.

---

## 5. Riesgos y mitigaciones (consolidado)

> Consolidación de los riesgos del plan (R1-R7) y tasks (Riesgo 1-4) + riesgos de seguridad (SEC-01..SEC-06).

| # | Riesgo | Severidad | Fuente | Mitigación |
|---|--------|:---------:|--------|------------|
| R1 | OpenCode no lee `.env.mcp` → `{env:...}` = string vacío | 🟠 Media | plan R1 | D3: `environment`/ruta real; nunca persistir `{env:...}` irresoluble |
| R2 | Borrar `.opencode/config.json` con valores reales | 🔴 Alta | plan R2, SEC-05 | D4/FR-003: no borrar a ciegas; WARN + migración |
| R3 | El sync sobrescribe `opencode.json` resuelto | 🟠 Media | plan R3 | D7: excluir/ajustar el sync sobre `opencode.json` |
| R4 | Re-resolución incondicional corrompe JSON existente | 🟠 Media | plan R4 | Parche por entrada; `ConvertTo-Json -Depth 10`; T-05/T-12 |
| R5 | `-ForceUpgradeTools` ejecuta instalaciones de terceros | 🟠 Media | plan R5, SEC-06 | Solo paquetes conocidos; fail-open; excluido por defecto |
| R6 | tokenslayer fuera de containment | 🟠 Media | plan R6 | Containment-check; RNF-07 |
| R7 | Rutas huérfanas tras desinstalar un MCP | 🟠 Media | plan R7, SEC-03 | D2/FR-004c: `Remove-McpPath` |
| SEC-01 | Fuga de secrets por commit accidental | 🔴 **Alta** | spec/seguridad | D4 + FR-007 + `.gitignore` (verificado) |
| SEC-02 | Rutas absolutas versionadas | 🟠 Media | spec/seguridad | D3: plantilla sin rutas absolutas |
| SEC-04 | `opencode auth login` no expone keys al proceso → `{env:...}` vacío | 🟠 **Media (validar)** | spec Assumptions | **Validar en Fase 0** cómo `opencode auth` expone las keys; no asumir |

**Riesgo crítico pendiente**: **SEC-04** es el único riesgo no mitigado por el plan actual. Debe validarse en Fase 0 (Research) antes de implementar D4/D5, porque afecta a la resolución de los API keys de los providers.

---

## 6. Recomendaciones (ajustes a spec/plan/tasks)

### Ajustes al plan

1. **Alinear `enabled` en `opencode.json` (H4)**: decidir si la plantilla versionada usa `enabled: false` (seguro por defecto, coherente con ADR-0006 guardrail 3) o `enabled: true`. El plan D3 dice `false`, pero el archivo actual tiene `true`. **Recomendación**: `enabled: false` en la plantilla, promovido a `true` por el runtime solo cuando la ruta esté resuelta.
2. **Añadir `D3b` al plan o renombrar Task 4 (H1)**: la consistencia entre arneses debe tener trazabilidad clara. **Recomendación**: renombrar Task 4 para referirse a D1/FR-004 (menor diff).
3. **Fijar destino de documentación D5 (H2)**: decidir `quickstart.md` vs `README.md`. Verificar si `quickstart.md` existe.
4. **Referenciar T-01..T-13 en Task 9 (H3)**: que la validación integral use la matriz de tests del plan como checklist.

### Ajustes a la spec

5. **Revisar la asunción de `opencode auth login` (SEC-04)**: la spec asume que `{env:...}` se resuelve desde la memoria segura. Esto **no está garantizado** (el ADR-0006 dice que `{env:...}` se resuelve desde el entorno del proceso). La spec debe aclarar el mecanismo real de resolución de los API keys de los providers, o delegar su validación a la Fase 0.

### Ajustes a tasks

6. **Task 4**: renombrar `D3b` → D1/FR-004 (ver H1).
7. **Task 6**: fijar el archivo de documentación (ver H2).
8. **Task 9**: referenciar la matriz T-01..T-13 (ver H3).

### Ajustes de seguridad

9. **Validar SEC-04 en Fase 0** antes de implementar D4/D5: confirmar cómo `opencode auth login` expone las API keys al proceso (¿variables de entorno? ¿inyección de opencode?). Si no las expone, documentar el mecanismo real (setear variables en el entorno del proceso o usar el campo `environment` del provider).

---

## Conclusión

La feature 008 está **bien especificada y planificada**: cobertura cross-artifact del 100% (FR 11/11, SC 11/11, US 4/4), decisiones D1-D7 alineadas con la constitución (Art.I, Art.IV, Art.V, Art.VIII), y guardrails sólidos heredados del ADR-0006. **No hay requisitos huérfanos ni tareas sin trazabilidad.**

Se detectan **4 inconsistencias menores** (H1-H4) y **1 riesgo de seguridad pendiente** (SEC-04). Las inconsistencias son de nomenclatura/alineación y se resuelven con ajustes menores a plan/tasks. El riesgo SEC-04 (resolución de `{env:...}` desde `opencode auth`) debe validarse en Fase 0 antes de implementar D4/D5.

**Veredicto**: **APROBADO con ajustes menores**. La feature puede pasar a la siguiente fase (Converge) tras aplicar las recomendaciones de la sección 6.

---

## Siguiente fase del pipeline

- **Fase siguiente**: `speckit-converge` / `converge.md`
- **Objetivo**: evaluar el estado del código actual contra spec/plan/tasks y anexar cualquier trabajo pendiente como nuevas tareas en `tasks.md` para que `speckit-implement` lo complete.
- **Precondición**: aplicar los ajustes recomendados (sección 6), especialmente la validación de SEC-04 en Fase 0.
