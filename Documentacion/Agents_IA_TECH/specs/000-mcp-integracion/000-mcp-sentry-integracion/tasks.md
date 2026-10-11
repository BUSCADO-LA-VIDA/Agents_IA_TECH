# Tasks: 000-mcp-sentry-integracion

- T01 Habilitar MCP en plantilla [RF-01,RF-04]
  Actualizar opencode.json plantilla con entrada sentry type stdio command {env:SENTRY_MCP_CMD}, enabled controlado por runtime
- T02 Resolver token .env.mcp [RF-02,SC-002]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand SENTRY_MCP_CMD y crear/actualizar .env.mcp
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable si sentry-cli --version falla; no registrar entrada rota; bootstrap continúa
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json vía Sync-TransversalKit
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir comando de verificación y ejemplo de consulta de issues de Sentry en quickstart.md
- T06 Validar idempotencia [RF-03,SC-005,EC-03]
  Ejecutar bootstrap dos veces y confirmar bloque mcp idéntico sin duplicados

- T01 [2026-10-11]: instalacion `npm i -g @sentry/mcp-server` 0.42.0 OK. Entrada NO registrada habilitada (ver T05).
- T02 [2026-10-11]: binario en npm global. Ruta pendiente de registro hasta que el binario responda.
- T03 [BLOQUEADO]: el binario se cuelga en toda invocacion (--help, auth status, stdio) sin salida; mas auth interactiva (device flow) que requiere al usuario.
- T04 [PENDIENTE]: paridad pendiente del registro.
- T05 [PENDIENTE - NO VALIDADO]: verificacion viva imposible sin auth + hang. NO se marca [x] por regla de integridad.
