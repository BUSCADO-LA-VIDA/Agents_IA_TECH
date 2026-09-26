# Tasks: Remediación de fuga de secreto

## Phase 1: Preparación
- [x] T001: Identificar commits con temp_opencode_output.txt
- [x] T002: Backup del repo local

## Phase 2: Limpieza working tree
- [x] T003: Eliminar temp_opencode_output.txt del disco
- [x] T004: Añadir temp_opencode_output.txt y temp_* a .gitignore

## Phase 3: Reescritura historial
- [x] T005: Instalar git filter-repo
- [x] T006: Ejecutar filter-repo para remover archivo
- [x] T007: Verificar que archivo no existe en historial

## Phase 4: Hardening gitleaks
- [x] T008: Crear .gitleaks.toml con allowlist
- [x] T009: Añadir exclusiones para .env.mcp y .bootstrap-state.json

## Phase 5: Validación
- [x] T010: Ejecutar gitleaks detect --source . --redact --verbose
- [x] T011: Rotar API key filtrada
- [x] T012: Push con --force-with-lease
- [x] T013: Confirmar workflow security-scan verde

## Phase 6: Documentación
- [x] T014: Actualizar 00-indice.md con nueva spec
- [x] T015: Registrar ADR de remediación de secretos
