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

---

## Profundidad ECC (integrada b92f181b, 2026-10-16)

> Fuente: proyect_ext/ECC/skills/safety-guard/SKILL.md (cache de descarga, no se sincroniza). Contenido copiado al KIT: viaja en git a los demas proyectos.

---
name: safety-guard
description: "Guard against destructive operations with three modes: Careful intercepts dangerous commands (rm -rf, git push --force, DROP TABLE) for confirmation, Freeze locks writes to one directory, and Guard combines both via PreToolUse hooks. Use when working on production systems, running agents autonomously, restricting edits to a directory, or during migrations, deploys, and data changes."
metadata:
  origin: ECC
---

# Safety Guard — Prevent Destructive Operations

## When to Use

- When working on production systems
- When agents are running autonomously (full-auto mode)
- When you want to restrict edits to a specific directory
- During sensitive operations (migrations, deploys, data changes)

## How It Works

Three modes of protection:

### Mode 1: Careful Mode

Intercepts destructive commands before execution and warns:

```
Watched patterns:
- rm -rf (especially /, ~, or project root)
- git push --force
- git reset --hard
- git checkout . (discard all changes)
- DROP TABLE / DROP DATABASE
- docker system prune
- kubectl delete
- chmod 777
- sudo rm
- npm publish (accidental publishes)
- Any command with --no-verify
```

When detected: shows what the command does, asks for confirmation, suggests safer alternative.

### Mode 2: Freeze Mode

Locks file edits to a specific directory tree:

```
/safety-guard freeze src/components/
```

Any Write/Edit outside `src/components/` is blocked with an explanation. Useful when you want an agent to focus on one area without touching unrelated code.

### Mode 3: Guard Mode (Careful + Freeze combined)

Both protections active. Maximum safety for autonomous agents.

```
/safety-guard guard --dir src/api/ --allow-read-all
```

Agents can read anything but only write to `src/api/`. Destructive commands are blocked everywhere.

### Unlock

```
/safety-guard off
```

## Implementation

Uses PreToolUse hooks to intercept Bash, Write, Edit, and MultiEdit tool calls. Checks the command/path against the active rules before allowing execution.

## Integration

- Enable by default for `codex -a never` sessions
- Pair with observability risk scoring in ECC 2.0
- Logs all blocked actions to `~/.claude/safety-guard.log`
