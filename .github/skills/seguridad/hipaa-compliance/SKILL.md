---
name: hipaa-compliance
description: "Use when: working with healthcare data, ensuring HIPAA compliance, or implementing PHI protection."
user-invocable: true
---

# HIPAA Compliance

## When to Activate

- When handling Protected Health Information (PHI)
- When designing healthcare applications
- When auditing existing systems for HIPAA compliance
- When configuring data storage for medical records

## Core Concepts

### HIPAA Rules

| Rule | Requirement |
|------|-------------|
| Privacy Rule | PHI access control and disclosure limits |
| Security Rule | Administrative, physical, technical safeguards |
| Breach Notification | Notify patients within 60 days |
| Enforcement | Penalties for non-compliance |

### Technical Safeguards

- **Access Control** — unique user IDs, emergency access, automatic logoff
- **Audit Controls** — record all PHI access and activity
- **Integrity Controls** — prevent improper PHI alteration
- **Transmission Security** — encrypt all PHI in transit
- **Encryption at Rest** — AES-256 for stored PHI

## Best Practices

- Encrypt everything — PHI at rest and in transit
- Log all access to PHI — who, what, when
- Implement automatic session timeout
- Conduct annual risk assessments
- Sign BAAs with all third-party vendors handling PHI
- Never log PHI to debug logs, error reports, or analytics
