#!/usr/bin/env powershell
#requires -Version 7.0
# [021-DEPRECATED] Flujo nuevo: scripts/sync-kit-agents.ps1 (spec 021-sync-kit-agents). Este script se mantiene por compatibilidad (lo invoca Invoke-SyncKit del bootstrap); no agregar funcionalidad aqui.
# =============================================================================
# sync-kit.ps1
# =============================================================================
# Sincroniza el kit transversal desde el repo maestro (GitHub) hacia el proyecto
# local. Migrado desde la funcion Sync-TransversalKit de
# plataformador-bootstrap.ps1 (Spec 015: division sync-kit / bootstrap).
#
# Responsabilidades:
#   - Clonar shallow el repo maestro (fail-closed: solo https://github.com/).
#   - Copiar SOLO los transversales: .github/, .opencode/, .doc_agents/,
#     scripts/, .specify/memory/constitution.md, AGENTS.md, opencode.json,
#     README.md, sync-agents.ps1, upgrade_framework.ps1.
#   - NUNCA tocar Documentacion/<AppName>/ (frontera kit <-> app, guardrail 1).
#   - Excluir .opencode/config.json (posibles credenciales).
#   - Detectar y decidir huerfanos (Borrar|Conservar|Preguntar).
#
# Uso:
#   .\scripts\sync-kit.ps1
#   .\scripts\sync-kit.ps1 -DryRun
#   .\scripts\sync-kit.ps1 -Force
#   .\scripts\sync-kit.ps1 -RepoUrl <url>
#   .\scripts\sync-kit.ps1 -OrphanAction Borrar|Conservar|Preguntar
#   .\scripts\sync-kit.ps1 -RootPath <ruta>
# Requisito: PowerShell 7+ (pwsh = 7). No funciona en Windows PowerShell 5.1.
# =============================================================================

[CmdletBinding()]
param(
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$RootPath = "",
    [string]$OrphanAction = "Preguntar",
    [switch]$DryRun,
    [switch]$Force,
    # [002-KITPATH] Fuente local del kit (opt-in): checkout local del kit que
    # manda sobre GitHub. Permite replicar rama + cambios sin pushear a los
    # proyectos consumidores. Solo -Force controla sobrescritura (igual que
    # en modo GitHub). Jamas acepta URLs (fail-closed).
    [string]$KitPath = ""
)

$ErrorActionPreference = "Stop"

# Acumulacion de WARNs/ERRORs para el cuadro resumen final.
$script:Warnings = [System.Collections.Generic.List[string]]::new()
$script:Errors = [System.Collections.Generic.List[string]]::new()
$script:EmittedWarns = [System.Collections.Generic.List[string]]::new()

# =============================================================================
# Logging
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

function Show-ExecutionSummary {
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " RESUMEN DE LA EJECUCION (sync-kit)" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " WARNs: $($uniqueWarns.Count)"
    foreach ($w in $uniqueWarns) { Write-Host "   - $w" }
    Write-Host " ERRORs: $($uniqueErrors.Count)"
    foreach ($e in $uniqueErrors) { Write-Host "   - $e" }
    Write-Host "===============================================================" -ForegroundColor Yellow
}

# =============================================================================
# Allowlist de owners de confianza para validar URLs (fail-closed).
# Solo se permite https://github.com/<owner-en-allowlist>/<repo>
# =============================================================================
$TrustedOwners = @(
    "BUSCADO-LA-VIDA",
    "github",
    "microsoft",
    "DeusData",
    "mksglu"
)

function Test-TrustedGithubUrl {
    param([string]$Url)
    # Solo https://github.com/<owner>/<repo> con owner en allowlist
    if ($Url -notmatch '^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$') {
        return $false
    }
    $owner = $matches[1]
    return $TrustedOwners -contains $owner
}

# =============================================================================
# Deteccion de artefactos de la herramienta OpenCode (nunca versionar).
# =============================================================================
function Test-ToolArtifactPath {
    param([string]$Rel)

    # 1) node_modules en cualquier nivel dentro de .opencode/.
    if ($Rel -match '(^|/)node_modules(/|$)') { return $true }
    # 2) Manifiestos de dependencias dentro de .opencode/.
    if ($Rel -eq '.opencode/package.json' -or
        $Rel -eq '.opencode/package-lock.json' -or
        $Rel -eq '.opencode/bun.lock') { return $true }
    # 3) Carpetas lib/ y bin/ SOLO dentro de .opencode/.
    if ($Rel -match '^\.opencode/(lib|bin)(/|$)') { return $true }

    return $false
}

# =============================================================================
# Huerfanos: existen local, no existen en el maestro.
# =============================================================================
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
            # Exclusion de artefactos de la herramienta OpenCode.
            if (Test-ToolArtifactPath $rel) { continue }
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
        $backupRoot = Join-Path $RootPath ("revisar_manualmente\" + $day + "-" + (Get-Date -Format 'HHmmss') + "_$n")
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

# =============================================================================
# 034: merge de propagacion (opencode.json por claves, AGENTS.md por bloque)
# + comparador local B-01/B-02.
#
# - B-01/B-02: esta rama llamaba a Compare-KitFileContent, funcion que NO vive
#   en este script (solo en scripts/sync-kit-lib.ps1, spec 029, sin dot-source).
#   Con $ErrorActionPreference = "Stop" la llamada lanzaba
#   CommandNotFoundException, el try externo la capturaba y el sync ABORTABA en
#   el primer archivo de raiz. Ahora se usa Compare-KitFileState, local y con el
#   contrato que el motor ya esperaba: 'Equal' | 'EolOnly' | 'Different'.
# - opencode.json y AGENTS.md dejan de ser SKIP: viajan por merge (por claves y
#   por bloque delimitado) preservando lo que pertenece al proyecto.
#
# Todo autocontenido a proposito: NO se hace dot-source de
# scripts/sync-kit-lib.ps1 porque su ausencia en un consumidor nuevo romperia el
# sync antes de haber copiado scripts/. Cuando la 029 se implemente, su
# comparador reemplaza a este sin cambiar el contrato del motor.
# =============================================================================

function Compare-KitFileState {
    <#
    .SYNOPSIS
        Compara maestro vs destino y clasifica la diferencia (comparador local de
        respaldo para la rama de archivos de raiz del sync).
    .OUTPUTS
        'Equal'     : mismo contenido (incluye BOM y fin de linea).
        'EolOnly'   : solo difiere el fin de linea (LF vs CRLF).
        'Different' : otra diferencia, BOM de un solo lado, o fallo de lectura.
    #>
    param(
        [string]$Source,
        [string]$Destination
    )

    try {
        $srcBytes = [System.IO.File]::ReadAllBytes($Source)
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
    } catch {
        Write-Warn "Compare-KitFileState: no se pudo leer '$Source' o '$Destination' ($_): se trata como 'Different'."
        return 'Different'
    }

    # BOM UTF-8 (EF BB BF): si la presencia difiere entre los dos, no son iguales.
    $srcHasBom = ($srcBytes.Length -ge 3 -and $srcBytes[0] -eq 0xEF -and $srcBytes[1] -eq 0xBB -and $srcBytes[2] -eq 0xBF)
    $dstHasBom = ($dstBytes.Length -ge 3 -and $dstBytes[0] -eq 0xEF -and $dstBytes[1] -eq 0xBB -and $dstBytes[2] -eq 0xBF)
    if ($srcHasBom -ne $dstHasBom) { return 'Different' }

    try {
        # ReadAllText descarta el BOM. Comparacion case-sensitive (-ceq).
        $srcText = [System.IO.File]::ReadAllText($Source)
        $dstText = [System.IO.File]::ReadAllText($Destination)
    } catch {
        Write-Warn "Compare-KitFileState: no se pudo leer el contenido ($_): se trata como 'Different'."
        return 'Different'
    }

    if ($srcText -ceq $dstText) { return 'Equal' }

    $srcNorm = $srcText -replace "`r`n", "`n"
    $dstNorm = $dstText -replace "`r`n", "`n"
    if ($srcNorm -ceq $dstNorm) { return 'EolOnly' }

    return 'Different'
}

function Merge-OpenCodeConfig {
    <#
    .SYNOPSIS
        Merge por claves de opencode.json: el maestro manda sobre $schema,
        instructions y default_agent; el proyecto conserva mcp, model,
        small_model, permission, lsp y cualquier clave desconocida.
    .NOTES
        La edicion es TEXTUAL sobre el string del destino a proposito:
        re-serializar el objeto con ConvertTo-Json reordenaria claves y
        reindentaria todo el archivo.
    #>
    param(
        [string]$Source,
        [string]$Destination,
        [string]$ProjectRoot,
        [switch]$Force
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Write-Warn "opencode.json: no existe la plantilla del maestro ($Source); se omite el merge."
        return
    }
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "  [FILE] opencode.json (copiado del maestro)" -ForegroundColor Cyan
        return
    }

    # BOM y estilo de fin de linea originales: se preservan al escribir.
    $dstBytes = $null
    $original = $null
    try {
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
        $original = [System.IO.File]::ReadAllText($Destination)
    } catch {
        Write-Warn "opencode.json: no se pudo leer el archivo local ($_): se conserva sin tocar (fail-closed)."
        return
    }
    $hadBom = ($dstBytes.Length -ge 3 -and $dstBytes[0] -eq 0xEF -and $dstBytes[1] -eq 0xBB -and $dstBytes[2] -eq 0xBF)
    $nl = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }

    # Fail-closed: si el local no parsea, no se escribe absolutamente nada.
    $dstJson = $null
    try {
        $dstJson = $original | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $dstJson = $null
    }
    if ($null -eq $dstJson) {
        Write-Warn "opencode.json local no parsea (JSON invalido): se conserva sin tocar (fail-closed)."
        return
    }

    # El maestro tambien debe parsear; si no, no se modifica el local.
    $srcJson = $null
    try {
        $srcJson = [System.IO.File]::ReadAllText($Source) | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $srcJson = $null
    }
    if ($null -eq $srcJson) {
        Write-Warn "opencode.json: la plantilla del maestro no parsea (JSON invalido); no se modifica el local."
        return
    }

    $newText = $original

    # --- $schema (clave escalar gestionada) ---
    $schemaProp = $srcJson.PSObject.Properties['$schema']
    if (($null -ne $schemaProp) -and ($null -ne $schemaProp.Value)) {
        # Literal JSON completo (comillas + escapes) del valor del maestro.
        $schemaLiteral = ConvertTo-Json -InputObject ([string]$schemaProp.Value) -Compress
        $schemaRx = '("\$schema"\s*:\s*)"[^"]*"'
        if ([regex]::IsMatch($newText, $schemaRx)) {
            $newText = [regex]::Replace($newText, $schemaRx, ('$1' + $schemaLiteral.Replace('$', '$$')))
        } else {
            $braceIdx = $newText.IndexOf('{')
            if ($braceIdx -ge 0) {
                $newText = $newText.Insert(($braceIdx + 1), ($nl + '  "$schema": ' + $schemaLiteral + ','))
            }
        }
    }

    # --- instructions (array plano de strings) ---
    $instrProp = $srcJson.PSObject.Properties['instructions']
    if ($null -eq $instrProp) {
        Write-Warn "opencode.json: el maestro no declara 'instructions'; se omite esa clave (se conserva la local)."
    } else {
        $instrValue = $instrProp.Value
        $instrOk = $false
        if (($null -ne $instrValue) -and ($instrValue -isnot [string]) -and ($instrValue -is [System.Collections.IEnumerable])) {
            $instrOk = $true
            foreach ($entry in $instrValue) {
                if ($entry -isnot [string]) { $instrOk = $false; break }
            }
        }
        if (-not $instrOk) {
            Write-Warn "opencode.json: 'instructions' del maestro no es un array plano de strings; se omite esa clave (se conserva la local)."
        } else {
            $instrLiteral = '[' + ((@($instrValue) | ForEach-Object { ConvertTo-Json -InputObject ([string]$_) -Compress }) -join ', ') + ']'
            $instrRx = '("instructions"\s*:\s*)\[[^\]]*\]'
            if ([regex]::IsMatch($newText, $instrRx)) {
                $newText = [regex]::Replace($newText, $instrRx, ('$1' + $instrLiteral.Replace('$', '$$')))
            } else {
                $braceIdx = $newText.IndexOf('{')
                if ($braceIdx -ge 0) {
                    $newText = $newText.Insert(($braceIdx + 1), ($nl + '  "instructions": ' + $instrLiteral + ','))
                }
            }
        }
    }

    # --- default_agent (FR-15 / spec 034 seccion 19.3) ---
    $masterDefault = $null
    $masterDefaultProp = $srcJson.PSObject.Properties['default_agent']
    if (($null -ne $masterDefaultProp) -and ($null -ne $masterDefaultProp.Value)) {
        $masterDefault = ([string]$masterDefaultProp.Value).Trim()
    }

    if (-not $masterDefault) {
        Write-Warn "opencode.json: el maestro no declara 'default_agent'; se omite esa clave (se conserva la local)."
    } else {
        $writeDefault = $false
        $defaultReason = 'igual'
        $currentDefault = ''
        $dstDefaultProp = $dstJson.PSObject.Properties['default_agent']
        if ($Force) {
            $writeDefault = $true
            $defaultReason = 'force'
        } elseif ($null -eq $dstDefaultProp) {
            $writeDefault = $true
            $defaultReason = 'agregado'
        } else {
            $currentDefault = ([string]$dstDefaultProp.Value).Trim()
            if ($currentDefault -ceq $masterDefault) {
                $defaultReason = 'igual'
            } elseif ($currentDefault -ceq 'build') {
                $writeDefault = $true
                $defaultReason = 'build'
            } else {
                # Agente del kit con mode: primary -> se respeta la eleccion del proyecto.
                $agentIsPrimary = $false
                if ($ProjectRoot) {
                    $agentPath = Join-Path $ProjectRoot (".opencode/agents/$currentDefault.md")
                    if (Test-Path -LiteralPath $agentPath -PathType Leaf) {
                        try {
                            $head = @(Get-Content -LiteralPath $agentPath -TotalCount 25 -ErrorAction Stop) -join "`n"
                            if ($head -match '(?m)^mode:\s*primary\s*$') { $agentIsPrimary = $true }
                        } catch {
                            $agentIsPrimary = $false
                        }
                    }
                }
                if ($agentIsPrimary) {
                    $defaultReason = 'preservar'
                } else {
                    $writeDefault = $true
                    $defaultReason = 'invalido'
                }
            }
        }

        if ($writeDefault) {
            $defaultLiteral = ConvertTo-Json -InputObject $masterDefault -Compress
            $defaultRx = '("default_agent"\s*:\s*)"[^"]*"'
            if ([regex]::IsMatch($newText, $defaultRx)) {
                $newText = [regex]::Replace($newText, $defaultRx, ('$1' + $defaultLiteral.Replace('$', '$$')))
            } else {
                $braceIdx = $newText.IndexOf('{')
                if ($braceIdx -ge 0) {
                    $newText = $newText.Insert(($braceIdx + 1), ($nl + '  "default_agent": ' + $defaultLiteral + ','))
                }
            }
        }

        if ($defaultReason -eq 'agregado') {
            Write-OK "  [OK] opencode.json: default_agent agregado (='$masterDefault')"
        } elseif ($defaultReason -eq 'build') {
            Write-Warn "opencode.json: default_agent apuntaba a 'build' (fallback silencioso); se corrige a '$masterDefault'."
        } elseif ($defaultReason -eq 'invalido') {
            Write-Warn "opencode.json: default_agent '$currentDefault' no es un agente del kit con mode: primary; se corrige a '$masterDefault'."
        } elseif ($defaultReason -eq 'preservar') {
            Write-Info "opencode.json: default_agent '$currentDefault' es un agente del kit con mode: primary; se respeta la eleccion del proyecto."
        } elseif ($defaultReason -eq 'force') {
            Write-OK "  [OK] opencode.json: default_agent forzado a '$masterDefault' (-Force)"
        }
    }

    if ($newText -ceq $original) {
        Write-OK "  [OK] opencode.json - sin cambios (merge por claves)"
        return
    }

    # Backup junto al destino (patron ignorado por .gitignore: opencode.json.bak-*).
    $backupPath = "$Destination.bak-" + (Get-Date -Format 'yyyyMMddTHHmmss')
    try {
        Copy-Item -LiteralPath $Destination -Destination $backupPath -Force
    } catch {
        Write-Fail "opencode.json: no se pudo crear el backup ($_); no se escribe."
        return
    }

    try {
        $encoding = [System.Text.UTF8Encoding]::new($hadBom)
        [System.IO.File]::WriteAllText($Destination, $newText, $encoding)
        $null = Get-Content -LiteralPath $Destination -Raw -Encoding utf8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Write-OK "  [OK] opencode.json - merge por claves aplicado (backup: $(Split-Path -Leaf $backupPath))"
    } catch {
        Copy-Item -LiteralPath $backupPath -Destination $Destination -Force
        Write-Fail "opencode.json: el JSON resultante no valida ($_); se restauro el backup."
    }
}

function Merge-KitBlock {
    <#
    .SYNOPSIS
        Merge por bloque delimitado de AGENTS.md: reemplaza solo el tramo entre
        los marcadores KIT-BLOCK del maestro, preservando el resto del archivo
        (que es del proyecto).
    .NOTES
        Fail-closed ante marcadores corruptos: si el local tiene START sin END,
        END sin START, duplicados o desordenados, no se escribe nada.
    #>
    param(
        [string]$Source,
        [string]$Destination,
        [string]$BlockId = 'arranque-por-defecto'
    )

    $startMarker = "<!-- KIT-BLOCK:START $BlockId -->"
    $endMarker = "<!-- KIT-BLOCK:END $BlockId -->"

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Write-Warn "AGENTS.md: no existe la plantilla del maestro ($Source); se omite el merge del bloque."
        return
    }
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "  [FILE] AGENTS.md (copiado del maestro)" -ForegroundColor Cyan
        return
    }

    $masterText = $null
    try {
        $masterText = [System.IO.File]::ReadAllText($Source)
    } catch {
        Write-Warn "AGENTS.md: no se pudo leer el maestro ($_); se omite el merge del bloque."
        return
    }

    # El maestro debe tener exactamente un START y un END, en ese orden.
    $mStartCount = ([regex]::Matches($masterText, [regex]::Escape($startMarker))).Count
    $mEndCount = ([regex]::Matches($masterText, [regex]::Escape($endMarker))).Count
    $mStartIdx = $masterText.IndexOf($startMarker, [System.StringComparison]::Ordinal)
    $mEndIdx = $masterText.IndexOf($endMarker, [System.StringComparison]::Ordinal)
    if (($mStartCount -ne 1) -or ($mEndCount -ne 1) -or ($mStartIdx -lt 0) -or ($mEndIdx -lt 0) -or ($mStartIdx -ge $mEndIdx)) {
        Write-Warn "AGENTS.md: bloque '$BlockId' del maestro sin marcadores KIT-BLOCK validos: no se modifica el local"
        return
    }

    # Bloque INCLUSIVE: desde el inicio de la linea del START hasta el final de
    # la linea del END (sin el salto de linea posterior al END).
    $block = $masterText.Substring($mStartIdx, ($mEndIdx + $endMarker.Length) - $mStartIdx)

    $dstBytes = $null
    $original = $null
    try {
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
        $original = [System.IO.File]::ReadAllText($Destination)
    } catch {
        Write-Warn "AGENTS.md: no se pudo leer el archivo local ($_): no se escribe (fail-closed)."
        return
    }
    $hadBom = ($dstBytes.Length -ge 3 -and $dstBytes[0] -eq 0xEF -and $dstBytes[1] -eq 0xBB -and $dstBytes[2] -eq 0xBF)
    $usesCrlf = $original.Contains("`r`n")
    $nl = if ($usesCrlf) { "`r`n" } else { "`n" }

    # Normalizar el bloque insertado al estilo dominante del destino.
    $blockNorm = $block -replace "`r`n", "`n"
    if ($usesCrlf) { $blockNorm = $blockNorm -replace "`n", "`r`n" }

    $dStartCount = ([regex]::Matches($original, [regex]::Escape($startMarker))).Count
    $dEndCount = ([regex]::Matches($original, [regex]::Escape($endMarker))).Count
    $newText = $null

    if (($dStartCount -eq 1) -and ($dEndCount -eq 1)) {
        # Caso A: marcadores presentes y unicos -> reemplazar el tramo delimitado.
        $sIdx = $original.IndexOf($startMarker, [System.StringComparison]::Ordinal)
        $eIdx = $original.IndexOf($endMarker, [System.StringComparison]::Ordinal)
        if (($sIdx -lt 0) -or ($eIdx -lt 0) -or ($sIdx -ge $eIdx)) {
            Write-Warn "AGENTS.md: marcadores KIT-BLOCK corruptos en AGENTS.md: no se escribe (fail-closed)"
            return
        }
        $newText = $original.Substring(0, $sIdx) + $blockNorm + $original.Substring($eIdx + $endMarker.Length)
    } elseif (($dStartCount -eq 0) -and ($dEndCount -eq 0)) {
        # Caso B: seccion presente sin marcadores -> migrar y envolver.
        # Solo el prefijo del encabezado, sin el acento, para no depender de la
        # codificacion del archivo leido.
        $headerRx = [regex]'(?m)^##[ \t]+Arranque por defecto del arn'
        $headerMatch = $headerRx.Match($original)
        if ($headerMatch.Success) {
            $afterHeader = $headerMatch.Index + $headerMatch.Length
            $nextHeaderMatch = ([regex]'(?m)^##[ \t]').Match($original, $afterHeader)
            if ($nextHeaderMatch.Success) {
                # Hasta justo antes del siguiente '## ' + una linea en blanco.
                $newText = $original.Substring(0, $headerMatch.Index) + $blockNorm + $nl + $nl + $original.Substring($nextHeaderMatch.Index)
            } else {
                # Hasta EOF + salto de linea final.
                $newText = $original.Substring(0, $headerMatch.Index) + $blockNorm + $nl
            }
        } else {
            # Caso C: seccion ausente -> agregar una linea en blanco + el bloque al final.
            $trimmed = $original.TrimEnd("`r", "`n")
            $newText = $trimmed + $nl + $nl + $blockNorm + $nl
            Write-Warn "AGENTS.md: seccion ausente: bloque '$BlockId' agregado al final"
        }
    } else {
        # Caso D: START sin END, END sin START o duplicados -> fail-closed.
        Write-Warn "AGENTS.md: marcadores KIT-BLOCK corruptos en AGENTS.md: no se escribe (fail-closed)"
        return
    }

    if ($newText -ceq $original) {
        Write-OK "  [OK] AGENTS.md - sin cambios (bloque al dia)"
        return
    }

    # Backup junto al destino (patron ignorado por .gitignore: AGENTS.md.bak-*).
    $backupPath = "$Destination.bak-" + (Get-Date -Format 'yyyyMMddTHHmmss')
    try {
        Copy-Item -LiteralPath $Destination -Destination $backupPath -Force
    } catch {
        Write-Fail "AGENTS.md: no se pudo crear el backup ($_); no se escribe."
        return
    }

    try {
        $encoding = [System.Text.UTF8Encoding]::new($hadBom)
        [System.IO.File]::WriteAllText($Destination, $newText, $encoding)
        Write-OK "  [OK] AGENTS.md - bloque '$BlockId' actualizado (backup: $(Split-Path -Leaf $backupPath))"
    } catch {
        Copy-Item -LiteralPath $backupPath -Destination $Destination -Force
        Write-Fail "AGENTS.md: no se pudo escribir el bloque ($_); se restauro el backup."
    }
}

# =============================================================================
# Sync-TransversalKit: sincroniza el kit transversal desde el repo maestro.
# Copia SOLO los transversales. NUNCA toca Documentacion/<AppName>/.
# Seguridad: excluye .opencode/config.json y valida la URL fail-closed.
# =============================================================================
function Sync-TransversalKit {
    param(
        [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
        [string]$RootPath = "",
        [string]$OrphanAction = "Preguntar",
        [string]$KitPath = ""
    )

    if (-not $RootPath) {
        $RootPath = (Split-Path -Parent $PSScriptRoot)
    }

    $orphanNorm = @{ "borrar" = "Borrar"; "conservar" = "Conservar"; "preguntar" = "Preguntar" }
    $orphanKey = "$OrphanAction".Trim().ToLowerInvariant()
    if ($orphanNorm.ContainsKey($orphanKey)) { $OrphanAction = $orphanNorm[$orphanKey] } else {
        if ($OrphanAction) { Write-Warn "Sync-TransversalKit: -OrphanAction '$OrphanAction' no valido (Borrar|Conservar|Preguntar). Se usa 'Preguntar'." }
        $OrphanAction = "Preguntar"
    }

    # Fail-closed: solo https://github.com/ (rechaza http://, git://, ssh, otras hosts).
    if ($RepoUrl -notlike "https://github.com/*") {
        throw "[SECURITY] URL no permitida (fail-closed): $RepoUrl (solo https://github.com/)"
    }
    if (-not (Test-TrustedGithubUrl $RepoUrl)) {
        throw "[SECURITY] Repo maestro no permitido (fail-closed): $RepoUrl (solo https://github.com/<owner en allowlist>/<repo>)"
    }

    Write-Step "Sincronizando kit transversal desde $RepoUrl..."

    # Lista blanca de transversales. Documentacion/<AppName>/ NO figura aqui por diseno.
    $transversalDirs = @(".github/", ".opencode/", ".doc_agents/", "scripts/")
    $transversalFiles = @(
        ".specify/memory/constitution.md",
        "AGENTS.md",
        "opencode.json",
        "README.md",
        "sync-agents.ps1",
        "upgrade_framework.ps1"
    )

    if ($DryRun) {
        if ($KitPath) {
            Write-Info "DryRun: fuente LOCAL del kit: $KitPath (sin clonar GitHub; incluye rama y cambios locales sin pushear)"
        } else {
            Write-Info "DryRun: clonaria shallow `"$RepoUrl`" en `$env:TEMP\agents-sync-temp"
        }
        foreach ($d in $transversalDirs) {
            Write-Info "DryRun: copiaria $d -> $(Join-Path $RootPath $d)"
        }
        foreach ($f in $transversalFiles) {
            Write-Info "DryRun: copiaria $f -> $(Join-Path $RootPath $f)"
        }
        Write-Info "DryRun: excluiria .opencode/config.json (posibles credenciales, nunca se copia)"
        Write-Info "DryRun: hash-guard .opencode/.gitignore: si el local existe y difiere del maestro se CONSERVA el local (fail-closed); solo -Force sobrescribe"
        Write-Info "DryRun: NUNCA tocaria Documentacion/<AppName>/ (frontera kit <-> app)"
        Write-Info "DryRun: copiaria la whitelist de tests del kit: tests/harness-default.ps1, tests/kit-sync-merge.ps1, tests/agents-parity.ps1, tests/kb-parity.ps1, tests/mcp-refresh-parity.ps1"
        Write-Info "DryRun: NO trataria tests/ como directorio transversal (los tests propios de la app no se tocan)"
        Write-Info "DryRun: detectaria huerfanos y aplicaria -OrphanAction $OrphanAction"
        return
    }

    $tempDir = Join-Path $env:TEMP "agents-sync-temp"
    $ownsTemp = $false
    try {
        if ($KitPath) {
            # [002-KITPATH] Fuente local del kit: el checkout local manda (rama +
            # cambios sin pushear incluidos). Fail-closed: solo directorios
            # locales con marcadores de kit; jamas URLs ni el propio destino.
            if ($KitPath -match '^[a-zA-Z][a-zA-Z0-9+.-]*://' -or $KitPath.StartsWith('git@')) {
                throw "[SECURITY] -KitPath no acepta URLs ni esquemas remotos (fail-closed): $KitPath (usa una ruta local, ej. C:\Proyectos\Agents_IA_TECH)"
            }
            try { $kitCanon = [IO.Path]::GetFullPath($KitPath) } catch { throw "sync-kit: -KitPath invalido ($KitPath): $_" }
            if (-not (Test-Path -LiteralPath $kitCanon -PathType Container)) {
                throw "sync-kit: -KitPath no existe o no es un directorio: $kitCanon"
            }
            $missing = @()
            foreach ($m in @("scripts", ".github", ".opencode", ".doc_agents", "AGENTS.md")) {
                if (-not (Test-Path -LiteralPath (Join-Path $kitCanon $m))) { $missing += $m }
            }
            if ($missing.Count -gt 0) {
                throw "sync-kit: -KitPath no parece un checkout del kit (faltan: $($missing -join ', ') en $kitCanon)"
            }
            try { $rootCanon = [IO.Path]::GetFullPath($RootPath) } catch { throw "sync-kit: -RootPath invalido ($RootPath): $_" }
            $sep = [IO.Path]::DirectorySeparatorChar
            if ($kitCanon.TrimEnd($sep) -eq $rootCanon.TrimEnd($sep)) {
                Write-Warn "sync-kit: -KitPath es el propio proyecto destino; no hay nada que sincronizar (se omite)."
                return
            }
            $tempDir = $kitCanon
            $commitHash = "local-kit"
            try {
                $kitBranch = (git -C $kitCanon rev-parse --abbrev-ref HEAD 2>$null)
                $kitShort = (git -C $kitCanon rev-parse --short HEAD 2>$null)
                if ($kitBranch -and $kitShort) { $commitHash = "local-kit ($kitBranch@$kitShort)" }
            } catch { }
            Write-Info "Fuente LOCAL del kit: $kitCanon [$commitHash] (rama y cambios locales incluidos, sin pasar por GitHub)"
        } else {
            if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

            Write-Host "  Clonando repo maestro..." -NoNewline
            git clone --depth 1 $RepoUrl $tempDir 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host " ERROR" -ForegroundColor Red
                throw "No se pudo clonar el repo maestro $RepoUrl (verifica git y URL)."
            }
            Write-Host " OK" -ForegroundColor Green
            $ownsTemp = $true

            $commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
            $commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
            Write-Info "Version repo maestro: $commitHash ($commitDate)"
        }

        $transversalItems = @(
            @{ Source = (Join-Path $tempDir ".github");                    Target = (Join-Path $RootPath ".github");                    Type = "Dir";  Label = ".github/" },
            @{ Source = (Join-Path $tempDir ".opencode");                  Target = (Join-Path $RootPath ".opencode");                  Type = "Dir";  Label = ".opencode/" },
            @{ Source = (Join-Path $tempDir ".doc_agents");                Target = (Join-Path $RootPath ".doc_agents");                Type = "Dir";  Label = ".doc_agents/" },
            @{ Source = (Join-Path $tempDir "scripts");                    Target = (Join-Path $RootPath "scripts");                    Type = "Dir";  Label = "scripts/" },
            @{ Source = (Join-Path $tempDir ".specify/memory/constitution.md"); Target = (Join-Path $RootPath ".specify/memory/constitution.md"); Type = "File"; Label = ".specify/memory/constitution.md (base)" },
            @{ Source = (Join-Path $tempDir "AGENTS.md");                  Target = (Join-Path $RootPath "AGENTS.md");                  Type = "File"; Label = "AGENTS.md" },
            @{ Source = (Join-Path $tempDir "opencode.json");              Target = (Join-Path $RootPath "opencode.json");              Type = "File"; Label = "opencode.json" },
            @{ Source = (Join-Path $tempDir "README.md");                  Target = (Join-Path $RootPath "README.md");                  Type = "File"; Label = "README.md" },
            @{ Source = (Join-Path $tempDir "sync-agents.ps1");            Target = (Join-Path $RootPath "sync-agents.ps1");            Type = "File"; Label = "sync-agents.ps1" },
            @{ Source = (Join-Path $tempDir "upgrade_framework.ps1");      Target = (Join-Path $RootPath "upgrade_framework.ps1");      Type = "File"; Label = "upgrade_framework.ps1" }
        )

        foreach ($item in $transversalItems) {
            $src = $item.Source
            $dst = $item.Target
            $dstDir = if ($item.Type -eq "File") { Split-Path $dst -Parent } else { $dst }
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

            if ($item.Type -eq "Dir") {
                Write-Host "  [SYNC] $($item.Label)" -ForegroundColor Cyan
                if ($item.Label -eq ".opencode/") {
                    # hash-guard .opencode/.gitignore: si el local difiere del maestro -> conservar local.
                    $masterGi = Join-Path $src ".gitignore"
                    $localGi = Join-Path $dst ".gitignore"
                    $giGuardHold = $false
                    if ((Test-Path -LiteralPath $masterGi -PathType Leaf) -and (Test-Path -LiteralPath $localGi -PathType Leaf) -and (-not $Force)) {
                        try {
                            $mh = (Get-FileHash -LiteralPath $masterGi -Algorithm SHA256 -ErrorAction Stop).Hash
                            $lh = (Get-FileHash -LiteralPath $localGi -Algorithm SHA256 -ErrorAction Stop).Hash
                            if ($mh -ne $lh) {
                                Write-Warn "  [GUARD] .opencode/.gitignore local difiere del maestro: se CONSERVA el local (fail-closed). Usa -Force para sobrescribir."
                                $giGuardHold = $true
                            }
                        } catch {
                            Write-Warn "  [GUARD] No se pudo comparar .opencode/.gitignore (hash fallo): se conserva el local por seguridad."
                            $giGuardHold = $true
                        }
                    }
                    # Seguridad: nunca copiar .opencode/config.json (posibles credenciales).
                    if ($giGuardHold) {
                        robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" ".gitignore" >$null 2>&1
                    } else {
                        robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" >$null 2>&1
                    }
                    # Verificar que .opencode/.gitignore existe tras el sync; si falta -> restaurar desde el maestro.
                    if (-not (Test-Path -LiteralPath $localGi -PathType Leaf)) {
                        if (Test-Path -LiteralPath $masterGi -PathType Leaf) {
                            Write-Warn "  [GUARD] .opencode/.gitignore ausente tras sync: se restaura desde el maestro."
                            Copy-Item -LiteralPath $masterGi -Destination $localGi -Force
                        } else {
                            Write-Warn "  [GUARD] .opencode/.gitignore ausente en local y en maestro: proteccion de secrets degradada; no hacer commit de config.json."
                        }
                    } else {
                        try {
                            $giTextAfter = Get-Content -LiteralPath $localGi -Raw -ErrorAction Stop
                            if ($giTextAfter -notmatch '(?m)^config\.json\s*$') {
                                Write-Warn "  [GUARD] .opencode/.gitignore local SIN linea 'config.json': proteccion de secrets degradada; revisalo antes de commitear."
                            }
                        } catch { }
                    }
                    # Baseline lib/bin: si aparecen contenidos -> WARN supply-chain.
                    foreach ($ab in @("lib", "bin")) {
                        $abFull = Join-Path $dst $ab
                        try {
                            if (Test-Path -LiteralPath $abFull) {
                                $abFiles = @(Get-ChildItem -LiteralPath $abFull -Recurse -File -Force -ErrorAction Stop)
                                if ($abFiles.Count -gt 0) {
                                    Write-Warn "  [GUARD] .opencode/$ab con $($abFiles.Count) archivo(s): tratar como NO confiable hasta pin+hash en manifest (supply-chain); no ejecutar sin verificar."
                                }
                            }
                        } catch { }
                    }
                } else {
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XD "context-mode" >$null 2>&1
                }
            } else {
                # 034: archivos de raiz con politica de merge (no SKIP). Se
                # resuelven antes de la regla SKIP para que apliquen con y sin -Force.
                if ($item.Label -eq "opencode.json") {
                    Write-Host "  [MERGE] opencode.json (merge por claves)" -ForegroundColor Cyan
                    Merge-OpenCodeConfig -Source $src -Destination $dst -ProjectRoot $RootPath -Force:$Force
                    continue
                }
                if ($item.Label -eq "AGENTS.md") {
                    Write-Host "  [MERGE] AGENTS.md (bloque delimitado)" -ForegroundColor Cyan
                    Merge-KitBlock -Source $src -Destination $dst
                    continue
                }
                if ((Test-Path $dst) -and (-not $Force)) {
                    $comparison = Compare-KitFileState -Source $src -Destination $dst
                    if ($comparison -eq 'Equal') {
                        Write-OK "  [OK] $($item.Label) - contenido identico"
                    } elseif ($comparison -eq 'EolOnly') {
                        Write-Info "  [INFO] $($item.Label) - solo difiere el fin de linea"
                    } else {
                        Write-Warn "  [SKIP] $($item.Label) - contenido distinto; usa -Force para sobrescribir"
                    }
                    continue
                }
                Write-Host "  [FILE] $($item.Label)" -ForegroundColor Cyan
                Copy-Item $src -Destination $dst -Force
            }
        }

        # 034 / T18: tests/ es de las apps, NO es un directorio transversal. Solo
        # viaja esta whitelist, copiada por nombre exacto (una app puede tener sus
        # propios tests/ y no se tocan). Si el archivo no esta en el maestro -> INFO,
        # nunca se crea vacio.
        $kitTestWhitelist = @(
            "tests/harness-default.ps1",
            "tests/kit-sync-merge.ps1",
            "tests/agents-parity.ps1",
            "tests/kb-parity.ps1",
            "tests/mcp-refresh-parity.ps1"
        )
        $testsDir = Join-Path $RootPath "tests"
        foreach ($rel in $kitTestWhitelist) {
            $testSrc = Join-Path $tempDir $rel
            if (Test-Path -LiteralPath $testSrc -PathType Leaf) {
                if (-not (Test-Path -LiteralPath $testsDir)) {
                    New-Item -ItemType Directory -Path $testsDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $testSrc -Destination (Join-Path $RootPath $rel) -Force
                Write-Host "  [SYNC] $rel" -ForegroundColor Cyan
            } else {
                Write-Info "  [INFO] $rel no esta en el maestro; se omite"
            }
        }

        # Seguridad: confirmar que .opencode/config.json del kit NO se copio.
        $kitConfig = Join-Path $tempDir ".opencode\config.json"
        if (Test-Path $kitConfig) {
            Write-Warn "Se excluye .opencode/config.json (posibles credenciales) de la sincronizacion."
        }

        # Deteccion defensiva config.json trackeado.
        try {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                $trackedCfg = & git -C $RootPath ls-files -- ".opencode/config.json" 2>$null
                if ($trackedCfg) {
                    Write-Warn ".opencode/config.json esta TRACKEADO por git (posibles secrets versionados): ejecuta git rm --cached .opencode/config.json y ROTA las keys."
                }
            }
        } catch { }

        # Manejo de huerfanos (dentro del try: $tempDir sigue disponible).
        $orphans = @(Find-OrphanKitFiles -RootPath $RootPath -TempDir $tempDir)
        Invoke-OrphanDecision -Orphans $orphans -RootPath $RootPath -OrphanAction $OrphanAction

        Write-OK "Kit transversal sincronizado (commit $commitHash). Documentacion/<AppName>/ NO fue tocada."
    }
    catch { Write-Warn "Error en Sync-TransversalKit: $_" }
    finally {
        # [002-KITPATH] Solo se borra el clon temporal propio; la fuente local
        # del kit (-KitPath) jamas se toca.
        if ($ownsTemp -and (Test-Path $tempDir)) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# =============================================================================
# Punto de entrada
# =============================================================================
$resolvedRoot = if ($RootPath) { $RootPath } else { (Split-Path -Parent $PSScriptRoot) }

Write-Step "sync-kit: sincronizando kit transversal en $resolvedRoot"
Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction -KitPath $KitPath
Show-ExecutionSummary
