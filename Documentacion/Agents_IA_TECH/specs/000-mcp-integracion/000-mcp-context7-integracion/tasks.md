# Tasks: 000-mcp-context7-integracion

- T01 Habilitar MCP en plantilla [RF-01,SC-001]
  Actualizar opencode.json plantilla con entrada context7 type stdio, command ["{env:CONTEXT7_CMD}"], args ["--stdio"], enabled controlado por runtime
- T02 Resolver token .env.mcp [RF-02,SC-002]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand CONTEXT7_CMD y crear/actualizar .env.mcp con CONTEXT7_CMD
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable con comando `npm install -g @upstash/context7-mcp` si context7 --version falla; no registrar entrada rota; bootstrap continúa
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json vía Sync-TransversalKit
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir verificación `context7 --list-sources` y ejemplo de consulta en quickstart.md
- T06 Validar idempotencia [RF-03,SC-005,EC-03]
  Ejecutar bootstrap dos veces y confirmar bloque mcp idéntico sin duplicados
