#Requires -Version 7.0
param(
    [string]$EnvPath = '$PSScriptRoot\..\.env.mcp',
    [string]$JsonPath = '$PSScriptRoot\..\proyect_ext\ECC\mcp-configs\mcp-servers.json'
)
$ErrorActionPreference = 'Stop'
$envContent = Get-Content $EnvPath -Raw
$servers = @{}
foreach($line in $envContent -split "`n"){
    if($line -match '^([^=]+)=(.*)$'){
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        $servers[$key] = $val
    }
}
$output = @{ mcpServers = $servers }
$output | ConvertTo-Json -Depth 5 | Set-Content $JsonPath -Encoding UTF8
Write-Host "Migración completada a $JsonPath"

