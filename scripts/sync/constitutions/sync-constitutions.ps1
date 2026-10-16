#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/constitutions/sync-constitutions.ps1
# [021] Capa "constitutions" del sync por capas (spec 021-sync-kit-agents,
# [021] fase 2). Version sync de Ensure-ConstitutionAppSync de
# [021] plataformador-bootstrap.ps1: la fuente es <Stage>/.specify/memory/
# [021] constitution.md (no la raiz del destino). Por app:
# [021]   (a) seed Documentacion/<App>/.specify/constitution.md (nivel 2) si
# [021]       falta; se conserva si existe salvo -Force (con backup previo);
# [021]   (b) si existe <Root>/src/<App>/, copiar nivel 2 ->
# [021]       src/<App>/.specify/constitution.md (nivel 3, runtime); se conserva
# [021]       si existe salvo -Force (con backup previo);
# [021]   (c) regla gitignore ".specify/constitution.md" en
# [021]       src/<App>/.gitignore con append idempotente (se crea el archivo
# [021]       si falta).
# [021] Con -Force pero contenido identico no se escribe (idempotencia).
# [021] Emite RESULT:constitutions:<app>:<ok|sin-cambios|omitido> en stdout.
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
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-constitutions: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-constitutions: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] Descubrir apps: subdirectorios de <Root>/Documentacion/ excluyendo
# [021] templates (mismo criterio que la capa docs).
function Resolve-ConstitutionApps {
    param([string]$Root)
    $docRoot = Join-Path $Root "Documentacion"
    if (-not (Test-Path -LiteralPath $docRoot -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $docRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'templates' } | Select-Object -ExpandProperty Name)
}

# [021] Copia un archivo solo si falta o si (-Force y difiere). Con contenido
# [021] identico no escribe (idempotencia, RNF-02). Devuelve $true si escribio
# [021] o escribiria (DryRun), $false si se conserva.
function Copy-ConstitutionIfNeeded {
    param([string]$SrcFile, [string]$DstFile, [string]$BackupBase, [string]$BackupRel,
        [string]$App, [string]$Level, [switch]$Simulate, [switch]$Overwrite)
    $dstExists = Test-Path -LiteralPath $DstFile -PathType Leaf
    if ($dstExists) {
        try {
            $ha = (Get-FileHash -LiteralPath $SrcFile -Algorithm SHA256 -ErrorAction Stop).Hash
            $hb = (Get-FileHash -LiteralPath $DstFile -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($ha -eq $hb) {
                Write-Info "Nivel $Level de '$App' sin cambios (se conserva): $DstFile"
                return $false
            }
        } catch {
            Write-Warn "sync-constitutions: no se pudo comparar $DstFile ($($_)); se asume cambio."
        }
        if (-not $Overwrite) {
            Write-Info "Nivel $Level de '$App' se conserva (existe; usa -Force para sobrescribir): $DstFile"
            return $false
        }
    }
    $verb = if ($dstExists) { "sobrescribiria" } else { "sembraria" }
    if ($Simulate) {
        Write-Info "DryRun: $verb nivel $Level de '$App': $DstFile"
        return $true
    }
    $dstDir = Split-Path -Parent $DstFile
    if ($dstDir -and (-not (Test-Path -LiteralPath $dstDir -PathType Container))) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    if ($dstExists) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = Join-Path $BackupBase ("$stamp/$BackupRel")
        $backupDir = Split-Path -Parent $backup
        if ($backupDir -and (-not (Test-Path -LiteralPath $backupDir -PathType Container))) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $DstFile -Destination $backup -Force
        Write-Info "Backup previo en $backup"
    }
    Copy-Item -LiteralPath $SrcFile -Destination $DstFile -Force
    if ($dstExists) { Write-OK "Nivel $Level actualizado con -Force para '$App': $DstFile" }
    else { Write-OK "Nivel $Level sembrado para '$App': $DstFile" }
    return $true
}

# [021] Regla gitignore idempotente en src/<App>/.gitignore (crea el archivo si
# [021] falta). Devuelve $true si escribio o escribiria (DryRun).
function Ensure-ConstitutionGitignore {
    param([string]$SrcAppDir, [string]$App, [switch]$Simulate)
    $giPath = Join-Path $SrcAppDir ".gitignore"
    $hasEntry = $false
    if (Test-Path -LiteralPath $giPath -PathType Leaf) {
        try {
            $giText = Get-Content -LiteralPath $giPath -Raw -ErrorAction Stop
            if ($giText -match '(?m)^\s*\.specify/constitution\.md\s*$') { $hasEntry = $true }
        } catch {
            Write-Warn "sync-constitutions: no se pudo leer $giPath ($_); se asume sin regla."
        }
    }
    if ($hasEntry) {
        Write-Info "src/$App/.gitignore ya ignora .specify/constitution.md (se conserva)."
        return $false
    }
    if ($Simulate) {
        Write-Info "DryRun: agregaria '.specify/constitution.md' a src/$App/.gitignore"
        return $true
    }
    if (-not (Test-Path -LiteralPath $giPath -PathType Leaf)) {
        $giContent = "# [021] copia runtime de constitution (no versionar)" + [Environment]::NewLine + ".specify/constitution.md" + [Environment]::NewLine
        Set-Content -LiteralPath $giPath -Value $giContent -Encoding UTF8
    } else {
        $entry = [Environment]::NewLine + "# [021] copia runtime de constitution (no versionar)" + [Environment]::NewLine + ".specify/constitution.md" + [Environment]::NewLine
        Add-Content -LiteralPath $giPath -Value $entry -Encoding UTF8
    }
    Write-OK "'.specify/constitution.md' agregado a src/$App/.gitignore"
    return $true
}

# [021] Sincroniza una app. Devuelve ok|sin-cambios|omitido.
function Sync-AppConstitution {
    param([string]$Root, [string]$Stage, [string]$App, [string]$BackupBase,
        [switch]$Simulate, [switch]$Overwrite)
    $stageConst = Join-Path $Stage ".specify/memory/constitution.md"
    if (-not (Test-Path -LiteralPath $stageConst -PathType Leaf)) {
        Write-Warn "sync-constitutions: el stage no trae .specify/memory/constitution.md; se omite '$App'."
        return "omitido"
    }
    $changed = $false
    # [021] (a) Nivel 2: Documentacion/<App>/.specify/constitution.md.
    $docFile = Join-Path $Root ("Documentacion/" + $App + "/.specify/constitution.md")
    if (Copy-ConstitutionIfNeeded -SrcFile $stageConst -DstFile $docFile `
            -BackupBase $BackupBase -BackupRel "constitutions/$App/nivel2-constitution.md" `
            -App $App -Level "2" -Simulate:$Simulate -Overwrite:$Overwrite) {
        $changed = $true
    }
    # [021] (b)+(c) Nivel 3 y gitignore solo si existe src/<App>/.
    $srcApp = Join-Path $Root ("src/" + $App)
    if (Test-Path -LiteralPath $srcApp -PathType Container) {
        # [021] Nivel 3 se copia desde el nivel 2 (si el nivel 2 existe en disco;
        # [021] en DryRun con nivel 2 aun no sembrado se compara contra el stage).
        $level2Src = $docFile
        if ((-not (Test-Path -LiteralPath $level2Src -PathType Leaf)) -and (-not $Simulate)) {
            Write-Warn "sync-constitutions: sin nivel 2 para '$App' ($level2Src); se omite nivel 3 (runtime)."
        } else {
            if (-not (Test-Path -LiteralPath $level2Src -PathType Leaf)) { $level2Src = $stageConst }
            $runtime = Join-Path $srcApp ".specify/constitution.md"
            if (Copy-ConstitutionIfNeeded -SrcFile $level2Src -DstFile $runtime `
                    -BackupBase $BackupBase -BackupRel "constitutions/$App/nivel3-constitution.md" `
                    -App $App -Level "3" -Simulate:$Simulate -Overwrite:$Overwrite) {
                $changed = $true
            }
        }
        if (Ensure-ConstitutionGitignore -SrcAppDir $srcApp -App $App -Simulate:$Simulate) {
            $changed = $true
        }
    } else {
        Write-Info "App '$App' sin src/$App; se omite nivel 3 (runtime) y su .gitignore."
    }
    return ($changed ? "ok" : "sin-cambios")
}

Write-Step "sync-constitutions: sincronizando constitutions en $RootPath"

$list = @($Apps | Where-Object { $_ -ne "" })
if ($list.Count -eq 0) { $list = @(Resolve-ConstitutionApps -Root $RootPath) }
if ($list.Count -eq 0) {
    Write-Warn "sync-constitutions: sin apps (sin -Apps ni subdirectorios en Documentacion/ salvo templates); nada que sincronizar."
    exit 0
}

$backupBase = Join-Path $RootPath ".kit-backup"

foreach ($app in $list) {
    try {
        $status = Sync-AppConstitution -Root $RootPath -Stage $StageDir -App $app `
            -BackupBase $backupBase -Simulate:$DryRun -Overwrite:$Force
        Write-Host "RESULT:constitutions:$app`:$status"
    } catch {
        # [021] Fail-open por app: WARN + omitido, sin abortar las demas.
        Write-Warn "sync-constitutions: '$app' omitida por error ($_); se continua con las demas."
        Write-Host "RESULT:constitutions:$app`:omitido"
        continue
    }
}

Show-ExecutionSummary -Title "sync-constitutions"
