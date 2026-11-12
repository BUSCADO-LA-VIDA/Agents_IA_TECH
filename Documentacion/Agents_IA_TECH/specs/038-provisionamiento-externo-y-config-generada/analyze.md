# Specification Analysis Report — 038

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Fecha**: 2026-11-12 | **Comando**: `/speckit-analyze`

**Contexto de ejecución**: `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks` → exit `0`, `AVAILABLE_DOCS: research.md, data-model.md, contracts/, quickstart.md, tasks.md`.

**Alcance**: análisis no destructivo de `spec.md`, `plan.md` y `tasks.md` contra `.specify/memory/constitution.md` (v2.1.0). Este archivo es el registro del informe, exigido como artefacto de la cascada por el Art. III de la constitución; ver hallazgo C1.

---

## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| C1 | Constitution Alignment | CRITICAL | `.opencode/skills/speckit-analyze/SKILL.md` L66 · `.specify/memory/constitution.md` Art. III L23 | El comando `speckit-analyze` ordena "STRICTLY READ-ONLY: do not modify any files; output a structured report", mientras el Art. III enumera `analyze.md` como artefacto obligatorio de la cascada. Dos MUST incompatibles: uno exige no escribir, el otro exige el archivo. | Decidir en spec propia cuál de los dos cambia. Mientras tanto este informe se persiste como `analyze.md` (cumple Art. III) y la divergencia queda declarada aquí. No se diluye el principio: se registra para corrección explícita. |
| I1 | Inconsistency | HIGH | `spec.md` §Key Entities L253-276 · `contracts/dependencias-manifest.schema.json` L7 | El ejemplo de manifest de la spec solo muestra `dependencias_externas`, pero el contrato exige además `version_manifest` y `updated`. El ejemplo de la spec no valida contra su propio esquema. | Añadir `version_manifest` y `updated` al ejemplo de la spec, o relajar el `required` del esquema. Gana el esquema (es el que valida en runtime): actualizar el ejemplo. |
| I2 | Inconsistency | MEDIUM | `tasks.md` T011 (Phase 2) | T011 conecta `Validate-Manifest.ps1` "al inicio de los tres verbos", pero los verbos se crean en Phase 3 (T015) y Phase 6 (T041). La tarea referencia archivos que aún no existen en su fase. | Reubicar T011 al final de Phase 3 y repetir la conexión en US-2/US-4, o reformular como "definir el punto de validación que cada verbo invocará". |
| U1 | Coverage Gap | MEDIUM | `spec.md` NFR-04 · `tasks.md` | NFR-04 ("sin secretos en artefactos") no tiene tarea de verificación: ningún test comprueba que `.opencode/mcp-state.json`, `opencode.json` y `.vscode/mcp.json` no contengan tokens, claves ni rutas de credenciales. | Añadir tarea de prueba en `tests/provisioning-generate.Tests.ps1`: escanear los tres artefactos contra patrones de secreto y fallar si aparecen. |
| U2 | Underspecification | MEDIUM | `tasks.md` T049 · `contracts/capability-matrix.schema.json` | T049 manda validar la matriz contra el esquema de fila, pero ninguna tarea implementa el parser que convierte la tabla Markdown en objetos fila. Sin parser, el esquema no tiene entrada. | Añadir tarea explícita de parser (tabla Markdown → objetos) antes de T049, con prueba para fila incompleta. |
| A1 | Ambiguity | MEDIUM | `quickstart.md` QS6 | "Ejecutar con la red deshabilitada (o bloqueando el registro con un proxy inválido)" no da un comando reproducible; el escenario no es verificable tal como está escrito. | Concretar el comando de bloqueo (por ejemplo `$env:NPM_CONFIG_REGISTRY='http://127.0.0.1:1'` y `$env:HTTP_PROXY` inválido) o marcar QS6 como verificación manual con criterio de aceptación explícito. |
| D1 | Duplication | LOW | `tasks.md` T005 · `tasks.md` T048 | T005 crea `capacidades-por-harness.md` ya con las 4 capacidades y `spec_responsable` 040-043; T048 "completa" la misma matriz con las mismas 4 capacidades. | Dejar T005 como creación de estructura vacía con encabezados y T048 como poblado real, o fusionar ambas en una tarea. |
| T1 | Traceability | LOW | `tasks.md` (todas las tareas) | Los requisitos se citan en prosa dentro de la descripción (`(FR-02)`, `(SC-001)`) y no en un campo verificable: un conteo automático de cobertura sobre `tasks.md` devuelve 0 referencias aunque las 58 tareas sí citan requisitos. | Añadir un marcador uniforme al final de cada descripción (`— req: FR-02, SC-001`) para que la cobertura sea comprobable por script. |
| U3 | Underspecification | LOW | `tasks.md` T041 · `contracts/cli-provisioning.contract.md` | El contrato de `apply` incluye `-Force` sin definir su semántica ni su efecto observable; ninguna tarea lo especifica. | Definir `-Force` (¿re-clona el clon? ¿sobrescribe `degraded`?) en el contrato y en una prueba. |
| A2 | Ambiguity | LOW | `tasks.md` T002 | La tarea enumera 11 dependencias, pero la spec solo ejemplifica 2 y no fija el inventario completo. El ejecutor debe inferirlo del `opencode.json` actual. | Añadir el inventario de 11 dependencias a `data-model.md` o a `spec.md` §Key Entities para que T002 no dependa de inferencia. |

**Hallazgos adicionales fuera del alcance de los tres artefactos** (no puntúan en las métricas, se registran porque afectan la ejecución del flujo): `.specify/scripts/powershell/check-prerequisites.ps1` contenía variables inexistentes (`$RepoRoot`, `$AppName`, `$featureDir`) en el bloque "Documentation First" introducido por el commit `de42ff4` (spec 044), lo que hacía que **todo** comando Speckit abortara con exit `1`. Corregido en esta ronda; requiere registro propio porque la 044 creyó cerrar un gate y en realidad lo rompió.

---

## Coverage Summary Table

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|
| FR-01 Taxonomía declarada | ✅ | T002, T008 | Manifest + validación de enum |
| FR-02 Tipo ausente/desconocido = FAIL | ✅ | T008, T012 | Exit 2 y prueba de contrato |
| FR-03 Sonda de versión declarativa | ✅ | T002, T015, T016, T017 | Una sonda por autoridad |
| FR-04 Comparación por SHA | ✅ | T016, T031 | `rev-parse` vs `ls-remote` |
| FR-05 Estado por workspace | ✅ | T018 | Siete estados admitidos + escritura atómica |
| FR-06 Verbo `validate` | ✅ | T015, T019, T020 | Solo lectura + exit codes |
| FR-07 Verbo `apply` fail-open | ✅ | T038, T041 | Degradado con causa, resto continúa |
| FR-08 Verbo `generate` solo resolubles | ✅ | T021, T025 | Omisión con WARN |
| FR-09 Generación dual desde fuente única | ✅ | T025, T026, T027 | Dos generadores + paridad |
| FR-10 `opencode.json` no versionado | ✅ | T001, T003, T025 | Plantilla versionada + preservación de claves |
| FR-11 Forma canónica única | ✅ | T023, T028, T029 | `mcp.servers.<nombre>` |
| FR-12 `requerido` por MCP | ✅ | T002, T018 | Persistido en estado |
| FR-13 Aislamiento del clon | ✅ | T039, T042 | Prueba de ausencia de `AGENTS.md` |
| FR-14 Actualización sin copia | ✅ | T042 | Solo operaciones git |
| FR-15 Matriz de capacidades | ✅ | T005, T045, T046, T047, T048, T049, T050 | Incluye reglas 1-4 y estados deducidos |
| FR-16 Build local verificable | ✅ | T038, T043 | Artefacto declarado obligatorio |
| FR-17 Documento de referencia | ✅ | T051 | `provisionamiento-externo.md` |
| NFR-01 Solo lectura por defecto | ✅ | T014, T020 | `git status` sin cambios de configuración |
| NFR-02 Idempotencia | ✅ | T022 | Hash idéntico |
| NFR-03 Escritura atómica | ✅ | T007, T025 | Temporal + reemplazo |
| NFR-04 Sin secretos en artefactos | ❌ | — | **Sin cobertura** (U1) |
| NFR-05 Fail-open, nunca fail-silent | ✅ | T018, T038 | `causa` obligatoria en degradado/desconocido |
| NFR-06 Portabilidad de rutas | ✅ | T006, T055 | Regresión 16/16 |
| NFR-07 Tiempo de `validate` | ✅ | T033, T036 | 60 s / 15 s |
| NFR-08 Paridad de arneses | ✅ | T024, T027 | Por conjunto y campos |
| SC-001 Detecta defecto actual | ✅ | T013 | `context-mode` con `build/cli.js` |
| SC-002 Config válida y sesión operativa | ✅ | T025, T026, T030, T052 | Quickstart QS2 |
| SC-003 Idempotencia | ✅ | T022 | SHA256 igual |
| SC-004 Paridad de servidores | ✅ | T024 | Mismo conjunto |
| SC-005 100% con tipo y autoridad | ✅ | T010 | Manifest real validado |
| SC-006 Sonda coincide con remoto | ✅ | T031, T037 | Verificación manual cruzada |
| SC-007 Sin rutas absolutas versionadas | ✅ | T006, T055 | Portabilidad |
| SC-008 Sin forma plana | ✅ | T023 | Grep de `mcp.<nombre>` |
| SC-009 Sin artefactos de terceros en raíz | ✅ | T039 | Aislamiento |
| SC-010 Matriz con fuente y versión | ✅ | T048, T049 | Cuatro capacidades iniciales |
| SC-011 `validate-agents-skills` en verde | ✅ | T054 | `FAIL: 0` |
| SC-012 Documento suficiente sin leer código | ✅ | T051 | Referencia por tipo |
| SC-013 FAIL/WARN de capacidades | ✅ | T045, T046, T047 | Tres casos del validador |

**Unmapped Tasks**: ninguna. Las 58 tareas se mapean a al menos un FR, NFR o SC, o a un requisito de gobernanza (T057 → Art. III; T058 → regla de autorización de commit).

---

## Constitution Alignment Issues

| Principio | Estado | Evidencia |
|---|---|---|
| I. Modular Agent Design | PASS | Una responsabilidad por script (`Get-ProvisioningState`, `generate-opencode`, `generate-copilot`, `validate-parity`, `Invoke-ProvisioningApply`, `Validate-Manifest`) con interfaz y exit codes verificables |
| II. Orchestrator Pattern | PASS | `pensador` gobierna, `Agent-SSD` ejecuta los comandos, `developer` implementa, `plataformador` aprovisiona |
| III. Specification-Driven Development | **CONFLICTO** | El ciclo se respeta, pero el skill de analyze ordena no escribir archivos y el Art. III exige `analyze.md` (C1) |
| IV. Copilot/Opencode Compatibility | PASS | Dos generadores + `validate-parity`; diferencia no declarada = FAIL |
| V. Observability | PASS | Estado explícito, exit codes contratados, WARN con causa |
| VI. Dependencias externas / `proyect_ext` | PASS | Clones aislados, manifest versionado, aislamiento verificado por prueba (T039) |
| VII. Restricción de Paths por Tier | PASS | Artefactos en `Documentacion/Agents_IA_TECH/`; código en `scripts/` y `tests/` para el tier implementador |
| VIII. Fail-Open | PASS | `degraded`/`desconocido` con causa, sin abortar el resto |
| IX. Contenido Completo | PASS | Sin placeholders: `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/*`, `tasks.md` y este informe tienen contenido real en todas las secciones |

---

## Metrics

- **Total Requirements**: 38 (17 FR + 8 NFR + 13 SC)
- **Total Tasks**: 58 (T001-T058 en 8 fases)
- **Coverage %**: 97,4 % (37 de 38 requisitos con al menos una tarea)
- **Ambiguity Count**: 2 (A1, A2)
- **Duplication Count**: 1 (D1)
- **Critical Issues Count**: 1 (C1, conflicto constitución ↔ contrato del comando)
- **High Issues Count**: 1 (I1)
- **Medium Issues Count**: 4 (I2, U1, U2, A1)
- **Low Issues Count**: 4 (D1, T1, U3, A2)
- **Unmapped Tasks**: 0

---

## Next Actions

1. **C1 (CRITICAL)** no bloquea la implementación siempre que se acepte explícitamente la decisión registrada aquí: el informe se persiste como `analyze.md` porque el Art. III de la constitución es autoridad no negociable en este alcance. La corrección del contrato del skill (o del Art. III) va en **spec propia**, no dentro de 038.
2. **I1 (HIGH)** conviene resolverlo antes de implementar: actualizar el ejemplo de manifest en `spec.md` con `version_manifest` y `updated` para que sea válido contra `contracts/dependencias-manifest.schema.json`.
3. **U1** (NFR-04 sin tarea) se corrige añadiendo una tarea de prueba de secretos a `tests/provisioning-generate.Tests.ps1`.
4. **I2 / U2 / D1 / T1 / U3 / A2** no bloquean el arranque: se ajustan en `tasks.md` antes de entrar en la fase que tocan.
5. **Siguiente comando del ciclo**: `/speckit-implement` sobre Phase 1 y Phase 3 (MVP: US-1). `/speckit-converge` **no puede ejecutarse todavía**: su contrato exige que `/speckit-implement` haya corrido sobre el `tasks.md` actual, y ninguna tarea está implementada.

**Remediación ofrecida**: ¿querés que proponga los edits concretos para I1, U1, I2 y D1 antes de habilitar `/speckit-implement`? No se aplican sin tu aprobación.
