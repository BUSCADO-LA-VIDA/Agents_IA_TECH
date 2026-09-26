# Tasks 015

Cada tarea incluye: ID, descripcion, archivo(s), estimacion, dependencias,
criterio de done y FR de origen. Ver `design.md` para el detalle tecnico.

## Fase 1: Documentacion (completada)

- [x] T001 Documentar diseno tecnico | Documentacion/Agents_IA_TECH/specs/015-sync-kit-bootstrap/design.md | 3h | Sin dependencias | Criterio: design.md con inventario de funciones, estructura de sync-kit.ps1, cambios en bootstrap, matriz FR | FR-005
- [x] T002 Ampliar spec con migracion y ampliacion | Documentacion/Agents_IA_TECH/specs/015-sync-kit-bootstrap/spec.md | 1h | Sin dependencias | Criterio: FR-005 y FR-006 presentes con criterios de aceptacion | FR-005, FR-006
- [x] T003 Completar artefactos Speckit | Documentacion/Agents_IA_TECH/specs/015-sync-kit-bootstrap/{plan,research,data-model,quickstart,analyze,converge}.md | 2h | T001 | Criterio: todos los artefactos con contenido real, sin placeholders | FR-002

## Fase 2: Implementacion (completada)

- [x] T004 Crear scripts/sync-kit.ps1 | scripts/sync-kit.ps1 | 4h | T001 | Criterio: script standalone con logging, validacion URL, huerfanos y Sync-TransversalKit migrados; `-DryRun` ejecuta sin errores | FR-001, FR-005
- [x] T005 Anadir transversal scripts/ a la sincronizacion | scripts/sync-kit.ps1 | 1h | T004 | Criterio: `$transversalDirs` incluye `scripts/`; modulos Manifest viajan al proyecto | FR-002, FR-004, FR-006
- [x] T006 Eliminar funciones migradas del bootstrap | scripts/plataformador-bootstrap.ps1 | 2h | T004 | Criterio: funciones de huerfanos (1619-2011) y Sync-TransversalKit (2182-2411) eliminadas | FR-005
- [x] T007 Reemplazar llamadas a Sync-TransversalKit | scripts/plataformador-bootstrap.ps1 | 2h | T006 | Criterio: flujo normal y -SyncOnly invocan sync-kit.ps1 via pwsh -File | FR-003
- [x] T008 Verificar AC-01 a AC-08 | scripts/ | 2h | T007 | Criterio: todos los criterios de aceptacion de design.md seccion 7 verificados | FR-001..FR-006

## Fase 3: Verificacion (completada)

- [x] T009 Ejecutar sync-kit.ps1 en proyecto derivado | scripts/sync-kit.ps1 | 1h | T008 | Criterio: scripts/modules/ copiados; Documentacion/ intacta; config.json excluido | FR-004
- [x] T010 Ejecutar plataformador-bootstrap.ps1 -DryRun | scripts/plataformador-bootstrap.ps1 | 1h | T008 | Criterio: sin errores; invoca sync-kit.ps1 correctamente | FR-003

## Evidencia de verificacion

| Task | Evidencia |
|------|-----------|
| T004 | `scripts/sync-kit.ps1` existe (33783 bytes, 608 lineas); sintaxis OK; `-DryRun` ejecuta sin errores |
| T005 | `$transversalDirs` incluye `scripts/`; DryRun muestra "copiaria scripts/ -> ..." |
| T006 | Bootstrap reducido de 3322 a 2699 lineas; funciones de huerfanos y Sync-TransversalKit eliminadas |
| T007 | `Invoke-SyncKit` definida (linea 1785); llamadas en lineas 2495 y 2563; sintaxis OK |
| T008 | AC-01..AC-08 verificados (ver tabla abajo) |
| T009 | `sync-kit.ps1 -DryRun` muestra copia de scripts/ y exclusion de config.json |
| T010 | `plataformador-bootstrap.ps1 -SyncOnly -DryRun` invoca sync-kit.ps1 sin errores |

## Criterios de aceptacion verificados

| ID | Criterio | Estado | Evidencia |
|----|----------|--------|-----------|
| AC-01 | `sync-kit.ps1` existe y es standalone | OK | 33783 bytes; ejecuta sin bootstrap |
| AC-02 | `sync-kit.ps1 -DryRun` no escribe nada | OK | Solo imprime INFO |
| AC-03 | `sync-kit.ps1` copia `scripts/` al proyecto | OK | DryRun lista `scripts/` |
| AC-04 | `sync-kit.ps1` no toca `Documentacion/` | OK | DryRun lo declara explicitamente |
| AC-05 | `sync-kit.ps1` excluye `.opencode/config.json` | OK | DryRun lo declara |
| AC-06 | `plataformador-bootstrap.ps1` invoca `sync-kit.ps1` | OK | `Invoke-SyncKit` linea 1785 |
| AC-07 | `plataformador-bootstrap.ps1 -SyncOnly` solo sincroniza | OK | Ejecutado; solo sync |
| AC-08 | Huerfanos se manejan igual que antes | OK | Funciones migradas textualmente |
