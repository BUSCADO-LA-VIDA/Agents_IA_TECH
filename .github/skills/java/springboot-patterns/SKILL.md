---
name: springboot-patterns
description: "Use when: building Spring Boot applications, REST APIs, services, or configuring Spring projects."
user-invocable: true
---

# Spring Boot Patterns

## When to Activate

- Creating new Spring Boot applications
- Designing REST controllers and services
- Configuring Spring Data JPA
- Writing integration tests

## Core Concepts

### Layered Architecture

```
Controller → Service → Repository → Entity
    ↑           ↑          ↑
  @RestController  @Service  @Repository
```

### REST Controller

```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService service;

    @PostMapping
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        var user = service.create(request);
        return ResponseEntity.status(201).body(user);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> findById(@PathVariable UUID id) {
        return service.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
```

### Service with Transaction

```java
@Service
@Transactional
public class UserService {
    private final UserRepository repository;

    public User create(CreateUserRequest request) {
        if (repository.existsByEmail(request.email())) {
            throw new DuplicateResourceException("Email already exists");
        }
        return repository.save(new User(request));
    }
}
```

## Best Practices

- Use constructor injection (no @Autowired on fields)
- Use @Valid for request validation
- Use DTOs — never expose entities directly
- Use @Transactional on service layer
- Use @ExceptionHandler for global error handling
- Use Pageable for pagination
- Profile-specific configs (application-dev.yml, application-prod.yml)
