# Tasks: Ciclo de vida de integración ECC

## Phase 1: Preparación
- [ ] T001: Crear rama feature/ecc-integration
- [ ] T002: Clonar ECC en proyect_ext/ECC
- [ ] T003: Crear matriz de comparación

## Phase 2: Script de control
- [ ] T004: Crear scripts/ecc-sync.ps1 con install/update/validate/uninstall
- [ ] T005: Implementar detección de versión y estado
- [ ] T006: Registrar estado en .ecc-state.json

## Phase 3: Validación
- [ ] T007: Validar flujo Speckit tras integración
- [ ] T008: Corregir duplicaciones con namespace ecc-
- [ ] T009: Probar rollback

## Phase 4: Documentación
- [ ] T010: Documentar proceso de actualización
- [ ] T011: Documentar corrección de errores
- [ ] T012: Actualizar 00-indice.md
