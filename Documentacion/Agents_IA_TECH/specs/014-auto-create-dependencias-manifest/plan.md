# Implementation Plan: Auto-crear dependencias-manifest.yml si falta en bootstrap

**Branch**: `014-auto-create-dependencias-manifest` | **Date**: 2026-09-25 | **Spec**: Documentacion/Agents_IA_TECH/specs/014-auto-create-dependencias-manifest/spec.md

**Input**: Feature specification from `Documentacion/Agents_IA_TECH/specs/014-auto-create-dependencias-manifest/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

El bootstrap debe detectar la ausencia de `dependencias-manifest.yml` y crear un esqueleto mínimo genérico sin sobrescribir archivos existentes. Esto elimina warnings de `Read-DependenciasManifest` y permite que `upgrade_framework` continúe. El enfoque es modificar `plataformador-bootstrap.ps1` para asegurar la existencia del manifest antes de leerlo, respetando la regla de no mezclar proyectos.

## Technical Context

**Language/Version**: PowerShell 7+

**Primary Dependencies**: Ninguna externa; usa cmdlets nativos de PowerShell y YAML via texto plano.

**Storage**: Archivo YAML en filesystem `dependencias-manifest.yml` en raíz del proyecto.

**Testing**: Validación manual con bootstrap en proyecto sin manifest; verificación de YAML válido y no sobrescritura.

**Target Platform**: Windows PowerShell 7+

**Project Type**: script/tooling de bootstrap

**Performance Goals**: Creación de archivo < 100ms

**Constraints**: No sobrescribir manifest existente; no forzar contenido de apps; esqueleto genérico.

**Scale/Scope**: Un archivo por proyecto, operación puntual en bootstrap.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Modular Agent Design**: PASS. Cambio aislado en script de bootstrap, sin afectar agentes.
- **II. Orchestrator Pattern**: PASS. No introduce comunicación entre agentes.
- **III. Specification-Driven Development**: PASS. Feature definida por spec antes de implementación.
- **IV. Copilot/Opencode Compatibility**: PASS. Script es agnóstico a harness.
- **V. Observability and Monitoring**: PASS. Se añade aviso visible al crear esqueleto.
- **VI. Gestión de Dependencias Externas y Estructura proyect_ext**: PASS. Respeta que manifest es del proyecto y no se fuerzan apps del KIT.

No violations.

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/014-auto-create-dependencias-manifest/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
scripts/
└── plataformador-bootstrap.ps1   # Modificación: Ensure-DependenciasManifest

Documentacion/Agents_IA_TECH/
└── specs/014-auto-create-dependencias-manifest/
```

**Structure Decision**: Cambio localizado en `scripts/plataformador-bootstrap.ps1`. No se crean nuevos módulos. El manifest se crea en raíz del proyecto destino durante bootstrap.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
