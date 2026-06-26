<#
.SYNOPSIS
    Sincroniza .github/ desde Agents_IA_TECH sin tocar Documentacion/ del proyecto.
.DESCRIPTION
    Descarga agentes, skills y prompts actualizados desde el repo central
    (https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH.git) a la carpeta .github/
    del proyecto actual. Documentacion/ nunca se modifica.
.EXAMPLE
    .\sync-agents.ps1
#>

$repoUrl  = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH.git"
$tempDir  = Join-Path $env:TEMP "agents-sync-temp"
$target   = Join-Path (Get-Location) ".github"

Write-Host "🧠 Sync Agents_IA_TECH" -ForegroundColor Cyan

# 1. Limpiar temp si existe
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

# 2. Clonar shallow
Write-Host "  📦 Clonando..." -NoNewline
git clone --depth 1 $repoUrl $tempDir 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host " ERROR" -ForegroundColor Red
    Write-Error "No se pudo clonar el repo. Verificá que git esté instalado y la URL sea correcta."
    exit 1
}
Write-Host " OK" -ForegroundColor Green

# 3. Copiar .github/ del repo clonado al proyecto
$source = Join-Path $tempDir ".github"
if (-not (Test-Path $source)) {
    Write-Error "El repo clonado no contiene la carpeta .github/"
    Remove-Item $tempDir -Recurse -Force
    exit 1
}

Write-Host "  📁 Copiando a .github/..." -NoNewline
Copy-Item "$source\*" $target -Recurse -Force
Write-Host " OK" -ForegroundColor Green

# 4. Limpiar temp
Remove-Item $tempDir -Recurse -Force

# 5. Resumen
$count = (Get-ChildItem $target -Recurse -File).Count
Write-Host "`n✅ Sync completado. $count archivos en .github/" -ForegroundColor Green
Write-Host "   Documentacion/ NO fue modificada." -ForegroundColor Yellow
