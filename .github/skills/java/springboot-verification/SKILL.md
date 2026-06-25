---
name: springboot-verification
description: "Use when: verifying Spring Boot implementations, running checks, or validating requirements."
user-invocable: true
---

# Spring Boot Verification

## When to Activate

- After implementing Spring Boot modules
- Before deploying changes
- When verifying requirements

## Core Concepts

### Verification Checklist

- [ ] All tests pass
- [ ] No N+1 queries (check logs for n+1-selects)
- [ ] Flyway/Liquibase migrations run cleanly
- [ ] `mvn verify` passes (includes integration tests)
- [ ] Checkstyle passes
- [ ] Coverage ≥ 80%
- [ ] No hardcoded secrets in application.yml
- [ ] Actuator endpoints secured
- [ ] CORS configured for production
- [ ] API returns consistent error format
