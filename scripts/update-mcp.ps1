#Requires -Version 7.0
param([switch]$Force,[switch]$DryRun,[string[]]$Tools)
$ErrorActionPreference="Stop"
$ScriptRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot=Split-Path -Parent $ScriptRoot
$StateFile=Join-Path $ProjectRoot ".bootstrap-state.json"
$EnvMcpFile=Join-Path $ProjectRoot ".env.mcp"
function Write-Log{param($Level,$Message); Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] [$Level] $Message"}
function Get-State{ if(Test-Path $StateFile){ try{ Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ return $null } } return $null }
function Save-State{ param($State); Set-Content -Path $StateFile -Value ($State | ConvertTo-Json -Depth 5) -Encoding UTF8 }
function Read-EnvMcp{ $m=@{}; if(Test-Path $EnvMcpFile){ Get-Content $EnvMcpFile | ForEach-Object{ if($_ -match "^\s*([^#=]+?)\s*=\s*(.+?)\s*$"){ $m[$matches[1].Trim()]=$matches[2].Trim() } } }; return $m }
Write-Log "INFO" "Iniciando update-mcp.ps1"
$state=Get-State
if(-not $state){ $state=[PSCustomObject]@{ lastUpdate=(Get-Date).ToString("o"); tools=@{} } }
$now=Get-Date
try{ $last=[DateTime]::Parse($state.lastUpdate) }catch{ $last=$now.AddDays(-2) }
$needsUpdate=$Force -or ($now-$last).TotalHours -ge 24
if(-not $needsUpdate -and -not $DryRun){ Write-Log "INFO" "MCPs actualizados recientemente"; Write-Host "MCP_NAME | ESTADO | VERSION | RUTA | NOTA"; Write-Host "ALL | UP_TO_DATE | - | - | Ultima $($last.ToString("yyyy-MM-dd HH:mm"))"; exit 0 }
$envMcp=Read-EnvMcp
$report=@("MCP_NAME | ESTADO | VERSION | RUTA | NOTA")
$target=if($Tools -and $Tools.Count -gt 0){ $Tools }else{ @("CONTEXT_MODE_CMD","CODEBASE_MEMORY_CMD","MARKITDOWN_CMD","PYTHON_CMD") }
foreach($key in $target){
    $path=$envMcp[$key]
    if(-not $path){ $report+= "$key | SKIPPED | - | - | No definido"; continue }
    if(-not (Test-Path $path)){ $report+= "$key | ERROR | - | $path | Ruta no existe"; continue }
    $estado="UP_TO_DATE"; $nota="Verificado"
    if($Force){ $estado="UPDATED"; $nota="Forzado" }
    $report+= "$key | $estado | - | $path | $nota"
}
if(-not $DryRun){ $state.lastUpdate=$now.ToString("o"); Save-State $state; Write-Log "INFO" "Estado actualizado." }else{ Write-Log "INFO" "DryRun activo." }
$report | ForEach-Object { Write-Host $_ }
Write-Log "INFO" "update-mcp.ps1 completado."

