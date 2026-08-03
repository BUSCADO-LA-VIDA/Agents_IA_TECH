---
type: Concepts
title: Domain Concepts
description: Key domain concepts and terminology used in the OpenCode agent system.
timestamp: 2025-08-10T00:00:00Z
---

# Domain Concepts

This document explains key domain concepts and terminology used throughout the OpenCode agent system documentation.

## Core Concepts

### Agent
An autonomous AI assistant specialized in a specific domain (e.g., API development, architecture, DevOps) that can be invoked via GitHub Copilot Chat. Agents have defined skills, tools, and behavioral guidelines specified in their agent definition files.

### Skill
A specialized capability that agents can utilize to perform specific tasks. Skills are organized by domain (e.g., api, arquitectura, python) and contain executable functionality such as code generation, analysis, or integration with external tools.

### Agent Definition
A Markdown file (`.agent.md`) that defines an agent's:
- Description and use cases
- Available skills
- Behavioral guidelines and approach
- Language and output expectations
- Restrictions and constraints

### Agent Collaboration
The process where multiple agents work together to solve complex tasks, leveraging their respective skills and expertise. Collaboration is facilitated through shared context and sequential or parallel execution.

### Design-First Approach
A methodology emphasized by the Arquitecto agent where design decisions are made and documented (often as Architecture Decision Records - ADRs) before implementation begins.

### Skill-First Approach
An approach where agents first identify and activate relevant skills before attempting to solve a problem, leveraging pre-built capabilities rather than implementing from scratch.

## Agent Categories

### Development Agents
Focused on creating and modifying code:
- **API Developer**: Specializes in backend API development, RESTful design, database schemas, and API connectors
- **Frontend Developer**: Specializes in frontend technologies, UI/UX implementation, and client-side development
- **Solucionador**: Specializes in remote diagnostics and troubleshooting via SSH connections

### Operations Agents
Focused on deployment, infrastructure, and workflows:
- **DevOps**: Specializes in infrastructure, deployment pipelines, and operational practices
- **Plataformador**: Specializes in platform engineering, deployment strategies, and environment management
- **GitFlow**: Specializes in Git workflows, branching strategies, and release management

### Quality Assurance Agents
Focused on quality, security, and correctness:
- **QA Senior**: Specializes in testing strategies, quality assurance processes, and test automation
- **Security Auditor**: Specializes in security auditing, vulnerability assessment, and security best practices
- **Documentador**: Specializes in technical documentation, knowledge management, and documentation standards
- **Arquitecto**: Specializes in software architecture, design patterns, and technical decision-making

## Skills Domains

### API Skills
Skills related to API development including RESTful design, OpenAPI specification, API connectors, and backend patterns.

### Architecture Skills
Skills related to software architecture including Architecture Decision Records (ADRs), hexagonal/clean architecture, coding standards, and production auditing.

### Language-Specific Skills
Skills specific to programming languages including C#, Java, and Python development practices.

### Infrastructure Skills
Skills related to infrastructure and deployment including Docker containerization, deployment strategies, and environment management.

### Documentation Skills
Skills related to technical documentation including writing standards, documentation lookup, and knowledge operations.

### Testing Skills
Skills related to software testing including test automation, quality assurance practices, and testing methodologies.

### Security Skills
Skills related to security including vulnerability assessment, security auditing, and secure coding practices.

## Key Artifacts

### Agent Specification Files
Located in `.github/agents/`, these files define the global agent definitions shared across repositories.

### Local Agent Overrides
Located in `.opencode/agents/`, these files can override or extend global agent definitions for repository-specific customization.

### Agent Documentation
Located in `Documentacion/agents/`, these directories contain detailed specifications and documentation for each agent type.

### Skill Directories
Located in `.github/skills/`, these directories contain executable skills organized by domain.

### Configuration Files
- `opencode.json`: Main OpenCode configuration
- `.github/copilot-instructions.md`: Base instructions for GitHub Copilot
- `sync-agents.ps1`: PowerShell script for agent synchronization
- `AGENTS.md`: Registry of available agents

## Key Processes

### Agent Invocation
Users invoke agents via GitHub Copilot Chat by:
1. Selecting an agent from the agent selector (alongside the chat input)
2. Using slash commands that route to specific agents
3. Having agents invoke other agents via the `agent` tool in their definitions

### Skill Execution
When an agent executes a skill:
1. The agent identifies the needed skill from its definition
2. The skill is loaded from `.github/skills/[domain]/[skill-name]/`
3. The skill executes with access to reading, searching, editing, and executing files as permitted by its tool permissions
4. The skill returns results that the agent incorporates into its response

### Configuration Synchronization
The `sync-agents.ps1` script:
1. Compares global agent definitions (`.github/agents/`) with local overrides (`.opencode/agents/`)
2. Applies updates from global definitions while preserving local overrides
3. Reports any conflicts that require manual resolution

### Documentation Synchronization
Documentation in `Documentacion/agents/` is maintained to match the agent definitions in `.github/agents/` through manual updates or automated workflows.

## Relationships Between Concepts

### Agent → Skill
Agents declare which skills they can use in their definition files under the `skills` section.

### Agent → Agent
Agents can invoke other agents using the `agent` tool, enabling collaboration and specialization chaining.

### Skill → Tool
Skills utilize tools (read, search, edit, execute, agent) to perform their functions, with tool permissions defined in the skill's metadata.

### Documentation → Agent
Documentation in `Documentacion/agents/` provides detailed specifications that complement and elaborate on the agent definitions.

### Configuration → Agent
Local agent definitions (`.opencode/agents/`) can override or extend global definitions (`.github/agents/`) to tailor behavior to specific repository needs.

## Terminology

- **ADR**: Architecture Decision Record - a document that captures an architectural decision including context, decision, and consequences
- **YAGNI**: "You Aren't Gonna Need It" - principle of avoiding unnecessary complexity
- **API-first**: Approach of designing the API contract before implementing the underlying service
- **Design-first**: Approach of creating designs and documentation before writing implementation code
- **Hexagonal Architecture**: Also known as Ports and Adapters pattern, focuses on separating core logic from external concerns
- **Slash Commands**: Commands prefixed with `/` that can be invoked in GitHub Copilot Chat to trigger specific agent behaviors or workflows
- **Agent Shield**: Security scanning workflow that validates agent definitions for security best practices
- **OpenWiki**: The documentation system being generated to provide a navigable knowledge base of the repository

## See Also

- [Architecture Overview](/openwiki/architecture/overview.md) - For how these concepts are realized in the system architecture
- [Workflows Overview](/openwiki/workflows/overview.md) - For how these concepts are used in operational workflows
- [Source Map](/openwiki/source-map.md) - For mapping of files and directories to architectural components
- [Operations Runbook](/openwiki/operations/runbook.md) - For operational procedures involving these concepts