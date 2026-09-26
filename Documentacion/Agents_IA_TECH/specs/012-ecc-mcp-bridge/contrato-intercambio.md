# Contrato de intercambio ECC ↔ MCPs

## Formato de entrada ECC
- Hooks de sesión generan JSON con: sessionId, timestamp, summary, decisions, errors.
- contexts/ genera archivos markdown con contexto declarativo.
- workflows/ genera pasos ejecutados.

## Formato de salida MCP
- context-mode: ctx_index con source = 'ecc-session-<id>'
- codebase-memory-mcp: index_repository con metadata ECC
- graphify: extract con tags ecc-context

## Mapeo
ECC summary → ctx_index content
ECC decision → ctx_index con source 'ecc-decision'
ECC workflow step → graphify node con label WorkflowStep

## Sincronización mcp-configs
mcp-servers.json es fuente única. scripts/update-mcp.ps1 lee JSON y genera .env.mcp temporal si necesario.
