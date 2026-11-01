#requires -Version 7.0
# tests/kit-sync-merge.ps1
# Spec 034 (T20): contrato de Compare-KitFileState, Merge-OpenCodeConfig y
# Merge-KitBlock de scripts/sync-kit.ps1. PowerShell plano, sin Pester.
#   exit 0 = todos los escenarios OK | exit 1 = al menos un fallo.
#
# No se hace dot-source de scripts/sync-kit.ps1: eso ejecutaria el sync real
# sobre esta maquina. Se parsea el archivo con el parser de PowerShell, se
# extraen los FunctionDefinitionAst de las tres funciones y se evaluan en el
# scope de este script.
#
# Todos los fixtures viven en un directorio temporal: nunca se escribe en el
# repositorio (verificable con git status antes/despues).

$ErrorActionPreference = 'Stop'

# --- Stubs de logging del motor (las funciones reales las invocan) ------------
function Write-OK   { param([string]$Message) }
function Write-Warn { param([string]$Message) }
function Write-Info { param([string]$Message) }
function Write-Fail { param([string]$Message) }

$script:Failures = 0
$script:Checks = 0
$script:Scenarios = 0

function Write-Case {
    param([bool]$Ok, [string]$Name)
    $script:Checks++
    if ($Ok) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        $script:Failures++
    }
}

function New-CaseDir {
    param([string]$Name)
    $dir = Join-Path $script:TmpRoot $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Text,
        [switch]$Bom
    )
    $enc = [System.Text.UTF8Encoding]::new([bool]$Bom)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Get-TextFile {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path)
}

function Write-JsonFile {
    param(
        [string]$Path,
        $Object
    )
    Write-TextFile -Path $Path -Text (ConvertTo-Json -InputObject $Object -Depth 10)
}

function Read-JsonFile {
    param([string]$Path)
    return (Get-TextFile $Path) | ConvertFrom-Json
}

# --- Carga de las funciones bajo prueba --------------------------------------
$repoRoot = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $repoRoot 'scripts/sync-kit.ps1'

if (-not (Test-Path -LiteralPath $enginePath)) {
    Write-Host "FAIL: no existe $enginePath" -ForegroundColor Red
    exit 1
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($enginePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) {
    Write-Host "FAIL: scripts/sync-kit.ps1 no parsea ($($parseErrors.Count) error(es) de sintaxis)" -ForegroundColor Red
    foreach ($pe in $parseErrors) { Write-Host ("  - " + $pe.Message) -ForegroundColor Red }
    exit 1
}

$wantedFunctions = @('Compare-KitFileState', 'Merge-OpenCodeConfig', 'Merge-KitBlock')
$foundFunctions = @{}
$allFunctions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
foreach ($fn in $allFunctions) {
    if (($wantedFunctions -contains $fn.Name) -and (-not $foundFunctions.ContainsKey($fn.Name))) {
        $foundFunctions[$fn.Name] = $fn
    }
}

$missing = @()
foreach ($name in $wantedFunctions) {
    if (-not $foundFunctions.ContainsKey($name)) { $missing += $name }
}
if ($missing.Count -gt 0) {
    foreach ($name in $missing) {
        Write-Host "FAIL: funcion $name no encontrada en scripts/sync-kit.ps1" -ForegroundColor Red
    }
    exit 1
}

foreach ($name in $wantedFunctions) {
    . ([scriptblock]::Create($foundFunctions[$name].Extent.Text))
}

Write-Host "=== kit-sync-merge (spec 034): contrato de merge del sync del kit ==="
Write-Host ""

$script:TmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('kit-sync-merge-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:TmpRoot -Force | Out-Null

try {
    # =========================================================================
    # Escenario 1: Compare-KitFileState
    # =========================================================================
    $script:Scenarios++
    $dir1 = New-CaseDir 'scenario1-compare'
    $sameText = "linea1`nlinea2`n"
    $cmpSrc = Join-Path $dir1 'src.txt'
    $cmpDst = Join-Path $dir1 'dst.txt'

    Write-TextFile -Path $cmpSrc -Text $sameText
    Copy-Item -LiteralPath $cmpSrc -Destination $cmpDst -Force
    Write-Case ((Compare-KitFileState -Source $cmpSrc -Destination $cmpDst) -eq 'Equal') '1a Compare: identicos -> Equal'

    Write-TextFile -Path $cmpDst -Text "linea1`r`nlinea2`r`n"
    Write-Case ((Compare-KitFileState -Source $cmpSrc -Destination $cmpDst) -eq 'EolOnly') '1b Compare: LF vs CRLF mismo contenido -> EolOnly'

    Write-TextFile -Path $cmpDst -Text "linea1`nlinea2 distinta`n"
    Write-Case ((Compare-KitFileState -Source $cmpSrc -Destination $cmpDst) -eq 'Different') '1c Compare: contenido distinto -> Different'

    Write-TextFile -Path $cmpDst -Text $sameText -Bom
    Write-Case ((Compare-KitFileState -Source $cmpSrc -Destination $cmpDst) -eq 'Different') '1d Compare: BOM en uno solo -> Different'

    # =========================================================================
    # Escenario 2: Merge-OpenCodeConfig (merge por claves)
    # =========================================================================
    $script:Scenarios++
    $dir2 = New-CaseDir 'scenario2-merge-keys'
    $master2 = Join-Path $dir2 'master'
    New-Item -ItemType Directory -Path $master2 -Force | Out-Null
    $master2Path = Join-Path $master2 'opencode.json'
    Write-JsonFile -Path $master2Path -Object ([ordered]@{
            '$schema'       = 'https://opencode.ai/config.json'
            'default_agent' = 'pensador'
            'instructions'  = @('AGENTS.md')
        })

    $servers2 = [ordered]@{}
    for ($i = 1; $i -le 8; $i++) {
        $servers2["servidor$i"] = [ordered]@{ type = 'local'; command = @("srv$i") }
    }
    $dst2 = Join-Path $dir2 'opencode.json'
    Write-JsonFile -Path $dst2 -Object ([ordered]@{
            'model'         = 'mi/modelo-propio'
            'default_agent' = 'build'
            'permission'    = [ordered]@{ edit = 'allow'; bash = [ordered]@{ 'git *' = 'allow' } }
            'mcp'           = [ordered]@{ timeout = [ordered]@{ startup = 180000 }; servers = $servers2 }
        })

    $null = Merge-OpenCodeConfig -Source $master2Path -Destination $dst2 -ProjectRoot $dir2

    $res2 = $null
    $parseOk2 = $true
    try { $res2 = Read-JsonFile -Path $dst2 } catch { $parseOk2 = $false }
    Write-Case $parseOk2 '2a Merge: el resultado es JSON valido'
    if ($parseOk2) {
        Write-Case ($res2.default_agent -eq 'pensador') '2b Merge: default_agent build -> pensador'
        $serverNames = @($res2.mcp.servers.PSObject.Properties.Name)
        Write-Case (($serverNames.Count -eq 8) -and ($serverNames -contains 'servidor1') -and ($serverNames -contains 'servidor8')) '2c Merge: los 8 servidores mcp siguen presentes'
        Write-Case ($res2.mcp.servers.servidor3.command[0] -eq 'srv3') '2d Merge: las claves internas de cada servidor mcp se conservan'
        Write-Case ($res2.mcp.timeout.startup -eq 180000) '2e Merge: el bloque mcp completo se conserva'
        Write-Case ($res2.model -eq 'mi/modelo-propio') '2f Merge: model propio conservado'
        Write-Case ($res2.permission.edit -eq 'allow') '2g Merge: permission propio conservado'
        Write-Case ($res2.'$schema' -eq 'https://opencode.ai/config.json') '2h Merge: $schema del maestro presente'
        Write-Case ($res2.instructions.Count -eq 1 -and $res2.instructions[0] -eq 'AGENTS.md') '2i Merge: instructions del maestro aplicado'
    }

    # =========================================================================
    # Escenario 3: regla de default_agent (5 subcasos, spec 034 seccion 19.3)
    # =========================================================================
    $script:Scenarios++
    $dir3 = New-CaseDir 'scenario3-default-agent'
    $master3Path = Join-Path $dir3 'opencode.master.json'
    Write-JsonFile -Path $master3Path -Object ([ordered]@{
            'default_agent' = 'pensador'
            'instructions'  = @('AGENTS.md')
        })

    # (a) clave ausente -> se escribe el valor del maestro
    $projA = Join-Path $dir3 'a'; New-Item -ItemType Directory -Path $projA -Force | Out-Null
    $localA = Join-Path $projA 'opencode.json'
    Write-JsonFile -Path $localA -Object ([ordered]@{ 'model' = 'a/modelo' })
    $null = Merge-OpenCodeConfig -Source $master3Path -Destination $localA -ProjectRoot $projA
    Write-Case ((Read-JsonFile $localA).default_agent -eq 'pensador') '3a default_agent ausente -> pensador'

    # (b) valor build -> se corrige
    $projB = Join-Path $dir3 'b'; New-Item -ItemType Directory -Path $projB -Force | Out-Null
    $localB = Join-Path $projB 'opencode.json'
    Write-JsonFile -Path $localB -Object ([ordered]@{ 'default_agent' = 'build' })
    $null = Merge-OpenCodeConfig -Source $master3Path -Destination $localB -ProjectRoot $projB
    Write-Case ((Read-JsonFile $localB).default_agent -eq 'pensador') '3b default_agent build -> pensador'

    # (c) agente del kit con mode: primary -> se preserva
    $projC = Join-Path $dir3 'c'; New-Item -ItemType Directory -Path $projC -Force | Out-Null
    $agentsC = Join-Path $projC '.opencode/agents'
    New-Item -ItemType Directory -Path $agentsC -Force | Out-Null
    Write-TextFile -Path (Join-Path $agentsC 'arquitecto.md') -Text "---`ndescription: Arquitecto de prueba`nmode: primary`n---`n`n# Arquitecto`n"
    $localC = Join-Path $projC 'opencode.json'
    Write-JsonFile -Path $localC -Object ([ordered]@{ 'default_agent' = 'arquitecto' })
    $null = Merge-OpenCodeConfig -Source $master3Path -Destination $localC -ProjectRoot $projC
    Write-Case ((Read-JsonFile $localC).default_agent -eq 'arquitecto') '3c agente del kit con mode: primary -> se preserva'

    # (d) agente inexistente -> se corrige al del maestro
    $projD = Join-Path $dir3 'd'; New-Item -ItemType Directory -Path $projD -Force | Out-Null
    $localD = Join-Path $projD 'opencode.json'
    Write-JsonFile -Path $localD -Object ([ordered]@{ 'default_agent' = 'fantasma' })
    $null = Merge-OpenCodeConfig -Source $master3Path -Destination $localD -ProjectRoot $projD
    Write-Case ((Read-JsonFile $localD).default_agent -eq 'pensador') '3d agente inexistente -> pensador'

    # (e) -Force gana siempre, incluso sobre un agente valido
    $projE = Join-Path $dir3 'e'; New-Item -ItemType Directory -Path $projE -Force | Out-Null
    $agentsE = Join-Path $projE '.opencode/agents'
    New-Item -ItemType Directory -Path $agentsE -Force | Out-Null
    Write-TextFile -Path (Join-Path $agentsE 'arquitecto.md') -Text "---`nmode: primary`n---`n"
    $localE = Join-Path $projE 'opencode.json'
    Write-JsonFile -Path $localE -Object ([ordered]@{ 'default_agent' = 'arquitecto' })
    $null = Merge-OpenCodeConfig -Source $master3Path -Destination $localE -ProjectRoot $projE -Force
    Write-Case ((Read-JsonFile $localE).default_agent -eq 'pensador') '3e -Force con agente valido -> pensador'

    # =========================================================================
    # Escenario 4: idempotencia (segunda pasada byte-identica, sin backup nuevo)
    # =========================================================================
    $script:Scenarios++
    $dir4 = New-CaseDir 'scenario4-idempotencia'
    $master4Dir = Join-Path $dir4 'master'
    New-Item -ItemType Directory -Path $master4Dir -Force | Out-Null
    $master4Path = Join-Path $master4Dir 'opencode.json'
    Write-JsonFile -Path $master4Path -Object ([ordered]@{
            '$schema'       = 'https://opencode.ai/config.json'
            'default_agent' = 'pensador'
            'instructions'  = @('AGENTS.md')
        })
    $servers4 = [ordered]@{}
    for ($i = 1; $i -le 8; $i++) {
        $servers4["servidor$i"] = [ordered]@{ type = 'local'; command = @("srv$i") }
    }
    $dst4 = Join-Path $dir4 'opencode.json'
    Write-JsonFile -Path $dst4 -Object ([ordered]@{
            'model'         = 'mi/modelo-propio'
            'default_agent' = 'build'
            'mcp'           = [ordered]@{ servers = $servers4 }
        })

    $null = Merge-OpenCodeConfig -Source $master4Path -Destination $dst4 -ProjectRoot $dir4
    $bytes4First = [System.IO.File]::ReadAllBytes($dst4)
    $backups4First = @(Get-ChildItem -LiteralPath $dir4 -Filter 'opencode.json.bak-*' -File)

    $null = Merge-OpenCodeConfig -Source $master4Path -Destination $dst4 -ProjectRoot $dir4
    $bytes4Second = [System.IO.File]::ReadAllBytes($dst4)
    $backups4Second = @(Get-ChildItem -LiteralPath $dir4 -Filter 'opencode.json.bak-*' -File)

    $bytesEqual = ([Convert]::ToBase64String($bytes4First) -eq [Convert]::ToBase64String($bytes4Second))
    Write-Case $bytesEqual '4a idempotencia: la segunda pasada deja el archivo byte-identico'
    Write-Case ($backups4First.Count -ge 1) '4b idempotencia: la primera pasada creo backup'
    Write-Case ($backups4Second.Count -eq $backups4First.Count) '4c idempotencia: la segunda pasada no crea otro backup'

    # =========================================================================
    # Escenario 5: Merge-KitBlock migra la seccion sin marcadores
    # =========================================================================
    $script:Scenarios++
    $dir5 = New-CaseDir 'scenario5-migracion'
    $master5Dir = Join-Path $dir5 'master'
    New-Item -ItemType Directory -Path $master5Dir -Force | Out-Null
    $master5Path = Join-Path $master5Dir 'AGENTS.md'
    $master5Text = @'
# Kit AGENTS (maestro)

<!-- KIT-BLOCK:START arranque-por-defecto -->
## Arranque por defecto del arnés

> Texto NUEVO del maestro.
<!-- KIT-BLOCK:END arranque-por-defecto -->

## Commands del kit

Texto posterior del maestro.
'@
    Write-TextFile -Path $master5Path -Text $master5Text

    $dst5 = Join-Path $dir5 'AGENTS.md'
    $local5Text = @'
# Mi Proyecto

Texto propio de la app.

## Arranque por defecto del arnés

> Texto VIEJO del proyecto.

### Subseccion vieja

detalle viejo

## Otra Seccion Propia

Texto propio final.
'@
    Write-TextFile -Path $dst5 -Text $local5Text

    $null = Merge-KitBlock -Source $master5Path -Destination $dst5
    $res5 = Get-TextFile $dst5
    $start5 = '<!-- KIT-BLOCK:START arranque-por-defecto -->'
    $end5 = '<!-- KIT-BLOCK:END arranque-por-defecto -->'

    Write-Case ($res5.Contains('> Texto NUEVO del maestro.')) '5a migracion: el bloque nuevo del maestro esta presente'
    Write-Case ((-not $res5.Contains('Texto VIEJO del proyecto.')) -and (-not $res5.Contains('Subseccion vieja')) -and (-not $res5.Contains('detalle viejo'))) '5b migracion: el contenido viejo desaparecio'
    Write-Case ($res5.Contains('# Mi Proyecto') -and $res5.Contains('Texto propio de la app.')) '5c migracion: el encabezado y el texto propios se conservan'
    Write-Case ($res5.Contains('## Otra Seccion Propia') -and $res5.Contains('Texto propio final.')) '5d migracion: la otra seccion propia se conserva'
    Write-Case (([regex]::Matches($res5, [regex]::Escape($start5))).Count -eq 1 -and ([regex]::Matches($res5, [regex]::Escape($end5))).Count -eq 1) '5e migracion: aparecen los dos marcadores'
    Write-Case ($res5.IndexOf($start5) -lt $res5.IndexOf($end5)) '5f migracion: START antes que END'

    # =========================================================================
    # Escenario 6: Merge-KitBlock con marcadores ya presentes
    # =========================================================================
    $script:Scenarios++
    $dir6 = New-CaseDir 'scenario6-marcadores'
    $master6Path = Join-Path $dir6 'master-AGENTS.md'
    Write-TextFile -Path $master6Path -Text $master5Text

    $dst6 = Join-Path $dir6 'AGENTS.md'
    $local6Text = @'
# Mi Proyecto

<!-- KIT-BLOCK:START arranque-por-defecto -->
## Arranque por defecto del arnés

> Texto VIEJO DOS
<!-- KIT-BLOCK:END arranque-por-defecto -->

## Otra Seccion Propia

Final.
'@
    Write-TextFile -Path $dst6 -Text $local6Text

    $null = Merge-KitBlock -Source $master6Path -Destination $dst6
    $res6 = Get-TextFile $dst6
    $before6 = $local6Text.Substring(0, $local6Text.IndexOf($start5))
    $after6 = $local6Text.Substring($local6Text.IndexOf($end5) + $end5.Length)

    Write-Case ($res6.Contains('> Texto NUEVO del maestro.')) '6a marcadores: el bloque se actualiza con el del maestro'
    Write-Case (-not $res6.Contains('Texto VIEJO DOS')) '6b marcadores: el texto viejo del bloque ya no esta'
    Write-Case ($res6.StartsWith($before6) -and $res6.EndsWith($after6)) '6c marcadores: el resto del archivo no cambia'

    # =========================================================================
    # Escenario 7: Merge-KitBlock con marcadores corruptos (fail-closed)
    # =========================================================================
    $script:Scenarios++
    $dir7 = New-CaseDir 'scenario7-corruptos'
    $master7Path = Join-Path $dir7 'master-AGENTS.md'
    Write-TextFile -Path $master7Path -Text $master5Text

    $dst7 = Join-Path $dir7 'AGENTS.md'
    $local7Text = @'
# Mi Proyecto

<!-- KIT-BLOCK:START arranque-por-defecto -->
## Arranque por defecto del arnés

> Seccion sin cierre.

## Otra Seccion Propia

Texto propio final.
'@
    Write-TextFile -Path $dst7 -Text $local7Text
    $beforeBytes7 = [System.IO.File]::ReadAllBytes($dst7)

    $null = Merge-KitBlock -Source $master7Path -Destination $dst7
    $afterBytes7 = [System.IO.File]::ReadAllBytes($dst7)

    Write-Case ([Convert]::ToBase64String($beforeBytes7) -eq [Convert]::ToBase64String($afterBytes7)) '7a corruptos: el archivo queda identico al original'
    Write-Case (-not (Test-Path -LiteralPath "$dst7.bak-")) '7b corruptos: no se genero backup (no se intento escribir)'
}
finally {
    if (Test-Path -LiteralPath $script:TmpRoot) {
        Remove-Item -LiteralPath $script:TmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host ("RESULTADO: FALLO ($($script:Failures) de $($script:Checks) verificaciones)") -ForegroundColor Red
    exit 1
}

Write-Host "OK: $($script:Scenarios) escenarios" -ForegroundColor Green
exit 0
