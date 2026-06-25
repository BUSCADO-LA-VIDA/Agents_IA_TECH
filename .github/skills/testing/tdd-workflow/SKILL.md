---
name: tdd-workflow
description: "Use when: doing TDD cycle, writing tests first, implementing minimally, and refactoring. RED → GREEN → IMPROVE."
user-invocable: true
---

# TDD Workflow

## When to Activate

- Starting a new feature
- Fixing a bug (write test that reproduces it first)
- Adding new functionality
- Any coding task where tests don't exist yet

## Core Concepts

### The TDD Cycle

```
┌─────────────────────────────────────────────────┐
│  🔴 RED                                         │
│  Write a failing test that describes the desired │
│  behavior. Run it → it fails (because no code).  │
├─────────────────────────────────────────────────┤
│  🟢 GREEN                                        │
│  Write the MINIMUM code to make the test pass.   │
│  No refactoring. No extra features.              │
├─────────────────────────────────────────────────┤
│  🔵 IMPROVE                                      │
│  Refactor: improve code quality, remove         │
│  duplication, while tests stay green.           │
└─────────────────────────────────────────────────┘
```

### AAA Pattern

```python
def test_calculate_total():
    # Arrange
    items = [Item(price=10), Item(price=20)]
    cart = Cart(items)

    # Act
    total = cart.calculate_total()

    # Assert
    assert total == 30
```

## Best Practices

- RED → GREEN → IMPROVE. Strict order. No cheating.
- Write the MINIMUM code to pass the test — nothing more
- Refactor only in IMPROVE phase, never in GREEN
- Tests are documentation — they describe what the code should do
- One assertion per test when possible
- Test behavior, not implementation
- If a test is hard to write, the design might be wrong
