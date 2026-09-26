# Spec: Migración .env.mcp → mcp-configs/mcp-servers.json

## User Story
Quiero migrar la fuente única de verdad de MCPs de .env.mcp a mcp-configs/mcp-servers.json de ECC, manteniendo update-mcp.ps1 funcional y controlando actualización de herramientas vs índices y grafos.

## Contexto
Actual: .env.mcp + scripts/update-mcp.ps1
Objetivo: mcp-configs/mcp-servers.json como fuente única.

## Requisitos Funcionales
FR-001: Leer mcp-servers.json de proyect_ext/ECC/mcp-configs
FR-002: scripts/update-mcp.ps1 debe generar .env.mcp temporal si necesario
FR-003: Separar actualización de herramientas MCP de actualización de índices y grafos
FR-004: Script debe validar integración correcta antes de aplicar cambios
FR-005: Registrar estado en .ecc-state.json

## Requisitos No Funcionales
NFR-001: No duplicar fuentes de verdad
NFR-002: Proceso idempotente

## Criterios de Aceptación
SC-001: update-mcp.ps1 lee JSON de ECC
SC-002: Índices y grafos se actualizan en paso separado
SC-003: Validación de integración pasa
