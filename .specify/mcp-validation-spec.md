# Specification: MCP Validation and Synchronization for Agents_IA_TECH Kit

## Overview
Validate and synchronize the MCP (Model Context Protocol) configuration across the Agents_IA_TECH kit project. This specification covers the current state of MCP servers, validation requirements, and synchronization strategy with other projects.

## Current State Assessment

### MCP Configuration Source
- **File**: `.vscode\mcp.json`
- **Total Servers**: 8
- **Format**: JSON with `servers` block, each entry has `command`, `args` (array), `type: "stdio"`

### List of Configured MCP Servers
1. **markitdown** - `markitdown-mcp` - stdio
2. **codebase-memory-mcp** - `codebase-memory-mcp` - stdio
3. **context-mode** - `context-mode` - stdio
4. **graphify** - `C:/Python314/python.exe -m graphify.serve C:/Proyectos/Agents_IA_TECH/graphify-out/graph.json` - stdio
5. **github** - `C:/Users/tomas/.local/bin/github-mcp-server.exe` - stdio
6. **playwright** - `C:/Users/tomas/AppData/Roaming/npm/playwright-mcp.ps1` - stdio
7. **semgrep** - `C:/Users/tomas/.local/bin/semgrep.exe mcp` - stdio
8. **context7** - `C:/Users/tomas/AppData/Roaming/npm/context7-mcp.ps1 --stdio` - stdio

### Known Issues
- **4 commands not verified in runtime**: testsprite, sentry, pieces, perplexity (from Copilot migration report)
- **8th server context7** added (not in original 7-server report)
- **All routes hardcoded** to `C:/Users/tomas/` - machine-specific
- **No `.mcp.json` in root** - project uses `.vscode\mcp.json` exclusively
- **Backups preserved** from Copilot migration in `customizationMigrations\d98daa8a-...`

## Functional Requirements

### FR-001: Validar disponibilidad de comandos MCP
- Verificar que cada comando de servidor esté disponible en PATH o sea ejecutable
- Reportar estado True/False para cada uno de los 8 servidores
- Documentar rutas completas cuando existan

### FR-002: Validar consistencia de formato MCP
- Confirmar que todos los servidores usan `type: "stdio"`
- Confirmar que `args` usa formato array (no string suelta)
- Confirmar estructura JSON consistente en todas las entradas

### FR-003: Sincronizar configuración con otros proyectos
- Ejecutar `scripts/sync/mcp/lift-vscode.ps1` para propagar a otros proyectos
- Ejecutar `scripts/sync/mcp/lift-opencode.ps1` para OpenCode
- Mantener respaldo antes de cualquier escritura

### FR-004: Documentar rutas machine-specific
- Identificar todas las rutas hardcodeadas a `C:/Users/tomas/...`
- Proporcionar estrategia de normalización para sincronización multi-máquina
- Documentar en `.env.mcp` o documentación asociada

### FR-005: Mantener integridad de backups
- Preservar backups de migración Copilot existentes
- No modificar `.vscode\mcp.json` original sin validación previa
- Crear puntos de restore antes de sincronización

## Success Criteria

### SC-001: Todos los 8 servidores documentados
- Lista completa de servidores con comandos y rutas
- Estado de disponibilidad documentado (pending validation)

### SC-002: Formato consistente verificado
- Todos los servidores usan `type: "stdio"`
- Todos los `args` usan formato array
- Estructura JSON válida en todas las entradas

### SC-003: Sincronización exitosa (opcional)
- Si se ejecuta lift-vscode.ps1: Resultado `RESULT:mcp-vscode:sin-cambios|anadidas|reparadas`
- Si se ejecuta lift-opencode.ps1: Resultado `RESULT:mcp-opencode:sin-cambios|anadidas|reparadas`
- No se pierden configuraciones existentes

### SC-004: Backups preservados
- Archivos en `customizationMigrations\d98daa8a-...` sin modificar
- `.vscode\mcp.json` backup creado antes de cualquier modificación

## User Stories

### US-001: Validar configuración MCP actual
**Como** desarrollador del kit Agents_IA_TECH  
**Quiero** validar que la configuración MCP en `.vscode\mcp.json` sea consistente y completa  
**Para** asegurar que todos los servidores están correctamente configurados antes de sincronizar

### US-002: Sincronizar MCP a otros proyectos
**Como** orquestador del kit  
**Quiero** propagar la configuración MCP a otros proyectos usando scripts sincronización  
**Para** mantener consistencia across the kit

### US-003: Diagnosticar servidores no verificables
**Como** administrador del proyecto  
**Quiero** identificar qué servidores MCP pueden no estar disponibles en diferentes máquinas  
**Para** planificar normalización de rutas

## Assumptions
- El archivo `.vscode\mcp.json` es la fuente de verdad para la configuración MCP del proyecto
- Los scripts `scripts/sync/mcp/` son la vía oficial de sincronización
- Rutas hardcodeadas a `C:/Users/tomas/` son específicas de la máquina actual y requerirán normalización para sincronización multi-máquina
- Backups de migración Copilot ya existen y deben preservarse
- PowerShell 7.0+ está disponible en máquinas objetivo para ejecutar scripts de sincronización

## Dependencies
- `.vscode\mcp.json` - configuración base actual
- `scripts/sync/mcp/install.ps1` - instalación portable por máquina
- `scripts/sync/mcp/lift-vscode.ps1` - sincronización a VS Code
- `scripts/sync/mcp/lift-opencode.ps1` - sincronización a OpenCode
- `scripts/validar-mcps.ps1` - validación completa de MCP
- `.env.mcp` - variables de entorno MCP
- `graphify-out\graph.json` - grafo para servidor graphify

## Notes
- La validación runtime (ejecutando los comandos en el sistema) no se puede realizar en este entorno de sesión
- Los comandos `testsprite`, `sentry`, `pieces`, `perplexity` fueron reportados como no encontrados en PATH durante la migración Copilot
- El servidor `context7` fue agregado después de la migración inicial (8 servidores vs 7 reportados originalmente)
- Scripts de sincronización tienen modo `-DryRun` para probar sin escribir