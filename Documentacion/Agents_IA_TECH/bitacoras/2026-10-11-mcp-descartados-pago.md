# Bitacora 2026-10-11 — MCPs descartados por ser de pago (4/8 fuera)

## Decision del usuario
Se quitan: sentry, perplexity, pieces, testsprite. Quedan: github, playwright, semgrep, context7 (+ 5 base = 9 MCP activos).

## Acciones
- `npm uninstall -g @sentry/mcp-server` (154 paquetes removidos, shim eliminado). Los otros 3 nunca se instalaron: nada que desinstalar.
- `.env`: eliminado `SENTRY_AUTH_TOKEN=`. `.env.mcp`: eliminada linea `SENTRY_MCP_CMD` (era nota de pin, no ruta efectiva).
- `opencode.json`: nunca tuvo entradas de estos 4 (verificado: 9 entradas, ninguna es de ellos).
- Backlog: eliminadas las 4 filas T01 (eran verificaciones de plantilla viejas, alcance caido; historial en git).
- Specs `000-mcp-{sentry,perplexity,pieces,testsprite}`: nota DESCARTADO con fecha y motivo. No se archivan (el usuario no pidio archivar, solo quitar).

## Sentry (detalle)
Se habia fijado pin 0.41.0 y documentado el hang de 0.42.0. Todo ese trabajo queda sin efecto por el descarte; queda en el historial por si se retoma con licencia.
