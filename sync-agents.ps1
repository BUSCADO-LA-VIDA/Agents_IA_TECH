<#
.SYNOPSIS
    Sincroniza .github/ desde Agents_IA_TECH sin tocar Documentacion/ del proyecto.
.DESCRIPTION
    Descarga agentes, skills y prompts actualizados desde el repo central
    a la carpeta .github/ del proyecto actual. Documentacion/ nunca se modifica.
    El script debe estar en la raiz del proyecto (junto a la carpeta .github/).
.EXAMPLE
    .\sync-agents.ps1
.NOTES
    Usa $env:TEMP para la clonacion temporal, nunca toca Documentacion/.
#>

$repoUrl  = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH.git"
$tempDir  = Join-Path $env:TEMP "agents-sync-temp"
$target   = Join-Path $PSScriptRoot ".github"

# Validar que el target no sea un subdirectorio de .github/
$parentDir = Split-Path $PSScriptRoot -Leaf
if ($parentDir -eq ".github" -or $PSScriptRoot -like "*\.github*") {
    Write-Host "[ERROR] El script esta DENTRO de una carpeta .github/" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Estas en:          $PSScriptRoot" -ForegroundColor Yellow
    Write-Host "  Deberias estar en: $(Split-Path $PSScriptRoot -Parent)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Corre esto para moverlo:" -ForegroundColor Cyan
    Write-Host "  move '$PSCommandPath' '$(Split-Path $PSScriptRoot -Parent)\sync-agents.ps1'" -ForegroundColor White
    exit 1
}

Write-Host "Target: $target"

# 1. Limpiar temp si existe
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Clonar shallow
Write-Host "Clonando..." -NoNewline
git clone --depth 1 $repoUrl $tempDir 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host " ERROR" -ForegroundColor Red
    Write-Error "No se pudo clonar el repo. Verifica que git este instalado y la URL sea correcta."
    exit 1
}
Write-Host " OK" -ForegroundColor Green

# 3. Copiar .github/ del repo clonado al proyecto
$source = Join-Path $tempDir ".github"
if (-not (Test-Path $source)) {
    Write-Error "El repo clonado no contiene la carpeta .github/"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Copiando a .github/..." -NoNewline
robocopy "$source" "$target" /E /NDL /NFL /NJH /NJS >$null 2>&1
Write-Host " OK" -ForegroundColor Green

# 4. Limpiar temp (Force para archivos readonly de git)
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# 5. Resumen
$count = (Get-ChildItem $target -Recurse -File).Count
Write-Host "`nSync completado. $count archivos en .github/" -ForegroundColor Green
Write-Host "Documentacion/ NO fue modificada." -ForegroundColor Yellow
