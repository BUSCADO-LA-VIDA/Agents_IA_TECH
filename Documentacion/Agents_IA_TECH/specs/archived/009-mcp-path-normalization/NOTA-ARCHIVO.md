# NOTA DE ARCHIVO

**Título**: Archivado de `009-mcp-path-normalization`.

**Fecha**: 2026-11-01

**Fase**: E — Archivar obsoletas (spec 035-consolidacion-backlog; auditoría §5.2).

---

## Spec archivada

- **Dirección original**: `specs/009-mcp-path-normalization/`
- **Nueva ubicación**: `specs/archived/009-mcp-path-normalization/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: spec/plan/tasks/IMPLEMENTATION.md. 6/0 tasks, sin converge. Huérfana del índice.

## Motivo de archivado (regla IX / auditoría §5.2)

- Veredicto: **CERRAR-OBSOLETA** (auditoría §5.2, 6/0 absorbida por ADR-0009/0010). La normalización de rutas MCP quedó definida por la forma actual de trabajo:
  - **ADR-0009** — rutas MCP hardcodeadas en `opencode.json`.
  - **ADR-0010** — forma V2 de `opencode.json` (`mcp.servers`).
  - `020-mcp-config-operativa` — baseline de configuración MCP en vivo.
- No se conserva contenido residual fuera de esas fuentes: archivar sin fusión (la fusión de contenido, fase D, queda pendiente de aprobación puntual).

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- Huérfana del índice; no aplica actualización de `00-indice.md`.
