---
name: deployment-patterns
description: "Use when: setting up deployment pipelines, CI/CD workflows, or automating releases. Enfocado en depliegues automáticos vía webhook + docker-compose."
user-invocable: true
---

# Deployment Patterns

## When to Activate

- When setting up CI/CD pipelines
- When configuring automatic deployments (Gitea webhooks, GitHub Actions)
- When designing release strategies
- When deploying docker-compose stacks

## Core Concepts

### Webhook Auto-Deploy Pattern (tu estilo)

```yaml
# docker-compose con servicio de deploy
services:
  webhook-listener:
    image: adnanh/webhook:latest
    volumes:
      - ./webhooks:/etc/webhook
      - /var/run/docker.sock:/var/run/docker.sock
      - ./deploy-scripts:/scripts
    ports:
      - "9000:9000"
    environment:
      - WEBHOOK_SECRET=${WEBHOOK_SECRET}
```

### Deploy Script Pattern

```bash
#!/bin/bash
# deploy.sh — auto-deploy via webhook
set -euo pipefail

cd /path/to/project
git pull origin main
docker-compose build
docker-compose up -d
docker image prune -f
```

### Release Strategies

| Strategy | When |
|----------|------|
| Recreate | Simple, downtime OK |
| Rolling update | Zero-downtime, default |
| Blue/green | Critical services, instant rollback |
| Canary | Gradual rollout, testing in prod |

## Best Practices

- Webhook auto-deploy: always include a health check verification step
- Keep deploy scripts idempotent — running twice is safe
- Use git tags for versioned releases
- Always have a rollback plan (previous docker-compose config)
- Notify on deploy success/failure (Discord, Telegram, email)
