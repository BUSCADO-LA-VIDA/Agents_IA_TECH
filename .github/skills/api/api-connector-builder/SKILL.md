---
name: api-connector-builder
description: "Use when: building API clients, SDKs, or connectors for external services."
user-invocable: true
---

# API Connector Builder

## When to Activate

- Writing HTTP clients for external APIs
- Building SDKs or API wrappers
- Implementing retry and circuit breaker patterns

## Core Concepts

### HTTP Client Pattern

```python
import httpx
from typing import Optional


class ApiClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 30):
        self.client = httpx.Client(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
            timeout=timeout,
        )

    def get_users(self, page: int = 1) -> list[dict]:
        response = self.client.get("/users", params={"page": page})
        response.raise_for_status()
        return response.json()["data"]
```

### Retry Pattern

```python
from tenacity import retry, stop_after_attempt, wait_exponential


class ResilientClient:
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
    )
    def fetch(self, url: str) -> dict:
        response = httpx.get(url)
        response.raise_for_status()
        return response.json()
```

## Best Practices

- Use typed clients — never raw HTTP calls scattered
- Implement retry with exponential backoff
- Handle timeouts gracefully
- Log request IDs for debugging
- Use connection pooling for performance
