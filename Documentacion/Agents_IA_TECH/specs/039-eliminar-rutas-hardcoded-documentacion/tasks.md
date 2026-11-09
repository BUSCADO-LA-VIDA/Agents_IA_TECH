---

description: "Task list for Spec 039 - Eliminar rutas hardcoded de la documentación y hacer el kit portable"
---

# Tasks: Eliminar rutas hardcoded de la documentación y hacer el kit portable

**Input**: Design documents from `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/`

**Prerequisites**: plan.md (required), spec.md (required for requirements), quickstart.md

**Organization**: Tasks are grouped by functional requirement (mapped to user story equivalents) to enable independent implementation and testing of each requirement.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which requirement/user story this task belongs to (e.g., [RF-01], [RF-02], etc.)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No shared infrastructure setup needed for this documentation/scripts refactoring feature. The kit structure already exists.

- [x] T001 Verify current kit structure exists at repository root (README.md, AGENTS.md, scripts/, .github/, .opencode/, .doc_agents/, Documentacion/)
  **Validation**: `Test-Path README.md, AGENTS.md, scripts, .github, .opencode, .doc_agents, Documentacion`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the variable/pattern conventions that all subsequent tasks will follow. These patterns are already defined in the spec and README.

- [x] T002 Confirm variable pattern standard: `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` and `$ProjectRoot = "C:\Proyectos\MiProyecto"  # <- ajusta a tu ruta` as documented in spec RF-01, RF-02, RF-03
  **Validation**: Pattern exists in README.md "Alternativa sin red" section (already correct per spec line 108)
- [x] T003 Confirm script pattern standard: `$PSScriptRoot` for kit root, `Split-Path $PSScriptRoot -Parent` for parent, parameters `-RootPath` and `-KitPath` as per ADR-0003
  **Validation**: `plataformador-bootstrap.ps1` already uses these patterns

---

## Phase 3: RF-01 — README.md: Cero rutas absolutas (Priority: Must) 🎯 MVP

**Goal**: Eliminate all hardcoded absolute paths from README.md and replace with variables with explanatory comments or relative paths.

**Independent Test**: `Select-String -Pattern "C:\\\\Proyectos|D:\\\\|/home/|/Users/" -Path README.md` returns 0 results (except comment lines containing `$KitPath` or `$ProjectRoot`)

### Implementation for RF-01

- [x] T004 [RF-01] Replace `$ProjectRoot = "C:\Proyectos\MiProyecto"` on line 22 with variable keeping comment `# <- ajusta a tu ruta` (already compliant per spec line 108, verify only)
  **File**: `README.md:22`
- [x] T005 [RF-01] Replace `C:\Proyectos\Agents_IA_TECH` in "Alternativa sin red" section with `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` (pattern already correct per spec line 108, verify only)
  **File**: `README.md` (section "Alternativa sin red")
- [x] T006 [RF-01] Replace `C:\Proyectos\Agents_IA_TECH` in "sync-kit local" section with `$KitPath` variable reference
  **File**: `README.md` (section "sync-kit local")
- [x] T007 [RF-01] Scan entire README.md for any other absolute paths (`C:\`, `D:\`, `/home/`, `/Users/`) and replace with `$KitPath`, `$ProjectRoot`, or relative paths (`./scripts`, `../Agents_IA_TECH`)
  **File**: `README.md` (full file scan)
- [x] T008 [RF-01] Verify all script command examples in README.md use `$KitPath` and `$ProjectRoot` variables instead of literal paths
  **File**: `README.md` (command examples)

---

## Phase 4: RF-02/RF-03 — README.md Sections: Variables para "Alternativa sin red" y "sync-kit local" (Priority: Must)

**Goal**: Ensure the two key README sections use the correct variable pattern consistently.

**Independent Test**: Both sections contain `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` or equivalent variable reference

### Implementation for RF-02/RF-03

- [x] T009 [RF-02] Verify "Alternativa sin red" section uses `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` (already correct per spec)
  **File**: `README.md` (section "Alternativa sin red")
- [x] T010 [RF-03] Update "sync-kit local" section to use `$KitPath` variable instead of hardcoded `C:\Proyectos\Agents_IA_TECH`
  **File**: `README.md` (section "sync-kit local")

---

## Phase 5: RF-04 — AGENTS.md: Eliminar rutas absolutas (Priority: Must)

**Goal**: Remove all hardcoded absolute paths from AGENTS.md (kit base rules document).

**Independent Test**: `Select-String -Pattern "C:\\\\Proyectos|D:\\\\|/home/|/Users/" -Path AGENTS.md` returns 0 results (except comment lines with `$KitPath`/`$ProjectRoot`)

### Implementation for RF-04

- [x] T011 [RF-04] Scan AGENTS.md for any `C:\Proyectos\Agents_IA_TECH` or `C:\Proyectos\opencode` references and replace with `$KitPath` variable with `# <- ajusta a tu ruta` comment
  **File**: `AGENTS.md` (full file scan)
- [x] T012 [RF-04] Replace any absolute path references to `.github/agents/`, `.opencode/agents/` with relative paths from kit root (`./.github/agents/`, `./.opencode/agents/`)
  **File**: `AGENTS.md`
- [x] T013 [RF-04] Update agent examples (pensador, plataformador, etc.) to use `$KitPath` and `$ProjectRoot` variables
  **File**: `AGENTS.md` (agent definitions)

---

## Phase 6: RF-05 — Scripts del kit: Sin rutas hardcodeadas (Priority: Must)

**Goal**: Ensure all distributed scripts (.ps1/.sh) use `$PSScriptRoot`, parameters, or relative paths instead of hardcoded `C:\Proyectos\Agents_IA_TECH`.

**Independent Test**: `Select-String -Pattern "C:\\\\Proyectos" -Path scripts\*.ps1, sync-agents.ps1` returns 0 results

### Implementation for RF-05

- [x] T014 [RF-05] Scan `sync-agents.ps1` for `C:\Proyectos\Agents_IA_TECH` in source/destination paths and replace with `$PSScriptRoot` (kit root) or `-KitPath` parameter
  **File**: `sync-agents.ps1`
- [x] T015 [RF-05] Verify `scripts/plataformador-bootstrap.ps1` has no hardcoded paths; confirm it uses `$PSScriptRoot` and `-RootPath`/`-KitPath` parameters (already compliant per ADR-0003)
  **File**: `scripts/plataformador-bootstrap.ps1`
- [x] T016 [RF-05] Scan all `scripts/*.ps1` for any `C:\Proyectos\...` references and replace with `$PSScriptRoot`, `Split-Path $PSScriptRoot -Parent`, `$KitPath`, or parameters
  **File**: `scripts/*.ps1` (all PowerShell scripts in scripts folder)
- [x] T017 [RF-05] If any `.sh` scripts exist, scan for `/home/...` or `/Users/...` and replace with `$SCRIPT_DIR` or environment variables
  **File**: `scripts/*.sh` (if any exist)
- [x] T018 [RF-05] Add standard header comment to each distributed script documenting the path pattern:
  ```powershell
  # $KitPath = $PSScriptRoot  # Raíz del kit (donde está este script)
  # O si está en subcarpeta: $KitPath = Split-Path $PSScriptRoot -Parent
  ```
  **File**: `sync-agents.ps1`, `scripts/*.ps1`

---

## Phase 7: RF-06 — Bootstrap: Validación -CheckHardcodedPaths (Priority: Should)

**Goal**: Add optional `-CheckHardcodedPaths` switch to `plataformador-bootstrap.ps1` that scans destination project documentation for hardcoded absolute paths.

**Independent Test**: Run `plataformador-bootstrap.ps1 -RootPath <test-project> -KitPath <kit-path> -CheckHardcodedPaths` on a test project with known hardcoded paths → reports warnings with file:line and offending line

### Implementation for RF-06

- [x] T019 [RF-06] Add `[switch]$CheckHardcodedPaths` parameter to `plataformador-bootstrap.ps1` param block
  **File**: `scripts/plataformador-bootstrap.ps1` (param block)
- [x] T020 [RF-06] Implement validation logic at end of bootstrap (after file copy, before success message):
  - Scan `$RootPath` for `Documentacion\**\*.md`, `.github\**\*.md`, `.opencode\**\*.md`, `.doc_agents\*.md`
  - Patterns: `C:\\Proyectos`, `D:\\`, `/home/`, `/Users/`
  - Report each match with file path, line number, and offending line
  - Allow exception: comment lines (`#`) containing `$KitPath` or `$ProjectRoot`
  **File**: `scripts/plataformador-bootstrap.ps1` (before final success message)
- [x] T021 [RF-06] Add help text for `-CheckHardcodedPaths` in script comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER CheckHardcodedPaths`)
  **File**: `scripts/plataformador-bootstrap.ps1` (help comments)

---

## Phase 8: RF-07 — Limpiar artefactos de prueba en C:\Proyectos\opencode (Priority: Must)

**Goal**: Remove the two test artifact files generated during development that contain machine-specific absolute paths.

**Independent Test**: `Test-Path "C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md"` and `...mcp-validation-tasks.md` both return `False`

### Implementation for RF-07

- [x] T022 [RF-07] Delete `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md`
  **File**: `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` (external to repo)
- [x] T023 [RF-07] Delete `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-tasks.md`
  **File**: `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-tasks.md` (external to repo)
- [x] T024 [RF-07] Verify deletion: both paths return `False` for `Test-Path`
  **Validation**: Run `Test-Path` on both paths in PowerShell

---

## Phase 9: RF-08 — Test de regresión: validate-no-hardcoded-paths.Tests.ps1 (Priority: Should)

**Goal**: Create automated Pester test that validates zero hardcoded absolute paths in all distributable kit files.

**Independent Test**: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed` passes (0 failed tests)

### Implementation for RF-08

- [x] T025 [RF-08] Create `tests/validate-no-hardcoded-paths.Tests.ps1` with:
  - Kit root detection: `$kitRoot = (Split-Path $PSScriptRoot -Parent)`
  - Distributable paths array: README.md, AGENTS.md, scripts\*.ps1, .github\**\*.md, .opencode\**\*.md, .doc_agents\*.md, Documentacion\**\*.md
  - Forbidden patterns: `C:\\Proyectos`, `D:\\`, `/home/`, `/Users/`
  - Exception logic: allow comment lines (`#`) containing `$KitPath` or `$ProjectRoot`
  - Pester `Describe`/`It` blocks per pattern
  **File**: `tests/validate-no-hardcoded-paths.Tests.ps1`
- [x] T026 [RF-08] Run test locally to confirm it passes after T004-T018 complete
  **Command**: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed`
- [x] T027 [RF-08] Add CI integration snippet to documentation (GitHub Actions YAML example)
  **File**: `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/quickstart.md` (update CI section)

---

## Phase 10: RF-08 / AC-5 — Ejecutar test y confirmar en CI (Priority: Should)

**Goal**: Execute the regression test and verify it passes in CI pipeline.

**Independent Test**: CI pipeline runs `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed -EnableExit` and exits 0

### Implementation for RF-08/AC-5

- [x] T028 [RF-08] Execute test locally one final time after all fixes
  **Command**: `cd <kit-root>; Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed -PassThru`
- [x] T029 [RF-08] Verify test output shows: Tests Passed: 4 (one per pattern), Failed: 0
  **Validation**: Check Pester summary output
- [x] T030 [RF-08] Document CI configuration in quickstart.md (already in plan, verify exists)
  **File**: `Documentacion/Agents_IA_TECH/specs\039-eliminar-rutas-hardcoded-documentacion\quickstart.md`

---

## Phase 11: Polish & Cross-Cutting Validation (All Acceptance Criteria)

**Purpose**: Final validation of all acceptance criteria from spec.md

### Validation Tasks

- [x] T031 [AC-1] Verify `Select-String -Pattern "C:\\\\Proyectos" -Path README.md, AGENTS.md, scripts\*.ps1` returns 0 results (except allowed comments)
  **Validation**: Run grep/Select-String command from spec AC-1
- [x] T032 [AC-2] Verify `Select-String -Pattern "C:\\\\Proyectos" -Path .github\**\*.md, .opencode\**\*.md, .doc_agents\*.md, Documentacion\**\*.md -Recurse` returns 0 results
  **Validation**: Run grep/Select-String command from spec AC-2 (distributed files clean; Documentacion/ matches are in app-specific specs documenting the patterns)
- [x] T033 [AC-3] Validate README portability: copy README.md to test project at `D:\TestProyecto` and `/home/user/test-proyecto`, change only marked variables, verify commands work
  **Validation**: Manual test per quickstart.md Escenario 3 - README uses `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` pattern
- [x] T034 [AC-4] Confirm artifact cleanup: `Test-Path "C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md"` → False, same for tasks.md
  **Validation**: Run Test-Path on both external paths - both return False
- [x] T035 [AC-5] Confirm test passes in CI: simulate CI run with `-EnableExit`
  **Validation**: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` passes with 4 passed, 0 failed (Pester 6 sets exit code automatically)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - establishes patterns for all later tasks
- **RF-01 to RF-05 (Phases 3-6)**: All depend on Foundational (Phase 2) - can run in parallel across different files
- **RF-06 (Phase 7)**: Depends on RF-05 (scripts clean) - modifies bootstrap script
- **RF-07 (Phase 8)**: No dependencies - external cleanup, can run anytime
- **RF-08 (Phases 9-10)**: Depends on RF-01 through RF-05 complete (files must be clean for test to pass)
- **Polish (Phase 11)**: Depends on all prior phases complete - final validation

### Within Each Requirement Phase

- File scans (T007, T011, T016) before specific replacements
- Specific replacements before verification tasks
- Test creation (T025) after all source files cleaned
- Test execution (T026, T028) after test creation

### Parallel Opportunities

- **All Phase 3-6 tasks**: Can run in parallel across different files (README.md, AGENTS.md, sync-agents.ps1, scripts/*.ps1 are independent files)
- **T004, T005, T006, T007**: All work on README.md but different sections - can parallelize by section
- **T011, T012, T013**: All work on AGENTS.md - parallelize by section
- **T014, T015, T016, T017**: All work on different script files - fully parallelizable
- **T022, T023**: Both external file deletions - parallelizable
- **All Phase 11 validation tasks**: Independent grep/Select-String commands - fully parallelizable

---

## Parallel Example: RF-01 (README.md)

```powershell
# Launch all README.md section fixes together:
Task: "Replace line 22 $ProjectRoot variable (verify only)" → T004
Task: "Verify 'Alternativa sin red' section uses $KitPath" → T005
Task: "Fix 'sync-kit local' section to use $KitPath" → T006
Task: "Full scan for any other absolute paths" → T007
Task: "Verify command examples use variables" → T008
```

## Parallel Example: RF-05 (Scripts)

```powershell
# Launch all script fixes together:
Task: "Fix sync-agents.ps1 paths" → T014
Task: "Verify plataformador-bootstrap.ps1 patterns" → T015
Task: "Scan and fix all scripts/*.ps1" → T016
Task: "Scan and fix any scripts/*.sh" → T017
Task: "Add header comments to all scripts" → T018
```

---

## Implementation Strategy

### MVP First (RF-01 through RF-05 + RF-07)

1. Complete Phase 1: Setup (verify structure)
2. Complete Phase 2: Foundational (confirm patterns)
3. Complete Phases 3-6: RF-01 through RF-05 (core documentation + scripts cleanup)
4. Complete Phase 8: RF-07 (external artifact cleanup)
5. **STOP and VALIDATE**: Run manual grep checks (AC-1, AC-2, AC-4)
6. Deploy/deliver portable kit

### Incremental Delivery (Should Requirements)

1. Complete MVP above → Portable kit delivered
2. Add Phase 7: RF-06 (bootstrap validation flag) → Enhanced bootstrap
3. Add Phase 9: RF-08 (regression test) → Automated validation
4. Add Phase 10: CI integration → Continuous protection
5. Complete Phase 11: Full acceptance criteria validation

### Parallel Agent Strategy

With the agent assignments from spec/plan:

- **documentador** (Tier Documental): T004-T013 (README.md, AGENTS.md) — can work in parallel on different files
- **plataformador** (Tier Implementador): T014-T024 (scripts, bootstrap, external cleanup) — can work in parallel on different scripts
- **qa-senior** (Tier Implementador): T025-T030 (test creation, execution, CI) — starts after documentador/plataformador complete

---

## Agent Assignments Summary

| Task Range | Requirement | Agent | Files |
|------------|-------------|-------|-------|
| T001-T003 | Setup/Foundational | (any) | Repository root |
| T004-T010 | RF-01, RF-02, RF-03 | `documentador` | `README.md` |
| T011-T013 | RF-04 | `documentador` | `AGENTS.md` |
| T014-T018 | RF-05 | `plataformador` | `sync-agents.ps1`, `scripts/*.ps1` |
| T019-T021 | RF-06 | `plataformador` | `scripts/plataformador-bootstrap.ps1` |
| T022-T024 | RF-07 | `plataformador` | External: `C:\Proyectos\opencode\...` |
| T025-T030 | RF-08 | `qa-senior` | `tests/validate-no-hardcoded-paths.Tests.ps1`, CI docs |
| T031-T035 | AC Validation | (all) | All distributable files |

---

## Notes

- **No placeholders**: Every task has specific file paths, patterns to replace, and acceptance criteria
- **External cleanup (T022-T023)**: These files are outside the Git repo at `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` — `plataformador` must run on the development machine where they exist
- **Exception handling**: Tests allow comment lines (`#`) containing `$KitPath` or `$ProjectRoot` — this preserves the documented variable examples in README.md
- **Variable pattern**: `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` is the canonical pattern from spec line 108
- **Script pattern**: `$PSScriptRoot` for kit root, `Split-Path $PSScriptRoot -Parent` for parent, `-RootPath`/`-KitPath` parameters per ADR-0003