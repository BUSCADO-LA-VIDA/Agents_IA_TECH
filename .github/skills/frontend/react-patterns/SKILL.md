---
name: react-patterns
description: "Use when: writing React components, hooks, context, or implementing React design patterns."
user-invocable: true
---

# React Patterns

## When to Activate

- Writing React components
- Implementing custom hooks
- Managing state with React
- Optimizing re-renders

## Core Concepts

### Custom Hook Pattern

```typescript
import { useState, useEffect, useCallback } from "react";

interface UseUsersResult {
  users: User[];
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

function useUsers(): UseUsersResult {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getUsers();
      setUsers(data);
    } catch (e) {
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  return { users, loading, error, refetch: fetchUsers };
}
```

### Compound Component Pattern

```tsx
function Select<T extends string>({ children }: { children: ReactNode }) {
  const [value, setValue] = useState<T | null>(null);
  return (
    <SelectContext.Provider value={{ value, setValue }}>
      <div className="relative">{children}</div>
    </SelectContext.Provider>
  );
}

Select.Option = function Option({ value, children }: OptionProps) {
  const { setValue } = useSelectContext();
  return <div onClick={() => setValue(value)}>{children}</div>;
};
```

## Best Practices

- Extract logic into custom hooks
- Use useMemo/useCallback only when profiling says so
- Prefer composition over prop drilling
- Use React Query (TanStack Query) for server state
- Use Zustand for client state
- Lazy load components with React.lazy
- Test components with React Testing Library
