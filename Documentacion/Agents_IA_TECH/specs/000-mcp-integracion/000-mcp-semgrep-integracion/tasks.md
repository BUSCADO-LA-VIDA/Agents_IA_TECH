# Tasks: 000-mcp-semgrep-integracion

- T01 Habilitar MCP en plantilla [RF-01,RF-04]
  Actualizar opencode.json plantilla con entrada semgrep type stdio command {env:SEMGREP_MCP_CMD}, enabled controlado por runtime
- T02 Resolver token .env.mcp [RF-02,SC-002]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand SEMGREP_MCP_CMD y crear/actualizar .env.mcp
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable si semgrep --version falla; no registrar entrada rota; bootstrap continúa
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json vía Sync-TransversalKit
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir comando de verificación y ejemplo de scan de Semgrep en quickstart.md
- T06 Validar idempotencia [RF-03,SC-005,EC-03]
  Ejecutar bootstrap dos veces y confirmar bloque mcp idéntico sin duplicados

- T01 Habilitar MCP [HECHO 2026-10-11]: entrada `semgrep` hardcodeada en opencode.json (binario real). Desviacion ADR-0009: sin tokens {env:} (bug OpenCode #5299).
- T02 Instalar [HECHO 2026-10-11]: PIVOT documentado - el paquete `semgrep-mcp` 0.9.0 esta DEPRECADO por upstream (solo expone `deprecation_notice`); el servidor real es `semgrep mcp` del CLI oficial v1.180.0 (`uv tool install semgrep`). Wrapper deprecado desinstalado. Incidencia intermedia: `semgrep-mcp` exigio Python 3.12 aislado (3.14 sin wheels pydantic-core) + pin mcp==1.9.0/pydantic==2.11.7; todo ese trabajo quedo descartado por la deprecacion.
- T03 Fallback fail-open [HECHO 2026-10-11]: sin binario semgrep -> el servidor no arranca; WARN con `uv tool install semgrep`.
- T04 Paridad [HECHO 2026-10-11]: opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A.
- T05 Verificacion viva [HECHO 2026-10-11]: handshake stdio + tools/list = 7 tools (semgrep_scan, semgrep_findings, supply_chain, etc.).
