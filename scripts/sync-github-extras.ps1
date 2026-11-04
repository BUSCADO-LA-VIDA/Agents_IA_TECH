#!/usr/bin/env powershell
#requires -Version 7.0
# sync-github-extras.ps1 — Capa .github extras (rules, prompts, workflows, copilot-instructions.md)
# Parámetros: -StageDir, -RootPath, -DryRun, -Force, -Kind
# Emite RESULT:github-extras:<kind>:<estado> por cada -Kind procesado.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$StageDir,

    [Parameter(Mandatory=$true)]
    [string]$RootPath,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$true)]
    [ValidateSet('rules','prompts','workflows','copilot')]
    [string]$Kind
)

# Dot-source de logging compartido (spec 021) — scripts/sync/lib/common.ps1
. "$PSScriptRoot/sync/lib/common.ps1"
Initialize-SyncLog

# [036-T053] Contador de cambios que se harían en modo DryRun por -Kind.
# SC-008 exige que el dry-run reporte un número concreto de archivos que
# cambiarían (no "se sincronizarían"). Este contador se incrementa por cada
# archivo que el dry-run detecte como nuevo o divergente.
$script:dryRunCambios = 0

# ---- Validación de rutas ----
if (-not (Test-Path -LiteralPath $StageDir -PathType Container)) {
    Write-Fail "StageDir no existe o no es un directorio: ${StageDir}"
    exit 1
}
if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
    Write-Fail "RootPath no existe o no es un directorio: ${RootPath}"
    exit 1
}

# Función auxiliar: emitir RESULT y registrar
function emit-Resultado {
    param([string]$Estado)
    $resultado = "RESULT:github-extras:${Kind}:${Estado}"
    Write-Info $resultado
    # También agregamos al log de sync si corresponde
    if ($Estado -ne 'sin-cambios') {
        $script:Errors.Add($Resultado) | Out-Null
    }
}

# Función auxiliar: sincronizar un directorio completo (clean copy)
function Sync-Directory {
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [string]$KindName
    )

    if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
        Write-Warn "Source directory not found under StageDir: ${SourceDir} (kind: $KindName)"
        return 'omitido-item'
    }

    if (-not (Test-Path -LiteralPath $DestDir -PathType Container)) {
        # Crear directorio destino si no existe
        if ($DryRun) {
            Write-Info "DryRun: crearía directorio $DestDir"
            return 'creado'
        }
        try {
            # Backup si el directorio destino ya tiene contenido y no es dry-run
            if (-not $Force -and (Get-ChildItem -Path $DestDir -ErrorAction SilentlyContinue)) {
                $timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
                $backupPath = "$DestDir.bak-$timestamp"
                Copy-Item -Path $DestDir -Destination $backupPath -Recurse -Force -ErrorAction Stop
                Write-Info "Backup creado: $backupPath"
            }
            Invoke-Expression "Copy-Item -Path '$SourceDir' -Destination '$DestDir' -Recurse -Force"
            Write-OK "Sincronizado directorio: $DestDir (kind: $KindName)"
            return 'ok'
        } catch {
            Write-Fail "Error sincronizando ${SourceDir} a ${DestDir}: ${_}"
            return 'error'
        }
    }

    # Directorios existentes: comparar y hacer merge/clean
    $sourceFiles = Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction SilentlyContinue
    $destFiles = Get-ChildItem -Path $DestDir -Recurse -File -ErrorAction SilentlyContinue
    $changed = $false

    foreach ($srcFile in $sourceFiles) {
        $relPath = $srcFile.FullName.Substring($SourceDir.Length).TrimStart('\','/')
        $dstFile = Join-Path $DestDir $relPath

        if (-not (Test-Path -LiteralPath $dstFile)) {
            # Nuevo archivo — copiar
            if ($DryRun) {
                Write-Info "DryRun: crearía ${dstFile}"
                $changed = $true
                $script:dryRunCambios++
            } else {
                try {
                    $srcDir = Split-Path -Parent $srcFile.FullName
                    $dstDir = Split-Path -Parent $dstFile
                    if (-not (Test-Path -LiteralPath $dstDir)) { mkdir $dstDir -Force }
                    Copy-Item -Path $srcFile.FullName -Destination $dstFile -Force -ErrorAction Stop
                    Write-OK "Copiado nuevo archivo: $dstFile"
                } catch {
                    Write-Fail "Error copiando ${srcFile} a ${dstFile}: ${_}"
                    return 'error'
                }
            }
        } else {
            # Archivo existente — comparar contenido
            try {
                $srcContent = Get-Content -Path $srcFile.FullName -Raw
                $dstContent = Get-Content -Path $dstFile -Raw
                if ($srcContent -ne $dstContent) {
                    if ($DryRun) {
                        Write-Info "DryRun: $dstFile difiere (se sobreescribiría)"
                        $changed = $true
                        $script:dryRunCambios++
                    } else {
                        try {
                            # Backup antes de sobrescribir
                            $timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
                            $backupPath = "$dstFile.bak-$timestamp"
                            Copy-Item -Path $dstFile -Destination $backupPath -Force -ErrorAction Stop
                            Copy-Item -Path $srcFile.FullName -Destination $dstFile -Force -ErrorAction Stop
                            Write-OK "Sincronizado archivo: $dstFile (kind: $KindName)"
                        } catch {
                            Write-Fail "Error haciendo backup/sobreescritura de ${dstFile}: ${_}"
                            return 'error'
                        }
                    }
                } else {
                    Write-Info "Archivo idéntico: $dstFile (kind: $KindName)"
                }
            } catch {
                Write-Warn "No se pudo comparar ${srcFile} y ${dstFile}: ${_}"
            }
        }
    }

    # Verificar archivos de destino que ya no existen en source (opcional: podar)
    # Por ahora solo nos preocupamos de copiar desde source hacia dest

    if ($changed) {
        return 'ok'
    }
    return 'sin-cambios'
}

# Función auxiliar: sincronizar un archivo único
function Sync-File {
    param(
        [string]$SourceFile,
        [string]$DestFile,
        [string]$KindName
    )

    if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
        Write-Warn "Source file not found: $SourceFile (kind: $KindName)"
        return 'omitido-item'
    }

    $dstDir = Split-Path -Parent $DestFile
    if (-not (Test-Path -LiteralPath $dstDir)) {
        if ($DryRun) {
            Write-Info "DryRun: crearía directorio $dstDir"
        } else {
            mkdir $dstDir -Force
            Write-OK "Creado directorio: $dstDir"
        }
    }

    if ($DryRun) {
        Write-Info "DryRun: copiaría ${SourceFile} a ${DestFile} (kind: $KindName)"
        $script:dryRunCambios++
        return 'creado'
    }

    try {
        # Backup si el destino ya existe
        if (Test-Path -LiteralPath $DestFile) {
            $timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
            $backupPath = "$DestFile.bak-$timestamp"
            Copy-Item -Path $DestFile -Destination $backupPath -Force -ErrorAction Stop
            Write-Info "Backup creado: $backupPath"
        }
        Copy-Item -Path $SourceFile -Destination $DestFile -Force -ErrorAction Stop
        Write-OK "Sincronizado archivo: $DestFile (kind: $KindName)"
        return 'ok'
    } catch {
        Write-Fail "Error sincronizando ${SourceFile} a ${DestFile}: ${_}"
        return 'error'
    }
}

# --- Lógica por -Kind ---
$resultadoGlobal = 'ok'

switch -Wildcard ($Kind) {
    'rules' {
        Write-Step "Sincronizando .github/rules/ (Kind=rules)"
        $srcDir = Join-Path $StageDir '.github/rules'
        $dstDir = Join-Path $RootPath '.github/rules'
        $estado = Sync-Directory -SourceDir $srcDir -DestDir $dstDir -KindName 'rules'
        if ($estado -ne 'ok' -and $estado -ne 'sin-cambios') {
            $resultadoGlobal = 'error'
        }
        emit-Resultado -Estado $estado
    }

    'prompts' {
        Write-Step "Sincronizando .github/prompts/ (Kind=prompts)"
        $srcDir = Join-Path $StageDir '.github/prompts'
        $dstDir = Join-Path $RootPath '.github/prompts'
        $estado = Sync-Directory -SourceDir $srcDir -DestDir $dstDir -KindName 'prompts'
        if ($estado -ne 'ok' -and $estado -ne 'sin-cambios') {
            $resultadoGlobal = 'error'
        }
        emit-Resultado -Estado $estado
    }

    'workflows' {
        Write-Step "Sincronizando .github/workflows/ (Kind=workflows)"
        $srcDir = Join-Path $StageDir '.github/workflows'
        $dstDir = Join-Path $RootPath '.github/workflows'
        $estado = Sync-Directory -SourceDir $srcDir -DestDir $dstDir -KindName 'workflows'
        if ($estado -ne 'ok' -and $estado -ne 'sin-cambios') {
            $resultadoGlobal = 'error'
        }
        emit-Resultado -Estado $estado
    }

    'copilot' {
        Write-Step "Sincronizando .github/copilot-instructions.md (Kind=copilot)"
        $srcFile = Join-Path $StageDir '.github/copilot-instructions.md'
        $dstFile = Join-Path $RootPath '.github/copilot-instructions.md'
        $estado = Sync-File -SourceFile $srcFile -DestFile $dstFile -KindName 'copilot'
        if ($estado -ne 'ok' -and $estado -ne 'sin-cambios' -and $estado -ne 'creado') {
            $resultadoGlobal = 'error'
        }
        emit-Resultado -Estado $estado
    }
}

# Resumen y salida
if ($DryRun) {
    Write-OK "RESULT:github-extras:${Kind}:cambios=$($script:dryRunCambios)"
    Write-Info "DryRun completado para Kind=${Kind}: $($script:dryRunCambios) archivo(s) cambiarían. No se escribieron archivos."
} else {
    Write-OK "Sync github-extras finalizado para Kind=${Kind}. Resultado global: $resultadoGlobal"
}

exit 0