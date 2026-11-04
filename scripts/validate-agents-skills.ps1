#requires -Version 7.0
<#
.SYNOPSIS
    Validador de solo lectura de agentes y skills del kit Agents_IA_TECH.

.DESCRIPTION
    Ejecuta doce chequeos (VAL-01 .. VAL-12) que verifican la coherencia entre los
    dos arneses del kit (.github/ para GitHub Copilot y .opencode/ para OpenCode),
    la estructura minima de cada agente exigida por AGENTS.md (Regla 2), la
    cobertura de MCPs exigida por AGENTS.md (Regla 1b) y el arranque por defecto
    del arnes declarado en opencode.json (spec 034). VAL-12 es el gate mecanico
    del backlog (TRANS-001): exige que pendientes-implementacion.md exista, no
    tenga placeholders y sea coherente con specs/*/tasks.md, de modo que la
    aprobacion del plan dispare la actualizacion obligatoria del backlog.

    El script es de SOLO LECTURA: no crea, modifica ni elimina archivos del repo.
    Reporta [OK] / [WARN] / [FAIL] por chequeo y detalla cada violacion con el
    archivo y el numero de linea cuando aplica.

    Exit code: 0 si no hay ningun [FAIL]; 1 si hay al menos un [FAIL]. Los [WARN]
    no alteran el exit code.

.PARAMETER RootPath
    Raiz del kit a validar. Por defecto se deriva de $PSScriptRoot (el script vive
    en <raiz>/scripts, por lo que la raiz es su directorio padre).

.PARAMETER Json
    Emite el resultado completo como JSON (una sola estructura por stdout) en lugar
    del reporte legible. Tiene prioridad sobre -Quiet.

.PARAMETER Quiet
    Muestra solo el resumen final (conteos por severidad y exit code), sin el
    detalle de cada chequeo.

.EXAMPLE
    pwsh -File scripts/validate-agents-skills.ps1

.EXAMPLE
    pwsh -File scripts/validate-agents-skills.ps1 -Json

.EXAMPLE
    pwsh -File scripts/validate-agents-skills.ps1 -Quiet

.NOTES
    Fuente de verdad de las reglas citadas: AGENTS.md (Regla 1b "cobertura
    obligatoria", Regla 2 "Estructura estandar de agente", Regla 3 "Sincronizacion
    entre arneses" y la tabla "Agent road assignment").

    Este script NO corrige violaciones: solo las reporta. La correccion es tarea de
    los agentes responsables (plataformador / arquitecto / documentador).
#>
[CmdletBinding()]
param(
    [string]$RootPath,
    [switch]$Json,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

# =============================================================================
# 0. Resolucion de rutas
# =============================================================================
# El default de -RootPath se calcula aca (y no en el bloque param) para no
# depender del momento en que PowerShell evalua el default de los parametros.
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $RootPath = Split-Path -Parent $PSScriptRoot
    }
    else {
        $RootPath = (Get-Location).ProviderPath
    }
}

if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
    Write-Host "[FAIL] VAL-00 - Raiz inexistente: '$RootPath' no es un directorio." -ForegroundColor Red
    if ($MyInvocation.InvocationName -ne '.') { exit 1 }
    return
}

$RootPath = (Resolve-Path -LiteralPath $RootPath).ProviderPath

$script:RootPath           = $RootPath
$script:AgentsGithubDir    = Join-Path $RootPath '.github/agents'
$script:AgentsOpencodeDir  = Join-Path $RootPath '.opencode/agents'
$script:SkillsGithubDir    = Join-Path $RootPath '.github/skills'
$script:SkillsOpencodeDir  = Join-Path $RootPath '.opencode/skills'
$script:OpencodeConfigPath = Join-Path $RootPath 'opencode.json'
$script:AgentsMdPath       = Join-Path $RootPath 'AGENTS.md'
$script:SpecsDir           = Join-Path $RootPath 'Documentacion/Agents_IA_TECH/specs'
$script:BacklogIndexPath   = Join-Path $RootPath 'Documentacion/Agents_IA_TECH/00-indice.md'
$script:BacklogFilePath    = Join-Path $RootPath 'Documentacion/Agents_IA_TECH/pendientes-implementacion.md'

# =============================================================================
# 1. Utilidades generales
# =============================================================================

function Get-RelativeDisplayPath {
    <# Devuelve la ruta relativa a la raiz del kit con separador '/'. #>
    param(
        [Parameter(Mandatory)][string]$BasePath,
        [Parameter(Mandatory)][string]$FullPath
    )
    try {
        return ([System.IO.Path]::GetRelativePath($BasePath, $FullPath) -replace '\\', '/')
    }
    catch {
        return $FullPath
    }
}

function ConvertTo-NormalizedText {
    <#
        Minusculas y sin diacriticos. Los agentes del kit mezclan encoding
        (algunos archivos tienen mojibake), por lo que las comparaciones de
        secciones usan texto normalizado y raices de palabra cortas.
    #>
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $decomposed = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()
    foreach ($ch in $decomposed.ToCharArray()) {
        $category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($category -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($ch)
        }
    }
    return $builder.ToString().ToLowerInvariant()
}

function New-Violation {
    <# Estructura uniforme de una violacion (archivo + linea + mensaje). #>
    param(
        [string]$File = '',
        [int]$Line = 0,
        [Parameter(Mandatory)][string]$Message
    )
    [pscustomobject]@{
        File    = $File
        Line    = $Line
        Message = $Message
    }
}

function New-CheckOutcome {
    <#
        Construye el resultado de un chequeo. Sin violaciones => [OK].
        Con violaciones => [FAIL] o [WARN] segun -ViolationSeverity.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string]$OkMessage = '',
        [string]$ViolationSummary,
        [object[]]$Violations = @(),
        [ValidateSet('FAIL', 'WARN')][string]$ViolationSeverity = 'FAIL',
        [string]$Rule = ''
    )
    $list = @($Violations)
    if ($list.Count -eq 0) {
        $okText = if ([string]::IsNullOrWhiteSpace($OkMessage)) { 'sin hallazgos' } else { $OkMessage }
        return [pscustomobject]@{
            Id         = $Id
            Name       = $Name
            Severity   = 'OK'
            Message    = $okText
            Rule       = $Rule
            Violations = @()
        }
    }
    $summary = if ([string]::IsNullOrWhiteSpace($ViolationSummary)) {
        "$($list.Count) hallazgo(s)"
    }
    else { $ViolationSummary }
    return [pscustomobject]@{
        Id         = $Id
        Name       = $Name
        Severity   = $ViolationSeverity
        Message    = $summary
        Rule       = $Rule
        Violations = $list
    }
}

function Get-FirstMatchingLine {
    <#
        Devuelve la linea completa (con su numero) que matchea un patron.
        La comparacion es insensible a mayusculas y diacriticos para poder citar
        texto de AGENTS.md sin depender de tildes ni del encoding del archivo.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Pattern
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $normalizedPattern = ConvertTo-NormalizedText -Text $Pattern
    $i = 0
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $i++
        $normalizedLine = ConvertTo-NormalizedText -Text $line
        if ($normalizedLine -match $normalizedPattern) {
            return [pscustomobject]@{ Line = $i; Text = $line.Trim() }
        }
    }
    return $null
}

# =============================================================================
# 2. Lectura de agentes (frontmatter + cuerpo)
# =============================================================================

function Get-FrontmatterBlock {
    <#
        Detecta si el archivo abre con '---' en la linea 1 y si el bloque cierra.
        Devuelve tambien las lineas del bloque y el offset del cuerpo.
    #>
    param([Parameter(Mandatory)][string]$Path)

    $lines = @(Get-Content -LiteralPath $Path)
    $info = [pscustomobject]@{
        Path             = $Path
        Lines            = $lines
        HasFrontmatter   = $false
        IsClosed         = $false
        FrontmatterLines = @()
        BodyStartLine    = 1
    }
    if ($lines.Count -eq 0) { return $info }
    if ($lines[0].Trim() -ne '---') { return $info }

    $info.HasFrontmatter = $true
    $closeIndex = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $closeIndex = $i; break }
    }

    if ($closeIndex -gt 0) {
        $info.IsClosed = $true
        if ($closeIndex -eq 1) {
            $info.FrontmatterLines = @()
        }
        else {
            $info.FrontmatterLines = @($lines[1..($closeIndex - 1)])
        }
        $info.BodyStartLine = $closeIndex + 2
    }
    else {
        # Frontmatter abierto y nunca cerrado: se toma todo el archivo como bloque.
        if ($lines.Count -gt 1) {
            $info.FrontmatterLines = @($lines[1..($lines.Count - 1)])
        }
        $info.BodyStartLine = $lines.Count + 1
    }
    return $info
}

function ConvertFrom-MinimalYaml {
    <#
        Parser YAML minimo (sin dependencias) para el subconjunto usado en el kit:
        claves de primer nivel con valor escalar, secuencias inline 'clave: [a, b]'
        y secuencias en bloque 'clave:' + lineas '  - item'.
        Devuelve un OrderedDictionary: clave -> { Key, Value, Line, Items, IsList }.
        Los Items conservan su numero de linea para poder reportar violaciones.
    #>
    param(
        [string[]]$Lines = @(),
        [int]$FirstLineNumber = 2
    )

    $map = [ordered]@{}
    $lineCount = @($Lines).Count
    $i = 0

    while ($i -lt $lineCount) {
        $raw = $Lines[$i]
        if ($null -eq $raw) { $i++; continue }
        $line = [string]$raw
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) { $i++; continue }
        if ($line -notmatch '^([A-Za-z0-9_\-\.]+)\s*:\s*(.*)$') { $i++; continue }

        $key = $Matches[1]
        $value = $Matches[2].Trim()
        $keyLine = $FirstLineNumber + $i
        $items = @()

        # Secuencia inline: clave: [a, b, c]
        if ($value -match '^\[(.*)\]$') {
            $inner = $Matches[1].Trim()
            if ($inner.Length -gt 0) {
                foreach ($piece in ($inner -split ',')) {
                    $clean = $piece.Trim().Trim('"').Trim("'")
                    if ($clean.Length -gt 0) {
                        $items += [pscustomobject]@{ Value = $clean; Line = $keyLine }
                    }
                }
            }
            $map[$key] = [pscustomobject]@{
                Key = $key; Value = $value; Line = $keyLine; Items = @($items); IsList = $true
            }
            $i++
            continue
        }

        # Coleccion en bloque: lineas indentadas siguientes (termina en linea vacia
        # o en la proxima clave de primer nivel).
        $blockLines = @()
        $j = $i + 1
        while ($j -lt $lineCount) {
            $next = $Lines[$j]
            if ($null -eq $next) { break }
            $nextText = [string]$next
            if ($nextText.Trim().Length -eq 0) { break }
            if ($nextText -match '^\S') { break }
            $blockLines += [pscustomobject]@{ Text = $nextText; Line = $FirstLineNumber + $j }
            $j++
        }

        $isList = $false
        if ($blockLines.Count -gt 0) {
            $indents = @($blockLines | ForEach-Object { ($_.Text -replace '^(\s*).*$', '$1').Length })
            $minIndent = ($indents | Measure-Object -Minimum).Minimum
            $firstAtMin = $blockLines | Where-Object { ($_.Text -replace '^(\s*).*$', '$1').Length -eq $minIndent } | Select-Object -First 1
            if ($null -ne $firstAtMin -and $firstAtMin.Text -match '^\s*-\s+') { $isList = $true }
        }

        if ($isList) {
            foreach ($bl in $blockLines) {
                if ($bl.Text -match '^\s*-\s+(.*)$') {
                    $clean = $Matches[1].Trim().Trim('"').Trim("'")
                    if ($clean.Length -gt 0) {
                        $items += [pscustomobject]@{ Value = $clean; Line = $bl.Line }
                    }
                }
            }
        }

        $map[$key] = [pscustomobject]@{
            Key = $key; Value = $value; Line = $keyLine; Items = @($items); IsList = $isList
        }
        $i = $j
    }

    return $map
}

function Get-AgentDocument {
    <#
        Carga un archivo de agente y devuelve:
          Fields      -> frontmatter parseado (clave -> Value/Line/Items)
          YamlChecked -> $true si habia ConvertFrom-Yaml disponible
          YamlInvalid -> $true si ConvertFrom-Yaml fallo al parsear el bloque
          BodyStartLine, Lines
        Si ConvertFrom-Yaml no esta instalado NO se falla: se usa el parser minimo
        (el kit no tiene dependencias externas).
    #>
    param([Parameter(Mandatory)][string]$Path)

    $fm = Get-FrontmatterBlock -Path $Path
    $doc = [pscustomobject]@{
        Path            = $Path
        Lines           = $fm.Lines
        HasFrontmatter  = $fm.HasFrontmatter
        IsClosed        = $fm.IsClosed
        BodyStartLine   = $fm.BodyStartLine
        Fields          = [ordered]@{}
        YamlChecked     = $false
        YamlInvalid     = $false
        YamlError       = ''
    }
    if (-not $fm.HasFrontmatter) { return $doc }

    $doc.Fields = ConvertFrom-MinimalYaml -Lines $fm.FrontmatterLines -FirstLineNumber 2

    $yamlCommand = Get-Command -Name 'ConvertFrom-Yaml' -ErrorAction SilentlyContinue
    if ($null -ne $yamlCommand) {
        $doc.YamlChecked = $true
        try {
            $yamlText = ($fm.FrontmatterLines -join "`n")
            if ([string]::IsNullOrWhiteSpace($yamlText)) {
                $parsed = [ordered]@{}
            }
            else {
                $parsed = $yamlText | ConvertFrom-Yaml -ErrorAction Stop
            }
            if ($null -ne $parsed -and $parsed -is [System.Collections.IDictionary]) {
                # El YAML real manda: si el parser minimo no vio una clave, se agrega
                # (Line 0) para no reportar un falso "clave faltante".
                foreach ($yamlKey in $parsed.Keys) {
                    $plainKey = [string]$yamlKey
                    if (-not $doc.Fields.Contains($plainKey)) {
                        $rawValue = $parsed[$yamlKey]
                        $scalar = if ($null -eq $rawValue) { '' } else { [string]$rawValue }
                        $doc.Fields[$plainKey] = [pscustomobject]@{
                            Key = $plainKey; Value = $scalar; Line = 0; Items = @(); IsList = $false
                        }
                    }
                }
            }
        }
        catch {
            $doc.YamlInvalid = $true
            $doc.YamlError = $_.Exception.Message
        }
    }

    return $doc
}

function Get-FieldValue {
    param($Fields, [string]$Key)
    if ($null -eq $Fields) { return '' }
    if (-not $Fields.Contains($Key)) { return '' }
    return ([string]$Fields[$Key].Value).Trim()
}

function Get-BodySections {
    <#
        Encabezados Markdown del cuerpo (posterior al frontmatter), con su linea.
        Se aceptan niveles 1..6 para no depender del estilo de cada agente.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [int]$BodyStartLine = 1
    )
    $lines = @(Get-Content -LiteralPath $Path)
    $sections = @()
    for ($i = ($BodyStartLine - 1); $i -lt $lines.Count; $i++) {
        if ($null -eq $lines[$i]) { continue }
        if ($lines[$i] -match '^(#{1,6})\s+(.+)$') {
            $sections += [pscustomobject]@{
                Line  = $i + 1
                Level = $Matches[1].Length
                Title = $Matches[2].Trim()
            }
        }
    }
    return $sections
}

function Test-BodyIntroduction {
    <#
        Regla 2 exige "introduccion". Se considera cumplida si hay al menos una
        linea de prosa (no encabezado, no separador, no tabla) antes del primer
        encabezado de nivel 2 (o de nivel 1 distinto del titulo del agente).
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [int]$BodyStartLine = 1
    )
    $lines = @(Get-Content -LiteralPath $Path)
    $h1Seen = $false
    for ($i = ($BodyStartLine - 1); $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0) { continue }
        if ($trimmed -match '^#{1,6}\s+') {
            if ($trimmed -match '^#\s+' -and -not $h1Seen) { $h1Seen = $true; continue }
            # Cualquier otro encabezado cierra la zona de introduccion.
            return $false
        }
        if ($trimmed -match '^(-{3,}|\*{3,}|_{3,}|=+\s*$|```|\|)') { continue }
        if ($trimmed -match '^[-*+]\s+' -or $trimmed -match '^\d+\.\s+') { continue }
        return $true
    }
    return $false
}

function Get-DeclaredSkills {
    <# Skills declaradas en el frontmatter (lista 'skills:'), con su linea. #>
    param([Parameter(Mandatory)]$Document)
    $declared = @()
    if ($null -eq $Document.Fields) { return $declared }
    if (-not $Document.Fields.Contains('skills')) { return $declared }
    foreach ($item in @($Document.Fields['skills'].Items)) {
        if ($null -ne $item) {
            $declared += [pscustomobject]@{ Name = ([string]$item.Value).Trim(); Line = [int]$item.Line }
        }
    }
    return $declared
}

# =============================================================================
# 3. Indices de skills
# =============================================================================

function Get-SkillIndex {
    <#
        Indexa recursivamente los SKILL.md de una raiz de skills.
        La clave es el nombre del DIRECTORIO HOJA (lo que declaran los agentes);
        el valor es la lista de rutas relativas donde aparece ese nombre.
    #>
    param([Parameter(Mandatory)][string]$SkillsRoot)

    $index = @{}
    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) { return $index }
    foreach ($file in (Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue)) {
        $leaf = $file.Directory.Name
        $relative = Get-RelativeDisplayPath -BasePath $SkillsRoot -FullPath $file.FullName
        if (-not $index.ContainsKey($leaf)) { $index[$leaf] = @() }
        $index[$leaf] = @($index[$leaf]) + $relative
    }
    return $index
}

function Get-SkillRelativePaths {
    <# Rutas relativas de todos los SKILL.md de una raiz (normalizadas a '/'). #>
    param([Parameter(Mandatory)][string]$SkillsRoot)
    if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) { return @() }
    return @(
        Get-ChildItem -LiteralPath $SkillsRoot -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue |
            ForEach-Object { Get-RelativeDisplayPath -BasePath $SkillsRoot -FullPath $_.FullName } |
            Sort-Object
    )
}

# =============================================================================
# 4. Inventario de agentes
# =============================================================================

$githubAgentFiles = @()
if (Test-Path -LiteralPath $script:AgentsGithubDir -PathType Container) {
    $githubAgentFiles = @(Get-ChildItem -LiteralPath $script:AgentsGithubDir -File -Filter '*.agent.md' -ErrorAction SilentlyContinue | Sort-Object Name)
}

$opencodeAgentFiles = @()
if (Test-Path -LiteralPath $script:AgentsOpencodeDir -PathType Container) {
    $opencodeAgentFiles = @(Get-ChildItem -LiteralPath $script:AgentsOpencodeDir -File -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object Name)
}

function Get-AgentBaseName {
    <# Normaliza el sufijo '.agent' del nombre base antes de comparar arneses. #>
    param([Parameter(Mandatory)][string]$FileName)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $base = $base -replace '\.agent$', ''
    return $base
}

$agentDocuments = @()
foreach ($file in $githubAgentFiles) {
    $agentDocuments += [pscustomobject]@{
        Harness = 'github'
        Name    = (Get-AgentBaseName -FileName $file.Name)
        File    = $file.FullName
        Doc     = (Get-AgentDocument -Path $file.FullName)
    }
}
foreach ($file in $opencodeAgentFiles) {
    $agentDocuments += [pscustomobject]@{
        Harness = 'opencode'
        Name    = (Get-AgentBaseName -FileName $file.Name)
        File    = $file.FullName
        Doc     = (Get-AgentDocument -Path $file.FullName)
    }
}

# =============================================================================
# 5. Chequeos
# =============================================================================

function Test-AgentParity {
    <# VAL-01: paridad de agentes entre .github/agents y .opencode/agents. #>
    param(
        [object[]]$GithubFiles = @(),
        [object[]]$OpencodeFiles = @()
    )

    $id = 'VAL-01'
    $name = 'Paridad de agentes entre harnesses'
    $rule = 'AGENTS.md - Regla 3: ".github/agents/ y .opencode/agents/ en paralelo"'

    $violations = @()
    if (-not (Test-Path -LiteralPath $script:AgentsGithubDir -PathType Container)) {
        $violations += New-Violation -File '.github/agents' -Message 'no existe el directorio .github/agents'
    }
    if (-not (Test-Path -LiteralPath $script:AgentsOpencodeDir -PathType Container)) {
        $violations += New-Violation -File '.opencode/agents' -Message 'no existe el directorio .opencode/agents'
    }
    if ($violations.Count -gt 0) {
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' -ViolationSummary 'faltan directorios de agentes' -Violations $violations
    }

    $githubNames = @($GithubFiles | ForEach-Object { Get-AgentBaseName -FileName $_.Name })
    $opencodeNames = @($OpencodeFiles | ForEach-Object { Get-AgentBaseName -FileName $_.Name })

    foreach ($entry in $GithubFiles) {
        $baseName = Get-AgentBaseName -FileName $entry.Name
        if ($opencodeNames -notcontains $baseName) {
            $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.FullName) `
                -Message "agente '$baseName' sin par: falta .opencode/agents/$baseName.md"
        }
    }
    foreach ($entry in $OpencodeFiles) {
        $baseName = Get-AgentBaseName -FileName $entry.Name
        if ($githubNames -notcontains $baseName) {
            $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.FullName) `
                -Message "agente '$baseName' sin par: falta .github/agents/$baseName.agent.md"
        }
    }

    $okMessage = "$($githubNames.Count) agentes en .github/agents y $($opencodeNames.Count) en .opencode/agents; todos con par"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) agente(s) sin par entre arneses" -Violations $violations
}

function Test-Frontmatter {
    <# VAL-02: frontmatter presente (--- en linea 1) y bloque cerrado/parseable. #>
    param([object[]]$Documents = @())

    $id = 'VAL-02'
    $name = 'Frontmatter presente y parseable'
    $rule = 'AGENTS.md - Regla 2: "Estructura estandar de agente: frontmatter, ..."'

    $violations = @()
    foreach ($entry in $Documents) {
        $doc = $entry.Doc
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File
        if (-not $doc.HasFrontmatter) {
            $violations += New-Violation -File $relative -Line 1 -Message 'el archivo no abre con --- en la linea 1 (frontmatter ausente)'
            continue
        }
        if (-not $doc.IsClosed) {
            $violations += New-Violation -File $relative -Line 1 -Message 'bloque de frontmatter abierto sin cierre ---'
            continue
        }
        if ($doc.YamlInvalid) {
            $violations += New-Violation -File $relative -Line 1 -Message "frontmatter YAML invalido (ConvertFrom-Yaml): $($doc.YamlError)"
        }
    }

    $okMessage = "$(@($Documents).Count) agentes con frontmatter delimitado y parseable"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) agente(s) con frontmatter ausente, sin cierre o invalido" -Violations $violations
}

function Test-FrontmatterRequiredKeys {
    <# VAL-03: claves obligatorias tier y description. #>
    param([object[]]$Documents = @())

    $id = 'VAL-03'
    $name = 'Claves obligatorias del frontmatter'
    $rule = 'AGENTS.md - Regla 2 (frontmatter) + campos consumidos por ambos arneses: tier, description'

    $violations = @()
    foreach ($entry in $Documents) {
        $doc = $entry.Doc
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File
        foreach ($requiredKey in @('tier', 'description')) {
            if (-not $doc.Fields.Contains($requiredKey)) {
                $violations += New-Violation -File $relative -Line 1 -Message "frontmatter sin la clave obligatoria '$requiredKey'"
                continue
            }
            $value = Get-FieldValue -Fields $doc.Fields -Key $requiredKey
            if ([string]::IsNullOrWhiteSpace($value)) {
                $line = [int]$doc.Fields[$requiredKey].Line
                $violations += New-Violation -File $relative -Line $line -Message "la clave '$requiredKey' esta vacia"
            }
        }
    }

    $okMessage = "todos los agentes declaran 'tier' y 'description'"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) clave(s) obligatoria(s) ausente(s) o vacia(s)" -Violations $violations
}

function Test-TierValue {
    <# VAL-04: el valor de tier pertenece a la lista canonica de AGENTS.md. #>
    param(
        [object[]]$Documents = @(),
        [string[]]$CanonicalTiers = @()
    )

    $id = 'VAL-04'
    $name = 'Tier valido'
    $rule = 'AGENTS.md - tabla "Agent road assignment" (cinco tiers canonicos)'

    $violations = @()
    foreach ($entry in $Documents) {
        $doc = $entry.Doc
        if (-not $doc.Fields.Contains('tier')) { continue }  # lo reporta VAL-03
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File
        $tier = Get-FieldValue -Fields $doc.Fields -Key 'tier'
        if ([string]::IsNullOrWhiteSpace($tier)) { continue }  # lo reporta VAL-03
        $normalized = ConvertTo-NormalizedText -Text $tier
        $match = $CanonicalTiers | Where-Object { (ConvertTo-NormalizedText -Text $_) -eq $normalized } | Select-Object -First 1
        if ($null -eq $match) {
            $line = [int]$doc.Fields['tier'].Line
            $violations += New-Violation -File $relative -Line $line `
                -Message "tier '$tier' no pertenece a la lista canonica ($($CanonicalTiers -join ', '))"
        }
    }

    $okMessage = "todos los agentes usan un tier canonico ($($CanonicalTiers -join ', '))"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) agente(s) con tier fuera de la lista canonica" -Violations $violations
}

function Test-DeclaredSkillsExist {
    <# VAL-05: cada skill declarada resuelve a un SKILL.md real (hoja, dos niveles). #>
    param(
        [object[]]$Documents = @(),
        [hashtable]$OpencodeSkills = @{},
        [hashtable]$GithubSkills = @{}
    )

    $id = 'VAL-05'
    $name = 'Skills declaradas existen'
    $rule = 'Skills de dos niveles: .opencode/skills/<categoria>/<skill>/SKILL.md; el agente declara el directorio hoja'

    $violations = @()
    $declaredCount = 0
    foreach ($entry in @($Documents)) {
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File
        foreach ($skill in (Get-DeclaredSkills -Document $entry.Doc)) {
            $declaredCount++
            if ($OpencodeSkills.ContainsKey($skill.Name)) { continue }
            if ($GithubSkills.ContainsKey($skill.Name)) {
                $violations += New-Violation -File $relative -Line $skill.Line `
                    -Message "skill '$($skill.Name)' existe solo en .github/skills (:$($GithubSkills[$skill.Name] -join ', ')); falta en .opencode/skills"
                continue
            }
            $violations += New-Violation -File $relative -Line $skill.Line `
                -Message "skill '$($skill.Name)' no resuelve a ningun SKILL.md bajo .opencode/skills (se busca el directorio hoja '$($skill.Name)')"
        }
    }

    $okMessage = "$declaredCount skill(s) declarada(s) en frontmatter, todas resueltas a un SKILL.md"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) skill(s) declarada(s) que no resuelven a un SKILL.md" -Violations $violations
}

function Test-SkillsParity {
    <# VAL-06: mismo conjunto de SKILL.md relativos en ambos arneses. #>
    param(
        [string]$GithubRoot = $script:SkillsGithubDir,
        [string]$OpencodeRoot = $script:SkillsOpencodeDir
    )

    $id = 'VAL-06'
    $name = 'Paridad de skills entre harnesses'
    $rule = 'AGENTS.md - Regla 3: arneses en paralelo (mismas skills en ambos arboles)'

    $violations = @()
    $githubSkills = Get-SkillRelativePaths -SkillsRoot $GithubRoot
    $opencodeSkills = Get-SkillRelativePaths -SkillsRoot $OpencodeRoot

    foreach ($relative in $githubSkills) {
        if ($opencodeSkills -notcontains $relative) {
            $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath (Join-Path $GithubRoot $relative)) `
                -Message "SKILL.md presente en .github/skills y ausente en .opencode/skills ($relative)"
        }
    }
    foreach ($relative in $opencodeSkills) {
        if ($githubSkills -notcontains $relative) {
            $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath (Join-Path $OpencodeRoot $relative)) `
                -Message "SKILL.md presente en .opencode/skills y ausente en .github/skills ($relative)"
        }
    }

    $okMessage = "$($githubSkills.Count) SKILL.md en cada arnes, mismo conjunto"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) SKILL.md sin par entre arneses" -Violations $violations
}

function Test-McpCoverage {
    <# VAL-07: cobertura de MCPs (Regla 1b) - todo MCP de opencode.json citado por algun agente. #>
    param(
        [string]$ConfigPath = $script:OpencodeConfigPath,
        [object[]]$Documents = @()
    )

    $id = 'VAL-07'
    $name = 'Cobertura MCP (Regla 1b)'
    $reglaNode = Get-FirstMatchingLine -Path $script:AgentsMdPath -Pattern 'Regla 1b'
    $ruleText = if ($null -ne $reglaNode) {
        "AGENTS.md L$($reglaNode.Line): $($reglaNode.Text)"
    }
    else { 'AGENTS.md - Regla 1b (no se pudo citar: linea no encontrada)' }

    $violations = @()
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $ConfigPath) `
            -Message 'no existe opencode.json: no se puede verificar la cobertura de MCPs'
        return New-CheckOutcome -Id $id -Name $name -Rule $ruleText -OkMessage '' `
            -ViolationSummary 'no existe opencode.json' -Violations $violations
    }

    $serverNames = @()
    try {
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $config.mcp -and $null -ne $config.mcp.servers) {
            $serverNames = @($config.mcp.servers.PSObject.Properties.Name)
        }
        elseif ($null -ne $config.mcp) {
            $serverNames = @($config.mcp.PSObject.Properties.Name | Where-Object { $_ -notmatch '^[$_@]' })
        }
    }
    catch {
        $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $ConfigPath) `
            -Message "opencode.json no es JSON valido: $($_.Exception.Message)"
        return New-CheckOutcome -Id $id -Name $name -Rule $ruleText -OkMessage '' `
            -ViolationSummary 'opencode.json invalido' -Violations $violations
    }

    if ($serverNames.Count -eq 0) {
        $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $ConfigPath) `
            -Message 'opencode.json no declara ningun MCP en mcp.servers'
        return New-CheckOutcome -Id $id -Name $name -Rule $ruleText -OkMessage '' `
            -ViolationSummary 'sin MCPs declarados' -Violations $violations
    }

    # El cuerpo de cada agente de OpenCode es la superficie que consume los MCPs.
    $opencodeDocs = @($Documents | Where-Object { $_.Harness -eq 'opencode' })
    $bodies = @()
    foreach ($entry in $opencodeDocs) {
        $doc = $entry.Doc
        $start = [Math]::Max(0, $doc.BodyStartLine - 1)
        $bodyLines = @()
        if ($start -lt $doc.Lines.Count) {
            $bodyLines = @($doc.Lines[$start..($doc.Lines.Count - 1)])
        }
        $bodies += [pscustomobject]@{
            File = (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File)
            Text = ($bodyLines -join "`n")
        }
    }

    foreach ($serverName in $serverNames) {
        $escaped = [regex]::Escape($serverName)
        $matching = @($bodies | Where-Object { $_.Text -match $escaped })
        if ($matching.Count -eq 0) {
            $violations += New-Violation -File 'opencode.json' `
                -Message "MCP '$serverName' registrado en mcp.servers pero ningun agente de .opencode/agents lo declara (Regla 1b)"
        }
    }

    $covered = $serverNames.Count - $violations.Count
    $okMessage = "$($serverNames.Count) MCP(s) declarado(s) en opencode.json, todos citados por al menos un agente"
    return New-CheckOutcome -Id $id -Name $name -Rule $ruleText -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) de $($serverNames.Count) MCP(s) sin cobertura en agentes" -Violations $violations
}

function Test-AgentStructure {
    <# VAL-08: estructura minima del agente segun Regla 2 de AGENTS.md. #>
    param([object[]]$Documents = @())

    $id = 'VAL-08'
    $name = 'Estructura minima del agente (Regla 2)'
    $reglaNode = Get-FirstMatchingLine -Path $script:AgentsMdPath -Pattern 'Estructura estandar de agente'
    $ruleText = if ($null -ne $reglaNode) {
        "AGENTS.md L$($reglaNode.Line): $($reglaNode.Text)"
    }
    else { 'AGENTS.md - Regla 2 (no se pudo citar: linea no encontrada)' }

    # Secciones exigidas por la Regla 2. 'frontmatter' lo cubren VAL-02/VAL-03.
    # Los patrones aceptan el equivalente en espanol que usa el kit.
    $requiredSections = @(
        [pscustomobject]@{ Key = 'introduccion'; Label = 'introduccion'; Patterns = @() }
        [pscustomobject]@{ Key = 'skills';       Label = 'skills';       Patterns = @('skills') }
        [pscustomobject]@{ Key = 'enfoque';      Label = 'enfoque';      Patterns = @('enfoque', 'approach') }
        [pscustomobject]@{ Key = 'mcps';         Label = 'MCPs';         Patterns = @('mcp') }
        [pscustomobject]@{ Key = 'idioma';       Label = 'idioma';       Patterns = @('idioma', 'language') }
        [pscustomobject]@{ Key = 'constraints';  Label = 'constraints';  Patterns = @('constraint', 'restricci') }
    )

    $violations = @()
    foreach ($entry in @($Documents)) {
        $doc = $entry.Doc
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $entry.File
        $sections = Get-BodySections -Path $entry.File -BodyStartLine $doc.BodyStartLine
        $titles = @($sections | ForEach-Object { ConvertTo-NormalizedText -Text $_.Title })

        foreach ($required in $requiredSections) {
            if ($required.Key -eq 'introduccion') {
                $hasIntro = Test-BodyIntroduction -Path $entry.File -BodyStartLine $doc.BodyStartLine
                if (-not $hasIntro) {
                    $violations += New-Violation -File $relative -Line $doc.BodyStartLine `
                        -Message 'falta la introduccion (no hay prosa antes del primer encabezado de seccion)'
                }
                continue
            }
            $found = $false
            foreach ($pattern in $required.Patterns) {
                if (@($titles | Where-Object { $_ -match $pattern }).Count -gt 0) { $found = $true; break }
            }
            if (-not $found) {
                $violations += New-Violation -File $relative -Line $doc.BodyStartLine `
                    -Message "falta la seccion '$($required.Label)' exigida por la Regla 2"
            }
        }
    }

    $okMessage = "$(@($Documents).Count) agentes con las secciones de la Regla 2 (introduccion, skills, enfoque, MCPs, idioma, constraints)"
    return New-CheckOutcome -Id $id -Name $name -Rule $ruleText -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) seccion(es) obligatoria(s) ausente(s)" -Violations $violations
}

function Test-OrphanSkills {
    <#
        VAL-09: SKILL.md que ningun agente declara. Es AVISO (WARN): el kit puede
        tener skills globales legitimas que ningun agente declara en su frontmatter.
        Se considera "declarada" si aparece en el frontmatter (lista skills:) o si
        el nombre hoja es mencionado en el cuerpo de algun agente (seccion
        "Skills que utilizas"), en cualquiera de los dos arneses.
    #>
    param(
        [object[]]$Documents = @(),
        [string]$GithubRoot = $script:SkillsGithubDir,
        [string]$OpencodeRoot = $script:SkillsOpencodeDir
    )

    $id = 'VAL-09'
    $name = 'Skills huerfanas'
    $rule = 'Aviso: skill global sin agente declarante (no es error por si mismo)'

    $githubIndex = Get-SkillIndex -SkillsRoot $GithubRoot
    $opencodeIndex = Get-SkillIndex -SkillsRoot $OpencodeRoot

    $allSkills = @{}
    foreach ($key in @($opencodeIndex.Keys) + @($githubIndex.Keys)) { $allSkills[$key] = $true }

    $declared = @{}
    $bodyTexts = @()
    foreach ($entry in @($Documents)) {
        foreach ($skill in (Get-DeclaredSkills -Document $entry.Doc)) {
            $declared[$skill.Name.ToLowerInvariant()] = $true
        }
        foreach ($line in $entry.Doc.Lines) { $bodyTexts += [string]$line }
    }
    $normalizedBody = (ConvertTo-NormalizedText -Text ($bodyTexts -join "`n"))

    $violations = @()
    foreach ($skillName in ($allSkills.Keys | Sort-Object)) {
        $lower = $skillName.ToLowerInvariant()
        if ($declared.ContainsKey($lower)) { continue }
        if ($normalizedBody -match [regex]::Escape($lower)) { continue }
        $locations = @()
        if ($opencodeIndex.ContainsKey($skillName)) { $locations += @($opencodeIndex[$skillName] | ForEach-Object { ".opencode/skills/$_" }) }
        if ($githubIndex.ContainsKey($skillName)) { $locations += @($githubIndex[$skillName] | ForEach-Object { ".github/skills/$_" }) }
        $violations += New-Violation -File ($locations | Select-Object -First 1) `
            -Message "skill '$skillName' no esta declarada ni mencionada por ningun agente ($($locations -join ', '))"
    }

    $total = $allSkills.Keys.Count
    $okMessage = "$total skills indexadas y todas declaradas o mencionadas por algun agente"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSeverity 'WARN' `
        -ViolationSummary "$($violations.Count) de $total skill(s) sin agente declarante (aviso)" -Violations $violations
}

function Test-DefaultAgentBoot {
    <#
        VAL-10: arranque por defecto valido (spec 034). opencode.json debe declarar
        default_agent; el valor no puede ser el agente incorporado 'build'; debe
        existir .opencode/agents/<valor>.md y ese archivo debe declarar mode: primary.
        Si falta cualquiera de esas condiciones, OpenCode degrada el arranque a
        'build' con un warning, por lo que se reporta como FAIL.
    #>
    param(
        [string]$ConfigPath = $script:OpencodeConfigPath,
        [string]$AgentsDir = $script:AgentsOpencodeDir
    )

    $id = 'VAL-10'
    $name = 'Arranque por defecto valido'
    $reglaNode = Get-FirstMatchingLine -Path $script:AgentsMdPath -Pattern 'Arranque por defecto del arnes'
    $rule = if ($null -ne $reglaNode) {
        "AGENTS.md L$($reglaNode.Line): $($reglaNode.Text)"
    }
    else { 'AGENTS.md - "Arranque por defecto del arnes" (spec 034; no se pudo citar la linea)' }

    $configRelative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $ConfigPath
    $violations = @()

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        $violations += New-Violation -File $configRelative `
            -Message 'no existe opencode.json: no se puede verificar el arranque por defecto'
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' `
            -ViolationSummary 'no existe opencode.json' -Violations $violations
    }

    try {
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $violations += New-Violation -File $configRelative `
            -Message "opencode.json no es JSON valido: $($_.Exception.Message)"
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' `
            -ViolationSummary 'opencode.json invalido' -Violations $violations
    }

    if (-not (@($config.PSObject.Properties.Name) -contains 'default_agent')) {
        $violations += New-Violation -File $configRelative `
            -Message 'opencode.json no declara default_agent: el arnes arranca con el agente incorporado'
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' `
            -ViolationSummary 'falta default_agent' -Violations $violations
    }

    $defaultAgent = ([string]$config.default_agent).Trim()
    if ([string]::IsNullOrWhiteSpace($defaultAgent)) {
        $violations += New-Violation -File $configRelative -Message 'default_agent esta vacio'
    }
    elseif ($defaultAgent -eq 'build') {
        $violations += New-Violation -File $configRelative `
            -Message "default_agent apunta al agente incorporado 'build': no es un agente del kit"
    }
    else {
        $agentFile = Join-Path $AgentsDir ($defaultAgent + '.md')
        if (-not (Test-Path -LiteralPath $agentFile -PathType Leaf)) {
            $violations += New-Violation -File $configRelative `
                -Message "default_agent '$defaultAgent' no tiene archivo .opencode/agents/$defaultAgent.md"
        }
        else {
            $agentDoc = Get-AgentDocument -Path $agentFile
            $mode = Get-FieldValue -Fields $agentDoc.Fields -Key 'mode'
            if ($mode -ne 'primary') {
                $modeLine = 0
                if ($agentDoc.Fields.Contains('mode')) { $modeLine = [int]$agentDoc.Fields['mode'].Line }
                $shownMode = if ([string]::IsNullOrWhiteSpace($mode)) { '(sin mode)' } else { $mode }
                $violations += New-Violation -File (Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $agentFile) `
                    -Line $modeLine `
                    -Message "el agente por defecto '$defaultAgent' declara mode: $shownMode (se exige primary)"
            }
        }
    }

    $okMessage = "default_agent = '$defaultAgent', agente del kit presente y con mode: primary"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) problema(s) en el arranque por defecto" -Violations $violations
}

function Get-CanonicalTiers {
    <#
        Deriva los tiers canonicos de la tabla "Agent road assignment" de AGENTS.md.
        El parseo se ANCLA en la cabecera de esa tabla (linea que matchea
        '| Tier | Agents |') y solo recorre las filas contiguas de esa misma tabla:
        al topar la primera linea que deja de ser fila de tabla, corta (break). Asi
        una tabla ajena que tambien use backticks en su segunda columna (por
        ejemplo la "Matriz de enrutamiento por tarea") ya NO contamina la lista
        canonica. Dentro de la tabla se conserva la logica previa: se salta la
        cabecera y la fila separadora y se toma la columna 0 como tier.
        Si no se pueden derivar >= 3 tiers, se usa la lista hardcodeada de respaldo.
        Fuente de verdad: AGENTS.md ("Agent road assignment: 14 agentes, cinco tiers").
    #>
    param([Parameter(Mandatory)][string]$AgentsMdPath)

    $fallback = @('Documental', 'Documental extendido', 'Implementador', 'Tooling', 'Plataforma')
    if (-not (Test-Path -LiteralPath $AgentsMdPath -PathType Leaf)) { return $fallback }

    $lines = @(Get-Content -LiteralPath $AgentsMdPath)
    $tiers = @()
    $enTabla = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]
        if (-not $enTabla) {
            # Ancla: cabecera exacta de la tabla de tiers.
            if ($line -match '^\s*\|\s*Tier\s*\|\s*Agents\s*\|') { $enTabla = $true }
            continue
        }
        # Ya dentro de la tabla: la primera linea que no es fila cierra el bloque.
        if ($line -notmatch '^\s*\|.*\|\s*$') { break }
        $cells = @($line.Trim().Trim('|') -split '\|')
        if ($cells.Count -lt 2) { continue }
        $tierCell = $cells[0].Trim()
        $agentsCell = $cells[1].Trim()
        if ($tierCell -eq 'Tier') { continue }
        if ($tierCell -match '^[-:\s]+$') { continue }
        if ($agentsCell -notmatch '`') { continue }   # solo la tabla de tiers lista agentes entre backticks
        if ($tiers -notcontains $tierCell) { $tiers += $tierCell }
    }

    if (@($tiers).Count -ge 3) { return $tiers }
    return $fallback
}

function Test-BacklogCoherence {
    <#
        VAL-11: coherencia backlog <-> disco (spec 035). Compara las carpetas de
        Documentacion/Agents_IA_TECH/specs/ que tienen spec.md contra el indice
        00-indice.md:
          - Orfanas: spec numerada/no-numerada en disco sin entrada en el indice
            (ni '## Especificacion <NNN>' ni el slug) -> FAIL.
          - Divergencia de estado: el bloque del indice declara 'Cerrado'/
            'Completada'/'Completa' pero tasks.md (si existe) tiene tareas en
            'Pendiente'/sin marcar '[ ]' -> WARN (listado, no rompe el gate).
        Excluye specs/archived/ y los directorios sin spec.md.
        Severidad: FAIL (orfanas) y WARN (divergencias de estado). Solo lectura.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SpecsDir,
        [Parameter(Mandatory)][string]$IndexPath
    )

    $id = 'VAL-11'
    $name = 'Coherencia backlog-desc (spec 035)'
    $rule = 'spec 035 (auditoria-specs-backlog.md): specs/ con spec.md debe tener entrada en 00-indice.md; estados Cerrado/Completada coherentes con tasks.md'

    $failViolations = @()
    $warnViolations = @()
    $indexDisplay = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $IndexPath

    if (-not (Test-Path -LiteralPath $SpecsDir -PathType Container)) {
        $failViolations += New-Violation -File $indexDisplay `
            -Message "no existe el directorio Documentacion/Agents_IA_TECH/specs ($SpecsDir)"
        return New-CheckOutcome -Id $id -Name $name -Rule $rule `
            -ViolationSummary "no existe specs/: no se puede verificar coherencia" -Violations $failViolations
    }

    # Lectura del indice: lineas crudas (para fragmentos) y normalizadas (para busquedas).
    $rawIndexLines = @()
    if (Test-Path -LiteralPath $IndexPath -PathType Leaf) {
        $rawIndexLines = @(Get-Content -LiteralPath $IndexPath)
    }
    else {
        $failViolations += New-Violation -File $indexDisplay -Message 'no existe 00-indice.md'
        return New-CheckOutcome -Id $id -Name $name -Rule $rule `
            -ViolationSummary 'no existe 00-indice.md' -Violations $failViolations
    }
    $normIndexLines = @($rawIndexLines | ForEach-Object { ConvertTo-NormalizedText -Text $_ })
    $normalizedIndex = ($normIndexLines -join "`n")
    $normalizedIndexLineCount = $normIndexLines.Count

    # Cabeceras del indice: '## especificacion <nombre>'.
    $headers = @()
    for ($i = 0; $i -lt $normIndexLines.Count; $i++) {
        if ($normIndexLines[$i] -match '^## especificacion\s+(.+)$') {
            $headers += [pscustomobject]@{ RetainedIndex = $i; Name = $Matches[1].Trim() }
        }
    }

    $dirs = @(Get-ChildItem -LiteralPath $SpecsDir -Directory | Where-Object { $_.Name -ne 'archived' } | Sort-Object Name)
    $specCount = 0
    $orphanCount = 0
    $warnCount = 0

    foreach ($dir in $dirs) {
        $specFile = Join-Path $dir.FullName 'spec.md'
        if (-not (Test-Path -LiteralPath $specFile -PathType Leaf)) { continue }  # sin spec.md no aplica
        $specCount++
        $relative = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $dir.FullName
        $normalizedSlug = ConvertTo-NormalizedText -Text $dir.Name

        # 1) Buscar cabecera en el indice: por numero (si el slug tiene prefijo numerico) o por slug.
        $header = $null
        if ($normalizedSlug -match '^(\d+)') {
            $num = $Matches[1]
            $header = $headers | Where-Object {
                ($_.Name -match ('^' + [regex]::Escape($num) + '\b')) -or ($_.Name -match ('\b' + [regex]::Escape($num) + '\b'))
            } | Select-Object -First 1
        }
        if ($null -eq $header) {
            $header = $headers | Where-Object { $_.Name -match [regex]::Escape($normalizedSlug) -or $normalizedSlug -match [regex]::Escape($_.Name) } | Select-Object -First 1
        }
        # Fallback: el slug aparece en el cuerpo del indice (sin ser cabecera).
        $slugInBody = $null -eq $header -and $normalizedIndex -match [regex]::Escape($normalizedSlug)

        if ($null -eq $header -and -not $slugInBody) {
            $orphanCount++
            $failViolations += New-Violation -File $relative -Message 'spec en disco sin entrada en 00-indice.md (huerfana)'
            continue
        }

        # 2) Divergencia de estado (WARN): bloque del indice declara Cerrado/Completada y tasks.md tiene pendientes.
        $tasksPath = Join-Path $dir.FullName 'tasks.md'
        if (-not (Test-Path -LiteralPath $tasksPath -PathType Leaf)) { continue }  # sin tasks.md no hay coherencia que evaluar

        # Ventana del bloque de la spec en el indice: de su cabecera a la proxima cabecera (o limite 80 lineas).
        $blockStart = if ($null -ne $header) { $header.RetainedIndex } else { 0 }
        $blockEnd = [Math]::Min($blockStart + 80, $rawIndexLines.Count - 1)
        if ($null -ne $header) {
            $next = $headers | Where-Object { $_.RetainedIndex -gt $blockStart } | Select-Object -First 1
            if ($null -ne $next) { $blockEnd = $next.RetainedIndex - 1 }
        }
        else {
            # Sin cabecera exacta: buscar la linea donde aparece el slug en el cuerpo del indice.
            for ($i = 0; $i -lt $normalizedIndexLineCount; $i++) {
                if ($normIndexLines[$i] -match [regex]::Escape($normalizedSlug)) { $blockStart = $i; break }
            }
        }
        if ($blockStart -lt 0) { $blockStart = 0 }
        $blockNorm = ''
        if ($blockStart -lt $rawIndexLines.Count) {
            $slice = @($normIndexLines[$blockStart..$blockEnd])
            $blockNorm = ($slice -join "`n")
        }
        else { $blockNorm = $normalizedIndex }

        $declaresClosed = $blockNorm -match '\bcerrad[oa]s?\b' -or $blockNorm -match '\bcompletad[oa]s?\b' -or $blockNorm -match '\bcompleta\b'

        $tasksText = (Get-Content -LiteralPath $tasksPath -Raw)
        $hasPending = ($tasksText -match '- \[ \]') -or ($tasksText -match '\[ \]') -or ($tasksText -match '\bpendiente\b' -and $tasksText -notmatch 'sin pendientes')
        if ($declaresClosed -and $hasPending) {
            $warnCount++
            $warnViolations += New-Violation -File $relative `
                -Message "el indice declara Cerrado/Completada pero tasks.md tiene tareas Pendiente/sin marcar ([ ])"
        }
    }

    if ($failViolations.Count -gt 0) {
        $summary = "$orphanCount spec(s) huerfana(s) de $specCount con spec.md"
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' `
            -ViolationSummary $summary -Violations $failViolations
    }

    if ($warnViolations.Count -gt 0) {
        $summary = "$warnCount divergencia(s) de estado (Cerrado/Completada con tasks pendientes)"
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage `
            "$specCount specs con entrada en el indice, sin huerfanas; $warnCount divergencia(s) de estado" `
            -ViolationSeverity 'WARN' -ViolationSummary $summary -Violations $warnViolations
    }

    return New-CheckOutcome -Id $id -Name $name -Rule $rule `
        -OkMessage "$specCount specs con spec.md, todas registradas en el indice y con estados coherentes" `
        -Violations @()
}

function Get-TaskStateMap {
    <#
        Devuelve un mapa: taskId (mayusculas, normalizado) -> { State, Line, File }.
        Parsea las filas de tabla de un archivo de tareas/backlog extrayendo la
        primera columna (ID) y la columna de estado. Se usa tanto para
        specs/*/tasks.md como para pendientes-implementacion.md.
        Estado = las primeras palabras apoyadas por el kit; se conserva el texto
        crudo normalizado para decidir si es 'cerrado' o 'pendiente'.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [int]$IdColumn = 1,
        [int]$StateColumn = 6
    )

    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $map }
    $i = 0
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $i++
        if ($line -notmatch '^\s*\|.*\|.*\|') { continue }
        $cells = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt ($StateColumn + 1)) { continue }
        $idRaw = $cells[$IdColumn]
        if ($idRaw -match '^\s*[-: ]+\s*$') { continue }   # fila separadora |---|---|
        if ($idRaw -cmatch '^\s*ID\s*$') { continue }      # cabecera
        $idNorm = ConvertTo-NormalizedText -Text $idRaw
        if ([string]::IsNullOrWhiteSpace($idNorm)) { continue }
        # Solo IDs de tarea reales (prefijo de spec + sufijo T.. / TRANS- / [x]).
        if ($idNorm -notmatch '^(t\d+|[a-z0-9]+\-t\d+[a-z0-9\-]*|trans\-\d+|t0|t\d{2}\-[a-z]\d+(\-[a-z]\d+)?)') { continue }
        $state = $cells[$StateColumn]
        $map[$idNorm] = [pscustomobject]@{
            Id      = $idRaw
            State   = $state
            StateNorm = (ConvertTo-NormalizedText -Text $state)
            Line    = $i
            File    = $Path
        }
    }
    return $map
}

function Test-BacklogGate {
    <#
        VAL-12: gate mecanico del backlog (TRANS-001 / feature 017). Hace
        obligatorio que Documentacion/Agents_IA_TECH/pendientes-implementacion.md
        exista y este coherente con los tasks.md de cada spec, de modo que una
        fase Speckit no pueda abrirse/cerrarse sin mantener el backlog al dia.
          (a) Existencia: el archivo debe existir. FAIL si falta.
          (b) Placeholders: sin TBD/TODO/XXX/Lorem/pendiente de informacion/
              por definir/etc. FAIL si aparece alguno.
          (c) Divergencia critica: una tarea 'Cerrado' en tasks.md NO debe estar
              'Pendiente' (ni '[ ]') en el backlog de la misma spec. FAIL.
        Solo la divergencia critica del punto (c) rompe el gate; la direccion
        inversa (backlog mas avanzado que tasks.md, tipica de una spec recien
        implementada) se tolera para no generar falso FAIL (los estados del
        backlog reflejan lo ya implementado).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BacklogPath,
        [Parameter(Mandatory)][string]$SpecsDir
    )

    $id = 'VAL-12'
    $name = 'Gate del backlog pendientes-implementacion (TRANS-001)'
    $rule = 'spec 035 (fr-011/sc-006) + feature 017: pendientes-implementacion.md debe existir, sin placeholders y coherente con specs/*/tasks.md (Cerrado en tasks.md nunca Pendiente en backlog)'

    $violations = @()
    $backlogDisplay = Get-RelativeDisplayPath -BasePath $script:RootPath -FullPath $BacklogPath

    # ---------------------------------------------------------------- (a) exista
    if (-not (Test-Path -LiteralPath $BacklogPath -PathType Leaf)) {
        $violations += New-Violation -File $backlogDisplay `
            -Message 'no existe Documentacion/Agents_IA_TECH/pendientes-implementacion.md: el gate de backlog no puede operar'
        return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage '' `
            -ViolationSummary 'no existe pendientes-implementacion.md' -Violations $violations
    }

    $rawBacklogLines = @(Get-Content -LiteralPath $BacklogPath)
    $normBacklog = (ConvertTo-NormalizedText -Text ($rawBacklogLines -join "`n"))

    # ------------------------------------------------------- (b) placeholders
    # Placeholder canonizados (AGENTS.md). Dos clases:
    #   - Marcadores ASCII en minuscula/ingles (TBD, TODO, XXX, Lorem) y frases
    #     en espanol se detectan sobre texto normalizado con limites de palabra.
    #     Se omite deliberadamente 'todo' suelto (es espanol legitimo: "todo item")
    #     y 'N/A' (en este archivo significa "no aplica", no falta de contenido).
    #   Se evalua el texto crudo para distinguir 'pendiente' (estado legitimo) de
    #     la frase 'pendiente de informacion'.
    $placeholderPatterns = @(
        '\btbd\b',
        '\btbd\-\w+',
        '\btodo\b(?![a-z\s])',
        '\bxxx+\b',
        '\blorem\b',
        'pendiente\s+de\s+informacion',
        'por\s+definir',
        'por\s+completar',
        'completar\s+aqui',
        'por\s+rellenar',
        'a\s+rellenar'
    )
    foreach ($lineNum in 0..($rawBacklogLines.Count - 1)) {
        $normLine = ConvertTo-NormalizedText -Text $rawBacklogLines[$lineNum]
        if ([string]::IsNullOrWhiteSpace($normLine)) { continue }
        foreach ($pattern in $placeholderPatterns) {
            if ($normLine -match $pattern) {
                $violations += New-Violation -File $backlogDisplay -Line ($lineNum + 1) `
                    -Message "placeholder detectado: patron '/$pattern/' en la linea"
                break
            }
        }
    }

    # ------------------------------------------- (c) divergencia critica
    # Mapa de estados del backlog: columna de estado en posicion 6 (ID=1, Estado=6).
    $backlogMap = Get-TaskStateMap -Path $BacklogPath -IdColumn 1 -StateColumn 6

    if (Test-Path -LiteralPath $SpecsDir -PathType Container) {
        $dirs = @(Get-ChildItem -LiteralPath $SpecsDir -Directory | Where-Object { $_.Name -ne 'archived' })
        foreach ($dir in $dirs) {
            $tasksPath = Join-Path $dir.FullName 'tasks.md'
            if (-not (Test-Path -LiteralPath $tasksPath -PathType Leaf)) { continue }
            # Spec 036 usa Estado en columna 8 (con columna Fase); el resto en 6.
            $stateCol = if ($dir.Name -like '036*') { 8 } else { 6 }
            $tasksMap = Get-TaskStateMap -Path $tasksPath -IdColumn 1 -StateColumn $stateCol
            foreach ($key in $tasksMap.Keys) {
                $task = $tasksMap[$key]
                $taskState = $task.StateNorm
                # Solo interesa la direccion critica: tasks.md = Cerrado.
                if ($taskState -notmatch 'cerrad') { continue }
                if (-not $backlogMap.ContainsKey($key)) {
                    $violations += New-Violation -File $dir.Name -Message "tarea '$($task.Id)' Cerrado en tasks.md pero ausente en pendientes-implementacion.md"
                    continue
                }
                $back = $backlogMap[$key]
                $backState = $back.StateNorm
                # Pendiente = estado Pendiente explicito o checklist '[ ]' sin marcar.
                $isPending = ($backState -match 'pendiente') -or ($backState -match '\[ \]')
                if ($isPending) {
                    $violations += New-Violation -File ($backlogDisplay + ":$($back.Line)") `
                        -Message "divergencia critica: '$($task.Id)' esta Cerrado en $($dir.Name)/tasks.md pero Pendiente/$($back.State) en el backlog"
                }
            }
        }
    }

    $okMessage = "pendientes-implementacion.md existente, sin placeholders y sin divergencias criticas con specs/*/tasks.md"
    return New-CheckOutcome -Id $id -Name $name -Rule $rule -OkMessage $okMessage `
        -ViolationSummary "$($violations.Count) hallazgo(s) en el gate del backlog" -Violations $violations
}

# =============================================================================
# 6. Ejecucion de los chequeos
# =============================================================================

$canonicalTiers = Get-CanonicalTiers -AgentsMdPath $script:AgentsMdPath
$opencodeSkillIndex = Get-SkillIndex -SkillsRoot $script:SkillsOpencodeDir
$githubSkillIndex = Get-SkillIndex -SkillsRoot $script:SkillsGithubDir

$checks = @()
$checks += Test-AgentParity -GithubFiles $githubAgentFiles -OpencodeFiles $opencodeAgentFiles
$checks += Test-Frontmatter -Documents $agentDocuments
$checks += Test-FrontmatterRequiredKeys -Documents $agentDocuments
$checks += Test-TierValue -Documents $agentDocuments -CanonicalTiers $canonicalTiers
$checks += Test-DeclaredSkillsExist -Documents $agentDocuments -OpencodeSkills $opencodeSkillIndex -GithubSkills $githubSkillIndex
$checks += Test-SkillsParity
$checks += Test-McpCoverage -Documents $agentDocuments
$checks += Test-AgentStructure -Documents $agentDocuments
$checks += Test-OrphanSkills -Documents $agentDocuments
$checks += Test-DefaultAgentBoot
$checks += Test-BacklogCoherence -SpecsDir $script:SpecsDir -IndexPath $script:BacklogIndexPath
$checks += Test-BacklogGate -BacklogPath $script:BacklogFilePath -SpecsDir $script:SpecsDir

$failChecks = @($checks | Where-Object { $_.Severity -eq 'FAIL' })
$warnChecks = @($checks | Where-Object { $_.Severity -eq 'WARN' })
$okChecks = @($checks | Where-Object { $_.Severity -eq 'OK' })
$failViolations = ($failChecks | ForEach-Object { @($_.Violations).Count } | Measure-Object -Sum).Sum
$warnViolations = ($warnChecks | ForEach-Object { @($_.Violations).Count } | Measure-Object -Sum).Sum
if ($null -eq $failViolations) { $failViolations = 0 }
if ($null -eq $warnViolations) { $warnViolations = 0 }
$exitCode = if ($failChecks.Count -gt 0) { 1 } else { 0 }

# =============================================================================
# 7. Salida
# =============================================================================

# La consola de Windows no siempre esta en UTF-8; sin esto las tildes y comillas
# del texto citado de AGENTS.md se muestran corruptas. Se fuerza UTF-8 en stdout
# para que el reporte (y el JSON) sea determinista y coincida con el encoding de
# AGENTS.md, que es UTF-8.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

if ($Json) {
    $payload = [pscustomobject]@{
        tool        = 'validate-agents-skills'
        version     = '1.0.0'
        readOnly    = $true
        rootPath    = $script:RootPath
        generatedAt = (Get-Date).ToString('o')
        checks      = @($checks)
        summary     = [pscustomobject]@{
            checks           = $checks.Count
            ok               = $okChecks.Count
            warn             = $warnChecks.Count
            fail             = $failChecks.Count
            failViolations   = [int]$failViolations
            warnViolations   = [int]$warnViolations
            exitCode         = $exitCode
        }
    }
    $payload | ConvertTo-Json -Depth 12
}
else {
    if (-not $Quiet) {
        Write-Host ''
        Write-Host '======================================================================' -ForegroundColor Cyan
        Write-Host ' Validador de agentes y skills - Agents_IA_TECH' -ForegroundColor Cyan
        Write-Host '======================================================================' -ForegroundColor Cyan
        Write-Host " Raiz: $($script:RootPath)"
        Write-Host ' Modo: solo lectura (no escribe archivos)'
        Write-Host ''

        foreach ($check in $checks) {
            $color = switch ($check.Severity) {
                'OK' { 'Green' }
                'WARN' { 'Yellow' }
                default { 'Red' }
            }
            Write-Host ("[{0}] {1} - {2}: {3}" -f $check.Severity, $check.Id, $check.Name, $check.Message) -ForegroundColor $color
            if (-not [string]::IsNullOrWhiteSpace($check.Rule)) {
                Write-Host ("        Regla: {0}" -f $check.Rule) -ForegroundColor DarkGray
            }
            foreach ($violation in @($check.Violations)) {
                $location = if ([string]::IsNullOrWhiteSpace($violation.File)) { '(global)' } else { $violation.File }
                if ($violation.Line -gt 0) { $location = "$location`:$($violation.Line)" }
                Write-Host ("        - {0} -> {1}" -f $location, $violation.Message) -ForegroundColor DarkGray
            }
            Write-Host ''
        }
    }

    Write-Host '----------------------------------------------------------------------' -ForegroundColor Cyan
    Write-Host (" Resumen: {0} chequeos | OK: {1} | WARN: {2} | FAIL: {3}" -f $checks.Count, $okChecks.Count, $warnChecks.Count, $failChecks.Count) -ForegroundColor Cyan
    Write-Host (" Hallazgos: FAIL={0} | WARN={1}" -f $failViolations, $warnViolations) -ForegroundColor Cyan
    Write-Host (" Exit code: {0}" -f $exitCode) -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Red' })
    Write-Host '----------------------------------------------------------------------' -ForegroundColor Cyan
}

# El exit code solo se materializa cuando el script corre como proceso hijo
# (pwsh -File ...). Al hacer dot-source (pruebas unitarias) NO se llama exit,
# para no terminar el proceso del runner.
if ($MyInvocation.InvocationName -ne '.') {
    exit $exitCode
}
