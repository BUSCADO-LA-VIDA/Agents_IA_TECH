# 🔄 Script de Sincronización del Kit de Agentes (Actualizado)

> Este script sincroniza **solo los archivos transversales del kit** (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`).  
> **NUNCA toca** `Documentacion/<AppName>/` de ninguna app — cada app tiene su documentación propia.

```powershell
<# 
.SYNOPSIS
    Sincroniza el kit de agentes transversal desde el repo maestro.
    NO toca Documentacion/<AppName>/ de ninguna aplicación.

.DESCRIPTION
    Este script copia/actualiza:
    - .github/ (agents, prompts, skills, copilot-instructions.md)
    - .opencode/ (agents, commands, config.json)
    - .doc_agents/ (estructura-aplicacion.md, capacidad-base.md, memoria-proyecto-template.md)
    - .specify/memory/constitution.md (versión base)
    - AGENTS.md, opencode.json, README.md, sync-agents.ps1
    
    Crea directorios si no existen.
    Sobrescribe archivos existentes en las carpetas transversales.
    NO modifica ni borra nada en Documentacion/<AppName>/.
#>

param (
    [string]$SourcePath = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO_MAESTRO/main",
    [switch]$Force,
    [switch]$DryRun
)

$TransversalPaths = @(
    ".github",
    ".opencode",
    ".doc_agents",
    ".specify/memory/constitution.md",
    "AGENTS.md",
    "opencode.json",
    "README.md",
    "sync-agents.ps1"
)

$ExcludedPaths = @(
    "Documentacion/*"  # NUNCA tocar documentación por app
)

Write-Host "=== Sincronización Kit de Agentes Transversal ===" -ForegroundColor Cyan
Write-Host "Origen: $SourcePath" -ForegroundColor Gray
Write-Host "Modo: $(if ($DryRun) { 'DRY-RUN (simulación)' } else { 'REAL' })" -ForegroundColor Yellow

foreach ($path in $TransversalPaths) {
    $fullPath = Join-Path $PSScriptRoot $path
    
    if ($path -like "*.md" -or $path -like "*.json" -or $path -like "*.ps1") {
        # Archivo individual
        $dir = Split-Path $fullPath -Parent
        if (-not (Test-Path $dir)) {
            if (-not $DryRun) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Write-Host "  [DIR]  Creando: $dir" -ForegroundColor Green
        }
        Write-Host "  [FILE] $(if ($DryRun) { 'Simulando' } else { 'Actualizando' }): $path" -ForegroundColor Cyan
        if (-not $DryRun) {
            # Aquí iría la descarga real: Invoke-WebRequest "$SourcePath/$path" -OutFile $fullPath
            Write-Host "    (Implementar descarga real desde $SourcePath/$path)" -ForegroundColor Gray
        }
    } else {
        # Directorio completo
        if (-not (Test-Path $fullPath)) {
            if (-not $DryRun) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
            Write-Host "  [DIR]  Creando: $path" -ForegroundColor Green
        }
        Write-Host "  [DIR]  $(if ($DryRun) { 'Simulando sync' } else { 'Sincronizando' }): $path/" -ForegroundColor Cyan
        if (-not $DryRun) {
            # Aquí iría la sincronización real del directorio
            Write-Host "    (Implementar sync real de $SourcePath/$path/)" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Excluidos (NUNCA se tocan) ===" -ForegroundColor Yellow
$ExcludedPaths | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }

Write-Host "`n$(if ($DryRun) { 'Simulación completada. Ejecuta sin -DryRun para aplicar.' } else { 'Sincronización completada.' })" -ForegroundColor Green
```

> **Nota**: Este es el template en `.doc_agents/`. El `sync-agents.ps1` real en la raíz del repo debe implementar la descarga/sync real desde tu repo maestro.