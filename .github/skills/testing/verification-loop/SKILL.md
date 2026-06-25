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
