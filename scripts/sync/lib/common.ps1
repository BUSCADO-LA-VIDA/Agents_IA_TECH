#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/lib/common.ps1
# [021] Logging + resumen compartidos del sync por capas (spec 021-sync-kit-agents).
# [021] Extraido literalmente de scripts/sync-kit.ps1 (lineas 45-78): Write-Info,
# [021] Write-Step, Write-OK, Write-Warn, Write-Fail, Write-WarnOnce y
# [021] Show-ExecutionSummary, adaptados para dot-sourcing.
# [021] Uso desde cada capa: . "$PSScriptRoot/../lib/common.ps1"; Initialize-SyncLog
# =============================================================================

$ErrorActionPreference = "Stop"

# [021] Inicializa las 3 listas de acumulacion en el scope script del LLAMADOR.
# [021] Como este archivo se importa con dot-sourcing, el cuerpo de la funcion
# [021] se ejecuta en el scope del llamador y `$script:` resuelve alli. Llamar
# [021] a Initialize-SyncLog una vez al inicio de cada script que lo importe.
function Initialize-SyncLog {
    $script:Warnings = [System.Collections.Generic.List[string]]::new()
    $script:Errors = [System.Collections.Generic.List[string]]::new()
    $script:EmittedWarns = [System.Collections.Generic.List[string]]::new()
}

# [021] Listas por defecto por si un script olvida llamar a Initialize-SyncLog.
if (-not (Get-Variable -Name Warnings -Scope Script -ErrorAction SilentlyContinue)) {
    $script:Warnings = [System.Collections.Generic.List[string]]::new()
}
if (-not (Get-Variable -Name Errors -Scope Script -ErrorAction SilentlyContinue)) {
    $script:Errors = [System.Collections.Generic.List[string]]::new()
}
if (-not (Get-Variable -Name EmittedWarns -Scope Script -ErrorAction SilentlyContinue)) {
    $script:EmittedWarns = [System.Collections.Generic.List[string]]::new()
}

# =============================================================================
# [021] Logging (copia literal de sync-kit.ps1, sin cambios de semantica)
# =============================================================================
function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow; $script:Warnings.Add($Message) | Out-Null }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red; $script:Errors.Add($Message) | Out-Null }

function Write-WarnOnce {
    param([string]$Message)
    if ($script:EmittedWarns -contains $Message) { return }
    $script:EmittedWarns.Add($Message) | Out-Null
    Write-Warn $Message
}

# [021] Resumen final. Unico cambio respecto a sync-kit.ps1: titulo parametrizable
# [021] (por defecto "sync-kit-agents" para el orquestador nuevo).
function Show-ExecutionSummary {
    param([string]$Title = "sync-kit-agents")
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " RESUMEN DE LA EJECUCION ($Title)" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " WARNs: $($uniqueWarns.Count)"
    foreach ($w in $uniqueWarns) { Write-Host "   - $w" }
    Write-Host " ERRORs: $($uniqueErrors.Count)"
    foreach ($e in $uniqueErrors) { Write-Host "   - $e" }
    Write-Host "===============================================================" -ForegroundColor Yellow
}
