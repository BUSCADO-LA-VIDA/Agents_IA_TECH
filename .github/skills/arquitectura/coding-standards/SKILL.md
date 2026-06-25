---
name: coding-standards
description: "Use when: applying coding standards, code review guidelines, or project conventions across the codebase."
user-invocable: true
---

# Coding Standards

## When to Activate

- Before any code review
- When setting up new projects
- When enforcing code quality
- When onboarding new team members

## Core Concepts

### Universal Rules

| Rule | Standard |
|------|----------|
| Functions | < 50 lines |
| Files | < 400 lines |
| Nesting | ≤ 4 levels |
| Abstractions | Only if needed (YAGNI) |
| Naming | Descriptive, not abbreviated |
| Comments | Explain WHY, not WHAT |

### Code Review Checklist

- [ ] Follows project conventions (naming, structure)
- [ ] No dead code, commented-out code, or debug artifacts
- [ ] Functions do ONE thing
- [ ] No magic numbers — use named constants
- [ ] Error handling at all trust boundaries
- [ ] No hardcoded secrets
- [ ] Tests exist and pass
- [ ] Documentation updated if behavior changed

## Best Practices

- Be boring — simple over clever
- Delete more code than you add
- Prefer standard library over external dependencies
- One abstraction level per function
- Immutable by default — create new objects, don't mutate
- Fail fast — validate early, fail with clear messages
