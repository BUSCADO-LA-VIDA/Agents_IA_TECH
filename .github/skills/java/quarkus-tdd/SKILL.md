---
name: quarkus-tdd
description: "Use when: doing TDD in Quarkus, testing reactive endpoints, or writing Quarkus integration tests."
user-invocable: true
---

# Quarkus TDD

## When to Activate

- Writing tests first for Quarkus features
- Testing reactive REST endpoints
- Testing Panache repositories

## Core Concepts

### Test Pattern

```java
@QuarkusTest
public class UserResourceTest {
    @Test
    void create_shouldReturn201() {
        var request = new CreateUserRequest("test@test.com", "pass");

        given()
            .contentType(ContentType.JSON)
            .body(request)
            .post("/api/v1/users")
            .then()
            .statusCode(201);
    }
}
```

## Best Practices

- Use @QuarkusTest for integration tests
- Use Wiremock for external services
- Test reactive endpoints with await().atMost()
- Use @TestProfile for different configs
