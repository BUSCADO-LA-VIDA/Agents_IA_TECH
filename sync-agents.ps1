<#
.SYNOPSIS
    Wrapper que delega la sincronización del KIT TRANSVERSAL DE AGENTES en
    Sync-TransversalKit del instalador/actualizador único
    (scripts/plataformador-bootstrap.ps1 -SyncOnly). Opción A, ADR-0003.
.DESCRIPTION
    La lógica de sincronización del kit transversal (Opción A del ADR-0003)
    vive ahora en `Sync-TransversalKit` dentro de `plataformador-bootstrap.ps1`.
    Este script solo reenvía la llamada, preservando compatibilidad con los
    parámetros previos:
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
    Delegación como PROCESO HIJO (no dot-sourcing): el bootstrap NO tiene
    guard anti-ejecución al cargar (su MAIN en líneas ~1349+ corre
    incondicionalmente al hacer dot-sourcing, ejecutaría el flujo completo).
    Por eso se invoca con -SyncOnly. El switch -SyncOnly SÍ existe en el
    bootstrap (param + rama MAIN "Modo sync únicamente"), así que se usa
    directamente. Mapeo: -DryRun→-DryRun, -Force→-Force, -RepoUrl→-RepoUrl.
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

# El bootstrap vive en scripts\plataformador-bootstrap.ps1 (raíz del repo)
$bootstrapPath = Join-Path $PSScriptRoot "scripts\plataformador-bootstrap.ps1"

if (-not (Test-Path $bootstrapPath)) {
    Write-Host "[ERROR] No se encontró el instalador/actualizador único: $bootstrapPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== sync-agents.ps1 → delegando en Sync-TransversalKit (bootstrap) ===" -ForegroundColor Cyan
Write-Host "Repo origen: $RepoUrl" -ForegroundColor Gray
Write-Host "Modo: $(if ($DryRun) { 'DRY-RUN (simulación)' } else { 'REAL' })" -ForegroundColor Yellow
Write-Host "EXCLUIDOS (nunca se tocan): Documentacion/<AppName>/, src/, tests/ de las apps, .opencode/config.json" -ForegroundColor DarkGray
Write-Host ""

$invokeArgs = @{ SyncOnly = $true; DryRun = $DryRun; Force = $Force; RepoUrl = $RepoUrl }

& $bootstrapPath @invokeArgs
exit $LASTEXITCODE
