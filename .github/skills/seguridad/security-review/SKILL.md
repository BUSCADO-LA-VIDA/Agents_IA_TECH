---
name: security-review
description: "Use when: performing security audits, reviewing code for vulnerabilities, or applying security best practices."
user-invocable: true
---

# Security Review

## When to Activate

- Before any commit or PR
- When reviewing authentication/authorization code
- When handling user input or external data
- Before deploying to production
- When touching payment, PII, or sensitive data

## Core Concepts

### Security Review Checklist

- [ ] **No hardcoded secrets** — API keys, tokens, passwords in env vars
- [ ] **Input validation** — all user input sanitized at trust boundaries
- [ ] **SQL injection** — parameterized queries, no string interpolation
- [ ] **XSS prevention** — output escaped, Content-Security-Policy headers
- [ ] **CSRF protection** — tokens on state-changing requests
- [ ] **Authentication** — session management, password hashing (bcrypt/argon2)
- [ ] **Authorization** — server-side checks, not just UI hiding
- [ ] **Rate limiting** — on all public endpoints
- [ ] **Error messages** — don't leak stack traces, DB schema, or internals
- [ ] **Dependencies** — no known vulnerable versions

### Review Flow

```
Code → Security Review → Fix Issues → Re-review → Commit
```

## Anti-Patterns

- Trusting client-side validation alone
- Using `eval()` or dynamic `exec()`
- Storing passwords in plain text
- Logging sensitive data (passwords, tokens, PII)
- "We'll add security later" — security is not retrofittable

## Best Practices

- Security is everyone's responsibility, not just the "security team"
- Principle of least privilege — every component gets minimum access
- Defense in depth — multiple layers of security controls
- Fail securely — errors should default to secure state
- Validate at every trust boundary, not just at entry points
