# Bitacora 2026-10-11 — Reparacion MCP apagados (timeouts + shim .ps1)

## Diagnostico (log opencode.log)
- Casi todos los MCP fallaban con `mcp connect failed: Request timed out` (graphify, context-mode, markitdown, semgrep, tokenslayer, github, playwright, context7). Solo `codebase-memory-mcp` conectaba.
- Causa 1: 30 procesos filtrados (node/python/browsers de pruebas de handshake) saturando CPU -> arranques lentos -> timeout. Limpiados.
- Causa 2: los shim `.ps1` de npm (context-mode, playwright, context7) obligan a OpenCode a envolver con `pwsh -NonInteractive -Command`, rompiendo/degradando el transporte stdio (evidencia: `transport error: unknown message ID` en playwright).
- Config estaba correcta (9/9 enabled:true, binarios existen).

## Reparacion
- Comandos cambiados a `node <cli.js>` directo (RC=0 verificado en los 3):
  - context-mode -> `node .../context-mode/build/cli.js`
  - playwright -> `node .../@playwright/mcp/cli.js`
  - context7 -> `node .../@upstash/context7-mcp/dist/index.js` (sin args `--stdio`)
- `.env.mcp` actualizado en concordancia.
- Patron a aplicar (ADR-0009): preferir entry-point JS directo sobre shim .ps1 siempre.

## Pendiente del usuario
- Recargar OpenCode (Reload Window o reinicio) para que reconecte con la nueva config. Sin reload los cambios no surten efecto.
- Sin commit (reparacion pendiente de verificacion post-reload).
