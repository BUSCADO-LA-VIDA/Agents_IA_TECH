# ecc-orchestrator.ps1 — Orquestador central de MCP (Spec 015, E-03/E-05/E-07)
# Uso: .\scripts\ecc-orchestrator.ps1 --action <tarea> [--mcp <nombre>] [--dry-run]
param(
    [Parameter(Mandatory = $true)]
    [string]$action,
    [string]$mcp = "ecc",
    [switch]$dryrun
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

# Whitelist de paths (Constitution Art-VII). El orquestador solo opera dentro de estos.
$whitelist = @(
    "Documentacion/Agents_IA_TECH/",
    "proyect_ext/ECC/",
    ".github/",
    ".opencode/"
)

function Test-Whitelisted {
    param([string]$relativePath)
    foreach ($allowed in $whitelist) {
        if ($relativePath.StartsWith($allowed)) { return $true }
    }
    return $false
}

function Get-SlavePath {
    param([string]$mcpName)
    if ($mcpName -eq "ecc") {
        return Join-Path $repoRoot "scripts/ecc-sync.ps1"
    }
    return Join-Path $repoRoot ("scripts/ecc-mcp-" + $mcpName + ".ps1")
}

function Write-Summary {
    param([string]$status, [string]$detail)
    $stamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Write-Output ("[{0}] action={1} mcp={2} dryrun={3} status={4} detail={5}" -f $stamp, $action, $mcp, $dryrun, $status, $detail)
}

$slave = Get-SlavePath $mcp
if (-not (Test-Path -LiteralPath $slave)) {
    Write-Summary "error" ("slave-missing:" + $slave)
    exit 2
}

if ($action -eq "status") {
    $marker = Join-Path $repoRoot "proyect_ext/ECC/.ecc-levanta"
    if (Test-Path -LiteralPath $marker) {
        Write-Summary "ok" "active"
        exit 0
    }
    Write-Summary "ok" "inactive"
    exit 0
}

if ($dryrun) {
    Write-Summary "ok" ("would-invoke:" + $slave)
    exit 0
}

# Modo real: solo --run con aprobación queda registrado por el agente que invoca.
& $slave -action $action
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Summary "error" ("slave-exit:" + $code)
    exit $code
}

$marker = Join-Path $repoRoot "proyect_ext/ECC/.ecc-levanta"
"levantado=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss') action=$action mcp=$mcp" | Out-File -FilePath $marker -Encoding utf8 -Force
Write-Summary "ok" ("marker-written:" + $marker)
exit 0
