---
name: api-design
description: "Use when: designing REST APIs, defining endpoints, request/response formats, versioning, or OpenAPI specs."
user-invocable: true
---

# API Design

## When to Activate

- Designing new REST APIs
- Reviewing API contracts
- Defining OpenAPI/Swagger specs
- API versioning strategy

## Core Concepts

### RESTful Design

```
GET    /api/v1/users           # List with pagination
POST   /api/v1/users           # Create
GET    /api/v1/users/{id}      # Read
PUT    /api/v1/users/{id}      # Full update
PATCH  /api/v1/users/{id}      # Partial update
DELETE /api/v1/users/{id}      # Soft delete
```

### Response Envelope

```json
{
  "success": true,
  "data": {},
  "error": null,
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Error Format

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "message": "must not be empty" }
    ]
  }
}
```

## Best Practices

- Use nouns for resources, not verbs
- Version via URL prefix (/v1/, /v2/)
- Use proper HTTP status codes (201 created, 204 no content)
- Paginate all list endpoints
- Use consistent error format
- Document with OpenAPI 3.0
- Use camelCase for JSON fields
- Support filtering via query params (?status=active)
