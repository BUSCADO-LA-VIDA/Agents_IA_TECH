# Plan 033 — Refresh de conocimiento e índices de MCP en la primera ejecución del día

## Contexto

Spec `033-refresh-conocimiento-mcp` definida (12 FR, 7 NFR, 4 US, 12 CA). Los 8 MCP del proyecto (`codebase-memory-mcp`, `graphify`, `context-mode`, `markitdown`, `tokenslayer`, `github`, `playwright`, `context7`) necesitan que sus índices se refresquen en la primera ejecución del día para que los agentes consulten información actualizada.

## Decisiones del plan (se fijan ahora, no en implementación)

### D1 — Dónde vive cada regla de refresh MCP

| Componente | Qué declara | Qué no debe duplicar |
|---|---|---|
| `agent.md` (`.github/` y `.opencode/`) | Dominio de escritura para refresh MCP, prohibiciones (no secretos), enfoque, MCPs, idioma, constraints | No repite lógica del validador ni del pipeline de refresh |
| Skill (SKILL.md) | Procedimiento reutilizable de refresh MCP | No define dominio de agente; solo cómo se ejecuta |
| Validador | Fuente de verdad de conformidad: VAL-01..VAL-09 | No escribe archivos; solo lee y reporta |
| Pipeline de refresh | Secuencia codebase-memory-mcp → graphify → context-mode → tokenslayer | No es un script nuevo; usa comandos existentes de MCPs |

**Por qué no puede esperar a tasks:** si se define durante la implementación, aparecen contradicciones de refrescar secretos o no cubrir todos los MCP de `opencode.json`.

### D2 — Técnica de ejecución

- Ningún agente reescribe archivos completos con `write`. Se usa edición quirúrgica (`edit`) para actualizar `00-indice.md` y bitácoras.
- El pipeline se ejecuta mediante comandos de MCP existentes, no mediante scripts nuevos.
- Resultado: 0 nuevos scripts creados; solo actualización de índices y registros.

### D3 — Disparador del refresh

- El refresh se dispara solo en la primera ejecución del día.
- `pensador` valida que sea la primera ejecución; `plataformador` orquesta con autorización; `analista_tecnico` ejecuta el pipeline.

### D4 — Fail-closed y verificación

- Si cualquier MCP falla durante el refresh, la operación no se da por exitosa.
- Se verifica idempotencia: reejecutar el mismo día no duplica nodos.
- `security-auditor` audita que no haya secretos en los índices.

## Mapeo FR → componente → verificación

| FR | Componente responsable | Verificación |
|---|---|---|
| FR-01 (disparador primera ejecución) | `pensador` valida → `plataformador` orquesta | `00-indice.md` refleja timestamp del último refresh |
| FR-02 (cubre todos los MCP de opencode.json) | `plataformador` verifica cobertura | VAL-07 = 0 |
| FR-03 (sin IA de entrada) | `analista_tecnico` | Sección Enfoque de `analista_tecnico` |
| FR-04 (no secretos en índices MCP) | `security-auditor` audita | Informe de auditoría |
| FR-05 (registro en 00-indice.md) | `plataformador` registra | Inspección de `00-indice.md` |
| FR-06 (paridad de arneses) | `plataformador` verifica | Test de paridad de índices |
| FR-07 (autorización de plataformador) | `pensador` autoriza, `plataformador` ejecuta | `pendientes-implementacion.md` |
| FR-08 (fail-closed) | `analista_tecnico` reporta errores | Registro de errores en bitácora |
| FR-09 (idempotencia) | `analista_tecnico` verifica conteo | Repetir refresh y comparar |
| FR-10 (comunidades graphify) | `analista_tecnico` ejecuta graphify | Query de comunidades |
| FR-11 (context-mode FTS5+BM25) | `analista_tecnico` ejecuta context-mode | Query FTS |
| FR-12 (codebase-memory-mcp nodos) | `analista_tecnico` ejecuta codebase-memory-mcp | Query de nodos |

## Mapeo CA → verificación

| CA | Verificación concreta |
|---|---|
| CA-01 | `00-indice.md` refleja timestamp del último refresh |
| CA-02 | VAL-07 = 0 (todos los MCP de opencode.json citados) |
| CA-03 | `analista_tecnico` ejecuta sin IA de entrada |
| CA-04 | `security-auditor` verifica ausencia de secretos |
| CA-05 | `00-indice.md` tiene timestamp, MCPs, resultado |
| CA-06 | Test de paridad de índices `.github/` ↔ `.opencode/` |
| CA-07 | `pendientes-implementacion.md` refleja autorización |
| CA-08 | Registro de errores en bitácora ante fallo de MCP |
| CA-09 | Repetir refresh; conteo de nodos no duplica |
| CA-10 | Query de comunidades en graphify |
| CA-11 | Query FTS en context-mode |
| CA-12 | Query de nodos en codebase-memory-mcp |

## Criterio de aceptación del plan

Cada FR-01..FR-12 mapeado a componente y verificación; cada CA-01..CA-12 tiene verificación concreta; el pipeline es fail-closed y cubre todos los 8 MCP.
