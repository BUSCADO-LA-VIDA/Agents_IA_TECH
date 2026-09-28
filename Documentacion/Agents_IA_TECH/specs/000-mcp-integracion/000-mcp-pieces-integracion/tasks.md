# Tasks: 000-mcp-pieces-integracion

- T01 Habilitar MCP en plantilla [RF-01,RF-04]
  Actualizar opencode.json plantilla con entrada pieces type stdio command {env:PIECES_MCP_CMD}, enabled controlado por runtime
- T02 Resolver token .env.mcp [RF-02,SC-002]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand PIECES_MCP_CMD y crear/actualizar .env.mcp
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable si la verificación de pieces falla; no registrar entrada rota; bootstrap continúa
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json vía Sync-TransversalKit
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir comando de verificación y ejemplo de consulta de memoria de Pieces en quickstart.md
- T06 Validar idempotencia [RF-03,SC-005,EC-03]
  Ejecutar bootstrap dos veces y confirmar bloque mcp idéntico sin duplicados
