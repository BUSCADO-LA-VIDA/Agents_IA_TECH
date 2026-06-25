---
name: generating-python-installer
description: "Use when: packaging Python projects, creating distribution packages, or configuring pyproject.toml for pip install."
user-invocable: true
---

# Generating Python Installer

## When to Activate

- Packaging Python projects for distribution
- Creating pyproject.toml configuration
- Publishing to PyPI or private registry

## Core Concepts

### pyproject.toml

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-package"
version = "0.1.0"
description = "A useful package"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "MIT"}
dependencies = [
    "requests>=2.28",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = ["pytest", "mypy", "ruff"]
```

### Installation

```bash
# Dev install
pip install -e ".[dev]"

# Build distribution
python -m build

# Publish
twine upload dist/*
```

## Best Practices

- Use pyproject.toml — setup.py is legacy
- Pin minimum versions, not exact versions
- Keep dependencies minimal
- Include README.md with usage examples
- Use src-layout for package structure
