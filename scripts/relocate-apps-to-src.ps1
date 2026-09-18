#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# relocate-apps-to-src.ps1
# =============================================================================
# Script standalone de reubicacion de apps a `src\<App>` (RF-13, criterio 9).
# Mueve carpetas de app desde la raiz del proyecto a `src\<App>` con:
#   - confirmacion SIEMPRE obligatoria (sin flag de bypass, por diseno)
#   - pre-chequeos fail-closed por app (origen existe, destino libre,
#     nombres simples, denylist dura, containment-check, symlinks)
#   - transaccion por app + verificacion post-movido + log OK/ABORTADO
#   - `.venv` movido con la app pero REPORTADO "a recrear" (nunca recreado solo)
#   - RF-14 (criterio 10): `Suspend-AppLocks` (desactiva venv + pausa git.exe
#     puntuales con confirmacion, nunca Code) + `Restore-AppLocks` (recrea
#     y reactiva `src\<App>\.venv` si se movio; cada accion pregunta, sin bypass)
#   - RF-15 (criterio 11): `Find-RegenerableDirs` (allowlist exacta, UN nivel,
#     gate git-trackeado) + `Clear-RegenerableDirs` (elimina con log, sin
#     respaldo) + pregunta global S/N (default No) ANTES del S/N/T/C por app;
#     `.venv` se ELIMINA por comando (no se mueve) con confirmacion separada
#     + `deactivate` previo verificado + `pip freeze` de rescate si no hay
#     manifiesto; DryRun/no-interactivo no borra; logs solo rutas relativas
#   - nunca toca `Documentacion/` (ni siquiera la enumera como candidata)
#
# Uso:
#   .\scripts\relocate-apps-to-src.ps1 -AppDirs @("trading_bot", "Telegram") -DryRun
#   .\scripts\relocate-apps-to-src.ps1 -AppDirs @("trading_bot")            # modo real interactivo
#   .\scripts\relocate-apps-to-src.ps1 -AppDirs @("mi_app") -ProjectRoot "C:\otro\proyecto"
#
# Requisito: PowerShell 7+ (pwsh >= 7). No funciona en Windows PowerShell 5.1.
#   Recomendacion (solo texto, ejecutar manualmente si aplica):
#     winget install --id Microsoft.PowerShell --source winget
#
# Referencias:
#   Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md (RF-13, criterio 9; RF-15, criterio 11)
#   Documentacion/Agents_IA_TECH/seguridad/relocate.md (condiciones innegociables)
#   Documentacion/Agents_IA_TECH/seguridad/relocate-locks.md (RF-14: revalidacion pre-kill + allowlist git.exe + denylist Code)
#   Documentacion/Agents_IA_TECH/seguridad/relocate-cleanup.md (RF-15: nombres exactos + gate git + deactivate + freeze + S/N global)
#   Documentacion/Agents_IA_TECH/pendientes-implementacion.md (tarea [RELOCATE])
# =============================================================================

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string[]]$AppDirs = @(),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

# =============================================================================
# Denylist dura (seguridad/relocate.md S1.7): nunca aceptar como -AppDirs.
# Comparacion case-insensitive (operador -contains). `proyect_ext` cubre
# `proyect_ext/spec-kit` porque solo se aceptan nombres simples (S1.8).
# =============================================================================
$DeniedAppNames = @(
    "Documentacion", ".specify", "src", "scripts", "proyect_ext",
    ".github", ".opencode", ".doc_agents", ".git", ".venv"
)

function Get-RelativeLogPath {
    param([string]$RootPath, [string]$FullPath)
    $rootFull = [System.IO.Path]::GetFullPath($RootPath)
    $targetFull = [System.IO.Path]::GetFullPath($FullPath)
    if ($targetFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $targetFull.Substring($rootFull.Length).TrimStart('\', '/')
        if ($rel -eq "") { return "." }
        return $rel
    }
    return "[fuera-del-proyecto]"
}

function Test-IsInteractive {
    if ($env:CI) { return $false }
    try {
        if ([System.Console]::IsInputRedirected) { return $false }
        $null = $Host.UI.RawUI
        return $true
    }
    catch {
        return $false
    }
}

function Test-SimpleAppName {
    param([string]$AppName)
    if ([string]::IsNullOrWhiteSpace($AppName)) { return $false }
    if ($AppName -eq ".") { return $false }
    if ($AppName -match '[\\/]') { return $false }
    if ($AppName -match '\.\.') { return $false }
    if ($AppName -match ':') { return $false }
    try {
        if ([System.IO.Path]::IsPathRooted($AppName)) { return $false }
    }
    catch {
        return $false
    }
    return $true
}

function Get-AppSizeInfo {
    param([string]$LiteralDir)
    $files = Get-ChildItem -LiteralPath $LiteralDir -Recurse -File -Force -ErrorAction SilentlyContinue
    $count = @($files).Count
    $bytes = 0
    foreach ($f in $files) { $bytes += $f.Length }
    return [PSCustomObject]@{
        FileCount = $count
        Bytes     = $bytes
        MB        = [Math]::Round($bytes / 1MB, 2)
    }
}

function Get-GitDirtyHint {
    param([string]$RootPath)
    try {
        $out = git -C $RootPath status --porcelain 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        if ($out) { return $true }
        return $false
    }
    catch {
        return $null
    }
}

# =============================================================================
# Test-ActiveVenv: detecta si hay un .venv ACTIVADO en esta terminal.
# Lee $env:VIRTUAL_ENV (lo setea Activate.ps1 de venv/virtualenv) y, como
# informativo, $env:CONDA_PREFIX (conda). Sin venv activo retorna $null en
# silencio (sin ruido). Con venv activo resuelve si esta dentro de alguna
# app candidata <root>\<App>\ (prefijo canonico, case-insensitive) o dentro
# del proyecto en general. Solo avisa: nunca aborta (el usuario decide).
# Devuelve hashtable @{ Active=$true; Path=...; InApp="<App o ''>";
# InProject=$true/$false; IsConda=$true/$false } o $null.
# =============================================================================
function Test-ActiveVenv {
    param(
        [string]$ProjectRoot = "",
        [string[]]$AppDirs = @()
    )

    $venvPath = $env:VIRTUAL_ENV
    $isConda = $false
    if ([string]::IsNullOrWhiteSpace($venvPath)) {
        if (-not [string]::IsNullOrWhiteSpace($env:CONDA_PREFIX)) {
            $venvPath = $env:CONDA_PREFIX
            $isConda = $true
        }
    }
    if ([string]::IsNullOrWhiteSpace($venvPath)) { return $null }

    try {
        $venvFull = [System.IO.Path]::GetFullPath($venvPath)
    }
    catch {
        $venvFull = $venvPath
    }

    $rootFull = ""
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        }
        catch {
            $rootFull = ""
        }
    }

    $inApp = ""
    $inProject = $false
    if ($rootFull -ne "") {
        $sep = [System.IO.Path]::DirectorySeparatorChar
        $rootPrefix = $rootFull.TrimEnd('\', '/') + $sep
        if ($venvFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or `
            $venvFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $inProject = $true
        }
        foreach ($app in $AppDirs) {
            if ([string]::IsNullOrWhiteSpace($app)) { continue }
            try {
                $appFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $app))
            }
            catch {
                continue
            }
            $appPrefix = $appFull.TrimEnd('\', '/') + $sep
            if ($venvFull.Equals($appFull, [System.StringComparison]::OrdinalIgnoreCase) -or `
                $venvFull.StartsWith($appPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $inApp = $app
                $inProject = $true
                break
            }
        }
    }

    return @{
        Active    = $true
        Path      = $venvPath
        InApp     = $inApp
        InProject = $inProject
        IsConda   = $isConda
    }
}

# =============================================================================
# Confirm-AppRelocation (RF-13): confirmacion SIEMPRE obligatoria, sin bypass.
# Pregunta [S]i / [N]o / [T]odos restantes / [C]ancelar todo.
# Devuelve: 'S' | 'N' | 'T' | 'C'.
# Sin consola interactiva -> devuelve 'N' + Write-Warn (nunca mueve sin humano).
# En -DryRun el MAIN no la invoca (solo previsualiza).
# =============================================================================
function Confirm-AppRelocation {
    param(
        [string]$AppName,
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-IsInteractive)) {
        Write-Warn "Sin consola interactiva: NO se mueve '$AppName' (fail-closed, criterio 9). Se requiere humano."
        return 'N'
    }

    Write-Host ""
    Write-Step "Confirmar reubicacion de '$AppName'"
    Write-Info "Origen : $Source"
    Write-Info "Destino: $Destination"
    $answer = Read-Host "Mover esta app? [S]i mover / [N]o dejar / [T]odos los restantes / [C]ancelar todo"
    switch -Regex ($answer.Trim().ToLowerInvariant()) {
        '^(s|si|sí|y|yes)$' { return 'S' }
        '^(t|todos|all)$'   { return 'T' }
        '^(c|cancelar|cancel)$' { return 'C' }
        default             { return 'N' }
    }
}

# =============================================================================
# Move-AppToSrc (RF-13): mueve UNA app de <root>\<App> a <root>\src\<App>.
# Pre-chequeos fail-closed, transaccion por app, verificacion post-movido,
# log OK/ABORTADO, `.venv` reportado "a recrear". En -DryRun solo informa.
# Usa el $DryRun del script (mismo patron que Ensure-Directory del bootstrap).
# Devuelve PSCustomObject: AppName, Status (OK|OMITIDA|ABORTADA|SIMULADA),
# SourceRel, DestRel, FileCount, SizeMB, NeedsVenvRecreate, Detail, Rollback.
# =============================================================================
function Move-AppToSrc {
    param(
        [string]$AppName,
        [string]$ProjectRoot
    )

    $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
    $srcDirFull = [System.IO.Path]::Combine($rootFull, "src")
    $nowIso = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $newResult = {
        param($Status, $SourceRel, $DestRel, $Count, $MB, $Venv, $Detail, $Rollback)
        return [PSCustomObject]@{
            AppName            = $AppName
            Status             = $Status
            SourceRel          = $SourceRel
            DestRel            = $DestRel
            FileCount          = $Count
            SizeMB             = $MB
            NeedsVenvRecreate  = $Venv
            Detail             = $Detail
            Rollback           = $Rollback
            Timestamp          = $nowIso
        }
    }

    # --- Nombres simples + denylist dura (S1.7, S1.8) ---
    if (-not (Test-SimpleAppName $AppName)) {
        Write-Warn "OMITIDA '$AppName': solo se aceptan nombres simples (sin '\', '/', '..', ':' ni rutas absolutas)."
        return (& $newResult "OMITIDA" $AppName "src\$AppName" 0 0 $false "nombre-no-simple" "")
    }
    if ($DeniedAppNames -contains $AppName) {
        Write-Warn "OMITIDA '$AppName': esta en la denylist (nunca se mueve: Documentacion/.specify/src/scripts/proyect_ext/.github/.opencode/.doc_agents/.git/.venv)."
        return (& $newResult "OMITIDA" $AppName "src\$AppName" 0 0 $false "denylist" "")
    }

    # --- Rutas canonicas + containment-check (S1.8, fail-closed) ---
    $sourceFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $AppName))
    $destFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($srcDirFull, $AppName))
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $insideRoot = $sourceFull.StartsWith($rootFull + $sep, [System.StringComparison]::OrdinalIgnoreCase)
    $insideSrc = $destFull.StartsWith($srcDirFull + $sep, [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $insideRoot -or -not $insideSrc) {
        Write-Warn "OMITIDA '$AppName': containment-check fallo (origen fuera del proyecto o destino fuera de src\)."
        return (& $newResult "OMITIDA" $AppName "src\$AppName" 0 0 $false "containment-check" "")
    }
    $sourceRel = Get-RelativeLogPath $rootFull $sourceFull
    $destRel = Get-RelativeLogPath $rootFull $destFull

    # --- Pre-chequeo: origen existe y es directorio real ---
    if (-not (Test-Path -LiteralPath $sourceFull -PathType Container)) {
        Write-Warn "OMITIDA '$AppName': origen '$sourceRel' no existe o no es directorio (SKIP)."
        return (& $newResult "OMITIDA" $sourceRel $destRel 0 0 $false "origen-inexistente" "")
    }

    # --- Symlinks/junctions: no se siguen (S1.8) ---
    try {
        $attrs = (Get-Item -LiteralPath $sourceFull -Force).Attributes
        if (($attrs -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            Write-Warn "OMITIDA '$AppName': el origen es symlink/junction; no se sigue (resolucion manual primero)."
            return (& $newResult "OMITIDA" $sourceRel $destRel 0 0 $false "symlink" "")
        }
    }
    catch {
        Write-Warn "OMITIDA '$AppName': no se pudo inspeccionar el origen ($($_.Exception.Message))."
        return (& $newResult "OMITIDA" $sourceRel $destRel 0 0 $false "origen-no-inspeccionable" "")
    }

    # --- Pre-chequeo: destino libre, nunca sobrescribir/fusionar (S1.3) ---
    if (Test-Path -LiteralPath $destFull) {
        Write-Warn "OMITIDA '$AppName': destino '$destRel' ya existe; nunca se fusiona/sobrescribe (resolucion manual primero)."
        return (& $newResult "OMITIDA" $sourceRel $destRel 0 0 $false "destino-ocupado" "")
    }

    # --- Tamano informado + deteccion .venv (se mueve con la app, a recrear) ---
    $size = Get-AppSizeInfo -LiteralDir $sourceFull
    $venvDir = Join-Path $sourceFull ".venv"
    $needsVenv = Test-Path -LiteralPath $venvDir -PathType Container

    # --- Aviso .venv en uso (S1.2): procesos Python corriendo ---
    $pyProcs = Get-Process -Name "python", "pythonw" -ErrorAction SilentlyContinue
    if ($pyProcs -and $needsVenv) {
        Write-Warn "'$AppName' tiene .venv y hay proceso(s) Python corriendo: cierra servidores/jobs/terminales con el venv activado antes del modo real (movido parcial si hay locks)."
    }

    # --- -DryRun: solo informa, cero escrituras ---
    if ($DryRun) {
        $venvTxt = if ($needsVenv) { "Si (a recrear)" } else { "No" }
        Write-Info "DryRun: moveria '$sourceRel' -> '$destRel' ($($size.FileCount) archivos, $($size.MB) MB, .venv: $venvTxt, $nowIso). Sin cambios."
        return (& $newResult "SIMULADA" $sourceRel $destRel $size.FileCount $size.MB $needsVenv "dry-run" "")
    }

    # --- Transaccion por app: crear src\ si falta -> mover -> verificar ---
    if (-not (Test-Path -LiteralPath $srcDirFull -PathType Container)) {
        New-Item -ItemType Directory -Path $srcDirFull -Force | Out-Null
        Write-OK "Directorio listo: src"
    }

    $rollbackCmd = "Move-Item -LiteralPath `"$destRel`" -Destination `".\$AppName`"  # ejecutar desde la raiz del proyecto"
    try {
        Move-Item -LiteralPath $sourceFull -Destination $destFull
    }
    catch {
        $msg = $_.Exception.Message
        Write-Fail "ABORTADA '$AppName': Move-Item fallo ($msg)."
        Write-Warn "Si el .venv estaba en uso (archivos bloqueados): cierra procesos Python y reintenta."
        try {
            if ((Test-Path -LiteralPath $destFull) -and (-not (Test-Path -LiteralPath $sourceFull))) {
                Move-Item -LiteralPath $destFull -Destination $sourceFull -ErrorAction Stop
                Write-Warn "Revertido lo movido de '$AppName' al origen (rollback automatico parcial)."
            }
        }
        catch {
            Write-Fail "No se pudo revertir '$AppName' automaticamente; estado posiblemente mixto: revisa '$sourceRel' y '$destRel' antes de reintentar."
        }
        return (& $newResult "ABORTADA" $sourceRel $destRel $size.FileCount $size.MB $needsVenv "move-item-fallo" $rollbackCmd)
    }

    # --- Verificacion post-movido (S1.3): destino existe + origen ausente + conteo coincide ---
    $after = Get-AppSizeInfo -LiteralDir $destFull
    $destExists = Test-Path -LiteralPath $destFull -PathType Container
    $sourceGone = -not (Test-Path -LiteralPath $sourceFull)
    if ($destExists -and $sourceGone -and ($after.FileCount -eq $size.FileCount)) {
        $venvTxt = if ($needsVenv) { "Si" } else { "No" }
        Write-OK "Movida '$AppName': $sourceRel -> $destRel | $nowIso | $($after.FileCount) archivos | .venv: $venvTxt"
        return (& $newResult "OK" $sourceRel $destRel $after.FileCount $after.MB $needsVenv "movido-verificado" $rollbackCmd)
    }

    Write-Fail "ABORTADA '$AppName': verificacion post-movido fallo (destino: $destExists, origen ausente: $sourceGone, archivos antes: $($size.FileCount), despues: $($after.FileCount))."
    try {
        if ((Test-Path -LiteralPath $destFull) -and (-not (Test-Path -LiteralPath $sourceFull))) {
            Move-Item -LiteralPath $destFull -Destination $sourceFull -ErrorAction Stop
            Write-Warn "Revertido lo movido de '$AppName' al origen (rollback automatico parcial)."
        }
    }
    catch {
        Write-Fail "No se pudo revertir '$AppName' automaticamente; estado INTERRUMPIDO: revisa '$sourceRel' y '$destRel' con el log antes de reintentar."
    }
    return (& $newResult "ABORTADA" $sourceRel $destRel $after.FileCount $after.MB $needsVenv "verificacion-fallo" $rollbackCmd)
}

# =============================================================================
# Get-AppGitLocks (RF-14): detecta `git.exe` con actividad dentro de las apps
# candidatas <root>\<App>\. Solo lectura vía CIM Win32_Process (nombre + Id +
# CreationDate + ExecutablePath + CommandLine). CIM no expone el cwd: se usa
# como proxy verificable que el CommandLine contenga la ruta canónica de la
# app, o que el ejecutable resida dentro de ella.
# Allowlist: solo `git.exe`. Denylist dura (defensa en profundidad aunque el
# filtro CIM ya pida `git.exe`): jamás `Code`/`Code - Insiders`, `pwsh`,
# `powershell` ni `python`. Sin candidatos en esas apps → @() (el llamante no
# pregunta lo inaplicable). Logs: solo PID + ruta relativa, nunca CommandLine
# completa (puede traer tokens).
# Devuelve array de PSCustomObject: Id, Name, StartTime, ExecutablePath,
# CommandLine, App, AppRel.
# =============================================================================
function Get-AppGitLocks {
    param(
        [string[]]$AppDirs = @(),
        [string]$ProjectRoot = ""
    )

    $found = @()
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { return $found }
    try {
        $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
    }
    catch {
        return $found
    }

    try {
        $procs = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'git.exe'" -ErrorAction Stop
    }
    catch {
        Write-Warn "No se pudo enumerar procesos git (CIM no disponible). Se informa sin pausar nada."
        return $found
    }

    $appMap = @{}
    foreach ($app in $AppDirs) {
        if ([string]::IsNullOrWhiteSpace($app)) { continue }
        if (-not (Test-SimpleAppName $app)) { continue }
        if ($DeniedAppNames -contains $app) { continue }
        try {
            $appMap[$app] = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $app))
        }
        catch { }
    }
    if ($appMap.Count -eq 0) { return $found }

    foreach ($p in @($procs)) {
        if ([string]$p.Name -ine "git.exe") { continue }
        $exePath = [string]$p.ExecutablePath
        if ($exePath -match '(?i)Code[^\\/]*\.exe$') { continue }
        if (($exePath -ne "") -and ($exePath -notmatch '(?i)git\.exe$')) { continue }
        $cmdLine = [string]$p.CommandLine
        $pidNum = 0
        try {
            $pidNum = [int]$p.ProcessId
        }
        catch {
            continue
        }
        $startTime = $null
        try {
            $startTime = [System.Management.ManagementDateTimeConverter]::ToDateTime([string]$p.CreationDate)
        }
        catch {
            $startTime = $null
        }

        foreach ($entry in $appMap.GetEnumerator()) {
            $appFull = $entry.Value
            $hit = $false
            if (($cmdLine -ne "") -and ($cmdLine.IndexOf($appFull, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)) {
                $hit = $true
            }
            if (-not $hit -and ($exePath -ne "")) {
                $sep = [System.IO.Path]::DirectorySeparatorChar
                $prefix = $appFull.TrimEnd('\', '/') + $sep
                if ($exePath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $hit = $true
                }
            }
            if ($hit) {
                $found += [PSCustomObject]@{
                    Id             = $pidNum
                    Name           = [string]$p.Name
                    StartTime      = $startTime
                    ExecutablePath = $exePath
                    CommandLine    = $cmdLine
                    App            = $entry.Key
                    AppRel         = (Get-RelativeLogPath $rootFull $appFull)
                }
                break
            }
        }
    }

    return $found
}

# =============================================================================
# Stop-VerifiedGitProcess (RF-14): pausa UN `git.exe` con revalidación
# atómica pre-kill (innegociable, criterio 10): en el momento del kill se
# reobtiene el proceso por Id y se exige ProcessName -eq 'git' + mismo Id +
# mismo StartTime (tolerancia 2 s por redondeo CIM/.NET) + mismo ejecutable
# git.exe + denylist Code. Cualquier diferencia → ABORTA ese kill
# (fail-closed, aviso). Kill suave: CloseMainWindow + Stop-Process SIN -Force
# + espera breve; si persiste → aviso (no se fuerza a ciegas).
# Devuelve $true si el proceso ya no existe tras la pausa, $false si no.
# =============================================================================
function Stop-VerifiedGitProcess {
    param(
        [int]$ProcessId,
        $ExpectedStartTime = $null,
        [string]$ExpectedExecutable = "",
        [string]$AppRel = ""
    )

    try {
        $live = Get-Process -Id $ProcessId -ErrorAction Stop
    }
    catch {
        Write-Warn "git.exe PID ${ProcessId} ya terminó solo. No se mata nada."
        return $false
    }

    if ($live.ProcessName -ine "git") {
        Write-Warn "ABORTADO kill PID ${ProcessId}: ya no es git.exe (ahora '$($live.ProcessName)', PID reutilizado). No se mata nada."
        return $false
    }

    if ($null -ne $ExpectedStartTime) {
        try {
            $gap = [Math]::Abs((($live.StartTime) - ([datetime]$ExpectedStartTime)).TotalSeconds)
            if ($gap -gt 2) {
                Write-Warn "ABORTADO kill PID ${ProcessId}: StartTime cambió (PID reutilizado). No se mata nada."
                return $false
            }
        }
        catch { }
    }

    $livePath = ""
    try {
        $livePath = [string]$live.Path
    }
    catch {
        $livePath = ""
    }
    if ($livePath -match '(?i)Code[^\\/]*\.exe$') {
        Write-Warn "ABORTADO kill PID ${ProcessId}: el ejecutable es del editor (denylist Code). No se mata nada."
        return $false
    }
    if (($livePath -ne "") -and ($livePath -notmatch '(?i)git\.exe$')) {
        Write-Warn "ABORTADO kill PID ${ProcessId}: el ejecutable ya no es git.exe. No se mata nada."
        return $false
    }
    if (($ExpectedExecutable -ne "") -and ($livePath -ne "") -and (-not $livePath.Equals($ExpectedExecutable, [System.StringComparison]::OrdinalIgnoreCase))) {
        Write-Warn "ABORTADO kill PID ${ProcessId}: el ejecutable cambió desde la detección. No se mata nada."
        return $false
    }

    try {
        try {
            $null = $live.CloseMainWindow()
        }
        catch { }
        if (-not $live.WaitForExit(2000)) {
            Stop-Process -Id $ProcessId -ErrorAction Stop
            $still = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
            if ($null -ne $still) {
                $null = $still.WaitForExit(3000)
            }
        }
    }
    catch {
        Write-Warn "No se pudo pausar git.exe PID ${ProcessId} ($($_.Exception.Message)). Se informa; mueve con locks bajo tu responsabilidad."
        return $false
    }

    if ($null -eq (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
        Write-OK "Pausado git.exe PID ${ProcessId} (app '$AppRel'). Git se redescubre solo tras el movido."
        return $true
    }

    Write-Warn "git.exe PID ${ProcessId} sigue vivo tras pausa suave (sin -Force por diseño). Se informa; mueve con locks bajo tu responsabilidad."
    return $false
}

# =============================================================================
# Suspend-AppLocks (RF-14, criterio 10): antes de mover, suspende locks por app.
# 1) venv: si $env:VIRTUAL_ENV está dentro de una app candidata → pregunta
#    "¿Desactivo el venv X antes de mover? [S]í/[N]o" → si S, guarda el estado
#    previo (ruta + app) y ejecuta `deactivate` (función de sesión; si no
#    existe como comando, aborta ESA acción con aviso, sin fallar).
#    Conda ($env:CONDA_PREFIX) → solo informativo, sin mutar. Venv ajeno al
#    lote → solo informativo, sin mutar.
# 2) git: por cada `git.exe` con actividad en apps candidatas (Get-AppGitLocks)
#    → pregunta "¿Pauso git.exe PID N? [S]í/[N]o" → si S, revalida y pausa
#    (Stop-VerifiedGitProcess). Jamás Code (denylist).
# Resumen previo agrupado antes del primer prompt (relocate-locks §1.5). Sin
# bypass: S/N por acción (+[T]odos intra-acción, +[C]ancela lo restante);
# -Force no aplica. No interactivo → no muta (avisa). -DryRun → informa, no
# muta (usa el $DryRun del script, como Move-AppToSrc). Mutar la sesión
# (deactivate) es comportamiento esperado y documentado.
# Devuelve hashtable @{ Venvs; Git; DryRun } para Restore-AppLocks.
# =============================================================================
function Suspend-AppLocks {
    param(
        [string[]]$AppDirs = @(),
        [string]$ProjectRoot = ""
    )

    $state = @{
        Venvs  = @()
        Git    = @()
        DryRun = [bool]$DryRun
    }

    $rootFull = ""
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        }
        catch {
            $rootFull = $ProjectRoot
        }
    }

    if ($DryRun) {
        if (-not [string]::IsNullOrWhiteSpace($env:VIRTUAL_ENV)) {
            Write-Info "DryRun: preguntaría '¿Desactivo el venv ... antes de mover? [S]í/[N]o' (cero mutación, no desactiva)."
        }
        else {
            Write-Info "DryRun: sin venv activo (VIRTUAL_ENV vacío); nada que desactivar."
        }
        $preview = @(Get-AppGitLocks -AppDirs $AppDirs -ProjectRoot $rootFull)
        if ($preview.Count -gt 0) {
            foreach ($c in $preview) {
                Write-Info "DryRun: preguntaría '¿Pauso git.exe PID $($c.Id) (app '$($c.App)')? [S]í/[N]o' (cero kills)."
            }
        }
        else {
            Write-Info "DryRun: sin git.exe con actividad en las apps candidatas; nada que pausar."
        }
        Write-Info "DryRun: en modo real esta fase muta la sesión del llamante (deactivate) por diseño; en DryRun NO se muta."
        return $state
    }

    if (-not (Test-IsInteractive)) {
        Write-Warn "Sin consola interactiva: Suspend-AppLocks NO muta nada (ni desactiva venv ni pausa git). Ejecuta en terminal interactiva o usa -DryRun."
        return $state
    }

    Write-Step "Resumen de locks a suspender (RF-14) — cada acción preguntará por separado:"
    if (-not [string]::IsNullOrWhiteSpace($env:VIRTUAL_ENV)) {
        Write-Info "  venv activo: $($env:VIRTUAL_ENV)"
    }
    else {
        Write-Info "  venv activo: (ninguno)"
    }
    $locksPreview = @(Get-AppGitLocks -AppDirs $AppDirs -ProjectRoot $rootFull)
    if ($locksPreview.Count -gt 0) {
        foreach ($c in $locksPreview) {
            Write-Info "  git.exe candidato: PID $($c.Id) en app '$($c.App)' ($($c.AppRel))"
        }
    }
    else {
        Write-Info "  git.exe en apps candidatas: (ninguno)"
    }

    $cancelRest = $false
    $venvApplyAll = $false

    # --- 1) venv activo dentro de apps a mover (solo $env:VIRTUAL_ENV) ---
    $venvPath = $env:VIRTUAL_ENV
    if ([string]::IsNullOrWhiteSpace($venvPath)) {
        if (-not [string]::IsNullOrWhiteSpace($env:CONDA_PREFIX)) {
            Write-Info "Conda activo ($($env:CONDA_PREFIX)): solo informativo, no se desactiva (RF-14 cubre venv)."
        }
    }
    else {
        try {
            $venvFull = [System.IO.Path]::GetFullPath($venvPath)
        }
        catch {
            $venvFull = $venvPath
        }
        foreach ($app in $AppDirs) {
            if ($cancelRest) {
                break
            }
            if ([string]::IsNullOrWhiteSpace($app)) { continue }
            if (-not (Test-SimpleAppName $app)) { continue }
            if ($DeniedAppNames -contains $app) { continue }
            try {
                $appFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $app))
            }
            catch {
                continue
            }
            $sep = [System.IO.Path]::DirectorySeparatorChar
            $prefix = $appFull.TrimEnd('\', '/') + $sep
            $inApp = $venvFull.Equals($appFull, [System.StringComparison]::OrdinalIgnoreCase) -or `
                $venvFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
            if (-not $inApp) { continue }

            $appRel = Get-RelativeLogPath $rootFull $appFull
            $answer = 's'
            if (-not $venvApplyAll) {
                $answer = [string](Read-Host "¿Desactivo el venv '$appRel' antes de mover? [S]í/[N]o")
                if ($answer.Trim().ToLowerInvariant() -match '^(t|todos|all)$') {
                    $venvApplyAll = $true
                    $answer = 's'
                }
            }
            switch -Regex ($answer.Trim().ToLowerInvariant()) {
                '^(s|si|sí|y|yes)$' {
                    $entry = @{ App = $app; Path = $venvPath; IsConda = $false; Deactivated = $false; Detail = "" }
                    $deact = Get-Command deactivate -CommandType Function -ErrorAction SilentlyContinue
                    if ($null -eq $deact) {
                        Write-Warn "Sin función 'deactivate' en esta sesión: NO se desactiva el venv de '$app' (mueve con locks bajo tu responsabilidad)."
                        $entry.Detail = "sin-funcion-deactivate"
                    }
                    else {
                        try {
                            deactivate
                            $entry.Deactivated = $true
                            $entry.Detail = "desactivado"
                            Write-OK "Venv desactivado para '$app' (previo: $appRel). Restore-AppLocks lo reactivará al final."
                        }
                        catch {
                            Write-Warn "No se pudo desactivar el venv de '$app' ($($_.Exception.Message)). Mueve con locks bajo tu responsabilidad."
                            $entry.Detail = "deactivate-fallo"
                        }
                    }
                    $state.Venvs += $entry
                }
                '^(c|cancelar|cancel)$' {
                    Write-Warn "Suspend cancelado por el usuario: lo restante queda con locks activos (bajo tu responsabilidad)."
                    $cancelRest = $true
                }
                default {
                    Write-Warn "'$app': venv NO desactivado ([N]o). Mueve con locks activos bajo tu responsabilidad."
                    $state.Venvs += @{ App = $app; Path = $venvPath; IsConda = $false; Deactivated = $false; Detail = "no-desactivado-por-usuario" }
                }
            }
        }
    }

    # --- 2) git.exe puntuales con actividad en apps candidatas ---
    $gitLocks = @(Get-AppGitLocks -AppDirs $AppDirs -ProjectRoot $rootFull)
    $gitApplyAll = $false
    foreach ($g in $gitLocks) {
        if ($cancelRest) {
            $state.Git += @{ Id = $g.Id; App = $g.App; Paused = $false; Detail = "suspend-cancelado" }
            continue
        }
        $gAnswer = 's'
        if (-not $gitApplyAll) {
            $gAnswer = [string](Read-Host "¿Pauso git.exe PID $($g.Id) (app '$($g.App)', $($g.AppRel))? [S]í/[N]o")
            if ($gAnswer.Trim().ToLowerInvariant() -match '^(t|todos|all)$') {
                $gitApplyAll = $true
                $gAnswer = 's'
            }
        }
        switch -Regex ($gAnswer.Trim().ToLowerInvariant()) {
            '^(s|si|sí|y|yes)$' {
                $ok = Stop-VerifiedGitProcess -ProcessId $g.Id -ExpectedStartTime $g.StartTime -ExpectedExecutable $g.ExecutablePath -AppRel $g.AppRel
                $detail = if ($ok) { "pausado" } else { "pausa-abortada-o-fallida" }
                if (-not $ok) {
                    Write-Warn "'$($g.App)': git.exe PID $($g.Id) NO pausado. Mueve con locks bajo tu responsabilidad."
                }
                $state.Git += @{ Id = $g.Id; App = $g.App; Paused = [bool]$ok; Detail = $detail }
            }
            '^(c|cancelar|cancel)$' {
                Write-Warn "Suspend cancelado por el usuario: lo restante queda con locks activos (bajo tu responsabilidad)."
                $cancelRest = $true
                $state.Git += @{ Id = $g.Id; App = $g.App; Paused = $false; Detail = "suspend-cancelado" }
            }
            default {
                Write-Warn "'$($g.App)': git.exe PID $($g.Id) NO pausado ([N]o). Mueve con locks bajo tu responsabilidad."
                $state.Git += @{ Id = $g.Id; App = $g.App; Paused = $false; Detail = "no-pausado-por-usuario" }
            }
        }
    }

    return $state
}

# =============================================================================
# Invoke-VerifiedVenvActivation (RF-14): dot-source VERIFICADO de un venv.
# Exige: ruta canónica contenida en $MustBeInside (containment-check) +
# `Activate.ps1` existe como archivo + `pyvenv.cfg` hermano (marca de venv
# real). Tras el dot-source confirma que $env:VIRTUAL_ENV resuelve al venv
# esperado; si no → aviso y $false. Logs solo con rutas relativas.
# =============================================================================
function Invoke-VerifiedVenvActivation {
    param(
        [string]$VenvDir = "",
        [string]$MustBeInside = "",
        [string]$RootFull = ""
    )

    if ([string]::IsNullOrWhiteSpace($VenvDir)) {
        return $false
    }
    try {
        $venvFull = [System.IO.Path]::GetFullPath($VenvDir)
        $baseFull = [System.IO.Path]::GetFullPath($MustBeInside)
    }
    catch {
        Write-Warn "Ruta de venv no canónica; no se activa (fail-closed)."
        return $false
    }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $basePrefix = $baseFull.TrimEnd('\', '/') + $sep
    if (-not ($venvFull.Equals($baseFull, [System.StringComparison]::OrdinalIgnoreCase) -or `
            $venvFull.StartsWith($basePrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
        Write-Warn "El venv queda fuera de la app esperada; NO se ejecuta su Activate.ps1 (containment-check)."
        return $false
    }

    $activate = [System.IO.Path]::Combine($venvFull, "Scripts", "Activate.ps1")
    $cfg = [System.IO.Path]::Combine($venvFull, "pyvenv.cfg")
    $venvRel = Get-RelativeLogPath $RootFull $venvFull
    if (-not (Test-Path -LiteralPath $activate -PathType Leaf)) {
        Write-Warn "Sin Activate.ps1 en '$venvRel'; no se activa (recrea el venv a mano)."
        return $false
    }
    if (-not (Test-Path -LiteralPath $cfg -PathType Leaf)) {
        Write-Warn "Sin pyvenv.cfg en '$venvRel' (no parece un venv real); NO se ejecuta su Activate.ps1."
        return $false
    }

    try {
        . $activate
    }
    catch {
        Write-Warn "Falló la activación de '$venvRel' ($($_.Exception.Message)). Reactiva a mano el anterior."
        return $false
    }

    $after = $env:VIRTUAL_ENV
    if ([string]::IsNullOrWhiteSpace($after)) {
        Write-Warn "La activación de '$venvRel' no dejó VIRTUAL_ENV; no se da por restaurado."
        return $false
    }
    try {
        $afterFull = [System.IO.Path]::GetFullPath($after)
    }
    catch {
        $afterFull = $after
    }
    if ($afterFull.Equals($venvFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-OK "Venv reactivado: $venvRel (VIRTUAL_ENV verificado)."
        return $true
    }

    Write-Warn "VIRTUAL_ENV resultante no es el esperado; no se da por restaurado (revisa a mano)."
    return $false
}

# =============================================================================
# Restore-AppLocks (RF-14, criterio 10): tras mover, restaura por app según su
# RESULTADO REAL (nunca asume "todas se movieron": movida→nuevo
# `src\<App>\.venv`, omitida/abortada→original). App movida: ofrece RECREAR con
# confirmación separada — (1) `python -m venv` (barato, local) y (2)
# `pip install` SOLO con confirmación propia + manifiesto fijado dentro de la
# app (`requirements.txt` o `requirements.lock`; si no hay → venv vacío +
# aviso de instalar a mano). Luego ofrece REACTIVAR (dot-source verificado +
# VIRTUAL_ENV confirmado). Git: nada que reactivar (se redescubre solo) → se
# informa. Todo con confirmación por acción, sin bypass; -Force no aplica. No
# interactivo → no muta (instrucciones manuales). -DryRun → informa, no muta
# (cero red, cero ejecución). Registra el resultado real por app. Logs: rutas
# relativas.
# =============================================================================
function Restore-AppLocks {
    param(
        [hashtable]$Suspended = @{},
        [string]$ProjectRoot = ""
    )

    $rootFull = ""
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        }
        catch {
            $rootFull = $ProjectRoot
        }
    }

    $venvs = @()
    $gits = @()
    if ($null -ne $Suspended) {
        if ($Suspended.ContainsKey("Venvs")) {
            $venvs = @($Suspended.Venvs)
        }
        if ($Suspended.ContainsKey("Git")) {
            $gits = @($Suspended.Git)
        }
    }
    $pausedGit = @($gits | Where-Object { $_.Paused })

    if ($DryRun) {
        Write-Info "DryRun: Restore-AppLocks informa sin mutar (cero venv, cero pip install, cero red)."
        foreach ($v in $venvs) {
            if ($v.Deactivated) {
                Write-Info "DryRun: recrearía/reactivaría el venv de '$($v.App)' según su resultado real (movida→src\, omitida→original). Sin cambios."
            }
        }
        if ($pausedGit.Count -gt 0) {
            Write-Info "DryRun: git se redescubre solo; nada que reactivar ($($pausedGit.Count) pausado(s))."
        }
        return
    }

    $activeLocks = @($venvs | Where-Object { $_.Deactivated })
    if (-not (Test-IsInteractive)) {
        if (($activeLocks.Count -gt 0) -or ($pausedGit.Count -gt 0)) {
            Write-Warn "Sin consola interactiva: Restore-AppLocks NO muta nada. Recrea/reactiva tu venv a mano; git se redescubre solo."
        }
        return
    }

    if (($venvs.Count -eq 0) -and ($gits.Count -eq 0)) {
        return
    }

    foreach ($v in $activeLocks) {
        $app = [string]$v.App
        if ([string]::IsNullOrWhiteSpace($app)) { continue }
        if (-not (Test-SimpleAppName $app)) { continue }
        if ($DeniedAppNames -contains $app) { continue }

        $origFull = ""
        $newFull = ""
        try {
            $origFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $app))
            $newFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine([System.IO.Path]::Combine($rootFull, "src"), $app))
        }
        catch {
            continue
        }
        $moved = ((Test-Path -LiteralPath $newFull -PathType Container) -and (-not (Test-Path -LiteralPath $origFull -PathType Container)))
        $newRel = Get-RelativeLogPath $rootFull $newFull

        if ($moved) {
            $newVenv = [System.IO.Path]::Combine($newFull, ".venv")
            $newVenvRel = Get-RelativeLogPath $rootFull $newVenv
            $r1 = [string](Read-Host "La app '$app' SE MOVIÓ a '$newRel'. ¿Recreo su venv vacío en '$newVenvRel' (python -m venv, local; reemplaza el .venv movido, roto)? [S]í/[N]o")
            if ($r1.Trim().ToLowerInvariant() -notmatch '^(s|si|sí|y|yes)$') {
                Write-Warn "'$app': venv NO recreado ([N]o). Recréalo a mano tras revisar."
                continue
            }
            $sep = [System.IO.Path]::DirectorySeparatorChar
            $newPrefix = $newFull.TrimEnd('\', '/') + $sep
            try {
                $newVenvFull = [System.IO.Path]::GetFullPath($newVenv)
            }
            catch {
                $newVenvFull = ""
            }
            if (($newVenvFull -eq "") -or (-not $newVenvFull.StartsWith($newPrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
                Write-Warn "'$app': la ruta del venv nuevo escapa de la app; NO se recrea (containment-check)."
                continue
            }
            try {
                if (Test-Path -LiteralPath $newVenvFull) {
                    Remove-Item -LiteralPath $newVenvFull -Recurse -Force -ErrorAction Stop
                }
                & python -m venv "$newVenvFull" 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "python -m venv salió con código $LASTEXITCODE"
                }
            }
            catch {
                Write-Warn "'$app': no se pudo recrear el venv ($($_.Exception.Message)). Recréalo a mano en '$newRel'."
                continue
            }
            if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($newVenvFull, "pyvenv.cfg")) -PathType Leaf)) {
                Write-Warn "'$app': tras recrear no hay pyvenv.cfg en '$newVenvRel'; no se continúa (fail-closed)."
                continue
            }
            Write-OK "Venv recreado (vacío) en '$newVenvRel'."

            # `pip install` SOLO con confirmación separada + manifiesto fijado dentro de la app.
            $manifest = ""
            foreach ($cand in @("requirements.txt", "requirements.lock")) {
                $tryPath = [System.IO.Path]::Combine($newFull, $cand)
                if (Test-Path -LiteralPath $tryPath -PathType Leaf) {
                    $manifest = $tryPath
                    break
                }
            }
            if ($manifest -ne "") {
                $manifestRel = Get-RelativeLogPath $rootFull $manifest
                $r2 = [string](Read-Host "¿Instalo dependencias desde '$manifestRel' (pip install: ejecuta código + necesita red + tarda)? [S]í/[N]o")
                if ($r2.Trim().ToLowerInvariant() -match '^(s|si|sí|y|yes)$') {
                    $venvPython = [System.IO.Path]::Combine($newVenvFull, "Scripts", "python.exe")
                    try {
                        & $venvPython -m pip install -r "$manifest"
                        if ($LASTEXITCODE -ne 0) {
                            Write-Warn "'$app': pip install salió con código $LASTEXITCODE (venv vacío utilizable; reinstala a mano)."
                        }
                        else {
                            Write-OK "'$app': dependencias instaladas desde '$manifestRel'."
                        }
                    }
                    catch {
                        Write-Warn "'$app': pip install falló ($($_.Exception.Message)). Venv vacío utilizable; reinstala a mano."
                    }
                }
                else {
                    Write-Warn "'$app': dependencias NO instaladas ([N]o). Venv vacío; instala a mano cuando quieras."
                }
            }
            else {
                Write-Warn "'$app': sin requirements.txt/requirements.lock en '$newRel' → venv vacío + instala dependencias a mano."
            }

            $r3 = [string](Read-Host "¿Activo el nuevo venv '$newVenvRel'? [S]í/[N]o")
            if ($r3.Trim().ToLowerInvariant() -match '^(s|si|sí|y|yes)$') {
                $okAct = Invoke-VerifiedVenvActivation -VenvDir $newVenvFull -MustBeInside $newFull -RootFull $rootFull
                if (-not $okAct) {
                    Write-Warn "'$app': no se pudo activar el nuevo venv; reactiva a mano el anterior si lo necesitas."
                }
            }
            else {
                Write-Warn "'$app': nuevo venv NO activado ([N]o). Actívalo a mano cuando quieras."
            }
        }
        else {
            $origVenv = [string]$v.Path
            $origVenvRel = $origVenv
            try {
                $origVenvRel = Get-RelativeLogPath $rootFull ([System.IO.Path]::GetFullPath($origVenv))
            }
            catch { }
            $r0 = [string](Read-Host "La app '$app' NO se movió. ¿Reactivo su venv original '$origVenvRel'? [S]í/[N]o")
            if ($r0.Trim().ToLowerInvariant() -match '^(s|si|sí|y|yes)$') {
                $okBack = Invoke-VerifiedVenvActivation -VenvDir $origVenv -MustBeInside $origFull -RootFull $rootFull
                if (-not $okBack) {
                    Write-Warn "'$app': no se pudo reactivar el venv original; reactiva a mano."
                }
            }
            else {
                Write-Warn "'$app': venv original NO reactivado ([N]o). Reactiva a mano si lo necesitas."
            }
        }
    }

    foreach ($v in $venvs) {
        if (-not $v.Deactivated) {
            if (([string]$v.Detail) -notin @("", "suspend-cancelado")) {
                Write-Warn "Aviso persistente: venv de '$($v.App)' quedó sin desactivar ($($v.Detail)); se movió con locks bajo tu responsabilidad."
            }
        }
    }

    if ($pausedGit.Count -gt 0) {
        Write-Info "Git pausado ($($pausedGit.Count)): se redescubre solo; nada que reactivar."
    }
}

# =============================================================================
# Find-RegenerableDirs (RF-15, criterio 11): escanea UNA app contra la
# allowlist fija de nombres exactos, UN nivel (hijos directos, sin -Recurse),
# y mide tamanos. Nunca desciende a `Documentacion/` (exclusion explicita,
# tanto si la app fuera `Documentacion` como si hubiera un hijo con ese
# nombre). Allowlist: Python `__pycache__`, `.pytest_cache`, `*.egg-info`
# (sufijo), `.mypy_cache`, `.ruff_cache`, `build`, `dist`; Node
# `node_modules`, `.next`, `dist`, `build`, `coverage`; general `.cache`;
# mas `.venv/`. Comparacion exacta case-insensitive (el FS de Windows ya lo
# es); `dist-new` NO matchea (no hay substrings). `*.egg-info` matchea por
# sufijo exacto.
# Gate git-trackeado (relocate-cleanup.md riesgo 1, condicion innegociable):
# si `git ls-files` lista algo bajo el candidato → esta versionado a proposito
# → se EXCLUYE con aviso ("versionado, no se toca") y se mueve con la app.
# Sin repo git → se incluye marcado "sin gate git" (decision informada).
# Devuelve array de PSCustomObject (incluidos + excluidos con su motivo).
# =============================================================================
function Find-RegenerableDirs {
    param(
        [string]$AppPath = "",
        [string]$ProjectRoot = ""
    )

    $found = @()
    if ([string]::IsNullOrWhiteSpace($AppPath)) { return $found }
    try {
        $appFull = [System.IO.Path]::GetFullPath($AppPath)
    }
    catch {
        return $found
    }
    if (-not (Test-Path -LiteralPath $appFull -PathType Container)) { return $found }
    if ((Split-Path -Leaf $appFull) -ieq "Documentacion") { return $found }

    $rootFull = ""
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        }
        catch {
            $rootFull = ""
        }
    }
    if ($rootFull -eq "") { $rootFull = (Split-Path -Parent $appFull) }
    $appName = Split-Path -Leaf $appFull

    $exactNames = @(
        "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache",
        "build", "dist", "node_modules", ".next", "coverage", ".cache", ".venv"
    )

    $inRepo = $false
    try {
        $null = git -C $appFull rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -eq 0) { $inRepo = $true }
    }
    catch {
        $inRepo = $false
    }

    $venvActiveFull = ""
    if (-not [string]::IsNullOrWhiteSpace($env:VIRTUAL_ENV)) {
        try {
            $venvActiveFull = [System.IO.Path]::GetFullPath($env:VIRTUAL_ENV)
        }
        catch {
            $venvActiveFull = [string]$env:VIRTUAL_ENV
        }
    }

    $children = @()
    try {
        $children = @(Get-ChildItem -LiteralPath $appFull -Force -ErrorAction Stop | Where-Object { $_.PSIsContainer })
    }
    catch {
        return $found
    }

    foreach ($child in $children) {
        $name = $child.Name
        if ($name -ieq "Documentacion") { continue }
        $isVenv = $name -ieq ".venv"
        $isEggInfo = (-not $isVenv) -and ($name -like "*.egg-info")
        if ((-not $isVenv) -and (-not $isEggInfo) -and (-not ($exactNames -contains $name))) { continue }

        $size = Get-AppSizeInfo -LiteralDir $child.FullName
        $rel = Get-RelativeLogPath $rootFull $child.FullName

        $gitChecked = $inRepo
        $gitTracked = $false
        if ($inRepo) {
            try {
                $listed = git -C $appFull ls-files -- $name 2>$null
                if (($LASTEXITCODE -eq 0) -and ($listed)) { $gitTracked = $true }
            }
            catch {
                $gitChecked = $false
            }
        }

        $isActive = $false
        if ($isVenv -and ($venvActiveFull -ne "")) {
            $sep = [System.IO.Path]::DirectorySeparatorChar
            $candPrefix = $child.FullName.TrimEnd('\', '/') + $sep
            if ($venvActiveFull.Equals($child.FullName, [System.StringComparison]::OrdinalIgnoreCase) -or `
                $venvActiveFull.StartsWith($candPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isActive = $true
            }
        }

        $manifest = ""
        $nodeLock = ""
        $nodePatches = $false
        if ($isVenv) {
            foreach ($cand in @("requirements.txt", "requirements.lock", "pyproject.toml")) {
                if (Test-Path -LiteralPath ([System.IO.Path]::Combine($appFull, $cand)) -PathType Leaf) {
                    $manifest = $cand
                    break
                }
            }
        }
        if ($name -ieq "node_modules") {
            foreach ($cand in @("package-lock.json", "pnpm-lock.yaml", "yarn.lock")) {
                if (Test-Path -LiteralPath ([System.IO.Path]::Combine($appFull, $cand)) -PathType Leaf) {
                    $nodeLock = $cand
                    break
                }
            }
            if (Test-Path -LiteralPath ([System.IO.Path]::Combine($appFull, "patches")) -PathType Container) {
                $nodePatches = $true
            }
        }

        $excluded = $false
        $reason = ""
        if ($gitTracked) {
            $excluded = $true
            $reason = "versionado-no-se-toca"
            Write-Warn "'$rel': versionado en git (trackeado a proposito) -> se EXCLUYE de la limpieza, no se toca; se mueve con la app."
        }

        $found += [PSCustomObject]@{
            App         = $appName
            Name        = $name
            FullPath    = $child.FullName
            AppFull     = $appFull
            RelPath     = $rel
            FileCount   = $size.FileCount
            Bytes       = $size.Bytes
            MB          = $size.MB
            IsVenv      = $isVenv
            Excluded    = $excluded
            Reason      = $reason
            GitChecked  = $gitChecked
            GitTracked  = $gitTracked
            IsActive    = $isActive
            Manifest    = $manifest
            NodeLock    = $nodeLock
            NodePatches = $nodePatches
        }
    }

    return $found
}

# =============================================================================
# Clear-RegenerableDirs (RF-15, criterio 11): elimina cada target (solo
# objetos de `Find-RegenerableDirs` ya filtrados por allowlist + gate git)
# con log de ruta relativa + tamano liberado. Sin respaldo (regenerables).
# Controles: containment-check (ruta canonica dentro de la app), idempotente
# al reintentar ("ya limpio", no error), `.venv` ACTIVADO → se SALTA con
# aviso (fail-closed: exige `deactivate` previo verificado, RF-14).
# En -DryRun informa sin borrar; sin consola no borra (fail-closed).
# Usa el $DryRun del script (mismo patron que Move-AppToSrc).
# Devuelve PSCustomObject: Removed, Skipped, FreedBytes, FreedMB.
# =============================================================================
function Clear-RegenerableDirs {
    param(
        [array]$Targets = @()
    )

    $removed = 0
    $skipped = 0
    $freedBytes = 0

    foreach ($t in $Targets) {
        $full = [string]$t.FullPath
        $rel = [string]$t.RelPath
        if ([string]::IsNullOrWhiteSpace($full)) { continue }
        if ([string]::IsNullOrWhiteSpace($rel)) { $rel = $full }

        $appFull = [string]$t.AppFull
        try {
            $fullCanon = [System.IO.Path]::GetFullPath($full)
            $appCanon = [System.IO.Path]::GetFullPath($appFull)
        }
        catch {
            Write-Warn "'$rel': ruta no canonica; se SALTA (containment-check)."
            $skipped++
            continue
        }
        $sep = [System.IO.Path]::DirectorySeparatorChar
        $appPrefix = $appCanon.TrimEnd('\', '/') + $sep
        if (-not $fullCanon.StartsWith($appPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Warn "'$rel': fuera de la app esperada; se SALTA (containment-check)."
            $skipped++
            continue
        }

        $isVenv = [bool]$t.IsVenv
        $stillThere = Test-Path -LiteralPath $fullCanon -PathType Container

        $nowActive = $false
        if ($isVenv -and (-not [string]::IsNullOrWhiteSpace($env:VIRTUAL_ENV))) {
            try {
                $vFull = [System.IO.Path]::GetFullPath($env:VIRTUAL_ENV)
            }
            catch {
                $vFull = [string]$env:VIRTUAL_ENV
            }
            $candPrefix = $fullCanon.TrimEnd('\', '/') + $sep
            if ($vFull.Equals($fullCanon, [System.StringComparison]::OrdinalIgnoreCase) -or `
                $vFull.StartsWith($candPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $nowActive = $true
            }
        }

        if ($DryRun) {
            $extra = if ($nowActive) { " [.venv ACTIVO: en modo real se exigiria 'deactivate' previo]" } else { "" }
            if ($stillThere) {
                Write-Info "DryRun: eliminaria '$rel' ($($t.FileCount) archivos, $($t.MB) MB)$extra. Sin cambios."
            }
            else {
                Write-Info "DryRun: '$rel' ya limpio (no existe). Sin cambios."
            }
            continue
        }

        if (-not (Test-IsInteractive)) {
            Write-Warn "Sin consola interactiva: NO se elimina '$rel' (fail-closed). Limpia a mano o usa terminal interactiva."
            $skipped++
            continue
        }

        if (-not $stillThere) {
            Write-Info "'$rel': ya limpio (no existe); nada que borrar."
            continue
        }

        if ($isVenv -and $nowActive) {
            Write-Warn "'$rel': .venv ACTIVADO en esta terminal -> exige 'deactivate' previo verificado (RF-14). Se SALTA este .venv, no se borra (fail-closed)."
            $skipped++
            continue
        }

        try {
            Remove-Item -LiteralPath $fullCanon -Recurse -Force -ErrorAction Stop
            $freedBytes += [long]$t.Bytes
            $removed++
            Write-OK "Eliminado '$rel' (liberados $($t.MB) MB)."
        }
        catch {
            Write-Fail "No se pudo eliminar '$rel' ($($_.Exception.Message)). Se deja en su lugar."
            $skipped++
        }
    }

    return [PSCustomObject]@{
        Removed    = $removed
        Skipped    = $skipped
        FreedBytes = $freedBytes
        FreedMB    = [Math]::Round($freedBytes / 1MB, 2)
    }
}

# =============================================================================
# Invoke-RegenerableCleanup (RF-15, criterio 11): fase de limpieza ANTES del
# plan S/N/T/C por app. Escanea apps candidatas validadas (nombres simples +
# denylist + containment de RF-13; nunca `Documentacion/`), muestra la lista
# consolidada por app (dirs + tamanos + total + flags "sin gate git" /
# ".venv ACTIVO, requiere deactivate" / manifiesto / lockfile Node) y pregunta
# global "¿Elimino caches regenerables antes de mover? [S]i/[N]o" (default No,
# solo S/N: no hay T global). Si N → mueve todo (comportamiento anterior).
# Si S: borra caches via `Clear-RegenerableDirs` y pide confirmacion SEPARADA
# por cada `.venv` listado (nunca dentro del "si a todo" de caches): sin
# manifiesto → aviso "irreproducible" + comando `pip freeze` de rescate a
# ejecutar ANTES de borrar (el rescate se guarda fuera de la app, junto al
# log); con manifiesto → se informa el nombre. `.venv` activo sin `deactivate`
# → `Clear` lo salta (fail-closed). -DryRun/no-interactivo: informa, no borra.
# Devuelve hashtable @{ CleanedVenvs } (app -> @{ Manifest; RelPath }) para que
# el informe final de los comandos de recreacion en la ruta nueva `src\<App>`.
# =============================================================================
function Invoke-RegenerableCleanup {
    param(
        [string[]]$AppDirs = @(),
        [string]$ProjectRoot = ""
    )

    $state = @{ CleanedVenvs = @{} }

    $rootFull = ""
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
        }
        catch {
            $rootFull = $ProjectRoot
        }
    }
    if ($rootFull -eq "") { return $state }

    $all = @()
    foreach ($app in $AppDirs) {
        if ([string]::IsNullOrWhiteSpace($app)) { continue }
        if (-not (Test-SimpleAppName $app)) { continue }
        if ($DeniedAppNames -contains $app) { continue }
        try {
            $appFull = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFull, $app))
        }
        catch {
            continue
        }
        if (-not (Test-Path -LiteralPath $appFull -PathType Container)) { continue }
        $all += @(Find-RegenerableDirs -AppPath $appFull -ProjectRoot $rootFull)
    }

    $candidatos = @($all | Where-Object { -not $_.Excluded })
    $excluidos = @($all | Where-Object { $_.Excluded })

    if (($candidatos.Count -eq 0) -and ($excluidos.Count -eq 0)) {
        Write-Info "Limpieza RF-15: sin dirs regenerables en las apps candidatas."
        return $state
    }

    Write-Step "Regenerables detectados (RF-15) — resumen por app ANTES de decidir:"
    $totalBytes = 0
    $grouped = $candidatos | Group-Object -Property App
    foreach ($g in $grouped) {
        Write-Info "  [$($g.Name)]:"
        foreach ($c in $g.Group) {
            $flags = @()
            if (-not $c.GitChecked) { $flags += "sin gate git" }
            if ($c.IsVenv) {
                if ($c.IsActive) { $flags += ".venv ACTIVO, requiere deactivate" }
                if ([string]::IsNullOrWhiteSpace($c.Manifest)) { $flags += "SIN manifiesto (irreproducible)" }
                else { $flags += "manifiesto: $($c.Manifest)" }
            }
            if ($c.Name -ieq "node_modules") {
                if ([string]::IsNullOrWhiteSpace($c.NodeLock)) { $flags += "sin lockfile" }
                else { $flags += "lockfile: $($c.NodeLock)" }
                if ($c.NodePatches) { $flags += "patches/ presente: verifica commit antes" }
            }
            $flagTxt = if ($flags.Count -gt 0) { " [" + ($flags -join "; ") + "]" } else { "" }
            Write-Info "    - $($c.RelPath) ($($c.FileCount) archivos, $($c.MB) MB)$flagTxt"
            $totalBytes += [long]$c.Bytes
        }
    }
    $totalMB = [Math]::Round($totalBytes / 1MB, 2)
    Write-Info "  Total a liberar: $totalMB MB en $($candidatos.Count) dir(s)."
    foreach ($x in $excluidos) {
        Write-Info "  Excluido (versionado, no se toca): $($x.RelPath)"
    }
    $venvsListed = @($candidatos | Where-Object { $_.IsVenv })
    if ($venvsListed.Count -gt 0) {
        Write-Warn "Los .venv NUNCA entran en un 'si a todo': cada uno pide confirmacion SEPARADA."
    }
    if (@($candidatos | Where-Object { $_.Name -ieq "node_modules" }).Count -gt 0) {
        Write-Warn "node_modules se reconstruye con 'npm ci' (red + tiempo); si trabajas offline, di No."
    }

    if ($DryRun) {
        Write-Info "DryRun: eliminaria lo listado arriba (cero escrituras, cero red). Sin cambios."
        return $state
    }
    if (-not (Test-IsInteractive)) {
        Write-Warn "Sin consola interactiva: NO se borra nada (fail-closed, criterio 11)."
        return $state
    }

    $answer = [string](Read-Host "¿Elimino caches regenerables antes de mover? [S]i/[N]o")
    if ($answer.Trim().ToLowerInvariant() -notmatch '^(s|si|sí|y|yes)$') {
        Write-Info "Sin limpieza ([N]o, default seguro): se mueve todo (comportamiento anterior)."
        return $state
    }

    $caches = @($candidatos | Where-Object { -not $_.IsVenv })
    if ($caches.Count -gt 0) {
        $res = Clear-RegenerableDirs -Targets $caches
        Write-Info "Caches: eliminados $($res.Removed), omitidos $($res.Skipped) (liberados $($res.FreedMB) MB)."
    }

    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    foreach ($v in $venvsListed) {
        $appRel = [string]$v.App
        if ([string]::IsNullOrWhiteSpace($v.Manifest)) {
            Write-Warn "'$($v.RelPath)': .venv SIN manifiesto (requirements.txt/lock/pyproject.toml) -> entorno IRREPRODUCIBLE si se borra."
            Write-Info "  Rescate ANTES de borrar (ejecutalo tu, desde la raiz del proyecto, antes de decir Si): & `"$($v.FullPath)\Scripts\python.exe`" -m pip freeze > `"requirements-rescate-$stamp.txt`""
        }
        else {
            Write-Info "'$($v.RelPath)': manifiesto '$($v.Manifest)' presente (recreable con pip install en la ruta nueva)."
        }
        if ($v.IsActive) {
            Write-Warn "'$($v.RelPath)': .venv ACTIVO -> requiere 'deactivate' previo verificado; si sigue activo se SALTA (fail-closed)."
        }
        $va = [string](Read-Host "¿Eliminar el .venv de '$appRel' ($($v.MB) MB)? [S]i/[N]o")
        if ($va.Trim().ToLowerInvariant() -notmatch '^(s|si|sí|y|yes)$') {
            Write-Info "'$($v.RelPath)': .venv conservado ([N]o); se mueve con la app."
            continue
        }
        $r1 = Clear-RegenerableDirs -Targets @($v)
        if ($r1.Removed -gt 0) {
            $state.CleanedVenvs[$appRel] = @{ Manifest = [string]$v.Manifest; RelPath = [string]$v.RelPath }
        }
    }

    return $state
}

# =============================================================================
# MAIN (RF-13, criterio 9): itera -AppDirs (nunca adivina), lista numerada
# visible antes del primer prompt, S/N/T/C por app, informe final con
# movidas/omitidas/venvs-a-recrear/imports+tests/rollback manual.
# Nunca toca Documentacion/.
# =============================================================================
function Invoke-AppRelocation {
    $rootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
    Write-Step "Reubicacion a src\ (standalone, RF-13) | Raiz: $rootFull | DryRun: $($DryRun.IsPresent)"

    if ($AppDirs.Count -eq 0) {
        Write-Warn "Sin apps: pasa -AppDirs con los nombres simples de las carpetas a reubicar. No se adivina nada."
        Write-Info 'Ejemplo: .\scripts\relocate-apps-to-src.ps1 -AppDirs @("trading_bot", "Telegram") -DryRun'
        return
    }

    # --- git limpio recomendado (S1.6): aviso, no bloqueo ---
    $dirty = Get-GitDirtyHint -RootPath $rootFull
    if ($dirty -eq $true) {
        Write-Warn "git con cambios sin commitear: haz commit/stash ANTES de mover y commit atomico por app/lote tras verificar (no commitear a medias)."
    }

    # --- .venv activado en esta terminal (solo aviso, no bloquea; tambien en -DryRun) ---
    $activeVenv = Test-ActiveVenv -ProjectRoot $rootFull -AppDirs $AppDirs
    if ($null -ne $activeVenv) {
        $venvLabel = if ($activeVenv.IsConda) { "conda ($($activeVenv.Path))" } else { ".venv ($($activeVenv.Path))" }
        $offCmd = if ($activeVenv.IsConda) { "conda deactivate" } else { "deactivate" }
        if (-not [string]::IsNullOrWhiteSpace($activeVenv.InApp)) {
            Write-Warn "Hay un entorno virtual ACTIVADO dentro de la app a mover '$($activeVenv.InApp)': $venvLabel."
            Write-Warn "Desactivalo antes del modo real con '$offCmd'; tras mover y RECREAR el venv, reactivalo con 'src\$($activeVenv.InApp)\.venv\Scripts\Activate.ps1' (el .venv movido queda roto: recrear primero con 'python -m venv .venv', no reutilizar)."
        }
        elseif ($activeVenv.InProject) {
            Write-Warn "Hay un entorno virtual ACTIVADO dentro del proyecto pero fuera de las apps a mover: $venvLabel. Desactivalo con '$offCmd' si interfiere; verifica que no apunte a una app candidata antes del modo real."
        }
        else {
            Write-Info "Entorno virtual activado fuera del proyecto: $venvLabel (no bloquea; solo se informa)."
        }
    }

    # --- RF-14: suspender locks (venv + git.exe) tras el aviso y antes del plan ---
    # El restore va en `finally` (cubre DryRun/no-interactivo/interactivo,
    # abortos y cancelaciones). Sin bypass en ningún punto.
    # ponytail: try/finally sin re-indent interno (diff mínimo, sintaxis válida).
    $suspendedLocks = @{ Venvs = @(); Git = @(); DryRun = [bool]$DryRun }
    try {
    $suspendedLocks = Suspend-AppLocks -AppDirs $AppDirs -ProjectRoot $rootFull

    # --- RF-15: limpieza de regenerables tras el aviso/suspend de venv y
    # ANTES del plan S/N/T/C (pregunta global S/N default No; N = mueve todo;
    # .venv con confirmacion separada; DryRun/no-interactivo no borra) ---
    $cleanupState = Invoke-RegenerableCleanup -AppDirs $AppDirs -ProjectRoot $rootFull

    # --- Lista completa numerada antes del primer prompt (S1.4) ---
    Write-Step "Plan de reubicacion ($($AppDirs.Count) candidata(s)):"
    $i = 0
    foreach ($app in $AppDirs) {
        $i++
        $cand = [System.IO.Path]::Combine($rootFull, $app)
        $dest = [System.IO.Path]::Combine($rootFull, "src", $app)
        $extra = ""
        if ((Test-SimpleAppName $app) -and -not ($DeniedAppNames -contains $app) -and (Test-Path -LiteralPath $cand -PathType Container)) {
            $sz = Get-AppSizeInfo -LiteralDir $cand
            $venvMark = if (Test-Path -LiteralPath (Join-Path $cand ".venv") -PathType Container) { ", .venv: Si (a recrear)" } else { ", .venv: No" }
            $extra = " ($($sz.FileCount) archivos, $($sz.MB) MB$venvMark)"
        }
        elseif ($DeniedAppNames -contains $app) {
            $extra = " (DENYLIST: se omitira)"
        }
        Write-Info "  [$i] $app : $(Get-RelativeLogPath $rootFull $cand) -> $(Get-RelativeLogPath $rootFull $dest)$extra"
    }

    $results = @()

    # --- -DryRun: informa por app, cero escrituras, sin confirmacion ---
    if ($DryRun) {
        Write-Info "DryRun: solo previsualiza (cero escrituras). Sin confirmacion."
        foreach ($app in $AppDirs) {
            $results += Move-AppToSrc -AppName $app -ProjectRoot $rootFull
        }
        Show-RelocationReport -Results $results -RootFull $rootFull -WasDryRun $true -CleanedVenvs $cleanupState.CleanedVenvs
        return
    }

    # --- No interactivo: NO mueve, informa (fail-closed, criterio 9) ---
    # NOTA: aqui NO se llama a Move-AppToSrc en modo real; solo se informa.
    if (-not (Test-IsInteractive)) {
        Write-Warn "Modo no interactivo (sin consola): NO se mueve nada (fail-closed). Ejecuta en terminal interactiva para confirmar S/N/T/C por app, o usa -DryRun para previsualizar."
        foreach ($app in $AppDirs) {
            $results += [PSCustomObject]@{
                AppName           = $app
                Status            = "OMITIDA"
                SourceRel         = $app
                DestRel           = "src\$app"
                FileCount         = 0
                SizeMB            = 0
                NeedsVenvRecreate = $false
                Detail            = "no-interactivo-no-mueve"
                Rollback          = ""
                Timestamp         = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        Show-RelocationReport -Results $results -RootFull $rootFull -WasDryRun $false -CleanedVenvs $cleanupState.CleanedVenvs
        return
    }

    # --- Interactivo: S/N/T/C por app; T aplica a restantes, C aborta todo ---
    $applyAll = $false
    foreach ($app in $AppDirs) {
        $sourceRel = $app
        $destRel = "src\$app"
        try {
            $sourceRel = Get-RelativeLogPath $rootFull ([System.IO.Path]::Combine($rootFull, $app))
            $destRel = Get-RelativeLogPath $rootFull ([System.IO.Path]::Combine($rootFull, "src", $app))
        }
        catch { }

        $decision = 'S'
        if ($applyAll) {
            Write-Info "'$app': aplica [T]odos restantes (confirmado en lote)."
            $decision = 'S'
        }
        else {
            $decision = Confirm-AppRelocation -AppName $app -Source $sourceRel -Destination $destRel
        }

        switch ($decision) {
            'T' {
                $applyAll = $true
                $results += Move-AppToSrc -AppName $app -ProjectRoot $rootFull
            }
            'C' {
                Write-Warn "Cancelado por el usuario: no se mueve nada mas."
                $results += [PSCustomObject]@{
                    AppName           = $app
                    Status            = "OMITIDA"
                    SourceRel         = $sourceRel
                    DestRel           = $destRel
                    FileCount         = 0
                    SizeMB            = 0
                    NeedsVenvRecreate = $false
                    Detail            = "cancelado-por-usuario"
                    Rollback          = ""
                    Timestamp         = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
                break
            }
            'S' {
                $results += Move-AppToSrc -AppName $app -ProjectRoot $rootFull
            }
            default {
                Write-Info "'$app': se deja en su lugar ([N]o)."
                $results += [PSCustomObject]@{
                    AppName           = $app
                    Status            = "OMITIDA"
                    SourceRel         = $sourceRel
                    DestRel           = $destRel
                    FileCount         = 0
                    SizeMB            = 0
                    NeedsVenvRecreate = $false
                    Detail            = "omitida-por-usuario"
                    Rollback          = ""
                    Timestamp         = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
        }
    }

    Show-RelocationReport -Results $results -RootFull $rootFull -WasDryRun $false -CleanedVenvs $cleanupState.CleanedVenvs
    }
    finally {
        Restore-AppLocks -Suspended $suspendedLocks -ProjectRoot $rootFull
    }
}

function Show-RelocationReport {
    param(
        [array]$Results,
        [string]$RootFull,
        [bool]$WasDryRun,
        [hashtable]$CleanedVenvs = @{}
    )

    $moved = @($Results | Where-Object { $_.Status -eq "OK" })
    $simulated = @($Results | Where-Object { $_.Status -eq "SIMULADA" })
    $skipped = @($Results | Where-Object { $_.Status -eq "OMITIDA" })
    $aborted = @($Results | Where-Object { $_.Status -eq "ABORTADA" })
    $venvs = @($Results | Where-Object { $_.NeedsVenvRecreate -and ($_.Status -eq "OK" -or $_.Status -eq "SIMULADA") })

    Write-Host ""
    Write-Step "Informe final de reubicacion"
    if ($WasDryRun) {
        Write-Info "Modo DryRun: cero escrituras. Nada se movio."
        Write-Info "Simuladas: $($simulated.Count) | Omitidas por pre-chequeo: $($skipped.Count)"
    }
    else {
        Write-OK "Movidas (OK): $($moved.Count)"
        foreach ($r in $moved) {
            Write-Info "  - $($r.SourceRel) -> $($r.DestRel) | $($r.Timestamp) | $($r.FileCount) archivos"
        }
        Write-Info "Omitidas: $($skipped.Count)"
        foreach ($r in $skipped) {
            Write-Info "  - $($r.AppName) ($($r.Detail))"
        }
        if ($aborted.Count -gt 0) {
            Write-Fail "Abortadas: $($aborted.Count)"
            foreach ($r in $aborted) {
                Write-Info "  - $($r.AppName) ($($r.Detail)): revisa '$($r.SourceRel)' y '$($r.DestRel)' con este log antes de reintentar."
            }
        }
    }

    if ($venvs.Count -gt 0) {
        Write-Host ""
        Write-Warn ".venv a RECREAR (no reutilizar el movido: sus paths absolutos internos quedan rotos): $($venvs.Count)"
        foreach ($r in $venvs) {
            Write-Info "  - $($r.DestRel):"
            Write-Info "      cd `"$($r.DestRel)`"  # desde la raiz del proyecto"
            Write-Info "      python -m venv .venv"
            Write-Info "      .\.venv\Scripts\Activate.ps1"
            Write-Info "      python -m pip install -r requirements.txt  # si la app tiene requirements"
        }
    }

    if ($CleanedVenvs.Count -gt 0) {
        Write-Host ""
        Write-Warn ".venv ELIMINADOS antes de mover (recrear en la ruta NUEVA, no reutilizar): $($CleanedVenvs.Count)"
        foreach ($key in $CleanedVenvs.Keys) {
            $info = $CleanedVenvs[$key]
            $man = [string]$info.Manifest
            Write-Info "  - src\$key\.venv:"
            Write-Info "      cd `"src\$key`"  # desde la raiz del proyecto"
            Write-Info "      python -m venv .venv"
            Write-Info "      .\.venv\Scripts\Activate.ps1"
            if ($man -ne "") {
                Write-Info "      python -m pip install -r $man  # manifiesto original '$man'"
            }
            else {
                Write-Info "      # SIN manifiesto original: si guardaste requirements-rescate-<fecha>.txt ANTES de borrar:"
                Write-Info "      python -m pip install -r requirements-rescate-<fecha>.txt  # rescate, o instala a mano"
            }
        }
    }

    if ($moved.Count -gt 0 -and -not $WasDryRun) {
        Write-Host ""
        Write-Warn "Post-movido: revisa imports/paths/configs que apunten a la ubicacion anterior y pasa los tests en la nueva ubicacion antes de commitear (commit atomico por app/lote; no commitear a medias)."
        Write-Step "Rollback manual (por app, en orden inverso, desde la raiz; verifica destino libre antes):"
        for ($k = $moved.Count - 1; $k -ge 0; $k--) {
            Write-Info "  $($moved[$k].Rollback)"
        }
    }

    Write-Info "Documentacion/ intacta (fuera de alcance por diseno); proyect_ext/spec-kit sigue en la raiz."
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AppRelocation
}
