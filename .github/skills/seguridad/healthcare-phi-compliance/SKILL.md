---
name: healthcare-phi-compliance
description: "Use when: handling Protected Health Information (PHI), implementing healthcare data privacy, or auditing PHI access."
user-invocable: true
---

# Healthcare PHI Compliance

## When to Activate

- When designing systems that store or process PHI
- When auditing PHI access patterns
- When implementing de-identification
- When setting up data retention policies

## Core Concepts

### PHI Identifiers

18 identifiers that make data PHI:
1. Names
2. Geographic subdivisions smaller than a state
3. Dates (except year) related to individuals
4. Phone/fax numbers
5. Email addresses
6. SSN
7. Medical record numbers
8. Health plan numbers
9. Account numbers
10. Certificate/license numbers
11. Vehicle identifiers
12. Device identifiers
13. URLs
14. IP addresses
15. Biometric identifiers
16. Full-face photos
17. Any other unique identifying number/code

### De-identification Methods

| Method | Standard | Risk |
|--------|----------|------|
| Safe Harbor | Remove all 18 identifiers | Low |
| Expert Determination | Statistical verification | Very low |

## Best Practices

- Minimize PHI collection — only what's necessary
- Use de-identification whenever possible
- Implement strict access controls (role-based)
- Audit all PHI access automatically
- Encrypt PHI at rest (AES-256) and in transit (TLS 1.3)
- Never include PHI in logs, error messages, or analytics
