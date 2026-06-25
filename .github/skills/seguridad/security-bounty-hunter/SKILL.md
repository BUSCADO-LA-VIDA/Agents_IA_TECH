---
name: security-bounty-hunter
description: "Use when: performing bug bounty-style security testing, penetration testing, or vulnerability research."
user-invocable: true
---

# Security Bounty Hunter

## When to Activate

- When doing penetration testing
- When hunting for vulnerabilities
- When assessing application security posture
- Before public release

## Core Concepts

### Methodology

1. **Reconnaissance** — map the attack surface (endpoints, inputs, auth)
2. **Threat Modeling** — identify potential attack vectors
3. **Fuzzing** — test inputs with unexpected/malformed data
4. **Privilege Escalation** — test authorization boundaries
5. **Business Logic** — test workflow manipulation
6. **Reporting** — document findings with PoC

### Common Vulnerabilities to Check

- IDOR (Insecure Direct Object Reference)
- Broken authentication
- Mass assignment
- SSTI / template injection
- Path traversal
- SSRF
- Race conditions
- Business logic bypasses

## Best Practices

- Report findings responsibly — disclose to maintainers first
- Include reproduction steps in reports
- Test in isolation — don't affect production data
- Keep a security research journal
- Follow responsible disclosure timelines (typically 90 days)
