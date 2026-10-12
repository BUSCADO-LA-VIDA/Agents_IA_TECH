#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/agents/sync-agents-vscode.ps1
# [021] Capa "agents-vscode" del sync por capas (spec 021-sync-kit-agents, fase 1).
# [021] Sincroniza UN harness con clean+replace:
# [021]   <Stage>/.vscode/ -> <Root>/.vscode/
# [021] EXCEPTO .vscode/mcp.json con contenido local valido: si el destino tiene
# [021] un mcp.json con "servers" no vacio, se CONSERVA (no se copia el del stage
# [021] ni se borra el local). El merge de claves nuevas del maestro queda para
# [021] la fase 3 (lift-vscode); en fase 1 solo conservar.
# [021] NOTA guard .opencode/config.json: este sync no lo toca (opera solo en
# [021] .vscode/). Emite RESULT:vscode:<estado> en stdout.
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
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-agents-vscode: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-agents-vscode: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] mcp.json local valido = existe, parsea como JSON y trae "servers" no vacio.
function Test-ValidLocalMcpJson {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $servers = $json.servers
        if ($null -eq $servers) { return $false }
        $count = @($servers.PSObject.Properties).Count
        return ($count -gt 0)
    } catch {
        return $false
    }
}

Write-Step "sync-agents-vscode: sincronizando .vscode/ en $RootPath"

$srcDir = Join-Path $StageDir ".vscode"
if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) {
    # [021] Stage sin la carpeta: WARN + salir 0 sin borrar nada.
    Write-Warn "sync-agents-vscode: el stage no trae .vscode/ ($srcDir); no se borra nada."
    Write-Host "RESULT:vscode:omitido"
    exit 0
}

try {
    $dstDir = Join-Path $RootPath ".vscode"
    $dstMcp = Join-Path $dstDir "mcp.json"
    # [021] Preservar mcp.json local valido antes del replace.
    $preserveMcp = Test-ValidLocalMcpJson -Path $dstMcp
    $preservedText = $null
    if ($preserveMcp) {
        Write-Info ".vscode/mcp.json local con servers valido: se conserva (merge en fase 3)."
        if (-not $DryRun) {
            $preservedText = Get-Content -LiteralPath $dstMcp -Raw -ErrorAction Stop
        }
    }

    $existed = Test-Path -LiteralPath $dstDir -PathType Container
    if (-not $existed) {
        if ($DryRun) { Write-Info "DryRun: crear $dstDir desde $srcDir" }
        else {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Copy-Item -Path (Join-Path $srcDir "*") -Destination $dstDir -Recurse -Force
            if ($preserveMcp -and $null -ne $preservedText) {
                Set-Content -LiteralPath $dstMcp -Value $preservedText -Encoding UTF8
            }
            Write-OK "Creado $dstDir desde el stage."
        }
        Write-Host "RESULT:vscode:creado"
        exit 0
    }

    # [021] Idempotencia: comparar excluyendo mcp.json preservado.
    $same = $false
    try {
        $hashOf = {
            param([string]$Base, [bool]$SkipMcp)
            $map = @{}
            foreach ($f in (Get-ChildItem -LiteralPath $Base -Recurse -File -Force -ErrorAction Stop)) {
                $rel = ([IO.Path]::GetRelativePath($Base, $f.FullName)) -replace '\\', '/'
                if ($SkipMcp -and $rel -eq 'mcp.json') { continue }
                $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            }
            return $map
        }
        $a = & $hashOf $srcDir ($preserveMcp -and (-not $Force))
        $b = & $hashOf $dstDir ($preserveMcp -and (-not $Force))
        $same = ($a.Count -eq $b.Count) -and (($a.Keys | Where-Object { -not $b.ContainsKey($_) -or $b[$_] -ne $a[$_] }).Count -eq 0)
    } catch {
        Write-Warn "sync-agents-vscode: no se pudo comparar ($($_)); se asume cambio."
        $same = $false
    }
    # [021] Si solo difiere el mcp.json preservado, tambien es sin-cambios.
    if ($same) {
        Write-OK ".vscode/ sin cambios."
        Write-Host "RESULT:vscode:sin-cambios"
        exit 0
    }
    if ($DryRun) {
        Write-Info "DryRun: reemplazaria $dstDir desde $srcDir (con backup previo; mcp.json local preservado: $preserveMcp)"
        Write-Host "RESULT:vscode:ok"
        exit 0
    }

    # [021] Backup previo (solo si hay algo que reemplazar y no es DryRun).
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $RootPath (".kit-backup/$stamp/vscode")
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -Path (Join-Path $dstDir "*") -Destination $backup -Recurse -Force
    Write-Info "Backup previo en $backup"
    Remove-Item -LiteralPath $dstDir -Recurse -Force
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    if ($preserveMcp -and (-not $Force)) {
        # [021] Copiar todo excepto mcp.json, luego restaurar el local.
        foreach ($item in (Get-ChildItem -LiteralPath $srcDir -Force)) {
            if ($item.Name -eq 'mcp.json') { continue }
            Copy-Item -LiteralPath $item.FullName -Destination $dstDir -Recurse -Force
        }
        Set-Content -LiteralPath $dstMcp -Value $preservedText -Encoding UTF8
        Write-OK ".vscode/ reemplazado desde el stage (mcp.json local conservado)."
    } else {
        if ($preserveMcp -and $Force) {
            Write-Warn ".vscode/mcp.json local sobrescrito por -Force (el backup conserva el original)."
        }
        Copy-Item -Path (Join-Path $srcDir "*") -Destination $dstDir -Recurse -Force
        Write-OK ".vscode/ reemplazado desde el stage."
    }
    Write-Host "RESULT:vscode:ok"
} catch {
    Write-Fail "sync-agents-vscode: $_"
    exit 1
}

Show-ExecutionSummary -Title "sync-agents-vscode"
