#!/usr/bin/env pwsh
# scripts/sync-gitignore.ps1 — Sincroniza reglas del kit en los .gitignore
# Objetivo: que ningún proyecto versionado suba dependencias, entornos virtuales,
#           artefactos de build, backups del kit ni caches de herramientas.
#           Según Spec 036 (RF-011) y Spec 037: graphify-out/ nunca se sube.
#
# Frontera de seguridad:
#   - Solo abre archivos llamados exactamente '.gitignore'.
#   - NUNCA entra en node_modules, .git, .venv, vendor, caches ni backups.
#   - NUNCA genera graphify, NUNCA toca graphify-out/, NUNCA commitea.
#   - Idempotente: cada bloque se identifica por su cabecera y no se duplica.
#
# Uso:
#   .\scripts\sync-gitignore.ps1                                  # raíces de proyecto de .
#   .\scripts\sync-gitignore.ps1 -Path "C:\Proyectos\X" -WhatIf   # simulación
#   .\scripts\sync-gitignore.ps1 -Sets graphify,deps              # solo esos bloques
#   .\scripts\sync-gitignore.ps1 -AllGitignore                    # todo .gitignore, no solo raíces
#   .\scripts\sync-gitignore.ps1 -RemoveBlock -OnlyExcluded       # rollback de rutas excluidas

#requires -Version 7.0

param(
    [string]$Path = ".",
    # Bloques a aplicar: all | deps | build | kit | graphify | logs | os
    [string[]]$Sets = @('all'),
    [switch]$Force,
    [switch]$WhatIf,
    # Revierte los bloques del kit en lugar de agregarlos.
    [switch]$RemoveBlock,
    # Procesa únicamente los .gitignore que están dentro de rutas excluidas (limpieza).
    [switch]$OnlyExcluded,
    # Con -RemoveBlock: elimina también líneas de regla huérfanas (sin cabecera).
    [switch]$PruneRules,
    # Procesa todos los .gitignore del árbol, no solo el de cada raíz de proyecto.
    [switch]$AllGitignore,
    # Sobrescribe la lista de directorios excluidos.
    [string[]]$Exclude
)

# Directorios que NUNCA deben recibir reglas: dependencias, entornos virtuales,
# metadatos de git, artefactos de build, backups del kit y caches de herramientas.
$defaultExcluded = @(
    '.git'
    'node_modules'
    '.venv'
    'venv'
    'env'
    'site-packages'
    '__pycache__'
    '.pytest_cache'
    '.mypy_cache'
    '.ruff_cache'
    '.tox'
    'vendor'
    'dist'
    'build'
    'bin'
    'obj'
    'target'
    'packages'
    '.next'
    '.nuxt'
    '.cache'
    '.terraform'
    'graphify-out'
    '.kit-backup'
    '.kit-backup-manual'
    '.kit-sync-temp'
    'revisar_manualmente'
    'proyect_ext'
)

if ($Exclude -and $Exclude.Count -gt 0) {
    $excludedNames = $Exclude | ForEach-Object { $_.ToLowerInvariant() }
} else {
    $excludedNames = $defaultExcluded | ForEach-Object { $_.ToLowerInvariant() }
}

function Test-ExcludedPath {
    param(
        [Parameter(Mandatory)][string]$FullName,
        [Parameter(Mandatory)][string]$Root,
        # $true cuando se evalúa un directorio (todos los segmentos cuentan).
        [switch]$AsDirectory
    )
    $relative = [System.IO.Path]::GetRelativePath($Root, $FullName)
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -eq '.') { return $false }
    $segments = $relative -split '[\\/]'
    $limit = if ($AsDirectory) { $segments.Count } else { $segments.Count - 1 }
    for ($i = 0; $i -lt $limit; $i++) {
        if ($excludedNames -contains $segments[$i].ToLowerInvariant()) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Catálogo de bloques. El orden de las claves es el orden de escritura.
# 'Detect' es el patrón que indica que el bloque ya está presente (idempotencia).
# ---------------------------------------------------------------------------
$catalog = [ordered]@{
    deps     = @{
        Detect = '# 1\. Dependencias'
        Header = '# 1\. Dependencias'
        Lines  = @(
            '# 1. Dependencias y entornos virtuales (se reinstalan con el gestor de paquetes)'
            'node_modules/'
            '.venv/'
            'venv/'
            '__pycache__/'
            '*.py[cod]'
            '.pytest_cache/'
            '.mypy_cache/'
            '.ruff_cache/'
            '.tox/'
            'vendor/'
        )
    }
    build    = @{
        Detect = '# 2\. Artefactos'
        Header = '# 2\. Artefactos'
        Lines  = @(
            '# 2. Artefactos de build (se regeneran con el build)'
            'dist/'
            'build/'
            'out/'
            'coverage/'
            '*.tsbuildinfo'
        )
    }
    kit      = @{
        Detect = '# 3\. Backups'
        Header = '# 3\. Backups'
        Lines  = @(
            '# 3. Backups y temporales del kit (se regeneran con bootstrap/sync)'
            '.kit-backup/'
            '.kit-backup-manual/'
            '.kit-sync-temp/'
            'opencode.json.bak-*'
            'AGENTS.md.bak-*'
        )
    }
    graphify = @{
        Detect = 'graphify-out'
        Header = '# 4\. Caches'
        Lines  = @(
            '# 4. Caches de herramientas del kit (graphify) - se regeneran con graphify update'
            'graphify-out/*'
            '.playwright-mcp/'
        )
    }
    logs     = @{
        Detect = '# 5\. Logs'
        Header = '# 5\. Logs'
        Lines  = @(
            '# 5. Logs y temporales (no se versionan)'
            '*.log'
            '!.bootstrap-audit.log'
            'logs/'
            'tmp/'
            'temp/'
        )
    }
    os       = @{
        Detect = '# 6\. Sistema'
        Header = '# 6\. Sistema'
        Lines  = @(
            '# 6. Sistema y editor'
            'Thumbs.db'
            '.DS_Store'
            '.idea/'
        )
    }
}

if ($Sets -contains 'all' -or $Sets.Count -eq 0) {
    $selectedSets = @($catalog.Keys)
} else {
    $unknown = @($Sets | Where-Object { -not $catalog.Contains($_) })
    if ($unknown.Count -gt 0) {
        Write-Host "ERROR: sets desconocidos: $($unknown -join ', '). Válidos: $($catalog.Keys -join ', '), all" -ForegroundColor Red
        exit 1
    }
    $selectedSets = @($Sets)
}

function New-BlockText {
    param([string[]]$Lines)
    $sep = '#-----------------------------------------------------------------------------'
    $body = (@('', $sep) + $Lines + @($sep)) -join "`n"
    return $body + "`n"
}

# Quita un bloque del kit de forma exacta. Soporta los dos formatos históricos:
#   A) sep + header + sep + reglas          (formato original, sin cierre)
#   B) sep + header + reglas + sep          (formato actual, con cierre)
function Remove-KitBlock {
    param(
        [string]$Content,
        [string]$Detect
    )
    $lines = $Content -split "\r?\n"
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    $removed = $false
    while ($i -lt $lines.Count) {
        if ($lines[$i] -match '^#-{10,}\s*$' -and ($i + 1) -lt $lines.Count -and $lines[$i + 1] -match $Detect) {
            while ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
            $i += 2
            if ($i -lt $lines.Count -and $lines[$i] -match '^#-{10,}\s*$') {
                # Formato A: separador de cierre de la cabecera y luego reglas sueltas.
                $i++
                while ($i -lt $lines.Count -and $lines[$i] -ne '' -and $lines[$i] -notmatch '^#-{10,}\s*$') { $i++ }
            } else {
                # Formato B: reglas hasta el separador de cierre.
                while ($i -lt $lines.Count -and $lines[$i] -notmatch '^#-{10,}\s*$') { $i++ }
                $i++
            }
            $removed = $true
            continue
        }
        $out.Add($lines[$i])
        $i++
    }
    return @{
        Content = ($out -join "`n")
        Removed = $removed
    }
}

$rootFull = (Resolve-Path -Path $Path -ErrorAction SilentlyContinue).Path
if (-not $rootFull) {
    Write-Host "ERROR: la ruta no existe: $Path" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Selección de archivos
# ---------------------------------------------------------------------------
if ($AllGitignore -or $OnlyExcluded) {
    $found = Get-ChildItem -Path $rootFull -Recurse -Filter '.gitignore' -File -Force -ErrorAction SilentlyContinue
} else {
    # Raíces de proyecto: la ruta indicada + todo directorio que tenga su propio .git
    $rootDirs = @($rootFull)
    $nestedGit = Get-ChildItem -Path $rootFull -Recurse -Depth 8 -Directory -Force -Filter '.git' -ErrorAction SilentlyContinue
    foreach ($gitDir in $nestedGit) {
        $parent = $gitDir.Parent.FullName
        if (Test-ExcludedPath -FullName $parent -Root $rootFull -AsDirectory) { continue }
        if ($rootDirs -notcontains $parent) { $rootDirs += $parent }
    }
    $found = @()
    foreach ($dir in $rootDirs) {
        $candidate = Join-Path $dir '.gitignore'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $found += Get-Item -LiteralPath $candidate -Force
        }
    }
    if (-not $found) {
        Write-Host "No se encontró .gitignore en ninguna raíz de proyecto de: $rootFull"
        return
    }
}

$selected = @()
$excludedCount = 0
foreach ($file in ($found | Sort-Object FullName -Unique)) {
    $isExcluded = Test-ExcludedPath -FullName $file.FullName -Root $rootFull
    if ($isExcluded) { $excludedCount++ }
    if ($OnlyExcluded) {
        if ($isExcluded) { $selected += $file }
    } else {
        if (-not $isExcluded) { $selected += $file }
    }
}

if (-not $selected) {
    Write-Host "No hay .gitignore en el conjunto seleccionado ($rootFull)."
    Write-Host "  Excluidos por política: $excludedCount"
    return
}

# ---------------------------------------------------------------------------
# Aplicación
# ---------------------------------------------------------------------------
$changedFiles = 0
$changedBlocks = 0
$skipped = 0

foreach ($file in $selected) {
    try {
        $raw = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
    } catch {
        Write-Host "WARN: no se pudo leer $($file.FullName); se omite." -ForegroundColor Yellow
        continue
    }
    if ($null -eq $raw) { $raw = '' }
    $original = $raw

    foreach ($setName in $selectedSets) {
        $set = $catalog[$setName]

        if ($RemoveBlock) {
            $result = Remove-KitBlock -Content $raw -Detect $set.Header
            if ($result.Removed) {
                $raw = $result.Content
                $changedBlocks++
            } else {
                $skipped++
            }
            continue
        }

        if ($raw -match $set.Detect) {
            $skipped++
            continue
        }

        $raw = $raw.TrimEnd("`r", "`n") + "`n" + (New-BlockText -Lines $set.Lines)
        $changedBlocks++
    }

    if ($RemoveBlock -and $PruneRules) {
        # Líneas huérfanas que dejaron versiones previas sin cabecera.
        $pruned = New-Object System.Collections.Generic.List[string]
        $removedLines = 0
        foreach ($line in ($raw -split "\r?\n")) {
            if ($line -match '^\s*(graphify-out/\*|\.playwright-mcp/)\s*$') {
                $removedLines++
                continue
            }
            $pruned.Add($line)
        }
        if ($removedLines -gt 0) {
            $raw = $pruned -join "`n"
            $changedBlocks += $removedLines
        }
    }

    if ($raw -ne $original) {
        if ($RemoveBlock) {
            $raw = $raw.TrimEnd("`r", "`n") + "`n"
        }
        if ($WhatIf) {
            $verb = if ($RemoveBlock) { 'Quitaría' } else { 'Agregaría' }
            Write-Host "[WhatIf] $verb bloques a: $($file.FullName)" -ForegroundColor DarkYellow
            $changedFiles++
            continue
        }
        try {
            Set-Content -LiteralPath $file.FullName -Value $raw -NoNewline -Force:$Force -ErrorAction Stop
            $verb = if ($RemoveBlock) { 'REVERTIDO' } else { 'OK' }
            Write-Host "$($verb): $($file.FullName)" -ForegroundColor Green
            $changedFiles++
        } catch {
            Write-Host "WARN: no se pudo escribir $($file.FullName): $_" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if ($RemoveBlock) {
    Write-Host "Archivos revertidos: $changedFiles"
} else {
    Write-Host "Archivos actualizados: $changedFiles"
    Write-Host "Sets aplicados: $($selectedSets -join ', ')"
}
Write-Host "Bloques modificados: $changedBlocks"
Write-Host "Bloques ya presentes / sin cambios: $skipped"
Write-Host "Total archivos seleccionados: $($selected.Count)"
Write-Host "Excluidos por política (node_modules, .git, venv, vendor, backups, caches): $excludedCount"
if (-not $RemoveBlock) {
    Write-Host "Recordá revisar y commitear los .gitignore modificados (el script no commitea)."
}
