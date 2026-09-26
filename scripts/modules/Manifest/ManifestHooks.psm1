# ManifestHooks.psm1
function Invoke-PostUpdateHooks { Write-Info 'Invoke-PostUpdateHooks' }
Export-ModuleMember -Function Invoke-PostUpdateHooks

# Hooks implementados
function Invoke-PostUpdateHooks { param([string]$ToolName) Write-Info 'Hooks ejecutados' }
