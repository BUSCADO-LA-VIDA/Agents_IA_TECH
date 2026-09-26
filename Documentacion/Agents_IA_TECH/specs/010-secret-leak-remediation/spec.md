# Spec: Remediación de fuga de secreto en historial Git

## User Story
Como mantenedor del repositorio, quiero eliminar una API key filtrada en `temp_opencode_output.txt` del historial Git y prevenir futuras fugas, para que el security-scan pase y no queden credenciales expuestas.

## Contexto
Gitleaks detectó en el commit `e54c7b6eb90b6bc5fd15293420072d6cb952549b`:
- Archivo: `temp_opencode_output.txt`
- Línea 21: `"apiKey": "REDACTED"`
- RuleID: `generic-api-key`
El workflow `security-scan.yml` falla con exit code 1 y el job `Detect secrets (gitleaks)` reporta leaks found: 1.

## Requisitos Funcionales
FR-001: Eliminar `temp_opencode_output.txt` del working tree y del historial Git.
FR-002: Añadir patrones de archivos temporales y de configuración local a `.gitignore`.
FR-003: Configurar `.gitleaks.toml` con allowlist para `.env.mcp`, `.bootstrap-state.json` y `temp_*`.
FR-004: Rotar la API key filtrada fuera del alcance del repo.
FR-005: Reescribir historial y forzar push seguro con `--force-with-lease`.
FR-006: Verificar que `gitleaks detect --source . --redact --verbose` no reporte leaks.

## Requisitos No Funcionales
NFR-001: No se versionan archivos con rutas locales ni credenciales.
NFR-002: El security-scan debe pasar con exit code 0.
NFR-003: La remediación no debe romper referencias de issues/PRs existentes.

## Criterios de Aceptación
SC-001: `temp_opencode_output.txt` no existe en working tree ni en historial.
SC-002: `.gitignore` contiene `temp_opencode_output.txt` y `temp_*`.
SC-003: `.gitleaks.toml` existe con allowlist configurada.
SC-004: `gitleaks detect --source . --redact --verbose` retorna 0 leaks.
SC-005: Workflow `security-scan.yml` pasa en el próximo push.

## Riesgos
- Reescritura de historial afecta colaboradores. Mitigación: comunicar y usar `--force-with-lease`.
- Pérdida de datos si se filtra más que el archivo objetivo. Mitigación: dry-run con `git filter-repo --dry-run`.

## Dependencias
- Acceso a repo con permisos de force push.
- Herramienta `git filter-repo` o BFG Repo-Cleaner instalada.
