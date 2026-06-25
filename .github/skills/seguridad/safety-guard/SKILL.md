---
name: safety-guard
description: "Use when: implementing safety guardrails, preventing unsafe operations, or adding validation layers to protect system integrity."
user-invocable: true
---

# Safety Guard

## When to Activate

- When implementing destructive operations (delete, drop, truncate)
- When designing user permission systems
- When creating confirmation dialogs or undo mechanisms
- When handling irreversible actions

## Core Concepts

### Safety Patterns

| Pattern | Description |
|---------|-------------|
| Confirmation | Require explicit confirmation for destructive actions |
| Undo/Reversible | Support rollback for state-changing operations |
| Dry-run | Preview changes before applying |
| Soft-delete | Mark as deleted instead of removing |
| Rate limit | Prevent accidental mass operations |
| Approval flow | Require second person for critical actions |

### Implementation

```python
# ponytail: safety guard pattern
def delete_project(project_id: str, confirm: bool = False) -> Result:
    if not confirm:
        return Result.failure("Requires explicit confirmation")
    if not _user_has_permission(current_user, "project:delete"):
        return Result.failure("Unauthorized")
    # Proceed with deletion
```

## Best Practices

- Always ask for confirmation on destructive operations
- Provide dry-run mode for bulk operations
- Log all safety guard triggers for audit
- Make destructive actions require elevated privileges
- Default to safe — require opting into risk
