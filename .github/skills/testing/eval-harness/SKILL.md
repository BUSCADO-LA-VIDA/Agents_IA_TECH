---
name: eval-harness
description: "Use when: setting up evaluation frameworks, running model evaluations, or building test harnesses for AI systems."
user-invocable: true
---

# Evaluation Harness

## When to Activate

- Setting up automated evaluation pipelines
- Running model evaluations
- Building test harnesses
- Comparing model versions

## Core Concepts

### Harness Structure

```
eval-harness/
├── datasets/
│   ├── golden.json       # Expected outputs
│   └── edge-cases.json   # Edge case tests
├── metrics/
│   ├── accuracy.py
│   └── latency.py
├── runners/
│   ├── local.py
│   └── ci.py
├── results/
└── config.yaml
```

## Best Practices

- Automate eval runs in CI
- Version control evaluation datasets
- Set baseline metrics and alert on regression
- Document evaluation methodology
- Use consistent random seeds for reproducibility
