# NOTA DE CONSOLIDACIÓN

**Título**: Consolidación de `006-post-platforming-speckit` por absorción ADR.

**Fecha**: 2026-11-01

**Fase**: C — Consolidar absorbidas por ADR (spec 035-consolidacion-backlog; auditoría §5.1).

---

## Spec absorbida: `006-post-platforming-speckit`

- **Dirección**: `specs/006-post-platforming-speckit/`
- **Estado previo**: completa en disco (31 tasks, 31/0) pero sin índice.

### ADR que la absorbe
- **ADR-0004** — Post-plataformado Speckit (flujo post-plataformado → speckit con 3 escenarios + re-indexación + Constitution por proyecto + memoria + graphify por app).

### Por qué se consolida
- El flujo post-plataformado hacia Speckit (3 escenarios), la re-indexación, la siembra de Constitution por proyecto, la memoria del proyecto y el graphify por aplicación están definidos por el ADR-0004 implementado. La spec 006 describe ese mismo flujo y quedó absorbida por la forma actual de trabajo del ADR.

### Contenido vigente preservado
- Los 3 escenarios del flujo post-plataformado → speckit, la re-indexación, la Constitution por proyecto, la memoria y el graphify por app se conservan en ADR-0004 (forma actual) y en la spec `021-sync-kit-agents` (orquestación del sync). No queda contenido técnico de 006 sin cubrir por el ADR; por ello permanece en `specs/` con estado cerrado y no se archiva.

---

## Estado de cierre

| Spec | Estado de cierre |
|---|---|
| `006-post-platforming-speckit` | CERRADA-POR-ABSORCION-ADR (no se archiva) |

Permanece en `specs/006-post-platforming-speckit/` con esta nota y estado cerrado en el índice. No ejecuta fusión de contenido (fase D) ni renumeración (fase F).
