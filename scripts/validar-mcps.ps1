#!/usr/bin/env powershell
# =============================================================================
# validar-mcps.ps1 — Validación de instalación y configuración de los MCPs del kit
# =============================================================================
# Verifica que los MCPs del ecosistema de documentación sin IA estén:
#   1. Instalados (comando disponible en PATH)
#   2. Con la versión esperada (según dependencias-manifest.yml)
#   3. Configurados correctamente en .vscode/mcp.json (con "type": "stdio")
#   4. Con los hooks de context-mode configurados (.github/hooks/context-mode.json)
#   5. Respondiendo (ejecución real del servidor)
#
# ⚠️ MANTENIMIENTO OBLIGATORIO:
#   Este script debe actualizarse CADA VEZ que se agregue o quite una herramienta
#   del ecosistema. Al agregar/quitar un MCP:
#     1. Agregar/quitar la entrada en el array $mcps (abajo)
#     2. Actualizar el ValidateSet del parámetro -MCP
#     3. Actualizar la versión esperada en VersionEsperada
#     4. Actualizar dependencias-manifest.yml
#     5. Actualizar Documentacion/<AppName>/reglas-transversales-agentes.md
#   Ver: Documentacion/<AppName>/reglas-transversales-agentes.md (Regla 1)
#
# Uso:
#   .\scripts\validar-mcps.ps1              # Validación completa
#   .\scripts\validar-mcps.ps1 -MCP context-mode   # Validar un MCP específico
#   .\scripts\validar-mcps.ps1 -SkipRuntime # Omitir la prueba de ejecución (más rápido)
#
# Exit codes:
#   0 = todo OK
#   1 = al menos un MCP falló la validación
# =============================================================================

[CmdletBinding()]
param(
    [ValidateSet("context-mode", "codebase-memory-mcp", "markitdown", "markitdown-mcp")]
    [string[]]$MCP,
    [switch]$SkipRuntime
)

$ErrorActionPreference = "Stop"
$script:failed = $false

# --- Colores de salida -------------------------------------------------------
function Write-Ok   { Write-Host "   [OK]   $args" -ForegroundColor Green }
function Write-Warn { Write-Host "   [WARN] $args" -ForegroundColor Yellow }
function Write-Fail { Write-Host "   [FAIL] $args" -ForegroundColor Red; $script:failed = $true }

# --- Resolver rutas del proyecto ---------------------------------------------
$projectRoot = Split-Path -Parent $PSScriptRoot
$mcpJsonPath = Join-Path $projectRoot ".vscode\mcp.json"
$hooksPath   = Join-Path $projectRoot ".github\hooks\context-mode.json"
$manifestPath = Join-Path $projectRoot "dependencias-manifest.yml"

Write-Host "`n=== Validación de MCPs del kit Agents_IA_TECH ===`n" -ForegroundColor Cyan
Write-Host "Proyecto: $projectRoot`n"

# --- Definición de MCPs a validar --------------------------------------------
# Cada MCP: comando, tipo (npm/pip), cómo obtener la versión, versión esperada
# VersionSource: "flag" (usa --version), "npm-package" (lee package.json), "pip" (usa pip show)
# McpServerName: nombre del server en .vscode/mcp.json (si aplica)
# RequiereMcpJson: si debe estar registrado en .vscode/mcp.json
$mcps = @(
    @{
        Nombre      = "context-mode"
        Comando     = "context-mode"
        Tipo        = "npm"
        VersionSource = "npm-package"
        VersionEsperada = "1.0.169"
        RequiereHooks = $true
        McpServerName = "context-mode"
        RequiereMcpJson = $true
    },
    @{
        Nombre      = "codebase-memory-mcp"
        Comando     = "codebase-memory-mcp"
        Tipo        = "npm"
        VersionSource = "flag"
        VersionEsperada = "0.9.0"
        RequiereHooks = $false
        McpServerName = "codebase-memory-mcp"
        RequiereMcpJson = $true
    },
    @{
        Nombre      = "markitdown"
        Comando     = "markitdown"
        Tipo        = "pip"
        VersionSource = "flag"
        VersionEsperada = "0.1.7"
        RequiereHooks = $false
        McpServerName = $null   # Solo CLI/librería, no es un server MCP
        RequiereMcpJson = $false
    },
    @{
        Nombre      = "markitdown-mcp"
        Comando     = "markitdown-mcp"
        Tipo        = "pip"
        VersionSource = "pip"
        VersionEsperada = "0.0.1a3"
        RequiereHooks = $false
        McpServerName = "markitdown"   # En mcp.json el server se llama "markitdown"
        RequiereMcpJson = $true
    }
)

# Filtrar por MCP si se especificó
if ($MCP) {
    $mcps = $mcps | Where-Object { $_.Nombre -in $MCP }
}

# --- 1. Verificar instalación y versión de cada MCP ---------------------------
Write-Host "1. Verificando instalación y versión de los MCPs..." -ForegroundColor Yellow

foreach ($m in $mcps) {
    Write-Host "`n--- $($m.Nombre) ---" -ForegroundColor Cyan

    # 1a. Comando disponible en PATH
    $cmd = Get-Command $m.Comando -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Fail "Comando '$($m.Comando)' no encontrado en PATH. ¿Está instalado?"
        Write-Host "       Instalación: $($m.Tipo) install -g $($m.Comando)" -ForegroundColor DarkGray
        continue
    }
    Write-Ok "Comando '$($m.Comando)' encontrado en: $($cmd.Source)"

    # 1b. Versión instalada según la fuente
    $versionInstalada = $null
    switch ($m.VersionSource) {
        "flag" {
            # codebase-memory-mcp y markitdown: --version termina solo
            try {
                $versionOutput = & $m.Comando --version 2>&1 | Out-String
                # markitdown imprime un warning de pydub (ffmpeg) antes de la versión.
                # Buscar la línea que contiene la versión real (patrón "X.Y.Z").
                $versionLine = ($versionOutput -split "`n" | Where-Object { $_ -match "\d+\.\d+\.\d+" } | Select-Object -First 1)
                $versionInstalada = $versionLine.Trim()
                Write-Ok "Versión instalada: $versionInstalada"
            } catch {
                Write-Warn "No se pudo obtener la versión de '$($m.Comando)'"
            }
        }
        "npm-package" {
            # context-mode: --version inicia el servidor stdio y se cuelga.
            # Leer la versión del package.json del paquete npm global.
            try {
                $npmRoot = npm root -g 2>$null
                $pkgPath = Join-Path $npmRoot "$($m.Nombre)\package.json"
                if (Test-Path $pkgPath) {
                    $versionInstalada = (Get-Content $pkgPath -Raw | ConvertFrom-Json).version
                    Write-Ok "Versión instalada (package.json): $versionInstalada"
                } else {
                    Write-Warn "No se encontró $pkgPath"
                }
            } catch {
                Write-Warn "No se pudo leer la versión de '$($m.Nombre)' desde npm"
            }
        }
        "pip" {
            # markitdown-mcp no soporta --version; verificar vía pip show
            try {
                $pipInfo = pip show markitdown-mcp 2>&1 | Select-String "^Version:"
                $versionInstalada = ($pipInfo -replace "^Version:\s*", "").Trim()
                Write-Ok "Versión instalada (pip show): $versionInstalada"
            } catch {
                Write-Warn "No se pudo obtener la versión de markitdown-mcp vía pip show"
            }
        }
    }

    # 1c. Comparar con versión esperada (si está definida)
    if ($m.VersionEsperada -and $versionInstalada) {
        if ($versionInstalada -match [regex]::Escape($m.VersionEsperada)) {
            Write-Ok "Versión coincide con la esperada: $($m.VersionEsperada)"
        } else {
            Write-Warn "Versión instalada ($versionInstalada) difiere de la esperada ($($m.VersionEsperada)). Revisar dependencias-manifest.yml."
        }
    }
}

# --- 2. Verificar configuración en .vscode/mcp.json ---------------------------
Write-Host "`n2. Verificando configuración en .vscode/mcp.json..." -ForegroundColor Yellow

if (-not (Test-Path $mcpJsonPath)) {
    Write-Fail "No se encontró $mcpJsonPath. Crear el archivo con los MCPs configurados."
} else {
    try {
        $mcpJson = Get-Content $mcpJsonPath -Raw | ConvertFrom-Json
        foreach ($m in $mcps) {
            # Solo validar en mcp.json los MCPs que son servers (RequiereMcpJson)
            if (-not $m.RequiereMcpJson) {
                Write-Ok "MCP '$($m.Nombre)' es solo CLI/librería (no requiere registro en mcp.json)"
                continue
            }

            $serverName = $m.McpServerName
            $server = $mcpJson.servers.$($serverName)
            if (-not $server) {
                Write-Fail "MCP '$serverName' no está registrado en .vscode/mcp.json"
                continue
            }
            Write-Ok "MCP '$serverName' registrado en .vscode/mcp.json"

            # Verificar "type": "stdio" (decisión del usuario 2026-09-12)
            if ($server.type -eq "stdio") {
                Write-Ok "  'type': 'stdio' presente (correcto)"
            } else {
                Write-Fail "  Falta 'type': 'stdio' en '$serverName'. Agregarlo (decisión del usuario 2026-09-12)."
            }

            # Verificar que el comando coincide
            if ($server.command -eq $m.Comando) {
                Write-Ok "  command: '$($server.command)' (correcto)"
            } else {
                Write-Warn "  command: '$($server.command)' difiere del esperado '$($m.Comando)'"
            }
        }
    } catch {
        Write-Fail "Error al parsear ${mcpJsonPath}: $($_.Exception.Message)"
    }
}

# --- 3. Verificar hooks de context-mode ---------------------------------------
Write-Host "`n3. Verificando hooks de context-mode..." -ForegroundColor Yellow

$contextMode = $mcps | Where-Object { $_.Nombre -eq "context-mode" }
if ($contextMode -and $contextMode.RequiereHooks) {
    if (-not (Test-Path $hooksPath)) {
        Write-Fail "No se encontró $hooksPath. Configurar los hooks de context-mode."
    } else {
        try {
            $hooks = Get-Content $hooksPath -Raw | ConvertFrom-Json
            $hookTypes = @("PreToolUse", "PostToolUse", "SessionStart")
            foreach ($hookType in $hookTypes) {
                if ($hooks.hooks.$hookType) {
                    Write-Ok "Hook '$hookType' configurado"
                } else {
                    Write-Fail "Falta hook '$hookType' en $hooksPath"
                }
            }
        } catch {
            Write-Fail "Error al parsear ${hooksPath}: $($_.Exception.Message)"
        }
    }
} else {
    Write-Ok "context-mode no requiere hooks (o no se validó)"
}

# --- 4. Verificar ejecución real (runtime) ------------------------------------
if (-not $SkipRuntime) {
    Write-Host "`n4. Verificando ejecución real de los MCPs..." -ForegroundColor Yellow

    foreach ($m in $mcps) {
        Write-Host "`n--- $($m.Nombre) (runtime) ---" -ForegroundColor Cyan

        # Determinar el comando de runtime según el MCP:
        # - context-mode: 'doctor' (diagnóstico que termina solo; --version inicia el servidor stdio y se cuelga)
        # - codebase-memory-mcp / markitdown: '--version' (termina solo)
        # - markitdown-mcp: no expone --version; solo verificar que el binario existe
        if ($m.Nombre -eq "markitdown-mcp") {
            $cmd = Get-Command $m.Comando -ErrorAction SilentlyContinue
            if ($cmd) {
                Write-Ok "Binario '$($m.Comando)' presente y ejecutable (no expone --version)."
            } else {
                Write-Fail "Binario '$($m.Comando)' no encontrado."
            }
            continue
        }

        $runtimeArgs = if ($m.Nombre -eq "context-mode") { @("doctor") } else { @("--version") }

        try {
            # context-mode es un script .ps1 (no un exe Win32), Start-Process no lo ejecuta.
            # Usar un job de PowerShell con timeout y verificar que completó sin errores.
            if ($m.Nombre -eq "context-mode") {
                $job = Start-Job -ScriptBlock {
                    param($cmd, $argsList)
                    & $cmd @argsList *> "$env:TEMP\cm_doctor.txt"
                    if ($LASTEXITCODE -eq 0) { "OK" } else { "ERROR:$LASTEXITCODE" }
                } -ArgumentList $m.Comando, $runtimeArgs
                if (-not (Wait-Job $job -Timeout 20)) {
                    Stop-Job $job
                    Remove-Job $job -Force
                    Write-Fail "El MCP '$($m.Nombre)' no respondió en 20 segundos (timeout)."
                } else {
                    $jobResult = (Receive-Job $job | Out-String).Trim()
                    Remove-Job $job -Force
                    if ($jobResult -eq "OK") {
                        Write-Ok "El MCP '$($m.Nombre)' respondió correctamente (doctor OK)."
                    } else {
                        Write-Warn "El MCP '$($m.Nombre)' terminó con estado: $jobResult"
                    }
                }
                continue
            }

            # Ejecutar el comando con timeout para verificar que responde
            $proc = Start-Process -FilePath $m.Comando -ArgumentList $runtimeArgs -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\mcp_out.txt" -RedirectStandardError "$env:TEMP\mcp_err.txt"
            if (-not $proc.WaitForExit(8000)) {
                $proc.Kill()
                Write-Fail "El MCP '$($m.Nombre)' no respondió en 8 segundos (timeout)."
            } else {
                $stdout = Get-Content "$env:TEMP\mcp_out.txt" -Raw -ErrorAction SilentlyContinue
                $stderr = Get-Content "$env:TEMP\mcp_err.txt" -Raw -ErrorAction SilentlyContinue
                if ($proc.ExitCode -eq 0) {
                    Write-Ok "El MCP '$($m.Nombre)' respondió correctamente (exit code 0)."
                    if ($stdout) {
                        $firstLine = ($stdout -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
                        if ($firstLine) { Write-Host "       $firstLine" -ForegroundColor DarkGray }
                    }
                } else {
                    Write-Warn "El MCP '$($m.Nombre)' terminó con exit code $($proc.ExitCode)."
                    if ($stderr) { Write-Host "       stderr: $($stderr.Trim())" -ForegroundColor DarkGray }
                }
            }
        } catch {
            Write-Fail "Error al ejecutar '$($m.Comando)': $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "`n4. Prueba de ejecución omitida (-SkipRuntime)." -ForegroundColor DarkGray
}

# --- Resumen final ------------------------------------------------------------
Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
if ($script:failed) {
    Write-Host "Resultado: HAY FALLOS. Revisar los [FAIL] de arriba." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Resultado: TODOS LOS MCPs VALIDADOS CORRECTAMENTE." -ForegroundColor Green
    exit 0
}
