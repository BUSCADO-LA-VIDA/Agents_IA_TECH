#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# scripts/sync/kit-block/sync-kit-block.ps1
# Capa "kit-block" del sync por capas (spec 036-T002). Merge por bloque
# delimitado KIT-BLOCK de AGENTS.md: reemplaza solo el tramo entre los
# marcadores KIT-BLOCK del maestro (Source), preservando el resto del archivo
# del proyecto (Destination). No toca nada fuera de $Destination.
#
# Funcion Merge-KitBlock extraida literalmente de scripts/sync-kit.ps1
# (lineas 725-856) y hecha autónoma: toda su lógica vive aqui.
#
# Estados devueltos: 'ok' | 'sin-cambios' | 'creado' | 'omitido-item'
# Emite RESULT:kit-block:<estado> en stdout.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [string]$BlockId = 'arranque-por-defecto'
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# Validacion de rutas obligatorias.
try { $Source = [IO.Path]::GetFullPath($Source) } catch {
    Write-Fail "sync-kit-block: -Source invalido ('$Source'): $_"
    exit 1
}
try { $Destination = [IO.Path]::GetFullPath($Destination) } catch {
    Write-Fail "sync-kit-block: -Destination invalido ('$Destination'): $_"
    exit 1
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
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [string]$BlockId = 'arranque-por-defecto'
    )

    $startMarker = "<!-- KIT-BLOCK:START $BlockId -->"
    $endMarker = "<!-- KIT-BLOCK:END $BlockId -->"

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Write-Warn "AGENTS.md: no existe la plantilla del maestro ($Source); se omite el merge del bloque."
        return 'omitido-item'
    }
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "  [FILE] AGENTS.md (copiado del maestro)" -ForegroundColor Cyan
        return 'creado'
    }

    $masterText = $null
    try {
        $masterText = [System.IO.File]::ReadAllText($Source)
    } catch {
        Write-Warn "AGENTS.md: no se pudo leer el maestro ($_); se omite el merge del bloque."
        return 'omitido-item'
    }

    # El maestro debe tener exactamente un START y un END, en ese orden.
    $mStartCount = ([regex]::Matches($masterText, [regex]::Escape($startMarker))).Count
    $mEndCount = ([regex]::Matches($masterText, [regex]::Escape($endMarker))).Count
    $mStartIdx = $masterText.IndexOf($startMarker, [System.StringComparison]::Ordinal)
    $mEndIdx = $masterText.IndexOf($endMarker, [System.StringComparison]::Ordinal)
    if (($mStartCount -ne 1) -or ($mEndCount -ne 1) -or ($mStartIdx -lt 0) -or ($mEndIdx -lt 0) -or ($mStartIdx -ge $mEndIdx)) {
        Write-Warn "AGENTS.md: bloque '$BlockId' del maestro sin marcadores KIT-BLOCK validos: no se modifica el local"
        return 'omitido-item'
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
        return 'omitido-item'
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
            return 'omitido-item'
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
        return 'omitido-item'
    }

    if ($newText -ceq $original) {
        Write-OK "  [OK] AGENTS.md - sin cambios (bloque al dia)"
        return 'sin-cambios'
    }

    # Backup junto al destino (patron ignorado por .gitignore: AGENTS.md.bak-*).
    $backupPath = "$Destination.bak-" + (Get-Date -Format 'yyyyMMddTHHmmss')
    try {
        Copy-Item -LiteralPath $Destination -Destination $backupPath -Force
    } catch {
        Write-Fail "AGENTS.md: no se pudo crear el backup ($_); no se escribe."
        return 'omitido-item'
    }

    try {
        $encoding = [System.Text.UTF8Encoding]::new($hadBom)
        [System.IO.File]::WriteAllText($Destination, $newText, $encoding)
        Write-OK "  [OK] AGENTS.md - bloque '$BlockId' actualizado (backup: $(Split-Path -Leaf $backupPath))"
        return 'ok'
    } catch {
        Copy-Item -LiteralPath $backupPath -Destination $Destination -Force
        Write-Fail "AGENTS.md: no se pudo escribir el bloque ($_); se restauro el backup."
        return 'omitido-item'
    }
}

Write-Step "sync-kit-block: merge de bloque KIT-BLOCK '$BlockId' en $Destination"

$estado = 'omitido-item'
try {
    $estado = Merge-KitBlock -Source $Source -Destination $Destination -BlockId $BlockId
    if (-not $estado) { $estado = 'omitido-item' }
} catch {
    Write-Fail "sync-kit-block: excepcion inesperada ($_); no se escribe (fail-closed)."
    $estado = 'omitido-item'
}

Write-Host "RESULT:kit-block:$estado"
Show-ExecutionSummary -Title "sync-kit-block"
