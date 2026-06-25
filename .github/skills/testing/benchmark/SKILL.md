---
name: benchmark
description: "Use when: benchmarking code performance, measuring execution time, or comparing implementations."
user-invocable: true
---

# Benchmark

## When to Activate

- Measuring code performance
- Comparing implementation alternatives
- Before/after optimization comparisons
- Setting performance baselines

## Core Concepts

### Python Benchmark

```python
import time
from functools import wraps


def benchmark(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__}: {elapsed*1000:.2f}ms")
        return result
    return wrapper


@benchmark
def process_data():
    return [i**2 for i in range(100_000)]
```

## Best Practices

- Run benchmarks multiple times and average
- Warm up before measuring (JIT, cache effects)
- Test with realistic data sizes
- Document benchmark environment (CPU, RAM, OS)
- Use dedicated tools (pytest-benchmark, k6 for APIs)
