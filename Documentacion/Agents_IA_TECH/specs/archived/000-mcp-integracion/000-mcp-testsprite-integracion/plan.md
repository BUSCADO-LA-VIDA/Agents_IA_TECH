# Implementation Plan: 000-mcp-testsprite-integracion

**Origen**: `https://github.com/testsprite/testsprite-mcp`

## Overview
Plan de implementación para integrar TestSprite MCP como herramienta externa (proyect_ext) siguiendo el estándar `000-mcp-integracion-estandar.md`. No se desarrolla el MCP; solo se instala, integra, consume y usa.

## Technical Context
- Patrón de tokens `{env:TESTSPRITE_MCP_CMD}` interpolado por OpenCode en runtime.
- Bootstrap `scripts/plataformador-bootstrap.ps1` con `Ensure-OpenCodeMcp` y `Resolve-McpCommand`.
- `.env.mcp` gitignored; plantilla versionada sin rutas absolutas.

## Architecture
Entrada MCP idempotente `testsprite` (type stdio) en `opencode.json`, `.opencode/mcp.json` y `.vscode/mcp.json`, sincronizada por `Sync-TransversalKit`. Activación condicionada a la resolución del binario en runtime.

## Phases
1. **P1 Plantilla** — Añadir entrada `testsprite` a la plantilla `opencode.json` [RF-01]
2. **P2 Bootstrap** — Extender `Resolve-McpCommand` para `TESTSPRITE_MCP_CMD` y `.env.mcp` [RF-02]
3. **P3 Fallback** — WARN accionable si la verificación falla; no registrar entrada rota [RF-03, EC-01..EC-04]
4. **P4 Sync** — Paridad `.opencode/mcp.json` y `.vscode/mcp.json` [RF-04]
5. **P5 Docs** — Verificación y ejemplo en `quickstart.md` [RF-05]
6. **P6 Validación** — Idempotencia con doble corrida del bootstrap [SC-005]

## Dependencies
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md` — patrón de tokens.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-integracion/000-mcp-integracion-estandar.md` — estándar de flujo.
- `AGENTS.md` y `.specify/memory/constitution.md` — gobernanza transversal.
- `scripts/plataformador-bootstrap.ps1`.

## Risks
- Herramienta no instalada → WARN requerido, fail-open, bootstrap continúa.
- Credenciales de TestSprite ausentes → WARN de autenticación (EC-04).
- Entrada manual pre-existente → bootstrap no debe duplicarla (EC-03).
