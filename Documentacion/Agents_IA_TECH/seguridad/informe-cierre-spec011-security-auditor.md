# Informe de Cierre — Security Auditor Spec #011

**Spec ID:** 011-bootstrap-invokes-upgrade-framework  
**Fecha auditoría:** 2026-10-04  
**Auditor:** security-auditor  
**Alcance:** `C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1` + `Documentacion\Agents_IA_TECH\seguridad\`  
**Threat Model de referencia:** `011-bootstrap-upgrade-framework-threat-model.md`

---

## 1. Objetivo de la auditoría

Verificar que las implementaciones de DevOps para spec 011 cumplen con el threat model STRIDE y con las mitigaciones etiquetadas `security-risk:`. Confirmar estado de tareas T051, T052, T056, T057, T058, T060, T061, T062, T064 y validación de T059 por qa-senior.

---

## 2. Hallazgos de implementación

### 2.1 Tareas HIGH/MEDIUM solicitadas

| ID | Descripción | Evidencia en código | Estado |
|----|-------------|---------------------|--------|
| T051 | Verificar identidad de upgrade_framework (hash SHA256) | `upgrade_framework.ps1:1358-1371` compara hash del script con `Documentacion\Agents_IA_TECH\seguridad\upgrade_framework.sha256`. Audit entry `script_identity_ok` / `script_identity_mismatch` | Implementado |
| T052 | Manifest inmutable tras primera copia | `upgrade_framework.ps1:477-487` verifica `IsReadOnly`; `Ensure-ManifestTemplate:725-741` marca `IsReadOnly=$true` + icacls + audit `manifest_copy` | Implementado |
| T056 | Límites de tamaño/tipo en clones + timeout git | `Invoke-GitWithTimeout` 807-826, timeout 120s, audit `git_timeout`. `Get-GitRepoSizeMB` 830-841, límite `$script:MAX_CLONE_MB` y rechazo fail-closed con audit `clone_size_exceeded` | Implementado |
| T057 | Timeout estricto uv tool install 60s | `Sync-Graphify:1231-1240` `Start-Process uv` con `WaitForExit(60000)`, audit `uv_timeout` | Implementado |
| T058 | Validar schema de opencode.json | `Validate-OpencodeSchema:237-276`. Schema por defecto `Documentacion\...seguridad\opencode.schema.json`. Validación antes/después de MCP registration, audit `opencode_schema_validated`/`opencode_schema_missing_props` | Implementado |
| T060 | Log inmutable de auditoría append-only con hash chain | `Write-AuditEntry:166-201` crea entrada JSON Lines con `prevHash`/`hash` SHA256. `Test-AuditLogIntegrity:203-235` verifica cadena | Implementado |
| T061 | Integridad de logs | Verificación de cadena en `Test-AuditLogIntegrity`, llamada tras cada `Write-AuditEntry:195`. Alerta `audit_integrity_violation` | Implementado |
| T062 | Registro de manifest copy en audit log | `Ensure-ManifestTemplate:734-740` escribe `manifest_copy` con hash fuente, source/target, user, timestamp | Implementado |
| T064 | Rotación periódica allowlist | `Test-AllowlistRotation:123-164`. Lee `allowlist-rotation.json`, alerta si >90 días, registra rotación y audit `allowlist_rotation_due` | Implementado |

### 2.2 T059 — Validar DryRun zero side effects

Evidencia encontrada:
- `upgrade_framework.ps1` propaga `-DryRun` en todas las funciones críticas: `Ensure-ManifestTemplate`, `Invoke-CommandCaptureSafe`, `Sync-GitRepository`, `Sync-Graphify`, `Invoke-UpgradeFrameworkSync`.
- Tests Pester en `tests\upgrade_framework.Tests.ps1` cubren DryRun:
  - `Debe respetar -DryRun (no escribir en filesystem real)` líneas 639-660
  - `Debe procesar spec-kit y graphify en DryRun` líneas 604-612
  - Validaciones de logs `*DryRun:*`
- **Validación qa-senior:** No existe bitácora formal de validación firmada por qa-senior en `Documentacion\Agents_IA_TECH\bitacoras\`. Los tests Pester existen pero no hay evidencia de ejecución aprobada ni registro de cierre T059. Estado: implementación técnica presente, validación formal pendiente de evidencia.

### 2.3 Cumplimiento STRIDE

**Spoofing**
- S-01 allowlist URLs: `Test-TrustedGithubUrl:302-310` con `$TrustedOwners` implementado. Falta verificación de firma cosign/checksum.
- S-03 identidad script: T051 implementado.
- S-04 firma ausente: **No mitigado**. T040, T041, T042 pendientes.

**Tampering**
- T-04 containment: `Test-ProyectExtContainment:383-433` con realpath + reparse points. Implementado.
- T-01/T-02 build sin sandbox: **No mitigado**. T043, T044 pendientes.

**Repudiation**
- R-01/R-02/R-03 audit log hash chain implementado T060/T061/T062. Cumple parcialmente.

**Information Disclosure**
- I-02 sanitización output: `Format-SanitizedText:547-614` con redacción de tokens, PEM, headers. Implementado T047.
- I-01 secretos en manifest: T046 **no implementado**. `Read-DependenciasManifest` detecta secretos pero en fail-closed; no hay bloqueo de escritura.

**Denial of Service**
- D-01 fail-open: script siempre exit 0, try/catch en MAIN 1402-1406. Implementado T048.
- D-02 tamaño clone: T056 implementado.
- D-04 timeout uv: T057 implementado.

**Elevation of Privilege**
- E-01 menor privilegio: `Invoke-CommandLeastPrivilege:758-773` limpia env vars sensibles. Parcial.
- E-02 containment hardening: implementado.
- E-03 schema opencode: T058 implementado.

---

## 3. Riesgos residuales

### CRITICAL no mitigados
- **T040** Allowlist + verificación de firma/checksum para clones. Actualmente solo allowlist, sin cosign/checksum obligatorio.
- **T041** Manifest firmado. `Test-ManifestSignature` existe pero es fail-open y no se genera firma en plantilla maestra.
- **T042** Verificación obligatoria de checksum de artefacts clonados antes de build. Código intenta validar checksum del manifest pero depende de campo opcional y es fail-closed incompleto.
- **T043** Sandbox/container para build de tokenslayer. `Invoke-SandboxBuild` existe como esqueleto pero no se ejecuta en flujo real.
- **T044** `--ignore-scripts` en npm. No forzado.
- **T046** Cero secrets en manifest. Detección existe pero no hay policy de secret manager.
- **T049** Least privilege real con scopes mínimos. Limpieza de env vars parcial.

### HIGH residuales
- T059 validación formal DryRun por qa-senior sin evidencia de cierre.
- T054 sanitización env vars completa pendiente.

### MEDIUM/LOW
- Rotación allowlist T064 implementada, pero `allowlist-rotation.json` muestra última rotación 2026-10-04T18:30:42, dentro de ventana 90 días.

---

## 4. Conclusión

**Implementaciones solicitadas T051,T052,T056,T057,T058,T060,T061,T062,T064 están presentes en `upgrade_framework.ps1` y en documentación de seguridad.** El código cumple con los requisitos técnicos descritos.

**T059:** la funcionalidad DryRun zero side effects está implementada y cubierta por tests Pester, pero **no existe evidencia formal de validación por qa-senior** en bitácora/documentación. Se requiere registro de ejecución de tests y firma de aprobación.

**Cumplimiento STRIDE:** Parcial. Mitigaciones de Spoofing, Tampering y Elevation of Privilege críticas permanecen abiertas. Fail-open, containment, audit log y sanitización están operativos.

---

## 5. Recomendación de converge

**No recomendar converge completo para spec 011 en este momento.**

Condiciones para converge seguro:
1. Cerrar tareas CRITICAL T040,T041,T042,T043,T044,T046,T049 con implementación verificable y tests.
2. Obtener evidencia formal de validación T059 por qa-senior: ejecución de Pester, reporte de cobertura ≥80% y registro en bitácora.
3. Actualizar `pendientes-implementacion.md` para reflejar estado real de T051-T064 como `done` y eliminar inconsistencias con inventario.
4. Revisar `upgrade_framework.sha256` contra hash actual del script y regenerar referencia tras cambios.
5. Ejecutar `speckit-analyze` y `speckit-converge` para re-generar tareas residuales.

Si se requiere cierre parcial, se puede converger el subconjunto HIGH/MEDIUM implementado con **riesgo residual aceptado documentado** y plan de remediación para CRITICAL en sprint siguiente.

---

*Informe generado por security-auditor — Spec #011 — 2026-10-04*
