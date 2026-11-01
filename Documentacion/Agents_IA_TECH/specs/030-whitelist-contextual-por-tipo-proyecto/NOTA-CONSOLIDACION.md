# NOTA DE CONSOLIDACIÓN (PARCIAL)

**Título**: Consolidación del NÚCLEO de `030-whitelist-contextual-por-tipo-proyecto` por absorción ADR (el resto queda pendiente).

**Fecha**: 2026-11-01

**Fase**: C — Consolidar absorbidas por ADR (spec 035-consolidacion-backlog; auditoría §5.1).

**Importante**: esta nota documenta solo la absorción del NÚCLEO. La spec **NO se cierra por completo** ni se archiva: el resto de su implementación queda como **PENDIENTE-REAL**.

---

## Spec absorbida (núcleo): `030-whitelist-contextual-por-tipo-proyecto`

- **Dirección**: `specs/030-whitelist-contextual-por-tipo-proyecto/`
- **Estado previo**: especificada — ciclo SSD+Speckit completo (spec 1.1.0, plan 1.1.0, tasks 1.2.0 con **66 tasks, 0 implementadas**, analyze PASS con observaciones, converge 2026-10-29). En índice como Especificada.
- **Tamaño**: spec grande (66 tasks). Implementación **no iniciada**.

### ADR que la absorbe
- **ADR-0013** — Agentes como orquestadores delgados (capacidades de procedimiento a skills) y whitelist de escritura resuelta por `(tier ∩ capa, tipo de proyecto)`.

### Por qué se consolida (el núcleo)
- El **núcleo** de la 030 — la whitelist de escritura contextual por tipo de proyecto/capa y el replanteo de los agentes como orquestadores delgados con capacidades de procedimiento en skills — está resuelto por el ADR-0013 implementado (forma actual de trabajo de permisos, dominio y delegación). Por eso el núcleo se absorbe.

### Qué NO se archiva ni se cierra (resto PENDIENTE-REAL)
- **El resto de los 66 tasks de la 030 NO está cubierto por ADR-0013** y sigue pendiente de implementación real: la redefinición/adelgazamiento de los agentes en skills, la siembra de whitelist por capa/tipo en cada agente, el adelgazamiento del `developer`, las decisiones pendientes D-01/D-02/D-03 que bloquean tasks, y las deudas 030-DD-01..DD-05 registradas en el converge.
- La spec **permanece ACTIVA en `specs/`** con estado "Especificada — núcleo absorbido por ADR-0013; implementación del resto pendiente". No se archiva.

### Contenido vigente preservado
- Lo preservado y a ejecutar es el resto del alcance 030 (adelgazamiento, skills por agente, decisiones pendientes y deudas), según su `tasks.md` (66 tasks) y `converge.md`. Lo ya cubierto (núcleo/whitelist contextual) queda en ADR-0013.

---

## Estado de cierre

| Spec | Estado |
|---|---|
| `030-whitelist-contextual-por-tipo-proyecto` | NÚCLEO absorbido por ADR-0013; resto PENDIENTE-REAL (no cerrada por completo, no archivada) |

Esta nota se crea dentro de la spec; la entrada del índice se actualiza para indicar la absorción del núcleo y el pendiente del resto.
