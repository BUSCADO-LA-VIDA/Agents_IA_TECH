# Checklist de Requisitos — Spec 030

> Validación de calidad de `spec.md` antes de pasar a la fase Plan.
> Fecha: 2026-10-29 · Autor: `pensador`

## Estructura del documento

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 1 | El documento tiene las 11 secciones del template | ✅ PASS | Problema, Objetivo, Alcance, FR, NFR, CA, Supuestos, Dependencias, Riesgos, Trazabilidad, Spec linking |
| 2 | Ninguna sección quedó con solo el título | ✅ PASS | Verificado por lectura completa; todas tienen contenido propio |
| 3 | Cero placeholders (TBD/TODO/pendiente/N/A) | ✅ PASS | Búsqueda sobre el archivo: 0 coincidencias |
| 4 | Las tablas tienen filas reales | ✅ PASS | 9 tablas; la menor tiene 3 filas de datos |
| 5 | Los IDs son únicos y secuenciales | ✅ PASS | FR-01..FR-11, NFR-01..NFR-06, CA-01..CA-12, R-01..R-05 |

## Calidad de los requisitos funcionales

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 6 | Cada FR tiene verbo normativo (MUST/MUST NOT) | ✅ PASS | Los 11 FR lo declaran explícitamente |
| 7 | Cada FR tiene fundamento, no solo enunciado | ✅ PASS | FR-01, FR-03, FR-05, FR-06, FR-07, FR-09, FR-11 incluyen su razón |
| 8 | Los FR prohibidos listan alternativas vedadas | ✅ PASS | FR-02 (prohibido inventar criterio), FR-07 (3 formas prohibidas), FR-09 (prohibido reintentar) |
| 9 | No hay FR que dependa de criterio del agente | ✅ PASS | NFR-01 lo prohíbe; FR-04 lo resuelve por tabla |
| 10 | Cada FR es verificable | ✅ PASS | Cada uno mapea a un CA en la sección 6 |

## Cobertura de los tres fallos observados

| # | Fallo | FR que lo cubre | Resultado |
|---|---|---|:---:|
| 11 | F-01 · Evasión del límite por shell | FR-09 | ✅ PASS |
| 12 | F-02 · Asignación al agente equivocado | FR-04 + FR-08 | ✅ PASS |
| 13 | F-03 · Sin circuito de resolución | FR-08 | ✅ PASS |
| 14 | F-04 · Denegación sin escalado | FR-09 | ✅ PASS |
| 15 | F-05 · Asimetría entre harnesses | FR-10 | ✅ PASS |
| 16 | Fuga kit → consumidor | FR-06 + FR-07 | ✅ PASS |

## Criterios de aceptación

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 17 | Cada CA tiene método de verificación concreto | ✅ PASS | Los 12 CA nombran el método (lectura, ejecución real, ParseFile, diff, sandbox) |
| 18 | Al menos un CA por FR | ✅ PASS | FR-01→CA-01/02/03, FR-04→CA-04/05, FR-05→CA-04, FR-06→CA-05, FR-07→CA-03, FR-08→CA-07, FR-09→CA-06, FR-10→CA-09, FR-11→CA-08 |
| 19 | Los CA son medibles sin ambigüedad | ✅ PASS | Cada uno describe una observación binaria |
| 20 | Hay CA del caso negativo (prohibición) | ✅ PASS | CA-03 (no fuga), CA-05 (denegación en consumidor), CA-12 (fail-closed) |

## Alcance y límites

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 21 | Hay sección de fuera-de-alcance explícita | ✅ PASS | Sección 3.2 con 5 exclusiones y su razón |
| 22 | No invade la spec 029 en curso | ✅ PASS | 3.2 excluye implementar 029-T001..T037 |
| 23 | No invade la deuda DD-08 | ✅ PASS | 3.2 excluye reparar la suite de tests |
| 24 | Reusa lo existente en vez de reinventar | ✅ PASS | FR-02 reusa L1867-1884; FR-01 reusa `.bootstrap-state.json` |

## Supuestos y riesgos

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 25 | Cada supuesto declara qué pasa si es falso | ✅ PASS | A-01..A-04 con columna "Si resulta falso" |
| 26 | Cada riesgo tiene mitigación | ✅ PASS | R-01..R-05, todos con mitigación asignada |
| 27 | Los riesgos incluyen el caso del defecto silencioso | ✅ PASS | R-04 (el defecto persiste sin síntomas) |

## Trazabilidad

| # | Item | Resultado | Evidencia |
|---|---|:---:|---|
| 28 | Cada FR traza a un origen verificable | ✅ PASS | Sección 10 con evidencia por FR |
| 29 | Los orígenes son mediciones, no suposiciones | ✅ PASS | Cada uno cita archivo con línea o evento observado |
| 30 | El documento enlaza a sus artefactos hermanos | ✅ PASS | Sección 11 |

## Constitution Check (previo a la fase Plan)

| # | Artículo | Cumplimiento |
|---|---|:---:|
| I | Modular Agent Design | ✅ La spec no crea agentes nuevos |
| II | Orchestrator Pattern | ✅ FR-08 refuerza el rol del `pensador` |
| III | Specification-Driven Development | ✅ Esta spec ES el artefacto de la fase |
| IV | Copilot/Opencode Compatibility | ✅ FR-10 lo hace requisito explícito |
| V | Observability | ✅ NFR-05 + FR-03 (WARN visible) |
| VI | proyect_ext | N/A — la spec no toca dependencias externas |
| VII | Restricción de Paths por Tier | ✅ FR-04/05/06 la hacen contextual |
| VIII | Fail-Open | ✅ NFR-04 fail-closed en detección; la política no bloquea el sync |
| IX | Contenido Completo | ✅ 0 placeholders verificado |
| X | Estructura kit sin `src/` | ✅ FR-11 lo completa |

---

**Resultado global: 30/30 PASS + 10/10 artículos cumplidos.**

**Veredicto: la spec está lista para la fase Plan.**

**Punto que Plan debe resolver**: FR-07 admite dos formas de cumplirse (no propagar el marcador, o fijarlo a `consumidor` en destino). Plan debe elegir una y justificarla.
