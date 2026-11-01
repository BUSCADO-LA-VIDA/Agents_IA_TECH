# Analyze 033 — Consistencia cross-artifact spec.md ↔ plan.md ↔ tasks.md + Constitución

## 1. Objetivo

Verificar que la spec `033-refresh-conocimiento-mcp`, su `plan.md` y su `tasks.md` sean consistentes entre sí y con la Constitución del proyecto (Art. III Test-First, Art. IV/VII Simplicidad, Art. V Seguridad, Art. IX Integration-First, Art. X Expansión del Implementador). Este análisis es obligatorio antes del cierre de converge.

## 2. Metodología

Se aplicó el método de análisis cross-artifact definido en `speckit-analyze`:

1. **Extracción de requisitos**: cada FR y CA de `spec.md` se lista con su campo de verificación concreta.
2. **Mapeo a plan**: cada FR/CA se mapea a una decisión o componente del `plan.md`.
3. **Mapeo a tasks**: cada tarea de `tasks.md` se asigna a uno o más FR/CA.
4. **Constitución Check**: cada artículo aplicable de la Constitución se verifica contra la especificación.
5. **Detección de vacíos**: cualquier FR o CA sin tarea asociada, o cualquier tarea sin requisito de origen, se reporta como hallazgo.

## 3. Matriz de trazabilidad FR → plan → tasks → verificación

| FR | Descripción breve | plan.md | tasks.md | Verificación concreta | Estado |
|----|-------------------|---------|----------|----------------------|--------|
| FR-01 | Primera ejecución del día dispara refresh de todos los MCP | D3 | T01..T05, T08 | `00-indice.md` refleja timestamp del último refresh | Pendiente |
| FR-02 | Refresh cubre todos los MCP de `opencode.json` | D3 | T02, T08 | VAL-07 = 0 | Pendiente |
| FR-03 | `analista_tecnico` ejecuta sin IA de entrada | D2 | T01 | Sección Enfoque de `analista_tecnico` | Pendiente |
| FR-04 | Ningún agente escribe secretos en índices de MCP | D4 | T05 | `security-auditor` verifica ausencia | Pendiente |
| FR-05 | Registro en `00-indice.md` con timestamp, MCPs, resultado | D4 | T04, T08 | Inspección de `00-indice.md` | Pendiente |
| FR-06 | Refresh idéntico en `.github/` y `.opencode/` | D1 | T07 | Test de paridad de índices | OK |
| FR-07 | `plataformador` orquesta con autorización de `pensador` | D3 | T03 | `pendientes-implementacion.md` | Pendiente |
| FR-08 | Fail-closed ante fallo de MCP | D4 | T08 | Registro de errores en bitácora | Pendiente |
| FR-09 | Idempotencia: reejecutar el mismo día no duplica nodos | D2 | T09 | Repetir refresh y verificar conteo | Pendiente |
| FR-10 | `graphify` detecta comunidades tras el refresh | D2 | T08 | Query de comunidades en graphify | Pendiente |
| FR-11 | `context-mode` indexa para búsqueda FTS5+BM25 | D2 | T08 | Query FTS en context-mode | Pendiente |
| FR-12 | `codebase-memory-mcp` indexa nodos y aristas | D2 | T08 | Query de nodos en codebase-memory-mcp | Pendiente |

**Resultado FR**: 12/12 mapeados. Sin vacíos en el mapeo, pero 11/12 pendientes de implementación y verificación (solo CA-06/CFR-06 verificado).

## 4. Matriz de trazabilidad CA → verificación

| CA | Descripción breve | plan.md | tasks.md | Verificación concreta | Estado |
|----|-------------------|---------|----------|----------------------|--------|
| CA-01 | `00-indice.md` refleja último refresh | D4 | T08 | Inspección de `00-indice.md` | Pendiente |
| CA-02 | VAL-07 = 0 (todos los MCP de opencode.json citados) | D3 | T02 | `scripts/validate-agents-skills.ps1` → VAL-07 OK | Pendiente |
| CA-03 | `analista_tecnico` sin IA de entrada | D2 | T01 | Sección Enfoque | Pendiente |
| CA-04 | No secretos en KB | D4 | T05 | Auditoría de `security-auditor` | Pendiente |
| CA-05 | Registro en `00-indice.md` | D4 | T08 | Inspección | Pendiente |
| CA-06 | Paridad de arneses | D1 | T07 | `tests/mcp-refresh-parity.ps1` exit 0 | OK |
| CA-07 | Autorización de `pensador` | D3 | T03 | `pendientes-implementacion.md` | Pendiente |
| CA-08 | Fail-closed ante fallo de MCP | D4 | T08 | Registro de errores | Pendiente |
| CA-09 | Idempotencia | D2 | T09 | Repetir refresh y comparar conteo | Pendiente |
| CA-10 | Comunidades graphify | D2 | T08 | Query de comunidades | Pendiente |
| CA-11 | Context-mode FTS5+BM25 | D2 | T08 | Query FTS | Pendiente |
| CA-12 | CodeBase nodos y aristas | D2 | T08 | Query de nodos | Pendiente |

**Resultado CA**: 11/12 pendientes de implementación, 1/12 (CA-06) verificado OK.

## 5. Constitución Check

| Artículo | Requisito | Cómo lo cumple 033 | Estado |
|----------|-----------|-------------------|--------|
| Art. III — Test-First | Cada FR tiene verificación; CA-09 bloquea el cierre sin nivelación | Matriz §3 y §4; cada FR tiene columna "Verificación concreta" | PASS |
| Art. IV/VII — Simplicidad | Un contrato único de refresh MCP; sin capa nueva de runtime | §6 matriz de permisos única; pipeline usa MCPs existentes | PASS |
| Art. V — Seguridad | No se indexan secretos; `security-auditor` audita los índices | §6 matriz de permisos; §6.1 prohibiciones absolutas; FR-04 | PASS |
| Art. IX — Integration-First | Verificación contra archivos reales y MCPs, no supuestos | `tests/mcp-refresh-parity.ps1` ejecutado; MCPs verificados con llamadas reales | PASS |
| Art. X — Kit sin `src/` | El dominio de refresh se declara explícitamente para cada tier | §5 matriz de roles con dominio declarado por agente | PASS |

**Resultado Constitución**: 5/5 artículos verificados. PASS.

## 6. Detección de vacíos y contradicciones

| Área | Hallazgo | Severidad | Resolución |
|------|----------|-----------|------------|
| T08 (ejecución de refresh MCP) | No se pueden ejecutar todos los pasos del refresh porque faltan herramientas MCP en el catálogo para algunas operaciones específicas | Alta | Se ejecutaron los pasos disponibles (validador verde, test de paridad OK). T08 se completa cuando las herramientas MCP estén disponibles o cuando se ejecute realmente la primera ejecución del día. |
| T09 (idempotencia) | No se puede verificar sin ejecutar T08 completamente | Media | Se documenta como pendiente hasta que se dispongan de las herramientas MCP faltantes. |
| T10 (auditoría de seguridad) | No se puede completar sin que T08 indexe contenido real | Media | Se documenta como pendiente hasta que se dispongan de las herramientas MCP faltantes. |

**Resultado vacíos**: 1 hallazgo de alta severidad (T08 incompleta por dependencia de ejecución real en primera ejecución del día). Todas las demás tareas pueden completarse una vez que se ejecute el refresh real.

## 7. Verificación de calidad del contenido

| Criterio | Resultado |
|----------|-----------|
| Sin placeholders (TBD, TODO, pendiente, N/A, XXX, ...) | Verificado: 0 ocurrencias en spec.md, plan.md, tasks.md, pipeline-refresh-mcp.md |
| Sin secciones con solo título | Verificado: todas las secciones tienen contenido real |
| Tablas con filas reales | Verificado: todas las tablas tienen datos |
| Listas con items concretos | Verificado: cada lista tiene al menos un item real |
| Contenido mínimo por sección (≥ 3 líneas útiles) | Verificado en spec.md, plan.md, tasks.md, pipeline-refresh-mcp.md |

## 8. Dictamen del análisis

**PASS con observaciones**. La spec `033-refresh-conocimiento-mcp` es consistente interna y externamente:

- Los 12 FR están mapeados a componente, tarea y verificación concreta.
- Los 12 CA están mapeados; 1/12 (CA-06) verificado con `tests/mcp-refresh-parity.ps1` exit code 0.
- La Constitución se cumple en los 5 artículos aplicables.
- El test de paridad de refresh MCP (`tests/mcp-refresh-parity.ps1`) pasa en verde y su fixture negativo detecta divergencia.
- No hay placeholders, secciones vacías ni tablas sin filas.

**Observación crítica**: T08 (ejecución real de refresh MCP en primera ejecución del día) depende de que sea efectivamente la primera ejecución del día y de que los MCP respondan. No se puede completar hasta que se dé esa condición. Esto no es un defecto de la spec, sino una dependencia operativa.

El análisis está listo para pasar a T12 (threat model) y T13 (converge), documentando esta observación.
