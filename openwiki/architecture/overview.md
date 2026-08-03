---
type: SectionIndex
title: Architecture Overview
description: Overview of the OpenCode agent system architecture including agents, skills, and configuration structure.
timestamp: 2025-08-10T00:00:00Z
---

# Architecture Overview

This document provides an overview of the OpenCode agent system architecture, including the structure of agents, skills, configurations, and documentation.

## Overview

The OpenCode agent system is organized into several key components:

1. **Agent Definitions** - Specialized agents with defined roles and capabilities
2. **Skills** - Specialized capabilities that agents can utilize
3. **Configuration** - Local and global configuration files
4. **Documentation** - Specifications and documentation for agents and skills
5. **Workflows** - Automated workflows and processes

## Agent Definitions

Agents are defined in two locations:
- **Global agent definitions** (`.github/agents/`) - Standard agent definitions shared across repositories
- **Local agent definitions** (`.opencode/agents/`) - Local overrides and customizations

Each agent is defined in a `.agent.md` file that specifies:
- Agent role and purpose
- Skills the agent can utilize
- Behavior and interaction patterns
- Integration points with other systems

## Skills

Skills are organized by domain in the `.github/skills/` directory. Each skill provides specific capabilities that agents can utilize, such as:
- API development skills
- Architecture skills
- Security auditing skills
- Testing skills
- Documentation skills
- And many others across various domains

## Configuration

Configuration files include:
- `.github/copilot-instructions.md` - Base instructions for GitHub Copilot
- `opencode.json` - OpenCode configuration
- `.opencode/agents/` - Local agent configuration overrides
- `.github/workflows/` - GitHub Actions workflows for automation

## Documentation Structure

Documentation is organized in the `Documentacion/` directory:
- `Documentacion/agents/` - Detailed specifications for each agent
- `Documentacion/arquitectura/` - Architectural documentation
- `Documentacion/funcionalidades/` - Functional feature documentation
- `Documentacion/capacidad-base.md` - Base capabilities documentation
- `Documentacion/memoria-proyecto.md` - Project memory/documentation
- And other documentation files

## Relationships

- Agents reference skills they can use in their `.agent.md` files
- Skills are implemented in the `.github/skills/` directory structure
- Local agent definitions in `.opencode/agents/` can override or extend global definitions
- Documentation in `Documentacion/` provides detailed specifications for agents and skills
- Workflows in `.github/workflows/` automate processes involving agents and skills

## Source Mapping

For a detailed mapping of files and directories to architectural components, see the [Source Map](/openwiki/source-map.md).