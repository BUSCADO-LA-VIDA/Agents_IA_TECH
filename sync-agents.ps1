<#
.SYNOPSIS
    Sincroniza el KIT TRANSVERSAL DE AGENTES desde el repo maestro.
.DESCRIPTION
    Descarga y actualiza SOLO los archivos transversales del kit:
    - .github/ (agents, prompts, skills, copilot-instructions.md)
    - .opencode/ (agents, commands, config.json)
    - .doc_agents/ (estructura por app, capacidad-base, templates)
    - .specify/memory/constitution.md (versión base)
    - AGENTS.md, opencode.json, README.md, sync-agents.ps1
    
    NUNCA toca Documentacion/<AppName>/ de ninguna aplicación —  
    cada app tiene su propia documentación aislada y propia.
    
    El script debe estar en la raiz del proyecto/repo (junto a .github/).
.EXAMPLE
    .\sync-agents.ps1
    .\sync-agents.ps1 -DryRun
.NOTES
    Usa $env:TEMP para la clonacion temporal.
    Parámetros: -DryRun (simula sin escribir), -Force (fuerza sobrescritura)
#>

param (
    [string]$RepoUrl = "https://github.com/TU_USUARIO/TU_REPO_MAESTRO.git",
    [switch]$DryRun,
    [switch]$Force
)

$tempDir = Join-Path $env:TEMP "agents-sync-temp"

# Validar que el script esté en la raíz del proyecto
$parentDir = Split-Path $PSScriptRoot -Leaf
if ($parentDir -eq ".github" -or $parentDir -eq ".opencode" -or $parentDir -eq ".doc_agents") {
    Write-Host "[ERROR] El script está DENTRO de una carpeta del kit (.github/, .opencode/, .doc_agents/)" -ForegroundColor Red
    Write-Host "  Estás en:          $PSScriptRoot" -ForegroundColor Yellow
    Write-Host "  Deberías estar en: $(Split-Path $PSScriptRoot -Parent)" -ForegroundColor Green
    exit 1
}

Write-Host "=== Sincronización Kit Transversal de Agentes ===" -ForegroundColor Cyan
Write-Host "Repo origen: $RepoUrl" -ForegroundColor Gray
Write-Host "Modo: $(if ($DryRun) { 'DRY-RUN (simulación)' } else { 'REAL' })" -ForegroundColor Yellow
Write-Host ""

# 1. Limpiar temp si existe
if (Test-Path $tempDir) {
    if (-not $DryRun) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}

# 2. Clonar shallow
if (-not $DryRun) {
    Write-Host "Clonando repo maestro..." -NoNewline
    git clone --depth 1 $RepoUrl $tempDir 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host " ERROR" -ForegroundColor Red
        Write-Error "No se pudo clonar el repo. Verifica git y URL."
        exit 1
    }
    Write-Host " OK" -ForegroundColor Green
}

# Rutas fuente en el repo clonado
$sourceGithub   = Join-Path $tempDir ".github"
$sourceOpencode = Join-Path $tempDir ".opencode"
$sourceDocAgents = Join-Path $tempDir ".doc_agents"
$sourceSpecify   = Join-Path $tempDir ".specify/memory/constitution.md"
$sourceAgentsMd  = Join-Path $tempDir "AGENTS.md"
$sourceOpencodeJson = Join-Path $tempDir "opencode.json"
$sourceReadme    = Join-Path $tempDir "README.md"
$sourceScript    = Join-Path $tempDir "sync-agents.ps1"

# Capturar versión del repo maestro
if (-not $DryRun) {
    $commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
    $commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
    Write-Host "Versión repo maestro: $commitHash ($commitDate)" -ForegroundColor Cyan
}

# Auto-actualizar este script
$thisScript = $PSCommandPath
if (-not $DryRun -and (Test-Path $sourceScript) -and ((Get-FileHash $sourceScript).Hash -ne (Get-FileHash $thisScript).Hash)) {
    Copy-Item $sourceScript -Destination $thisScript -Force
    Write-Host "Script auto-actualizado. Re-ejecutando..." -ForegroundColor Yellow
    & $thisScript @PSBoundParameters
    exit 0
}

# 3. Sincronizar archivos/carpetas transversales
$transversalItems = @(
    @{ Source = $sourceGithub;   Target = Join-Path $PSScriptRoot ".github";        Type = "Dir";  Label = ".github/" },
    @{ Source = $sourceOpencode; Target = Join-Path $PSScriptRoot ".opencode";      Type = "Dir";  Label = ".opencode/" },
    @{ Source = $sourceDocAgents;Target = Join-Path $PSScriptRoot ".doc_agents";    Type = "Dir";  Label = ".doc_agents/" },
    @{ Source = $sourceSpecify;  Target = Join-Path $PSScriptRoot ".specify/memory/constitution.md"; Type = "File"; Label = ".specify/memory/constitution.md (base)" },
    @{ Source = $sourceAgentsMd; Target = Join-Path $PSScriptRoot "AGENTS.md";       Type = "File"; Label = "AGENTS.md" },
    @{ Source = $sourceOpencodeJson; Target = Join-Path $PSScriptRoot "opencode.json"; Type = "File"; Label = "opencode.json" },
    @{ Source = $sourceReadme;   Target = Join-Path $PSScriptRoot "README.md";      Type = "File"; Label = "README.md" },
    @{ Source = $sourceScript;   Target = Join-Path $PSScriptRoot "sync-agents.ps1"; Type = "File"; Label = "sync-agents.ps1" }
)

$updatedCount = 0
$createdCount = 0

foreach ($item in $transversalItems) {
    $src = $item.Source
    $dst = $item.Target
    $label = $item.Label
    
    if (-not (Test-Path $src)) {
        Write-Host "  [SKIP] $label — no existe en repo maestro" -ForegroundColor DarkGray
        continue
    }
    
    $dstDir = if ($item.Type -eq "File") { Split-Path $dst -Parent } else { $dst }
    
    if (-not (Test-Path $dstDir)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Write-Host "  [DIR]  Creando directorio: $dstDir" -ForegroundColor Green
        $createdCount++
    }
    
    if ($item.Type -eq "Dir") {
        Write-Host "  [SYNC] $label" -ForegroundColor Cyan
        if (-not $DryRun) {
            robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS >$null 2>&1
            $updatedCount++
        }
    } else {
        Write-Host "  [FILE] $label" -ForegroundColor Cyan
        if (-not $DryRun) {
            Copy-Item $src -Destination $dst -Force
            $updatedCount++
        }
    }
}

# 4. NUNCA tocar Documentacion/<AppName>/ — cada app tiene la suya propia
Write-Host "" 
Write-Host "=== EXCLUIDOS (NUNCA se tocan) ===" -ForegroundColor Yellow
Write-Host "  Documentacion/<AppName>/  ← Documentación propia de cada app" -ForegroundColor DarkGray
Write-Host "  src/                      ← Código de cada app" -ForegroundColor DarkGray
Write-Host "  tests/                    ← Tests de cada app" -ForegroundColor DarkGray

# 5. Limpiar temp
if (-not $DryRun) {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 6. Resumen
if (-not $DryRun) {
    Write-Host "`n=== Resumen ===" -ForegroundColor Green
    Write-Host "  Directorios creados: $createdCount" -ForegroundColor Green
    Write-Host "  Items actualizados:  $updatedCount" -ForegroundColor Green
    Write-Host "  Commit:              $commitHash ($commitDate)" -ForegroundColor Cyan
    Write-Host "`n  Verifica cambios con: git diff .github/ .opencode/ .doc_agents/" -ForegroundColor Gray
} else {
    Write-Host "`n[DRY-RUN] Simulación completada. Ejecuta sin -DryRun para aplicar." -ForegroundColor Yellow
}
