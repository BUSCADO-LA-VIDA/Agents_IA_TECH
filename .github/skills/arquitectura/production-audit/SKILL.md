---
name: production-audit
description: "Use when: auditing production systems, reviewing deployment health, or checking production readiness."
user-invocable: true
---

# Production Audit

## When to Activate

- Before production deployment
- Auditing existing production systems
- Checking production readiness
- Post-incident review

## Core Concepts

### Production Readiness Checklist

- [ ] Health check endpoint (`/health` or `/ping`)
- [ ] Metrics exposed (Prometheus, /metrics)
- [ ] Structured logging (JSON format)
- [ ] Error tracking (Sentry, etc.)
- [ ] Rate limiting on all public endpoints
- [ ] Database connection pooling
- [ ] Caching layer configured
- [ ] Backups automated and tested
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Runbook for common incidents
- [ ] Security headers configured

### Post-Incident Review

1. **Timeline** — what happened, when, in what order
2. **Root cause** — why did it happen?
3. **Impact** — what was affected? users, data, revenue?
4. **Action items** — what will prevent recurrence?
5. **Follow-up** — who owns each action item?

## Best Practices

- Automate production readiness checks
- Runbook should fit in one page
- Test rollback procedures regularly
- Document incident response steps
- Monitor after every deployment (watch metrics for 15 min)
