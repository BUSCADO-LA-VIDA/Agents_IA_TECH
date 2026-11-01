# NOTA DE CONSOLIDACIÓN

**Título**: Consolidación de `007-mcp-token-resolution` y `017-garantizar-mcp-activos` por absorción ADR.

**Fecha**: 2026-11-01

**Fase**: C — Consolidar absorbidas por ADR (spec 035-consolidacion-backlog; auditoría §5.1).

---

## Spec absorbida: `007-mcp-token-resolution`

- **Dirección**: `specs/000-mcp-gobernanza/007-mcp-token-resolution/`
- **Estado previo**: completada en disco (46/0 tasks) pero sin índice.

### ADR que la absorbe
- **ADR-0006** — MCP token resolution + `.env.mcp` + upgrade tools + self-update + activación kit maestro.

### Por qué se consolida
- ADR-0006 define la forma actual de trabajo para la resolución de tokens MCP y la portabilidad de `.env.mcp` (y su activación en el kit). El contenido de `007-mcp-token-resolution` quedó resuelto y superado por ese ADR implementado; no aporta una forma de trabajo distinta a la vigente.

### Contenido vigente preservado
- Las decisiones de resolución de tokens y rutas de `.env.mcp` que siguen aplicando están plasmadas en ADR-0006 y en `020-mcp-config-operativa` (baseline de configuración MCP en vivo). No queda contenido técnico del spec sin cubrir por el ADR; por ello no se archiva ni se migra: permanece en `specs/` con estado cerrado y trazabilidad.

---

## Spec absorbida: `017-garantizar-mcp-activos`

- **Dirección**: `specs/000-mcp-gobernanza/017-garantizar-mcp-activos/`
- **Estado previo**: solo spec.md, sin tasks.

### ADR que la absorbe
- **ADR-0006** (resolución/activación de tokens MCP + `.env.mcp` portable) + **020-mcp-config-operativa** (baseline de MCP activos verificado en vivo).

### Por qué se consolida
- Garantizar la activación de los MCPs del kit queda cubierto por ADR-0006 (portabilidad y activación del kit maestro) y por la spec 020, que congela `opencode.json` con los 9 MCP activos verificados. No queda una forma de trabajo adicional en 017 que no esté en esas fuentes.

### Contenido vigente preservado
- La noción de "MCP activos" es la que fija `020-mcp-config-operativa` (baseline en vivo) y ADR-0006. No se archiva la spec: permanece con estado cerrado y nota de trazabilidad.

---

## Estado de cierre

| Spec | Estado de cierre |
|---|---|
| `007-mcp-token-resolution` | CERRADA-POR-ABSORCION-ADR (no se archiva) |
| `017-garantizar-mcp-activos` | CERRADA-POR-ABSORCION-ADR (no se archiva) |

Ambas permanecen en `specs/000-mcp-gobernanza/` con esta nota y estado cerrado en el índice. No ejecuta fusión de contenido (fase D) ni renumeración (fase F).
