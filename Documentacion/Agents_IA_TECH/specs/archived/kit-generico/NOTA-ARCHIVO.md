# NOTA DE ARCHIVO

**Título**: Archivado de `kit-generico` (no-numerada) — Blindaje `.git` + alcance quirúrgico del kit.

**Fecha**: 2026-11-01

**Fase**: F — Últimas migraciones/archivados del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/kit-generico/`
- **Nueva ubicación**: `specs/archived/kit-generico/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: `spec.md` (6.869 B, RF-B1..RF-B4, RNF-B1..B3, AC-1..AC-6) + `tasks.md` (9 tareas cerradas, 9/0). Sin plan/analyze/converge.

## Motivo de archivado (decisión usuario fase F, spec 035)

- Veredicto: **ARCHIVAR / superada**.
- **Absorbida por spec 021 (sync por capas)**: los guards de alcance quirúrgico y blindaje de `.git` que pedía (allowlist/denylist de `.git`, rutas destructivas con containment-check) ya están implementados en la spec 021 con guards equivalentes; sus tareas quedaron marcadas "superada". Sin contenido único pendiente.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase F de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- El blindaje de `.git` y los guards de alcance quirúrgico (allowlist/denylist de `.git`, containment-check en rutas destructivas) están implementados en **`021-sync-kit-agents`** (canónica, ACTIVA en `specs/`): `scripts/sync-kit.ps1` (lógica de referencia: guards, allowlist de URLs, merge `opencode.json`) con regla "Nunca tocar: `Documentacion/<AppName>/`, `.opencode/config.json`, `.opencode/.gitignore` local si difiere".
- Los principios de fail-closed y `-DryRun` que esta spec pedía (RNF-B1/B2) son transversales al mecanismo de sync actual de la capa 021.
- No hay artefactos en `kit-generico` que no estén ya cubiertos por 021. Archivado por referenciación a la canónica; no se duplica contenido.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase F (spec 035): de "CERRAR-COMPLETADA-SIN-REGISTRO" a estado **ARCHIVADA (fase F)** con referencia a esta NOTA-ARCHIVO y ubicación `specs/archived/kit-generico/`.
