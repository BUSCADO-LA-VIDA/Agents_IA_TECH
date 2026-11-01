# Feature Specification: Consolidación del Backlog de Specs

**Feature Branch**: `035-consolidacion-backlog`

**Created**: 2026-11-01

**Status**: Draft

**Input**: Consolidar y limpiar el backlog de especificaciones del KIT: archivar las obsoletas, consolidar las absorbidas por ADR, fusionar las duplicadas y registrar las completadas sin registro, para dejar solo lo que aporta valor y un tablero de la verdad coherente.

## Contexto

La auditoría `Documentacion/Agents_IA_TECH/auditoria-specs-backlog.md` (2026-11-01) detectó que el backlog de specs del KIT es incoherente con el estado real en disco:

- ~29+8 specs **huérfanas del índice** (en disco pero sin registrar).
- Varias specs **declaradas cerradas/completadas** manteniendo trabajo **sin iniciar** (032, 033) o **sin implementar** (026, 028).
- **Duplicados de numeración** (016, 017, 018, 012, 013, 021, 022).
- **Temas solapados** (013-mcp-flow ↔ 015-mcp-flow; 009 ↔ 019; 021-estructura ↔ 027; kit-generico ↔ solucion-generica).
- **7 consolidaciones por ADR** (specs resueltas por un ADR implementado: 0006, 0009/0010, 0004, 0007, 0013, 0003, 0005).
- **7 fusiones** de specs solapadas.
- **5 migraciones** (numeración/contenido obsoleto).
- **6 obsoletas** (ya no aplican).

Esta spec ejecuta la limpieza con el flujo SSD+Speckit, de forma ordenada y verificable, para dejar un único punto de la verdad: el `00-indice.md` y el `pendientes-implementacion.md` coherentes con el disco.

## User Scenarios & Testing

### User Story 1 - Índice coherente con el disco (Priority: P1)

El mantenedor del kit puede confiar en `00-indice.md` para saber qué specs existen, cuál es su estado real y dónde está cada una, sin que el índice mienta sobre specs "cerradas" o "en proceso" que en disco están sin iniciar.

**Why this priority**: Sin un índice veraz, cualquier decisión de backlog (qué implementar, qué cerrar) se apoya en datos falsos. Es la base de todo lo demás.

**Independent Test**: Ejecutar un script de verificación que compare las carpetas `specs/*/` contra las entradas de `00-indice.md` y reporte divergencias. El test pasa cuando no hay huérfanas ni divergencias disco↔índice.

**Acceptance Scenarios**:

1. **Given** una spec en disco sin entrada en el índice, **When** se ejecuta la verificación, **Then** se reporta como huérfana y se corrige (se indexa o se archiva).
2. **Given** una spec declarada "Cerrada" pero con tareas "Pendiente" en `tasks.md`, **When** se ejecuta la verificación, **Then** el estado se corrige a su estado real (En proceso/Especificada).

---

### User Story 2 - Backlog operativo como segundo control actualizado (Priority: P1)

`pendientes-implementacion.md` refleja todas las tareas pendientes reales (incluidas las de 032/033 que faltaban) y cada fase Speckit actualiza el archivo antes de reportar al pensador, como parte del flujo.

**Why this priority**: Es el segundo control del pensador: respaldo de Speckit y contenedor de procesos fuera del flujo. Si no se actualiza, la información vuelve a quedar incoherente.

**Independent Test**: El validador `VAL-XX` (nuevo) verifica que `pendientes-implementacion.md` existe, está coherente con `specs/*/tasks.md` (estados derivados) y no tiene placeholders. El test pasa cuando el archivo refleja el disco.

**Acceptance Scenarios**:

1. **Given** una spec con tareas en `tasks.md`, **When** se valida, **Then** el archivo de pendientes las contiene con el mismo estado derivado.
2. **Given** el cierre de una fase Speckit, **When** termina, **Then** actualizó `pendientes-implementacion.md` antes de reportar.

---

### User Story 3 - Consolidaciones y archivados ejecutados (Priority: P2)

Las specs absorbidas por ADR quedan consolidadas (nota + cerrado), las obsoletas se archivan a `specs/archived/`, las duplicadas se fusionan y las completadas sin registro se indexan.

**Why this priority**: Es la limpieza mecánica que ordena el backlog; depende de que la base del índice sea veraz (US1).

**Independent Test**: Para cada spec clasificada, existe una acción ejecutada verificable (archivado, nota de consolidación, fusión, indexación).

**Acceptance Scenarios**:

1. **Given** una spec absorbida por ADR, **When** se consolida, **Then** queda una nota de consolidación y la spec se marca cerrada/archivada.
2. **Given** una spec obsoleta, **When** se archiva, **Then** su carpeta pasa a `specs/archived/` y el índice la refleja.

---

### User Story 4 - Gate de coherencia permanentizado (Priority: P2)

Una verificación automática (`VAL-XX`) en el validador del kit hace cumplir la coherencia backlog↔disco, para que la regresión no vuelva a ocurrir en silencio.

**Why this priority**: La causa raíz de la incoherencia fue que la regla existía pero no se verificaba. Sin gate, el problema reaparece.

**Independent Test**: Se fuerza una divergencia (agregar una spec huérfana o un estado falso) y el validador la detecta y emite FAIL.

**Acceptance Scenarios**:

1. **Given** una spec huérfana en disco, **When** corre el validador, **Then** reporta la divergencia.
2. **Given** un estado falso en el índice, **When** corre el validador, **Then** lo reporta.

### Edge Cases

- **Spec con el mismo tema bajo dos números**: se fusiona la secundaria en la canónica y se archiva la duplicada.
- **Spec absorbida por ADR pero con contenido no cubierto por el ADR**: se conserva el contenido en la nota de consolidación antes de cerrar.
- **Spec declarada cerrada que en disco tiene tareas pendientes**: se corrige al estado real; nunca se marca cerrada sin evidencia.
- **Spec huérfana completa**: se indexa en `00-indice.md` como cerrada (no se archiva ni se borra).
- **Fusión entre specs que ambas tienen tasks pendientes**: se consolidan las tareas en la canónica antes de archivar la secundaria.
- **Requerimiento futuro propuesto durante una fase Speckit**: se redirige a `pendientes-implementacion.md` como backlog (a refinar por Speckit), nunca se agrega al `spec.md` del feature en curso ni a specs ya cerradas. Esto aplica a TODOS los agentes documentales (pensador, documentador, arquitecto, security-auditor, Agent-SSD).

## Requirements

### Functional Requirements

- **FR-001**: El sistema de indexación (agente documental) DEBE poder generar un inventario real de `specs/*/` cruzado contra `00-indice.md`, reportando huérfanas y divergencias.
- **FR-002**: El índice `00-indice.md` DEBE reflejar el estado real de cada spec derivado de su `tasks.md`/`converge.md` (no estados declarados manualmente que contradigan el disco).
- **FR-003**: El archivo `pendientes-implementacion.md` DEBE contener todas las tareas de `specs/*/tasks.md` con IDs calificados `<spec>-T<nnn>` y estados derivados (regla de agregación multi-spec de la feature 017).
- **FR-004**: Cada fase Speckit (`specify/plan/tasks/analyze/converge`) DEBE actualizar `pendientes-implementacion.md` antes de reportar al pensador (mecanismo de la feature 017, reforzado con gate).
- **FR-005**: El validador del kit DEBE incluir una verificación (`VAL-XX`) que compare backlog↔disco y falle en divergencias (huérfanas, estados falsos, placeholders).
- **FR-006**: Las specs absorbidas por un ADR implementado DEBEN consolidarse (nota de absorción) y cerrarse, sin retener contenido huérfano.
- **FR-007**: Las specs obsoletas DEBEN archivarse a `specs/archived/` con nota de motivo, sin borrarse.
- **FR-008**: Las specs duplicadas DEBEN fusionarse en la canónica (se consolida su contenido/tasks), y la secundaria se archiva.
- **FR-009**: Las specs completadas sin registro DEBEN indexarse en `00-indice.md` como cerradas.
- **FR-010**: La limpieza DEBE respetar la integridad de datos: ninguna spec se borra ni se pierde contenido al consolidar/archivar/fusionar.

- **FR-011**: El sistema de especificación DEBE mantener los specs **acotados al alcance presente**: prohibido agregar a `spec.md` requisitos, intenciones o mejoras con criterio "por si acaso" o "para el futuro". Todo requerimiento futuro o mejora DEBE registrarse en `pendientes-implementacion.md` como backlog a refinar por Speckit, y NO forma parte del spec.

### Key Entities

- **Spec**: Directorio `specs/<NNN-slug>/` con sus artefactos (spec.md, plan.md, tasks.md, analyze.md, converge.md, etc.).
- **Índice** (`00-indice.md`): Registro declarativo del estado de cada spec.
- **Backlog** (`pendientes-implementacion.md`): Registro operativo de tareas, segundo control del pensador.
- **ADR**: Decisiones arquitectónicas que pueden absorber o redefinir el tema de una spec.
- **Validador** (`scripts/validate-agents-skills.ps1`): Gate que detecta divergencias.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 0 specs huérfanas en disco sin entrada en `00-indice.md` (verificado por script).
- **SC-002**: 0 divergencias de estado entre `00-indice.md` y el `tasks.md`/`converge.md` real de cada spec.
- **SC-003**: `pendientes-implementacion.md` contiene el 100% de las tareas de `specs/*/tasks.md` con estados derivados y IDs calificados.
- **SC-004**: El validador `VAL-XX` pasa en el estado final (FAIL: 0) y detecta al menos una divergencia forzada (fixture negativo).
- **SC-005**: Las ~7 consolidaciones por ADR, ~7 fusiones, ~6 obsoletas y ~5 migraciones de la auditoría quedan ejecutadas y documentadas (nada queda "airborne" sin decidir).
- **SC-006**: 0 requerimientos "por si acaso" o "para el futuro" dentro de los `spec.md` del kit; todo requerimiento futuro vive en `pendientes-implementacion.md` como backlog a refinar por Speckit. Verificado por revisión de specs + norma de flujo en agentes documentales.

## Assumptions

- Las specs absorbidas por ADR (resueltas por ADR-0003/0004/0005/0006/0007/0009/0010/0013) se consolidan y cierran, porque el ADR ya define la forma actual de trabajo (decisión de criterio del usuario, 2026-11-01).
- Las specs 032/033/029/030, 024/025/027 y las divergentes 026/028 (implementación) permanecen como PENDIENTE-REAL: la limpieza no las implementa, solo registra su estado real.
- El archivo `pendientes-implementacion.md` es un segundo control del pensador: respaldo de Speckit y contenedor de procesos fuera del flujo (decisión del usuario).
- La numeración de spec nueva para consolidar (si procede para Docker/kit-generico/solucion-generica) se define durante el Plan, no en esta spec.
- Ninguna spec se borra del disco: las obsoletas se archivan a `specs/archived/`.
- El `feature.json` de `.specify/` lo gestiona el `Agent-SSD`; los artefactos de la spec 035 viven en `Documentacion/Agents_IA_TECH/specs/`.
