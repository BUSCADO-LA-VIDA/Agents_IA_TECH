---
name: react-testing
description: "Use when: testing React components, React Testing Library, Vitest, or Jest with React."
user-invocable: true
---

# React Testing

## When to Activate

- Writing unit tests for React components
- Testing component behavior
- Testing hooks
- Testing user interactions

## Core Concepts

### Component Test

```typescript
import { render, screen, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import { UserCard } from "./UserCard";

describe("UserCard", () => {
  it("renders user name and email", () => {
    const user = { id: "1", name: "John", email: "john@test.com" };
    render(<UserCard user={user} onSelect={vi.fn()} />);

    expect(screen.getByText("John")).toBeInTheDocument();
    expect(screen.getByText("john@test.com")).toBeInTheDocument();
  });

  it("calls onSelect when clicked", () => {
    const onSelect = vi.fn();
    const user = { id: "1", name: "John", email: "john@test.com" };

    render(<UserCard user={user} onSelect={onSelect} />);
    fireEvent.click(screen.getByText("John"));

    expect(onSelect).toHaveBeenCalledWith("1");
  });
});
```

### Hook Test

```typescript
import { renderHook, waitFor } from "@testing-library/react";
import { useUsers } from "./useUsers";

describe("useUsers", () => {
  it("returns users after loading", async () => {
    const { result } = renderHook(() => useUsers());

    expect(result.current.loading).toBe(true);

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.users).toHaveLength(3);
  });
});
```

## Best Practices

- Test behavior, not implementation
- Use `@testing-library/user-event` over `fireEvent`
- Use `findBy*` for async elements
- Avoid testing internal state — test rendered output
- Use wrapper in render for providers
- Mock API calls, not modules
