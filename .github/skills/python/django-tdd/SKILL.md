---
name: django-tdd
description: "Use when: doing TDD in Django, writing tests before implementation, testing models, views, APIs."
user-invocable: true
---

# Django TDD

## When to Activate

- Starting a new Django feature
- Writing tests first (RED phase)
- Testing models, views, serializers, or APIs

## Core Concepts

### TDD Cycle for Django

```
RED:   Write test → run → fails
GREEN: Write minimal code → run → passes
IMPROVE: Refactor → run → still passes
```

### Test Patterns

```python
# tests/test_models.py
import pytest
from apps.users.models import User


@pytest.mark.django_db
class TestUserModel:
    def test_create_user_success(self) -> None:
        user = User.objects.create_user(
            email="test@test.com",
            password="securepass123",
            name="Test User"
        )
        assert user.email == "test@test.com"
        assert user.check_password("securepass123")

    def test_user_str_returns_email(self) -> None:
        user = User(email="test@test.com")
        assert str(user) == "test@test.com"
```

### API Test Pattern

```python
from rest_framework import status
from rest_framework.test import APITestCase


class TestUserAPI(APITestCase):
    def test_create_user_returns_201(self) -> None:
        data = {"email": "test@test.com", "password": "securepass123"}
        response = self.client.post("/api/users/", data)
        assert response.status_code == status.HTTP_201_CREATED
```

## Best Practices

- Use pytest-django instead of Django's TestCase
- Use `@pytest.mark.django_db` for DB tests
- Use APIRequestFactory for view tests
- Test error cases, not just happy paths
- Use django-test-migrations for migration tests
