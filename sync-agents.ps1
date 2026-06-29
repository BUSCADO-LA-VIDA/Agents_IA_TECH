<#
.SYNOPSIS
    Sincroniza .github/ y Documentacion/ desde Agents_IA_TECH al proyecto local.
.DESCRIPTION
    Descarga agentes, skills y prompts actualizados desde el repo central.
    .github/ se sobreescribe siempre con la ultima version.
    Documentacion/ solo crea estructura y archivos faltantes, nunca modifica existentes.
    El script debe estar en la raiz del proyecto (junto a la carpeta .github/).
.EXAMPLE
    .\sync-agents.ps1
.NOTES
    Usa $env:TEMP para la clonacion temporal.
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

# 2b. Capturar version del repo central
$commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
$commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
$syncInfo = @{
    repo     = $repoUrl
    commit   = $commitHash
    date     = $commitDate
    syncDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
$syncInfo | ConvertTo-Json | Set-Content (Join-Path $sourceGithub "sync-info.json")
Write-Host "Version: $commitHash ($commitDate)" -ForegroundColor Cyan

# 3. Sincronizar .github/ — sobreescribe siempre
$sourceGithub = Join-Path $tempDir ".github"
if (-not (Test-Path $sourceGithub)) {
    Write-Error "El repo clonado no contiene la carpeta .github/"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Sincronizando .github/ (sobreescribe)..." -NoNewline
robocopy "$sourceGithub" "$target" /E /NDL /NFL /NJH /NJS >$null 2>&1
Write-Host " OK" -ForegroundColor Green

# 4. Sincronizar Documentacion/ — solo crea archivos faltantes, no modifica existentes
$sourceDocs = Join-Path $tempDir "Documentacion"
$targetDocs = Join-Path $PSScriptRoot "Documentacion"

if (Test-Path $sourceDocs) {
    Write-Host "Sincronizando Documentacion/ (solo faltantes)..." -NoNewline
    
    $addedCount = 0
    
    Get-ChildItem $sourceDocs -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceDocs.Length + 1)
        $destPath = Join-Path $targetDocs $relativePath
        
        if (-not (Test-Path $destPath)) {
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $_.FullName -Destination $destPath
            $addedCount++
        }
    }
    
    if ($addedCount -gt 0) {
        Write-Host " OK (+$addedCount archivos nuevos)" -ForegroundColor Green
    } else {
        Write-Host " OK (todo actualizado)" -ForegroundColor Green
    }
}

# 5. Limpiar temp (Force para archivos readonly de git)
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# 6. Resumen
$countGithub = (Get-ChildItem $target -Recurse -File).Count
Write-Host "`nSync completado." -ForegroundColor Green
Write-Host "  Commit:   $commitHash ($commitDate)" -ForegroundColor Cyan
Write-Host "  .github/: $countGithub archivos (sobreescrito)" -ForegroundColor Green
if (Test-Path $targetDocs) {
    $countDocs = (Get-ChildItem $targetDocs -Recurse -File).Count
    Write-Host "  Documentacion/: $countDocs archivos (solo faltantes agregados)" -ForegroundColor Yellow
}
Write-Host "`n  Verifica cambios con: git diff .github/" -ForegroundColor Gray
