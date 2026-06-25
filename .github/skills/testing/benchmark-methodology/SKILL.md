---
name: benchmark-methodology
description: "Use when: designing benchmark experiments, statistical analysis, or comparing system performance scientifically."
user-invocable: true
---

# Benchmark Methodology

## When to Activate

- Designing benchmark experiments
- Analyzing performance results
- Comparing systems statistically
- Writing performance reports

## Core Concepts

### Methodology

1. **Define metrics** — latency (p50, p95, p99), throughput, error rate
2. **Control variables** — same hardware, same data, same conditions
3. **Warm-up** — discard first N iterations
4. **Multiple runs** — ≥ 10 runs for statistical significance
5. **Statistical analysis** — mean, median, stddev, confidence intervals

### Report Format

```markdown
## Benchmark: API Response Time

| Scenario | p50 | p95 | p99 | Throughput |
|----------|-----|-----|-----|------------|
| Before optimization | 45ms | 120ms | 250ms | 500 req/s |
| After optimization  | 12ms | 30ms  | 60ms  | 2000 req/s |
| Improvement | 73%  | 75%  | 76%  | 300%       |
```

## Best Practices

- Never compare single runs — always use statistical aggregates
- Document ALL conditions (hardware, load, data size)
- Test under realistic load, not just ideal conditions
- Include confidence intervals
- Share raw data for reproducibility
