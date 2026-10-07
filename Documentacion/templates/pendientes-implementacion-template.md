# Pendientes de implementación — <AppName>

> **Documento vivo generado por el pipeline Speckit.** Rastreo de qué hay que hacer, qué se está haciendo y qué se terminó, con responsables asignados automáticamente por expertise.

> Este archivo es un **agregado del PROYECTO**: consolida las tareas de TODAS las `specs/*/tasks.md` de `Documentacion/<AppName>/`, no de una sola spec. Se actualiza automáticamente en cada fase del pipeline Speckit (specify → plan → tasks → analyze → converge → implement).

> **IDs calificados**: cada tarea usa el prefijo de su spec (`<spec-id>-T<nnn>`, ej. `009-T001`) para evitar colisiones entre specs.

> **Whitelist de paths (Constitution Art.VII):** Este archivo solo puede escribirse en `Documentacion/<AppName>/`. Ningún agente documental puede tocar `Documentacion/<OtraApp>/`.

> **Ciclo de vida de specs (vinculante):** `Completar/Cerrar` = terminar el flujo SSD+Speckit sin saltar pasos; la spec queda lista para producción y permanece ACTIVA en `specs/`. El estado `Cerrado` significa flujo completo/operativo, nunca eliminada. `Archivar` (`specs/archived/`) = SOLO cuando el usuario indique explícitamente que algo se retira del flujo/proceso.

## Estado general del proyecto
- **Última actualización:** <FECHA>
- **Fase actual:** specify
- **Specs con tareas:** <N_SPECS>
- **Total de tareas inventariadas:** <TOTAL_TAREAS>
- **Tareas completadas:** <TAREAS_COMPLETADAS>
- **Tareas pendientes:** <TAREAS_PENDIENTES>
- **Próxima tarea:** <PROXIMA_TAREA>
- **Específica del mecanismo:** `specs/017-pendientes-implementacion-por-app/spec.md`

## Sin asignar

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T001 | <SPEC> | Inventario inicial del proyecto | Recorrer TODAS las specs (`specs/*/tasks.md`), consolidar sus tareas con IDs calificados y volcarlas al archivo con el estado actual. | `pensador` | Sin asignar |  |

## Pendiente

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T002 | <SPEC> | Ejemplo tarea pendiente | Descripción de tarea | `devops` | Pendiente | `devops` |

## En progreso

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T003 | <SPEC> | Ejemplo tarea en progreso | Descripción de tarea | `api-developer` | En Progreso | `api-developer` |

## Finalizada

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T004 | <SPEC> | Ejemplo tarea finalizada | Descripción de tarea | `qa-senior` | Finalizada | `qa-senior` |

## Finalizado QA

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T005 | <SPEC> | Ejemplo tarea QA | Descripción de tarea | `qa-senior` | Finalizado QA | `qa-senior` |

## Finalizado Security

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T006 | <SPEC> | Ejemplo tarea Security | Descripción de tarea | `security-auditor` | Finalizado Security | `security-auditor` |

## Cerrado

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| <SPEC>-T007 | <SPEC> | Ejemplo tarea cerrada | Descripción de tarea | `pensador` | Cerrado | `pensador` |

## Responsables por dominio
- **`pensador`**: Orquestador. Valida, delega, asegura contexto previo, valida placeholders, actualiza estado vivo.
- **`Agent-SSD`**: Ejecuta speckit phases, actualiza `pendientes-implementacion.md`.
- **`documentador`**: Crea templates, documenta reglas de aislamiento.
- **`arquitecto`**: ADRs, guardrails, decisiones de arquitectura.
- **`security-auditor`**: Threat model, riesgos de seguridad.
- **`api-developer`**: Tareas de backend, APIs, modelos, DB.
- **`frontend-developer`**: Tareas de UI, componentes, estado, accesibilidad.
- **`devops`**: Tareas de CI/CD, infra, containers, observabilidad.
- **`qa-senior`**: Tareas de tests, quality gates, contract testing.
- **`plataformador`**: Nivelación de proyectos, scripts de bootstrap.
- **`gitflow`**: Branching, commits, PRs.
- **`analista-tecnico`**: Investigación técnica, POCs, evaluación de librerías.

## Notes
- Este documento es un **agregado del proyecto**: consolida TODAS las `specs/*/tasks.md`.
- IDs calificados `<spec-id>-T<nnn>` para evitar colisiones entre specs.
- El feature que implementa el mecanismo (017) NO se auto-referencia: sus tareas de infraestructura no se inyectan como trabajo del proyecto destino.
- Constitution Art.IX (Contenido Completo, Nunca Esqueletos) se aplica estrictamente: ningún placeholder prohibido.
- Constitution Art.VII (Restricción de Paths por Tier) es la frontera: solo `Documentacion/<AppName>/`.

## Próximo paso
Recorrer TODAS las specs (`specs/*/tasks.md`) del proyecto, consolidar sus tareas con IDs calificados `<spec-id>-T<nnn>`, y volcarlas a este archivo con el estado actual. Esta es la primera tarea de inicialización (inventario multi-spec).