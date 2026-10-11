# Tasks: Ciclo de vida de integración ECC

## Phase 1: Preparación
- [x] T001: Crear rama feature/ecc-integration (existe local+remoto; merge a master f5edc95 verificado 2026-10-09)
- [x] T002: Clonar ECC en proyect_ext/ECC (clonado vía install 2026-10-09; `main` limpio)
- [x] T003: Crear matriz de comparación (specs/013-ecc-integration-lifecycle/matriz-comparacion.md)

## Phase 2: Script de control
- [x] T004: Crear scripts/ecc-sync.ps1 con install/update/validate/uninstall (72 líneas; +update-indexes)
- [x] T005: Implementar detección de versión y estado (install guarda version/path; update guarda lastToolUpdate; validate chequea rules/skills/mcp-configs)
- [x] T006: Registrar estado en .ecc-state.json (existe tras install 2026-10-09; gitignored por diseño)

## Phase 3: Validación
- [x] T007: Validar flujo Speckit tras integración (flujo probado specs 002→019, todas con implement+verify)
- [x] T008: Corregir duplicaciones con namespace ecc- (verificado en 32/32 agents 2026-10-09)
- [x] T009: Probar rollback (validate→uninstall→install→validate 2026-10-09, todo exit 0; ver ciclo-de-vida.md)

## Phase 4: Documentación
- [x] T010: Documentar proceso de actualización (ciclo-de-vida.md §actualización)
- [x] T011: Documentar corrección de errores (ciclo-de-vida.md §corrección, 6 casos)
- [x] T012: Actualizar 00-indice.md (líneas 32 y 62 referencian lifecycle/ECC)
