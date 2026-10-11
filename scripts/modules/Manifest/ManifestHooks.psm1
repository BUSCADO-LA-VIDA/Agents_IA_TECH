# ManifestHooks.psm1 — Hooks post-update por herramienta (014-manifest, T004).
#
# Tras actualizar una herramienta del manifest, sus hooks post-update ejecutan
# reindexación/verificación. Diseño:
# - Registro extensible: Register-PostUpdateHook [-ToolName] [-ScriptBlock].
#   Hooks por defecto: 'reindex' (re-indexa código+docs+grafo del proyecto).
# - Fail-open: cada hook corre en try/catch; si falla -> WARN + continúa con
#   el siguiente; el resultado global indica cuáles fallaron (exit del
#   llamador NO se ve afectado salvo que pida -FailClosed... no hay tal flag:
#   siempre fail-open por diseño del kit).
# - -DryRun: informa lo que ejecutaría sin ejecutar nada.
# - Herramienta sin hook: se registra 'skipped' (no es error).
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Warning $Message }

$script:HookRegistry = [ordered]@{}

function Register-PostUpdateHook {
    param(
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    $script:HookRegistry[$ToolName] = $Action
    Write-Info "Hook post-update registrado para '$ToolName'."
}

function Get-PostUpdateHooks {
    return @($script:HookRegistry.Keys)
}

function Invoke-DefaultReindexHook {
    param([string]$RootPath, [string]$ToolName, [switch]$DryRun)
    $steps = @(
        @{ Name = 'codebase-memory'; Check = 'codebase-memory-mcp'; Run = { param($rp) & codebase-memory-mcp cli index_repository --path $rp } },
        @{ Name = 'context-mode';    Check = 'context-mode';        Run = { param($rp) & context-mode index (Join-Path $rp 'Documentacion') } },
        @{ Name = 'graphify';        Check = 'graphify';            Run = { param($rp) & graphify update $rp } }
    )
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($s in $steps) {
        if (-not (Get-Command $s.Check -ErrorAction SilentlyContinue)) {
            $results.Add([pscustomobject]@{ Step = $s.Name; Status = 'skipped'; Detail = 'comando ausente' }) | Out-Null
            Write-Warn "Hook '$ToolName': $($s.Check) ausente; paso '$($s.Name)' omitido."
            continue
        }
        if ($DryRun) {
            $results.Add([pscustomobject]@{ Step = $s.Name; Status = 'dryrun'; Detail = 'simulado' }) | Out-Null
            Write-Info "Hook '$ToolName' DryRun: ejecutaría reindex '$($s.Name)'."
            continue
        }
        try {
            & $s.Run $RootPath 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
            $results.Add([pscustomobject]@{ Step = $s.Name; Status = 'ok'; Detail = '' }) | Out-Null
            Write-OK "Hook '$ToolName': reindex '$($s.Name)' OK."
        } catch {
            $results.Add([pscustomobject]@{ Step = $s.Name; Status = 'error'; Detail = "$_" }) | Out-Null
            Write-Warn "Hook '$ToolName': reindex '$($s.Name)' falló ($_); se continúa."
        }
    }
    return $results
}

# Hooks por defecto: toda herramienta conocida reindexa tras actualizarse.
foreach ($t in @('spec-kit', 'graphify', 'markitdown', 'markitdown-mcp', 'codebase-memory-mcp', 'context-mode', 'tokenslayer-mcp-server')) {
    $script:HookRegistry[$t] = { param($ToolName, $RootPath, $DryRun) Invoke-DefaultReindexHook -RootPath $RootPath -ToolName $ToolName -DryRun:$DryRun }
}

function Invoke-PostUpdateHooks {
    param(
        [string]$ToolName = '',
        [string]$Action = 'update',
        [string]$RootPath = '.',
        [switch]$DryRun
    )
    if (-not $ToolName) {
        $names = @(Get-PostUpdateHooks)
        Write-Info ("Hooks registrados ({0}): {1}" -f $names.Count, ($names -join ', '))
        return $names
    }
    if (-not $script:HookRegistry.Contains($ToolName)) {
        Write-Warn "Invoke-PostUpdateHooks: '$ToolName' sin hook registrado (skipped, no es error)."
        return [pscustomobject]@{ Tool = $ToolName; Action = $Action; Status = 'skipped'; Steps = @() }
    }
    Write-Info "Invoke-PostUpdateHooks: '$ToolName' action=$Action."
    try {
        $steps = @(& $script:HookRegistry[$ToolName] $ToolName $RootPath $DryRun)
        $failed = @($steps | Where-Object { $_.Status -eq 'error' }).Count
        $status = if ($failed -gt 0) { 'partial' } else { 'ok' }
        return [pscustomobject]@{ Tool = $ToolName; Action = $Action; Status = $status; Steps = $steps }
    } catch {
        Write-Warn "Invoke-PostUpdateHooks: hook de '$ToolName' falló ($_); se continúa (fail-open)."
        return [pscustomobject]@{ Tool = $ToolName; Action = $Action; Status = 'error'; Steps = @() }
    }
}

Export-ModuleMember -Function Invoke-PostUpdateHooks, Register-PostUpdateHook, Get-PostUpdateHooks
