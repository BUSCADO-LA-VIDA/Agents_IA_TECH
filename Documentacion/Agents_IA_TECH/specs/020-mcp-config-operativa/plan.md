# Implementation Plan: 020-mcp-config-operativa

**Origen**: congela el estado verificado 2026-10-11 (ver `spec.md`). Plan documental + procedimiento de verificación reutilizable.

## Overview

Esta spec es documental: no instala ni modifica nada. Su plan describe (1) cómo se llegó al estado operativo y (2) el procedimiento de verificación viva por MCP para reusar ante regresiones.

## Procedimiento de verificación viva por MCP

Patrón general (Python + stdio JSON-RPC, con timeout y limpieza de procesos):

1. Lanzar el binario con transporte stdio.
2. Enviar `initialize` (`protocolVersion 2024-11-05`) → esperar `serverInfo`.
3. Enviar `notifications/initialized`.
4. Enviar `tools/list` → contar tools.
5. Matar el proceso y limpiar (`Get-Process node/python | Stop-Process`).

Particularidades por MCP (aprendidas 2026-10-11):

| MCP | Particularidad |
|-----|----------------|
| playwright | Invocar `node cli.js` directo; el shim `.ps1` no canaliza stdio en pruebas manuales |
| semgrep | Requiere flag `-t stdio`; exige CLI `semgrep` en PATH (si no, el lifespan falla); paquete `semgrep-mcp` 0.9.0 deprecado, usar `semgrep mcp` |
| semgrep-mcp (descartado) | Exigió Python 3.12 aislado + pin `mcp==1.9.0`/`pydantic==2.11.7`; todo descartado por deprecación upstream |
| context7 | `resolve-library-id` exige `{libraryName, query}`; `query-docs` exige `libraryId` + `query` específico |
| github | Exige `GITHUB_TOKEN` en el entorno del proceso; sin él, arranca pero las llamadas dan error de auth |
| sentry | Se cuelga en toda invocación + exige auth interactiva → NO registrar habilitado (bloqueado) |
| graphify/tokenslayer | Verificación por respuesta de tools en sesión (graph_stats, get_stats), no por handshake manual |

## Verificación de índices

- codebase-memory: `index_status({project: "C-Proyectos-Agents_IA_TECH"})` → `status: ready`.
- graphify: `graph_stats({project_path})` → nodos/aristas/comunidades + `EXTRACTED: 100%`.
- context-mode: `ctx_doctor()` → `[OK]` runtimes + performance.

## Diagnóstico ante MCP apagado (orden)

1. Leer `~\.local\share\opencode\log\opencode.log`, filtrar `mcp connect failed` / `mcp connected` por servidor: distingue timeout (lentitud/CPU) de transport error (protocolo roto, típico de shim `.ps1`).
2. Contar procesos filtrados (`node`, `python`, browsers): >15 cadáveres saturan CPU → matarlos.
3. Probar binario directo con `--help` (RC=0 esperado); si es shim `.ps1`, probar el `cli.js` con node.
4. Recargar OpenCode (Reload Window): los MCP solo se cargan al arrancar; cambios de config exigen reload.

## Dependencies

- ADR-0009 (hardcodeo + guardrails), ADR-0006 (diseño original de tokens), specs 000-mcp-* (trazabilidad por MCP).

## Risks

- La config congelada es máquina-específica (`C:/Users/tomas/...`): en otro equipo hay que re-resolver rutas (salida: corrección de #5299 → volver a tokens).
- Deriva futura: cualquier cambio manual a `opencode.json` invalida este baseline hasta re-verificar.
