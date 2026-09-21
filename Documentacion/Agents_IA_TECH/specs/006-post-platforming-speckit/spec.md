# Spec: [POST-PLATAFORMADO] — Flujo post-plataformado → speckit (3 escenarios) + re-indexación + Constitution por proyecto + memoria auto/manual

**Versión**: 1.0
**Fecha**: 2026-09-20
**Estado**: Borrador
**Autor**: pensador

---

## Objetivo

Definir el flujo que sigue el `pensador` **después** de que el bootstrap plataforma un proyecto (`plataformador-bootstrap.ps1`), para llevarlo al pipeline speckit según su estado. Cubre 3 escenarios (nuevo / existente con docs a migrar / existente sin docs), la re-indexación automática de MCPs + Graphify al aprobar artefactos, la Constitution específica por proyecto, la estrategia de Graphify por aplicación, y la actualización de memoria (índices + grafo) automática diaria y manual.

**Contexto**: El bootstrap termina con "Flujo del instalador/actualizador único completado" pero **no hay puente hacia speckit**. Los MCPs quedan indexados al momento del bootstrap; los cambios posteriores a docs/specs no re-indexan (índices stale). La Constitution copiada es la plantilla del kit, no una específica del proyecto. Graphify queda registrado pero sin grafo construido.

---

## User Scenarios & Testing

### User Story 1 — Proyecto nuevo desde idea (Escenario A) (Priority: P1)

El usuario tiene una idea y un proyecto recién plataformado (o sin plataformar). El `pensador` detecta que no hay documentación previa ni estructura de app, y guía el flujo completo: Constitution Wizard → speckit pipeline.

**Why this priority**: Es el caso base y el más común; sin él no hay pipeline.

**Independent Test**: Puede probarse creando un proyecto vacío y verificando que el `pensador` detecta el escenario A y ejecuta Constitution → specify → plan → tasks.

**Acceptance Scenarios**:

1. **Given** un proyecto sin `.specify/memory/constitution.md` específico, **When** el `pensador` inicia el flujo post-plataformado, **Then** ofrece el Constitution Wizard (RF-14) antes de cualquier `speckit-*`.
2. **Given** una constitution válida, **When** el usuario pide una feature, **Then** se ejecuta el pipeline `specify → plan → tasks → analyze → converge` en orden estricto.

---

### User Story 2 — Proyecto existente con documentación a migrar (Escenario B) (Priority: P1)

El proyecto tiene documentación previa (posiblemente en formatos no-MD) que debe migrarse a la nueva estructura `Documentacion/<App>/`, preservando los originales como fuente de verdad. La nueva documentación se genera dinámicamente con speckit según lo que la IA lee.

**Why this priority**: Es el caso más complejo y el que el usuario quiere resolver (migración asistida con IA).

**Independent Test**: Puede probarse con un proyecto que tenga docs en PDF/DOCX y verificar que: (1) se inventarían con markitdown, (2) los originales se preservan, (3) se indexan MCPs + graphify, (4) la IA genera la nueva doc con speckit.

**Acceptance Scenarios**:

1. **Given** un proyecto con documentación previa, **When** se inicia el flujo post-plataformado, **Then** el `pensador` pregunta si existe documentación previa a migrar.
2. **Given** documentación previa en formatos no-MD, **When** se migra, **Then** los originales se preservan como fuente de verdad (markitdown genera vista Markdown indexada sin reemplazar el original).
3. **Given** documentación previa migrada, **When** se genera la nueva doc, **Then** se usa speckit dinámicamente según lo que la IA lee de la documentación.

---

### User Story 3 — Proyecto existente sin documentación (Escenario C) (Priority: P2)

El proyecto existe con código pero sin documentación. Se crea la nueva estructura y se documenta desde cero con speckit.

**Why this priority**: Menos común que B pero necesario.

**Independent Test**: Puede probarse con un proyecto con código pero sin docs, verificando que se crea la estructura y se documenta con speckit.

**Acceptance Scenarios**:

1. **Given** un proyecto con código pero sin documentación, **When** se inicia el flujo, **Then** se crea la estructura `Documentacion/<App>/` + Constitution + speckit desde cero.

---

### User Story 4 — Re-indexación automática y memoria (Priority: P2)

Al aprobar spec/plan/tasks y tras implement, los índices (context-mode, codebase-memory) y el grafo (graphify) se actualizan automáticamente. La memoria se actualiza automáticamente cada día (si la última actualización es del día anterior) o manualmente con "actualizar memoria".

**Why this priority**: Evita índices stale y garantiza contexto actualizado.

**Independent Test**: Puede probarse verificando que tras aprobar un artefacto, los índices se re-indexan; y que al pedir "actualizar memoria" se actualizan índices + grafo.

**Acceptance Scenarios**:

1. **Given** un artefacto aprobado (spec/plan/tasks), **When** se confirma, **Then** se dispara la re-indexación de context-mode + codebase-memory + graphify.
2. **Given** una petición del usuario, **When** la última actualización de memoria es del día anterior o más vieja, **Then** se actualiza automáticamente antes de responder.
3. **Given** el usuario dice "actualizar memoria" (o similar), **When** se recibe el trigger, **Then** se actualizan índices + grafo on-demand.

---

### Edge Cases

- ¿Qué pasa si el proyecto tiene documentación previa pero en estructura no estándar? → Se migra a la nueva estructura con análisis IA.
- ¿Qué pasa si no hay backend LLM configurado para `graphify extract --mode deep`? → Se usa `--code-only` (estructura, sin IA) y se WARN.
- ¿Qué pasa si el grafo de una app ya existe pero el código cambió? → `graphify update` (incremental, sin LLM).
- ¿Qué pasa si el usuario no quiere migrar la documentación previa? → Se respeta y se documenta desde cero (Escenario C).
- ¿Qué pasa si la re-indexación automática falla? → Se reporta como WARN en el cuadro resumen, no bloquea.
- ¿Qué pasa si el Constitution Wizard se requiere para varias apps? → Se genera `Documentacion/Constitution_Wizard_Instructions.md` con la lista de apps y el script para ejecutar todos los wizards seguidos (patrón del ejemplo de trading_bot).
- ¿Qué pasa si `graphify-out/` no está en `.gitignore`? → Se agrega (FR-011); si ya hay grafos trackeados, `git rm --cached` para dejar de versionarlos sin borrarlos del disco.

---

## Requirements

### Functional Requirements

- **FR-001**: El sistema DEBE detectar el escenario post-bootstrap (A nuevo desde idea / B existente con docs a migrar / C existente sin docs) al iniciar el flujo post-plataformado.
- **FR-002**: El sistema DEBE, en el escenario A, ejecutar Constitution Wizard (RF-14) → speckit pipeline completo (specify → plan → tasks → analyze → converge).
- **FR-003**: El sistema DEBE, en el escenario B, inventariar la documentación previa con markitdown, preservar los originales como fuente de verdad, indexar MCPs + graphify, y generar la nueva documentación dinámicamente con speckit.
- **FR-004**: El sistema DEBE, en el escenario C, crear la estructura `Documentacion/<App>/` + Constitution + speckit desde cero.
- **FR-005**: El sistema DEBE re-indexar automáticamente (context-mode + codebase-memory + graphify) al aprobar spec/plan/tasks y tras implement.
- **FR-006**: El sistema DEBE detectar si la Constitution es la plantilla genérica del kit y ofrecer el Constitution Wizard (RF-14) para generar una específica del proyecto.
- **FR-007**: El sistema DEBE usar 1 grafo de Graphify por app (`src/<App>/graphify-out/`) como primario, con vista workspace unificada on-demand vía `merge-graphs`.
- **FR-008**: El sistema DEBE actualizar la memoria (índices + grafo) automáticamente cada día (si la última actualización es del día anterior o más vieja) y manualmente con el trigger "actualizar memoria".
- **FR-009**: Cuando el flujo post-plataformado requiera ejecutar el Constitution Wizard (RF-06), el sistema DEBE generar un documento `Constitution_Wizard_Instructions.md` en `Documentacion/` (raíz del proyecto) que estandarice el proceso: lista de aplicaciones objetivo, comando único por app (`speckit-constitution --app <ruta>`), comportamiento del wizard (creación vs revisar/actualizar), script opcional para ejecutar todos los wizards seguidos, y qué hacer después (pipeline speckit + reglas transversales).
- **FR-010**: Cuando se ejecuten procesos de re-indexación (RF-05) o actualización de memoria (RF-08), el sistema DEBE mostrar un **aviso visible** de que la re-indexación está en ejecución (ej. "Re-indexando context-mode + codebase-memory + graphify..."), para que el usuario sepa que la operación está corriendo y no la confunda con una pausa o error.
- **FR-011**: El directorio `graphify-out/` (grafos de Graphify) DEBE estar en `.gitignore` para que **nunca** se suba a repositorios. Esto mitiga el riesgo de que `.env`, claves o datos no requeridos se suban accidentalmente. Costo aceptado: al iniciar, la extracción del grafo gasta más tiempo y tokens (solo la primera vez o tras cambios).

### Key Entities

- **Escenario**: A (nuevo desde idea) / B (existente con docs a migrar) / C (existente sin docs).
- **Artefacto speckit**: spec.md, plan.md, tasks.md, analyze.md, converge.md.
- **Índice**: context-mode (docs), codebase-memory (código), graphify (grafo).
- **Constitution**: `.specify/memory/constitution.md` específica del proyecto.
- **Grafo por app**: `src/<App>/graphify-out/graph.json`.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: El `pensador` detecta correctamente el escenario (A/B/C) en el 100% de los casos al iniciar el flujo post-plataformado.
- **SC-002**: En el escenario B, el 100% de los documentos previos se inventarían con markitdown y los originales se preservan sin modificación.
- **SC-003**: Tras aprobar un artefacto, la re-indexación (context-mode + codebase-memory + graphify) se completa en menos de 2 minutos.
- **SC-004**: La memoria se actualiza automáticamente cuando la última actualización es del día anterior o más vieja, en el 100% de las peticiones.
- **SC-005**: El trigger manual "actualizar memoria" actualiza índices + grafo on-demand en el 100% de los casos.
- **SC-006**: Cada app tiene su propio grafo Graphify (`src/<App>/graphify-out/`), y la vista workspace unificada se construye on-demand vía `merge-graphs`.
- **SC-007**: Cuando el flujo requiera ejecutar el Constitution Wizard, se genera `Documentacion/Constitution_Wizard_Instructions.md` con: lista de apps objetivo, comando único por app, comportamiento del wizard (creación vs revisar/actualizar), script opcional para ejecutar todos seguidos, y qué hacer después (pipeline speckit + reglas transversales). El documento es válido y accionable (los comandos funcionan).
- **SC-008**: Cuando se ejecuta una re-indexación o actualización de memoria, el usuario ve un aviso visible de que la operación está en ejecución (no la confunde con pausa/error).
- **SC-009**: `graphify-out/` está en `.gitignore` — `git check-ignore graphify-out/` devuelve 0 (ignorado). Ningún grafo, `.env` o clave se sube al repositorio.

---

## Assumptions

- El bootstrap (`plataformador-bootstrap.ps1`) ya se ejecutó y plataformó el proyecto (estructura `src/<App>/` + `Documentacion/<App>/` + `.specify`).
- Los MCPs (context-mode, codebase-memory, graphify) están instalados y registrados.
- Graphify está instalado (v0.9.48) y el CLI disponible.
- La documentación previa en formatos no-MD se preserva como fuente de verdad; markitdown genera vista Markdown indexada sin reemplazar el original.
- La frecuencia automática de actualización de memoria es diaria (configurable).
- El trigger manual es la frase "actualizar memoria" (o similar).
- `graphify extract --mode deep` requiere backend LLM configurado; si no, se usa `--code-only` (estructura, sin IA).

---

## Dependencias

- `specs/metodologia-ssd-speckit/spec.md` — Constitution Check (RF-01), pipeline ordenado (RF-02), Constitution Wizard (RF-14).
- `specs/plataforma-bootstrap-instalador-unico/spec.md` — bootstrap, `Resolve-ActiveApp`, `Sync-TransversalKit`, `Configure-Graphify` (RF-19).
- `MCPs/graphify.md` — guía de Graphify (extract, update, merge-graphs, label).
- `seguridad/graphify.md` — riesgos de Graphify (secrets, stdio-only, supply chain).
- Tareas `[BOOTSTRAP-FIXES]`, `[AGENTES-INDEX]` en `pendientes-implementacion.md`.
