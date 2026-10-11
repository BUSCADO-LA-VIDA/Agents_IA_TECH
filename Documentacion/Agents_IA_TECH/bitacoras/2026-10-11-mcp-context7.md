# Bitacora 2026-10-11 — MCP context7 (cuarto de 8, implementacion individual)

## Instalacion
- `npm i -g @upstash/context7-mcp`. (La primera tentativa quedo a medias por shell colgado; reinstalado limpio tras matar procesos filtrados.)

## Registro (ADR-0009 + reparacion node-direct)
- `opencode.json`: `context7` = `node .../dist/index.js` (sin `--stdio`; el shim .ps1 rompia el transporte).
- `.vscode/mcp.json`: paridad. Sin keys.

## Verificacion viva
- Handshake + `tools/list` = 2 tools (`resolve-library-id`, `query-docs`).
- `resolve-library-id({libraryName:react, query:hooks})` -> IDs reales (`/reactjs/react.dev`, 4342 snippets).

## Cambios
- tasks.md T01-T05, backlog T02-T05 `[x]`/Si. Commit junto a reparacion MCP (mismo flujo).
