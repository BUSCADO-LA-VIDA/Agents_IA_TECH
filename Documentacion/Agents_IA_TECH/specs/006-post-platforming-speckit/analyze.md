# Analyze: post-platforming-speckit

> **Rol**: `arquitecto` (Fase Analyze)
> **Fecha**: 2026-09-20
> **Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md) | **Data Model**: [data-model.md](data-model.md) | **Tasks**: [tasks.md](tasks.md)
> **ADR**: [adr-0004-post-plataformado-speckit](../../arquitectura/adr/adr-0004-post-plataformado-speckit.md)

---

## Resumen del análisis arquitectónico

La spec `[POST-PLATAFORMADO]` define el **puente que faltaba** entre el bootstrap (`plataformador-bootstrap.ps1`, ADR-0003) y el pipeline speckit. No agrega código de aplicación: es un **flujo de orquestación del `pensador`** que normaliza el estado de cualquier proyecto recién plataformado hacia el ciclo `specify → plan → tasks → analyze → converge → implement`.

Arquitectónicamente el feature resuelve cuatro brechas detectadas en modo real:

1. **Sin puente post-bootstrap** — el bootstrap termina en "Flujo completado" pero no hay camino hacia speckit. La detección de escenario (A/B/C) se convierte en el enrutador de entrada.
2. **Índices stale** — los MCPs (context-mode, codebase-memory) quedan indexados al momento del bootstrap; los cambios posteriores de docs/specs no re-indexan. Se introduce re-indexación automática al aprobar artefactos + memoria auto/manual con regla de frescura diaria.
3. **Constitution genérica** — el bootstrap copia la plantilla del kit; el feature detecta `es_plantilla=true` y ofrece el Constitution Wizard (RF-14) para generar una específica del proyecto.
4. **Graphify sin grafo** — Graphify queda registrado pero sin grafo construido. Se adopta estrategia **estructura-first** con 1 grafo por app.

El análisis confirma que el plan (Constitution Check PASS 9/9) es coherente y que las 26 tareas se derivan correctamente de las 4 user stories. No hay violaciones de arquitectura que justificar; se definen guardrails para la implementación.

---

## Decisiones clave

### D1 — Grafo por app (Graphify) — `FR-007`
- **Decisión**: 1 grafo por app en `src/<App>/graphify-out/graph.json` como primario; vista workspace unificada on-demand vía `graphify merge-graphs`.
- **Por qué**: los 10 tools del MCP graphify aceptan `project_path` (soporte nativo multi-grafo); `update` incremental solo re-extrae la app cambiada; communities por-app son significativas; evita ruido del kit (`.github/`, `.opencode/` no son código de app); alinea con el flujo speckit per-app.
- **Origen**: research D-1; spec FR-007; data-model entidad *Grafo por app*.

### D2 — Memoria auto/manual — `FR-008`
- **Decisión**: actualización automática diaria (si la última actualización es del día anterior o más vieja, se actualiza antes de responder) + manual con trigger "actualizar memoria". Actualiza context-mode + codebase-memory + graphify.
- **Por qué**: evita índices stale (problema real detectado); la frecuencia diaria balancea frescura y costo.
- **Origen**: research D-2; spec FR-008; data-model entidad *Índice* + regla de frescura.

### D3 — Estructura-first graphify — `FR-007` / D-3 research
- **Decisión**: flujo estructura-first con detección de estado: sin grafo → `extract --code-only` (estructura, sin IA); grafo existe + código cambiado → `update` (incremental, sin LLM); flag `-GraphifyDeep` → `extract --mode deep` (semántica con LLM, solo si hay backend; si no, WARN y sigue).
- **Por qué**: coincide con la filosofía del `analista_tecnico` (ADR-0001: sin IA de entrada, IA bajo demanda); `--code-only` evita indexar secrets.
- **Origen**: research D-3; data-model regla de construcción del grafo.

### D4 — Detección de escenario — `FR-001`
- **Decisión**: el `pensador` detecta automáticamente el escenario (A/B/C) por el estado real del proyecto: ¿constitution específica? ¿documentación previa? ¿código en `src/<App>/`? — en lugar de preguntar siempre al usuario.
  - `A` = sin código + sin documentación previa + sin constitution específica → Constitution Wizard → speckit pipeline.
  - `B` = con documentación previa a migrar → inventario markitdown + preservar originales + speckit dinámico.
  - `C` = con código pero sin documentación → crear estructura + Constitution + speckit desde cero.
- **Por qué**: la IA debe ser dinámica y detectar automáticamente el estado.
- **Origen**: research D-4; spec FR-001/FR-002/FR-003/FR-004; data-model entidad *Escenario* + reglas de detección.

### D5 — Preservar originales en migración (Escenario B) — `FR-003`
- **Decisión**: los documentos previos en formatos no-MD (PDF, DOCX, etc.) se preservan como fuente de verdad; `markitdown` genera una vista Markdown indexada (para context-mode) **sin reemplazar el original**.
- **Por qué**: el usuario pidió explícitamente "mantener en su formato original como fuente de la verdad".
- **Origen**: research D-5; spec FR-003; SC-002.

### D6 — Constitution Wizard Instructions — `RF-009` / `FR-009`
- **Decisión**: cuando el flujo requiera ejecutar el Constitution Wizard, se genera `Documentacion/Constitution_Wizard_Instructions.md` con estructura estandarizada: lista de apps objetivo, comando único por app (`speckit-constitution --app <ruta>`), comportamiento del wizard (creación vs revisar/actualizar), script opcional `run_all_constitution_wizards.ps1`, y qué hacer después (pipeline speckit + reglas transversales).
- **Por qué**: estandariza un proceso que hoy vive en un ejemplo aislado (trading_bot); permite ejecutar wizards de varias apps seguidos.
- **Origen**: spec RF-009/FR-009, SC-007; tasks T021-T026 (fase 8 de validación).

---

## Guardrails arquitectónicos

Restricciones que la implementación debe respetar (los agentes implementadores los leen desde aquí y desde el ADR-0004):

1. **`Documentacion/<AppName>/` nunca se toca en re-indexación/sync** — el flujo post-plataformado y la memoria operan sobre índices y grafos, no sobre la documentación propia de la app (herencia del ADR-0003, guardrail 1).
2. **Fresca o stale, nunca "siempre indexar"** — la memoria se actualiza solo cuando hay un disparador válido (artefacto aprobado, petición con índice stale del día anterior/más vieja, o trigger manual "actualizar memoria"). No re-indexar en cada cambio (costo).
3. **Estructura-first en Graphify** — por defecto `--code-only` (sin LLM, sin secrets); `--mode deep` SOLO con flag explícito `-GraphifyDeep` y backend LLM disponible; si no hay backend, WARN y continuar (nunca bloquear).
4. **Grafo por app como primario** — cada app su grafo en `src/<App>/graphify-out/`; la vista workspace unificada se construye on-demand vía `merge-graphs`, no de forma permanente.
5. **Constitución específica del proyecto** — la plantilla genérica del kit NO es suficiente; si `es_plantilla=true`, se ofrece el Constitution Wizard (RF-14) antes de cualquier `speckit-*`. El pipeline no puede iniciar sin constitution válida.
6. **Pipeline ordenado sin saltos** — `specify → plan → tasks → analyze → converge → implement` en orden estricto; Constitution Check (RF-01) obligatorio antes de cualquier `speckit-*`.
7. **Preservar originales en Escenario B** — nunca convertir/reemplazar el documento previo; `markitdown` solo genera vista indexada para que la IA lea.
8. **La re-indexación automática no bloquea** — si falla, se reporta como WARN en el cuadro resumen y el flujo continúa.
9. **Frontera de responsabilidad** — este feature es de orquestación (agentes `pensador`, `analista_tecnico`, `documentador`); no modifica código de apps ni `src/`. Los únicos cambios de código permitidos son los `[BOOTSTRAP-FIXES]`/`[AGENTES-INDEX]` en `scripts/plataformador-bootstrap.ps1` y las definiciones de agentes (`.github/` + `.opencode/` en paralelo, Regla 3).
10. **Sync de definiciones de agentes** — todo cambio a un agente se hace en `.github/agents/*` y `.opencode/agents/*` (Regla 3). Convencional commits.
11. **Configurable, no hardcodeado** — la frecuencia automática de actualización de memoria es diaria por defecto pero configurable.

---

## Spec linking (trazabilidad)

### spec.md ↔ plan.md
- `FR-001` (detección escenario) ↔ plan Constitution Check PASS + tareas T004/T005.
- `FR-002` (Escenario A pipeline) ↔ plan Project Structure + tareas T004-T007.
- `FR-003` (Escenario B migración) ↔ plan + tareas T008-T011.
- `FR-004` (Escenario C) ↔ plan + tareas T012-T013.
- `FR-005` (re-indexación al aprobar) ↔ plan + tareas T014, T017.
- `FR-006`/`RF-009`/`FR-009` (Constitution Wizard) ↔ plan + tareas T006, T021-T026.
- `FR-007` (grafo por app) ↔ plan + tarea T002.
- `FR-008` (memoria auto/manual) ↔ plan + tareas T015-T016.
- `SC-001..SC-007` ↔ plan Performance Goals / Constraints + tareas de validación T021-T026.

### spec.md ↔ tasks.md
- US1 (Escenario A) ↔ T004-T007 (flujo base, MVP).
- US2 (Escenario B) ↔ T008-T011 (migración asistida).
- US3 (Escenario C) ↔ T012-T013 (documentación desde cero).
- US4 (Re-indexación + memoria) ↔ T014-T017.
- RF-009 ↔ T021-T026 (tests de validación del documento estandarizado).
- Polishing ↔ T018-T020.

### spec.md / plan.md / tasks.md ↔ ADRs
| ADR | Relación |
|-----|----------|
| `adr-0001-ecosistema-documentacion-sin-ia.md` | Base de la filosofía estructura-first (D3): sin IA de entrada, IA bajo demanda. |
| `adr-0002-flujos-kit.md` | Flujo de contexto: consultar `Documentacion/` + MCPs como optimización + actualización de memoria/índice (base de D2 y US4). |
| `adr-0003-plataforma-bootstrap-instalador-unico.md` | Define el bootstrap del que parte este flujo (punto de entrada post-plataformado) y los guardrails de `Documentacion/<App>/`. |
| `adr-0004-post-plataformado-speckit.md` | **Este ADR** — recoge el flujo post-plataformado → speckit (3 escenarios), re-indexación, Constitution por proyecto, memoria auto/manual, Graphify por app. |

### Otras fuentes
- `specs/metodologia-ssd-speckit/spec.md` — Constitution Check (RF-01), pipeline ordenado (RF-02), Constitution Wizard (RF-14).
- `specs/plataforma-bootstrap-instalador-unico/spec.md` — bootstrap, `Resolve-ActiveApp`, `Sync-TransversalKit`, `Configure-Graphify` (RF-19).
- `MCPs/graphify.md` — guía de Graphify (extract, update, merge-graphs, label).
- `seguridad/graphify.md` — riesgos de Graphify (secrets, stdio-only, supply chain).
- `pendientes-implementacion.md` — tareas `[BOOTSTRAP-FIXES]`, `[AGENTES-INDEX]` y el registro de `[POST-PLATAFORMADO]`.

---

## Resumen de artefactos generados

| Artefacto | Ruta |
|-----------|------|
| Analyze | `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/analyze.md` |
| ADR-0004 | `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md` |