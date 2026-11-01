# Plan 032 — Actualización de Knowledge Base tras spec validada

## Contexto

Spec `032-actualizacion-knowledge-base` definida (12 FR, 7 NFR, 4 US, 12 CA). La Knowledge Base consiste en CodeBase (`codebase-memory-mcp`), Context (`context-mode`) y Graphify (`graphify`). El cierre de la spec 031 (2026-10-31) demostró que no existe un procedimiento para propagar specs validadas a estos índices. Este plan fija cómo se ejecutará la actualización.

## Decisiones del plan (se fijan ahora, no en implementación)

### D1 — Dónde vive cada regla de actualización de KB

| Componente | Qué declara | Qué no debe duplicar |
|---|---|---|
| `agent.md` (`.github/` y `.opencode/`) | Dominio de escritura para actualización de KB, prohibiciones (no secretos), enfoque, MCPs, idioma, constraints | No repite lógica del validador ni del pipeline de actualización |
| Skill (SKILL.md) | Procedimiento reutilizable de indexación (markitdown, graphify, codebase-memory-mcp, context-mode) | No define dominio de agente; solo cómo se ejecuta |
| Validador | Fuente de verdad de conformidad de los índices de KB | No escribe archivos; solo lee y reporta |
| Pipeline de actualización | Secuencia markitdown → graphify → codebase-memory-mcp → context-mode | No es un script nuevo; usa comandos existentes de MCPs |

**Por qué no puede esperar a tasks:** si se define durante la implementación, aparece la contradicción de indexar secretos o duplicar nodos sin control.

### D2 — Técnica de ejecución

- Ningún agente reescribe archivos completos con `write`. Se usa edición quirúrgica (`edit`) para actualizar `00-indice.md` y bitácoras.
- El pipeline se ejecuta mediante comandos de MCP (`codebase-memory-mcp index_repository`, `graphify extract`, `context-mode ctx_index`, `markitdown convert_to_markdown`), no mediante scripts nuevos.
- Resultado: 0 nuevos scripts creados; solo actualización de índices y registros.

### D3 — Disparador de la actualización

- La actualización se dispara solo cuando una spec pasa a estado `Cerrado` en `00-indice.md`.
- `documentador` confirma el cierre en `00-indice.md`; `plataformador` orquesta con autorización de `pensador`; `analista_tecnico` ejecuta el pipeline.

### D4 — Fail-closed y verificación

- Si cualquier MCP falla durante la actualización, la operación no se da por exitosa.
- Se verifica idempotencia: reindexar una spec ya indexada no duplica nodos.
- `security-auditor` audita que no haya secretos en los índices.

## Mapeo FR → componente → verificación

| FR | Componente responsable | Verificación |
|---|---|---|
| FR-01 (disparador tras cierre) | `documentador` confirma cierre → `plataformador` orquesta | `00-indice.md` refleja actualización |
| FR-02 (orden del pipeline) | `analista_tecnico` ejecuta markitdown → graphify → codebase-memory-mcp → context-mode | Revisión de bitácora |
| FR-03 (sin IA de entrada) | `analista_tecnico` | Sección Enfoque de `analista_tecnico` |
| FR-04 (no secretos en KB) | `security-auditor` audita | Informe de auditoría |
| FR-05 (registro en 00-indice.md) | `plataformador` registra | Inspección de `00-indice.md` |
| FR-06 (paridad de arneses) | `plataformador` verifica | Test de paridad de índices |
| FR-07 (autorización de plataformador) | `pensador` autoriza, `plataformador` ejecuta | `pendientes-implementacion.md` |
| FR-08 (fail-closed) | `analista_tecnico` reporta errores | Registro de errores en bitácora |
| FR-09 (idempotencia) | `analista_tecnico` verifica conteo | Repetir actualización y comparar |
| FR-10 (comunidades graphify) | `analista_tecnico` ejecuta graphify | Query de comunidades |
| FR-11 (context-mode FTS5+BM25) | `analista_tecnico` ejecuta context-mode | Query FTS |
| FR-12 (codebase-memory-mcp nodos) | `analista_tecnico` ejecuta codebase-memory-mcp | Query de nodos |

## Mapeo CA → verificación

| CA | Verificación concreta |
|---|---|
| CA-01 | `00-indice.md` refleja actualización tras cierre de spec |
| CA-02 | Orden del pipeline verificado en bitácora |
| CA-03 | `analista_tecnico` ejecuta sin IA de entrada |
| CA-04 | `security-auditor` verifica ausencia de secretos |
| CA-05 | `00-indice.md` tiene timestamp, spec, MCPs |
| CA-06 | Test de paridad de índices `.github/` ↔ `.opencode/` |
| CA-07 | `pendientes-implementacion.md` refleja autorización |
| CA-08 | Registro de errores en bitácora ante fallo de MCP |
| CA-09 | Repetir actualización; conteo de nodos no duplica |
| CA-10 | Query de comunidades en graphify |
| CA-11 | Query FTS en context-mode |
| CA-12 | Query de nodos en codebase-memory-mcp |

## Criterio de aceptación del plan

Cada FR-01..FR-12 mapeado a componente y verificación; cada CA-01..CA-12 tiene verificación concreta; el pipeline usa orden correcto y es fail-closed.
