# Tasks — Spec 036: Orquestador único de sync del kit

**Spec**: `specs/036-sync-kit-paridad-motor/spec.md`  
**Plan**: `specs/036-sync-kit-paridad-motor/plan.md` (aprobado por usuario)  
**Estado**: Borrador (pendiente aprobación usuario)  
**Responsable**: `plataformador` (ejecución), `pensador` (orquestación)  
**Fecha**: 2026-11-03

## 1. Convenciones

- **Estado**: `Pendiente` = no iniciada; `En curso` = en ejecución; `Cerrado` = completada y verificada.
- **Dependencias**: una tarea no inicia hasta que sus dependencias estén `Cerrado`.
- **Criterio de aceptación**: cada tarea tiene criterio verificable; sin criterio cumplido, no se cierra.
- **Responsable**: todas las tareas de implementación son de `plataformador` (según pendientes-implementacion.md). `pensador` solo orquesta y valida. `TRANS-001` es de `pensador`.
- **Sin placeholders**: ninguna tarea queda con "TBD", "por definir" o "pendiente de información".

## 2. Tabla de tareas por fase

| ID | Fase | Tarea | Descripción | Dependencias | Criterio de aceptación | Responsable | Estado | Aprobación del plan |
|----|------|-------|-------------|--------------|------------------------|-------------|--------|---------------------|
| 036-T050 | F0 Línea base | Ejecutar 5 suites de tests del kit y capturar snapshot | Correr `harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1` y registrar exit code de cada una. Capturar divergencia maestro→destino en skills, rules, prompts, workflows, copilot-instructions, tests whitelist. | Ninguna | 5 suites ejecutadas, exit codes registrados, snapshot de divergencia guardado en `tests/fixtures/baseline-036.md` | plataformador | Pendiente | plataformador |
| 036-T051 | F0 Línea base | Capturar estado actual de .bootstrap-audit.log | Leer `.bootstrap-audit.log` (206 entradas), contar entradas totales, entradas con `prevHash: null` (raíces), y registrar hash de la última entrada para comparación post-D3. | Ninguna | Informe con: 206 entradas, 136 raíces, hash última entrada, estado actual del verificador | plataformador | Pendiente | plataformador |
| 036-T000 | F1 Adelgazar orquestador | Retirar marca [021-DEPRECATED] de sync-kit.ps1 | Eliminar el comentario de deprecación en la cabecera de `scripts/sync-kit.ps1` (commit c56b56c) y actualizar el encabezado para reflejar que es el orquestador vigente. | 036-T050, 036-T051 | `scripts/sync-kit.ps1` no contiene `[021-DEPRECATED]`; encabezado describe orquestador estable | plataformador | Pendiente | plataformador |
| 036-T001 | F1 Adelgazar orquestador | Extraer Merge-OpenCodeConfig a dominio propio | Extraer la función `Merge-OpenCodeConfig` (213 líneas, L512-724 en sync-kit.ps1) a `scripts/sync/opencode/sync-opencode-config.ps1` con parámetros `-Source`, `-Destination`, `-ProjectRoot`, `-Force`. | 036-T000 | Script existe, ejecutable aislado con exit 0 sobre fixture, `sync-kit.ps1` ya no define `Merge-OpenCodeConfig` | plataformador | Pendiente | plataformador |
| 036-T002 | F1 Adelgazar orquestador | Extraer Merge-KitBlock a dominio propio | Extraer la función `Merge-KitBlock` (138 líneas, L725-862 en sync-kit.ps1) a `scripts/sync/kit-block/sync-kit-block.ps1` con parámetros `-Source`, `-Destination`. | 036-T001 | Script existe, ejecutable aislado con exit 0, `sync-kit.ps1` ya no define `Merge-KitBlock` | plataformador | Pendiente | plataformador |
| 036-T003 | F1 Adelgazar orquestador | Extraer gestión de huérfanos a dominio propio | Extraer `Find-OrphanKitFiles`, `Show-OrphanList`, `Remove-OrphanFiles`, `Move-OrphanFilesToBackup`, `Invoke-OrphanDecision` (~340 líneas, L124-465) a `scripts/sync/orphans/sync-orphans.ps1`. | 036-T002 | Script existe, ejecutable aislado con exit 0, `sync-kit.ps1` ya no define funciones de huérfanos | plataformador | Pendiente | plataformador |
| 036-T004 | F1 Adelgazar orquestador | Extraer Sync-TransversalKit a dominio propio | Extraer `Sync-TransversalKit` (~280 líneas, L863-1134) a `scripts/sync/transversal/sync-transversal.ps1`. | 036-T003 | Script existe, ejecutable aislado con exit 0, `sync-kit.ps1` ya no define `Sync-TransversalKit` | plataformador | Pendiente | plataformador |
| 036-T005 | F1 Adelgazar orquestador | Adelgazar sync-kit.ps1 a solo orquestación | Reescribir `scripts/sync-kit.ps1` para que contenga solo: declaración de `$script:Layers`, invocación de scripts hijos vía `&`, recolección de líneas `RESULT:`, `Show-ExecutionSummary`, punto de entrada. Sin lógica de dominio. | 036-T001, 036-T002, 036-T003, 036-T004 | `sync-kit.ps1` no define ninguna de las 4 funciones de dominio; ejecuta los 4 scripts extraídos y emite `RESULT:` para cada uno | plataformador | Pendiente | plataformador |
| 036-T006 | F2 Crear dominios planos | Mover sync-skills.ps1 a scripts/sync-skills.ps1 | Mover `scripts/sync/skills/sync-skills.ps1` a `scripts/sync-skills.ps1` (layout plano, no anidado). Actualizar referencias internas y rutas relativas. | 036-T005 | `scripts/sync-skills.ps1` existe, ejecutable aislado con `-StageDir -RootPath -DryRun`, emite `RESULT:skills:`, el script original en `scripts/sync/skills/` queda retirado o como módulo | plataformador | Pendiente | plataformador |
| 036-T007 | F2 Crear dominios planos | Crear scripts/sync-github-extras.ps1 | Crear capa para `.github/rules/`, `.github/prompts/`, `.github/workflows/` y `.github/copilot-instructions.md` con parámetros `-StageDir`, `-RootPath`, `-DryRun`, `-Force`, `-Kind rules|prompts|workflows|copilot`. | 036-T005 | Script existe, ejecutable aislado con exit 0 por cada `-Kind`, emite `RESULT:github-extras:<kind>:<estado>`, cubre superficie `.github/` completa | plataformador | Pendiente | plataformador |
| 036-T008 | F2 Crear dominios planos | Crear scripts/sync-tests-kit.ps1 | Crear capa de whitelist de tests del kit: `tests/harness-default.ps1`, `tests/kit-sync-merge.ps1`, `tests/agents-parity.ps1`, `tests/kb-parity.ps1`, `tests/mcp-refresh-parity.ps1`. Respaldar tests del proyecto que colisionen por nombre; no borrar tests fuera de whitelist. | 036-T005 | Script existe, ejecutable aislado con exit 0, los 5 tests viajan al destino, tests propios del proyecto no se borran | plataformador | Pendiente | plataformador |
| 036-T009 | F2 Crear dominios planos | Crear scripts/sync-mcp-graphify.ps1 | Crear capa que deje una sola entrada `graphify` canónica (spec 020, forma `mcp.servers`), regenere ruta cuando apunte fuera de `RootPath`, preservar `enabled` del usuario, emitir WARN al detectar duplicados. | 036-T005 | Script existe, ejecutable aislado con exit 0, `opencode.json` destino tiene 1 entrada graphify, ruta dentro de RootPath, enabled preservado | plataformador | Pendiente | plataformador |
| 036-T010 | F2 Crear dominios planos | Crear scripts/sync-backup-prune.ps1 | Crear capa de poda de `.kit-backup/` que excluya carpetas existentes antes de iniciar la corrida, exponga `-KeepBackups <n>` y `-NoPrune`, registre cada borrado (ruta, tamaño, regla), fail-open con WARN. | 036-T005 | Script existe, ejecutable aislado con exit 0, backup del llamador sobrevive, cada borrado registrado en resumen | plataformador | Pendiente | plataformador |
| 036-T011 | F3 Conectar capas al orquestador | Actualizar $script:Layers en sync-kit.ps1 | Añadir las nuevas capas (`skills`, `github-extras`, `tests-kit`, `mcp-graphify`, `backup-prune`) a `$script:Layers` con `Script`, `AcceptsForce`, `NoStage` según corresponda. | 036-T006, 036-T007, 036-T008, 036-T009, 036-T010 | `$script:Layers` contiene todas las capas, el orquestador las invoca en orden, cada una emite `RESULT:` | plataformador | Pendiente | plataformador |
| 036-T012 | F3 Conectar capas al orquestador | Implementar -Only / -Skip / -ListLayers | Hacer funcionales los parámetros `-Only`, `-Skip` y `-ListLayers` en `sync-kit.ps1` para filtrar y listar capas. | 036-T011 | `-ListLayers` enumera todas las capas; `-Only` ejecuta solo las indicadas; `-Skip` excluye las indicadas; nombres desconocidos emiten WARN | plataformador | Pendiente | plataformador |
| 036-T013 | F3 Conectar capas al orquestador | Retirar sync-kit-agents.ps1 como orquestador competidor | Convertir `sync-kit-agents.ps1` en módulo invocado por `sync-kit.ps1` o retirarlo; asegurar que no exista un segundo entry point que nadie invoque. | 036-T011 | 0 scripts huérfanos en `scripts/sync/`, `sync-kit-agents.ps1` no es entry point independiente, el bootstrap sigue invocando `sync-kit.ps1` | plataformador | Pendiente | plataformador |
| 036-T001-D1 | F4 Corregir D1 (poda) | Implementar protección backup del llamador | La poda de `.kit-backup/` excluya carpetas que existían antes de iniciar la corrida (conjunto inicial, no nombre ni fecha). | 036-T010 | Con 3 backups previos, una corrida completa deja los 3 intactos (hash MANIFEST.sha256 idéntico) | plataformador | Pendiente | plataformador |
| 036-T002-D1 | F4 Corregir D1 (poda) | Exponer -KeepBackups y -NoPrune | Añadir parámetros `-KeepBackups <n>` (retención de carpetas generadas por la corrida) y `-NoPrune` (desactiva poda) a la capa de poda y al orquestador. | 036-T001-D1 | `-KeepBackups 2` conserva backup del llamador + 2 más recientes; `-NoPrune` no borra ninguna carpeta | plataformador | Pendiente | plataformador |
| 036-T003-D1 | F4 Corregir D1 (poda) | Registrar borrados en resumen | Cada borrado de poda quede registrado en el resumen de ejecución con ruta, tamaño y regla aplicada; fallo de poda = fail-open WARN, no aborta corrida. | 036-T002-D1 | Resumen incluye ruta, tamaño y regla de cada borrado; fallo de poda no aborta la corrida | plataformador | Pendiente | plataformador |
| 036-T003-D3 | F5 Corregir D3 (audit log) | Recalcular hash sin hash ni prevHash | Modificar `Test-AuditLogIntegrity` en `upgrade_framework.ps1` para recalcular hash sobre payload que excluya `hash` y `prevHash`. | 036-T051 | Hash recalculado sobre entrada sin `hash` ni `prevHash`, coincide con valor almacenado | plataformador | Cerrado | plataformador |
| 036-T004-D3 | F5 Corregir D3 (audit log) | Verificar sobre texto crudo, no round-trip JSON | Cambiar la verificación para operar sobre el texto crudo de cada línea, evitando `ConvertFrom-Json`/`ConvertTo-Json` que altera el `timestamp`. | 036-T003-D3 | Verificación no depende del round-trip JSON; timestamp ISO-8601 se preserva | plataformador | Cerrado | plataformador |
| 036-T005-D3 | F5 Corregir D3 (audit log) | Tratar prevHash: null como raíz legítima | Contar y reportar entradas con `prevHash: null` como raíces legítimas, sin exigir cadena lineal completa, sin escribir `audit_integrity_violation` por raíces. | 036-T004-D3 | 136 raíces históricas reportadas, 0 violaciones espurias por raíces | plataformador | Cerrado | plataformador |
| 036-T006-D3 | F5 Corregir D3 (audit log) | Exit code distinguible | El verificador devuelva exit 0 (log válido), ≠0 (violaciones), estado propio (ausente/vacío, informado). | 036-T005-D3 | Exit codes distinguibles; log vacío reportado como "log vacío", no éxito silencioso | plataformador | Cerrado | plataformador |
| 036-T005-D5 | F6 Corregir D5 (graphify) | Unificar entrada graphify canónica | Dejar una sola entrada `graphify` en `opencode.json` (forma `mcp.servers`), regenerar ruta cuando apunte fuera de `RootPath`, preservar `enabled`. | 036-T009 | `opencode.json` destino tiene exactamente 1 entrada graphify, ruta dentro de RootPath, enabled preservado en 100% de casos | plataformador | Pendiente | plataformador |
| 036-T006-D5 | F6 Corregir D5 (graphify) | Emitir WARN en duplicados y ruta ajena | Detectar duplicados V1/V2 y rutas ajenas, corregir la ruta, emitir WARN indicando cuál se conservó y qué se corrigió. | 036-T005-D5 | WARN emitido al detectar duplicados o ruta ajena corregida | plataformador | Pendiente | plataformador |
| 036-T004-D4 | F7 Corregir D4 (tests) | Mover whitelist de tests a capa del orquestador | La whitelist de 5 tests del kit viaje en la capa de tests del orquestador, no solo en `sync-kit.ps1`. | 036-T008 | Los 5 tests del kit aparecen en `tests/` del destino usando solo el orquestador | plataformador | Pendiente | plataformador |
| 036-T005-D4 | F7 Corregir D4 (tests) | Respaldar tests del proyecto que colisionen | Si un test del proyecto colisiona por nombre con uno del kit, el del kit gana y el del proyecto se respalda antes de reemplazarse. | 036-T004-D4 | Test del proyecto colisionante respaldado antes de ser reemplazado; tests fuera de whitelist no se borran | plataformador | Pendiente | plataformador |
| 036-T006-D4 | F7 Corregir D4 (tests) | Suite ejecutable sin Pester | La suite del kit sea ejecutable sin Pester, con `exit 0` / `exit 1` como único contrato de resultado. | 036-T005-D4 | Suite pasa con exit 0, contrato de resultado claro | plataformador | Pendiente | plataformador |
| 036-T052 | F8 Tests de regresión | Agregar asserts de regresión D1-D5 | Agregar al menos 1 assert nuevo por defecto (D1-D5) en `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1`, sobre fixtures temporales, sin escribir en el repositorio. | 036-T001-D1, 036-T003-D3, 036-T005-D5, 036-T004-D4, 036-T006-D4 | Suma ≥15 asserts nuevos respecto de los 45 actuales, 0 `[FAIL]`, cada assert falla antes del arreglo y pasa después | plataformador | Pendiente | plataformador |
| 036-T053 | F8 Tests de regresión | Verificar dry-run reporta números concretos | El dry-run del orquestador reporte, para cada capa nueva, cuántos archivos cambiarían (número concreto, no "se sincronizarían") y no escriba ningún archivo. | 036-T012 | Dry-run reporta número concreto de archivos por capa, 0 escrituras | plataformador | Pendiente | plataformador |
| 036-T054 | F8 Tests de regresión | Verificar frontera de escritura | Confirmar que ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json` (mtimes sin cambios antes/después). | 036-T050 | mtimes de Documentacion/<AppName>/, src/, .opencode/config.json sin cambios tras corrida | plataformador | Pendiente | plataformador |
| TRANS-001 | Transversal Gate | Implementar gate mecánico "aprobación → Speckit" | Crear mecanismo que haga obligatorio que las fases Speckit actualicen `pendientes-implementacion.md` tras aprobación del plan, evitando que se omita el flujo. | 036-T054 | Existe gate que impide ejecutar speckit sin plan aprobado registrado; TRANS-001 pasa a Cerrado | pensador | Pendiente | pensador |

## 3. Orden de ejecución y dependencias críticas

```
F0 (036-T050, 036-T051) → línea base obligatoria
    ↓
F1 (036-T000 → 036-T001 → 036-T002 → 036-T003 → 036-T004 → 036-T005)
    ↓
F2 (036-T006 → 036-T007 → 036-T008 → 036-T009 → 036-T010)
    ↓
F3 (036-T011 → 036-T012 → 036-T013)
    ↓
F4 (036-T001-D1 → 036-T002-D1 → 036-T003-D1)
F5 (036-T003-D3 → 036-T004-D3 → 036-T005-D3 → 036-T006-D3)
F6 (036-T005-D5 → 036-T006-D5)
F7 (036-T004-D4 → 036-T005-D4 → 036-T006-D4)
    ↓
F8 (036-T052 → 036-T053 → 036-T054)
    ↓
Transversal (TRANS-001)
```

F4-F7 son independientes entre sí una vez F1-F3 completadas. Pueden ejecutarse en paralelo por diferentes sesiones.

## 4. Criterios de aceptación globales (SC)

| SC | Descripción | Tareas que lo verifican |
|----|-------------|------------------------|
| SC-001 | 3 backups previos intactos tras corrida | 036-T001-D1, 036-T002-D1 |
| SC-002 | Divergencia 0 solo con orquestador | 036-T000 a 036-T013, 036-T004-D4 a 036-T006-D4 |
| SC-003 | Un solo comando completa el sync, 0 scripts huérfanos | 036-T013 |
| SC-004 | Verificador: 0 violaciones, 136 raíces; detecta 1 entrada alterada | 036-T003-D3 a 036-T006-D3 |
| SC-005 | 1 entrada graphify, ruta dentro de RootPath, enabled preservado | 036-T005-D5, 036-T006-D5 |
| SC-006 | Suite pasa exit 0, ≥15 asserts nuevos, 0 FAIL | 036-T052 |
| SC-007 | Ninguna corrida toca Documentacion/<AppName>/, src/, .opencode/config.json | 036-T054 |
| SC-008 | Dry-run reporta número concreto de archivos por capa, sin escribir | 036-T053 |
| SC-009 | 0 funciones de dominio dentro sync-kit.ps1; 4 scripts propios exit 0 | 036-T001 a 036-T005 |
| SC-010 | 6 capas de superficie restante exit 0 con RESULT: propio; -ListLayers funcional | 036-T006 a 036-T012 |

## 5. Notas de ejecución

- Cada script de dominio debe poder ejecutarse de forma aislada con `-StageDir`, `-RootPath`, `-DryRun` y devolver `RESULT:`.
- El orquestador `sync-kit.ps1` no define lógica de dominio: solo lista capas, invoca, recolecta `RESULT:` y resume.
- No tocar `Documentacion/<AppName>/`, `src/`, ni `.opencode/config.json` de apps (guardrail absoluto).
- `TRANS-001` es responsabilidad de `pensador`, no de `plataformador`; cierra la deuda del gate mecánico.