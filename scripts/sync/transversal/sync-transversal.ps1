#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [036-T004] scripts/sync/transversal/sync-transversal.ps1 - Funcion Sync-TransversalKit extraida
# Extraida de scripts/sync-kit.ps1 lineas 863-1134 (spec 036).
# Sincroniza el kit transversal desde el repositorio maestro hacia el proyecto local.
# =============================================================================

[CmdletBinding()]
. ../lib/common.ps1
Initialize-SyncLog

function Sync-TransversalKit {
<#
.SYNOPSIS
    Sincroniza el kit transversal desde el repositorio maestro hacia el proyecto local.
    Directorios transversales: .github/, .opencode/, .doc_agents/, scripts/
    Archivos transversales: constitution.md, AGENTS.md, opencode.json, README.md,
    sync-agents.ps1, upgrade_framework.ps1.
    NUNCA toca Documentacion/<AppName>/ (frontera kit <-> app).

.DESCRIPTION
    Extraida de Sync-TransversalKit de scripts/sync-kit.ps1 (lineas 863-1134).
    Soporta modo DryRun, origen local via -KitPath, deteccion de huérfanos y poda.
    Estados RESULT: RESULT:sync-transversal:completed | RESULT:sync-transversal:error
#>

param(
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$RootPath = "",
    [string]$OrphanAction = "Preguntar",
    [string]$KitPath = "",
    [switch]$DryRun,
    [switch]$Force
)

if (-not $RootPath) {
    $RootPath = (Split-Path -Parent $PSScriptRoot)
}

$orphanNorm = @{ "borrar" = "Borrar"; "conservar" = "Conservar"; "preguntar" = "Preguntar" }
$orphanKey = "$OrphanAction".Trim().ToLowerInvariant()
if ($orphanNorm.ContainsKey($orphanKey)) { $OrphanAction = $orphanNorm[$orphanKey] } else {
    if ($OrphanAction) { Write-Warn "Sync-TransversalKit: -OrphanAction '$OrphanAction' no valido (Borrar|Conservar|Preguntar). Se usa 'Preguntar'." }
    $OrphanAction = "Preguntar"
}

# Fail-closed: solo https://github.com/ (rechaza http://, git://, ssh, otras hosts).
if ($RepoUrl -notlike "https://github.com/*") {
    throw "[SECURITY] URL no permitida (fail-closed): $RepoUrl (solo https://github.com/)"
}
if (-not (Test-TrustedGithubUrl $RepoUrl)) {
    throw "[SECURITY] Repo maestro no permitido (fail-closed): $RepoUrl (solo https://github.com/<owner en allowlist>/<repo>)"
}

Write-Step "Sincronizando kit transversal desde $RepoUrl..."

# Lista blanca de transversales. Documentacion/<AppName>/ NO figura aqui por diseno.
$transversalDirs = @(".github/", ".opencode/", ".doc_agents/", "scripts/")
$transversalFiles = @(
    ".specify/memory/constitution.md",
    "AGENTS.md",
    "opencode.json",
    "README.md",
    "sync-agents.ps1",
    "upgrade_framework.ps1"
)

if ($DryRun) {
    if ($KitPath) {
        Write-Info "DryRun: fuente LOCAL del kit: $KitPath (sin clonar GitHub; incluye rama y cambios locales sin pushear)"
    } else {
        Write-Info "DryRun: clonaria shallow `"$RepoUrl`" en `$env:TEMP\agents-sync-temp"
    }
    foreach ($d in $transversalDirs) {
        Write-Info "DryRun: copiaria $d -> $(Join-Path $RootPath $d)"
    }
    foreach ($f in $transversalFiles) {
        Write-Info "DryRun: copiaria $f -> $(Join-Path $RootPath $f)"
    }
    Write-Info "DryRun: excluiria .opencode/config.json (posibles credenciales, nunca se copia)"
    Write-Info "DryRun: hash-guard .opencode/.gitignore: si el local existe y difiere del maestro se CONSERVA el local (fail-closed); solo -Force sobrescribe"
    Write-Info "DryRun: NUNCA tocaria Documentacion/<AppName>/ (frontera kit <-> app)"
    Write-Info "DryRun: copiaria la whitelist de tests del kit: tests/harness-default.ps1, tests/kit-sync-merge.ps1, tests/agents-parity.ps1, tests/kb-parity.ps1, tests/mcp-refresh-parity.ps1"
    Write-Info "DryRun: NO trataria tests/ como directorio transversal (los tests propios de la app no se tocan)"
    Write-Info "DryRun: detectaria huerfanos y aplicaria -OrphanAction $OrphanAction"
    Write-OK "RESULT:sync-transversal:completed"
    return
}

$tempDir = Join-Path $env:TEMP "agents-sync-temp"
$ownsTemp = $false
try {
    if ($KitPath) {
        # [002-KITPATH] Fuente local del kit: el checkout local manda (rama +
        # cambios sin pushear incluidos). Fail-closed: solo directorios
        # locales con marcadores de kit; jamas URLs ni el propio destino.
        if ($KitPath -match '^[a-zA-Z][a-zA-Z0-9+.-]*://' -or $KitPath.StartsWith('git@')) {
            throw "[SECURITY] -KitPath no acepta URLs ni esquemas remotos (fail-closed): $KitPath (usa una ruta local, ej. C:\Proyectos\Agents_IA_TECH)"
        }
        try { $kitCanon = [IO.Path]::GetFullPath($KitPath) } catch { throw "sync-kit: -KitPath invalido ($KitPath): $_" }
        if (-not (Test-Path -LiteralPath $kitCanon -PathType Container)) {
            throw "sync-kit: -KitPath no existe o no es un directorio: $kitCanon"
        }
        $missing = @()
        foreach ($m in @("scripts", ".github", ".opencode", ".doc_agents", "AGENTS.md")) {
            if (-not (Test-Path -LiteralPath (Join-Path $kitCanon $m))) { $missing += $m }
        }
        if ($missing.Count -gt 0) {
            throw "sync-kit: -KitPath no parece un checkout del kit (faltan: $($missing -join ', ') en $kitCanon)"
        }
        try { $rootCanon = [IO.Path]::GetFullPath($RootPath) } catch { throw "sync-kit: -RootPath invalido ($RootPath): $_" }
        $sep = [IO.Path]::DirectorySeparatorChar
        if ($kitCanon.TrimEnd($sep) -eq $rootCanon.TrimEnd($sep)) {
            Write-Warn "sync-kit: -KitPath es el propio proyecto destino; no hay nada que sincronizar (se omite)."
            return
        }
        $tempDir = $kitCanon
        $commitHash = "local-kit"
        try {
            $kitBranch = (git -C $kitCanon rev-parse --abbrev-ref HEAD 2>$null)
            $kitShort = (git -C $kitCanon rev-parse --short HEAD 2>$null)
            if ($kitBranch -and $kitShort) { $commitHash = "local-kit ($kitBranch@$kitShort)" }
        } catch { }
        Write-Info "Fuente LOCAL del kit: $kitCanon [$commitHash] (rama y cambios locales incluidos, sin pasar por GitHub)"
    } else {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

        Write-Host "  Clonando repo maestro..." -NoNewline
        git clone --depth 1 $RepoUrl $tempDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host " ERROR" -ForegroundColor Red
            throw "No se pudo clonar el repo maestro $RepoUrl (verifica git y URL)."
        }
        Write-Host " OK" -ForegroundColor Green
        $ownsTemp = $true

        $commitHash = (git -C $tempDir rev-parse --short HEAD 2>$null)
        $commitDate = (git -C $tempDir log -1 --format=%ci 2>$null)
        Write-Info "Version repo maestro: $commitHash ($commitDate)"
    }

    $transversalItems = @(
        @{ Source = (Join-Path $tempDir ".github");                    Target = (Join-Path $RootPath ".github");                    Type = "Dir";  Label = ".github/" },
        @{ Source = (Join-Path $tempDir ".opencode");                  Target = (Join-Path $RootPath ".opencode");                  Type = "Dir";  Label = ".opencode/" },
        @{ Source = (Join-Path $tempDir ".doc_agents");                Target = (Join-Path $RootPath ".doc_agents");                Type = "Dir";  Label = ".doc_agents/" },
        @{ Source = (Join-Path $tempDir "scripts");                    Target = (Join-Path $RootPath "scripts");                    Type = "Dir";  Label = "scripts/" },
        @{ Source = (Join-Path $tempDir ".specify/memory/constitution.md"); Target = (Join-Path $RootPath ".specify/memory/constitution.md"); Type = "File"; Label = ".specify/memory/constitution.md (base)" },
        @{ Source = (Join-Path $tempDir "AGENTS.md");                  Target = (Join-Path $RootPath "AGENTS.md");                  Type = "File"; Label = "AGENTS.md" },
        @{ Source = (Join-Path $tempDir "opencode.json");              Target = (Join-Path $RootPath "opencode.json");              Type = "File"; Label = "opencode.json" },
        @{ Source = (Join-Path $tempDir "README.md");                  Target = (Join-Path $RootPath "README.md");                  Type = "File"; Label = "README.md" },
        @{ Source = (Join-Path $tempDir "sync-agents.ps1");            Target = (Join-Path $RootPath "sync-agents.ps1");            Type = "File"; Label = "sync-agents.ps1" },
        @{ Source = (Join-Path $tempDir "upgrade_framework.ps1");      Target = (Join-Path $RootPath "upgrade_framework.ps1");      Type = "File"; Label = "upgrade_framework.ps1" }
    )

    foreach ($item in $transversalItems) {
        $src = $item.Source
        $dst = $item.Target
        $dstDir = if ($item.Type -eq "File") { Split-Path $dst -Parent } else { $dst }
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        if ($item.Type -eq "Dir") {
            Write-Host "  [SYNC] $($item.Label)" -ForegroundColor Cyan
            if ($item.Label -eq ".opencode/") {
                # hash-guard .opencode/.gitignore: si el local difiere del maestro -> conservar local.
                $masterGi = Join-Path $src ".gitignore"
                $localGi = Join-Path $dst ".gitignore"
                $giGuardHold = $false
                if ((Test-Path -LiteralPath $masterGi -PathType Leaf) -and (Test-Path -LiteralPath $localGi -PathType Leaf) -and (-not $Force)) {
                    try {
                        $mh = (Get-FileHash -LiteralPath $masterGi -Algorithm SHA256 -ErrorAction Stop).Hash
                        $lh = (Get-FileHash -LiteralPath $localGi -Algorithm SHA256 -ErrorAction Stop).Hash
                        if ($mh -ne $lh) {
                            Write-Warn "  [GUARD] .opencode/.gitignore local difiere del maestro: se CONSERVA el local (fail-closed). Usa -Force para sobrescribir."
                            $giGuardHold = $true
                        }
                    } catch {
                        Write-Warn "  [GUARD] No se pudo comparar .opencode/.gitignore (hash fallo): se conserva el local por seguridad."
                        $giGuardHold = $true
                    }
                }
                # Seguridad: nunca copiar .opencode/config.json (posibles credenciales).
                if ($giGuardHold) {
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" ".gitignore" >$null 2>&1
                } else {
                    robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XF "config.json" >$null 2>&1
                }
                # Verificar que .opencode/.gitignore existe tras el sync; si falta -> restaurar desde el maestro.
                if (-not (Test-Path -LiteralPath $localGi -PathType Leaf)) {
                    if (Test-Path -LiteralPath $masterGi -PathType Leaf) {
                        Write-Warn "  [GUARD] .opencode/.gitignore ausente tras sync: se restaura desde el maestro."
                        Copy-Item -LiteralPath $masterGi -Destination $localGi -Force
                    } else {
                        Write-Warn "  [GUARD] .opencode/.gitignore ausente en local y en maestro: proteccion de secrets degradada; no hacer commit de config.json."
                    }
                } else {
                    try {
                        $giTextAfter = Get-Content -LiteralPath $localGi -Raw -ErrorAction Stop
                        if ($giTextAfter -notmatch '(?m)^config\.json\s*$') {
                            Write-Warn "  [GUARD] .opencode/.gitignore local SIN linea 'config.json': proteccion de secrets degradada; revisalo antes de commitear."
                        }
                    } catch { }
                }
                # Baseline lib/bin: si aparecen contenidos -> WARN supply-chain.
                foreach ($ab in @("lib", "bin")) {
                    $abFull = Join-Path $dst $ab
                    try {
                        if (Test-Path -LiteralPath $abFull) {
                            $abFiles = @(Get-ChildItem -LiteralPath $abFull -Recurse -File -Force -ErrorAction Stop)
                            if ($abFiles.Count -gt 0) {
                                Write-Warn "  [GUARD] .opencode/$ab con $($abFiles.Count) archivo(s): tratar como NO confiable hasta pin+hash en manifest (supply-chain); no ejecutar sin verificar."
                            }
                        }
                    } catch { }
                }
            } else {
                robocopy "$src" "$dst" /E /NDL /NFL /NJH /NJS /XD "context-mode" >$null 2>&1
            }
        } else {
            # 034: archivos de raiz con politica de merge (no SKIP). Se
            # resuelven antes de la regla SKIP para que apliquen con y sin -Force.
            if ($item.Label -eq "opencode.json") {
                Write-Host "  [MERGE] opencode.json (merge por claves)" -ForegroundColor Cyan
                Merge-OpenCodeConfig -Source $src -Destination $dst -ProjectRoot $RootPath -Force:$Force
                continue
            }
            if ($item.Label -eq "AGENTS.md") {
                Write-Host "  [MERGE] AGENTS.md (bloque delimitado)" -ForegroundColor Cyan
                Merge-KitBlock -Source $src -Destination $dst
                continue
            }
            if ((Test-Path $dst) -and (-not $Force)) {
                $comparison = Compare-KitFileState -Source $src -Destination $dst
                if ($comparison -eq 'Equal') {
                    Write-OK "  [OK] $($item.Label) - contenido identico"
                } elseif ($comparison -eq 'EolOnly') {
                    Write-Info "  [INFO] $($item.Label) - solo difiere el fin de linea"
                } else {
                    Write-Warn "  [SKIP] $($item.Label) - contenido distinto; usa -Force para sobrescribir"
                }
                continue
            }
            Write-Host "  [FILE] $($item.Label)" -ForegroundColor Cyan
            Copy-Item $src -Destination $dst -Force
        }
    }

    # 034 / T18: tests/ es de las apps, NO es un directorio transversal. Solo
    # viaja esta whitelist, copiada por nombre exacto (una app puede tener sus
    # propios tests/ y no se tocan). Si el archivo no esta en el maestro -> INFO,
    # nunca se crea vacio.
    $kitTestWhitelist = @(
        "tests/harness-default.ps1",
        "tests/kit-sync-merge.ps1",
        "tests/agents-parity.ps1",
        "tests/kb-parity.ps1",
        "tests/mcp-refresh-parity.ps1"
    )
    $testsDir = Join-Path $RootPath "tests"
    foreach ($rel in $kitTestWhitelist) {
        $testSrc = Join-Path $tempDir $rel
        if (Test-Path -LiteralPath $testSrc -PathType Leaf) {
            if (-not (Test-Path -LiteralPath $testsDir)) {
                New-Item -ItemType Directory -Path $testsDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $testSrc -Destination (Join-Path $RootPath $rel) -Force
            Write-Host "  [SYNC] $rel" -ForegroundColor Cyan
        } else {
            Write-Info "  [INFO] $rel no esta en el maestro; se omite"
        }
    }

    # Seguridad: confirmar que .opencode/config.json del kit NO se copio.
    $kitConfig = Join-Path $tempDir ".opencode\config.json"
    if (Test-Path $kitConfig) {
        Write-Warn "Se excluye .opencode/config.json (posibles credenciales) de la sincronizacion."
    }

    # Manejo de huerfanos (dentro del try: $tempDir sigue disponible).
    $orphans = @(Find-OrphanKitFiles -RootPath $RootPath -TempDir $tempDir)
    Invoke-OrphanDecision -Orphans $orphans -RootPath $RootPath -OrphanAction $OrphanAction

    Write-OK "RESULT:sync-transversal:completed"
}
catch {
    Write-Warn "Error en Sync-TransversalKit: $_"
    Write-OK "RESULT:sync-transversal:error"
}
finally {
    # [002-KITPATH] Solo se borra el clon temporal propio; la fuente local
    # del kit (-KitPath) jamas se toca.
    if ($ownsTemp -and (Test-Path $tempDir)) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}
}