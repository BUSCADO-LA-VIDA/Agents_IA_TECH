#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/mcp/lift-opencode.ps1
# [021] Capa "mcp-lift-opencode" del sync por capas (spec 021-sync-kit-agents,
# [021] fase 3, T010, RF-04). Fusion ADITIVA del bloque `mcp` de opencode.json:
# [021] origen <Stage>/opencode.json (maestro), destino <Root>/opencode.json.
# [021] Reglas: (a) clave del maestro ausente en destino -> agregar tal cual;
# [021] (b) clave existente cuyo command[0] NO existe en disco -> reemplazar por
# [021] la del maestro (reparacion); con -Force tambien se refresca la entrada
# [021] si difiere del maestro (sin tocar `enabled` del usuario en ningun caso);
# [021] (c) todo lo demas intacto (claves desconocidas, commands validos,
# [021] `enabled`: NO tocar). Clave `graphify`: regenerar command[3] (ruta del
# [021] grafo) a <Root>/graphify-out/graph.json con forward slashes (nunca se
# [021] copia la ruta del maestro). Si falta `mcp` en destino o el archivo no
# [021] existe -> crearlo desde el maestro (con graphify regenerado).
# [021] Round-trip JSON con -Depth 10; fail-closed: si el JSON resultante no
# [021] parsea, NO se escribe + ERROR. Backup previo en
# [021] <Root>/.kit-backup/<timestamp>/ (patron fases 1-2). Respeta -DryRun
# [021] (cero escrituras). Emite RESULT:mcp-opencode:<anadidas|reparadas|
# [021] sin-cambios> (reparadas domina si hubo ambas).
#
# [021-FIX] Ademas del bloque `mcp`, aplica las claves GESTIONADAS de
# [021-FIX] opencode.json desde el maestro: $schema, instructions y
# [021-FIX] default_agent (reglas de Merge-OpenCodeConfig, spec 034):
# [021-FIX]   - default_agent ausente -> se escribe el del maestro;
# [021-FIX]   - default_agent == 'build' -> se corrige (fallback silencioso);
# [021-FIX]   - default_agent de un agente del kit con mode: primary -> se respeta;
# [021-FIX]   - default_agent desconocido -> se corrige;
# [021-FIX]   - -Force fuerza el valor del maestro.
# [021-FIX] Todo cambio en claves gestionadas cuenta como "reparadas" en el RESULT.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# [021] Default: raiz del repo (scripts/sync/mcp/ -> 3 niveles arriba).
if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "mcp-lift-opencode: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "mcp-lift-opencode: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] ¿Existe el binario/ruta del primer elemento del command en disco?
# [021] Soporta array (opencode) o string; rutas relativas se resuelven contra
# [021] RootPath (p. ej. proyect_ext/...). Entrada sin command (remote/url) -> $true.
function Test-McpCommandTarget {
    param($CommandNode, [string]$Root)
    if ($null -eq $CommandNode) { return $true }
    $first = $null
    if ($CommandNode -is [array]) { if ($CommandNode.Count -gt 0) { $first = "$($CommandNode[0])" } }
    elseif ($CommandNode -is [string]) { $first = (($CommandNode -split '\s+') | Where-Object { $_ -ne '' } | Select-Object -First 1) }
    else { return $false }
    if (-not $first) { return $false }
    if (Test-Path -LiteralPath $first) { return $true }
    if (-not [IO.Path]::IsPathRooted($first)) {
        if (Test-Path -LiteralPath (Join-Path $Root $first)) { return $true }
    }
    if (Get-Command $first -ErrorAction SilentlyContinue) { return $true }
    return $false
}

# [021] Clon profundo via round-trip (evita referencias compartidas).
function Copy-McpEntry {
    param($Entry)
    return ($Entry | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
}

# [021] graphify regenerado: copia del maestro con toda ruta *graph.json
# [021] sustituida por <Root>/graphify-out/graph.json (forward slashes).
function New-RegeneratedGraphify {
    param($MasterEntry, [string]$Root)
    $clone = Copy-McpEntry -Entry $MasterEntry
    $graphPath = ((Join-Path $Root "graphify-out/graph.json") -replace '\\', '/')
    if ($clone.command -is [array]) {
        $hit = $false
        for ($i = 0; $i -lt $clone.command.Count; $i++) {
            if ("$($clone.command[$i])" -match '(?i)graph\.json$') { $clone.command[$i] = $graphPath; $hit = $true }
        }
        if (-not $hit) { $clone.command = @($clone.command) + @($graphPath) }
    }
    return $clone
}

function Test-JsonEqual {
    param($A, $B)
    return (($A | ConvertTo-Json -Depth 10 -Compress) -eq ($B | ConvertTo-Json -Depth 10 -Compress))
}

Write-Step "mcp-lift-opencode: fusion aditiva mcp en $RootPath (stage: $StageDir)"

$masterPath = Join-Path $StageDir "opencode.json"
$destPath = Join-Path $RootPath "opencode.json"

# [021] Maestro: fail-closed en integridad (sin maestro valido no hay lift).
try {
    $master = Get-Content -LiteralPath $masterPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Fail "mcp-lift-opencode: no se pudo leer el maestro $masterPath ($_); no se escribe nada."
    exit 1
}
if ($null -eq $master.mcp) {
    Write-Warn "mcp-lift-opencode: el maestro no trae bloque mcp ($masterPath); nada que levantar."
    Write-Host "RESULT:mcp-opencode:sin-cambios"
    exit 0
}

$destExists = Test-Path -LiteralPath $destPath -PathType Leaf
$dest = $null
if ($destExists) {
    try {
        $dest = Get-Content -LiteralPath $destPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Fail "mcp-lift-opencode: el destino $destPath no parsea ($_); no se escribe nada (fail-closed)."
        exit 1
    }
}

$added = 0
$repaired = 0

if (-not $destExists -or $null -eq $dest.mcp) {
    # [021] Destino sin archivo o sin bloque mcp: crear desde el maestro.
    $newDest = Copy-McpEntry -Entry $master
    if ($null -eq $newDest.mcp) { $newDest | Add-Member -NotePropertyName "mcp" -NotePropertyValue ($master.mcp | ConvertTo-Json -Depth 10 | ConvertFrom-Json) -Force }
    foreach ($p in @($master.mcp.PSObject.Properties)) {
        if ($p.Name -eq "graphify") {
            $newDest.mcp.graphify = New-RegeneratedGraphify -MasterEntry $p.Value -Root $RootPath
        }
    }
    $added = @($master.mcp.PSObject.Properties).Count
    $dest = $newDest
    Write-Info "mcp-lift-opencode: destino sin bloque mcp; se crea desde el maestro ($added clave(s), graphify regenerado)."
} else {
    foreach ($p in @($master.mcp.PSObject.Properties)) {
        $key = $p.Name
        $destProp = $dest.mcp.PSObject.Properties[$key]
        if ($null -eq $destProp) {
            # [021] Regla (a): ausente -> agregar tal cual (graphify ya regenerado).
            if ($key -eq "graphify") { $dest.mcp | Add-Member -NotePropertyName $key -NotePropertyValue (New-RegeneratedGraphify -MasterEntry $p.Value -Root $RootPath) }
            else { $dest.mcp | Add-Member -NotePropertyName $key -NotePropertyValue (Copy-McpEntry -Entry $p.Value) }
            $added++
            Write-OK "mcp-lift-opencode: clave '$key' agregada desde el maestro."
            continue
        }
        if ($key -eq "graphify") {
            # [021] graphify nunca se copia: siempre regenerado al grafo del destino.
            $regen = New-RegeneratedGraphify -MasterEntry $p.Value -Root $RootPath
            if (-not (Test-JsonEqual -A $destProp.Value -B $regen)) {
                $destEnabled = $null
                if ($destProp.Value.PSObject.Properties['enabled']) { $destEnabled = $destProp.Value.enabled }
                $dest.mcp.$key = $regen
                if ($null -ne $destEnabled) { $dest.mcp.$key.enabled = $destEnabled }
                $repaired++
                Write-OK "mcp-lift-opencode: 'graphify' regenerado al grafo del destino."
            }
            continue
        }
        $masterHasCmd = ($null -ne $p.Value.command)
        $cmdOk = $true
        if ($masterHasCmd) { $cmdOk = Test-McpCommandTarget -CommandNode $destProp.Value.command -Root $RootPath }
        if (-not $cmdOk) {
            # [021] Regla (b): command roto -> reemplazar por la del maestro,
            # [021] preservando `enabled` del usuario (regla (c)).
            $destEnabled = $null
            if ($destProp.Value.PSObject.Properties['enabled']) { $destEnabled = $destProp.Value.enabled }
            $dest.mcp.$key = Copy-McpEntry -Entry $p.Value
            if ($null -ne $destEnabled) { $dest.mcp.$key.enabled = $destEnabled }
            $repaired++
            Write-OK "mcp-lift-opencode: '$key' reparada (command inexistente -> maestro; enabled preservado)."
        } elseif ($Force -and $masterHasCmd -and (-not (Test-JsonEqual -A $destProp.Value.command -B $p.Value.command))) {
            # [021] -Force: refrescar command aunque el actual sea valido.
            $destEnabled = $null
            if ($destProp.Value.PSObject.Properties['enabled']) { $destEnabled = $destProp.Value.enabled }
            $dest.mcp.$key = Copy-McpEntry -Entry $p.Value
            if ($null -ne $destEnabled) { $dest.mcp.$key.enabled = $destEnabled }
            $repaired++
            Write-OK "mcp-lift-opencode: '$key' refrescada con -Force (enabled preservado)."
        }
        # [021] Regla (c): lo demas (claves desconocidas, commands validos,
        # [021] enabled) no se toca.
    }
}

# =============================================================================
# [021-FIX] Claves gestionadas de opencode.json: $schema, instructions y
# default_agent. Antes NINGUNA capa las aplicaba: el destino quedaba con
# default_agent="build" aunque el sync terminara en verde (fallback silencioso,
# fallo de configuracion segun spec 034 seccion 19.3). Reglas equivalentes a
# Merge-OpenCodeConfig de scripts/sync-kit.ps1.
# Se aplican sobre el objeto (round-trip JSON); el resto de claves no se toca.
# =============================================================================
$managedChanges = 0

function Test-KitAgentPrimary {
    param([string]$Root, [string]$AgentName)
    if (-not $AgentName) { return $false }
    $p = Join-Path $Root (".opencode/agents/$AgentName.md")
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $false }
    try {
        $head = @(Get-Content -LiteralPath $p -TotalCount 25 -ErrorAction Stop) -join "`n"
        return ($head -match '(?m)^mode:\s*primary\s*$')
    } catch { return $false }
}

# --- $schema ---------------------------------------------------------------
$masterSchema = ''
if ($master.PSObject.Properties['$schema']) { $masterSchema = [string]$master.'$schema' }
if ($masterSchema) {
    $currentSchema = ''
    if ($dest.PSObject.Properties['$schema']) { $currentSchema = [string]$dest.'$schema' }
    if ($currentSchema -cne $masterSchema) {
        $dest | Add-Member -NotePropertyName '$schema' -NotePropertyValue $masterSchema -Force
        $managedChanges++
        Write-OK "mcp-lift-opencode: `$schema aplicado desde el maestro."
    }
}

# --- instructions ----------------------------------------------------------
$masterInstr = $null
if ($master.PSObject.Properties['instructions']) { $masterInstr = $master.instructions }
$instrOk = $false
if (($null -ne $masterInstr) -and ($masterInstr -isnot [string]) -and ($masterInstr -is [System.Collections.IEnumerable])) {
    $instrOk = $true
    foreach ($e in $masterInstr) { if ($e -isnot [string]) { $instrOk = $false; break } }
}
if ($instrOk) {
    $masterInstrJson = @($masterInstr) | ConvertTo-Json -Compress
    $currentInstrJson = ''
    if ($dest.PSObject.Properties['instructions'] -and ($null -ne $dest.instructions)) {
        $currentInstrJson = @($dest.instructions) | ConvertTo-Json -Compress
    }
    if ($currentInstrJson -cne $masterInstrJson) {
        $dest | Add-Member -NotePropertyName 'instructions' -NotePropertyValue @($masterInstr) -Force
        $managedChanges++
        Write-OK "mcp-lift-opencode: instructions aplicado desde el maestro."
    }
}

# --- default_agent ---------------------------------------------------------
$masterDefault = ''
if ($master.PSObject.Properties['default_agent']) { $masterDefault = ([string]$master.default_agent).Trim() }
if ($masterDefault) {
    $currentDefault = ''
    if ($dest.PSObject.Properties['default_agent']) { $currentDefault = ([string]$dest.default_agent).Trim() }
    $writeDefault = $false
    if ($Force) {
        $writeDefault = $true
    } elseif (-not $currentDefault) {
        $writeDefault = $true
    } elseif ($currentDefault -ceq $masterDefault) {
        $writeDefault = $false
    } elseif ($currentDefault -ceq 'build') {
        $writeDefault = $true
        Write-Warn "mcp-lift-opencode: default_agent apuntaba a 'build' (fallback silencioso); se corrige a '$masterDefault'."
    } elseif (Test-KitAgentPrimary -Root $RootPath -AgentName $currentDefault) {
        Write-Info "mcp-lift-opencode: default_agent '$currentDefault' es un agente del kit con mode: primary; se respeta la eleccion del proyecto."
    } else {
        $writeDefault = $true
        Write-Warn "mcp-lift-opencode: default_agent '$currentDefault' no es un agente del kit con mode: primary; se corrige a '$masterDefault'."
    }
    if ($writeDefault -and ($currentDefault -cne $masterDefault)) {
        $dest | Add-Member -NotePropertyName 'default_agent' -NotePropertyValue $masterDefault -Force
        $managedChanges++
        Write-OK "mcp-lift-opencode: default_agent = '$masterDefault'."
    }
}

if (($added -eq 0) -and ($repaired -eq 0) -and ($managedChanges -eq 0)) {
    Write-OK "mcp-lift-opencode: sin cambios (idempotente)."
    Write-Host "RESULT:mcp-opencode:sin-cambios"
    Show-ExecutionSummary -Title "mcp-lift-opencode"
    exit 0
}

$status = if (($repaired -gt 0) -or ($managedChanges -gt 0)) { "reparadas" } else { "anadidas" }
if ($DryRun) {
    Write-Info "DryRun: aplicaria $added anadida(s) + $repaired reparada(s) + $managedChanges clave(s) gestionada(s) en $destPath (sin escribir)"
    Write-Host "RESULT:mcp-opencode:$status"
    Show-ExecutionSummary -Title "mcp-lift-opencode"
    exit 0
}

# [021] Fail-closed: validar que el resultado serializa y parsea antes de tocar disco.
try {
    $text = $dest | ConvertTo-Json -Depth 10
    $null = $text | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Fail "mcp-lift-opencode: el JSON resultante no parsea ($_); NO se escribe."
    exit 1
}

# [021] Backup previo del destino (patron fases 1-2; solo si el archivo existia).
try {
    if ($destExists) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = Join-Path $RootPath (".kit-backup/$stamp")
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Copy-Item -LiteralPath $destPath -Destination (Join-Path $backup "opencode.json") -Force
        Write-Info "Backup previo en $backup/opencode.json"
    }
    $text | Set-Content -LiteralPath $destPath -Encoding UTF8
    Write-OK "mcp-lift-opencode: $destPath actualizado ($added anadida(s), $repaired reparada(s))."
} catch {
    Write-Fail "mcp-lift-opencode: no se pudo escribir $destPath ($_)."
    exit 1
}

Write-Host "RESULT:mcp-opencode:$status"
Show-ExecutionSummary -Title "mcp-lift-opencode"
