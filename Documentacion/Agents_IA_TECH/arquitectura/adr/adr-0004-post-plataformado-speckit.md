# ADR-0004: Flujo Post-Plataformado → Speckit (3 escenarios) + Re-indexación + Constitution por proyecto + Memoria auto/manual + Graphify por app

> **Estado**: Aceptado
> **Fecha**: 2026-09-20
> **Decisión**: Definir el flujo que sigue el `pensador` después de que el bootstrap plataforma un proyecto, para llevarlo al pipeline speckit según su estado. Cubre 3 escenarios (A nuevo desde idea / B existente con docs a migrar / C existente sin docs), re-indexación automática de MCPs + Graphify al aprobar artefactos y tras implement, Constitution específica por proyecto (con Constitution Wizard Instructions estandarizado), memoria automática diaria + manual, y estrategia de Graphify con 1 grafo por app.
> **Autor**: `arquitecto` (Fase Analyze)
> **Fuente del plan**: Spec aprobada `[POST-PLATAFORMADO]` (specs/006-post-platforming-speckit/spec.md)

---

## Contexto y problema

El bootstrap (`plataformador-bootstrap.ps1`, ADR-0003) plataforma un proyecto y termina con "Flujo del instalador/actualizador único completado". Sin embargo quedan **cuatro brechas sin resolver**:

1. **No hay puente hacia speckit.** Una vez plataformado, no existe un flujo que lleve el proyecto al pipeline speckit (`specify → plan → tasks → analyze → converge → implement`) según su estado. No hay detección de si es un proyecto nuevo, uno con documentación previa a migrar, o uno con código sin docs.
2. **Índices stale.** Los MCPs (context-mode, codebase-memory) quedan indexados al momento del bootstrap. Los cambios posteriores a docs/specs no re-indexan → los índices se vuelven obsoletos y el contexto que la IA consulta no refleja el estado real.
3. **Constitution genérica.** El bootstrap copia la plantilla del kit (`.specify/memory/constitution.md` base), no una específica del proyecto. El pipeline speckit exige Constitution Check (RF-01) y Constitution Wizard (RF-14) antes de cualquier `speckit-*`.
4. **Graphify sin grafo.** Graphify queda registrado pero sin grafo construido. No hay estrategia definida de qué scope, qué modo (estructura vs deep con LLM) ni cómo actualizarlo incrementalmente.

Además, el usuario pidió explícitamente que la documentación previa en formatos no-MD (PDF, DOCX, etc.) se **mantenga en su formato original como fuente de la verdad**, migrando con asistencia IA (markitdown indexado, sin reemplazar el original).

**Principio rector**:
> *"Tras plataformar, el `pensador` lleva el proyecto al pipeline speckit según su estado real (3 escenarios), mantiene los índices y el grafo al día (auto/manual), genera una Constitution específica del proyecto, y preserva los documentos originales como fuente de verdad."*

---

## Decisión

Adoptar un **flujo post-plataformado orquestado por el `pensador`** con los siguientes componentes:

### 1. Detección de escenario (A/B/C)

Al iniciar el flujo post-plataformado, el `pensador` verifica el **estado real del proyecto** y enruta a uno de tres escenarios:

- **A — Nuevo desde idea**: sin código (`src/<App>/`) + sin documentación previa + sin constitution específica. Flujo: Constitution Wizard (RF-14) → speckit pipeline completo.
- **B — Existente con documentación a migrar**: hay documentación previa (posiblemente no-MD). Flujo: inventario con `markitdown`, preservar originales como fuente de verdad, indexar MCPs + graphify, generar nueva doc dinámica con speckit.
- **C — Existente sin documentación**: hay código pero sin docs. Flujo: crear estructura `Documentacion/<App>/` + Constitution + speckit desde cero.

La detección se basa en señales concretas: ¿existe `.specify/memory/constitution.md` específico (o es la plantilla)? ¿existe documentación previa? ¿existe código en `src/<App>/`?

### 2. Re-indexación automática al aprobar artefactos

Al aprobar spec/plan/tasks y tras implement, se dispara la re-indexación de:
- **context-mode** (`ctx_index` / index FTS5+BM25 de docs)
- **codebase-memory** (`index_repository` de código)
- **graphify** (`graphify update` del grafo de la app)

Si la re-indexación automática falla, se reporta como **WARN** en el cuadro resumen; no bloquea el flujo.

### 3. Memoria auto/manual

- **Automática diaria**: al recibir una petición, verificar la fecha de última actualización de índices/grafo; si es del día anterior o más vieja → actualizar automáticamente antes de responder. Frecuencia diaria configurable.
- **Manual**: trigger "actualizar memoria" (o similar) → actualiza context-mode + codebase-memory + graphify on-demand.

### 4. Constitution específica por proyecto

- Detectar si `.specify/memory/constitution.md` es la **plantilla genérica** del kit (`es_plantilla=true`). Si lo es → ofrecer Constitution Wizard (RF-14) para generar una específica del proyecto, **antes** de cualquier `speckit-*`.
- Cuando el flujo requiera ejecutar el Constitution Wizard (RF-09), generar `Documentacion/Constitution_Wizard_Instructions.md` estandarizado: lista de apps objetivo, comando único por app (`speckit-constitution --app <ruta>`), comportamiento del wizard (creación vs revisar/actualizar), script opcional `run_all_constitution_wizards.ps1` para ejecutar todos seguidos, y qué hacer después (pipeline speckit + reglas transversales).

### 5. Estrategia Graphify por app (estructura-first)

- **1 grafo por app** en `src/<App>/graphify-out/graph.json` como primario (los 10 tools del MCP aceptan `project_path`).
- **Vista workspace unificada on-demand** vía `graphify merge-graphs` (solo cuando se necesita).
- **Flujo estructura-first** con detección de estado:
  1. Sin grafo → `graphify extract <scope> --code-only` (estructura, sin IA).
  2. Grafo existe + código cambiado → `graphify update <scope>` (incremental, sin LLM).
  3. Flag `-GraphifyDeep` → `graphify extract --mode deep` (semántica con LLM) solo si hay backend; si no, WARN y continúa.

---

## Consecuencias

### Positivas

- **Puente completo**: el flujo post-plataformado → speckit cierra la brecha entre el bootstrap y el pipeline; el `pensador` guía cualquier proyecto según su estado real.
- **Contexto siempre fresco**: la re-indexación automática + memoria auto/manual eliminan los índices stale.
- **Constitution por proyecto**: cada app tiene su constitution específica, no la plantilla genérica; el pipeline speckit se ejecuta sobre una base válida.
- **Preservación de originales**: los documentos previos se mantienen como fuente de verdad (requisito explícito del usuario), con vista markitdown indexada para la IA.
- **Estructura-first**: sin LLM por defecto (coherente con ADR-0001), `--mode deep` solo bajo demanda y con backend disponible; evita indexar secrets.
- **Graphify escalable por app**: `update` incremental solo re-extrae la app cambiada; communities por-app significativas; sin ruido del kit (`.github/`, `.opencode/`).
- **Proceso estandarizado**: `Constitution_Wizard_Instructions.md` convierte un ejemplo aislado (trading_bot) en un flujo reproducible multi-app.

### Negativas / Trade-offs

- **Complejidad de orquestación**: el `pensador` acumula mucha lógica (detección de escenario, re-indexación, memoria auto/manual, Constitution, Graphify), lo que exige mantener las definiciones de agente en sync (`.github/` + `.opencode/`, Regla 3).
- **Re-indexación costosa si mal disparada**: re-indexar en cada cambio sería caro; se limita a aprobaciones de artefactos, implement y regla de frescura diaria (configurable).
- **Dependencia de backend LLM**: `graphify extract --mode deep` requiere backend; sin él solo se obtiene estructura (mitigable con WARN y fallback `--code-only`).
- **Frecuencia diaria no en tiempo real**: la memoria automática puede no reflejar cambios intra-día hasta la siguiente petición (trade-off aceptado por costo; hay trigger manual).

---

## Guardrails (restricciones que el código/agentes deben cumplir)

> Definidos por el `arquitecto` para la fase de implementación. Todo agente que implemente este ADR debe respetarlos.

1. **`Documentacion/<AppName>/` es sagrada**: el flujo post-plataformado y la memoria operan sobre índices y grafos, nunca sobre la documentación propia de la app. Herencia del ADR-0003.
2. **Re-indexar solo con disparador válido**: artefacto aprobado, petición con índice stale (día anterior o más vieja), o trigger manual "actualizar memoria". No re-indexar en cada cambio.
3. **Estructura-first en Graphify**: por defecto `--code-only` (sin LLM, sin secrets); `--mode deep` SOLO con flag `-GraphifyDeep` y backend LLM disponible; sin backend → WARN y continuar (nunca bloquear).
4. **Grafo por app como primario**: cada app su grafo en `src/<App>/graphify-out/`; vista workspace unificada on-demand vía `merge-graphs`, no permanente.
5. **Constitución específica del proyecto**: la plantilla del kit no es suficiente; si `es_plantilla=true`, Constitution Wizard (RF-14) antes de cualquier `speckit-*`. Sin constitution válida no se inicia el pipeline.
6. **Pipeline ordenado sin saltos**: `specify → plan → tasks → analyze → converge → implement` en orden estricto; Constitution Check (RF-01) obligatorio.
7. **Preservar originales (Escenario B)**: nunca convertir/reemplazar el documento previo; `markitdown` solo genera vista indexada para que la IA lea.
8. **La re-indexación automática no bloquea**: si falla, WARN en el cuadro resumen y el flujo continúa.
9. **Frontera de responsabilidad**: este feature es de orquestación (agentes `pensador`, `analista_tecnico`, `documentador`); no modifica código de apps ni `src/`. Únicos cambios de código permitidos: `[BOOTSTRAP-FIXES]`/`[AGENTES-INDEX]` en `scripts/plataformador-bootstrap.ps1` y definiciones de agentes.
10. **Sync de definiciones de agentes**: todo cambio a un agente se hace en `.github/agents/*` y `.opencode/agents/*` (Regla 3). Conventional commits.
11. **Configurable, no hardcodeado**: la frecuencia automática de actualización de memoria es diaria por defecto pero configurable.

---

## Alternativas consideradas

| Alternativa | Razón de rechazo |
|-------------|------------------|
| 1 grafo workspace (vs por app) | Lento, communities mezcladas, ruido del kit, `update` re-extrae todo. |
| Memoria solo manual (vs auto/manual) | Riesgo de índices stale (el problema real detectado). |
| Re-indexar en cada cambio (vs por disparador) | Costo alto, innecesario; se degrada el rendimiento. |
| `extract --mode deep` siempre (vs estructura-first) | Requiere LLM, más lento, indexa más (y secrets). |
| Solo `--code-only` (vs estructura-first + deep bajo demanda) | Pierde semántica cuando hay backend LLM disponible. |
| Preguntar siempre el escenario al usuario (vs detección automática) | La IA debe ser dinámica y detectar el estado real automáticamente. |
| Convertir toda la doc previa a MD (vs preservar originales) | Pierde el original como fuente de verdad (requisito explícito del usuario). |

---

## Spec linking (trazabilidad)

| Artefacto | Relación con este ADR |
|-----------|----------------------|
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` | Spec aprobada `[POST-PLATAFORMADO]` de la que deriva este ADR (FR-001..FR-009, SC-001..SC-007). |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/plan.md` | Plan (Constitution Check PASS 9/9; estructura doc/proceso). |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/research.md` | Decisiones D-1..D-5 (grafo por app, memoria auto/manual, estructura-first, detección escenario, preservar originales). |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/data-model.md` | Entidades Escenario/Artefacto/Índice/Constitution/Grafo + reglas de frescura. |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/tasks.md` | Tareas T001-T026 (US1-US4 + validación RF-009). |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/analyze.md` | Análisis arquitectónico del que este ADR es la versión formal. |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` | Base de la filosofía estructura-first (sin IA de entrada, IA bajo demanda). |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0002-flujos-kit.md` | Flujo de contexto + actualización de memoria/índice (base de memoria auto/manual). |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` | Define el bootstrap del que parte este flujo y los guardrails de `Documentacion/<App>/`. |
| `Documentacion/Agents_IA_TECH/specs/metodologia-ssd-speckit/spec.md` | Constitution Check (RF-01), pipeline ordenado (RF-02), Constitution Wizard (RF-14). |
| `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` | Bootstrap, `Resolve-ActiveApp`, `Sync-TransversalKit`, `Configure-Graphify` (RF-19). |
| `Documentacion/Agents_IA_TECH/MCPs/graphify.md` | Guía de Graphify (extract, update, merge-graphs, label). |
| `Documentacion/Agents_IA_TECH/seguridad/graphify.md` | Riesgos de Graphify (secrets, stdio-only, supply chain). |
| `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` | Tareas `[BOOTSTRAP-FIXES]`, `[AGENTES-INDEX]` y registro de `[POST-PLATAFORMADO]`. |
| `Documentacion/Agents_IA_TECH/00-indice.md` | Entrada de la feature activa `006-post-platforming-speckit`. |

---

## Diagrama Mermaid — Flujo post-plataformado → speckit

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
    R -->|Sí| RI[Re-indexación automática<br/>context-mode + codebase-memory + graphify]
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

## Referencias

- `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` — Spec aprobada `[POST-PLATAFORMADO]`.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` — Pipeline de documentación sin IA (estructura-first).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0002-flujos-kit.md` — Flujos del kit (contexto + actualización de memoria/índice).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — Bootstrap/instalador único del que parte este flujo.
- `Documentacion/Agents_IA_TECH/MCPs/graphify.md` — Guía de Graphify (extract, update, merge-graphs, label).
- `Documentacion/Agents_IA_TECH/seguridad/graphify.md` — Riesgos de Graphify.
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tracking de tareas `[POST-PLATAFORMADO]`, `[BOOTSTRAP-FIXES]`, `[AGENTES-INDEX]`.
- `scripts/plataformador-bootstrap.ps1` — Bootstrap del que parte el flujo post-plataformado.