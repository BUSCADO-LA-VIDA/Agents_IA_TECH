#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/src-structure/sync-src-structure.ps1
# [021] Capa "src-structure" del sync por capas (spec 021-sync-kit-agents,
# [021] fase 2). Replica la logica de Ensure-SrcAppStructure de
# [021] plataformador-bootstrap.ps1 (sin su paso 3): por app, crear
# [021] src/<App>/ y copiar la base .specify/ del stage si falta (se conserva
# [021] si existe salvo -Force, con backup previo). NO crea ni toca
# [021] Documentacion/ (eso es responsabilidad de la capa docs).
# [021] Con -Force pero contenido identico no se escribe (idempotencia).
# [021] Emite RESULT:src:<app>:<ok|sin-cambios|omitido> en stdout.
# [021] Fail-open por app: un error en una app no aborta las demas.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [string]$RootPath = "",
    [string[]]$Apps = @(),
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-src-structure: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-src-structure: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] El stage debe traer la base .specify/; si no, WARN + salir 0 sin tocar nada.
$stageSpecify = Join-Path $StageDir ".specify"
if (-not (Test-Path -LiteralPath $stageSpecify -PathType Container)) {
    Write-Warn "sync-src-structure: el stage no trae .specify/ base ($stageSpecify); nada que replicar."
    exit 0
}

# [021] Descubrir apps: subdirectorios de <Root>/Documentacion/ excluyendo
# [021] templates (mismo criterio que las capas docs y constitutions).
function Resolve-SrcApps {
    param([string]$Root)
    $docRoot = Join-Path $Root "Documentacion"
    if (-not (Test-Path -LiteralPath $docRoot -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $docRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'templates' } | Select-Object -ExpandProperty Name)
}

# [021] Mapa ruta-relativa -> hash SHA256 de un directorio.
function Get-SrcRelHashMap {
    param([string]$Base)
    $map = @{}
    foreach ($f in (Get-ChildItem -LiteralPath $Base -Recurse -File -Force -ErrorAction Stop)) {
        $rel = ([IO.Path]::GetRelativePath($Base, $f.FullName)) -replace '\\', '/'
        $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    return $map
}

# [021] Asegura src/<App>/ + .specify. Devuelve ok|sin-cambios.
function Ensure-SyncSrcApp {
    param([string]$Root, [string]$StageSpecify, [string]$App, [string]$BackupBase,
        [switch]$Simulate, [switch]$Overwrite)
    $changed = $false
    # [021] 1) Crear directorio src/<App>/ (paso 1 de Ensure-SrcAppStructure).
    $srcAppDir = Join-Path $Root ("src/" + $App)
    if (-not (Test-Path -LiteralPath $srcAppDir -PathType Container)) {
        if ($Simulate) {
            Write-Info "DryRun: crear directorio $srcAppDir"
        } else {
            New-Item -ItemType Directory -Path $srcAppDir -Force | Out-Null
            Write-OK "Directorio creado: $srcAppDir"
        }
        $changed = $true
    }
    # [021] 2) Copiar .specify base (paso 2 de Ensure-SrcAppStructure).
    # [021] NOTA: no hay paso 3 aqui (Documentacion/ es de la capa docs).
    $appSpecify = Join-Path $srcAppDir ".specify"
    $needsCopy = (-not (Test-Path -LiteralPath $appSpecify -PathType Container)) -or $Overwrite
    if (-not $needsCopy) {
        Write-Info ".specify ya existe en $appSpecify (usa -Force para sobrescribir)"
    } else {
        $isOverwrite = (Test-Path -LiteralPath $appSpecify -PathType Container) -and $Overwrite
        if ($isOverwrite) {
            # [021] Con -Force pero contenido identico no se escribe (idempotencia).
            try {
                $a = Get-SrcRelHashMap -Base $StageSpecify
                $b = Get-SrcRelHashMap -Base $appSpecify
                $same = ($a.Count -eq $b.Count) -and (($a.Keys | Where-Object { -not $b.ContainsKey($_) -or $b[$_] -ne $a[$_] }).Count -eq 0)
            } catch {
                Write-Warn "sync-src-structure: no se pudo comparar $appSpecify ($($_)); se asume cambio."
                $same = $false
            }
            if ($same) {
                Write-Info ".specify de '$App' sin cambios (se conserva aunque haya -Force): $appSpecify"
                return ($changed ? "ok" : "sin-cambios")
            }
        }
        if ($Simulate) {
            if ($isOverwrite) { Write-Info "DryRun: reemplazaria $appSpecify desde $StageSpecify (con backup previo)" }
            else { Write-Info "DryRun: copiar $StageSpecify -> $appSpecify" }
            return "ok"
        }
        if ($isOverwrite) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $backup = Join-Path $BackupBase ("$stamp/src-$App-specify")
            New-Item -ItemType Directory -Path $backup -Force | Out-Null
            Copy-Item -Path (Join-Path $appSpecify "*") -Destination $backup -Recurse -Force
            Write-Info "Backup previo en $backup"
            Remove-Item -LiteralPath $appSpecify -Recurse -Force
        }
        Copy-Item -Path $StageSpecify -Destination $appSpecify -Recurse -Force
        if ($isOverwrite) { Write-OK ".specify actualizado con -Force para '$App': $appSpecify" }
        else { Write-OK ".specify copiado a: $appSpecify" }
        $changed = $true
    }
    return ($changed ? "ok" : "sin-cambios")
}

Write-Step "sync-src-structure: asegurando estructura src/<App>/ en $RootPath"

$list = @($Apps | Where-Object { $_ -ne "" })
if ($list.Count -eq 0) { $list = @(Resolve-SrcApps -Root $RootPath) }
if ($list.Count -eq 0) {
    Write-Warn "sync-src-structure: sin apps (sin -Apps ni subdirectorios en Documentacion/ salvo templates); nada que sincronizar."
    exit 0
}

$backupBase = Join-Path $RootPath ".kit-backup"

foreach ($app in $list) {
    try {
        $status = Ensure-SyncSrcApp -Root $RootPath -StageSpecify $stageSpecify -App $app `
            -BackupBase $backupBase -Simulate:$DryRun -Overwrite:$Force
        Write-Host "RESULT:src:$app`:$status"
    } catch {
        # [021] Fail-open por app: WARN + omitido, sin abortar las demas.
        Write-Warn "sync-src-structure: '$app' omitida por error ($_); se continua con las demas."
        Write-Host "RESULT:src:$app`:omitido"
        continue
    }
}

Show-ExecutionSummary -Title "sync-src-structure"
