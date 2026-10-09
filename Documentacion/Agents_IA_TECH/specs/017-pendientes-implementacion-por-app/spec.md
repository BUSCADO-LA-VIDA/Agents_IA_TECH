# Spec 017 — Pendientes de implementación por proyecto

**Feature**: Cada proyecto en `Documentacion/<AppName>/` debe tener su propio archivo `pendientes-implementacion.md` que funcione como recordatorio vivo del plan completo, estado de ejecución y responsables.

**Problem**: Cuando migramos a Specs (spec.md, plan.md, tasks.md), perdimos la funcionalidad de tener un documento por proyecto que muestre qué hay que hacer, qué se está haciendo y qué se terminó, junto con quién debe hacerlo. Esto dificulta el seguimiento y la asignación de responsabilidades según las capacidades y permisos de cada agente.

**Solution**: Implementar un archivo `pendientes-implementacion.md` por proyecto en `Documentacion/<AppName>/pendientes-implementacion.md`, mantenido automáticamente por el pipeline Speckit. Este documento debe ser "vivo" y reflejar el estado actual de todas las tareas del proyecto.

**Scope**: Aplicable a todos los proyectos que usen el flujo SSD + Speckit. El archivo estará en `Documentacion/<AppName>/pendientes-implementacion.md`.

**Success Criteria**:
1. Cada proyecto tiene `Documentacion/<AppName>/pendientes-implementacion.md` con contenido completo (no esqueleto, no placeholders)
2. El archivo contiene secciones: `Qué hacer`, `En progreso`, `Terminado`, `Responsables`
3. Cada tarea tiene: ID calificado (`<spec-id>-T<nnn>`), descripci�n, estado (`pending|in-progress|done`), responsable asignado
4. El pipeline Speckit actualiza autom�ticamente este archivo en cada fase (specify  plan  tasks  analyze  converge )
5. El archivo respeta la whitelist de paths del tier documental (solo escribe en `Documentacion/<AppName>/`)
6. No hay placeholders: `TBD`, `TODO`, `pendiente`, `por definir`, `N/A`, `completar aqu�`, `XXX`, `...` est�n prohibidos
7. Las tablas tienen filas reales y las listas tienen items concretos
8. **El archivo es un agregado del PROYECTO**: consolida las tareas de TODAS las `specs/*/tasks.md`, no de una sola spec
9. **IDs calificados**: `<spec-id>-T<nnn>` (ej. `019-T001`) para evitar colisiones entre specs (bug detectado: dos `T001`, dos `T008`, dos `T010` sin prefijo)
10. **Sin auto-referencia**: el feature que implementa el mecanismo (017) NO inyecta sus tareas de infraestructura en el archivo del proyecto destino
11. **Estado derivado**: el estado de cada tarea se deriva del `tasks.md` de su spec (`[ ]` = pending, `[x]` = done), no se inventa
12. **Estados de la especificación**:
    - **ACTIVO**: Spec en trabajo activo. Todas sus tareas críticas tienen check `[x]`. Es la base del pipeline actual.
    - **EN PROCESO**: Spec siendo trabajada actualmente. Tiene tasks `[ ]` (pending) o `[x]` parciales.
    - **ARCHIVADO**: Spec retirada del flujo activo. Se mueve a `specs/archived/` y ya no es la base de trabajo.
    - **Transiciones permitidas**:
      - ACTIVO → EN PROCESO: Cuando surge nuevo requerimiento o bug.
      - EN PROCESO → ACTIVO: Cuando se completan las tasks pendientes.
      - ACTIVO → ARCHIVADO: Cuando el spec ha cumplido su ciclo y se decide retirarlo.
      - ARCHIVADO → ACTIVO: Cuando se detecta nuevo requerimiento sobre la funcionalidad histórica (preferible crear nueva spec).
    - **Regla de oro**: Para nueva funcionalidad evolutiva, **SIEMPRE crear spec nueva** (018, 019...), no reactivar la anterior. Esto asegura historial claro de cambios.
13. **Historial de evolución**:
    - El archivo `00-indice.md` y `pendientes-implementacion.md` deben registrar cambios significativos entre versiones de specs relacionadas.
    - Registrar cuándo y por qué se creó cada spec, qué funcionalidad añadió, y por qué se archivó la anterior.
    - Formato: Tabla resumida al final del `00-indice.md` o en sección específica de historial.

**Artefactos generados**:
- `Documentacion/<AppName>/pendientes-implementacion.md` — por proyecto
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/` — specs, plan, tasks, analyze, converge

**Artefactos generados**:
- `Documentacion/<AppName>/pendientes-implementacion.md` — por proyecto
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/` — specs, plan, tasks, analyze, converge

**Limitaciones (Constitution VII — Restricción de Paths por Tier)**:
- El `pensador` y agentes documentales solo pueden escribir en `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`
- No pueden tocar `Documentacion/<OtraApp>/` — cada app está aislada
- En proyecto kit (sin `src/`), el `pensador` puede ejecutar Speckit porque los artefactos van a `Documentacion/<AppName>/specs/`

**Relación con otros specs**:
- RF-006 (Constitution por proyecto — RF-06): Este spec se genera/actualiza usando el Constitution Wizard si es necesario
- RF-009 (Constitution Wizard — RF-14): Si el proyecto no tiene constitution.md válida, se lanza el wizard antes del pipeline
- RF-010 (Re-indexación y memoria): Al aprobar spec/plan/tasks y tras implement, se re-indexa context-mode + codebase-memory + graphify con aviso visible
- RF-008 (Actualización automática de memoria): Al recibir una petición, verificar fecha de última actualización de índices/grafo; si es del día anterior o más vieja → actualizar automáticamente antes de responder

**Ejemplo de contenido esperado en `Documentacion/<AppName>/pendientes-implementacion.md`**:

```
# Pendientes de implementación — <AppName>

> Documento vivo generado por el pipeline Speckit. Rastreo de qué hay que hacer, qué se está haciendo y qué se terminó, con responsables asignados.

## Estado general del proyecto
- Última actualización: YYYY-MM-DD
- Fase actual: <spec|plan|tasks|analyze|converge|implement>
- Total de tareas: N
- Tareas completadas: M (P%)
- Próxima tarea: <ID> — <descripción>

## Qué hacer (pending)
| ID | Tarea | Descripción | Responsable |
|----|-------|-------------|-------------|
| T001 | ... | ... | ... |

## En progreso (in-progress)
| ID | Tarea | Descripción | Responsable |
|----|-------|-------------|-------------|
| T005 | ... | ... | ... |

## Terminado (done)
| ID | Tarea | Descripción | Responsable |
|----|-------|-------------|-------------|
| T010 | ... | ... | ... |

## Responsables por dominio
- **api-developer**: Tareas de backend, APIs, modelos, DB
- **frontend-developer**: Tareas de UI, componentes, estado, accesibilidad
- **devops**: Tareas de CI/CD, infra, containers, observabilidad
- **qa-senior**: Tareas de tests, quality gates, contract testing

## Notas
- Este documento se actualiza automáticamente en cada fase del pipeline Speckit
- Para cambios manuales, usar el Constitution Wizard o editar directamente (respeto whitelist de paths)
- Ver también: `specs/017-pendientes-implementacion-por-app/spec.md`, `specs/017-pendientes-implementacion-por-app/plan.md`, `specs/017-pendientes-implementacion-por-app/tasks.md`