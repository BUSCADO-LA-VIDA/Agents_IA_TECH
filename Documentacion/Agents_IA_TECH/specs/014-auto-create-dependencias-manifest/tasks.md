# Tasks: Auto-crear dependencias-manifest.yml si falta en bootstrap

**Input**: Design documents from `Documentacion/Agents_IA_TECH/specs/014-auto-create-dependencias-manifest/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks grouped by user story

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Create feature directory structure per plan
- [x] T002 [P] Review constitution and spec for constraints

## Phase 2: Foundational

- [x] T003 [P] Analyze current `Read-DependenciasManifest` implementation in `scripts/plataformador-bootstrap.ps1`
- [x] T004 [P] Identify insertion point for manifest creation before read

## Phase 3: User Story 1 - Bootstrap en proyecto sin manifest (Priority: P1) MVP

**Goal**: Crear esqueleto de manifest cuando falta

**Independent Test**: Ejecutar bootstrap en proyecto sin manifest y verificar archivo creado y sin WARN

### Implementation for User Story 1

- [x] T005 [P] [US1] Add `Ensure-DependenciasManifest` function in `scripts/plataformador-bootstrap.ps1`
- [x] T006 [US1] Implement file existence check with `Test-Path` in `scripts/plataformador-bootstrap.ps1`
- [x] T007 [US1] Implement skeleton creation with header and empty sections in `scripts/plataformador-bootstrap.ps1`
- [x] T008 [US1] Add visible aviso `Write-Host "Creando esqueleto dependencias-manifest.yml..."` in `scripts/plataformador-bootstrap.ps1`
- [x] T009 [US1] Call `Ensure-DependenciasManifest` before `Read-DependenciasManifest` in bootstrap flow
- [x] T010 [US1] Ensure no overwrite of existing manifest

**Checkpoint**: User Story 1 fully functional

## Phase 4: User Story 2 - No forzar contenido del proyecto (Priority: P1)

**Goal**: Esqueleto genérico sin apps concretas del KIT

**Independent Test**: Inspeccionar archivo creado y verificar ausencia de apps del KIT

### Implementation for User Story 2

- [x] T011 [P] [US2] Define skeleton template with generic comments in `scripts/plataformador-bootstrap.ps1`
- [x] T012 [US2] Ensure template contains `licencia: pendiente de verificar` comment
- [x] T013 [US2] Verify template does not include KIT-specific apps
- [x] T014 [US2] Add guard to preserve user edits on subsequent runs

**Checkpoint**: User Story 2 fully functional

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T015 [P] Update documentation in `Documentacion/Agents_IA_TECH/specs/014-auto-create-dependencias-manifest/`
- [x] T016 Run quickstart validation
- [x] T017 Code review for constitution compliance

## Dependencies & Execution Order

- Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
- User stories can be implemented sequentially

## Parallel Opportunities

- T003 and T004 can run in parallel
- T005 and T011 can run in parallel after foundational

## Implementation Strategy

MVP = User Story 1 only. Validate bootstrap creates manifest without warnings.

**Nota de refinamiento**: Los requisitos de sincronización con referencia del KIT, switch `upgrade` por herramienta, add/remove de herramientas y post-update hooks se trasladan a la spec 015-manifest-sync-and-upgrade. Esta spec 014 queda cerrada en la creación de esqueleto y no-forzar contenido.
