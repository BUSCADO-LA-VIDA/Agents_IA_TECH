# NOTA DE ARCHIVO

**Título**: Archivado de `019-update-mcp-lastupdate-guard`.

**Fecha**: 2026-11-01

**Fase**: D — Fusión de specs del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/019-update-mcp-lastupdate-guard/`
- **Nueva ubicación**: `specs/archived/019-update-mcp-lastupdate-guard/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: spec.md, plan.md, tasks.md. Estado Completado (6 tasks cerradas, 6/0).

## Motivo de la fusión (decisión usuario fase D spec 035)

- Veredicto: **FUSIONAR/ARCHIVAR** (su guard vive en el mismo script que congela 020).
- **019-update-mcp-lastupdate-guard** → su guard (`lastupdate`) vive en `scripts/update-mcp.ps1`, el mismo que **020 congela como baseline**. Sin contenido único pendiente.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase D de la spec 035. La nota de solapamiento previa (con 020/009) queda resuelta archiving 019.

## Contenido que se conserva en la canónica (referencia)

- El guard de `lastupdate` está implementado dentro de **`scripts/update-mcp.ps1`**, script que **`020-mcp-config-operativa`** congela como baseline operativo vivo (ACTIVA en `specs/`).
- No hay contenido único de 019 fuera del guard ya implementado en el script; la evolución del guard depende de 020.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase D (spec 035): de entrada activa a nota de fusión bajo "Specs archivadas / fusiones D".
