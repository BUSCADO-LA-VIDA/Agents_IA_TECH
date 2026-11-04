<# 
.SYNOPSIS
    Script de gestión de archivos huérfanos para sincronización de kits.
    Contiene las funciones: Find-OrphanKitFiles, Show-OrphanList, 
    Remove-OrphanFiles, Move-OrphanFilesToBackup, Invoke-OrphanDecision.
#>

[CmdletBinding()]

# Dot-source de la librería común y inicialización de log
. ../lib/common.ps1
Initialize-SyncLog

param(
    [string]$RootPath = "",
    [string]$TempDir = "",
    [string]$OrphanAction = "Preguntar",
    [switch]$DryRun
)

# --- Find-OrphanKitFiles ---
function Find-OrphanKitFiles {
    param(
        [string]$RootPath = "",
        [string]$TempDir = ""
    )

    if (-not $RootPath) {
        $RootPath = (Split-Path -Parent $PSScriptRoot)
    }
    if (-not $TempDir) {
        throw "Find-OrphanKitFiles: falta -TempDir (clon maestro). Se aborta la fase de huerfanos."
    }
    if (-not (Test-Path -LiteralPath $TempDir)) {
        throw "Find-OrphanKitFiles: el clon maestro no existe ($TempDir). Se aborta la fase de huerfanos: jamas decidir huerfanos contra un clon fallido."
    }

    # Fail-closed: maestro incompleto => abortar (todo lo local pareceria huerfano).
    $allowDirs = @(".github", ".opencode", ".doc_agents")
    foreach ($d in $allowDirs) {
        if (-not (Test-Path -LiteralPath (Join-Path $TempDir $d))) {
            throw "Find-OrphanKitFiles: clon maestro incompleto (falta '$d' en $TempDir). Se aborta la fase de huerfanos."
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
            # Defensa: rechaza rutas que escapan (fail-closed).
            if ($rel -match '(^|/)\.\.(/|$)') { continue }
            # .github/context-mode/ es runtime local de cada proyecto: jamas huerfano.
            if ($rel -match '(^|/)\.github/context-mode(/|$)') { continue }
            $masterPath = Join-Path $TempDir ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path -LiteralPath $masterPath)) {
                $orphans += $rel
            }
        }
    }
    return $orphans
}

# --- Show-OrphanList ---
function Show-OrphanList {
    param(
        [string[]]$Orphans = @(),
        [string]$RootPath = ""
    )

    Write-Step "Huerfanos detectados ($($Orphans.Count)): existen local, no existen en el maestro."
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

# --- Remove-OrphanFiles ---
function Remove-OrphanFiles {
    param(
        [string[]]$Files = @(),
        [string]$RootPath = ""
    )

    if ($script:DryRun) {
        Write-Warn "Remove-OrphanFiles: -DryRun activo, no se borra nada (fail-closed)."
        return @()
    }
    $rootCanon = [IO.Path]::GetFullPath($RootPath)
    $sep = [IO.Path]::DirectorySeparatorChar
    $deleted = @()
    foreach ($rel in $Files) {
        if ($rel -match '(^|/)\.\.(/|$)') {
            Write-Warn "  [RECHAZADO] $rel - ruta fuera de alcance (..), no se toca."
            continue
        }
        $full = [IO.Path]::GetFullPath((Join-Path $RootPath ($rel -replace '/', $sep)))
        if (-not $full.StartsWith($rootCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel - containment-check: fuera del proyecto, no se toca."
            continue
        }
        try {
            $item = Get-Item -LiteralPath $full -ErrorAction Stop
            $size = $item.Length
            $date = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            $hash = ((Get-FileHash -LiteralPath $full -Algorithm SHA256 -ErrorAction Stop).Hash).Substring(0, 12)
        } catch {
            Write-Warn "  [OMITIDO] $rel - ya no existe o no se puede leer, no se toca."
            continue
        }
        Remove-Item -LiteralPath $full -Force
        $deleted += $rel
        Write-Host "  [BORRADO] $rel ($size bytes, $date, sha256:$hash...)" -ForegroundColor Red
    }
    return $deleted
}

# --- Move-OrphanFilesToBackup ---
function Move-OrphanFilesToBackup {
    param(
        [string[]]$Files = @(),
        [string]$RootPath = ""
    )

    if ($script:DryRun) {
        Write-Warn "Move-OrphanFilesToBackup: -DryRun activo, no se mueve nada (fail-closed)."
        return @{ Moved = @(); Destino = "" }
    }
    if (-not $Files -or $Files.Count -eq 0) { return @{ Moved = @(); Destino = "" } }

    # Seguridad: revisar_manualmente/ debe estar en .gitignore (no versionar respaldos).
    $gitignore = Join-Path $RootPath ".gitignore"
    $gitText = ""
    try { $gitText = Get-Content -LiteralPath $gitignore -Raw -ErrorAction Stop } catch { $gitText = "" }
    if ($gitText -notmatch 'revisar_manualmente/') {
        Write-Warn "revisar_manualmente/ NO esta en .gitignore: no hacer commit de los respaldos (pueden contener secrets)."
    }

    # Carpeta del dia; si existe => sufijo -HHmmss; si aun existe => contador.
    $day = Get-Date -Format 'yyyyMMdd'
    $backupRoot = Join-Path $RootPath "revisar_manualmente\$day"
    if (Test-Path -LiteralPath $backupRoot) {
        $backupRoot = Join-Path $RootPath ("revisar_manualmente\" + $day + "-" + (Get-Date -Format 'HHmmss'))
    }
    $n = 2
    while (Test-Path -LiteralPath $backupRoot) {
        $backupRoot = Join-Path $RootPath ("revisar_manualmente" + $day + "-" + (Get-Date -Format 'HHmmss') + "_$n")
        $n++
    }
    $rootCanon = [IO.Path]::GetFullPath($RootPath)
    $backupCanon = [IO.Path]::GetFullPath($backupRoot)
    $sep = [IO.Path]::DirectorySeparatorChar

    $moved = @()
    foreach ($rel in ($Files | Sort-Object)) {
        if ($rel -match '(^|/)\.\.(/|$)') {
            Write-Warn "  [RECHAZADO] $rel - ruta fuera de alcance (..), no se toca."
            continue
        }
        $srcFull = [IO.Path]::GetFullPath((Join-Path $RootPath ($rel -replace '/', $sep)))
        if (-not $srcFull.StartsWith($rootCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel - containment-check: fuera del proyecto, no se toca."
            continue
        }
        if (-not (Test-Path -LiteralPath $srcFull)) {
            Write-Warn "  [OMITIDO] $rel - ya no existe, no se mueve."
            continue
        }
        try {
            $linkType = (Get-Item -LiteralPath $srcFull -ErrorAction Stop).LinkType
            if ($linkType) { Write-Info "  $rel es enlace ($linkType): se mueve el enlace como tal, sin seguirlo." }
        } catch { Write-Warn "  [OMITIDO] $rel - no se puede leer, no se mueve."; continue }

        $dstFull = [IO.Path]::GetFullPath((Join-Path $backupRoot ($rel -replace '/', $sep)))
        if (-not $dstFull.StartsWith($backupCanon + $sep, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "  [RECHAZADO] $rel - containment-check: el destino escapa del respaldo, se aborta ese movido."
            continue
        }
        # Nunca sobrescribir respaldo existente: sufijo incremental antes de la extension.
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

# --- Invoke-OrphanDecision ---
function Invoke-OrphanDecision {
    param(
        [string[]]$Orphans = @(),
        [string]$RootPath = "",
        [string]$OrphanAction = "Preguntar"
    )

    if (-not $RootPath) {
        $RootPath = (Split-Path -Parent $PSScriptRoot)
    }
    $inDryRun = [bool]$script:DryRun
    $withForce = [bool]$script:Force

    $norm = @{ "borrar" = "Borrar"; "conservar" = "Conservar"; "preguntar" = "Preguntar" }
    $key = "$OrphanAction".Trim().ToLowerInvariant()
    if ($norm.ContainsKey($key)) { $action = $norm[$key] } else {
        if ($OrphanAction) { Write-Warn "Invoke-OrphanDecision: -OrphanAction '$OrphanAction' no valido (Borrar|Conservar|Preguntar). Se usa 'Preguntar'." }
        $action = "Preguntar"
    }

    if (-not $Orphans -or $Orphans.Count -eq 0) {
        Write-OK "Sin huerfanos: todo lo local en .github/ .opencode/ .doc_agents/ existe en el maestro."
        return
    }

    Show-OrphanList -Orphans $Orphans -RootPath $RootPath

    if ($inDryRun) {
        Write-Info "DryRun: con -OrphanAction $action se haria lo siguiente (sin borrar ni mover nada):"
        switch ($action) {
            "Borrar"    { Write-Info "DryRun: se ELIMINARIAN $($Orphans.Count) huerfano(s) (en modo real no interactivo requiere -Force)." }
            "Conservar" { Write-Info "DryRun: se MOVERIAN $($Orphans.Count) huerfano(s) a revisar_manualmente\<yyyymmdd>\ preservando estructura." }
            default     { Write-Info "DryRun: se PREGUNTARIA [B]orrar todos / [C]onservar todos / [U]no por uno / [O]mitir (default seguro: Conservar)." }
        }
        Write-Info "DryRun: fase de huerfanos simulada. Documentacion/<AppName>/ nunca entra en alcance."
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
            Write-Warn "Modo no interactivo sin -OrphanAction explicito: default seguro Conservar (respaldo en revisar_manualmente/)."
            $effective = "Conservar"
        } else {
            $choice = ""
            try { $choice = (Read-Host "Huerfanos: [B]orrar todos / [C]onservar todos / [U]no por uno / [O]mitir = propios, dejar en su lugar [default: C]").Trim().ToLowerInvariant() } catch { $choice = "" }
            switch ($choice) {
                "b" {
                    $confirm = ""
                    try { $confirm = (Read-Host "CONFIRMAR: Borrar $($Orphans.Count) huerfano(s) SIN respaldo? [S = si / N = no] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
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
            try { $confirm = (Read-Host "CONFIRMAR: Borrar $($toDelete.Count) huerfano(s) SIN respaldo? [S/N] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
            if ($confirm -eq "s") { $confirmedViaPrompt = $true }
            else {
                Write-Warn "Borrado no confirmado: esos archivos pasan a Conservar."
                $toKeep += $toDelete
                $toDelete = @()
            }
        }
    } elseif ($effective -eq "__Omit__") {
        $omitted = @($Orphans)
        Write-Info "Se omiten $($omitted.Count) huerfano(s): se consideran propios y se dejan en su lugar."
    } elseif ($effective -eq "Borrar") {
        if ($confirmedViaPrompt) { $toDelete = @($Orphans) }
        elseif ($interactive) {
            $confirm = ""
            try { $confirm = (Read-Host "CONFIRMAR: -OrphanAction Borrar eliminara $($Orphans.Count) huerfano(s) SIN respaldo. Continuar? [S/N] [default: N]").Trim().ToLowerInvariant() } catch { $confirm = "" }
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

    # Informe final: que se borro / que se movio y donde / que se omitio.
    Write-Host ""
    if ($deleted.Count -gt 0) { Write-Warn "Borrados sin respaldo ($($deleted.Count)): $($deleted -join ', ')" }
    if ($backupResult.Moved.Count -gt 0) {
        $dstRel = ([IO.Path]::GetRelativePath($RootPath, $backupResult.Destino)) -replace '\\', '/'
        Write-OK "Conservados en respaldo ($($backupResult.Moved.Count)): $dstRel"
        foreach ($rel in ($backupResult.Moved | Sort-Object)) {
            Write-Host "    - $rel" -ForegroundColor DarkGray
        }
        Write-Warn "NO hacer commit de revisar_manualmente/ (puede contener credenciales); si un huerfano tenia secrets, rotalos; no reintroducir al kit sin revision manual."
    }
    if ($omitted.Count -gt 0) { Write-Info "Omitidos (propios, dejados en su lugar) ($($omitted.Count)): $($omitted -join ', ')" }
    if ($deleted.Count -eq 0 -and $backupResult.Moved.Count -eq 0 -and $omitted.Count -eq 0) {
        Write-OK "Fase de huerfanos completada sin cambios."
    }
}

# Ejecución principal: invocar decisión de huérfanos con parámetros recibidos
Invoke-OrphanDecision -Orphans @($TempDir) -RootPath $RootPath -OrphanAction $OrphanAction

# Escribir resultado final
Write-OK "RESULT:orphans:completed"