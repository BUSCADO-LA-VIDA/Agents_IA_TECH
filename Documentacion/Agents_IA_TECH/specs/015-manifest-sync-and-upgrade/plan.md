# Implementation Plan: Sincronización y actualización de dependencias-manifest.yml

**Branch**: `015-manifest-sync-and-upgrade` | **Date**: 2026-09-25 | **Spec**: Documentacion/Agents_IA_TECH/specs/015-manifest-sync-and-upgrade/spec.md

**Input**: Feature specification from `Documentacion/Agents_IA_TECH/specs/015-manifest-sync-and-upgrade/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Sincronizar `dependencias-manifest.yml` con la referencia del KIT, crear esqueleto completo si falta, respetar switch `upgrade` por herramienta, agregar/quitar herramientas y ejecutar post-update hooks para mantener conocimiento actualizado.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: PowerShell 7+

**Primary Dependencies**: Ninguna externa

**Storage**: Archivo YAML `dependencias-manifest.yml`

**Testing**: Validación manual y pruebas de integración con bootstrap

**Target Platform**: Windows PowerShell 7+

**Project Type**: script/tooling

**Performance Goals**: Sincronización < 500ms

**Constraints**: No sobrescribir personalizaciones, respetar `upgrade: false`

**Scale/Scope**: Un manifest por proyecto

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Art.VI Gestión de Dependencias Externas: PASS. Sincroniza manifest y respeta upgrade.
- Art.III Specification-Driven Development: PASS.
- Art.V Observability: PASS. Logs visibles.

No violations.

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/015-manifest-sync-and-upgrade/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
scripts/
└── plataformador-bootstrap.ps1   # Sync-Manifest, Ensure-DependenciasManifest

proyect_ext/
└── [herramientas externas]
```

**Structure Decision**: Modificación localizada en `scripts/plataformador-bootstrap.ps1`. No se crean nuevos módulos.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
