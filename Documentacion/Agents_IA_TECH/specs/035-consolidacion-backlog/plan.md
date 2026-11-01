# Implementation Plan: Consolidación del Backlog de Specs

**Branch**: `035-consolidacion-backlog` | **Date**: 2026-11-01 | **Spec**: [035-consolidacion-backlog/spec.md](./spec.md)

**Input**: Feature specification from `/specs/035-consolidacion-backlog/spec.md`

**Nota**: Este plan se ejecuta en el proyecto **kit** (sin `src/`), donde según la Constitution Art.II L134 el `pensador` puede ejecutar Speckit directamente porque los artefactos van a `Documentacion/Agents_IA_TECH/specs/`. Los artefactos del plan viven en la carpeta de la spec 035.

## Summary

La limpia del backlog de specs del KIT. La auditoría `auditoria-specs-backlog.md` detectó ~59 especificaciones con estados incoherentes entre disco, `00-indice.md` y `pendientes-implementacion.md`. Este plan ejecuta la consolidación en bloques ordenados y verificables, respetando la integridad de datos (nada se borra; las obsoletas se archivan), y deja un único punto de la verdad: índice y backlog coherentes con el disco, con un gate automático (`VAL-XX`) que evita la regresión.

El foco NO es implementar las specs pendientes (032/033/029/030/024/025/027/026-impl/028-impl): solo normalizar su estado y registrarlas correctamente. Las consolidationes/fusiones/archivados se ejecutan con trazabilidad.

## Technical Context

**Language/Version**: Markdown (documentación/estado), PowerShell 7+ (scripts de verificación), JSON (opencode.json, bootstrap-state). El kit es configuración, no aplicación (Constitution: "el kit es configuración, no aplicación: no hay src/, ni build, ni runtime de aplicación").

**Primary Dependencies**: `scripts/validate-agents-skills.ps1` (validador, incorporará `VAL-XX`); `Documentacion/Agents_IA_TECH/specs/` (las ~59 specs); `00-indice.md` y `pendientes-implementacion.md` (registros); `auditoria-specs-backlog.md` (fuente de veredictos).

**Storage**: Archivos Markdown en `Documentacion/Agents_IA_TECH/`. No hay base de datos.

**Testing**: Verificación por script PowerShell plano (exit 0/1) que cruza `specs/*/` contra `00-indice.md` y `pendientes-implementacion.md`. No Pester (hostil, ver 034).

**Target Platform**: PowerShell 7+ / Windows. Los comandos se ejecutan localmente en el kit.

**Project Type**: Kit de agentes + skills + configuración (repository de configuración, no aplicación).

**Performance Goals**: N/A — no hay runtime. Se mide completitud del backlog (0 divergencias), no rendimiento.

**Constraints**:
- Ninguna spec se borra: las obsoletas se archivan a `specs/archived/`.
- `Documentacion/<AppName>/` es del proyecto y `specs/archived/` debe respetar la frontera.
- Regla de integridad: no marcar nada "Cerrado" sin evidencia en disco.
- Prohibido tocar `Documentacion/<OtraApp>/` (cada app aislada).
- El `feature.json` de `.specify/` lo gestiona `Agent-SSD`; el pensador no escribe en `.specify/`.

**Scale/Scope**: ~59 specs clasificadas; 7 absorciones por ADR, 7 fusiones, 6 obsoletas, 5 migraciones, ~8 completadas sin registro, 17 pendientes reales.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Resultado | Nota |
|---|---|---|
| I. Modular Agent Design | ✅ PASS | Los agentes documentales conservan su whitelist; no se crean agentes nuevos salvo verificación. |
| II. Orchestrator Pattern | ✅ PASS | Ejecutado por el `pensador` en excepción kit (Art.II L134); `Agent-SSD` gestiona `.specify/`. |
| III. SSD | ✅ PASS | Ciclo completo specify → plan → tasks → analyze → converge → implement. |
| IV. Copilot/Opencode | ✅ PASS | Solo se tocan `Documentacion/Agents_IA_TECH/` (índice, backlog, specs, auditoría); `.github/`/`.opencode/` solo para `VAL-XX` en validador (que va en `scripts/`, transversal). |
| V. Observability | ✅ PASS | Cada consolidación/archivado deja trazabilidad (nota, bitácora de fecha, entry en índice). |
| VI. proyect_ext | ✅ PASS | No se toca `proyect_ext/` ni dependencias externas. |
| VII. Paths por Tier | ✅ PASS | El pensador escribe solo en `Documentacion/<AppName>/`; archivar a `specs/archived/` está dentro de esa ruta. |
| VIII. Fail-Open | ✅ PASS | Los movimientos no son destructivos fuera de allowlist; el archivado es fail-closed con confirmación. |
| IX. Contenido Completo | ✅ PASS | Todos los artefactos (spec, plan, tasks, notes de consolidación) con contenido real, sin placeholders. |

**Constitution Check: PASS.** Ninguna violación que justificar (Complexity Tracking vacío).

## Project Structure

### Documentación (feature 035)

```text
Documentacion/Agents_IA_TECH/specs/035-consolidacion-backlog/
├── spec.md              # Especificación (creada por speckit-specify)
├── plan.md              # Este archivo (speckit-plan)
├── research.md          # Fase 0 (resolución de incógnitas del contexto)
├── data-model.md        # Fase 1 (entidades del sistema de estado)
├── quickstart.md        # Fase 1 (guía de verificación end-to-end)
├── contracts/           # Fase 1 (contrato del VAL-XX de coherencia)
├── checklists/
│   └── requirements.md  # Checklist de calidad de la spec
└── tasks.md             # Fase tasks (speckit-tasks)
```

Además, se actualizan:
- `Documentacion/Agents_IA_TECH/00-indice.md` (estados corregidos y nuevas entradas).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` (segundo control, ya parcialmente alineado).
- `Documentacion/Agents_IA_TECH/auditoria-specs-backlog.md` (se marca como base de veredictos ejecutados).
- `scripts/validate-agents-skills.ps1` (recibe `VAL-XX`, va en `scripts/`, transversal).

### Source Code

No hay `src/` (kit). El único código tocado es `scripts/validate-agents-skills.ps1` (agregar `VAL-XX`), que corre el gate. No se crean proyectos nuevos.

**Structure Decision**: Estructura documental del kit (ya definida por las specs previas). No hay opciones de estructura de aplicación que aplicar.

## Complexity Tracking

No aplica: Constitution Check PASS sin violaciones. La consolidación se mantiene dentro de la whitelist documental y no exige abstracciones nuevas.

---

## Fases de consolidación (bloques ordenados)

La ejecución sigue bloques de menor a mayor riesgo, cada uno verificable por separado y en orden dependiente:

### Fase A — Normalizar estados del índice (base)
Corrige las divergencias disco↔índice ya identificadas (032, 033, 026, 028 en el índice — **ya hechas** en esta sesión) y verifica que el `00-indice.md` ya no declare cerrado/en-proceso lo que está sin iniciar. Asegurada; se verifica con el VAL-XX.
**Salida**: `00-indice.md` con estados reales; verificable.

### Fase B — Indexar completadas sin registro
Las specs completadas en disco pero ausentes del índice se agregan como cerradas (006-post-platforming, 007-mcp-token-resolution, 009-path-normalization, 014-manifest, 015-sync-bootstrap, 019-update-mcp, kit-generico, solucion-generica).
**Salida**: entradas nuevas en `00-indice.md`.

### Fase C — Consolidar absorbidas por ADR
Las 7 specs resueltas por un ADR implementado (0006, 0009/0010, 0004, 0007, 0013, 0003, 0005) se consolidan con una **nota de absorción** (ref: ADR) y se cierran.
**Fuente**: auditoría §5.1.
**Salida**: nota de consolidación por spec + estado cerrado.

### Fase D — Fusionar duplicadas
Las specs solapadas (013-mcp-flow→015, 009-update-lifecycle→020, 019→020, 017-mcp→020, 021-estructura→027, 000-mcp-standard→020, 002→sync-kit) consolidan su contenido/tasks en la canónica y la secundaria se archiva.
**Fuente**: auditoría §5.5.
**Salida**: destino actualizado + secundaria archivada.

### Fase E — Archivar obsoletas
Las specs que ya no aplican (grupo 000-mcp-integracion, 008-mcp-config-portable, 009-path-normalization si no indexada, 018-pensador-delegation-fix, metodologia-ssd-speckit, cambio-vision) se mueven a `specs/archived/` con nota de motivo.
**Fuente**: auditoría §5.2.
**Salida**: directorio `specs/archived/` con las specs y sus notas.

### Fase F — Resolver migraciones (numeración/agrupación)
Se decide la numeración de las specs MIGRAR (022-docker-metodologia, 022-docker-standard, 023-copilot-mcp, kit-generico, solucion-generica): se renumeran/consolidan o se archivan si no aportan. Cada decisión queda registrada.
**Fuente**: auditoría §5.4.
**Salida**: renumeraciones/archivados decididos.

### Fase G — Backlog operativo (segundo control)
`pendientes-implementacion.md` recibe todas las tareas reales y se declara como **segundo control** del flujo. Se registra TRANS-001 (VAL-XX) ya creado, y las tareas de 032/033/026/028 ya agregadas. Se verifica coherencia con `specs/*/tasks.md`.
**Salida**: backlog completo y coherente.

### Fase H — Gate automático (VAL-XX)
Se agrega `VAL-XX` en `scripts/validate-agents-skills.ps1`: compara `specs/*/` contra `00-indice.md` y `pendientes-implementacion.md` (huérfanas, estados falsos, placeholders), severidad FAIL.
**Salida**: validador con VAL-XX; fixture negativo detecta divergencia.

### Fase I — Cierre y verificación
Converge: se ejecuta el gate completo, se confirma working tree limpio, se actualiza la auditoría como "veredictos ejecutados", y se registra el punto de control.

### Fase J — Norma de flujo: futuro al backlog, nunca a specs
Actualiza los flujos de los agentes documentales (pensador, documentador, arquitecto, security-auditor, Agent-SSD) para que **cualquier requerimiento, intención o mejora "por si acaso" o "para el futuro" se canalice al `pendientes-implementacion.md` como backlog a refinar por Speckit, y NUNCA se agregue al `spec.md`** en curso ni a specs cerradas. Se edita la sección correspondiente de cada agente en `.github/agents/*.agent.md` y `.opencode/agents/*.md` (paridad) para declarar esta regla explícitamente. También se registra la norma transitiva en `pendientes-implementacion.md` y el `README.md` si corresponde.

**Fuente**: decisión del usuario (2026-11-01): "NO agregues requerimientos o intenciones a los spec con criterio de por si acaso... lo que deseamos para el futuro son backlog, que deben ser refinados por speckits. Eso no forma parte nunca de los specs."

**Salida**: agentes documentales con la regla de flujo; la norma queda como requisito FR-011 / SC-006 de la spec 035.

### Fase K — Re-evaluar gate tras la norma
Tras editar los agentes documentales en la fase J, re-ejecutar el validador (`scripts/validate-agents-skills.ps1`) para confirmar que la edición de agentes no rompió paridad (VAL-01, VAL-02, VAL-06, VAL-08) y que VAL-11 sigue detectando solo las huérfanas intencionales de D/F.

## Orden de dependencia

A → B → C → D → E → F → G → H → I → J → K

- Fases A-G solo tocan `Documentacion/Agents_IA_TECH/` (whitelist documental).
- Fase H toca `scripts/` (transversal, habilitado por VAL-01..VAL-11 ya existentes).
- Fase J toca `.github/agents/` y `.opencode/agents/` (whitelist documental transversales), con paridad entre harnesses.
- Fase K re-ejecuta el gate.
- Ninguna fase es crítica de seguridad (FAIL-closed solo en archivado fuera de allowlist).
