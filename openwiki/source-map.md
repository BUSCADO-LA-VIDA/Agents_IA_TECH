---
type: SourceMap
title: Source Map
description: Mapping of important files and directories to architectural components in the OpenCode agent system.
timestamp: 2025-08-10T00:00:00Z
---

# Source Map

This document maps important files and directories in the repository to their corresponding architectural components and concepts.

## Agent System Components

| File/Directory | Component | Description |
|----------------|-----------|-------------|
| `.github/agents/` | Agent Definitions | Global agent definitions shared across repositories |
| `.opencode/agents/` | Local Agent Definitions | Local agent configuration overrides |
| `.github/skills/` | Skills | Specialized capabilities organized by domain |
| `Documentacion/agents/` | Agent Documentation | Detailed specifications for each agent |
| `Documentacion/capacidad-base.md` | Base Capabilities | Foundational capabilities documentation |
| `Documentacion/memoria-proyecto.md` | Project Memory | Project history and context documentation |
| `.github/copilot-instructions.md` | Copilot Instructions | Base instructions for GitHub Copilot |
| `opencode.json` | OpenCode Configuration | Main OpenCode configuration file |
| `.github/workflows/` | Workflows | GitHub Actions workflows for automation |
| `sync-agents.ps1` | Synchronization Script | PowerShell script for agent synchronization |
| `AGENTS.md` | Agent Registry | Registry of available agents and their capabilities |
| `CLAUDE.md` | Claude Instructions | Instructions for Claude AI integration |

## Agent Categories

### Development Agents
- **API Developer** (`api-developer.agent.md` / `api-developer.md`) - API development specialist
- **Frontend Developer** (`frontend-developer.agent.md` / `frontend-developer.md`) - Frontend development specialist
- **Solucionador** (`solucionador.agent.md` / `solucionador.md`) - Remote diagnostics specialist via SSH
- **Pensador** (`pensador.agent.md` / `pensador.md`) - Thinking and reasoning specialist

### Operations Agents
- **DevOps** (`devops.agent.md` / `devops.md`) - DevOps and infrastructure specialist
- **Plataformador** (`plataformador.agent.md` / `plataformador.md`) - Platform and deployment specialist
- **GitFlow** (`gitflow.agent.md` / `gitflow.md`) - Git workflow specialist

### Quality Assurance Agents
- **QA Senior** (`qa-senior.agent.md` / `qa-senior.md`) - Senior quality assurance specialist
- **Security Auditor** (`security-auditor.agent.md` / `security-auditor.md`) - Security auditing specialist
- **Documentador** (`documentador.agent.md` / `documentador.md`) - Documentation specialist
- **Arquitecto** (`arquitecto.agent.md` / `arquitecto.md`) - Architecture specialist

## Skills Domains

| Directory | Domain | Description |
|-----------|--------|-------------|
| `api/` | API Development | Skills for API design, development, and documentation |
| `arquitectura/` | Architecture | Skills for software architecture and design patterns |
| `csharp/` | C# Development | Skills for C# programming language |
| `docker/` | Containerization | Skills for Docker containerization |
| `documentacion/` | Documentation | Skills for technical documentation |
| `frontend/` | Frontend Development | Skills for frontend web development |
| `java/` | Java Development | Skills for Java programming language |
| `python/` | Python Development | Skills for Python programming language |
| `seguridad/` | Security | Skills for security auditing and penetration testing |
| `testing/` | Testing | Skills for software testing and quality assurance |

## Documentation Structure

| Directory/File | Purpose |
|----------------|---------|
| `Documentacion/00-indice.md` | Main documentation index |
| `Documentacion/agents/*/` | Detailed specifications for each agent type |
| `Documentacion/arquitectura/` | Architectural documentation and decision records |
| `Documentacion/funcionalidades/` | Functional feature documentation |
| `Documentacion/idioma.md` | Language configuration documentation |
| `Documentacion/preferencias-git.md` | Git preferences documentation |
| `Documentacion/preferencias.md` | General preferences documentation |
| `Documentacion/referencias.md` | References and bibliography |
| `Documentacion/soluciones-conocidas.md` | Known solutions and troubleshooting |
| `Documentacion/pendientes-implementacion.md` | Pending implementation items |

## Workflow Automation

| File | Purpose |
|------|---------|
| `.github/workflows/openwiki-update.yml` | GitHub Actions workflow for OpenWiki documentation updates |
| `sync-agents.ps1` | PowerShell script for synchronizing agent definitions |

## Configuration Files

| File | Purpose |
|------|---------|
| `opencode.json` | Main OpenCode configuration including agent settings |
| `.github/copilot-instructions.md` | Base instructions for GitHub Copilot integration |
| `.opencode/agents/` | Local overrides for agent definitions |
| `.github/agents/` | Global agent definitions shared across repositories |

## Relationships

- Agents reference skills via their `.agent.md` files using the `skills` field
- Local agent definitions (`.opencode/agents/`) can override or extend global definitions (`.github/agents/`)
- Documentation in `Documentacion/agents/` provides detailed specifications matching the agent definitions
- Skills in `.github/skills/` provide executable capabilities that agents can utilize
- Workflows in `.github/workflows/` automate processes involving agent deployment and documentation updates
- The `sync-agents.ps1` script synchronizes local agent definitions with global definitions

For more detailed information about the architecture, see the [Architecture Overview](/openwiki/architecture/overview.md).