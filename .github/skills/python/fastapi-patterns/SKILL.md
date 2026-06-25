---
name: fastapi-patterns
description: "Use when: building FastAPI applications, REST APIs with Pydantic, async endpoints, or OpenAPI documentation."
user-invocable: true
---

# FastAPI Patterns

## When to Activate

- Creating new FastAPI applications
- Designing REST APIs with Pydantic schemas
- Implementing async endpoints
- Generating OpenAPI documentation

## Core Concepts

### Project Structure

```
project/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── users.py
│   │   │   └── items.py
│   ├── core/
│   │   ├── config.py
│   │   ├── database.py
│   │   └── security.py
│   ├── models/
│   ├── schemas/
│   └── services/
├── tests/
├── Dockerfile
├── docker-compose.yml
└── pyproject.toml
```

### Endpoint Pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from app.schemas.user import UserCreate, UserResponse
from app.services.user import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    data: UserCreate,
    service: UserService = Depends(),
) -> UserResponse:
    user = await service.create(data)
    if not user:
        raise HTTPException(400, "User already exists")
    return user
```

### Dependency Injection

```python
from fastapi import Depends, FastAPI
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_session

app = FastAPI()


@app.get("/health")
async def health(db: AsyncSession = Depends(get_session)):
    await db.execute("SELECT 1")
    return {"status": "ok"}
```

## Best Practices

- Use Pydantic v2 for all schemas
- Use async endpoints — FastAPI was built for async
- Use dependency injection for services
- Use `response_model` for automatic validation
- Use `status_code` explicitly on all endpoints
- Group endpoints by version (v1, v2)
- Auto-generate OpenAPI docs — keep them accurate
