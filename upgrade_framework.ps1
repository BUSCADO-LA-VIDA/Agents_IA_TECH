#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# upgrade_framework.ps1
# =============================================================================
# Entrypoint CLI para el agente upgrade_framework.
# Gestiona la sincronización de dependencias externas según dependencias-manifest.yml
# clona/actualiza repositorios en proyect_ext/ y registra herramientas (graphify via uv).
#
# Uso:
#   & "C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1" -RootPath "C:\Proyectos\trading_bot" -ForceUpgradeTools -DryRun
#   & "C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1" -RootPath "C:\Proyectos\trading_bot"
#
# Parámetros:
#   -RootPath (obligatorio): Ruta raíz del proyecto donde buscar dependencias-manifest.yml
#   -ForceUpgradeTools: Fuerza la actualización de herramientas (uv tool install graphifyy[mcp])
#   -DryRun: Simula las acciones sin escribir nada (fail-open: exit code 0 siempre)
#
# Requisito: PowerShell 7+ (pwsh ≥ 7). No funciona en Windows PowerShell 5.1.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RootPath,

    [switch]$ForceUpgradeTools,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Funciones de logging estructurado
# =============================================================================
function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

# =============================================================================
# Validaciones de seguridad y containment
# =============================================================================

# Allowlist de owners de confianza para validar URLs (fail-closed)
$TrustedOwners = @(
    "BUSCADO-LA-VIDA",
    "github",
    "microsoft",
    "DeusData",
    "mksglu",
    "ajvikram",
    "Graphify-Labs"
)

function Test-TrustedGithubUrl {
    param([string]$Url)
    # Solo https://github.com/<owner>/<repo> con owner en allowlist
    if ($Url -notmatch '^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$') {
        return $false
    }
    $owner = $matches[1]
    return $TrustedOwners -contains $owner
}

# Verificación de containment: ruta debe estar dentro de proyect_ext/
function Test-ProyectExtContainment {
    param([string]$Path, [string]$RootPath)
    $proyectExtRoot = Join-Path $RootPath "proyect_ext"
    $canonicalProyectExt = [IO.Path]::GetFullPath($proyectExtRoot)
    $canonicalPath = [IO.Path]::GetFullPath($Path)
    $sep = [IO.Path]::DirectorySeparatorChar
    return $canonicalPath.StartsWith($canonicalProyectExt + $sep, [StringComparison]::OrdinalIgnoreCase)
}

# =============================================================================
# Lectura del manifest YAML (parser simple para evitar dependencias)
# =============================================================================
function Read-DependenciasManifest {
    param([string]$RootPath)
    
    $manifestFile = Join-Path $RootPath "dependencias-manifest.yml"
    if (-not (Test-Path -LiteralPath $manifestFile)) {
        Write-Warn "No existe dependencias-manifest.yml en $manifestFile"
        return @()
    }
    
    $content = Get-Content -Path $manifestFile -Raw
    
    # Parser simple para la sección dependencias_externas
    # Busca entradas: - nombre: ... url: ... rama: ... tipo: ...
    $deps = @()
    
    # Buscar la sección dependencias_externas
    $sectionMatch = [regex]::Match($content, '(?ms)^dependencias_externas:\s*\r?\n(.*)$')
    if (-not $sectionMatch.Success) {
        Write-Warn "No se encontró sección 'dependencias_externas:' en el manifest"
        return @()
    }
    
    $section = $sectionMatch.Groups[1].Value
    
    # Regex para extraer cada dependencia
    $pattern = '(?ms)^  - nombre:\s*(\S+)\s*\r?\n    url:\s*(\S+)\s*\r?\n    rama:\s*(\S+)\s*\r?\n(?:.*?\r?\n)*?    tipo:\s*(\S+)\s*$'
    foreach ($m in [regex]::Matches($section, $pattern)) {
        $dep = @{
            Nombre = $m.Groups[1].Value
            Url = $m.Groups[2].Value
            Rama = $m.Groups[3].Value
            Tipo = $m.Groups[4].Value
        }
        $deps += $dep
    }
    
    return $deps
}

# =============================================================================
# Funciones de ejecución segura (fail-open)
# =============================================================================
function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Command,
        [string[]]$Args = @(),
        [switch]$DryRun
    )
    
    if ($DryRun) {
        Write-Info "DryRun: $Command $($Args -join ' ')"
        return 0
    }
    
    try {
        & $Command @Args 2>&1 | Out-String
        return $LASTEXITCODE
    }
    catch {
        Write-Warn "Comando falló sin romper el flujo: $Command $($Args -join ' '). Error: $_"
        return 1
    }
}

function Ensure-Directory {
    param([string]$Path, [switch]$DryRun)
    
    if (-not (Test-Path -LiteralPath $Path)) {
        if ($DryRun) {
            Write-Info "DryRun: crear directorio $Path"
        } else {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        Write-OK "Directorio listo: $Path"
    }
    return $true
}

# =============================================================================
# Copia idempotente del manifest template
# =============================================================================
function Ensure-ManifestTemplate {
    param(
        [string]$RootPath,
        [string]$MasterManifestPath,
        [switch]$DryRun
    )
    
    $targetManifest = Join-Path $RootPath "dependencias-manifest.yml"
    
    if (Test-Path -LiteralPath $targetManifest) {
        Write-OK "dependencias-manifest.yml ya existe en $RootPath (no se sobrescribe)"
        return $true
    }
    
    if (-not (Test-Path -LiteralPath $MasterManifestPath)) {
        Write-Warn "Manifest maestro no encontrado en $MasterManifestPath; no se puede copiar plantilla"
        return $false
    }
    
    if ($DryRun) {
        Write-Info "DryRun: copiar plantilla manifest $MasterManifestPath -> $targetManifest"
        return $true
    }
    
    try {
        Copy-Item -LiteralPath $MasterManifestPath -Destination $targetManifest -Force
        Write-OK "Plantilla de manifest copiada: $targetManifest"
        return $true
    }
    catch {
        Write-Warn "No se pudo copiar la plantilla del manifest: $_"
        return $false
    }
}

# =============================================================================
# Clonar/actualizar repositorio Git (shallow, --depth=1)
# =============================================================================
function Sync-GitRepository {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Branch,
        [string]$RootPath,
        [switch]$DryRun
    )
    
    $destDir = Join-Path $RootPath "proyect_ext\$Name"
    
    # Verificación de containment
    if (-not (Test-ProyectExtContainment -Path $destDir -RootPath $RootPath)) {
        Write-Warn "[$Name] Ruta fuera de containment ($destDir); se omite (fail-closed)"
        return $false
    }
    
    # Validar URL en allowlist
    if (-not (Test-TrustedGithubUrl $Url)) {
        Write-Warn "[$Name] URL no permitida por allowlist: $Url (fail-closed)"
        return $false
    }
    
    # Deshabilitar submodules (seguridad)
    $gitArgs = @("--no-recurse-submodules")
    
    if (Test-Path -LiteralPath (Join-Path $destDir ".git")) {
        # Repositorio existe: fetch + reset
        Write-Step "[$Name] Actualizando repositorio existente..."
        
        if ($DryRun) {
            Write-Info "DryRun: git -C $destDir fetch origin $Branch --depth=1"
            Write-Info "DryRun: git -C $destDir reset --hard FETCH_HEAD"
            return $true
        }
        
        $exitCode = Invoke-CommandSafe -Command "git" -Args @("git", "-C", $destDir, "fetch", "origin", $Branch, "--depth=1") -DryRun:$DryRun
        if ($exitCode -ne 0) {
            Write-Warn "[$Name] git fetch falló (exit $exitCode); se continúa"
            return $false
        }
        
        $exitCode = Invoke-CommandSafe -Command "git" -Args @("git", "-C", $destDir, "reset", "--hard", "FETCH_HEAD") -DryRun:$DryRun
        if ($exitCode -ne 0) {
            Write-Warn "[$Name] git reset falló (exit $exitCode); se continúa"
            return $false
        }
        
        Write-OK "[$Name] Repositorio actualizado en $destDir"
        return $true
    }
    else {
        # Repositorio no existe: clone shallow
        Write-Step "[$Name] Clonando repositorio (shallow)..."
        
        Ensure-Directory -Path (Split-Path $destDir -Parent) -DryRun:$DryRun
        
        if ($DryRun) {
            Write-Info "DryRun: git clone --depth=1 --branch $Branch $Url $destDir"
            return $true
        }
        
        $exitCode = Invoke-CommandSafe -Command "git" -Args @("git", "clone", "--depth=1", "--branch", $Branch, $Url, $destDir) -DryRun:$DryRun
        if ($exitCode -ne 0) {
            Write-Warn "[$Name] git clone falló (exit $exitCode); se continúa"
            return $false
        }
        
        Write-OK "[$Name] Repositorio clonado en $destDir"
        return $true
    }
}

# =============================================================================
# Instalar/actualizar graphify via uv tool
# =============================================================================
function Sync-Graphify {
    param(
        [switch]$ForceUpgradeTools,
        [switch]$DryRun
    )
    
    Write-Step "[graphify] Sincronizando via uv tool..."
    
    if (-not $ForceUpgradeTools) {
        Write-Info "[graphify] -ForceUpgradeTools no especificado; se omite instalación forzada"
        return $true
    }
    
    if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
        Write-Warn "[graphify] 'uv' no está en el PATH; no se puede instalar graphifyy[mcp]"
        return $false
    }
    
    if ($DryRun) {
        Write-Info "DryRun: uv tool install \"graphifyy[mcp]\" --force"
        return $true
    }
    
    $exitCode = Invoke-CommandSafe -Command "uv" -Args @("uv", "tool", "install", "graphifyy[mcp]", "--force") -DryRun:$DryRun
    if ($exitCode -ne 0) {
        Write-Warn "[graphify] uv tool install falló (exit $exitCode); se continúa (fail-open)"
        return $false
    }
    
    Write-OK "[graphify] Instalado/actualizado via uv tool"
    return $true
}

# =============================================================================
# Función principal de sincronización
# =============================================================================
function Invoke-UpgradeFrameworkSync {
    param(
        [string]$RootPath,
        [switch]$ForceUpgradeTools,
        [switch]$DryRun
    )
    
    # Resolver ruta absoluta
    $resolvedRoot = (Resolve-Path $RootPath).Path
    Write-Info "Ruta del proyecto resuelta: $resolvedRoot"
    
    # 1. Copiar manifest template si no existe
    $masterManifest = Join-Path (Split-Path $PSScriptRoot -Parent) "dependencias-manifest.yml"
    # El manifest maestro está en la raíz del kit (donde está este script)
    if (-not (Test-Path -LiteralPath $masterManifest)) {
        $masterManifest = Join-Path (Split-Path $PSScriptRoot) "dependencias-manifest.yml"
    }
    
    Ensure-ManifestTemplate -RootPath $resolvedRoot -MasterManifestPath $masterManifest -DryRun:$DryRun
    
    # 2. Leer manifest
    $dependencies = Read-DependenciasManifest -RootPath $resolvedRoot
    if ($dependencies.Count -eq 0) {
        Write-Warn "No se encontraron dependencias en el manifest; nada que sincronizar"
        return $true
    }
    
    Write-Step "Dependencias encontradas: $($dependencies.Count)"
    foreach ($dep in $dependencies) {
        Write-Info "  - $($dep.Nombre) ($($dep.Tipo)): $($dep.Url) @ $($dep.Rama)"
    }
    
    # 3. Procesar cada dependencia
    $allSuccess = $true
    
    foreach ($dep in $dependencies) {
        try {
            switch ($dep.Tipo) {
                "git" {
                    $success = Sync-GitRepository -Name $dep.Nombre -Url $dep.Url -Branch $dep.Rama -RootPath $resolvedRoot -DryRun:$DryRun
                    if (-not $success) { $allSuccess = $false }
                }
                "uv tool" {
                    if ($dep.Nombre -eq "graphify") {
                        $success = Sync-Graphify -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun
                        if (-not $success) { $allSuccess = $false }
                    }
                    else {
                        Write-Warn "[$($dep.Nombre)] Tipo 'uv tool' no reconocido para esta dependencia; se omite"
                    }
                }
                default {
                    Write-Warn "[$($dep.Nombre)] Tipo de dependencia desconocido: $($dep.Tipo); se omite"
                }
            }
        }
        catch {
            Write-Warn "[$($dep.Nombre)] Error inesperado: $_; se continúa (fail-open)"
            $allSuccess = $false
        }
    }
    
    # 4. Asegurar que proyect_ext/ existe (para tokenslayer build posterior)
    Ensure-Directory -Path (Join-Path $resolvedRoot "proyect_ext") -DryRun:$DryRun
    
    if ($allSuccess) {
        Write-OK "Sincronización de dependencias completada exitosamente"
        return 0
    }
    else {
        Write-Warn "Sincronización completada con advertencias (fail-open: exit code 0)"
        return 0  # FAIL-OPEN: siempre exit code 0
    }
}

# =============================================================================
# MAIN
# =============================================================================
try {
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " upgrade_framework - Sincronización de dependencias externas" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Info "RootPath: $RootPath"
    Write-Info "ForceUpgradeTools: $ForceUpgradeTools"
    Write-Info "DryRun: $DryRun"
    
    $exitCode = Invoke-UpgradeFrameworkSync -RootPath $RootPath -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun
    
    Write-Host "===============================================================" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host " DryRun completado - no se realizaron cambios" -ForegroundColor Yellow
    } else {
        Write-Host " Sincronización finalizada" -ForegroundColor Green
    }
    Write-Host "===============================================================" -ForegroundColor Cyan
    
    # FAIL-OPEN: siempre exit code 0
    exit 0
}
catch {
    Write-Fail "Error crítico en upgrade_framework: $_"
    Write-Warn "Fail-open: continuando con exit code 0"
    exit 0
}