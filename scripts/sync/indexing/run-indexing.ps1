#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/indexing/run-indexing.ps1
# [021] Capa "indexing" del sync por capas (spec 021-sync-kit-agents, fase 4,
# [021] T011, RF-06). Extraccion mecanica de Index-CodebaseMemory
# [021] (plataformador-bootstrap.ps1:1512), Index-ContextMode (:1587) y
# [021] Configure-Graphify (:2680): mismos comandos, adaptados a -RootPath (el
# [021] destino ya sincronizado). NO recibe -StageDir: es NoStage en el
# [021] orquestador. Fail-open por herramienta (WARN accionable + continua con
# [021] la siguiente). Respeta -DryRun (cero escrituras, cero indexaciones).
# [021] -Force refresca el registro graphify en opencode.json aunque ya exista
# [021] (patron Configure-Graphify, que lee el $Force del bootstrap).
# [021] Emite RESULT:indexing:<herramienta>:<ok|omitido-warn|sin-cambios>.
# [021] NOTA --repo-path: el bootstrap invoca
# [021] `codebase-memory-mcp cli index_repository --repo-path <Root>` (no
# [021] `--path`); se replica el flag real verificado en el codigo fuente.
# [021] NOTA .vscode/mcp.json: el registro graphify ahi lo posee la capa
# [021] mcp-lift-vscode; esta capa asegura el grafo + su entrada en
# [021] opencode.json (evita doble escritura del mismo archivo).
# =============================================================================

[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string[]]$Apps = @(),
    [switch]$DryRun,
    # [021] Aceptado por uniformidad del orquestador (capas NoStage siempre
    # [021] reciben -Force): aqui solo refresca el registro graphify.
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# [021] Default: raiz del repo (scripts/sync/indexing/ -> 3 niveles arriba).
if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "indexing: -RootPath invalido ($RootPath): $_"; exit 1 }

# [021] Scopes de indexacion: -Apps explicito > descubrir subdirectorios de
# [021] Documentacion/ (patron sync-docs, sin 'templates') > vacio (= raiz).
function Resolve-IndexApps {
    param([string]$Root, [string[]]$Wanted)
    if ($Wanted.Count -gt 0) { return @($Wanted | Select-Object -Unique) }
    $docRoot = Join-Path $Root "Documentacion"
    if (-not (Test-Path -LiteralPath $docRoot -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $docRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'templates' } | Select-Object -ExpandProperty Name)
}

# [021] Scope del grafo por app (patron Configure-Graphify scope App):
# [021] src/<App>/ (tolerancia: <App>/ en raiz); si no existe -> raiz.
function Resolve-ScopePath {
    param([string]$Root, [string]$App)
    foreach ($cand in @((Join-Path $Root "src/$App"), (Join-Path $Root $App))) {
        if (Test-Path -LiteralPath $cand -PathType Container) { return $cand }
    }
    return $Root
}

Write-Step "indexing: indexando destino $RootPath"

$apps = @(Resolve-IndexApps -Root $RootPath -Wanted $Apps)

# =============================================================================
# [021] codebase-memory (bootstrap Index-CodebaseMemory:1512-1585). Repo-level:
# [021] una sola indexacion sobre RootPath + verificacion de DB (list_projects
# [021] o archivo .db) + reintento --mode fast si el default crashea.
# =============================================================================
function Invoke-CodebaseMemoryIndex {
    param([string]$Root)
    $cmd = Get-Command "codebase-memory-mcp" -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Warn "indexing: codebase-memory-mcp no esta en el PATH; se omite indexacion de codigo (accion: npm install -g codebase-memory-mcp y re-ejecuta la capa indexing)."
        Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
        return
    }
    $safeName = (Split-Path $Root -Leaf) -replace '[^a-zA-Z0-9_-]', '-'
    if ($DryRun) {
        Write-Info "DryRun: codebase-memory-mcp cli index_repository --repo-path `"$Root`" (sin ejecutar)"
        Write-Host "RESULT:indexing:codebase-memory:sin-cambios"
        return
    }
    try {
        Write-Step "indexing: codebase-memory-mcp cli index_repository --repo-path `"$Root`" (proyecto: $safeName)..."
        $result = & $cmd.Source cli index_repository --repo-path $Root 2>&1
        $indexExit = $LASTEXITCODE
        $indexErr = ($result | Out-String).Trim()
        $dbVerified = $false
        try {
            $projectsOut = (& $cmd.Source cli list_projects 2>&1 | Out-String)
            if ($projectsOut -match [regex]::Escape($Root) -or $projectsOut -match [regex]::Escape($safeName)) { $dbVerified = $true }
        } catch { $dbVerified = $false }
        if (-not $dbVerified) {
            $cmDbDir = Join-Path $HOME ".cache/codebase-memory-mcp"
            $dbFile = Get-ChildItem -Path $cmDbDir -Filter "*$safeName*.db" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($dbFile) { $dbVerified = $true }
        }
        if ($indexExit -eq 0 -and $dbVerified) {
            Write-OK "indexing: codigo indexado en codebase-memory-mcp (DB del proyecto verificada)."
            Write-Host "RESULT:indexing:codebase-memory:ok"
        } elseif ($indexExit -eq 0) {
            Write-Warn "indexing: indexacion OK pero la DB '$safeName' no aparece en list_projects. Error real: $indexErr"
            Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
        } elseif ($indexErr -match 'exit_nonzero|worker_failed') {
            Write-Warn "indexing: modo default crasheo (worker_failed); reintentando UNA vez con --mode fast..."
            $resultFast = & $cmd.Source cli index_repository --repo-path $Root --mode fast 2>&1
            $fastExit = $LASTEXITCODE
            $fastErr = ($resultFast | Out-String).Trim()
            if ($fastExit -eq 0) {
                Write-OK "indexing: codigo indexado con --mode fast (degradacion gracefully)."
                Write-Host "RESULT:indexing:codebase-memory:ok"
            } else {
                Write-Warn "indexing: --mode fast tambien fallo (exit $fastExit). Error real: $fastErr"
                Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
            }
        } else {
            Write-Warn "indexing: indexacion de codigo fallo (exit $indexExit). Error real: $indexErr"
            Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
        }
    } catch {
        Write-Warn "indexing: codebase-memory fallo inesperado ($_); se continua (fail-open)."
        Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
    }
}

# =============================================================================
# [021] context-mode (bootstrap Index-ContextMode:1587-1630): `context-mode
# [021] index <ruta>` por cada Documentacion/<App> (o Documentacion/ raiz si no
# [021] hay apps). Fail-open por ruta.
# =============================================================================
function Invoke-ContextModeIndex {
    param([string]$Root, [string[]]$AppList)
    $cmd = Get-Command "context-mode" -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Warn "indexing: context-mode no esta en el PATH; se omite indexacion de documentacion (accion: npm install -g context-mode y re-ejecuta la capa indexing)."
        Write-Host "RESULT:indexing:context-mode:omitido-warn"
        return
    }
    $paths = @()
    foreach ($a in $AppList) { $paths += Join-Path $Root ("Documentacion/" + $a) }
    if ($paths.Count -eq 0) { $paths += Join-Path $Root "Documentacion" }
    if ($DryRun) {
        foreach ($p in $paths) { Write-Info "DryRun: context-mode index `"$p`" (sin ejecutar)" }
        Write-Host "RESULT:indexing:context-mode:sin-cambios"
        return
    }
    $done = 0; $failed = 0
    foreach ($p in $paths) {
        if (-not (Test-Path -LiteralPath $p)) { Write-Warn "indexing: ruta no existe, se omite: $p"; $failed++; continue }
        try {
            $r = & $cmd.Source index $p 2>&1
            if ($LASTEXITCODE -eq 0) { Write-OK "indexing: indexado en context-mode: $p"; $done++ }
            else { Write-Warn "indexing: context-mode index fallo para $p (exit $LASTEXITCODE): $(($r | Out-String).Trim())"; $failed++ }
        } catch {
            Write-Warn "indexing: error al indexar $p ($_); se continua."
            $failed++
        }
    }
    if ($done -gt 0 -and $failed -eq 0) { Write-Host "RESULT:indexing:context-mode:ok" }
    else {
        if ($done -gt 0) { Write-Warn "indexing: context-mode parcial ($done ok, $failed fallo(s))." }
        Write-Host "RESULT:indexing:context-mode:omitido-warn"
    }
}

# =============================================================================
# [021] graphify (bootstrap Configure-Graphify:2680-2821 + registro
# [021] opencode.json:2823-2858). Deteccion Rama A: CLI `graphify` + modulo
# [021] `python -m graphify.serve --help` (o via `uv tool run --from
# [021] graphifyy`). Por scope: sin grafo -> `graphify extract <scope>
# [021] --code-only`; con grafo -> `graphify update <scope>`. Registro en
# [021] <Root>/opencode.json (type local, stdio, sin secrets) solo si falta o
# [021] con -Force, con backup previo en <Root>/.kit-backup/<timestamp>/.
# =============================================================================
function Invoke-GraphifyIndex {
    param([string]$Root, [string[]]$AppList)
    $graphifyCmd = Get-Command graphify -ErrorAction SilentlyContinue
    if (-not $graphifyCmd) {
        Write-Warn 'indexing: graphify no instalado (comando graphify ausente); se omite (accion: uv tool install "graphifyy[mcp]" y re-ejecuta la capa indexing).'
        Write-Host "RESULT:indexing:graphify:omitido-warn"
        return
    }
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $pythonCmd -and -not $uvCmd) {
        Write-Warn "indexing: ni python ni uv en el PATH; no se puede verificar 'python -m graphify.serve'; se omite graphify."
        Write-Host "RESULT:indexing:graphify:omitido-warn"
        return
    }
    if ($uvCmd) { $serveExe = $uvCmd.Source; $useUv = $true } else { $serveExe = $pythonCmd.Source; $useUv = $false }
    $serveOK = $false
    try {
        if ($useUv) { & $serveExe tool run --from graphifyy python -m graphify.serve --help 2>$null | Out-Null }
        else { & $serveExe -m graphify.serve --help 2>$null | Out-Null }
        if ($LASTEXITCODE -eq 0) { $serveOK = $true }
    } catch { $serveOK = $false }
    if (-not $serveOK) {
        Write-Warn 'indexing: el modulo MCP embebido no responde (python -m graphify.serve --help fallo): falta el extra mcp; se omite graphify.'
        Write-Host "RESULT:indexing:graphify:omitido-warn"
        return
    }
    $scopes = @()
    foreach ($a in $AppList) { $scopes += Resolve-ScopePath -Root $Root -App $a }
    if ($scopes.Count -eq 0) { $scopes += $Root }
    $scopes = @($scopes | Select-Object -Unique)
    $graphifyCli = $graphifyCmd.Source
    $failed = 0; $graphs = @()
    foreach ($scope in $scopes) {
        $graphPath = Join-Path $scope "graphify-out/graph.json"
        try { $graphCanon = [IO.Path]::GetFullPath($graphPath) } catch { Write-Warn "indexing: scope invalido ($scope); se omite."; $failed++; continue }
        $graphs += $graphCanon
        if (Test-Path -LiteralPath $graphCanon -PathType Leaf) { $gArgs = @("update", $scope); $gAction = "update" }
        else { $gArgs = @("extract", $scope, "--code-only"); $gAction = "extract --code-only" }
        if ($DryRun) {
            Write-Info "DryRun: graphify $($gArgs -join ' ') (grafo: $graphCanon) (sin ejecutar)"
            continue
        }
        try {
            $gOut = & $graphifyCli @gArgs 2>&1
            if ($LASTEXITCODE -eq 0) { Write-OK "indexing: graphify $gAction completado (grafo: $graphCanon)" }
            else { Write-Warn "indexing: graphify $gAction fallo (exit $LASTEXITCODE): $(($gOut | Out-String).Trim())"; $failed++ }
        } catch {
            Write-Warn "indexing: graphify $gAction fallo ($_); se continua."
            $failed++
        }
    }
    # [021] Registro en <Root>/opencode.json (patron Configure-Graphify). El
    # [021] grafo registrado es el del scope raiz si esta en el set, si no el
    # [021] primero (opencode.json admite una sola entrada graphify).
    $graphCanonG = if ($graphs -contains ([IO.Path]::GetFullPath((Join-Path $Root "graphify-out/graph.json")))) {
        [IO.Path]::GetFullPath((Join-Path $Root "graphify-out/graph.json"))
    } else { $graphs[0] }
    $graphCanonG = $graphCanonG -replace '\\', '/'
    if ($useUv) { $regCmd = @($serveExe, "tool", "run", "--from", "graphifyy", "python", "-m", "graphify.serve", $graphCanonG) }
    else { $regCmd = @($serveExe, "-m", "graphify.serve", $graphCanonG) }
    $opencodePath = Join-Path $Root "opencode.json"
    if ($DryRun) {
        Write-Info "DryRun: registraria graphify en opencode.json (command: [..., graphify.serve, $graphCanonG]) (sin escribir)"
    } elseif (-not (Test-Path -LiteralPath $opencodePath -PathType Leaf)) {
        Write-Warn "indexing: no existe opencode.json en $Root; se omite el registro de graphify."
        $failed++
    } else {
        try {
            $existing = Get-Content -LiteralPath $opencodePath -Raw -ErrorAction Stop | ConvertFrom-Json
            if (($null -ne $existing.mcp) -and ($null -ne $existing.mcp.graphify) -and (-not $Force)) {
                Write-OK "indexing: opencode.json ya registra graphify; se conserva (usa -Force para refrescar)."
            } else {
                $entry = [ordered]@{ type = "local"; command = $regCmd; enabled = $true }
                if ($null -eq $existing.mcp) { $existing | Add-Member -NotePropertyName "mcp" -NotePropertyValue ([ordered]@{}) -Force }
                if ($existing.mcp -is [System.Collections.IDictionary]) { $existing.mcp["graphify"] = $entry }
                else { $existing.mcp | Add-Member -NotePropertyName "graphify" -NotePropertyValue $entry -Force }
                $text = $existing | ConvertTo-Json -Depth 10
                $null = $text | ConvertFrom-Json -ErrorAction Stop
                $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $backup = Join-Path $Root (".kit-backup/$stamp")
                New-Item -ItemType Directory -Path $backup -Force | Out-Null
                Copy-Item -LiteralPath $opencodePath -Destination (Join-Path $backup "opencode.json") -Force
                Write-Info "Backup previo en $backup/opencode.json"
                $text | Set-Content -LiteralPath $opencodePath -Encoding UTF8
                Write-OK "indexing: graphify registrado como MCP stdio en opencode.json"
            }
        } catch {
            Write-Warn "indexing: no se pudo registrar graphify en opencode.json ($_); se continua."
            $failed++
        }
    }
    if ($DryRun) { Write-Host "RESULT:indexing:graphify:sin-cambios" }
    elseif ($failed -eq 0) { Write-Host "RESULT:indexing:graphify:ok" }
    else { Write-Host "RESULT:indexing:graphify:omitido-warn" }
}

try { Invoke-CodebaseMemoryIndex -Root $RootPath } catch {
    Write-Warn "indexing: codebase-memory omitido por error no controlado ($_)."
    Write-Host "RESULT:indexing:codebase-memory:omitido-warn"
}
try { Invoke-ContextModeIndex -Root $RootPath -AppList $apps } catch {
    Write-Warn "indexing: context-mode omitido por error no controlado ($_)."
    Write-Host "RESULT:indexing:context-mode:omitido-warn"
}
try { Invoke-GraphifyIndex -Root $RootPath -AppList $apps } catch {
    Write-Warn "indexing: graphify omitido por error no controlado ($_)."
    Write-Host "RESULT:indexing:graphify:omitido-warn"
}

# [021] NOTA: no se normaliza $LASTEXITCODE aqui: la asignacion seria local
# [021] a este script (se descarta al retornar); lo hace el orquestador.
Show-ExecutionSummary -Title "indexing"
