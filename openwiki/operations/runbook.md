---
type: Runbook
title: Operations Runbook
description: Operational procedures and runbook for the OpenCode agent system.
timestamp: 2025-08-10T00:00:00Z
---

# Operations Runbook

This document outlines operational procedures and runbook information for maintaining and operating the OpenCode agent system.

## Overview

The OpenCode agent system requires certain operational procedures to maintain its functionality, update agent definitions, synchronize configurations, and ensure proper functioning of the agent ecosystem.

## Routine Operations

### 1. Agent Synchronization

Regular synchronization ensures local agent definitions stay in sync with global definitions while preserving local overrides.

**Procedure:**
1. Open PowerShell in the repository root
2. Execute the synchronization script:
   ```powershell
   .\sync-agents.ps1
   ```
3. Review the output for any conflicts that need manual resolution
4. If conflicts are reported, manually resolve them in the `.opencode/agents/` directory
5. Commit changes to `.opencode/agents/` if local overrides were modified
6. Commit changes to `.github/agents/` if global definitions were updated (typically done separately)

**Frequency:** As needed, or when global agent definitions are updated

### 2. Documentation Updates

Keeping documentation in sync with agent definitions ensures accuracy.

**Procedure:**
1. Update agent definitions in `.github/agents/` as needed
2. Update corresponding documentation in `Documentacion/agents/` to reflect changes
3. Optionally trigger the OpenWiki update workflow to regenerate documentation:
   - Push changes to trigger the `.github/workflows/openwiki-update.yml` workflow
   - Or manually trigger the workflow via GitHub Actions UI
4. Verify generated documentation in `/openwiki/` is correct
5. Commit documentation changes

**Frequency:** Whenever agent definitions are updated

### 3. Skill Management

Managing skills ensures agents have access to necessary capabilities.

**Procedure:**
1. To add a new skill:
   - Create the skill directory under `.github/skills/[domain]/[skill-name]/`
   - Implement the skill functionality following the skill template
   - Add skill documentation
   - Update agent definitions in `.github/agents/` to include the new skill where appropriate
   - Update corresponding agent documentation in `Documentacion/agents/`
2. To update an existing skill:
   - Modify the skill implementation in `.github/skills/[domain]/[skill-name]/`
   - Update documentation if needed
   - Verify agents using the skill still function correctly
3. To remove a skill:
   - Remove the skill from all agent definitions that reference it
   - Remove the skill directory from `.github/skills/`
   - Update corresponding agent documentation

**Frequency:** As needed for capability enhancement

### 4. Workflow Maintenance

GitHub Actions workflows require occasional maintenance.

**Procedure:**
1. Review workflow files in `.github/workflows/` periodically
2. Update workflows as needed for:
   - Changes in automation requirements
   - Updates to actions or tools used
   - Changes in branch protection or trigger conditions
3. Test workflow changes by pushing to a test branch or using workflow_dispatch
4. Monitor workflow runs in GitHub Actions tab for failures

**Frequency:** Quarterly or as issues arise

## Troubleshooting

### Common Issues

#### 1. Agent Not Responding Correctly
**Symptoms:** Agent provides unexpected responses or fails to use expected skills
**Diagnosis:**
1. Check agent definition in `.github/agents/` for correct skills listing
2. Verify local overrides in `.opencode/agents/` aren't causing conflicts
3. Check that referenced skills exist in `.github/skills/`
4. Verify skill has correct tool permissions for intended operations
**Resolution:**
1. Correct agent definition if skills are missing or incorrect
2. Resolve any conflicts in local overrides
3. Install or fix missing skills
4. Adjust skill tool permissions as needed

#### 2. Synchronization Conflicts
**Symptoms:** `sync-agents.ps1` reports conflicts during synchronization
**Diagnosis:**
1. Script will show specific files with conflicts
2. Compare `.github/agents/[agent].agent.md` with `.opencode/agents/[agent].agent.md`
**Resolution:**
1. Manually edit the local file to preserve desired overrides while incorporating upstream changes
2. Or delete local override if no longer needed
3. Re-run synchronization to confirm resolution

#### 3. Skill Execution Failures
**Symptoms:** Skills fail to execute or return errors
**Diagnosis:**
1. Check skill implementation for syntax errors or logical issues
2. Verify skill has necessary tool permissions (read, search, edit, execute)
3. Check if skill requires external dependencies or API keys
4. Review skill documentation for usage requirements
**Resolution:**
1. Fix skill implementation issues
2. Adjust tool permissions in skill definition
3. Provide required dependencies or configuration
4. Update skill documentation if usage instructions if API or requirements have changed

#### 4. Documentation Mismatch
**Symptoms:** Generated documentation doesn't match current agent definitions
**Diagnosis:**
1. Compare agent definitions in `.github/agents/` with documentation in `Documentacion/agents/`
2. Check if OpenWiki workflow has run recently
**Resolution:**
1. Update documentation to match agent definitions
2. Trigger OpenWiki update workflow to regenerate wiki documentation
3. Commit both documentation and wiki updates

## Monitoring

### Health Checks

1. **Agent Definition Validity**: Periodically validate that all agent definition files are valid YAML with required fields
2. **Skill Availability**: Ensure all skills referenced by agents exist in `.github/skills/`
3. **Workflow Status**: Monitor GitHub Actions workflows for failures
4. **Synchronization Status**: Regularly run sync script to detect drift

### Logging

1. **GitHub Actions Logs**: Available in the Actions tab for each workflow run
2. **Skill Execution Output**: Visible in Copilot Chat when skills are invoked
3. **Synchronization Script Output**: Visible in PowerShell console when running `sync-agents.ps1`

## Backup and Recovery

### Backup Procedures

1. **Agent Definitions**: Back up `.github/agents/` and `.opencode/agents/` directories
2. **Skills**: Back up `.github/skills/` directory
3. **Documentation**: Back up `Documentacion/` directory
4. **Workflows**: Back up `.github/workflows/` directory
5. **Configuration**: Back up `opencode.json` and other configuration files

### Recovery Procedures

1. **From Backup**: Restore backed up directories to their respective locations
2. **Verify Integrity**: Run synchronization script to ensure consistency
3. **Validate Functionality**: Test agent interactions to ensure proper operation
4. **Regenerate Documentation**: Trigger OpenWiki update if needed

## Security Considerations

### Agent Definition Security

1. **Tool Permissions**: Review agent and skill tool permissions to ensure principle of least privilege
2. **External Access**: Monitor skills that access external systems or APIs for proper authentication and authorization
3. **File Access**: Ensure agents and skills only access necessary files and directories

### Workflow Security

1. **Action Versions**: Use specific versions of GitHub Actions rather than tags when possible
2. **Secrets Management**: Ensure any secrets used in workflows are properly stored in GitHub Secrets
3. **Code Review**: Review workflow changes for security implications

## Contact Information

For questions about operating the OpenCode agent system, refer to:
- The [agent specifications](./.github/agents/)
- The [agent documentation](./Documentacion/agents/)
- The [skills documentation](./.github/skills/)
- The [copilot instructions](./.github/copilot-instructions.md)