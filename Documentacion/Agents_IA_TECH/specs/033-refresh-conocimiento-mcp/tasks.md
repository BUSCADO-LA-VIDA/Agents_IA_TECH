# Tasks 033 — Refresh de conocimiento e índices de MCP en la primera ejecución del día

## Estado general

Spec 033 definida y plan aprobado. Quedan por ejecutar: nivelación de agentes para el pipeline de refresh, creación del pipeline de refresh, test de paridad, ejecución real en primera ejecución del día, verificación de idempotencia, auditoría de seguridad, analyze, threat model y converge.

## Tareas

### T01 — Nivelar `analista_tecnico` para pipeline de refresh MCP
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** ninguna
- **Contenido:** Añadir a la sección Enfoque el paso del pipeline de refresh MCP (`codebase-memory-mcp` → `graphify` → `context-mode` → `tokenslayer`); añadir sección MCPs con los 8 MCP de `opencode.json`; verificar que tenga Idioma y Constraints.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección Enfoque incluye el pipeline de refresh MCP; sección MCPs declara los 8 MCP.
- **Estado:** Pendiente.

### T02 — Nivelar `plataformador` para orquestación de refresh MCP
- **Agente asignado:** `plataformador`
- **Dependencias:** ninguna
- **Contenido:** Añadir a la sección Enfoque el paso de orquestar el refresh MCP en la primera ejecución del día; añadir a Output el registro en `00-indice.md` y bitácora de fecha.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección Enfoque incluye orquestación de refresh MCP; Output incluye `00-indice.md`.
- **Estado:** Pendiente.

### T03 — Nivelar `pensador` para validador de primera ejecución del día
- **Agente asignado:** `pensador`
- **Dependencias:** ninguna
- **Contenido:** Añadir sección de validador: al iniciar la primera sesión del día, `pensador` valida que es la primera ejecución y autoriza a `plataformador` para iniciar el refresh MCP.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; sección de validador presente en ambos arneses.
- **Estado:** Pendiente.

### T04 — Nivelar `documentador` para registro de refresh
- **Agente asignado:** `documentador`
- **Dependencias:** ninguna
- **Contenido:** Añadir a Output el registro del último refresh en `00-indice.md` con timestamp, hora, MCPs actualizados y resultado.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; Output incluye `00-indice.md`.
- **Estado:** Pendiente.

### T05 — Nivelar `security-auditor` para auditoría de refresh MCP
- **Agente asignado:** `security-auditor`
- **Dependencias:** ninguna
- **Contenido:** Añadir a Responsabilidades la auditoría de ausencia de secretos en índices de MCP tras cada refresh; añadir a Output el informe de auditoría en `Documentacion/<App>/seguridad/`.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; Responsabilidades incluye auditoría de refresh MCP; Output incluye informe de seguridad.
- **Estado:** Pendiente.

### T06 — Documentar pipeline de refresh MCP
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** T01 cerrada
- **Contenido:** Crear `Documentacion/Agents_IA_TECH/specs/033-refresh-conocimiento-mcp/pipeline-refresh-mcp.md` documentando el pipeline `codebase-memory-mcp` → `graphify` → `context-mode` → `tokenslayer` con comandos exactos de cada MCP.
- **Criterio de aceptación:** Archivo `pipeline-refresh-mcp.md` creado con comandos exactos; sin placeholders; orden del pipeline correcto.
- **Estado:** Pendiente.

### T07 — Test de paridad de índices MCP
- **Agente asignado:** `developer`
- **Dependencias:** T01..T05 cerradas
- **Contenido:** Crear `tests/mcp-refresh-parity.ps1` que verifique que los índices de MCP tienen el mismo contenido en `.github/` y `.opencode/`.
- **Criterio de aceptación:** Test pasa en verde; fixture negativo detecta divergencia en un arnés.
- **Estado:** Pendiente.

### T08 — Ejecutar refresh MCP en primera ejecución del día
- **Agente asignado:** `plataformador` (orquesta), `analista_tecnico` (ejecuta)
- **Dependencias:** T01..T06 cerradas; primera ejecución del día validada por `pensador`
- **Contenido:** Ejecutar el pipeline `codebase-memory-mcp` → `graphify` → `context-mode` → `tokenslayer`; registrar en `00-indice.md` y bitácora de fecha.
- **Criterio de aceptación:** `00-indice.md` tiene entrada de refresh MCP con timestamp; bitácora de fecha creada con comandos y resultado; `git status` limpio de escrituras no deseadas.
- **Estado:** Pendiente.

### T09 — Verificar idempotencia de refresh MCP
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** T08 cerrada
- **Contenido:** Reejecutar el refresh el mismo día y verificar que el conteo de nodos no duplica.
- **Criterio de aceptación:** Segunda ejecución no duplica nodos; `00-indice.md` no se duplica.
- **Estado:** Pendiente.

### T10 — Auditoría de seguridad de refresh MCP
- **Agente asignado:** `security-auditor`
- **Dependencias:** T08 cerrada
- **Contenido:** Auditar que los índices de MCP no contienen credenciales, tokens ni secretos; crear informe en `Documentacion/Agents_IA_TECH/seguridad/`.
- **Criterio de aceptación:** Informe de auditoría creado; ausencia de secretos verificada.
- **Estado:** Pendiente.

### T11 — Analyze cross-artifact (arquitecto)
- **Agente asignado:** `arquitecto`
- **Dependencias:** T01..T10 cerradas
- **Contenido:** `specs/033-refresh-conocimiento-mcp/analyze.md` — análisis de consistencia spec.md ↔ plan.md ↔ tasks.md + Constitución.
- **Criterio de aceptación:** `analyze.md` generado con contenido real; 12/12 FR mapeados; 12/12 CA verificados; Constitución PASS.
- **Estado:** Pendiente.

### T12 — Threat model (security-auditor)
- **Agente asignado:** `security-auditor`
- **Dependencias:** T01..T10 cerradas
- **Contenido:** `specs/033-refresh-conocimiento-mcp/threat-model.md` — DFD, matriz STRIDE, registro de riesgos para refresh MCP.
- **Criterio de aceptación:** `threat-model.md` generado con contenido real; matriz STRIDE completa; registro de riesgos con mitigaciones.
- **Estado:** Pendiente.

### T13 — Converge y cierre de 033
- **Agente asignado:** `documentador` (orquesta), `pensador` (valida)
- **Dependencias:** T11, T12 cerradas
- **Contenido:** Actualizar `00-indice.md` con estado de cierre de 033; confirmar que la spec queda ACTIVA en `specs/`; verificar que no hay placeholders ni secciones vacías.
- **Criterio de aceptación:** Validador en verde; `git status` limpio; `00-indice.md` refleja cierre de 033; spec 033 activa y completa.
- **Estado:** Pendiente.

## Orden de ejecución

T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11 → T12 → T13.

## Gate de cierre

- `scripts/validate-agents-skills.ps1`: `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0.
- `tests/mcp-refresh-parity.ps1`: pasa en verde; fixture negativo detecta divergencia.
- `analyze.md` y `threat-model.md`: verificados, sin placeholders ni secciones vacías.
- `git status`: limpio después de ejecutar validador y test.
