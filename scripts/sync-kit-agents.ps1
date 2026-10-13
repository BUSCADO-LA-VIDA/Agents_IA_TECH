#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync-kit-agents.ps1 — Orquestador del sync por capas (fases 1-2)
# [021] Spec 021-sync-kit-agents, fases 1-2. 5 fases: Stage -> Sync -> Plataformar
# [021] -> Verify -> Restart-flag. Capas: kit-files, agents-github,
# [021] agents-opencode, agents-vscode, docs, constitutions, src-structure.
# [021] Invoke-SyncKit del bootstrap NO se modifica en esta fase: este
# [021] orquestador es independiente (compatibilidad = no romper su firma).
# [021] En -DryRun, CERO escrituras: ni temp, ni gitignore, ni reportes.
# =============================================================================

[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$KitPath = "",
    [string[]]$Only = @(),
    [string[]]$Skip = @(),
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/sync/lib/common.ps1"
Initialize-SyncLog

if (-not $RootPath) { $RootPath = (Split-Path -Parent $PSScriptRoot) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-kit-agents: -RootPath invalido ($RootPath): $_"; exit 1 }

# [021] Capas fases 1-2 en orden RF-02 (kit-files -> agents -> docs ->
# [021] constitutions -> src-structure; mcp/indexing/externals en fases 3-4):
# [021] nombre logico -> script relativo a scripts/.
# [021] AcceptsForce indica si la capa acepta -Force (docs nunca sobrescribe
# [021] contenido y no lo declara; kit-files lo acepta por uniformidad aunque su
# [021] clean+replace siempre sobrescribe diferencias).
$script:Layers = @(
    @{ Name = "kit-files";         Script = "sync/kit-files/sync-kit-files.ps1";                 AcceptsForce = $true },
    @{ Name = "agents-github";     Script = "sync/agents/sync-agents-github.ps1";       AcceptsForce = $true },
    @{ Name = "agents-opencode";   Script = "sync/agents/sync-agents-opencode.ps1";     AcceptsForce = $true },
    @{ Name = "agents-vscode";     Script = "sync/agents/sync-agents-vscode.ps1";       AcceptsForce = $true },
    @{ Name = "docs";              Script = "sync/docs/sync-docs.ps1";                   AcceptsForce = $false },
    @{ Name = "constitutions";     Script = "sync/constitutions/sync-constitutions.ps1"; AcceptsForce = $true },
    @{ Name = "src-structure";     Script = "sync/src-structure/sync-src-structure.ps1"; AcceptsForce = $true },
    # [021] Fase 3 (T009-T010, RF-04/RF-06): mcp-install es portable por maquina
    # [021] (NoStage: se invoca solo con -RootPath, sin -StageDir); los lifts son
    # [021] fusion aditiva (aceptan -Force para refrescar commands del maestro).
    @{ Name = "mcp-install";       Script = "sync/mcp/install.ps1";         AcceptsForce = $true; NoStage = $true },
    @{ Name = "mcp-lift-opencode"; Script = "sync/mcp/lift-opencode.ps1";   AcceptsForce = $true },
    @{ Name = "mcp-lift-vscode";   Script = "sync/mcp/lift-vscode.ps1";     AcceptsForce = $true }
)
$script:LayerNames = @($script:Layers | Select-Object -ExpandProperty Name)

# [021] --Only limita, --Skip excluye (nombres validados contra las capas fase 1).
function Resolve-ActiveLayers {
    param([string[]]$OnlyList, [string[]]$SkipList)
    $active = @($script:LayerNames)
    if ($OnlyList.Count -gt 0) {
        $unknown = @($OnlyList | Where-Object { $_ -and $script:LayerNames -notcontains $_ })
        foreach ($u in $unknown) { Write-Warn "sync-kit-agents: -Only '$u' no es una capa conocida (fases 1-2) (capas: $($script:LayerNames -join ', ')); se ignora." }
        $active = @($OnlyList | Where-Object { $script:LayerNames -contains $_ })
    }
    if ($SkipList.Count -gt 0) {
        $unknown = @($SkipList | Where-Object { $_ -and $script:LayerNames -notcontains $_ })
        foreach ($u in $unknown) { Write-Warn "sync-kit-agents: -Skip '$u' no es una capa conocida (fases 1-2); se ignora." }
        $active = @($active | Where-Object { $SkipList -notcontains $_ })
    }
    return $active
}

# [021] Validacion fail-closed de URL (mismo criterio que sync-kit.ps1).
function Test-AllowedKitUrl {
    param([string]$Url)
    return ($Url -like "https://github.com/*")
}

# [021] Validacion de -KitPath local (misma regla que sync-kit.ps1: no URLs,
# [021] marcadores del kit, distinto del destino).
function Resolve-KitPathSource {
    param([string]$Candidate, [string]$DestRoot)
    if ($Candidate -match '^[a-zA-Z][a-zA-Z0-9+.-]*://' -or $Candidate.StartsWith('git@')) {
        throw "[SECURITY] -KitPath no acepta URLs ni esquemas remotos (fail-closed): $Candidate"
    }
    try { $canon = [IO.Path]::GetFullPath($Candidate) } catch { throw "sync-kit-agents: -KitPath invalido ($Candidate): $_" }
    if (-not (Test-Path -LiteralPath $canon -PathType Container)) {
        throw "sync-kit-agents: -KitPath no existe o no es un directorio: $canon"
    }
    $missing = @()
    foreach ($m in @("scripts", ".github", ".opencode", ".doc_agents", "AGENTS.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $canon $m))) { $missing += $m }
    }
    if ($missing.Count -gt 0) {
        throw "sync-kit-agents: -KitPath no parece un checkout del kit (faltan: $($missing -join ', ') en $canon)"
    }
    $sep = [IO.Path]::DirectorySeparatorChar
    try { $rootCanon = [IO.Path]::GetFullPath($DestRoot) } catch { throw "sync-kit-agents: -RootPath invalido ($DestRoot): $_" }
    if ($canon.TrimEnd($sep) -eq $rootCanon.TrimEnd($sep)) {
        Write-Warn "sync-kit-agents: -KitPath es el propio proyecto destino; no hay nada que sincronizar."
        return $null
    }
    return $canon
}

# =============================================================================
# [021] F1 STAGE
# =============================================================================
Write-Step "sync-kit-agents: F1 STAGE (RootPath=$RootPath)"

$activeLayers = @(Resolve-ActiveLayers -OnlyList $Only -SkipList $Skip)
Write-Info "Capas activas: $($activeLayers -join ', ')"

$stageKitRoot = $null
$ownsTemp = $false
$tempBase = $null
$commitHash = "desconocido"
$commitDate = "desconocida"

if ($KitPath) {
    try {
        $stageKitRoot = Resolve-KitPathSource -Candidate $KitPath -DestRoot $RootPath
    } catch {
        Write-Fail "sync-kit-agents F1: $_"
        Show-ExecutionSummary -Title "sync-kit-agents"
        exit 1
    }
    if ($null -eq $stageKitRoot) {
        Write-Info "sync-kit-agents: stage = destino (nada que hacer)."
        Show-ExecutionSummary -Title "sync-kit-agents"
        exit 0
    }
    try {
        $b = (git -C $stageKitRoot rev-parse --abbrev-ref HEAD 2>$null)
        $s = (git -C $stageKitRoot rev-parse --short HEAD 2>$null)
        if ($b -and $s) { $commitHash = "local-kit ($b@$s)" } else { $commitHash = "local-kit" }
        $commitDate = (git -C $stageKitRoot log -1 --format=%ci 2>$null)
        if (-not $commitDate) { $commitDate = (Get-Date).ToString("o") }
    } catch { $commitDate = (Get-Date).ToString("o") }
    Write-Info "Stage LOCAL: $stageKitRoot [$commitHash]"
} else {
    if (-not (Test-AllowedKitUrl $RepoUrl)) {
        Write-Fail "sync-kit-agents F1: [SECURITY] URL no permitida (fail-closed): $RepoUrl (solo https://github.com/)"
        Show-ExecutionSummary -Title "sync-kit-agents"
        exit 1
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $tempBase = Join-Path $RootPath (".kit-sync-temp/$stamp")
    if ($DryRun) {
        # [021] DryRun: el stage solo se informa, no se clona (cero escrituras).
        Write-Info "DryRun: clonaria shallow `"$RepoUrl`" en $tempBase (sin escribir nada)"
        $stageKitRoot = "<stage-dryrun>"
    } else {
        try {
            New-Item -ItemType Directory -Path $tempBase -Force | Out-Null
            Write-Host "  Clonando repo maestro..." -NoNewline
            git clone --depth 1 $RepoUrl $tempBase 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host " ERROR" -ForegroundColor Red
                throw "No se pudo clonar el repo maestro $RepoUrl (verifica git y URL)."
            }
            Write-Host " OK" -ForegroundColor Green
            $ownsTemp = $true
            $stageKitRoot = $tempBase
            $commitHash = (git -C $tempBase rev-parse --short HEAD 2>$null)
            if (-not $commitHash) { $commitHash = "desconocido" }
            $commitDate = (git -C $tempBase log -1 --format=%ci 2>$null)
            if (-not $commitDate) { $commitDate = (Get-Date).ToString("o") }
            Write-Info "Version repo maestro: $commitHash ($commitDate)"
        } catch {
            Write-Fail "sync-kit-agents F1: $_"
            Show-ExecutionSummary -Title "sync-kit-agents"
            exit 1
        }
    }
}

# [021] Asegurar gitignore de .kit-sync-temp/ en el destino (append idempotente).
$gitignorePath = Join-Path $RootPath ".gitignore"
if ($DryRun) {
    Write-Info "DryRun: aseguraria regla .kit-sync-temp/ en .gitignore (sin escribir)"
} else {
    try {
        $gitText = ""
        if (Test-Path -LiteralPath $gitignorePath -PathType Leaf) {
            $gitText = Get-Content -LiteralPath $gitignorePath -Raw -ErrorAction Stop
        }
        if ($gitText -notmatch '(?m)^\.kit-sync-temp/') {
            Add-Content -LiteralPath $gitignorePath -Value "`n.kit-sync-temp/`n" -Encoding UTF8
            Write-OK ".gitignore: regla .kit-sync-temp/ agregada."
        } else {
            Write-Info ".gitignore: regla .kit-sync-temp/ ya presente (idempotente)."
        }
    } catch {
        Write-Warn "sync-kit-agents: no se pudo asegurar .gitignore ($_); se continua."
    }
}

# =============================================================================
# [021] F2 SYNC (invocar cada capa con &, recolectar lineas RESULT:)
# =============================================================================
Write-Step "sync-kit-agents: F2 SYNC"

$results = @()
if ($DryRun -and (-not $KitPath)) {
    # [021] DryRun sin KitPath: no hay stage real; solo se informa el plan.
    foreach ($layer in $script:Layers) {
        if ($activeLayers -notcontains $layer.Name) { continue }
        Write-Info "DryRun: ejecutaria capa $($layer.Name) ($($layer.Script) -StageDir <stage> -RootPath $RootPath)"
    }
} else {
    foreach ($layer in $script:Layers) {
        if ($activeLayers -notcontains $layer.Name) { continue }
        $scriptPath = Join-Path $PSScriptRoot $layer.Script
        Write-Step "Capa $($layer.Name): $scriptPath"
        try {
            # [021] Invocacion con & (no dot-source): cada capa es proceso hijo
            # [021] con su propio scope; la comunicacion es via lineas RESULT:.
            # [021] -Force solo se pasa a las capas que lo declaran (harnesses).
            # [021] Las capas emiten RESULT: via Write-Host (stream informacion 6):
            # [021] se fusiona todo a stdout con *>&1 para recolectar el reporte.
            # [021] Fase 3: mcp-install es portable por maquina (NoStage) y se
            # [021] invoca solo con -RootPath (sin -StageDir).
            if ($layer.NoStage) {
                $out = @(& $scriptPath -RootPath $RootPath -DryRun:$DryRun -Force:$Force *>&1)
            } elseif ($layer.AcceptsForce) {
                $out = @(& $scriptPath -StageDir $stageKitRoot -RootPath $RootPath -DryRun:$DryRun -Force:$Force *>&1)
            } else {
                $out = @(& $scriptPath -StageDir $stageKitRoot -RootPath $RootPath -DryRun:$DryRun *>&1)
            }
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                Write-Warn "sync-kit-agents: capa $($layer.Name) salio con codigo $LASTEXITCODE; se continua con las demas (fail-open)."
            }
            foreach ($line in $out) { Write-Host "$line" }
            foreach ($line in ($out | Where-Object { "$_".StartsWith("RESULT:") })) {
                $results += "$line".Trim()
            }
        } catch {
            Write-Warn "sync-kit-agents: capa $($layer.Name) fallo ($_); se continua con las demas (fail-open)."
            continue
        }
    }
}

# =============================================================================
# [021] F3 PLATAFORMAR (fase 1: placeholder operativo, no funcional)
# =============================================================================
Write-Info "Fase Plataformar: pendiente fases 3-4 (mcp/indexing/externals)"

# =============================================================================
# [021] F4 VERIFY (.kit-last-sync.json; NO se escribe en DryRun)
# =============================================================================
$runDate = (Get-Date).ToString("o")
if ($DryRun) {
    Write-Info "DryRun: escribiria $RootPath/.kit-last-sync.json (sin escribir)"
} else {
    try {
        $report = [ordered]@{
            tool   = "sync-kit-agents"
            phase  = 2
            commit = $commitHash
            date   = $runDate
            layers = $activeLayers
            results = $results
        }
        $reportPath = Join-Path $RootPath ".kit-last-sync.json"
        ($report | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $reportPath -Encoding UTF8
        Write-OK "Reporte escrito: $reportPath"
    } catch {
        Write-Warn "sync-kit-agents F4: no se pudo escribir .kit-last-sync.json ($_)."
    }
}

# =============================================================================
# [021] F5 FLAG (restart si alguna capa de agents reporto cambios; NO en DryRun)
# =============================================================================
$agentsChanged = @($results | Where-Object { $_ -match '^RESULT:(github|opencode|vscode):(ok|creado)$' }).Count -gt 0
$flagPath = Join-Path $RootPath ".kit-restart-required"
if ($DryRun) {
    Write-Info "DryRun: gestionaria flag .kit-restart-required (cambios en agents: $agentsChanged; sin escribir)"
} else {
    try {
        if ($agentsChanged) {
            "RESTART:VSCODE $runDate" | Set-Content -LiteralPath $flagPath -Encoding UTF8
            Write-Warn "Cambios en agents: flag de restart escrito en $flagPath"
        } elseif (Test-Path -LiteralPath $flagPath -PathType Leaf) {
            Remove-Item -LiteralPath $flagPath -Force
            Write-OK "Sin cambios en agents: flag de restart eliminado."
        } else {
            Write-Info "Sin cambios en agents: no se requiere restart."
        }
    } catch {
        Write-Warn "sync-kit-agents F5: no se pudo gestionar el flag ($_)."
    }
}

# [021] Limpieza del temp en exito; se conserva en fallo (forense, spec RF-08).
if ($ownsTemp -and $tempBase -and (Test-Path -LiteralPath $tempBase)) {
    $hasErrors = $script:Errors.Count -gt 0
    if (-not $hasErrors) {
        Remove-Item -LiteralPath $tempBase -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Temp de stage limpiado ($tempBase)."
    } else {
        Write-Warn "Temp de stage conservado para forense ($tempBase) por errores en la corrida."
    }
}

Show-ExecutionSummary -Title "sync-kit-agents"
