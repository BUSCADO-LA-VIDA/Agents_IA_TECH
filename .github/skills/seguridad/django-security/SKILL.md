---
name: django-security
description: "Use when: securing Django applications, implementing Django security best practices, or auditing Django projects."
user-invocable: true
---

# Django Security

## When to Activate

- When building or reviewing Django applications
- When configuring Django settings for production
- When implementing authentication in Django
- When handling user data in Django

## Core Concepts

### Django Security Settings

```python
# Required for production
DEBUG = False
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
```

### Django-Specific Checklist

- [ ] Use `@login_required` and `@permission_required` decorators
- [ ] Never use `mark_safe()` or `|safe` filter with user input
- [ ] Use Django ORM (parameterized queries) — not raw SQL
- [ ] CSRF tokens enabled on all forms
- [ ] Use `UserPassesTestMixin` for class-based views
- [ ] Validate file uploads (type, size, content)
- [ ] Set `FILE_UPLOAD_MAX_MEMORY_SIZE` and `DATA_UPLOAD_MAX_MEMORY_SIZE`
- [ ] Use `django-csp` for Content Security Policy
- [ ] Keep `SECRET_KEY` in environment variable
- [ ] Rotate `SECRET_KEY` if compromised

## Best Practices

- Use Django's built-in auth — don't roll your own
- Prefer function-based views with decorators over raw request handling
- Use `django-allauth` for social auth — battle-tested
- Implement rate limiting with `django-ratelimit`
- Run `python manage.py check --deploy` before production
- Never log sensitive data — use Django's filter for sensitive variables
