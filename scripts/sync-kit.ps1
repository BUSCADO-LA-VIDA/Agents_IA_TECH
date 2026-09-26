#!/usr/bin/env powershell
#requires -Version 7.0
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
    [switch]$Force
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
# Sync-TransversalKit: sincroniza el kit transversal desde el repo maestro.
# Copia SOLO los transversales. NUNCA toca Documentacion/<AppName>/.
# Seguridad: excluye .opencode/config.json y valida la URL fail-closed.
# =============================================================================
function Sync-TransversalKit {
    param(
        [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
        [string]$RootPath = "",
        [string]$OrphanAction = "Preguntar"
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
        Write-Info "DryRun: clonaria shallow `"$RepoUrl`" en `$env:TEMP\agents-sync-temp"
        foreach ($d in $transversalDirs) {
            Write-Info "DryRun: copiaria $d -> $(Join-Path $RootPath $d)"
        }
        foreach ($f in $transversalFiles) {
            Write-Info "DryRun: copiaria $f -> $(Join-Path $RootPath $f)"
        }
        Write-Info "DryRun: excluiria .opencode/config.json (posibles credenciales, nunca se copia)"
        Write-Info "DryRun: hash-guard .opencode/.gitignore: si el local existe y difiere del maestro se CONSERVA el local (fail-closed); solo -Force sobrescribe"
        Write-Info "DryRun: NUNCA tocaria Documentacion/<AppName>/ (frontera kit <-> app)"
        Write-Info "DryRun: detectaria huerfanos y aplicaria -OrphanAction $OrphanAction"
        return
    }

    $tempDir = Join-Path $env:TEMP "agents-sync-temp"
    try {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

        Write-Host "  Clonando repo maestro..." -NoNewline
        git clone --depth 1 $RepoUrl $tempDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host " ERROR" -ForegroundColor Red
            throw "No se pudo clonar el repo maestro $RepoUrl (verifica git y URL)."
        }
        Write-Host " OK" -ForegroundColor Green

        $commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
        $commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
        Write-Info "Version repo maestro: $commitHash ($commitDate)"

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
                if ((Test-Path $dst) -and (-not $Force)) {
                    $srcHash = (Get-FileHash $src).Hash
                    $dstHash = (Get-FileHash $dst).Hash
                    if ($srcHash -eq $dstHash) {
                        Write-OK "  [OK] $($item.Label) - sin cambios"
                    } else {
                        Write-Warn "  [SKIP] $($item.Label) - existe y difiere; usa -Force para sobrescribir (se conserva local)"
                    }
                    continue
                }
                Write-Host "  [FILE] $($item.Label)" -ForegroundColor Cyan
                # Guard del sync sobre opencode.json: preservar el bloque `mcp` resuelto localmente.
                if ($item.Label -eq "opencode.json" -and (Test-Path -LiteralPath $dst)) {
                    $merged = $false
                    try {
                        $srcJson = Get-Content -LiteralPath $src -Raw -ErrorAction Stop | ConvertFrom-Json
                        $dstJson = Get-Content -LiteralPath $dst -Raw -ErrorAction Stop | ConvertFrom-Json
                        if (($null -ne $dstJson.mcp) -and ($null -ne $srcJson)) {
                            if ($srcJson.PSObject.Properties["mcp"]) {
                                $srcJson.PSObject.Properties.Remove("mcp")
                            }
                            $srcJson | Add-Member -NotePropertyName "mcp" -NotePropertyValue $dstJson.mcp -Force
                            $srcJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $dst -Encoding UTF8
                            Write-OK "  [GUARD] opencode.json: bloque mcp local PRESERVADO (merge con la plantilla del maestro)."
                            $merged = $true
                        }
                    } catch {
                        Write-Warn "  [GUARD] opencode.json: no se pudo mergear el bloque mcp local ($_); se conserva el local sin sobrescribir."
                        $merged = $true
                    }
                    if ($merged) { continue }
                }
                Copy-Item $src -Destination $dst -Force
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
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# =============================================================================
# Punto de entrada
# =============================================================================
$resolvedRoot = if ($RootPath) { $RootPath } else { (Split-Path -Parent $PSScriptRoot) }

Write-Step "sync-kit: sincronizando kit transversal en $resolvedRoot"
Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction
Show-ExecutionSummary
