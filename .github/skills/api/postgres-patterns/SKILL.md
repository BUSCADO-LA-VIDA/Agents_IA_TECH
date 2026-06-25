---
name: postgres-patterns
description: "Use when: designing PostgreSQL schemas, writing queries, optimizing performance, or managing migrations."
user-invocable: true
---

# PostgreSQL Patterns

## When to Activate

- Designing database schemas
- Writing complex queries
- Optimizing slow queries
- Managing database migrations
- Implementing indexing strategy

## Core Concepts

### Indexing Strategy

```sql
-- B-tree for equality and range queries
CREATE INDEX idx_users_email ON users(email);

-- Composite index for multi-column queries
CREATE INDEX idx_users_status_created ON users(status, created_at);

-- Partial index for filtered queries
CREATE INDEX idx_users_active ON users(created_at) WHERE is_active = true;
```

### Query Optimization

```sql
-- Use EXPLAIN ANALYZE to identify slow queries
EXPLAIN ANALYZE
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.is_active = true
GROUP BY u.id;

-- Avoid N+1: use JOIN instead of separate queries
-- Use LIMIT + OFFSET for pagination (or keyset pagination for large datasets)
```

### Migration Pattern

```sql
-- Always use transactional migrations
BEGIN;
  ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  UPDATE users SET phone = '' WHERE phone IS NULL;
  ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
COMMIT;
```

## Best Practices

- Always use EXPLAIN ANALYZE before optimizing
- Use UUIDs for distributed systems, serial IDs for monolithic
- Add indexes based on query patterns, not guesses
- Use connection pooling (PgBouncer)
- Use read replicas for reporting queries
- Set statement_timeout to prevent runaway queries
- Regular VACUUM and ANALYZE maintenance
- Use migrations for ALL schema changes — no manual ALTER
