---
name: e2e-testing
description: "Use when: writing end-to-end tests with Playwright, Cypress, or Selenium. Testing critical user flows."
user-invocable: true
---

# E2E Testing

## When to Activate

- Writing end-to-end tests
- Testing critical user flows
- Setting up Playwright or Cypress
- Debugging flaky E2E tests

## Core Concepts

### Playwright Test

```typescript
import { test, expect } from "@playwright/test";

test("user can log in and view dashboard", async ({ page }) => {
  // Navigate
  await page.goto("/login");

  // Fill form
  await page.fill("[data-testid=email]", "admin@test.com");
  await page.fill("[data-testid=password]", "securepass");
  await page.click("[data-testid=login-button]");

  // Assert
  await expect(page.locator("[data-testid=dashboard]")).toBeVisible();
  await expect(page).toHaveURL(/\/dashboard/);
});
```

### Test Structure

```
tests/e2e/
├── auth/
│   ├── login.spec.ts
│   └── registration.spec.ts
├── features/
│   ├── checkout.spec.ts
│   └── search.spec.ts
├── fixtures/
│   └── test-data.ts
└── helpers/
    └── auth-helper.ts
```

## Best Practices

- Test critical user flows only (login, checkout, search)
- Use data-testid attributes — not CSS classes
- Avoid hardcoded waits — use auto-waiting
- Run in CI with headed mode for debugging
- Record videos on failure
- Use page objects for reusable selectors
- Keep tests independent — no shared state
