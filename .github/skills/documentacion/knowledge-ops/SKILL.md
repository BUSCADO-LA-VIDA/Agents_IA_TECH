---
name: knowledge-ops
description: "Use when: organizing project knowledge, maintaining docs structure, or setting up knowledge management workflows. Design-first: knowledge architecture before content."
user-invocable: true
---

# Knowledge Operations

## Design-First Philosophy

Design the knowledge structure BEFORE creating content. A well-organized knowledge base prevents duplication and makes information discoverable.

## When to Activate

- Setting up documentation structure for a new project
- Reorganizing existing documentation
- Creating cross-reference systems
- Establishing documentation conventions

## Core Concepts

### Knowledge Structure

```
docs/
├── adr/              # Architecture Decision Records
├── guides/           # How-to guides
├── explanations/     # Deep dives and concepts
├── reference/        # API docs, configs, specs
├── tutorials/        # Step-by-step learning
├── glossary.md       # Domain terms
└── SUMMARY.md        # Index of all docs
```

### Design-First Docs Process

```
Specification (docs/specs/)
  → Design (docs/adr/)
    → Implementation (code + inline docs)
      → Tests (docs verified)
        → Fix specs if test fails
```

## Best Practices

- Documentation is code — review it, version it, test it
- Cross-link related documents
- Keep a single source of truth — no duplication
- Update docs when the code changes (or before)
- Use `docs/README.md` as entry point
