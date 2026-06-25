---
name: repo-scan
description: "Use when: auditing repository structure, analyzing codebase health, or identifying documentation gaps. Design-first: understand structure before changing it."
user-invocable: true
---

# Repository Scan

## Design-First Philosophy

Before changing a codebase, scan and understand its structure. Document what exists before deciding what to modify.

## When to Activate

- Starting work on an existing project
- Auditing code quality or coverage
- Identifying dead code or outdated docs
- Pre-refactoring analysis
- Finding undocumented areas

## Core Concepts

### Scan Checklist

- [ ] Project structure (directories, modules)
- [ ] Dependencies and their versions
- [ ] Configuration files and environment variables
- [ ] Documentation coverage (what's missing?)
- [ ] Test coverage (what's untested?)
- [ ] Dead code candidates
- [ ] Security-sensitive areas

### Design-First Scan Flow

```
Scan → Document findings → Design changes → Update specs → Code → Test
```

## Best Practices

- Generate a REPO-SCAN.md report at project root
- Track findings as GitHub Issues
- Prioritize: Security → Data integrity → Functionality → Docs
- If documentation is missing → create it (fill the gap)
