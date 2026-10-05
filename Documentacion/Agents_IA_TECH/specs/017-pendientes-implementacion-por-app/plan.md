# Plan 017 — Pendientes de implementación por proyecto

**Objetivo**: Implementar un archivo `pendientes-implementacion.md` por proyecto en `Documentacion/<AppName>/` que funcione como recordatorio vivo del plan completo, estado de ejecución y responsables de cada tarea. Este documento debe ser mantenido automáticamente por el pipeline Speckit.

**Alcance**: Aplicable a todos los proyectos que usen el flujo SSD + Speckit. El archivo estará en `Documentacion/<AppName>/pendientes-implementacion.md`.

**Fases del pipeline y entregables**:

### Fase 1: Specify — `speckit-specify`
- **Comando**: `speckit-specify`
- **Artefacto**: `spec.md` en `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/spec.md`
- **Validación**: El usuario aprueba la spec que describe el feature y sus success criteria.
- **Contexto previo**: codebase-memory (arquitectura del proyecto), graphify (god nodes, communities), context-mode (ADRs previos), markitdown (convertir docs no-MD si es necesario).

### Fase 2: Plan — `speckit-plan`
- **Comando**: `speckit-plan`
- **Artefacto**: `plan.md` en `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/plan.md`
- **Validación**: El usuario aprueba el plan que detalla las fases y entregables.
- **Contexto previo**: Mismo que Fase 1.

### Fase 3: Tasks — `speckit-tasks`
- **Comando**: `speckit-tasks`
- **Artefacto**: `tasks.md` en `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/tasks.md`
- **Validación**: El usuario aprueba las tasks accionables.
- **Contexto previo**: Mismo que Fase 1.

### Fase 4: Analyze — `speckit-analyze`
- **Agentes delegados**: `arquitecto` + `security-auditor`
- **Artefactos**: `analyze.md` + ADRs + threat model
- **Validación**: El usuario aprueba el análisis.
- **Contexto previo**: codebase-memory (callers/callees, impacto), graphify (god nodes).

### Fase 5: Converge — `speckit-converge`
- **Agente delegado**: `documentador`
- **Artefactos**: `converge.md` + docs consolidadas
- **Validación**: El usuario aprueba la convergencia.
- **Contexto previo**: Mismo que Fase 4.

### Fase 6: Implement — `speckit-implement`
- **Agentes delegados**: `api-developer`, `frontend-developer`, `devops`, `qa-senior`
- **Artefacto**: `Documentacion/<AppName>/pendientes-implementacion.md` actualizado automáticamente
- **Validación**: El usuario confirma la implementación. El archivo se actualiza con el estado final.
- **Contexto previo**: codebase-memory (callers/callees), graphify (impacto de tareas).

**Contexto previo obligatorio antes de cada fase**:
- `codebase-memory-mcp` -> `get_architecture`, `search_graph`, `trace_path`
- `graphify` -> `extract` (si grafo desactualizado), `query` (god nodes, communities)
- `context-mode` -> `ctx_search` (documentación indexada), `ctx_fetch_and_index` (docs externas)
- `markitdown` -> `convert_to_markdown` (formatos no-MD a Markdown)

**Validación del usuario**: Se pide confirmación SOLO en puntos de decisión reales:
- Cambio de fase con impacto
- Decisiones de arquitectura
- Necesidad de permisos de escritura

No se pregunta en pasos mecanicos (verificar artefactos, leer contexto, ejecutar análisis, confirmar estado) — esos se ejecutan directamente.

**Actualización de `pendientes-implementacion.md`**: Al finalizar cada fase, el pipeline actualiza el archivo en `Documentacion/<AppName>/pendientes-implementacion.md` con el estado actual. El archivo refleja:
- Qué tareas están pending, in-progress o done
- Quién es el responsable de cada tarea
- La fase actual del proyecto

**Restricciones (Constitution VII)**:
- El `pensador` y agentes documentales solo pueden escribir en `Documentacion/<AppName>/`
- No pueden tocar `Documentacion/<OtraApp>/`
- En proyecto kit (sin `src/`), el `pensador` puede ejecutar Speckit porque los artefactos van a `Documentacion/<AppName>/specs/`

**Resultados esperados**:
- `Documentacion/<AppName>/pendientes-implementacion.md` — archivo vivo por proyecto
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/spec.md` — especificación
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/plan.md` — plan
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/tasks.md` — tasks
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/analyze.md` — análisis
- `Documentacion/<AppName>/specs/017-pendientes-implementacion-por-app/converge.md` — convergencia