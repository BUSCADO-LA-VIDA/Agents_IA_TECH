#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/mcp/lift-vscode.ps1
# [021] Capa "mcp-lift-vscode" del sync por capas (spec 021-sync-kit-agents,
# [021] fase 3, T010, RF-04). Mismo contrato que lift-opencode.ps1 para
# [021] <Root>/.vscode/mcp.json, bloque `servers`, formato {command, args,
# [021] type}: (a) clave del maestro ausente -> agregar tal cual; (b) clave
# [021] existente cuyo command (string, primer token) NO existe en disco ->
# [021] reemplazar por la del maestro; con -Force tambien se refresca si
# [021] difiere (sin tocar claves desconocidas); (c) lo demas intacto.
# [021] `graphify`: misma regeneracion que opencode (ruta del grafo a
# [021] <Root>/graphify-out/graph.json, forward slashes; nunca la del maestro).
# [021] Si el archivo no existe -> crearlo (con graphify regenerado).
# [021] Round-trip JSON con -Depth 10; fail-closed: si el JSON resultante no
# [021] parsea, NO se escribe + ERROR. Backup previo en
# [021] <Root>/.kit-backup/<timestamp>/. Respeta -DryRun (cero escrituras).
# [021] Emite RESULT:mcp-vscode:<anadidas|reparadas|sin-cambios>.
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
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "mcp-lift-vscode: -RootPath invalido ($RootPath): $_"; exit 1 }
try { $StageDir = [IO.Path]::GetFullPath($StageDir) } catch { Write-Fail "mcp-lift-vscode: -StageDir invalido ($StageDir): $_"; exit 1 }

# [021] ¿Existe el command (string; primer token si trae args) en disco?
function Test-VscodeCommandTarget {
    param($CommandNode, [string]$Root)
    if ($null -eq $CommandNode) { return $true }
    $first = "$CommandNode"
    if ($CommandNode -is [array]) { if ($CommandNode.Count -gt 0) { $first = "$($CommandNode[0])" } else { return $false } }
    else { $first = (($first -split '\s+') | Where-Object { $_ -ne '' } | Select-Object -First 1) }
    if (-not $first) { return $false }
    if (Test-Path -LiteralPath $first) { return $true }
    if (-not [IO.Path]::IsPathRooted($first)) {
        if (Test-Path -LiteralPath (Join-Path $Root $first)) { return $true }
    }
    if (Get-Command $first -ErrorAction SilentlyContinue) { return $true }
    return $false
}

# [021] Clon profundo via round-trip (evita referencias compartidas).
function Copy-VscodeEntry {
    param($Entry)
    return ($Entry | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
}

# [021] graphify regenerado: args con *graph.json -> <Root>/graphify-out/
# [021] graph.json (forward slashes); si command trae la ruta, tambien.
function New-RegeneratedVscodeGraphify {
    param($MasterEntry, [string]$Root)
    $clone = Copy-VscodeEntry -Entry $MasterEntry
    $graphPath = ((Join-Path $Root "graphify-out/graph.json") -replace '\\', '/')
    if ($clone.args -is [array]) {
        $hit = $false
        for ($i = 0; $i -lt $clone.args.Count; $i++) {
            if ("$($clone.args[$i])" -match '(?i)graph\.json$') { $clone.args[$i] = $graphPath; $hit = $true }
        }
        if (-not $hit) { $clone.args = @($clone.args) + @($graphPath) }
    }
    if ("$($clone.command)" -match '(?i)graph\.json$') { $clone.command = $graphPath }
    return $clone
}

function Test-VscodeJsonEqual {
    param($A, $B)
    return (($A | ConvertTo-Json -Depth 10 -Compress) -eq ($B | ConvertTo-Json -Depth 10 -Compress))
}

Write-Step "mcp-lift-vscode: fusion aditiva servers en $RootPath (stage: $StageDir)"

$masterPath = Join-Path $StageDir ".vscode/mcp.json"
$destPath = Join-Path $RootPath ".vscode/mcp.json"

# [021] Maestro: fail-closed en integridad (sin maestro valido no hay lift).
try {
    $master = Get-Content -LiteralPath $masterPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Fail "mcp-lift-vscode: no se pudo leer el maestro $masterPath ($_); no se escribe nada."
    exit 1
}
if ($null -eq $master.servers) {
    Write-Warn "mcp-lift-vscode: el maestro no trae bloque servers ($masterPath); nada que levantar."
    Write-Host "RESULT:mcp-vscode:sin-cambios"
    exit 0
}

$destExists = Test-Path -LiteralPath $destPath -PathType Leaf
$dest = $null
if ($destExists) {
    try {
        $dest = Get-Content -LiteralPath $destPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Fail "mcp-lift-vscode: el destino $destPath no parsea ($_); no se escribe nada (fail-closed)."
        exit 1
    }
}

$added = 0
$repaired = 0

if (-not $destExists -or $null -eq $dest.servers) {
    # [021] Destino sin archivo o sin bloque servers: crear desde el maestro.
    $newDest = [pscustomobject]@{ servers = ($master.servers | ConvertTo-Json -Depth 10 | ConvertFrom-Json) }
    foreach ($p in @($master.servers.PSObject.Properties)) {
        if ($p.Name -eq "graphify") {
            $newDest.servers.graphify = New-RegeneratedVscodeGraphify -MasterEntry $p.Value -Root $RootPath
        }
    }
    $added = @($master.servers.PSObject.Properties).Count
    $dest = $newDest
    Write-Info "mcp-lift-vscode: destino sin bloque servers; se crea desde el maestro ($added clave(s), graphify regenerado)."
} else {
    foreach ($p in @($master.servers.PSObject.Properties)) {
        $key = $p.Name
        $destProp = $dest.servers.PSObject.Properties[$key]
        if ($null -eq $destProp) {
            # [021] Regla (a): ausente -> agregar tal cual (graphify ya regenerado).
            if ($key -eq "graphify") { $dest.servers | Add-Member -NotePropertyName $key -NotePropertyValue (New-RegeneratedVscodeGraphify -MasterEntry $p.Value -Root $RootPath) }
            else { $dest.servers | Add-Member -NotePropertyName $key -NotePropertyValue (Copy-VscodeEntry -Entry $p.Value) }
            $added++
            Write-OK "mcp-lift-vscode: clave '$key' agregada desde el maestro."
            continue
        }
        if ($key -eq "graphify") {
            $regen = New-RegeneratedVscodeGraphify -MasterEntry $p.Value -Root $RootPath
            if (-not (Test-VscodeJsonEqual -A $destProp.Value -B $regen)) {
                $dest.servers.$key = $regen
                $repaired++
                Write-OK "mcp-lift-vscode: 'graphify' regenerado al grafo del destino."
            }
            continue
        }
        $masterHasCmd = ($null -ne $p.Value.command)
        $cmdOk = $true
        if ($masterHasCmd) { $cmdOk = Test-VscodeCommandTarget -CommandNode $destProp.Value.command -Root $RootPath }
        if (-not $cmdOk) {
            # [021] Regla (b): command roto -> reemplazar por la del maestro.
            $dest.servers.$key = Copy-VscodeEntry -Entry $p.Value
            $repaired++
            Write-OK "mcp-lift-vscode: '$key' reparada (command inexistente -> maestro)."
        } elseif ($Force -and $masterHasCmd -and (-not (Test-VscodeJsonEqual -A $destProp.Value -B $p.Value))) {
            # [021] -Force: refrescar entrada aunque la actual sea valida.
            $dest.servers.$key = Copy-VscodeEntry -Entry $p.Value
            $repaired++
            Write-OK "mcp-lift-vscode: '$key' refrescada con -Force."
        }
        # [021] Regla (c): lo demas (claves desconocidas, commands validos) no se toca.
    }
}

if (($added -eq 0) -and ($repaired -eq 0)) {
    Write-OK "mcp-lift-vscode: sin cambios (idempotente)."
    Write-Host "RESULT:mcp-vscode:sin-cambios"
    Show-ExecutionSummary -Title "mcp-lift-vscode"
    exit 0
}

$status = if ($repaired -gt 0) { "reparadas" } else { "anadidas" }
if ($DryRun) {
    Write-Info "DryRun: aplicaria $added anadida(s) + $repaired reparada(s) en $destPath (sin escribir)"
    Write-Host "RESULT:mcp-vscode:$status"
    Show-ExecutionSummary -Title "mcp-lift-vscode"
    exit 0
}

# [021] Fail-closed: validar que el resultado serializa y parsea antes de tocar disco.
try {
    $text = $dest | ConvertTo-Json -Depth 10
    $null = $text | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Fail "mcp-lift-vscode: el JSON resultante no parsea ($_); NO se escribe."
    exit 1
}

# [021] Backup previo del destino (patron fases 1-2; solo si el archivo existia).
try {
    if ($destExists) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = Join-Path $RootPath (".kit-backup/$stamp")
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Copy-Item -LiteralPath $destPath -Destination (Join-Path $backup "mcp-vscode.json") -Force
        Write-Info "Backup previo en $backup/mcp-vscode.json"
    } else {
        New-Item -ItemType Directory -Path (Split-Path -Parent $destPath) -Force | Out-Null
    }
    $text | Set-Content -LiteralPath $destPath -Encoding UTF8
    Write-OK "mcp-lift-vscode: $destPath actualizado ($added anadida(s), $repaired reparada(s))."
} catch {
    Write-Fail "mcp-lift-vscode: no se pudo escribir $destPath ($_)."
    exit 1
}

Write-Host "RESULT:mcp-vscode:$status"
Show-ExecutionSummary -Title "mcp-lift-vscode"
