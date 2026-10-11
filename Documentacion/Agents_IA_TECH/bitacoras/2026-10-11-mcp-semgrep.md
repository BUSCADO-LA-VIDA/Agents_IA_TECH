# Bitacora 2026-10-11 — MCP semgrep (tercero de 8, implementacion individual)

## PIVOT: upstream deprecio el paquete
- `semgrep-mcp` 0.9.0 (PyPI, ultimo) solo expone `deprecation_notice`: indica usar `semgrep mcp` del CLI oficial.
- Servidor real verificado: `semgrep mcp` (CLI 1.180.0, `uv tool install semgrep`), handshake stdio + 7 tools.
- Wrapper deprecado desinstalado (`uv tool uninstall semgrep-mcp`).

## Incidencias intermedias (descartadas, se registran por honestidad)
- `semgrep-mcp` exigio Python 3.12 aislado (`uv python install 3.12`) porque 3.14 no tiene wheels pydantic-core viejos + pin `mcp==1.9.0`/`pydantic==2.11.7`. Todo ese entorno quedo sin uso tras el pivot.

## Registro (ADR-0009)
- `opencode.json`: `semgrep` = `semgrep.exe mcp` hardcodeado. `.vscode/mcp.json`: paridad. Sin keys (herramienta local).

## Cambios
- tasks.md T01-T05, backlog T02-T05 `[x]`/Si. Sin commit (usuario pide commit por MCP).
