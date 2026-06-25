---
name: django-patterns
description: "Use when: building Django applications, designing models, views, serializers, or Django REST Framework APIs."
user-invocable: true
---

# Django Patterns

## When to Activate

- Creating new Django apps or models
- Writing DRF serializers and viewsets
- Optimizing Django queries
- Setting up Django project structure

## Core Concepts

### Project Structure

```
project/
├── config/
│   ├── settings/
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   └── users/
│       ├── models.py
│       ├── serializers.py
│       ├── views.py
│       ├── services.py
│       ├── urls.py
│       ├── tests.py
│       └── filters.py
├── templates/
├── static/
└── manage.py
```

### Service Layer Pattern

```python
# apps/users/services.py
from django.db import transaction
from apps.users.models import User


class UserService:
    @staticmethod
    @transaction.atomic
    def create_user(data: dict) -> User:
        user = User.objects.create_user(**data)
        user.set_password(data["password"])
        user.save()
        return user
```

### DRF ViewSet

```python
from rest_framework import viewsets, permissions
from apps.users.models import User
from apps.users.serializers import UserSerializer


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.filter(is_active=True)
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
```

## Best Practices

- Fat models? No — fat services, thin models
- Use select_related/prefetch_related to avoid N+1
- Use Django ORM — avoid raw SQL unless necessary
- Use migrations for ALL schema changes
- Keep settings in environment variables
- Use django-filter for complex filtering
- Cache with django-cacheops or redis
