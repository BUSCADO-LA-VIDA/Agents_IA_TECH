# NOTA DE CONSOLIDACIÓN

**Título**: Consolidación de `010-mcp-env-file-guarantee` por absorción ADR.

**Fecha**: 2026-11-01

**Fase**: C — Consolidar absorbidas por ADR (spec 035-consolidacion-backlog; auditoría §5.1).

---

## Spec absorbida: `010-mcp-env-file-guarantee`

- **Dirección**: `specs/010-mcp-env-file-guarantee/`
- **Estado previo**: solo `spec.md` (7.879 B), sin tasks, sin índice.

### ADR que la absorbe
- **ADR-0006** — MCP token resolution + `.env.mcp` portable + upgrade tools + self-update + activación kit maestro.

### Por qué se consolida
- La garantía del archivo `.env.mcp` portable está definida por el ADR-0006 (portabilidad de `.env.mcp`), que es la forma actual de trabajo para esa responsabilidad. La spec 010 quedó absorbida por ese ADR implementado.

### Contenido vigente preservado
- La portabilidad y garantía de `.env.mcp` se conserva en ADR-0006 y en la spec `020-mcp-config-operativa` (baseline de configuración MCP en vivo). No queda contenido de 010 sin cubrir por el ADR; por ello permanece en `specs/` con estado cerrado y no se archiva.

---

## Estado de cierre

| Spec | Estado de cierre |
|---|---|
| `010-mcp-env-file-guarantee` | CERRADA-POR-ABSORCION-ADR (no se archiva) |

Permanece en `specs/010-mcp-env-file-guarantee/` con esta nota y estado cerrado en el índice. No ejecuta fusión de contenido (fase D) ni renumeración (fase F).
