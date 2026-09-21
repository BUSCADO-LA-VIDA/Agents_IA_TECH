# Research: post-platforming-speckit

**Fecha**: 2026-09-20
**Autor**: pensador (Phase 0)

## Decisiones de investigación

### D-1: ¿1 grafo por Workspace o 1 por APP?

- **Decision**: 1 grafo por app (`src/<App>/graphify-out/graph.json`) como primario, con vista workspace unificada on-demand vía `graphify merge-graphs`.
- **Rationale**: Los 10 tools del MCP graphify aceptan `project_path` (soporte nativo multi-grafo). `merge-graphs` construye la vista unificada solo cuando se necesita. Update incremental solo re-extrae la app cambiada. Communities por-app son significativas. Evita ruido del kit (`.github/`, `.opencode/` no son código de app). Alinea con el flujo speckit per-app.
- **Alternatives considered**: 1 grafo workspace (rechazado: lento, communities mezcladas, ruido del kit, update re-extrae todo).

### D-2: ¿Cómo se actualiza la memoria (índices + grafo)?

- **Decision**: Automática diaria + manual con trigger "actualizar memoria".
  - **Automática**: al recibir una petición, verificar fecha de última actualización de índices/grafo; si es del día anterior o más vieja → actualizar automáticamente antes de responder.
  - **Manual**: frase "actualizar memoria" (o similar) → actualiza context-mode + codebase-memory + graphify on-demand.
- **Rationale**: Evita índices stale (el problema detectado en modo real: los MCPs quedaron con índices de ayer tras actualizar docs). La frecuencia diaria es un balance razonable entre frescura y costo.
- **Alternatives considered**: Actualizar en cada cambio (rechazado: costo alto, innecesario); solo manual (rechazado: riesgo de índices stale).

### D-3: ¿Cómo se construye el grafo Graphify?

- **Decision**: Flujo estructura-first con detección de estado:
  1. Sin grafo → `graphify extract <scope> --code-only` (estructura, sin IA)
  2. Grafo existe → `graphify update <scope>` (incremental, sin LLM)
  3. Flag `-GraphifyDeep` → `graphify extract --mode deep` (semántica con LLM, solo si hay backend configurado; si no, WARN y sigue)
- **Rationale**: Coincide con la filosofía del `analista_tecnico` (ADR-0001: sin IA de entrada, IA bajo demanda). `--code-only` evita indexar secrets. `update` es incremental sin LLM.
- **Alternatives considered**: `extract --mode deep` siempre (rechazado: requiere LLM, más lento, indexa más); solo `--code-only` (rechazado: pierde semántica cuando hay backend).

### D-4: ¿Cómo se detecta el escenario post-bootstrap?

- **Decision**: El `pensador` al iniciar el flujo post-plataformado verifica:
  - ¿Existe `.specify/memory/constitution.md` específico? (si es la plantilla del kit → Escenario requiere Constitution Wizard)
  - ¿Existe documentación previa en `Documentacion/` o en el proyecto? (sí → Escenario B; no → Escenario C)
  - ¿Es un proyecto nuevo sin código? (sí → Escenario A)
- **Rationale**: La detección se basa en el estado real del proyecto (docs existentes, constitution, código).
- **Alternatives considered**: Preguntar siempre al usuario (rechazado: la IA debe ser dinámica y detectar automáticamente).

### D-5: ¿Cómo se preservan los originales en la migración (Escenario B)?

- **Decision**: Los documentos previos en formatos no-MD (PDF, DOCX, etc.) se preservan como fuente de verdad. `markitdown` genera una vista Markdown indexada (para context-mode) sin reemplazar el original.
- **Rationale**: El usuario pidió explícitamente "mantener en su formato original como fuente de la verdad". markitdown indexa para que la IA pueda leer, pero el original queda intacto.
- **Alternatives considered**: Convertir todo a MD (rechazado: pierde el original como fuente de verdad).

## Dependencias y mejores prácticas

- **graphify CLI**: `extract <path> --code-only`, `extract <path> --mode deep`, `update <path>`, `merge-graphs <g1> <g2> --out`, `label <path>`, `cluster-only --no-label`.
- **context-mode**: `ctx_index`, `ctx_search`, `ctx_fetch_and_index` (indexación FTS5+BM25).
- **codebase-memory**: `index_repository`, `search_graph`, `query`.
- **markitdown**: `convert_to_markdown` (PDF/DOCX/PPTX/XLSX/HTML → MD).
- **speckit**: `specify → plan → tasks → analyze → converge → implement` (pipeline ordenado).
