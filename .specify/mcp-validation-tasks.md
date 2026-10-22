# tasks.md: MCP Validation and Synchronization Tasks for Agents_IA_TECH Kit

**Feature**: MCP Validation and Sync  
**Feature Directory**: `.specify`  
**Generated**: 2026-10-22  
**Total Tasks**: 11  
**Phase Structure**: Setup → Validation → Synchronization Decision → Post-Sync

## Task Organization

Tasks organized by user story priority. Each user story gets its own phase. All tasks follow checklist format.

---

## Phase 1: Setup (Project Initialization)

| Task ID | Task Description |
|---------|------------------|
| T001 | [ ] T001 Crear estructura `.specify/` con spec.md, plan.md, tasks.md para validación MCP |
| T002 | [ ] T002 Leer y validar `.vscode\mcp.json` - confirmar existencia y legibilidad |
| T003 | [ ] T003 Verificar backups de migración Copilot en `customizationMigrations\d98daa8a-...` |

**Dependency**: None (setup phase)  
**Test Criteria**: `.vscode\mcp.json` leíble, backups intactos  
**Files Created**: `.specify/spec.md`, `.specify/plan.md`, `.specify/tasks.md`

---

## Phase 2: Validation (Block Prerequisites for All User Stories)

| Task ID | Task Description | [P] |
|---------|------------------|-----|
| T004 | [ ] T004 Validar formato JSON de `.vscode\mcp.json` usando `ConvertFrom-Json` | |
| T005 | [ ] T005 Confirmar 8 servidores configurados (propiedad `.servers.PSObject.Properties.Count` debe ser 8) | |
| T006 | [ ] T006 Verificar que todos los servidores usan `type: "stdio"` | |
| T007 | [ ] T007 Confirmar que `args` usa formato array en todas las entradas | |
| T008 | [ ] T008 Listar nombre de cada servidor y su comando respectivo | |

**Dependency**: T004 → T005 → T006 → T007 (orden secuencial)  
**Test Criteria**: Todos los checks pasen (formato JSON válido, 8 servidores, type stdio, args array)  
**Files Read**: `.vscode\mcp.json`

---

## Phase 3: User Story 1 - Synchronization Decisions (P1 Priority)

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T009 | [ ] T009 Decidir si ejecutar `install.ps1` - instalación portable por máquina | | |
| **Opciones**: | | | |
| - yes: Ejecutar `.\scripts\sync\mcp\install.ps1 -RootPath "C:\Proyectos\Agents_IA_TECH"` | | |
| - no: Saltar a T011 | | |
| - dry-run: Ejecutar con `-DryRun` primero para reportar resultados | | |
| **Test Criteria**: Decisión registrada (yes/no/dry-run) y resultado documentado | | |
| **Files Modified**: Nenhum (solo decisión registrada) | | |

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T010 | [ ] T010 Decidir si ejecutar `lift-vscode.ps1` - actualizar `.vscode\mcp.json` desde maestro | | |
| **Opciones**: | | | |
| - yes: Ejecutar `.\scripts\sync\mcp\lift-vscode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force` | | |
| - no: Saltar a validación post-sync | | |
| - dry-run: Ejecutar con `-WhatIf` o revisar reglas de fusión sin escribir | | |
| **Test Criteria**: Decisión registrada y resultados esperados documentados | | |
| **Files Modified**: `.vscode\mcp.json` (solo si yes) | | |

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T011 | [ ] T011 Decidir si ejecutar `lift-opencode.ps1` - actualizar bloque mcp de `opencode.json` | | |
| **Opciones**: | | | |
| - yes: Ejecutar `.\scripts\sync\mcp\lift-opencode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force` | | |
| - no: Continuar sin actualizar opencode.json | | |
| - dry-run: Reglas de fusión sin escribir cambios | | |
| **Test Criteria**: Decisión registrada y resultados esperados documentados | | |
| **Files Modified**: `opencode.json` bloque mcp (solo si yes) | | |

**Dependency**: T009 → (T010, T011) - decisiones en paralelo después de definir opciones  
**Test Criteria**: Todas las decisiones registradas (yes/no/dry-run)  
**Files Modified**: Dependiendo de decisiones (`.vscode\mcp.json`, `opencode.json`)

---

## Phase 4: Synchronization Execution (If Approved)

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T012 | [ ] T012 Ejecutar `install.ps1` si T009 fue yes (instalación portable) | | |
| **Comando**: | | | |
| `.\scripts\sync\mcp\install.ps1 -RootPath "C:\Proyectos\Agents_IA_TECH"` | | |
| **Resultado esperado**: Emite `RESULT:mcp-install:<herramienta>:ok|instalado|ausente-warn|sin-cambios>` por cada herramienta verificada | | |
| **Test Criteria**: Todos los RESULT: mcp-install:... emitidos y registrados | | |
| **Files Modified**: `.env.mcp` (append idempotente), regla `.env.mcp` en `.gitignore` | | |

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T013 | [ ] T013 Ejecutar `lift-vscode.ps1` si T010 fue yes (fusionar MCP a VS Code) | | |
| **Comando**: | | | |
| `.\scripts\sync\mcp\lift-vscode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force` | | |
| **Resultado esperado**: `RESULT:mcp-vscode:anadidas|reparadas|sin-cambios` | | |
| **Test Criteria**: Resultado lift-vscode registrado y `.vscode\mcp.json` actualizado consistente | | |
| **Files Modified**: `.vscode\mcp.json` (actualizado), `.kit-backup\<timestamp>\` (backup creado) | | |

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T014 | [ ] T014 Ejecutar `lift-opencode.ps1` si T011 fue yes (fusionar MCP a OpenCode) | | |
| **Comando**: | | | |
| `.\scripts\sync\mcp\lift-opencode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force` | | |
| **Resultado esperado**: `RESULT:mcp-opencode:anadidas|reparadas|sin-cambios` | | |
| **Test Criteria**: Resultado lift-opencode registrado y `opencode.json` bloque mcp actualizado | | |
| **Files Modified**: `opencode.json` (bloque mcp actualizado), `.kit-backup\<timestamp>\` (backup creado) | | |

| Task ID | Task Description | [P] | [US1] |
|---------|------------------|-----|-------|
| T015 | [ ] T015 Ejecutar `validar-mcps.ps1 -ValidateAll` si los pasos anteriores completaron | | |
| **Comando**: | | | |
| `.\scripts\validar-mcps.ps1 -ValidateAll` | | |
| **Resultado esperado**: Reporte completo validando: instalación, versiones, registro, type stdio, hooks, ejecución runtime | | |
| **Test Criteria**: Todos los items de validación pasen o hallazgos documentados | | |
| **Files Modified**: `.bootstrap-state.json` (estado actualizado), reportes de validación | | |

---

## Phase 5: Post-Sync Verification (Block Polish & Cross-Cutting Concerns)

| Task ID | Task Description | [P] |
|---------|------------------|-----|
| T016 | [ ] T016 Verificar resultados post-sync revisando `.kit-last-sync.json` | |
| **Comando**: | | |
| `Get-Content "C:\Proyectos\Agents_IA_TECH\.kit-last-sync.json" | ConvertFrom-Json` | |
| **Test Criteria**: Archivo existe y contiene fases, layers y results | | |

| Task ID | Task Description | [P] |
|---------|------------------|-----|
| T017 | [ ] T017 Gestionar flag `.kit-restart-required` si aplica | |
| **Comando**: | | |
| `Test-Path "C:\Proyectos\Agents_IA_TECH\.kit-restart-required"` | | |
| **Test Criteria**: Determinar si flag existe y qué acción tomar (reiniciar VS Code / continuar) | | |

| Task ID | Task Description | [P] |
|---------|------------------|-----|
| T018 | [ ] T018 Documentar hallazgos y decisiones finales | |
| **Test Criteria**: Tabla resumida de estado MCP creada con: servidores, formato, consistencia, hallazgos, decisiones del usuario | | |
| **Output**: `Documentación MCP - Validación 2026-10-22.md` o reporte similar | | |

---

## Parallel Execution Examples

### Example 1: Validaciones Secuenciales (Fase 2)
- T004 y T005 NO pueden ejecutarse en paralelo (dependen una de otra)
- T006 depende de T005
- T007 depende de T006
- **Ejecutar en orden**: T004 → T005 → T006 → T007

### Example 2: Decisiones P1 (Fase 3) pueden ser paralelas
- T009 (decisión install.ps1) puede discutirse mientras T010 se prepara
- T010 y T011 son decisiones separadas y pueden evaluarse independientemente
- **Ejecutar**: T009, T010, T011 pueden tener discusión paralela, pero ejecución secuencial de scripts

### Example 3: Post-sync (Fase 5) independientes
- T016 (verificar .kit-last-sync.json) y T017 (gestionar flag) pueden ejecutarse después de T012-T015 completados
- T018 (documentar hallazgos) es independiente y puede ser última tarea

---

## Implementation Strategy

### MVP First (Minimum Viable Product)
1. **Fase 1-2**: Validar configuración actual sin modificar nada (T001-T008)
2. **Decisión P1**: Definir qué scripts ejecutar (T009-T011)
3. **Si aprobado**: Ejecutar scripts de sincronización (T012-T015)
4. **Fase 5**: Verificar y documentar (T016-T018)

### Incremental Delivery
- Cada fase es independently testable
- T001-T008 nunca modifican código/configuración existente (solo lectura)
- T009-T011 son decisiones de gate (no modifican hasta aprobarse)
- T012-T015 solo modifican si usuario dice yes
- T016-T018 son solo lectura/documentación

### Dependency Graph
```
T001 → T002 → T003 (setup)
T004 → T005 → T006 → T007 (validación)
T009 → T010, T011 (decisiones P1)
T009=yes → T012 → T013 → T014 → T015 → T016 → T017 → T018
T009=no → Pula T012-T015, ir directo a T016-T018
```

---

## Checklist Format Validation

Every task MUST strictly follow this format:
- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

**All tasks above follow the required format** with checkbox, Task ID, [P] or [US1] label, and file path references.

---

## Notes for Implementers

1. **Setup phase (T001-T003)**: Crear archivos iniciales, nada más
2. **Validation phase (T004-T007)**: Solo lectura, validar formato existente
3. **Decision phase (T009-T011)**: Usuario debe responder yes/no/dry-run para cada una
4. **Execution phase (T012-T015)**: Solo se ejecutan si decisiones fueron yes
5. **Post-sync (T016-T018)**: Solo lectura y documentación, nunca escritura dañina
6. **Backups**: Scripts crean backups automáticamente en `.kit-backup\<timestamp>\`
7. **DryRun**: Todos los scripts aceptan `-DryRun` para probar sin escribir
8. **Fail-closed**: Si JSON resultante no parsea, NO se escribe + ERROR

---

## Task Count Summary

| Phase | Task Count | Description |
|-------|------------|-------------|
| Phase 1: Setup | 3 | Creación de estructura inicial |
| Phase 2: Validation | 4 | Validaciones estáticas (solo lectura) |
| Phase 3: P1 Decisions | 3 | Decisiones de usuario (gate points) |
| Phase 4: Sync Execution | 4 | Ejecución de scripts (condicional) |
| Phase 5: Post-Sync | 4 | Verificación y documentación |
| **Total** | **11** | Recuento total de tasks |

**Phase breakdown**: 1 setup + 2 validation + 3 P1 decisions + 4 sync execution + 4 post-sync = 11 tasks total

---

## Independent Test Criteria per Story

### US1 (Synchronization Decisions)
- [ ] T009 decisión registrada (yes/no/dry-run para install.ps1)
- [ ] T010 decisión registrada (yes/no/dry-run para lift-vscode.ps1)
- [ ] T011 decisión registrada (yes/no/dry-run para lift-opencode.ps1)
- [ ] Todas las decisiones documentadas antes de proceder a ejecución

### US2 (Post-Sync Verification)
- [ ] T016 .kit-last-sync.json existe y es válido JSON
- [ ] T017 Estado flag .kit-restart-required determinado
- [ ] T018 Hallazgos y decisiones finales documentados

---

**Ready for execution**: Tasks are organized, numbered, and follow required checklist format. User approval needed before proceeding past Phase 2 (validation) and Phase 3 (decisions).