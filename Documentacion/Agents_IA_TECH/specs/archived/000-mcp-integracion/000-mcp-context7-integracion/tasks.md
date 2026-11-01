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

- T01 Habilitar MCP [HECHO 2026-10-11]: entrada `context7` hardcodeada en opencode.json (node directo a dist/index.js). Desviacion ADR-0009: sin tokens {env:} (bug OpenCode #5299).
- T02 Instalar [HECHO 2026-10-11]: `npm i -g @upstash/context7-mcp`. CONTEXT7_CMD en .env.mcp.
- T03 Fallback fail-open [HECHO 2026-10-11]: sin binario -> WARN; sin red -> la API no resuelve (documentado).
- T04 Paridad [HECHO 2026-10-11]: opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. Sin keys (API publica).
- T05 Verificacion viva [HECHO 2026-10-11]: handshake + tools/list = 2 tools + resolve-library-id(react) real contra la API.

- T07 Actualizar agentes afectados por context7 [RF-04,SC-005] [RF-04,SC-005]
  Anadir la linea de `context7` a la seccion 'Uso de MCPs' de Agent-SSD, analista_tecnico, api-developer, arquitecto, documentador, frontend-developer, pensador, plataformador, qa-senior y upgrade_framework, replicando en .github/agents/ y .opencode/agents/ con bloques identicos (0 desajustes)
- T08 Verificacion anti-huerfano [RF-07,SC-005,SC-006] [RF-07,SC-005,SC-006]
  Cruz ar MCPs de opencode.json contra los bloques 'Uso de MCPs' de los 16 agentes. Exigir: cobertura total, 0 huerfanos inversos, 0 desajustes entre arneses, y al menos una ejecucion real de agente que llame la herramienta. Adjuntar el resultado del cruce a la spec
