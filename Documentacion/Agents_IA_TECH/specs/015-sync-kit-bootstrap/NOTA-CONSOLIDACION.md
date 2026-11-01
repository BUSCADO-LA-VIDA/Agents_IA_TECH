# NOTA DE CONSOLIDACIÓN

**Título**: Consolidación de `015-sync-kit-bootstrap` por absorción ADR.

**Fecha**: 2026-11-01

**Fase**: C — Consolidar absorbidas por ADR (spec 035-consolidacion-backlog; auditoría §5.1).

---

## Spec absorbida: `015-sync-kit-bootstrap`

- **Dirección**: `specs/015-sync-kit-bootstrap/`
- **Estado previo**: completa en disco (`spec.md`, `plan.md`, `design.md`, `analyze.md`, `converge.md`, `tasks.md` con 10 tasks, 10/0; contiene `implementation/sync-kit.ps1`) y sin índice propio.

### ADR que la absorbe
- **ADR-0003** — Plataforma bootstrap instalador/actualizador único + `sync-kit` (mecanismo de sync vigente).

### Por qué se consolida
- El bootstrap instalador/actualizador único está definido por ADR-0003 y el motor de sync transversal es `scripts/sync-kit.ps1`. La spec 015-sync-kit-bootstrap describió ese mismo mecanismo (incluido un `implementation/sync-kit.ps1` dentro de la spec) y quedó absorbida por la forma actual de trabajo del ADR/script canónico.

### Contenido vigente preservado
- La instalación/actualización única del kit se conserva en ADR-0003 y en el `sync-kit` canónico. La comparación por EOL normalizado y los 3 estados la define ADR-0012 (spec 029). No queda contenido de 015 no cubierto por esas fuentes; por ello permanece en `specs/` con estado cerrado y no se archiva. El `implementation/sync-kit.ps1` de la spec queda como histórico (el script canónico vive en `scripts/sync-kit.ps1`).

---

## Estado de cierre

| Spec | Estado de cierre |
|---|---|
| `015-sync-kit-bootstrap` | CERRADA-POR-ABSORCION-ADR (no se archiva) |

Permanece en `specs/015-sync-kit-bootstrap/` con esta nota y estado cerrado en el índice. No ejecuta fusión de contenido (fase D) ni renumeración (fase F).
