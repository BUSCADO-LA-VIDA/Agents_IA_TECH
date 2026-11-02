#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/lib/common.ps1
# [021] Logging + resumen compartidos del sync por capas (spec 021-sync-kit-agents).
# [021] Extraido literalmente de scripts/sync-kit.ps1 (lineas 45-78): Write-Info,
# [021] Write-Step, Write-OK, Write-Warn, Write-Fail, Write-WarnOnce y
# [021] Show-ExecutionSummary, adaptados para dot-sourcing.
# [021] Uso desde cada capa: . "$PSScriptRoot/../lib/common.ps1"; Initialize-SyncLog
# =============================================================================

$ErrorActionPreference = "Stop"

# [021] Inicializa las 3 listas de acumulacion en el scope script del LLAMADOR.
# [021] Como este archivo se importa con dot-sourcing, el cuerpo de la funcion
# [021] se ejecuta en el scope del llamador y `$script:` resuelve alli. Llamar
# [021] a Initialize-SyncLog una vez al inicio de cada script que lo importe.
function Initialize-SyncLog {
    $script:Warnings = [System.Collections.Generic.List[string]]::new()
    $script:Errors = [System.Collections.Generic.List[string]]::new()
    $script:EmittedWarns = [System.Collections.Generic.List[string]]::new()
}

# [021] Listas por defecto por si un script olvida llamar a Initialize-SyncLog.
if (-not (Get-Variable -Name Warnings -Scope Script -ErrorAction SilentlyContinue)) {
    $script:Warnings = [System.Collections.Generic.List[string]]::new()
}
if (-not (Get-Variable -Name Errors -Scope Script -ErrorAction SilentlyContinue)) {
    $script:Errors = [System.Collections.Generic.List[string]]::new()
}
if (-not (Get-Variable -Name EmittedWarns -Scope Script -ErrorAction SilentlyContinue)) {
    $script:EmittedWarns = [System.Collections.Generic.List[string]]::new()
}

# =============================================================================
# [021] Logging (copia literal de sync-kit.ps1, sin cambios de semantica)
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

# [021] Resumen final. Unico cambio respecto a sync-kit.ps1: titulo parametrizable
# [021] (por defecto "sync-kit-agents" para el orquestador nuevo).
function Show-ExecutionSummary {
    param([string]$Title = "sync-kit-agents")
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " RESUMEN DE LA EJECUCION ($Title)" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " WARNs: $($uniqueWarns.Count)"
    foreach ($w in $uniqueWarns) { Write-Host "   - $w" }
    Write-Host " ERRORs: $($uniqueErrors.Count)"
    foreach ($e in $uniqueErrors) { Write-Host "   - $e" }
    Write-Host "===============================================================" -ForegroundColor Yellow
}

# =============================================================================
# [021-FIX] Merge por bloque delimitado (KIT-BLOCK) de AGENTS.md.
#
# Motivo: la capa kit-files hacia `Copy-Item -Force` sobre AGENTS.md, que es un
# archivo COMPARTIDO (reglas del kit + texto propio de cada proyecto). Eso
# destruia el contenido del proyecto en cada sync del motor por capas. Este
# helper lo COMPLEMENTA: reemplaza solo el tramo entre marcadores y conserva
# todo lo demas.
#
# Implementacion derivada de Merge-KitBlock de scripts/sync-kit.ps1 (spec 034),
# con dos diferencias deliberadas:
#   1. Soporta MULTIPLES bloques KIT-BLOCK en el maestro (aplica todos).
#   2. Devuelve un estado para que el llamador pueda agregarlo al RESULT.
#
# Estados devueltos: 'sin-cambios' | 'ok' | 'creado' | 'omitido-item'
#   - 'omitido-item': no se pudo complementar (fail-closed, el destino NO se
#     toca). Se emite WARN, igual que Merge-KitBlock en sync-kit.ps1.
#
# Garantias:
#   - Preserva BOM y estilo de fin de linea (LF/CRLF) del destino.
#   - Idempotente: segunda pasada deja el archivo byte-identico.
#   - Fail-closed ante marcadores corruptos: START sin END, END sin START,
#     duplicados o desordenados -> no se escribe nada.
# =============================================================================
function Merge-KitBlockFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [switch]$Simulate
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Write-Warn "merge-kit-block: no existe la plantilla del maestro ($Source); el destino no se toca."
        return 'omitido-item'
    }
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        if ($Simulate) {
            Write-Info "DryRun: crearia $Destination desde el maestro"
            return 'creado'
        }
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-OK "AGENTS.md creado desde el maestro."
        return 'creado'
    }

    $masterText = $null
    try { $masterText = [System.IO.File]::ReadAllText($Source) }
    catch {
        Write-Warn "merge-kit-block: no se pudo leer el maestro ($_); el destino no se toca."
        return 'omitido-item'
    }

    # --- Descubrir y validar los bloques del maestro -------------------------
    $startRx = [regex]'<!--\s*KIT-BLOCK:START\s+([A-Za-z0-9._:-]+)\s*-->'
    $ids = @($startRx.Matches($masterText) | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    if ($ids.Count -eq 0) {
        Write-Warn "merge-kit-block: el maestro no declara bloques KIT-BLOCK; el destino no se toca."
        return 'omitido-item'
    }

    $blocks = [ordered]@{}
    foreach ($id in $ids) {
        $sm = "<!-- KIT-BLOCK:START $id -->"
        $em = "<!-- KIT-BLOCK:END $id -->"
        $sc = ([regex]::Matches($masterText, [regex]::Escape($sm))).Count
        $ec = ([regex]::Matches($masterText, [regex]::Escape($em))).Count
        $si = $masterText.IndexOf($sm, [System.StringComparison]::Ordinal)
        $ei = $masterText.IndexOf($em, [System.StringComparison]::Ordinal)
        if (($sc -ne 1) -or ($ec -ne 1) -or ($si -lt 0) -or ($ei -lt 0) -or ($si -ge $ei)) {
            Write-Warn "merge-kit-block: bloque '$id' del maestro sin marcadores validos; se omite ese bloque."
            continue
        }
        # Bloque INCLUSIVE: del inicio de la linea del START al final del END.
        $blocks[$id] = $masterText.Substring($si, ($ei + $em.Length) - $si)
    }
    if ($blocks.Count -eq 0) {
        Write-Warn "merge-kit-block: ningun bloque del maestro es valido; el destino no se toca."
        return 'omitido-item'
    }

    # --- Leer destino preservando BOM y fin de linea -------------------------
    $dstBytes = $null
    $original = $null
    try {
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
        $original = [System.IO.File]::ReadAllText($Destination)
    } catch {
        Write-Warn "merge-kit-block: no se pudo leer el destino ($_): no se escribe (fail-closed)."
        return 'omitido-item'
    }
    $hadBom = ($dstBytes.Length -ge 3 -and $dstBytes[0] -eq 0xEF -and $dstBytes[1] -eq 0xBB -and $dstBytes[2] -eq 0xBF)
    $usesCrlf = $original.Contains("`r`n")
    $nl = if ($usesCrlf) { "`r`n" } else { "`n" }

    # Encabezado con el que se reconoce cada seccion cuando el destino aun no
    # tiene marcadores (migracion Caso B). Solo el prefijo, sin acentos, para no
    # depender de la codificacion con la que se leyo el archivo.
    $headerPatterns = @{
        'arranque-por-defecto' = [regex]'(?m)^##[ \t]+Arranque por defecto del arn'
    }

    $newText = $original
    $applied = 0

    foreach ($id in @($blocks.Keys)) {
        $sm = "<!-- KIT-BLOCK:START $id -->"
        $em = "<!-- KIT-BLOCK:END $id -->"

        $blockNorm = $blocks[$id] -replace "`r`n", "`n"
        if ($usesCrlf) { $blockNorm = $blockNorm -replace "`n", "`r`n" }

        $ds = ([regex]::Matches($newText, [regex]::Escape($sm))).Count
        $de = ([regex]::Matches($newText, [regex]::Escape($em))).Count

        if (($ds -eq 1) -and ($de -eq 1)) {
            # Caso A: marcadores presentes y unicos -> reemplazar el tramo.
            $sIdx = $newText.IndexOf($sm, [System.StringComparison]::Ordinal)
            $eIdx = $newText.IndexOf($em, [System.StringComparison]::Ordinal)
            if (($sIdx -lt 0) -or ($eIdx -lt 0) -or ($sIdx -ge $eIdx)) {
                Write-Warn "merge-kit-block: marcadores corruptos de '$id' en AGENTS.md: no se escribe (fail-closed)."
                return 'omitido-item'
            }
            $newText = $newText.Substring(0, $sIdx) + $blockNorm + $newText.Substring($eIdx + $em.Length)
            $applied++
        } elseif (($ds -eq 0) -and ($de -eq 0)) {
            # Caso B: seccion presente sin marcadores -> migrar y envolver.
            # Caso C: seccion ausente -> agregar al final.
            $headerRx = $headerPatterns[$id]
            $headerMatch = if ($headerRx) { $headerRx.Match($newText) } else { $null }
            if ($headerMatch -and $headerMatch.Success) {
                $afterHeader = $headerMatch.Index + $headerMatch.Length
                $nextHeaderMatch = ([regex]'(?m)^##[ \t]').Match($newText, $afterHeader)
                if ($nextHeaderMatch.Success) {
                    $newText = $newText.Substring(0, $headerMatch.Index) + $blockNorm + $nl + $nl + $newText.Substring($nextHeaderMatch.Index)
                } else {
                    $newText = $newText.Substring(0, $headerMatch.Index) + $blockNorm + $nl
                }
            } else {
                $trimmed = $newText.TrimEnd("`r", "`n")
                $newText = $trimmed + $nl + $nl + $blockNorm + $nl
                Write-Warn "AGENTS.md: seccion ausente: bloque '$id' agregado al final."
            }
            $applied++
        } else {
            # Caso D: START sin END, END sin START o duplicados -> fail-closed.
            Write-Warn "merge-kit-block: marcadores corruptos de '$id' en AGENTS.md: no se escribe (fail-closed)."
            return 'omitido-item'
        }
    }

    if ($newText -ceq $original) {
        Write-OK "AGENTS.md: sin cambios (bloques del kit al dia)."
        return 'sin-cambios'
    }

    if ($Simulate) {
        Write-Info "DryRun: complementaria AGENTS.md con $applied bloque(s) del kit, conservando el resto del archivo."
        return 'ok'
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
        Write-OK "AGENTS.md: $applied bloque(s) del kit complementados (backup: $(Split-Path -Leaf $backupPath)); el resto del archivo se conservo."
        return 'ok'
    } catch {
        Copy-Item -LiteralPath $backupPath -Destination $Destination -Force
        Write-Fail "AGENTS.md: no se pudo escribir ($_); se restauro el backup."
        return 'omitido-item'
    }
}
