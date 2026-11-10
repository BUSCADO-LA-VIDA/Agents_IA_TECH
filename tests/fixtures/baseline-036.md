# Baseline F0 — Spec 036

## 1. Fecha de ejecucion

2026-11-04 (ejecutado por plataformador sobre $KitPath)

## 2. Exit codes de las suites de prueba

Se ejecutaron con `pwsh -File` los 5 scripts de prueba del F0 de spec 036.

| # | Suite | Comando | Exit code | Resultado |
|---|---|---|---:|---|
| 1 | tests/harness-default.ps1 | pwsh -File tests/harness-default.ps1 | 0 | OK (arranque valido del arnes) |
| 2 | tests/kit-sync-merge.ps1 | pwsh -File tests/kit-sync-merge.ps1 | 0 | OK (10 escenarios PASS) |
| 3 | tests/agents-parity.ps1 | pwsh -File tests/agents-parity.ps1 | 1 | FALLO (1 incidencia: Agent-SSD cuerpos difieren entre arneses) |
| 4 | tests/kb-parity.ps1 | pwsh -File tests/kb-parity.ps1 | 0 | OK (paridad KB PASS + fixture negativo detectado) |
| 5 | tests/mcp-refresh-parity.ps1 | pwsh -File tests/mcp-refresh-parity.ps1 | 0 | OK (paridad refresh MCP PASS + fixture negativo detectado) |

Suite con fallo: tests/agents-parity.ps1 (exit 1). Resto: exit 0.

## 3. Conteo del audit log (.bootstrap-audit.log)

Archivo analizado: $KitPath\.bootstrap-audit.log

| Metrica | Valor |
|---|---:|
| Numero total de lineas | 206 |
| Lineas con "prevHash": null | 136 |
| Lineas con "prevHash" distinto de null | 70 |
| Hash de la ultima linea | 370673cd94ef14ed8984c64c9b85f87d18718d74529b07018ca879a9a3414673 |
| Accion de la ultima linea | kit_patch_committed |
| Timestamp de la ultima linea | 2026-11-02T18:11:54.6449270+01:00 |

## 4. Estado general del F0 (spec 036)

- 4 de 5 suites pasaron (exit 0).
- 1 suite fallo (agents-parity.ps1, exit 1) por divergencia de cuerpos del agente Agent-SSD entre los arneses .github y .opencode.
- Audit log leido sin modificaciones: 206 lineas, 136 bloques con prevHash nulo (inicios de cadena), ultimo hash 370673cd...
- Ningun archivo del repositorio fue modificado salvo la creacion de este baseline.
