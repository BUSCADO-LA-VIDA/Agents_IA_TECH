# Tasks: post-platforming-speckit

**Fecha**: 2026-09-20
**Autor**: pensador (Phase 2)
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Resumen

Tareas accionables para implementar el flujo post-plataformado → speckit (3 escenarios), re-indexación automática, Constitution por proyecto, estrategia Graphify por app, y memoria auto/manual.

**Total de tareas**: 31
**Por user story**: US1 (4 + 6 tests), US2 (4), US3 (2), US4 (4 + 5 RF-010/011)
**MVP sugerido**: US1 (Escenario A — flujo base)

---

## Phase 1: Setup

- [x] T001 Crear la estructura del feature `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/` con `spec.md`, `plan.md`, `research.md`, `data-model.md`, `checklists/requirements.md` (ya creados en fase documental)

## Phase 2: Foundational

- [x] T002 [P] Documentar la estrategia Graphify por app en `Documentacion/Agents_IA_TECH/MCPs/graphify.md` (sección "Estrategia por app": 1 grafo por `src/<App>/graphify-out/`, vista workspace on-demand vía `merge-graphs`, flujo estructura-first `--code-only` → `update` → `label` bajo demanda)
- [x] T003 [P] Documentar el flujo de actualización de memoria (RF-08) en `Documentacion/Agents_IA_TECH/00-indice.md` (sección "Memoria": automática diaria + manual "actualizar memoria"; qué actualiza: context-mode + codebase-memory + graphify)

## Phase 3: US1 — Proyecto nuevo desde idea (Escenario A)

**Objetivo**: El `pensador` detecta el escenario A y ejecuta Constitution Wizard → speckit pipeline completo.
**Test independiente**: Crear un proyecto vacío y verificar que se detecta A y se ejecuta Constitution → specify → plan → tasks.

- [x] T004 [US1] Agregar al agente `pensador` (`.github/agents/pensador.agent.md` y `.opencode/agents/pensador.md`) la sección "Flujo post-plataformado" con la detección de escenario (A/B/C) y el flujo del escenario A (Constitution Wizard → speckit pipeline)
- [x] T005 [US1] Agregar al `pensador` la lógica de detección de escenario: verificar `.specify/memory/constitution.md` (¿es plantilla?), documentación previa en `Documentacion/`, código en `src/<App>/`
- [x] T006 [US1] Agregar al `pensador` la invocación del Constitution Wizard (RF-14) cuando la constitution es la plantilla genérica del kit (RF-06)
- [x] T007 [US1] Documentar el flujo del escenario A en `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/` (referencia para el `pensador`)

## Phase 4: US2 — Proyecto existente con documentación a migrar (Escenario B)

**Objetivo**: El `pensador` inventaría docs previas con markitdown, preserva originales, indexa MCPs + graphify, y genera nueva doc dinámica con speckit.
**Test independiente**: Proyecto con docs en PDF/DOCX → verificar inventario markitdown, originales preservados, indexación, nueva doc con speckit.

- [x] T008 [US2] Agregar al `pensador` el flujo del escenario B: inventario con markitdown (`convert_to_markdown`), preservar originales como fuente de verdad, indexar context-mode + codebase-memory + graphify
- [x] T009 [US2] Agregar al `pensador` la generación dinámica de nueva documentación con speckit según lo que la IA lee de la documentación previa (RF-03)
- [x] T010 [US2] Documentar el flujo del escenario B en `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/` (inventario markitdown + preservación de originales + migración asistida)
- [x] T011 [US2] Agregar al `analista_tecnico` (`.github/agents/analista_tecnico.agent.md` y `.opencode/agents/analista_tecnico.md`) el paso `graphify extract --code-only` como estructura-first en el pipeline de documentación

## Phase 5: US3 — Proyecto existente sin documentación (Escenario C)

**Objetivo**: El `pensador` crea la estructura + Constitution + speckit desde cero.
**Test independiente**: Proyecto con código pero sin docs → verificar creación de estructura + Constitution + speckit.

- [x] T012 [US3] Agregar al `pensador` el flujo del escenario C: crear estructura `Documentacion/<App>/` + Constitution Wizard + speckit desde cero (RF-04)
- [x] T013 [US3] Documentar el flujo del escenario C en `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/`

## Phase 6: US4 — Re-indexación automática y memoria

**Objetivo**: Al aprobar artefactos se re-indexa; la memoria se actualiza automática diaria + manual.
**Test independiente**: Tras aprobar un artefacto, verificar re-indexación; al pedir "actualizar memoria", verificar actualización on-demand.

- [x] T014 [US4] Agregar al `pensador` (`.github/agents/pensador.agent.md` y `.opencode/agents/pensador.md`) la re-indexación automática al aprobar spec/plan/tasks y tras implement (RF-05): `context-mode index` + `codebase-memory index_repository` + `graphify update`
- [x] T015 [US4] Agregar al `pensador` la actualización de memoria automática diaria (RF-08): al recibir petición, verificar fecha de última actualización; si es del día anterior o más vieja → actualizar automáticamente antes de responder
- [x] T016 [US4] Agregar al `pensador` el trigger manual "actualizar memoria" (RF-08): actualiza context-mode + codebase-memory + graphify on-demand
- [x] T017 [US4] Agregar a `documentador` (`.github/agents/documentador.agent.md` y `.opencode/agents/documentador.md`) la re-indexación tras docs consolidadas (`context-mode index` + `graphify update`)

## Phase 7: Polish & Cross-Cutting

- [x] T018 [P] Actualizar `Documentacion/Agents_IA_TECH/00-indice.md` con la entrada de la spec `006-post-platforming-speckit` (features activas)
- [x] T019 [P] Actualizar `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` marcando la tarea `[POST-PLATAFORMADO]` como completada en fase documental
- [x] T020 [P] Verificar que las definiciones de agentes (`.github/` y `.opencode/`) quedan en sync tras los cambios (Regla 3)

## Phase 8: Tests de validación (RF-009 — Constitution Wizard Instructions)

**Objetivo**: Validar que la nueva funcionalidad cumple con lo solicitado, usando como guía el ejemplo `Constitution_Wizard_Instructions.md` de trading_bot. NO incluir un nuevo proyecto en el actual — solo generar tests para verificar que la funcionalidad genera el documento estandarizado correctamente.
**Test independiente**: Verificar que al requerir ejecutar el Constitution Wizard, se genera `Documentacion/Constitution_Wizard_Instructions.md` con la estructura estándar y comandos accionables.

- [x] T021 [P] [US1] Crear test de validación: verificar que al detectar constitution = plantilla genérica (RF-06), el flujo genera `Documentacion/Constitution_Wizard_Instructions.md` con la estructura estándar (lista de apps objetivo, comando único por app, comportamiento del wizard, script opcional, qué hacer después)
- [x] T022 [P] [US1] Crear test de validación: verificar que el documento generado lista TODAS las apps bajo `src/<App>/` (no solo una) y que cada app tiene su comando `speckit-constitution --app <ruta>` correcto
- [x] T023 [P] [US1] Crear test de validación: verificar que el documento distingue apps con constitution existente (modo revisar/actualizar) vs sin constitution (modo creación), según el estado real de cada `.specify/memory/constitution.md`
- [x] T024 [P] [US1] Crear test de validación: verificar que el documento incluye el script opcional `run_all_constitution_wizards.ps1` que recorre todas las apps y ejecuta el wizard seguido
- [x] T025 [P] [US1] Crear test de validación: verificar que el documento incluye la sección "Qué hacer después" con el pipeline speckit (specify → plan → tasks → analyze → converge → implement) y las reglas transversales (contexto previo MCPs, validación usuario, no saltar fases, delegación por expertise)
- [x] T026 [P] [US1] Crear test de validación: verificar que los comandos del documento son accionables (el comando `speckit-constitution --app <ruta>` existe y funciona para cada app listada)

## Phase 9: Aviso de re-indexación + gitignore (RF-010 / RF-011)

**Objetivo**: Mostrar aviso visible cuando se ejecuta re-indexación/actualización de memoria, y garantizar que `graphify-out/` está en `.gitignore`.
**Test independiente**: Verificar que al re-indexar se muestra el aviso; verificar que `git check-ignore graphify-out/` devuelve 0.

- [x] T027 [P] [US4] Agregar al `pensador` (`.github/agents/pensador.agent.md` y `.opencode/agents/pensador.md`) el aviso visible de re-indexación: al ejecutar RF-005/RF-008, mostrar "Re-indexando context-mode + codebase-memory + graphify..." antes de iniciar (RF-010)
- [x] T028 [P] [US4] Agregar al `documentador` (`.github/agents/documentador.agent.md` y `.opencode/agents/documentador.md`) el aviso visible de re-indexación tras docs consolidadas (RF-010)
- [x] T029 [P] Agregar `graphify-out/` al `.gitignore` raíz (RF-011) + `git rm --cached -r graphify-out/` si ya hay grafos trackeados (sin borrarlos del disco)
- [x] T030 [P] Crear test de validación: verificar que `git check-ignore graphify-out/` devuelve 0 (ignorado) y que ningún grafo/`.env`/clave está trackeado (RF-011, SC-009)
- [x] T031 [P] Crear test de validación: verificar que al re-indexar se muestra el aviso visible "Re-indexando..." (RF-010, SC-008)

---

## Dependencias

**Orden de completado de user stories**:
```
US1 (Escenario A) → US2 (Escenario B) → US3 (Escenario C) → US4 (Re-indexación + memoria)
```

**Dependencias clave**:
- T004-T007 (US1) dependen de T001 (setup)
- T008-T011 (US2) dependen de T004-T007 (US1) — el flujo base debe existir
- T012-T013 (US3) dependen de T004-T007 (US1)
- T014-T017 (US4) dependen de T002-T003 (foundational) — la estrategia y el flujo de memoria deben estar documentados

## Ejecución en paralelo

- **T002 + T003** (foundational) pueden ejecutarse en paralelo
- **T004-T007** (US1) son secuenciales (flujo base)
- **T008-T011** (US2) y **T012-T013** (US3) pueden ejecutarse en paralelo entre sí (dependen de US1)
- **T014-T017** (US4) pueden ejecutarse en paralelo entre sí
- **T021-T026** (tests RF-009) dependen de T004-T007 (US1) — validan que el flujo genera el documento estandarizado
- **T027-T028** (aviso RF-010) dependen de T014-T017 (US4) — el aviso se agrega donde ya hay re-indexación
- **T029** (gitignore RF-011) es independiente — puede ejecutarse en paralelo
- **T030-T031** (tests RF-010/011) dependen de T027-T029
- **T018-T020** (polish) al final

## Estrategia de implementación

**MVP primero**: US1 (Escenario A) es el MVP — el flujo base que todos los demás escenarios extienden. Implementar primero T004-T007, validar con `qa-senior`, luego US2/US3/US4.

**Entrega incremental**: Cada user story es un incremento independientemente testeable. US1 entrega el flujo base; US2 agrega migración; US3 agrega documentación desde cero; US4 agrega re-indexación + memoria.

