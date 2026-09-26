# Specification: Bootstrap Invokes upgrade_framework for External Dependency Sync

**Version:** 1.0.0  
**Status:** Draft  
**Date:** 2026-09-25  
**Spec ID:** 011

---

## 1. Summary

The `plataformador-bootstrap.ps1` script prepares projects by syncing the transversal kit, MCPs, indexes, and apps. Currently it attempts to build `tokenslayer` in `proyect_ext/tokenslayer/mcp-server` but **does not clone the repository** — the clone was done manually in the master kit. Consumer projects (e.g., `trading_bot`) lack both `dependencias-manifest.yml` and `proyect_ext/`.

The `upgrade_framework` agent already exists to manage `dependencias-manifest.yml` and clone/update `proyect_ext/` (spec-kit, tokenslayer, graphify, etc.). This spec defines the integration where bootstrap delegates 100% of external dependency synchronization to `upgrade_framework` before the tokenslayer build step.

---

## 2. User Stories

| ID | Story |
|----|-------|
| US-01 | As a **project maintainer**, I want `plataformador-bootstrap.ps1 -ForceUpgradeTools` to automatically sync `dependencias-manifest.yml` → `proyect_ext/` so that consumer projects get all external dependencies without manual intervention. |
| US-02 | As a **developer onboarding a new project**, I want a single command (`-ForceUpgradeTools`) to clone `proyect_ext/tokenslayer/`, build it, and register the 4th MCP (`tokenslayer.enabled=true`) in `opencode.json` so the environment is ready in one run. |
| US-03 | As a **CI/CD pipeline**, I want the bootstrap to be **fail-open** on external operations (network, git, npm, uv) so that transient failures don't block the rest of the bootstrap process. |
| US-04 | As a **kit maintainer**, I want **zero hardcoded URLs** in the bootstrap script — all source URLs come from `dependencias-manifest.yml` so updates only require manifest changes. |

---

## 3. Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| **RF-01** | The bootstrap **MUST** invoke `upgrade_framework` to synchronize `dependencias-manifest.yml` → `proyect_ext/` **before** the tokenslayer build step (Step 3b). | Must |
| **RF-02** | The invocation **MUST** be **fail-open**: if `upgrade_framework` fails (network, repo, permissions) → emit `WARN` and continue bootstrap execution. | Must |
| **RF-03** | The invocation **MUST** be gated by `-ForceUpgradeTools` (opt-in, same flag as tokenslayer build). | Must |
| **RF-04** | `upgrade_framework` **MUST** clone/update `proyect_ext/tokenslayer/` from `https://github.com/ajvikram/TokenSlayer` (per `dependencias-manifest.yml`). | Must |
| **RF-05** | `upgrade_framework` **MUST** clone/update `proyect_ext/spec-kit/` from `https://github.com/github/spec-kit`. | Must |
| **RF-06** | `upgrade_framework` **MUST** handle `graphify` via `uv tool install` (not git clone). | Must |
| **RF-07** | If the project **does NOT** have a local `dependencias-manifest.yml` → copy the master kit template to the project root (first run only). | Must |
| **RF-08** | The bootstrap **MUST NOT** clone `proyect_ext/` directly — delegate 100% to `upgrade_framework`. | Must |
| **RF-09** | After `upgrade_framework` completes, the tokenslayer build (Step 3b) **MUST** find the clone and compile automatically. | Must |
| **RF-10** | All operations **MUST** respect the kit ↔ app boundary: **NEVER** touch `Documentacion/<AppName>/`. | Must |

---

## 4. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| **RNF-01** | **Fail-open** on all external operations (network, git, npm, uv, PowerShell). |
| **RNF-02** | **No hardcoded URLs** in bootstrap — read all sources from `dependencias-manifest.yml`. |
| **RNF-03** | **Idempotent**: re-execution must not break or duplicate resources. |
| **RNF-04** | **PowerShell 7+** (`pwsh`) compatibility required. |
| **RNF-05** | Execution time for upgrade_framework invocation should not exceed 120 seconds under normal network conditions. |
| **RNF-06** | Clear logging: each phase (manifest copy, clone, build, MCP registration) emits structured `INFO`/`WARN`/`ERROR` messages. |

---

## 5. Scenarios

### Scenario 1: Clean Consumer Project (Happy Path)
**Given** a fresh consumer project (e.g., `trading_bot`) with:
- No `dependencias-manifest.yml`
- No `proyect_ext/`
- No `opencode.json` tokenslayer entry

**When** running `.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools`

**Then**:
1. Master kit `dependencias-manifest.yml` is copied to project root
2. `upgrade_framework` is invoked and clones:
   - `proyect_ext/tokenslayer/` from GitHub
   - `proyect_ext/spec-kit/` from GitHub
   - Installs `graphify` via `uv tool install`
3. Tokenslayer build (Step 3b) finds `proyect_ext/tokenslayer/mcp-server` and compiles successfully
4. `opencode.json` is updated with `"tokenslayer.enabled": true` (4th MCP registered)
5. All steps complete in a single run with `INFO` logs

### Scenario 2: Project Already Has Manifest and proyect_ext (Idempotency)
**Given** a project with existing `dependencias-manifest.yml` and `proyect_ext/tokenslayer/`

**When** running `.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools`

**Then**:
1. Manifest is **not** overwritten
2. `upgrade_framework` updates existing clones (git pull / uv tool upgrade)
3. Tokenslayer rebuilds if sources changed
4. No duplicate files or conflicts

### Scenario 3: upgrade_framework Fails (Fail-Open)
**Given** network failure or GitHub rate limit during `upgrade_framework` execution

**When** running `.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools`

**Then**:
1. `WARN` emitted: "upgrade_framework failed: <reason> — continuing bootstrap"
2. Bootstrap continues to subsequent steps (MCP registration, index rebuild, etc.)
3. Tokenslayer build **skipped** if `proyect_ext/tokenslayer/` not present
4. Exit code remains 0 (bootstrap succeeds)

### Scenario 4: Without -ForceUpgradeTools Flag
**Given** any project state

**When** running `.\scripts\plataformador-bootstrap.ps1` (without flag)

**Then**:
1. `upgrade_framework` is **NOT** invoked
2. Tokenslayer build (Step 3b) is **skipped**
3. Bootstrap completes normally for other steps (sync kit, MCPs, indexes)

---

## 6. Acceptance Criteria

| ID | Criterion | Verification |
|----|-----------|--------------|
| AC-01 | `.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools` on clean consumer project → clones manifest, clones `proyect_ext/tokenslayer/`, compiles tokenslayer, registers 4th MCP (`tokenslayer.enabled=true`) in `opencode.json` | Manual test on fresh clone |
| AC-02 | Re-running the same command → no errors, no duplicates, updates only changed | Manual re-run |
| AC-03 | Network failure during clone → `WARN` logged, bootstrap continues, exit code 0 | Simulate network failure (disconnect) |
| AC-04 | Running without `-ForceUpgradeTools` → no upgrade_framework invocation, no tokenslayer build | Manual test without flag |
| AC-05 | `dependencias-manifest.yml` is source of truth for all URLs — no hardcoded URLs in bootstrap | Code review |
| AC-06 | `Documentacion/<AppName>/` never touched by bootstrap | Code review / filesystem audit |

---

## 7. Out of Scope

- Modifying `upgrade_framework` agent logic (assumed working per its own spec)
- Changing `dependencias-manifest.yml` schema
- Building `spec-kit` or `graphify` (only tokenslayer build is in bootstrap scope)
- MCP configuration beyond `tokenslayer.enabled=true` registration

---

## 8. Traceability

| Requirement | Origin |
|-------------|--------|
| RF-01..RF-10 | User request (2026-09-25) |
| RNF-01..RNF-06 | User request (2026-09-25) |
| AC-01..AC-06 | User request (2026-09-25) |

---

## 9. Architectural Analysis (Analyze Phase)

**ADR Generado**: [ADR-0007: Bootstrap delega sincronización de dependencias externas en upgrade_framework](../../arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md)

**Analyze Consolidado**: [analyze.md](analyze.md)

**Guardrails Definidos** (8 restricciones obligatorias):
1. Fail-open obligatorio en toda llamada externa
2. No hardcodear URLs en bootstrap (leer del manifest)
3. `-DryRun` debe propagarse y no escribir nada
4. Idempotencia: re-ejecutar no duplica ni rompe
5. Frontera kit ↔ app: NO tocar `Documentacion/<AppName>/`
6. Propagación correcta de flags (`-ForceUpgradeTools`, `-DryRun`, `-SkipSync`)
7. Logging estructurado (INFO/WARN/ERROR)
8. Containment de `proyect_ext/` bajo `<root>/proyect_ext/`

**Spec Linking**: Trazabilidad completa spec ↔ plan ↔ tasks ↔ ADR documentada en `analyze.md` Sección 4.

---

*Generated by speckit-specify for Agent-SSD*  
*Analyzed by `arquitecto` — ADR-0007 + analyze.md creados*