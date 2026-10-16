#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/kit-files/sync-kit-files.ps1
# [021] Capa "kit-files" del sync por capas (spec 021-sync-kit-agents, fase 2).
# [021] Sincroniza con clean+replace (backup previo) los archivos/carpetas del
# [021] kit que no pertenecen a otra capa:
# [021]   <Stage>/scripts/ (EXCLUYENDO scripts/sync/ para no auto-sobrescribirse
# [021]     durante el sync) -> <Root>/scripts/
# [021]   <Stage>/AGENTS.md -> <Root>/AGENTS.md
# [021]   <Stage>/README.md -> <Root>/README.md
# [021]   <Stage>/.specify/memory/constitution.md
# [021]     -> <Root>/.specify/memory/constitution.md (solo ese archivo; se crea
# [021]     .specify/memory/ si falta).
# [021] Por directorio: borrar destino y copiar del stage (con backup previo en
# [021] <Root>/.kit-backup/<timestamp>/). Por archivo: sobrescribir siempre que
# [021] difiera (con backup). Si el stage no trae un item -> WARN + omitir (no
# [021] se borra el destino). Emite RESULT:kit-files:<estado> en stdout.
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
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-kit-files: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-kit-files: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] -Force no cambia la semantica aqui (clean+replace siempre sobrescribe
# [021] diferencias); se acepta por uniformidad con el orquestador.
if ($Force) { Write-Info "sync-kit-files: -Force sin efecto (clean+replace siempre sobrescribe diferencias)." }

# [021] Mapa ruta-relativa -> hash SHA256, excluyendo subcarpetas de nivel 1.
function Get-SyncRelHashMap {
    param([string]$Base, [string[]]$ExcludeTop = @())
    $map = @{}
    foreach ($f in (Get-ChildItem -LiteralPath $Base -Recurse -File -Force -ErrorAction Stop)) {
        $rel = ([IO.Path]::GetRelativePath($Base, $f.FullName)) -replace '\\', '/'
        $top = ($rel -split '/')[0]
        if ($ExcludeTop -contains $top) { continue }
        $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    return $map
}

# [021] Clean+replace de directorio con backup previo. Devuelve
# [021] creado|ok|sin-cambios. Nunca toca las subcarpetas de $ExcludeTop en el
# [021] destino (ni las borra ni las copia): se conservan tal cual.
function Invoke-KitCleanReplaceDir {
    param([string]$Src, [string]$Dst, [string]$BackupBase, [string]$BackupSub,
        [string[]]$ExcludeTop, [switch]$Simulate, [string]$Label)
    $existed = Test-Path -LiteralPath $Dst -PathType Container
    if (-not $existed) {
        if ($Simulate) { Write-Info "DryRun: crear $Dst desde $Src"; return "creado" }
        New-Item -ItemType Directory -Path $Dst -Force | Out-Null
        foreach ($item in (Get-ChildItem -LiteralPath $Src -Force -ErrorAction Stop)) {
            if ($ExcludeTop -contains $item.Name) { continue }
            Copy-Item -Path $item.FullName -Destination $Dst -Recurse -Force
        }
        Write-OK "$Label creado desde el stage."
        return "creado"
    }
    # [021] Idempotencia: comparar contenido (rutas relativas + hash) antes de tocar.
    $same = $false
    try {
        $a = Get-SyncRelHashMap -Base $Src -ExcludeTop $ExcludeTop
        $b = Get-SyncRelHashMap -Base $Dst -ExcludeTop $ExcludeTop
        $same = ($a.Count -eq $b.Count) -and (($a.Keys | Where-Object { -not $b.ContainsKey($_) -or $b[$_] -ne $a[$_] }).Count -eq 0)
    } catch {
        Write-Warn "sync-kit-files: no se pudo comparar $Label ($($_)); se asume cambio."
        $same = $false
    }
    if ($same) { Write-OK "$Label sin cambios."; return "sin-cambios" }
    if ($Simulate) {
        Write-Info "DryRun: reemplazaria $Dst desde $Src (con backup previo en $BackupBase)"
        return "ok"
    }
    # [021] Backup previo (solo si hay algo que reemplazar y no es DryRun).
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $BackupBase ("$stamp/$BackupSub")
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -Path (Join-Path $Dst "*") -Destination $backup -Recurse -Force
    Write-Info "Backup previo en $backup"
    foreach ($item in (Get-ChildItem -LiteralPath $Dst -Force -ErrorAction Stop)) {
        if ($ExcludeTop -contains $item.Name) { continue }
        Remove-Item -LiteralPath $item.FullName -Recurse -Force
    }
    foreach ($item in (Get-ChildItem -LiteralPath $Src -Force -ErrorAction Stop)) {
        if ($ExcludeTop -contains $item.Name) { continue }
        Copy-Item -Path $item.FullName -Destination $Dst -Recurse -Force
    }
    Write-OK "$Label reemplazado desde el stage."
    return "ok"
}

# [021] Sync de un archivo suelto con backup previo. Devuelve
# [021] creado|ok|sin-cambios|omitido-item (omitido-item = el stage no lo trae).
function Invoke-KitSingleFile {
    param([string]$SrcFile, [string]$DstFile, [string]$BackupBase, [string]$BackupRel,
        [switch]$Simulate, [string]$Label)
    if (-not (Test-Path -LiteralPath $SrcFile -PathType Leaf)) {
        Write-Warn "sync-kit-files: el stage no trae $Label ($SrcFile); no se borra el destino."
        return "omitido-item"
    }
    $dstExists = Test-Path -LiteralPath $DstFile -PathType Leaf
    if ($dstExists) {
        try {
            $ha = (Get-FileHash -LiteralPath $SrcFile -Algorithm SHA256 -ErrorAction Stop).Hash
            $hb = (Get-FileHash -LiteralPath $DstFile -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($ha -eq $hb) { Write-OK "$Label sin cambios."; return "sin-cambios" }
        } catch {
            Write-Warn "sync-kit-files: no se pudo comparar $Label ($($_)); se asume cambio."
        }
    }
    if ($Simulate) {
        if ($dstExists) { Write-Info "DryRun: sobrescribiria $DstFile desde el stage (con backup previo)" }
        else { Write-Info "DryRun: crear $DstFile desde el stage" }
        return ($dstExists ? "ok" : "creado")
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
    if ($dstExists) { Write-OK "$Label actualizado desde el stage." } else { Write-OK "$Label creado desde el stage." }
    return ($dstExists ? "ok" : "creado")
}

Write-Step "sync-kit-files: sincronizando archivos del kit en $RootPath"

$backupBase = Join-Path $RootPath ".kit-backup"
$itemStatus = @()

try {
    # [021] scripts/ excluyendo scripts/sync/ (no auto-sobrescribirse).
    $srcScripts = Join-Path $StageDir "scripts"
    $dstScripts = Join-Path $RootPath "scripts"
    if (-not (Test-Path -LiteralPath $srcScripts -PathType Container)) {
        Write-Warn "sync-kit-files: el stage no trae scripts/ ($srcScripts); no se borra el destino."
        $itemStatus += "omitido-item"
    } else {
        $itemStatus += Invoke-KitCleanReplaceDir -Src $srcScripts -Dst $dstScripts `
            -BackupBase $backupBase -BackupSub "kit-files/scripts" `
            -ExcludeTop @("sync") -Simulate:$DryRun -Label "scripts/ (sin sync/)"
    }
    foreach ($f in @("AGENTS.md", "README.md")) {
        $itemStatus += Invoke-KitSingleFile -SrcFile (Join-Path $StageDir $f) `
            -DstFile (Join-Path $RootPath $f) -BackupBase $backupBase `
            -BackupRel "kit-files/$f" -Simulate:$DryRun -Label $f
    }
    $itemStatus += Invoke-KitSingleFile `
        -SrcFile (Join-Path $StageDir ".specify/memory/constitution.md") `
        -DstFile (Join-Path $RootPath ".specify/memory/constitution.md") `
        -BackupBase $backupBase -BackupRel "kit-files/specify-memory-constitution.md" `
        -Simulate:$DryRun -Label ".specify/memory/constitution.md"
} catch {
    Write-Fail "sync-kit-files: $_"
    exit 1
}

# [021] Agregacion: si el stage no trajo ningun item -> omitido (nada que hacer,
# [021] destino intacto). Si algun item cambio -> ok. Si todo igual -> sin-cambios.
$real = @($itemStatus | Where-Object { $_ -ne "omitido-item" })
if ($real.Count -eq 0) {
    Write-Host "RESULT:kit-files:omitido"
} elseif (@($real | Where-Object { $_ -eq "ok" -or $_ -eq "creado" }).Count -gt 0) {
    Write-Host "RESULT:kit-files:ok"
} else {
    Write-Host "RESULT:kit-files:sin-cambios"
}

Show-ExecutionSummary -Title "sync-kit-files"
