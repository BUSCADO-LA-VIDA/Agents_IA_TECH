# Implementation Plan: post-platforming-speckit

**Branch**: `006-post-platforming-speckit` | **Date**: 2026-09-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-post-platforming-speckit/spec.md`

**Note**: Este plan lo completa el comando `/speckit-plan`; su definición describe el flujo de ejecución.

## Summary

Definir el flujo que sigue el `pensador` después de que el bootstrap plataforma un proyecto, para llevarlo al pipeline speckit según su estado. Cubre 3 escenarios (A nuevo desde idea / B existente con docs a migrar / C existente sin docs), la re-indexación automática de MCPs + Graphify al aprobar artefactos, la Constitution específica por proyecto, la estrategia de Graphify por aplicación, y la actualización de memoria (índices + grafo) automática diaria y manual.

## Technical Context

**Language/Version**: PowerShell 7+ (scripts bootstrap), Markdown/YAML (documentación), Python 3.10+ (graphify)

**Primary Dependencies**: `plataformador-bootstrap.ps1`, `graphify` (v0.9.48), `context-mode` (v1.0.169), `codebase-memory-mcp` (v0.9.0), `markitdown` (v0.1.7), speckit skills

**Storage**: `Documentacion/<App>/specs/` (spec/plan/tasks), `src/<App>/graphify-out/` (grafo por app), `.specify/memory/constitution.md` (constitution por proyecto)

**Testing**: `qa-senior` valida con fixtures en `$env:TEMP` (patrón existente en tareas previas)

**Target Platform**: Kit de agentes (GitHub Copilot + OpenCode), scripts PowerShell

**Project Type**: Documentación/Proceso (no es una app de código; es el flujo de orquestación del `pensador`)

**Performance Goals**: Re-indexación completa en < 2 minutos; detección de escenario inmediata

**Constraints**: Constitution Check obligatorio antes de cualquier `speckit-*`; pipeline ordenado sin saltos; MCPs + Graphify como contexto previo; `Documentacion/<App>/` nunca se toca en sync

**Scale/Scope**: 3 escenarios de flujo post-plataformado + re-indexación + Constitution por proyecto + memoria auto/manual

## Constitution Check

*GATE: Debe pasar antes de Phase 0 research. Re-chequear después de Phase 1 design.*

| Artículo | Estado |
|----------|--------|
| Art.I Library-First | ✅ PASS — cada feature como librería standalone; el flujo post-plataformado es un módulo del kit |
| Art.II CLI Interface | ✅ PASS — los comandos graphify/context-mode/codebase-memory son CLI |
| Art.III Test-First (TDD) | ✅ PASS — `qa-senior` valida con fixtures |
| Art.IV Simplicity | ✅ PASS — 3 escenarios claros, sin over-engineering |
| Art.V Security | ✅ PASS — `graphify extract --code-only` evita indexar secrets; stdio-only |
| Art.VI project_ext | ✅ PASS — graphify en `proyect_ext/` |
| Art.VII Simplicity (max 3 projects) | ✅ PASS — no se agregan proyectos nuevos |
| Art.VIII Anti-Abstraction | ✅ PASS — framework directo, sin capas innecesarias |
| Art.IX Integration-First | ✅ PASS — integra MCPs reales (context-mode, codebase-memory, graphify) |

**Resultado: PASS** — sin violaciones que justificar.

## Project Structure

### Documentation (this feature)

```text
specs/006-post-platforming-speckit/
├── spec.md              # Este archivo (/speckit-specify command output)
├── plan.md              # Este archivo (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
├── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
# Este feature es de documentación/proceso — no agrega código de app.
# Los cambios tocan:
scripts/
├── plataformador-bootstrap.ps1   # [BOOTSTRAP-FIXES] F1-F7 (tarea 1)
└── relocate-apps-to-src.ps1      # (existente, no se toca)

Documentacion/Agents_IA_TECH/
├── specs/006-post-platforming-speckit/   # Esta feature
├── seguridad/                            # ADRs + threat model (tarea analyze)
└── pendientes-implementacion.md          # Tracking

.github/agents/*.agent.md   # [AGENTES-INDEX] tarea 3
.opencode/agents/*.md       # [AGENTES-INDEX] tarea 3
```

**Structure Decision**: Este feature es de **documentación/proceso** — define el flujo de orquestación del `pensador`, no agrega código de aplicación. Los cambios de código se limitan a `scripts/plataformador-bootstrap.ps1` (tarea 1 `[BOOTSTRAP-FIXES]`) y a las definiciones de agentes (tarea 3 `[AGENTES-INDEX]`).

## Complexity Tracking

> **Solo llenar si Constitution Check tiene violaciones que justificar**

| Violación | Por qué es necesaria | Alternativa más simple rechazada porque |
|-----------|----------------------|------------------------------------------|
| (ninguna) | — | — |
