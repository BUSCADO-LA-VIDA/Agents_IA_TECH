---
name: error-handling
description: "Use when: implementing error handling strategies, exception patterns, logging, or retry logic."
user-invocable: true
---

# Error Handling

## When to Activate

- Designing error handling strategies
- Implementing exception handling
- Setting up logging and monitoring
- Creating user-friendly error messages

## Core Concepts

### Error Handling Layers

```
UI Layer        → User-friendly messages
Service Layer   → Business exceptions → meaningful errors
Infrastructure  → Technical exceptions → logged, not exposed
```

### Result Pattern

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E")


@dataclass(frozen=True)
class Result(Generic[T, E]):
    value: T | None = None
    error: E | None = None

    @property
    def is_ok(self) -> bool:
        return self.error is None

    @classmethod
    def ok(cls, value: T) -> "Result[T, E]":
        return cls(value=value)

    @classmethod
    def fail(cls, error: E) -> "Result[T, E]":
        return cls(error=error)
```

### Logging Pattern

```python
import logging

logger = logging.getLogger(__name__)


def process_order(order_id: int) -> None:
    try:
        order = fetch_order(order_id)
        process_payment(order)
        logger.info("Order %d processed successfully", order_id)
    except PaymentError as e:
        logger.error("Payment failed for order %d: %s", order_id, e)
        raise  # Re-raise for upper layer to handle
    except Exception:
        logger.exception("Unexpected error processing order %d", order_id)
        raise
```

## Best Practices

- Never expose stack traces to users
- Log exceptions with context (order_id, user_id, etc.)
- Use Result type instead of exceptions for expected failures
- Always have a catch-all at the top level
- Add correlation IDs for request tracing
- Use structured logging (JSON)
- Handle errors at the boundary, not everywhere
