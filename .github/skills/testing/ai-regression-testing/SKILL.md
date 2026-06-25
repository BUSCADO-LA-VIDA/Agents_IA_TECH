---
name: ai-regression-testing
description: "Use when: testing AI model outputs for regressions, comparing model versions, or ensuring consistent AI behavior."
user-invocable: true
---

# AI Regression Testing

## When to Activate

- Testing AI model updates for regressions
- Comparing model version outputs
- Ensuring consistent AI behavior
- Validating prompt changes

## Core Concepts

### Regression Test Pattern

```python
REGRESSION_TESTS = [
    {
        "prompt": "Summarize: The quick brown fox jumps over the lazy dog.",
        "expected_terms": ["fox", "dog", "jumps"],
        "min_length": 10,
        "max_length": 100,
    },
]


def test_model_regression(model):
    for test in REGRESSION_TESTS:
        output = model.generate(test["prompt"])
        for term in test["expected_terms"]:
            assert term in output, f"Missing term: {term}"
        assert test["min_length"] <= len(output) <= test["max_length"]
```

## Best Practices

- Version control golden test outputs
- Run regression tests before every deployment
- Track output differences across versions
- Set thresholds for acceptable change
- Review regression failures manually
- Maintain a diverse test dataset
