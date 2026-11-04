#requires -Version 7.0
# tests/kit-sync-merge.ps1
# Spec 034 (T20): contrato de Compare-KitFileState, Merge-OpenCodeConfig y
# Merge-KitBlock de scripts/sync-kit.ps1. PowerShell plano, sin Pester.
#   exit 0 = todos los escenarios OK | exit 1 = al menos un fallo.
#
# [021-FIX] Escenarios 8-10: regresion del motor POR CAPAS. Verifican que
# scripts/sync/kit-files/sync-kit-files.ps1 COMPLEMENTA AGENTS.md (en lugar de
# sobrescribirlo) y que scripts/sync/mcp/lift-opencode.ps1 aplica default_agent
# del maestro conservando las claves locales del proyecto.
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
# Capturan el texto emitido para permitir asserts sobre el informe (p. ej. D3).
$script:Capture = [System.Collections.Generic.List[string]]::new()
function Write-OK   { param([string]$Message) $script:Capture.Add("OK:$Message") }
function Write-Warn { param([string]$Message) $script:Capture.Add("WARN:$Message") }
function Write-Info { param([string]$Message) $script:Capture.Add("INFO:$Message") }
function Write-Fail { param([string]$Message) $script:Capture.Add("FAIL:$Message") }

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
# [036-T052] El refactor F1 (spec 036) ELIMINO deliberadamente las funciones de
# dominio del orquestador scripts/sync-kit.ps1. Ahora viven en scripts extraidos:
#   - Merge-OpenCodeConfig -> scripts/sync/opencode/sync-opencode-config.ps1
#   - Merge-KitBlock       -> scripts/sync/kit-block/sync-kit-block.ps1
#   - Compare-KitFileState -> ELIMINADA de produccion en F1 (aun se referencia
#     en scripts/sync/transversal/sync-transversal.ps1:233; queda documentado como
#     deuda). Se preserva aqui su contrato como shim de regresion fiel al original.
#
# No se dot-source los scripts extraidos (tienen param block y ejecucion top-level):
# se extrae cada funcion via AST (FunctionDefinitionAst) y se evalua en este scope.
$repoRoot = Split-Path -Parent $PSScriptRoot

function Get-FunctionFromScript {
    param(
        [string]$Path,
        [string]$FunctionName
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { return $null }
    foreach ($node in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($node.Name -eq $FunctionName) { return $node }
    }
    return $null
}

$opencodeEngine = Join-Path $repoRoot 'scripts/sync/opencode/sync-opencode-config.ps1'
$kitblockEngine = Join-Path $repoRoot 'scripts/sync/kit-block/sync-kit-block.ps1'

foreach ($path in @($opencodeEngine, $kitblockEngine)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "FAIL: no existe $path" -ForegroundColor Red
        exit 1
    }
}

$mergeOpenCode = Get-FunctionFromScript -Path $opencodeEngine -FunctionName 'Merge-OpenCodeConfig'
$mergeKitBlock = Get-FunctionFromScript -Path $kitblockEngine -FunctionName 'Merge-KitBlock'

if ($null -eq $mergeOpenCode) {
    Write-Host "FAIL: Merge-OpenCodeConfig no encontrada en $opencodeEngine" -ForegroundColor Red
    exit 1
}
if ($null -eq $mergeKitBlock) {
    Write-Host "FAIL: Merge-KitBlock no encontrada en $kitblockEngine" -ForegroundColor Red
    exit 1
}

. ([scriptblock]::Create($mergeOpenCode.Extent.Text))
. ([scriptblock]::Create($mergeKitBlock.Extent.Text))

# [036-T052] Compare-KitFileState se retiro de produccion en el refactor F1, pero
# aun es referenciada en scripts/sync/transversal/sync-transversal.ps1.
# Shim de regresion fiel al contrato original (Equal/EolOnly/Different contando
# BOM y fin de linea). Documenta la deuda sin romper el contrato que verifica el
# archivo de raiz del sync.
function Compare-KitFileState {
    param(
        [string]$Source,
        [string]$Destination
    )
    try {
        $srcBytes = [System.IO.File]::ReadAllBytes($Source)
        $dstBytes = [System.IO.File]::ReadAllBytes($Destination)
    } catch { return 'Different' }
    $srcHasBom = ($srcBytes.Length -ge 3 -and $srcBytes[0] -eq 0xEF -and $srcBytes[1] -eq 0xBB -and $srcBytes[2] -eq 0xBF)
    $dstHasBom = ($dstBytes.Length -ge 3 -and $dstBytes[0] -eq 0xEF -and $dstBytes[1] -eq 0xBB -and $dstBytes[2] -eq 0xBF)
    if ($srcHasBom -ne $dstHasBom) { return 'Different' }
    $srcText = [System.IO.File]::ReadAllText($Source)
    $dstText = [System.IO.File]::ReadAllText($Destination)
    if ($srcText -ceq $dstText) { return 'Equal' }
    if (($srcText -replace "`r`n", "`n") -ceq ($dstText -replace "`r`n", "`n")) { return 'EolOnly' }
    return 'Different'
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

    # =========================================================================
    # Escenario 8: la capa kit-files COMPLEMENTA AGENTS.md, no lo sobrescribe
    # [021-FIX] Regresion: antes hacia Copy-Item -Force y borraba el contenido
    # propio del proyecto en cada sync del motor por capas.
    # =========================================================================
    $script:Scenarios++
    $dir8 = New-CaseDir 'scenario8-kit-files-agents'
    $stage8 = Join-Path $dir8 'stage'
    New-Item -ItemType Directory -Path $stage8 -Force | Out-Null
    Write-TextFile -Path (Join-Path $stage8 'AGENTS.md') -Text $master5Text
    Write-TextFile -Path (Join-Path $stage8 'README.md') -Text "# README del kit (nuevo)`n"
    $spec8Dir = Join-Path $stage8 '.specify/memory'
    New-Item -ItemType Directory -Path $spec8Dir -Force | Out-Null
    Write-TextFile -Path (Join-Path $spec8Dir 'constitution.md') -Text "# Constitucion del kit`n"
    $stageScripts8 = Join-Path $stage8 'scripts'
    New-Item -ItemType Directory -Path $stageScripts8 -Force | Out-Null
    Write-TextFile -Path (Join-Path $stageScripts8 'sync-kit.ps1') -Text "# script del kit`n"

    $root8 = Join-Path $dir8 'root'
    New-Item -ItemType Directory -Path $root8 -Force | Out-Null
    Write-TextFile -Path (Join-Path $root8 'AGENTS.md') -Text $local5Text
    Write-TextFile -Path (Join-Path $root8 'README.md') -Text "# README viejo del proyecto`n"
    $rootScripts8 = Join-Path $root8 'scripts'
    New-Item -ItemType Directory -Path $rootScripts8 -Force | Out-Null
    Write-TextFile -Path (Join-Path $rootScripts8 'local-propio.ps1') -Text "# script propio del proyecto`n"

    $layerKitFiles = Join-Path $repoRoot 'scripts/sync/kit-files/sync-kit-files.ps1'
    $out8 = (& pwsh -NoProfile -File $layerKitFiles -StageDir $stage8 -RootPath $root8 2>&1 | Out-String)
    $agents8 = Get-TextFile (Join-Path $root8 'AGENTS.md')

    Write-Case ($out8 -match 'RESULT:kit-files:ok') '8a kit-files: emite RESULT:kit-files:ok'
    Write-Case ($agents8.Contains('# Mi Proyecto') -and $agents8.Contains('Texto propio de la app.') -and $agents8.Contains('Texto propio final.')) '8b kit-files: el contenido propio del proyecto SOBREVIVE'
    Write-Case ($agents8.Contains('> Texto NUEVO del maestro.')) '8c kit-files: el bloque del kit se actualizo'
    Write-Case ((-not $agents8.Contains('Texto VIEJO del proyecto.')) -and (-not $agents8.Contains('Subseccion vieja')) -and (-not $agents8.Contains('detalle viejo'))) '8d kit-files: la seccion vieja del bloque desaparecio'
    Write-Case (([regex]::Matches($agents8, [regex]::Escape($start5))).Count -eq 1 -and ([regex]::Matches($agents8, [regex]::Escape($end5))).Count -eq 1) '8e kit-files: marcadores START/END unicos'
    Write-Case ((Get-TextFile (Join-Path $root8 'README.md')).Contains('README del kit')) '8f kit-files: README.md si se reemplaza (es 100% del kit)'
    Write-Case ((-not (Test-Path -LiteralPath (Join-Path $root8 'scripts/local-propio.ps1'))) -and (Test-Path -LiteralPath (Join-Path $root8 'scripts/sync-kit.ps1'))) '8g kit-files: scripts/ conserva clean+replace'
    Write-Case (@(Get-ChildItem -LiteralPath $root8 -Filter 'AGENTS.md.bak-*' -File).Count -ge 1) '8h kit-files: se creo backup de AGENTS.md'

    # =========================================================================
    # Escenario 9: idempotencia de la capa kit-files
    # =========================================================================
    $script:Scenarios++
    $bytes9Before = [System.IO.File]::ReadAllBytes((Join-Path $root8 'AGENTS.md'))
    $out9 = (& pwsh -NoProfile -File $layerKitFiles -StageDir $stage8 -RootPath $root8 2>&1 | Out-String)
    $bytes9After = [System.IO.File]::ReadAllBytes((Join-Path $root8 'AGENTS.md'))
    Write-Case ([Convert]::ToBase64String($bytes9Before) -eq [Convert]::ToBase64String($bytes9After)) '9a idempotencia: AGENTS.md byte-identico en la segunda pasada'
    Write-Case ($out9 -match 'RESULT:kit-files:sin-cambios') '9b idempotencia: RESULT:kit-files:sin-cambios'

    # =========================================================================
    # Escenario 10: mcp-lift-opencode aplica default_agent/$schema sin perder
    # las claves locales del proyecto (model, mcp.graphify).
    # =========================================================================
    $script:Scenarios++
    $dir10 = New-CaseDir 'scenario10-lift-default-agent'
    $stage10 = Join-Path $dir10 'stage'
    New-Item -ItemType Directory -Path $stage10 -Force | Out-Null
    Write-JsonFile -Path (Join-Path $stage10 'opencode.json') -Object ([ordered]@{
            '$schema'       = 'https://opencode.ai/config.json'
            'default_agent' = 'pensador'
            'instructions'  = @('AGENTS.md')
            'mcp'           = [ordered]@{ servers = [ordered]@{
                    'context-mode' = [ordered]@{ type = 'local'; command = @('npx'); enabled = $true }
                }
            }
        })
    $root10 = Join-Path $dir10 'root'
    New-Item -ItemType Directory -Path $root10 -Force | Out-Null
    Write-JsonFile -Path (Join-Path $root10 'opencode.json') -Object ([ordered]@{
            'model'         = 'propio/modelo'
            'default_agent' = 'build'
            'mcp'           = [ordered]@{ servers = [ordered]@{
                    'context-mode' = [ordered]@{ type = 'local'; command = @('npx'); enabled = $true }
                    'graphify'     = [ordered]@{ type = 'local'; command = @('uv', 'tool', 'run', 'graphify') }
                }
            }
        })

    $layerLift = Join-Path $repoRoot 'scripts/sync/mcp/lift-opencode.ps1'
    $out10 = (& pwsh -NoProfile -File $layerLift -StageDir $stage10 -RootPath $root10 2>&1 | Out-String)
    $res10 = Read-JsonFile -Path (Join-Path $root10 'opencode.json')
    Write-Case ($res10.default_agent -eq 'pensador') '10a lift: default_agent build -> pensador'
    Write-Case ($res10.model -eq 'propio/modelo') '10b lift: model propio conservado'
    Write-Case ($res10.'$schema' -eq 'https://opencode.ai/config.json') '10c lift: $schema aplicado desde el maestro'
    Write-Case ($null -ne $res10.mcp.servers.graphify) '10d lift: la entrada local mcp.graphify se conserva'
    Write-Case ($out10 -match 'RESULT:mcp-opencode:reparadas') '10e lift: RESULT:mcp-opencode:reparadas'

    # =========================================================================
    # Escenario 11 [036-T052-D1]: poda de .kit-backup/ protege los backups del
    # llamador (pre-existentes). Con 3 backups previos + 1 nuevo generado por la
    # corrida y -KeepBackups 1, los 3 previos SOBREVIVEN y el nuevo (mas reciente)
    # se conserva. La correccion D1 uso el snapshot del conjunto inicial.
    # =========================================================================
    $script:Scenarios++
    $dir11 = New-CaseDir 'scenario11-backup-prune'
    $root11 = Join-Path $dir11 'root'
    New-Item -ItemType Directory -Path $root11 -Force | Out-Null
    $backupRoot11 = Join-Path $root11 '.kit-backup'
    New-Item -ItemType Directory -Path $backupRoot11 -Force | Out-Null
    # 3 backups PRE-EXISTENTES del llamador (anteriores a la corrida).
    foreach ($n in @('20260101T000000', '20260201T000000', '20260301T000000')) {
        New-Item -ItemType Directory -Path (Join-Path $backupRoot11 $n) -Force | Out-Null
        Write-TextFile -Path (Join-Path (Join-Path $backupRoot11 $n) 'MANIFEST.sha256') -Text "pre$n`n"
    }
    # Snapshot del conjunto inicial que captura el orquestador ANTES de la corrida.
    $stateFile11 = Join-Path $dir11 'initial-backups.txt'
    Write-TextFile -Path $stateFile11 -Text "20260101T000000`n20260201T000000`n20260301T000000`n"
    # 1 backup NUEVO (generado por la corrida), el mas reciente en mtime.
    $newBackup11 = Join-Path $backupRoot11 '20260401T000000'
    New-Item -ItemType Directory -Path $newBackup11 -Force | Out-Null
    Write-TextFile -Path (Join-Path $newBackup11 'MANIFEST.sha256') -Text "nuevo`n"

    $pruneLayer = Join-Path $repoRoot 'scripts/sync-backup-prune.ps1'
    $out11 = (& pwsh -NoProfile -File $pruneLayer -RootPath $root11 -KeepBackups 1 -InitialStateFile $stateFile11 2>&1 | Out-String)
    $remaining11 = @(Get-ChildItem -LiteralPath $backupRoot11 -Directory)
    $remainingNames11 = @($remaining11 | ForEach-Object { $_.Name })
    Write-Case (@('20260101T000000', '20260201T000000', '20260301T000000' | Where-Object { $_ -in $remainingNames11 }).Count -eq 3) '11a D1 poda: los 3 backups pre-existentes del llamador SOBREVIVEN'
    Write-Case ('20260401T000000' -in $remainingNames11) '11b D1 poda: el 1 backup nuevo (mas reciente) se conserva con -KeepBackups 1'
    Write-Case ($remaining11.Count -eq 4) '11c D1 poda: total de carpetas tras poda = 4 (3 previos + 1 nuevo)'
    Write-Case ($out11 -match 'RESULT:backup-prune:(sin-cambios|poda_hecha|ok)') '11d D1 poda: emite RESULT:backup-prune:'

    # =========================================================================
    # Escenario 12 [036-T052-D2]: la capa skills (scripts/sync-skills.ps1)
    # integra .github/skills/<n>/SKILL.md con la contraparte ECC y espeja
    # .github/skills -> .opencode/skills (misma ruta relativa).
    # =========================================================================
    $script:Scenarios++
    $dir12 = New-CaseDir 'scenario12-skills'
    $root12 = Join-Path $dir12 'root'
    $eccSkill = Join-Path $root12 'proyect_ext/ECC/skills/mi-skill/SKILL.md'
    $ghSkill = Join-Path $root12 '.github/skills/mi-skill/SKILL.md'
    $ocSkill = Join-Path $root12 '.opencode/skills/mi-skill/SKILL.md'
    New-Item -ItemType Directory -Path (Split-Path $eccSkill -Parent) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $ghSkill -Parent) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $ocSkill -Parent) -Force | Out-Null
    Write-TextFile -Path $eccSkill -Text "# Contenido ECC profundo`nDetalle tecnico ECC.`n"
    Write-TextFile -Path $ghSkill -Text "# Mi Skill (fachada)`nFachada SSD.`n"

    $skillsLayer = Join-Path $repoRoot 'scripts/sync-skills.ps1'
    $out12 = (& pwsh -NoProfile -File $skillsLayer -RootPath $root12 2>&1 | Out-String)
    Write-Case (Test-Path -LiteralPath $ocSkill) '12a D2 skills: .opencode/skills/mi-skill/SKILL.md se creo (espejo)'
    Write-Case ((Get-TextFile $ghSkill).Contains('Profundidad ECC')) '12b D2 skills: la fachada .github/skills integro el contenido ECC'
    $hashGh12 = (Get-FileHash -LiteralPath $ghSkill -Algorithm SHA256).Hash
    $hashOc12 = if (Test-Path -LiteralPath $ocSkill) { (Get-FileHash -LiteralPath $ocSkill -Algorithm SHA256).Hash } else { '' }
    Write-Case ($hashGh12 -eq $hashOc12 -and $hashGh12 -ne '') '12c D2 skills: el espejo .opencode/skills tiene el MISMO hash que .github/skills'
    Write-Case ($out12 -match 'RESULT:skills:') '12d D2 skills: emite RESULT:skills:'

    # =========================================================================
    # Escenario 13 [036-T052-D3]: el verificador de integridad del audit log
    # (Test-AuditLogIntegrity, upgrade_framework.ps1) devuelve 0 violaciones
    # sobre un log valido (raices prevHash:null legitimas incluidas), detecta
    # una entrada alterada y distingue log vacio.
    # =========================================================================
    $script:Scenarios++
    $dir13 = New-CaseDir 'scenario13-audit-log'
    # Extraer Test-AuditLogIntegrity via AST (no dot-source el pipeline completo).
    $ufPath = Join-Path $repoRoot 'upgrade_framework.ps1'
    $ufFn = Get-FunctionFromScript -Path $ufPath -FunctionName 'Test-AuditLogIntegrity'
    if ($null -eq $ufFn) {
        Write-Case $false '13z D3: Test-AuditLogIntegrity encontrada en upgrade_framework.ps1'
    } else {
        Write-Case $true '13z D3: Test-AuditLogIntegrity encontrada en upgrade_framework.ps1'
        . ([scriptblock]::Create($ufFn.Extent.Text))
    }

    # Generador de entradas de audit log con cadena de hash valida (mismo
    # algoritmo que Write-AuditEntry: sha256(prevHash + payload sin hash/prevHash)).
    # Genera formato CANONICO (empieza por {"timestamp":" y cierra con
    # ,"hash":..,"prevHash":..}): solo las entradas canonicas son verificadas
    # estrictamente por el verificador (las legacy se toleran, D3).
    function New-AuditLine {
        param([string]$Action, [string]$PrevHash, [bool]$AsRoot = $false)
        $entry = [ordered]@{
            timestamp = (Get-Date -Format 'o')
            actor     = 'test-user'
            host      = 'test-host'
            action    = $Action
            details   = [ordered]@{ test = $Action }
        }
        $payload = $entry | ConvertTo-Json -Compress
        $chainInput = (($(if ($PrevHash) { $PrevHash } else { '' })) + $payload)
        $hashBytes = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($chainInput))
        $hash = [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
        if ($AsRoot -or -not $PrevHash) {
            $repl = ',"hash":"' + $hash + '","prevHash":null}'
        } else {
            $repl = ',"hash":"' + $hash + '","prevHash":"' + $PrevHash + '"}'
        }
        return ($payload -replace '\}\s*$', $repl)
    }

    $auditLog13 = Join-Path $dir13 'audit.log'
    # Una raiz (prevHash:null) + dos entradas encadenadas validas.
    $l1 = New-AuditLine -Action 'raiz_1' -AsRoot $true
    $h1 = ([regex]::Match($l1, '"hash":"([0-9a-f]{64})"')).Groups[1].Value
    $l2 = New-AuditLine -Action 'entry_2' -PrevHash $h1
    $h2 = ([regex]::Match($l2, '"hash":"([0-9a-f]{64})"')).Groups[1].Value
    $l3 = New-AuditLine -Action 'entry_3' -PrevHash $h2
    Set-Content -LiteralPath $auditLog13 -Value @($l1, $l2, $l3) -Encoding UTF8

    $rc13valid = Test-AuditLogIntegrity -Path $auditLog13
    Write-Case ($rc13valid -eq 0) '13a D3: log valido (raiz + cadena) -> exit 0 (0 violaciones)'
    $script:Capture.Clear()
    $null = Test-AuditLogIntegrity -Path $auditLog13
    $report13 = ($script:Capture -join ' ')
    Write-Case ($report13 -match '0 violaciones') '13b D3: el informe del verificador reporta 0 violaciones'
    Write-Case ($report13 -match 'raices=1') '13c D3: la raiz legitima (prevHash:null) se cuenta como raiz, no como violacion'

    # Corrupcion: alterar el payload de la ultima entrada -> violacion detectada.
    $corrupt13 = Get-Content -LiteralPath $auditLog13 -Raw
    $corrupt13 = $corrupt13 -replace '"test":"entry_3"', '"test":"entry_3_TAMPERED"'
    Set-Content -LiteralPath $auditLog13 -Value $corrupt13 -NoNewline -Encoding UTF8
    $rc13corrupt = Test-AuditLogIntegrity -Path $auditLog13
    Write-Case ($rc13corrupt -eq 1) '13d D3: una entrada alterada -> exit 1 (violacion detectada)'
    Write-Case ([regex]::Matches($corrupt13, 'entry_3_TAMPERED').Count -eq 1) '13f D3: la corrupcion del fixture se aplico sobre el payload'

    # Log vacio -> estado propio 3.
    $emptyLog13 = Join-Path $dir13 'vacio.log'
    New-Item -ItemType File -Path $emptyLog13 -Force | Out-Null
    $rc13empty = Test-AuditLogIntegrity -Path $emptyLog13
    Write-Case ($rc13empty -eq 3) '13e D3: log vacio -> estado 3 (no exito silencioso)'

    # =========================================================================
    # Escenario 14 [036-T052-D4]: la capa de whitelist de tests del kit
    # (scripts/sync-tests-kit.ps1) hace viajar los 5 tests del kit, respalda el
    # test del proyecto que colisiona por nombre y NO borra los tests fuera de
    # la whitelist.
    # =========================================================================
    $script:Scenarios++
    $dir14 = New-CaseDir 'scenario14-tests-kit'
    $stage14 = Join-Path $dir14 'stage'
    New-Item -ItemType Directory -Path (Join-Path $stage14 'tests') -Force | Out-Null
    foreach ($t in @('harness-default.ps1', 'kit-sync-merge.ps1', 'agents-parity.ps1', 'kb-parity.ps1', 'mcp-refresh-parity.ps1')) {
        Write-TextFile -Path (Join-Path (Join-Path $stage14 'tests') $t) -Text "# kit $t`n"
    }
    $root14 = Join-Path $dir14 'root'
    New-Item -ItemType Directory -Path (Join-Path $root14 'tests') -Force | Out-Null
    # Test del proyecto que COLISIONA por nombre (contenido distinto al del kit).
    Write-TextFile -Path (Join-Path (Join-Path $root14 'tests') 'kit-sync-merge.ps1') -Text "# proyecto: contenido propio distinto`n"
    # Test del proyecto FUERA de la whitelist: no debe borrarse.
    Write-TextFile -Path (Join-Path (Join-Path $root14 'tests') 'proyecto-propio.ps1') -Text "# test propio del proyecto`n"

    $testsLayer = Join-Path $repoRoot 'scripts/sync-tests-kit.ps1'
    $out14 = (& pwsh -NoProfile -File $testsLayer -StageDir $stage14 -RootPath $root14 2>&1 | Out-String)
    Write-Case (Test-Path -LiteralPath (Join-Path (Join-Path $root14 'tests') 'harness-default.ps1')) '14a D4 tests: un test de la whitelist viajo a tests/ del destino'
    Write-Case (@(Get-ChildItem -LiteralPath (Join-Path $root14 'tests') -Filter 'kit-sync-merge.ps1.bak-*' -File).Count -ge 1) '14b D4 tests: el test del proyecto que colisionaba quedo respaldado (.bak-*)'
    Write-Case ((Get-TextFile (Join-Path (Join-Path $root14 'tests') 'kit-sync-merge.ps1')).Contains('# kit kit-sync-merge.ps1')) '14c D4 tests: el test del kit gana la colision (contenido del kit)'
    Write-Case (Test-Path -LiteralPath (Join-Path (Join-Path $root14 'tests') 'proyecto-propio.ps1')) '14d D4 tests: el test fuera de la whitelist NO se borra'
    Write-Case ($out14 -match 'RESULT:tests-kit:(creado|ok)') '14e D4 tests: emite RESULT:tests-kit:creado|ok'

    # =========================================================================
    # Escenario 15 [036-T052-D5]: sync-mcp-graphify deja UNA sola entrada
    # graphify en mcp.servers (forma canonica), elimina la duplicada V1 y
    # regenera la ruta del comando para que quede DENTRO de RootPath, preservando
    # el campo enabled.
    # =========================================================================
    $script:Scenarios++
    $dir15 = New-CaseDir 'scenario15-graphify'
    $root15 = Join-Path $dir15 'root'
    New-Item -ItemType Directory -Path $root15 -Force | Out-Null
    Write-JsonFile -Path (Join-Path $root15 'opencode.json') -Object ([ordered]@{
            'mcp' = [ordered]@{
                'graphify' = [ordered]@{ type = 'local'; command = @('uv', 'tool', 'run', 'graphify', 'C:/FUERA/graph.json'); enabled = $true }
                'servers'  = [ordered]@{
                    'graphify'  = [ordered]@{ type = 'local'; command = @('uv', 'tool', 'run', 'graphify', 'C:/FUERA/servers.json'); enabled = $false }
                    'graphify2' = [ordered]@{ type = 'local'; command = @('uv', 'tool', 'run', 'C:/FUERA/otro.json') }
                    'context-mode' = [ordered]@{ type = 'local'; command = @('npx'); enabled = $true }
                }
            }
        })

    $graphifyLayer = Join-Path $repoRoot 'scripts/sync-mcp-graphify.ps1'
    $out15 = (& pwsh -NoProfile -File $graphifyLayer -RootPath $root15 2>&1 | Out-String)
    $res15 = Read-JsonFile -Path (Join-Path $root15 'opencode.json')
    $grKeys15 = @($res15.mcp.servers.PSObject.Properties.Name | Where-Object { $_ -match '^graphify' })
    Write-Case ($grKeys15.Count -eq 1) '15a D5 graphify: queda exactamente 1 entrada graphify en mcp.servers'
    Write-Case ($null -eq $res15.mcp.PSObject.Properties['graphify']) '15b D5 graphify: la entrada duplicada V1 (mcp.graphify) se descarto'
    Write-Case ($null -ne $res15.mcp.servers.graphify.enabled -and $res15.mcp.servers.graphify.enabled -eq $false) '15c D5 graphify: el campo enabled se preserva'
    $rootAbs15 = (Resolve-Path $root15).Path
    $gCmd15 = $res15.mcp.servers.graphify.command
    $pathAbs15 = $null
    if ($gCmd15 -and $gCmd15.Count -gt 0) {
        $idx15 = if ($gCmd15.Count -gt 3) { 3 } else { $gCmd15.Count - 1 }
        $pathAbs15 = try { (Get-Item -LiteralPath $gCmd15[$idx15] -ErrorAction Stop).FullName } catch { $gCmd15[$idx15] }
    }
    # Normalizar separadores: el script regenera con "/" y Resolve-Path devuelve "\".
    $rootNorm15 = $rootAbs15 -replace '\\', '/'
    $pathNorm15 = if ($pathAbs15) { ([string]$pathAbs15) -replace '\\', '/' } else { '' }
    Write-Case ($pathNorm15 -and $pathNorm15.StartsWith($rootNorm15, [StringComparison]::OrdinalIgnoreCase)) '15d D5 graphify: la ruta del comando graphify queda DENTRO de RootPath'
    Write-Case ($out15 -match 'RESULT:mcp-graphify:consolidated') '15e D5 graphify: emite RESULT:mcp-graphify:consolidated'
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
