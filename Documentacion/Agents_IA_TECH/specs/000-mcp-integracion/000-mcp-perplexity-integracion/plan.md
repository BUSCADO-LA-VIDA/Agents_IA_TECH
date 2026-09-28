# Implementation Plan: 000-mcp-perplexity-integracion

**Origen**: `https://github.com/perplexity-ai/mcp-server-perplexity` (URL a verificar contra docs oficiales antes de implementar)

## Overview
Plan de implementación para integrar Perplexity MCP como herramienta externa (proyect_ext) siguiendo el estándar `000-mcp-integracion-estandar.md`. No se desarrolla el MCP; solo se instala, integra, consume y usa.

## Technical Context
- Patrón de tokens `{env:PERPLEXITY_MCP_CMD}` interpolado por OpenCode en runtime.
- Bootstrap `scripts/plataformador-bootstrap.ps1` con `Ensure-OpenCodeMcp` y `Resolve-McpCommand`.
- `.env.mcp` gitignored; plantilla versionada sin rutas absolutas ni API keys.

## Architecture
Entrada MCP idempotente `perplexity` (type stdio) en `opencode.json`, `.opencode/mcp.json` y `.vscode/mcp.json`, sincronizada por `Sync-TransversalKit`. Activación condicionada a la resolución del binario en runtime.

## Phases
1. **P1 Plantilla** — Añadir entrada `perplexity` a la plantilla `opencode.json` [RF-01]
2. **P2 Bootstrap** — Extender `Resolve-McpCommand` para `PERPLEXITY_MCP_CMD` y `.env.mcp` [RF-02]
3. **P3 Fallback** — WARN accionable si la verificación falla; no registrar entrada rota [RF-03, EC-01..EC-04]
4. **P4 Sync** — Paridad `.opencode/mcp.json` y `.vscode/mcp.json` [RF-04]
5. **P5 Docs** — Verificación y ejemplo de consulta en `quickstart.md` [RF-05]
6. **P6 Validación** — Idempotencia con doble corrida del bootstrap [SC-005]

## Dependencies
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md`.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-integracion/000-mcp-integracion-estandar.md`.
- `AGENTS.md` y `.specify/memory/constitution.md`.
- `scripts/plataformador-bootstrap.ps1`.
- Herramienta externa Perplexity MCP (requiere `PERPLEXITY_API_KEY`).

## Risks
- Herramienta no instalada → WARN requerido, fail-open.
- API key ausente → WARN de configuración; entrada permanece si el binario existe (EC-04).
- URL de repo/paquete no verificada → confirmar contra docs oficiales de Perplexity (P1).
- Entrada manual pre-existente → no duplicar (EC-03).
