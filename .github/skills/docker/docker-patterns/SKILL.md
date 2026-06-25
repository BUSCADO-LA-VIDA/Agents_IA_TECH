---
name: docker-patterns
description: "Use when: creating Dockerfiles, docker-compose setups, or containerizing applications. Especializado en docker-compose y depliegues personalizados."
user-invocable: true
---

# Docker Patterns

## When to Activate

- When creating or optimizing Dockerfiles
- When setting up docker-compose for multi-service apps
- When deploying with Docker (Gitea, auto-deploys, etc.)
- When debugging container issues

## Core Concepts

### Dockerfile Best Practices

```dockerfile
# Multi-stage builds
FROM python:3.12-slim AS builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.12-slim AS runtime
COPY --from=builder /root/.local /root/.local
COPY . .
CMD ["python", "app.py"]
```

### Docker-Compose Structure (tu estilo)

```yaml
version: "3.8"
services:
  app:
    build: .
    env_file: .env
    volumes:
      - ./data:/app/data
    networks:
      - internal
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    env_file: .env
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]
      interval: 5s
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - internal

networks:
  internal:
    driver: bridge

volumes:
  pgdata:
```

### Gitea + Auto-Deploy Pattern

```yaml
services:
  gitea:
    image: gitea/gitea:latest
    volumes:
      - gitea_data:/data
    ports:
      - "3000:3000"
      - "22:22"
    environment:
      - RUN_MODE=prod

  webhook-deploy:
    build: ./deploy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WEBHOOK_SECRET=${WEBHOOK_SECRET}
```

## Best Practices

- Always pin image versions (no `:latest` in production)
- Use healthchecks for dependency ordering
- Use `.env` files for environment separation
- Networks: isolate services, only expose what's needed
- Named volumes for persistent data
- Docker socket mounting only when necessary (CI/deploy)
- Keep images small — use Alpine/slim variants
- Label your images with version and date
- Scan images with Trivy or Docker Scout
