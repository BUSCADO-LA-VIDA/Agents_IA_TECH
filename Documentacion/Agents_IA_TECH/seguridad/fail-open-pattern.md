# Fail-Open Pattern — Bootstrap & Agents

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Fuente:** Threat Model STRIDE Spec #011 (D-01, RF-02, RNF-01, Guardrail 1 ADR-0007)  
**Estado:** Activo  

---

## 1. Definición

> **Fail-Open**: Ante cualquier fallo en operaciones externas (red, git, npm, uv, procesos hijos), el sistema **emite WARN, registra en audit log, y CONTINÚA la ejecución**. El código de salida **siempre es 0** para el proceso principal (bootstrap).

Esto garantiza que fallos transitorios o dependencias externas no disponibles **nunca bloqueen** el entorno de desarrollo.

---

## 2. Patrones Canónicos

### 2.1 Nivel Bootstrap (Orquestador)

```powershell
# PATRÓN OBLIGATORIO para CADA invocación externa en bootstrap
function Invoke-WithFailOpen {
    param(
        [ScriptBlock]$Action,
        [string]$OperationName,
        [string]$CorrelationId,
        [string]$ManifestHash
    )
    
    try {
        Write-Info "Starting $OperationName..."
        $result = & $Action
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-OK "$OperationName completed successfully"
            Write-AuditLog -Operation $OperationName -CorrelationId $CorrelationId `
                -ManifestHash $ManifestHash -Actions $result.Actions `
                -Result 'success' -ExitCode 0
            return @{ success = $true; output = $result }
        } else {
            Write-Warn "$OperationName exited with code $exitCode: $($result.Output | Out-String). Continuing (fail-open)."
            Write-AuditLog -Operation $OperationName -CorrelationId $CorrelationId `
                -ManifestHash $ManifestHash -Actions $result.Actions `
                -Result 'partial' -ExitCode $exitCode
            return @{ success = $false; output = $result; exitCode = $exitCode }
        }
    } catch {
        $errMsg = $_.Exception.Message
        Write-Warn "$OperationName failed with exception: $errMsg — continuing bootstrap (fail-open)"
        Write-AuditLog -Operation $OperationName -CorrelationId $CorrelationId `
            -ManifestHash $ManifestHash -Actions @() `
            -Result 'failed' -ExitCode -1
        return @{ success = $false; error = $errMsg; exitCode = -1 }
    }
}

# USO EN BOOTSTRAP:
$correlationId = [Guid]::NewGuid().ToString()
$manifestHash = (Get-FileHash (Join-Path $RootPath 'dependencias-manifest.yml') -Algorithm SHA256).Hash

# upgrade_framework sync
$ufResult = Invoke-WithFailOpen -Action { 
    Invoke-UpgradeFramework -RootPath $RootPath -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun `
        -CorrelationId $correlationId -ManifestHash $manifestHash
} -OperationName 'upgrade_framework_sync' -CorrelationId $correlationId -ManifestHash $manifestHash

# tokenslayer build (TAMBIÉN fail-open)
$tsResult = Invoke-WithFailOpen -Action {
    Invoke-TokenslayerBuild -RootPath $RootPath -DryRun:$DryRun -CorrelationId $correlationId
} -OperationName 'tokenslayer_build' -CorrelationId $correlationId -ManifestHash $manifestHash

# MCP registration (TAMBIÉN fail-open)
$mcpResult = Invoke-WithFailOpen -Action {
    Register-MCP -RootPath $RootPath -DryRun:$DryRun -CorrelationId $correlationId
} -OperationName 'mcp_registration' -CorrelationId $correlationId -ManifestHash $manifestHash

# Bootstrap SIEMPRE termina con exit 0
Write-Info "Bootstrap completed (fail-open: all external ops attempted)"
exit 0
```

### 2.2 Nivel upgrade_framework (Ejecutor)

```powershell
# En upgrade_framework.ps1 — cada dependencia es independiente
param(
    [Parameter(Mandatory)][string]$RootPath,
    [switch]$ForceUpgradeTools,
    [switch]$DryRun,
    [string]$CorrelationId,
    [string]$ManifestHash
)

$manifest = Validate-Manifest (Join-Path $RootPath 'dependencias-manifest.yml')
$actions = @()
$partialFailure = $false

foreach ($dep in $manifest.dependencies.Values) {
    $actionStart = Get-Date
    try {
        if (-not $ForceUpgradeTools) {
            $actions += @{ type = $dep.type; repo = $dep.name; status = 'skipped'; reason = 'ForceUpgradeTools not set'; durationMs = 0 }
            continue
        }
        
        if ($DryRun) {
            Write-Info "DryRun: would sync $($dep.name) ($($dep.version))"
            $actions += @{ type = $dep.type; repo = $dep.name; status = 'skipped'; reason = 'DryRun'; durationMs = 0 }
            continue
        }
        
        # Sync real (git clone/pull o uv tool install)
        $syncResult = Sync-Dependency $dep $RootPath
        
        $duration = (Get-Date) - $actionStart
        $actions += @{
            type = $dep.type
            repo = $dep.name
            status = 'success'
            commit = $syncResult.commit
            integrity = $syncResult.integrity
            durationMs = [int]$duration.TotalMilliseconds
        }
        Write-OK "Synced $($dep.name) @ $($syncResult.commit)"
    } catch {
        $duration = (Get-Date) - $actionStart
        $partialFailure = $true
        $actions += @{
            type = $dep.type
            repo = $dep.name
            status = 'failed'
            error = $_.Exception.Message
            durationMs = [int]$duration.TotalMilliseconds
        }
        Write-Warn "Failed to sync $($dep.name): $($_.Exception.Message) — continuing with other dependencies"
    }
}

# Audit log
Write-AuditLog -Operation 'upgrade_framework_sync' -CorrelationId $CorrelationId `
    -ManifestHash $ManifestHash -Actions $actions `
    -Result (if ($partialFailure) { 'partial' } else { 'success' }) -ExitCode 0

# POLÍTICA: upgrade_framework SIEMPRE exit 0 (fail-open total)
# El bootstrap decide si actuar sobre partial/failed
exit 0
```

---

## 3. Matriz de Operaciones Fail-Open

| Operación | Fallo Típico | Acción Fail-Open | Bootstrap Continúa |
|-----------|--------------|------------------|-------------------|
| `upgrade_framework` sync | Network timeout, GitHub rate limit, repo not found | WARN + audit log `partial` | ✅ Sí |
| Manifest copy (first run) | Permisos FS, master template missing | WARN + audit log `failed` | ✅ Sí |
| `git clone/pull` | Auth fallo, red, disco lleno | WARN por dep, otras continúan | ✅ Sí |
| `uv tool install` | PyPI down, compile error, timeout | WARN, dep marcada `failed` | ✅ Sí |
| `npm ci` | Registry down, lockfile corrupt | WARN, build saltado | ✅ Sí |
| `npm run build` | TypeScript errors, memoria | WARN, build saltado | ✅ Sí |
| MCP registration | opencode.json corrupto, permisos | WARN, registro saltado | ✅ Sí |
| Index rebuild (MCPs) | context-mode fallo, grafo corrupto | WARN, índice no actualizado | ✅ Sí |

---

## 4. Lo que NO es Fail-Open (Bloqueantes)

Estos errores **SÍ detienen el bootstrap** (exit code ≠ 0):

| Error | Razón |
|-------|-------|
| Parámetros obligatorios faltantes (`-RootPath`) | Bug de invocación, no fallo externo |
| Contención violada (`proyect_ext/` escape) | **Vulnerabilidad de seguridad** — stop inmediato |
| Manifest schema inválido / integrity check fallo | **Supply chain compromise** — stop inmediato |
| Symlink detectado en containment | **Vulnerabilidad** — stop inmediato |
| Cosign verification fallo | **Integridad comprometida** — stop inmediato |

**Regla**: Solo fallos de **seguridad/integridad** son blocking. Fallos de **disponibilidad externa** son fail-open.

---

## 5. Validación de Fail-Open (Tests Obligatorios)

| Test | Escenario | Verificación |
|------|-----------|--------------|
| FO-01 | `git clone` timeout (simulado) | WARN logged, audit `partial`, bootstrap exit 0 |
| FO-02 | `uv tool install` network fail | WARN logged, audit `partial`, bootstrap exit 0 |
| FO-03 | `npm ci` registry 500 | WARN logged, build skipped, bootstrap exit 0 |
| FO-04 | upgrade_framework script missing | WARN logged, audit `failed`, bootstrap exit 0 |
| FO-05 | Manifest copy permission denied | WARN logged, audit `failed`, bootstrap exit 0 |
| FO-06 | Containment violation attempt | **EXCEPTION thrown, bootstrap exit ≠ 0** (no fail-open) |
| FO-07 | Integrity mismatch post-clone | **EXCEPTION thrown, bootstrap exit ≠ 0** (no fail-open) |

---

## 6. Referencias

- Threat Model #011: `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` (D-01)
- ADR-0007: `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` (Guardrail 1, D2)
- Supply Chain Guidelines: `seguridad/supply-chain-security-guidelines.md` (Sección 5)
- Audit Logging Standard: `seguridad/audit-logging-standard.md` (audit log en fail-open)

---

*Generado por security-auditor — spec #011 threat model*