---
name: cpp-testing
description: "Use when: writing C++ tests, GoogleTest, Catch2, or testing C++ applications."
user-invocable: true
---

# C++ Testing

## When to Activate

- Writing unit tests for C++ code
- Using GoogleTest or Catch2
- Testing C++ classes and functions

## Core Concepts

### GoogleTest Pattern

```cpp
#include <gtest/gtest.h>
#include "user.h"

TEST(UserTest, CreateUserSetsEmail) {
    auto user = User::Create("test@test.com", "password123");
    EXPECT_EQ(user.GetEmail(), "test@test.com");
    EXPECT_TRUE(user.CheckPassword("password123"));
}

TEST(UserTest, EmptyEmailThrows) {
    EXPECT_THROW(User::Create("", "pass"), std::invalid_argument);
}
```

## Best Practices

- Use GoogleTest for C++ projects
- Use TEST_F for fixture-based tests
- Use EXPECT_* for non-fatal assertions
- Use ASSERT_* for fatal assertions (stop on failure)
- Mock with GoogleMock
