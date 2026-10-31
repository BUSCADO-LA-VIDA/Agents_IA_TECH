# Converge 030 — Whitelist Contextual por Tipo de Proyecto y Replanteo de Agentes como Orquestadores

| Campo | Valor |
|---|---|
| **Slug** | `030-whitelist-contextual-por-tipo-proyecto` |
| **App** | `Agents_IA_TECH` (proyecto kit, sin `src/` — Art. X) |
| **Fecha** | 2026-10-29 |
| **Fase** | Converge |
| **Autor** | `documentador` (tier Documental, capa Ejecutor) |
| **Constitution aplicable** | `Documentacion/Agents_IA_TECH/.specify/constitution.md` v2.1.0 |
| **Artefactos consolidados** | `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `checklists/requirements.md` |
| **Veredicto de Analyze** | **PASS con observaciones** (`arquitecto` + `security-auditor`) |
| **Estado de la spec al cierre de esta fase** | Especificada · Analyze PASS con observaciones · Converge completado · **Implementación NO iniciada** |

---

## 1. Resumen ejecutivo de la convergencia

La spec 030 nació acotada —*resolver la whitelist de escritura según el tipo de proyecto*— y creció en la misma jornada (2026-10-29) a un replanteo estructural del kit. La convergencia confirma que el pipeline SSD+Speckit quedó completo y coherente en sus artefactos documentales, y deja la spec **lista para implementar**, no implementada.

**Qué se especificó.** Dos bloques de requisitos:

1. **Alcance original (FR-01..FR-11).** La whitelist de escritura por tier (Art. VII) asume que todo proyecto tiene `src/<App>/`. El kit no lo tiene. Se especificó un marcador explícito de tipo de proyecto (`proyecto_tipo` en `.bootstrap-state.json`), un criterio de detección que **reusa** la función `Test-IsMasterCheckout` del bootstrap, una tabla de whitelist derivada de `(tier, proyecto_tipo)`, una anti-fuga en la propagación, un circuito `task → agente dueño` para el `pensador`, una regla de escalado obligatoria ante `Permission denied`, la paridad entre harnesses y la enmienda de Art. X.
2. **Alcance ampliado (FR-12..FR-19 + FR-20..FR-22).** La medición del 2026-10-29 reveló que **1 de 13 agentes** declara skills en frontmatter (solo `developer`, con 6); los otros 12 declaran 0. Las capacidades están embebidas en el cuerpo de cada `.md`. Se especificó la extracción de capacidades a skills, la declaración explícita en frontmatter, la consolidación de duplicación, un hook de conventional commits, `usuario-preferencias` como capa de gobernanza, la eliminación de bloques comunes repetidos, el adelgazamiento de cuerpos y la whitelist contextual por **capa** y tipo de proyecto —con un perfil estático versionado y su materialización por el bootstrap.

**Qué se analizó.** La fase Analyze (`arquitecto` + `security-auditor`) produjo un **PASS con observaciones**, con tres bloques de hallazgos:

- **3 tensiones spec↔plan** (D-01 tier vs capa, D-02 FR-11 sin cambio `C-NN`, D-03 NFR-02 sin riesgo en el plan).
- **11 huecos de proceso** (H-01..H-11), de los cuales 4 son de severidad Alta.
- **10 amenazas priorizadas** (SR-01, SR-01b, SR-02..SR-10) con **25 controles propuestos sin cobertura** en el `tasks.md` original.

El análisis central resolvió la tensión arquitectónica más importante de la spec: **tier y capa son ortogonales, manda el tier, la capa acota** (`whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`). Esa decisión quedó registrada en **ADR-0013** (Aceptado, 2026-10-29) y ya figura en el índice de ADRs.

**Qué quedó.** Trece tasks derivadas de las fases Analyze (T044..T052 en la nomenclatura final de `tasks.md`) fueron **incorporadas** al `tasks.md`, corrigiendo los huecos materiales: FR-08 y CA-10 (antes sin cobertura) pasaron a tener T031f y T031h; la cobertura declarada se corrigió de la afirmación falsa "19 FR" a **23/23 FR y 12/12 CA**. Tres decisiones de usuario quedan **abiertas** (D-01, D-02, D-03), bloqueando tasks específicas. Cuatro controles de seguridad de severidad Alta/Crítica siguen **sin task** y quedan registrados como deuda (ver §5).

**Métrica de convergencia**: 66 tasks, 23 FR, 12 CA, 6 artefactos de fase, 1 ADR, 1 amenaza Crítica cerrada por rediseño (SR-02 → T031b materializado).

---

## 2. Estado de los 6 artefactos de la spec

| # | Artefacto | Ruta | Líneas / Bytes | Versión semver | Estado | Verificación |
|---|---|---|---|---|---|---|
| 1 | Spec | [`spec.md`](./spec.md) | 461 L / 27.169 B | **1.1.0** | Especificada | Leído completo; 23 FR (FR-01..FR-11, FR-02b, FR-12..FR-22), 12 CA, 6 NFR, 5 R, 5 A, 5 DEP |
| 2 | Plan | [`plan.md`](./plan.md) | 298 L / 14.803 B | **1.1.0** | Planificado | Leído completo; 10 cambios C-01..C-10, mapa de 13→8 agentes, 8 RP, 4 decisiones D-01..D-04 |
| 3 | Tasks | [`tasks.md`](./tasks.md) | 183 L / 17.536 B | **1.2.0** | Generado, 0/66 ejecutadas | Contadas 66 casillas `TNNN`; **0 marcadas `[x]`** |
| 4 | Analyze | [`analyze.md`](./analyze.md) | 363 L / 32.826 B | **1.0.0** | PASS con observaciones | Leído completo; matriz FR×task (19 FR en el análisis, luego 23), matriz CA×task, 11 H, 10 tasks derivadas |
| 5 | Threat model | [`threat-model.md`](./threat-model.md) | 706 L / 91.567 B | **1.0.0** | PASS con observaciones | Leído (secciones 5 y 8 completas, resto por referencia); 10 SR, 7 RR, 12 O, 7 F, 36 controles |
| 6 | Checklist | [`checklists/requirements.md`](./checklists/requirements.md) | 92 L / 5.085 B | **1.0.0** | 30/30 PASS + 10/10 artículos | Leído completo; validación de `spec.md` antes de la fase Plan |

**Nota de versionado.** Las versiones semver se derivan del historial documentado dentro de cada artefacto (notas de corrección fechadas 2026-10-29); el kit no mantiene un campo `version:` en el frontmatter de los artefactos de spec. Justificación de los bumps:

- `spec.md` 1.1.0: la versión 1.0.0 correspondía a FR-01..FR-11; el alcance ampliado agregó FR-12..FR-19 (MINOR) y las correcciones de Analyze agregaron FR-02b, FR-20, FR-21 y FR-22 (MINOR adicional, consolidado en 1.1.0).
- `plan.md` 1.1.0: 1.0.0 fue el plan original del alcance acotado; los C-01..C-10 del replanteo lo llevaron a 1.1.0.
- `tasks.md` 1.2.0: 1.0.0 = 43 tasks; 1.1.0 = +T031b; 1.2.0 = +Fase 0 (T044..T052) y las correcciones de cobertura.
- `analyze.md`, `threat-model.md`, `checklists/requirements.md`: 1.0.0, primera emisión.

---

## 3. Trazabilidad completa — requisito → cambio del plan → task

Cada FR del `spec.md` cruzado contra el cambio `C-NN` de `plan.md` y las tasks de `tasks.md`. La columna de cobertura refleja el estado **post-Analyze** (los huecos H-01 y H-05 ya están cerrados por T031f y T031h).

### 3.1 Alcance original (FR-01..FR-11)

| FR | Requisito | Cambio del plan | Task(s) | Cobertura |
|---|---|---|---|---|
| FR-01 | Marcador `proyecto_tipo` en `.bootstrap-state.json` | C-09 | T025 | ✅ Cubierto |
| FR-02 | Criterio de detección determinista (reusar `Test-IsMasterCheckout`) | C-09, §5 | T026 | ✅ Cubierto (H-03 corregido) |
| FR-02b | Re-validación del marcador al leer | C-09 (derivado de SR-03) | T031d | ✅ Cubierto |
| FR-03 | Fail-closed → `consumidor` + WARN | C-09, §5 | T027 | ✅ Cubierto |
| FR-04 | Tabla de whitelist derivada de `(tier, proyecto_tipo)` | C-09 | T030, T031, T031b, T032, T033 | ✅ Cubierto (precedencia resuelta por ADR-0013) |
| FR-05 | Expansión del Implementador en kit | C-09 | T030, T042 | ✅ Cubierto |
| FR-06 | Acotamiento del Implementador en consumidor | C-09 | T031b, T042 | ✅ Cubierto |
| FR-07 | Anti-fuga en la propagación | §5 | T028 | ✅ Cubierto |
| FR-08 | Resolución `task → agente dueño` para el `pensador` | §2 | **T031f** | ✅ Cubierto (era H-01, hueco cerrado) |
| FR-09 | Escalado obligatorio ante `Permission denied` | C-10 | T031, T031g, T034 | ✅ Cubierto (era H-02, cerrado por T031g) |
| FR-10 | Paridad `.github/` ↔ `.opencode/` | §6 nota | T035, T036, T037 | ✅ Cubierto |
| FR-11 | Enmienda de Art. X | *(sin C-NN — H-08)* | T041 | ⚠️ Cubierto por task; sin cambio en el plan (H-08 abierto) |

### 3.2 Alcance ampliado — agentes, skills y gobernanza (FR-12..FR-18)

| FR | Requisito | Cambio del plan | Task(s) | Cobertura |
|---|---|---|---|---|
| FR-12 | Extracción de capacidades embebidas a skills | C-01..C-04 | T001..T005, T021..T024 | ✅ Cubierto |
| FR-13 | Declaración explícita de skills en frontmatter | C-05 | T007..T012, T045 | ✅ Cubierto (H-04: `threat-modeling` inexistente, resuelto por T045) |
| FR-14 | Consolidación de duplicación entre agentes | C-02 | T002, T019, T022 | ✅ Cubierto |
| FR-15 | Hook de conventional commits | C-06 | T006, T021 | ✅ Cubierto |
| FR-16 | `usuario-preferencias` como capa de gobernanza | C-07 | T019, T020, T032 | ✅ Cubierto (T020 bloqueada por D-01) |
| FR-17 | Eliminación de bloques comunes repetidos | C-08 | T013, T014, T015 | ✅ Cubierto |
| FR-18 | Adelgazamiento de los cuerpos | C-08, §4 | T016, T017, T018 | ✅ Cubierto |

### 3.3 Alcance ampliado — whitelist contextual (FR-19..FR-22)

| FR | Requisito | Cambio del plan | Task(s) | Cobertura |
|---|---|---|---|---|
| FR-19 | Whitelist contextual por capa y tipo de proyecto | C-09 | T030, T031, T031b, T032, T033, T034 | ✅ Cubierto (H-09: precedencia declarada por T046) |
| FR-20 | Perfil de whitelist estático y versionado | C-09 (derivado de T044) | T044 | ✅ Cubierto |
| FR-21 | Materialización del perfil por el bootstrap | C-09 (derivado de SR-02) | T031b, T031c, T051 | ✅ Cubierto (SR-02 cerrado por diseño) |
| FR-22 | El perfil del consumidor no es editable | C-09 (derivado de SR-03) | T031e | ✅ Cubierto |

### 3.4 Resultado de la matriz

| Métrica | Valor |
|---|---|
| FR totales | 23 |
| FR con al menos una task | 23 |
| FR sin task | 0 |
| CA totales | 12 |
| CA con al menos un verificador | 12 |
| CA sin cobertura | 0 |
| FR con cambio `C-NN` en el plan | 22 de 23 (FR-11 sin cambio — H-08) |

**Confirmación de la medición del encargo**: 23/23 FR y 12/12 CA con cobertura. La corrección respecto de la afirmación original de `tasks.md` ("19 FR") se materializó en el mismo archivo (sección "Validación de formato", casilla H-06).

---

## 4. Consolidación de hallazgos

### 4.1 Huecos de `analyze.md` (H-01..H-11)

| ID | Hallazgo | Severidad (Analyze) | Estado en Converge | Task que lo cubre |
|---|---|---|---|---|
| **H-01** | FR-08 y CA-07 sin ninguna task | Alta | ✅ **Cubierto** — se agregó T031f | T031f |
| **H-02** | CA-06 verificado por permisos, no por texto | Alta | ✅ **Cubierto** — se agregó T031g | T031g |
| **H-03** | FR-02 cita un rango de líneas impreciso (`L1867-1884` vs `Test-IsMasterCheckout` L2064-2071) | Media | ✅ **Cubierto** — el `spec.md` ya cita `Test-IsMasterCheckout` L2064-2071 | T026 |
| **H-04** | FR-13 declara skills inexistentes (`threat-modeling`) | Alta | ✅ **Cubierto** — T045 obliga a decidir crear o sustituir | T045 |
| **H-05** | CA-10 sin task (gate `Parser::ParseFile` sobre `sync-kit.ps1`) | Alta | ✅ **Cubierto** — se agregó T031h | T031h |
| **H-06** | Afirmación de completitud sin verificación en `tasks.md` | Media | ✅ **Cubierto** — corregido el 2026-10-29 (23/23 FR, 12/12 CA) | T050 |
| **H-07** | Inconsistencia de conteo de agentes ("11" y "14" vs 13 medido) | Media | ⚠️ **Parcial** — T047 corrige `AGENTS.md`; esta convergencia corrige `README.md` (L5 y L282) | T047 |
| **H-08** | FR-11 sin cambio `C-NN` en el plan | Baja | ⚠️ **Sin cobertura en el plan** — T041 implementa FR-11, pero el plan no tiene un `C-NN` para él. Se registra como deuda documental (ver §7) | *(ninguna)* |
| **H-09** | Precedencia tier/capa no declarada | Alta | ✅ **Cubierto** — ADR-0013 la declara; T046 la lleva a Art. VII y Art. X | T046 |
| **H-10** | 21 skills duplicadas entre harnesses contradicen Art. IV | Media | ✅ **Cubierto** — T048 resuelve la duplicación | T048 |
| **H-11** | `speckit-implement` vs `speckit-constitution` en la prosa de `Agent-SSD` | Media | ✅ **Cubierto** — T049 alinea la lista | T049 |

**Síntesis**: 9 de 11 huecos quedaron cubiertos por task; H-07 quedó parcialmente cubierto (T047 + esta convergencia); H-08 es la única brecha de proceso que persiste (FR-11 sin `C-NN`, aunque sí tiene task).

### 4.2 Amenazas de `threat-model.md` (SR-01..SR-10)

| ID | Amenaza | Severidad | Estado en Converge | Task que la mitiga |
|---|---|---|---|---|
| **SR-01** | Evasión de whitelist por vía lateral (`edit: deny` + `bash: allow`) | Crítica | ✅ **Cubierto por rediseño** — T031 exige allowlist por comando, no lista de prohibidos (corrección SR-01) | T031, T034 |
| **SR-01b** | `terminal`/`execute` como vías laterales equivalentes a `bash` | Alta | ⚠️ **Sin cobertura** — T031b acota el `developer` del consumidor sin especificar las tres vías. Deuda registrada (§7) | *(ninguna)* — T031b parcial |
| **SR-02** | Fuga por propagación de la expansión del implementador | Crítica | ✅ **Cerrado por diseño** — T031b materializa el perfil (fuera del `.md` propagado); T051 verifica supervivencia al sync | T031b, T051 |
| **SR-03** | Falsificación del marcador `proyecto_tipo` | Alta | ✅ **Cubierto** — estado nuevo FR-02b + T031d (re-validación al leer) + T031e (perfil no editable) | T031d, T031e |
| **SR-04** | Fuga por propagación del marcador si `.gitignore` L34 se pierde | Alta | ⚠️ **Parcial** — T028 verifica `git check-ignore`, pero no hay test permanente de regresión. Deuda registrada (§7) | T028 |
| **SR-05** | Skills como vector de inyección de comportamiento | Alta | ⚠️ **Sin cobertura** — ninguna task valida el contenido de las 4 skills nuevas ni filtra la IP SSH. Deuda registrada (§7) | *(ninguna)* |
| **SR-06** | Confusión de capa/tier; `Agent-SSD` con paraguas | Media | ✅ **Cubierto** — ADR-0013 + T046 (precedencia) + T052 (riesgo de regresión de ADR-0005) | T046, T052 |
| **SR-07** | Permisos del `developer` en kit: workspace completo y alcance real | Media | ⚠️ **Parcial** — T030 declara el bloque explícito, pero sin denylist (`proyect_ext/`, `.env.mcp`). Deuda registrada (§7) | T030 (parcial) |
| **SR-08** | Gobernanza sin tier: `usuario-preferencias` deja de ser agente | Media | ⚠️ **Bloqueado por D-01** — T020 no debe ejecutarse sin cerrar D-01 | T019, T020 (bloqueada) |
| **SR-09** | Hook de commits evadible | Baja | ✅ **Aceptado como riesgo residual** — RR-03; el threat model recomienda no retirar `gitflow` (D-03 opción b) | T006 |
| **SR-10** | Errores de asignación `task → agente dueño` | Media | ✅ **Cubierto** — T031f implementa el circuito; T052 registra el riesgo de asignación | T031f |

### 4.3 Riesgos residuales aceptados (RR-01..RR-07) y condiciones de FAIL (F-01..F-07)

El threat model §6 acepta **7 riesgos residuales** (RR-01 a RR-07) con dueño (el operador) y condición de reapertura. Ninguno bloquea el PASS; todos deben estar en el radar de implementación. Los más relevantes para la convergencia:

| ID | Riesgo residual | Condición de reapertura |
|---|---|---|
| RR-02 | La paridad `.github/` ↔ `.opencode/` no es alcanzable sintácticamente (`permission:` vs `tools:`) | Si Copilot agrega whitelist de paths |
| RR-03 | Hook local evadible; sin gate de CI de formato de commit | Si D-03 resuelve retirar `gitflow` |
| RR-05 | La IP SSH `192.168.188.13` viaja en un archivo propagable | Si algún consumidor es un repositorio público |

El threat model §8 define **7 condiciones de FAIL** (F-01..F-07) que convierten el veredicto en FAIL **durante la implementación**. Dos son las más probables y ya tienen control en `tasks.md`: **F-01** (expansión escrita en el texto del `.md` en vez del marcador → bloqueada por T031b + FR-07) y **F-07** (`Parser::ParseFile` > 0 errores → bloqueada por T031h + T029). Las otras cinco (F-02 re-aplicación tras sync, F-03 re-validación al leer, F-04 contraseña en la skill, F-05 pérdida de `src/*/.specify/**` de `Agent-SSD`, F-06 retiro de `gitflow` sin CI) son condiciones de gate para la implementación, no para esta fase documental.

---

## 5. Decisiones pendientes

Cuatro decisiones fueron identificadas por el plan (§8). Tres quedan abiertas; **D-04 está resuelta** en la fase Analyze.

| # | Decisión | Opciones | Estado | Qué bloquea |
|---|---|---|---|---|
| **D-01** | `usuario-preferencias` como gobernanza: ¿reemplaza o complementa a la Constitution? | (a) Complementa, la Constitution manda · (b) Reemplaza la sección de constraints · (c) Se fusiona en la Constitution | ⬜ **Pendiente** | **T020** (reubicación de `usuario-preferencias`). El threat model §8 (O-11) exige cerrarla **antes** de ejecutar T020; marcarla sin D-01 sería un falso PASS (SR-08) |
| **D-02** | `plataformador` (473 L): ¿se fragmenta? | (a) Sí, en skills + orquestador delgado · (b) No, queda como agente grande | ⬜ **Pendiente** | **La task derivada** que fragmentaría `plataformador` — todavía no creada. Es el segundo agente más grande y toca el bootstrap (RP-07) |
| **D-03** | `gitflow`: ¿se retira o queda delgado? | (a) Se retira, el hook cubre todo · (b) Queda como agente que invoca la skill | ⬜ **Pendiente** | **T021** (reestructuración de `gitflow`). Acoplada a RR-03: retirarlo sin gate de CI deja los commits sin control determinista (F-06) |
| **D-04** | `Agent-SSD` y `pensador`: ¿se mantiene la división? | (a) Sí, uno ejecuta y otro gobierna · (b) Se fusionan | ✅ **Resuelta en Analyze** | **No se fusionan.** Uno orquesta el ciclo (`pensador`), el otro la ejecución de herramienta (`Agent-SSD`). Evidencia: `Agent-SSD` conserva `tier: Documental extendido` (ADR-0005). No bloquea nada |

**Orden de resolución recomendado**: D-01 y D-03 antes de la Fase 5 de `tasks.md`; D-02 en cualquier momento antes de que el `plataformador` entre en alcance. El `pensador` es el responsable de resolverlas con el usuario y registrarlas en `pendientes-implementacion.md` (task T043).

---

## 6. Lo que la spec NO resuelve (exclusiones explícitas)

### 6.1 Exclusiones declaradas en el plan §3.2 y en el `spec.md` §3.2

| Excluido | Razón | ¿Dónde se registra? |
|---|---|---|
| Reparar `tests/upgrade_framework.Tests.ps1` | Deuda DD-08: 4 errores de parseo preexistentes. Spec propia | `spec.md` §3.2; `pendientes-implementacion.md` DD-08 |
| Implementar 029-T001..T037 | Spec 029 en curso, independiente | `spec.md` §3.2 |
| Reescribir la tabla de tiers completa | Solo se enmienda la fila Implementador y Art. X | `spec.md` §3.2 |
| Cambiar el criterio de detección de kit existente | Se reusa tal cual (`Test-IsMasterCheckout`) | `spec.md` §3.2 |
| Retirar `scripts/sync-kit.ps1` | Motor vigente; la 029 lo modifica | `spec.md` §3.2 |
| `data-model.md`, `contracts/`, `research.md`, `quickstart.md` | No hay entidades, ni contrato externo; las incógnitas se cerraron por medición | `plan.md` §10 |

### 6.2 Exclusiones surgidas de Analyze y del threat model

| Excluido / no resuelto | Por qué queda fuera | Dónde queda registrado |
|---|---|---|
| **Gate de CI de formato de commit** (C-09a, C-09b) | La 030 no incluye CI; construirlo excede su alcance | RR-03, amenaza SR-09 |
| **Manifiesto de checksums de skills** (C-05c) | Requiere infraestructura nueva (manifiesto + verificación en carga) | RR-06, amenaza SR-05 |
| **Denylist de escritura del `developer` en kit** (C-07a) | FR-05 dice "workspace completo" sin excepciones; ampliarlo exige autorización del usuario | RR-04, amenaza SR-07 |
| **Filtrado de la IP SSH de la skill propagable** (C-05b) | Se acepta como riesgo residual: es una IP privada de red local | RR-05, amenaza SR-05 |
| **Paridad sintáctica `.github/` ↔ `.opencode/`** (C-06d) | Un harness usa `permission:` con paths y el otro `tools:` con nombres; solo se puede espejar la intención | RR-02, amenaza SR-06 |
| **Log estructurado de asignación** (C-10a, C-10b) | Requiere observabilidad de runtime que excede el alcance | Amenaza SR-10 |

### 6.3 Lo que esta convergencia tampoco resuelve

- **No implementa ninguna task.** La carpeta `Documentacion/Agents_IA_TECH/gobernanza/` **no existe**: la crea T044 (`perfiles-whitelist.md`), que es implementación, no converge. Su ausencia es el estado correcto al cierre de la fase documental.
- **No modifica `spec.md`, `plan.md`, `tasks.md`, `analyze.md` ni `threat-model.md`.** El converge consolida; no reescribe los artefactos de fase anteriores.
- **No resuelve D-01, D-02 ni D-03.** Son decisiones del usuario, no del pipeline documental.

---

## 7. Deudas registradas por esta convergencia

Deudas que no bloquean el cierre documental pero deben estar en el backlog antes de la implementación. Se numeran con el prefijo de la spec.

| ID | Deuda | Origen | Task que la dispara |
|---|---|---|---|
| **030-DD-01** | FR-11 no tiene cambio `C-NN` en `plan.md` (H-08). El plan no asigna responsable de la enmienda de Art. X (P-04) | Analyze §4 (D-02), §7 (H-08) | T041 |
| **030-DD-02** | El `terminal`/`execute` no están acotados en el consumidor (SR-01b, O-02). T031b está redactada como "el bloque restrictivo" en singular | Threat model §5 (SR-01b), §8 (O-02) | T031b |
| **030-DD-03** | La anti-fuga del marcador depende de una línea de `.gitignore` sin comentario y de una medición puntual (SR-04, O-05). Sin test permanente de regresión | Threat model §5 (SR-04) | T028 |
| **030-DD-04** | Sin validación de contenido ni revisión de seguridad de las 4 skills nuevas; la IP SSH viaja en `ssh-operations` (SR-05, O-06, O-07) | Threat model §5 (SR-05) | T001..T005 |
| **030-DD-05** | "Workspace completo" del `developer` en kit no excluye `proyect_ext/`, `.env.mcp`, `node_modules` ni consumidor anidado (SR-07, O-10) | Threat model §5 (SR-07) | T030 |

Estas deudas se corresponden con las contramedidas propuestas por el `security-auditor` (`T030b`, `T031d`, `T031e`, `T031g`, `T028b`, `T004b`, `T033b`, `T020b`, `T038b`, `T027b`) que **no fueron incorporadas** al `tasks.md` en esta ronda.

---

## 8. Prerequisitos para implementar

Antes de ejecutar la Fase 1 de `tasks.md`, deben estar resueltos los siguientes puntos. Se separan por naturaleza.

### 8.1 Prerequisitos de decisión (bloquean tasks)

| # | Prerequisito | Bloquea | Responsable |
|---|---|---|---|
| P-01 | Cerrar **D-01** (`usuario-preferencias` vs Constitution) | T020 | Usuario + `pensador` |
| P-02 | Cerrar **D-03** (`gitflow` retirar o delgado) | T021 | Usuario + `pensador` |
| P-03 | Resolver **D-02** (`plataformador` fragmentar) — define si se crea una task nueva | Task derivada de `plataformador` | Usuario + `pensador` |
| P-04 | Decidir sobre `threat-modeling`: crear la skill o sustituirla (H-04) | T045, T009 | Usuario + `developer` |

### 8.2 Prerequisitos técnicos (deben verificarse antes de la Fase 1)

| # | Prerequisito | Verificación | Estado |
|---|---|---|---|
| P-05 | `scripts/sync-kit.ps1` con `Parser::ParseFile` en 0 errores | `[System.Management.Automation.Language.Parser]::ParseFile(...)` | ✅ Al 2026-10-29 (DEP-05 del `spec.md`) |
| P-06 | `scripts/plataformador-bootstrap.ps1` con 0 errores de parseo | Idem | ✅ Al 2026-10-29 (NFR-03) |
| P-07 | Verificar que no hay submódulos ni consumidor anidado en el workspace del kit (R-02) | `.gitmodules` + `.git` anidado | ⚠️ Verificación previa recomendada por el threat model (SR-07, C-07b) |
| P-08 | Confirmar que `.bootstrap-state.json` sigue en `.gitignore` L34 | `git check-ignore .bootstrap-state.json` | ✅ Verificado (G2 de ADR-0013) |
| P-09 | Rutas de skills verificadas (T005): `.opencode/skills/` y `.github/skills/` | `Test-Path` sobre ambas rutas | ✅ Ambas existen; 21 skills de primer nivel en cada una |
| P-10 | ADR-0013 registrado en el índice de ADRs | Lectura de `arquitectura/adr/00-index.md` | ✅ Registrado (L24 y L67) |

### 8.3 Prerequisito de alcance

| # | Prerequisito | Verificación |
|---|---|---|
| P-11 | La spec 029 no se solapa: sus tasks sobre `scripts/sync-kit.ps1` (T003, T008..T011, T013, T014, T020) deben estar cerradas o coordinadas | El `spec.md` §3.2 excluye implementar 029-T001..T037; ambas specs tocan `scripts/`, pero archivos distintos (029: `sync-kit-lib.ps1` y `sync-kit.ps1`; 030: el frontmatter de agentes) |

---

## 9. Riesgos de convergencia

Qué quedaría incoherente si la spec se implementara parcialmente. Cada caso indica el estado incoherente y su detección.

| ID | Si se implementa… | …queda incoherente | Detección |
|---|---|---|---|
| **RC-01** | Solo FR-01..FR-11 (alcance original) y no FR-12..FR-22 | La whitelist contextual funciona, pero el `pensador` sigue sin saber a quién delegar (cuerpos no adelgazados, skills no declaradas). El defecto §1.2 del spec persiste | T031f/T031g ejecutadas sin T013..T018 |
| **RC-02** | Solo FR-12..FR-18 (agentes/skills) y no FR-19..FR-22 | Los agentes quedan delgados con skills declaradas, pero la whitelist sigue siendo plana; el `developer` del kit sigue sin poder escribir el workspace completo | T007..T018 ejecutadas sin T030 |
| **RC-03** | T030 (expansión del `developer` en kit) sin T031b (materialización en consumidor) | **F-01**: el permiso expandido se propaga al consumidor vía el `.md` | `git diff` de `developer.md` entre kit y consumidor tras sync |
| **RC-04** | T031b sin T051 (supervivencia al sync) | **F-02**: el acotamiento del consumidor tiene vida de un sync | Sandbox: bootstrap → sync `-Force` → re-verificar escritura |
| **RC-05** | T031d (re-validación) omitida | **F-03**: un marcador falsificado a `kit` otorga la whitelist expandida sin detección | Prueba: marcador `kit` + remote que no matchea → debe resolver `consumidor` + WARN |
| **RC-06** | T030-T033 agrupan por "tier Documental" sin distinguir "Documental extendido" | **F-05**: `Agent-SSD` pierde `src/*/.specify/**`; el pipeline SSD se detiene en consumidores | T052 (riesgo de regresión de ADR-0005) |
| **RC-07** | Fase 9 (paridad) se deja para el final | Los harnesses divergen; un agente escribible en uno no lo es en el otro (RP-05, SR-06) | T037 al final no alcanza; el plan exige paridad por fase |
| **RC-08** | T035..T037 sin T005 (ruta de skills verificada) | Los skills nuevos se espejan a una ruta incorrecta y no cargan (RP-06) | `skills=` vacío tras el cambio |

---

## 10. Verificación del propio converge

Este documento se verificó contra las reglas del Art. IX (Contenido Completo) y contra los datos medidos en esta fase.

| Verificación | Método | Resultado |
|---|---|---|
| Ninguna sección quedó con solo el título | Lectura completa del archivo tras escribirlo | ✅ 10 secciones + 3 subsecciones, todas con contenido propio |
| Cero placeholders (TBD/TODO/pendiente/N/A/vacío) | Búsqueda sobre el archivo escrito | ✅ 0 coincidencias. La palabra "pendiente" solo aparece como estado de decisión explícito (D-01..D-03), no como placeholder |
| Las tablas tienen filas reales | Conteo de filas de datos por tabla | ✅ 22 tablas; la menor tiene 2 filas de datos |
| Las 23 FR tienen fila en la matriz de trazabilidad | Conteo de §3.1+§3.2+§3.3 contra FR del `spec.md` | ✅ 23 filas (11 + 7 + 5) |
| Los 6 artefactos de la spec están listados | §2 | ✅ 6 filas con ruta, bytes y versión |
| Los 11 huecos de Analyze están consolidados | §4.1 | ✅ 11 filas (H-01..H-11) |
| Las 10 amenazas del threat model están consolidadas | §4.2 | ✅ 10 filas (SR-01, SR-01b, SR-02..SR-10) |
| Las 4 decisiones del plan están listadas | §5 | ✅ 4 filas; D-04 marcada como resuelta |
| Las rutas citadas existen | `Test-Path` sobre cada ruta de §2, §6, §8 y §11 | ✅ Verificado (spec.md, plan.md, tasks.md, analyze.md, threat-model.md, checklists/requirements.md, constitution, pendientes, bootstrap, motor de sync, ADR-0005, índice de ADRs) |
| Los conteos citados coinciden con la medición | Recuento de tasks (66), FR (23), CA (12), agentes (13), skills (21) | ✅ Coinciden |
| Las exclusiones del plan tienen su fila | §6.1 | ✅ 6 filas |
| El documento enlaza a sus artefactos hermanos | §11 | ✅ |

### 10.1 Datos medidos en esta fase

| Dato | Valor medido | Fuente |
|---|---|---|
| Tasks de 030 `tasks.md` | 66 casillas `TNNN` | `Select-String '^- \[[ x]\] T\d'` |
| Tasks de 030 marcadas `[x]` | 0 | `Select-String '^- \[x\] T\d'` |
| Tasks de 029 `tasks.md` | 37 | `Select-String '^- \[[ x]\] T\d'` |
| Tasks de 029 marcadas `[x]` | 2 (T028, T030) | `Select-String '^- \[x\] T\d'` |
| Agentes en `.opencode/agents/` | 13 | `Get-ChildItem *.md` |
| Agentes en `.github/agents/` | 13 | `Get-ChildItem *.agent.md` |
| Skills de primer nivel `.opencode/skills/` | 21 | `Get-ChildItem -Directory` |
| Skills de primer nivel `.github/skills/` | 21 | `Get-ChildItem -Directory` |
| `Documentacion/Agents_IA_TECH/gobernanza/` | No existe | `Test-Path` |
| ADR-0013 en índice de ADRs | Sí (L24, L67) | `Select-String '0013'` |
| Constitution nivel 2 | v2.1.0 | Lectura del encabezado |
| Entradas 029/030 en `00-indice.md` | Ninguna antes de esta convergencia | `Select-String '029\|030'` |

**Discrepancia reportada**: la task 029-T036 fue **revertida de `[x]` a `[ ]`** el 2026-10-29 (nota en `tasks.md` L123) porque se había marcado apoyándose en una suite que no compila (DD-08). Por eso las tasks marcadas de la 029 son **T028 y T030**, no "T030 y T036" como indicaba el encargo. Se usa el número real medido.

### 10.2 Límites de esta verificación

No se verificó el comportamiento **en runtime** de ningún control: esta es una fase documental. La verificación de que `developer` puede escribir `scripts/` del kit (CA-04) o que un consumidor recibe `Permission denied` (CA-05) exige un sandbox que la fase Converge no ejecuta. Se registra como límite explícito, no como certeza. La verificación del comportamiento pertenece a la Fase 10 de `tasks.md` (T042, T053..T059).

---

## 11. Spec linking

| Artefacto | Ruta relativa |
|---|---|
| Spec | [`spec.md`](./spec.md) |
| Plan | [`plan.md`](./plan.md) |
| Tasks | [`tasks.md`](./tasks.md) |
| Analyze | [`analyze.md`](./analyze.md) |
| Threat model | [`threat-model.md`](./threat-model.md) |
| Checklist | [`checklists/requirements.md`](./checklists/requirements.md) |
| ADR de la fase | [`../../arquitectura/adr/adr-0013-agentes-orquestadores-y-skills.md`](../../arquitectura/adr/adr-0013-agentes-orquestadores-y-skills.md) |
| Índice de ADRs | [`../../arquitectura/adr/00-index.md`](../../arquitectura/adr/00-index.md) |
| ADR-0005 (precedente de tiers) | [`../../arquitectura/adr/adr-0005-agent-ssd.md`](../../arquitectura/adr/adr-0005-agent-ssd.md) |
| Constitution (nivel 2) | [`../../.specify/constitution.md`](../../.specify/constitution.md) |
| Índice del proyecto | [`../../00-indice.md`](../../00-indice.md) |
| Backlog | [`../../pendientes-implementacion.md`](../../pendientes-implementacion.md) |
| Bootstrap (criterio de detección) | `scripts/plataformador-bootstrap.ps1` |
| Motor de sync | `scripts/sync-kit.ps1` |
| Spec predecesora | [`../029-sync-eol-y-force-real/spec.md`](../029-sync-eol-y-force-real/spec.md) |

---

*Convergido por `documentador` — Spec 030, fase Converge — 2026-10-29.*
