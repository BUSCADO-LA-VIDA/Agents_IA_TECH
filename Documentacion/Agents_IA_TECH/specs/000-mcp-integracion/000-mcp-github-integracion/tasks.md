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

- T01 Habilitar MCP [HECHO 2026-10-11]: entrada `github` hardcodeada en opencode.json (binario real v2.0.2). Desviacion ADR-0009: sin tokens {env:} en mcp.command (bug OpenCode #5299).
- T02 Resolver ruta [HECHO 2026-10-11]: binario oficial v2.0.2, SHA256 verificado, en `C:/Users/tomas/.local/bin/github-mcp-server.exe`. GITHUB_MCP_CMD registrada en .env.mcp (ruta, sin secreto).
- T03 Fallback fail-open [HECHO 2026-10-11]: hook Ensure-ConstitutionAppSync no toca MCPs; el bootstrap emite WARN si el binario falta (patron existente). Este MCP exige GITHUB_TOKEN: sin el, el servidor arranca pero las llamadas devuelven error de auth.
- T04 Paridad [HECHO 2026-10-11]: entrada en opencode.json + .vscode/mcp.json. .opencode/mcp.json NO existe en este proyecto (N/A documentado).
- T05 Quickstart [HECHO 2026-10-11]: verificado vivo get_me=tomasecastro + get_latest_release=v2.0.2.

- T07 Actualizar agentes afectados por github MCP [RF-04,SC-005] [RF-04,SC-005]
  Anadir la linea de `github` a la seccion 'Uso de MCPs' de api-developer, devops, frontend-developer, gitflow, plataformador y security-auditor, replicando en .github/agents/ y .opencode/agents/ con bloques identicos
- T08 Verificacion anti-huerfano [RF-07,SC-005,SC-006] [RF-07,SC-005,SC-006]
  Cruz ar MCPs de opencode.json contra los bloques 'Uso de MCPs' de los 16 agentes. Exigir: cobertura total, 0 huerfanos inversos, 0 desajustes entre arneses, y al menos una ejecucion real de agente que llame la herramienta. Adjuntar el resultado del cruce a la spec
