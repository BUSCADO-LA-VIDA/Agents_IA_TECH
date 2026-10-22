# Plan: MCP Validation and Synchronization for Agents_IA_TECH Kit

## Objective
Validate the current MCP configuration in `.vscode\mcp.json` and synchronize with other projects in the kit using official scripts. Define execution order and decision points.

## Prerequisites

### Verified Artifacts
- `.vscode\mcp.json` exists con 8 servidores ✓
- `scripts/sync/mcp/install.ps1` disponible ✓
- `scripts/sync/mcp/lift-vscode.ps1` disponible ✓
- `scripts/sync/mcp/lift-opencode.ps1` disponible ✓
- Backups de migración Copilot preservados en `customizationMigrations\d98daa8a-...` ✓
- `.env.mcp` existe ✓
- `graphify-out\graph.json` existe ✓

### Requerimientos Previos
1. PowerShell 7.0+ en máquina objetivo
2. Acceso de escritura a `.vscode\mcp.json` (backup se creará automáticamente)
3. Conocimiento de rutas machine-specific (`C:/Users/tomas/...`)

## Execution Order

### Fase 1: Validación Estática (Paso Obligatorio)

#### Tarea T001: Verificar formato JSON
```powershell
# Validar que .vscode\mcp.json sea JSON válido
Get-Content "C:\Proyectos\Agents_IA_TECH\.vscode\mcp.json" | ConvertFrom-Json
```
**Resultado esperado**: JSON parseado sin errores  
**Fallos posibles**: JSON corrupted, formato inesperado

#### Tarea T002: Verificar estructura de servidores
```powershell
# Contar servidores y validar estructura
($mcp = Get-Content "C:\Proyectos\Agents_IA_TECH\.vscode\mcp.json" | ConvertFrom-Json).servers.PSObject.Properties.Count
```
**Resultado esperado**: 8  
**Fallos posibles**: Distinto de 8 servidores

#### Tarea T003: Verificar consistencia de tipo
```powershell
# Confirmar que todos usan type: "stdio"
($mcp = Get-Content "C:\Proyectos\Agents_IA_TECH\.vscode\mcp.json" | ConvertFrom-Json).servers | ForEach-Object { $_.type -eq "stdio" }
```
**Resultado esperado**: True para todas las entradas  
**Fallos posibles**: Algun servidor usa tipo distinto

#### Tarea T004: Verificar formato de args
```powershell
# Confirmar que args usa formato array
($mcp = Get-Content "C:\Proyectos\Agents_IA_TECH\.vscode\mcp.json" | ConvertFrom-Json).servers | ForEach-Object { $_.args.GetType().IsArray }
```
**Resultado esperado**: True para todas las entradas  
**Fallos posibles**: Algun servidor trae args como string

### Fase 2: Sincronización Opcional (Si el usuario lo aprueba)

#### Tarea T005: Ejecutar install.ps1 (portable por máquina)
```powershell
.\scripts\sync\mcp\install.ps1 -RootPath "C:\Proyectos\Agents_IA_TECH"
```
**Propósito**: Instalar/MCP verificar en máquina actual  
**Modo DryRun**: `.\\scripts\\sync\\mcp\\install.ps1 -RootPath "C:\\Proyectos\\Agents_IA_TECH" -DryRun`  
**Resultado**: Emite RESULT:mcp-install:<herramienta>:ok|instalado|ausente-warn|sin-cambios>  
**Decisión**: ¿Proceder con instalación? (yes/no)

#### Tarea T006: Ejecutar lift-vscode.ps1 (actualizar .vscode\mcp.json)
```powershell
.\scripts\sync\mcp\lift-vscode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force
```
**Propósito**: Fusionar MCP desde maestro a .vscode\mcp.json  
**Reglas**:
- (a) clave del maestro ausente → agregar tal cual
- (b) clave existente cuyo command NO existe en disco → reemplazar por la del maestro
- (c) lo demás intacto
- graphify: regenera args con ruta `<Root>/graphify-out/graph.json`
- Si archivo no existe → crearlo (con graphify regenerado)
- **Con -Force**: refrescar commands del maestro aunque difieran
- **Sin tocar `enabled` del usuario en ningún caso**
- **Respeta -DryRun** (cero escrituras)
- **Resultado**: `RESULT:mcp-vscode:anadidas|reparadas|sin-cambios`

**Decisión de usuario**: ¿Ejecutar lift-vscode.ps1 con -Force? (yes/no/proceed)

#### Tarea T007: Ejecutar lift-opencode.ps1 (actualizar opencode.json)
```powershell
.\scripts\sync\mcp\lift-opencode.ps1 -StageDir "C:\Proyectos\Agents_IA_TECH" -Force
```
**Propósito**: Fusionar bloque mcp de opencode.json desde maestro  
**Mismo contrato** que lift-vscode.ps1 pero para OpenCode  
**Resultado**: `RESULT:mcp-opencode:anadidas|reparadas|sin-cambios`  
**Decisión de usuario**: ¿Ejecutar lift-opencode.ps1 con -Force? (yes/no/proceed)

#### Tarea T008: Ejecutar validar-mcps.ps1 (validación completa)
```powershell
.\scripts\validar-mcps.ps1 -ValidateAll
```
**Propósito**: Validación completa del estado MCP  
**Valida**:
1. Instalación y disponibilidad de comandos MCP
2. Versiones esperadas según dependencias-manifest.yml
3. Registro correcto en .vscode/mcp.json
4. Uso de "type": "stdio"
5. Hooks de context-mode en .github/hooks/context-mode.json
6. Ejecución real de los servidores MCP
**Opciones**: `-MCP <nombre>` para validar selectivo, `-SkipRuntime` para omitir ejecución

### Fase 3: Post-Sincronización

#### Tarea T009: Verificar resultados post-sync
```powershell
# Revisar reporte de sincronización
Get-Content "C:\Proyectos\Agents_IA_TECH\.kit-last-sync.json" | ConvertFrom-Json
```
**Propósito**: Confirmar qué capas ejecutaron y resultados

#### Tarea T010: Gestionar flag de restart
```powershell
# Verificar si se requiere reinicio
Test-Path "C:\Proyectos\Agents_IA_TECH\.kit-restart-required"
```
**Propósito**: Flag escrito por sync-kit-agents si los agents cambiaron

#### Tarea T011: Podar backups antiguos (si éxito)
```powershell
# Conservar ultimos 2 backups, podar el resto
# Esto sucede automáticamente al final exitoso de sync-kit-agents
```
**Propósito**: Fail-open: si falla, WARN y se sigue

## Decision Points

### DP-001: ¿Ejecutar T005 (install.ps1)?
- **Contexto**: Instalación portable por máquina, no afecta proyecto
- **Opciones**: yes (proceder), no (saltar), skip (usar -DryRun primero)
- **Recomendación**: Ejecutar con -DryRun primero para ver qué detecta

### DP-002: ¿Ejecutar T006 (lift-vscode.ps1)?
- **Contexto**: Actualiza .vscode\mcp.json desde configuración maestra
- **Opciones**: yes (ejecutar con -Force), no (saltar), dry-run (probar primero)
- **Impacto**: Puede agregar/quitar/servidores en .vscode\mcp.json
- **Rollback**: Backup creado automáticamente en .kit-backup\<timestamp>/

### DP-003: ¿Ejecutar T007 (lift-opencode.ps1)?
- **Contexto**: Actualiza bloque mcp de opencode.json
- **Opciones**: yes (ejecutar con -Force), no (saltar)
- **Notable**: No tocar `enabled` del usuario bajo ningun caso

### DP-004: ¿Ejecutar T008 (validar-mcps.ps1)?
- **Contexto**: Validación completa, puede tomar tiempo por ejecuciones runtime
- **Opciones**: ValidateAll (completo), -MCP <nombre> (selectivo), -SkipRuntime (solo configuración)
- **Tiempo estimado**: Variable, depende de qué tan rápido respondan los servidores

## Artifacts to Generate

### A) .kit-last-sync.json
- Reporte automático por sync-kit-agents después de ejecutar todas las capas
- Contiene: tool, phase, commit, date, layers, results
- Ubicación: `C:\Proyectos\Agents_IA_TECH\.kit-last-sync.json`

### B) .kit-restart-required (si aplica)
- Flag escrito si los agents de GitHub/OpenCode/VSCode reportaron cambios
- Ubicación: `C:\Proyectos\Agents_IA_TECH\.kit-restart-required`

### C) .kit-backup\<timestamp>\
- Backups automáticos antes de modificaciones críticas
- Se podan automáticamente al final exitoso, conservando ultimos 2

### D) Reporte de validación
- Tabla resumida de estado MCP después de validaciones
- Incluye: servidores, formato, consistencia, hallazgos

## Success Criteria (Post-Execution)

### SC-001: Formato consistente mantenido
- Todos los servidores siguen usando `type: "stdio"`
- Todos los `args` mantienen formato array
- No se introdujeron servidores sin comando válido

### SC-002: Sincronización documentada
- Resultados de lift-vscode.ps1 y lift-opencode.ps1 guardados
- .kit-last-sync.json creado con fases y resultados

### SC-003: Backups preservados
- Backup en .kit-backup\<timestamp>/ creado antes de modificaciones
- Backups antiguos podados (conservados ultimos 2) si éxito
- Backups originales de migración Copilot sin tocar

### SC-004: Decisiones registradas
- Elecciones del usuario (yes/no/skip/dry-run) documentadas
- Cualquier excepción o fallback notado

## Risks and Mitigations

### RI-001: Rutas hardcodeadas a tomas
- **Riesgo**: Sincronización a otras máquinas fallará por rutas inexistentes
- **Mitigación**: Documentar necesidad de normalizar rutas o usar variables de entorno

### RI-002: Commands no disponibles en PATH
- **Riesgo**: Algunos servidores (testsprite, sentry, pieces, perplexity) no iniciarán
- **Mitigación**: Validar disponibilidad antes de depender de ellos en flujos de trabajo

### RI-003: Pérdida de configuración local
- **Riesgo**: lift-vscode.ps1 podría reemplazar commands locales con los del maestro
- **Mitigación**: Usar -DryRun primero, revisar resultados. El script falla-closed si JSON resultante no parsea.

### RI-003: Backups no podados
- **Riesgo**: .kit-backup acumula muchos timestamps
- **Mitigación**: Ejecutar sync-kit-agents exitosamente para limpieza automática

## Notes for Implementation
- Todo script acepta -DryRun para probar sin escribir
- Backups se crean automáticamente en .kit-backup\<timestamp>/
- Los scripts fallan-closed: si JSON resultante no parsea, NO se escribe + ERROR
- No modificar .vscode\mcp.json manualmente sin ejecutar los scripts sincronización primero
- Las decisiones del usuario en DP-001 a DP-004 son vinculantes antes de proceeding

<context_window_protection>
  <priority_instructions>
    Every byte a tool returns enters your conversation memory and costs reasoning capacity for the rest of the session. The context-mode tools let you do the work in a sandbox and surface only the derived answer — the raw bytes stay out. Think-in-Code: program the analysis, do not compute it by reading raw data into your conversation.
  </priority_instructions>

  <tool_selection_hierarchy>
    0. MEMORY: context-mode_ctx_search(sort: "timeline")
       - On resume or compaction, query prior decisions, errors, plans, user prompts before asking the user — auto-captured session memory is searchable.
    1. GATHER: context-mode_ctx_batch_execute(commands, queries)
       - Primary research tool. Runs commands in parallel, auto-indexes each output, and (when queries are passed) returns matching sections in the same round trip — no follow-up search call.
       - Each command: {label: "section header", command: "shell command"}; the label becomes the FTS5 chunk title — descriptive labels improve search.
    2. FOLLOW-UP: context-mode_ctx_search(queries: ["q1", "q2", ...])
       - Multiple related questions about anything already indexed (your captures + session memory). Batch every question in one array; the ranking pipeline runs per-query and the round-trip cost is paid once.
    3. PROCESSING: context-mode_ctx_execute(language, code) | context-mode_ctx_execute_file(path, language, code)
       - Derive answers FROM data: filter, count, aggregate, parse, transform. Only what you console.log() enters your conversation; the raw bytes stay in the sandbox.
  </tool_selection_hierarchy>

  <when_not_to_use>
    - You intend to PROCESS the output (filter, count, parse, aggregate) → use context-mode_ctx_batch_execute or context-mode_ctx_execute. Bash stays correct when you intend to OBSERVE a short fixed output (git status on a clean tree, whoami, pwd) or when you are mutating state (git, mkdir, rm, mv, navigation).
    - You want to analyze, summarize, or extract from a file → use context-mode_ctx_execute_file. Read stays correct when you intend to Edit the file (Edit needs the exact bytes in your conversation to match against).
    - WebFetch → use context-mode_ctx_fetch_and_index; full network access, results indexed for context-mode_ctx_search, raw page bytes never enter your conversation.
    - context-mode_ctx_execute and context-mode_ctx_execute_file for file writes → these run code in a subprocess and discard the sandbox FS; they are for analysis, processing, and computation only.
  </when_not_to_use>

  <file_writing_policy>
    File writes use the native Write or Edit tool — context-mode_ctx_execute, context-mode_ctx_execute_file, and Bash subprocesses do not persist edits to the host filesystem.
    Applies to all file types: code, configs, plans, specs, YAML, JSON, markdown.
  </file_writing_policy>

  <output_constraints>
    <artifact_policy>
      Write artifacts (code, configs, PRDs) to files. Return only: file path + 1-line description.
    </artifact_policy>
  </output_constraints>
  <session_continuity>
    Skills, roles, and decisions captured earlier in this session are a memory aid, not a standing order. Treat them as context that may help — the user's most recent message always takes precedence. If a captured directive conflicts with what the user now asks, follow the user; a past phrase does not bind you.
  </session_continuity>

</context_window_protection>