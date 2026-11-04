# Plan Técnico — Spec 036: Orquestador único de sync del kit

**Feature Branch**: `036-sync-kit-paridad-motor`  
**Spec**: `specs/036-sync-kit-paridad-motor/spec.md`  
**Estado**: Aprobado por usuario  
**Responsable**: `pensador` (ejecuta speckit-plan)  
**Fecha**: 2026-11-03

## 1. Objetivo del plan

Convertir `scripts/sync-kit.ps1` en el único orquestador estable del sync transversal del kit, extrayendo toda la lógica de dominio a scripts independientes depurables por separado, y cerrar los cinco defectos D1-D5 documentados en la spec.

## 2. Constitución y guardrails

- Constitution Check: PASS (`.specify/memory/constitution.md` v2.0.0, 9 artículos + Art.VI, sin placeholders).
- Límites de escritura (agente documental): solo `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`. NUNCA tocar `src/`, `Documentacion/<OtraApp>/`, `.opencode/config.json` de apps.
- Cada script de dominio debe poder ejecutarse aislado con `-StageDir`, `-RootPath`, `-DryRun` y emitir `RESULT:`.
- El orquestador no define lógica de dominio: solo lista capas, invoca, recolecta `RESULT:` y resume.

## 3. Hallazgos condicionantes (5)

| ID | Hallazgo | Impacto en el plan |
|----|----------|-------------------|
| H1 | Bootstrap descarga `sync-kit.ps1` como archivo único desde master | Al adelgazar `sync-kit.ps1`, la descarga en frío queda incompleta → hay que descargar bundle del motor o exigir clon |
| H2 | Layout plano `scripts/` + clean+replace borraría el orquestador en ejecución | Regla "el motor no se auto-sincroniza": excluir `sync-kit*.ps1`, `sync-*.ps1`, `lib/` de la capa de copia |
| H3 | `sync-kit-agents.ps1` es orquestador desconectado (nadie lo invoca) | Sus 12 capas se integran al orquestador único `sync-kit.ps1` o quedan como módulo invocado por él |
| H4 | `scripts/sync/skills/sync-skills.ps1` huérfano (no figura en `$script:Layers`) | Mover a `scripts/sync-skills.ps1` (dominio plano, no anidado) |
| H5 | `plataformador-bootstrap.ps1` invoca solo `sync-kit.ps1` vía `Invoke-SyncKit` | El bootstrap debe seguir invocando `sync-kit.ps1` (orquestador); `sync-kit-agents.ps1` deja de ser entry point competidor |

## 4. Fases de implementación (F0-F8)

### F0 — Línea base (obligatorio antes de tocar código)

- Correr las 5 suites de tests del kit: `harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1`
- Capturar snapshot de divergencia maestro→destino (skills, rules, prompts, workflows, copilot-instructions, tests whitelist)
- Capturar estado actual de `.bootstrap-audit.log` (206 entradas, 136 raíces)
- Resultado: baseline documentado para comparar post-implementación

### F1 — Adelgazar orquestador `sync-kit.ps1` (FR-016, FR-017, FR-019, SC-009)

- Retirar marca `[021-DEPRECATED]` (commit c56b56c)
- Extraer `Merge-OpenCodeConfig` → `scripts/sync/opencode/sync-opencode-config.ps1`
- Extraer `Merge-KitBlock` → `scripts/sync/kit-block/sync-kit-block.ps1`
- Extraer gestión de huérfanos → `scripts/sync/orphans/sync-orphans.ps1`
- Extraer `Sync-TransversalKit` → `scripts/sync/transversal/sync-transversal.ps1`
- Orquestador queda con: lista de capas, invocación de scripts hijos, recolección `RESULT:`, resumen

### F2 — Crear scripts de dominio plano `scripts/` (FR-018, FR-020, SC-010)

- `scripts/sync-skills.ps1` (mover desde `scripts/sync/skills/sync-skills.ps1`) — capa `skills`
- `scripts/sync-github-extras.ps1 -Kind rules|prompts|workflows|copilot` — capa `.github/` restante (D2, FR-005)
- `scripts/sync-tests-kit.ps1` — capa de tests whitelist (D4, FR-007)
- `scripts/sync-mcp-graphify.ps1` — capa graphify unificación (D5, FR-011, FR-012)
- `scripts/sync-backup-prune.ps1` — capa de poda con protección backup llamador (D1, FR-001, FR-002, FR-003)
- Cada uno: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`, `RESULT:`

### F3 — Conectar capas al orquestador (FR-016, FR-020, SC-003, SC-010)

- `$script:Layers` en `sync-kit.ps1` incluye: kit-files, agents-github, agents-opencode, agents-vscode, docs, constitutions, src-structure, mcp-install, mcp-lift-opencode, mcp-lift-vscode, indexing, externals, skills, github-extras, tests-kit, mcp-graphify, backup-prune
- `-Only` / `-Skip` / `-ListLayers` funcionales
- `sync-kit-agents.ps1` deja de ser orquestador competidor: sus capas se absorben o se retira

### F4 — Corregir D1: Poda que protege backup del llamador (FR-001, FR-002, FR-003, SC-001)

- Poda excluye carpetas que existían antes de iniciar la corrida (conjunto inicial, no nombre/fecha)
- Parámetros `-KeepBackups <n>` y `-NoPrune`
- Cada borrado registrado en resumen (ruta, tamaño, regla)
- Fallo de poda = fail-open WARN, no aborta corrida

### F5 — Corregir D3: Verificador audit log sin falso negativo (FR-008, FR-009, FR-010, SC-004)

- `Test-AuditLogIntegrity` recalcula hash sobre payload sin `hash` y sin `prevHash`
- Opera sobre texto crudo de cada línea (no round-trip JSON)
- `prevHash: null` = raíz legítima, contada y reportada, sin violación
- Exit code distingue: 0 (válido), ≠0 (violaciones), estado propio (ausente/vacío)

### F6 — Corregir D5: Unificar entrada graphify (FR-011, FR-012, SC-005)

- Una sola entrada `graphify` canónica (spec 020, forma `mcp.servers`)
- Regenerar ruta cuando apunte fuera de `RootPath` (no solo cuando command falte)
- Preservar `enabled` del usuario
- WARN al detectar duplicados o ruta ajena corregida

### F7 — Corregir D4: Capa de tests del kit (FR-007, FR-014, SC-002, SC-006)

- Whitelist de 5 tests en capa del orquestador
- Respaldo de tests del proyecto que colisionen por nombre
- No borrar tests fuera de whitelist
- Suite ejecutable sin Pester, exit 0 / exit 1

### F8 — Tests de regresión y verificación (FR-013, SC-006, SC-007, SC-008)

- Al menos 1 assert nuevo por defecto (D1-D5) en `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1`
- Suma ≥15 asserts nuevos respecto de los 45 actuales, 0 `[FAIL]`
- Dry-run del orquestador reporta cuántos archivos cambiarían por capa (número concreto)
- Ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`

## 5. Criterios de aceptación (mapeo SC)

| SC | Descripción | Fase |
|----|-------------|------|
| SC-001 | 3 backups previos intactos tras corrida | F4 |
| SC-002 | Divergencia 0 solo con orquestador (skills, rules, prompts, workflows, tests, copilot-instructions) | F1-F7 |
| SC-003 | Un solo comando completa el sync, 0 scripts huérfanos | F3 |
| SC-004 | Verificador: 0 violaciones, 136 raíces; detecta 1 entrada alterada | F5 |
| SC-005 | 1 entrada graphify, ruta dentro de RootPath, enabled preservado | F6 |
| SC-006 | Suite pasa exit 0, ≥15 asserts nuevos, 0 FAIL | F8 |
| SC-007 | Ninguna corrida toca Documentacion/<AppName>/, src/, .opencode/config.json | F0-F8 |
| SC-008 | Dry-run reporta número concreto de archivos por capa, sin escribir | F8 |
| SC-009 | 0 funciones de dominio dentro sync-kit.ps1; 4 funciones como scripts propios exit 0 | F1 |
| SC-010 | 6 capas de superficie restante exit 0 con RESULT: propio; -ListLayers funcional | F2-F3 |

## 6. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Bootstrap descarga sync-kit.ps1 como archivo único | Descarga incompleta al adelgazar | Exigir clon o descargar bundle del motor; documentar en bootstrap |
| Capa clean+replace borra orquestador en ejecución | Sync falla o se auto-destruye | Excluir `sync-kit*.ps1`, `sync-*.ps1`, `lib/` de copia (regla motor no auto-sincroniza) |
| sync-kit-agents.ps1 sigue siendo entry point huérfano | Confusión de dos orquestadores | Retirar o convertir en módulo invocado por sync-kit.ps1 |
| Test-AuditLogIntegrity sigue fallando | Auditoría rota | Verificación por texto crudo, sin round-trip JSON, raíces como legítimas |
| Dry-run no calcula diff | Usuario no sabe qué cambiará | Cada capa nueva implementa cálculo de diff en dry-run |

## 7. Dependencias entre fases

```
F0 (línea base) → F1 (adelgazar orquestador) → F2 (crear dominios) → F3 (conectar capas)
                                                      ↓
                                              F4 (D1 poda) ←→ F5 (D3 audit) ←→ F6 (D5 graphify) ←→ F7 (D4 tests)
                                                      ↓
                                              F8 (tests regresión + verificación)
```

F0 es prerequisito de todo. F1-F3 son dependencias estructurales. F4-F7 son independientes entre sí una vez F1-F3 completadas. F8 valida todo.

## 8. Artefactos de salida

| Fase | Artefacto | Ubicación |
|------|-----------|-----------|
| F0 | Snapshot de divergencia | `tests/fixtures/baseline-036.md` |
| F1 | `sync-kit.ps1` adelgazado (sin lógica de dominio) | `scripts/sync-kit.ps1` |
| F1 | 4 scripts de dominio extraídos | `scripts/sync/{opencode,kit-block,orphans,transversal}/*.ps1` |
| F2 | 6 scripts de dominio nuevos | `scripts/sync-skills.ps1`, `scripts/sync-github-extras.ps1`, etc. |
| F3 | `$script:Layers` actualizado, `-Only/-Skip/-ListLayers` | `scripts/sync-kit.ps1` |
| F4 | `scripts/sync-backup-prune.ps1` + lógica en orquestador | `scripts/` |
| F5 | `Test-AuditLogIntegrity` corregido | `upgrade_framework.ps1` |
| F6 | Lógica graphify unificada | `scripts/sync/mcp/lift-opencode.ps1` + capa nueva |
| F7 | Capa tests whitelist | `scripts/sync-tests-kit.ps1` |
| F8 | ≥15 asserts nuevos | `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1` |
| Transversal | `spec.md` actualizado con D1-D4 persistidos | `specs/036.../spec.md` |
| Transversal | `00-indice.md` y `pendientes-implementacion.md` actualizados | `Documentacion/Agents_IA_TECH/` |

## 9. Estimación y orden de ejecución

1. F0: Línea base (1 sesión)
2. F1: Adelgazar orquestador + extraer 4 dominios (1-2 sesiones)
3. F2: Crear 6 scripts de dominio plano (1-2 sesiones)
4. F3: Conectar capas al orquestador (1 sesión)
5. F4-F7: Corregir D1, D3, D5, D4 (paralelizable, 2-3 sesiones)
6. F8: Tests de regresión y verificación (1 sesión)

Total estimado: 7-10 sesiones de implementación.