#!/usr/bin/env powershell
#requires -Version 7.0
# sync-backup-prune.ps1 — Capa de poda con protección backup del llamador
# FR-001, FR-002, FR-003, D1, SC-001
# Emite RESULT:backup-prune:<estado> al final

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RootPath,

    [Parameter()]
    [int]$KeepBackups = 2,

    [switch]$NoPrune,

    [Parameter()]
    [string]$OrphanAction = "Preguntar",

    [switch]$DryRun,

    # [036-T003-D1] Snapshot del conjunto inicial de backups capturado por el
    # orquestador al INICIO de la corrida (antes de que las capas creen backups).
    # Permite distinguir backups del llamador (pre-existentes) de los generados
    # por la corrida. Si no se provee, se captura al inicio de este script
    # (comportamiento de ejecución aislada, FR-018).
    [Parameter()]
    [string]$InitialStateFile = ""
)

# Dot-source la capa compartida de logging y sincronización
# Ruta correcta: este script vive en scripts/ y la librería común en scripts/sync/lib/
. "$PSScriptRoot/sync/lib/common.ps1"
Initialize-SyncLog

# Resolver rutas absolutas
$resolvedRoot = [IO.Path]::GetFullPath($RootPath)
$backupRoot = Join-Path $resolvedRoot ".kit-backup"

# ---- 1. Detectar backups pre-existentes (conjunto inicial) ----
# Al inicio de la corrida, identificar qué carpetas ya existían en .kit-backup/
# Estas carpetas se protegerán de la poda sin importar qué.
$initialBackupFolders = @()
if ($InitialStateFile -and (Test-Path -LiteralPath $InitialStateFile)) {
    # [036-T003-D1] El orquestador capturó el snapshot al inicio de la corrida
    # (antes de que las capas creen backups). Es la fuente de verdad correcta.
    $initialBackupFolders = @(Get-Content -LiteralPath $InitialStateFile | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() })
    Write-Step "sync-backup-prune: conjunto inicial desde snapshot del orquestador: $($initialBackupFolders.Count) carpetas"
} elseif (Test-Path -Path $backupRoot) {
    $initialBackupFolders = Get-ChildItem -Path $backupRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
}
# Guardar el conjunto inicial para referencia posterior (comparar por nombre, no por fecha)
$initialBackupSet = $initialBackupFolders | ForEach-Object { $_ } | Sort-Object

Write-Step "sync-backup-prune: detectadas $($initialBackupFolders.Count) carpetas de backup pre-existentes en $backupRoot"

# ---- 2. Si -NoPrune: no borrar nada, salir inmediatamente ----
if ($NoPrune) {
    Write-Info "sync-backup-prune: -NoPrune especificado, no se realizará poda alguna."
    Write-Host "RESULT:backup-prune:sin-cambios"
    exit 0
}

# ---- 3. Identificar carpetas de backup generadas por esta corrida ----
# Las carpetas que NO estaban en el conjunto inicial son las generadas por esta corrida.
# Usar comparación de conjunto (set difference) para excluir las pre-existentes.
if (Test-Path -Path $backupRoot) {
    $allFolders = Get-ChildItem -Path $backupRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    $newFolders = $allFolders | Where-Object { $_ -notin $initialBackupSet }
    
    Write-Step "sync-backup-prune: carpetas nuevas (generadas por esta corrida): $($newFolders.Count)"
    Write-Info "sync-backup-prune: carpetas pre-existentes protegidas: $($initialBackupFolders.Count)"

    # Si no hay carpetas nuevas, no hay nada que podar
    if ($newFolders.Count -eq 0) {
        Write-Info "sync-backup-prune: no hay carpetas nuevas por podar (todas son pre-existentes)."
        Write-Host "RESULT:backup-prune:sin-cambios"
        exit 0
    }
} else {
    Write-Info "sync-backup-prune: no existe .kit-backup/, no hay qué podar."
    Write-Host "RESULT:backup-prune:sin-cambios"
    exit 0
}

# ---- 4. Determinar qué carpetas conservar ----
# a) Siempre conservar las carpetas pre-existentes (las del llamador)
# b) De las carpetas nuevas, conservar las $KeepBackups más recientes
# c) El resto se podarán

# Para ordenar por fecha de modificación (más recientes primero)
$newFoldersFull = @()
if (Test-Path -Path $backupRoot) {
    $newFoldersFull = Get-ChildItem -Path $backupRoot -Directory | Where-Object { $_.Name -in $newFolders }
}

# Ordenar por LastWriteTime descendente (más recientes primero)
# [036-T003-D1] Forzar a array con @(...): con exactamente 1 carpeta nueva,
# 'Get-ChildItem | Sort-Object' devuelve un ESCALAR, y el indizado '$arr[0..n]'
# sobre un escalar devuelve vacio, lo que dejaría $recentToKeepNames vacio y
# podaría la unica carpeta nueva (violando -KeepBackups). Forzar array lo evita.
$sortedNewFolders = @($newFoldersFull | Sort-Object -Property LastWriteTime -Descending)

# Determinar cuáles conservar (las n más recientes + las pre-existentes)
$foldersToKeep = @()
$foldersToKeep += $initialBackupFolders  # Proteger las pre-existentes

# De las carpetas nuevas, tomar las $KeepBackups más recientes
$recentToKeepNames = @()
if ($sortedNewFolders.Count -ge $KeepBackups) {
    $recentToKeepNames = $sortedNewFolders[0..($KeepBackups - 1)] | ForEach-Object { $_.Name }
} else {
    $recentToKeepNames = $sortedNewFolders | ForEach-Object { $_.Name }
}
$foldersToKeep += $recentToKeepNames

# Calcular las carpetas a podar (nuevas - las que conservamos)
$foldersToPrune = $sortedNewFolders | Where-Object { $_.Name -notin $recentToKeepNames }

Write-Step "sync-backup-prune: carpetas a conservar (pre-existentes + $KeepBackups más recientes): $($foldersToKeep.Count)"
Write-Step "sync-backup-prune: carpetas a podar (nuevas - conservadas): $($foldersToPrune.Count)"

# ---- 5. Ejecutar poda ----
if ($DryRun) {
    Write-Info "sync-backup-prune: modo DRY-RUN - no se borrarán carpetas."
    # Informar qué sucedería
    foreach ($folder in $foldersToPrune) {
        $folderPath = Join-Path $backupRoot $folder.Name
        $size = 0
        try { $size = (Get-ChildItem -Path $folderPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { }
        $sizeStr = if ($size -and $size -gt 0) { "{0:N0} bytes" -f $size } else { "0 bytes" }
        Write-Info "  [DRY-RUN] Borraría: $($folder.Name) ($sizeStr)"
    }
    Write-Host "RESULT:backup-prune:ok"
    exit 0
}

# Modo real: efectivamente borrar
Write-Step "sync-backup-prune: iniciando poda de carpetas..."

$pruneSummary = @()

# [036-T003-D1] CORRECCION: iterar SOLO '$foldersToPrune' (los que exceden la
# retencion -KeepBackups), NO '$sortedNewFolders' (todos los nuevos). Esto
# preserva las $KeepBackups mas recientes generadas por la corrida (FR-002).
foreach ($folder in $foldersToPrune) {
    $folderPath = Join-Path $backupRoot $folder.Name
    $size = 0
    $keepRule = "KeepBackups=$KeepBackups (descartar después de $KeepBackups más recientes)"

    # Calcular tamaño antes de borrar
    try {
        $size = (Get-ChildItem -Path $folderPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if (-not $size -or $size -eq 0) { $size = 0 }
    } catch {
        $size = 0
    }

    try {
        # Borrar la carpeta (y su contenido)
        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction Stop

        $pruneSummary += [pscustomobject]@{
            Folder = $folder.Name
            Size   = $size
            Rule   = $keepRule
        }

        Write-OK "sync-backup-prune: borrado $($folder.Name) ($size bytes) - regla: $keepRule"
    } catch {
        # Fallo de poda = fail-open: WARN, continuar con el resto
        $errMsg = $_.Exception.Message
        Write-Warn "sync-backup-prune: falló el borrado de $($folder.Name): $errMsg"
        $pruneSummary += [pscustomobject]@{
            Folder = $folder.Name
            Size   = $size
            Rule   = $keepRule
            Error  = $errMsg
        }
    }
}

# Registrar resumen de poda
Write-Step "sync-backup-prune: resumen de poda completada"
if ($pruneSummary.Count -gt 0) {
    foreach ($item in $pruneSummary) {
        # [036-T003-D1] Registrar cada borrado en el resumen de ejecución (FR-003)
        # con ruta, tamaño y regla aplicada. Write-Warn lo hace visible tanto en
        # pantalla como en el contador de WARNs de Show-ExecutionSummary.
        $pathStr = Join-Path $backupRoot $item.Folder
        $sizeStr = "{0:N0} bytes" -f $item.Size
        if ($item.Error) {
            Write-Warn "backup-prune: borrado registrado (fallo) $($item.Folder) | ruta=$pathStr | tamaño=$sizeStr | regla=$($item.Rule) | error=$($item.Error)"
        } else {
            Write-Warn "backup-prune: borrado $($item.Folder) | ruta=$pathStr | tamaño=$sizeStr | regla=$($item.Rule)"
        }
    }
}

$prunedCount = ($pruneSummary | Where-Object { -not $_.Error }).Count
$errorCount = ($pruneSummary | Where-Object { $_.Error }).Count

# [036-T003-D1] Emitir el resumen de ejecución de la capa para que el orquestador
# (o una ejecución aislada) vea el conteo de borrados y errores de poda.
Show-ExecutionSummary -Title "backup-prune"

Write-Info "sync-backup-prune: completadas. Podas exitosas: $prunedCount, error(es): $errorCount"

# Emitir RESULT final
if ($errorCount -gt 0) {
    Write-Host "RESULT:backup-prune:error"
    exit 1
} elseif ($prunedCount -gt 0) {
    Write-Host "RESULT:backup-prune:poda_hecha"
    exit 0
} else {
    # Si no se podó nada (aunque no haya sido -NoPrune), informar sin-cambios
    Write-Host "RESULT:backup-prune:sin-cambios"
    exit 0
}