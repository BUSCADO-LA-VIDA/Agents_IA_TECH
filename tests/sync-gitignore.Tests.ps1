<#
.SYNOPSIS
    Test de contrato para scripts/sync-gitignore.ps1 (Spec 037).

.DESCRIPTION
    Valida que el script de sincronización de .gitignore:
      1. Existe en scripts/sync-gitignore.ps1 (FR-037-01).
      2. Agrega el bloque graphify-out/* a un .gitignore de raíz (FR-037-02).
      3. Es idempotente: una segunda ejecución no duplica bloques (FR-037-03).
      4. No modifica el contenido propio del .gitignore (FR-037-04).
      5. Maneja gracefulmente la ausencia de .gitignore (FR-037-05).
      6. Aplica el catálogo completo de carpetas no versionables (FR-037-08).
      7. Excluye node_modules/.git/venv/vendor/backups del recorrido (FR-037-07).
      8. -RemoveBlock revierte exactamente lo agregado (FR-037-09).

    No usa Pester: se ejecuta con `pwsh -NoProfile -File tests/sync-gitignore.Tests.ps1`
    y devuelve exit 0 si todo pasa, exit 1 si algo falla.

.NOTES
    Dominio: implementador (developer). Vive en tests/.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root 'scripts/sync-gitignore.ps1'

$failures = 0
$passes = 0

function Assert {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
        $script:passes++
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        $script:failures++
    }
}

function Get-Text {
    param([string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return '' }
    return (Get-Content -LiteralPath $LiteralPath -Raw)
}

Write-Host "== Test contrato sync-gitignore (Spec 037) ==" -ForegroundColor Cyan

# --- FR-037-01: el script existe ---
Assert (Test-Path $scriptPath) "FR-037-01: scripts/sync-gitignore.ps1 existe"

# --- Fixture ---
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("sync-gitignore-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$rootGi = Join-Path $temp '.gitignore'
$originalRootContent = "# proyecto propietario`n/datos`n*.tmp`n"
Set-Content -Path $rootGi -Value $originalRootContent -NoNewline

$excludedDirs = @('node_modules', '.git', '.venv', 'vendor', '.kit-backup-manual')
foreach ($dir in $excludedDirs) {
    $full = Join-Path $temp $dir
    New-Item -ItemType Directory -Path $full -Force | Out-Null
    Set-Content -Path (Join-Path $full '.gitignore') -Value "# third-party`n*" -NoNewline
}

try {
    # --- FR-037-02 / FR-037-08: aplica el catálogo completo en la raíz ---
    & pwsh -NoProfile -File $scriptPath -Path $temp | Out-Null
    $c = Get-Text $rootGi
    Assert ($c -match 'graphify-out/\*') "FR-037-02: agrega graphify-out/* al .gitignore raíz"
    Assert ($c -match 'node_modules/' -and $c -match '\.venv/' -and $c -match '\.kit-backup/' -and $c -match '\.playwright-mcp/' -and $c -match '\*\.log') "FR-037-08: agrega dependencias, backups, caches y logs"
    Assert ($c -match '# 1\. Dependencias' -and $c -match '# 2\. Artefactos' -and $c -match '# 3\. Backups' -and $c -match '# 4\. Caches' -and $c -match '# 5\. Logs' -and $c -match '# 6\. Sistema') "FR-037-08: los 6 bloques quedan identificados por su cabecera"

    # --- FR-037-04: preserva el contenido propio ---
    Assert ($c -match '/datos' -and $c -match '\*\.tmp' -and $c -match '# proyecto propietario') "FR-037-04: preserva el contenido original del .gitignore"

    # --- FR-037-03: idempotencia ---
    & pwsh -NoProfile -File $scriptPath -Path $temp | Out-Null
    $c2 = Get-Text $rootGi
    $graphifyCount = ([regex]::Matches($c2, 'graphify-out/\*')).Count
    $depsCount = ([regex]::Matches($c2, '# 1\. Dependencias')).Count
    Assert (($graphifyCount -eq 1) -and ($depsCount -eq 1)) "FR-037-03: idempotente (graphify=$graphifyCount, deps=$depsCount tras 2 corridas)"

    # --- FR-037-07: exclusiones (con -AllGitignore, que es el modo agresivo) ---
    & pwsh -NoProfile -File $scriptPath -Path $temp -AllGitignore | Out-Null
    $leaked = @()
    foreach ($dir in $excludedDirs) {
        $candidate = Join-Path (Join-Path $temp $dir) '.gitignore'
        if ((Get-Text $candidate) -match 'graphify-out') { $leaked += $dir }
    }
    Assert ($leaked.Count -eq 0) "FR-037-07: no toca rutas excluidas (fugas: $($leaked -join ', '))"

    # --- FR-037-05: ausencia de .gitignore no falla ---
    $emptyDir = Join-Path $temp 'empty-proj'
    New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
    $exit = 0
    try {
        & pwsh -NoProfile -File $scriptPath -Path $emptyDir | Out-Null
    } catch { $exit = 1 }
    Assert ($exit -eq 0) "FR-037-05: ausencia de .gitignore no produce error fatal"

    # --- FR-037-09: rollback exacto ---
    # Se simula un overreach: se inyecta el bloque dentro de node_modules y vendor.
    & pwsh -NoProfile -File $scriptPath -Path $temp -AllGitignore -Exclude 'zzz-no-existe' | Out-Null
    $nmGi = Join-Path (Join-Path $temp 'node_modules') '.gitignore'
    $vdGi = Join-Path (Join-Path $temp 'vendor') '.gitignore'
    Assert (((Get-Text $nmGi) -match 'graphify-out') -and ((Get-Text $vdGi) -match 'graphify-out')) "Rollback: fixture con overreach simulado en rutas excluidas"

    & pwsh -NoProfile -File $scriptPath -Path $temp -AllGitignore -RemoveBlock -OnlyExcluded | Out-Null
    $nmAfter = Get-Text $nmGi
    $vdAfter = Get-Text $vdGi
    $rootAfter = Get-Text $rootGi
    Assert ((-not ($nmAfter -match 'graphify-out|node_modules/|# 1\. Dependencias')) -and (-not ($vdAfter -match 'graphify-out|node_modules/'))) "FR-037-09: -RemoveBlock limpia las rutas excluidas"
    Assert ($nmAfter.Trim() -eq "# third-party`n*") "FR-037-09: la reversión deja el archivo de terceros como estaba"
    Assert ($rootAfter -match 'graphify-out' -and $rootAfter -match '/datos') "FR-037-09: la reversión NO toca las raíces legítimas"

    # --- FR-037-09b: reversión del formato legacy (sep + header + sep + regla, sin cierre) ---
    $legacyGi = Join-Path (Join-Path $temp '.venv') '.gitignore'
    $legacy = "# third-party`n*`n`n#-----------------------------------------------------------------------------`n# 4. Caches de herramientas del kit (graphify) - se regeneran con graphify update`n#-----------------------------------------------------------------------------`ngraphify-out/*"
    Set-Content -LiteralPath $legacyGi -Value $legacy -NoNewline
    & pwsh -NoProfile -File $scriptPath -Path $temp -RemoveBlock -OnlyExcluded | Out-Null
    $legacyAfter = (Get-Text $legacyGi).Trim()
    Assert ($legacyAfter -eq "# third-party`n*") "FR-037-09b: revierte el formato legacy sin dejar restos"

    # --- Filtro -Sets ---
    & pwsh -NoProfile -File $scriptPath -Path $temp -RemoveBlock | Out-Null
    & pwsh -NoProfile -File $scriptPath -Path $temp -Sets deps | Out-Null
    $c3 = Get-Text $rootGi
    Assert (($c3 -match '# 1\. Dependencias') -and (-not ($c3 -match 'graphify-out')) -and ($c3 -match '/datos')) "Filtro -Sets deps: aplica solo ese bloque y preserva el contenido"
}
finally {
    Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "== Resumen: PASS=$passes FAIL=$failures ==" -ForegroundColor Cyan
if ($failures -gt 0) { exit 1 } else { exit 0 }
