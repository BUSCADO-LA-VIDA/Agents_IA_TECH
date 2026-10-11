# Bitacora 2026-10-11 — MCP github (primero de 8, implementacion individual)

## Instalacion
- Release oficial `github/github-mcp-server v2.0.2` (2026-10-08), asset `Windows_x86_64.zip` (~9 MB).
- SHA256 verificado contra el publicado (`4ae64087...b8c4bd99DF`): coincide.
- Instalado en `C:/Users/tomas/.local/bin/github-mcp-server.exe` (28.6 MB). `--help` responde (`stdio`, `http`, `list-scopes`).

## Registro (ADR-0009, sin tokens)
- `opencode.json`: entrada `github` type local, command hardcodeado + `stdio`, enabled true. 0 `{env:}` en commands.
- `.vscode/mcp.json`: paridad con command/args/type stdio.
- `.opencode/mcp.json`: NO existe en este proyecto (N/A).
- `.env.mcp`: `GITHUB_MCP_CMD` = ruta (sin secreto). `.env`: `GITHUB_TOKEN=` vacio como plantilla; el token YA esta en el entorno del host (no se invento ni se escribio ningun secreto).

## Verificacion viva
- `get_me` -> `tomasecastro` (24 repos privados visibles). `get_latest_release(github/github-mcp-server)` -> v2.0.2. 46 tools del servidor en catalogo.

## Desviaciones de la spec vieja (registradas, no silenciosas)
- Spec pedia `{env:GITHUB_MCP_CMD}` + `.env.mcp` como mecanismo: sustituido por hardcodeo (bug OpenCode #5299, ADR-0009).
- Spec T05 pedia `github --list-repos` en quickstart: se documento el patron de verificacion viva en su lugar.

## Cambios
- `specs/000-mcp-integracion/000-mcp-github-integracion/tasks.md`: T01-T05 con evidencia.
- Backlog: filas T02-T05 `[x]`/Si. `quickstart.md`: nota de verificacion viva + manejo del token.
- Binario fuera del repo (`~/.local/bin`, no versionado). Sin commit (user no lo pidio para MCPs).

## Siguiente
Playwright o semgrep (sin keys) cuando el usuario indique. Faltan 7/8.
