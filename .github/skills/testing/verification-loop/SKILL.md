---
name: verification-loop
description: "Use when: running build-verify loops, checking code quality, linting, type checking, and running tests."
user-invocable: true
---

# Verification Loop

## When to Activate

- Before committing code
- After making changes
- When debugging CI failures
- Running quality checks

## Core Concepts

### Verification Pipeline

```
1. Lint (ruff, ESLint)         → fail fast
2. Type check (mypy, TypeScript) → catch type errors
3. Unit tests                  → verify logic
4. Integration tests           → verify components
5. Build                       → verify packaging
6. E2E tests                   → verify user flows
```

### Pre-commit Hook Pattern

```yaml
# .github/hooks/pre-commit.json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "npx eslint src/ && npm run typecheck && npm test -- --changed"
      }
    ]
  }
}
```

## Best Practices

- Fail fast — run cheapest checks first (lint → types → unit → integration → E2E)
- Use pre-commit hooks for instant feedback
- Run full verification in CI
- Never bypass verification with --no-verify

---

## Profundidad ECC (integrada b92f181b, 2026-10-16)

> Fuente: proyect_ext/ECC/skills/verification-loop/SKILL.md (cache de descarga, no se sincroniza). Contenido copiado al KIT: viaja en git a los demas proyectos.

---
name: verification-loop
description: Run a six-phase verification of a Claude Code session's work — build, type check, lint, tests with coverage, security grep, and diff review — then produce a PASS/FAIL verification report. Use when verifying work after completing a feature or refactor, before creating a PR, or when quality gates must pass.
license: MIT
metadata:
  origin: ECC
---

# Verification Loop Skill

A comprehensive verification system for Claude Code sessions.

## When to Use

Invoke this skill:
- After completing a feature or significant code change
- Before creating a PR
- When you want to ensure quality gates pass
- After refactoring

## Verification Phases

### Phase 1: Build Verification
```bash
set -o pipefail  # report the build's exit status, not tail's
# Check if project builds
npm run build 2>&1 | tail -20
# OR
pnpm build 2>&1 | tail -20
```

If build fails, STOP and fix before continuing.

### Phase 2: Type Check
```bash
set -o pipefail
# TypeScript projects
npx --no-install tsc --noEmit 2>&1 | sed -n '1,30p'

# Python projects
pyright . 2>&1 | sed -n '1,30p'
```

Report all type errors. Fix critical ones before continuing.

### Phase 3: Lint Check

Use `sed` to limit displayed output while consuming the whole stream. This keeps a
successful linter from failing on SIGPIPE when `pipefail` is enabled.
```bash
set -o pipefail
# JavaScript/TypeScript
npm run lint 2>&1 | sed -n '1,30p'

# Python
ruff check . 2>&1 | sed -n '1,30p'
```

### Phase 4: Test Suite
```bash
set -o pipefail
# Run tests with coverage
npm run test -- --coverage 2>&1 | tail -50

# Check coverage threshold
# Target: 80% minimum
```

Report:
- Total tests: X
- Passed: X
- Failed: X
- Coverage: X%

### Phase 5: Security Scan
```bash
# Check for secrets
grep -rn "sk-" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "api_key" --include="*.ts" --include="*.js" . 2>/dev/null | head -10

# Check for console.log
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10
```

### Phase 6: Diff Review
```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

Review each changed file for:
- Unintended changes
- Missing error handling
- Potential edge cases

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Continuous Mode

For long sessions, run verification every 15 minutes or after major changes:

```markdown
Set a mental checkpoint:
- After completing each function
- After finishing a component
- Before moving to next task

Run: /verify
```

## Integration with Hooks

This skill complements PostToolUse hooks but provides deeper verification.
Hooks catch issues immediately; this skill provides comprehensive review.
