#!/usr/bin/env powershell
#requires -Version 7.0
# sync-mcp-graphify.ps1 — Capa que unifica entrada graphify en opencode.json
# [036-T009] Spec 036: Unifica la entrada graphify en mcp.servers de opencode.json

[CmdletBinding()]
param(
    [string]$StageDir = "",
    # [040-RF-08] Sin default de la maquina del autor: se deriva de la raiz del kit.
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Force
)

# Dot-source shared logging library (spec 021)
# Resolve path relative to the script's location using MyInvocation
$scriptFullPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptFullPath -Parent
# common.ps1 está en scripts/sync/lib/relative to the project root
# Desde scripts/sync-mcp-graphify.ps1, subimos al root y luego a scripts/sync/lib/
$projectRoot = Split-Path -Path $scriptDir -Parent
$commonPath = Join-Path $projectRoot "scripts/sync/lib/common.ps1"
. $commonPath
Initialize-SyncLog

# [040-RF-08] Default portable: la raiz del kit se deriva de la ubicacion del script.
if (-not $RootPath -or [string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = $projectRoot
    Write-Info "RootPath no informado; se usa la raiz del kit derivada de la ubicacion del script."
}

$opencodeJsonPath = Join-Path -Path $RootPath -ChildPath "opencode.json"
if (-not (Test-Path -Path $opencodeJsonPath)) {
    Write-Fail "No se encuentra opencode.json en $opencodeJsonPath"
    exit 1
}

# Cargar opencode.json actual
try {
    $opencodeRaw = Get-Content -Path $opencodeJsonPath -Raw
    $opencodeData = $opencodeRaw | ConvertFrom-Json
} catch {
    Write-Fail "No se pudo parsear opencode.json: $_"
    exit 1
}

$servers = $opencodeData.mcp.servers
if (-not $servers) {
    Write-Warn "Sección mcp.servers no existe en opencode.json."
    if (-not $DryRun) {
        # Crear estructura básica si no existe
        $opencodeData.mcp.servers = [PSCustomObject]@{
            graphify = [PSCustomObject]@{
                type = "local"
                command = @()
                enabled = $true
            }
        }
    }
    exit 1
}

# [036-T005-D5] Detectar también la forma V1 (mcp.graphify, hermana de
# mcp.servers) que produce la entrada dual contradictoria del defecto D5.
# Si existe una V1 y la V2 canónica también existe, se descarta la V1
# (la canónica para OpenCode es la de mcp.servers, spec 020). Se emite WARN
# indicando cuál se conservó y cuál se descartó.
$v1Graphify = $null
if ($opencodeData.mcp.PSObject.Properties['graphify']) {
    $v1Graphify = $opencodeData.mcp.graphify
}
if ($null -ne $v1Graphify -and -not $DryRun) {
    Write-Warn "Duplicado graphify V1 detectado (mcp.graphify) apuntando al grafo del destino. La forma canónica es mcp.servers.graphify (spec 020); se descarta la entrada V1."
    $opencodeData.mcp.PSObject.Properties.Remove('graphify') | Out-Null
} elseif ($null -ne $v1Graphify) {
    Write-Warn "Duplicado graphify V1 detectado (mcp.graphify). DryRun: se descartaría esta entrada y se conservaría mcp.servers.graphify (forma canónica, spec 020)."
}

# --- Detectar entradas graphify existentes (pueden ser V1, V2, etc.) ---
# Usamos .PSObject.Properties.Name porque .Keys no funciona en PSCustomObject parseado de JSON
$serverPropNames = $servers.PSObject.Properties.Name
$graphifyKeys = @($serverPropNames | Where-Object { $_ -match '^graphify' })
$graphifyEntryCount = $graphifyKeys.Count

if ($graphifyEntryCount -gt 1) {
    $keptName = $graphifyKeys[0]
    $discardedNames = @($graphifyKeys[1..($graphifyEntryCount - 1)]) -join ', '
    Write-Warn "Duplicados de graphify detectados en mcp.servers: $($graphifyKeys -join ', '). Se conserva '$keptName' (primera) y se descartan: $discardedNames."
    # Eliminar duplicados: conservar la primera, quitar las demás
    $firstKey = $graphifyKeys[0]
    for ($i = $graphifyEntryCount - 1; $i -ge 1; $i--) {
        $keyToRemove = $graphifyKeys[$i]
        if (-not $DryRun) {
            [void]$servers.PSObject.Properties.Remove($keyToRemove)
        } else {
            Write-Info "DryRun: se quitaría la entrada graphify '$keyToRemove' (se conserva '$keptName')."
        }
    }
    # Actualizar la lista de propiedades después de remover
    $serverPropNames = $servers.PSObject.Properties.Name
    $graphifyKeys = @($serverPropNames | Where-Object { $_ -match '^graphify' })
    $graphifyEntryCount = $graphifyKeys.Count
}

# Obtener la entrada graphify canónica (la primera restante)
if ($graphifyEntryCount -eq 0) {
    Write-Warn "No se encontró ninguna entrada graphify después de limpiar duplicados."
    exit 1
}

$canonicalKey = $graphifyKeys[0]
$graphifyEntry = $servers.$canonicalKey

if (-not $graphifyEntry) {
    Write-Warn "No se pudo obtener la entrada graphify canonical después de limpiar duplicados."
    exit 1
}

# --- Preservar el campo 'enabled' si existe ---
$hasEnabled = $graphifyEntry.PSObject.Properties | Where-Object { $_.Name -eq 'enabled' }
if ($hasEnabled) {
    $enabledValue = $graphifyEntry.enabled
    Write-Info "Preservando campo 'enabled' existente: $enabledValue"
} else {
    # Agregar enabled: true por defecto para servidores local graphify
    $graphifyEntry | Add-Member -MemberType NoteProperty -Name 'enabled' -Value $true -Force
    Write-Info "Añadido campo 'enabled': true (predeterminado graphify local)."
}

# --- Verificar y regenerar command[3] (o último elemento) si apunta fuera de RootPath ---
$command = $graphifyEntry.command
if ($command -is [System.Array] -and $command.Count -gt 0) {
    # Determinar índice: command[3] si existe (count > 3), sino el último elemento
    if ($command.Count -gt 3) {
        $cmdIdx = 3
    } else {
        $cmdIdx = $command.Count - 1
    }

    $currentPath = $command[$cmdIdx]
    # Verificar si la ruta absolutizada está dentro de RootPath
    $currentPathAbs = try { (Get-Item -LiteralPath $currentPath).FullName } catch { $currentPath }
    $rootPathAbs = (Resolve-Path $RootPath).Path
    $pathStartsWithRoot = $currentPathAbs.StartsWith($rootPathAbs)

    if (-not $pathStartsWithRoot) {
        # Ruta fuera de RootPath: regenerar usando graphify-out dentro de RootPath
        $canonicalPath = (Join-Path -Path $rootPathAbs -ChildPath "graphify-out/graph.json") -replace '\\','/'

        Write-Warn "Ruta graphify command[$cmdIdx] '$currentPath' está fuera de RootPath '$RootPath'. Regenerando a '$canonicalPath'."

        if (-not $DryRun) {
            $command[$cmdIdx] = $canonicalPath
            Write-OK "command[$cmdIdx] actualizada a '$canonicalPath'."
        } else {
            Write-Info "DryRun: command[$cmdIdx] cambiaría de '$currentPath' a '$canonicalPath'."
        }
    }
} else {
    Write-Warn "La entrada graphify no tiene comandos definidos."
}

# --- Consolidar: asegurar exactamente 1 entrada graphify en mcp.servers ---
# Reconstruir el objeto mcp.servers manteniendo todas las demás entradas y solo la graphify canónica.

$newServers = [PSCustomObject]@{}
foreach ($key in $serverPropNames) {
    if ($key -match '^graphify$') {
        # Ya procesamos la entrada graphify; la agregamos solo la canónica
        if (-not $DryRun) {
            $newServers | Add-Member -MemberType NoteProperty -Name $key -Value $graphifyEntry -Force | Out-Null
        }
    } else {
        $newServers | Add-Member -MemberType NoteProperty -Name $key -Value $servers.$key -Force | Out-Null
    }
}

# Re-asignar el objeto mcp.servers consolidado
$opencodeData.mcp.servers = $newServers

# --- Modo DryRun: reportar cambios sin escribir ---
if ($DryRun) {
    Write-Step "RESUMEN DryRun - sync-mcp-graphify"
    Write-Info "Archivo objetivo: $opencodeJsonPath"
    Write-Info "Entradas graphify antes: $graphifyEntryCount"
    Write-Info "Entradas graphify después: 1 (canónica)"

    # Reportar qué se habría cambiado
    if ($graphifyEntryCount -gt 1) {
        Write-Warn "Se habrían removido $($graphifyEntryCount - 1) entradas graphify duplicadas."
    }

    if ($command -and $command.Count -gt 0) {
        # Determinar el índice que se mostró/analizó
        $dryRunCmdIdx = ($command.Count -gt 3) ? 3 : ($command.Count - 1)
        $current = $command[$dryRunCmdIdx]
        # Verificar si la ruta estaría fuera de RootPath después del procesamiento
        $currentAbs = try { (Get-Item -LiteralPath $current).FullName } catch { $current }
        $rootAbs = (Resolve-Path $RootPath).Path
        $pathStartsWithRoot = $currentAbs.StartsWith($rootAbs)
        if (-not $pathStartsWithRoot) {
            $idxStr = if ($dryRunCmdIdx -eq 3) { "command[3]" } else { "command[$dryRunCmdIdx]" }
            $canonicalRun = (Join-Path -Path $rootAbs -ChildPath "graphify-out/graph.json") -replace '\\','/'
            Write-Warn "Se habría regenerado $idxStr de graphify de '$current' a '$canonicalRun'."
        }
    }

    # Reportar preservación de enabled
    $hasEnabledProp = $graphifyEntry.PSObject.Properties | Where-Object { $_.Name -eq 'enabled' }
    if ($hasEnabledProp) {
        Write-Info "El campo 'enabled' se preservaría tal cual: $($hasEnabledProp.Value)."
    } else {
        Write-Info "Se habría añadido 'enabled': true a la entrada graphify."
    }

    Write-OK "DryRun completado. No se escribió opencode.json."
    exit 0
}

# --- Modo normal: escribir opencode.json consolidado ---
try {
    $outputJson = $opencodeData | ConvertTo-Json -Depth 10 -Compress
    # Backup antes de escribir
    $backupPath = "$opencodeJsonPath.bak-" + (Get-Date -Format 'yyyyMMddTHHmmss')
    try {
        Copy-Item -Path $opencodeJsonPath -Destination $backupPath -Force
    } catch {
        Write-Fail "No se pudo crear backup de opencode.json: $_"
        exit 1
    }
    
    try {
        [System.IO.File]::WriteAllText($opencodeJsonPath, $outputJson, [System.Text.Encoding]::UTF8)
    } catch {
        # Restore backup
        try { Copy-Item -Path $backupPath -Destination $opencodeJsonPath -Force } catch { Write-Fail "No se pudo restaurar el backup." }
        Write-Fail "No se pudo escribir opencode.json: $_"
        exit 1
    }
    
    Write-OK "opencode.json consolidado exitosamente."
    Write-OK "RESULT:mcp-graphify:consolidated"
    
    # Emitir resumen
    $graphifyCount = ($newServers.PSObject.Properties.Name | Where-Object { $_ -match '^graphify$' }).Count
    Write-Info "Total entradas graphify en opencode.json: $graphifyCount"
    if ($graphifyEntry.command) {
        Write-Info "Ruta graphify command[3] (o última): $($graphifyEntry.command[3])"
    } else {
        Write-Info "Ruta graphify command[3] (o última): N/A"
    }
    Write-Info "Campo enabled preservado: $($graphifyEntry.enabled)"
    
} catch {
    Write-Fail "Error inesperado al escribir opencode.json: $_"
    exit 1
}