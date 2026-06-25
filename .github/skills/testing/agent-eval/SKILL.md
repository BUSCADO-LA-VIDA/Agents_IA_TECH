---
name: agent-eval
description: "Use when: evaluating AI agent performance, testing agent outputs, or creating evaluation datasets."
user-invocable: true
---

# Agent Evaluation

## When to Activate

- Testing AI agent responses
- Creating evaluation datasets
- Measuring agent accuracy
- A/B testing agent configurations

## Core Concepts

### Evaluation Framework

| Metric | What it measures |
|--------|-----------------|
| Accuracy | Correct outputs / total outputs |
| Precision | True positives / (true + false positives) |
| Recall | True positives / (true + false negatives) |
| F1 Score | Harmonic mean of precision and recall |
| Latency | Time to first token, total time |

### Test Dataset

```json
[
  {
    "input": "What is the user's email?",
    "expected": "user@test.com",
    "tools_required": ["search_users"]
  }
]
```

## Best Practices

- Create golden test datasets with expected outputs
- Test edge cases (empty inputs, ambiguous queries)
- Measure both accuracy AND latency
- Log all agent decisions for audit
- Continuously update evaluation datasets
