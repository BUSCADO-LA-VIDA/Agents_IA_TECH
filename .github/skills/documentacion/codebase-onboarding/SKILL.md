---
name: codebase-onboarding
description: "Use when: onboarding to a new project, understanding project structure, or documenting architecture for newcomers. Design-first: understand before coding."
user-invocable: true
---

# Codebase Onboarding

## Design-First Philosophy

Onboarding is about understanding the **design decisions** behind the code. Start with docs, not code.

## When to Activate

- Starting work on a new project
- Understanding a brownfield codebase
- Documenting project structure for new devs
- Before making changes to unfamiliar code

## Core Concepts

### Onboarding Checklist

1. **Read docs first** — README, CONTRIBUTING, ADRs
2. **Trace the architecture** — identify layers, boundaries, patterns
3. **Map the data flow** — entry → processing → storage → response
4. **Run the tests** — understand what's verified
5. **Make a small change** — verify the full cycle

### Documentation to Generate

| Artifact | Purpose |
|----------|---------|
| `docs/architecture.md` | High-level design |
| `docs/data-flow.md` | How data moves through the system |
| `docs/glossary.md` | Domain terms and concepts |
| `docs/decisions.md` | Key ADRs |

## Best Practices

- Don't read every file — trace the critical paths
- Document as you learn — future devs will thank you
- If docs are missing → create them; that IS the documentation task
- Architecture first, then details
