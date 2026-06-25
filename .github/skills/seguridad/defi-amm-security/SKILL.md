---
name: defi-amm-security
description: "Use when: auditing DeFi protocols, reviewing smart contract security, or analyzing AMM vulnerabilities."
user-invocable: true
---

# DeFi AMM Security

## When to Activate

- When auditing DeFi smart contracts
- When analyzing AMM (Automated Market Maker) implementations
- When reviewing token economics and liquidity pools

## Core Concepts

### Common DeFi Vulnerabilities

| Vulnerability | Description |
|---------------|-------------|
| Re-entrancy | Recursive external calls draining funds |
| Flash loan attacks | Manipulating prices via uncollateralized loans |
| Oracle manipulation | Tampering with price feeds |
| Sandwich attacks | Front-running transactions |
| Impermanent loss | LP value divergence |
| Rug pull | Malicious contract owner |

### Security Checklist

- [ ] Use Checks-Effects-Interactions pattern
- [ ] Implement re-entrancy guards
- [ ] Use decentralized oracles (Chainlink)
- [ ] Timelocks on administrative functions
- [ ] Multi-sig for contract upgrades
- [ ] Formal verification where possible

## Best Practices

- Never trust external contract calls
- Always validate return values from external calls
- Use OpenZeppelin audited contracts as base
- Implement emergency pause mechanisms
- Get multiple professional audits before mainnet
- Bug bounty program before launch
