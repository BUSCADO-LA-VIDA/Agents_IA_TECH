---
name: hexagonal-architecture
description: "Use when: designing hexagonal/clean architecture, ports and adapters, or decoupling business logic from infrastructure."
user-invocable: true
---

# Hexagonal Architecture

## When to Activate

- Designing new application architecture
- Decoupling business logic from frameworks
- Implementing ports and adapters pattern
- Making systems testable without infrastructure

## Core Concepts

### Architecture Layers

```
┌─────────────────────────────────────────┐
│           Interface Adapters             │
│  (Controllers, CLI, API, UI, Serializers)│
└────────────────┬────────────────────────┘
                 │ Ports (interfaces)
┌────────────────┴────────────────────────┐
│           Application Layer              │
│  (Use Cases, Services, DTOs, Mappers)   │
└────────────────┬────────────────────────┘
                 │ Ports (interfaces)
┌────────────────┴────────────────────────┐
│           Domain Layer                   │
│  (Entities, Value Objects, Aggregates)  │
└────────────────┬────────────────────────┘
                 │ Ports (interfaces)
┌────────────────┴────────────────────────┐
│         Infrastructure Layer             │
│  (DB, External APIs, File System, etc.) │
└─────────────────────────────────────────┘
```

### Port & Adapter Pattern

```python
# Domain/Port — interface (the "port")
class UserRepository(ABC):
    @abstractmethod
    async def find_by_id(self, user_id: UUID) -> Optional[User]: ...

    @abstractmethod
    async def save(self, user: User) -> User: ...


# Infrastructure — implementation (the "adapter")
class PostgresUserRepository(UserRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_by_id(self, user_id: UUID) -> Optional[User]:
        result = await self._session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        return result.scalar_one_or_none()
```

### Project Structure

```
src/
├── domain/
│   ├── entities/
│   ├── value_objects/
│   └── ports/
├── application/
│   ├── use_cases/
│   └── services/
├── infrastructure/
│   ├── database/
│   ├── cache/
│   └── external_apis/
└── interfaces/
    ├── controllers/
    └── serializers/
```

## Best Practices

- Domain layer has ZERO external dependencies — pure Python/Java/C#
- Ports are interfaces defined by the domain, not by the framework
- Adapters implement ports, never the other way around
- Use dependency injection to wire adapters to ports
- Business logic lives in domain/application — never in infrastructure
- Test domain logic without infrastructure (pure unit tests)
- Integration tests verify adapters work correctly
