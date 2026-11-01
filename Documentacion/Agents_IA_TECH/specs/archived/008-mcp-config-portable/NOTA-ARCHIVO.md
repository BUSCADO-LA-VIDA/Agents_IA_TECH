# NOTA DE ARCHIVO

**Título**: Archivado de `008-mcp-config-portable`.

**Fecha**: 2026-11-01

**Fase**: E — Archivar obsoletas (spec 035-consolidacion-backlog; auditoría §5.2).

---

## Spec archivada

- **Dirección original**: `specs/008-mcp-config-portable/`
- **Nueva ubicación**: `specs/archived/008-mcp-config-portable/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: spec/plan/tasks/analyze/README/checklists. Estado Draft, **0/0 tasks** (no iniciada). Huérfana del índice.

## Motivo de archivado (regla IX / auditoría §5.2)

- Veredicto: **CERRAR-OBSOLETA** (auditoría §5.2). Draft 0/0 sin implementación; la configuración MCP portable quedó definida por la forma actual de trabajo:
  - **ADR-0009** — rutas MCP hardcodeadas en `opencode.json` (workaround bug #5299).
  - **ADR-0010** — forma V2 de `opencode.json` (`mcp.servers` + `mcp.timeout.startup`).
- No se conserva contenido residual fuera de esos ADRs: archivar sin fusión (la fusión de contenido, fase D, queda pendiente de aprobación puntual).

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- Huérfana del índice; no aplica actualización de `00-indice.md`.
