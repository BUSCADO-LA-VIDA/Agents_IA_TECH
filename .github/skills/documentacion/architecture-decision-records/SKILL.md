---
name: architecture-decision-records
description: "Use when: making architectural decisions, recording design choices, or evaluating alternatives. Design-first: ADR before implementation."
user-invocable: true
---

# Architecture Decision Records (ADR)

## Design-First Philosophy

**ADR before code.** Every significant architectural decision MUST be documented before implementation begins. If the implementation reveals flaws, update the ADR.

## When to Activate

- Choosing between technologies or patterns
- Defining project structure
- Making API design decisions
- Changing existing architecture
- After a failed test reveals a design gap — update ADR first

## Core Concepts

### ADR Format (YALC — Yet Another Lightweight Convention)

```markdown
# ADR-{NNN}: {Title}

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** {YYYY-MM-DD}
**Designer:** {name}

## Context
What problem are we solving? What constraints exist?

## Decision
What did we decide?

## Consequences
What tradeoffs, risks, and benefits does this bring?

## Alternatives Considered
What else was evaluated and why was it rejected?

## Validation
How will we verify this decision was correct? (tests, benchmarks, etc.)
```

### ADR Workflow

```
Design → Write ADR → Review → Accept → Implement → Test → Update ADR if needed
```

## Best Practices

- One ADR per significant decision
- Store in `docs/adr/` with sequential numbering
- Link ADRs from code comments: `// See ADR-042`
- ADRs can be superseded — keep history
- If implementation contradicts the ADR → update the ADR (the doc is truth)
