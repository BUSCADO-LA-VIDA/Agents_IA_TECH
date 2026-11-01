# NOTA DE ARCHIVO

**Título**: Archivado de `009-mcp-update-lifecycle`.

**Fecha**: 2026-11-01

**Fase**: D — Fusión de specs del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/009-mcp-update-lifecycle/`
- **Nueva ubicación**: `specs/archived/009-mcp-update-lifecycle/` (movido con `Move-Item` + `git add -A` por lock en `git mv`; git detecta los renames, reversible).
- **Contenido**: spec.md, plan.md, tasks.md, converge.md, data-model.md, quickstart.md, research.md, checklists/requirements.md. Estado Completado con converge.

## Motivo de la fusión (decisión usuario fase D spec 035)

- Veredicto: **FUSIONAR/ARCHIVAR** (superada por `020-mcp-config-operativa`).
- **009-mcp-update-lifecycle** → **superada por `020-mcp-config-operativa`**. El script `scripts/update-mcp.ps1` que definía **YA EXISTE en disco** y 020 lo congeló como baseline operativo vivo. El converge de 009 quedó desactualizado (decía que el script no existía).
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase D de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- El lifecycle real de actualización de MCPs y el script `scripts/update-mcp.ps1` viven como **baseline operativo vivo** en **`020-mcp-config-operativa`** (ACTIVA en `specs/`).
- El converge de 009 afirmaba que el script no existía; esa afirmación quedó desactualizada y es justamente la razón por la que 009 se archiva: 020 congeló el script que ya está en disco.
- No se conserva contenido único de 009 fuera de lo cubierto por 020; la evolución futura del script la gobierna 020.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con revert del rename).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase D (spec 035): de entrada activa a nota de fusión bajo "Specs archivadas / fusiones D".
