# Quickstart: 009-mcp-update-lifecycle

## Prerrequisitos
- PowerShell 7+
- Repositorio clonado
- Acceso a internet para actualizar MCPs

## Escenarios de validación

### 1. Actualización manual
```powershell
pwsh scripts/update-mcp.ps1
```
**Esperado**: Script detecta MCPs, actualiza si necesario, escribe `.bootstrap-state.json`, reporta estado por MCP.

### 2. Forzar actualización
```powershell
pwsh scripts/update-mcp.ps1 -Force
```
**Esperado**: Actualiza todos los MCPs independientemente de la fecha.

### 3. DryRun
```powershell
pwsh scripts/update-mcp.ps1 -DryRun
```
**Esperado**: Reporta qué haría sin modificar archivos.

### 4. Integración bootstrap
```powershell
pwsh scripts/plataformador-bootstrap.ps1
```
**Esperado**: Al finalizar, invoca `update-mcp.ps1` y los MCPs quedan actualizados.

### 5. Delegación desde pensador
**Esperado**: El agente `pensador` puede solicitar actualización y recibir reporte de estado.

## Validación
- `.bootstrap-state.json` existe y `lastUpdate` es hoy.
- Variables de entorno de usuario actualizadas.
- MCPs habilitados en `opencode.json` y `.vscode/mcp.json`.
