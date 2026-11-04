#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# scripts/sync/opencode/sync-opencode-config.ps1
# Merge por claves de opencode.json: el maestro manda sobre $schema,
# instructions y default_agent; el proyecto conserva mcp, model,
# small_model, permission, lsp y cualquier clave desconocida.
#
# Funcion Merge-OpenCodeConfig extraida (literalmente) de
# scripts/sync-kit.ps1 (lineas 512-724) y convertida en script autonomo
# con su propio param block (-Source, -Destination, -ProjectRoot, -Force).
#
# Depende (via dot-source) de scripts/sync/lib/common.ps1 para
# Initialize-SyncLog y los escritores Write-Info/Write-Step/Write-OK/
# Write-Warn/Write-Fail. No depende de ninguna otra funcion de
# sync-kit.ps1.
#
# Uso:
#   .\scripts\sync\opencode\sync-opencode-config.ps1 `
#       -Source <maestro/opencode.json> `
#       -Destination <proyecto/.opencode/opencode.json> `
#       -ProjectRoot <raiz-del-proyecto> [-Force]
#
# Emite RESULT:opencode-config:<estado> en stdout.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [string]$ProjectRoot = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# =============================================================================
# Validacion de rutas
# =============================================================================
try { $Source = [IO.Path]::GetFullPath($Source) } catch {
    Write-Fail "sync-opencode-config: -Source invalido ('$Source'): $_"
    Write-Host "RESULT:opencode-config:error"
    exit 1
}
try { $Destination = [IO.Path]::GetFullPath($Destination) } catch {
    Write-Fail "sync-opencode-config: -Destination invalido ('$Destination'): $_"
    Write-Host "RESULT:opencode-config:error"
    exit 1
}
if ($ProjectRoot) {
    try { $ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot) } catch {
        Write-Fail "sync-opencode-config: -ProjectRoot invalido ('$ProjectRoot'): $_"
        Write-Host "RESULT:opencode-config:error"
        exit 1
    }
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

# =============================================================================
# Ejecucion
# =============================================================================
try {
    Merge-OpenCodeConfig -Source $Source -Destination $Destination -ProjectRoot $ProjectRoot -Force:$Force
    Write-Host "RESULT:opencode-config:ok"
} catch {
    Write-Fail "sync-opencode-config: $_"
    Write-Host "RESULT:opencode-config:error"
    exit 1
}

Show-ExecutionSummary -Title "sync-opencode-config"
