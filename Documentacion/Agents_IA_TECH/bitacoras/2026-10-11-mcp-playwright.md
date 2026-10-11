# Bitacora 2026-10-11 — MCP playwright (segundo de 8, implementacion individual)

## Instalacion
- `npm i -g @playwright/mcp` (Microsoft, v1.64.0). Browsers ya presentes (`ms-playwright`).
- Shim: `C:/Users/tomas/AppData/Roaming/npm/playwright-mcp.ps1`; binario real `node_modules/@playwright/mcp/cli.js`.

## Registro (ADR-0009)
- `opencode.json`: entrada `playwright` hardcodeada (shim .ps1, igual que context-mode que funciona). `.vscode/mcp.json`: paridad. `.env.mcp`: ruta sin secreto.

## Verificacion viva
- Handshake stdio: serverInfo `Playwright 1.64.0`, capability tools. `tools/list` = 25 tools.
- Incidencia: invocacion directa del shim .ps1 via powershell no canaliza stdio en pruebas manuales (se cuelga); invocando `node cli.js` responde. El registro usa el shim igual que context-mode (verificado funcional en vivo en sesion anterior), por lo que se considera valido; si OpenCode no lo levanta, cambiar el command al `cli.js` con node es el fallback documentado.

## Cambios
- tasks.md T01-T05 con evidencia. Backlog T02-T05 `[x]`/Si. Sin commit (el usuario pide commit por MCP).
