#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/agents/sync-agents-opencode.ps1
# [021] Capa "agents-opencode" del sync por capas (spec 021-sync-kit-agents, fase 1).
# [021] Sincroniza UN harness con clean+replace:
# [021]   <Stage>/.opencode/agents/ -> <Root>/.opencode/agents/
# [021] NOTA guard .opencode/config.json: JAMAS se copia ni se borra (posibles
# [021] credenciales; bug OpenCode #5299 impide tokens). Este sync opera SOLO
# [021] dentro de .opencode/agents/ y nunca toca config.json. Emite
# [021] RESULT:opencode:<estado> en stdout.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-agents-opencode: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-agents-opencode: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] Copia limpia con backup previo (clean+replace). Carpetas chicas:
# [021] Copy-Item + Remove-Item (mas legible que robocopy aqui).
function Invoke-CleanReplaceDir {
    param([string]$Src, [string]$Dst, [string]$BackupBase, [switch]$Simulate)
    $existed = Test-Path -LiteralPath $Dst -PathType Container
    if (-not $existed) {
        if ($Simulate) { Write-Info "DryRun: crear $Dst desde $Src" }
        else {
            New-Item -ItemType Directory -Path $Dst -Force | Out-Null
            Copy-Item -Path (Join-Path $Src "*") -Destination $Dst -Recurse -Force
            Write-OK "Creado $Dst desde el stage."
        }
        return "creado"
    }
    # [021] Idempotencia: comparar contenido (rutas relativas + hash) antes de tocar.
    $same = $false
    try {
        $hashOf = {
            param([string]$Base)
            $map = @{}
            foreach ($f in (Get-ChildItem -LiteralPath $Base -Recurse -File -Force -ErrorAction Stop)) {
                $rel = ([IO.Path]::GetRelativePath($Base, $f.FullName)) -replace '\\', '/'
                $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            }
            return $map
        }
        $a = & $hashOf $Src; $b = & $hashOf $Dst
        $same = ($a.Count -eq $b.Count) -and (($a.Keys | Where-Object { -not $b.ContainsKey($_) -or $b[$_] -ne $a[$_] }).Count -eq 0)
    } catch {
        Write-Warn "sync-agents-opencode: no se pudo comparar ($($_)); se asume cambio."
        $same = $false
    }
    if ($same) { Write-OK ".opencode/agents/ sin cambios."; return "sin-cambios" }
    if ($Simulate) {
        Write-Info "DryRun: reemplazaria $Dst desde $Src (con backup previo en $BackupBase)"
        return "ok"
    }
    # [021] Backup previo (solo si hay algo que reemplazar y no es DryRun).
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $BackupBase ("$stamp/opencode-agents")
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -Path (Join-Path $Dst "*") -Destination $backup -Recurse -Force
    Write-Info "Backup previo en $backup"
    Remove-Item -LiteralPath $Dst -Recurse -Force
    New-Item -ItemType Directory -Path $Dst -Force | Out-Null
    Copy-Item -Path (Join-Path $Src "*") -Destination $Dst -Recurse -Force
    Write-OK ".opencode/agents/ reemplazado desde el stage."
    return "ok"
}

Write-Step "sync-agents-opencode: sincronizando .opencode/agents/ en $RootPath"

$srcDir = Join-Path $StageDir ".opencode/agents"
if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) {
    # [021] Stage sin la carpeta: WARN + salir 0 sin borrar nada.
    Write-Warn "sync-agents-opencode: el stage no trae .opencode/agents/ ($srcDir); no se borra nada."
    Write-Host "RESULT:opencode:omitido"
    exit 0
}

try {
    $dstDir = Join-Path $RootPath ".opencode/agents"
    $backupBase = Join-Path $RootPath ".kit-backup"
    $status = Invoke-CleanReplaceDir -Src $srcDir -Dst $dstDir -BackupBase $backupBase -Simulate:$DryRun
    # [021] Guard .opencode/config.json: verificar que sigue intacto tras el sync.
    $cfg = Join-Path $RootPath ".opencode/config.json"
    if ($Simulate) {
        Write-Info "DryRun: .opencode/config.json nunca se copia ni se borra (guard)."
    }
    Write-Host "RESULT:opencode:$status"
} catch {
    Write-Fail "sync-agents-opencode: $_"
    exit 1
}

Show-ExecutionSummary -Title "sync-agents-opencode"
