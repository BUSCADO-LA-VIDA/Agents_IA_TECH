---
name: security-scan
description: "Use when: running automated security scanners, analyzing dependency vulnerabilities, or auditing code for security issues."
user-invocable: true
---

# Security Scan

## When to Activate

- Before running security scans
- When analyzing vulnerability reports
- When configuring CI/CD security pipelines
- After adding new dependencies
- Before production releases

## Core Concepts

### Scan Types

| Scan | Tool | Frequency |
|------|------|-----------|
| Dependency audit | `npm audit`, `pip-audit`, `dotnet list vulnerabilities` | Every build |
| SAST (Static Analysis) | SonarQube, Semgrep, CodeQL | Per PR |
| Secret detection | GitLeaks, TruffleHog, `ecc-agentshield` | Per commit |
| Lint security rules | ESLint security plugin, Bandit (Python) | Per commit |
| Container scan | Trivy, Docker Scout | Per deployment |

### Scan Pipeline

```
Commit → Secret scan → SAST → Dep audit → Container scan → Deploy
```

## Best Practices

- Fail the build on CRITICAL/HIGH vulnerabilities
- Generate SBOM (Software Bill of Materials) for every release
- Keep a vulnerability database (`docs/security/advisories.md`)
- Schedule regular full scans (weekly)
- Rotate exposed secrets immediately
