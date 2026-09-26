# Manifest Security — dependencias-manifest.yml

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Fuente:** Threat Model STRIDE Spec #011 (I-01, I-03, S-01, S-02, S-04)  
**Estado:** Activo  

---

## 1. Principio Fundamental

> **NUNCA** almacenar secrets, tokens, credenciales o claves privadas en `dependencias-manifest.yml`.

El manifest es un archivo **versionado en git** y **leído por procesos automatizados**. Cualquier secret en él es:
- Expuesto en historia de git
- Visible en logs de CI/CD
- Accesible a cualquier proceso que lea el archivo
- Fuga garantizada en supply chain compromise

---

## 2. Esquema Seguro (v2 — con Integridad)

```yaml
# dependencias-manifest.yml — Esquema v2 (seguro)
# Ubicación: raíz del proyecto (copiado desde kit maestro en primera ejecución)

schemaVersion: 2

dependencies:
  tokenslayer:
    name: "tokenslayer"
    type: "git"
    source: "https://github.com/ajvikram/TokenSlayer"     # URL pública HTTPS, SIN token
    version: "v1.2.3"                                     # Tag fijo O commit hash (40 chars)
    # version: "a1b2c3d4e5f6..."                          # Commit hash preferido para inmutabilidad
    targetDir: "proyect_ext/tokenslayer"                  # Ruta relativa bajo containment
    integrity: "sha256-abc123def456..."                         # OBLIGATORIO: SHA256 del artefacto esperado
    cosign:                                               # OPCIONAL: Firma cosign para verificación criptográfica
      publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
      signature: "MEUCIQD..."                              # Firma base64 del artefacto
    verifyCommit: true                                    # Verificar que commit coincide con version
  
  spec-kit:
    name: "spec-kit"
    type: "git"
    source: "https://github.com/github/spec-kit"
    version: "v0.5.0"
    targetDir: "proyect_ext/spec-kit"
    integrity: "sha256-def456ghi789..."
    cosign:
      publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
      signature: "MEUCIQD..."
    verifyCommit: true
  
  graphify:
    name: "graphify"
    type: "uv-tool"
    package: "graphifyy[mcp]"                             # Nombre del paquete en uv/pip
    version: "0.1.0"                                      # Versión fija (pinned)
    integrity: "sha256-ghi789jkl012..."                         # Checksum del wheel/binary instalado
    # uv tool install no soporta cosign nativamente — confiar en integrity + PyPI trust

# Metadatos de auditoría (auto-generados, no editar manualmente)
_metadata:
  createdAt: "2026-09-25T10:00:00Z"
  createdBy: "plataformador-bootstrap"
  sourceHash: "sha256-..."                                # Hash del manifest template original
  lastSyncAt: "2026-09-25T10:30:00Z"
  lastSyncBy: "upgrade_framework"
  lastSyncResult: "success"
```

---

## 3. Campos Obligatorios por Tipo

### 3.1 type: "git" (tokenslayer, spec-kit)

| Campo | Requerido | Descripción |
|-------|-----------|-------------|
| `name` | ✅ | Identificador único (clave del objeto) |
| `type` | ✅ | `"git"` |
| `source` | ✅ | URL HTTPS pública del repo (sin credenciales) |
| `version` | ✅ | Tag semver (`v1.2.3`) **O** commit hash completo (`a1b2c3d...`) |
| `targetDir` | ✅ | Ruta relativa bajo `proyect_ext/` (ej. `proyect_ext/tokenslayer`) |
| `integrity` | ✅ | SHA256 del directorio/clon esperado (calculado post-clone) |
| `cosign` | ⚠️ Recomendado | Objeto con `publicKey` y `signature` para verificación criptográfica |
| `verifyCommit` | ✅ | `true` — validar que commit clonado coincide con `version` |

### 3.2 type: "uv-tool" (graphify)

| Campo | Requerido | Descripción |
|-------|-----------|-------------|
| `name` | ✅ | Identificador único |
| `type` | ✅ | `"uv-tool"` |
| `package` | ✅ | Nombre del paquete en uv/pip (ej. `graphifyy[mcp]`) |
| `version` | ✅ | Versión pinned exacta (ej. `0.1.0`) |
| `integrity` | ✅ | SHA256 del wheel/binary instalado (verificar post-install) |

---

## 4. Validaciones en upgrade_framework

### 4.1 Pre-Sync (antes de cualquier operación)

```powershell
function Validate-Manifest($manifestPath) {
    $manifest = YamlTo-Object $manifestPath
    
    # 1. Schema version
    if ($manifest.schemaVersion -ne 2) {
        throw "Unsupported manifest schema version: $($manifest.schemaVersion). Expected 2."
    }
    
    # 2. No secrets en source URLs
    foreach ($dep in $manifest.dependencies.Values) {
        if ($dep.source -match '[:@].*[@/]') {  # Detecta user:pass@ o token@
            throw "SECURITY: Secret detected in source URL for $($dep.name): $($dep.source)"
        }
        if ($dep.source -notmatch '^https://github\.com/') {
            throw "SECURITY: Untrusted source domain for $($dep.name): $($dep.source)"
        }
    }
    
    # 3. Campos obligatorios presentes
    foreach ($dep in $manifest.dependencies.Values) {
        $required = @('name', 'type', 'source', 'version', 'targetDir', 'integrity')
        if ($dep.type -eq 'uv-tool') { $required = @('name', 'type', 'package', 'version', 'integrity') }
        
        foreach ($field in $required) {
            if (-not $dep.$field) {
                throw "Manifest validation failed: $($dep.name) missing required field '$field'"
            }
        }
    }
    
    # 4. Allowlist de fuentes (Test-TrustedGithubUrl extendido)
    foreach ($dep in $manifest.dependencies.Values) {
        if (-not (Test-TrustedSource $dep)) {
            throw "Source not in allowlist: $($dep.name) -> $($dep.source)"
        }
    }
    
    return $manifest
}
```

### 4.2 Post-Sync (tras clone/install)

```powershell
function Verify-PostSync($dep, $targetPath) {
    # 1. Integridad del artefacto
    $actualHash = Get-DirectoryHash -Path $targetPath -Algorithm SHA256
    if ($actualHash -ne $dep.integrity) {
        throw "Integrity mismatch for $($dep.name): expected $($dep.integrity), got $actualHash"
    }
    
    # 2. Verificación commit (git)
    if ($dep.type -eq 'git' -and $dep.verifyCommit) {
        $clonedCommit = git -C $targetPath rev-parse HEAD
        $expectedCommit = $dep.version -match '^[a-f0-9]{40}$' ? $dep.version : (git -C $targetPath rev-list -n 1 $dep.version)
        if ($clonedCommit -ne $expectedCommit) {
            throw "Commit mismatch for $($dep.name): cloned $clonedCommit, expected $expectedCommit"
        }
    }
    
    # 3. Verificación cosign (si presente)
    if ($dep.cosign) {
        # Requiere cosign CLI instalado
        $result = cosign verify-blob \
            --key $dep.cosign.publicKey \
            --signature $dep.cosign.signature \
            $targetPath
        if ($LASTEXITCODE -ne 0) {
            throw "Cosign verification failed for $($dep.name)"
        }
    }
    
    Write-OK "Post-sync verification passed for $($dep.name)"
}
```

---

## 5. Plantilla Maestra (Kit Maestro)

Ubicación: `<kit-root>/dependencias-manifest.yml`

```yaml
# Plantilla maestra — copiada a proyectos consumidores en primera ejecución
# NO EDITAR DIRECTAMENTE EN PROYECTOS CONSUMIDORES — solo override local si necesario

schemaVersion: 2

dependencies:
  tokenslayer:
    name: "tokenslayer"
    type: "git"
    source: "https://github.com/ajvikram/TokenSlayer"
    version: "v1.2.3"
    targetDir: "proyect_ext/tokenslayer"
    integrity: "sha256-PENDIENTE_CALCULAR_EN_RELEASE"
    cosign:
      publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
      signature: "PENDIENTE_FIRMAR_EN_RELEASE"
    verifyCommit: true
  
  spec-kit:
    name: "spec-kit"
    type: "git"
    source: "https://github.com/github/spec-kit"
    version: "v0.5.0"
    targetDir: "proyect_ext/spec-kit"
    integrity: "sha256-PENDIENTE_CALCULAR_EN_RELEASE"
    cosign:
      publicKey: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
      signature: "PENDIENTE_FIRMAR_EN_RELEASE"
    verifyCommit: true
  
  graphify:
    name: "graphify"
    type: "uv-tool"
    package: "graphifyy[mcp]"
    version: "0.1.0"
    integrity: "sha256-PENDIENTE_CALCULAR_EN_RELEASE"

_metadata:
  templateVersion: "1.0.0"
  kitVersion: "2026.09.25"
  maintainer: "Agents_IA_TECH team"
```

---

## 6. Flujo de Actualización de Manifest

1. **Release de dependencia** → Mantenedor actualiza `version` + calcula nuevo `integrity` + firma con `cosign`
2. **Kit maestro** → Commit con manifest actualizado
3. **Proyectos consumidores** → En próxima ejecución bootstrap con `-ForceUpgradeTools`:
   - `upgrade_framework` lee manifest local
   - Detecta versión cambiada → `git pull` / `uv tool upgrade`
   - Verifica `integrity` post-sync
   - Actualiza `_metadata.lastSyncAt` en manifest local

---

## 7. Referencias

- Threat Model #011: `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` (I-01, I-03, S-01, S-02, S-04)
- ADR-0007: `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` (Guardrail 2, 4, 8)
- Supply Chain Guidelines: `seguridad/supply-chain-security-guidelines.md`
- Containment Rules: `seguridad/proyect_ext-containment.md`

---

*Generado por security-auditor — basado en threat model STRIDE spec #011*