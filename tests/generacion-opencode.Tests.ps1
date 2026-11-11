#Requires -Version 7.0
<#
.SYNOPSIS
    Prueba de generacion de opencode.json (Spec 046).
.DESCRIPTION
    Ejecuta el generador real (scripts/plataformador-bootstrap.ps1) sobre un
    directorio temporal y valida LA SALIDA, no el archivo del proyecto.

    Regla de oro de la 046: los artefactos generados no se editan a mano; se
    ajusta el generador y se comprueba lo que produce.

    Casos cubiertos:
      T014  entrada context-mode rota -> se repara a server.mjs --agent opencode
      T016  graphify apunta al destino, no al kit
      T013  el JSON generado es valido y conserva default_agent
#>

Describe 'Generacion de opencode.json (spec 046)' {

    BeforeAll {
        $script:kitRoot = Split-Path $PSScriptRoot -Parent
        $script:bootstrap = Join-Path $script:kitRoot 'scripts/plataformador-bootstrap.ps1'
        $script:node = (Get-Command node -ErrorAction SilentlyContinue).Source

        $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ('gen-opencode-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $script:tmp -Force | Out-Null
        Copy-Item (Join-Path $script:kitRoot 'scripts') -Destination (Join-Path $script:tmp 'scripts') -Recurse -Force

        # Semilla: entrada context-mode apuntando a un layout que ya no existe.
        $bogus = Join-Path $script:tmp 'node_modules/context-mode/build/cli.js'
        New-Item -ItemType Directory -Path (Join-Path $script:tmp 'graphify-out') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:tmp 'graphify-out/graph.json') -Value '{}' -Encoding UTF8
        $seed = [ordered]@{
            '$schema'       = 'https://opencode.ai/config.json'
            default_agent   = 'pensador'
            mcp             = [ordered]@{
                servers = [ordered]@{
                    'context-mode' = [ordered]@{
                        type    = 'local'
                        command = @($script:node.Replace('\', '/'), ($bogus -replace '\\', '/'))
                    }
                    graphify       = [ordered]@{
                        type    = 'local'
                        command = @($script:node.Replace('\', '/'), '-m', 'graphify.serve', (($script:kitRoot + '/graphify-out/graph.json') -replace '\\', '/'))
                        enabled = $true
                    }
                }
            }
        }
        $seed | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $script:tmp 'opencode.json') -Encoding UTF8

        & pwsh -NoProfile -File (Join-Path $script:tmp 'scripts/plataformador-bootstrap.ps1') 2>&1 | Out-Null
        $script:exit = $LASTEXITCODE

        $script:generatedPath = Join-Path $script:tmp 'opencode.json'
        $script:generated = if (Test-Path $script:generatedPath) { Get-Content $script:generatedPath -Raw | ConvertFrom-Json } else { $null }
    }

    AfterAll {
        if ($script:tmp -and (Test-Path $script:tmp)) { Remove-Item -LiteralPath $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'El generador termina sin error' {
        if (-not (Test-Path $script:bootstrap)) { Set-ItResult -Skipped -Because 'no hay scripts/plataformador-bootstrap.ps1' }
        $script:exit | Should -Be 0
    }

    It 'El JSON generado es valido y conserva default_agent' {
        $script:generated | Should -Not -BeNullOrEmpty
        $script:generated.default_agent | Should -Be 'pensador'
    }

    It 'Repara context-mode al layout actual (server.mjs + --agent)' {
        $cmd = @($script:generated.mcp.servers.'context-mode'.command)
        $cmd.Count | Should -BeGreaterThan 0
        ($cmd -join ' ') | Should -Match 'context-mode[/\\]server\.mjs'
        ($cmd -join ' ') | Should -Match '--agent'
        ($cmd -join ' ') | Should -Not -Match 'build[/\\]cli\.js'
        $script:generated.mcp.servers.'context-mode'.enabled | Should -BeTrue
    }

    It 'Regenera graphify con la ruta del destino' {
        $cmd = @($script:generated.mcp.servers.graphify.command) -join ' '
        $cmd | Should -Match ([regex]::Escape(($script:tmp -replace '\\', '/')))
        $cmd | Should -Not -Match ([regex]::Escape(($script:kitRoot -replace '\\', '/')))
    }
}
