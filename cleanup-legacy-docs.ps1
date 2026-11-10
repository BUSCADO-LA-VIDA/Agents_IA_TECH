# Limpieza legacy de Documentacion/ raiz (one-off historico).
# Estos archivos ya viven en Documentacion/<AppName>/.
#
# [044-RF-08] Sin rutas de la maquina del autor y sin borrado implicito:
#   - la raiz se deriva de la ubicacion del script;
#   - sin -Confirm solo muestra que haria (dry-run por defecto).
#
# Uso:
#   pwsh ./cleanup-legacy-docs.ps1            # dry-run
#   pwsh ./cleanup-legacy-docs.ps1 -Confirm   # ejecuta

param([switch]$Confirm)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$docRoot = Join-Path $root 'Documentacion'

$files = @(
    'capacidad-base.md',
    'idioma.md',
    'preferencias.md',
    'preferencias-git.md',
    'referencias.md',
    'roadmap.md',
    'pendientes-implementacion.md',
    'soluciones-conocidas.md',
    'memoria-proyecto.md'
)

$dirs = @('arquitectura', 'funcionalidades', 'bitacoras', 'agents')

Write-Host "Raiz del proyecto: $root"
foreach ($name in $files) {
    $target = Join-Path $docRoot $name
    if (Test-Path -LiteralPath $target) {
        if ($Confirm) { Remove-Item -LiteralPath $target -Force; Write-Host "eliminado: $target" }
        else { Write-Host "dry-run: eliminaria $target" }
    }
}

foreach ($name in $dirs) {
    $target = Join-Path $docRoot $name
    if (Test-Path -LiteralPath $target) {
        if ($Confirm) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "eliminado: $target" }
        else { Write-Host "dry-run: eliminaria $target (recursivo)" }
    }
}

if (-not $Confirm) { Write-Host 'Dry-run: no se modifico nada. Re-ejecuta con -Confirm para aplicar.' }
