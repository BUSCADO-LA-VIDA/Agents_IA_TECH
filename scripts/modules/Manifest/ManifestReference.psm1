# ManifestReference.psm1 — Lee el manifest de referencia del KIT (014-manifest).
#
# La referencia vive en <RootPath>/proyect_ext/dependencias-manifest.yml
# (plantilla versionada con flags `upgrade:` por herramienta). Si no existe se
# avisa y se devuelve $null (fail-open para el llamador); jamás se inventa.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Logging local: las funciones Write-* del bootstrap NO resuelven dentro del
# ámbito del módulo.
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Warning $Message }
$yamlHelper = Join-Path (Split-Path -Parent $here) 'Utils\YamlHelper.psm1'
if ((Test-Path -LiteralPath $yamlHelper) -and -not (Get-Command Read-Yaml -ErrorAction SilentlyContinue)) {
    Import-Module $yamlHelper -Force
}

function Get-ManifestReference {
    param(
        [string]$RootPath = '.',
        [string]$ReferencePath = ''
    )
    if (-not $ReferencePath) {
        $ReferencePath = Join-Path $RootPath 'proyect_ext\dependencias-manifest.yml'
    }
    if (-not (Test-Path -LiteralPath $ReferencePath)) {
        Write-Warn "Get-ManifestReference: sin referencia en $ReferencePath (se omite sync de versiones)."
        return $null
    }
    try {
        return Read-Yaml $ReferencePath
    } catch {
        Write-Warn "Get-ManifestReference: no se pudo parsear $ReferencePath : $_"
        return $null
    }
}

Export-ModuleMember -Function Get-ManifestReference
