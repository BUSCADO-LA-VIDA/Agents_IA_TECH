#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/externals/resolve-externals.ps1
# [021] Capa "externals" del sync por capas (spec 021-sync-kit-agents, fase 4,
# [021] T012, RF-02/RF-06). Envuelve los modulos scripts/modules/Manifest/
# [021] (ManifestManager: Ensure-DependenciasManifest + Sync-Manifest con
# [021] cirugia de lineas; ManifestReference: referencia en
# [021] proyect_ext/dependencias-manifest.yml; YamlHelper: parseo YAML) +
# [021] Invoke-UpgradeFramework del bootstrap
# [021] (plataformador-bootstrap.ps1:1937, mismos flags -RootPath /
# [021] -ForceUpgradeTools / -DryRun sobre upgrade_framework.ps1) + re-integra
# [021] contenido seleccionado con copia al KIT via
# [021] scripts/sync/skills/sync-skills.ps1 (patron copia+tag con HEAD, mismo
# [021] que integra skills ECC: el contenido copiado viaja en git).
# [021] Modelo 2026-10-16: externo (proyect_ext/, gitignored) = cache de
# [021] descarga; lo integrado viaja en git. NUNCA se copia proyect_ext/
# [021] entero a destinos: solo lecturas de referencia + copias selectivas con
# [021] tag de origen. NO recibe -StageDir (NoStage): opera sobre el destino ya
# [021] sincronizado. Fail-open por paso (WARN + continua). Respeta -DryRun
# [021] (cero escrituras). Sin -Force, Sync-Manifest solo informa drift y
# [021] upgrade_framework se omite (patron bootstrap:1949-1952: sin -Force no
# [021] hay sync de dependencias). Emite RESULT:externals:<ok|sin-cambios|
# [021] omitido-warn> (agregado de la capa).
# [021] NOTA hooks: ManifestHooks/Invoke-PostUpdateHooks (reindex tras update)
# [021] NO se invoca aqui a proposito: el reindex lo posee la capa indexing
# [021] (evita doble indexacion en la misma corrida del orquestador).
# =============================================================================

[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# [021] Default: raiz del repo (scripts/sync/externals/ -> 3 niveles arriba).
if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "externals: -RootPath invalido ($RootPath): $_"; exit 1 }

# [021] Raiz del KIT (esta capa vive en el checkout sincronizado): de ahi
# [021] salen los modulos Manifest y el script de re-integracion selectiva.
$kitRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))

Write-Step "externals: resolviendo dependencias del manifest en $RootPath"

$applied = 0
$warned = 0

# =============================================================================
# [021] Paso 1: Sync-Manifest (reporte de drift; -Apply solo con -Force).
# [021] Sin referencia en proyect_ext/ -> fail-open (WARN, sin tocar nada).
# =============================================================================
try {
    $manifestMod = Join-Path $kitRoot "scripts/modules/Manifest/ManifestManager.psm1"
    if (-not (Test-Path -LiteralPath $manifestMod -PathType Leaf)) { throw "modulo no encontrado: $manifestMod" }
    Import-Module $manifestMod -Force -DisableNameChecking
    $localManifest = Join-Path $RootPath "dependencias-manifest.yml"
    if (-not (Test-Path -LiteralPath $localManifest -PathType Leaf)) {
        if ($DryRun) {
            Write-Info "DryRun: crearia $localManifest desde la referencia (sin escribir)"
        } else {
            Ensure-DependenciasManifest -RootPath $RootPath | Out-Null
        }
    }
    if ((Test-Path -LiteralPath $localManifest -PathType Leaf) -or (-not $DryRun)) {
        $report = Sync-Manifest -RootPath $RootPath -Apply:$Force -DryRun:$DryRun
        if ($report.Applied -gt 0) { $applied += $report.Applied }
        if (@($report.Details | Where-Object { $_ -like 'sin-referencia*' }).Count -gt 0) {
            Write-Warn "externals: sin manifest de referencia en proyect_ext/ (se omite sync de versiones; fail-open)."
            $warned++
        } elseif (-not $Force -and $report.Differ -gt 0) {
            Write-Info "externals: drift de $($report.Differ) herramienta(s) pendiente(s) de -Force (solo informado)."
        }
    } else {
        Write-Warn "externals: sin manifest local ni referencia (DryRun: nada que comparar)."
        $warned++
    }
} catch {
    Write-Warn "externals: Sync-Manifest omitido ($_); se continua (fail-open)."
    $warned++
}

# =============================================================================
# [021] Paso 2: re-integracion selectiva con copia+tag (sync-skills, patron
# [021] ECC: fachada SSD + bloque anexado con HEAD; espejo .github -> .opencode;
# [021] rules con tag). Hijo con & (scope propio); se re-emite su salida y su
# [021] RESULT:skills: para trazabilidad. Fail-open si falta o falla.
# =============================================================================
try {
    $skillsScript = Join-Path $kitRoot "scripts/sync/skills/sync-skills.ps1"
    if (-not (Test-Path -LiteralPath $skillsScript -PathType Leaf)) {
        Write-Warn "externals: sin script de re-integracion ($skillsScript); se omite el paso (fail-open)."
        $warned++
    } else {
        Write-Step "externals: re-integrando contenido seleccionado (sync-skills)..."
        # [021] Subproceso aislado (pwsh -File, como upgrade_framework abajo):
        # [021] sync-skills.ps1 usa `exit 1` al fallar y el `exit` en sesion
        # [021] contamina el $LASTEXITCODE del llamador de forma no
        # [021] normalizable (verificado empiricamente); en subproceso el exit
        # [021] queda contenido y el fail-open se maneja aqui con WARN.
        $out = @(pwsh -NoProfile -File $skillsScript -RootPath $RootPath -DryRun:$DryRun -Force:$Force 2>&1)
        foreach ($line in $out) { Write-Host "$line" }
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Write-Warn "externals: sync-skills salio con codigo $LASTEXITCODE (fail-open: se continua)."
            $warned++
            # [021] NOTA: no se normaliza $LASTEXITCODE aqui: la asignacion
            # [021] seria local a este script (se descarta al retornar); lo
            # [021] hace el orquestador tras cada capa.
        } else {
            $rl = @($out | Where-Object { "$_".StartsWith("RESULT:skills:") } | Select-Object -First 1)
            if ($rl.Count -gt 0 -and "$($rl[0])" -match 'integradas=(\d+)') { $applied += [int]$matches[1] }
        }
    }
} catch {
    Write-Warn "externals: re-integracion omitida ($_); se continua (fail-open)."
    $warned++
}

# =============================================================================
# [021] Paso 3: upgrade_framework (patron Invoke-UpgradeFramework del
# [021] bootstrap:1937-2006: copia manifest plantilla si falta, resuelve
# [021] upgrade_framework.ps1 en RootPath, invoca con -RootPath /
# [021] -ForceUpgradeTools / -DryRun, fail-open con exit code ignorado).
# =============================================================================
try {
    $upgradeScript = Join-Path $RootPath "upgrade_framework.ps1"
    if ((-not $Force) -and (-not $DryRun)) {
        Write-Info "externals: sin -Force; se omite sync de dependencias (o directo: upgrade_framework.ps1 -ForceUpgradeTools)."
    } elseif (-not (Test-Path -LiteralPath $upgradeScript -PathType Leaf)) {
        Write-Warn "externals: script no encontrado en $upgradeScript; se omite (fail-open)."
        $warned++
    } elseif ($DryRun) {
        Write-Info "DryRun: ejecutaria: pwsh -NoProfile -File $upgradeScript -RootPath $RootPath -ForceUpgradeTools (sin escribir)"
    } else {
        Write-Info "externals: ejecutando: pwsh -NoProfile -File $upgradeScript -RootPath $RootPath -ForceUpgradeTools"
        $uout = @(pwsh -NoProfile -File $upgradeScript -RootPath $RootPath -ForceUpgradeTools 2>&1)
        foreach ($line in $uout) { Write-Host "  $line" }
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Write-Warn "externals: upgrade_framework termino con exit code $LASTEXITCODE (fail-open: se continua)."
            $warned++
        } else {
            Write-OK "externals: upgrade_framework completado."
            $applied++
        }
    }
} catch {
    Write-Warn "externals: upgrade_framework omitido ($_); se continua (fail-open)."
    $warned++
}

# =============================================================================
# [021] RESULT agregado: ok si algo se aplico; sin-cambios en DryRun o si nada
# [021] difiere; omitido-warn si algun paso se degrado (fail-open).
# =============================================================================
if ($DryRun) { $status = "sin-cambios" }
elseif ($applied -gt 0) { $status = "ok" }
elseif ($warned -gt 0) { $status = "omitido-warn" }
else { $status = "sin-cambios" }
Write-Host "RESULT:externals:$status"

Show-ExecutionSummary -Title "externals"
