# Tasks: 000-mcp-github-integracion

- T01 Habilitar MCP en plantilla [RF-01,RF-04]
  Actualizar opencode.json plantilla con entrada github type stdio command {env:GITHUB_MCP_CMD}
- T02 Resolver token .env.mcp [RF-02]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand GITHUB_MCP_CMD
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable si github --version falla
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir verificación github --list-repos en quickstart.md
