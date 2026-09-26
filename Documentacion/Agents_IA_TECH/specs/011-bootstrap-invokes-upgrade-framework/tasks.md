# Tasks: Bootstrap Invokes upgrade_framework for External Dependency Sync

**Version:** 1.0.0  
**Status:** Draft  
**Date:** 2026-09-25  
**Spec ID:** 011  
**Plan ID:** 011

---

## Security Risks (security-risk: tags)

> **IMPORTANTE**: Los siguientes riesgos fueron identificados en el **Threat Model STRIDE** (`threat-model.md`). Cada tarea de mitigación debe incluir la etiqueta `security-risk:` correspondiente para priorización automática en `speckit-analyze`.

### CRITICAL
- [ ] **T040** Implementar allowlist de URLs confiables (Test-TrustedGithubUrl) + verificación de firma (cosign/checksums) para todos los clones (security-risk:CRITICAL)
- [ ] **T041** Firmar manifest template y verificar integridad antes de leer (security-risk:CRITICAL)
- [ ] **T042** Verificación obligatoria de firma/checksum en artefacts clonados antes de build (security-risk:CRITICAL)
- [ ] **T043** Sandbox/container para build de tokenslayer (aislar npm scripts) (security-risk:CRITICAL)
- [ ] **T044** Deshabilitar scripts npm arbitrarios en build (--ignore-scripts) o usar build aislado (security-risk:CRITICAL)
- [ ] **T045** Validación estricta de containment en upgrade_framework (realpath, sin symlinks, sin ..) (security-risk:CRITICAL)
- [ ] **T046** Eliminar secrets de manifest — usar env vars / secret managers, nunca en YAML (security-risk:CRITICAL)
- [ ] **T047** Sanitizar output de build — filtrar secrets de stdout/stderr (security-risk:CRITICAL)
- [ ] **T048** Fail-open obligatorio en TODA llamada externa (try/catch + WARN + continue, exit code 0) (security-risk:CRITICAL)
- [ ] **T049** Principio de menor privilegio — upgrade_framework con token/scopes mínimos, sin env vars sensibles heredados (security-risk:CRITICAL)
- [ ] **T050** Containment hardening — chroot/container/validación realpath para proyect_ext/ (security-risk:CRITICAL)

### HIGH
- [ ] **T051** Verificar identidad de upgrade_framework (hash del script, firma, ruta absoluta) antes de invocar (security-risk:HIGH)
- [ ] **T052** Manifest inmutable tras primera copia (chmod 444, o versionado git) (security-risk:HIGH)
- [ ] **T053** Deshabilitar submodules en git clone (--no-recurse-submodules) (security-risk:HIGH)
- [ ] **T054** Sanitizar env vars antes de pasar a upgrade_framework (solo vars necesarias) (security-risk:HIGH)
- [ ] **T055** Shallow clone (--depth=1) para evitar historia .git completa (security-risk:HIGH)
- [ ] **T056** Límites de tamaño/tipo en clones (max depth, max size, timeout) (security-risk:HIGH)
- [ ] **T057** Timeout estricto en uv tool install (ej. 60s) + kill en exceso (security-risk:HIGH)
- [ ] **T058** Validar schema de opencode.json antes/después de MCP registration (security-risk:HIGH)
- [ ] **T059** Validar DryRun — zero side effects (auditoría de fs writes en DryRun) (security-risk:HIGH)

### MEDIUM
- [ ] **T060** Log inmutable de auditoría (append-only, hash chain, o syslog remoto) para cada sync (security-risk:MEDIUM)
- [ ] **T061** Integridad de logs (hash, firma, write-once) (security-risk:MEDIUM)
- [ ] **T062** Registro de manifest copy (timestamp, source hash, user) en audit log (security-risk:MEDIUM)
- [ ] **T063** Lock file / mutex para proyect_ext/ durante sync (security-risk:MEDIUM)

### LOW
- [ ] **T064** Mejora continua: Rotación periódica de allowlist URLs, revisión de dependencias (security-risk:LOW)

---

## Dependency Graph (Mermaid)

```mermaid
graph TD
    %% Phase A: upgrade_framework CLI
    T001[CLI Entrypoint] --> T002[Unit Tests CLI]
    
    %% Phase B: Bootstrap invokes upgrade_framework
    T010[Invoke-UpgradeFramework func] --> T011[Call in Step 3]
    T011 --> T012[Fail-open wrapper]
    T011 --> T013[DryRun propagation]
    T001 -.-> T010  %% CLI must exist before bootstrap can call it
    
    %% Phase C: Manifest template
    T020[Copy manifest template] --> T021[Idempotent first-run only]
    
    %% Phase D: Integration Tests
    T030[Clean project test] --> T031[Verify tokenslayer + MCP]
    T010 -.-> T030
    T011 -.-> T030
    T012 -.-> T030
    T013 -.-> T030
    T020 -.-> T030
    T021 -.-> T030
    
    style T001 fill:#e1f5fe
    style T002 fill:#e1f5fe
    style T010 fill:#fff3e0
    style T011 fill:#fff3e0
    style T012 fill:#fff3e0
    style T013 fill:#fff3e0
    style T020 fill:#e8f5e9
    style T021 fill:#e8f5e9
    style T030 fill:#fce4ec
    style T031 fill:#fce4ec
```

**Legend:**
- 🔵 **Phase A** — `upgrade_framework` CLI preparation
- 🟠 **Phase B** — Bootstrap integration
- 🟢 **Phase C** — Manifest template handling
- 🟣 **Phase D** — Integration tests

---

## Phase A: upgrade_framework CLI

### T001 — Create CLI entrypoint `upgrade_framework.ps1`

| Field | Value |
|-------|-------|
| **ID** | T001 |
| **Title** | Create PowerShell CLI entrypoint for `upgrade_framework` agent |
| **Description** | Create `upgrade_framework.ps1` in `.github/agents/upgrade_framework/` that accepts `-RootPath`, `-ForceUpgradeTools`, `-DryRun` parameters. The script should read `dependencias-manifest.yml` from `$RootPath`, execute the sync logic (clone/update `proyect_ext/` per manifest for spec-kit, graphify via `uv tool install`, tokenslayer), and return exit code 0 on success / non-zero on failure. |
| **File(s)** | `.github/agents/upgrade_framework/upgrade_framework.ps1` (NEW) |
| **Done Criteria** | • File exists and is executable<br>• Accepts `-RootPath` (mandatory), `-ForceUpgradeTools` (switch), `-DryRun` (switch)<br>• Reads manifest from `$RootPath/dependencias-manifest.yml`<br>• Clones/updates `proyect_ext/spec-kit/` from GitHub<br>• Clones/updates `proyect_ext/tokenslayer/` from GitHub<br>• Installs/upgrades `graphify` via `uv tool install`<br>• Returns 0 on success, non-zero on failure<br>• Respects `-DryRun` (simulates only) |
| **Dependencies** | None |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

### T002 — Unit tests for CLI entrypoint

| Field | Value |
|-------|-------|
| **ID** | T002 |
| **Title** | Write unit tests for `upgrade_framework.ps1` CLI |
| **Description** | Create Pester tests validating parameter parsing, dry-run mode, manifest reading, and error handling. Tests should mock external calls (git, uv, npm). |
| **File(s)** | `.github/agents/upgrade_framework/upgrade_framework.Tests.ps1` (NEW) |
| **Done Criteria** | • Tests exist and run with `Invoke-Pester`<br>• Covers: mandatory `-RootPath`, optional flags, dry-run output, manifest missing error, exit codes<br>• External calls mocked (no network/git in tests)<br>• Minimum 80% coverage |
| **Dependencies** | T001 |
| **Responsible Agent** | `qa-senior` |

---

## Phase B: Bootstrap invokes upgrade_framework

### T010 — Add `Invoke-UpgradeFramework` helper function in bootstrap

| Field | Value |
|-------|-------|
| **ID** | T010 |
| **Title** | Add `Invoke-UpgradeFramework` function to `plataformador-bootstrap.ps1` |
| **Description** | Add a helper function `Invoke-UpgradeFramework` in `scripts/plataformador-bootstrap.ps1` that locates the `upgrade_framework.ps1` CLI (relative to script or known path) and invokes it with `-RootPath $resolvedRoot -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun`. Function should return the exit code and captured output. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY) |
| **Done Criteria** | • Function `Invoke-UpgradeFramework` exists in the script<br>• Accepts `-RootPath`, `-ForceUpgradeTools`, `-DryRun`<br>• Locates `upgrade_framework.ps1` (relative path from script or `$PSScriptRoot/../.github/agents/upgrade_framework/upgrade_framework.ps1`)<br>• Invokes with correct parameters<br>• Returns exit code and output<br>• Handles missing CLI gracefully (returns non-zero) |
| **Dependencies** | T001 |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

### T011 — Invoke upgrade_framework in Step 3 (before tokenslayer build)

| Field | Value |
|-------|-------|
| **ID** | T011 |
| **Title** | Call `Invoke-UpgradeFramework` in `-ForceUpgradeTools` block before tokenslayer build |
| **Description** | In `plataformador-bootstrap.ps1`, inside the `if ($ForceUpgradeTools)` block (Step 3), add the call to `Invoke-UpgradeFramework` **before** the tokenslayer build section (Step 3b). Pass `$resolvedRoot`, `$ForceUpgradeTools`, `$DryRun`. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY) |
| **Done Criteria** | • Call occurs inside `if ($ForceUpgradeTools)` block<br>• Call is **before** tokenslayer build (Step 3b)<br>• Parameters: `-RootPath $resolvedRoot -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun`<br>• Result captured (exit code + output) |
| **Dependencies** | T010 |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

### T012 — Fail-open wrapper (try/catch + WARN + continue)

| Field | Value |
|-------|-------|
| **ID** | T012 |
| **Title** | Wrap invocation in try/catch with fail-open semantics |
| **Description** | Wrap the `Invoke-UpgradeFramework` call in a `try/catch` block. On any error (exception or non-zero exit code): emit `Write-Warn "upgrade_framework failed: <reason> — continuing bootstrap"` and **continue** execution. Bootstrap must **never** exit with non-zero due to upgrade_framework failure. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY) |
| **Done Criteria** | • try/catch block wraps the invocation<br>• On exception: `Write-Warn` with error detail + continue<br>• On non-zero exit code: `Write-Warn` with exit code + continue<br>• Bootstrap continues to subsequent steps (tokenslayer build, MCP registration, indexes)<br>• Exit code of bootstrap remains 0 |
| **Dependencies** | T011 |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

### T013 — Respect `$DryRun` flag propagation

| Field | Value |
|-------|-------|
| **ID** | T013 |
| **Title** | Ensure `-DryRun` propagates to upgrade_framework and suppresses all writes |
| **Description** | Verify that when `plataformador-bootstrap.ps1` is run with `-DryRun`, the `Invoke-UpgradeFramework` call passes `-DryRun:$true` and the upgrade_framework CLI respects it (no git clones, no npm installs, no file writes). The bootstrap should only log what *would* happen. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY), `.github/agents/upgrade_framework/upgrade_framework.ps1` (MODIFY if needed) |
| **Done Criteria** | • `-DryRun` passed to `Invoke-UpgradeFramework`<br>• CLI respects `-DryRun` (logs actions only, no external calls, no writes)<br>• Bootstrap logs "DryRun: would invoke upgrade_framework..."<br>• No side effects on filesystem or network |
| **Dependencies** | T010, T011 |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

## Phase C: Manifest template

### T020 — Copy `dependencias-manifest.yml` from kit to project if missing

| Field | Value |
|-------|-------|
| **ID** | T020 |
| **Title** | Copy master manifest template to project root on first run |
| **Description** | In `Sync-TransversalKit` (or early in bootstrap Step 1), check if `$RootPath/dependencias-manifest.yml` exists. If not, copy from master template at `$PSScriptRoot/../dependencias-manifest.yml` → `$RootPath/dependencias-manifest.yml`. This ensures the manifest is available for `upgrade_framework` to read. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY) — inside `Sync-TransversalKit` or new early step |
| **Done Criteria** | • Check runs before `upgrade_framework` invocation<br>• Copies from `$PSScriptRoot/../dependencias-manifest.yml` (kit root)<br>• Destination: `$RootPath/dependencias-manifest.yml`<br>• Respects `-DryRun` (logs only, no copy)<br>• Does NOT overwrite if file already exists |
| **Dependencies** | None (can run in parallel with Phase A) |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

### T021 — Idempotent: only first run (no overwrite)

| Field | Value |
|-------|-------|
| **ID** | T021 |
| **Title** | Ensure manifest copy is idempotent (first run only) |
| **Description** | The copy logic in T020 must only execute if the destination file does NOT exist. If `$RootPath/dependencias-manifest.yml` already exists, preserve it (user may have customized it). Never overwrite. |
| **File(s)** | `scripts/plataformador-bootstrap.ps1` (MODIFY — same location as T020) |
| **Done Criteria** | • `Test-Path` check before copy<br>• If exists: `Write-OK "dependencias-manifest.yml ya existe; se conserva"`<br>• If not exists: copy + `Write-OK "dependencias-manifest.yml copiado desde plantilla maestra"`<br>• Re-running bootstrap does not modify existing manifest |
| **Dependencies** | T020 |
| **Responsible Agent** | `upgrade_framework` / `devops` |

---

## Phase D: Integration Tests

### T030 — Clean consumer project test with `-ForceUpgradeTools`

| Field | Value |
|-------|-------|
| **ID** | T030 |
| **Title** | End-to-end test: fresh consumer project with `-ForceUpgradeTools` |
| **Description** | Create a test script/scenario that: (1) creates a temporary clean directory (simulating a fresh consumer project like `trading_bot`), (2) runs `.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools -DryRun:$false`, (3) verifies all expected outcomes. |
| **File(s)** | `scripts/test-bootstrap-upgrade-framework.ps1` (NEW) or integration test in test suite |
| **Done Criteria** | • Test creates temp dir with no `dependencias-manifest.yml`, no `proyect_ext/`, no `opencode.json` tokenslayer entry<br>• Runs bootstrap with `-ForceUpgradeTools`<br>• Verifies: manifest copied to project root<br>• Verifies: `proyect_ext/tokenslayer/` cloned from GitHub<br>• Verifies: `proyect_ext/spec-kit/` cloned from GitHub<br>• Verifies: `graphify` installed via `uv tool install`<br>• Verifies: tokenslayer builds successfully (`proyect_ext/tokenslayer/mcp-server/build/index.js` exists)<br>• Verifies: `opencode.json` gets `"tokenslayer.enabled": true` (4th MCP)<br>• All steps complete with `INFO` logs, exit code 0 |
| **Dependencies** | T001, T010, T011, T012, T013, T020, T021 |
| **Responsible Agent** | `qa-senior` |

---

### T031 — Verify idempotency and fail-open behavior

| Field | Value |
|-------|-------|
| **ID** | T031 |
| **Title** | Verify idempotency (re-run) and fail-open (network failure simulation) |
| **Description** | Two sub-tests: (1) Re-run the same command from T030 on the same temp dir → verify no errors, no duplicates, only updates changed files. (2) Simulate network failure during `upgrade_framework` execution (e.g., block GitHub or use invalid URL in manifest temporarily) → verify `WARN` logged, bootstrap continues, exit code 0, tokenslayer build skipped if clone missing. |
| **File(s)** | `scripts/test-bootstrap-upgrade-framework.ps1` (EXTEND) |
| **Done Criteria** | **Idempotency test:**<br>• Re-run completes without errors<br>• No duplicate files/clones<br>• Manifest NOT overwritten<br>• `proyect_ext/` updated via git pull / uv tool upgrade<br>• Tokenslayer rebuilds only if sources changed<br><br>**Fail-open test:**<br>• Network failure simulated (e.g., `git clone` fails)<br>• `Write-Warn` emitted: "upgrade_framework failed: ... — continuing bootstrap"<br>• Bootstrap continues to subsequent steps<br>• Tokenslayer build skipped if `proyect_ext/tokenslayer/` not present<br>• Exit code 0 |
| **Dependencies** | T030 |
| **Responsible Agent** | `qa-senior` |

---

## 9. Architectural Analysis Reference

**ADR Generado**: [ADR-0007: Bootstrap delega sincronización de dependencias externas en upgrade_framework](../../arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md)

**Analyze Consolidado**: [analyze.md](analyze.md)

**Guardrails** (desde ADR-0007 — cada tarea debe respetarlos):
1. Fail-open obligatorio en toda llamada externa
2. No hardcodear URLs en bootstrap (leer del manifest)
3. `-DryRun` debe propagarse y no escribir nada
4. Idempotencia: re-ejecutar no duplica ni rompe
5. Frontera kit ↔ app: NO tocar `Documentacion/<AppName>/`
6. Propagación correcta de flags (`-ForceUpgradeTools`, `-DryRun`, `-SkipSync`)
7. Logging estructurado (INFO/WARN/ERROR)
8. Containment de `proyect_ext/` bajo `<root>/proyect_ext/`

**Spec Linking**: Ver `analyze.md` Sección 4 para matriz completa spec ↔ plan ↔ tasks ↔ ADR. Cada tarea referencia su RF/RNF/AC origen en "Description" y "Done Criteria".

---

## Final Validation Checklist

| # | Check | Verification Method | Status |
|---|-------|---------------------|--------|
| 1 | `upgrade_framework.ps1` CLI exists and is invocable | File exists, runs with `-Help` | ⬜ |
| 2 | CLI accepts `-RootPath`, `-ForceUpgradeTools`, `-DryRun` | Manual test / unit tests | ⬜ |
| 3 | `Invoke-UpgradeFramework` function in bootstrap | Grep for function name | ⬜ |
| 4 | Invocation occurs **before** tokenslayer build in Step 3 | Code review / trace execution | ⬜ |
| 5 | Fail-open: bootstrap continues on any upgrade_framework error | Simulate failure, check exit code | ⬜ |
| 6 | Manifest copied to project root on first run (idempotent) | Fresh dir test | ⬜ |
| 7 | No hardcoded URLs in bootstrap (all from manifest) | Code review `grep -n "github.com"` | ⬜ |
| 8 | `Documentacion/<AppName>/` never touched | Filesystem audit / git status | ⬜ |
| 9 | Clean consumer project: single run → manifest + proyect_ext + tokenslayer build + 4th MCP | T030 test passes | ⬜ |
| 10 | Re-run → no errors, no duplicates | T031 idempotency test passes | ⬜ |
| 11 | Network failure → WARN + continue + exit 0 | T031 fail-open test passes | ⬜ |
| 12 | Without `-ForceUpgradeTools` → no invocation, no tokenslayer build | Manual test without flag | ⬜ |

---

## Traceability Matrix

| Task | Spec Requirement | Plan Section |
|------|------------------|--------------|
| T001 | RF-04, RF-05, RF-06 | Phase A |
| T002 | RF-04, RF-05, RF-06 | Phase A |
| T010 | RF-01, RF-03 | Phase B, 3.2 |
| T011 | RF-01, RF-09 | Phase B, 2.1 |
| T012 | RF-02, RNF-01 | Phase B, 2.3 |
| T013 | RNF-03, RF-03 | Phase B, 2.2 |
| T020 | RF-07 | Phase C, 3.2 |
| T021 | RF-07, RNF-03 | Phase C, 3.2 |
| T030 | AC-01, AC-05, AC-06 | Phase D, VC-01..VC-08 |
| T031 | AC-02, AC-03, AC-04 | Phase D, VC-03, VC-07, VC-10 |

---

*Generated by `speckit-tasks` for Agent-SSD*