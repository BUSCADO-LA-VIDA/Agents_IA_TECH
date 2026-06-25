---
name: benchmark-optimization-loop
description: "Use when: doing iterative performance optimization — measure, optimize, measure again."
user-invocable: true
---

# Benchmark Optimization Loop

## When to Activate

- Performance optimization cycles
- Iterative improvements with measurement
- Capacity planning

## Core Concepts

### The Loop

```
Measure → Identify bottleneck → Optimize → Measure again → Compare
```

### Optimization Workflow

1. **Profile** — identify the real bottleneck (don't guess)
2. **Hypothesize** — what change will improve it?
3. **Implement** — make the smallest possible change
4. **Measure** — did it actually improve? By how much?
5. **Decide** — keep, revert, or try something else

## Best Practices

- Always measure before AND after — if it's not measurable, it's not an optimization
- Change ONE variable at a time
- Profile first — the bottleneck is never where you expect
- Optimize for the p95, not the average
- Document every optimization with before/after numbers
