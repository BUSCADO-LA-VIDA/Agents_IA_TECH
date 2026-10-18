# Bitacora 2026-10-16 — Despliegue por Git a Generator_IA_Projects (src protegido)

## Corrida (12 capas - 2 skips, 0 errores bloqueantes)
- Stage: clone del remoto. kit-files/agents/docs OK. mcp-install 8/9 (tokenslayer ausente-warn, esperado).
- mcp lift: reparadas en opencode.json + .vscode/mcp.json. indexing OK (graphify omitido-warn: 1 file sensible).
- externals fail-open (sin manifest/ECC en destino, esperado). Reporte + flag restart escritos.

## src/ intacto (verificado)
- Capas src-structure y constitutions salteadas; 0 archivos src en backup.

## Documentacion como fuente de verdad (verificado + completado)
- 10/15 apps con L2; sembradas las 5 faltantes (agents, Agents_IA_TECH, arquitectura, bitacoras, funcionalidades) desde la raiz del KIT con hash identico.

## Pendiente conocido
- `.kit-sync-temp/` base no lo limpia el orquestador (limpiado a mano; registrar como T014 en spec 021).
- Commit en repo Generator_IA_Projects: su flujo (no commiteado por el sync).
