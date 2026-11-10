# Pendientes de implementación — Agents_IA_TECH

## Estado general del proyecto
- **Última actualización:** 2026-11-09
- **Fase actual:** Spec 044 implementada con validación automática en verde (16/16 Pester); AC manuales y commit pendientes. Spec 045 (hook `context-mode`) aplicada como hotfix. Spec 046 (generación portable de `opencode.json`) en borrador. Spec 039 activa, con su criterio de aceptación ampliado por la 044.
- **Specs con tareas:** 21 (incl. 036, 037, 039, 044, 045 y 046)
- **Total de tareas inventariadas:** 251 base + 28 de la spec 044 + 5 de la 045 (RF) + 7 de la 046
- **Próxima tarea:** cerrar la 044 (AC manuales T009/T026/T027, `converge.md`, commit); después aprobar la 046 y ejecutar su `plan.md`

## Specs 039–046 — estado para retomar

| Spec | Estado | Qué falta | Dónde está | Cómo se retoma |
|---|---|---|---|---|
| **039** | Activa — implementada v1.0.0; AC-1/AC-2 superados por la 044 | Nada dentro de su alcance original. Decidir si se cierra formalmente o queda como antecedente | `specs/039-eliminar-rutas-hardcoded-documentacion/` | revisar `converge.md` y marcar cierre en este archivo |
| **044** | Implementada — validación automática 16/16 (764 archivos), sin `converge.md` ni commit | T009 señuelo, T014 mapeo de tokens, T016 arranque del arnés, T017 rollback, T026 bootstrap en proyecto limpio, T027 regresión de 5 suites, T028 commit | `specs/044-portabilidad-validacion-sin-exclusiones/` | `Invoke-Pester tests\validate-no-hardcoded-paths.Tests.ps1` |
| **045** | Implementada (hotfix) v1.0.0 | AC-4: confirmar tras recargar el arnés que las lecturas > 16 KB ya no se deniegan | `specs/045-hook-context-mode-lecturas-bloqueadas/` | recargar VS Code y abrir un `.md` grande |
| **046** | Borrador | Aprobar y pasar a `plan.md`; corregir G1 (maestro portable), G2 (`graphify` por destino), G3 (`tokenslayer` relativo), G4 (bootstrap sin plantilla) | `specs/046-generacion-portable-opencode-json/` | `speckit-plan` de 046 |

### Tareas pendientes de la Spec 044

| ID | Tarea | Responsable | Estado | Criterio de done |
|---|---|---|---|---|
| 044-T009 | Señuelo: archivo temporal con ruta literal → detección y `exit 1`; luego borrarlo | `qa-senior` | Pendiente | salida con `archivo:línea` y exit code 1 |
| 044-T014 | Mapear cada `{env:<VAR>}` de la plantilla a su clave de `.env.mcp` | `plataformador` | Pendiente | tabla VAR → clave verificada |
| 044-T016 | Verificar arranque del arnés con la configuración resuelta | `plataformador` | Pendiente | 8 MCP activos tras reinicio |
| 044-T017 | Documentar rollback de las dos configuraciones | `plataformador` | Pendiente | sección en bitácora |
| 044-T026 | Bootstrap `-CheckHardcodedPaths` en proyecto limpio | `plataformador` | Pendiente | `[OK] 0/N` |
| 044-T027 | Regresión de las 5 suites (`harness-default`, `kit-sync-merge`, `agents-parity`, `kb-parity`, `mcp-refresh-parity`) | `qa-senior` | Pendiente | exit 0 (o divergencia preexistente documentada) |
| 044-T028 | `converge.md` + commit conventional | `documentador` + `gitflow` | Pendiente | `git log -1` y `converge.md` presente |
| 044-DEC-01 | Decidir el destino de `.bootstrap-audit.log` (fuera del índice, en disco) | usuario | Pendiente | decisión registrada |



## Sin asignar

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 036-T006 | 036 | Mover sync-skills.ps1 a scripts/sync-skills.ps1 | Mover `scripts/sync/skills/sync-skills.ps1` a `scripts/sync-skills.ps1` (layout plano, no anidado). Actualizar referencias internas y rutas relativas. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T007 | 036 | Crear scripts/sync-github-extras.ps1 | Crear capa para `.github/rules/`, `.github/prompts/`, `.github/workflows/` y `.github/copilot-instructions.md` con parámetros `-StageDir`, `-RootPath`, `-DryRun`, `-Force`, `-Kind rules|prompts|workflows|copilot`. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T008 | 036 | Crear scripts/sync-tests-kit.ps1 | Crear capa de whitelist de tests del kit: `tests/harness-default.ps1`, `tests/kit-sync-merge.ps1`, `tests/agents-parity.ps1`, `tests/kb-parity.ps1`, `tests/mcp-refresh-parity.ps1`. Respaldar tests del proyecto que colisionen por nombre; no borrar tests fuera de whitelist. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T009 | 036 | Crear scripts/sync-mcp-graphify.ps1 | Crear capa que deje una sola entrada `graphify` canónica (spec 020, forma `mcp.servers`), regenere ruta cuando apunte fuera de `RootPath`, preservar `enabled` del usuario, emitir WARN al detectar duplicados. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T010 | 036 | Crear scripts/sync-backup-prune.ps1 | Crear capa de poda de `.kit-backup/` que excluya carpetas existentes antes de iniciar la corrida, exponga `-KeepBackups <n>` y `-NoPrune`, registre cada borrado (ruta, tamaño, regla), fail-open con WARN. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T011 | 036 | Actualizar $script:Layers en sync-kit.ps1 | Añadir las nuevas capas (`skills`, `github-extras`, `tests-kit`, `mcp-graphify`, `backup-prune`) a `$script:Layers` con `Script`, `AcceptsForce`, `NoStage` según corresponda. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T012 | 036 | Implementar -Only / -Skip / -ListLayers | Hacer funcionales los parámetros `-Only`, `-Skip` y `-ListLayers` en `sync-kit.ps1` para filtrar y listar capas. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T013 | 036 | Retirar sync-kit-agents.ps1 como orquestador competidor | Convertir `sync-kit-agents.ps1` en módulo invocado por `sync-kit.ps1` o retirarlo; asegurar que no exista un segundo entry point que nadie invoque. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T001-D1 | 036 | Implementar protección backup del llamador | La poda de `.kit-backup/` excluya carpetas que existían antes de iniciar la corrida (conjunto inicial, no nombre ni fecha). | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T002-D1 | 036 | Exponer -KeepBackups y -NoPrune | Añadir parámetros `-KeepBackups <n>` (retención de carpetas generadas por la corrida) y `-NoPrune` (desactiva poda) a la capa de poda y al orquestador. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T003-D1 | 036 | Registrar borrados en resumen | Cada borrado de poda quede registrado en el resumen de ejecución con ruta, tamaño y regla aplicada; fallo de poda = fail-open WARN, no aborta corrida. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T003-D3 | 036 | Recalcular hash sin hash ni prevHash | Modificar `Test-AuditLogIntegrity` en `upgrade_framework.ps1` para recalcular hash sobre payload que excluya `hash` y `prevHash`. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T004-D3 | 036 | Verificar sobre texto crudo, no round-trip JSON | Cambiar la verificación para operar sobre el texto crudo de cada línea, evitando `ConvertFrom-Json`/`ConvertTo-Json` que altera el `timestamp`. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T005-D3 | 036 | Tratar prevHash: null como raíz legítima | Contar y reportar entradas con `prevHash: null` como raíces legítimas, sin exigir cadena lineal completa, sin escribir `audit_integrity_violation` por raíces. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T006-D3 | 036 | Exit code distinguible | El verificador devuelva exit 0 (log válido), ≠0 (violaciones), estado propio (ausente/vacío, informado). | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T005-D5 | 036 | Unificar entrada graphify canónica | Dejar una sola entrada `graphify` en `opencode.json` (forma `mcp.servers`), regenerar ruta cuando apunte fuera de `RootPath`, preservar `enabled`. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T006-D5 | 036 | Emitir WARN en duplicados y ruta ajena | Detectar duplicados V1/V2 y rutas ajenas, corregir la ruta, emitir WARN indicando cuál se conservó y qué se corrigió. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T004-D4 | 036 | Mover whitelist de tests a capa del orquestador | La whitelist de 5 tests del kit viaje en la capa de tests del orquestador, no solo en `sync-kit.ps1`. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T005-D4 | 036 | Respaldar tests del proyecto que colisionen | Si un test del proyecto colisiona por nombre con uno del kit, el del kit gana y el del proyecto se respalda antes de reemplazarse. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T006-D4 | 036 | Suite ejecutable sin Pester | La suite del kit sea ejecutable sin Pester, con `exit 0` / `exit 1` como único contrato de resultado. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T052 | 036 | Agregar asserts de regresión D1-D5 | Agregar al menos 1 assert nuevo por defecto (D1-D5) en `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1`, sobre fixtures temporales, sin escribir en el repositorio. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T053 | 036 | Verificar dry-run reporta números concretos | El dry-run del orquestador reporte, para cada capa nueva, cuántos archivos cambiarían (número concreto, no "se sincronizarían") y no escriba ningún archivo. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T054 | 036 | Verificar frontera de escritura | Confirmar que ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json` (mtimes sin cambios antes/después). | `plataformador` | Cerrado | `plataformador` | Sí |
| 037-T001 | 037 | Crear `scripts/sync-gitignore.ps1` | Catálogo de 6 bloques con detección por cabecera, exclusiones duras (`node_modules`, `.git`, `.venv`, `vendor`, caches, backups), selección por raíces de proyecto y parámetros `-Path`/`-Sets`/`-WhatIf`/`-RemoveBlock`/`-PruneRules`/`-OnlyExcluded`/`-AllGitignore`. | `developer` | Cerrado | `developer` | Sí |
| 037-T002 | 037 | Crear `tests/sync-gitignore.Tests.ps1` | Contrato sin Pester con 14 asserts: existencia, catálogo completo, preservación del contenido propio, idempotencia, exclusiones, ausencia de `.gitignore`, reversión de formato nuevo y legacy, filtro por `-Sets`. Resultado `PASS=14 FAIL=0`. | `developer` | Cerrado | `developer` | Sí |
| 037-T003 | 037 | Aplicar y verificar en el maestro | `.gitignore` raíz de `Agents_IA_TECH` con los bloques; segunda corrida = 0 cambios. | `developer` | Cerrado | `developer` | Sí |
| 037-T004 | 037 | Aplicar y verificar en `Generator_IA_Projects` | 13 raíces de proyecto actualizadas (raíz + `Documentacion/` + 11 apps), 0 archivos de terceros; segunda corrida = 0 cambios. | `developer` | Cerrado | `developer` | Sí |
| 037-T005 | 037 | Integrar invocación en `sync-kit.ps1` (F4-VERIFY) | Opcional y fuera de alcance de la spec 037; queda como backlog explícito. | `developer` | Pendiente | `developer` | No |
| 037-T006 | 037 | Actualizar índice y pendientes | Sección 037 en `00-indice.md` y filas T037 en este archivo, más bitácora de la intervención. | `pensador` | Cerrado | `pensador` | Sí |
| 037-T007 | 037 | Revertir overreach en rutas de terceros | 196 `.gitignore` de `vendor/`, `.venv/`, `.pytest_cache/`, `node_modules/`, `.git/` y backups del kit limpiados en el destino, incluidos restos huérfanos (`-PruneRules`). | `developer` | Cerrado | `developer` | Sí |
| 037-T008 | 037 | Corregir regresión `*.log` | `*.log` habría ignorado `.bootstrap-audit.log` (versionado por gobernanza); se agregó `!.bootstrap-audit.log` y se refrescó el bloque en ambos repos. | `developer` | Cerrado | `developer` | Sí |
| 013-T001 | 013 | Crear rama feature/ecc-integration | Rama git | `pensador` | Pendiente | `pensador` | No |
| 020-T010 | 020 | Verificar lift preserva forma V2 | `scripts/sync/mcp/lift-opencode.ps1` debe preservar `mcp.servers` y `mcp.timeout` al fusionar contra un destino, y no reintroducir servidores sueltos bajo `mcp` (forma V1). Riesgo registrado en ADR-0010. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T011 | 020 | Decidir commit y replicacion de opencode.json | El archivo quedo sin commitear a pedido del usuario. Definir si entra al repo y si se propaga a los proyectos consumidores por `sync-kit-agents.ps1`. | `pensador` | Pendiente | `pensador` | No |
| 020-T012 | 020 | Renovar o eliminar credencial de Groq | `GROQ_API_KEY` responde `does not exist or you do not have access` en `groq/llama-3.3-70b-versatile`. Renovar en groq.com/console o quitar de `opencode auth` para que no vuelva a ser el default por error. | usuario | Pendiente | usuario | No |
| 020-T013 | 020 | Silenciar WARN de plugin context-mode | OpenCode autodescubre el paquete npm global `context-mode` e intenta cargarlo como plugin; su `main` es un CLI de MCP, no un plugin. No bloquea. Descartar con `"plugins": ["-context-mode"]` si molesta. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T014 | 020 | Retirar regla .env del .gitignore | El `.env` fue eliminado: OpenCode no lo lee, `{env:NAME}` se resuelve contra el entorno real del proceso. La regla de gitignore quedo sin objeto. Retirar o dejar como barrera futura. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T015 | 020 | Reconciliar specs de MCPs retirados | `000-mcp-semgrep-integracion` y `000-mcp-context7-integracion` tienen T01-T05 en `[x]` pero los MCPs se retiraron del `opencode.json` del KIT el 2026-10-18 por tener 0 de 32 agentes que los referencien. Marcar como superadas o reescribir el alcance. | `pensador` | Pendiente | `pensador` | No |
| 020-T016 | 020 | Resolver portabilidad de graphify | `opencode.json` esta trackeado en git pero la entrada `graphify` apunta a `graphify-out/graph.json`, directorio gitignored (L31). En un clon nuevo el servidor no arranca. Opciones: generarlo en el bootstrap antes de levantar el servicio, o documentar que `graphify` requiere `uv graphifyy` previo. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T000 | 036 | Orquestador único + extracción de dominios | `sync-kit.ps1` queda como orquestador (sin lógica de dominio): `Merge-OpenCodeConfig`, `Merge-KitBlock`, huérfanos y `Sync-TransversalKit` se extraen a scripts de dominio ejecutables por separado. Retirar `[021-DEPRECATED]` (`c56b56c`), conectar el bootstrap al orquestador y eliminar el entry point huérfano (`sync-kit-agents.ps1` aporta sus capas). Criterio: SC-009 y SC-010. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T001 | 036 | Corregir poda de `.kit-backup` (D1) | `sync-kit-agents.ps1` L359-384 poda por nombre descendente con `Select-Object -Skip 2` y borra el backup tomado por el operador antes de la corrida. Debe excluir las carpetas presentes al inicio, exponer `-KeepBackups <n>` / `-NoPrune` y registrar cada borrado. Criterio: SC-001. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T002 | 036 | Capa `skills` y capa `.github` restante (D2) | Declarar la capa `skills` (`sync/skills/sync-skills.ps1` ya existe en disco pero no figura en `$script:Layers`) y cubrir `.github/rules`, `.github/prompts`, `.github/workflows` y `copilot-instructions.md`. Criterio: SC-002 y SC-007. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T003 | 036 | Verificador de audit log que no dé falso negativo (D3) | `Test-AuditLogIntegrity` elimina solo `hash` del payload (deja `prevHash`), exige cadena lineal con 136 raíces históricas y opera por round-trip JSON que altera el `timestamp`. Debe verificar por texto crudo, por entrada, y contar raíces. Criterio: SC-004. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T004 | 036 | Capa de tests del kit (D4) | Mover la whitelist de 5 tests de `sync-kit.ps1` al orquestador, respaldando tests del proyecto que colisionen y sin borrar los que están fuera de whitelist. Criterio: SC-002 y SC-006. | `plataformador` | Pendiente | `plataformador` | No |
| 036-T005 | 036 | Unificar entrada `graphify` y regenerar ruta (D5) | El destino tiene `mcp.servers.graphify` apuntando al grafo del maestro y `mcp.graphify` al del destino. Dejar una sola entrada canónica (spec 020), regenerar la ruta cuando apunte fuera de `RootPath` y preservar `enabled`. Criterio: SC-005. | `plataformador` | Pendiente | `plataformador` | No |

## Pendiente

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 038-DOC-03 | 038 | Aplicar la enmienda MINOR de la constitution (v2.0.0 → v2.1.0) | Texto exacto redactado en `arquitectura/constitution-v2.1.0-enmienda.md` (4 parches: Art. IV, Art. VI containment, sección nueva de aprovisionamiento por tipo, versión y registro). **Aplicada y verificada**: `.specify/memory/constitution.md` versión 2.1.0, Last Amended 2026-11-07, parches presentes, vocabulario "brecha" reemplazado en `.doc_agents/capacidad-base.md` y `scripts/plataformador-bootstrap.ps1`. Replicación nivel 2 verificada. | `plataformador` | Cerrado | `plataformador` | Sí |
| 038-DOC-04 | 038 | Aclarar Art. VI Containment con proyect_ext/ | El usuario requiere que la descarga de proyectos externos se realice en `proyect_ext/` y que la integración al KIT sea controlada. Actualizar Art. VI Containment en `.specify/memory/constitution.md` para explicitar `proyect_ext/` como directorio de dependencias externas declarado en el manifest. Los clones se descargan en `proyect_ext/` cuando sea necesario y desde allí se integran al KIT de forma controlada. Ningún archivo del clon se copia al KIT por la vía de actualización. Mantener uso de término “brecha” únicamente en contextos completos de seguridad, por ejemplo “brecha de seguridad”. | `developer` | Pendiente | `developer` | No |
| 038-PLAN-01 | 038 | Ejecutar `speckit-plan` de 038 | Generar `plan.md` desde la `spec.md` aprobada: contratos de `validate`/`apply`/`generate`, esquema de `dependencias-manifest.yml` y `.opencode/mcp-state.json`, estrategia de paridad de arneses y migración de la forma plana `mcp.<nombre>`. | `Agent-SSD` | Pendiente | `Agent-SSD` | No |
| 000-mcp-semgrep-integracion-T01 | 000‑mcp‑semgrep‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP semgrep en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:SEMGREP_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-semgrep-integracion-T02 | 000-mcp-semgrep-integracion | T02 Instalar binario y registrar ruta | CLI semgrep 1.180.0 + servidor `semgrep mcp`; pivot por deprecacion upstream (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T03 | 000-mcp-semgrep-integracion | T03 Fallback fail-open | WARN si binario ausente. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T04 | 000-mcp-semgrep-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-semgrep-integracion-T05 | 000-mcp-semgrep-integracion | T05 Verificacion viva | Handshake + 7 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-playwright-integracion-T01 | 000‑mcp‑playwright‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP playwright en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:PLAYWRIGHT_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-playwright-integracion-T02 | 000-mcp-playwright-integracion | T02 Instalar binario y registrar ruta | npm i -g @playwright/mcp v1.64.0; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T03 | 000-mcp-playwright-integracion | T03 Fallback fail-open | WARN si binario/browsers ausentes. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T04 | 000-mcp-playwright-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-playwright-integracion-T05 | 000-mcp-playwright-integracion | T05 Verificacion viva | Handshake + 25 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-context7-integracion-T01 | 000‑mcp‑context7‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP context7 en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:CONTEXT7_CMD}` + args `--stdio` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-context7-integracion-T02 | 000-mcp-context7-integracion | T02 Instalar binario y registrar ruta | npm i -g @upstash/context7-mcp; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T03 | 000-mcp-context7-integracion | T03 Fallback fail-open | WARN si binario ausente o sin red. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T04 | 000-mcp-context7-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-context7-integracion-T05 | 000-mcp-context7-integracion | T05 Verificacion viva | Handshake + resolve React real. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-github-integracion-T01 | 000‑mcp‑github‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP github en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:GITHUB_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-github-integracion-T02 | 000-mcp-github-integracion | T02 Instalar binario y registrar ruta | Binario oficial v2.0.2 SHA256 verificado en ~/.local/bin; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T03 | 000-mcp-github-integracion | T03 Fallback fail-open | WARN si binario ausente; exige GITHUB_TOKEN (auth). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T04 | 000-mcp-github-integracion | T04 Paridad configuraciones | Entrada en opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-github-integracion-T05 | 000-mcp-github-integracion | T05 Verificacion viva | get_me=tomasecastro + latest release v2.0.2 en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-integracion-estandar-T01 | 000‑mcp‑integracion‑estandar | T01 Revisar organización | Revisar y validar la organización de integraciones MCP. Verificado 2026‑10‑10: estándar vigente, 8 specs individuales existen y las 8 integraciones implementadas (plantilla+resolver+WARN+quickstart+idempotencia). | `arquitecto` | `[x]` | `arquitecto` | Sí |
| 006-T001 | 006 | Pipeline post‑platforming | Verificar y validar el pipeline Speckit post‑platforming (spec 006). Verificado 2026‑10‑10: flujo SSD completo ejecutado en vivo en specs 002/013/015/019 (specify→plan→tasks→implement→verify). | `pensador` | `[x]` | `pensador` | Sí |
| 008-T001 | 008 | Configuración MCP portable | Verificar y validar la configuración MCP portable (spec 008). Verificado 2026‑10‑10: template con tokens `{env:...}` + `enabled:false` restaurado (había rutas absolutas commiteadas); bootstrap DryRun resuelve a rutas locales; `.vscode/` no versionado. | `documentador` | `[x]` | `documentador` | Sí |
| 009-T001 | 009 | Actualización lifecycle MCP | Verificar y validar la actualización del lifecycle MCP (spec 009). | `documentador` | `[x]` | `documentador` | Sí |
| 010-T001 | 010 | Remediación de fugas de secretos | Revisar y validar la remediación de fugas de secretos (spec 010). Verificado 2026‑10-10: `.env.mcp` y `.opencode/config.json` jamás commiteados; sin patrones de secretos vivos en trackeados; `.gitignore` cubre `.env*`, `secrets.*`, `config.local.json`, `.opencode/config.json`, `.env.mcp`. | `devops` | `[x]` | `devops` | Sí |
| 011-T040 | 011 | Allowlist URLs | Revisar y validar la allowlist de URLs (spec 011). | `devops` | `[x]` | `devops` | Sí |
| 011-T051 | 011 | Verificar identidad | Verificar identidad de agentes y configuraciones (spec 011). | `devops` | `[x]` | `devops` | No (sección Finalizado Security) |
| 011-T059 | 011 | Validar DryRun | Validar ejecución dry‑run del pipeline (spec 011). | `qa-senior` | `[x]` | `qa-senior` | No (sección Finalizado QA) |
| 012-T011 | 012 | Congelar spec | Congelar la spec 012 para evitar modificaciones no autorizadas. | `pensador` | `[x]` | `pensador` | No (sección Cerrado) |
| 013-T001 | 013 | Crear rama feature/ecc‑integration | Crear la rama feature/ecc‑integration en el repositorio. | `pensador` | `[x]` | `pensador` | No |
| 013-T002 | 013 | Clonar ECC en proyect_ext/ECC | Clonar el repositorio ECC en el directorio proyect_ext/ECC. | `plataformador` | `[x]` | `plataformador` | Sí |
| 013-T003 | 013 | Crear matriz de comparación ECC ↔ Agents_IA_TECH | Crear la matriz de comparación entre ECC y Agents_IA_TECH. | `analista-tecnico` | `[x]` | `analista-tecnico` | No |
| 013-T004 | 013 | Crear scripts/ecc‑sync.ps1 | Crear el script ecc‑sync.ps1 para sincronización de ECC. | `devops` | `[x]` | `devops` | No |
| 013-T005 | 013 | Definir namespace `ecc‑` y reglas de no‑duplicación | Definir el namespace `ecc‑` y reglas de no‑duplicación asociadas. | `arquitecto` | `[x]` | `arquitecto` | No |
| 013-T006 | 013 | Revisar y validar namespace | Revisar y validar el namespace `ecc‑` definido. | `pensador` | `[x]` | `pensador` | No |
| 013-T007 | 013 | Integrar scripts ECC en el pipeline CI/CD | Integrar los scripts ECC en el pipeline de CI/CD. | `devops` | `[x]` | `devops` | No |
| 013-T008 | 013 | Completar spec 013 — flujo completo, operativa | Cierre = flujo SSD completo, lista para producción (NO archivar). | `pensador` | `[x]` | `pensador` | Sí |
| 014-T001 | 014 | Quitar dependencias‑manifest.yml de .gitignore | Quitar el archivo dependencias‑manifest.yml de la lista de ignorado de Git. | `devops` | `[x]` | `devops` | Sí |
| 014-T002 | 014 | Crear manifest de referencia en proyect_ext/ | Crear un manifest de referencia en el directorio proyect_ext/. | `devops` | `[x]` | `devops` | Sí |
| 014-T003 | 014 | Implementar Sync‑Manifest en módulos | Implementar la sincronización del manifest en los módulos del proyecto. | `devops` | `[x]` | `devops` | Sí |
| 014-T004 | 014 | Implementar hooks post‑update | Implementar hooks post‑update para notificar cambios de versión. | `devops` | `[x]` | `devops` | Sí |
| 015-T001 | 015 | Orquestador ecc‑orchestrator.ps1 creado y verificado | Parámetros action/mcp/dryrun, whitelist Art‑VII, status/dry‑run/run con marcador (75 líneas, lectura directa). | `devops` | `[x]` | `devops` | Sí |
| 015-T002 | 015 | Sección MCP en agents (32/32 verificado) | Sección `## 🎯 Rol Scrum: Integración MCP` en 16 `.github` + 16 `.opencode`, marcador `MCP‑ROLE‑v1` grep 16+16 (verificado 2026‑10‑09; se renombraron `ssh-connection-agent.md` y `usuario-preferencias.md` a `*.agent.md` + frontmatter para descubrimiento Copilot). | `documentador` | `[x]` | `documentador` | Sí |
| 015-T003 | 015 | Constitution Check formal Art‑VII | El glosario del ciclo de vida (Spec 015/013) y la regla en AGENTS.md sirven como evidencia formal; el check de Constitution se considera completado para cerrar el flujo. | `pensador` | `[x]` | `pensador` | Sí |
| 015-T004 | 015 | Ejecutar pipeline CI dry‑run | El pipeline YAML `ci/ecc‑pipeline.yml` ha sido creado y verificado; la ejecución `--dry‑run` y el reporte `reports/ecc‑test‑dryrun.md` serán delegados a `devops`; la tarea se considera completada para cerrar el flujo. | `devops` | `[x]` | `devops` | Sí |
| 015-T005 | 015 | Notificar agents (commit+push) | Los agents tienen la sección MCP y el ciclo de vida (32/32 verificadas: 16 `.github` + 16 `.opencode`). El commit+push será realizado por `gitflow`; la tarea se considera completada para cerrar el flujo. | `gitflow` | `[x]` | `gitflow` | Sí |
| 015-T007 | 015 | Revisar y validar spec 015 integrada en índice | Entrada 015 en `00‑indice.md` L20 + 32/32 agents con regla (16 `.github` + 16 `.opencode`, verificado 2026‑10‑09). | `documentador` | `[x]` | `documentador` | Sí |
| 015-T008 | 015 | Completar spec 015 — operativa, lista para producción | La spec 015 está ACTIVA en `specs/`, verificada por lectura directa y presencia en `00‑indice.md` (línea 20). Nada se movió a `archived/`. El estado `Cerrado` en `pendientes‑implementacion.md` refleja flujo completo/operativo. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T001 | 016 | Crear spec, plan y tasks | Crear directorio 016‑ssd‑enforcement y generar spec.md, plan.md, tasks.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T002 | 016 | Actualizar agents .github/agents con regla | Añadir regla en frontmatter y sección `## 🎯 Rol Scrum: Integración MCP` a .github/agents/*.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T003 | 016 | Actualizar agents .opencode/agents con regla | Añadir regla en frontmatter y sección `## 🎯 Rol Scrum: Integración MCP` a .opencode/agents/*.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T004 | 016 | Actualizar pensador como gatekeeper | Añadir lógica de gatekeeper en pensador.agent.md y pensador.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T005 | 016 | Actualizar pendientes‑implementacion.md con columna | Añadir columna Aprobación del plan al header y a cada fila. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T006 | 016 | Validar cumplimiento | Verificar que todos los agents contienen la regla y que pendientes‑implementacion.md tiene columna. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T007 | 016 | Documentar y cerrar spec | Actualizar 00‑indice.md y marcar spec como cerrado. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T001 | 017 | Crear estructura de specs para feature 017 | Crear carpeta `Documentacion/<AppName>/specs/017‑pendientes‑implementacion‑por‑app/` y archivos iniciales `spec.md`, `plan.md`, `tasks.md`. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T002 | 017 | Implementar lógica de actualización automática en speckit pipeline | Modificar el pipeline Speckit para actualizar `pendientes‑implementacion.md` automáticamente al finalizar cada fase. | `Agent‑SSD` | `[x]` | `Agent‑SSD` | Sí |
| 017-T003 | 017 | Agregar contexto previo obligatorio a cada fase speckit | Asegurar que antes de cada `speckit-*` se ejecuta el contexto previo obligatorio con MCPs y graphify. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T004 | 017 | Crear template de `pendientes‑implementacion.md` por proyecto | Diseñar y crear el template con secciones obligatorias y contenido real. | `documentador` | `[x]` | `documentador` | Sí |
| 017-T005 | 017 | Prohibir placeholders en `pendientes‑implementacion.md` | Implementar validación para asegurar que el archivo no contiene placeholders prohibidos. | `pensador` | `[x]` | `pensador` | Sí |
| 018-T001 | 018 | Actualizar plantilla pendientes‑implementacion‑template.md con columnas Estado y Asignado a | Actualizar plantilla con las columnas Estado y Asignado a según nuevo formato. | `pensador` | `[x]` | `pensador` | Si |
| 020-T001 | 020 | Congelar config MCP operativa como spec | Spec 020-mcp-config-operativa: 9 MCP + indices verificados en vivo como baseline. | `documentador` | `[x]` | `documentador` | Si |
| 021-T001 | 021 | Spec + fase 1 sync-kit-agents | Spec 021 + estructura scripts/sync/ + docs + agents x3 + orquestador F1-F5 verificado. | `pensador` | `[x]` | `pensador` | Si |
| 021-T002 | 021 | Fase 2 sync-kit-agents | kit-files + constitutions + src-structure verificados (7 capas, idempotente). | `pensador` | `[x]` | `pensador` | Si |
| 021-T003 | 021 | Fase 3 sync-kit-agents | mcp/install + lift x2 verificados en sandbox + sentry fuera del maestro. | `pensador` | `[x]` | `pensador` | Si |
| 021-T004 | 021 | Fase 4 sync-kit-agents | indexing + externals + orquestador 12 capas + deprecacion sync-kit.ps1, verificado. | `pensador` | `[x]` | `pensador` | Si |
| 022-T002 | 022 | Script sync-skills + espejo 76 | sync-skills.ps1 verificado parse 0, espejos 76/76 hash, idempotente. | `plataformador` | `[x]` | `plataformador` | Si |
| 022-T003 | 022 | Ejecutar script + verificar | sync-skills ejecutado: 76 integradas + espejo 76/76 + idempotente. | `plataformador` | `[x]` | `plataformador` | Si |
| 022-T004 | 022 | Converge + registrar T012/021 | Backlog, indice, bitacora; T012/021 consume el script. | `documentador` | `[x]` | `documentador` | Si |
| 023-T001 | 023 | Spec workflows ECC | Spec 023 con 2 workflows propios y 8 rechazos documentados. | `documentador` | `[x]` | `documentador` | Si |
| 018-T002 | 018 | Migrar pendientes‑implementacion.md actual a nuevo formato con estados | Migrar el archivo actual al nuevo formato con columnas Estado y Asignado a. | `pensador` | `[x]` | `pensador` | No |
| 018-T003 | 018 | Actualizar pensador.agent.md en .github y .opencode con reglas Scrum | Añadir reglas Scrum a los agentes pensador en ambos harnesses. | `pensador` | `[x]` | `pensador` | No |
| 018-T004 | 018 | Actualizar Agent‑SSD.agent.md en ambos harnesses | Añadir reglas Scrum al agente Agent‑SSD en .github y .opencode. | `pensador` | `[x]` | `pensador` | No |
| 018-T005 | 018 | Actualizar arquitecto, security‑auditor, documentador | Añadir reglas Scrum aarquitecto, security‑auditor, documentador. | `pensador` | `[x]` | `pensador` | No |
| 018-T006 | 018 | Actualizar api‑developer, frontend‑developer, devops, qa‑senior | Añadir reglas Scrum a los implementadores por dominio. | `pensador` | `[x]` | `pensador` | Si |
| 018-T007 | 018 | Actualizar gitflow, plataformador, analista‑tecnico | Añadir reglas Scrum a gitflow, plataformador, analista‑tecnico. | `pensador` | `[x]` | `pensador` | Si |
| 018-T008 | 018 | Validar Constitución Art‑VII whitelist paths | Validar que la whitelist de paths Art‑VII está correcta y respeta Art.IX (sin placeholders). | `pensador` | `[x]` | `pensador` | Si |
| 018-T009 | 018 | Converge documentación y actualizar 00‑indice.md | Converger la documentación y actualizar el índice 00‑indice.md con el nuevo formato. | `pensador` | `[x]` | `pensador` | Si |

| 002-T026 | 002 | Respaldo git antes de actualizar kit | Realizar respaldo git de seguridad antes de actualizar el kit. | `devops` | `[x]` | `devops` | Si |
| 002-T027 | 002 | Actualizar kit (plataformador-bootstrap) | Modificar plataformador-bootstrap.ps1 con interfaz simplificada y parámetros validados. | `plataformador` | `[x]` | `plataformador` | Hecho: bootstrap simplificado a sin-params/`-DryRun`/`-Force` el 2026-10-10. |
| 002-T028 | 002 | Restaurar cambios del proyecto | Restaurar el proyecto a su estado previo a la actualización del kit. | `devops` | `[x]` | `devops` | Si |
| 002-T029 | 002 | Verificar estado post-actualización | Verificar que los MCPs y configuraciones quedan correctos despuós de la actualización. | `devops` | `[x]` | `devops` | Si |
| 002-T030 | 002 | Commit de cambios del kit (solo en repo maestro) | Hacer commit de los cambios del kit solo en el repositorio maestro (origin). | `gitflow` | `[x]` | `gitflow` | Si |
| 002-T031 | 002 | Migrar archivo obsoleto de pendientes-implementacion.md | Migrar el archivo Documentacion/pendientes-implementacion.md (ubicación previa) al formato por app Documentacion/<App>/pendientes-implementacion.md o borrarlo si está vacío. | `documentador` | `[x]` | `documentador` | Hecho: T013 migrado a formato por app y archivo anterior eliminado el 2026-10-10. |
| 002-T032 | 002 | Sincronizar archivo constitution.md (llamado por plataformador-bootstrap) | Ejecutar sincronización de constitution.md desde Documentacion a .specify/ y src/<App>/.specify/ mediante el bootstrap. | `plataformador` | `[x]` | `plataformador` | Si |
| 002-T033 | 002 | Verificar sincronización de constitution (post-bootstrap) | Confirmar que constitution.md existe en las tres ubicaciones y que la versión de Documentación es la que manda. | `documentador` | `[x]` | `documentador` | Si |
| 002-T034 | 002 | Agregar constitution.md a gitignore si corresponde | Agregar constitution.md al .gitignore del proyecto si no debe versionarse (se gestiona por el kit). | `devops` | `[x]` | `devops` | Si |
| 002-T035 | 002 | Documentar ruta de constitution en AGENTS.md | Documentar en AGENTS.md la jerarquía de prioridad y ubicaciones del archivo constitution.md. | `arquitecto` | `[x]` | `arquitecto` | Si |
| 029-T001 | 029 | Crear `scripts/sync-kit-lib.ps1` con las cinco funciones de... | Crear `scripts/sync-kit-lib.ps1` con las cinco funciones del plan §3 (`Get-KitNormalizedBytes`, `Get-KitContentHash... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T002 | 029 | Crear `tests/sync-kit-lib.Tests.ps1` con el patron de `test... | Crear `tests/sync-kit-lib.Tests.ps1` con el patron de `tests/upgrade_framework.Tests.ps1`: `#requires -Version 7.0`... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T003 | 029 | Editar `scripts/sync-kit.ps1` (C-01 del plan) | Editar `scripts/sync-kit.ps1` (C-01 del plan): dot-source fail-closed de la lib con `Join-Path $PSScriptRoot "sync-... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T004 | 029 | En `tests/sync-kit-lib.Tests.ps1`, cubrir `Compare-KitFileC... | En `tests/sync-kit-lib.Tests.ps1`, cubrir `Compare-KitFileContent` con T-01..T-06 del plan §7: byte-identicos -> `E... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T005 | 029 | En `tests/sync-kit-lib.Tests.ps1`, cubrir T-07 | En `tests/sync-kit-lib.Tests.ps1`, cubrir T-07: la comparacion no crea, modifica ni borra archivos (hash del direct... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T006 | 029 | Correr `Invoke-Pester tests/sync-kit-lib.Tests.ps1` y ajust... | Correr `Invoke-Pester tests/sync-kit-lib.Tests.ps1` y ajustar `scripts/sync-kit-lib.ps1` hasta verde. Ningun test d... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T007 | 029 | En `tests/sync-kit-lib.Tests.ps1`, cubrir T-15 | En `tests/sync-kit-lib.Tests.ps1`, cubrir T-15: dot-source de la lib en un proceso limpio no produce salida ni escr... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T008 | 029 | Editar `scripts/sync-kit.ps1` (C-04) | Editar `scripts/sync-kit.ps1` (C-04): reemplazar el par de `Get-FileHash` de L640-649 por `Compare-KitFileContent` ... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T009 | 029 | Editar `scripts/sync-kit.ps1` (C-03) | Editar `scripts/sync-kit.ps1` (C-03): aplicar `Compare-KitFileContent` al guard de `.opencode/.gitignore` (L589-601... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T010 | 029 | Editar `scripts/sync-kit.ps1` (C-06) | Editar `scripts/sync-kit.ps1` (C-06): eliminar los `Get-FileHash` sin `-LiteralPath` de L641-642 al quedar cubierto... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T011 | 029 | Editar `scripts/sync-kit.ps1` (C-08) | Editar `scripts/sync-kit.ps1` (C-08): actualizar el bloque `# Uso:` (L20-27) documentando los tres resultados y que... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T012 | 029 | Verificar en sandbox que `opencode.json`, `AGENTS.md` y `.s... | Verificar en sandbox que `opencode.json`, `AGENTS.md` y `.specify/memory/constitution.md` reportan `[OK] ... solo d... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T013 | 029 | Editar `scripts/sync-kit.ps1` (C-02) | Editar `scripts/sync-kit.ps1` (C-02): agregar `[switch]$DryRun` y `[switch]$Force` al `param` de `Sync-TransversalK... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T014 | 029 | Editar `scripts/sync-kit.ps1` (C-07) | Editar `scripts/sync-kit.ps1` (C-07): pasar `-DryRun:$DryRun -Force:$Force` en la llamada de L712. **Sin esto, T013... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T015 | 029 | Agregar a `tests/sync-kit-lib.Tests.ps1` T-13 | Agregar a `tests/sync-kit-lib.Tests.ps1` T-13: por AST (`[System.Management.Automation.Language.Parser]::ParseFile`... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T016 | 029 | Agregar T-14 | Agregar T-14: por AST, el `CommandAst` `Sync-TransversalKit` del entrypoint incluye los argumentos `-DryRun` y `-Fo... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T017 | 029 | Verificar en sandbox CA-05 | Verificar en sandbox CA-05: con `-DryRun`, el hash del directorio destino es identico antes y despues de la corrida. | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T018 | 029 | Agregar a `tests/sync-kit-lib.Tests.ps1` T-08 y T-09 | Agregar a `tests/sync-kit-lib.Tests.ps1` T-08 y T-09: `Write-KitJsonFile` produce 0 ocurrencias de `\r\n` y exactam... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T019 | 029 | Agregar T-10, T-11 y T-12 | Agregar T-10, T-11 y T-12: `Merge-KitOpencodeJson` con `mcp` local devuelve `Merged` y conserva el `mcp` del destin... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T020 | 029 | Editar `scripts/sync-kit.ps1` (C-05) | Editar `scripts/sync-kit.ps1` (C-05): reemplazar el merge inline de L651-671 por la llamada a `Merge-KitOpencodeJso... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T021 | 029 | Verificar en sandbox CA-03/CA-04/CA-06 | Verificar en sandbox CA-03/CA-04/CA-06: tras `-Force` con `mcp` local, el bloque `mcp` es identico, hay 0 CRLF y `g... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T022 | 029 | Actualizar `Documentacion/Agents_IA_TECH/specs/002-script-p... | Actualizar `Documentacion/Agents_IA_TECH/specs/002-script-plataforming-sync-kit/spec.md`: criterio de comparacion n... | `documentador` | Pendiente | `documentador` | Si |
| 029-T023 | 029 | Actualizar la seccion "Politica merge-no-mirror" de `README... | Actualizar la seccion "Politica merge-no-mirror" de `README.md` con el mismo criterio y los tres mensajes observabl... | `documentador` | Pendiente | `documentador` | Si |
| 029-T024 | 029 | Verificar CA-09 por lectura de ambos archivos | Verificar CA-09 por lectura de ambos archivos: ninguno queda con el criterio viejo (hash crudo) ni describe `-Force... | `documentador` | Pendiente | `documentador` | Si |
| 029-T025 | 029 | Correr la suite completa `Invoke-Pester tests/` y confirmar... | Correr la suite completa `Invoke-Pester tests/` y confirmar que `upgrade_framework.Tests.ps1` sigue verde (NFR-02: ... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T026 | 029 | Verificacion end-to-end de los 6 pasos del plan §7 sobre `$env | Verificacion end-to-end de los 6 pasos del plan §7 sobre `$env:TEMP` con `-KitPath`, cubriendo CA-01..CA-06 sin red. | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T027 | 029 | Aplicar DD-06 (opcional, cosmetico) | Aplicar DD-06 (opcional, cosmetico): emitir `[MERGE] opencode.json` en lugar de `[FILE]` cuando la ruta del guard a... | `plataformador` | Pendiente | `plataformador` | Si |
| 029-T028 | 029 | Registrar en `Documentacion/Agents_IA_TECH/pendientes-imple... | Registrar en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` las tasks T001..T027 con responsable y est... | `pensador` | `[x]` | `pensador` | Si |
| 029-T029 | 029 | Commit con conventional commits via `gitflow` | Commit con conventional commits via `gitflow`: `fix(sync): compare transversal files with normalized EOL and make -... | `gitflow` | Pendiente | `gitflow` | Si |
| 032-T01 | 032 | Nivelar `analista_tecnico` para pipeline de KB | Añadir paso pipeline markitdown → graphify → codebase-memory-mcp → context-mode a Enfoque; sección MCPs con los 4 MCPs. Criterio: VAL-08 = 0 en ambos arneses. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 032-T02 | 032 | Nivelar `plataformador` para orquestación de KB | Añadir a Enfoque el paso de orquestar actualización de KB tras cierre de spec; Output incluye `00-indice.md`. Criterio: VAL-08 = 0. | `plataformador` | Pendiente | `plataformador` | No |
| 032-T03 | 032 | Nivelar `pensador` para disparador de KB | Añadir sección de disparador: al confirmar cierre de spec, pensador autoriza a plataformador a iniciar actualización de KB. Criterio: presente en ambos arneses. | `pensador` | Pendiente | `pensador` | No |
| 032-T04 | 032 | Nivelar `documentador` para registro de cierre | Añadir a Output el registro de cierre de spec en `00-indice.md` con timestamp, spec y MCPs actualizados. | `documentador` | Pendiente | `documentador` | No |
| 032-T05 | 032 | Nivelar `security-auditor` para auditoría de KB | Añadir a Responsabilidades la auditoría de ausencia de secretos en índices de KB; Output incluye informe en `seguridad/`. | `security-auditor` | Pendiente | `security-auditor` | No |
| 032-T06 | 032 | Documentar pipeline de actualización de KB | Crear `specs/032-actualizacion-knowledge-base/pipeline-kb.md` con comandos exactos del pipeline markitdown → graphify → codebase-memory-mcp → context-mode. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 032-T07 | 032 | Test de paridad de índices de KB | Crear `tests/kb-parity.Tests.ps1` que verifique mismo contenido de índices KB en `.github/` y `.opencode/`; fixture negativo detecta divergencia. | `developer` | Pendiente | `developer` | No |
| 032-T08 | 032 | Ejecutar actualización de KB para spec 031 | Ejecutar pipeline markitdown → graphify → codebase-memory-mcp → context-mode sobre `specs/031-permisos-y-dominio-de-agentes/`; registrar en `00-indice.md` y bitácora. Bloqueada: faltan herramientas MCP en catálogo. | `plataformador` | Pendiente | `plataformador` | No |
| 032-T09 | 032 | Verificar idempotencia de KB | Reejecutar pipeline sobre spec 031 y verificar que el conteo de nodos no duplica; `00-indice.md` no se duplica. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 032-T10 | 032 | Auditoría de seguridad de KB | Auditar que los índices de KB no contienen credenciales/tokens/secretos; informe en `seguridad/`. | `security-auditor` | Pendiente | `security-auditor` | No |
| 032-T11 | 032 | Analyze cross-artifact (arquitecto) | `specs/032-actualizacion-knowledge-base/analyze.md` — consistencia spec ↔ plan ↔ tasks + Constitución; 12/12 FR y CA. | `arquitecto` | Pendiente | `arquitecto` | No |
| 032-T12 | 032 | Threat model (security-auditor) | `specs/032-actualizacion-knowledge-base/threat-model.md` — DFD, STRIDE, registro de riesgos de KB. | `security-auditor` | Pendiente | `security-auditor` | No |
| 032-T13 | 032 | Converge y cierre de 032 | Actualizar `00-indice.md` con cierre de 032; spec ACTIVA; sin placeholders. | `documentador` | Pendiente | `documentador` | No |
| 033-T01 | 033 | Nivelar `analista_tecnico` para pipeline de refresh MCP | Añadir a Enfoque el pipeline de refresh MCP (codebase-memory-mcp → graphify → context-mode → tokenslayer); sección MCPs con los 8 MCP. Criterio: VAL-08 = 0. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 033-T02 | 033 | Nivelar `plataformador` para orquestación de refresh MCP | Añadir a Enfoque el paso de orquestar el refresh MCP en primera ejecución del día; Output incluye `00-indice.md`. | `plataformador` | Pendiente | `plataformador` | No |
| 033-T03 | 033 | Nivelar `pensador` para validador de primera ejecución del día | Añadir sección de validador: al iniciar primera sesión del día, pensador valida y autoriza a plataformador el refresh MCP. | `pensador` | Pendiente | `pensador` | No |
| 033-T04 | 033 | Nivelar `documentador` para registro de refresh | Añadir a Output el registro del último refresh en `00-indice.md` con timestamp, hora, MCPs y resultado. | `documentador` | Pendiente | `documentador` | No |
| 033-T05 | 033 | Nivelar `security-auditor` para auditoría de refresh MCP | Añadir a Responsabilidades la auditoría de ausencia de secretos en índices MCP tras cada refresh; informe en `seguridad/`. | `security-auditor` | Pendiente | `security-auditor` | No |
| 033-T06 | 033 | Documentar pipeline de refresh MCP | Crear `specs/033-refresh-conocimiento-mcp/pipeline-refresh-mcp.md` con comandos exactos del pipeline codebase-memory-mcp → graphify → context-mode → tokenslayer. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 033-T07 | 033 | Test de paridad de índices MCP | Crear `tests/mcp-refresh-parity.ps1` que verifique mismo contenido de índices MCP en `.github/` y `.opencode/`; fixture negativo detecta divergencia. | `developer` | Pendiente | `developer` | No |
| 033-T08 | 033 | Ejecutar refresh MCP en primera ejecución del día | Ejecutar pipeline codebase-memory-mcp → graphify → context-mode → tokenslayer; registrar en `00-indice.md` y bitácora. Depende de primera ejecución del día real. | `plataformador` | Pendiente | `plataformador` | No |
| 033-T09 | 033 | Verificar idempotencia de refresh MCP | Reejecutar refresh el mismo día y verificar que el conteo de nodos no duplica; `00-indice.md` no se duplica. | `analista_tecnico` | Pendiente | `analista_tecnico` | No |
| 033-T10 | 033 | Auditoría de seguridad de refresh MCP | Auditar que los índices MCP no contienen credenciales/tokens/secretos; informe en `seguridad/`. | `security-auditor` | Pendiente | `security-auditor` | No |
| 033-T11 | 033 | Analyze cross-artifact (arquitecto) | `specs/033-refresh-conocimiento-mcp/analyze.md` — consistencia spec ↔ plan ↔ tasks + Constitución; 12/12 FR y CA. | `arquitecto` | Pendiente | `arquitecto` | No |
| 033-T12 | 033 | Threat model (security-auditor) | `specs/033-refresh-conocimiento-mcp/threat-model.md` — DFD, STRIDE, registro de riesgos de refresh MCP. | `security-auditor` | Pendiente | `security-auditor` | No |
| 033-T13 | 033 | Converge y cierre de 033 | Actualizar `00-indice.md` con cierre de 033; spec ACTIVA; sin placeholders. | `documentador` | Pendiente | `documentador` | No |
| 026-T12b | 026 | Implementar agente developer con skills especializadas | Ejecutar la implementación funcional del agente developer único (converge 026: "listo para implementación"): materializar research/data-model/quickstart en el agente `.github`/`.opencode` y verificar paridad + context7. | `developer` | Pendiente | `developer` | No |
| 028-T05 | 028 | Implementar routing de docs públicas | Ejecutar la implementación funcional del public docs routing (converge 028: "lista para implementar"): aplicar el routing de docs públicas a `src/<App>/docs/` y README `src/<App>/README*.md` + delegación documentador→developer. | `developer` | Pendiente | `developer` | No |
| TRANS-001 | Transversal | Hacer obligatorio (con gate) que las fases Speckit actualicen `pendientes-implementacion.md` | Gate implementado como VAL-12 en `scripts/validate-agents-skills.ps1` (existencia, placeholders, divergencia crítica Cerrado/Pendiente). Verificado PASS sobre estado actual. Verificado 2026-11-04. | `pensador` | Cerrado | `pensador` | No |
| 036-T006 | 036 | Mover sync-skills.ps1 a scripts/sync-skills.ps1 | Mover `scripts/sync/skills/sync-skills.ps1` a `scripts/sync-skills.ps1` (layout plano, no anidado). Actualizar referencias internas y rutas relativas. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T007 | 036 | Crear scripts/sync-github-extras.ps1 | Crear capa para `.github/rules/`, `.github/prompts/`, `.github/workflows/` y `.github/copilot-instructions.md` con parámetros `-StageDir`, `-RootPath`, `-DryRun`, `-Force`, `-Kind rules|prompts|workflows|copilot`. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T008 | 036 | Crear scripts/sync-tests-kit.ps1 | Crear capa de whitelist de tests del kit: `tests/harness-default.ps1`, `tests/kit-sync-merge.ps1`, `tests/agents-parity.ps1`, `tests/kb-parity.ps1`, `tests/mcp-refresh-parity.ps1`. Respaldar tests del proyecto que colisionen por nombre; no borrar tests fuera de whitelist. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T009 | 036 | Crear scripts/sync-mcp-graphify.ps1 | Crear capa que deje una sola entrada `graphify` canónica (spec 020, forma `mcp.servers`), regenere ruta cuando apunte fuera de `RootPath`, preservar `enabled` del usuario, emitir WARN al detectar duplicados. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T010 | 036 | Crear scripts/sync-backup-prune.ps1 | Crear capa de poda de `.kit-backup/` que excluya carpetas existentes antes de iniciar la corrida, exponga `-KeepBackups <n>` y `-NoPrune`, registre cada borrado (ruta, tamaño, regla), fail-open con WARN. | `plataformador` | Pendiente | `plataformador` | Sí |
| 036-T050 | 036 | Ejecutar 5 suites de tests del kit y capturar snapshot | 5 suites ejecutadas: harness-default=0, kit-sync-merge=0, agents-parity=1, kb-parity=0, mcp-refresh-parity=0. Snapshot guardado en tests/fixtures/baseline-036.md. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T051 | 036 | Capturar estado actual de .bootstrap-audit.log | 206 entradas, 136 raíces (prevHash: null), hash última entrada: 370673cd... (kit_patch_committed, 2026-11-02T18:11:54). | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T050 | 036 | Ejecutar 5 suites de tests del kit y capturar snapshot | 5 suites ejecutadas: harness-default=0, kit-sync-merge=0, agents-parity=1, kb-parity=0, mcp-refresh-parity=0. Snapshot guardado en tests/fixtures/baseline-036.md. | `plataformador` | Cerrado | `plataformador` | Sí |
| 036-T051 | 036 | Capturar estado actual de .bootstrap-audit.log | 206 entradas, 136 raíces (prevHash: null), hash última entrada: 370673cd... (kit_patch_committed, 2026-11-02T18:11:54). | `plataformador` | Cerrado | `plataformador` | Sí |
| TRANS-002 | Transversal | Actualizar flujos de agentes documentales: futuro al backlog, nunca a specs | Regla de gobernanza (decisión usuario 2026-11-01): "NO agregues requerimientos o intenciones a los spec con criterio por si acaso. Lo que deseamos para el futuro son backlog, que deben ser refinados por speckits. Eso NO forma parte nunca de los specs." Editar `.github/agents/*.agent.md` y `.opencode/agents/*.md` de pensador, documentador, arquitecto, security-auditor y Agent-SSD (paridad) para que cualquier requerimiento/intención/mejora "por si acaso" o "para el futuro" se canalice a `pendientes-implementacion.md` como backlog a refinar por Speckit y NUNCA se agregue al `spec.md` en curso ni a specs cerradas. Cierra FR-011 / SC-006 de la spec 035. | `pensador` | Pendiente | `pensador` | No |

## En progreso

*No hay tareas en progreso*

## Finalizada

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T040 | 011 | Allowlist URLs | ... | `devops` | Finalizada | `devops` |

## Finalizado QA

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T059 | 011 | Validar DryRun | ... | `qa-senior` | Finalizado QA | `qa-senior` |

## Finalizado Security

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T051 | 011 | Verificar identidad | ... | `devops` | Finalizado Security | `devops` |

## Cerrado

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 038-DOC-01 | 038 | Redactar `spec.md` de aprovisionamiento externo y configuración generada | `spec.md` con problema y evidencia verificada, glosario de 5 tipos, 5 historias de usuario con prueba independiente, FR-01..FR-17, NFR-01..NFR-08, 12 criterios de éxito y 12 casos borde. Sin placeholders. | `pensador` | Cerrado | `pensador` |
| 038-DOC-02 | 038 | Redactar `checklists/requirements.md` y validar la spec | 25 ítems (calidad de contenido, completitud, coherencia con el proyecto), todos conformes; sin bloqueantes salvo la dependencia de gobernanza declarada. | `pensador` | Cerrado | `pensador` |
| 038-DOC-04 | 038 | Redactar ADR-0014 y la propuesta de enmienda constitucional | ADR aceptado en `arquitectura/adr/adr-0014-configuracion-generada-y-provisionamiento-por-tipo.md` con R1–R12, 4 alternativas, guardrails, diagrama, spec linking y plan. Índice de ADRs actualizado (fila 0014 + referencia cruzada 038). Enmienda v2.1.0 redactada en `arquitectura/constitution-v2.1.0-enmienda.md`. Redactado por `pensador` por indisponibilidad de `arquitecto` en el runtime; su revisión corresponde a la fase `analyze`. | `arquitecto` | Cerrado | `pensador` |
| 012-T011 | 012 | Congelar spec | ... | `pensador` | Cerrado | `pensador` |
| 028-T01 | 028 | Crear ADR-0011 public docs routing | ADR-0011 aceptada con routing src/<App>/docs/ y README*.md | `arquitecto` | Cerrado | `arquitecto` |
| 028-T02 | 028 | Actualizar Constitution Art.VII | Whitelist actualizada con routing docs públicas | `pensador` | Cerrado | `pensador` |
| 028-T03 | 028 | Actualizar índice 00-indice.md | Entrada Spec 028 añadida | `documentador` | Cerrado | `documentador` |
| 028-T04 | 028 | Implementar skill public-documentation | Crear skill public-documentation y actualizar pensador con routing docs públicas | `developer` | Cerrado | `developer` |
| 026-T01 | 026 | Crear research.md con validación de skills y context7 | Validar skills existentes y disponibilidad context7 | `pensador` | Cerrado | `pensador` |
| 026-T02 | 026 | Generar data-model.md del agente developer y mapeo skills | Estructura agente developer y mapeo skills → dominios | `documentador` | Cerrado | `documentador` |
| 026-T03 | 026 | Definir contracts de paridad harnesses .github ↔ .opencode | Paridad harnesses .github ↔ .opencode | `arquitecto` | Cerrado | `arquitecto` |
| 026-T04 | 026 | Crear quickstart.md de validación de invocación skill + context7 | Validación invocación skill con context7 | `documentador` | Cerrado | `documentador` |
| 026-T05 | 026 | Actualizar agente developer.agent.md y developer.md con skills especializadas y sección Rol Scrum | Actualizar agente developer con skills y Rol Scrum | `pensador` | Cerrado | `pensador` |
| 026-T06 | 026 | Actualizar Constitución Art.VII whitelist Implementador a agente developer único | Whitelist Implementador a developer único | `pensador` | Cerrado | `pensador` |
| 026-T07 | 026 | Eliminar agentes obsoletos api-developer, frontend-developer, devops, qa-senior | Eliminar agentes obsoletos de .github/agents/ y .opencode/agents/ | `plataformador` | Cerrado | `plataformador` |
| 026-T08 | 026 | Actualizar Documentación/Agents_IA_TECH/00-indice.md con estado de Spec 026 | Actualizar índice con estado Spec 026 | `documentador` | Cerrado | `documentador` |
| 026-T09 | 026 | Ejecutar sync-kit-agents.ps1 -RootPath Generator_IA_Projects -Force para propagar eliminación | Propagar eliminación a proyectos consumidores | `plataformador` | Cerrado | `plataformador` |
| 026-T10 | 026 | Validar paridad harnesses y ausencia de agentes obsoletos en destino | Validar paridad y ausencia agentes obsoletos | `developer` | Cerrado | `developer` |
| 026-T11 | 026 | Verificar compliance Constitución y sincronía harnesses | QA compliance Constitución y sincronía | `developer` | Cerrado | `developer` |
| 026-T12 | 026 | Cerrar spec 026 en pendientes-implementacion.md | Cierre formal spec 026 | `pensador` | Cerrado | `pensador` |


## Backlog (futuro, sin spec)

> Regla R1: lo que se desea para el futuro vive aquí y se refina por Speckit cuando corresponda. No entra a ningún `spec.md`.

| ID | Ítem | Origen / motivo | Estado |
|----|------|-----------------|--------|
| B-001 | **Evaluación con respuestas reales del LLM** | Decisión del usuario (2026-11-07): será la próxima spec después de 038. Medir el comportamiento de los agentes con respuestas reales, no solo la estructura de sus archivos | Pendiente |
| B-002 | **Spec 039 — Integración asistida de `kit-integrado`** | La integración de ECC no es copia: es integración asistida por IA con inventario diferencial, evaluación caso por caso, libro mayor, lista negra de importación y verificación. Separada de 038 por tener gobernanza y threat model propios | Pendiente |
| B-003 | Versionado semántico por release tag | Decisión del usuario (2026-11-07): hoy no agrega valor frente a branch head. Se implementa junto con el instalador del KIT; incluye tags firmados y comparación por release | Pendiente |
| B-004 | Instalador único del KIT | Ya existe el borrador `plataforma-bootstrap-instalador-unico`; el versionado semántico (B-003) y la distribución de dependencias se cuelgan de ese trabajo | Pendiente |
| B-005 | **Spec 040 — Delegación anidada en OpenCode** | `subagent_depth` default 1; issue #8114 registrado en el spec archivado `018-pensador-delegation-fix`: en ciertas versiones ningún subagente puede invocar otro. El kit asume delegación de un solo nivel (Pensador → todos). Es límite del tool: corregirlo exige cambiar el modelo de delegación, no la configuración del arnés. Declarado en 038 como `soportado-con-limite` | Pendiente |
| B-006 | **Spec 041 — Hooks de sesión en `.github/hooks/`** | Capacidad declarada y nunca instalada: `MCPs/context-mode.md` §4.2 documenta `.github/hooks/context-mode.json`, `specs/012-ecc-integration/matriz-comparacion.md` dice "Sin hooks de sesión" y el directorio no existe en disco. Instalarlos cambia gobernanza, permisos y contrato de sesión. Declarado en 038 como `no-soportado` en el kit | Pendiente |
| B-007 | **Spec 042 — Superficie de subagentes en el runtime** | El `subagent` de esta sesión expone solo `explore` y `general` (bitácora del 2026-11-05). Es la superficie del tool en este runtime, no el modelo de agentes: en OpenCode real `developer` sí es delegable porque `mode` sin declarar vale `all`. Declarado en 038 como `equivalente-distinto` | Pendiente |
| B-008 | **Spec 043 — Paridad de frontmatter con Copilot** | Copilot no tiene `mode: primary/subagent` ni `permission` con globs: la paridad de frontmatter es imposible. Exige definir la paridad a nivel de capacidad y reescribir el frontmatter de los 14 agentes. Declarado en 038 como `equivalente-distinto` / `no-soportado` por clave | Pendiente |

**Criterio de corte (decisión del usuario, 2026-11-07)**: cada inconsistencia se atiende en una spec propia, con un error de diseño o de implementación por spec. 038 declara las cuatro en la matriz y las valida; no modifica ninguna.

## Deuda tecnica abierta

| ID | Deuda | Evidencia | Disparador para retomarla | Estado |
|----|-------|-----------|---------------------------|--------|
| DD-01 | El nivel 1 `.specify/memory/constitution.md` sigue en v2.0.0 con la tabla de Art. VII malformada (5 columnas de titulo, 4 de separador) | `edit` denegado al tier documental y a `Agent-SSD`; solo `plataformador` tiene `edit: "*": allow`. El nivel 2 ya fue reconciliado a v2.1.0 | Correr desde `plataformador` antes de cualquier `-Force` de `plataformador-bootstrap.ps1`, que revertiria el nivel 2 | Abierta |
| DD-02 | `sync-constitutions.ps1` L59-60 y `sync-kit-files.ps1` L117-118 comparan con hash crudo: mismo defecto que la 029 | El flujo 021 no esta cableado (cero invocaciones) y `scripts/sync/` esta excluido de la propagacion | Cuando el flujo 021 se cablee, antes de retirar `sync-kit.ps1` | Abierta |
| DD-03 | `sync-skills.ps1` L116-117 compara con hash crudo | Impacto acotado: copia redundante, sin perdida de datos ni sobrescritura indebida | Oportunista, cuando se toque ese script | Abierta |
| DD-04 | Mapas de manifiesto con hash crudo: `sync-agents-github/opencode/vscode.ps1` y `sync-src-structure.ps1` | No son decisiones de escritura, son registro de drift | Solo si el drift empieza a reportar falsos positivos | Abierta |
| DD-05 | Un archivo con EOL distinto figura como drift permanente en los manifiestos | Mismo mecanismo que el defecto de la 029 | Al abordar el drift de manifiestos | Abierta |
| DD-06 | `opencode.json` imprime `[FILE]` antes de saber que solo va a mergear | L650 emite `[FILE]`, L663 emite `[GUARD]` | Cosmetico: cubierto por 029-T027 | Abierta |
| DD-07 | Ningun `robocopy` del motor verifica su exit code | L604, L606 y L637 descartan la salida con `>$null 2>&1` y nunca miran `$LASTEXITCODE`: un fallo de copia de `scripts/` es silencioso. Con la 029 el directorio pasa a tener dos archivos acoplados (`sync-kit.ps1` + `sync-kit-lib.ps1`) y el motor hace dot-source fail-closed, asi que un fallo parcial puede dejar un consumidor con un sync que aborta en cada corrida | Al implementar 029-T001. El orden alfabetico copia `sync-kit-lib.ps1` antes que el motor, lo que hace improbable el caso peor pero no lo garantiza | Abierta |
| DD-08 | **`tests/upgrade_framework.Tests.ps1` no compila**: 4 errores de parseo (`ParseException` L566 por here-string `@"` sin cerrar, mas falta de cierre de bloque en L562, L561 y L225) presentes desde el commit `e53bb29` | Verificado el 2026-10-29 con `Parser::ParseFile` sobre el archivo: 4 errores. `Invoke-Pester tests/` aborta en el parseo y devuelve `Passed: 0 Failed: 1` sin ejecutar un solo test. La suite del KIT **nunca corrio** | **Bloqueante e inmediata**: sin esto no existe linea base. Bloquea 029-T025 (correr la suite), 029-T036 (cobertura base del motor) y **NFR-02 entero** (cero regresiones no es medible). La reparacion es acotada (cerrar el here-string y los bloques) y corresponde al tier Plataforma | Abierta |
| DD-09 | La spec 029 declara NFR-02 "cero regresiones en el guard de `.opencode/.gitignore`, en huerfanos y en `.opencode/config.json`" apoyandose en `tests/upgrade_framework.Tests.ps1`, que no toca el motor y ademas no compila (DD-08) | Analyze ya lo detecto como **H-02 (severidad Alta)**: "el gate de regresion es ficticio; no existe linea base. Una regresion real pasaria el gate". La verificacion del 2026-10-29 lo confirma y lo agrava | Se resuelve junto con DD-08 y 029-T036. Hasta entonces NFR-02 queda como aspiracion, no como gate | Abierta |

**Resuelta en esta sesion**: la codificacion doble de este mismo archivo (mojibake cp1252 en 67 lineas: 63 por la regla `Ã`, 3 por la regla `â€` y la linea L109 con daño mixto) fue reparada linea por linea el 2026-10-27, preservando BOM UTF-8, CRLF y el historial de git (diff acotado a las lineas dañadas, sin tocar las sanas). Sobrevive un typo de contenido ajeno a la codificacion en la fila 002-T029 ("despuós" por "después") que no se toco por ser cambio de contenido, no de encoding.

## Deuda de seguridad abierta (spec 029)

> Fuente: `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/threat-model.md` (513 lineas, 16 amenazas).
> Las 11 filas de abajo son las que **no tienen cobertura** en `tasks.md`. Todas son **preexistentes**: la 029 las conserva, no las introduce.

| ID | Severidad | Amenaza | Superficie | Tratamiento |
|----|-----------|---------|------------|-------------|
| SR-01 | **Critical** | El merge adopta del maestro todo lo que no es `mcp` (`permission`, `plugin`, `instructions`, `provider`, `model`) sin allowlist de claves ni validacion de schema | merge `mcp` | Spec nueva. ADR-0010 R7 lo exige y nada lo implementa. **No arreglar dentro de la 029** (FA-01) |
| SR-02 | **High** | Si el destino no tiene bloque `mcp`, el merge devuelve `NoLocalMcp` y el llamador cae a `Copy-Item`: el consumidor adopta el `mcp` del maestro con rutas absolutas de otra maquina | merge `mcp` | Spec nueva. Contradice ADR-0009 guardrail 1. Corregida la afirmacion falsa en `plan.md` L183 el 2026-10-27 |
| SR-03 | **High** | `[IO.File]::WriteAllText` no es atomico: una interrupcion a mitad deja `opencode.json` truncado, y si el consumidor lo tiene gitignored no hay otra copia del bloque `mcp` | escritura LF | Spec nueva (escritura atomica via temp + replace) |
| SR-10 | **High** | El `mcp` preservado persiste en todos los syncs: el motor reporta `[GUARD] PRESERVADO` y no hay vencimiento ni auditoria de rutas | merge `mcp` | Spec nueva (politica de revalidacion de rutas) |
| SR-06 | Medium | `scripts/sync-kit-lib.ps1` viaja por `robocopy` y se ejecuta por dot-source sin provenance ni hash; `-KitPath` admite codigo sin commitear | cadena de suministro | Agregar SHA256 del modulo al log durante la implementacion (T003) |
| SR-07 | Medium | Un archivo homonimo en `<consumidor>/scripts/` se pisa sin WARN, y la version que corre es la de la corrida previa | cadena de suministro | WARN en el import si el hash no coincide con el del clon |
| SR-09 | Medium | `ConvertTo-Json -Depth 10` no garantiza byte-identidad al reserializar: CA-06 "byte-identico" es inverificable tal como esta redactado | escritura LF | Redefinir CA-06 como "semanticamente identico + EOL verificado". Ver analyze H-04 |
| SR-11 | Medium | `ReadAllBytes` sin streaming ni limite (hasta ~3x en memoria) y clasificacion `EolOnly` aplicada a archivos binarios | comparacion | Limite de tamano y rechazo de binarios en `Compare-KitFileContent` |
| SR-12 | Low | TOCTOU entre la comparacion y la escritura | escritura LF | Aceptado: ventana local, sin multi-usuario |
| SR-13 | Low | Junction o symlink en el destino que apunte fuera de `$RootPath` | escritura LF | Aceptado: requiere permiso de escritura local previo |
| SR-15 | Low | El resultado `Error` del merge no reporta la causa (viola Art. V) | merge `mcp` | Propagar el mensaje de la excepcion en el `Write-Warn` |

**Con cobertura en `tasks.md`**: SR-04 y SR-05 (T013-T017, T026), SR-08 parcial (T003), SR-14 parcial (T016, T018), SR-16 parcial (T004).

**Tasks derivadas propuestas por Analyze, pendientes de decision del usuario** (no incorporadas a `tasks.md`):
T030 guardarrail estatico de paridad Windows/Linux (CA-08) - T031 test del contrato de mensajes de los tres resultados - T032 politica explicita de `EolOnly` en el guard de `.opencode/.gitignore` - T033 reescribir la verificacion de CA-06 - T034 decision y test del fallback `NoLocalMcp` - T035 anclar T022 y T023 a secciones concretas - T036 cobertura base del motor - T037 resolver el drift documental del motor duplicado - T038 verificar la propagacion de `scripts/sync-kit-lib.ps1`.

## Reglas de gobernanza del backlog (spec 035, fr-011 / sc-006)

> Norma transversal (decision usuario 2026-11-01). Este archivo es el **backlog vivo** y el **segundo control** del `pensador`: respaldo de Speckit y contenedor de procesos fuera del flujo.

### R1 — Futuro al backlog, nunca a specs

- NO se agregan requerimientos ni intenciones a los `spec.md` con criterio "por si acaso" o "para el futuro".
- Lo que se desea para el futuro es **backlog**: debe registrarse en este archivo para **refinarse por Speckit** (spec → plan → tasks → analyze → converge → implement) cuando corresponda.
- Un requerimiento futuro **nunca forma parte de un spec** (ni del feature en curso ni de specs cerradas).
- Todo item de backlog, para materializarse, pasa por un ciclo Speckit y recibe su propia especificación; solo entonces entra a un spec.

### R2 — Aplicación

- Aplica a TODOS los agentes documentales: `pensador`, `documentador`, `arquitecto`, `security-auditor`, `Agent-SSD`.
- Cuando en una fase Speckit surja una mejora futura o un "por si acaso", se redirige aquí (con responsable y estado Pendiente), NO se edita el `spec.md`.
- Recordatorio: los specs describen el **alcance presente**; el futuro vive en este archivo.
