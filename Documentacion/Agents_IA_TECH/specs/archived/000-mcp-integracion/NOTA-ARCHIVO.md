# NOTA DE ARCHIVO

**Título**: Archivado de `000-mcp-integracion` (grupo de 8 sub-specs de integración MCP por herramienta).

**Fecha**: 2026-11-01

**Fase**: E — Archivar obsoletas (spec 035-consolidacion-backlog; auditoría §5.2, fila 1).

---

## Spec archivada

- **Dirección original**: `specs/000-mcp-integracion/`
- **Nueva ubicación**: `specs/archived/000-mcp-integracion/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: 8 sub-specs de plantilla (`000-mcp-context7`, `000-mcp-github`, `000-mcp-perplexity`, `000-mcp-pieces`, `000-mcp-playwright`, `000-mcp-semgrep`, `000-mcp-sentry`, `000-mcp-testsprite`) + `000-mcp-integracion-estandar.md` + `ORGANIZACION.md`. Sin `converge`, 0/0 tasks.

## Motivo de archivado (regla IX / auditoría §5.2)

- Veredicto: **CERRAR-OBSOLETA** (auditoría §5.2). Las 8 sub-specs son **plantilla sin contenido** (0/0, casi idénticas por herramienta), sin converge ni valor incremental. El tema quedó resuelto y absorbido por:
  - `020-mcp-config-operativa` (baseline de configuración MCP verificado en vivo).
  - `opencode.json` real (la configuración vigente de los MCPs, aceptada por ADR-0009/0010).
- No se conserva contenido residual fuera de esas fuentes: archivar el grupo sin fusión.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; se puede revertir con `git mv` inverso).
- La mayoría de los ítems del grupo eran huérfanos del índice (sin entrada propia). No aplica actualización de `00-indice.md`.
