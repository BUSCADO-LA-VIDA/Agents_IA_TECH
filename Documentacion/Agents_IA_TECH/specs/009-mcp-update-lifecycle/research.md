# Research: 009-mcp-update-lifecycle

**Feature**: 009-mcp-update-lifecycle
**Date**: 2026-09-24

## Decisiones de investigación

### D1 - Formato de estado
**Decisión**: Usar `.bootstrap-state.json` con campos `lastUpdate` ISO8601 y `tools` con versión y ruta.
**Racional**: Simple, legible, gitignored, compatible con PowerShell.
**Alternativas**: SQLite, archivo .txt → descartadas por complejidad.

### D2 - Lógica de auto-actualización
**Decisión**: Ventana de 24h, forzable con `-Force`.
**Racional**: Balance entre frescura y ruido.
**Alternativas**: Actualización siempre → descartada por tiempo.

### D3 - Integración con pensador
**Decisión**: Regla documental en agente, delegación a script.
**Racional**: Mantiene separación de responsabilidades.
**Alternativas**: Lógica embebida en pensador → descartada.

## Hallazgos
- PowerShell 7+ soporta `Get-Content -Raw` y `ConvertFrom-Json` sin dependencias.
- `.env.mcp` ya existe como inventario central.
- Bootstrap ya invoca scripts de nivelación.

## Conclusión
No hay NEEDS CLARIFICATION pendientes. Listo para diseño.
