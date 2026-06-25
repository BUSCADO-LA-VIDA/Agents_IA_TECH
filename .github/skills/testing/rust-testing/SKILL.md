---
name: rust-testing
description: "Use when: writing Rust tests, unit tests, integration tests, property-based testing, or benchmarking."
user-invocable: true
---

# Rust Testing

## When to Activate

- Writing unit tests for Rust code
- Integration tests in tests/
- Property-based testing with proptest
- Benchmarking with criterion

## Core Concepts

### Unit Test

```rust
#[derive(Debug, PartialEq)]
struct User {
    email: String,
    is_active: bool,
}

impl User {
    fn new(email: &str) -> Self {
        Self {
            email: email.to_string(),
            is_active: true,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_user_is_active() {
        let user = User::new("test@test.com");
        assert_eq!(user.email, "test@test.com");
        assert!(user.is_active);
    }
}
```

### Integration Test

```rust
// tests/user_api.rs
use my_project::api;

#[test]
fn create_user_returns_201() {
    let response = api::create_user("test@test.com");
    assert_eq!(response.status(), 201);
}
```

## Best Practices

- Use `#[cfg(test)]` to exclude test code from release builds
- Keep unit tests in the same file as the code
- Integration tests go in `tests/` directory
- Use `cargo test` for running all tests
- Use proptest for property-based testing
- Use criterion for benchmarks
