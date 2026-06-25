---
name: frontend-patterns
description: "Use when: building frontend applications with React, Next.js, or modern JS frameworks. Structure, components, state management."
user-invocable: true
---

# Frontend Patterns

## When to Activate

- Creating new frontend projects
- Designing component structures
- Implementing state management
- Optimizing frontend performance

## Core Concepts

### Project Structure

```
src/
├── components/
│   ├── ui/          # Atomic: Button, Input, Card
│   ├── layout/      # Header, Sidebar, Footer
│   └── features/    # Domain-specific: UserCard, ProductList
├── hooks/           # Custom React hooks
├── services/        # API clients
├── stores/          # State management (Zustand, Redux)
├── types/           # TypeScript types/interfaces
├── utils/           # Helper functions
├── pages/           # Page components (Next.js App Router)
└── app/             # App entry (Next.js App Router)
```

### Component Pattern

```tsx
// Single Responsibility Component
interface UserCardProps {
  user: User;
  onSelect: (id: string) => void;
}

export function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div className="p-4 border rounded-lg" onClick={() => onSelect(user.id)}>
      <h3 className="font-semibold">{user.name}</h3>
      <p className="text-gray-500">{user.email}</p>
    </div>
  );
}
```

## Best Practices

- Components should do ONE thing
- Use TypeScript — no `any`
- Use Tailwind CSS for styling
- Server components by default (Next.js)
- Client components only when interactivity needed
- Extract logic into custom hooks
- Use composition over inheritance
