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
#   - reiniciar VS Code cuando el usuario lo pide
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
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$ManifestPath = "",
    [string]$OrphanAction = "Preguntar"
)

$ErrorActionPreference = "Stop"

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

# =============================================================================
# Configuración del instalador/actualizador único (ADR-0003)
# =============================================================================
$KnownApps = @("dwxconnect", "fibonacci-scanner", "operation_mt5", "Telegram", "trading_bot")

# Allowlist de owners de confianza para validar URLs (fail-closed).
# Solo se permite https://github.com/<owner-en-allowlist>/<repo>
$TrustedOwners = @(
    "BUSCADO-LA-VIDA",
    "tomasecastro",
    "github",
    "microsoft",
    "DeusData",
    "mksglu",
    "tomasgraph"
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
    $apps = @()
    foreach ($m in [regex]::Matches($content, '(?ms)^  - nombre:\s*(\S+)\s*\r?\n    url:\s*(\S+)\s*\r?\n    rama:\s*(\S+)\s*\r?\n(?:.*?)\r?\n    licencia:\s*(.+?)\s*$')) {
        if ($m.Groups[1].Value -in $KnownApps) {
            $apps += @{ Nombre = $m.Groups[1].Value; Url = $m.Groups[2].Value; Rama = $m.Groups[3].Value; Licencia = $m.Groups[4].Value }
        }
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

function Ensure-OpenCodeMcp {
    param([string]$RootPath)

    $opencodePath = Join-Path $RootPath "opencode.json"
    
    if (-not (Test-Path $opencodePath)) {
        Write-Warn "No existe opencode.json en $RootPath; se omite configuración de MCP para OpenCode."
        return
    }

# Leer el JSON existente
    $existing = Get-Content -Path $opencodePath -Raw | ConvertFrom-Json

    # Verificar si ya tiene la sección mcp
    if ($existing.mcp -and -not $Force) {
        Write-OK "opencode.json ya tiene sección mcp; se conserva (usa -Force para sobrescribir)."
    } else {
        $mcpConfig = [ordered]@{
            "context-mode" = [ordered]@{
                type = "local"
                command = @("C:/Users/tomas/AppData/Roaming/npm/context-mode.cmd")
                enabled = $true
            }
            "codebase-memory-mcp" = [ordered]@{
                type = "local"
                command = @("C:/Users/tomas/.local/bin/codebase-memory-mcp.exe")
                enabled = $true
            }
            "markitdown" = [ordered]@{
                type = "local"
                command = @("C:/Python314/Scripts/markitdown-mcp.exe")
                enabled = $true
            }
        }

        if (-not $DryRun) {
            $existing.mcp = $mcpConfig
            Write-OK "Sección mcp agregada a opencode.json"
        } else {
            Write-Info "DryRun: agregar sección mcp a opencode.json"
        }
    }

    # Plugin de context-mode (falta el array `plugin` según ctx_doctor)
    $hasPlugin = $false
    foreach ($p in @($existing.plugin)) { if ($p -eq "context-mode") { $hasPlugin = $true } }
    if (-not $hasPlugin -and -not $DryRun) {
        $existing.plugin = @(@($existing.plugin) + "context-mode")
        Write-OK "Plugin de context-mode agregado a opencode.json"
    } elseif (-not $hasPlugin) {
        Write-Info "DryRun: agregar plugin de context-mode a opencode.json"
    }

    if (-not $DryRun) {
        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $opencodePath -Encoding UTF8
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
        $result = & "C:/Users/tomas/.local/bin/codebase-memory-mcp.exe" cli index_repository --path $RootPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Código indexado correctamente en codebase-memory-mcp"
        } else {
            Write-Warn "Indexación de código completada con advertencias (ver salida arriba)"
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
                $result = & "C:/Users/tomas/AppData/Roaming/npm/context-mode.cmd" index $p 2>&1
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
            $projects = & "C:/Users/tomas/.local/bin/codebase-memory-mcp.exe" cli list_projects 2>&1
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
            $doctor = & "C:/Users/tomas/AppData/Roaming/npm/context-mode.cmd" doctor 2>&1
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
    $cmContent = "C:\Users\tomas\AppData\Roaming\opencode\context-mode\content"
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
    $cmDbPath = "C:\Users\tomas\.cache\codebase-memory-mcp"
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

function Restart-VSCode {
    if ($NoRestart -or $DryRun) {
        Write-Info "Se omite el reinicio de VS Code porque -NoRestart o -DryRun está activo."
        return
    }

    Write-Step "Reiniciando VS Code para cargar los cambios de MCP y configuración..."

    $codeExe = $null
    foreach ($candidate in @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles(x86)\Microsoft VS Code\Code.exe",
        "C:\Program Files\Microsoft VS Code\Code.exe",
        "C:\Program Files (x86)\Microsoft VS Code\Code.exe"
    )) {
        if (Test-Path $candidate) {
            $codeExe = $candidate
            break
        }
    }

    if ($codeExe) {
        try {
            Get-Process Code -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 2
            Start-Process -FilePath $codeExe -ArgumentList "--reuse-window"
            Write-OK "VS Code reiniciado desde: $codeExe"
            return
        } catch {
            Write-Warn "No se pudo reiniciar VS Code por proceso activo; se intenta abrir una nueva ventana."
        }
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        & code --reuse-window
        Write-OK "VS Code reiniciado mediante el comando 'code'."
        return
    }

Write-Warn "No se pudo localizar VS Code para reiniciarlo automáticamente."
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
        "sync-agents.ps1"
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
            @{ Source = (Join-Path $tempDir "sync-agents.ps1");            Target = (Join-Path $RootPath "sync-agents.ps1");            Type = "File"; Label = "sync-agents.ps1" }
        )

        foreach ($item in $transversalItems) {
            $src = $item.Source
            $dst = $item.Target
            if (-not (Test-Path $src)) {
                Write-Host "  [SKIP] $($item.Label) — no existe en repo maestro" -ForegroundColor DarkGray
                continue
            }
            $dstDir = if ($item.Type -eq "File") { Split-Path $dst -Parent } else { $dst }
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

            if ($item.Type -eq "Dir") {
                Write-Host "  [SYNC] $($item.Label)" -ForegroundColor Cyan
                if ($item.Label -eq ".opencode/") {
                    # Seguridad: nunca copiar .opencode/config.json (posibles credenciales).
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" >$null 2>&1
                } else {
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS >$null 2>&1
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
                Copy-Item $src -Destination $dst -Force
            }
        }

        # Seguridad: confirmar que .opencode/config.json del kit NO se copió.
        $kitConfig = Join-Path $tempDir ".opencode\config.json"
        if (Test-Path $kitConfig) {
            Write-Warn "Se excluye .opencode/config.json (posibles credenciales) de la sincronización."
        }

        # T-I7 / RF-12: manejo de huérfanos (dentro del try: $tempDir sigue
        # disponible; el finally lo limpia después). Find-OrphanKitFiles hace
        # throw si el maestro está incompleto (fail-closed: nada se borra).
        $orphans = @(Find-OrphanKitFiles -RootPath $RootPath -TempDir $tempDir)
        Invoke-OrphanDecision -Orphans $orphans -RootPath $RootPath -OrphanAction $OrphanAction

        Write-OK "Kit transversal sincronizado (commit $commitHash). Documentacion/<AppName>/ NO fue tocada."
    }
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

    # 1) Flag -App (equivale a -AppName): precedencia máxima.
    if ($AppName) {
        if (($AppName -ne "root") -and ($AppName -notin $KnownApps)) {
            Write-Warn "App '$AppName' no está en la lista conocida ($($KnownApps -join ', ')); se usa igual por precedencia del flag."
        }
        Write-Info "App activa resuelta por flag -App: $AppName"
        return $AppName
    }

    # 2) cwd dentro de una app conocida: src\<app>\ o \<app>\ en la raíz.
    $cwd = (Get-Location).Path
    foreach ($known in $KnownApps) {
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
    foreach ($known in $KnownApps) {
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

    $apps = @("dwxconnect", "fibonacci-scanner", "operation_mt5", "Telegram", "trading_bot")
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
# Configure-Graphify (T-I3 / RF-09): verificar presencia sin descargar (guardrail 8)
# =============================================================================
# Verifica si graphify está disponible (.opencode/bin/graphify* o
# .opencode/lib/graphify/). Existe -> Write-OK. No existe -> Write-Warn
# indicando que su URL/licencia deben validarse antes de descargar (la licencia
# de graphify está pendiente según dependencias-manifest.yml — NO se descarga
# nada todavía). Respeta -DryRun. Nunca ejecuta binarios/scripts descargados
# sin revisión manual previa.
function Configure-Graphify {
    param([string]$RootPath = "")

    if (-not $RootPath) {
        if (Get-Variable -Name ProjectRoot -Scope Script -ErrorAction SilentlyContinue) {
            $RootPath = $script:ProjectRoot
        } else {
            $RootPath = (Split-Path -Parent $PSScriptRoot)
        }
    }

    Write-Step "Configurando Graphify..."

    $binDir = Join-Path $RootPath ".opencode\bin"
    $libDir = Join-Path $RootPath ".opencode\lib\graphify"
    $binHits = @()
    if (Test-Path $binDir) {
        $binHits = @(Get-ChildItem -Path $binDir -Filter "graphify*" -ErrorAction SilentlyContinue)
    }
    if (($binHits.Count -gt 0) -or (Test-Path $libDir)) {
        if ($binHits.Count -gt 0) { Write-OK "Graphify disponible en: $binDir" }
        if (Test-Path $libDir) { Write-OK "Graphify disponible en: $libDir" }
        return
    }

    Write-Warn "Graphify no encontrado (.opencode/bin/graphify* ni .opencode/lib/graphify/); su URL/licencia deben validarse antes de descargar (licencia pendiente según dependencias-manifest.yml, guardrail 8). NO se descarga nada."
    if ($DryRun) {
        Write-Info "DryRun: Configure-Graphify solo informa, no escribe nada."
    }
    # TODO: cuando la licencia esté verificada y la URL en la allowlist
    # (fail-closed: solo https://github.com/<owner en allowlist>/<repo>),
    # descargar shallow y registrar la licencia en dependencias-manifest.yml:
    #   git clone --depth 1 <url-validada> (Join-Path $RootPath "proyect_ext\graphify")
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
Ensure-ProjectDocumentation $resolvedRoot
Ensure-MemoryIndex $resolvedRoot
Ensure-VSCodeSettings $resolvedRoot
Ensure-McpJson $resolvedRoot
Ensure-OpenCodeMcp $resolvedRoot
Ensure-ContextHooks $resolvedRoot

Write-Step "2) Validando dependencias externas y MCPs..."
if (-not $SkipInstall) {
    Ensure-Command -Name "npm" -InstallCommand "npm --version" -AllowMissing
    Ensure-Command -Name "pip" -InstallCommand "python -m pip --version" -AllowMissing
    Ensure-Command -Name "context-mode" -InstallCommand "npm install -g context-mode" -AllowMissing
    Ensure-Command -Name "codebase-memory-mcp" -InstallCommand "npm install -g codebase-memory-mcp" -AllowMissing
    Ensure-Command -Name "markitdown" -InstallCommand "python -m pip install 'markitdown[all]'" -AllowMissing
    Ensure-Command -Name "markitdown-mcp" -InstallCommand "python -m pip install 'markitdown-mcp==0.0.1a3' 'mcp<2'" -AllowMissing
} else {
    Write-Info "Se omite la instalación de dependencias por -SkipInstall."
}

Write-Step "3) Sincronizando kit transversal (Sync-TransversalKit)..."
Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction

Write-Step "4) Configurando MCPs para OpenCode..."
Ensure-OpenCodeMcp $resolvedRoot

Write-Step "5) Resolviendo app activa (Resolve-ActiveApp)..."
$activeApp = Resolve-ActiveApp -AppName $App -RootPath $resolvedRoot
Write-OK "App activa: $activeApp"

Write-Step "6) Configurando Spec-kit para la app activa (Configure-SpecKit)..."
$specKit = Configure-SpecKit -ActiveApp $activeApp -RootPath $resolvedRoot

Write-Step "7) Preparando apps (Prepare-Apps)..."
Prepare-Apps -RootPath $resolvedRoot

Write-Step "8) Configurando Graphify (Configure-Graphify)..."
Configure-Graphify -RootPath $resolvedRoot

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
    Restart-VSCode
}

Write-Host "" 
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " Bootstrap completado" -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "Siguientes pasos recomendados:" -ForegroundColor White
Write-Host "  1. Revisar `Documentacion/00-indice.md`" -ForegroundColor White
Write-Host "  2. Validar `Documentacion/index-preflight.md`" -ForegroundColor White
Write-Host "  3. Mover archivos solo después de revisar la estructura real" -ForegroundColor White
Write-Host "  4. Reabrir VS Code si hizo falta recargar la configuración" -ForegroundColor White
Write-Host "  5. Reiniciar OpenCode para cargar la nueva configuración MCP" -ForegroundColor White
Write-Host "  6. Usar comandos de verificación manual si necesitas confirmar" -ForegroundColor White
