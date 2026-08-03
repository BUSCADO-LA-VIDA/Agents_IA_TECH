---
type: Guide
title: Testing Guidance
description: Guidance on testing practices for the OpenCode agent system.
timestamp: 2025-08-10T00:00:00Z
---

# Testing Guidance

This document provides guidance on testing practices for the OpenCode agent system, including how to test agents, skills, and integrations.

## Overview

Testing in the OpenCode agent system involves verifying that agents, skills, and integrations function correctly and meet their specifications. This includes unit testing of skills, integration testing of agents, and end-to-end testing of workflows.

## Testing Strategy

### 1. Skill Testing
Skills are the fundamental building blocks that agents use to perform tasks. Each skill should be thoroughly tested.

#### Unit Testing Skills
- Each skill should have unit tests that cover its core functionality
- Tests should mock any external dependencies (filesystem, git, APIs, etc.)
- Tests should cover both success and failure cases
- Example: For a file reading skill, test reading various file formats, handling missing files, and handling permissions errors

#### Integration Testing Skills
- Test skills in the context of an agent to ensure they integrate properly
- Verify that skills are correctly invoked with the expected parameters
- Check that skill outputs are correctly interpreted by the agent

### 2. Agent Testing
Agents should be tested to ensure they correctly utilize their skills and follow their defined behavior.

#### Agent Skill Utilization
- Verify that agents correctly invoke the skills listed in their definition
- Check that agents handle skill outputs appropriately
- Ensure agents follow their specified approach and guidelines

#### Agent Collaboration
- Test agents working together to solve complex tasks
- Verify that context is properly shared between agents
- Ensure that agents can delegate subtasks appropriately

### 3. Workflow Testing
Workflows (GitHub Actions) should be tested to ensure they run correctly and produce expected outcomes.

#### Workflow Validation
- Validate workflow syntax using GitHub Actions validation tools
- Test workflows on sample repositories to ensure they trigger correctly
- Verify that workflows produce expected outputs and artifacts

#### Security Workflow Testing
- Test the AgentShield workflow to ensure it properly scans agent definitions
- Verify that security issues are correctly identified and reported

### 4. Documentation Testing
Documentation should be verified for accuracy and completeness.

#### Documentation Accuracy
- Verify that agent documentation matches the agent definitions
- Check that skill documentation matches skill implementations
- Ensure that examples and usage instructions are correct

#### Documentation Completeness
- Ensure all agents have corresponding documentation
- Ensure all skills have documentation
- Verify that key concepts and processes are documented

## Testing Tools and Frameworks

### Skill Testing
- Skills can be tested using standard JavaScript/TypeScript testing frameworks (Jest, Vitest, etc.) since many skills are JavaScript/TypeScript based
- For skills that are not code-based (e.g., documentation skills), manual verification may be sufficient

### Agent Testing
- Agent testing can be done through manual interaction in GitHub Copilot Chat
- Automated testing of agents is more complex due to their reliance on the Copilot platform, but can be approximated by testing the underlying skills and logic

### Workflow Testing
- GitHub Actions workflows can be tested using the `act` tool locally
- Workflows can also be tested by pushing to test branches and using `workflow_dispatch`

### Documentation Testing
- Documentation can be validated using markdown linters (markdownlint)
- Links can be checked using link-checking tools
- Consistency can be checked by comparing with source agent definitions

## Testing Procedures

### Testing a Skill
1. Identify the skill to test and its location in `.github/skills/[domain]/[skill-name]/`
2. Review the skill implementation to understand its inputs, outputs, and side effects
3. Write unit tests that:
   - Mock any external dependencies
   - Test normal operation with various inputs
   - Test error conditions and edge cases
   - Verify that the skill uses the correct tools (read, search, edit, execute) as defined
4. Run the tests and ensure they pass
5. Update documentation if needed based on test findings

### Testing an Agent
1. Review the agent definition in `.github/agents/[agent].agent.md`
2. Identify the skills the agent is supposed to use
3. Test each skill individually (as above)
4. Test the agent in GitHub Copilot Chat by:
   - Invoking the agent for tasks that should use each of its skills
   - Verifying that the agent correctly invokes the expected skills
   - Checking that the agent follows its specified approach and guidelines
   - Verifying that the agent's output is correct and complete
5. For agent collaboration, test agents working together on complex tasks

### Testing a Workflow
1. Review the workflow file in `.github/workflows/[workflow].yml`
2. Use `act` to test the workflow locally, or push to a test branch
3. Verify that the workflow triggers on the expected events
4. Check that each step runs successfully
5. Verify that the workflow produces the expected outputs or side effects
6. For the AgentShield workflow, verify that it correctly identifies issues in agent definitions

### Testing Documentation
1. Compare agent documentation in `Documentacion/agents/[agent]/` with the agent definition in `.github/agents/[agent].agent.md`
2. Verify that all skills listed in the agent definition are documented in the agent's documentation
3. Check that examples in the documentation are accurate and work as described
4. Use a markdown linter to check for syntax errors
5. Use a link checker to verify that all links are valid

## Continuous Testing

### GitHub Actions
The repository uses GitHub Actions for continuous integration:
- The `openwiki-update.yml` workflow runs on pushes to keep documentation up to date
- The `agentshield.yml` workflow runs on changes to `.github/` to scan for security issues

### Local Development
Developers should:
- Test skills locally before submitting changes
- Test agent interactions in Copilot Chat
- Run documentation checks locally
- Test workflow changes using `act` or test branches

## Test Environments

Skills and agents should be designed to work in various environments:
- Different operating systems (Windows, macOS, Linux)
- Different Node.js versions (where applicable)
- Different repository structures and configurations

## Test Data and Mocks

When testing skills:
- Use mock filesystems or temporary directories for file operations
- Mock git operations when testing git-related skills
- Mock API calls when testing API-related skills
- Use realistic but safe test data that doesn't contain sensitive information

## Reporting Test Results

- Skill unit tests should be run as part of the skill's CI if it has one
- Agent and workflow testing is primarily manual but can be supplemented with automated checks
- Documentation validation can be automated and run in CI

## Test Coverage Goals

While strict test coverage metrics may not be practical for all skills and agents, the following goals are recommended:
- Critical skills (those used by multiple agents or for critical operations) should have high test coverage
- New skills should be tested thoroughly before being added to agents
- Documentation should be reviewed for accuracy whenever agent definitions change
- Workflows should be tested whenever they are modified

## Troubleshooting Tests

### Skill Tests Fail Due to path. Yes, here is the translation:

Test Fails Due to Missing Dependencies
- Ensure all required dependencies are installed
- Check that the skill has the correct tool permissions
- Verify that any required configuration or API keys are provided in the test environment

Tests Fail Due to Environmental Differences
- Use mocks or abstractions to isolate the code from environmental differences
- Use temporary directories for file operations
- Use environment-specific configuration in tests

Tests Pass Locally but Fail in CI
- Check for differences in Node.js versions or other tool versions
- Ensure that the CI environment has all necessary dependencies
- Check for differences in environment variables or configuration

Documentation Tests Fail Due to Broken Links
- Update links to point to correct locations
- Ensure that linked files exist and are accessible
- Use relative links where appropriate to avoid breakage when moving documentation

## See Also

- [Architecture Overview](/openwiki/architecture/overview.md) - For understanding how components fit together
- [Workflows Overview](/openwiki/workflows/overview.md) - For understanding how testing fits into workflows
- [Source Map](/openwiki/source-map.md) - For locating files related to testing
- [Domain Concepts](/openwiki/domain/concepts.md) - For understanding testing-related terminology
- [Operations Runbook](/openwiki/operations/runbook.md) - For operational procedures related to testing