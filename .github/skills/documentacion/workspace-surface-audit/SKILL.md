---
name: workspace-surface-audit
description: "Use when: auditing VS Code workspace setup, checking project configuration, or ensuring dev environment consistency. Design-first: audit before building."
user-invocable: true
---

# Workspace Surface Audit

## Design-First Philosophy

A well-configured workspace is the foundation of productive development. Audit the surface before diving into implementation.

## When to Activate

- Setting up a new development environment
- Auditing existing VS Code configuration
- Standardizing team workspace settings
- Before starting a new project phase

## Core Concepts

### Audit Areas

| Area | What to Check |
|------|---------------|
| Workspace settings | `.vscode/settings.json` |
| Launch configs | `.vscode/launch.json` |
| Task definitions | `.vscode/tasks.json` |
| Extensions | `extensions.json` recommendations |
| Copilot config | `.github/copilot-instructions.md` |
| Prompts | `.github/prompts/*` |

### Design-First Workspace Setup

```
Define dev requirements → Configure workspace → Document setup → Verify → Maintain
```

## Best Practices

- Share workspace config via `.vscode/` in repo
- Recommend extensions via `extensions.json`
- Define tasks for common operations (build, test, lint)
- Keep copilot-instructions.md up to date with project conventions
- Audit workspace config when project requirements change
