# Tasks: 000-mcp-playwright-integracion

- T01 Habilitar MCP en plantilla [RF-01,RF-04]
  Actualizar opencode.json plantilla con entrada playwright type stdio command {env:PLAYWRIGHT_MCP_CMD}, enabled controlado por runtime
- T02 Resolver token .env.mcp [RF-02,SC-002]
  Extender scripts/plataformador-bootstrap.ps1 para Resolve-McpCommand PLAYWRIGHT_MCP_CMD y crear/actualizar .env.mcp
- T03 Fallback fail-open [RF-03,SC-003]
  Implementar WARN accionable si la verificación de playwright falla; no registrar entrada rota; bootstrap continúa
- T04 Sincronizar configuraciones [RF-04,SC-004]
  Asegurar paridad .opencode/mcp.json y .vscode/mcp.json vía Sync-TransversalKit
- T05 Documentar quickstart [RF-05,SC-001]
  Añadir comando de verificación y ejemplo de navegación de Playwright en quickstart.md
- T06 Validar idempotencia [RF-03,SC-005,EC-03]
  Ejecutar bootstrap dos veces y confirmar bloque mcp idéntico sin duplicados

- T01 Habilitar MCP [HECHO 2026-10-11]: entrada `playwright` hardcodeada en opencode.json (ruta real npm global). Desviacion ADR-0009: sin tokens {env:} en mcp.command (bug OpenCode #5299).
- T02 Instalar [HECHO 2026-10-11]: `npm i -g @playwright/mcp` (Microsoft, v1.64.0); browsers ya presentes en ms-playwright. PLAYWRIGHT_MCP_CMD en .env.mcp (ruta, sin secreto).
- T03 Fallback fail-open [HECHO 2026-10-11]: sin binario -> WARN; browsers ausentes -> el servidor los exige al invocar tools (documentado).
- T04 Paridad [HECHO 2026-10-11]: entrada en opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A.
- T05 Verificacion viva [HECHO 2026-10-11]: handshake stdio Playwright 1.64.0 + tools/list = 25 tools (browser_navigate, browser_snapshot, etc.). Nota: invocacion via shim .ps1 no canaliza stdio; el registro usa el shim igual que los demas MCP npm (context-mode funciona asi).

- T07 Actualizar agentes afectados por playwright [RF-04,SC-005] [RF-04,SC-005]
  Anadir la linea de `playwright` a la seccion 'Uso de MCPs' de devops, frontend-developer y qa-senior, replicando en .github/agents/ y .opencode/agents/ con bloques identicos (0 desajustes)
- T08 Verificacion anti-huerfano [RF-07,SC-005,SC-006] [RF-07,SC-005,SC-006]
  Cruz ar MCPs de opencode.json contra los bloques 'Uso de MCPs' de los 16 agentes. Exigir: cobertura total, 0 huerfanos inversos, 0 desajustes entre arneses, y al menos una ejecucion real de agente que llame la herramienta. Adjuntar el resultado del cruce a la spec
