---
name: django-celery
description: "Use when: setting up Celery with Django, writing async tasks, scheduling periodic jobs, or managing task queues."
user-invocable: true
---

# Django Celery

## When to Activate

- Implementing background tasks in Django
- Setting up Celery with Redis/RabbitMQ
- Scheduling periodic tasks
- Monitoring task execution

## Core Concepts

### Celery Setup

```python
# config/celery.py
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
app = Celery("project")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

### Task Pattern

```python
# apps/notifications/tasks.py
from celery import shared_task
from django.core.mail import send_mail


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def send_welcome_email(self, user_email: str) -> None:
    try:
        send_mail(
            "Welcome!",
            "Thanks for signing up.",
            "noreply@project.com",
            [user_email],
        )
    except Exception as exc:
        raise self.retry(exc=exc)
```

### Periodic Tasks

```python
# config/celery_beat.py
from celery.schedules import crontest

app.conf.beat_schedule = {
    "cleanup-expired-sessions": {
        "task": "apps.users.tasks.cleanup_sessions",
        "schedule": crontest(hour=3, minute=0),
    },
}
```

## Best Practices

- Use Redis as broker for simplicity
- Always set `max_retries` and `default_retry_delay`
- Keep tasks small and idempotent
- Monitor with Flower or Prometheus
- Use task result backend only when needed
