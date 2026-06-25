---
name: quarkus-patterns
description: "Use when: building Quarkus applications, reactive REST APIs, or native compiled Java services."
user-invocable: true
---

# Quarkus Patterns

## When to Activate

- Creating new Quarkus applications
- Building reactive REST APIs
- Compiling to native with GraalVM

## Core Concepts

### Project Structure

```
project/
├── src/
│   ├── main/
│   │   ├── java/com/project/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   └── infrastructure/
│   │   └── resources/
│   │       └── application.properties
│   └── test/
├── pom.xml
└── Dockerfile
```

### Reactive REST

```java
@Path("/api/v1/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {
    @Inject
    UserService service;

    @POST
    @Transaction
    public Uni<UserResponse> create(CreateUserRequest request) {
        return service.create(request);
    }

    @GET
    @Path("/{id}")
    public Uni<UserResponse> findById(@PathParam UUID id) {
        return service.findById(id);
    }
}
```

## Best Practices

- Prefer reactive (Uni/Multi) for I/O operations
- Use Panache for simplified Hibernate
- Use @Transaction for database operations
- Profile for native compilation early
- Use application.properties per profile
