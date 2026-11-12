#Requires -Version 7.0
<#
.SYNOPSIS
    Prueba la politica de hooks de context-mode (Spec 045).
.DESCRIPTION
    Ejecuta el generador y el validador REALES sobre directorios temporales y
    valida su SALIDA, nunca el archivo del proyecto.

    Casos:
      P4  bootstrap en proyecto vacio -> registro sin PreToolUse
      P5  registro con PreToolUse (restaurado del .bak) -> se retira al correr el bootstrap
      P6  validar-mcps.ps1 no falla por PreToolUse ausente
      P7  validar-mcps.ps1 falla si PreToolUse reaparece
      P8  el registro del repo aplica la misma politica que la salida generada

    Nota sobre -Force: usa el mismo bloque de emision que la creacion (P4);
    por eso no se ejecuta un tercer bootstrap que solo repetiria P4.

    Pester 6 aisla el scope: toda funcion auxiliar se declara DENTRO de BeforeAll.
    Una funcion declarada en el nivel de archivo no se resuelve desde BeforeAll.
#>

Describe 'Hooks de context-mode (spec 045)' {

    BeforeAll {
        $script:kitRoot = Split-Path $PSScriptRoot -Parent
        $script:backupPath = Join-Path $script:kitRoot '.github/hooks/context-mode.json.bak-20261109'
        $script:repoHooksPath = Join-Path $script:kitRoot '.github/hooks/context-mode.json'

        function New-TempProject {
            param([string]$Prefix, [string]$KitRoot)
            $dir = Join-Path ([IO.Path]::GetTempPath()) ($Prefix + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6))
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Copy-Item (Join-Path $KitRoot 'scripts') -Destination (Join-Path $dir 'scripts') -Recurse -Force

            # Test-IsMasterCheckout se salta el sync transversal (que sobrescribiria
            # scripts/validar-mcps.ps1 desde master). Declarar el temporal como
            # checkout maestro reproduce la condicion: origin = repo maestro.
            git -C $dir init --quiet 2>&1 | Out-Null
            git -C $dir remote add origin "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH" 2>&1 | Out-Null
            return $dir
        }

        function Get-HookKeys {
            param([string]$Path)
            if (-not (Test-Path -LiteralPath $Path)) { return @() }
            $doc = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
            if ($null -eq $doc.hooks) { return @() }
            return @($doc.hooks.PSObject.Properties.Name)
        }

        # Escenario 1: proyecto vacio -> el generador crea el registro.
        $script:tmpEmpty = New-TempProject -Prefix 'hooks045-empty' -KitRoot $script:kitRoot
        & pwsh -NoProfile -File (Join-Path $script:tmpEmpty 'scripts/plataformador-bootstrap.ps1') 2>&1 | Out-Null
        $script:exitEmpty = $LASTEXITCODE
        $script:hooksEmpty = Join-Path $script:tmpEmpty '.github/hooks/context-mode.json'
        $script:keysEmpty = Get-HookKeys -Path $script:hooksEmpty

        # Escenario 2: registro con PreToolUse sembrado desde el respaldo.
        $script:tmpSeed = New-TempProject -Prefix 'hooks045-seed' -KitRoot $script:kitRoot
        $script:seedDir = Join-Path $script:tmpSeed '.github/hooks'
        New-Item -ItemType Directory -Path $script:seedDir -Force | Out-Null
        Copy-Item -LiteralPath $script:backupPath -Destination (Join-Path $script:seedDir 'context-mode.json') -Force
        $script:hooksSeed = Join-Path $script:seedDir 'context-mode.json'

        $script:keysSeedBefore = Get-HookKeys -Path $script:hooksSeed
        $script:outSeedBefore = & pwsh -NoProfile -File (Join-Path $script:tmpSeed 'scripts/validar-mcps.ps1') 2>&1 | Out-String

        & pwsh -NoProfile -File (Join-Path $script:tmpSeed 'scripts/plataformador-bootstrap.ps1') 2>&1 | Out-Null
        $script:exitSeed = $LASTEXITCODE
        $script:keysSeedAfter = Get-HookKeys -Path $script:hooksSeed
        $script:outSeedAfter = & pwsh -NoProfile -File (Join-Path $script:tmpSeed 'scripts/validar-mcps.ps1') 2>&1 | Out-String

        $script:repoKeys = Get-HookKeys -Path $script:repoHooksPath
    }

    AfterAll {
        foreach ($dir in @($script:tmpEmpty, $script:tmpSeed)) {
            if ($dir -and (Test-Path -LiteralPath $dir)) {
                Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'P4 - El generador emite la politica vigente en un proyecto vacio' {
        It 'termina sin error' {
            $script:exitEmpty | Should -Be 0
        }

        It 'crea el registro sin PreToolUse' {
            $script:keysEmpty | Should -Not -Contain 'PreToolUse'
        }

        It 'conserva PostToolUse y SessionStart' {
            $script:keysEmpty | Should -Contain 'PostToolUse'
            $script:keysEmpty | Should -Contain 'SessionStart'
        }

        It 'apunta a las etapas de VS Code Copilot' {
            $json = Get-Content -LiteralPath $script:hooksEmpty -Raw | ConvertFrom-Json
            $json.hooks.PostToolUse[0].command | Should -Be 'context-mode hook vscode-copilot posttooluse'
            $json.hooks.SessionStart[0].command | Should -Be 'context-mode hook vscode-copilot sessionstart'
        }
    }

    Context 'P5 - El generador normaliza un registro que reintroduce PreToolUse' {
        It 'el sembrado si declaraba PreToolUse' {
            $script:keysSeedBefore | Should -Contain 'PreToolUse'
        }

        It 'termina sin error' {
            $script:exitSeed | Should -Be 0
        }

        It 'retira PreToolUse y conserva las otras etapas' {
            $script:keysSeedAfter | Should -Not -Contain 'PreToolUse'
            $script:keysSeedAfter | Should -Contain 'PostToolUse'
            $script:keysSeedAfter | Should -Contain 'SessionStart'
        }
    }

    Context 'P7 - El validador falla cuando PreToolUse reaparece' {
        It 'reporta FAIL nombrando PreToolUse' {
            $script:outSeedBefore | Should -Match '\[FAIL\].*PreToolUse'
        }

        It 'nombra la spec que define la decision' {
            $script:outSeedBefore | Should -Match '045-retirar-pretooluse-hook-context-mode'
        }
    }

    Context 'P6 - El validador no falla por PreToolUse ausente' {
        It 'confirma la retirada' {
            $script:outSeedAfter | Should -Match '\[OK\].*PreToolUse.*retirado'
        }

        It 'no emite ningun FAIL sobre PreToolUse' {
            $script:outSeedAfter | Should -Not -Match '\[FAIL\].*PreToolUse'
        }

        It 'sigue exigiendo PostToolUse y SessionStart' {
            $script:outSeedAfter | Should -Match "\[OK\].*Hook 'PostToolUse'"
            $script:outSeedAfter | Should -Match "\[OK\].*Hook 'SessionStart'"
        }
    }

    Context 'P8 - El registro del repo coincide con la politica generada' {
        It 'no declara PreToolUse' {
            $script:repoKeys | Should -Not -Contain 'PreToolUse'
        }

        It 'declara las mismas etapas que la salida generada' {
            # Comparacion por conjuntos: el orden de las claves no es parte del contrato.
            (($script:repoKeys | Sort-Object) -join ',') | Should -Be ((@($script:keysEmpty) | Sort-Object) -join ',')
        }

        It 'usa los mismos comandos que la salida generada' {
            $repo = Get-Content -LiteralPath $script:repoHooksPath -Raw | ConvertFrom-Json
            $gen = Get-Content -LiteralPath $script:hooksEmpty -Raw | ConvertFrom-Json
            $repo.hooks.PostToolUse[0].command | Should -Be $gen.hooks.PostToolUse[0].command
            $repo.hooks.SessionStart[0].command | Should -Be $gen.hooks.SessionStart[0].command
        }

        It 'no conserva ningun comando de la etapa retirada' {
            $repo = Get-Content -LiteralPath $script:repoHooksPath -Raw
            $repo | Should -Not -Match 'pretooluse'
        }
    }
}