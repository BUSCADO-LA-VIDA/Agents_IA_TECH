---
name: gateguard
description: "Use when: implementing approval gates, CI/CD quality gates, or deployment checkpoints."
user-invocable: true
---

# GateGuard

## When to Activate

- When setting up CI/CD pipelines
- When defining quality gates for deployments
- When implementing approval workflows
- When enforcing policies before promotions (dev → staging → prod)

## Core Concepts

### Gate Types

| Gate | Check | Action on Fail |
|------|-------|----------------|
| Code Review | At least 1 approval | Block merge |
| Tests | All tests pass | Block merge |
| Security Scan | No CVEs critical | Block deployment |
| Coverage | Min 80% | Warning |
| Linting | No errors | Block merge |
| Performance | Benchmarks pass | Block promotion |

### Deployment Pipeline

```
PR → Code Review → Tests → Security Scan → Staging → Approval → Production
    └── Gate ──┘   └── Gate ──┘   └── Gate ──┘           └── Gate ──┘
```

## Best Practices

- Gates should be automated — no manual steps
- Fail fast — check the cheapest gates first
- Allow emergency bypass with audit trail
- Monitor gate metrics — too many failures = process problem
- Document gate exceptions and why they were granted
