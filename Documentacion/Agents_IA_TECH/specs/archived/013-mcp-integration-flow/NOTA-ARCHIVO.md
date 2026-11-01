# NOTA DE ARCHIVO

**Título**: Archivado de `013-mcp-integration-flow`.

**Fecha**: 2026-11-01

**Fase**: D — Fusión de specs del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/013-mcp-integration-flow/`
- **Nueva ubicación**: `specs/archived/013-mcp-integration-flow/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: spec.md, plan.md, tasks.md. Estado Completado (T001-T008), marcada ACTIVA/operativa en el índice previo.

## Motivo de la fusión (decisión usuario fase D spec 035)

- Veredicto: **FUSIONAR/ARCHIVAR** (fusionada en la canónica `015-mcp-integration-flow`).
- **013-mcp-integration-flow** → **consolidada en `015-mcp-integration-flow` (canónica)**. Ambas trataban el mismo flujo de integración MCP/ECC (`ecc-orchestrator`, sección MCP en agents, `ci/ecc-pipeline`, glosario). Sin contenido único que conservar.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase D de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- El flujo de integración MCP/ECC completo vive en **`015-mcp-integration-flow`** (canónica, ACTIVA en `specs/`):
  - `ecc-orchestrator` y su integración.
  - Sección MCP en los agents (16 `.github` + 16 `.opencode`).
  - `ci/ecc-pipeline`.
  - Glosario de términos compartidos.
- No hay artefactos en 013 que no estén ya cubiertos por 015. Fusión de contenido realizada por referenciación a la canónica; no se duplica contenido.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase D (spec 035): de entrada activa a nota de fusión bajo "Specs archivadas / fusiones D".
