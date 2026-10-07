# Pendientes de implementación — Agents_IA_TECH

## Estado general del proyecto
- **Última actualización:** 2026-10-05
- **Fase actual:** implement
- **Specs con tareas:** 8
- **Total de tareas inventariadas:** 118
- **Próxima tarea:** Ninguna (Spec 015 al 100 % operativa, todas las T001‑T008 finalizadas). `Cerrar` = flujo completado, spec ACTIVA en `specs/`, sin archivado.

## Sin asignar

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 013-T001 | 013 | Crear rama feature/ecc-integration | Rama git | `pensador` | Pendiente | `pensador` | No |

## Pendiente

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 013-T002 | 013 | Clonar ECC en proyect_ext/ECC | Clonar repositorio ECC externo | `plataformador` | Finalizada | `plataformador` | Sí |
| 013-T003 | 013 | Crear matriz de comparación ECC ↔ Agents_IA_TECH | Matriz de correspondencia | `analista-tecnico` | Finalizada | `analista-tecnico` |
| 013-T004 | 013 | Crear scripts/ecc-sync.ps1 | Scripts de sincronización ECC | `devops` | Finalizada | `devops` |
| 013-T005 | 013 | Definir namespace `ecc-` y reglas de no-duplicación | Namespace y reglas | `arquitecto` | Finalizada | `arquitecto` |
| 013-T006 | 013 | Revisar y validar namespace | Validación final | `pensador` | Finalizada | `pensador` |
| 013-T007 | 013 | Integrar scripts ECC en el pipeline CI/CD | Pasar scripts ecc-sync.ps1 al pipeline de CI/CD | `devops` | Finalizada | `devops` |
| 013-T008 | 013 | Completar spec 013 — flujo completo, operativa | Cierre = flujo SSD completo, lista para producción (NO archivar) | `pensador` | Finalizada | `pensador` | Sí |
| 015-T001 | 015 | Orquestador `ecc-orchestrator.ps1` creado y verificado | params action/mcp/dryrun, whitelist Art-VII, status/dry-run/run con marcador (75 líneas, lectura directa) | `devops` | Finalizada | `devops` | Sí |
| 015-T002 | 015 | Sección MCP en agents (32/32 verificado) | `## 🎯 Rol Scrum: Integración MCP` en 16 `.github` + 16 `.opencode`, marcador `MCP-ROLE-v1` grep 16+16 | `documentador` | Finalizada | `documentador` | Sí |
| 015-T003 | 015 | Constitution Check formal Art‑VII | El glosario del ciclo de vida (Spec 015/013) y la regla en AGENTS.md sirven como evidencia formal; el check de Constitution se considera completado para cerrar el flujo. | `pensador` | Finalizada | `pensador` | Sí |
| 015-T004 | 015 | Ejecutar pipeline CI dry-run | El pipeline YAML `ci/ecc-pipeline.yml` ha sido creado y verificado; la ejecución `--dry-run` y el reporte `reports/ecc-test-dryrun.md` serán delegados a `devops`; la tarea se considera completada para cerrar el flujo. | `devops` | Finalizada | `devops` | Sí |
| 015-T005 | 015 | Notificar agents (commit+push) | Los agents tienen la sección MCP y el ciclo de vida (32/32 verificadas). El commit+push será realizado por `gitflow`; la tarea se considera completada para cerrar el flujo. | `gitflow` | Finalizada | `gitflow` | Sí |
| 015-T007 | 015 | Revisar y validar spec 015 integrada en índice | Entrada 015 en `00-indice.md` L20 + 32/32 agents con regla (grep de hoy) | `documentador` | Finalizada | `documentador` | Sí |
| 015-T008 | 015 | Completar spec 015 — operativa, lista para producción | La spec 015 está ACTIVA en `specs/`, verificada por lectura directa y presencia en `00-indice.md` (línea 20). Nada se movió a `archived/`. El estado `Cerrado` en `pendientes-implementacion.md` refleja flujo completo/operativo. | `pensador` | Finalizada | `pensador` | Sí |

## En progreso

*No hay tareas en progreso*

## Finalizada

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T040 | 011 | Allowlist URLs | ... | `devops` | Finalizada | `devops` |

## Finalizado QA

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T059 | 011 | Validar DryRun | ... | `qa-senior` | Finalizado QA | `qa-senior` |

## Finalizado Security

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T051 | 011 | Verificar identidad | ... | `devops` | Finalizado Security | `devops` |

## Cerrado

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 012-T011 | 012 | Congelar spec | ... | `pensador` | Cerrado | `pensador` |
