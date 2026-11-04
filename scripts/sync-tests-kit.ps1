#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [036-T008] scripts/sync-tests-kit.ps1 — Capa de whitelist de tests del kit
# =============================================================================
# Whitelist de tests del kit que se sincronizan desde StageDir a RootPath.
# 5 tests definidos: harness-default, kit-sync-merge, agents-parity,
# kb-parity, mcp-refresh-parity.
#
# [036-T004-D4] La whitelist viaja en la capa del orquestador (declarada en
# $script:Layers de sync-kit.ps1), no solo en el motor deprecado.
#
# [036-T005-D4] Si un test del proyecto colisiona por nombre con uno del kit,
# el del kit gana y el del proyecto se respalda (renombra con .bak-<timestamp>)
# ANTES de reemplazarse. Los tests fuera de la whitelist NUNCA se borran.
#
# Contrato de salida: emite RESULT:tests-kit:<estado> y exit 0 si no hubo
# error, exit 1 si hubo fallos de copiado.
# =============================================================================

# --- Parámetros del script ---
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$StageDir,
    [string]$RootPath,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Dot-sourcing de logging compartido ---
. "$PSScriptRoot/sync/lib/common.ps1"
Initialize-SyncLog

# --- Whitelist de tests del kit (5 tests, rutas relativas desde RootPath) ---
$kitTestWhitelist = @(
    "tests/harness-default.ps1"
    "tests/kit-sync-merge.ps1"
    "tests/agents-parity.ps1"
    "tests/kb-parity.ps1"
    "tests/mcp-refresh-parity.ps1"
)

# --- Resolución de raíces ---
if (-not $RootPath) { $RootPath = (Split-Path -Parent $PSScriptRoot) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-tests-kit: -RootPath invalido ($RootPath): $_"; exit 1 }
if (-not $StageDir) { $StageDir = $RootPath }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "sync-tests-kit: -StageDir invalido ($StageDir): $_"; exit 1 }

# --- Función auxiliar: ruta destino de un test ---
# La whitelist ya lleva el prefijo "tests/", así que el destino es RootPath + rel.
function Get-TestDestinationPath {
    param([string]$TestRelativePath)
    return Join-Path $RootPath $TestRelativePath
}

# --- Inicio del proceso de sincronización ---
Write-Step "Iniciando sincronización de tests del kit desde StageDir: $StageDir a RootPath: $RootPath"
if ($DryRun) { Write-Info "sync-tests-kit: modo DryRun (sin escrituras)." }

$resultadoGlobal = "ok"
$testsCopiados = 0
$testsNoExistentes = 0
$testsOmitidos = 0
$testsError = 0
$testsRespaldados = 0

# --- Verificar que StageDir existe ---
$huboErrorTemprano = $false
if (-not (Test-Path -LiteralPath $StageDir -PathType Container)) {
    Write-Fail "StageDir no existe o no es un directorio: $StageDir"
    $resultadoGlobal = "error"
    $huboErrorTemprano = $true
}

if (-not $huboErrorTemprano) {
    # --- Probar cada test de la whitelist ---
    foreach ($testRelPath in $kitTestWhitelist) {
        $stageTestPath = Join-Path $StageDir $testRelPath
        $destTestPath = Get-TestDestinationPath -TestRelativePath $testRelPath

        # Si Stage y destino son la misma ruta, no hay copia que hacer.
        $stageTestPathNorm = [System.IO.Path]::GetFullPath($stageTestPath)
        $destTestPathNorm = [System.IO.Path]::GetFullPath($destTestPath)
        $esMismoArchivo = ($stageTestPathNorm -eq $destTestPathNorm)

        if (-not (Test-Path -LiteralPath $stageTestPath -PathType Leaf)) {
            Write-Info "Test no encontrado en Stage (se omite): $testRelPath"
            $testsNoExistentes++
            continue
        }

        # Directorio destino tests/ puede no existir aún
        $destTestsDir = Split-Path -Parent $destTestPath
        if (-not (Test-Path -LiteralPath $destTestsDir -PathType Container)) {
            if ($DryRun) {
                Write-Info "DryRun: crearia directorio $destTestsDir"
            } else {
                $null = New-Item -ItemType Directory -Path $destTestsDir -Force
                Write-OK "Directorio de tests creado: $destTestsDir"
            }
        }

        # --- Idempotencia: si el destino ya tiene el contenido del kit, no tocar.
        # Se compara el hash (patrón de la capa skills): backup SOLO ante divergencia.
        $yaSincronizado = $false
        if (Test-Path -LiteralPath $destTestPath -PathType Leaf) {
            $hStage = (Get-FileHash -LiteralPath $stageTestPath -Algorithm SHA256 -ErrorAction Stop).Hash
            $hDest = (Get-FileHash -LiteralPath $destTestPath -Algorithm SHA256 -ErrorAction Stop).Hash
            $yaSincronizado = ($hStage -eq $hDest)
        }

        if ($esMismoArchivo -or $yaSincronizado) {
            # Sin cambios que aplicar (mismo archivo o ya al día con el kit).
            Write-Info "Test ya al día (sin cambios): $testRelPath"
            $testsOmitidos++
            continue
        }

        # [036-T005-D4] Colisión de nombre en destino: el del kit gana y el del
        # proyecto se respalda (.bak-<timestamp>) ANTES de reemplazar.
        $colisiona = (Test-Path -LiteralPath $destTestPath -PathType Leaf)
        if ($colisiona) {
            if ($Force -or $PSCmdlet.ShouldProcess($destTestPath, "ser reemplazado por $testRelPath")) {
                # Respaldo con timestamp ANTES de reemplazar.
                $timestamp = (Get-Date -Format 'yyyyMMddTHHmmss')
                $backupPath = "$destTestPath.bak-$timestamp"
                try {
                    if ($DryRun) {
                        Write-Info "DryRun: respaldaria $(Split-Path -Leaf $destTestPath) -> $(Split-Path -Leaf $backupPath)"
                    } else {
                        Copy-Item -LiteralPath $destTestPath -Destination $backupPath -Force
                        Write-Info "Backup creado: $(Split-Path -Leaf $backupPath)"
                    }
                    $testsRespaldados++
                } catch {
                    Write-Warn "No se pudo crear backup de ${destTestPath}: $_"
                }
            } else {
                # Sin -Force ni confirmación: conservar el existente (omitir).
                Write-Info "Test ya existe en destino (no Force/fin de ShouldProcess): $testRelPath"
                $testsOmitidos++
                continue
            }
        }

        # Registrar el cambio real (local o de destino) para el estado final.
        $testsCopiados++

        if ($DryRun) {
            Write-Info "DryRun: copiaria $stageTestPath -> $destTestPath"
            continue
        }

        # Copiar desde StageDir a destino.
        try {
            Copy-Item -LiteralPath $stageTestPath -Destination $destTestPath -Force
            Write-OK "Test copiado: $testRelPath"
        } catch {
            Write-Fail "Error copiando ${testRelPath}: $_"
            $testsError++
            $testsCopiados--
            $resultadoGlobal = "error"
        }
    }
}

# --- Determinar estado final ---
if ($huboErrorTemprano) {
    # Error de arranque (StageDir inválido): mantener 'error' y salir ≠ 0.
    $resultadoGlobal = "error"
} elseif ($testsError -gt 0) {
    $resultadoGlobal = "error"
} elseif ($testsNoExistentes -eq $kitTestWhitelist.Count) {
    # Todos los tests faltaron en Stage -> no es error, solo info
    $resultadoGlobal = "sin-cambios"
} elseif ($testsCopiados -gt 0) {
    # Hubo al menos un test nuevo o reemplazado -> 'creado'.
    Write-Info "Sincronización completada: $testsCopiados test(s) copiados/reemplazados, $testsNoExistentes no existían en Stage, $testsOmitidos ya al día/omitidos, $testsRespaldados respaldado(s)."
    $resultadoGlobal = "creado"
} else {
    # Todo ya al día (idempotencia): segunda corrida sin cambios.
    Write-Info "Sincronización sin cambios: los $($kitTestWhitelist.Count) tests ya están al día."
    $resultadoGlobal = "sin-cambios"
}

# --- Emitir resultado ---
Write-Step "Emitiendo RESULT:tests-kit:$resultadoGlobal"
Write-OK "RESULT:tests-kit:$resultadoGlobal"
# [036-T053] SC-008: el dry-run debe reportar un número concreto de archivos
# que cambiarían (los `testsCopiados` = test(s) a copiar/reemplazar).
if ($DryRun) {
    Write-OK "RESULT:tests-kit:cambios=$testsCopiados"
    Write-Info "DryRun tests-kit: $testsCopiados test(s) cambiarían. No se escribieron archivos."
}
Show-ExecutionSummary -Title "sync-tests-kit"

# --- Salir con código de retorno acorde ---
if ($resultadoGlobal -eq "error") {
    exit 1
} else {
    exit 0
}
