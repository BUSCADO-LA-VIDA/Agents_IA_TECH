# Plan — Spec 037: Sincronización de `.gitignore`

## Objetivo
Implementar `scripts/sync-gitignore.ps1` con catálogo de bloques, exclusiones duras y reversión exacta; verificarlo con un test de contrato ejecutable sin Pester; aplicarlo al repo maestro y a `Generator_IA_Projects`; y corregir el overreach detectado durante la propia implementación.

## Contexto de ejecución (dominio de agentes)
- **Documental** (`pensador`/`documentador`): escribe `Documentacion/Agents_IA_TECH/specs/037-mcp-gitignore-fix/`.
- **Implementador** (`developer`): escribe `scripts/` y `tests/`.
- El agente activo puede escribir en ambos dominios (`opencode.json` → `permission.edit: allow`); la separación se respeta igual porque es la política del kit.

## Fase 1: Specify — Completada
`spec.md` con FR-037-01..09 y SC-037-01..08, incluyendo la ampliación del catálogo y las lecciones del overreach.

## Fase 2: Plan — Completada
| ID | Tarea | Responsable | Depende de | Estado |
|----|-------|-------------|-----------|--------|
| T037-001 | Crear `scripts/sync-gitignore.ps1` con catálogo, exclusiones y modo reversión | `developer` | — | Completada |
| T037-002 | Crear `tests/sync-gitignore.Tests.ps1` (contrato sin Pester) | `developer` | T037-001 | Completada |
| T037-003 | Ejecutar sobre `Agents_IA_TECH` y verificar | `developer` | T037-002 | Completada |
| T037-004 | Ejecutar sobre `Generator_IA_Projects` y verificar | `developer` | T037-002 | Completada |
| T037-005 | Integrar invocación en fase F4-VERIFY de `sync-kit.ps1` | `developer` | T037-001 | Pendiente (opcional, fuera de alcance) |
| T037-006 | Actualizar `00-indice.md` y `pendientes-implementacion.md` | `pensador` | T037-003, T037-004 | Completada |
| T037-007 | Revertir el overreach en rutas de terceros (196 archivos) | `developer` | T037-004 | Completada |
| T037-008 | Corregir regresión `*.log` vs `.bootstrap-audit.log` | `developer` | T037-003 | Completada |

## Fase 3: Tasks — Checklist de verificación
- [x] `scripts/sync-gitignore.ps1` con los 6 bloques y detección por cabecera.
- [x] `tests/sync-gitignore.Tests.ps1` con 14 asserts, `PASS=14 FAIL=0`.
- [x] Selección por raíces de proyecto (13 en el destino, 1 en el maestro).
- [x] Exclusiones duras aplicadas (0 archivos de terceros tocados en la corrida final).
- [x] Idempotencia verificada: segunda corrida = 0 archivos actualizados en ambos repos.
- [x] Reversión verificada en formato nuevo y en formato legacy.
- [x] Sin archivos versionados que queden ignorados por las reglas nuevas.
- [x] Documentación actualizada (spec, plan, tasks, índice, pendientes, bitácora).

## Fase 4: Analyze — Riesgos y mitigación
| Riesgo | Impacto | Mitigación aplicada |
|--------|---------|---------------------|
| Escribir dentro de dependencias o entornos virtuales | Alto (materializado una vez) | Lista de exclusión por segmento + selección por raíz de proyecto; overreach revertido y verificado |
| Reglas genéricas que oculten archivos versionados | Alto | `git ls-files -i -c --exclude-standard` tras aplicar; negación `!.bootstrap-audit.log` |
| Reversión incompleta (formatos distintos) | Medio | `Remove-KitBlock` soporta formato con y sin separador de cierre; `-PruneRules` para huérfanas |
| Duplicación de bloques | Medio | Detección por cabecera (`Detect`) antes de escribir |
| Integración prematura en `sync-kit.ps1` | Alto | T037-005 queda fuera de alcance, aislada y documentada |

## Fase 5: Converge — Criterios de cierre
- Artefactos: `spec.md`, `plan.md`, `tasks.md` en `Documentacion/Agents_IA_TECH/specs/037-mcp-gitignore-fix/`.
- Implementación: `scripts/sync-gitignore.ps1` + `tests/sync-gitignore.Tests.ps1`.
- Verificación: SC-037-01..08 cumplidos con evidencia registrada.
- Deuda declarada: T037-005 (integración en el orquestador) queda como backlog explícito.

## Evidencia de ejecución (2026-11-05)
| Corrida | Repo | Archivos actualizados | Bloques | Notas |
|---------|------|----------------------|---------|-------|
| 1 (versión inicial) | `Agents_IA_TECH` | 8 | 8 | Overreach: tocó `.opencode/.gitignore`, `.specify/.gitignore` y clones |
| 2 (versión inicial) | `Generator_IA_Projects` | 270 | 270 | Overreach grave: 196 archivos de terceros |
| 3 (rollback) | `Generator_IA_Projects` | 196 revertidos | 196 | Incluye `-PruneRules` para huérfanas |
| 4 (versión final) | `Agents_IA_TECH` | 1 | 5 | Solo `.gitignore` raíz (graphify ya presente) |
| 5 (versión final) | `Generator_IA_Projects` | 13 | 64 | Raíz + `Documentacion/` + 11 apps |
| 6 (idempotencia) | ambos | 0 | 0 | Sin cambios: idempotencia confirmada |

## Deuda y backlog
- T037-005: invocar `sync-gitignore.ps1` desde `sync-kit.ps1` (F4-VERIFY) cuando se decida el punto exacto del pipeline.
- Evaluar excluir además `tmp/`, `temp/`, `logs/` del versionado en proyectos que ya los tengan versionados (requiere revisión caso a caso).
- `tests/agents-parity.ps1` reporta divergencia preexistente en `Agent-SSD` entre arneses; no fue introducida por esta spec (los archivos no tienen cambios locales).
