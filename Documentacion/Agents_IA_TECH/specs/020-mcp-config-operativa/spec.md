# Feature Specification: 020-mcp-config-operativa — Configuración MCP operativa verificada en vivo

**Feature Branch**: `020-mcp-config-operativa`
**Created**: 2026-10-11
**Status**: Completado (documental — congela la configuración que levanta los 9 MCP)
**Input**: Sesión de verificación 2026-10-11. Esta spec NO instala nada: congela como referencia la configuración de `opencode.json` + binarios + índices que se verificó funcionando en vivo.

---

## Problema

El kit sufrió reiteradas regresiones de MCP (tokens `{env:...}` sin resolver por bug OpenCode #5299, shims `.ps1` que rompen stdio, binarios inexistentes registrados, timeouts por CPU saturada). Cada incidente obligaba a re-diagnosticar desde cero porque no existía una referencia congelada de "la configuración que funciona".

## Objetivos

- Dejar por escrito la configuración exacta (`opencode.json`, rutas, versiones) que levanta los 9 MCP el 2026-10-11.
- Definir el procedimiento de verificación viva por MCP (handshake stdio + llamada real).
- Servir de baseline para detectar regresiones futuras (comparar contra este documento).

## Configuración congelada (verificada 2026-10-11)

### `opencode.json` — bloque `mcp` (9 entradas, todas `enabled: true`)

| MCP | `command` hardcodeado | Versión verificada |
|-----|----------------------|-------------------|
| `context-mode` | `C:/Program Files/nodejs/node.exe` + `.../npm/node_modules/context-mode/build/cli.js` | responde `Usage:` RC=0 |
| `codebase-memory-mcp` | `C:/Users/tomas/.local/bin/codebase-memory-mcp.exe` | 0.9.0 |
| `markitdown` | `C:/Python314/Scripts/markitdown.exe` | markitdown-mcp 0.0.1a7 |
| `graphify` | `C:/Python314/python.exe -m graphify.serve C:/Proyectos/Agents_IA_TECH/graphify-out/graph.json` | graphifyy 0.9.48 |
| `tokenslayer` | `node proyect_ext/tokenslayer/mcp-server/build/index.js` | build presente |
| `github` | `C:/Users/tomas/.local/bin/github-mcp-server.exe stdio` | v2.0.2 oficial, 46 tools |
| `playwright` | `node .../@playwright/mcp/cli.js` | v1.64.0, 25 tools |
| `semgrep` | `C:/Users/tomas/.local/bin/semgrep.exe mcp` | CLI 1.180.0, 7 tools |
| `context7` | `node .../@upstash/context7-mcp/dist/index.js` | 2 tools |

Reglas (ADR-0009): rutas absolutas con forward slashes; entry-point JS directo en vez de shim `.ps1`; `0` tokens `{env:}` en `mcp.command`; los 8 MCP extendidos originales sin binario NO se registran (solo github/playwright/semgrep/context7 que sí están instalados; sentry bloqueado, perplexity/pieces/testsprite pendientes de keys/apps).

### Índices (verificados 2026-10-11)

| Índice | Estado | Métrica |
|--------|--------|---------|
| codebase-memory (`C-Proyectos-Agents_IA_TECH`) | `ready` | 5.664 nodos, 6.157 aristas, head `012bf36` |
| graphify (`graphify-out/graph.json`) | 100% extraído | 4.793 nodos, 4.717 aristas, 460 comunidades, 4.6 MB |
| context-mode (`content/`) | 9 archivos | — |

### Secretos

- `GITHUB_TOKEN` vive en el entorno del host (nunca en archivos). `.env` del proyecto es plantilla gitignored con la clave vacía.
- `.env.mcp` contiene solo rutas de comandos, sin secretos.

## Requisitos funcionales

- **RF-01**: `opencode.json` commiteado con las 9 entradas hardcodeadas y `enabled: true` (necesario para que `sync-kit` lo distribuya).
- **RF-02**: Ninguna entrada MCP sin binario verificado en disco (guardrail 1 de ADR-0009).
- **RF-03**: Procedimiento de verificación viva documentado en `plan.md` (handshake + llamada real por MCP).
- **RF-04**: Ante MCP apagado, orden de diagnóstico: 1) `opencode.log` (timeout vs transport error), 2) procesos filtrados (CPU), 3) shim `.ps1` vs node directo, 4) reload OpenCode.

## Fuera de alcance

- Instalar perplexity/pieces/testsprite (pendientes de keys/apps del usuario) y desbloquear sentry (hang + auth interactiva).
- Corregir el bug OpenCode #5299 (externo; salida del workaround ADR-0009).

## Criterios de éxito

- **SC-01**: Los 9 MCP responden handshake stdio en vivo (hecho 2026-10-11 para 8/9; markitdown verificado por binario + uso en pipeline).
- **SC-02**: `git status` limpio salvo `opencode.json` local si difiere de la plantilla commiteada (documentar la divergencia).
- **SC-03**: Esta spec permanece como baseline: cualquier regresión futura se diagnostica comparando contra ella.
