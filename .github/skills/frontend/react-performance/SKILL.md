---
name: react-performance
description: "Use when: optimizing React performance, reducing re-renders, bundle size, or improving Core Web Vitals."
user-invocable: true
---

# React Performance

## When to Activate

- Optimizing slow React components
- Reducing bundle size
- Improving Core Web Vitals (LCP, FID, CLS)
- Profiling and debugging performance

## Core Concepts

### Memoization

```typescript
import { memo, useMemo, useCallback } from "react";

// Component only re-renders when props change
const ExpensiveList = memo(function ExpensiveList({ items }: Props) {
  return items.map(item => <Item key={item.id} data={item} />);
});

// Memoize computed values
const total = useMemo(() => items.reduce((sum, i) => sum + i.price, 0), [items]);

// Memoize callbacks
const handleClick = useCallback((id: string) => {
  onSelect(id);
}, [onSelect]);
```

### Code Splitting

```typescript
import { lazy, Suspense } from "react";

const Dashboard = lazy(() => import("./Dashboard"));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Dashboard />
    </Suspense>
  );
}
```

### Performance Checklist

- [ ] Images lazy loaded and optimized
- [ ] Bundle analyzed (no duplicate dependencies)
- [ ] Server components used where possible (Next.js)
- [ ] No unnecessary re-renders
- [ ] Virtual list for long lists
- [ ] Debounced search inputs
- [ ] Fonts self-hosted and preloaded

## Best Practices

- Profile BEFORE optimizing — don't guess bottlenecks
- Use React DevTools Profiler
- Use Next.js built-in optimizations (Image, Font, Script)
- Avoid prop drilling — use context or state libraries
- Memoize only when needed — premature memoization adds complexity
