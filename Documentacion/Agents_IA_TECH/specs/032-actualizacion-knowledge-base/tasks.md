# Tasks 032 — Actualización de Knowledge Base tras spec validada

## Estado general

Spec 032 definida y plan aprobado. Quedan por ejecutar: nivelación de agentes para el pipeline de KB, creación del pipeline de actualización, test de paridad, ejecución real sobre spec 031, verificación de idempotencia, auditoría de seguridad, analyze, threat model y converge.

## Tareas

### T01 — Nivelar `analista_tecnico` para pipeline de KB
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** ninguna
- **Contenido:** Añadir a la sección Enfoque el paso del pipeline markitdown → graphify → codebase-memory-mcp → context-mode; añadir sección MCPs con `codebase-memory-mcp`, `graphify`, `context-mode`, `markitdown`; verificar que tenga Idioma y Constraints.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección Enfoque incluye el pipeline de KB; sección MCPs declara los 4 MCPs.
- **Estado:** Pendiente.

### T02 — Nivelar `plataformador` para orquestación de KB
- **Agente asignado:** `plataformador`
- **Dependencias:** ninguna
- **Contenido:** Añadir a la sección Enfoque el paso de orquestar la actualización de KB tras cierre de spec; añadir a Output el registro en `00-indice.md` y bitácora de fecha.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección Enfoque incluye orquestación de KB; Output incluye `00-indice.md`.
- **Estado:** Pendiente.

### T03 — Nivelar `pensador` para disparador de KB
- **Agente asignado:** `pensador`
- **Dependencias:** ninguna
- **Contenido:** Añadir sección de disparador: al confirmar cierre de spec en `00-indice.md`, `pensador` autoriza a `plataformador` para iniciar la actualización de KB.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección de disparador presente en ambos arneses.
- **Estado:** Pendiente.

### T04 — Nivelar `documentador` para registro de cierre
- **Agente asignado:** `documentador`
- **Dependencias:** ninguna
- **Contenido:** Añadir a Output el registro de cierre de spec en `00-indice.md` con timestamp, spec afectada y MCPs actualizados.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; Output incluye `00-indice.md`.
- **Estado:** Pendiente.

### T05 — Nivelar `security-auditor` para auditoría de KB
- **Agente asignado:** `security-auditor`
- **Dependencias:** ninguna
- **Contenido:** Añadir a Responsabilidades la auditoría de ausencia de secretos en índices de KB tras cada actualización; añadir a Output el informe de auditoría en `Documentacion/<App>/seguridad/`.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; Responsabilidades incluye auditoría de KB; Output incluye informe de seguridad.
- **Estado:** Pendiente.

### T06 — Documentar pipeline de actualización de KB
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** T01 cerrada
- **Contenido:** Crear `Documentacion/Agents_IA_TECH/specs/032-actualizacion-knowledge-base/pipeline-kb.md` documentando el pipeline markitdown → graphify → codebase-memory-mcp → context-mode con comandos exactos de cada MCP.
- **Criterio de aceptación:** Archivo `pipeline-kb.md` creado con comandos exactos; sin placeholders; orden del pipeline correcto.
- **Estado:** Pendiente.

### T07 — Test de paridad de índices de KB
- **Agente asignado:** `developer`
- **Dependencias:** T01..T05 cerradas
- **Contenido:** Crear `tests/kb-parity.Tests.ps1` que verifique que los índices de KB (codebase-memory-mcp, context-mode, graphify) tienen el mismo contenido en `.github/` y `.opencode/`.
- **Criterio de aceptación:** Test pasa en verde; fixture negativo detecta divergencia en un arnés.
- **Estado:** Pendiente.

### T08 — Ejecutar actualización de KB para spec 031
- **Agente asignado:** `plataformador` (orquesta), `analista_tecnico` (ejecuta)
- **Dependencias:** T01..T06 cerradas; spec 031 cerrada
- **Contenido:** Ejecutar el pipeline markitdown → graphify → codebase-memory-mcp → context-mode sobre `specs/031-permisos-y-dominio-de-agentes/`; registrar en `00-indice.md` y bitácora de fecha.
- **Criterio de aceptación:** `00-indice.md` tiene entrada de actualización de 031; bitácora de fecha creada con comandos y resultado; `git status` limpio de escrituras no deseadas.
- **Estado:** Pendiente.

### T09 — Verificar idempotencia de KB
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** T08 cerrada
- **Contenido:** Reejecutar el pipeline sobre spec 031 y verificar que el conteo de nodos no duplica.
- **Criterio de aceptación:** Segundo ejecución no duplica nodos; `00-indice.md` no se duplica.
- **Estado:** Pendiente.

### T10 — Auditoría de seguridad de KB
- **Agente asignado:** `security-auditor`
- **Dependencias:** T08 cerrada
- **Contenido:** Auditar que los índices de KB no contienen credenciales, tokens ni secretos; crear informe en `Documentacion/Agents_IA_TECH/seguridad/`.
- **Criterio de aceptación:** Informe de auditoría creado; ausencia de secretos verificada.
- **Estado:** Pendiente.

### T11 — Analyze cross-artifact (arquitecto)
- **Agente asignado:** `arquitecto`
- **Dependencias:** T01..T10 cerradas
- **Contenido:** `specs/032-actualizacion-knowledge-base/analyze.md` — análisis de consistencia spec.md ↔ plan.md ↔ tasks.md + Constitución.
- **Criterio de aceptación:** `analyze.md` generado con contenido real; 12/12 FR mapeados; 12/12 CA verificados; Constitución PASS.
- **Estado:** Pendiente.

### T12 — Threat model (security-auditor)
- **Agente asignado:** `security-auditor`
- **Dependencias:** T01..T10 cerradas
- **Contenido:** `specs/032-actualizacion-knowledge-base/threat-model.md` — DFD, matriz STRIDE, registro de riesgos para actualización de KB.
- **Criterio de aceptación:** `threat-model.md` generado con contenido real; matriz STRIDE completa; registro de riesgos con mitigaciones.
- **Estado:** Pendiente.

### T13 — Converge y cierre de 032
- **Agente asignado:** `documentador` (orquesta), `pensador` (valida)
- **Dependencias:** T11, T12 cerradas
- **Contenido:** Actualizar `00-indice.md` con estado de cierre de 032; confirmar que la spec queda ACTIVA en `specs/`; verificar que no hay placeholders ni secciones vacías.
- **Criterio de aceptación:** Validador en verde; `git status` limpio; `00-indice.md` refleja cierre de 032; spec 032 activa y completa.
- **Estado:** Pendiente.

## Orden de ejecución

T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11 → T12 → T13.

## Gate de cierre

- `scripts/validate-agents-skills.ps1`: `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0.
- `tests/kb-parity.Tests.ps1`: pasa en verde; fixture negativo detecta divergencia.
- `analyze.md` y `threat-model.md`: verificados, sin placeholders ni secciones vacías.
- `git status`: limpio después de ejecutar validador y test.
