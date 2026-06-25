---
name: code-tour
description: "Use when: generating code tours, onboarding walkthroughs, or creating step-by-step explanations of the codebase. Follows design-first: document before coding."
user-invocable: true
---

# Code Tour

## Design-First Philosophy

Code tours document the **why** and **how** of the codebase. Create them as part of the design phase, not as an afterthought.

## When to Activate

- Onboarding new team members
- Documenting complex feature flows
- Creating walkthroughs for code reviews
- Mapping out a feature before implementation

## Core Concepts

### Tour Structure

```
docs/tours/
├── 00-overview.md         # High-level architecture
├── 01-getting-started.md  # Dev setup + first feature
├── 02-core-flow.md        # Main business flow
└── 03-deployment.md       # How it ships
```

### Design-First Tour Creation

1. **Map the flow** (design) — identify entry points, data flow, decisions
2. **Write the tour** (document) — step-by-step with code references
3. **Validate** — someone unfamiliar should understand the codebase from the tour
4. **Keep updated** — when code changes, update the tour first

## Best Practices

- Each step should have a clear starting point (file:line)
- Include "why" explanations, not just "what"
- Link to ADRs for architectural decisions
- Use before/after examples for complex changes
