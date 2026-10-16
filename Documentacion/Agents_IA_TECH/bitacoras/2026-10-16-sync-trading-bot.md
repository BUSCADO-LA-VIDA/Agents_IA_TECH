# Bitacora 2026-10-16 — Primer sync real por Git a trading_bot (spec 021 T013 parcial)

## Corrida por Git (sin -KitPath)
- Stage: `git clone --depth 1` del remoto a `.kit-sync-temp/<stamp>/`. 0 ERRORs en 12 capas.
- kit-files ok (scripts+README reemplazados con backup); agents sin cambios; docs/constitutions/src ok.
- mcp-install 8/9 (tokenslayer ausente-warn: sin build en trading_bot, esperado).
- mcp lift: 2 claves anadidas + 4 reparadas en su opencode.json (13 entries); graphify regenerado al destino.
- indexing ok; externals fail-open (sin manifest/ECC en destino, esperado).
- Reporte `.kit-last-sync.json` + flag `.kit-restart-required` escritos; backup en `.kit-backup/`.

## Mejora pendiente (no bloqueante)
- El orquestador limpia el stage con stamp pero deja el dir base `.kit-sync-temp/` vacio (limpiado a mano esta vez).
- Filtro de apps basura (dirs `.specify`, `specs` tomados como apps con scaffolding vacio).
- Registrar ambas en spec 021 como T014.

## Nota
- Commit en el repo trading_bot lo hace su flujo (el orquestador no commitea destinos ajenos).
- T013 (prueba en 1 consumidor) EVIDENCIADA aqui; deprecacion de sync-kit.ps1 ya hecha (comentario [021-DEPRECATED]).
