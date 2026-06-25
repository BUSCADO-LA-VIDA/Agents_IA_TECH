---
name: llm-trading-agent-security
description: "Use when: securing AI/LLM trading agents, preventing prompt injection, or implementing safety for automated trading systems."
user-invocable: true
---

# LLM Trading Agent Security

## When to Activate

- When building AI-powered trading systems
- When implementing LLM-based financial decisions
- When auditing autonomous agent safety

## Core Concepts

### Risk Categories

| Risk | Mitigation |
|------|------------|
| Prompt injection | Strict input sanitization, output validation |
| Hallucination | Constrained generation, fact-checking |
| Price manipulation | Circuit breakers, position limits |
| Unauthorized trades | Multi-sig approval for trades above threshold |
| Data leakage | Never expose API keys or secrets in prompts |

### Safety Architecture

```
LLM Output → Validator → Risk Check → Circuit Breaker → Execute
    │           │            │              │
    └── Context filter    Max position   Kill switch
```

## Best Practices

- Always constrain LLM outputs to structured JSON
- Implement maximum position size and loss limits
- Require human approval for large trades
- Log all LLM decisions for audit trail
- Never give LLMs direct access to exchange APIs
- Implement kill-switch that can halt all trading
- Use read-only API keys for LLM-connected endpoints
