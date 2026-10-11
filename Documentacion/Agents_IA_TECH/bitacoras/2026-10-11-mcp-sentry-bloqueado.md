# Bitacora 2026-10-11 — MCP sentry BLOQUEADO (no se commitea registro)

## Instalado
- `npm i -g @sentry/mcp-server` 0.42.0 (getsentry/sentry-mcp). Shim presente.

## Bloqueo doble
1. El binario se cuelga en TODA invocacion (`--help`, `auth status`, stdio handshake): sin salida, proceso vivo, ni con stdin=DEVNULL. node v24 funciona bien con otros paquetes.
2. Requiere auth interactiva (device code flow `auth login` o `--access-token`): imposible sin el usuario.

## Decision
- NO se registra la entrada habilitada: un binario colgado colgaria el arranque de OpenCode.
- T05 queda pendiente sin [x] por regla de integridad (2026-09-26).
- Para retomar: usuario ejecuta `sentry-mcp auth login`, luego reintentar handshake; si sigue colgando, probar version anterior o `npx -y @sentry/mcp-server@<prev>`.
