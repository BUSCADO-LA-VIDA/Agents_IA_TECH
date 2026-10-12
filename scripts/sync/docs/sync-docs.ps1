#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/docs/sync-docs.ps1
# [021] Capa "docs" del sync por capas (spec 021-sync-kit-agents, fase 1).
# [021] Harness-independiente. Version sync de Ensure-AppStructure /
# [021] Ensure-AppDocumentation de plataformador-bootstrap.ps1: SOLO asegura la
# [021] estructura minima Documentacion/<App>/ (+ specs/ y .specify/ vacias si
# [021] faltan). Nunca escribe contenido dentro (no crea indices ni pendientes:
# [021] eso sigue siendo responsabilidad del bootstrap en el proyecto destino).
# [021] Emite lineas RESULT:<App>:<ok|creado|sin-cambios> en stdout para el reporte.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [string]$RootPath = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-docs: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-docs: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] Resolucion de apps: 1) manifest tolerante, 2) descubrir subdirectorios.
function Resolve-SyncApps {
    param([string]$Root)
    # [021] 1) dependencias-manifest.yml con clave de apps tolerante.
    $manifest = Join-Path $Root "dependencias-manifest.yml"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try {
            $apps = @()
            $inAppsSection = $false
            foreach ($line in (Get-Content -LiteralPath $manifest -ErrorAction Stop)) {
                # [021] Claves aceptadas (tolerante): aplicaciones / apps / applications.
                if ($line -match '^(aplicaciones|apps|applications)\s*:') { $inAppsSection = $true; continue }
                if ($inAppsSection -and $line -match '^[A-Za-z_][A-Za-z0-9_-]*\s*:' -and $line -notmatch '^\s') { break }
                if ($inAppsSection -and $line -match '^\s*-\s+nombre\s*:\s*(.+?)\s*$') {
                    $name = $matches[1].Trim().Trim('"').Trim("'")
                    if ($name -and $name -ne 'MiApp') { $apps += $name }
                }
            }
            if ($apps.Count -gt 0) {
                Write-Info "sync-docs: apps resueltas desde dependencias-manifest.yml: $($apps -join ', ')"
                return @($apps | Select-Object -Unique)
            }
            Write-Info "sync-docs: manifest sin lista de apps activa; se descubre desde Documentacion/."
        } catch {
            Write-Warn "sync-docs: no se pudo leer dependencias-manifest.yml ($_); se descubre desde Documentacion/."
        }
    }
    # [021] 2) Descubrir subdirectorios de Documentacion/ (excluir templates).
    $docRoot = Join-Path $Root "Documentacion"
    if (-not (Test-Path -LiteralPath $docRoot -PathType Container)) { return @() }
    $found = @(Get-ChildItem -LiteralPath $docRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'templates' } | Select-Object -ExpandProperty Name)
    return $found
}

# [021] Asegura la estructura minima de una app. Fail-open: el llamador envuelve.
function Ensure-SyncAppDoc {
    param([string]$Root, [string]$App, [switch]$Simulate)
    $appDoc = Join-Path $Root ("Documentacion/" + $App)
    $existedApp = Test-Path -LiteralPath $appDoc -PathType Container
    $created = @()
    foreach ($sub in @("", "specs", ".specify")) {
        $dir = if ($sub) { Join-Path $appDoc $sub } else { $appDoc }
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            if ($Simulate) {
                Write-Info "DryRun: crear directorio $dir"
            } else {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-OK "Directorio creado: $dir"
            }
            $created += ($sub -eq '' ? '.' : $sub)
        }
    }
    if (-not $existedApp) { return "creado" }
    if ($created.Count -gt 0) { return "ok" }
    return "sin-cambios"
}

Write-Step "sync-docs: asegurando estructura Documentacion/<App>/ en $RootPath"

$apps = @(Resolve-SyncApps -Root $RootPath)
if ($apps.Count -eq 0) {
    Write-Warn "sync-docs: sin apps (sin manifest activo ni subdirectorios en Documentacion/); nada que sincronizar."
    exit 0
}

foreach ($app in $apps) {
    try {
        $status = Ensure-SyncAppDoc -Root $RootPath -App $app -Simulate:$DryRun
        Write-Host "RESULT:$app`:$status"
    } catch {
        # [021] Fail-open por app: WARN + continue, sin abortar las demas.
        Write-Warn "sync-docs: $app omitida por error ($_); se continua con las demas."
        continue
    }
}

Show-ExecutionSummary -Title "sync-docs"
