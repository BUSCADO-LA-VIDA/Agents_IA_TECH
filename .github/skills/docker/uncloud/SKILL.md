---
name: uncloud
description: "Use when: migrating from cloud to self-hosted infrastructure, or designing on-premise deployments."
user-invocable: true
---

# Uncloud

## When to Activate

- When migrating from cloud services to self-hosted
- When designing on-premise infrastructure
- When replacing SaaS with docker-compose equivalents

## Core Concepts

### Self-Hosted Replacements

| Cloud Service | Self-Hosted Alternative |
|---------------|------------------------|
| GitHub | Gitea |
| GitHub Actions | Gitea Actions / Drone CI |
| Docker Hub | Self-hosted registry |
| S3 | MinIO |
| PostgreSQL RDS | PostgreSQL in Docker |
| Redis | Redis in Docker |
| Cloud DNS | Bind9 / Pi-hole |
| Sentry | Self-hosted Sentry |
| Slack | Mattermost |

## Best Practices

- Start with docker-compose — add orchestration only when needed
- Use reverse proxy (Nginx, Caddy, Traefik) for routing
- Automate backups to external storage
- Monitor with Uptime Kuma + self-hosted Grafana
- Document your infra in a runbook
