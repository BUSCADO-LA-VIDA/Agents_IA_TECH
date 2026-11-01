# tests/harness-default.ps1
# Spec 034 - Arranque por defecto con agentes del kit (FR-01..FR-06, FR-12)
# Exit 0 = todo OK. Exit 1 = al menos un fallo. Sin Pester por incompatibilidad documentada.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Get-ArranqueFallos {
    param(
        [string]$RepoRoot,
        [string]$OpencodePath
    )
    $fallos = New-Object System.Collections.ArrayList

    # --- opencode.json / default_agent ---
    if (-not (Test-Path -LiteralPath $OpencodePath)) {
        [void]$fallos.Add('opencode.json no existe')
        return $fallos
    }

    $cfg = $null
    try {
        $raw = Get-Content -LiteralPath $OpencodePath -Raw -Encoding utf8
        $cfg = $raw | ConvertFrom-Json
    }
    catch {
        [void]$fallos.Add('opencode.json no es JSON valido: ' + $_.Exception.Message)
        return $fallos
    }

    $props = $cfg.PSObject.Properties.Name
    if (-not ($props -contains 'default_agent')) {
        [void]$fallos.Add('opencode.json no declara default_agent')
    }
    else {
        $da = [string]$cfg.default_agent
        if ($da -eq 'build') {
            [void]$fallos.Add('default_agent apunta al agente incorporado build (fallback silencioso)')
        }
        elseif ($da -ne 'pensador') {
            [void]$fallos.Add('default_agent inesperado: ' + $da + ' (se esperaba pensador)')
        }

        $agentPath = Join-Path $RepoRoot ('.opencode/agents/' + $da + '.md')
        if (-not (Test-Path -LiteralPath $agentPath)) {
            [void]$fallos.Add('no existe el archivo del agente por defecto: ' + $agentPath)
        }
        else {
            $agentText = Get-Content -LiteralPath $agentPath -Raw -Encoding utf8
            if ($agentText -notmatch '(?m)^mode:\s*primary\s*$') {
                [void]$fallos.Add('el agente ' + $da + ' no declara mode: primary')
            }
        }
    }

    # --- Regla de arranque en AGENTS.md ---
    $agentsMd = Join-Path $RepoRoot 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $agentsMd)) {
        [void]$fallos.Add('AGENTS.md no existe')
    }
    else {
        $agentsText = Get-Content -LiteralPath $agentsMd -Raw -Encoding utf8
        if ($agentsText -notmatch '## Arranque por defecto del arnés') {
            [void]$fallos.Add('AGENTS.md no contiene la seccion "## Arranque por defecto del arnés"')
        }
        if ($agentsText -notmatch 'Matriz de enrutamiento por tarea') {
            [void]$fallos.Add('AGENTS.md no contiene la matriz de enrutamiento por tarea')
        }
    }

    # --- Enrutamiento en copilot-instructions.md ---
    $copilot = Join-Path $RepoRoot '.github/copilot-instructions.md'
    if (-not (Test-Path -LiteralPath $copilot)) {
        [void]$fallos.Add('.github/copilot-instructions.md no existe')
    }
    else {
        $copilotText = Get-Content -LiteralPath $copilot -Raw -Encoding utf8
        if ($copilotText -notmatch 'AGENTS\.md') {
            [void]$fallos.Add('copilot-instructions.md no remite a AGENTS.md')
        }
        if ($copilotText -notmatch 'Arranque por defecto del arnés') {
            [void]$fallos.Add('copilot-instructions.md no declara el arranque por defecto')
        }
    }

    # --- Higiene: carpeta huerfana ---
    $huerfano = Join-Path $RepoRoot '.opencode/agents/pensador/spec.md'
    if (Test-Path -LiteralPath $huerfano) {
        [void]$fallos.Add('existe la carpeta huerfana .opencode/agents/pensador/spec.md (no es un agente)')
    }

    return $fallos
}

Write-Host "=== harness-default (spec 034): arranque por defecto del arnes ==="

$opencodePath = Join-Path $root 'opencode.json'
$fallosReales = Get-ArranqueFallos -RepoRoot $root -OpencodePath $opencodePath

Write-Host ""
Write-Host "--- Verificacion sobre el estado real ---"
if ($fallosReales.Count -eq 0) {
    Write-Host "OK: arranque valido (pensador, primary, regla presente en ambos arneses)" -ForegroundColor Green
}
else {
    foreach ($f in $fallosReales) { Write-Host ("  - " + $f) -ForegroundColor Red }
}

Write-Host ""
Write-Host "--- Fixture negativo: default_agent = build ---"
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ('harness-default-fixture-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$tmpOpencode = Join-Path $tmpDir 'opencode.json'

if (Test-Path -LiteralPath $opencodePath) {
    $contenido = Get-Content -LiteralPath $opencodePath -Raw -Encoding utf8
    $contenido = [regex]::Replace($contenido, '"default_agent"\s*:\s*"[^"]*"', '"default_agent": "build"')
    Set-Content -LiteralPath $tmpOpencode -Value $contenido -Encoding utf8 -NoNewline
}

$fallosFixture = Get-ArranqueFallos -RepoRoot $root -OpencodePath $tmpOpencode
$fixtureDetectado = $false
if ($fallosFixture.Count -gt 0) {
    foreach ($f in $fallosFixture) {
        if ($f -match 'build') { $fixtureDetectado = $true }
    }
}
if (-not $fixtureDetectado) {
    Write-Host "  - el fixture negativo NO fue detectado (error del test)" -ForegroundColor Red
}
else {
    Write-Host "OK: el fixture negativo detecto la degradacion a build" -ForegroundColor Green
}

if (Test-Path -LiteralPath $tmpDir) { Remove-Item -LiteralPath $tmpDir -Recurse -Force }

Write-Host ""
$totalFallos = $fallosReales.Count
if (-not $fixtureDetectado) { $totalFallos = $totalFallos + 1 }

if ($totalFallos -gt 0) {
    Write-Host ("RESULTADO: FALLO (" + $totalFallos + " incidencia(s))") -ForegroundColor Red
    exit 1
}

Write-Host "RESULTADO: OK" -ForegroundColor Green
exit 0
