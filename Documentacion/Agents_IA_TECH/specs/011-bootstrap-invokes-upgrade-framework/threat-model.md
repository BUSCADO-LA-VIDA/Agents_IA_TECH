# Threat Model STRIDE — Spec #011: Bootstrap Invokes upgrade_framework

**Spec ID:** 011-bootstrap-invokes-upgrade-framework  
**Fecha:** 2026-09-25  
**Agente:** security-auditor  
**Estado:** Completado  
**Versión:** 1.0.0  

---

## 1. Resumen del Sistema

Este threat model cubre la integración donde `plataformador-bootstrap.ps1` delega la sincronización de dependencias externas (`dependencias-manifest.yml` → `proyect_ext/`) al agente `upgrade_framework` antes del build de `tokenslayer`.

**Actores principales:**
- `plataformador-bootstrap.ps1` — Orquestador (fail-open, gated por `-ForceUpgradeTools`)
- `upgrade_framework` — Ejecutor de sync (git clone/pull, uv tool install/upgrade)
- `dependencias-manifest.yml` — Fuente de verdad para URLs y versiones
- `proyect_ext/` — Directorio de contención para dependencias clonadas
- `tokenslayer build` — Compilación que consume `proyect_ext/tokenslayer/`

**Flujo crítico:**
```
Bootstrap (Step 3) → upgrade_framework → proyect_ext/ (tokenslayer, spec-kit, graphify) → tokenslayer build → MCP registration
```

---

## 2. Matriz STRIDE por Componente

| Componente | Spoofing | Tampering | Repudiation | Info Disclosure | DoS | Elevation of Privilege |
|------------|----------|-----------|-------------|-----------------|-----|------------------------|
| **bootstrap → upgrade_framework invocation** | 🔴 CRITICAL | 🟠 ALTO | 🟡 MEDIO | 🟡 MEDIO | 🟠 ALTO | 🟠 ALTO |
| **dependencias-manifest.yml (lectura/escritura)** | 🟠 ALTO | 🔴 CRITICAL | 🟡 MEDIO | 🔴 CRITICAL | 🟡 MEDIO | 🟡 MEDIO |
| **proyect_ext/ clone (git/uv)** | 🔴 CRITICAL | 🔴 CRITICAL | 🟠 ALTO | 🟠 ALTO | 🔴 CRITICAL | 🔴 CRITICAL |
| **tokenslayer build (consumo proyect_ext)** | 🟡 MEDIO | 🟠 ALTO | 🟡 MEDIO | 🟡 MEDIO | 🟡 MEDIO | 🟠 ALTO |
| **MCP registration (opencode.json)** | 🟡 MEDIO | 🟠 ALTO | 🟡 MEDIO | 🟡 MEDIO | 🟡 BAJO | 🟡 MEDIO |

---

## 3. Análisis Detallado STRIDE

### 3.1 Spoofing (Suplantación de Identidad)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **S-01** | **Repo falso / typosquatting** | `upgrade_framework` clona desde URL en manifest. Si manifest comprometido apunta a repo malicioso (typosquatting: `github.com/ajvkiram/TokenSlayer`), se ejecuta código arbitrario en build. | Ejecución remota de código (RCE) en build step | Media | 🔴 **CRITICAL** |
| **S-02** | **Manifest manipulado en tránsito** | Si `dependencias-manifest.yml` se descarga/modifica antes de que `upgrade_framework` lo lea (MITM en red, FS compromise), URLs alteradas redirigen a fuentes maliciosas. | Supply chain compromise | Media | 🔴 **CRITICAL** |
| **S-03** | **upgrade_framework suplantado** | PATH hijacking o alias malicioso `upgrade_framework` ejecuta código no autorizado en lugar del agente real. | Ejecución de código arbitrario con permisos del usuario | Baja | 🟠 **ALTO** |
| **S-04** | **Firma/verificación ausente** | Sin verificación de firma (cosign, gitsign, checksums) en artefacts clonados, no hay garantía de integridad del origen. | Imposibilidad de detectar supply chain attack | Alta | 🔴 **CRITICAL** |

### 3.2 Tampering (Manipulación)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **T-01** | **Clon malicioso en proyect_ext/** | Repo clonado contiene código malicioso en `proyect_ext/tokenslayer/` o `proyect_ext/spec-kit/` que se ejecuta durante `npm run build` o `tsc`. | RCE en build, persistencia en proyecto | Media | 🔴 **CRITICAL** |
| **T-02** | **Build tokenslayer comprometido** | `tokenslayer` build process ejecuta scripts arbitrarios (`prepare`, `preinstall`, `postinstall` en package.json) desde `proyect_ext/tokenslayer/`. | RCE durante build, exfiltración de secrets | Media | 🔴 **CRITICAL** |
| **T-03** | **Manifest modificado post-copia** | Usuario o proceso malicioso modifica `dependencias-manifest.yml` local tras copia inicial, apuntando a fuentes no confiables. | Persistencia, supply chain desviado | Media | 🟠 **ALTO** |
| **T-04** | **proyect_ext/ fuera de containment** | `upgrade_framework` clona fuera de `<root>/proyect_ext/` (path traversal `../../`) → escritura arbitraria en FS. | Escape de contención, overwrite de archivos críticos | Baja | 🔴 **CRITICAL** |
| **T-05** | **Git submodule / subrepo injection** | Repo clonado incluye submódulos maliciosos que se inicializan automáticamente. | Código adicional ejecutado sin consentimiento | Baja | 🟠 **ALTO** |

### 3.3 Repudiation (Repudio)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **R-01** | **Falta auditoría de qué se clonó/construyó** | No hay log inmutable de: qué repos clonó, qué commit hash, qué versión de graphify, quién invocó, cuándo. | Imposible forensics post-incidente, no accountability | Alta | 🟠 **ALTO** |
| **R-02** | **Logs modificables** | Logs de bootstrap/upgrade_framework en archivo local sin integridad → atacante puede borrar/modificar evidencia. | Encubrimiento de ataque | Media | 🟡 **MEDIO** |
| **R-03** | **No non-repudiation en manifest copy** | No hay registro de cuándo/cómo se copió el manifest template (primera ejecución vs actualización manual). | Confusión en investigación | Media | 🟡 **MEDIO** |

### 3.4 Information Disclosure (Divulgación de Información)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **I-01** | **Secrets en manifest** | `dependencias-manifest.yml` incluye tokens (PAT, npm token, uv index token) en URLs o campos → expuestos en logs, git history, FS. | Credenciales comprometidas, acceso a repos privados | Alta | 🔴 **CRITICAL** |
| **I-02** | **Tokens en build output** | `npm run build` / `tsc` emite secrets en stdout/stderr (env vars, .npmrc contenido) → logs de CI, terminal. | Fuga de tokens de registry, GitHub | Media | 🔴 **CRITICAL** |
| **I-03** | **Env vars expuestas a upgrade_framework** | `upgrade_framework` hereda env del bootstrap (GH_TOKEN, NPM_TOKEN, etc.) → accesible a proceso hijo y sus dependencias. | Escalada de privilegios, acceso no autorizado | Media | 🟠 **ALTO** |
| **I-04** | **proyect_ext/ contiene .git con historia** | Clones completos incluyen `.git/` con historia, remotes, config → posible fuga de tokens en `git config` o remotes privados. | Fuga de metadatos sensibles | Media | 🟡 **MEDIO** |

### 3.5 Denial of Service (Denegación de Servicio)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **D-01** | **Red/GitHub/npm/uv fallan → bootstrap bloqueado** | Fallo de red, rate limit GitHub, npm registry down, uv no instalado → `upgrade_framework` falla. Si no es fail-open, bootstrap entero se detiene. | Bootstrap incompleto, entorno roto | Alta | 🔴 **CRITICAL** |
| **D-02** | **Clone excesivamente grande** | Repo malicioso o corrupto con historia masiva (git bomb) → llenado de disco, OOM, timeout. | Agotamiento recursos, build colgado | Baja | 🟠 **ALTO** |
| **D-03** | **Deadlock / race condition** | Múltiples invocaciones concurrentes de bootstrap/upgrade_framework en mismo `proyect_ext/` → corrupción git, locks. | Estado inconsistente, fallos intermitentes | Media | 🟡 **MEDIO** |
| **D-04** | **uv tool install bloqueante** | `uv tool install graphify` requiere red, compila dependencias, sin timeout → hang indefinido. | Bootstrap nunca termina | Media | 🟠 **ALTO** |

### 3.6 Elevation of Privilege (Escalada de Privilegios)

| ID | Amenaza | Descripción | Impacto | Likelihood | Severidad |
|----|---------|-------------|---------|------------|-----------|
| **E-01** | **upgrade_framework con permisos excesivos** | Agente ejecuta con mismo token/permisos que bootstrap (puede escribir en cualquier ruta, acceder a todos los env vars, invocar CLI arbitrarios). | Compromiso total del entorno de build | Media | 🔴 **CRITICAL** |
| **E-02** | **Rutas fuera de containment** | `upgrade_framework` escribe fuera de `<root>/proyect_ext/` (symlinks, path traversal, `--prefix` en uv) → overwrite de archivos de sistema/config. | Persistencia, backdoor, config tampering | Baja | 🔴 **CRITICAL** |
| **E-03** | **MCP registration escribe opencode.json arbitrario** | Si `upgrade_framework` o bootstrap pueden inyectar claves arbitrarias en `opencode.json` → modificación de configuración de agente, execution flow hijack. | Persistencia, control de agente | Media | 🟠 **ALTO** |
| **E-04** | **DryRun bypass** | `-DryRun` no respetado completamente → side effects reales en modo "simulación". | Cambios no intencionados en prod | Media | 🟠 **ALTO** |

---

## 4. Riesgos Etiquetados `security-risk:` para `pendientes-implementacion.md`

```markdown
# Riesgos de Seguridad - Spec #011 (para pendientes-implementacion.md)

## CRITICAL
- [ ] S-01: Implementar allowlist de URLs confiables (Test-TrustedGithubUrl) + verificación de firma (cosign/checksums) para todos los clones (security-risk:CRITICAL)
- [ ] S-02: Firmar manifest template y verificar integridad antes de leer (security-risk:CRITICAL)
- [ ] S-04: Verificación obligatoria de firma/checksum en artefacts clonados antes de build (security-risk:CRITICAL)
- [ ] T-01: Sandbox/container para build de tokenslayer (aislar npm scripts) (security-risk:CRITICAL)
- [ ] T-02: Deshabilitar scripts npm arbitrarios en build (--ignore-scripts) o usar build aislado (security-risk:CRITICAL)
- [ ] T-04: Validación estricta de containment en upgrade_framework (realpath, sin symlinks, sin ..) (security-risk:CRITICAL)
- [ ] I-01: Eliminar secrets de manifest — usar env vars / secret managers, nunca en YAML (security-risk:CRITICAL)
- [ ] I-02: Sanitizar output de build — filtrar secrets de stdout/stderr (security-risk:CRITICAL)
- [ ] D-01: Fail-open obligatorio en TODA llamada externa (try/catch + WARN + continue, exit code 0) (security-risk:CRITICAL)
- [ ] E-01: Principio de menor privilegio — upgrade_framework con token/scopes mínimos, sin env vars sensibles heredados (security-risk:CRITICAL)
- [ ] E-02: Containment hardening — chroot/container/validación realpath para proyect_ext/ (security-risk:CRITICAL)

## HIGH
- [ ] S-03: Verificar identidad de upgrade_framework (hash del script, firma, ruta absoluta) antes de invocar (security-risk:HIGH)
- [ ] T-03: Manifest inmutable tras primera copia (chmod 444, o versionado git) (security-risk:HIGH)
- [ ] T-05: Deshabilitar submodules en git clone (--no-recurse-submodules) (security-risk:HIGH)
- [ ] I-03: Sanitizar env vars antes de pasar a upgrade_framework (solo vars necesarias) (security-risk:HIGH)
- [ ] I-04: Shallow clone (--depth=1) para evitar historia .git completa (security-risk:HIGH)
- [ ] D-02: Límites de tamaño/tipo en clones (max depth, max size, timeout) (security-risk:HIGH)
- [ ] D-04: Timeout estricto en uv tool install (ej. 60s) + kill en exceso (security-risk:HIGH)
- [ ] E-03: Validar schema de opencode.json antes/después de MCP registration (security-risk:HIGH)
- [ ] E-04: Validar DryRun — zero side effects (auditoría de fs writes en DryRun) (security-risk:HIGH)

## MEDIUM
- [ ] R-01: Log inmutable de auditoría (append-only, hash chain, o syslog remoto) para cada sync (security-risk:MEDIUM)
- [ ] R-02: Integridad de logs (hash, firma, write-once) (security-risk:MEDIUM)
- [ ] R-03: Registro de manifest copy (timestamp, source hash, user) en audit log (security-risk:MEDIUM)
- [ ] D-03: Lock file / mutex para proyect_ext/ durante sync (security-risk:MEDIUM)

## LOW
- [ ] Mejora continua: Rotación periódica de allowlist URLs, revisión de dependencias (security-risk:LOW)
```

---

## 5. Mitigaciones Obligatorias

### 5.1 Fail-Open (Obligatorio — RF-02, RNF-01, Guardrail 1)

```powershell
# PATRÓN OBLIGATORIO en plataformador-bootstrap.ps1
try {
    $result = Invoke-UpgradeFramework @params -ErrorAction Stop
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "upgrade_framework exited with code $LASTEXITCODE: $($result | Out-String). Continuing bootstrap (fail-open)."
    } else {
        Write-Info "upgrade_framework completed successfully"
    }
} catch {
    Write-Warn "upgrade_framework failed: $_ — continuing bootstrap (fail-open)"
}
# Bootstrap NUNCA hace exit/throw aquí — continúa siempre
```

**Regla**: Exit code del bootstrap **siempre 0** independientemente del resultado de `upgrade_framework`.

### 5.2 Allowlist de URLs (Obligatorio — S-01, S-02, Guardrail 2)

```powershell
# upgrade_framework DEBE validar cada URL contra allowlist antes de clonar
$TrustedDomains = @(
    'github.com/ajvikram/TokenSlayer',
    'github.com/github/spec-kit',
    # graphify via uv tool — no git clone
)

function Test-TrustedSource($url) {
    foreach ($domain in $TrustedDomains) {
        if ($url -like "*$domain*") { return $true }
    }
    return $false
}

# En upgrade_framework, antes de cada git clone:
if (-not (Test-TrustedSource $manifestEntry.url)) {
    throw "Untrusted source URL: $($manifestEntry.url) — not in allowlist"
}
```

**Regla**: `Test-TrustedGithubUrl` ya existe — **usarlo y extenderlo** para cubrir todas las fuentes del manifest.

### 5.3 Containment de `proyect_ext/` (Obligatorio — T-04, E-02, Guardrail 8)

```powershell
# En upgrade_framework, ANTES de cualquier operación FS en proyect_ext:
$proyectExtRoot = Resolve-Path (Join-Path $RootPath 'proyect_ext')
$targetPath = Resolve-Path (Join-Path $proyectExtRoot $relativePath) -ErrorAction SilentlyContinue

if ($null -eq $targetPath -or -not $targetPath.StartsWith($proyectExtRoot)) {
    throw "Containment violation: attempt to write outside proyect_ext/ ($targetPath)"
}

# Validar symlinks
if (Test-Path $targetPath -PathType Container) {
    $linkTarget = (Get-Item $targetPath).LinkType
    if ($linkTarget -ne 'HardLink' -and $linkTarget -ne 'Junction') {
        throw "Symlink detected in proyect_ext/ — not allowed"
    }
}
```

**Regla**: `proyect_ext/` **siempre** bajo `<root>/proyect_ext/`, sin rutas `..`, sin symlinks, sin escapes.

### 5.4 Verificación de Firma / Integridad (Obligatorio — S-04, T-01, T-02)

```yaml
# dependencias-manifest.yml — esquema extendido con integridad
dependencies:
  tokenslayer:
    source: "github.com/ajvikram/TokenSlayer"
    version: "v1.2.3"  # tag o commit hash
    integrity: "sha256-abc123..."  # checksum del artefacto esperado
    # OPCIONAL: firma cosign
    cosign:
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

```powershell
# En upgrade_framework, tras clone/install:
$actualHash = Get-FileHash -Algorithm SHA256 -Path $artefactPath
if ($actualHash.Hash -ne $expectedIntegrity) {
    throw "Integrity check failed for $name: expected $expectedIntegrity, got $($actualHash.Hash)"
}
```

### 5.5 Eliminación de Secrets del Manifest (Obligatorio — I-01, I-03)

```yaml
# dependencias-manifest.yml — SOLO URLs públicas, SIN tokens
dependencies:
  tokenslayer:
    source: "https://github.com/ajvikram/TokenSlayer"  # HTTPS público, sin token
    version: "v1.2.3"
    integrity: "sha256-..."
```

```powershell
# En bootstrap/upgrade_framework — sanitizar env antes de invocar procesos hijos
$safeEnv = @{}
$allowedEnvVars = @('PATH', 'HOME', 'USERPROFILE', 'TEMP', 'TMP')  # MÍNIMO necesario
foreach ($var in (Get-ChildItem Env:)) {
    if ($allowedEnvVars -contains $var.Name) {
        $safeEnv[$var.Name] = $var.Value
    }
}
# Pasar $safeEnv a Start-Process / Invoke-Expression
```

### 5.6 Build Aislado / --ignore-scripts (Obligatorio — T-01, T-02)

```powershell
# En tokenslayer build step (Step 3b):
npm ci --ignore-scripts --prefix proyect_ext/tokenslayer/mcp-server
npm run build --prefix proyect_ext/tokenslayer/mcp-server -- --ignore-scripts
# O mejor: build en container sandbox (Docker/Podman) sin red, sin secrets
```

### 5.7 Shallow Clone + No Submodules (Obligatorio — I-04, T-05)

```powershell
# En upgrade_framework git clone:
git clone --depth=1 --no-recurse-submodules --branch $version $url $targetDir
```

### 5.8 Timeouts Estrictos (Obligatorio — D-01, D-04, RNF-05)

```powershell
# En bootstrap, invocación a upgrade_framework:
$job = Start-Job -ScriptBlock { Invoke-UpgradeFramework @params }
$result = Wait-Job $job -Timeout 120  # RNF-05: 120s max
if ($job.State -eq 'Running') {
    Stop-Job $job -Force
    Write-Warn "upgrade_framework timeout (120s) — killed, continuing bootstrap (fail-open)"
}

# En upgrade_framework, uv tool install:
$uvJob = Start-Process uv -ArgumentList "tool install graphifyy[mcp]" -Wait -Timeout 60
if ($uvJob.ExitCode -ne 0 -or $uvJob.TimedOut) {
    Write-Warn "uv tool install timeout/failed — continuing"
}
```

### 5.9 Audit Log Inmutable (Obligatorio — R-01, R-02, R-03)

```powershell
# Estructura de entrada de auditoría (JSON Lines, append-only)
$auditEntry = @{
    timestamp   = (Get-Date).ToString('o')
    operation   = 'upgrade_framework_sync'
    actor       = $env:USERNAME
    host        = $env:COMPUTERNAME
    manifestHash = (Get-FileHash dependencias-manifest.yml -Algorithm SHA256).Hash
    actions     = @(
        @{ type = 'clone'; repo = 'tokenslayer'; commit = 'abc123'; status = 'success' }
        @{ type = 'clone'; repo = 'spec-kit'; commit = 'def456'; status = 'success' }
        @{ type = 'uv-install'; package = 'graphifyy[mcp]'; version = '0.1.0'; status = 'success' }
    )
    result      = 'success'  # success | partial | failed
} | ConvertTo-Json -Compress

# Append a audit log (archivo append-only, permisos 644, dueño root/admin)
Add-Content -Path "$RootPath/.bootstrap-audit.log" -Value $auditEntry -Encoding UTF8
```

---

## 6. Referencias en `Documentacion/Agents_IA_TECH/seguridad/`

Actualizar/crear los siguientes archivos:

| Archivo | Descripción |
|---------|-------------|
| `011-bootstrap-upgrade-framework-threat-model.md` | Este threat model (copia/referencia) |
| `supply-chain-security-guidelines.md` | Guía general: allowlist, firmas, containment, fail-open |
| `manifest-security.md` | Esquema seguro para dependencias-manifest.yml (sin secrets, con integrity) |
| `proyect_ext-containment.md` | Reglas de contención para directorio de dependencias externas |
| `audit-logging-standard.md` | Formato y requisitos de log de auditoría inmutable |
| `fail-open-pattern.md` | Patrón canónico de fail-open para bootstrap y agentes |

---

## 7. Validación Constitution Art.V (Security & Compliance)

| Requisito Art.V | Estado | Evidencia |
|-----------------|--------|-----------|
| **Secrets management** | ⚠️ Parcial | Manifest no debe contener secrets (I-01 mitigado), env vars sanitizadas (I-03) |
| **Encryption at rest/transit** | ✅ Cumple | HTTPS para git clone, uv tool install usa TLS; artefacts verificados por checksum |
| **AuthZ/AuthN** | ⚠️ Parcial | Allowlist de URLs (S-01), pero falta authZ granular para upgrade_framework (E-01) |
| **Audit logging** | ⚠️ Parcial | Diseñado (R-01, R-02, R-03) — pendiente implementación |
| **Supply chain integrity** | ⚠️ Parcial | Allowlist + integrity checks + shallow clone diseñados — pendiente implementación |

**Violaciones Art.V actuales (CRITICAL — bloquean implementación hasta remediación):**
1. **Falta verificación de firma/integridad** en artefacts clonados (S-04, T-01, T-02)
2. **Falta containment hardening** efectivo (T-04, E-02)
3. **Falta fail-open verificado** en código (D-01) — solo en spec/ADR
4. **Falta sanitización de secrets** en env vars heredados (I-03)
5. **Falta audit logging** inmutable (R-01, R-02)

---

## 8. Próximos Pasos

1. **`documentador`** → Crear/actualizar archivos en `Documentacion/Agents_IA_TECH/seguridad/` (Sección 6)
2. **`arquitecto`** → Revisar mitigaciones y actualizar ADR-0007 con referencias a threat model
3. **`security-auditor`** → Validar implementación contra este threat model en fase de converge
4. **`api-developer` / `devops`** → Implementar mitigaciones CRITICAL/HIGH en tasks.md (etiquetadas `security-risk:`)

---

*Generado por security-auditor — spec #011 threat model STRIDE*  
*Basado en: spec.md, analyze.md, ADR-0007*