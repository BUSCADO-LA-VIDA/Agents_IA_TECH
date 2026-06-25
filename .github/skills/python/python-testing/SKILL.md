---
name: python-testing
description: "Use when: writing Python tests, pytest fixtures, mocking, or testing strategies. TDD, coverage, property-based testing."
user-invocable: true
---

# Python Testing

## When to Activate

- Writing unit/integration tests for Python code
- Setting up pytest configuration
- Debugging flaky tests
- Improving test coverage

## Core Concepts

### Pytest Setup

```python
# pytest.ini or pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --cov=src --cov-report=term-missing"
```

### Fixture Pattern

```python
import pytest
from src.domain.user import User


@pytest.fixture
def user_factory() -> callable:
    def _create(name: str = "Test", email: str = "test@test.com") -> User:
        return User(id=1, name=name, email=email)
    return _create


def test_user_creation(user_factory) -> None:
    user = user_factory()
    assert user.name == "Test"
    assert user.is_active is True
```

### Mocking External Services

```python
from unittest.mock import patch


@patch("src.infrastructure.email.send_email")
def test_notification(mock_send) -> None:
    mock_send.return_value = {"status": "sent"}
    result = notify_user("test@test.com")
    assert result["status"] == "sent"
    mock_send.assert_called_once()
```

## Best Practices

- Use pytest — not unittest (built-in is too verbose)
- Fixtures over setUp/tearDown
- Parametrize tests for multiple scenarios
- Mock at the import path, not the implementation
- Test behavior, not implementation details
- Aim for > 80% coverage
- Use factory pattern for test data
