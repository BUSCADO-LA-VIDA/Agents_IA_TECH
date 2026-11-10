# Tasks — Spec 037: Sincronización de `.gitignore`

## Estado general
- **Última actualización**: 2026-11-05
- **Fase actual**: implement (cerrada), converge documental en curso
- **Total de tasks**: 8
- **Tasks completadas**: 7
- **Tasks pendientes**: 1 (T037-005, opcional y fuera de alcance)

## Tareas

| ID | Espec | Descripción | Tipo | Asignado a | Estado |
|----|-------|-------------|------|------------|--------|
| T037-001 | 037 | Crear `scripts/sync-gitignore.ps1`: catálogo de 6 bloques, detección por cabecera, exclusiones duras, `-Path`/`-Sets`/`-WhatIf`/`-RemoveBlock`/`-PruneRules`. | Script nuevo | `developer` | Cerrado |
| T037-002 | 037 | Crear `tests/sync-gitignore.Tests.ps1`: contrato sin Pester, 14 asserts (existencia, catálogo, preservación, idempotencia, exclusiones, ausencia, reversión, filtro). | Test | `developer` | Cerrado |
| T037-003 | 037 | Ejecutar sobre `$KitPath`, verificar `.gitignore` raíz e idempotencia. | Verificación | `developer` | Cerrado |
| T037-004 | 037 | Ejecutar sobre `<PROJECT_ROOT>`, verificar raíces de proyecto (13 archivos). | Verificación | `developer` | Cerrado |
| T037-005 | 037 | Integrar invocación en fase F4-VERIFY de `scripts/sync-kit.ps1`. | Modificación orquestador | `developer` | Pendiente (opcional, fuera de alcance) |
| T037-006 | 037 | Actualizar `00-indice.md` (sección 037) y `pendientes-implementacion.md`. | Documentación | `pensador` | Cerrado |
| T037-007 | 037 | Revertir overreach: 196 `.gitignore` en rutas de terceros del destino, incluidos restos huérfanos. | Corrección | `developer` | Cerrado |
| T037-008 | 037 | Corregir regresión `*.log`: negar `!.bootstrap-audit.log` y refrescar el bloque en ambos repos. | Corrección | `developer` | Cerrado |

## Dependencias
- T037-001 antes de T037-002, T037-003, T037-004, T037-005.
- T037-006 depende de T037-003 y T037-004.
- T037-007 depende de T037-004 (detecta el overreach).
- T037-008 depende de T037-003 (detecta la regresión con `git ls-files -i`).

## Definition of Done
- `scripts/sync-gitignore.ps1` existe, es idempotente y reversible.
- `tests/sync-gitignore.Tests.ps1` pasa con `PASS=14 FAIL=0`.
- Corridas sobre ambos repos con idempotencia confirmada (segunda corrida = 0 cambios).
- Ningún archivo versionado queda ignorado por las reglas nuevas.
- Overreach revertido y verificado (solo quedan 3 archivos con `graphify-out/` que lo tenían legítimamente).
- Índice, pendientes y bitácora actualizados.

## Frontera de dominio (recordatorio)
- `developer` escribe en `scripts/` y `tests/`.
- `pensador`/`documentador` escriben solo en `Documentacion/`.

## Backlog items
- T037-005: integración en el orquestador `sync-kit.ps1`.
- Revisar si los proyectos con `logs/`, `tmp/` o `temp/` versionados necesitan negaciones específicas.
- Divergencia preexistente de `Agent-SSD` en `tests/agents-parity.ps1` (no relacionada con esta spec): asignar al `plataformador`.
