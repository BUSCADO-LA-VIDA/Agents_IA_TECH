# Spec: Puente ECC ↔ MCPs y migración de mcp-configs

## User Story
Como mantenedor, quiero que ECC use mi stack MCP actual como fuente de verdad de memoria y que mcp-configs/ de ECC reemplace .env.mcp, para evitar dos arquitecturas y mantener eficiencia en tokens.

## Contexto
ECC versiona configs MCP en mcp-configs/mcp-servers.json. Mi kit usa .env.mcp. ECC controla memoria con hooks/contexts/workflows. Mi stack es context-mode, codebase-memory-mcp, graphify, markitdown.

## Requisitos Funcionales
FR-001: Migrar .env.mcp a mcp-configs/mcp-servers.json como fuente única de verdad.
FR-002: scripts/update-mcp.ps1 debe leer mcp-configs/mcp-servers.json.
FR-003: Hooks ECC deben escribir resúmenes en context-mode vía ctx_index.
FR-004: Contexts/workflows ECC deben materializarse en codebase-memory-mcp y graphify.
FR-005: Definir contrato de intercambio de información entre ECC y MCPs.

## Requisitos No Funcionales
NFR-001: No duplicar fuentes de verdad.
NFR-002: Mantener eficiencia de tokens con MCPs.

## Criterios de Aceptación
SC-001: .env.mcp deprecado, mcp-configs es fuente única.
SC-002: update-mcp.ps1 lee JSON de ECC.
SC-003: Contrato de intercambio documentado.
