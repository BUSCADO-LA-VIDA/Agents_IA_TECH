# YamlHelper.psm1
function Read-Yaml { param([string]$Path) Write-Info 'Read-Yaml' }
function Write-Yaml { param([string]$Path,[object]$Data) Write-Info 'Write-Yaml' }
Export-ModuleMember -Function Read-Yaml, Write-Yaml
