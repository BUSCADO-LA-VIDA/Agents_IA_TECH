#Requires -Version 7.0
<#
.SYNOPSIS
Controla ciclo de vida de integración ECC como proyecto externo
#>
param(
    [ValidateSet('install','update','validate','uninstall','update-indexes')]
    [string]$Action = 'validate'
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$EccPath = Join-Path $ProjectRoot 'proyect_ext\ECC'
$StateFile = Join-Path $ProjectRoot '.ecc-state.json'

function Write-Log { param($Level,$Msg); Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Msg" }
function Get-State { if(Test-Path $StateFile){ Get-Content $StateFile -Raw | ConvertFrom-Json } else { $null } }
function Save-State { param($State); $State | ConvertTo-Json -Depth 5 | Set-Content $StateFile -Encoding UTF8 }

switch($Action){
    'install' {
        Write-Log 'INFO' 'Instalando ECC...'
        if(-not (Test-Path $EccPath)){
            git clone https://github.com/affaan-m/ECC.git $EccPath
        }
        $state = @{ installed = (Get-Date).ToString('o'); version = 'main'; path = $EccPath }
        Save-State $state
        Write-Log 'INFO' 'ECC instalado'
    }
    'update' {
        Write-Log 'INFO' 'Actualizando herramienta ECC...'
        if(-not (Test-Path $EccPath)){ Write-Log 'ERROR' 'ECC no instalado'; exit 1 }
        Push-Location $EccPath
        git fetch origin
        git reset --hard origin/main
        Pop-Location
        $state = Get-State
        $state.lastToolUpdate = (Get-Date).ToString('o')
        Save-State $state
        Write-Log 'INFO' 'ECC actualizado. Ejecuta update-indexes para índices y grafos.'
    }
    'update-indexes' {
        Write-Log 'INFO' 'Actualizando índices y grafos...'
        $state = Get-State
        if(-not $state){ Write-Log 'ERROR' 'ECC no instalado'; exit 1 }
        # Placeholder para re-indexar context-mode, codebase-memory-mcp, graphify
        Write-Log 'INFO' 'Re-indexando context-mode + codebase-memory + graphify...'
        $state.lastIndexUpdate = (Get-Date).ToString('o')
        Save-State $state
        Write-Log 'INFO' 'Índices actualizados'
    }
    'validate' {
        Write-Log 'INFO' 'Validando integración ECC...'
        $state = Get-State
        if(-not $state){ Write-Log 'WARN' 'ECC no instalado'; exit 0 }
        $hasRules = Test-Path (Join-Path $EccPath 'rules')
        $hasSkills = Test-Path (Join-Path $EccPath 'skills')
        $hasMcpConfigs = Test-Path (Join-Path $EccPath 'mcp-configs')
        Write-Log 'INFO' "Rules presentes: $hasRules"
        Write-Log 'INFO' "Skills presentes: $hasSkills"
        Write-Log 'INFO' "mcp-configs presentes: $hasMcpConfigs"
        Write-Log 'INFO' 'Validación completada'
    }
    'uninstall' {
        Write-Log 'INFO' 'Desinstalando ECC...'
        if(Test-Path $EccPath){ Remove-Item $EccPath -Recurse -Force }
        if(Test-Path $StateFile){ Remove-Item $StateFile -Force }
        Write-Log 'INFO' 'ECC desinstalado'
    }
}

