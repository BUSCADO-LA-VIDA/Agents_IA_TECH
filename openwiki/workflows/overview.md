---
type: Overview
title: Workflows Overview
description: Overview of key workflows and procedures in the OpenCode agent system.
timestamp: 2025-08-10T00:00:00Z
---

# Key Workflows

This document outlines the key workflows and procedures in the OpenCode agent system, including how agents interact, how skills are utilized, and how automation is implemented.

## Overview

The OpenCode agent system implements several key workflows that enable agents to collaborate effectively and perform complex development tasks. These workflows leverage the agent specifications, skills, and configuration to provide a cohesive development assistant experience.

## Core Workflows

### 1. Agent Collaboration Workflow

This workflow defines how different agents collaborate to solve complex development tasks:

1. **Task Initiation**: A user initiates a task via GitHub Copilot Chat using a slash command or agent selection
2. **Agent Selection**: The appropriate agent(s) are selected based on the task requirements
3. **Skill Activation**: Selected agents activate relevant skills from their skill set
4. **Collaboration**: Multiple agents may collaborate, sharing information and building upon each other's work
5. **Result Synthesis**: Results are synthesized and presented to the user
6. **Feedback Loop**: User feedback can trigger additional iterations or refinements

### 2. Skill Utilization Workflow

This workflow describes how agents utilize skills to perform specific tasks:

1. **Skill Identification**: An agent identifies which skills are needed for a task
2. **Skill Activation**: The agent activates the relevant skills from the `.github/skills/` directory
3. **Skill Execution**: The skill executes its functionality (e.g., code generation, analysis, testing)
4. **Result Integration**: The agent integrates the skill's output into its response
5. **Skill Chaining**: Multiple skills can be chained together for complex operations

### 3. Configuration Synchronization Workflow

This workflow describes how agent configurations are synchronized between global and local definitions:

1. **Global Definition Update**: Changes are made to agent definitions in `.github/agents/`
2. **Sync Trigger**: The `sync-agents.ps1` script is run manually or via automation
3. **Local Override Preservation**: Local overrides in `.opencode/agents/` are preserved
4. **Conflict Resolution**: Conflicts are resolved according to defined precedence rules
5. **Local Update**: Local agent definitions are updated with global changes while preserving overrides

### 4. Documentation Synchronization Workflow

This workflow describes how documentation is kept synchronized with agent definitions:

1. **Agent Definition Update**: Agent definitions are updated in `.github/agents/`
2. **Documentation Update**: Corresponding documentation is updated in `Documentacion/agents/`
3. **Automation Trigger**: The `openwiki-update.yml` workflow can be triggered to update documentation
4. **Consistency Check**: Documentation is verified to match agent definitions

### 5. Skill Development Workflow

This workflow describes how new skills are developed and integrated:

1. **Skill Identification**: A need for a new skill is identified
2. **Skill Development**: The skill is developed in the appropriate domain directory under `.github/skills/`
3. **Documentation**: Documentation is added for the new skill
4. **Agent Integration**: Agents are updated to reference the new skill in their definitions
5. **Testing**: The skill is tested to ensure it functions correctly

## Automation Workflows

### GitHub Actions Workflows

The repository includes GitHub Actions workflows that automate various processes:

1. **OpenWiki Update Workflow** (`.github/workflows/openwiki-update.yml`)
   - Automatically updates OpenWiki documentation when repository changes occur
   - Triggers on pushes to main branch
   - Generates updated documentation based on current repository state

2. **Agent Shield Workflow** (`.github/workflows/agentshield.yml`)
   - Provides security scanning for agent definitions and configurations
   - Helps ensure agent definitions follow security best practices

## Manual Procedures

### Agent Synchronization Procedure

1. Open PowerShell in the repository root
2. Run `.\sync-agents.ps1` to synchronize local agent definitions with global definitions
3. Review any conflicts that are reported
4. Commit changes to `.opencode/agents/` if local overrides were modified

### Documentation Update Procedure

1. Make changes to agent definitions in `.github/agents/`
2. Update corresponding documentation in `Documentacion/agents/`
3. Optionally run the OpenWiki update workflow to generate updated wiki documentation
4. Commit changes to both agent definitions and documentation

## Integration Points

The agent system integrates with several external systems:

1. **GitHub Copilot**: Primary interface for agent interaction via chat and slash commands
2. **GitHub Actions**: For automation of documentation updates and security checks
3. **PowerShell**: For local agent synchronization scripts
4. **Various Linters and Tools**: Through skills that integrate with development tools

## Data Flow

1. **Input**: User interacts with GitHub Copilot Chat
2. **Processing**: 
   - Copilot routes request to appropriate agent based on agent selection or slash command
   - Agent consults its definition to determine available skills
   - Agent activates and executes relevant skills
   - Skills may interact with local filesystem, git repository, or external tools
3. **Output**: Agent returns response to user via Copilot Chat
4. **Feedback**: User feedback can trigger additional processing rounds

## Error Handling

Workflows include error handling mechanisms:

1. **Skill Execution Errors**: Skills return error information that agents can relay to users
2. **Configuration Conflicts**: Synchronization scripts identify and report configuration conflicts
3. **Automation Failures**: GitHub workflows include error handling and notification mechanisms
4. **Fallback Mechanisms**: Agents can fall back to basic functionality when skills fail

## Performance Considerations

1. **Skill Loading**: Skills are loaded on-demand to minimize initialization time
2. **Caching**: Frequently used skill results may be cached for performance
3. **Async Processing**: Long-running operations can be performed asynchronously where supported
4. **Resource Limits**: Agents and skills operate within defined resource limits to prevent system overload

## See Also

- [Architecture Overview](/openwiki/architecture/overview.md) - For architectural context
- [Source Map](/openwiki/source-map.md) - For file-to-component mapping
- [Domain Concepts](/openwiki/domain/concepts.md) - For terminology and concepts used in workflows
- [Operations Runbook](/openwiki/operations/runbook.md) - For detailed operational procedures