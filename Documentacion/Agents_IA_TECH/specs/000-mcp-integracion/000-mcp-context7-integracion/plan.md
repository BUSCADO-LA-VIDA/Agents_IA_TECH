# Implementation Plan: [008-context7-mcp-integration] — Integración oficial de Context7 MCP

**Branch**: `008-context7-mcp-integration` | **Date**: 2026-09-28 | **Spec**: [spec.md](./spec.md)

## Summary

Integración de Context7 MCP siguiendo el patrón de la spec 007:
- Añadir entrada `context7` a la plantilla `opencode.json` con `{env:CONTEXT7_CMD}`.
- Extender `Ensure-McpEnvFile` y `Ensure-OpenCodeMcp` para resolver `context7`.
- Fail-open con WARN y comando de instalación.

## Technical Context

- Language: PowerShell 7+
- Archivos: `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`
- Herramienta externa: `@upstash/context7-mcp`

## Decisiones de diseño

D1 — Registrar entrada `context7` en plantilla `opencode.json` con `enabled: false` y `command: ["{env:CONTEXT7_CMD}"]`.
D2 — Extender resolución en `Ensure-McpEnvFile` para `CONTEXT7_CMD`.
D3 — Guard en `Ensure-OpenCodeMcp` para ausente → WARN + no registrar.

## Cambios por archivo

`scripts/plataformador-bootstrap.ps1`
- Extender `Ensure-McpEnvFile` con variable `CONTEXT7_CMD`.
- Añadir detección `context7` en `Ensure-OpenCodeMcp` con fail-open.

`opencode.json`
- Añadir entrada `context7` con `{env:CONTEXT7_CMD}`.

`.gitignore`
- `.env.mcp` ya cubre.

## Estrategia de pruebas

T-01 Idempotencia: dos corridas → mismo bloque mcp.
T-02 Resolución: herramienta instalada → enabled true.
T-03 Fallback: herramienta ausente → WARN + no registro.

