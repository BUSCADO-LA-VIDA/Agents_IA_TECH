# Implementation Plan: MCP Update Lifecycle — Script independiente de actualización de MCPs con auto-actualización diaria

**Branch**: `009-mcp-update-lifecycle` | **Date**: 2026-09-24 | **Spec**: Documentacion/Agents_IA_TECH/specs/009-mcp-update-lifecycle/spec.md

**Input**: Feature specification from Documentacion/Agents_IA_TECH/specs/009-mcp-update-lifecycle/spec.md

**Note**: Plan generado para feature de tooling de plataforma. No hay src/; cambios en scripts/ y documentación.

## Summary

La feature crea `scripts/update-mcp.ps1` como script independiente que gestiona instalación, actualización y activación de MCPs, con auto-actualización diaria basada en `.bootstrap-state.json`. El script es invocable desde `plataformador-bootstrap.ps1` y por el agente `pensador`, manteniendo idempotencia y reporte por MCP. Reutiliza el inventario central `.env.mcp` y respeta los guardrails de portabilidad.

## Technical Context

**Language/Version**: PowerShell 7+

**Primary Dependencies**: `git`, `npm`, `python`, `node`, `uv`. Opcionales, fail-open.

**Storage**: Archivos de configuración por proyecto:
- `scripts/update-mcp.ps1` (nuevo)
- `.bootstrap-state.json` (gitignored, estado de última actualización)
- `.env.mcp` (inventario central de rutas)
- `opencode.json` / `.vscode/mcp.json` (configuración de MCPs)

**Testing**: Sin framework de tests. Validación por escenarios reproducibles y DryRun.

**Target Platform**: Windows win32 con PowerShell 7+

**Project Type**: Tooling / script de plataforma

**Performance Goals**: Ejecución <2 min en caso típico; idempotente.

**Constraints**: No commitear rutas absolutas; fail-open; retrocompatibilidad; no borrar a ciegas.

**Scale/Scope**: 1 script nuevo + integración en bootstrap + regla en pensador.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación | Estado |
|-----------|-----------|--------|
| I. Modular Agent Design | Script independiente, autocontenido. | ✅ PASS |
| II. Orchestrator Pattern | Pensador puede delegar actualización. | ✅ PASS |
| III. Specification-Driven Development | Spec precede implementación. | ✅ PASS |
| IV. Copilot/Opencode Compatibility | Usa inventario central `.env.mcp`. | ✅ PASS |
| V. Observability and Monitoring | Reporte por MCP con estado/razón. | ✅ PASS |
| VI. proyect_ext / Dependencias Externas | Mantiene containment. | ✅ PASS |

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/009-mcp-update-lifecycle/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
scripts/
├── plataformador-bootstrap.ps1   # Invoca update-mcp.ps1 (usa funciones compartidas)
├── update-mcp.ps1                # Script principal independiente
└── mcp-functions.ps1             # Funciones compartidas (Resolve-McpCommand, Ensure-McpEnvFile, Update-McpEnvFile, Ensure-OpenCodeMcp)

.bootstrap-state.json             # Estado de última actualización, gitignored
.env.mcp                          # Inventario central de rutas, gitignored
opencode.json                     # Config portable
.vscode/mcp.json                  # Config Copilot
```

**Structure Decision**: Tooling de plataforma sin src/. Las funciones MCP compartidas evitan duplicación entre bootstrap y update-mcp.ps1.

## Complexity Tracking

No violations. Se reutiliza `.env.mcp` y `.bootstrap-state.json` existentes.
