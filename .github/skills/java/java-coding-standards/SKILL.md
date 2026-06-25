---
name: java-coding-standards
description: "Use when: writing Java code, applying Java best practices, or reviewing Java projects. Clean code, project structure, conventions."
user-invocable: true
---

# Java Coding Standards

## When to Activate

- Writing new Java classes
- Reviewing Java code
- Setting up Java project structure

## Core Concepts

### Project Structure (Maven)

```
project/
├── src/
│   ├── main/
│   │   ├── java/com/project/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── infrastructure/
│   │   │   └── interfaces/
│   │   └── resources/
│   └── test/
│       └── java/com/project/
├── pom.xml
└── README.md
```

### Clean Code

```java
// ✅ Clear, typed, single responsibility
public record CreateUserRequest(String name, String email) {}

@Service
public class UserService {
    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    public User create(CreateUserRequest request) {
        var user = new User(request.name(), request.email());
        return repository.save(user);
    }
}
```

## Best Practices

- Use records for DTOs (Java 16+)
- Use var for obvious types (Java 10+)
- Prefer constructor injection over field injection
- Use Optional for nullable returns
- Never catch generic Exception
- Use SLF4J for logging
- Keep methods < 50 lines, classes < 400 lines
