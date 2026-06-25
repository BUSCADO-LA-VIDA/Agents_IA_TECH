---
name: documentation-lookup
description: "Use when: searching docs, reading API references, understanding existing code, or needing to trace specs before coding. Design-first approach: consult docs before writing code."
user-invocable: true
---

# Documentation Lookup

## Design-First Philosophy

Before writing ANY code:
1. **Research** — understand the domain, existing patterns, and constraints
2. **Document** — write/update the spec or ADR
3. **Code** — implement against the spec
4. **Test** — verify against the spec
5. **Fix docs** — if something changed, update docs FIRST

## When to Activate

- Searching for API documentation or library usage
- Understanding existing codebase patterns
- Looking up configuration references
- Before implementing a new feature — consult existing docs
- When a test fails — check if the spec needs updating before fixing code

## Core Concepts

### Documentation Sources (in priority order)

| Source | When |
|--------|------|
| Project docs (`.md`, `docs/`) | Always consult first |
| ADRs (`docs/adr/`) | Architecture decisions |
| Inline code comments | Implementation details |
| README / CONTRIBUTING | Project conventions |
| Official library docs | External dependencies |

### Design-First Workflow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Design   │────▶│ Document │────▶│  Code    │────▶│  Test    │────▶│ Fix Docs │
│ (pensar)  │     │ (espec)  │     │ (impl)   │     │ (verify) │     │ (si falla)│
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
                                                          │
                                                          ▼
                                                   ┌──────────┐
                                                   │ ¿Falla?  │────▶ Fix spec first
                                                   └──────────┘
```

## Best Practices

- Search project docs **before** writing new code
- If docs don't exist for what you're building → create them as you go
- Keep a `docs/` index or SUMMARY.md for discoverability
- Use ADRs to record why decisions were made, not just what
- When a test reveals a missing case → update the spec, then the code
