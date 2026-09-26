# Audit Logging Standard — Bootstrap & upgrade_framework

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Fuente:** Threat Model STRIDE Spec #011 (R-01, R-02, R-03)  
**Estado:** Activo  

---

## 1. Objetivo

Proveer **auditoría inmutable, verificable y completa** de todas las operaciones de supply chain:
- Qué se clonó/instaló
- Qué versión/commit
- Quién/quién lo ejecutó
- Cuándo
- Resultado (éxito/fallo/parcial)
- Integridad del manifest usado

---

## 2. Formato: JSON Lines (NDJSON)

Cada línea es un objeto JSON válido, independiente, append-only.

```json
{"timestamp":"2026-09-25T10:30:00.123Z","operation":"upgrade_framework_sync","actor":"developer","host":"workstation-01","correlationId":"a1b2c3d4-e5f6-7890","manifestHash":"sha256-abc123...","actions":[{"type":"clone","repo":"tokenslayer","source":"https://github.com/ajvikram/TokenSlayer","version":"v1.2.3","commit":"a1b2c3d4e5f6...","targetDir":"proyect_ext/tokenslayer","integrity":"sha256-def456...","status":"success","durationMs":15420},{"type":"clone","repo":"spec-kit","source":"https://github.com/github/spec-kit","version":"v0.5.0","commit":"f6e5d4c3b2a1...","targetDir":"proyect_ext/spec-kit","integrity":"sha256-ghi789...","status":"success","durationMs":8920},{"type":"uv-install","repo":"graphify","package":"graphifyy[mcp]","version":"0.1.0","integrity":"sha256-jkl012...","status":"success","durationMs":45600}],"result":"success","exitCode":0}
```

---

## 3. Campos Obligatorios

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `timestamp` | string (ISO 8601 UTC) | Momento exacto de finalización de la operación |
| `operation` | string | Identificador de operación: `upgrade_framework_sync`, `bootstrap_manifest_copy`, `tokenslayer_build`, `mcp_registration` |
| `actor` | string | Usuario/identidad que ejecutó (`$env:USERNAME` / `$env:USER`) |
| `host` | string | Hostname (`$env:COMPUTERNAME` / `hostname`) |
| `correlationId` | string (UUID v4) | ID único para correlacionar bootstrap + upgrade_framework + build |
| `manifestHash` | string (sha256-hex) | Hash SHA256 del `dependencias-manifest.yml` usado |
| `actions` | array | Lista de acciones individuales realizadas |
| `result` | string | `success` \| `partial` \| `failed` |
| `exitCode` | integer | Código de salida del proceso (0 = éxito) |

### 3.1 Estructura de `actions[]`

Cada acción tiene campos base + específicos por tipo:

**Base (todos):**
```json
{
  "type": "clone|uv-install|build|copy|register",
  "repo": "string",           // nombre lógico (tokenslayer, spec-kit, graphify)
  "status": "success|failed|skipped",
  "durationMs": 1234,
  "error": "string|null"      // solo si status != success
}
```

**type: clone (git):**
```json
{
  "source": "https://github.com/...",
  "version": "v1.2.3",
  "commit": "a1b2c3d4...",
  "targetDir": "proyect_ext/tokenslayer",
  "integrity": "sha256-...",
  "cosignVerified": true
}
```

**type: uv-install:**
```json
{
  "package": "graphifyy[mcp]",
  "version": "0.1.0",
  "installPath": "~/.local/bin/graphify",
  "integrity": "sha256-..."
}
```

**type: build:**
```json
{
  "tool": "npm",
  "command": "run build",
  "workingDir": "proyect_ext/tokenslayer/mcp-server",
  "outputPath": "proyect_ext/tokenslayer/mcp-server/build/index.js",
  "ignoreScripts": true
}
```

**type: copy (manifest template):**
```json
{
  "source": "master-kit/dependencias-manifest.yml",
  "destination": "project/dependencias-manifest.yml",
  "sourceHash": "sha256-...",
  "overwritten": false
}
```

**type: register (MCP):**
```json
{
  "configFile": "opencode.json",
  "key": "tokenslayer.enabled",
  "value": true,
  "previousValue": false
}
```

---

## 4. Propiedades del Archivo de Log

| Propiedad | Requisito |
|-----------|-----------|
| **Ubicación** | `<project-root>/.bootstrap-audit.log` |
| **Permisos** | 644 (owner rw, group r, other r) |
| **Propietario** | Usuario que ejecuta bootstrap (no root/admin requerido) |
| **Modo** | Append-only (`Add-Content` / `>>`) — **NUNCA** sobrescribir |
| **Rotación** | Diaria: `.bootstrap-audit.log.YYYYMMDD` |
| **Retención** | 30 días (90 días en entornos regulados) |
| **Integridad** | Hash chain opcional: cada línea incluye `prevLineHash` |

### 4.1 Hash Chain (Opcional pero Recomendado)

```json
{"timestamp":"...","operation":"...","prevLineHash":"sha256-abc123...","actions":[...],"result":"success"}
```
- `prevLineHash` = SHA256 de la línea anterior completa
- Primera línea: `"prevLineHash": "genesis"`
- Permite detectar truncación/inserción/eliminación de líneas

---

## 5. Implementación en PowerShell

```powershell
function Write-AuditLog {
    param(
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string]$CorrelationId,
        [Parameter(Mandatory)][string]$ManifestHash,
        [Parameter(Mandatory)][array]$Actions,
        [Parameter(Mandatory)][string]$Result,  # success|partial|failed
        [int]$ExitCode = 0
    )
    
    $entry = @{
        timestamp      = (Get-Date).ToString('o')
        operation      = $Operation
        actor          = $env:USERNAME
        host           = $env:COMPUTERNAME
        correlationId  = $CorrelationId
        manifestHash   = $ManifestHash
        actions        = $Actions
        result         = $Result
        exitCode       = $ExitCode
    }
    
    # Hash chain
    $logPath = Join-Path $ProjectRoot '.bootstrap-audit.log'
    if (Test-Path $logPath) {
        $lastLine = Get-Content $logPath -Tail 1 -ErrorAction SilentlyContinue
        if ($lastLine) {
            $entry.prevLineHash = (Get-StringHash -Input $lastLine -Algorithm SHA256).Hash
        } else {
            $entry.prevLineHash = 'genesis'
        }
    } else {
        $entry.prevLineHash = 'genesis'
    }
    
    $json = $entry | ConvertTo-Json -Compress -Depth 10
    Add-Content -Path $logPath -Value $json -Encoding UTF8
    
    # Permisos (Windows: ACL, Unix: chmod)
    if ($IsLinux -or $IsMacOS) {
        chmod 644 $logPath
    }
}

function Get-StringHash {
    param([string]$Input, [string]$Algorithm = 'SHA256')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Input)
    $hash = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm).ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace('-', '').ToLower()
}
```

---

## 6. Correlación Bootstrap ↔ upgrade_framework

```powershell
# En bootstrap, ANTES de invocar upgrade_framework:
$correlationId = [Guid]::NewGuid().ToString()
$manifestHash = (Get-FileHash -Path (Join-Path $RootPath 'dependencias-manifest.yml') -Algorithm SHA256).Hash

# Pasar a upgrade_framework como parámetros
Invoke-UpgradeFramework -CorrelationId $correlationId -ManifestHash $manifestHash ...

# En upgrade_framework, usar los mismos valores en su Write-AuditLog
```

---

## 7. Consultas Útiles (Análisis Post-Incidente)

```powershell
# Últimas 10 sincronizaciones
Get-Content .bootstrap-audit.log -Tail 10 | ConvertFrom-Json | Format-Table timestamp, operation, result, exitCode

# Fallos en últimos 7 días
$since = (Get-Date).AddDays(-7)
Get-Content .bootstrap-audit.log | ConvertFrom-Json | Where-Object { $_.timestamp -gt $since -and $_.result -ne 'success' }

# Verificar integridad hash chain
$prev = 'genesis'
Get-Content .bootstrap-audit.log | ForEach-Object {
    $obj = $_ | ConvertFrom-Json
    if ($obj.prevLineHash -ne $prev) { Write-Error "CHAIN BROKEN at $($obj.timestamp)" }
    $prev = (Get-StringHash -Input $_)
}
```

---

## 8. Referencias

- Threat Model #011: `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` (R-01, R-02, R-03)
- Supply Chain Guidelines: `seguridad/supply-chain-security-guidelines.md` (Sección 10)
- Fail-Open Pattern: `seguridad/fail-open-pattern.md` (audit log en fail-open)

---

*Generado por security-auditor — spec #011 threat model*