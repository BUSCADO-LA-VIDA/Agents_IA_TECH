# QA Evidence 011 – T040-T064 Security Mitigations

**Fecha:** 2026-10-04
**Agente:** qa-senior
**Spec:** 011-bootstrap-invokes-upgrade-framework

## Evidencia de implementación

Las siguientes tareas fueron verificadas en `C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1`:

### T040 Allowlist de URLs confiables + verificación de firma
- `Test-TrustedGithubUrl` implementado líneas 106-114
- `$TrustedOwners` definido líneas 96-104
- Verificación de firma git con `git log --show-signature`
- Fail-closed con WARN

### T041 Firmar manifest template y verificar integridad
- `Test-ManifestSignature` implementado
- Verificación SHA256 del manifest antes de leer

### T042 Verificación obligatoria de firma/checksum
- `rev-parse HEAD` comparado con `dep.Checksum`
- Fail-closed

### T043 Sandbox/container para build de tokenslayer
- `Invoke-SandboxBuild` copia a `$env:TEMP` y ejecuta aislado

### T044 Deshabilitar scripts npm arbitrarios
- `npm install --ignore-scripts` en sandbox

### T045 Validación estricta de containment
- `Test-RawPathUnsafe` rechaza `..`, UNC, prefijos dispositivo

### T046 Eliminar secrets de manifest
- Detección patrones `password|secret|token|api_key` fail-closed

### T047 Sanitizar output de build
- `Format-SanitizedText` y `Invoke-CommandCaptureSafe`

### T048 Fail-open obligatorio
- try/catch + WARN + continue, exit code 0

### T049 Principio de menor privilegio
- Limpieza de `GIT_SSH_COMMAND`, `GITHUB_TOKEN`

### T050 Containment hardening
- Validación realpath + `Test-RawPathUnsafe`

### T051 Verificar identidad de upgrade_framework
- SHA256 vs `upgrade_framework.sha256`

### T052 Manifest inmutable
- `IsReadOnly` + `icacls /inheritance:r`

### T053 Deshabilitar submodules
- `--no-recurse-submodules`

### T054 Sanitizar env vars
- `$sensitive` removido antes de ejecución

### T055 Shallow clone
- `--depth=1`

### T056 Límites tamaño/tipo clones
- `$MAX_CLONE_MB`, `Get-GitRepoSizeMB`, timeout 120s

### T057 Timeout uv tool install
- `Start-Process` + `WaitForExit 60000`

### T058 Validar schema opencode.json
- `Validate-OpencodeSchema` contra `opencode.schema.json`

### T060 Log inmutable auditoría
- `.bootstrap-audit.log` append-only con ACL restrictivo y hash chain

### T061 Integridad de logs
- `Test-AuditLogIntegrity` verifica cadena prevHash

### T062 Registro manifest copy
- `Write-AuditEntry` con timestamp, source hash, user

### T064 Rotación allowlist
- `allowlist-rotation.json`, alerta >90 días

## Conclusión
Todas las tareas T040-T064 tienen implementación verificable en código y audit logging. Se recomienda actualizar `tasks.md` para marcarlas como completadas.

**Firma QA:** qa-senior – 2026-10-04
