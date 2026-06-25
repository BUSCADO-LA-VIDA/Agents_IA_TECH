---
name: backend-patterns
description: "Use when: designing backend architecture, service layers, middleware, or backend project structure."
user-invocable: true
---

# Backend Patterns

## When to Activate

- Designing backend architecture
- Structuring service layers
- Implementing middleware
- Organizing backend projects

## Core Concepts

### Layered Architecture

```
[Interface Layer]
    Controllers / Routes / GraphQL Resolvers
         ↓
[Application Layer]
    Services / Use Cases / DTOs
         ↓
[Domain Layer]
    Entities / Value Objects / Domain Services
         ↓
[Infrastructure Layer]
    Repositories / External APIs / Database
```

### Middleware Pipeline

```
Request → Logging → Auth → Rate Limit → Validation → Handler → Response
```

### Service Pattern

```python
class UserService:
    def __init__(self, repo: UserRepository, cache: CacheService):
        self._repo = repo
        self._cache = cache

    async def find_by_id(self, user_id: int) -> Optional[User]:
        # Cache-aside pattern
        cached = await self._cache.get(f"user:{user_id}")
        if cached:
            return User.from_dict(cached)

        user = await self._repo.find_by_id(user_id)
        if user:
            await self._cache.set(f"user:{user_id}", user.to_dict(), ttl=300)
        return user
```

## Best Practices

- Keep controllers thin — no business logic
- Use dependency injection for services
- Cache aggressively at the right layer
- Use middleware for cross-cutting concerns (auth, logging, rate limit)
- Separate read and write models (CQRS when needed)
