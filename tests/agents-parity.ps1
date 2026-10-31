# tests/agents-parity.ps1
# Test de contrato spec 031 — CA-10 / CA-12: paridad .github/agents <-> .opencode/agents
# Devuelve exit code 0 si todo pasa, 1 si hay fallos.
# Uso: pwsh -NoProfile -File tests/agents-parity.ps1

$ErrorActionPreference = 'Stop'
$root = (Get-Item (Resolve-Path .)).FullName
$githubAgentsDir = Join-Path $root ".github\agents"
$opencodeAgentsDir = Join-Path $root ".opencode\agents"

$agentBaseNames = @(
    "Agent-SSD", "analista_tecnico", "arquitecto", "developer", "documentador",
    "gitflow", "pensador", "plataformador", "security-auditor", "solucionador",
    "ssh-connection-agent", "upgrade_framework", "usuario-preferencias"
)

$failures = @()
$newline = [environment]::NewLine

function Get-FrontmatterAndBody {
    param([string]$Path)
    $lines = @(Get-Content -LiteralPath $Path -Encoding utf8)
    $fmEnd = -1
    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
        }
    }
    if ($fmEnd -lt 0) {
        return [pscustomobject]@{ Frontmatter = @(); Body = $lines }
    }
    return [pscustomobject]@{
        Frontmatter = @($lines[1..($fmEnd - 1)])
        Body        = @($lines[($fmEnd + 1)..($lines.Count - 1)])
    }
}

function Get-FrontmatterValue {
    param([string[]]$Frontmatter, [string]$Key)
    $pattern = "^" + [regex]::Escape($Key) + ":\s*(.*)$"
    foreach ($line in $Frontmatter) {
        if ($line -match $pattern) {
            return $Matches[1].Trim().Trim('"')
        }
    }
    return $null
}

function Get-FrontmatterSkills {
    param([string[]]$Frontmatter)
    $skills = @()
    foreach ($line in $Frontmatter) {
        if ($line -match '^\s+-\s*(.+)$') {
            $skills += $Matches[1].Trim().Trim('"')
        }
    }
    return @($skills | Sort-Object)
}

function Get-SectionTitles {
    param([string[]]$Body)
    $titles = @()
    foreach ($line in $Body) {
        if ($line -match '^(#{1,6})\s+(.+)$') {
            $titles += $Matches[2].Trim()
        }
    }
    return $titles
}

function Test-Regla2Sections {
    param([string[]]$Body)

    $missing = @()
    $titles = Get-SectionTitles -Body $Body
    $normalized = @($titles | ForEach-Object {
        $t = $_
        $t = $t -replace '\s+', ' '
        $t = $t -replace '[^\w\s]', ''
        $t = $t -replace 'í','i' -replace 'é','e' -replace 'á','a' -replace 'ó','o' -replace 'ú','u' -replace 'ñ','n'
        $t.ToLowerInvariant()
    })

    # 1. Introducción: prosa antes del primer encabezado (igual que Test-BodyIntroduction del validador)
    $hasIntro = $false
    $h1Seen = $false
    foreach ($line in $Body) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($trimmed -match '^#{1,6}\s+') {
            if ($trimmed -match '^#\s+' -and -not $h1Seen) { $h1Seen = $true; continue }
            break
        }
        if ($trimmed -match '^(-{3,}|\*{3,}|_{3,}|=+\s*$|```|\|)') { continue }
        if ($trimmed -match '^[-*+]\s+' -or $trimmed -match '^\d+\.\s+') { continue }
        $hasIntro = $true
        break
    }
    if (-not $hasIntro) { $missing += "introduccion" }

    # 2. Resto de secciones: al menos un patrón que matchee (igual que VAL-08 del validador)
    $sectionChecks = @(
        @{ Key = "skills";       Patterns = @("skills") }
        @{ Key = "enfoque";      Patterns = @("enfoque", "approach") }
        @{ Key = "mcps";         Patterns = @("mcp") }
        @{ Key = "idioma";       Patterns = @("idioma", "language") }
        @{ Key = "constraints";  Patterns = @("constraint", "restricci") }
    )
    foreach ($check in $sectionChecks) {
        $found = $false
        foreach ($t in $normalized) {
            foreach ($p in $check.Patterns) {
                if ($t -like "*$p*") { $found = $true; break }
            }
            if ($found) { break }
        }
        if (-not $found) { $missing += $check.Key }
    }

    return $missing
}

Write-Host "=== Test de contrato spec 031 (CA-10 / CA-12): paridad .github <-> .opencode ==="

foreach ($name in $agentBaseNames) {
    $githubPath = Join-Path $githubAgentsDir ($name + ".agent.md")
    $opencodePath = Join-Path $opencodeAgentsDir ($name + ".md")

    if (-not (Test-Path -LiteralPath $githubPath)) {
        $failures += ($name + ": falta en .github/agents"); continue
    }
    if (-not (Test-Path -LiteralPath $opencodePath)) {
        $failures += ($name + ": falta en .opencode/agents"); continue
    }

    $g = Get-FrontmatterAndBody -Path $githubPath
    $o = Get-FrontmatterAndBody -Path $opencodePath

    $gBody = ($g.Body -join $newline)
    $oBody = ($o.Body -join $newline)
    if (-not [string]::Equals($gBody, $oBody, [System.StringComparison]::Ordinal)) {
        $failures += ($name + ": cuerpos difieren entre arneses")
    }

    $gt = Get-FrontmatterValue -Frontmatter $g.Frontmatter -Key "tier"
    $ot = Get-FrontmatterValue -Frontmatter $o.Frontmatter -Key "tier"
    if (-not [string]::Equals($gt, $ot, [System.StringComparison]::Ordinal)) {
        $failures += (($name + ": tier difiere ('" + $gt + "' vs '" + $ot + "')"))
    }

    $gd = Get-FrontmatterValue -Frontmatter $g.Frontmatter -Key "description"
    $od = Get-FrontmatterValue -Frontmatter $o.Frontmatter -Key "description"
    if (-not [string]::Equals($gd, $od, [System.StringComparison]::Ordinal)) {
        $failures += ($name + ": descripción difiere")
    }

    $gs = (Get-FrontmatterSkills -Frontmatter $g.Frontmatter) -join ','
    $os = (Get-FrontmatterSkills -Frontmatter $o.Frontmatter) -join ','
    if ($gs -ne $os) {
        $failures += (($name + ": skills difieren ('" + $gs + "' vs '" + $os + "')"))
    }

    $gMissing = (Test-Regla2Sections -Body $g.Body)
    $oMissing = (Test-Regla2Sections -Body $o.Body)
    if (@($gMissing).Count -gt 0) {
        $failures += ($name + ": .github/agents falta secciones (" + ($gMissing -join ',') + ")")
    }
    if (@($oMissing).Count -gt 0) {
        $failures += ($name + ": .opencode/agents falta secciones (" + ($oMissing -join ',') + ")")
    }
}

# Fixture negativo: divergencia unilateral debe detectarse
Write-Host "--- Fixture negativo: divergencia unilateral ---"
$tmp = Join-Path $env:TEMP ("agents-parity-fixture-" + (Get-Random) + ".md")
$src = Join-Path $root ".opencode\agents\developer.md"
$content = Get-Content -LiteralPath $src -Encoding utf8
$content = $content + $newline + "# Fixture negativo: linea agregada para forzar divergencia"
Set-Content -LiteralPath $tmp -Value $content -Encoding utf8 -NoNewline

$a = @(Get-Content -LiteralPath $tmp -Encoding utf8)
$b = @(Get-Content -LiteralPath (Join-Path $root ".github\agents\developer.agent.md") -Encoding utf8)
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
    Write-Host "Todas las verificaciones de paridad pasaron." -ForegroundColor Green
    Write-Host "Fixture negativo: divergencia detectada correctamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "RESULTADO: OK" -ForegroundColor Green
    exit 0
}
