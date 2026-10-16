---
name: django-verification
description: "Use when: verifying Django implementations, running checks, or validating that code meets requirements."
user-invocable: true
---

# Django Verification

## When to Activate

- After implementing a Django module
- Before deploying Django changes
- When verifying requirements are met

## Core Concepts

### Verification Checklist

- [ ] All tests pass (`pytest`)
- [ ] No N+1 queries (check with `django-debug-toolbar` or `nplusone`)
- [ ] Migrations are up to date (`python manage.py makemigrations --check`)
- [ ] Static files compile (`python manage.py collectstatic --dry-run`)
- [ ] System checks pass (`python manage.py check --deploy`)
- [ ] Coverage ≥ 80%
- [ ] No hardcoded secrets in settings
- [ ] CSRF enabled on all forms
- [ ] CORS configured correctly
- [ ] API returns proper status codes

## Profundidad ECC
Detalle tecnico completo (20 KB aprox): `../../../../proyect_ext/ECC/skills/django-verification/SKILL.md`.
Esta ficha es la fachada SSD del kit; ante duda tecnica, leer la fuente ECC (no se sincroniza: `proyect_ext/` nunca sale del KIT).
