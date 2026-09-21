# Converge: post-platforming-speckit

**Versión**: 1.0
**Fecha**: 2026-09-20
**Autor**: documentador (Fase Converge)
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md) | **Data Model**: [data-model.md](data-model.md) | **Analyze**: [analyze.md](analyze.md) | **ADR**: [adr-0004](../../arquitectura/adr/adr-0004-post-plataformado-speckit.md) | **Threat Model**: [post-plataformado](../../seguridad/post-plataformado.md)

---

## Resumen consolidado

La feature `[POST-PLATAFORMADO]` define el **puente entre el bootstrap y el pipeline speckit**: tras plataformar un proyecto, el `pensador` lo lleva al ciclo `specify → plan → tasks → analyze → converge → implement` según su estado real (3 escenarios A/B/C), mantiene los índices y el grafo al día (re-indexación automática + memoria auto/manual), genera una Constitution específica del proyecto (con `Constitution_Wizard_Instructions.md` estandarizado), y preserva los documentos originales como fuente de verdad.

### Componentes de la decisión (ADR-0004)

1. **Detección de escenario (A/B/C)** — enrutador de entrada según estado real del proyecto.
2. **Re-indexación automática** al aprobar artefactos y tras implement (context-mode + codebase-memory + graphify) con **aviso visible** (RF-010).
3. **Memoria auto/manual** — automática diaria (índice stale = día anterior o más vieja) + trigger manual "actualizar memoria".
4. **Constitution por proyecto** — detectar plantilla genérica → Constitution Wizard (RF-14) + generar `Constitution_Wizard_Instructions.md` (RF-009).
5. **Graphify por app (estructura-first)** — 1 grafo por `src/<App>/graphify-out/`, vista workspace on-demand vía `merge-graphs`, `--code-only` por defecto, `graphify-out/` en `.gitignore` (RF-011).

---

## Flujo post-plataformado → speckit

```mermaid
flowchart TD
    A[Inicio flujo post-plataformado] --> B[Detectar escenario<br/>constitution específica?<br/>doc previa? código en src/?]

    B -->|sin código + sin docs<br/>sin constitution específica| A1[Escenario A: nuevo desde idea]
    B -->|con documentación previa| B1[Escenario B: docs a migrar]
    B -->|con código, sin docs| C1[Escenario C: desde cero]

    A1 --> CW[Constitution Wizard<br/>RF-14 / RF-09]
    B1 --> B2[Inventariar con markitdown<br/>preservar originales]
    C1 --> C2[Crear Documentacion/<App>+<br/>Constitution + speckit desde cero]

    CW --> P[Pipeline speckit<br/>specify → plan → tasks<br/>→ analyze → converge]
    B2 --> B3[Indexar context-mode<br/>+ codebase-memory + graphify]
    B3 --> P
    C2 --> P

    P --> R{¿Artefacto aprobado<br/>o tras implement?}
    R -->|Sí| RI[Aviso visible RF-010<br/>Re-indexación automática<br/>context-mode + codebase-memory + graphify]
    R -->|No| M

    RI --> M[Memoria]
    M --> M1{¿Índice stale<br/>día anterior o más viejo?}
    M1 -->|Sí| M2[Actualizar automáticamente<br/>antes de responder]
    M1 -->|No| E[Responder]
    M -->|trigger manual<br/>"actualizar memoria"| M3[Actualizar on-demand]

    P --> G[Graphify por app<br/>estructura-first<br/>extract --code-only / update<br/>--mode deep bajo demanda]
    G --> V[Vista workspace unificada<br/>on-demand vía merge-graphs]
```

---

## Tabla de trazabilidad completa

| Artefacto | Relación |
|-----------|----------|
| `spec.md` (FR-001..FR-011, SC-001..SC-009) | Fuente de la feature — 4 user stories (A/B/C + memoria) |
| `plan.md` | Constitution Check PASS 9/9; estructura doc/proceso |
| `research.md` | Decisiones D-1..D-5 (grafo por app, memoria auto/manual, estructura-first, detección, preservar originales) |
| `data-model.md` | Entidades Escenario/Artefacto/Índice/Constitution/Grafo + reglas de frescura |
| `analyze.md` | Análisis arquitectónico + guardrails + spec linking |
| `adr-0004-post-plataformado-speckit.md` | Decisión formal + 11 guardrails + alternativas + diagrama |
| `seguridad/post-plataformado.md` | Threat model 5 riesgos (2🟠 3🔵) — no bloquea con condiciones |
| `tasks.md` (T001-T031) | Tareas accionables por user story + tests RF-009/010/011 |
| `checklists/requirements.md` | Spec quality checklist — todos PASS |

### Trazabilidad RF → Tasks

| RF | Tasks | User Story |
|----|-------|------------|
| RF-01 (detección escenario) | T004, T005 | US1 |
| RF-02 (escenario A) | T004, T006, T007 | US1 |
| RF-03 (escenario B) | T008, T009, T010, T011 | US2 |
| RF-04 (escenario C) | T012, T013 | US3 |
| RF-05 (re-indexación) | T014, T027 | US4 |
| RF-06 (Constitution por proyecto) | T006 | US1 |
| RF-07 (Graphify por app) | T002, T011 | Foundational/US2 |
| RF-08 (memoria auto/manual) | T003, T015, T016 | Foundational/US4 |
| RF-009 (Wizard Instructions) | T021-T026 | US1 (tests) |
| RF-010 (aviso re-indexación) | T027, T028, T031 | US4 |
| RF-011 (gitignore graphify-out) | T029, T030 | Polish |

---

## Estado de versionado

| Artefacto | Versión | Estado |
|-----------|---------|--------|
| `spec.md` | 1.0 | Aprobada (2026-09-20) |
| `plan.md` | 1.0 | Aprobado (2026-09-20) |
| `research.md` | 1.0 | Completo |
| `data-model.md` | 1.0 | Completo |
| `analyze.md` | 1.0 | Aprobado (2026-09-20) |
| `adr-0004` | 1.0 | Aceptado (2026-09-20) |
| `seguridad/post-plataformado.md` | 1.0 | Aprobado con condiciones (2026-09-20) |
| `tasks.md` | 1.0 | Aprobado (2026-09-20) |

---

## Documentación consolidada lista para implementadores

### Orden de implementación (MVP primero)

1. **Foundational** (T002-T003): estrategia Graphify por app + flujo de memoria documentados
2. **US1** (T004-T007): flujo base Escenario A (detección + Constitution Wizard + speckit)
3. **US2** (T008-T011) ∥ **US3** (T012-T013): migración docs ∥ docs desde cero (en paralelo)
4. **US4** (T014-T017, T027-T028): re-indexación + memoria auto/manual + aviso
5. **Tests** (T021-T026, T030-T031): validación RF-009/010/011
6. **Polish** (T018-T020, T029): índice, pendientes, sync, gitignore

### Condiciones de seguridad (innegociables, del threat model)

- `--code-only` por defecto en Graphify; `-GraphifyDeep` solo con backend + scope sin secrets
- Comandos allowlist para re-indexación y trigger manual + fail-closed
- `merge-graphs` on-demand no persistente; `graphify-out/` en `.gitignore`
- Rutas relativas/tokens en `Constitution_Wizard_Instructions.md`
- Aviso visible "Re-indexando..." (RF-010) en toda re-indexación

---

## Próximos pasos

1. **Implementación** (preguntar al usuario): ejecutar `speckit-implement` delegando por expertise — `pensador` (T004-T007, T014-T016, T027), `documentador` (T002-T003, T017, T028), `analista_tecnico` (T011), `devops` (T029), `qa-senior` (tests T021-T026, T030-T031)
2. **Validación**: `qa-senior` valida con fixtures antes del rollout
3. **gitflow**: commits convencionales + sync `.github/` ↔ `.opencode/`
