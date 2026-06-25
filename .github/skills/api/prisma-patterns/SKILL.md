---
name: prisma-patterns
description: "Use when: using Prisma ORM, defining schemas, writing queries, or managing migrations in Node.js/TypeScript."
user-invocable: true
---

# Prisma Patterns

## When to Activate

- Defining Prisma schemas
- Writing Prisma queries with relations
- Managing Prisma migrations
- Optimizing Prisma performance

## Core Concepts

### Schema Definition

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String   @id @default(uuid())
  title     String
  content   String?
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  createdAt DateTime @default(now())
}
```

### Query Patterns

```typescript
// Include relations
const user = await prisma.user.findUnique({
  where: { email: "test@test.com" },
  include: { posts: true },
});

// Pagination
const posts = await prisma.post.findMany({
  skip: 0,
  take: 20,
  orderBy: { createdAt: "desc" },
});

// Transaction
const [user, post] = await prisma.$transaction([
  prisma.user.create({ data: { email: "test@test.com" } }),
  prisma.post.create({ data: { title: "First post", authorId: "..." } }),
]);
```

## Best Practices

- Use Prisma Client — raw queries only as last resort
- Use `select` to fetch only needed fields
- Use `include` carefully — can cause N+1
- Use `$transaction` for atomic operations
- Use Prisma Migrate for schema changes
- Use `@updatedAt` for automatic timestamps
