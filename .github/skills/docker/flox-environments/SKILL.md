---
name: flox-environments
description: "Use when: managing development environments with Flox, or creating reproducible dev shells."
user-invocable: true
---

# Flox Environments

## When to Activate

- When setting up reproducible development environments
- When using Flox for environment management
- When creating project-specific dev shells

## Core Concepts

Flox provides reproducible, isolated development environments using Nix under the hood.

### Basic Usage

```bash
# Create a new environment
flox init

# Install packages
flox install python311 nodejs_20

# Enter the environment
flox activate

# Run a command in the environment
flox activate -- python --version
```

## Best Practices

- Commit `.flox/` to repo for team reproducibility
- Use one environment per project
- Combine with direnv for auto-activation
- Pin package versions for reproducible builds
