<#
.SYNOPSIS
    Wrapper que delega la sincronización del KIT TRANSVERSAL DE AGENTES en
    scripts/sync-kit.ps1 (motor de sync). Opción A, ADR-0003.
.DESCRIPTION
    La lógica de sincronización del kit transversal (Opción A del ADR-0003)
    vive en `scripts/sync-kit.ps1`. Este script solo reenvía la llamada con
    la interfaz simplificada (Spec 002):
    - -RepoUrl (repo maestro; default https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH)
    - -DryRun  (simula sin escribir)
    - -Force   (fuerza sobrescritura)

    NUNCA toca Documentacion/<AppName>/ de ninguna aplicación —
    cada app tiene su propia documentación aislada y propia.
    EXCLUIDOS (nunca se tocan): Documentacion/<AppName>/, src/, tests/
    de las apps, ni .opencode/config.json (posibles credenciales).
.EXAMPLE
    .\sync-agents.ps1
    .\sync-agents.ps1 -DryRun
    .\sync-agents.ps1 -DryRun -RepoUrl "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH"
.NOTES
    ADR-0003 / spec plataforma-bootstrap-instalador-unico (T-I4).
    Delegación como PROCESO HIJO (no dot-sourcing). Invoca directo al motor
    scripts/sync-kit.ps1 (el bootstrap ya no expone modo sync: interfaz
    simplificada Spec 002 — sin parametros / -DryRun / -Force).
    Mapeo: -DryRun→-DryRun, -Force→-Force, -RepoUrl→-RepoUrl.
#>

[CmdletBinding()]
param (
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [switch]$DryRun,
    [switch]$Force
)

# Validar que el script esté en la raíz del proyecto (no dentro del kit)
$parentDir = Split-Path $PSScriptRoot -Leaf
if ($parentDir -eq ".github" -or $parentDir -eq ".opencode" -or $parentDir -eq ".doc_agents") {
    Write-Host "[ERROR] El script está DENTRO de una carpeta del kit (.github/, .opencode/, .doc_agents/)" -ForegroundColor Red
    Write-Host "  Estás en:          $PSScriptRoot" -ForegroundColor Yellow
    Write-Host "  Deberías estar en: $(Split-Path $PSScriptRoot -Parent)" -ForegroundColor Green
    exit 1
}

# El motor de sync vive en scripts\sync-kit.ps1 (raíz del repo). Si falta es
# porque aún no corrió el bootstrap: él lo descarga del maestro en frío.
$syncKitPath = Join-Path $PSScriptRoot "scripts\sync-kit.ps1"

if (-not (Test-Path -LiteralPath $syncKitPath)) {
    Write-Host "[ERROR] No se encontró el motor de sync: $syncKitPath" -ForegroundColor Red
    Write-Host "  Ejecuta primero .\scripts\plataformador-bootstrap.ps1 (lo descarga del maestro) y reintenta." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== sync-agents.ps1 → delegando en scripts/sync-kit.ps1 ===" -ForegroundColor Cyan
Write-Host "Repo origen: $RepoUrl" -ForegroundColor Gray
Write-Host "Modo: $(if ($DryRun) { 'DRY-RUN (simulación)' } else { 'REAL' })" -ForegroundColor Yellow
Write-Host "EXCLUIDOS (nunca se tocan): Documentacion/<AppName>/, src/, tests/ de las apps, .opencode/config.json" -ForegroundColor DarkGray
Write-Host ""

$syncArgs = @("-RepoUrl", $RepoUrl, "-RootPath", $PSScriptRoot, "-OrphanAction", "Preguntar")
if ($DryRun) { $syncArgs += "-DryRun" }
if ($Force)  { $syncArgs += "-Force" }

pwsh -NoProfile -File $syncKitPath @syncArgs
exit $LASTEXITCODE
