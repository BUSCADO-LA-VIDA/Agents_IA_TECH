# Tasks: Sincronización y actualización de dependencias-manifest.yml

**Input**: Design documents from Documentacion/Agents_IA_TECH/specs/015-manifest-sync-and-upgrade/

## Phase 1: Setup
- [ ] T001 Create feature directory structure per plan
- [ ] T002 Review constitution Art.VI

## Phase 2: Foundational
- [ ] T003 Analyze current manifest handling in scripts/plataformador-bootstrap.ps1
- [ ] T004 Define reference manifest template for KIT

## Phase 3: User Story 1 — Manifest presente y completo
**Goal**: Asegurar manifest existe y completo
- [ ] T005 [P] [US1] Add Sync-Manifest function in scripts/plataformador-bootstrap.ps1
- [ ] T006 [US1] Implement creation of full skeleton if manifest missing
- [ ] T007 [US1] Implement completion of empty manifest with missing tools

## Phase 4: User Story 2 — Detección de actualización
**Goal**: Comparar y actualizar versiones
- [ ] T008 [P] [US2] Implement comparison with KIT reference manifest
- [ ] T009 [US2] Update version_actual and ultimo_check preserving customizations

## Phase 5: User Story 3 — Switch upgrade
**Goal**: Respetar upgrade por herramienta
- [ ] T010 [P] [US3] Add upgrade field with default true in template
- [ ] T011 [US3] Skip update if upgrade false

## Phase 6: User Story 4 — Post-update hooks
**Goal**: Ejecutar hooks tras actualización
- [ ] T012 [P] [US4] Execute context-mode index after update
- [ ] T013 [P] [US4] Execute codebase-memory index_repository after update
- [ ] T014 [P] [US4] Execute graphify update after update

## Phase 7: Polish
- [ ] T015 Update documentation
- [ ] T016 Run quickstart validation
