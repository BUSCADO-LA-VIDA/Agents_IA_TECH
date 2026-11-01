# NOTA DE ARCHIVO

**Título**: Archivado de `002-script-plataforming-sync-kit`.

**Fecha**: 2026-11-01

**Fase**: D — Fusión de specs del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/002-script-plataforming-sync-kit/`
- **Nueva ubicación**: `specs/archived/002-script-plataforming-sync-kit/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: spec.md, plan.md, tasks.md. Estado Completado (tasks implementadas).

## Motivo de la fusión (decisión usuario fase D spec 035)

- Veredicto: **FUSIONAR/ARCHIVAR** (precursora del motor de sync, superada).
- **002-script-plataforming-sync-kit** → **precursora del motor de sync**. El mecanismo actual (`scripts/sync-kit.ps1` + `scripts/sync/` con 10 subcarpetas + spec `021-sync-kit-agents`) ya implementa lo que esta spec describía. Archivar como superada.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase D de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- El mecanismo de sync actual se conserva en:
  - **`scripts/sync-kit.ps1`** — motor de sync (bootstrap instalador/actualizador).
  - **`scripts/sync/`** — 10 subcarpetas de capas de propagación.
  - **`021-sync-kit-agents`** (operativa) — orquestador por capas del sync.
  - Referencias históricas adicionales: ADR-0003 (bootstrap) y `015-sync-kit-bootstrap` (absorbida por ADR).
- No se conserva contenido único de 002 fuera de lo que el mecanismo actual ya implementa; archivar como superada.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase D (spec 035): de entrada activa a nota de fusión bajo "Specs archivadas / fusiones D".
