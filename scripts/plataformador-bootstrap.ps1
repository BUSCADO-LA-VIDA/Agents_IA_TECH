#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# plataformador-bootstrap.ps1
# =============================================================================
# Script de preflight para proyectos que necesitan nivelarse sin IA.
# Reproduce gran parte de las tareas de un Plataformador:
#   - validar/quitar dependencias faltantes
#   - configurar el ecosistema de MCPs (VS Code + OpenCode)
#   - crear/actualizar índices de código (codebase-memory-mcp) y documentación (context-mode)
#   - verificar que los índices y MCPs funcionan correctamente
#   - preparar la estructura antes de mover archivos
#   - recargar la ventana de VS Code del proyecto cuando el usuario lo pide (solo esa ventana, sin tocar las demás)
#
# Uso:
#   .\scripts\plataformador-bootstrap.ps1
#   .\scripts\plataformador-bootstrap.ps1 -SkipInstall
#   .\scripts\plataformador-bootstrap.ps1 -NoRestart
#   .\scripts\plataformador-bootstrap.ps1 -DryRun
#   .\scripts\plataformador-bootstrap.ps1 -SkipIndexing
#   .\scripts\plataformador-bootstrap.ps1 -VerifyOnly
#   .\scripts\plataformador-bootstrap.ps1 -SyncOnly [-DryRun] [-Force] [-RepoUrl <url>] [-OrphanAction Borrar|Conservar|Preguntar]  # delegación sync-agents
#   .\scripts\plataformador-bootstrap.ps1 -App <app> [-DryRun]  # app activa explícita
#   .\scripts\plataformador-bootstrap.ps1 [-GraphifyDeep] [-GraphifyScope App|Workspace]  # Graphify deep (LLM) / scope del grafo
#   .\scripts\plataformador-bootstrap.ps1 -SkipSelfUpdate  # saltar auto-actualización desde el maestro
# Requisito: PowerShell 7+ (pwsh ≥ 7). No funciona en Windows PowerShell 5.1.
#   Recomendación (solo texto, ejecutar manualmente si aplica):
#     winget install --id Microsoft.PowerShell --source winget
# =============================================================================

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipInstall,
    [switch]$NoRestart,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipIndexing,
    [switch]$VerifyOnly,
    [switch]$SyncOnly,
    [string]$App = "",
    [string[]]$Apps = @(),
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$ManifestPath = "",
    [string]$OrphanAction = "Preguntar",
    # [BOOTSTRAP-FIXES] F6: -GraphifyDeep -> graphify extract --mode deep (LLM);
    # -GraphifyScope App (default) = app activa / Workspace = raíz del proyecto.
    [ValidateSet("App", "Workspace")]
    [string]$GraphifyScope = "App",
    [switch]$GraphifyDeep,
    # [SELF-UPDATE] flag para saltar el mecanismo.
    [switch]$SkipSelfUpdate,
    # [007-MCP] RF-04/D3: instala/actualiza herramientas externas (fail-open,
    # opt-in). Sin el flag no se intenta ninguna instalación.
    [switch]$ForceUpgradeTools,
    # [007-MCP] RF-06/D5: "modo kit seguro" — salta Sync-TransversalKit pero
    # ejecuta el resto (resolución MCP, .env.mcp, índices). Permite activar los
    # MCPs en el kit maestro sin que el sync lo sobrescriba a sí mismo.
    [switch]$SkipSync
)

$ErrorActionPreference = "Stop"

# [BOOTSTRAP-FIXES] F5: acumulación de WARNs/ERRORs para el cuadro resumen final.
$script:Warnings = [System.Collections.Generic.List[string]]::new()
$script:Errors = [System.Collections.Generic.List[string]]::new()
# [BOOTSTRAP-FIXES] F4: WARNs ya emitidos (dedup tokenslayer paso 1/paso 4).
$script:EmittedWarns = [System.Collections.Generic.List[string]]::new()

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
# [BOOTSTRAP-FIXES] F5: Write-Warn/Write-Fail acumulan en $script:Warnings/$script:Errors.
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow; $script:Warnings.Add($Message) | Out-Null }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red; $script:Errors.Add($Message) | Out-Null }

# [BOOTSTRAP-FIXES] F4: WARN deduplicado — si el mismo texto ya se mostró, no repite.
function Write-WarnOnce {
    param([string]$Message)
    if ($script:EmittedWarns -contains $Message) { return }
    $script:EmittedWarns.Add($Message) | Out-Null
    Write-Warn $Message
}

# [BOOTSTRAP-FIXES] F5: cuadro resumen final (conteo + listas deduplicadas).
function Show-ExecutionSummary {
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " RESUMEN DE LA EJECUCION" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " WARNs: $($uniqueWarns.Count)"
    foreach ($w in $uniqueWarns) { Write-Host "   - $w" }
    Write-Host " ERRORs: $($uniqueErrors.Count)"
    foreach ($e in $uniqueErrors) { Write-Host "   - $e" }
    Write-Host " Rutas MCP en .env.mcp - consulta ese archivo (gitignored)." -ForegroundColor DarkGray
    Write-Host "===============================================================" -ForegroundColor Yellow
}

# =============================================================================
# Configuración del instalador/actualizador único (ADR-0003)
# [SOLUCION-GENERICA] RF-S3: sin lista fija de dominio. La lista de apps se
# resuelve por proyecto: flag -Apps explícito > manifest del proyecto >
# descubrimiento src/* > lista vacía + WARN (nunca hardcodeada).

# Resuelve la lista de apps del proyecto (RF-S3/RF-S5):
# 1) manifest del proyecto (sección `aplicaciones:` activa); 2) descubrimiento
# de directorios bajo src/; 3) lista vacía + WARN si no hay nada.
function Resolve-AppList {
    param([string]$RootPath = "")
    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }
    $fromManifest = @(Read-DependenciasManifest -RootPath $RootPath | ForEach-Object { $_.Nombre })
    if ($fromManifest.Count -gt 0) { return @($fromManifest) }
    $srcDir = Join-Path $RootPath "src"
    if (Test-Path -LiteralPath $srcDir) {
        # [BOOTSTRAP-FIXES] F2: directorios punto no son apps (.specify, .git,
        # .venv, .idea): sin este filtro src/.specify se levanta como app y
        # Prepare-Apps/Ensure-SrcAppStructure la tratan como tal.
        $found = @(Get-ChildItem -LiteralPath $srcDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Name.StartsWith(".") } |
            ForEach-Object { $_.Name })
        if ($found.Count -gt 0) { return @($found) }
    }
    Write-Warn "Sin apps en manifest ni en src/; lista vacía (pasa -Apps explícito o define `aplicaciones:` en tu manifest local)."
    return @()
}

# Allowlist de owners de confianza para validar URLs (fail-closed).
# Solo se permite https://github.com/<owner-en-allowlist>/<repo>
# [SOLUCION-GENERICA] RF-S1/RF-S5: owners personales del autor fuera del kit
# genérico (cada proyecto añade los suyos en su copia local si aplica).
$TrustedOwners = @(
    "BUSCADO-LA-VIDA",
    "github",
    "microsoft",
    "DeusData",
    "mksglu"
)

function Test-TrustedGithubUrl {
    param([string]$Url)
    # Solo https://github.com/<owner>/<repo> con owner en allowlist
    if ($Url -notmatch '^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$') {
        return $false
    }
    $owner = $matches[1]
    return $TrustedOwners -contains $owner
}

function Assert-ManifestApps {
    param([hashtable[]]$Apps)
    foreach ($a in $Apps) {
        if (-not (Test-TrustedGithubUrl $a.Url)) {
            throw "[SECURITY] URL no permitida para app '$($a.Nombre)': $($a.Url) (fail-closed: solo https://github.com/<owner en allowlist>/<repo>)"
        }
        if ($a.Licencia -match 'pendiente|desconocida|⚠️') {
            Write-Warn "Licencia de '$($a.Nombre)' pendiente/desconocida ($($a.Licencia)). NO se integra sin verificar (guardrail 8)."
        }
    }
}

function Read-DependenciasManifest {
    param([string]$RootPath)
    if ($ManifestPath) {
        $manifestFile = $ManifestPath
    } else {
        $manifestFile = Join-Path $RootPath "dependencias-manifest.yml"
    }
    if (-not (Test-Path $manifestFile)) {
        Write-Warn "No existe dependencias-manifest.yml en $manifestFile; no se preparan apps."
        return @()
    }
    $content = Get-Content -Path $manifestFile -Raw
    # Solo la sección `aplicaciones:` (no `dependencias_externas`: herramientas
    # como spec-kit/markitdown no son apps). Sin sección activa -> @().
    $mSection = [regex]::Match($content, '(?ms)^aplicaciones:\s*\r?\n(.*)$')
    if (-not $mSection.Success) { return @() }
    $section = $mSection.Groups[1].Value
    $apps = @()
    foreach ($m in [regex]::Matches($section, '(?ms)^  - nombre:\s*(\S+)\s*\r?\n    url:\s*(\S+)\s*\r?\n    rama:\s*(\S+)\s*\r?\n(?:.*?)\r?\n    licencia:\s*(.+?)\s*$')) {
        # [SOLUCION-GENERICA] RF-S3/RF-S5: el manifest del PROYECTO manda;
        # sin filtro por lista fija (el kit genérico no conoce apps concretas).
        $apps += @{ Nombre = $m.Groups[1].Value; Url = $m.Groups[2].Value; Rama = $m.Groups[3].Value; Licencia = $m.Groups[4].Value }
    }
    return $apps
}

function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Command,
        [string[]]$Args = @(),
        [switch]$AllowFailure
    )

    if ($DryRun) {
        Write-Info "DryRun: $Command $($Args -join ' ')"
        return $null
    }

    try {
        & $Command @Args 2>&1 | Out-String
        return $LASTEXITCODE
    }
    catch {
        if (-not $AllowFailure) {
            throw $_
        }
        Write-Warn "Comando falló sin romper el flujo: $Command $($Args -join ' ')"
        return 1
    }
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        if ($DryRun) {
            Write-Info "DryRun: crear directorio $Path"
        } else {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        Write-OK "Directorio listo: $Path"
    }
}

function Ensure-JsonFile {
    param(
        [string]$Path,
        [object]$Content
    )

    if ($DryRun) {
        Write-Info "DryRun: asegurar JSON en $Path"
        return
    }

    if (-not (Test-Path $Path) -or $Force) {
        $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        Write-OK "JSON creado/actualizado: $Path"
    }
}

function Ensure-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    if ($DryRun) {
        Write-Info "DryRun: asegurar texto en $Path"
        return
    }

    if (-not (Test-Path $Path) -or $Force) {
        Set-Content -Path $Path -Value $Content -Encoding UTF8
        Write-OK "Archivo creado/actualizado: $Path"
    }
}

function Ensure-Command {
    param(
        [string]$Name,
        [string]$InstallCommand,
        [switch]$AllowMissing
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-OK "Comando disponible: $Name -> $($cmd.Source)"
        return $true
    }

    if ($SkipInstall) {
        Write-Warn "Se omite instalación de '$Name' porque -SkipInstall está activo."
        return $false
    }

    if ($DryRun) {
        Write-Info "DryRun: instalar '$Name' usando: $InstallCommand"
        return $false
    }

    Write-Step "Instalando '$Name'..."
    $result = Invoke-Expression $InstallCommand
    $cmdAfter = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmdAfter) {
        if ($AllowMissing) {
            Write-Warn "No quedó disponible '$Name' inmediatamente, pero el flujo continúa."
            return $false
        }
        throw "El comando '$Name' sigue sin estar disponible después de la instalación."
    }

    Write-OK "Comando instalado: $Name"
    return $true
}

function Ensure-McpJson {
    param([string]$RootPath)

    $mcpPath = Join-Path $RootPath ".vscode\mcp.json"
    $mcpDir = Split-Path $mcpPath -Parent
    Ensure-Directory $mcpDir

    if (-not (Test-Path $mcpPath) -or $Force) {
        $payload = [ordered]@{
            servers = [ordered]@{
                markitdown = [ordered]@{
                    command = "markitdown-mcp"
                    type = "stdio"
                }
                "codebase-memory-mcp" = [ordered]@{
                    command = "codebase-memory-mcp"
                    type = "stdio"
                }
                "context-mode" = [ordered]@{
                    command = "context-mode"
                    type = "stdio"
                }
            }
        }

        if ($DryRun) {
            Write-Info "DryRun: crear .vscode/mcp.json con servidores markitdown, codebase-memory-mcp y context-mode"
            return
        }

        $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $mcpPath -Encoding UTF8
        Write-OK "Configuración de MCP registrada: $mcpPath"
    } else {
        Write-OK "Ya existe .vscode/mcp.json; se conserva y se valida la configuración actual."
    }
}

# [SOLUCION-GENERICA] RF-S6: re-resuelve un comando MCP a su ruta real en
# runtime local (Get-Command). Si no resuelve -> $null + WARN degradado
# (el caller deja el token con enabled=false y pide ejecutar el bootstrap).
# Nunca amplía permission.bash ni commitea rutas reales.
function Resolve-McpCommand {
    param([string]$ToolName, [string]$Token)
    $found = Get-Command $ToolName -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    Write-Warn "MCP '$ToolName' sin resolver ($Token): ejecuta el bootstrap tras instalar la herramienta; se deja degradado (enabled=false)."
    return $null
}

# [007-MCP] D2/RF-03: fuente de rutas MCP portable por proyecto (`.env.mcp`).
# Crea <root>/.env.mcp si no existe (idempotente; con -Force re-escribe) con
# CONTEXT_MODE_CMD/CODEBASE_MEMORY_CMD/MARKITDOWN_CMD resueltas en runtime local
# vía Resolve-McpCommand. `.env.mcp` es la fuente de verdad legible/portable
# (nunca versionada; se agrega a .gitignore); el mecanismo efectivo en OpenCode
# es `environment`/ruta real (ver Ensure-OpenCodeMcp). Sin secretos: solo rutas.
function Ensure-McpEnvFile {
    param(
        [string]$RootPath,
        [switch]$Force
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    $envPath = Join-Path $RootPath ".env.mcp"

    # Idempotencia (RF-02): si ya existe y no es -Force, se conserva.
    if ((Test-Path -LiteralPath $envPath) -and (-not $Force)) {
        Write-OK ".env.mcp ya existe; se conserva (usa -Force para re-escribir)."
        # El guard de .gitignore se aplica siempre (por si el archivo existía sin regla).
        Add-McpEnvGitignore -RootPath $RootPath
        return
    }

    if ($DryRun) {
        Write-Info "DryRun: crear $envPath con CONTEXT_MODE_CMD/CODEBASE_MEMORY_CMD/MARKITDOWN_CMD (rutas resueltas)."
        Add-McpEnvGitignore -RootPath $RootPath
        return
    }

    $tools = [ordered]@{
        "CONTEXT_MODE_CMD"    = "context-mode"
        "CODEBASE_MEMORY_CMD" = "codebase-memory-mcp"
        "MARKITDOWN_CMD"      = "markitdown"
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# [007-MCP] Rutas MCP resueltas localmente (NO se versiona; gitignored).") | Out-Null
    $lines.Add("# Fuente de verdad portable. OpenCode referencia {env:<NAME>} en opencode.json.") | Out-Null
    foreach ($var in @($tools.Keys)) {
        # Placeholders vacíos; la resolución real ocurre en Ensure-OpenCodeMcp
        $lines.Add("$var=") | Out-Null
    }
    Set-Content -LiteralPath $envPath -Value $lines -Encoding UTF8
    Write-OK ".env.mcp creado con plantilla básica (valores vacíos; se resuelven en Ensure-OpenCodeMcp): $envPath"
    Add-McpEnvGitignore -RootPath $RootPath
}

# [007-MCP] D2: Actualiza .env.mcp con las rutas MCP resueltas.
# Mantiene la plantilla básica + valores resueltos. Idempotente.
function Update-McpEnvFile {
    param(
        [string]$RootPath,
        [System.Collections.Specialized.OrderedDictionary]$McpReasons,
        [System.Collections.Specialized.OrderedDictionary]$TokenMap,
        $ExistingMcp,
        [bool]$McpIsDict
    )

    $envPath = Join-Path $RootPath ".env.mcp"
    if (-not (Test-Path -LiteralPath $envPath)) {
        # Si no existe, lo crea Ensure-McpEnvFile en el paso 1
        return
    }

    # Leer el contenido actual
    $currentLines = @(Get-Content -LiteralPath $envPath -ErrorAction SilentlyContinue)
    $updatedLines = [System.Collections.Generic.List[string]]::new()
    $hasHeader = $false

    foreach ($line in $currentLines) {
        if ($line -match '^#') {
            $updatedLines.Add($line) | Out-Null
            $hasHeader = $true
            continue
        }
        if ($line -match '^\s*(\w+)\s*=\s*(.*)$') {
            $varName = $Matches[1]
            $currentValue = $Matches[2].Trim()
            # Si ya tiene valor y no es un placeholder vacío, conservarlo
            # Si está vacío, intentar usar la ruta resuelta del MCP correspondiente
            if (-not [string]::IsNullOrWhiteSpace($currentValue)) {
                $updatedLines.Add("$varName=$currentValue") | Out-Null
            } else {
                # Buscar la ruta resuelta en el mcp actualizado
                $resolvedPath = $null
                foreach ($name in @($TokenMap.Keys)) {
                    if ($TokenMap[$name].Var -eq $varName) {
                        $entry = $null
                        if ($McpIsDict -and $ExistingMcp.Contains($name)) {
                            $entry = $ExistingMcp[$name]
                        } elseif (-not $McpIsDict) {
                            $entry = $ExistingMcp.PSObject.Properties[$name]
                        }
                        if ($entry -and $entry.Value.command) {
                            $resolvedPath = @($entry.Value.command)[0]
                        }
                        break
                    }
                }
                if ($resolvedPath) {
                    $updatedLines.Add("$varName=$resolvedPath") | Out-Null
                } else {
                    $updatedLines.Add("$varName=") | Out-Null
                }
            }
        } else {
            $updatedLines.Add($line) | Out-Null
        }
    }

    # Si no tenía header, agregar uno básico
    if (-not $hasHeader) {
        $headerLines = [System.Collections.Generic.List[string]]::new()
        $headerLines.Add("# [007-MCP] Rutas MCP resueltas localmente (NO se versiona; gitignored).") | Out-Null
        $headerLines.Add("# Fuente de verdad portable. OpenCode referencia {env:<NAME>} en opencode.json.") | Out-Null
        $updatedLines = $headerLines + $updatedLines
    }

    Set-Content -LiteralPath $envPath -Value $updatedLines -Encoding UTF8
    Write-OK ".env.mcp actualizado con rutas MCP resueltas: $envPath"
}

# [007-MCP] D2/T303: agrega `.env.mcp` a .gitignore con append idempotente
# (guard anti-duplicado). Fail-open: si no hay .gitignore o falla, WARN y sigue.
function Add-McpEnvGitignore {
    param([string]$RootPath)
    $giPath = Join-Path $RootPath ".gitignore"
    try {
        $hasEntry = $false
        if (Test-Path -LiteralPath $giPath) {
            $giText = Get-Content -LiteralPath $giPath -Raw -ErrorAction Stop
            if ($giText -match '(?m)^\s*\.env\.mcp\s*$') { $hasEntry = $true }
        }
        if ($hasEntry) { return }
        if ($DryRun) {
            Write-Info "DryRun: agregar '.env.mcp' a .gitignore"
            return
        }
        $entry = [Environment]::NewLine + "# [007-MCP] rutas MCP locales (nunca versionar)" + [Environment]::NewLine + ".env.mcp" + [Environment]::NewLine
        Add-Content -LiteralPath $giPath -Value $entry -Encoding UTF8
        Write-OK ".env.mcp agregado a .gitignore"
    } catch {
        Write-Warn "No se pudo actualizar .gitignore con '.env.mcp': $_"
    }
}

function Ensure-OpenCodeMcp {
    param([string]$RootPath)

    $opencodePath = Join-Path $RootPath "opencode.json"
    
    if (-not (Test-Path $opencodePath)) {
        Write-Warn "No existe opencode.json en $RootPath; se omite configuración de MCP para OpenCode."
        return
    }

# Leer el JSON existente
    $existing = Get-Content -Path $opencodePath -Raw | ConvertFrom-Json

    # [007-MCP] D1/RF-01: la sección `mcp` se crea si falta; si ya existe, NO se
    # emite un early "se conserva" que salte la re-resolución (bug previo). La
    # re-resolución de tokens corre SIEMPRE más abajo (fuera de este if/else).
    if ($existing.mcp -and -not $Force) {
        Write-Info "opencode.json ya tiene sección mcp; se re-resuelven tokens a rutas locales (se conserva el resto)."
    } else {
        # [SOLUCION-GENERICA] RF-S6 + [007-MCP] D2: plantilla con tokens `{env:...}`
        # + degradada con enabled=false. Sin rutas absolutas versionadas; la
        # resolución runtime (Fase de re-resolución) la promueve a enabled=true.
        # No amplía permission.bash.
        $mcpConfig = [ordered]@{
            "context-mode" = [ordered]@{
                type = "local"
                command = @("{env:CONTEXT_MODE_CMD}")
                enabled = $false
            }
            "codebase-memory-mcp" = [ordered]@{
                type = "local"
                command = @("{env:CODEBASE_MEMORY_CMD}")
                enabled = $false
            }
            "markitdown" = [ordered]@{
                type = "local"
                command = @("{env:MARKITDOWN_CMD}")
                enabled = $false
            }
        }
        Write-Warn "Plantilla MCP con {env:...} (ejecuta el bootstrap para resolver a rutas locales)."

        if (-not $DryRun) {
            $existing | Add-Member -NotePropertyName "mcp" -NotePropertyValue $mcpConfig -Force
            Write-OK "Sección mcp agregada a opencode.json"
        } else {
            Write-Info "DryRun: agregar sección mcp a opencode.json"
        }
    }

    # [007-MCP] D1/RF-01/RF-02: re-resolución SIEMPRE (corre exista o no la
    # sección mcp, con o sin -Force). Parche QUIRÚRGICO por entrada: solo toca
    # `command` y `enabled`; preserva type/environment/cwd/timeout/permission/
    # providers/model/region/plugin. Idempotente.
    #   - token `__*_CMD__`  -> sustituye por ruta real + enabled=true
    #   - `{env:<VAR>}`      -> resuelve de `.env.mcp`/entorno; A5: var vacía o
    #                           ausente = NO resuelto -> ruta real + enabled=true
    #   - ruta real válida    -> NO se toca (retrocompatibilidad)
    $tokenMap = [ordered]@{
        "context-mode"        = @{ Tool = "context-mode";        Var = "CONTEXT_MODE_CMD";    Token = "__CONTEXT_MODE_CMD__" }
        "codebase-memory-mcp" = @{ Tool = "codebase-memory-mcp"; Var = "CODEBASE_MEMORY_CMD"; Token = "__CODEBASE_MEMORY_CMD__" }
        "markitdown"          = @{ Tool = "markitdown";          Var = "MARKITDOWN_CMD";      Token = "__MARKITDOWN_CMD__" }
    }
    $mcpReasons = [ordered]@{}

    # Lee una variable desde `.env.mcp` (fuente de verdad portable).
    $readEnvMcp = {
        param([string]$VarName)
        $envFile = Join-Path $RootPath ".env.mcp"
        if (-not (Test-Path -LiteralPath $envFile)) { return $null }
        try {
            foreach ($ln in (Get-Content -LiteralPath $envFile -ErrorAction Stop)) {
                if ($ln -match "^\s*$([regex]::Escape($VarName))\s*=\s*(.*)$") {
                    $val = $Matches[1].Trim()
                    if ($val) { return $val }
                }
            }
        } catch { }
        return $null
    }

    # [007-MCP] Determinar si mcp es diccionario (para acceso correcto a propiedades)
    $mcpIsDict = $false
    if ($null -ne $existing.mcp) {
        $mcpIsDict = $existing.mcp -is [System.Collections.IDictionary]
    }

    if ($null -ne $existing.mcp) {
        # [007-MCP] BUG-1: `$existing.mcp` puede ser PSCustomObject (leído de
        # JSON) o OrderedDictionary/IDictionary (recién creado arriba). Sobre un
        # IDictionary, `PSObject.Properties[$name]` devuelve $null (expone
        # meta-propiedades Count/Keys/...), de modo que la re-resolución se
        # saltaba TODAS las entradas en el path de creación fresca. Se accede
        # por indexer cuando es diccionario (mismo patrón que tokenslayer L614).
        foreach ($name in @($tokenMap.Keys)) {
            if ($mcpIsDict) {
                if (-not $existing.mcp.Contains($name)) { continue }
                $entry = [pscustomobject]@{ Value = $existing.mcp[$name] }
            } else {
                $entry = $existing.mcp.PSObject.Properties[$name]
            }
            if ($null -eq $entry) { continue }
            $cmd0 = @($entry.Value.command)[0]

            $needsResolve = $false
            if ($cmd0 -eq $tokenMap[$name].Token) {
                $needsResolve = $true
            } elseif ($cmd0 -and ($cmd0 -match '^\{env:([^}]+)\}$')) {
                $envVar = $Matches[1]
                $valProc = [Environment]::GetEnvironmentVariable($envVar)
                $valFile = & $readEnvMcp $envVar
                if ([string]::IsNullOrWhiteSpace($valProc) -and [string]::IsNullOrWhiteSpace($valFile)) {
                    # A5: {env:...} con var vacía/ausente cuenta como NO resuelto.
                    $needsResolve = $true
                } else {
                    # Var disponible -> se conserva {env:...} y se promueve a true.
                    if (-not $entry.Value.enabled) {
                        if (-not $DryRun) { $entry.Value.enabled = $true }
                        $mcpReasons[$name] = "env resuelto ($envVar)"
                    }
                }
            } elseif ([string]::IsNullOrWhiteSpace($cmd0)) {
                $needsResolve = $true
            }

            if (-not $needsResolve) {
                if (-not $mcpReasons.Contains($name)) {
                    if ($entry.Value.enabled) { $mcpReasons[$name] = "ruta real valida (sin cambios)" }
                    else { $mcpReasons[$name] = "deshabilitado (sin cambios)" }
                }
                continue
            }

            $real = Resolve-McpCommand -ToolName $tokenMap[$name].Tool -Token $tokenMap[$name].Token
            if ($real) {
                if ($DryRun) {
                    $mcpReasons[$name] = "resolveria a ruta local ($real)"
                    Write-Info "DryRun: MCP '$name' -> $real (enabled=true)"
                } else {
                    $entry.Value.command = @($real)
                    $entry.Value.enabled = $true
                    $mcpReasons[$name] = "ruta resuelta"
                    Write-OK "MCP '$name' re-resuelto a ruta local."
                }
            } else {
                if (-not $DryRun) {
                    if ($cmd0 -eq $tokenMap[$name].Token) {
                        $entry.Value.command = @("{env:$($tokenMap[$name].Var)}")
                    }
                    $entry.Value.enabled = $false
                }
                $mcpReasons[$name] = "herramienta ausente ($($tokenMap[$name].Tool)); enabled=false"
            }
        }
    }

    # RF-16: registrar tokenslayer como 4º MCP (fuente del binario: entrada
    # tokenslayer-mcp-server en dependencias-manifest.yml).
    # Controles (seguridad/kit-gaps.md §§1.2/5, no negociables): node vía
    # Get-Command (si falta -> WARN + se omite tokenslayer, no falla);
    # containment-check (la ruta registrada queda bajo
    # <root>/proyect_ext/tokenslayer/, nada de .. ni rutas externas); sin
    # binario build/index.js -> WARN con instrucciones de clonar+compilar y NO
    # se registra la entrada (evita config rota); jamás auto-compila (npm
    # install ejecuta código de terceros). Estilo existente intacto
    # (Add-Member -Force, Write-*, $DryRun/$Force).
    if ($null -ne $existing.mcp) {
        if (($null -ne $existing.mcp.tokenslayer) -and (-not $Force)) {
            Write-OK "opencode.json ya registra tokenslayer; se conserva (usa -Force para sobrescribir)."
        } else {
            $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
            if (-not $nodeCmd) {
                # [BOOTSTRAP-FIXES] F4: Write-WarnOnce (Ensure-OpenCodeMcp corre en
                # paso 1 y paso 4; sin dedup el WARN de tokenslayer sale duplicado).
                Write-WarnOnce "node no está en el PATH; se omite tokenslayer (instala Node.js y re-ejecuta para registrar el 4º MCP)."
            } else {
                $tokenslayerBase = Join-Path $RootPath "proyect_ext\tokenslayer"
                $tokenslayerIndex = Join-Path $tokenslayerBase "mcp-server\build\index.js"
                $sepTok = [IO.Path]::DirectorySeparatorChar
                $baseCanonTok = [IO.Path]::GetFullPath($tokenslayerBase)
                $indexCanonTok = [IO.Path]::GetFullPath($tokenslayerIndex)
                if (-not $indexCanonTok.StartsWith($baseCanonTok + $sepTok, [StringComparison]::OrdinalIgnoreCase)) {
                    # [BOOTSTRAP-FIXES] F4: Write-WarnOnce (dedup paso 1/paso 4).
                    Write-WarnOnce "Ruta de tokenslayer fuera de containment ($tokenslayerIndex); no se registra (fail-closed)."
                } elseif (-not (Test-Path -LiteralPath $tokenslayerIndex)) {
                    # [BOOTSTRAP-FIXES] F4: Write-WarnOnce (dedup paso 1/paso 4).
                    Write-WarnOnce "tokenslayer sin compilar: falta mcp-server/build/index.js bajo proyect_ext/tokenslayer/. Para registrar el 4º MCP: clona https://github.com/ajvikram/TokenSlayer (ver entrada tokenslayer-mcp-server en dependencias-manifest.yml) en proyect_ext/tokenslayer y compila con: cd proyect_ext/tokenslayer/mcp-server && npm install && npm run build. No se registra la entrada (evita config rota); el bootstrap continúa."
                } elseif ($DryRun) {
                    $relIndexTok = ([IO.Path]::GetRelativePath($RootPath, $indexCanonTok)) -replace '\\', '/'
                    Write-Info "DryRun: registraría tokenslayer en opencode.json (type: local, command: [$($nodeCmd.Source), $relIndexTok], enabled: true)"
                } else {
                    $tokenslayerEntry = [ordered]@{
                        type = "local"
                        command = @($nodeCmd.Source, $indexCanonTok)
                        enabled = $true
                    }
                    # $existing.mcp puede ser PSCustomObject (leído de JSON) o
                    # OrderedDictionary (recién creado arriba): Add-Member sobre
                    # un IDictionary NO se serializa (ConvertTo-Json solo
                    # enumera entradas), así que en ese caso se agrega entrada.
                    if ($existing.mcp -is [System.Collections.IDictionary]) {
                        $existing.mcp["tokenslayer"] = $tokenslayerEntry
                    } else {
                        $existing.mcp | Add-Member -NotePropertyName "tokenslayer" -NotePropertyValue $tokenslayerEntry -Force
                    }
                    Write-OK "tokenslayer registrado como 4º MCP en opencode.json"
                }
            }
        }
    }

    # Plugin de context-mode (falta el array `plugin` según ctx_doctor)
    $hasPlugin = $false
    foreach ($p in @($existing.plugin)) { if ($p -eq "context-mode") { $hasPlugin = $true } }
    if (-not $hasPlugin -and -not $DryRun) {
        $currentPlugins = @(@($existing.plugin) | Where-Object { $_ -ne $null -and $_ -ne "" })
        if ("context-mode" -notin $currentPlugins) { $currentPlugins += "context-mode" }
        $existing | Add-Member -NotePropertyName "plugin" -NotePropertyValue @($currentPlugins) -Force
        Write-OK "Plugin de context-mode agregado a opencode.json"
    } elseif (-not $hasPlugin) {
        Write-Info "DryRun: agregar plugin de context-mode a opencode.json"
    }

    if (-not $DryRun) {
        # [007-MCP] CN-8/CN-9: serializar y VALIDAR el JSON antes de escribir
        # (no corromper opencode.json). Fail-open: si el round-trip falla, se
        # conserva el archivo original + WARN.
        $jsonOut = $existing | ConvertTo-Json -Depth 10
        $validJson = $true
        try {
            $null = $jsonOut | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $validJson = $false
            Write-Warn "El JSON resultante no es válido; se conserva opencode.json intacto (no se escribe). $_"
        }
        if ($validJson) {
            Set-Content -Path $opencodePath -Value $jsonOut -Encoding UTF8
        }
    }

    # [007-MCP] D2: Actualizar .env.mcp con las rutas resueltas (fuente de verdad portable)
    if (-not $DryRun) {
        Update-McpEnvFile -RootPath $RootPath -McpReasons $mcpReasons -TokenMap $tokenMap -ExistingMcp $existing.mcp -McpIsDict $mcpIsDict
    }

    # [007-MCP] D7/RF-08/CN-11: reporte final del bloque mcp resultante + estado
    # provisto por entrada. Solo rutas locales y nombres; SIN secretos.
    $reportReasons = [ordered]@{}
    if ($mcpReasons) { foreach ($k in @($mcpReasons.Keys)) { $reportReasons[$k] = $mcpReasons[$k] } }
    Write-Host ""
    Write-Host "  --- MCPs en opencode.json (estado por entrada) ---" -ForegroundColor Cyan
    if ($null -ne $existing.mcp) {
        # [007-MCP] BUG-2: enumerar según el tipo real de `mcp`. Sobre un
        # OrderedDictionary, `PSObject.Properties` lista meta-propiedades
        # (Count/Keys/Values/...) en vez de las entradas reales. Con -is
        # [IDictionary] se itera por Keys (mismo patrón que BUG-1/L614).
        if ($existing.mcp -is [System.Collections.IDictionary]) {
            $mcpEntries = @($existing.mcp.Keys | ForEach-Object { [pscustomobject]@{ Name = $_; Value = $existing.mcp[$_] } })
        } else {
            $mcpEntries = @($existing.mcp.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } })
        }
        foreach ($prop in $mcpEntries) {
            $nm = $prop.Name
            $en = [bool]$prop.Value.enabled
            $cmd0R = @($prop.Value.command)[0]
            $reason = ""
            if ($reportReasons.Contains($nm)) { $reason = $reportReasons[$nm] }
            elseif ($en) { $reason = "resuelto" }
            else { $reason = "deshabilitado" }
            $color = if ($en) { "Green" } else { "DarkYellow" }
            Write-Host ("    - {0}: enabled={1} ({2})" -f $nm, $en, $reason) -ForegroundColor $color
        }
    } else {
        Write-Host "    (sin sección mcp)" -ForegroundColor DarkGray
    }
}

# =============================================================================
# Ensure-OpenCodeConfig (RF-17 / criterio 13: plantilla .opencode/config.json)
# =============================================================================
# Crea .opencode/config.json SOLO si no existe, desde una plantilla con
# PLACEHOLDERS inconfundibles (__PEGAR_AQUI_TU_...__, nunca valores reales ni
# con formato válido). Si existe -> no lo toca NUNCA (ni para "actualizar la
# plantilla": pisaría keys reales). Estructura de ejemplo derivada de las keys
# que opencode.json referencia vía {env:...} (NVIDIA_API_KEY,
# DEEPINFRA_API_KEY), SIN copiar valores reales.
# Controles (seguridad/kit-gaps.md §§1.1/5, no negociables): aviso inline de no
# commitear en la plantilla; verifica que está gitignored (avisa si no);
# detección defensiva: si está trackeado por git -> WARN con git rm --cached +
# rotar keys; -DryRun informa, no escribe. Estilo: hashtables para construir,
# Add-Member -Force si hay que tocar PSObjects; NUNCA asignación directa de
# props nuevas (bug conocido de este entorno).
function Ensure-OpenCodeConfig {
    param([string]$RootPath)

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    $configRel = ".opencode/config.json"
    $configPath = Join-Path $RootPath ".opencode\config.json"

    # ¿Trackeado por git? (solo lectura; si no hay git, se asume no trackeado)
    $tracked = $false
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $lsOut = & git -C $RootPath ls-files -- $configRel 2>$null
            if ($lsOut) { $tracked = $true }
        }
    } catch { $tracked = $false }

    # ¿Gitignored? (texto de .gitignore + git check-ignore si hay git)
    $ignored = $false
    try {
        $giPath = Join-Path $RootPath ".gitignore"
        if (Test-Path -LiteralPath $giPath) {
            $giText = Get-Content -LiteralPath $giPath -Raw -ErrorAction Stop
            if ($giText -match '\.opencode/config\.json') { $ignored = $true }
        }
    } catch { $ignored = $false }
    if (-not $ignored) {
        try {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                & git -C $RootPath check-ignore -q -- $configRel 2>$null
                if ($LASTEXITCODE -eq 0) { $ignored = $true }
            }
        } catch { $ignored = $false }
    }

    if (Test-Path -LiteralPath $configPath) {
        Write-OK "$configRel ya existe; no se toca nunca (conserva tus keys locales)."
        if (-not $ignored) {
            Write-Warn "$configRel NO está gitignored: no hacer commit (contiene posibles secrets). Revisa .gitignore."
        }
        if ($tracked) {
            Write-Warn "$configRel está TRACKEADO por git (posibles secrets versionados): ejecuta git rm --cached $configRel y ROTA las keys (borrar no basta, quedan en el historial)."
        }
        return
    }

    if ($DryRun) {
        Write-Info "DryRun: crearía $configRel desde plantilla con PLACEHOLDERS (sin secrets reales)."
        if (-not $ignored) {
            Write-Warn "DryRun: $configRel NO está gitignored; debe estarlo antes de rellenar la plantilla."
        }
        return
    }

    $configParent = Split-Path $configPath -Parent
    if (-not (Test-Path -LiteralPath $configParent)) {
        New-Item -ItemType Directory -Path $configParent -Force | Out-Null
    }

    $configTemplate = [ordered]@{
        _AVISO = "Archivo LOCAL con credenciales. NO commitear (gitignored: .opencode/config.json). Si se versionó por error: git rm --cached .opencode/config.json + ROTAR las keys."
        NVIDIA_API_KEY = "__PEGAR_AQUI_TU_NVIDIA_API_KEY__"
        DEEPINFRA_API_KEY = "__PEGAR_AQUI_TU_DEEPINFRA_API_KEY__"
        GITHUB_TOKEN = "__PEGAR_AQUI_TU_GITHUB_TOKEN_OPCIONAL__"
    }
    $configTemplate | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-OK "Plantilla creada: $configRel (rellena los __PEGAR_AQUI_TU_...__ a mano; nunca commitear con valores reales)."
    if (-not $ignored) {
        Write-Warn "$configRel NO está gitignored: no hacer commit (contiene posibles secrets). Revisa .gitignore."
    }
    if ($tracked) {
        Write-Warn "$configRel está TRACKEADO por git (posibles secrets versionados): ejecuta git rm --cached $configRel y ROTA las keys (borrar no basta, quedan en el historial)."
    }
}

# =============================================================================
# Move-SingleDocFile (helper interno de RF-18: movido transaccional por archivo)
# =============================================================================
# Mueve UN .md de raíz a Documentacion/<App>/: si el destino existe -> no
# sobrescribe (omite); si Move-Item falla por lock -> omite + informa ("cierra
# el editor/indexador y reintenta") + continúa el llamante; tras mover verifica
# (destino existe + origen ausente) y si falla intenta rollback concreto (mover
# de vuelta) dejando el original en su sitio. Nunca borra. Devuelve "Moved",
# "OmittedExists", "OmittedLock" u "OmittedVerify". Logs con rutas relativas.
function Move-SingleDocFile {
    param(
        [string]$SourceFull = "",
        [string]$DestFull = "",
        [string]$DisplayName = "",
        [string]$DestRel = ""
    )

    if (-not $DisplayName) { $DisplayName = Split-Path $SourceFull -Leaf }
    if (-not $DestRel) { $DestRel = $DisplayName }

    if (Test-Path -LiteralPath $DestFull) {
        Write-Warn "  [OMITIDO] $DisplayName — ya existe en $DestRel, no se sobrescribe."
        return "OmittedExists"
    }
    try {
        Move-Item -LiteralPath $SourceFull -Destination $DestFull
    } catch {
        Write-Warn "  [OMITIDO] $DisplayName — no se pudo mover (posible lock: cierra el editor/indexador y reintenta). Detalle: $($_.Exception.Message)"
        return "OmittedLock"
    }
    if ((Test-Path -LiteralPath $DestFull) -and (-not (Test-Path -LiteralPath $SourceFull))) {
        Write-Host "  [MOVIDO] $DisplayName -> $DestRel" -ForegroundColor Green
        return "Moved"
    }
    try {
        if ((Test-Path -LiteralPath $DestFull) -and (-not (Test-Path -LiteralPath $SourceFull))) {
            Move-Item -LiteralPath $DestFull -Destination $SourceFull
        }
    } catch { }
    Write-Warn "  [OMITIDO] $DisplayName — verificación post-movido falló; se dejó en su sitio."
    return "OmittedVerify"
}

# =============================================================================
# Repair-DocStructure (RF-18 / criterio 14: reorganizar docs sueltas de raíz)
# =============================================================================
# Detecta .md sueltos en la RAÍZ (profundidad 0; nunca dentro de
# Documentacion/ como fuente) con allowlist exacta de nombres + patrones
# pendientes-*.md y preferencias*.md (00-indice.md,
# pendientes-implementacion.md, pendientes-*.md, capacidad-base.md,
# referencias.md, roadmap.md, idioma.md, preferencias*.md,
# memoria-proyecto.md, soluciones-conocidas.md — NUNCA otros: README.md,
# AGENTS.md, etc. jamás se cazan; nada de globs amplios ni recursivo).
# Destino Documentacion/<App>/: -App (ámbito del script) > cwd (vía
# Resolve-ActiveApp); si no se resuelve -> pregunta destino en interactivo o
# lista sin mover. Confirmación por archivo S/N/T/C sin bypass (-Force NO
# aplica aquí por diseño). Tracking vivo (>50KB o nombre pendientes-*) FUERA
# del [T]: siempre S/N individual con advertencia específica (quién lo
# consume, qué actualizar tras moverlo), default No. Orden seguro: rutinarias
# primero; tracking vivo/grandes al final de uno en uno. Movido transaccional
# por archivo (Move-SingleDocFile: verifica + rollback concreto; lock -> omitir
# + informar + continuar). Nunca borra. -DryRun / no-interactivo: solo lista
# (fail-closed). Logs con rutas relativas + tamaño; nunca contenido.
function Repair-DocStructure {
    param([string]$RootPath)

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    $allowExact = @("00-indice.md", "pendientes-implementacion.md", "capacidad-base.md", "referencias.md", "roadmap.md", "idioma.md", "memoria-proyecto.md", "soluciones-conocidas.md")

    $candidates = @()
    $rootFiles = Get-ChildItem -LiteralPath $RootPath -File -Filter "*.md" -ErrorAction SilentlyContinue
    foreach ($f in $rootFiles) {
        $docName = $f.Name
        $isDoc = ($allowExact -contains $docName) -or ($docName -like "pendientes-*.md") -or ($docName -like "preferencias*.md")
        if (-not $isDoc) { continue }
        $isLive = ($f.Length -gt 51200) -or ($docName -like "pendientes-*.md")
        $candidates += [pscustomobject]@{ Name = $docName; FullName = $f.FullName; Length = $f.Length; IsLive = [bool]$isLive }
    }
    if ($candidates.Count -eq 0) {
        Write-OK "Sin docs sueltas en raíz (allowlist RF-18: 00-indice.md, pendientes-*.md, capacidad-base.md, referencias.md, roadmap.md, idioma.md, preferencias*.md, memoria-proyecto.md, soluciones-conocidas.md)."
        return
    }

    # ¿Qué App? -App (ámbito del script) > cwd > preguntar/listar.
    $destApp = ""
    if (Get-Variable -Name App -Scope Script -ErrorAction SilentlyContinue) {
        if ($script:App -and ($script:App -ne "root")) { $destApp = $script:App }
    }
    if (-not $destApp) {
        $resolvedApp = Resolve-ActiveApp -AppName "" -RootPath $RootPath
        if ($resolvedApp -ne "root") { $destApp = $resolvedApp }
    }

    $routine = @($candidates | Where-Object { -not $_.IsLive } | Sort-Object Name)
    $live = @($candidates | Where-Object { $_.IsLive } | Sort-Object Name)
    $destLabel = if ($destApp) { "Documentacion/$destApp/" } else { "(sin app resuelta: falta -App)" }
    Write-Step "Docs sueltas en raíz ($($candidates.Count)): rutinarias $($routine.Count) + tracking vivo/grandes $($live.Count). Destino: $destLabel"
    foreach ($c in ($routine + $live)) {
        $kb = [math]::Round($c.Length / 1KB, 1)
        $tag = if ($c.IsLive) { " [tracking vivo/grande: solo S/N individual]" } else { "" }
        $dstShown = if ($destApp) { "Documentacion/$destApp/$($c.Name)" } else { "(sin destino)" }
        Write-Host "  - $($c.Name) ($kb KB) -> $dstShown$tag" -ForegroundColor DarkGray
    }

    if ($DryRun) {
        Write-Info "DryRun: Repair-DocStructure solo lista, no mueve nada."
        return
    }

    $interactive = $false
    try { $interactive = [Environment]::UserInteractive -and (-not [Console]::IsInputRedirected) } catch { $interactive = $false }
    if (-not $interactive) {
        Write-Warn "Modo no interactivo: solo se lista, no se mueve (fail-closed). Re-ejecuta en terminal interactiva con -App <nombre>."
        return
    }
    if (-not $destApp) {
        $askApp = ""
        try { $askApp = (Read-Host "¿A qué app pertenecen estas docs? (nombre de app para Documentacion/<App>/; vacío = solo listar)").Trim() } catch { $askApp = "" }
        if (-not $askApp) {
            Write-Warn "Sin app destino: solo se lista, no se mueve."
            return
        }
        $destApp = $askApp
    }

    $destDir = Join-Path $RootPath "Documentacion\$destApp"
    $sepDoc = [IO.Path]::DirectorySeparatorChar
    $rootCanonDoc = [IO.Path]::GetFullPath($RootPath)
    $destCanonDoc = [IO.Path]::GetFullPath($destDir)
    if (-not $destCanonDoc.StartsWith($rootCanonDoc + $sepDoc, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Warn "Destino fuera de containment ($destDir); no se mueve nada (fail-closed)."
        return
    }
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $moved = @()
    $omitted = @()
    $listed = @()
    $applyAll = $false
    $cancelled = $false

    foreach ($c in $routine) {
        if ($cancelled) { $listed += $c.Name; continue }
        $doMove = $false
        if ($applyAll) {
            $doMove = $true
        } else {
            $ans = ""
            try { $ans = (Read-Host "  $($c.Name) -> Documentacion/$destApp/ : [S]í mover / [N]o / [T]odos los restantes / [C]ancelar [default: N]").Trim().ToLowerInvariant() } catch { $ans = "" }
            switch ($ans) {
                "s" { $doMove = $true }
                "t" { $applyAll = $true; $doMove = $true }
                "c" { $cancelled = $true; $listed += $c.Name; continue }
                default { $listed += $c.Name; continue }
            }
        }
        if ($doMove) {
            $r = Move-SingleDocFile -SourceFull $c.FullName -DestFull (Join-Path $destDir $c.Name) -DisplayName $c.Name -DestRel "Documentacion/$destApp/$($c.Name)"
            if ($r -eq "Moved") { $moved += $c.Name } else { $omitted += $c.Name }
        }
    }

    foreach ($c in $live) {
        if ($cancelled) { $listed += $c.Name; continue }
        $kbLive = [math]::Round($c.Length / 1KB, 1)
        Write-Warn "  $($c.Name) ($kbLive KB) es tracking vivo/grande: lo leen los implementadores primero y specs que lo referencian; moverlo exige actualizar referencias y reindexar. Requiere OK explícito individual (fuera de [T])."
        $ansLive = ""
        try { $ansLive = (Read-Host "  Mover $($c.Name) -> Documentacion/$destApp/ ? [S]í / [N]o [default: N]").Trim().ToLowerInvariant() } catch { $ansLive = "" }
        if ($ansLive -ne "s") { $listed += $c.Name; continue }
        $rLive = Move-SingleDocFile -SourceFull $c.FullName -DestFull (Join-Path $destDir $c.Name) -DisplayName $c.Name -DestRel "Documentacion/$destApp/$($c.Name)"
        if ($rLive -eq "Moved") { $moved += $c.Name } else { $omitted += $c.Name }
    }

    Write-Host ""
    if ($moved.Count -gt 0) { Write-OK "Movidos ($($moved.Count)) a Documentacion/$destApp/: $($moved -join ', ')" }
    if ($omitted.Count -gt 0) { Write-Warn "Omitidos por lock/destino ($($omitted.Count)): $($omitted -join ', ') — reintentar tras cerrar el editor/indexador." }
    if ($listed.Count -gt 0) { Write-Info "Solo listados, sin mover ($($listed.Count)): $($listed -join ', ')" }
    if (($moved.Count -eq 0) -and ($omitted.Count -eq 0) -and ($listed.Count -eq 0)) {
        Write-OK "Repair-DocStructure completado sin cambios."
    }
}

function Ensure-ContextHooks {
    param([string]$RootPath)

    $hooksPath = Join-Path $RootPath ".github\hooks\context-mode.json"
    $hooksDir = Split-Path $hooksPath -Parent
    Ensure-Directory $hooksDir

    $hooksJson = [ordered]@{
        hooks = [ordered]@{
            PreToolUse = @(
                [ordered]@{
                    type = "command"
                    command = "context-mode hook vscode-copilot pretooluse"
                }
            )
            PostToolUse = @(
                [ordered]@{
                    type = "command"
                    command = "context-mode hook vscode-copilot posttooluse"
                }
            )
            SessionStart = @(
                [ordered]@{
                    type = "command"
                    command = "context-mode hook vscode-copilot sessionstart"
                }
            )
        }
    }

    if (-not (Test-Path $hooksPath) -or $Force) {
        if ($DryRun) {
            Write-Info "DryRun: preparar hooks de context-mode en $hooksPath"
            return
        }

        $hooksJson | ConvertTo-Json -Depth 10 | Set-Content -Path $hooksPath -Encoding UTF8
        Write-OK "Hooks de context-mode creados: $hooksPath"
    } else {
        Write-OK "Hooks de context-mode ya existen: $hooksPath"
    }
}

function Ensure-VSCodeSettings {
    param([string]$RootPath)

    $settingsPath = Join-Path $RootPath ".vscode\settings.json"
    Ensure-Directory (Split-Path $settingsPath -Parent)

    if (-not (Test-Path $settingsPath) -or $Force) {
        $payload = [ordered]@{
            "files.encoding" = "utf8"
            "files.autoSave" = "afterDelay"
            "terminal.integrated.defaultProfile.windows" = "PowerShell"
            "workbench.startupEditor" = "readme"
            "chat.promptFiles" = $true
            "search.useIgnoreFiles" = $true
        }

        if ($DryRun) {
            Write-Info "DryRun: preparar .vscode/settings.json con ajustes base del equipo"
            return
        }

        $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
        Write-OK "Ajustes base de VS Code creados: $settingsPath"
    } else {
        Write-OK "Ya existe .vscode/settings.json; no se reescribe salvo -Force."
    }
}

function Ensure-ProjectDocumentation {
    param([string]$RootPath)

    $docsDir = Join-Path $RootPath "Documentacion"
    Ensure-Directory $docsDir

    $indexPath = Join-Path $docsDir "00-indice.md"
    $today = Get-Date -Format "yyyy-MM-dd"
    $projectName = Split-Path $RootPath -Leaf

    $baseIndex = @"
# 📋 Índice del proyecto

> Proyecto: $projectName
> Fecha de auditoría: $today
> Fuente de verdad: `Documentacion/`

## Estado general
- Estructura de proyecto: validada por `plataformador-bootstrap.ps1`
- MCPs: configurados y listos para uso (VS Code + OpenCode)
- Índices: código (codebase-memory-mcp) + documentación (context-mode)
- Recomendación: usar `Documentacion/` como punto de referencia antes de mover archivos

## Carpetas clave
- `Documentacion/`
- `Documentacion/Agents_IA_TECH/`
- `.github/`
- `.vscode/`
- `scripts/`

## Tareas pendientes
- Revisar estructura real del proyecto y alinear con el patrón base
- Actualizar índices y memoria según el estado del repositorio
- Ejecutar validación de MCPs antes de trabajar con archivos sensibles
"@

    if (-not (Test-Path $indexPath) -or $Force) {
        if ($DryRun) {
            Write-Info "DryRun: crear índice base: $indexPath"
        } else {
            Set-Content -Path $indexPath -Value $baseIndex -Encoding UTF8
            Write-OK "Índice base creado: $indexPath"
        }
    }

    $pendingPath = Join-Path $docsDir "pendientes-implementacion.md"
    if (-not (Test-Path $pendingPath) -or $Force) {
        $pendingContent = @"
# Pendientes de implementación

> Este archivo es el puente entre documentación y ejecución.

## Preparación del proyecto
- [ ] Verificar estructura del repositorio
- [ ] Configurar herramientas externas y MCPs (VS Code + OpenCode)
- [ ] Indexar código con codebase-memory-mcp
- [ ] Indexar documentación con context-mode
- [ ] Verificar que índices y MCPs funcionan
- [ ] Revisar si hay que reorganizar carpetas o nombres
"@
        if ($DryRun) {
            Write-Info "DryRun: crear pendientes: $pendingPath"
        } else {
            Set-Content -Path $pendingPath -Value $pendingContent -Encoding UTF8
            Write-OK "Pendientes base creadas: $pendingPath"
        }
    }

    $appDocs = Join-Path $docsDir "Agents_IA_TECH"
    Ensure-Directory $appDocs

    $appIndex = Join-Path $appDocs "00-indice.md"
    if (-not (Test-Path $appIndex) -or $Force) {
        $appIndexContent = @"
# Índice de Agents_IA_TECH

> Proyecto base de agentes y herramientas del ecosistema.
> Generado por `plataformador-bootstrap.ps1`.

## Componentes clave
- `agents/`
- `.github/`
- `.opencode/`
- `scripts/`
- `Documentacion/Agents_IA_TECH/`

## Objetivo
Asegurar que cada proyecto tenga su documentación, la estructura base y los MCPs listos antes de reorganizar archivos.
"@
        if ($DryRun) {
            Write-Info "DryRun: crear índice de proyecto base: $appIndex"
        } else {
            Set-Content -Path $appIndex -Value $appIndexContent -Encoding UTF8
            Write-OK "Índice del proyecto base creado: $appIndex"
        }
    }
}

function Ensure-MemoryIndex {
    param([string]$RootPath)

    $memoryFiles = @(
        "Documentacion\Agents_IA_TECH\memoria-proyecto.md",
        "Documentacion\Agents_IA_TECH\analisis-memoria.md",
        "Documentacion\Agents_IA_TECH\capacidad-base.md"
    )

    foreach ($relative in $memoryFiles) {
        $fullPath = Join-Path $RootPath $relative
        $dirPath = Split-Path $fullPath -Parent
        Ensure-Directory $dirPath

        if (-not (Test-Path $fullPath) -or $Force) {
            $content = @"
# Registro de memoria

> Generado por `plataformador-bootstrap.ps1`
> Fecha: $(Get-Date -Format "yyyy-MM-dd")

## Estado
- Proyecto: $RootPath
- Preparación del entorno: completada o pendiente según el flujo
- ReIndexación: listo antes de mover archivos o consultar documentación
"@
            if ($DryRun) {
                Write-Info "DryRun: crear registro de memoria: $fullPath"
            } else {
                Set-Content -Path $fullPath -Value $content -Encoding UTF8
                Write-OK "Registro de memoria creado: $fullPath"
            }
        }
    }
}

function Index-CodebaseMemory {
    param(
        [string]$RootPath,
        [string]$ProjectName = ""
    )

    if ($SkipIndexing) {
        Write-Info "Se omite indexación de código por -SkipIndexing."
        return
    }

    if (-not (Get-Command "codebase-memory-mcp" -ErrorAction SilentlyContinue)) {
        Write-Warn "codebase-memory-mcp no está disponible; se omite indexación de código."
        return
    }

    $projectName = if ($ProjectName) { $ProjectName } else { Split-Path $RootPath -Leaf }
    $safeName = $projectName -replace '[^a-zA-Z0-9_-]', '-'

    Write-Step "Indexando código con codebase-memory-mcp (proyecto: $safeName)..."

    if ($DryRun) {
        Write-Info "DryRun: codebase-memory-mcp cli index_repository --path `"$RootPath`""
        return
    }

    try {
        # [SOLUCION-GENERICA] RF-S2/RF-S6: re-resolución en runtime (sin absolutas versionadas).
        $cbmCmd = Get-Command "codebase-memory-mcp" -ErrorAction SilentlyContinue
        if (-not $cbmCmd) {
            Write-Warn "codebase-memory-mcp no resuelve en PATH; se omite indexación (instala la herramienta y re-ejecuta)."
            return
        }
        $result = & $cbmCmd.Source cli index_repository --repo-path $RootPath 2>&1
        $indexExit = $LASTEXITCODE
        $indexErr = ($result | Out-String).Trim()
        # [BOOTSTRAP-FIXES] F3: verificar que la DB del proyecto existe tras indexar
        # (antes solo había un WARN genérico y silencioso). Fuente de verdad: CLI
        # (list_projects); fallback: archivo .db del proyecto en el directorio de DBs.
        $dbVerified = $false
        try {
            $projectsOut = (& $cbmCmd.Source cli list_projects 2>&1 | Out-String)
            if ($projectsOut -match [regex]::Escape($RootPath) -or $projectsOut -match [regex]::Escape($safeName)) {
                $dbVerified = $true
            }
        } catch { $dbVerified = $false }
        if (-not $dbVerified) {
            $cmDbDir = Join-Path $env:USERPROFILE ".cache\codebase-memory-mcp"
            $dbFile = Get-ChildItem -Path $cmDbDir -Filter "*$safeName*.db" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($dbFile) { $dbVerified = $true }
        }
        if ($indexExit -eq 0 -and $dbVerified) {
            Write-OK "Código indexado correctamente en codebase-memory-mcp (DB del proyecto verificada)"
        } elseif ($indexExit -eq 0) {
            Write-Warn "Indexación reportó éxito PERO la DB del proyecto ('$safeName' bajo $RootPath) NO aparece en codebase-memory-mcp. Error real: $indexErr"
        } else {
            # [BOOTSTRAP-FIXES] F8: si el modo default (full) crashea (exit_nonzero,
            # worker_failed por archivos gigantes tipo proyect_ext), reintentar UNA
            # vez con --mode fast (filtra directorios problematicos, sin
            # similarity/semantic). Degradacion gracefully: WARN si fast tambien falla.
            if ($indexErr -match 'exit_nonzero|worker_failed') {
                Write-Warn "Indexacion con modo default crasheo (worker_failed). Reintentando con --mode fast..."
                $resultFast = & $cbmCmd.Source cli index_repository --repo-path $RootPath --mode fast 2>&1
                $fastExit = $LASTEXITCODE
                $fastErr = ($resultFast | Out-String).Trim()
                if ($fastExit -eq 0) {
                    Write-OK "Codigo indexado con --mode fast (modo default crasheo; degradacion gracefully)"
                } else {
                    Write-Warn "Indexacion con --mode fast tambien fallo (exit $fastExit). Error real: $fastErr"
                }
            } else {
                Write-Warn "Indexacion de codigo fallo (exit $indexExit). Error real: $indexErr"
            }
        }
    }
    catch {
        Write-Warn ("Error al indexar código: {0}" -f $_)
    }
}

function Index-ContextMode {
    param(
        [string]$RootPath,
        [string[]]$PathsToIndex
    )

    if ($SkipIndexing) {
        Write-Info "Se omite indexación de documentación por -SkipIndexing."
        return
    }

    if (-not (Get-Command "context-mode" -ErrorAction SilentlyContinue)) {
        Write-Warn "context-mode no está disponible; se omite indexación de documentación."
        return
    }

    Write-Step "Indexando documentación con context-mode..."

    if ($DryRun) {
        foreach ($p in $PathsToIndex) {
            Write-Info "DryRun: context-mode index `"$p`""
        }
        return
    }

    foreach ($p in $PathsToIndex) {
        if (Test-Path $p) {
            try {
                # [SOLUCION-GENERICA] RF-S2/RF-S6: re-resolución en runtime.
                $ctxCmd = Get-Command "context-mode" -ErrorAction SilentlyContinue
                if (-not $ctxCmd) {
                    Write-Warn "context-mode no resuelve en PATH; se omite indexación de $p (instala la herramienta y re-ejecuta)."
                    continue
                }
                $result = & $ctxCmd.Source index $p 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-OK "Indexado en context-mode: $p"
                } else {
                    Write-Warn ("Advertencia al indexar {0} (ver salida arriba)" -f $p)
                }
            }
            catch {
                Write-Warn ("Error al indexar {0}: {1}" -f $p, $_)
            }
        } else {
            Write-Warn "Ruta no existe, se omite: $p"
        }
    }
}

function Verify-McpAndIndexes {
    param([string]$RootPath)

    Write-Step "Verificando MCPs e índices..."

    # 1. Verificar codebase-memory-mcp
    Write-Info "=== Verificación codebase-memory-mcp ==="
    if (Get-Command "codebase-memory-mcp" -ErrorAction SilentlyContinue) {
        try {
            # [SOLUCION-GENERICA] RF-S2/RF-S6: re-resolución en runtime.
            $cbmVerify = Get-Command "codebase-memory-mcp" -ErrorAction SilentlyContinue
            $projects = & $cbmVerify.Source cli list_projects 2>&1
            Write-OK "codebase-memory-mcp responde correctamente"
            Write-Info "Proyectos indexados:"
            $projects | ForEach-Object { Write-Host "  $_" }
        }
        catch {
            Write-Warn ("codebase-memory-mcp no responde correctamente: {0}" -f $_)
        }
    } else {
        Write-Warn "codebase-memory-mcp no instalado"
    }

    # 2. Verificar context-mode
    Write-Info "=== Verificación context-mode ==="
    if (Get-Command "context-mode" -ErrorAction SilentlyContinue) {
        try {
            # [SOLUCION-GENERICA] RF-S2/RF-S6: re-resolución en runtime.
            $ctxDoctor = Get-Command "context-mode" -ErrorAction SilentlyContinue
            $doctor = & $ctxDoctor.Source doctor 2>&1
            Write-OK "context-mode doctor ejecutado"
            $doctor | ForEach-Object { Write-Host "  $_" }
        }
        catch {
            Write-Warn ("context-mode doctor falló: {0}" -f $_)
        }
    } else {
        Write-Warn "context-mode no instalado"
    }

    # 3. Verificar markitdown
    Write-Info "=== Verificación markitdown ==="
    if (Get-Command "markitdown" -ErrorAction SilentlyContinue) {
        Write-OK "markitdown disponible"
    } else {
        Write-Warn "markitdown no instalado"
    }

    # 4. Verificar opencode.json tiene sección mcp
    Write-Info "=== Verificación opencode.json ==="
    $opencodePath = Join-Path $RootPath "opencode.json"
    if (Test-Path $opencodePath) {
        $config = Get-Content -Path $opencodePath -Raw | ConvertFrom-Json
        if ($config.mcp) {
            Write-OK "opencode.json tiene sección mcp configurada"
            $config.mcp.PSObject.Properties | ForEach-Object {
                Write-Host ("  - {0}: enabled={1}" -f $_.Name, $_.Value.enabled)
            }
        } else {
            Write-Warn "opencode.json NO tiene sección mcp"
        }
    } else {
        Write-Warn "No existe opencode.json en $RootPath"
    }

    # 5. Verificar .vscode/mcp.json
    Write-Info "=== Verificación .vscode/mcp.json ==="
    $vscodeMcp = Join-Path $RootPath ".vscode\mcp.json"
    if (Test-Path $vscodeMcp) {
        $config = Get-Content -Path $vscodeMcp -Raw | ConvertFrom-Json
        if ($config.servers) {
            Write-OK ".vscode/mcp.json configurado correctamente"
            $config.servers.PSObject.Properties | ForEach-Object {
                Write-Host ("  - {0}: {1} ({2})" -f $_.Name, $_.Value.command, $_.Value.type)
            }
        } else {
            Write-Warn ".vscode/mcp.json existe pero sin servidores"
        }
    } else {
        Write-Warn "No existe .vscode/mcp.json"
    }

    # 6. Verificar índices de documentación
    Write-Info "=== Verificación índices de documentación (context-mode storage) ==="
    # [SOLUCION-GENERICA] RF-S2: rutas derivadas del entorno (sin absolutas de usuario versionadas).
    $cmContent = Join-Path $env:APPDATA "opencode\context-mode\content"
    if (Test-Path $cmContent) {
        $files = Get-ChildItem -Path $cmContent -Recurse -File -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            Write-OK ("context-mode tiene {0} archivos indexados" -f $files.Count)
            $files | Select-Object -First 10 | ForEach-Object { Write-Host ("  {0} ({1} bytes)" -f $_.Name, $_.Length) }
        } else {
            Write-Warn "context-mode storage está vacío (ejecutar indexación)"
        }
    } else {
        Write-Warn "No existe storage de context-mode"
    }

    # 7. Verificar base de datos codebase-memory
    Write-Info "=== Verificación base de datos codebase-memory-mcp ==="
    # [SOLUCION-GENERICA] RF-S2: rutas derivadas del entorno (sin absolutas de usuario versionadas).
    $cmDbPath = Join-Path $env:USERPROFILE ".cache\codebase-memory-mcp"
    if (Test-Path $cmDbPath) {
        $dbs = Get-ChildItem -Path $cmDbPath -Filter "*.db" -ErrorAction SilentlyContinue
        if ($dbs.Count -gt 0) {
            Write-OK "Bases de datos codebase-memory-mcp encontradas:"
            $dbs | ForEach-Object { 
                $sizeMB = [math]::Round($_.Length / 1MB, 2)
                Write-Host ("  {0} ({1} MB)" -f $_.Name, $sizeMB)
            }
        } else {
            Write-Warn "No hay bases de datos .db en codebase-memory-mcp"
        }
    } else {
        Write-Warn "No existe directorio de codebase-memory-mcp"
    }
}

function Show-VerificationCommands {
    param([string]$RootPath)

    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " COMANDOS DE VERIFICACIÓN MANUAL (para usar en terminal)" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# Verificar proyectos indexados en codebase-memory-mcp:" -ForegroundColor Yellow
    Write-Host "codebase-memory-mcp cli list_projects" -ForegroundColor White
    Write-Host ""
    Write-Host "# Verificar estado de un proyecto específico:" -ForegroundColor Yellow
    Write-Host "codebase-memory-mcp cli index_status --project `"<nombre-proyecto>`"" -ForegroundColor White
    Write-Host ""
    Write-Host "# Buscar en el grafo de código:" -ForegroundColor Yellow
    Write-Host "codebase-memory-mcp cli search_graph '{\"query\":\"<búsqueda>\"}'" -ForegroundColor White
    Write-Host ""
    Write-Host "# Ver arquitectura del proyecto:" -ForegroundColor Yellow
    Write-Host "codebase-memory-mcp cli get_architecture '{\"project\":\"<nombre>\"}'" -ForegroundColor White
    Write-Host ""
    Write-Host "# Verificar context-mode (diagnóstico):" -ForegroundColor Yellow
    Write-Host "context-mode doctor" -ForegroundColor White
    Write-Host ""
    Write-Host "# Buscar en documentación indexada:" -ForegroundColor Yellow
    Write-Host "context-mode search `"<consulta>`"" -ForegroundColor White
    Write-Host ""
    Write-Host "# Indexar código manualmente:" -ForegroundColor Yellow
    Write-Host "codebase-memory-mcp cli index_repository --path `"$RootPath`"" -ForegroundColor White
    Write-Host ""
    Write-Host "# Indexar documentación manualmente:" -ForegroundColor Yellow
    Write-Host "context-mode index `"$RootPath\Documentacion\`"" -ForegroundColor White
    Write-Host ""
    Write-Host "# Verificar opencode.json tiene MCP:" -ForegroundColor Yellow
    Write-Host "cat opencode.json | jq '.mcp'" -ForegroundColor White
    Write-Host ""
    Write-Host "# Verificar .vscode/mcp.json:" -ForegroundColor Yellow
    Write-Host "cat .vscode/mcp.json | jq '.servers'" -ForegroundColor White
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " FLUJO RECOMENDADO DE USO" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ÍNDICES PARA CÓDIGO (codebase-memory-mcp):" -ForegroundColor Green
    Write-Host "   - Usar para: entender arquitectura, encontrar funciones, ver dependencias," -ForegroundColor White
    Write-Host "     tracear llamadas, analizar estructura, refactoring" -ForegroundColor White
    Write-Host ""
    Write-Host "2. ÍNDICES PARA DOCUMENTACIÓN (context-mode):" -ForegroundColor Green
    Write-Host "   - Usar para: consultar specs, ADRs, decisiones, flujos, onboarding," -ForegroundColor White
    Write-Host "     buscar cómo implementar algo según la documentación" -ForegroundColor White
    Write-Host ""
    Write-Host "3. CUANDO PREGUNTES TEMAS DE CÓDIGO O QUIERAS UNA FUNCIÓN NUEVA:" -ForegroundColor Green
    Write-Host "   - PRIMERO: consulta la documentación (context-mode) para entender el contexto," -ForegroundColor White
    Write-Host "     las decisiones previas (ADRs), specs y convenciones" -ForegroundColor White
    Write-Host "   - DESPUÉS: usa el grafo de código (codebase-memory-mcp) para ver la" -ForegroundColor White
    Write-Host "     implementación actual, dependencias y impacto" -ForegroundColor White
    Write-Host "   - COMBINA: documentación (qué y por qué) + código (cómo)" -ForegroundColor White
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
}

function Reload-ProjectWindow {
    param([string]$RootPath = "")

    if ($NoRestart -or $DryRun) {
        Write-Info "Se omite recargar la ventana de VS Code porque -NoRestart o -DryRun está activo."
        return
    }

    if ($env:TERM_PROGRAM -eq 'vscode') {
        Write-Warn "El script corre dentro del terminal integrado de VS Code (TERM_PROGRAM=vscode); recargar ahora mataría este mismo terminal y rompería la ejecución."
        Write-Warn "Recarga manual requerida en ESTA ventana al terminar: Ctrl+Shift+P -> Developer: Reload Window."
        return
    }

    Write-Info "Terminal externa detectada; la recarga automática es segura (la terminal externa sobrevive)."

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    Write-Step "Recargando la ventana de VS Code del proyecto para cargar los cambios de MCP y configuración..."
    Write-Info "Solo se recarga la ventana de este proyecto: $RootPath. Las demás ventanas quedan intactas."

    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Warn "CLI 'code' no encontrada en PATH. Recarga manual en ESA ventana: abre la carpeta del proyecto y ejecuta Ctrl+Shift+P -> Developer: Reload Window."
        return
    }

    & code --reuse-window "$RootPath"
    Write-OK "Ventana del proyecto recargada: $RootPath (solo esa ventana; las demás quedan intactas)."
    Write-Info "Si los MCPs no aparecen, haz Reload Window manual en ESA ventana (Ctrl+Shift+P -> Developer: Reload Window)."
}

# =============================================================================
# =============================================================================
# Find-OrphanKitFiles + Invoke-OrphanDecision (T-I7 / RF-12: manejo de huérfanos)
# =============================================================================
# RF-12: al sincronizar, detectar huérfanos (existen en .github/ .opencode/
# .doc_agents/ local pero ya no existen en el clon maestro) y preguntar
# ¿borrar o conservar? (conservar = mover a revisar_manualmente\yyyymmdd\ +
# informar; default seguro = conservar; -DryRun solo informa).
# Condiciones de seguridad (seguridad/huerfanos.md, no negociables):
# default Conservar, abortar si el maestro está incompleto, revisar_manualmente/
# en .gitignore, logs solo con metadatos (NUNCA contenido), containment-check +
# nunca sobrescribir respaldo, detector acotado a la allowlist (3 dirs),
# .opencode/config.json excluido, -DryRun no borra ni mueve nada.
# Solo lectura: funciona igual en -DryRun (no escribe nada por diseño).
# Devuelve $true si $rel (ruta relativa con separadores '/') es un artefacto de la
# herramienta OpenCode que .opencode/.gitignore define como "nunca versionar":
# dependencias locales (node_modules, package*.json, bun.lock) y carpetas lib/ y bin/
# dentro de .opencode/. Se usa para no reportar como huérfanos estos artefactos.
function Test-ToolArtifactPath {
    param([string]$Rel)

    # 1) node_modules en cualquier nivel dentro de .opencode/.
    if ($Rel -match '(^|/)node_modules(/|$)') { return $true }
    # 2) Manifiestos de dependencias dentro de .opencode/ (fuera de node_modules,
    #    ya cubiertos arriba).
    if ($Rel -eq '.opencode/package.json' -or
        $Rel -eq '.opencode/package-lock.json' -or
        $Rel -eq '.opencode/bun.lock') { return $true }
    # 3) Carpetas lib/ y bin/ SOLO dentro de .opencode/ (no .github/lib/ ni .doc_agents/lib/).
    if ($Rel -match '^\.opencode/(lib|bin)(/|$)') { return $true }

    return $false
}

function Find-OrphanKitFiles {
    param(
        [string]$RootPath = "",
        [string]$TempDir = ""
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }
    if (-not $TempDir) {
        throw "Find-OrphanKitFiles: falta -TempDir (clon maestro). Se aborta la fase de huérfanos."
    }
    if (-not (Test-Path -LiteralPath $TempDir)) {
        throw "Find-OrphanKitFiles: el clon maestro no existe ($TempDir). Se aborta la fase de huérfanos: jamás decidir huérfanos contra un clon fallido."
    }

    # Fail-closed: maestro incompleto => abortar (todo lo local parecería huérfano).
    $allowDirs = @(".github", ".opencode", ".doc_agents")
    foreach ($d in $allowDirs) {
        if (-not (Test-Path -LiteralPath (Join-Path $TempDir $d))) {
            throw "Find-OrphanKitFiles: clon maestro incompleto (falta '$d' en $TempDir). Se aborta la fase de huérfanos."
        }
    }

    $orphans = @()
    foreach ($d in $allowDirs) {
        $localDir = Join-Path $RootPath $d
        if (-not (Test-Path -LiteralPath $localDir)) { continue }
        $files = Get-ChildItem -LiteralPath $localDir -Recurse -File -Force -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $rel = ([IO.Path]::GetRelativePath($RootPath, $f.FullName)) -replace '\\', '/'
            # Seguridad: .opencode/config.json nunca se toca (posibles credenciales).
            if ($rel -eq ".opencode/config.json") { continue }
            # Defensa: rechaza rutas que escapan (fail-closed; no ocurre enumerando local).
            if ($rel -match '(^|/)\.\.(/|$)') { continue }
            # Exclusión de artefactos de la herramienta OpenCode (definidos como "nunca
            # versionar" en .opencode/.gitignore): dependencias locales que el maestro no
            # tiene (gitignored) y que, si se reportan, contaminan la fase de huérfanos.
            # NO aplica a contenido real del kit (.opencode/agents, .opencode/commands, etc.).
            if (Test-ToolArtifactPath $rel) { continue }
            # [BOOTSTRAP-FIXES] F1: .github/context-mode/ es runtime local de cada
            # proyecto (hooks/MCP de context-mode, NO es del kit): jamás reportar
            # como huérfano (el maestro no lo tiene y contaminaría la fase).
            if ($rel -match '(^|/)\.github/context-mode(/|$)') { continue }
            $masterPath = Join-Path $TempDir ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path -LiteralPath $masterPath)) {
                $orphans += $rel
            }
        }
    }
    return $orphans
}

# Muestra la lista de huérfanos agrupada por directorio (solo rutas relativas +
# tamaño/fecha si es barato; NUNCA contenido de archivos en logs).
function Show-OrphanList {
    param(
        [string[]]$Orphans = @(),
        [string]$RootPath = ""
    )

    Write-Step "Huérfanos detectados ($($Orphans.Count)): existen local, no existen en el maestro."
    $grouped = $Orphans | Group-Object { ($_ -split '/')[0] } | Sort-Object Name
    foreach ($g in $grouped) {
        Write-Host "  [$($g.Name)/] ($($g.Count))" -ForegroundColor Yellow
        foreach ($rel in ($g.Group | Sort-Object)) {
            $meta = ""
            try {
                $item = Get-Item -LiteralPath (Join-Path $RootPath ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)) -ErrorAction Stop
                $meta = " ($($item.Length) bytes, $($item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))"
            } catch { $meta = "" }
            Write-Host "    - $rel$meta" -ForegroundColor DarkGray
        }
    }
}

# Elimina huérfanos (limpio, sin respaldo). Containment-check fail-closed +
# log de lo borrado (ruta relativa, tamaño, fecha, hash; NUNCA contenido).
# Defensa: si el ámbito del script está en -DryRun, se niega a borrar.
function Remove-OrphanFiles {
    param(
        [string[]]$Files = @(),
        [string]$RootPath = ""
    )

    if (Get-Variable -Name DryRun -Scope Script -ErrorAction SilentlyContinue) {
        if ([bool]$script:DryRun) {
            Write-Warn "Remove-OrphanFiles: -DryRun activo, no se borra nada (fail-closed)."
            return @()
        }
    }
    $rootCanon = [IO.Path]::GetFullPath($RootPath)
    $sep = [IO.Path]::DirectorySeparatorChar
    $deleted = @()
    foreach ($rel in $Files) {
        if ($rel -match '(^|/)\.\.(/|$)') {
            Write-Warn "  [RECHAZADO] $rel — ruta fuera de alcance (..), no se toca."
            continue
        }
        $full = [IO.Path]::GetFullPath((Join-Path $RootPath ($rel -replace '/', $sep)))
        if (-not $full.StartsWith($rootCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel — containment-check: fuera del proyecto, no se toca."
            continue
        }
        try {
            $item = Get-Item -LiteralPath $full -ErrorAction Stop
            $size = $item.Length
            $date = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            $hash = ((Get-FileHash -LiteralPath $full -Algorithm SHA256 -ErrorAction Stop).Hash).Substring(0, 12)
        } catch {
            Write-Warn "  [OMITIDO] $rel — ya no existe o no se puede leer, no se toca."
            continue
        }
        Remove-Item -LiteralPath $full -Force
        $deleted += $rel
        Write-Host "  [BORRADO] $rel ($size bytes, $date, sha256:$hash...)" -ForegroundColor Red
    }
    return $deleted
}

# Conserva huérfanos: mueve a revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>
# preservando la estructura relativa. Containment-check fail-closed, nunca
# sobrescribe un respaldo existente (sufijo incremental), no crea carpetas
# vacías (crea bajo demanda al mover el primer archivo), no sigue symlinks
# (mueve el enlace como tal). Advierte si revisar_manualmente/ no está en
# .gitignore y recuerda que el respaldo puede contener secrets.
function Move-OrphanFilesToBackup {
    param(
        [string[]]$Files = @(),
        [string]$RootPath = ""
    )

    if (Get-Variable -Name DryRun -Scope Script -ErrorAction SilentlyContinue) {
        if ([bool]$script:DryRun) {
            Write-Warn "Move-OrphanFilesToBackup: -DryRun activo, no se mueve nada (fail-closed)."
            return @{ Moved = @(); Destino = "" }
        }
    }
    if (-not $Files -or $Files.Count -eq 0) { return @{ Moved = @(); Destino = "" } }

    # Seguridad: revisar_manualmente/ debe estar en .gitignore (no versionar respaldos).
    $gitignore = Join-Path $RootPath ".gitignore"
    $gitText = ""
    try { $gitText = Get-Content -LiteralPath $gitignore -Raw -ErrorAction Stop } catch { $gitText = "" }
    if ($gitText -notmatch 'revisar_manualmente/') {
        Write-Warn "revisar_manualmente/ NO está en .gitignore: no hacer commit de los respaldos (pueden contener secrets)."
    }

    # Carpeta del día; si existe => sufijo -HHmmss; si aún existe => contador.
    $day = Get-Date -Format 'yyyyMMdd'
    $backupRoot = Join-Path $RootPath "revisar_manualmente\$day"
    if (Test-Path -LiteralPath $backupRoot) {
        $backupRoot = Join-Path $RootPath ("revisar_manualmente\" + $day + "-" + (Get-Date -Format 'HHmmss'))
    }
    $n = 2
    while (Test-Path -LiteralPath $backupRoot) {
        $backupRoot = Join-Path $RootPath ("revisar_manualmente\" + $day + "-" + (Get-Date -Format 'HHmmss') + "_$n")
        $n++
    }
    $rootCanon = [IO.Path]::GetFullPath($RootPath)
    $backupCanon = [IO.Path]::GetFullPath($backupRoot)
    $sep = [IO.Path]::DirectorySeparatorChar

    $moved = @()
    foreach ($rel in ($Files | Sort-Object)) {
        if ($rel -match '(^|/)\.\.(/|$)') {
            Write-Warn "  [RECHAZADO] $rel — ruta fuera de alcance (..), no se toca."
            continue
        }
        $srcFull = [IO.Path]::GetFullPath((Join-Path $RootPath ($rel -replace '/', $sep)))
        if (-not $srcFull.StartsWith($rootCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel — containment-check: fuera del proyecto, no se toca."
            continue
        }
        if (-not (Test-Path -LiteralPath $srcFull)) {
            Write-Warn "  [OMITIDO] $rel — ya no existe, no se mueve."
            continue
        }
        try {
            $linkType = (Get-Item -LiteralPath $srcFull -ErrorAction Stop).LinkType
            if ($linkType) { Write-Info "  $rel es enlace ($linkType): se mueve el enlace como tal, sin seguirlo." }
        } catch { Write-Warn "  [OMITIDO] $rel — no se puede leer, no se mueve."; continue }

        $dstFull = [IO.Path]::GetFullPath((Join-Path $backupRoot ($rel -replace '/', $sep)))
        if (-not $dstFull.StartsWith($backupCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel — containment-check: el destino escapa del respaldo, se aborta ese movido."
            continue
        }
        # Nunca sobrescribir respaldo existente: sufijo incremental antes de la extensión.
        if (Test-Path -LiteralPath $dstFull) {
            $dstParent = Split-Path $dstFull -Parent
            $dstBase = [IO.Path]::GetFileNameWithoutExtension($dstFull)
            $dstExt = [IO.Path]::GetExtension($dstFull)
            $i = 2
            while (Test-Path -LiteralPath $dstFull) {
                $dstFull = Join-Path $dstParent ("{0}_{1:d2}{2}" -f $dstBase, $i, $dstExt)
                $i++
            }
            Write-Info "  Destino ocupado: se usa variante $dstFull"
        }
        $dstParent = Split-Path $dstFull -Parent
        if (-not (Test-Path -LiteralPath $dstParent)) { New-Item -ItemType Directory -Path $dstParent -Force | Out-Null }
        Move-Item -LiteralPath $srcFull -Destination $dstFull -Force
        $moved += $rel
        $dstRel = ([IO.Path]::GetRelativePath($RootPath, $dstFull)) -replace '\\', '/'
        Write-Host "  [CONSERVADO] $rel -> $dstRel" -ForegroundColor Green
    }
    return @{ Moved = $moved; Destino = $backupRoot }
}

# Pregunta ¿borrar o conservar? por lote o por archivo ([B]orrar / [C]onservar /
# [U]no por uno / [O]mitir = propio, dejar en su lugar). Default seguro Conservar
# (jamás auto-borrar; sin respuesta o no interactivo => Conservar). Borrar exige
# confirmación explícita en interactivo (doble confirmación en lote) o -Force en
# no interactivo (si no, degrada a Conservar). En -DryRun solo informa (no borra
# ni mueve). Al final informa qué se borró / qué se movió y dónde / qué se omitió.
function Invoke-OrphanDecision {
    param(
        [string[]]$Orphans = @(),
        [string]$RootPath = "",
        [string]$OrphanAction = "Preguntar"
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }
    $inDryRun = $false
    if (Get-Variable -Name DryRun -Scope Script -ErrorAction SilentlyContinue) { $inDryRun = [bool]$script:DryRun }
    $withForce = $false
    if (Get-Variable -Name Force -Scope Script -ErrorAction SilentlyContinue) { $withForce = [bool]$script:Force }

    $norm = @{ "borrar" = "Borrar"; "conservar" = "Conservar"; "preguntar" = "Preguntar" }
    $key = "$OrphanAction".Trim().ToLowerInvariant()
    if ($norm.ContainsKey($key)) { $action = $norm[$key] } else {
        if ($OrphanAction) { Write-Warn "Invoke-OrphanDecision: -OrphanAction '$OrphanAction' no válido (Borrar|Conservar|Preguntar). Se usa 'Preguntar'." }
        $action = "Preguntar"
    }

    if (-not $Orphans -or $Orphans.Count -eq 0) {
        Write-OK "Sin huérfanos: todo lo local en .github/ .opencode/ .doc_agents/ existe en el maestro."
        return
    }

    Show-OrphanList -Orphans $Orphans -RootPath $RootPath

    if ($inDryRun) {
        Write-Info "DryRun: con -OrphanAction $action se haría lo siguiente (sin borrar ni mover nada):"
        switch ($action) {
            "Borrar"    { Write-Info "DryRun: se ELIMINARÍAN $($Orphans.Count) huérfano(s) (en modo real no interactivo requiere -Force)." }
            "Conservar" { Write-Info "DryRun: se MOVERÍAN $($Orphans.Count) huérfano(s) a revisar_manualmente\<yyyymmdd>\ preservando estructura." }
            default     { Write-Info "DryRun: se PREGUNTARÍA [B]orrar todos / [C]onservar todos / [U]no por uno / [O]mitir (default seguro: Conservar)." }
        }
        Write-Info "DryRun: fase de huérfanos simulada. Documentacion/<AppName>/ nunca entra en alcance."
        return
    }

    $interactive = $false
    try { $interactive = [Environment]::UserInteractive -and (-not [Console]::IsInputRedirected) } catch { $interactive = $false }

    $toDelete = @()
    $toKeep = @()
    $omitted = @()
    $confirmedViaPrompt = $false
    $effective = $action

    if ($action -eq "Preguntar") {
        if (-not $interactive) {
            Write-Warn "Modo no interactivo sin -OrphanAction explícito: default seguro Conservar (respaldo en revisar_manualmente/)."
            $effective = "Conservar"
        } else {
            $choice = ""
            try { $choice = (Read-Host "Huérfanos: [B]orrar todos / [C]onservar todos / [U]no por uno / [O]mitir = propios, dejar en su lugar [default: C]").Trim().ToLowerInvariant() } catch { $choice = "" }
            switch ($choice) {
                "b" {
                    $confirm = ""
                    try { $confirm = (Read-Host "CONFIRMAR: ¿BORRAR $($Orphans.Count) huérfano(s) SIN respaldo? [S = sí / N = no] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
                    if ($confirm -eq "s") { $effective = "Borrar"; $confirmedViaPrompt = $true }
                    else { Write-Warn "Borrado no confirmado: default seguro Conservar."; $effective = "Conservar" }
                }
                "u" { $effective = "__PerFile__" }
                "o" { $effective = "__Omit__" }
                default { $effective = "Conservar" }
            }
        }
    }

    if ($effective -eq "__PerFile__") {
        foreach ($rel in ($Orphans | Sort-Object)) {
            $ans = ""
            try { $ans = (Read-Host "  $rel : [B]orrar / [C]onservar / [O]mitir [default: C]").Trim().ToLowerInvariant() } catch { $ans = "" }
            switch ($ans) {
                "b" { $toDelete += $rel }
                "o" { $omitted += $rel }
                default { $toKeep += $rel }
            }
        }
        if ($toDelete.Count -gt 0) {
            $confirm = ""
            try { $confirm = (Read-Host "CONFIRMAR: ¿BORRAR $($toDelete.Count) huérfano(s) SIN respaldo? [S/N] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
            if ($confirm -eq "s") { $confirmedViaPrompt = $true }
            else {
                Write-Warn "Borrado no confirmado: esos archivos pasan a Conservar."
                $toKeep += $toDelete
                $toDelete = @()
            }
        }
    } elseif ($effective -eq "__Omit__") {
        $omitted = @($Orphans)
        Write-Info "Se omiten $($omitted.Count) huérfano(s): se consideran propios y se dejan en su lugar."
    } elseif ($effective -eq "Borrar") {
        if ($confirmedViaPrompt) { $toDelete = @($Orphans) }
        elseif ($interactive) {
            $confirm = ""
            try { $confirm = (Read-Host "CONFIRMAR: -OrphanAction Borrar eliminará $($Orphans.Count) huérfano(s) SIN respaldo. ¿Continuar? [S/N] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
            if ($confirm -eq "s") { $toDelete = @($Orphans) }
            else { Write-Warn "Borrado no confirmado: default seguro Conservar."; $toKeep = @($Orphans) }
        } elseif ($withForce) { $toDelete = @($Orphans) }
        else {
            Write-Warn "-OrphanAction Borrar en modo no interactivo exige -Force (fail-closed): se degrada a Conservar."
            $toKeep = @($Orphans)
        }
    } else {
        $toKeep = @($Orphans)
    }

    $deleted = @()
    if ($toDelete.Count -gt 0) {
        $deleted = @(Remove-OrphanFiles -Files $toDelete -RootPath $RootPath)
    }
    $backupResult = @{ Moved = @(); Destino = "" }
    if ($toKeep.Count -gt 0) {
        $backupResult = Move-OrphanFilesToBackup -Files $toKeep -RootPath $RootPath
    }

    # Informe final: qué se borró / qué se movió y dónde / qué se omitió.
    Write-Host ""
    if ($deleted.Count -gt 0) { Write-Warn "Borrados sin respaldo ($($deleted.Count)): $($deleted -join ', ')" }
    if ($backupResult.Moved.Count -gt 0) {
        $dstRel = ([IO.Path]::GetRelativePath($RootPath, $backupResult.Destino)) -replace '\\', '/'
        Write-OK "Conservados en respaldo ($($backupResult.Moved.Count)): $dstRel"
        foreach ($rel in ($backupResult.Moved | Sort-Object)) {
            Write-Host "    - $rel" -ForegroundColor DarkGray
        }
        Write-Warn "NO hacer commit de revisar_manualmente/ (puede contener credenciales); si un huérfano tenía secrets, rótalos; no reintroducir al kit sin revisión manual."
    }
    if ($omitted.Count -gt 0) { Write-Info "Omitidos (propios, dejados en su lugar) ($($omitted.Count)): $($omitted -join ', ')" }
    if ($deleted.Count -eq 0 -and $backupResult.Moved.Count -eq 0 -and $omitted.Count -eq 0) {
        Write-OK "Fase de huérfanos completada sin cambios."
    }
}

# [SELF-UPDATE] ADR-0005 relacionado: el bootstrap se auto-actualiza desde el maestro
# antes de ejecutarse (fail-open, -SkipSelfUpdate para saltar). El sync del paso 3
# actualiza el kit transversal pero NO este script; aquí se corrige esa brecha.
function Update-Self {
    param(
        [string]$RootPath = "",
        [string]$RepoUrl = ""
    )

    if ($DryRun) {
        Write-Info "DryRun: verificaría self-update contra $RepoUrl"
        return
    }

    # [SECURITY] fail-open: no clonar ni re-ejecutar contenido de URLs no confiables.
    if (-not (Test-TrustedGithubUrl $RepoUrl)) {
        Write-Warn "[SECURITY] URL de maestro no permitida para self-update: $RepoUrl (solo https://github.com/<owner en allowlist>); se continúa con la versión local."
        return
    }

    # Detección del kit maestro: si el repo local YA es el maestro, comparar contra
    # sí mismo es inútil → saltar (auto-skip automático dentro de Agents_IA_TECH).
    $localOrigin = ""
    try {
        $originOut = git -C $RootPath remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0) { $localOrigin = @($originOut)[0] }
    } catch { }
    if ([string]::IsNullOrWhiteSpace($localOrigin)) {
        Write-Warn "git no disponible o remote origin no encontrado; se salta el self-update (se continúa con la versión local)."
        return
    }
    $normLocal = "$localOrigin".Trim().TrimEnd('/')
    if ($normLocal.EndsWith('.git')) { $normLocal = $normLocal.Substring(0, $normLocal.Length - 4) }
    $normMaster = "$RepoUrl".Trim().TrimEnd('/')
    if ($normMaster.EndsWith('.git')) { $normMaster = $normMaster.Substring(0, $normMaster.Length - 4) }
    if ($normLocal -eq $normMaster) {
        Write-Info "Repo local es el kit maestro ($normLocal); self-update omitido."
        return
    }

    # Clon shallow del maestro a temp (limpiar restos previos).
    $tempDir = Join-Path $env:TEMP "agents-selfupdate-temp"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
    try {
        $cloneOk = $false
        try {
            git clone --depth 1 $RepoUrl $tempDir 2>$null | Out-Null
            $cloneOk = ($LASTEXITCODE -eq 0)
        } catch { $cloneOk = $false }
        if (-not $cloneOk) {
            Write-Warn "No se pudo clonar el maestro ($RepoUrl); sin red o maestro inaccesible; se continúa con la versión local."
            return
        }

        # Comparar hash SHA256 del bootstrap local vs el del clon.
        $localFile = Join-Path $RootPath "scripts\plataformador-bootstrap.ps1"
        $remoteFile = Join-Path $tempDir "scripts\plataformador-bootstrap.ps1"
        if (-not (Test-Path $remoteFile)) {
            Write-Warn "El maestro no contiene scripts/plataformador-bootstrap.ps1; se continúa con la versión local."
            return
        }
        $localHash = (Get-FileHash -Algorithm SHA256 $localFile).Hash
        $remoteHash = (Get-FileHash -Algorithm SHA256 $remoteFile).Hash
        if ($localHash -eq $remoteHash) {
            Write-Info "Bootstrap ya está en la versión del maestro"
            return
        }

        # Difieren: sobrescribir el local con la versión del clon y re-ejecutar.
        Copy-Item -Force $remoteFile $localFile
        $commitHash = ""
        try {
            $revOut = git -C $tempDir rev-parse --short HEAD 2>$null
            if ($LASTEXITCODE -eq 0) { $commitHash = @($revOut)[0] }
        } catch { }
        Write-OK "Bootstrap actualizado desde el maestro (commit $commitHash). Re-ejecutando con los mismos argumentos..."
        # $script:PSBoundParameters (no el de la función) preserva TODOS los argumentos originales.
        & $PSCommandPath @script:PSBoundParameters
        exit $LASTEXITCODE
    }
    finally {
        # [007-MCP] D4/RF-05: limpieza en TODAS las rutas de salida (try/finally)
        # para no dejar temp dirs huérfanos; el re-exec queda tras la limpieza.
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }
}

# [011-BOOTSTRAP-UPGRADE] Invoca upgrade_framework para sincronizar dependencias
# externas (proyect_ext/) desde dependencias-manifest.yml. Fail-open, gated por
# -ForceUpgradeTools, respeta -DryRun. Idempotente.
function Invoke-UpgradeFramework {
    param(
        [string]$RootPath = "",
        [switch]$ForceUpgradeTools,
        [switch]$DryRun
    )

    if (-not $RootPath) {
        Write-Warn "Invoke-UpgradeFramework: RootPath vacío; se omite."
        return
    }

    if (-not $ForceUpgradeTools) {
        Write-Info "Invoke-UpgradeFramework: -ForceUpgradeTools no especificado; se omite sync de dependencias."
        return
    }

    Write-Step "  [upgrade_framework] Sincronizando dependencias externas (proyect_ext/)..."

    # [011-FIX] Copiar manifest maestro si no existe local (idempotente).
    $kitRoot = (Split-Path -Parent $PSScriptRoot)
    $masterManifest = Join-Path $kitRoot "dependencias-manifest.yml"
    $localManifest = Join-Path $RootPath "dependencias-manifest.yml"
    if (-not (Test-Path -LiteralPath $localManifest) -and (Test-Path -LiteralPath $masterManifest)) {
        if ($DryRun) {
            Write-Info "  [upgrade_framework] DryRun: copiaría manifest plantilla $masterManifest -> $localManifest"
        } else {
            Copy-Item -LiteralPath $masterManifest -Destination $localManifest -Force
            Write-OK "  [upgrade_framework] Manifest plantilla copiado: $localManifest"
        }
    }

    # Resolver ruta del script upgrade_framework.ps1 (en la raíz del proyecto, copiado por Sync-TransversalKit).
    $upgradeScript = Join-Path $RootPath "upgrade_framework.ps1"
    if (-not (Test-Path -LiteralPath $upgradeScript)) {
        Write-Warn "  [upgrade_framework] Script no encontrado en $upgradeScript; se omite (fail-open)."
        return
    }

    # Construir argumentos para invocación.
    $invokeArgs = @(
        "-RootPath", $RootPath
    )
    if ($ForceUpgradeTools) { $invokeArgs += "-ForceUpgradeTools" }
    if ($DryRun) { $invokeArgs += "-DryRun" }

    # Invocación fail-open: try/catch, WARN + continue, exit code ignorado.
    try {
        Write-Info "  [upgrade_framework] Ejecutando: pwsh -NoProfile -File $upgradeScript $($invokeArgs -join ' ')"
        if ($DryRun) {
            Write-Info "  [upgrade_framework] DryRun: simula sync de dependencias (no escribe)."
        } else {
            $exitCode = 0
            try {
                pwsh -NoProfile -File $upgradeScript @invokeArgs 2>&1 | ForEach-Object { Write-Host "    $_" }
                $exitCode = $LASTEXITCODE
            } catch {
                $exitCode = 1
                Write-Warn "  [upgrade_framework] Excepción: $_"
            }
            if ($exitCode -ne 0) {
                Write-Warn "  [upgrade_framework] Terminó con exit code $exitCode (fail-open: se continúa)."
            } else {
                Write-OK "  [upgrade_framework] Sincronización completada."
            }
        }
    } catch {
        Write-Warn "  [upgrade_framework] Error invocando script: $_ (fail-open: se continúa)."
    }
}

# Sync-TransversalKit (T-I1 / RF-01, RF-02, RF-11: absorbe la lógica de sync-agents.ps1)
# =============================================================================
# Copia SOLO los transversales del repo maestro. NUNCA toca
# Documentacion/<AppName>/ (frontera kit <-> app, guardrail 1).
# Seguridad: excluye .opencode/config.json (posibles credenciales) y valida
# la URL fail-closed (solo https://github.com/).
# T-I7 / RF-12: al final (dentro del try, con el clon aún disponible) detecta
# huérfanos con Find-OrphanKitFiles + Invoke-OrphanDecision (flag -OrphanAction).
# Usa las variables de ámbito del script: $DryRun (simula) y $Force (sobrescribe).
function Sync-TransversalKit {
    param(
        [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
        [string]$RootPath = "",
        [string]$OrphanAction = ""
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    # T-I7 / RF-12: -OrphanAction (Borrar|Conservar|Preguntar). Si no se pasa,
    # hereda del ámbito del script (flag CLI -OrphanAction); default: Preguntar.
    if (-not $OrphanAction) {
        if (Get-Variable -Name OrphanAction -Scope Script -ErrorAction SilentlyContinue) {
            $OrphanAction = $script:OrphanAction
        }
    }
    $orphanNorm = @{ "borrar" = "Borrar"; "conservar" = "Conservar"; "preguntar" = "Preguntar" }
    $orphanKey = "$OrphanAction".Trim().ToLowerInvariant()
    if ($orphanNorm.ContainsKey($orphanKey)) { $OrphanAction = $orphanNorm[$orphanKey] } else {
        if ($OrphanAction) { Write-Warn "Sync-TransversalKit: -OrphanAction '$OrphanAction' no válido (Borrar|Conservar|Preguntar). Se usa 'Preguntar'." }
        $OrphanAction = "Preguntar"
    }

    # Fail-closed: solo https://github.com/ (rechaza http://, git://, ssh, otras hosts).
    if ($RepoUrl -notlike "https://github.com/*") {
        throw "[SECURITY] URL no permitida (fail-closed): $RepoUrl (solo https://github.com/)"
    }
    if (-not (Test-TrustedGithubUrl $RepoUrl)) {
        throw "[SECURITY] Repo maestro no permitido (fail-closed): $RepoUrl (solo https://github.com/<owner en allowlist>/<repo>)"
    }

    Write-Step "Sincronizando kit transversal desde $RepoUrl..."

    # Lista blanca de transversales. Documentacion/<AppName>/ NO figura aquí por diseño.
    $transversalDirs = @(".github/", ".opencode/", ".doc_agents/")
    $transversalFiles = @(
        ".specify/memory/constitution.md",
        "AGENTS.md",
        "opencode.json",
        "README.md",
        "sync-agents.ps1",
        "upgrade_framework.ps1"
    )

    if ($DryRun) {
        Write-Info "DryRun: clonaría shallow `"$RepoUrl`" en `$env:TEMP\agents-sync-temp"
        foreach ($d in $transversalDirs) {
            Write-Info "DryRun: copiaría $d -> $(Join-Path $RootPath $d)"
        }
        foreach ($f in $transversalFiles) {
            Write-Info "DryRun: copiaría $f -> $(Join-Path $RootPath $f)"
        }
        Write-Info "DryRun: excluiría .opencode/config.json (posibles credenciales, nunca se copia)"
        Write-Info "DryRun: hash-guard .opencode/.gitignore: si el local existe y difiere del maestro se CONSERVA el local (fail-closed); solo -Force sobrescribe; nunca se pierde la línea 'config.json'"
        Write-Info "DryRun: verificaría que .opencode/.gitignore existe tras el sync (si falta se restauraría desde el maestro) + detectaría .opencode/config.json trackeado (WARN con git rm --cached + rotar keys)"
        Write-Info "DryRun: NUNCA tocaría Documentacion/<AppName>/ (frontera kit <-> app)"
        Write-Info "DryRun: detectaría huérfanos (local en .github/ .opencode/ .doc_agents/ no existentes en el maestro) y aplicaría -OrphanAction $OrphanAction (Preguntar/Borrar/Conservar; default seguro Conservar; sin borrar ni mover nada)"
        return
    }

    $tempDir = Join-Path $env:TEMP "agents-sync-temp"
    try {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

        Write-Host "  Clonando repo maestro..." -NoNewline
        git clone --depth 1 $RepoUrl $tempDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host " ERROR" -ForegroundColor Red
            throw "No se pudo clonar el repo maestro $RepoUrl (verifica git y URL)."
        }
        Write-Host " OK" -ForegroundColor Green

        $commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
        $commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
        Write-Info "Versión repo maestro: $commitHash ($commitDate)"

        $transversalItems = @(
            @{ Source = (Join-Path $tempDir ".github");                    Target = (Join-Path $RootPath ".github");                    Type = "Dir";  Label = ".github/" },
            @{ Source = (Join-Path $tempDir ".opencode");                  Target = (Join-Path $RootPath ".opencode");                  Type = "Dir";  Label = ".opencode/" },
            @{ Source = (Join-Path $tempDir ".doc_agents");                Target = (Join-Path $RootPath ".doc_agents");                Type = "Dir";  Label = ".doc_agents/" },
            @{ Source = (Join-Path $tempDir ".specify/memory/constitution.md"); Target = (Join-Path $RootPath ".specify/memory/constitution.md"); Type = "File"; Label = ".specify/memory/constitution.md (base)" },
            @{ Source = (Join-Path $tempDir "AGENTS.md");                  Target = (Join-Path $RootPath "AGENTS.md");                  Type = "File"; Label = "AGENTS.md" },
            @{ Source = (Join-Path $tempDir "opencode.json");              Target = (Join-Path $RootPath "opencode.json");              Type = "File"; Label = "opencode.json" },
            @{ Source = (Join-Path $tempDir "README.md");                  Target = (Join-Path $RootPath "README.md");                  Type = "File"; Label = "README.md" },
            @{ Source = (Join-Path $tempDir "sync-agents.ps1");            Target = (Join-Path $RootPath "sync-agents.ps1");            Type = "File"; Label = "sync-agents.ps1" },
            @{ Source = (Join-Path $tempDir "upgrade_framework.ps1");      Target = (Join-Path $RootPath "upgrade_framework.ps1");      Type = "File"; Label = "upgrade_framework.ps1" }
        )

        foreach ($item in $transversalItems) {
            $src = $item.Source
            $dst = $item.Target
            $dstDir = if ($item.Type -eq "File") { Split-Path $dst -Parent } else { $dst }
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

            if ($item.Type -eq "Dir") {
                Write-Host "  [SYNC] $($item.Label)" -ForegroundColor Cyan
                if ($item.Label -eq ".opencode/") {
                    # [BLINDAJE-GIT] T-I2 hash-guard .opencode/.gitignore (RF-B2/B3, riesgo 4):
                    # si el local existe y difiere del maestro -> conservar local + WARN, solo -Force sobrescribe.
                    $masterGi = Join-Path $src ".gitignore"
                    $localGi = Join-Path $dst ".gitignore"
                    $giGuardHold = $false
                    if ((Test-Path -LiteralPath $masterGi -PathType Leaf) -and (Test-Path -LiteralPath $localGi -PathType Leaf) -and (-not $Force)) {
                        try {
                            $mh = (Get-FileHash -LiteralPath $masterGi -Algorithm SHA256 -ErrorAction Stop).Hash
                            $lh = (Get-FileHash -LiteralPath $localGi -Algorithm SHA256 -ErrorAction Stop).Hash
                            if ($mh -ne $lh) {
                                Write-Warn "  [GUARD] .opencode/.gitignore local difiere del maestro: se CONSERVA el local (fail-closed). Usa -Force para sobrescribir (único bypass consciente)."
                                $giGuardHold = $true
                            }
                        } catch {
                            Write-Warn "  [GUARD] No se pudo comparar .opencode/.gitignore (hash falló): se conserva el local por seguridad."
                            $giGuardHold = $true
                        }
                    }
                    # Seguridad: nunca copiar .opencode/config.json (posibles credenciales).
                    if ($giGuardHold) {
                        robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" ".gitignore" >$null 2>&1
                    } else {
                        robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" >$null 2>&1
                    }
                    # [BLINDAJE-GIT] T-I3(c): verificar que .opencode/.gitignore existe tras el sync; si falta -> WARN + crear desde el maestro.
                    if (-not (Test-Path -LiteralPath $localGi -PathType Leaf)) {
                        if (Test-Path -LiteralPath $masterGi -PathType Leaf) {
                            Write-Warn "  [GUARD] .opencode/.gitignore ausente tras sync: se restaura desde el maestro."
                            Copy-Item -LiteralPath $masterGi -Destination $localGi -Force
                        } else {
                            Write-Warn "  [GUARD] .opencode/.gitignore ausente en local y en maestro: protección de secrets degradada; no hacer commit de config.json."
                        }
                    } else {
                        # Nunca perder la línea config.json (fail-closed informativo).
                        try {
                            $giTextAfter = Get-Content -LiteralPath $localGi -Raw -ErrorAction Stop
                            if ($giTextAfter -notmatch '(?m)^config\.json\s*$') {
                                Write-Warn "  [GUARD] .opencode/.gitignore local SIN línea 'config.json': protección de secrets degradada; revísalo antes de commitear."
                            }
                        } catch { }
                    }
                    # [BLINDAJE-GIT] Baseline lib/bin (riesgo 3, sin pin en manifest): si aparecen contenidos -> WARN supply-chain.
                    foreach ($ab in @("lib", "bin")) {
                        $abFull = Join-Path $dst $ab
                        try {
                            if (Test-Path -LiteralPath $abFull) {
                                $abFiles = @(Get-ChildItem -LiteralPath $abFull -Recurse -File -Force -ErrorAction Stop)
                                if ($abFiles.Count -gt 0) {
                                    Write-Warn "  [GUARD] .opencode/$ab con $($abFiles.Count) archivo(s): tratar como NO confiable hasta pin+hash en manifest (supply-chain); no ejecutar sin verificar."
                                }
                            }
                        } catch { }
                    }
                } else {
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XD "context-mode" >$null 2>&1
                }
            } else {
                if ((Test-Path $dst) -and (-not $Force)) {
                    $srcHash = (Get-FileHash $src).Hash
                    $dstHash = (Get-FileHash $dst).Hash
                    if ($srcHash -eq $dstHash) {
                        Write-OK "  [OK] $($item.Label) — sin cambios"
                    } else {
                        Write-Warn "  [SKIP] $($item.Label) — existe y difiere; usa -Force para sobrescribir (se conserva local)"
                    }
                    continue
                }
                Write-Host "  [FILE] $($item.Label)" -ForegroundColor Cyan
                # [007-MCP] A1/T604: guard del sync sobre opencode.json — preservar
                # el bloque `mcp` resuelto localmente al copiar la plantilla del
                # maestro (merge selectivo) para no degradar enabled:true -> tokens.
                # Idempotente y fail-open: parseo roto -> conserva el local + WARN.
                if ($item.Label -eq "opencode.json" -and (Test-Path -LiteralPath $dst)) {
                    $merged = $false
                    try {
                        $srcJson = Get-Content -LiteralPath $src -Raw -ErrorAction Stop | ConvertFrom-Json
                        $dstJson = Get-Content -LiteralPath $dst -Raw -ErrorAction Stop | ConvertFrom-Json
                        if (($null -ne $dstJson.mcp) -and ($null -ne $srcJson)) {
                            # Reinsertar el `mcp` local en la plantilla del maestro.
                            if ($srcJson.PSObject.Properties["mcp"]) {
                                $srcJson.PSObject.Properties.Remove("mcp")
                            }
                            $srcJson | Add-Member -NotePropertyName "mcp" -NotePropertyValue $dstJson.mcp -Force
                            $srcJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $dst -Encoding UTF8
                            Write-OK "  [GUARD] opencode.json: bloque mcp local PRESERVADO (merge con la plantilla del maestro)."
                            $merged = $true
                        }
                    } catch {
                        Write-Warn "  [GUARD] opencode.json: no se pudo mergear el bloque mcp local ($_); se conserva el local sin sobrescribir."
                        $merged = $true
                    }
                    if ($merged) { continue }
                }
                Copy-Item $src -Destination $dst -Force
            }
        }

        # Seguridad: confirmar que .opencode/config.json del kit NO se copió.
        $kitConfig = Join-Path $tempDir ".opencode\config.json"
        if (Test-Path $kitConfig) {
            Write-Warn "Se excluye .opencode/config.json (posibles credenciales) de la sincronización."
        }

        # [BLINDAJE-GIT] T-I3 detección defensiva config.json trackeado (riesgo 1, AC-6):
        # si git ls-files lo lista -> WARN con git rm --cached + rotar keys (solo lectura, también informa en DryRun-real).
        try {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                $trackedCfg = & git -C $RootPath ls-files -- ".opencode/config.json" 2>$null
                if ($trackedCfg) {
                    Write-Warn ".opencode/config.json está TRACKEADO por git (posibles secrets versionados): ejecuta git rm --cached .opencode/config.json y ROTA las keys (borrar no basta, quedan en el historial)."
                }
            }
        } catch { }

        # T-I7 / RF-12: manejo de huérfanos (dentro del try: $tempDir sigue
        # disponible; el finally lo limpia después). Find-OrphanKitFiles hace
        # throw si el maestro está incompleto (fail-closed: nada se borra).
        $orphans = @(Find-OrphanKitFiles -RootPath $RootPath -TempDir $tempDir)
        Invoke-OrphanDecision -Orphans $orphans -RootPath $RootPath -OrphanAction $OrphanAction

        Write-OK "Kit transversal sincronizado (commit $commitHash). Documentacion/<AppName>/ NO fue tocada."
    }
    catch { Write-Warn "Error en Sync-TransversalKit: $_" }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# =============================================================================
# Resolve-ActiveApp (T-I1 / RF-07): -App > cwd dentro de app conocida > root
# =============================================================================
# Precedencia: 1) -AppName si se pasó -> ese nombre. 2) cwd dentro de una app
# conocida (src\<app>\ o \<app>\ en la raíz). 3) "root" (kit, sin doc de app).
# Devuelve el nombre de la app (string).
function Resolve-ActiveApp {
    param(
        [string]$AppName = "",
        [string]$RootPath = ""
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    # [SOLUCION-GENERICA] RF-S3: lista resuelta del proyecto (flag/manifest/
    # src/*); vacía + WARN si no hay nada (nunca hardcodeada).
    $effectiveApps = @(Resolve-AppList -RootPath $RootPath)

    # 1) Flag -App (equivale a -AppName): precedencia máxima.
    if ($AppName) {
        if (($AppName -ne "root") -and ($AppName -notin $effectiveApps)) {
            Write-Warn "App '$AppName' no está en la lista resuelta ($($effectiveApps -join ', ')); se usa igual por precedencia del flag."
        }
        Write-Info "App activa resuelta por flag -App: $AppName"
        return $AppName
    }

    # 2) cwd dentro de una app conocida: src\<app>\ o \<app>\ en la raíz.
    $cwd = (Get-Location).Path
    foreach ($known in $effectiveApps) {
        $inSrc = $cwd -like "*src\$known*"
        $inRoot = $cwd -like "*\$known*"
        $anchored = $false
        foreach ($candidate in @(
            (Join-Path $RootPath "src\$known"),
            (Join-Path $RootPath "$known")
        )) {
            if ($cwd.StartsWith($candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
                $anchored = $true
                break
            }
        }
        if ($anchored -or $inSrc -or $inRoot) {
            # Desambiguar: exigir coincidencia anclada o segmento exacto para no
            # confundir nombres parciales; el anclado manda.
            if ($anchored) {
                Write-Info "App activa resuelta por cwd dentro de app: $known ($cwd)"
                return $known
            }
        }
    }
    # Segunda pasada solo con segmento exacto (evita falsos positivos de $inRoot).
    foreach ($known in $effectiveApps) {
        $segments = $cwd -split '[\\/]'
        if ($segments -contains $known) {
            # Verificar que el segmento corresponde a src\<app> o <raíz>\<app>.
            if (($cwd -like "*src\$known*") -or ($cwd -like "*\$known*")) {
                Write-Info "App activa resuelta por cwd dentro de app: $known ($cwd)"
                return $known
            }
        }
    }

    # 3) Sin coincidencia -> root (kit, sin doc de app).
    Write-Info "Sin coincidencia de cwd con apps conocidas; app activa: root (kit, sin doc de app)"
    return "root"
}

# =============================================================================
# Ensure-AppStructure (T-I2 / RF-06): estructura mínima de Documentacion/<AppName>/
# =============================================================================
# Asegura Documentacion/<AppName>/ con lo mínimo de estructura-aplicacion.md:
# 00-indice.md (nombre de la app + fecha), pendientes-implementacion.md
# (plantilla base), specs/, arquitectura/adr/, bitacoras/.
# No sobrescribe archivos existentes salvo -Force. Respeta -DryRun (solo
# informa). Nunca toca src/, tests/ ni la documentación de otras apps.
function Ensure-AppStructure {
    param(
        [string]$AppName = "",
        [string]$RootPath = ""
    )

    if (-not $AppName) {
        Write-Warn "Ensure-AppStructure sin AppName; se omite."
        return
    }

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    $appDoc = Join-Path $RootPath "Documentacion\$AppName"
    Ensure-Directory $appDoc
    Ensure-Directory (Join-Path $appDoc "specs")
    Ensure-Directory (Join-Path $appDoc "arquitectura\adr")
    Ensure-Directory (Join-Path $appDoc "bitacoras")

    $today = Get-Date -Format "yyyy-MM-dd"

    $indexPath = Join-Path $appDoc "00-indice.md"
    if ((-not (Test-Path $indexPath)) -or $Force) {
        $indexContent = @"
# Índice — $AppName

> Documentación técnica PROPIA de la aplicación **$AppName**.
> Generada por ``plataformador-bootstrap.ps1`` (instalador/actualizador único).
> Fecha: $today

## Estructura
- ``specs/`` — Specs (Spec-kit escribe spec.md/plan.md/tasks.md aquí)
- ``arquitectura/adr/`` — Decisiones de arquitectura de ESTA app
- ``bitacoras/`` — Bitácoras de intervenciones de ESTA app
- ``pendientes-implementacion.md`` — Puente docs ↔ código
"@
        if ($DryRun) {
            Write-Info "DryRun: crear $indexPath"
        } else {
            Set-Content -Path $indexPath -Value $indexContent -Encoding UTF8
            Write-OK "Índice creado: $indexPath"
        }
    }

    $pendingPath = Join-Path $appDoc "pendientes-implementacion.md"
    if ((-not (Test-Path $pendingPath)) -or $Force) {
        $pendingContent = @"
# Pendientes de implementación — $AppName

> Puente vivo entre documentación e implementación de ESTA app.
> Fecha: $today

- [ ] Revisar estructura y pendientes iniciales de ``$AppName``
"@
        if ($DryRun) {
            Write-Info "DryRun: crear $pendingPath"
        } else {
            Set-Content -Path $pendingPath -Value $pendingContent -Encoding UTF8
            Write-OK "Pendientes creados: $pendingPath"
        }
    }

    if ($DryRun) {
        Write-Info "DryRun: estructura de Documentacion/$AppName/ verificada (sin escribir)."
    } else {
        Write-OK "Estructura lista: Documentacion/$AppName/"
    }
}

# =============================================================================
# Ensure-SrcAppStructure (RF-XX): estructura completa de src/<AppName>/ con .specify
# =============================================================================
# Crea src/<AppName>/ si no existe, copia .specify desde la base (<RootPath>/.specify)
# y asegura Documentacion/<AppName>/ con Ensure-AppStructure.
# Genérico: recibe lista de apps por parámetro (no hardcodeado).
# Respeta -DryRun (solo informa), -Force (sobrescribe .specify si ya existe).
# Nunca clona repos; solo prepara la estructura local.
function Ensure-SrcAppStructure {
    param(
        [string[]]$Apps = @(),
        [string]$RootPath = "",
        [switch]$Force
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    $baseSpecify = Join-Path $RootPath ".specify"
    if (-not (Test-Path $baseSpecify)) {
        Write-Warn "No existe .specify base en $baseSpecify; no se puede copiar a las apps."
        return
    }

    if ($Apps.Count -eq 0) {
        Write-Warn "Ensure-SrcAppStructure sin lista de apps; se omite."
        return
    }

    Write-Step "Asegurando estructura src/<App>/ con .specify para cada app..."
    foreach ($app in $Apps) {
        $srcAppDir = Join-Path $RootPath "src\$app"
        $appSpecify = Join-Path $srcAppDir ".specify"

        # 1) Crear directorio src/<app>/
        if (-not (Test-Path $srcAppDir)) {
            if ($DryRun) {
                Write-Info "DryRun: crear directorio $srcAppDir"
            } else {
                Ensure-Directory $srcAppDir
                Write-OK "Directorio creado: $srcAppDir"
            }
        }

        # 2) Copiar .specify desde la base
        $needsCopy = (-not (Test-Path $appSpecify)) -or $Force
        if ($needsCopy) {
            if ($DryRun) {
                Write-Info "DryRun: copiar $baseSpecify -> $appSpecify"
            } else {
                Copy-Item -Path $baseSpecify -Destination $appSpecify -Recurse -Force
                Write-OK ".specify copiado a: $appSpecify"
            }
        } else {
            Write-Info ".specify ya existe en $appSpecify (usa -Force para sobrescribir)"
        }

        # 3) Asegurar Documentacion/<App>/
        if ($DryRun) {
            Write-Info "DryRun: asegurar Documentacion/$app/ con Ensure-AppStructure"
        } else {
            Ensure-AppStructure -AppName $app -RootPath $RootPath
        }
    }
    Write-OK "Estructura src/<App>/ con .specify completada para: $($Apps -join ', ')"
}

# =============================================================================
# Ensure-AppSpecify + Ensure-AppDocumentation (T-I2 / RF-06)
# =============================================================================
function Copy-SpecifyBase {
    param([string]$RootPath, [string]$DestPath)
    $baseSpecify = Join-Path $RootPath ".specify"
    if (-not (Test-Path $DestPath) -and (Test-Path $baseSpecify)) {
        Write-Info "  Creando .specify para app desde la base: $DestPath"
        if (-not $DryRun) {
            Copy-Item -Path $baseSpecify -Destination $DestPath -Recurse -Force
        }
    }
}

function Ensure-AppDocumentation {
    param([string]$RootPath, [string]$AppName)

    # Base mínima según estructura-aplicacion.md (no sobrescribe, respeta -DryRun).
    Ensure-AppStructure -AppName $AppName -RootPath $RootPath

    $docRoot = Join-Path $RootPath "Documentacion"
    $appDoc  = Join-Path $docRoot $AppName
    if ($DryRun) {
        Write-Info "DryRun: crear Documentacion/$AppName/ (00-indice.md, pendientes-implementacion.md, specs/, arquitectura/adr/)"
        return
    }

    Ensure-Directory $appDoc
    Ensure-Directory (Join-Path $appDoc "specs")
    Ensure-Directory (Join-Path $appDoc "arquitectura\adr")
    Ensure-Directory (Join-Path $appDoc "agents")

    $indexPath = Join-Path $appDoc "00-indice.md"
    if (-not (Test-Path $indexPath)) {
        $content = @"
# 📋 Índice — $AppName

> Documentación técnica PROPIA de la aplicación **$AppName**.
> Generada por `plataformador-bootstrap.ps1` (instalador/actualizador único).

## Estructura
- `specs/` — Specs (Spec-kit escribe spec.md/plan.md/tasks.md aquí)
- `arquitectura/adr/` — Decisiones de arquitectura de ESTA app
- `agents/` — Configuración de agentes para ESTA app
- `pendientes-implementacion.md` — Puente docs ↔ código
- `memoria-proyecto.md` — Capacidades instaladas en ESTA app
"@
        Set-Content -Path $indexPath -Value $content -Encoding UTF8
    }

    $pendingPath = Join-Path $appDoc "pendientes-implementacion.md"
    if (-not (Test-Path $pendingPath)) {
        $pending = @"
# Pendientes de implementación — $AppName

> Puente vivo entre documentación e implementación de ESTA app.

- [ ] Revisar estructura y pendientes iniciales de `$AppName`
"@
        Set-Content -Path $pendingPath -Value $pending -Encoding UTF8
    }

    $memoriaPath = Join-Path $appDoc "memoria-proyecto.md"
    if (-not (Test-Path $memoriaPath)) {
        $mem = @"
# Memoria de proyecto — $AppName

> Capacidades instaladas y estado de ESTA app.
"@
        Set-Content -Path $memoriaPath -Value $mem -Encoding UTF8
    }
    Write-OK "Documentación de app preparada: Documentacion/$AppName/"
}

# =============================================================================
# Prepare-Apps (T-I3 / RF-05): verificar apps sin mover ni clonar (RNF-04, RNF-06)
# =============================================================================
# Para cada app conocida verifica src\<app>\ primero y luego \<app>\ en la raíz.
# Existe en alguna -> Write-OK (se respeta su ubicación, NO se mueve nada) y se
# asegura su Documentacion/<AppName>/ con Ensure-AppStructure.
# No existe en ninguna -> Write-Warn (su URL git debe registrarse en el
# manifest; NO se clona nada todavía porque las URLs no están validadas).
# Además confirma que proyect_ext/spec-kit queda en la raíz (no se mueve).
# Respeta -DryRun (solo informa). Nunca ejecuta scripts descargados.
function Prepare-Apps {
    param([string]$RootPath = "")

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    Write-Step "Preparando apps (verificación sin mover ni clonar)..."

    # [SOLUCION-GENERICA] RF-S3/RF-S5: lista resuelta del proyecto: -Apps
    # explícito > manifest del proyecto > descubrimiento src/* > vacía + WARN.
    $apps = @($Apps | Where-Object { $_ -ne "" })
    if ($apps.Count -eq 0) { $apps = @(Resolve-AppList -RootPath $RootPath) }
    if ($apps.Count -eq 0) {
        Write-Warn "Sin apps que preparar (lista vacía; pasa -Apps o define el manifest local). Nada que instalar."
    }
    foreach ($app in $apps) {
        $inSrc = Join-Path $RootPath "src\$app"
        $inRoot = Join-Path $RootPath "$app"
        if (Test-Path $inSrc) {
            Write-OK "App '$app' existe en: $inSrc (se respeta su ubicación, RNF-04; no se mueve nada)"
            if ($DryRun) {
                Write-Info "DryRun: aseguraría Documentacion/$app/ con Ensure-AppStructure"
            } else {
                Ensure-AppStructure -AppName $app -RootPath $RootPath
            }
            continue
        }
        if (Test-Path $inRoot) {
            Write-OK "App '$app' existe en: $inRoot (se respeta su ubicación, RNF-04; no se mueve nada)"
            if ($DryRun) {
                Write-Info "DryRun: aseguraría Documentacion/$app/ con Ensure-AppStructure"
            } else {
                Ensure-AppStructure -AppName $app -RootPath $RootPath
            }
            continue
        }
        Write-Warn "App '$app' no encontrada en src\$app ni en $app; su URL git debe registrarse en dependencias-manifest.yml (no se clona nada sin URLs validadas, RNF-06)."
        # TODO: cuando las URLs estén validadas (allowlist de owners + licencia
        # verificada, guardrails 3 y 8), clonar shallow aquí:
        #   git clone --depth 1 <url-validada> (Join-Path $RootPath "src\$app")
    }

    $specKitDir = Join-Path $RootPath "proyect_ext\spec-kit"
    if (Test-Path $specKitDir) {
        Write-OK "proyect_ext/spec-kit queda en la raíz (no se mueve, decisión 3)."
    } else {
        Write-Info "proyect_ext/spec-kit no existe en la raíz; nada que mover (queda ahí por diseño)."
    }

    if ($DryRun) {
        Write-Info "DryRun: Prepare-Apps solo informa, no escribe nada."
    }
}

# =============================================================================
# Configure-SpecKit (T-I2 / RF-08): orientar Spec-kit a la app activa
# =============================================================================
# root -> .specify activo = <RootPath>/.specify, specs dir =
#         <RootPath>/Documentacion/Agents_IA_TECH/specs (doc del kit).
# app  -> .specify activo = <appDir>/.specify (<appDir> se busca primero en
#         <RootPath>/src/<app>/ y luego en <RootPath>/<app>/, tolerancia RNF-04;
#         si no existe se crea copiando desde <RootPath>/.specify/ base, solo si
#         existe la base; si no, Write-Warn y se sigue), specs dir =
#         <RootPath>/Documentacion/<AppName>/specs/ (se asegura el directorio).
# Devuelve @{ SpecDir = ...; SpecsDir = ...; AppDir = ... } e informa con
# Write-OK. Respeta -DryRun. Nunca ejecuta scripts descargados.
function Configure-SpecKit {
    param(
        [string]$ActiveApp = "root",
        [string]$RootPath = ""
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    if ($ActiveApp -eq "root") {
        $appDir = $RootPath
        $specDir = Join-Path $RootPath ".specify"
        $specsDir = Join-Path $RootPath "Documentacion\Agents_IA_TECH\specs"
        Write-Info ".specify activo (kit/root): $specDir"
    } else {
        $appDir = Join-Path $RootPath "src\$ActiveApp"
        if (-not (Test-Path $appDir)) {
            $candidateRoot = Join-Path $RootPath $ActiveApp
            if (Test-Path $candidateRoot) { $appDir = $candidateRoot }
        }
        if (Test-Path $appDir) {
            Write-Info "App '$ActiveApp' resuelta en: $appDir (se respeta su ubicación, RNF-04)"
        } else {
            Write-Warn "App '$ActiveApp' no existe en src\ ni en raíz; se usa la raíz como AppDir."
            $appDir = $RootPath
        }
        $specDir = Join-Path $appDir ".specify"
        if (-not (Test-Path $specDir)) {
            $baseSpecify = Join-Path $RootPath ".specify"
            if (Test-Path $baseSpecify) {
                Write-Info "Creando .specify de app desde la base: $specDir"
                if (-not $DryRun) {
                    Copy-Item -Path $baseSpecify -Destination $specDir -Recurse -Force
                } else {
                    Write-Info "DryRun: copiaría $baseSpecify -> $specDir"
                }
            } else {
                Write-Warn "No existe .specify base en $baseSpecify; no se crea el de la app (se sigue)."
            }
        }
        $specsDir = Join-Path $RootPath "Documentacion\$ActiveApp\specs"
    }

    Ensure-Directory $specsDir
    Write-Info ".specify activo: $specDir"
    Write-Info "Specs dir: $specsDir (Spec-kit escribe spec.md/plan.md/tasks.md aquí)"
    Write-OK "Spec-kit orientado a: $ActiveApp"
    return @{ SpecDir = $specDir; SpecsDir = $specsDir; AppDir = $appDir }
}

# =============================================================================
# Configure-Graphify (RF-19 / criterio 15 — [GRAPHIFY-INSTALL]; refina RF-09)
# =============================================================================
# Árbol de decisión MCP-preferido (spec plataforma-bootstrap-instalador-unico):
# Rama A (preferida): si el CLI `graphify` está disponible (Get-Command) y el
# módulo MCP embebido responde (`python -m graphify.serve --help` EXIT 0),
# registra el MCP stdio en opencode.json (type: local,
# command: [python, -m, graphify.serve, <root>/graphify-out/graph.json]) +
# .vscode/mcp.json (type: stdio). Rama B (fallback): el CLI como herramienta
# Python instalada (patrón markitdown); sin CLI -> WARN con instrucciones
# (cita dependencias-manifest.yml), no falla, no registra.
# Controles (seguridad/graphify.md, no negociables): stdio SIEMPRE (jamás
# --transport http en config persistente); sin secrets en args/configs; el
# grafo se construye excluyendo carpetas con secrets
# (`graphify extract <path> --code-only`); si <root>/graphify-out/graph.json
# aún no existe se registra igual (el servidor arranca sin grafo y cada
# herramienta acepta project_path) pero se avisa cómo construirlo. -DryRun
# informa, no escribe. Estilo: Write-*, Add-Member -Force para props nuevas
# (bug conocido: la asignación directa falla en pwsh 7.6); IDictionary-aware
# como Ensure-OpenCodeMcp (RF-16).
# [BOOTSTRAP-FIXES] F6: Graphify estructura-first con detección de estado
# (ADR-0004 RF-07): sin grafo -> extract --code-only; grafo existe -> update
# (incremental, sin LLM); -GraphifyDeep -> extract --mode deep solo con backend
# LLM (env OPENAI/ANTHROPIC/GEMINI/DEEPSEEK/KIMI_API_KEY); si no, WARN y sigue.
function Configure-Graphify {
    param(
        [string]$RootPath = "",
        # [BOOTSTRAP-FIXES] F6: scope del grafo: App (default) = app activa
        # (resultado de Resolve-ActiveApp) / Workspace = raíz del proyecto.
        [ValidateSet("App", "Workspace")]
        [string]$GraphifyScope = "App",
        [string]$ActiveApp = "",
        # [BOOTSTRAP-FIXES] F6: -GraphifyDeep -> extract --mode deep SOLO con backend LLM.
        [switch]$GraphifyDeep
    )

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    Write-Step "Configurando Graphify (RF-19, MCP-preferido)..."

    # --- Detección Rama A: CLI graphify (paquete PyPI graphifyy, doble-y) ---
    $graphifyCmd = Get-Command graphify -ErrorAction SilentlyContinue
    if (-not $graphifyCmd) {
        Write-Warn 'Graphify no instalado (comando graphify no está en el PATH). Para la Rama A (MCP stdio): instala el paquete oficial graphifyy (doble-y, versión fijada en dependencias-manifest.yml, entrada graphify): uv tool install "graphifyy[mcp]" (aislado, preferido) o pip install "graphifyy[mcp]". El bootstrap continúa sin Graphify.'
        if ($DryRun) {
            Write-Info "DryRun: Configure-Graphify solo informa, no escribe nada."
        }
        return
    }
    Write-OK "Graphify detectado: $($graphifyCmd.Source)"

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        Write-Warn "python no está en el PATH (se requiere 3.10+); no se puede registrar 'python -m graphify.serve'. Se omite Graphify; el bootstrap continúa."
        return
    }

    # Verificar que el comando stdio documentado existe (módulo + extra mcp).
    # Containment: solo se registra este comando exacto, sin --transport http.
    $serveOK = $false
    try {
        & $pythonCmd.Source -m graphify.serve --help 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $serveOK = $true }
    } catch { $serveOK = $false }
    if (-not $serveOK) {
        Write-Warn 'El módulo MCP embebido no responde (python -m graphify.serve --help falló): falta el extra mcp — reinstala con uv tool install "graphifyy[mcp]" (o pip install "graphifyy[mcp]"). No se registra la entrada (evita config rota); el bootstrap continúa.'
        return
    }
    Write-OK "MCP embebido verificado: python -m graphify.serve (stdio por defecto)"

    # --- [BOOTSTRAP-FIXES] F6: scope del grafo (ADR-0004 RF-07) ---
    # App (default) = app activa (resultado de Resolve-ActiveApp, paso 5) en
    # src/<App>/ (tolerancia RNF-04: <App>/ en raíz); Workspace = raíz del
    # proyecto. En el proyecto kit (app activa "root") -> raíz.
    $graphScopePath = $RootPath
    if ($GraphifyScope -eq "App" -and $ActiveApp -and $ActiveApp -ne "root") {
        $appDirG = Join-Path $RootPath "src\$ActiveApp"
        if (-not (Test-Path -LiteralPath $appDirG)) {
            $candidateRootG = Join-Path $RootPath $ActiveApp
            if (Test-Path -LiteralPath $candidateRootG) { $appDirG = $candidateRootG }
        }
        if (Test-Path -LiteralPath $appDirG) {
            $graphScopePath = $appDirG
            Write-Info "Graphify scope: App -> $graphScopePath"
        } else {
            Write-Warn "Graphify scope App: app '$ActiveApp' no existe en src\ ni en raíz; se usa la raíz."
        }
    } else {
        Write-Info "Graphify scope: $GraphifyScope -> $graphScopePath"
    }

    # --- Grafo local: <scope>/graphify-out/graph.json (containment-check) ---
    $graphBase = Join-Path $graphScopePath "graphify-out"
    $graphPath = Join-Path $graphBase "graph.json"
    $sepG = [IO.Path]::DirectorySeparatorChar
    $baseCanonG = [IO.Path]::GetFullPath($graphBase)
    $graphCanonG = [IO.Path]::GetFullPath($graphPath)
    if (-not $graphCanonG.StartsWith($baseCanonG + $sepG, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Warn "Ruta del grafo fuera de containment ($graphPath); no se registra (fail-closed)."
        return
    }
    # --- [BOOTSTRAP-FIXES] F6: Graphify estructura-first con detección de estado (ADR-0004 RF-07) ---
    # 1) Sin grafo -> graphify extract <scope> --code-only (estructura, sin IA,
    #    sin secrets: --code-only solo indexa código y respeta .gitignore).
    # 2) Grafo existe -> graphify update <scope> (incremental, sin LLM).
    # 3) -GraphifyDeep -> graphify extract --mode deep (semántica con LLM) SOLO
    #    si hay backend LLM configurado; si no, WARN y se continúa.
    $hasLlmBackend = ($env:OPENAI_API_KEY) -or ($env:ANTHROPIC_API_KEY) -or
                     ($env:GEMINI_API_KEY) -or ($env:DEEPSEEK_API_KEY) -or ($env:KIMI_API_KEY)
    if ($GraphifyDeep -and -not $hasLlmBackend) {
        Write-Warn "-GraphifyDeep requiere backend LLM (env OPENAI_API_KEY/ANTHROPIC_API_KEY/GEMINI_API_KEY/DEEPSEEK_API_KEY/KIMI_API_KEY); no hay backend configurado: se usa --code-only (estructura, sin IA) y se continúa."
    }
    $graphifyCli = $graphifyCmd.Source
    $graphifyArgs = @()
    $graphAction = ""
    if ($GraphifyDeep -and $hasLlmBackend) {
        $graphAction = "extract --mode deep"
        $graphifyArgs = @("extract", $graphScopePath, "--mode", "deep")
    } elseif (-not (Test-Path -LiteralPath $graphCanonG)) {
        $graphAction = "extract --code-only"
        $graphifyArgs = @("extract", $graphScopePath, "--code-only")
    } else {
        $graphAction = "update"
        $graphifyArgs = @("update", $graphScopePath)
    }
    Write-OK "Grafo local: $graphCanonG ($(if (Test-Path -LiteralPath $graphCanonG) { 'existe' } else { 'nuevo' }))"
    if ($DryRun) {
        Write-Info "DryRun: graphify $($graphifyArgs -join ' ') (grafo: $graphCanonG)"
    } else {
        # RF-010: aviso visible de re-indexación en ejecución.
        Write-Info "Re-indexando Graphify ($graphAction)..."
        try {
            $gOut = & $graphifyCli @graphifyArgs 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-OK "Graphify $graphAction completado (grafo: $graphCanonG)"
            } else {
                Write-Warn "graphify $graphAction falló (exit $LASTEXITCODE): $(($gOut | Out-String).Trim())"
            }
        } catch {
            Write-Warn "graphify $graphAction falló: $_"
        }
    }

    # --- Registro en opencode.json (type: local, stdio, sin secrets) ---
    $opencodePath = Join-Path $RootPath "opencode.json"
    if (-not (Test-Path -LiteralPath $opencodePath)) {
        Write-Warn "No existe opencode.json en $RootPath; se omite el registro de graphify en OpenCode."
    } else {
        $existing = Get-Content -Path $opencodePath -Raw | ConvertFrom-Json
        if (($null -ne $existing.mcp) -and ($null -ne $existing.mcp.graphify) -and (-not $Force)) {
            Write-OK "opencode.json ya registra graphify; se conserva (usa -Force para sobrescribir)."
        } elseif ($DryRun) {
            Write-Info "DryRun: registraría graphify en opencode.json (type: local, command: [$($pythonCmd.Source), -m, graphify.serve, <root>/graphify-out/graph.json], enabled: true)"
        } else {
            $graphifyEntry = [ordered]@{
                type = "local"
                command = @($pythonCmd.Source, "-m", "graphify.serve", $graphCanonG)
                enabled = $true
            }
            if ($null -eq $existing.mcp) {
                $existing | Add-Member -NotePropertyName "mcp" -NotePropertyValue ([ordered]@{}) -Force
            }
            # $existing.mcp puede ser PSCustomObject (leído de JSON) o
            # OrderedDictionary (recién creado): Add-Member sobre un
            # IDictionary NO se serializa, en ese caso se agrega entrada.
            if ($existing.mcp -is [System.Collections.IDictionary]) {
                $existing.mcp["graphify"] = $graphifyEntry
            } else {
                $existing.mcp | Add-Member -NotePropertyName "graphify" -NotePropertyValue $graphifyEntry -Force
            }
            $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $opencodePath -Encoding UTF8
            Write-OK "graphify registrado como MCP stdio en opencode.json"
        }
    }

    # --- Registro en .vscode/mcp.json (type: stdio) ---
    $mcpPath = Join-Path $RootPath ".vscode\mcp.json"
    $mcpDir = Split-Path $mcpPath -Parent
    if (Test-Path -LiteralPath $mcpPath) {
        $mcpExisting = Get-Content -Path $mcpPath -Raw | ConvertFrom-Json
    } else {
        $mcpExisting = [pscustomobject]@{}
        if (-not $DryRun) { Ensure-Directory $mcpDir }
    }
    if (($null -ne $mcpExisting.servers) -and ($null -ne $mcpExisting.servers.graphify) -and (-not $Force)) {
        Write-OK ".vscode/mcp.json ya registra graphify; se conserva (usa -Force para sobrescribir)."
    } elseif ($DryRun) {
        Write-Info "DryRun: registraría graphify en .vscode/mcp.json (type: stdio, command: [$($pythonCmd.Source)], args: [-m, graphify.serve, <root>/graphify-out/graph.json])"
    } else {
        $graphifyServer = [ordered]@{
            command = $pythonCmd.Source
            args = @("-m", "graphify.serve", $graphCanonG)
            type = "stdio"
        }
        if ($null -eq $mcpExisting.servers) {
            $mcpExisting | Add-Member -NotePropertyName "servers" -NotePropertyValue ([ordered]@{}) -Force
        }
        if ($mcpExisting.servers -is [System.Collections.IDictionary]) {
            $mcpExisting.servers["graphify"] = $graphifyServer
        } else {
            $mcpExisting.servers | Add-Member -NotePropertyName "graphify" -NotePropertyValue $graphifyServer -Force
        }
        $mcpExisting | ConvertTo-Json -Depth 10 | Set-Content -Path $mcpPath -Encoding UTF8
        Write-OK "graphify registrado como MCP stdio en .vscode/mcp.json"
    }
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " Plataformador bootstrap - preparación del proyecto" -ForegroundColor Cyan
Write-Host " Proyecto: $ProjectRoot" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan

$resolvedRoot = (Resolve-Path $ProjectRoot).Path
Write-Info "Ruta resuelta: $resolvedRoot"

# [SELF-UPDATE] auto-actualización desde el maestro antes de ejecutar (fail-open)
if (-not $SkipSelfUpdate) {
    Update-Self -RootPath $resolvedRoot -RepoUrl $RepoUrl
}

Ensure-Directory (Join-Path $resolvedRoot ".vscode")
Ensure-Directory (Join-Path $resolvedRoot ".github\hooks")
Ensure-Directory (Join-Path $resolvedRoot "Documentacion")
Ensure-Directory (Join-Path $resolvedRoot "scripts")

if ($VerifyOnly) {
    Write-Step "Modo verificación únicamente (-VerifyOnly)"
    Verify-McpAndIndexes $resolvedRoot
    Show-VerificationCommands $resolvedRoot
    exit 0
}

if ($SyncOnly) {
    Write-Step "Modo sync únicamente (-SyncOnly): delegación de sync-agents.ps1"
    Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Green
    Write-Host " Sync de kit transversal completado" -ForegroundColor Green
    Write-Host "===============================================================" -ForegroundColor Green
    exit 0
}

Write-Step "1) Validando y preparando la estructura base..."
# [007-MCP] A2/D2: `.env.mcp` (fuente de verdad portable) se crea ANTES del
# primer Ensure-OpenCodeMcp para que la resolución de {env:...} sea determinista
# e idempotente entre los pasos 1 y 4.
Ensure-McpEnvFile -RootPath $resolvedRoot -Force:$Force
Ensure-ProjectDocumentation $resolvedRoot
Ensure-MemoryIndex $resolvedRoot
Ensure-VSCodeSettings $resolvedRoot
Ensure-McpJson $resolvedRoot
Ensure-OpenCodeMcp $resolvedRoot
Ensure-ContextHooks $resolvedRoot

Write-Step "2) Validando dependencias externas y MCPs..."
if (-not $SkipInstall) {
    # [BOOTSTRAP-FIXES] F4: capturar el boolean de Ensure-Command ($null =) —
    # sin captura, el `return $true` se escapaba y imprimía un `True` suelto
    # tras cada "[OK] Comando disponible:".
    $null = Ensure-Command -Name "npm" -InstallCommand "npm --version" -AllowMissing
    $null = Ensure-Command -Name "pip" -InstallCommand "python -m pip --version" -AllowMissing
    $null = Ensure-Command -Name "context-mode" -InstallCommand "npm install -g context-mode" -AllowMissing
    $null = Ensure-Command -Name "codebase-memory-mcp" -InstallCommand "npm install -g codebase-memory-mcp" -AllowMissing
    $null = Ensure-Command -Name "markitdown" -InstallCommand "python -m pip install 'markitdown[all]'" -AllowMissing
    $null = Ensure-Command -Name "markitdown-mcp" -InstallCommand "python -m pip install 'markitdown-mcp==0.0.1a3' 'mcp<2'" -AllowMissing
} else {
    Write-Info "Se omite la instalación de dependencias por -SkipInstall."
}

# [007-MCP] D3/RF-04: -ForceUpgradeTools (opt-in). Reinstala/actualiza las
# herramientas externas con nombres oficiales exactos, FAIL-OPEN (CN-4/CN-5):
# fallo -> WARN + continuar; sin el flag no se intenta ninguna instalación.
# No auto-compila terceros fuera del clon controlado de tokenslayer.
if ($ForceUpgradeTools) {
    Write-Step "2b) -ForceUpgradeTools: actualizando herramientas externas (fail-open)..."
    $upgradeSteps = @(
        @{ Name = "context-mode";        Cmd = "npm";    Args = @("install", "-g", "context-mode@latest") },
        @{ Name = "codebase-memory-mcp"; Cmd = "npm";    Args = @("install", "-g", "codebase-memory-mcp@latest") },
        @{ Name = "markitdown";          Cmd = "python"; Args = @("-m", "pip", "install", "--upgrade", "markitdown[all]") },
        @{ Name = "graphifyy[mcp]";      Cmd = "uv";     Args = @("tool", "install", "graphifyy[mcp]", "--force") }
    )
    foreach ($up in $upgradeSteps) {
        if (-not (Get-Command $up.Cmd -ErrorAction SilentlyContinue)) {
            Write-Warn "  - $($up.Name): '$($up.Cmd)' no está en el PATH; upgrade omitido."
            continue
        }
        try {
            & $up.Cmd @($up.Args) 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-OK "  - $($up.Name): actualizado" }
            else { Write-Warn "  - $($up.Name): upgrade falló (exit $LASTEXITCODE); se continúa." }
        } catch {
            Write-Warn "  - $($up.Name): upgrade falló: $_; se continúa."
        }
    }
    }

if ($SkipSync) {
    # [007-MCP] D5/RF-06: modo kit seguro — NO sincronizar el kit transversal
    # (evita la auto-sobrescritura del maestro); el resto del flujo sigue.
    Write-Step "3) Sync-TransversalKit OMITIDO (-SkipSync: modo kit seguro)."
} else {
    Write-Step "3) Sincronizando kit transversal (Sync-TransversalKit)..."
    Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction
    
    # [011-BOOTSTRAP-UPGRADE] Invocar upgrade_framework para sincronizar dependencias
    # externas (proyect_ext/) ANTES de compilar tokenslayer. Fail-open, gated por
    # -ForceUpgradeTools, respeta -DryRun.
    if ($ForceUpgradeTools) {
        Invoke-UpgradeFramework -RootPath $resolvedRoot -ForceUpgradeTools -DryRun:$DryRun
    }
    
    # [007-MCP] D3/RF-04: -ForceUpgradeTools — build de tokenslayer DESPUÉS del sync
    # (el sync clona proyect_ext/tokenslayer/; aquí compilamos si existe).
    if ($ForceUpgradeTools) {
        Write-Step "3b) -ForceUpgradeTools: compilando tokenslayer (fail-open)..."
        $tsBuildDir = Join-Path $resolvedRoot "proyect_ext\tokenslayer\mcp-server"
        if ((Get-Command "node" -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $tsBuildDir "package.json"))) {
            if ($DryRun) {
                Write-Info "  - tokenslayer: DryRun (omitido build)"
            } else {
                try {
                    & npm --prefix $tsBuildDir install 2>&1 | Out-Null
                    $instOk = ($LASTEXITCODE -eq 0)
                    & npm --prefix $tsBuildDir run build 2>&1 | Out-Null
                    $buildOk = ($LASTEXITCODE -eq 0)
                    if ($instOk -and $buildOk) { Write-OK "  - tokenslayer: build completado" }
                    else { Write-Warn "  - tokenslayer: build falló (install=$instOk build=$buildOk); se continúa." }
                } catch {
                    Write-Warn "  - tokenslayer: build falló: $_; se continúa."
                }
            }
        } else {
            Write-Warn "  - tokenslayer: clon ausente en proyect_ext/tokenslayer/mcp-server; build omitido."
        }
    }
}

Write-Step "4) Configurando MCPs para OpenCode..."
Ensure-OpenCodeMcp $resolvedRoot
Ensure-OpenCodeConfig -RootPath $resolvedRoot

Write-Step "5) Resolviendo app activa (Resolve-ActiveApp)..."
$activeApp = Resolve-ActiveApp -AppName $App -RootPath $resolvedRoot
Write-OK "App activa: $activeApp"

Write-Step "6) Configurando Spec-kit para la app activa (Configure-SpecKit)..."
$specKit = Configure-SpecKit -ActiveApp $activeApp -RootPath $resolvedRoot

Write-Step "7) Preparando apps (Prepare-Apps)..."
Prepare-Apps -RootPath $resolvedRoot

Write-Step "7c) Asegurando estructura src/<App>/ con .specify (Ensure-SrcAppStructure)..."
# [SOLUCION-GENERICA] RF-S3: -Apps explícito > manifest/src/* resueltos.
$srcApps = @($Apps | Where-Object { $_ -ne "" })
if ($srcApps.Count -eq 0) { $srcApps = @(Resolve-AppList -RootPath $resolvedRoot) }
Ensure-SrcAppStructure -Apps $srcApps -RootPath $resolvedRoot

Write-Step "7b) Reorganizando docs sueltas (Repair-DocStructure)..."
Repair-DocStructure -RootPath $resolvedRoot

Write-Step "8) Configurando Graphify (Configure-Graphify)..."
# [BOOTSTRAP-FIXES] F6: Graphify estructura-first con detección de estado
# (ADR-0004 RF-07): scope por app + deep opcional.
Configure-Graphify -RootPath $resolvedRoot -GraphifyScope $GraphifyScope -GraphifyDeep:$GraphifyDeep -ActiveApp $activeApp

Write-Step "9) Indexando código y documentación..."
$projectName = Split-Path $resolvedRoot -Leaf
Index-CodebaseMemory -RootPath $resolvedRoot -ProjectName $projectName

$docPaths = @(
    (Join-Path $resolvedRoot "Documentacion"),
    (Join-Path $resolvedRoot "Documentacion\Agents_IA_TECH")
)
if ($activeApp -ne "root") {
    $docPaths += (Join-Path $resolvedRoot "Documentacion\$activeApp")
}
Index-ContextMode -RootPath $resolvedRoot -PathsToIndex $docPaths

Write-Step "10) Verificando MCPs e índices..."
Verify-McpAndIndexes $resolvedRoot

Write-Step "11) Mostrando comandos de verificación manual..."
Show-VerificationCommands $resolvedRoot

Write-Step "12) Creando hoja de trabajo de indexación para la reorganización..."
$indexPath = Join-Path $resolvedRoot "Documentacion\index-preflight.md"
$indexContent = @"
# Preflight de reorganización

> Generado por `plataformador-bootstrap.ps1`
> Este archivo se usa antes de mover archivos para ordenar el proyecto.

## Información del proyecto
- Ruta: $resolvedRoot
- Fecha: $(Get-Date -Format "yyyy-MM-dd")

## Validaciones pendientes
- Confirmar si hay carpetas fuera de su sitio
- Revisar archivos sueltos en raíz
- Alinear la documentación con `Documentacion/`
- Revisar dependencias y MCPs (VS Code + OpenCode)
- Verificar índices: código (codebase-memory-mcp) + docs (context-mode)

## Estándar sugerido
- `Documentacion/00-indice.md`
- `Documentacion/pendientes-implementacion.md`
- `Documentacion/Agents_IA_TECH/`
- `.vscode/mcp.json`
- `.github/hooks/context-mode.json`
- `opencode.json` (con sección mcp)
"@

if ($DryRun) {
    Write-Info "DryRun: generar $indexPath"
} else {
    Set-Content -Path $indexPath -Value $indexContent -Encoding UTF8
    Write-OK "Índice de preflight generado: $indexPath"
}

Write-Step "13) Validación final del flujo..."
Write-OK "Flujo del instalador/actualizador único completado."
Write-OK "App activa: $activeApp | Spec-kit orientado a: $activeApp"
Write-OK "Kit transversal sincronizado. Documentacion/<AppName>/ NO fue tocada (frontera kit ↔ app)."
Write-OK "Los MCPs (VS Code + OpenCode), el entorno y los índices quedaron preparados."

if (-not $NoRestart) {
    Reload-ProjectWindow -RootPath $resolvedRoot
}

# [BOOTSTRAP-FIXES] F5: cuadro resumen de la ejecución (WARNs/ERRORs únicos).
Show-ExecutionSummary

Write-Host "" 
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Bootstrap completado" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "Siguientes pasos recomendados:" -ForegroundColor White
Write-Host "  1. Revisar Documentacion/00-indice.md" -ForegroundColor White
Write-Host "  2. Validar Documentacion/index-preflight.md" -ForegroundColor White
Write-Host "  3. Mover archivos solo después de revisar la estructura real" -ForegroundColor White
Write-Host "  4. Recargar la ventana de VS Code del proyecto si hizo falta aplicar la configuración" -ForegroundColor White
Write-Host "  5. Reiniciar OpenCode para cargar la nueva configuración MCP" -ForegroundColor White
Write-Host "  6. Usar comandos de verificación manual si necesitas confirmar" -ForegroundColor White


# Invocar actualización de MCPs
$updateScript = Join-Path $PSScriptRoot "update-mcp.ps1"
if (Test-Path -LiteralPath $updateScript) {
    & $updateScript -Quick
} else {
    Write-Warn "No se encontró scripts/update-mcp.ps1; se omite la actualización automática."
}
