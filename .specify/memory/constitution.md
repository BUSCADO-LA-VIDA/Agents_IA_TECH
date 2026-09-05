# Agents IA Tech Constitution
<!-- Constitution for IA agents project working with Copilot and Opencode -->

## Core Principles

### I. Modular Agent Design
Every agent must be self-contained, independently testable, and have a clear purpose. No organizational-only agents without well-defined interfaces and documentation. Agents should be reusable across different harnesses and projects.

### II. Orchestrator Pattern
A main orchestrator must coordinate all transversal agents, enabling communication and cooperation between them. The orchestrator defines the contract for agent interactions and ensures consistent behavior across the system.

### III. Specification-Driven Development
All agent behavior must be defined in structured specifications (specs) before implementation. Specs must be machine-readable (JSON/YAML) and human-readable, serving as the single source of truth for agent behavior, capabilities, and interfaces.

### IV. Copilot/Opencode Compatibility
The project must work seamlessly with both GitHub Copilot and VS Code Opencode. Tool-agnostic design patterns must be used where possible, and any tool-specific integrations must be clearly documented and isolated.

### V. Observability and Monitoring
All agent interactions, decisions, and errors must be fully observable. Structured logging, tracing, and monitoring are non-negotiable. Every agent must emit traceable events for its lifecycle events, decisions, and errors.

## Additional Constraints

### Technology Stack Requirements
The project must use TypeScript for agent implementation, with JSON-based specification files. All agents must follow the defined specification format and use the centralized orchestrator for transversal communication. Node.js 18+ is required. The project must maintain compatibility with both the Copilot and Opencode extension APIs.

### Agent Communication Protocols
All inter-agent communication must go through the main orchestrator. Direct agent-to-agent communication is prohibited unless explicitly authorized by the orchestrator. Communication contracts must be versioned and backward-compatible.

## Development Workflow

### Agent Lifecycle
1. Define agent specification in `Documentacion/funcionalidades/`
2. Generate skeleton via `/speckit-specify` 
3. Implement agent following the spec
4. Run integration tests via `/speckit-converge`
5. Submit PR with mandatory code review

### Code Review Requirements
All PRs must verify compliance with the constitution principles. Complexity must be justified and documented. No new agent may be merged without passing all constitution compliance checks.

### Quality Gates
- Minimum 80% test coverage across all agents
- All specs must be validated before implementation
- Orchestrator integration tests must pass
- Cross-agent compatibility tests must pass

## Governance

**Constitution supersedes all other practices.** Amendments require documentation, approval, and migration plan.

**Amendment Procedure:**
1. Proposer drafts principle/section revision in `Documentacion/`
2. 30-day review period for all stakeholders
3. Supermajority (2/3) of architectural board approval required
4. Version increment follows semantic versioning:
   - MAJOR: Backward incompatible governance/principle removals or redefinitions
   - MINOR: New principle/section added or materially expanded guidance  
   - PATCH: Clarifications, wording, typo fixes, non-semantic refinements

**Version**: 1.0.0 | **Ratified**: 2026-08-25 | **Last Amended**: 2026-08-25
