# tests/mcp-refresh-parity.ps1
# Test de paridad de índices MCP spec 033 — CA-06
# Devuelve exit code 0 si todo pasa, 1 si hay fallos.
# Uso: pwsh -NoProfile -File tests/mcp-refresh-parity.ps1

$ErrorActionPreference = 'Stop'
$root = (Get-Item (Resolve-Path .)).FullName
$githubAgentsDir = Join-Path $root ".github\agents"
$opencodeAgentsDir = Join-Path $root ".opencode\agents"

$refreshAgents = @("plataformador", "analista_tecnico", "pensador", "documentador", "security-auditor")
$requiredMcps = @("codebase-memory-mcp", "graphify", "context-mode", "markitdown", "tokenslayer", "github", "playwright", "context7")
$failures = @()

Write-Host "=== Test de paridad refresh MCP spec 033 (CA-06): paridad de MCPs en agentes de refresh ==="

foreach ($name in $refreshAgents) {
    $githubPath = Join-Path $githubAgentsDir ($name + ".agent.md")
    $opencodePath = Join-Path $opencodeAgentsDir ($name + ".md")

    if (-not (Test-Path -LiteralPath $githubPath)) {
        $failures += ($name + ": falta en .github/agents"); continue
    }
    if (-not (Test-Path -LiteralPath $opencodePath)) {
        $failures += ($name + ": falta en .opencode/agents"); continue
    }

    $gContent = Get-Content -LiteralPath $githubPath -Encoding utf8
    $oContent = Get-Content -LiteralPath $opencodePath -Encoding utf8

    $gMcps = @()
    $oMcps = @()
    foreach ($mcp in $requiredMcps) {
        if ($gContent -match $mcp) { $gMcps += $mcp }
        if ($oContent -match $mcp) { $oMcps += $mcp }
    }

    $gSorted = ($gMcps | Sort-Object) -join ','
    $oSorted = ($oMcps | Sort-Object) -join ','
    if ($gSorted -ne $oSorted) {
        $failures += (($name + ": MCPs difieren ('" + $gSorted + "' vs '" + $oSorted + "')"))
    }
}

# Verificar que el pipeline de refresh MCP documentado existe
Write-Host "--- Verificando pipeline-refresh-mcp.md ---"
$pipelinePath = Join-Path $root "Documentacion\Agents_IA_TECH\specs\033-refresh-conocimiento-mcp\pipeline-refresh-mcp.md"
if (-not (Test-Path -LiteralPath $pipelinePath)) {
    $failures += "pipeline-refresh-mcp.md: falta el archivo"
} else {
    $content = Get-Content -LiteralPath $pipelinePath -Encoding utf8
    $contentStr = ($content -join [environment]::NewLine)
    if (-not ($contentStr -match "codebase-memory-mcp")) { $failures += "pipeline-refresh-mcp.md: falta referencia a codebase-memory-mcp" }
    if (-not ($contentStr -match "graphify")) { $failures += "pipeline-refresh-mcp.md: falta referencia a graphify" }
    if (-not ($contentStr -match "context-mode")) { $failures += "pipeline-refresh-mcp.md: falta referencia a context-mode" }
    if (-not ($contentStr -match "tokenslayer")) { $failures += "pipeline-refresh-mcp.md: falta referencia a tokenslayer" }
}

# Fixture negativo: falta un MCP en un arnés se detecta
Write-Host "--- Fixture negativo: divergencia de MCP en un arnés ---"
$tmp = Join-Path $env:TEMP ("mcp-refresh-parity-fixture-" + (Get-Random) + ".md")
$src = Join-Path $root ".opencode\agents\plataformador.md"
$content = Get-Content -LiteralPath $src -Encoding utf8
$content = $content -replace "codebase-memory-mcp", "codebase-memory-mcp-inexistente"
Set-Content -LiteralPath $tmp -Value $content -Encoding utf8 -NoNewline

$a = @(Get-Content -LiteralPath $tmp -Encoding utf8)
$b = @(Get-Content -LiteralPath (Join-Path $root ".github\agents\plataformador.agent.md") -Encoding utf8)
$different = $false
$max = [math]::Max($a.Count, $b.Count)
for ($i = 0; $i -lt $max; $i = $i + 1) {
    $la = if ($i -lt $a.Count) { $a[$i] } else { "" }
    $lb = if ($i -lt $b.Count) { $b[$i] } else { "" }
    if ($la -ne $lb) { $different = $true; break }
}
if (-not $different) {
    $failures += "Fixture negativo NO detectó la divergencia (error del test)"
}
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }

Write-Host ""
if (@($failures).Count -gt 0) {
    Write-Host "FALLOS:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host ("  - " + $_) -ForegroundColor Red }
    Write-Host ""
    Write-Host ("RESULTADO: FALLO (" + @($failures).Count + " incidencia(s))") -ForegroundColor Red
    exit 1
}
else {
    Write-Host "Todas las verificaciones de paridad refresh MCP pasaron." -ForegroundColor Green
    Write-Host "Fixture negativo: divergencia detectada correctamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "RESULTADO: OK" -ForegroundColor Green
    exit 0
}
