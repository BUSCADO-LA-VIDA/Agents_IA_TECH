# Implementation Plan: 000-mcp-github-integracion

**Origen**: https://github.com/github/github-mcp-server

## Overview
Plan de implementación para integración de GitHub MCP.

## Technical Context
- Patrón tokens {env:...}
- Bootstrap Ensure-OpenCodeMcp / Resolve-McpCommand
- .env.mcp gitignored

## Architecture
Entrada MCP idempotente en opencode.json, .opencode/mcp.json, .vscode/mcp.json

## Tasks
1. Actualizar plantilla opencode.json
2. Extender bootstrap para resolver GITHUB_MCP_CMD
3. Añadir verificación fail-open
4. Documentar quickstart

## Dependencies
007-mcp-token-resolution

## Risks
Herramienta no instalada → WARN requerido
