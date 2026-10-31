#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# validate-agents-skills.Tests.ps1
# =============================================================================
# Tests Pester 6 del validador de solo lectura scripts/validate-agents-skills.ps1.
#
# Estrategia: el validador se ejecuta SIEMPRE como proceso hijo (pwsh -File ...)
# contra fixtures creados en $env:TEMP. Esto permite verificar dos cosas que un
# dot-source no puede: el exit code real del proceso y que el validador no
# escribe nada en la raiz validada. Los fixtures se borran en el AfterAll de
# archivo, por lo que no queda basura en el repo.
#
# NOTA DE SCOPE (Pester 6): el cuerpo de un .Tests.ps1 corre en un script scope
# aislado y los Describe/It corren en scopes hijos. Por eso TODOS los helpers
# viven en un unico BeforeAll de archivo; los helpers declarados en el nivel
# superior del archivo no serian visibles dentro de los Describe.
# =============================================================================

BeforeAll {
    $script:validatorPath = Join-Path $PSScriptRoot '..\scripts\validate-agents-skills.ps1'
    $script:fixtureRoots = [System.Collections.Generic.List[string]]::new()

    # -------------------------------------------------------------------------
    # Helpers de filesystem (fixtures fuera del repo)
    # -------------------------------------------------------------------------
    function New-FixtureRoot {
        param([string]$Name = 'fixture')

        $root = Join-Path $env:TEMP ("validate_agents_skills_{0}_{1}" -f $Name, (Get-Random))
        if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $script:fixtureRoots.Add($root)
        return $root
    }

    function Set-FixtureFile {
        <# Crea (o reemplaza) un archivo del fixture. No emite salida a proposito:
           si emitiera la ruta, contaminaria el valor de retorno de los helpers
           que construyen fixtures y -RootPath recibiria un array. #>
        param(
            [Parameter(Mandatory)][string]$RootPath,
            [Parameter(Mandatory)][string]$RelativePath,
            [string]$Content = ''
        )
        $full = Join-Path $RootPath ($RelativePath -replace '/', '\')
        $directory = Split-Path -Parent $full
        if (-not (Test-Path -LiteralPath $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        Set-Content -LiteralPath $full -Value $Content -Encoding utf8 -NoNewline
    }

    function New-FixtureSkill {
        param(
            [Parameter(Mandatory)][string]$RootPath,
            [ValidateSet('github', 'opencode')][string]$Harness = 'opencode',
            [string]$Category = 'api',
            [Parameter(Mandatory)][string]$SkillName
        )
        $base = if ($Harness -eq 'github') { '.github/skills' } else { '.opencode/skills' }
        $content = "# $SkillName`n`nSkill de fixture para pruebas del validador.`n"
        Set-FixtureFile -RootPath $RootPath -RelativePath "$base/$Category/$SkillName/SKILL.md" -Content $content
    }

    function Get-TreeSnapshot {
        <# Huella (ruta + hash) de todos los archivos de un arbol, para probar solo-lectura. #>
        param([Parameter(Mandatory)][string]$RootPath)
        $entries = @(
            Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $relative = ([System.IO.Path]::GetRelativePath($RootPath, $_.FullName) -replace '\\', '/')
                $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                "$relative|$hash"
            } | Sort-Object
        )
        return ($entries -join "`n")
    }

    # -------------------------------------------------------------------------
    # Contenido de agentes de fixture
    # -------------------------------------------------------------------------
    function New-AgentContent {
        <#
            Agente de fixture. Con -OmitTier / -OmitDescription / -Tier se generan
            las variantes que usan los tests de VAL-03 y VAL-04.
        #>
        param(
            [string]$Tier = 'Documental',
            [string]$Description = 'Agente de fixture para pruebas del validador',
            [string[]]$Skills = @('api-design'),
            [switch]$OmitTier,
            [switch]$OmitDescription,
            [switch]$WithMentions
        )
        $frontmatter = @('---')
        if (-not $OmitTier) { $frontmatter += "tier: $Tier" }
        if (-not $OmitDescription) { $frontmatter += "description: `"$Description`"" }
        $frontmatter += 'tools: [read, edit]'
        if ($Skills.Count -gt 0) {
            $frontmatter += 'skills:'
            foreach ($skill in $Skills) { $frontmatter += "  - $skill" }
        }
        $frontmatter += '---'

        $body = @(
            '',
            '# Agente de fixture',
            '',
            'Introduccion de prueba: este agente existe solo para validar el validador.',
            '',
            '## Skills',
            ''
        )
        foreach ($skill in $Skills) { $body += "- $skill" }
        $body += @(
            '',
            '## Enfoque',
            '',
            'Trabaja en pasos pequenos y verificables.',
            '',
            '## Uso de MCPs (obligatorio)',
            '',
            '- context-mode (ctx_search) para contexto minimo.'
        )
        if ($WithMentions) { $body += '- playwright (navegador) para QA.' }
        $body += @(
            '',
            '## Idioma',
            '',
            'Espanol latino neutro, sin voseo.',
            '',
            '## Constraints',
            '',
            '- No escribe fuera de las rutas permitidas.',
            ''
        )
        return (($frontmatter + $body) -join "`n")
    }

    function New-AgentWithoutFrontmatter {
        return @(
            '# Agente sin frontmatter',
            '',
            'Este archivo no abre con --- por lo que VAL-02 debe fallar.',
            ''
        ) -join "`n"
    }

    # -------------------------------------------------------------------------
    # Fixtures completos
    # -------------------------------------------------------------------------
    function Get-FixtureAgentsMd {
        return @(
            '# AGENTS.md (fixture)',
            '',
            '### Reglas transversales de los agentes (gobernanza)',
            '',
            '- **Regla 1b - cobertura obligatoria**: todo MCP registrado en `opencode.json` debe estar declarado en la seccion "Uso de MCPs" de al menos un agente.',
            '- Estructura estandar de agente (Regla 2): frontmatter, introduccion, skills, enfoque, MCPs, idioma, constraints.',
            '',
            '## Core facts',
            '',
            '  | Tier | Agents | Can write code? |',
            '  |------|--------|:---:|',
            '  | Documental | `arquitecto` | No |',
            '  | Documental extendido | `Agent-SSD` | No |',
            '  | Implementador | `developer` | Si |',
            '  | Tooling | `gitflow` | Si |',
            '  | Plataforma | `plataformador` | Si |',
            ''
        ) -join "`n"
    }

    function Get-FixtureMcpJson {
        param([string[]]$ExtraServers = @())
        $servers = [ordered]@{ 'context-mode' = @{ type = 'local'; command = @('npx', 'context-mode') } }
        foreach ($name in $ExtraServers) { $servers[$name] = @{ type = 'local'; command = @('npx', $name) } }
        return ([ordered]@{ mcp = [ordered]@{ servers = $servers } } | ConvertTo-Json -Depth 8)
    }

    function New-ValidFixture {
        <# Repo minimo coherente: 1 agente con par, 1 skill con par, 1 MCP cubierto. #>
        $root = New-FixtureRoot -Name 'valido'
        Set-FixtureFile -RootPath $root -RelativePath 'AGENTS.md' -Content (Get-FixtureAgentsMd)
        Set-FixtureFile -RootPath $root -RelativePath 'opencode.json' -Content (Get-FixtureMcpJson)
        Set-FixtureFile -RootPath $root -RelativePath '.github/agents/arquitecto.agent.md' -Content (New-AgentContent)
        Set-FixtureFile -RootPath $root -RelativePath '.opencode/agents/arquitecto.md' -Content (New-AgentContent)
        New-FixtureSkill -RootPath $root -Harness 'github' -SkillName 'api-design' | Out-Null
        New-FixtureSkill -RootPath $root -Harness 'opencode' -SkillName 'api-design' | Out-Null
        return $root
    }

    function New-BrokenFixture {
        <#
            Fixture con las cuatro violaciones que exige el contrato de tests:
              - 'huerfano'      -> existe solo en .github  (VAL-01)
              - 'sin-tier'      -> frontmatter sin tier    (VAL-03)
              - 'skill-fantasma'-> declara skill inexistente (VAL-05)
              - MCP 'playwright' registrado y no declarado (VAL-07)
        #>
        $root = New-FixtureRoot -Name 'roto'
        Set-FixtureFile -RootPath $root -RelativePath 'AGENTS.md' -Content (Get-FixtureAgentsMd)
        Set-FixtureFile -RootPath $root -RelativePath 'opencode.json' -Content (Get-FixtureMcpJson -ExtraServers @('playwright'))

        # Agente sano (con par y skill valida)
        Set-FixtureFile -RootPath $root -RelativePath '.github/agents/arquitecto.agent.md' -Content (New-AgentContent)
        Set-FixtureFile -RootPath $root -RelativePath '.opencode/agents/arquitecto.md' -Content (New-AgentContent)

        # Agente sin par en .opencode
        Set-FixtureFile -RootPath $root -RelativePath '.github/agents/huerfano.agent.md' -Content (New-AgentContent)

        # Agente sin tier en ambos arneses
        Set-FixtureFile -RootPath $root -RelativePath '.github/agents/sin-tier.agent.md' -Content (New-AgentContent -OmitTier)
        Set-FixtureFile -RootPath $root -RelativePath '.opencode/agents/sin-tier.md' -Content (New-AgentContent -OmitTier)

        # Agente que declara una skill inexistente en ambos arneses
        Set-FixtureFile -RootPath $root -RelativePath '.github/agents/skill-fantasma.agent.md' -Content (New-AgentContent -Skills @('skill-que-no-existe'))
        Set-FixtureFile -RootPath $root -RelativePath '.opencode/agents/skill-fantasma.md' -Content (New-AgentContent -Skills @('skill-que-no-existe'))

        New-FixtureSkill -RootPath $root -Harness 'github' -SkillName 'api-design' | Out-Null
        New-FixtureSkill -RootPath $root -Harness 'opencode' -SkillName 'api-design' | Out-Null
        return $root
    }

    # -------------------------------------------------------------------------
    # Invocacion del validador como proceso hijo
    # -------------------------------------------------------------------------
    function Invoke-Validator {
        param(
            [Parameter(Mandatory)][string]$RootPath,
            [string[]]$Arguments = @('-Json')
        )
        $stdout = & pwsh -NoProfile -File $script:validatorPath -RootPath $RootPath @Arguments 2>$null | Out-String
        $exitCode = $LASTEXITCODE
        $parsed = $null
        if ($Arguments -contains '-Json') {
            try { $parsed = ($stdout.Trim() | ConvertFrom-Json) } catch { $parsed = $null }
        }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Stdout   = $stdout
            Result   = $parsed
        }
    }

    function Get-Check {
        param($Result, [string]$Id)
        if ($null -eq $Result) { return $null }
        return ($Result.checks | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
    }
}

AfterAll {
    foreach ($root in $script:fixtureRoots) {
        if (Test-Path -LiteralPath $root) {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $script:fixtureRoots.Clear()
}

# =============================================================================
# 1. Contrato del script: compila y expone los parametros pedidos
# =============================================================================

Describe "validate-agents-skills.ps1 - contrato del script" {

    It "Compila sin errores de parseo (Parser::ParseFile)" {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($script:validatorPath, [ref]$tokens, [ref]$errors)
        $errors | Should -HaveCount 0
    }

    It "Declara -RootPath, -Json y -Quiet" {
        $parameters = (Get-Command $script:validatorPath).Parameters
        $parameters.ContainsKey('RootPath') | Should -Be $true
        $parameters.ContainsKey('Json') | Should -Be $true
        $parameters.ContainsKey('Quiet') | Should -Be $true
        $parameters['Json'].ParameterType.Name | Should -Be 'SwitchParameter'
        $parameters['Quiet'].ParameterType.Name | Should -Be 'SwitchParameter'
    }

    It "Este mismo archivo de tests compila sin errores de parseo" {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($PSCommandPath, [ref]$tokens, [ref]$errors)
        $errors | Should -HaveCount 0
    }

    It "No lanza excepcion y sale con 1 cuando la raiz no es un kit (sin agentes)" {
        $root = New-FixtureRoot -Name 'vacio'
        $run = Invoke-Validator -RootPath $root

        $run.Result | Should -Not -BeNullOrEmpty
        $run.ExitCode | Should -Be 1
        (Get-Check -Result $run.Result -Id 'VAL-01').Severity | Should -Be 'FAIL'
    }
}

# =============================================================================
# 2. Fixture valido: VAL-01..VAL-08 en [OK] y exit code 0
# =============================================================================

Describe "Fixture valido - todos los chequeos en OK" {

    It "Reporta [OK] VAL-01, VAL-02, VAL-03, VAL-04 y VAL-05" {
        $fixture = New-ValidFixture
        $run = Invoke-Validator -RootPath $fixture

        $run.Result | Should -Not -BeNullOrEmpty
        foreach ($id in @('VAL-01', 'VAL-02', 'VAL-03', 'VAL-04', 'VAL-05')) {
            $check = Get-Check -Result $run.Result -Id $id
            $check | Should -Not -BeNullOrEmpty
            $check.Severity | Should -Be 'OK'
            @($check.Violations) | Should -HaveCount 0
        }
    }

    It "Reporta [OK] VAL-06, VAL-07 y VAL-08 cuando agente, skill y MCP estan completos" {
        $fixture = New-ValidFixture
        $run = Invoke-Validator -RootPath $fixture

        foreach ($id in @('VAL-06', 'VAL-07', 'VAL-08')) {
            $check = Get-Check -Result $run.Result -Id $id
            $check | Should -Not -BeNullOrEmpty
            $check.Severity | Should -Be 'OK'
        }
        (Get-Check -Result $run.Result -Id 'VAL-07').Message | Should -Match 'citados por al menos un agente'
    }

    It "Retorna exit code 0 cuando no hay ningun FAIL" {
        $fixture = New-ValidFixture
        $run = Invoke-Validator -RootPath $fixture

        $run.ExitCode | Should -Be 0
        $run.Result.summary.fail | Should -Be 0
        $run.Result.summary.exitCode | Should -Be 0
    }

    It "Es de solo lectura: no crea ni modifica archivos en la raiz validada" {
        $fixture = New-ValidFixture
        $before = Get-TreeSnapshot -RootPath $fixture

        $null = Invoke-Validator -RootPath $fixture
        $null = Invoke-Validator -RootPath $fixture -Arguments @('-Quiet')

        $after = Get-TreeSnapshot -RootPath $fixture
        $after | Should -Be $before
    }

    It "Sin -Json imprime el reporte legible y con -Quiet imprime solo el resumen" {
        $fixture = New-ValidFixture

        $verbose = Invoke-Validator -RootPath $fixture -Arguments @()
        $verbose.Stdout | Should -Match '\[OK\] VAL-01'
        $verbose.Stdout | Should -Match 'Resumen:'

        $quiet = Invoke-Validator -RootPath $fixture -Arguments @('-Quiet')
        $quiet.Stdout | Should -Match 'Resumen:'
        $quiet.Stdout | Should -Not -Match '\[OK\] VAL-01'
    }
}

# =============================================================================
# 3. Fixture roto: cada violacion produce el FAIL con el ID correcto
# =============================================================================

Describe "Fixture roto - cada violacion reporta su ID" {

    It "VAL-01 [FAIL] cuando un agente no tiene par en el otro arnes" {
        $fixture = New-BrokenFixture
        $run = Invoke-Validator -RootPath $fixture

        $check = Get-Check -Result $run.Result -Id 'VAL-01'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 1
        $check.Violations[0].File | Should -Match 'huerfano\.agent\.md'
        $check.Violations[0].Message | Should -Match 'falta \.opencode/agents/huerfano\.md'
    }

    It "VAL-02 [FAIL] cuando el agente no abre con frontmatter" {
        $fixture = New-ValidFixture
        Set-FixtureFile -RootPath $fixture -RelativePath '.opencode/agents/sin-frontmatter.md' -Content (New-AgentWithoutFrontmatter)
        Set-FixtureFile -RootPath $fixture -RelativePath '.github/agents/sin-frontmatter.agent.md' -Content (New-AgentWithoutFrontmatter)

        $run = Invoke-Validator -RootPath $fixture
        $check = Get-Check -Result $run.Result -Id 'VAL-02'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 2
        $check.Violations[0].Message | Should -Match 'frontmatter ausente'
    }

    It "VAL-03 [FAIL] cuando el frontmatter no declara tier" {
        $fixture = New-BrokenFixture
        $run = Invoke-Validator -RootPath $fixture

        $check = Get-Check -Result $run.Result -Id 'VAL-03'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 2
        @($check.Violations | Where-Object { $_.File -match 'sin-tier' }) | Should -HaveCount 2
        ($check.Violations | Where-Object { $_.Message -match "tier" }).Count | Should -Be 2
    }

    It "VAL-04 [FAIL] cuando el tier no pertenece a la lista canonica" {
        $fixture = New-ValidFixture
        Set-FixtureFile -RootPath $fixture -RelativePath '.github/agents/tier-inventado.agent.md' -Content (New-AgentContent -Tier 'Inventado')
        Set-FixtureFile -RootPath $fixture -RelativePath '.opencode/agents/tier-inventado.md' -Content (New-AgentContent -Tier 'Inventado')

        $run = Invoke-Validator -RootPath $fixture
        $check = Get-Check -Result $run.Result -Id 'VAL-04'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 2
        $check.Violations[0].Message | Should -Match 'Inventado'
    }

    It "VAL-05 [FAIL] cuando la skill declarada no existe" {
        $fixture = New-BrokenFixture
        $run = Invoke-Validator -RootPath $fixture

        $check = Get-Check -Result $run.Result -Id 'VAL-05'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 2
        $check.Violations[0].Message | Should -Match 'skill-que-no-existe'
        $check.Violations[0].File | Should -Match 'skill-fantasma'
    }

    It "VAL-06 [FAIL] cuando un SKILL.md falta en uno de los arneses" {
        $fixture = New-ValidFixture
        New-FixtureSkill -RootPath $fixture -Harness 'opencode' -Category 'docker' -SkillName 'docker-patterns' | Out-Null

        $run = Invoke-Validator -RootPath $fixture
        $check = Get-Check -Result $run.Result -Id 'VAL-06'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 1
        $check.Violations[0].Message | Should -Match 'ausente en \.github/skills'
    }

    It "VAL-07 [FAIL] cuando un MCP de opencode.json no lo declara ningun agente" {
        $fixture = New-BrokenFixture
        $run = Invoke-Validator -RootPath $fixture

        $check = Get-Check -Result $run.Result -Id 'VAL-07'
        $check.Severity | Should -Be 'FAIL'
        @($check.Violations) | Should -HaveCount 1
        $check.Violations[0].Message | Should -Match 'playwright'
        $check.Rule | Should -Match 'Regla 1b'
    }

    It "VAL-08 [FAIL] cuando el agente no tiene las secciones de la Regla 2" {
        $fixture = New-ValidFixture
        $minimo = @('---', 'tier: Documental', 'description: "Agente sin secciones"', '---', '# Minimo', '', 'Solo un parrafo.', '') -join "`n"
        Set-FixtureFile -RootPath $fixture -RelativePath '.github/agents/minimo.agent.md' -Content $minimo
        Set-FixtureFile -RootPath $fixture -RelativePath '.opencode/agents/minimo.md' -Content $minimo

        $run = Invoke-Validator -RootPath $fixture
        $check = Get-Check -Result $run.Result -Id 'VAL-08'
        $check.Severity | Should -Be 'FAIL'
        # El fixture minimo existe en ambos arneses: 5 secciones faltantes por archivo.
        $messages = @($check.Violations | Where-Object { $_.File -match '\.opencode/agents/minimo\.md' } | ForEach-Object { $_.Message })
        $messages | Should -HaveCount 5
        ($messages -join ' ') | Should -Match 'skills'
        ($messages -join ' ') | Should -Match 'enfoque'
        ($messages -join ' ') | Should -Match 'MCPs'
        ($messages -join ' ') | Should -Match 'idioma'
        ($messages -join ' ') | Should -Match 'constraints'
        $check.Rule | Should -Match 'Regla 2'
    }

    It "Retorna exit code 1 cuando hay al menos un FAIL" {
        $fixture = New-BrokenFixture
        $run = Invoke-Validator -RootPath $fixture

        $run.ExitCode | Should -Be 1
        $run.Result.summary.fail | Should -BeGreaterThan 0
        $run.Result.summary.exitCode | Should -Be 1
    }
}

# =============================================================================
# 4. Skills huerfanas: AVISO que no altera el exit code
# =============================================================================

Describe "Skills huerfanas - aviso sin impacto en el exit code" {

    It "VAL-09 [WARN] cuando una skill no la declara ningun agente" {
        $fixture = New-ValidFixture
        New-FixtureSkill -RootPath $fixture -Harness 'github' -Category 'docker' -SkillName 'kubernetes-patterns' | Out-Null
        New-FixtureSkill -RootPath $fixture -Harness 'opencode' -Category 'docker' -SkillName 'kubernetes-patterns' | Out-Null

        $run = Invoke-Validator -RootPath $fixture
        $check = Get-Check -Result $run.Result -Id 'VAL-09'
        $check.Severity | Should -Be 'WARN'
        @($check.Violations) | Should -HaveCount 1
        $check.Violations[0].Message | Should -Match 'kubernetes-patterns'
    }

    It "Un WARN no cambia el exit code (0 si no hay FAIL)" {
        $fixture = New-ValidFixture
        New-FixtureSkill -RootPath $fixture -Harness 'github' -Category 'docker' -SkillName 'kubernetes-patterns' | Out-Null
        New-FixtureSkill -RootPath $fixture -Harness 'opencode' -Category 'docker' -SkillName 'kubernetes-patterns' | Out-Null

        $run = Invoke-Validator -RootPath $fixture
        $run.Result.summary.warn | Should -Be 1
        $run.Result.summary.fail | Should -Be 0
        $run.ExitCode | Should -Be 0
    }
}
