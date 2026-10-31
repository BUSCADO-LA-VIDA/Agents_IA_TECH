# Analyze 030 — Whitelist de Escritura Contextual por Tipo de Proyecto y Replanteo de Agentes como Orquestadores

| Campo | Valor |
|---|---|
| **Slug** | `030-whitelist-contextual-por-tipo-proyecto` |
| **App** | `Agents_IA_TECH` (proyecto kit, sin `src/` — Art. X) |
| **Fecha** | 2026-10-29 |
| **Fase** | Analyze |
| **Autor** | `arquitecto` (tier Documental) |
| **Constitution aplicable** | `Documentacion/Agents_IA_TECH/.specify/constitution.md` v2.1.0 |
| **Artefactos analizados** | `spec.md` (22.419 B / 407 L), `plan.md` (14.803 B / 298 L), `tasks.md` (12.358 B / 154 L) |
| **Veredicto** | **PASS con observaciones** |

---

## 1. Resumen ejecutivo

La spec 030 nació con un alcance acotado —*resolver la whitelist de escritura según el tipo de proyecto*— y creció en la misma jornada a un replanteo estructural del kit: *los agentes deben ser orquestadores delgados y sus capacidades de procedimiento deben vivir en skills*. El `spec.md` documenta ese crecimiento como "alcance ampliado" (FR-12..FR-19), el `plan.md` lo convierte en 10 cambios (C-01..C-10) y el `tasks.md` lo despliega en 43 tasks más una tarea `T031b`.

El análisis encuentra que **el diseño es coherente en su dirección** (spec↔plan↔tasks se trazan sin contradicciones duras), pero presenta **dos huecos de cobertura materiales** y **una tensión arquitectónica no resuelta** que es el hallazgo central de esta fase:

1. **FR-13 apunta a skills que el frontmatter declararía pero que en tres casos no existen**: `threat-modeling` (referenciada para `security-auditor`) no existe en el repositorio; `speckit-implement` (referenciada para `Agent-SSD` y `pensador`) existe como skill pero no coincide con la lista en prosa del propio agente. Declarar una skill inexistente deja al agente sin la capacidad, sin error visible al analizar el `.md` (RP-06 del plan queda subestimado).

2. **La spec describe la whitelist por `(tier, proyecto_tipo)` en FR-04 y por `(capa, proyecto_tipo)` en FR-19**, y `tasks.md` asigna por **capa**. Conviven dos taxonomías para el mismo concepto sin una regla de precedencia escrita. Esta es la tensión que el `arquitecto` debe resolver, y lo hace en la sección 6 de este documento y en ADR-0013.

3. **La detección de kit descrita por FR-02 cita `L1867-1884` del bootstrap**, pero la medición ubica dos bloques candidatos: `L1871` (inside `Update-Self`) y `Test-IsMasterCheckout` en `L2065-2071`. El rango citado es **aproximadamente correcto pero no exacto**; la función reutilizable es `Test-IsMasterCheckout`, no el bloque de `Update-Self`. Reusar el bloque equivocado introduciría una dependencia del self-update en un cálculo de tipo de proyecto.

**La dirección del diseño es aceptable** (PASS con observaciones) porque ninguno de los tres hallazgos invalida la arquitectura propuesta; los tres son corregibles dentro del mismo ciclo sin reabrir el Specify. Pero **no puede marcarse PASS pleno** mientras FR-13 declare una skill inexistente y FR-04/FR-19 no tengan precedencia declarada: cualquiera de los dos, sin corregir, produce una implementación que falla silenciosamente (R-04 del spec).

---

## 2. Matriz de cobertura — FR (Requisitos Funcionales)

La spec define **19 FR** (FR-01..FR-11 del alcance original + FR-12..FR-19 del alcance ampliado). Se cruza cada uno contra las tasks de `tasks.md`.

| FR | Descripción corta | Tasks que lo cubren | Cobertura |
|---|---|---|---|
| **FR-01** | Marcador `proyecto_tipo` en `.bootstrap-state.json` | T025 | ✅ Cubierto |
| **FR-02** | Criterio de detección determinista (reusar bootstrap) | T026 | ⚠️ Cubierto con imprecisión de línea (ver H-03) |
| **FR-03** | Fail-closed → `consumidor` + WARN | T027 | ✅ Cubierto |
| **FR-04** | Tabla de whitelist derivada de `(tier, proyecto_tipo)` | T030, T031, T031b, T032, T033 | ⚠️ Cubierto, pero deriva a **capa** en las tasks (ver sección 6) |
| **FR-05** | Expansión del Implementador en kit | T030, T042 | ✅ Cubierto |
| **FR-06** | Acotamiento del Implementador en consumidor | T031b, T042 | ✅ Cubierto |
| **FR-07** | Anti-fuga en la propagación | T028 | ✅ Cubierto |
| **FR-08** | Resolución `task → agente dueño` para el `pensador` | — (ninguna task) | ❌ **SIN COBERTURA** (ver H-01) |
| **FR-09** | Escalado obligatorio ante `Permission denied` | T031, T034 | ⚠️ Cubierto parcialmente (ver H-02) |
| **FR-10** | Paridad `.github/` ↔ `.opencode/` | T035, T036, T037 | ✅ Cubierto |
| **FR-11** | Enmienda de Art. X | T041 | ✅ Cubierto |
| **FR-12** | Extracción de capacidades embebidas a skills | T001, T002, T003, T004, T021, T022, T023, T024 | ✅ Cubierto |
| **FR-13** | Declaración explícita de skills en frontmatter | T007, T008, T009, T010, T011, T012 | ⚠️ Cubierto, con skills inexistentes (ver H-04) |
| **FR-14** | Consolidación de duplicación entre agentes | T002, T019, T022 | ✅ Cubierto |
| **FR-15** | Hook de conventional commits | T006, T021 | ✅ Cubierto |
| **FR-16** | `usuario-preferencias` como capa de gobernanza | T019, T020, T032 | ✅ Cubierto |
| **FR-17** | Eliminación de bloques comunes repetidos | T013, T014, T015 | ✅ Cubierto |
| **FR-18** | Adelgazamiento de los cuerpos | T016, T017, T018 | ✅ Cubierto |
| **FR-19** | Whitelist contextual por **capa** y tipo de proyecto | T030, T031, T031b, T032, T033, T034 | ⚠️ Cubierto, taxonomía en conflicto con FR-04 (ver sección 6) |

**Resultado: 14 FR con cobertura plena, 4 con observaciones, 1 sin cobertura.**

### 2.1 FR sin cobertura en detalle

**FR-08 — Resolución `task → agente dueño` (❌ SIN COBERTURA).**
Es el requisito que ataca la causa raíz del defecto 1.2 del spec (el `pensador` asignó la reparación al agente equivocado tres veces). El spec lo declara MUST, con secuencia de 5 pasos y prohibición explícita ("Prohibido asignar por intuición o por el nombre del agente"). La CA-07 lo verifica por inspección de `pensador.md` y `pensador.agent.md`.

Sin embargo, **ninguna task de `tasks.md` lo implementa**. Las tasks de Fase 8 (T030-T034) ajustan frontmatters de otros agentes; T016 adelgaza el cuerpo del `pensador` pero no le agrega la tabla de resolución ni la secuencia de FR-08. La CA-07 quedaría sin artefacto que inspeccionar. Es un hueco de cobertura real, no cosmético: es el único FR que cierra el defecto observado en vivo.

---

## 3. Matriz de cobertura — CA (Criterios de Aceptación)

La spec define **12 CA** (CA-01..CA-12).

| CA | Descripción corta | Tasks que lo verifican | Cobertura |
|---|---|---|---|
| **CA-01** | Kit tiene `"proyecto_tipo": "kit"` | T025, T042 | ✅ Cubierto |
| **CA-02** | Consumidor recibe `"proyecto_tipo": "consumidor"` | T027, T042 | ✅ Cubierto |
| **CA-03** | El marcador del kit no se copia al consumidor | T028, T042 | ✅ Cubierto |
| **CA-04** | En kit, `developer` escribe en `scripts/`, `.github/`, `.opencode/`, `Documentacion/` | T030, T042 | ✅ Cubierto |
| **CA-05** | En consumidor, `developer` recibe `Permission denied` en `.github/agents/` | T031b, T042 | ✅ Cubierto |
| **CA-06** | Ante `Permission denied`, el `pensador` delega y no reintenta | T031, T034 | ⚠️ Cubierto por inspección de permisos, no del texto de escalado (ver H-02) |
| **CA-07** | La resolución `task → agente` usa la tabla | — (ninguna task) | ❌ **SIN COBERTURA** (hereda H-01) |
| **CA-08** | Art. X declara la expansión del Implementador en kit | T041 | ✅ Cubierto |
| **CA-09** | `.github/` y `.opencode/` tienen las mismas reglas | T037 | ✅ Cubierto |
| **CA-10** | `sync-kit.ps1` sigue con 0 errores de parseo | — (ninguna task) | ❌ **SIN COBERTURA** (ver H-05) |
| **CA-11** | `plataformador-bootstrap.ps1` sigue con 0 errores de parseo | T029 | ✅ Cubierto |
| **CA-12** | Ante git no disponible, marcador en `consumidor` con WARN | T027 | ✅ Cubierto |

**Resultado: 9 CA con cobertura plena, 1 con observación, 2 sin cobertura.**

### 3.1 CA sin cobertura en detalle

**CA-07 (❌)** — Hereda directamente el hueco de FR-08. La verificación pide inspeccionar la secuencia de FR-08 en ambos `pensador`. Si FR-08 no se implementa, CA-07 no puede pasar.

**CA-10 — `sync-kit.ps1` sigue con 0 errores de parseo (❌ SIN COBERTURA).**
El spec es explícito: NFR-02 exige que el motor de sync mantenga `Parser::ParseFile` en 0 errores, y CA-10 lo eleva a criterio de aceptación. La causa raíz que motivó toda la spec fue precisamente **romper `sync-kit.ps1`** el 2026-10-29. Ninguna task de `tasks.md` ejecuta el gate de parseo sobre el motor de sync; T029 sólo lo hace sobre el bootstrap. El gate que originó la spec queda sin verificación. Es un hueco de cobertura directo sobre el incidente fundacional.

---

## 4. Consistencia spec ↔ plan

Se contrastó cada FR/CA/NFR/R del spec contra las secciones 2 a 10 del plan.

| Elemento del spec | Sección del plan | Veredicto |
|---|---|---|
| FR-01..FR-11 (alcance original) | §5 "Diseño del marcador", C-09 | ✅ Alineado. El plan conserva íntegro el diseño original |
| FR-04 (tabla por tier) | §3 C-09 y §3 C-10 | ⚠️ **El plan **reinterpreta** la tabla de tier como tabla de capa** (C-09: "la whitelist ya no es solo contextual por proyecto — ahora también depende de la **capa del agente**"). El spec mantiene ambas formulaciones (FR-04 tier, FR-19 capa) sin declarar precedencia |
| FR-12..FR-18 (alcance ampliado) | §3 C-01..C-08, §4 mapa de agentes | ✅ Alineado y trazado en §9 |
| FR-19 (whitelist por capa) | §3 C-09, §5 | ✅ Alineado |
| FR-11 (enmienda Art. X) | No aparece en el plan | ⚠️ **Divergencia**: FR-11 es MUST del spec y no tiene cambio `C-NN` asociado. La única traza es la task T041, sin cobertura en el plan |
| NFR-02 (cero regresión sync-kit) | §7 RP-* | ⚠️ Los riesgos RP-05..RP-08 no incluyen "romper el sync-kit" pese a ser el incidente fundacional; RP-07 menciona el bootstrap, no el motor de sync |
| §3.2 "Fuera del alcance" (no reescribir la tabla de tiers) | §4 mapa de agentes reintroduce tiers implícitos ("Plataforma", "Operación") | ⚠️ **Divergencia menor**: el spec excluye "Reescribir la tabla de tiers completa"; el plan introduce nuevas capas con nombre de tier (`Plataforma`) en §4. No contradice pero tensiona |

**Divergencias detectadas (3):**

1. **D-01 — FR-04 vs FR-19 (tier vs capa).** El plan no resuelve cuál de las dos taxonomías manda. Es el hallazgo central (sección 6).
2. **D-02 — FR-11 sin cambio en el plan.** La enmienda de Art. X carece de `C-NN`.
3. **D-03 — NFR-02 no aparece como riesgo.** La causa raíz de la spec (romper `sync-kit.ps1`) desaparece del mapa de riesgos del plan; sólo subsiste como NFR en el spec.

---

## 5. Consistencia plan ↔ tasks

### 5.1 Toda decisión del plan tiene task asociada

| Cambio del plan | Task(s) | Veredicto |
|---|---|---|
| C-01 · skill `git-workflow` | T001, T021 | ✅ |
| C-02 · skill `ssh-operations` | T002, T022 | ✅ |
| C-03 · skill `dependency-upgrade` | T003, T023 | ✅ |
| C-04 · skill `technical-research` | T004, T024 | ✅ |
| C-05 · declarar skills en frontmatter | T007..T012 | ✅ |
| C-06 · hook conventional-commits | T006 | ✅ |
| C-07 · `usuario-preferencias` a gobernanza | T019, T020 | ✅ |
| C-08 · eliminar bloques comunes | T013, T014, T015 | ✅ |
| C-09 · marcador + whitelist contextual | T025..T034 | ✅ |
| C-10 · alinear `edit`/`bash` del `pensador` | T031, T034 | ✅ |
| §5 detección (reusar bootstrap L1867-1884) | T026 | ✅ |
| §5 anti-fuga (`.gitignore` L34) | T028 | ✅ |
| §2 principio "un agente decide, una skill ejecuta" | Sin task directa | ⚠️ Es principio rector, no cambio implementable; se materializa vía C-01..C-08 |

**Resultado**: los 10 cambios `C-NN` y las 2 decisiones de §5 tienen task. Ninguno quedó huérfano.

### 5.2 Toda task es trazable a un FR/CA/C

Revisadas las 43 tasks + T031b contra `tasks.md` (cada task cita su FR o C entre paréntesis):

| Rango | Task(s) | Traza declarada | Veredicto |
|---|---|---|---|
| Fase 1 | T001..T004 | FR-12, FR-14 | ✅ |
| Fase 1 | T005 | verificación de ruta (FR-12 implícito) | ✅ |
| Fase 2 | T006 | FR-15 | ✅ |
| Fase 3 | T007..T011 | FR-13 | ✅ |
| Fase 3 | T012 | verificación FR-13 | ✅ |
| Fase 4 | T013..T015 | FR-17 | ✅ |
| Fase 4 | T016, T017 | FR-18 | ✅ |
| Fase 4 | T018 | verificación FR-18 | ✅ |
| Fase 5 | T019, T020 | FR-16, FR-14 | ✅ |
| Fase 6 | T021..T024 | FR-12..FR-15 | ✅ |
| Fase 7 | T025..T027 | FR-01..FR-03, NFR-04 | ✅ |
| Fase 7 | T028, T029 | FR-07, NFR-03 | ✅ |
| Fase 8 | T030..T034, T031b | FR-05, FR-06, FR-09, FR-16, FR-19 | ✅ |
| Fase 9 | T035..T037 | FR-10, CA-09 | ✅ |
| Fase 10 | T038..T042 | fase posterior / FR-12..FR-19 / FR-19 / FR-11 / CA-* | ✅ |
| Fase 10 | T043 | proceso (sin FR) | ✅ Justificado como task de proceso |

**Ninguna task quedó sin traza.** El subconjunto complementario es el problema: **FR-08 y CA-10 no tienen ninguna task** (huecos 2.1 y 3.1). También FR-11 existe en el spec, se cita en T041, pero no tiene cambio `C-NN` en el plan (§4 D-02).

### 5.3 Chequeo de la afirmación del propio `tasks.md`

`tasks.md` §"Validación de formato" afirma: *"Las 43 tasks cubren los 19 FR del spec"*. **La afirmación es falsa en dos puntos**: FR-08 no tiene task y CA-10 (criterio, no FR) tampoco. La cobertura efectiva es **18 de 19 FR** y **10 de 12 CA**. Se registra como hallazgo de exactitud documental (H-06): una afirmación de completitud sin verificación es exactamente lo que el Art. IX prohíbe en dirección inversa.

---

## 6. Análisis central — Tensión `tier` vs `capa`

Esta es la tensión arquitectónica más importante de la fase y se desarrolla completa aquí. ADR-0013 la registra como decisión.

### 6.1 Las dos taxonomías

**Taxonomía A — `tier` (Art. VII de la constitution, vigente desde v2.0.0).** Divide a los agentes por **nivel de confianza de escritura**. Son cinco: `Documental`, `Documental extendido`, `Implementador`, `Tooling`, `Plataforma`. Cada tier mapea a rutas concretas. El `tier` se declara en el frontmatter de cada agente (`tier: Documental`, `tier: Plataforma`, etc.) y es **el campo que el runtime ya lee**.

**Taxonomía B — `capa` (spec 030 §4.0 FR-19, plan §2 y §3 C-09).** Divide a los agentes por **naturaleza de la función**. Son cuatro: `Gobernanza`, `Orquestador`, `Ejecutor`, `Operación`, más dos categorías no-agente (`Skill`, `Hook/Flow`). La capa **no** se declara hoy en ningún frontmatter.

### 6.2 ¿Se reemplaza el tier o coexisten?

**Respuesta: coexisten, y no son la misma clasificación con dos nombres — son ortogonales.**

La prueba está en los propios datos medidos. Tómense dos agentes del tier `Documental`:

| Agente | Tier (Art. VII) | Capa (FR-19) | Naturaleza |
|---|---|---|---|
| `arquitecto` | Documental | **Orquestador** | Decide y produce un artefacto de fase (ADR) |
| `documentador` | Documental | **Ejecutor** | Materializa documentación a pedido |

**Mismo tier, distinta capa.** Y el caso inverso también existe:

| Agente | Tier | Capa | Naturaleza |
|---|---|---|---|
| `developer` | Implementador | **Ejecutor** | Materializa código |
| `documentador` | Documental | **Ejecutor** | Materializa documentación |

**Misma capa, distinto tier.** Por lo tanto la capa **no es un refinamiento del tier**: es una segunda dimensión. El tier responde *"¿cuánto puede escribir este agente y dónde?"*; la capa responde *"¿qué rol juega este agente en el pipeline?"*. Un agente tiene **ambas**, y las dos son necesarias porque ninguno de los dos ejes determina al otro.

### 6.3 ¿Cuál manda cuando discrepan?

**Manda el tier (taxonomía A), y la capa (taxonomía B) se usa sólo para derivar la whitelist contextual que el tier todavía no puede expresar.**

El fundamento es de autoridad normativa, no de preferencia:

1. El **tier es constitutionally vinculante**: Art. VII lo define como principio no negociable, con tabla de rutas. Cambiarlo o dejar de aplicarlo exige enmienda constitucional (ADR + bump de versión, por Governance). La **capa es una propuesta de spec** (FR-19), todavía `Especificada`, sin rango constitucional.
2. El **tier ya está materializado** en el frontmatter de los 13 agentes y el runtime lo lee. La capa no está declarada en ningún archivo y, para operar, necesitaría un campo nuevo.
3. La **CA-08 del propio spec** sólo exige enmendar Art. X (no Art. VII), lo que confirma que la intención del spec no era reemplazar tiers sino **contextualizar** la whitelist dentro de la estructura de tiers existente.

**Regla de precedencia propuesta (a registrar en ADR-0013):**

> El `tier` sigue siendo la autoridad de whitelist base. La `capa` es un **descriptor de rol** que la whitelist usa como modificador contextual: `whitelist_efectiva = f(tier_base, proyecto_tipo, capa)`. Cuando el tier y la capa sugieren whitelists distintas, **prevalece la más restrictiva de las dos** (fail-closed, consistente con NFR-04). La capa nunca amplía lo que el tier prohíbe; sólo puede acotar.

Esto resuelve la tensión sin reabrir el Specify: FR-04 (tier) y FR-19 (capa) se reconcilian como *base + modificador*, no como dos tablas competidoras.

### 6.4 ¿La capa `Operación` (solucionador) es un tier nuevo?

**No. Es un caso del tier `Plataforma`.**

`solucionador` ya declara hoy `tier: Plataforma` en su frontmatter (verificado). La capa `Operación` lo describe como *"actúa sobre infraestructura viva"* — que es exactamente lo que el tier `Plataforma` autoriza: *"Diagnóstico remoto y nivelación de proyectos"*. La capa `Operación` es una etiqueta más fina (distingue operar sistemas de instalar/nivelar proyectos) **dentro** del mismo tier. Crear un tier nuevo violaría el §3.2 del spec (fuera de alcance) y duplicaría una autoridad ya existente. La diferencia `plataformador` (nivelación) vs `solucionador` (operación en vivo) es una diferencia de **capa dentro del tier**, no de tier.

### 6.5 ¿La capa `Gobernanza` (usuario-preferencias) tiene tier? ¿Y si declara `tier: Documental` pero no escribe?

`usuario-preferencias` declara `tier: Documental` en su frontmatter (verificado) pero **no escribe nada**: su cuerpo es política pura (SSH Policy, Git Preferences, Documentation Format, Agent Roles) sin artefacto propio. FR-19 lo pone en la capa `Gobernanza` con escritura *"No escribe"*.

Aquí hay una **contradicción latente**: el tier `Documental` **sí** otorga whitelist de escritura (`Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`), pero la capa `Gobernanza` dice "no escribe". Con la regla de precedencia de §6.3 (prevalece la más restrictiva), el resultado es coherente: **la capa `Gobernanza` acota a cero la whitelist que el tier `Documental` habilitaría.** El tier queda como autoridad de máximo permisible; la capa lo restringe a la nada. T030-T032 no necesitan cambiar el `tier` declarado — sólo alinear la ausencia de `permission` con la capa. Esto valida la regla del modificador restrictivo.

### 6.6 `Agent-SSD`: tier "Documental extendido" (ADO-0005), ¿en qué capa cae?

`Agent-SSD` es el caso más difícil porque su tier **no pertenece a ninguna fila de la tabla de capas del plan**. Se resolvió por medición:

- El plan §4 lo clasifica (implícitamente) como `Orquestador` junto al `pensador`.
- Pero ADR-0005 y el Art. II lo describen como **ejecutor** de los comandos Speckit: *"el que ejecuta mientras el `pensador` gobierna"*.
- La distinción real: `pensador` **decide** qué fase corre y **responde** por el resultado; `Agent-SSD` **ejecuta** el procedimiento Speckit y devuelve el artefacto. Por el test del plan §2 (*"si no invoca skills y su cuerpo describe procedimiento → es una skill"*), `Agent-SSD` invoca `speckit-*` y responde por el artefacto → es **Orquestador de ejecución** cuyo procedimiento ya está en skills.

**Conclusión D-04 (decisión pendiente del plan):** `Agent-SSD` y `pensador` **no se fusionan**; ambos son orquestadores pero en capas funcionales distintas dentro del mismo rol — `pensador` orquesta el **ciclo** (gobierna fases y artefactos), `Agent-SSD` orquesta la **ejecución de la herramienta** (corre Speckit). Su tier `Documental extendido` no cambia, porque sigue necesitando escribir en `src/<App>/.specify/` para un consumidor. La capa no lo reclasifica de tier.

### 6.7 Cierre del análisis tier vs capa

| Pregunta | Conclusión |
|---|---|
| ¿Se reemplaza el tier por la capa? | **No.** Son ortogonales (caso `arquitecto`/`documentador`: mismo tier, distinta capa). |
| Si coexisten, ¿cuál manda? | **El tier** (rango constitucional). La capa actúa como modificador contextual restrictivo. |
| ¿`Operación` es tier nuevo? | **No.** Es un caso del tier `Plataforma` (mismo frontmatter `tier: Plataforma`). |
| ¿`Gobernanza` tiene tier? | **Sí, `Documental`**, pero la capa lo acota a "no escribe" (prevalece lo restrictivo). |
| ¿En qué capa cae `Agent-SSD`? | **Orquestador** (de ejecución de herramienta), tier `Documental extendido` sin cambios. D-04: no se fusiona con `pensador`. |

**Fórmula de resolución propuesta:** `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`, con intersección restrictiva. Esto absorbe FR-04 y FR-19 sin contradicción y habilita T030-T034 con un criterio determinista (NFR-01).

---

## 7. Huecos y riesgos de proceso

Huecos, no de código. Se numeran `H-NN` y se vinculan a las tasks derivadas de la sección 8.

| ID | Hueco | Severidad | Evidencia |
|---|---|---|---|
| **H-01** | **FR-08 y CA-07 sin ninguna task.** El único requisito que cierra el defecto 1.2 del spec (asignación errónea de dueño) no tiene implementación ni verificación en `tasks.md` | **Alta** | `tasks.md` L33-105: ninguna task menciona la secuencia `task → agente dueño` |
| **H-02** | **CA-06 verificado por permisos, no por texto.** T031 alinea `edit`/`bash` del `pensador`, pero ninguna task inserta en el cuerpo la **regla de escalado** de FR-09 ("detenerse, no reintentar, delegar, reportar"). CA-06 exige inspeccionar la definición, y `edit` alineado no la contiene | **Alta** | T031 sólo menciona el allowlist de comandos; T034 chequea el patrón `edit: deny` + `bash: allow` |
| **H-03** | **FR-02 cita un rango de líneas impreciso.** El spec cita `L1867-1884`, pero la función reutilizable es `Test-IsMasterCheckout` (L2065-2071). El bloque `L1871` está dentro de `Update-Self` y depende del contexto del self-update | Media | Medición: `Select-String get-url origin` en `plataformador-bootstrap.ps1` → L1871 y L2067 |
| **H-04** | **FR-13 declara skills inexistentes.** `threat-modeling` (para `security-auditor`) no existe en el repositorio; las skills viven en subcarpetas de categoría (`seguridad/security-review`, `arquitectura/hexagonal-architecture`, etc.) y el nombre declarado debe coincidir con el campo `name:` del `SKILL.md`, no con la ruta | **Alta** | `Get-ChildItem skills -Recurse` no devuelve `threat-modeling` en ninguna categoría |
| **H-05** | **CA-10 sin task.** El gate `Parser::ParseFile` sobre `sync-kit.ps1` (el archivo que originó la spec al romperse) no se ejecuta en ninguna task; T029 sólo cubre el bootstrap | **Alta** | `tasks.md` T029 cita únicamente `plataformador-bootstrap.ps1` |
| **H-06** | **Afirmación de completitud sin verificación.** `tasks.md` §"Validación de formato" afirma que las 43 tasks cubren los 19 FR; la cobertura real es 18/19 FR y 10/12 CA | Media | Contraste de la matriz de las secciones 2 y 3 |
| **H-07** | **Inconsistencia de conteo de agentes.** `AGENTS.md` L95 dice "11 agentes", L105 dice "14 agentes"; la medición da **13** en cada harness. El mapa del plan §4 asume un punto de partida de 13 y proyecta 8 | Media | Conteo directo de `.opencode/agents/` y `.github/agents/` = 13 cada uno |
| **H-08** | **FR-11 sin cambio en el plan.** La enmienda de Art. X es MUST del spec, se cita en T041, pero no tiene `C-NN` en `plan.md` | Baja | §4 de este analyze (D-02) |
| **H-09** | **Precedencia tier/capa no declarada.** Ni el spec ni el plan definen qué manda cuando FR-04 y FR-19 divergen (§6). Riesgo de dos implementaciones distintas | **Alta** | §2, §3 (FR-04 vs FR-19), §5.1 |
| **H-10** | **Skills duplicadas entre harnesses contradicen Art. IV.** La constitution §IV afirma que las skills son "globales y compartidas desde el workspace master; no se duplican por proyecto". La medición muestra **21 skills idénticas** en `.opencode/skills/` y `.github/skills/`. T036 ("espejar los skills nuevos donde corresponda") operaría sobre una premisa contradictoria con la constitution | Media | `Get-ChildItem .github/skills` y `.opencode/skills` devuelven el mismo conjunto de 21 directorios de primer nivel |
| **H-11** | **`speckit-implement` no coincide con la lista en prosa de `Agent-SSD`.** FR-13 pide declarar los 6 `speckit-*` incluyendo `speckit-implement`; el agente hoy lista `speckit-constitution` en su lugar (L31-37). La lista de FR-13 y la prosa del agente no son idénticas | Media | `.opencode/agents/Agent-SSD.md` L31-37 lista `speckit-constitution`, no `speckit-implement` |

### 7.1 Riesgos de proceso (no de código)

| ID | Riesgo de proceso | Mitigación propuesta |
|---|---|---|
| **P-01** | **El `analyze` llega con el `tasks.md` ya marcado como el artefacto que afirma cubrir los 19 FR**, sin haber ejecutado la verificación. Repetir el patrón de "afirmar sin verificar" (H-06) erosiona la confianza en el pipeline | Toda afirmación de cobertura en `tasks.md` debe pasar por el gate de la matriz FR×task antes de declararse |
| **P-02** | **D-01..D-04 bloquean 4 tasks (T020, T021, T007/T011 y la de `plataformador`) sin plazo.** Un `tasks.md` con dependencias de decisión abiertas no es ejecutable de punta a punta | El `pensador` debe resolver D-01..D-04 con el usuario antes de iniciar la Fase 5 |
| **P-03** | **26 archivos a modificar en dos harnesses = 52 ediciones** (RP-05). La paridad es "condición de cada fase" pero no hay gate automático que la verifique por fase, sólo T037 al final | Elevar la verificación de paridad a pre-commit (el propio hook `conventional-commits` de C-06 puede extenderse) |
| **P-04** | **FR-11 enmienda la constitution pero no hay responsable declarado de la enmienda en el plan.** T041 lo asigna a "verificación end-to-end" (Fase 10), no a un orquestador de gobernanza | Asignar T041 al `Agent-SSD` o `pensador` explícitamente, con el bump de versión MINOR correspondiente |

---

## 8. Tasks derivadas propuestas

Propuestas al `pensador` para su decisión. **No se edita `tasks.md`** en esta fase (analyze es no destructivo). Numeración `T044+`, continua a T043.

| ID | Título | Cubre | Capa dueña sugerida |
|---|---|---|---|
| **T044** | Insertar la secuencia de resolución `task → agente dueño` (FR-08) en el cuerpo de `pensador.md` y `pensador.agent.md`, con la tabla tier×capa×proyecto_tipo como fuente | FR-08, CA-07 | Orquestador (`pensador`) |
| **T045** | Insertar en el cuerpo de `pensador.md` y `pensador.agent.md` la regla de escalado obligatoria (detenerse, no reintentar, delegar, reportar) de FR-09 | FR-09, CA-06 | Orquestador (`pensador`) |
| **T046** | Ejecutar el gate `Parser::ParseFile` sobre `scripts/sync-kit.ps1` y registrar el veredicto (0 errores) en `converge.md` | NFR-02, CA-10 | Ejecutor (`developer`, kit) |
| **T047** | Corregir el rango de líneas de FR-02 en `spec.md`: reemplazar `L1867-1884` por `Test-IsMasterCheckout` (L2065-2071) y registrar la función como fuente de reúso | FR-02, H-03 | Orquestador (`pensador`) |
| **T048** | Verificar la existencia de cada skill declarada en FR-13 contra el campo `name:` del `SKILL.md` correspondiente; crear `threat-modeling` o sustituirla por una existente de `seguridad/` | FR-13, H-04 | Ejecutor (`developer`, kit) |
| **T049** | Declarar la regla de precedencia `tier ∩ capa` en Art. VII o Art. X y en ADR-0013; resolver qué manda cuando FR-04 y FR-19 divergen | FR-04, FR-19, H-09 | Orquestador (`pensador`/`Agent-SSD`) |
| **T050** | Corregir el conteo de agentes en `AGENTS.md` (11→13 y 14→13) y alinear el mapa del plan §4 con el punto de partida medido | H-07 | Documentador |
| **T051** | Corregir la afirmación de cobertura en `tasks.md` §"Validación de formato" (18/19 FR y 10/12 CA) antes de iniciar la implementación | H-06 | Orquestador (`pensador`) |
| **T052** | Resolver D-01..D-04 con el usuario y registrar las respuestas en `pendientes-implementacion.md` antes de la Fase 5 | P-02, FR-16, FR-13 | Orquestador (`pensador`) |
| **T053** | Reconciliar Art. IV con la realidad medida: declarar explícitamente si las skills se duplican entre harnesses o se referencian desde el master | H-10 | Orquestador (`agent-SSD`/`pensador`) |
| **T054** | Alinear la lista de skills en prosa de `Agent-SSD` (`speckit-constitution` vs `speckit-implement`) con la lista de FR-13 y decidir cuál es la correcta | FR-13, H-11 | Orquestador (`Agent-SSD`) |

---

## 9. Spec linking

| Artefacto | Ruta relativa |
|---|---|
| Spec | [`spec.md`](./spec.md) |
| Plan | [`plan.md`](./plan.md) |
| Tasks | [`tasks.md`](./tasks.md) |
| Threat model | [`threat-model.md`](./threat-model.md) |
| ADR de esta fase | [`../../arquitectura/adr/adr-0013-agentes-orquestadores-y-skills.md`](../../arquitectura/adr/adr-0013-agentes-orquestadores-y-skills.md) |
| Índice de ADRs | [`../../arquitectura/adr/00-index.md`](../../arquitectura/adr/00-index.md) |
| Constitution (nivel 2) | [`../../.specify/constitution.md`](../../.specify/constitution.md) |
| ADR-0005 (precedente de tiers) | [`../../arquitectura/adr/adr-0005-agent-ssd.md`](../../arquitectura/adr/adr-0005-agent-ssd.md) |
| Bootstrap (criterio de detección) | `scripts/plataformador-bootstrap.ps1` |
| Motor de sync | `scripts/sync-kit.ps1` |
| Backlog | [`../../pendientes-implementacion.md`](../../pendientes-implementacion.md) |
| Spec predecesora | [`../029-sync-eol-y-force-real/spec.md`](../029-sync-eol-y-force-real/spec.md) |

---

## 10. Verificación del propio análisis

Este analyze se verificó contra las reglas del Art. IX (Contenido Completo) y contra los datos medidos.

| Verificación | Método | Resultado |
|---|---|---|
| Los 19 FR tienen fila en la matriz de cobertura | Conteo de filas de §2 contra FR-01..FR-19 del spec | ✅ 19 filas |
| Los 12 CA tienen fila en la matriz de cobertura | Conteo de filas de §3 contra CA-01..CA-12 del spec | ✅ 12 filas |
| Toda divergencia spec↔plan está numerada | §4 cierra con 3 divergencias (D-01..D-03) | ✅ |
| Toda decisión del plan tiene task | §5.1 recorre C-01..C-10 y las decisiones de §5 | ✅ |
| La tensión tier/capa responde las 5 preguntas del encargo | §6.3 a §6.6, más el cierre de §6.7 | ✅ |
| Los huecos tienen evidencia citada, no afirmada | §7: cada `H-NN` cita una medición o un archivo con línea | ✅ |
| Las tasks derivadas no editan `tasks.md` | §8 las lista sin tocar el archivo | ✅ |
| Ninguna sección quedó con solo el título | Lectura de cada sección del archivo tras escribirlo | ✅ |
| Cero placeholders (`TBD`/`TODO`/`pendiente`/`N/A`) | Búsqueda sobre el archivo escrito | ✅ |
| Las rutas citadas existen | Contraste de cada ruta de §9 con el árbol | ✅ (verificado con `Test-Path` y `Read`) |

### 10.1 Datos medidos en esta fase (no re-medidos del encargo)

| Dato | Valor medido | Fuente |
|---|---|---|
| Agentes en `.opencode/agents/` | 13 | `Get-ChildItem` |
| Agentes en `.github/agents/` | 13 | `Get-ChildItem` |
| Agentes con bloque `skills:` en frontmatter | 1 (`developer`) | `Select-String '^skills:'` |
| Skills de primer nivel en `.opencode/skills/` | 21; con subcategorías anidadas | `Get-ChildItem -Recurse` |
| `threat-modeling` existente | No existe | Búsqueda recursiva |
| `.bootstrap-state.json` | Existe, `{lastUpdate, tools}` sin `proyecto_tipo` | `Get-Content` |
| `.gitignore` L34 | `.bootstrap-state.json` | `git check-ignore -v` |
| `Test-IsMasterCheckout` | `plataformador-bootstrap.ps1` L2065-2071 | `Select-String` |
| `tier` declarado por `solucionador` | Plataforma | frontmatter |
| `tier` declarado por `usuario-preferencias` | Documental | frontmatter |
| `tier` declarado por `Agent-SSD` | Documental extendido | frontmatter |

### 10.2 Límites de esta verificación

No se verificó el comportamiento **en runtime** de la resolución de skills (si el nombre declarado con ruta anidada carga o no). La conclusión de H-04 se apoya en la **ausencia del directorio** `threat-modeling` en el árbol, no en una prueba de carga del harness. Reproducirlo exige un sandbox que esta fase de análisis no ejecuta; se registra como límite explícito, no como certeza.

---

*Analizado por `arquitecto` — Spec 030, fase Analyze — 2026-10-29.*
