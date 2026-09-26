# Tasks: MCP Update Lifecycle

**Input**: Design documents from Documentacion/Agents_IA_TECH/specs/009-mcp-update-lifecycle/

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: US1, US2, US3

## Phase 1: Setup

- [x] T001 Create project structure per implementation plan
- [x] T002 [P] Ensure scripts directory exists and is writable

## Phase 2: Foundational

- [x] T003 [P] Create `.bootstrap-state.json` schema and gitignore entry
- [x] T004 [P] Validate `.env.mcp` inventory exists and enforce no absolute paths in versioned files [FR-008]
- [x] T004b [P] Create `scripts/mcp-functions.ps1` with shared MCP functions (Resolve-McpCommand, Ensure-McpEnvFile, Update-McpEnvFile, Ensure-OpenCodeMcp)

## Phase 3: User Story 1 - Actualizar MCPs de forma independiente (Priority: P1)

**Goal**: Script `update-mcp.ps1` instala/actualiza/activa MCPs de forma independiente

**Independent Test**: Ejecutar `pwsh scripts/update-mcp.ps1` y verificar que MCPs quedan instalados/actualizados

- [x] T005 [P] [US1] Create `scripts/update-mcp.ps1` skeleton with parameters `-Force`, `-DryRun`, `-Tools`
- [x] T006 [P] [US1] Implement MCP detection logic in `scripts/update-mcp.ps1` (dot-source mcp-functions.ps1)
- [x] T007 [US1] Implement install/update logic per MCP in `scripts/update-mcp.ps1` using shared functions
- [x] T008 [US1] Implement reporting per MCP in `scripts/update-mcp.ps1` with format `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA` [FR-007]
- [x] T009 [US1] Add idempotency check in `scripts/update-mcp.ps1`
- [x] T009b [US1] Implement FR-009: Verify and update `.env.mcp` (validate existing values, resolve empty/incorrect)
- [x] T009c [US1] Implement FR-010: Update `opencode.json` resolving `{env:...}` tokens to real paths

## Phase 4: User Story 2 - Auto-actualización diaria (Priority: P2)

**Goal**: Auto-actualizar si han pasado >24h desde última actualización

**Independent Test**: Simular `.bootstrap-state.json` antiguo y ejecutar script

- [x] T010 [P] [US2] Implement `.bootstrap-state.json` read/write in `scripts/update-mcp.ps1`
- [x] T011 [US2] Implement 24h window check in `scripts/update-mcp.ps1`
- [x] T012 [US2] Implement `-Force` override in `scripts/update-mcp.ps1`
- [x] T013 [US2] Update `.bootstrap-state.json` after successful update

## Phase 5: User Story 3 - Integración con bootstrap y pensador (Priority: P2)

**Goal**: Bootstrap invoca update-mcp y pensador puede delegar

**Independent Test**: Ejecutar bootstrap y verificar invocación; simular petición de pensador

- [x] T014 [P] [US3] Modify `scripts/plataformador-bootstrap.ps1` to invoke `update-mcp.ps1` (via shared functions)
- [x] T015 [P] [US3] Add update rule to `.github/agents/pensador.agent.md`
- [x] T016 [P] [US3] Add update rule to `.opencode/agents/pensador.md`
- [x] T017 [US3] Document integration in `quickstart.md`

## Phase 6: Polish & Cross-Cutting

- [x] T018 [P] Validate idempotency and reporting
- [x] T019 [P] Update documentation in `Documentacion/Agents_IA_TECH/specs/009-mcp-update-lifecycle/`
- [x] T020 Run quickstart validation scenarios

## Dependencies & Execution Order

- Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
- US1, US2, US3 can proceed after foundational phase
- T014, T015, T016 can run in parallel

## Parallel Opportunities

- T002, T003, T004 can run in parallel
- T005, T006 can run in parallel
- T014, T015, T016 can run in parallel

## Phase 7: Convergence

- [x] T021 Create `scripts/update-mcp.ps1` with skeleton and parameters per FR-001 (missing)
- [x] T022 Implement 24h window check and `.bootstrap-state.json` read/write per FR-002, FR-003 (missing)
- [x] T023 Implement idempotency check per FR-006 (missing)
- [x] T024 Implement reporting format `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA` per FR-007 (missing)
- [x] T025 Validate `.env.mcp` inventory and enforce no absolute paths per FR-008 (missing)
- [x] T026 Modify `scripts/plataformador-bootstrap.ps1` to invoke `update-mcp.ps1` per FR-004 (missing)
- [x] T027 Add update delegation rule to `.github/agents/pensador.agent.md` per FR-005 (missing)
- [x] T028 Add update delegation rule to `.opencode/agents/pensador.md` per FR-005 (missing)
