---
name: python-patterns
description: "Use when: writing Python code, applying Python idioms, or reviewing Python projects. Best practices, typing, project structure."
user-invocable: true
---

# Python Patterns

## When to Activate

- Writing new Python modules or scripts
- Reviewing Python code for best practices
- Setting up Python project structure
- Debugging Python performance issues

## Core Concepts

### Project Structure

```
project/
├── src/
│   └── project/
│       ├── __init__.py
│       ├── main.py
│       ├── domain/       # Business logic
│       ├── application/  # Use cases / services
│       ├── infrastructure/ # DB, external APIs
│       └── interfaces/   # Controllers, serializers
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── pyproject.toml
└── README.md
```

### Pythonic Code

```python
# ✅ Typed, clean, explicit
from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class User:
    id: int
    name: str
    email: str
    is_active: bool = True


def get_active_users(users: list[User]) -> list[User]:
    return [u for u in users if u.is_active]
```

### Config Pattern

```python
# config.py — single source of truth
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False
    allowed_hosts: list[str] = ["*"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
```

## Best Practices

- Use type hints everywhere — enable strict mypy/pyright
- Prefer dataclasses over dicts for structured data
- Use pathlib over os.path
- Use context managers (with) for resources
- Use pyproject.toml — setup.py is legacy
- Keep functions < 50 lines, files < 400 lines
- Never use `from module import *`
- Use enums for constants, not magic strings
