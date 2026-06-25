---
name: jpa-patterns
description: "Use when: designing JPA entities, repositories, relationships, or optimizing database queries in Spring."
user-invocable: true
---

# JPA Patterns

## When to Activate

- Designing entity relationships
- Writing Spring Data JPA repositories
- Optimizing queries (N+1, pagination)
- Implementing auditing and soft deletes

## Core Concepts

### Entity Pattern

```java
@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener.class)
public class User {
    @Id
    @GeneratedValue(strategy = UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    protected User() {} // JPA requirement
}
```

### Repository Pattern

```java
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u JOIN FETCH u.roles WHERE u.id = :id")
    Optional<User> findByIdWithRoles(@Param("id") UUID id);

    Page<User> findByActiveTrue(Pageable pageable);
}
```

## Best Practices

- Use UUIDs over auto-increment for distributed systems
- Use LAZY loading by default — use JOIN FETCH explicitly
- Avoid N+1 — use `@EntityGraph` or `JOIN FETCH`
- Use `@Transactional(readOnly = true)` for reads
- Use projections for read-only queries
- Enable query logging in development
