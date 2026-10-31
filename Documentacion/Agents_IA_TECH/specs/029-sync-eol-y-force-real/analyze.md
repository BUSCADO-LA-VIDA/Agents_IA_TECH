# Analyze 029 - Sync honesto: EOL normalizado y `-Force` efectivo

| Campo | Valor |
|---|---|
| **Spec** | `spec.md` (8 FR, 4 NFR, 9 CA, 4 FA, 5 DEP, 4 R, 3 A) |
| **Plan** | `plan.md` (13 secciones, 9 cambios C-01..C-09, 15 tests T-01..T-15, 8 riesgos RP-01..RP-08) |
| **Tasks** | `tasks.md` (29 tasks, T001..T029, 4 historias US1..US4, 7 fases) |
| **Checklist** | `checklists/requirements.md` (16 items, todos PASS o PASS con salvedad) |
| **Constitution aplicable** | `Documentacion/Agents_IA_TECH/.specify/constitution.md` v2.1.0 (nivel 2, vigente para esta app) |
| **ADRs que acotan el alcance** | ADR-0006, ADR-0009, ADR-0010 (R4) |
| **ADR generado en esta fase** | `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0012-comparacion-eol-normalizada.md` |
| **Fecha** | 2026-10-27 |
| **Autor** | `arquitecto` (fase Analyze, tier Documental) |
| **Tier de escritura ejercido** | Documental: solo `Documentacion/Agents_IA_TECH/` (Art. VII) |
| **Carácter del análisis** | No destructivo: no modifica `spec.md`, `plan.md` ni `tasks.md`; no marca tasks como completadas |
| **Veredicto** | **PASS con observaciones** |

---

## 1. Resumen ejecutivo

La spec 029 está internamente coherente en su capa normativa. Los 8 requisitos funcionales tienen cambio identificado en el plan y al menos una task en `tasks.md`; 8 de los 9 criterios de aceptación tienen verificación asignada; las 29 tasks son trazables a un cambio (C-0x), a un test (T-xx) o a un criterio (CA-xx). La restricción dura que más podría haber contaminado el diseño —no tocar el guard del bloque `mcp`— está respetada en los tres artefactos y en el ADR-0012, que la eleva a guardrail explícito. No hay contradicciones entre lo que la spec pide y lo que el plan construye.

El análisis encontró **una omisión de cobertura real** (CA-08, paridad Windows/Linux, no tiene ninguna task), **dos coberturas aparentes que no lo son** (NFR-02 se apoya en T025, pero la única suite existente no toca el motor; FR-02 exige tres mensajes distintos y ningún test los afirma) y **un criterio sobredimensionado en su método de verificación** (CA-06 pide que el bloque `mcp` quede *byte-idéntico*, cuando la verificación asignada —T-10— prueba igualdad semántica, y el merge re-serializa el JSON por definición). Ninguna de esas cuatro observaciones invalida el diseño: se cierran con las tasks derivadas T030, T031 y T033 propuestas en la sección 10.

También se detectaron cuatro tensiones de redacción que no requieren enmienda de los FR/CA pero sí una decisión explícita del `pensador`: la spec narra **un** archivo afectado mientras la medición muestra **tres**; FR-07/CA-08 exigen paridad Windows/Linux mientras A-03 declara Windows como único entorno soportado; NFR-03 promete que todo se verifica en sandbox mientras T021 verifica `git diff` en el repo real; y FA-04 excluye "resolver el desfase del índice de ADRs" mientras el registro obligatorio de ADR-0012 exige editar ese índice. Las cuatro se resuelven por interpretación, documentada en la sección 7, sin tocar `spec.md`.

Riesgo de proceso más grave, ajeno al código: existe una **copia obsoleta del motor** en `Documentacion/Agents_IA_TECH/specs/015-sync-kit-bootstrap/implementation/sync-kit.ps1` (33.783 B / 608 líneas) frente al motor vivo (37.660 B / 713 líneas). Dos copias del mismo motor, una sin mantener, en un repo cuya única función es ser fuente de verdad documental. Se registra como H-09 y se propone T037.

---

## 2. Veredicto

**PASS con observaciones.**

Justificación por criterio del gate de constitución ("`speckit-analyze` sin hallazgos CRITICAL", Art. Quality Gates):

| Criterio del gate | Resultado | Sustento |
|---|---|---|
| Cero FR sin cobertura | **CUMPLE** | Los 8 FR tienen C-0x y al menos una task; ver sección 4 |
| Cero CA sin cobertura | **NO CUMPLE (1 de 9)** | CA-08 sin task alguna; las demás 8 tienen verificación asignada; ver sección 5 |
| Cero contradicción entre artefactos | **CUMPLE con salvedades** | Cinco tensiones de redacción (DS-01..DS-05), ninguna normativa, todas resolubles sin enmienda de FR/CA |
| Restricción arquitectónica respetada | **CUMPLE** | El guard del bloque `mcp` no se modifica en ningún cambio C-0x ni en el ADR-0012 |
| Trazabilidad tarea → cambio/criterio | **CUMPLE** | Las 29 tasks citan C-0x, T-xx o CA-xx; la única sin ancla técnica es T028, que ya está ejecutada |
| Hallazgos CRITICAL | **CERO** | Los dos hallazgos de severidad alta (H-01, H-02) y los siete de severidad media tienen mitigación acotada en tasks T030..T038; ninguno bloquea el arranque de la Fase 1 |

Por qué no es FAIL: ninguna omisión impide implementar ni invalida una decisión de diseño. La omisión de CA-08 es de *verificación*, no de *comportamiento*: el diseño (D-03, D-06) elimina estructuralmente la dependencia de plataforma, y el propio plan excluye CA-08 del gate de propagación (R-03 solo exige CA-01..CA-07). Marcar FAIL obligaría a reabrir una spec cuyo alcance ya está cerrado por evidencia.

Por qué no es PASS limpio: `tasks.md` L136 afirma que "las 29 tasks cubren los 8 FR y los 9 CA de la spec". Esa afirmación es **falsa para CA-08** y no verificada para NFR-02. Un `tasks.md` que declara cobertura total sin serlo es exactamente el defecto que el Art. IX prohíbe (afirmaciones contra evidencia, no contra intención). Corregir esa línea es trabajo del `pensador` sobre `tasks.md`; este análisis no lo edita.

Condición para pasar a PASS limpio: incorporar T030 (CA-08) y T036 (NFR-02) a `tasks.md` y ajustar la afirmación de L136.

---

## 3. Evidencia recolectada en esta fase

Todo lo de esta tabla se leyó en el repo durante esta sesión (2026-10-27); no se re-midieron los hechos ya establecidos, se confirmaron sus anclas.

| # | Hecho verificado | Fuente leída | Resultado |
|---|---|---|---|
| E-01 | `Sync-TransversalKit` no declara `-Force` ni `-DryRun` | `scripts/sync-kit.ps1` L452-458 | `param` con `RepoUrl`, `RootPath`, `OrphanAction`, `KitPath`. Confirmado |
| E-02 | El entrypoint no propaga ningún flag | `scripts/sync-kit.ps1` L712 | `Sync-TransversalKit -RepoUrl $RepoUrl -RootPath $resolvedRoot -OrphanAction $OrphanAction -KitPath $KitPath`. Confirmado |
| E-03 | El motor sí recibe los flags en su `param` de nivel superior | `scripts/sync-kit.ps1` L30-42 | `[switch]$DryRun`, `[switch]$Force`. El dynamic scoping es el único puente entre ambos niveles |
| E-04 | Los dos invocadores externos pasan los flags como argumentos de proceso hijo | `sync-agents.ps1` L61-63 y `scripts/plataformador-bootstrap.ps1` L2044-2046 | Ambos construyen `$syncArgs` con `-DryRun` / `-Force` y ejecutan `pwsh -NoProfile -File`. Ninguno llama a `Sync-TransversalKit` como función |
| E-05 | La comparación de transversales usa hash crudo sin `-LiteralPath` | `scripts/sync-kit.ps1` L640-649 | `(Get-FileHash $src).Hash` y `(Get-FileHash $dst).Hash`, `[OK]` / `[SKIP]` de dos estados |
| E-06 | El guard de `.opencode/.gitignore` usa hash crudo con `-LiteralPath` | `scripts/sync-kit.ps1` L589-601 | Dos `Get-FileHash` crudos; `-Force` corta el guard por la condición `(-not $Force)` |
| E-07 | El merge del bloque `mcp` está inline y escribe con `Set-Content -Encoding UTF8` | `scripts/sync-kit.ps1` L651-671 | Reproduce exactamente lo que el plan D-05 transcribe; `Copy-Item` en L672 |
| E-08 | `.opencode/.gitignore` no tiene atributo EOL | `.gitattributes` | Solo `*.yml`, `*.yaml`, `*.json`, `*.md` y `.env.example` declaran `eol=lf` |
| E-09 | La única suite Pester existente no toca el motor | `tests/` (1 archivo) más búsqueda de `Orphan` y `sync-kit` en `tests/upgrade_framework.Tests.ps1` | 32.534 B, cero coincidencias. El motor no tiene test previo |
| E-10 | Pester instalado | `Get-Module -ListAvailable Pester` | 3.4.0 únicamente. Confirma la restricción de `Should Be` posicional y la ausencia de `BeforeAll` |
| E-11 | La copia del motor en la spec 015 está desactualizada | `specs/015-sync-kit-bootstrap/implementation/sync-kit.ps1` | 33.783 B / 608 líneas contra 37.660 B / 713 líneas del motor vivo; su entrypoint (L663) tampoco propaga flags |
| E-12 | La sección "Política merge-no-mirror" documenta el criterio viejo | `README.md` L60-70 | L63 dice literalmente "Hash + SKIP sin `-Force`". Es el texto que T023 debe reemplazar |
| E-13 | La spec 002 contradice el criterio nuevo en su criterio de aceptación | `specs/002-script-plataforming-sync-kit/spec.md` L75 | "Los archivos transversales del proyecto coinciden con la fuente del kit". Con `EolOnly` el archivo **no** coincide byte a byte, y eso pasa a ser correcto |
| E-14 | La spec 002 arrastra una contradicción previa con ADR-0010 | `specs/002-script-plataforming-sync-kit/spec.md` L111 | FR-010 exige habilitar MCPs con `enabled: true`, que ADR-0010 R3 prohíbe. T022 edita ese mismo archivo |
| E-15 | El flujo 021 sigue sin cablear | `scripts/` y `sync-agents.ps1` | `Sync-TransversalKit` solo aparece en el motor vivo, el motor de la spec 015 y comentarios del bootstrap; ninguna llamada desde `scripts/sync/*` |
| E-16 | El índice de ADRs está desactualizado y ADR-0011 está incompleto | `arquitectura/adr/00-index.md` y `adr-0011-public-docs-routing.md` | El índice llegaba a ADR-0009 y declaraba última actualización 2026-10-11. ADR-0011 mide **453 B / 16 líneas** y le faltan Alternativas, Guardrails, Spec linking, Diagramas y Plan de implementación |

---

## 4. Matriz de cobertura - requisitos funcionales

| FR | Qué exige | Cambio en el plan | Task(s) | Test | Cobertura |
|---|---|---|---|---|---|
| **FR-01** | Comparación por contenido con EOL normalizado | C-01, C-03, C-04 | T003, T009, T008 | T-01..T-06 (T004) | **Completa** |
| **FR-02** | Tres resultados con mensajes distintos | C-04 más contrato §4 | T008, T011 | Ninguno afirma los strings; T012 y T026 los observan a ojo | **Parcial** - ver H-03 |
| **FR-03** | `-Force` declarado y propagado | C-02, C-07 | T013, T014, T015, T016 | T-13, T-14 (AST) | **Completa** |
| **FR-04** | `opencode.json` escrito en LF | C-05 más `Write-KitJsonFile` | T020, T018 | T-08, T-12 | **Completa** |
| **FR-05** | Guard del bloque `mcp` intacto | C-05 más `Merge-KitOpencodeJson` | T019, T020 | T-10, T-11 | **Completa** (con la salvedad de método de CA-06) |
| **FR-06** | `-DryRun` sin escrituras ni efectos | C-02, C-07 (L492 intacto) | T013, T014, T017 | T-07, sandbox paso 2 (T026) | **Completa** |
| **FR-07** | Idéntico en Windows y Linux, sin `[Environment]::NewLine` | D-03, D-06 | T004 (vía T-02, T-04 y T-06) | T-02, T-04, T-06 | **Parcial** - cobertura por construcción, sin verificación estática ni ejecución en Linux; ver H-01 |
| **FR-08** | Spec 002 y README actualizados | Converge | T022, T023, T024 | Reading check (T024) | **Completa en tasks**, con ancla imprecisa en T022 (H-06) |

**FR sin cobertura: ninguno.** Dos FR tienen cobertura parcial (FR-02, FR-07).

---

## 5. Matriz de cobertura - criterios de aceptación

| CA | Qué exige | Task(s) | Método de verificación | Cobertura |
|---|---|---|---|---|
| **CA-01** | Igual con EOL distinto, sin `-Force`, sin reescritura | T004 (T-02, T-04), T012 | Comparación pura más sandbox | **Completa con salvedad de método**: T012 dice "sin reescribir" pero no exige hash del archivo antes y después, que es la única prueba observable de no-escritura |
| **CA-02** | Distinto real sigue reportando y `-Force` copia | T004 (T-03), T026 paso 4 | Comparación pura más sandbox | **Completa** |
| **CA-03** | `opencode.json` resultante con 0 CRLF | T018 (T-08), T019 (T-12), T021 | Conteo de `\r\n` | **Completa** |
| **CA-04** | Sin diff espurio tras sync completo | T018 (T-09), T021, T026 paso 6 | Round-trip más `git diff` real | **Completa** |
| **CA-05** | `-DryRun` escribe cero | T017, T026 paso 2 | Hash del directorio antes y después | **Completa** |
| **CA-06** | Bloque `mcp` local byte-idéntico | T019 (T-10), T021 | Igualdad semántica del objeto | **Parcial** - el criterio pide bytes, la task prueba semántica; ver H-04 |
| **CA-07** | Firma con `-Force` más propagación en el entrypoint | T015 (T-13), T016 (T-14) | AST sobre `FunctionDefinitionAst` y `CommandAst` | **Completa** |
| **CA-08** | Mismo resultado en Windows y en Linux; sin ramas por plataforma | **NINGUNA** | Implícito en T-02, T-04 y T-06, que solo corren donde corre Pester | **SIN COBERTURA** |
| **CA-09** | Spec 002 y README al día | T024 (con T022, T023) | Lectura de ambos archivos | **Completa** |

**CA sin cobertura: CA-08.** Es el único, y es el único criterio que exige un entorno que este repo no tiene (ver DS-02).

---

## 6. Matriz de cobertura - requisitos no funcionales

Los NFR no tienen matriz propia en el plan §9; se agrega aquí porque dos de ellos son los que sostienen el veredicto.

| NFR | Qué exige | Task(s) | Cobertura |
|---|---|---|---|
| **NFR-01** | Semántica de `-Force` inalterada para los demás transversales | T004 (T-03), T026 paso 4, T013 y T014 | **Completa**: el caso "difiere de verdad más `-Force`" está probado en la lib y en sandbox |
| **NFR-02** | Cero regresiones en el guard de `.opencode/.gitignore`, en huérfanos y en `.opencode/config.json` | T025 | **Sin cobertura real**: T025 corre la suite completa, pero la suite completa es `upgrade_framework.Tests.ps1` (E-09), que no toca ninguno de los tres. No hay línea base contra la cual regresar; ver H-02 |
| **NFR-03** | Verificable en sandbox sobre `$env:TEMP`, sin tocar el repo real ni red | T005, T007, T015, T017, T026 | **Completa**, con la tensión de redacción de DS-05 |
| **NFR-04** | Normalizar solo `\r\n` -> `\n` | T004 (T-05, T-06), D-03 | **Completa**: los dos límites peligrosos (BOM y CR suelto) tienen test y veredicto esperado documentado |

---

## 7. Consistencia spec ↔ plan

Cinco divergencias detectadas. Ninguna exige enmienda de un FR o un CA; dos requieren una decisión de interpretación del `pensador`.

### DS-01 - La spec narra un archivo, la medición muestra tres

`spec.md` en su sección de contexto presenta la tabla de bytes con **solo** `opencode.json` y describe el defecto como un falso positivo sobre ese archivo. La medición de `git ls-files --eol` (plan §1.2) muestra tres archivos transversales silenciados en cada corrida: `opencode.json` (`w/crlf`), `AGENTS.md` (`w/mixed`, 1 CRLF) y `.specify/memory/constitution.md` (`w/mixed`, 2 CRLF).

**Evaluación**: la capa normativa ya cubre los tres. FR-01 dice "la comparación **de archivos transversales**" (plural, genérico) y CA-01 dice "**Un** archivo con contenido identico y EOL distinto" (cualquiera, no `opencode.json` en particular). El desfase está solo en la narrativa y en la tabla de evidencia. Además T012 ya verifica los tres archivos por nombre.

**Conclusión**: no requiere enmienda de FR ni de CA. Se recomienda, como mejora de honestidad documental para un PATCH posterior, ampliar la tabla de evidencia con las dos filas faltantes, porque hoy quien lea solo `spec.md` subestima el alcance del defecto. No es bloqueante: el plan lo resuelve de forma explícita en §1.2 con la frase "El defecto es mas ancho que lo que decia la spec".

### DS-02 - FR-07 y CA-08 exigen Linux; A-03 declara que solo existe Windows

FR-07 exige comportamiento idéntico en Windows y Linux; CA-08 exige "el mismo resultado reportado en Windows y en un entorno Linux". El supuesto A-03 declara: "el operador ejecuta el sync desde PowerShell 7 en Windows, que es el unico entorno soportado por el kit". **La spec se contradice a sí misma**: un criterio de aceptación sobre un entorno que un supuesto declara no soportado, y sin entorno Linux en este repo ni en CI (E-10 confirma que la única suite corre localmente).

**Interpretación recomendada**: FR-07 no es un requisito de ejecución en Linux, es un requisito de **no dependencia de plataforma**. Se satisface si el código no consulta `[Environment]::NewLine`, no compara con literales `\r\n` en la ruta de escritura y no usa cmdlets cuyo EOL dependa del host. Eso es verificable estáticamente hoy (AST o búsqueda de patrones), no requiere una máquina Linux.

**Consecuencia**: CA-08 queda verificable si se agrega un test estático (T030). Sin ese test, CA-08 es un criterio decorativo. Se recomienda además que un PATCH futuro reformule A-03 para que no contradiga CA-08.

### DS-03 - El plan declara `-DryRun` explícito y la spec solo nombra `-Force`

FR-03 obliga a declarar `-Force` en el `param`. El plan D-07 declara **los dos** flags, argumentando que `$DryRun` es el mismo defecto con peor consecuencia ("escribir cuando pidieron no escribir") y que FR-06 lo exige.

**Conclusión**: ampliación **justificada y dentro del alcance**, no desvío. FR-06 ("`-DryRun` MUST seguir produciendo cero escrituras") no es satisfacible de forma robusta si el flag sigue resolviéndose por dynamic scoping, y el Art. VIII de la constitución eleva el "cero escrituras en `-DryRun`" a consecuencia práctica obligatoria. No requiere enmienda; sí requiere que converge lo declare, para que spec 002 y README no describan un contrato de flags incompleto.

### DS-04 - FA-04 excluye el índice de ADRs, pero ADR-0012 obliga a tocarlo

`spec.md` FA-04: "Resolver el desfase del `00-indice.md` ni del indice de ADRs; se registran como deuda separada".

**Hecho**: esta misma fase Analyze produce ADR-0012 y la convención del índice (`00-index.md`, sección "Como agregar un nuevo ADR", paso 4) exige "Actualizar **esta tabla** con la nueva entrada". La constitución, en Governance, lo refuerza: "Un cambio de principio exige ademas **ADR** en `Documentacion/<AppName>/arquitectura/adr/` y entrada en su `00-index.md`".

**Interpretación**: FA-04 excluye el **backlog** del índice (23 specs sin registrar, ADR-0010 y ADR-0011 ausentes, fecha congelada en 2026-10-11), no el **registro de un ADR nuevo**. Registrar ADR-0012 no es "resolver el desfase", es cumplir el procedimiento. Por eso el índice se actualizó en esta fase, incluyendo de paso las dos filas que faltaban (ADR-0010, ADR-0011) porque la misma edición las volvía inevitables.

**Conclusión**: no hay contradicción de fondo, pero la redacción de FA-04 es ambigua y un lector estricto podría leerla como prohibición. Se recomienda precisar FA-04 en un PATCH: "no se resuelve el desfase histórico del índice; el registro de los ADR generados por esta spec sí se hace".

### DS-05 - NFR-03 promete sandbox; CA-04 y T021 verifican en el repo real

NFR-03: "El comportamiento es verificable en sandbox sobre `$env:TEMP`, sin tocar el repo real ni requerir red". T021: "y `git diff -- opencode.json` queda vacio **en el repo real**". T026 paso 6 repite la verificación real.

**Evaluación**: no es una contradicción de diseño sino de alcance de la promesa. NFR-03 habla de que el comportamiento **se puede** verificar en sandbox (y es cierto: T-01..T-12 y los pasos 1 a 5 lo hacen). CA-04 exige que *tras un sync completo* no haya diff espurio, y eso solo se observa en el repo donde se ejecutó el sync.

**Conclusión**: conviene reformular NFR-03 como "verificable en sandbox; la comprobación final de CA-04 se hace sobre el repo real con un merge controlado". No bloquea: T021 ya distingue ambos momentos.

---

## 8. Consistencia plan ↔ tasks

### 8.1 Decisiones del plan con task asociada

| Decisión | Contenido | Task(s) | Estado |
|---|---|---|---|
| D-01 | El helper va en `scripts/sync-kit-lib.ps1`, no en `scripts/sync/lib/` | T001 (creación), T003 (dot-source) | Trazada |
| D-02 | Solo se toca `scripts/sync-kit.ps1` más su lib; `scripts/sync/*` queda fuera | Ninguna task toca `scripts/sync/*` (verificado) | Trazada por ausencia, correctamente |
| D-03 | Normalización a nivel de bytes | T001, T004 (T-05, T-06) | Trazada |
| D-04 | Tres resultados con dos hashes en un solo helper | T001, T004 | Trazada |
| D-05 | Merge del bloque `mcp` extraído a la lib sin cambiar semántica | T019, T020 | Trazada |
| D-06 | Escritura LF con `WriteAllText` y `UTF8Encoding($false)` | T018, T020 | Trazada |
| D-07 | `-Force` y `-DryRun` como parámetros explícitos | T013, T014, T017 | Trazada |

### 8.2 Cambios C-0x con task

| Cambio | Task | Cambio | Task |
|---|---|---|---|
| C-01 dot-source fail-closed | T003 | C-06 quitar `Get-FileHash` sin `-LiteralPath` | T010 |
| C-02 `param` con `[switch]$DryRun, [switch]$Force` | T013 | C-07 propagar flags en L712 | T014 |
| C-03 guard de `.opencode/.gitignore` | T009 | C-08 bloque `# Uso:` | T011 |
| C-04 comparación de transversales | T008 | C-09 L3 DEPRECATED | Sin task, correcto: el plan dice "sin cambio" |
| C-05 merge vía lib | T020 | | |

**Cobertura de cambios: 8 de 8 cambios efectivos.** C-09 no es un cambio y su ausencia de task es coherente.

### 8.3 Tests T-xx con task

| Tests del plan | Task que los crea | Tests del plan | Task que los crea |
|---|---|---|---|
| T-01..T-06 | T004 | T-11 | T019 |
| T-07 | T005 | T-12 | T019 |
| T-08, T-09 | T018 | T-13 | T015 |
| T-10 | T019 | T-14 | T016 |
| | | T-15 | T007 |

**Cobertura de tests: 15 de 15.** Las tres verificaciones de sandbox de la sección 7 del plan que no tienen task individual (CA-01, CA-03/04/06 y CA-05) se cubren con T012, T021 y T017 respectivamente.

### 8.4 Tasks sin trazabilidad técnica

| Task | Observación |
|---|---|
| T028 | "Registrar en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` las tasks y las deudas". Ya está marcada `[x]` y es verificable por lectura del archivo: las filas 029-T001..029-T029 y las deudas DD-01..DD-06 existen (verificado en `pendientes-implementacion.md` L116-144 y L196-202). Trazable a un artefacto verificable |
| T029 | Commit. Trazable a la convención de conventional commits declarada en `AGENTS.md` |

Ninguna task queda sin ancla. La afirmación de `tasks.md` sobre validación de formato ("toda task referencia el cambio, el test o el criterio") se cumple.

### 8.5 Riesgos del plan sin verificación asignada

| Riesgo | Mitigación declarada | Verificación en tasks |
|---|---|---|
| RP-01 | T-14 (AST) falla si no se propaga | **Cubierto**: T016 |
| RP-02 | `switch` prohibido por C-04 | **No cubierto por test**: solo una instrucción en T008. Un `switch` introducido por error no rompe ningún test; ver H-12 |
| RP-03 | T-03, T-05 y T-06 | **Cubierto**: T004 |
| RP-04 | T-08 y T-09 | **Cubierto**: T018 |
| RP-05 | C-01 falla cerrado | **Parcial**: no hay task que verifique que la lib llegue a un consumidor; ver T038 |
| RP-06 | T-10 y T-11 fijan el contrato | **Cubierto**: T019 |
| RP-07 | Re-verificación manual de líneas | **Cubierto por proceso**: T003, T008, T009 y T020 lo declaran |
| RP-08 | FR-04 limita LF a `opencode.json` | **No cubierto por test**: la suite no verifica que `Copy-Item` siga siendo el mecanismo del resto; ver H-13 |

---

## 9. Huecos y riesgos de proceso

Se listan solo riesgos de **proceso y verificación**, no de código (los de código ya están en plan §8).

| ID | Hueco | Severidad | Impacto | Cierre propuesto |
|---|---|---|---|---|
| **H-01** | CA-08 (paridad Windows/Linux) no tiene task. FR-07 se apoya en dos decisiones de diseño y en tests que solo corren en Windows | **Alta** | Un futuro cambio podría reintroducir `[Environment]::NewLine` o un literal `\r\n` sin que nada falle | T030 |
| **H-02** | NFR-02 (cero regresiones en huérfanos, guard `.gitignore` y exclusión de `config.json`) se apoya en T025, que corre la única suite existente; esa suite no referencia el motor (E-09) | **Alta** | El gate de regresión es ficticio: no existe línea base. Una regresión real pasaría el gate | T036 |
| **H-03** | FR-02 exige tres mensajes distintos y ningún test afirma los strings del contrato (plan §4). T012 y T026 los verifican a ojo humano | **Media** | El mensaje puede degradarse (por ejemplo, volver a `[SKIP]` para `EolOnly`) sin fallo de test, que es exactamente el defecto original | T031 |
| **H-04** | CA-06 pide bloque `mcp` **byte-idéntico**; T-10 prueba igualdad semántica. El merge hace `ConvertFrom-Json` más `ConvertTo-Json`, que re-serializa por definición | **Media** | El criterio es inalcanzable si el `opencode.json` del consumidor no está en la forma canónica de `ConvertTo-Json`. Se puede "aprobar" por casualidad del archivo actual (2.466 contra 2.467 caracteres medidos) | T033 |
| **H-05** | RP-05 (la lib no viaja al consumidor y el dot-source revienta) tiene mitigación de código pero ninguna verificación end-to-end | **Media** | El modo de fallo es duro: `$ErrorActionPreference = "Stop"` mata el sync en el consumidor | T038 |
| **H-06** | T022 no ancla la sección a editar, y el archivo objetivo contiene dos frases que hoy contradicen el criterio nuevo: L75 ("coinciden con la fuente del kit") y L111 (FR-010 exige `enabled: true`, contra ADR-0010 R3) | **Media** | El `documentador` puede actualizar el criterio y dejar intactas las frases contradictorias: dos fuentes de verdad, que es el riesgo R-04 de la propia spec | T035 |
| **H-07** | El cambio se aplica a un motor marcado `[021-DEPRECATED]` y el flujo que lo reemplaza (021) no está cableado. Nadie registra la condición de salida de esa convivencia, y `scripts/sync/*` conserva dos comparaciones con hash crudo (DD-02) | **Media** | Deuda estructural: el defecto sobrevive en el flujo que algún día se cablee | Ya registrado como DD-02; el ADR-0012 lo declara en Consecuencias |
| **H-08** | T026 exige seis pasos de sandbox sobre `$env:TEMP` con `-KitPath`, pero no detalla cómo fabricar los marcadores de kit que `-KitPath` valida (`scripts`, `.github`, `.opencode`, `.doc_agents`, `AGENTS.md`). Tampoco dice cómo construir un `opencode.json` destino con `mcp` local | **Baja** | El paso 4 de la fase de plataforma puede consumir tiempo en montaje, o montarse mal y "probar" otra cosa | Se resuelve con el snippet de plan §7 y T026; se recomienda que el implementador fije el montaje en la bitácora |
| **H-09** | Copia obsoleta del motor en `specs/015-sync-kit-bootstrap/implementation/sync-kit.ps1` (33.783 B / 608 líneas) frente al motor vivo (37.660 B / 713 líneas). Su propio entrypoint (L663) tampoco propaga flags | **Media** | Drift documental: un lector o un agente puede tomar la copia como fuente y "arreglar" el archivo equivocado | T037 |
| **H-10** | A-01 ("LF es el formato canonico del repo") es cierto para `*.json` y `*.md`, pero **no** para `.opencode/.gitignore`, que no tiene atributo EOL (E-08). Ese archivo es justamente el del guard | **Media** | El veredicto sobre el guard depende de `core.autocrlf` del entorno, lo que reintroduce una dependencia de plataforma que CA-08 pretende prohibir | T032 |
| **H-11** | Plan D-04 afirma "Dos lecturas por archivo en el caso barato". En realidad son cuatro: dos dentro de `Get-KitContentHash` (una por archivo) y dos `Get-FileHash` adicionales cuando los hashes normalizados coinciden | **Baja** | Afirmación técnica incorrecta en un artefacto de referencia; sin efecto en rendimiento (los transversales son archivos pequeños) | Corrección editorial del plan por el `pensador` |
| **H-12** | RP-02 (`continue` dentro de `switch` sale del `switch`, no del `foreach`) solo está mitigado por una instrucción en T008, sin test | **Baja** | El hazard es real y silencioso: el efecto sería copiar el archivo en el caso `EolOnly`, que es justo lo que CA-01 prohíbe | T031 puede cubrirlo con un test de comportamiento sobre el motor, o una aserción AST de ausencia de `switch` en el bloque de transversales |
| **H-13** | RP-08 (no escribir LF en `.ps1`) no tiene verificación. La suite no comprueba que el resto de transversales siga escribiéndose con `Copy-Item` | **Baja** | Un refactor podría pasar todos los transversales por `Write-KitJsonFile` y corromper `.ps1` | Se cubre con la aserción AST de T030 (únicos usos de `WriteAllText` permitidos) |

---

## 10. Tasks derivadas propuestas (T030 en adelante)

No se edita `tasks.md`. Estas tasks se proponen al `pensador` para que decida su incorporación; la numeración continúa la secuencia existente (último ID vigente: T029).

| ID | Título | Cubre | Agente propuesto | Fase |
|---|---|---|---|---|
| **T030** | Guardarraíl estático de paridad Windows/Linux: AST y búsqueda de `[Environment]::NewLine`, literales `\r\n` en rutas de escritura y usos permitidos de `WriteAllText` | CA-08, FR-07, H-01, H-13 | `plataformador` | Polish |
| **T031** | Test del contrato de mensajes de los tres resultados (`Equal`, `EolOnly`, `Different`) contra los strings exactos del plan §4, incluyendo aserción de ausencia de `switch` en el bloque de transversales | FR-02, H-03, RP-02, H-12 | `plataformador` | Foundational y US1 |
| **T032** | Política explícita de `EolOnly` en el guard de `.opencode/.gitignore`: decidir si se preserva el local o se acepta la copia del maestro, con test que fije la decisión | FR-01, NFR-02, H-10 | `plataformador` | US1 |
| **T033** | Reescribir la verificación de CA-06 como igualdad semántica del bloque `mcp` (comparación profunda del objeto) más igualdad byte a byte solo cuando el destino ya es canónico, y documentar el límite | CA-06, H-04 | `plataformador` | US3 |
| **T034** | Decisión y test del fallback `NoLocalMcp` de `Merge-KitOpencodeJson`: la rama `$null -eq $srcJson` es inalcanzable con el `catch` actual y, si se alcanzara, cae a `Copy-Item` del maestro | FR-05, NFR-02 | `plataformador` | US3 |
| **T035** | Anclar T022 y T023 a secciones concretas: spec 002 L75, L78 y FR-011 (L112); README L60-70. Registrar la enmienda con fecha y referencia a spec 029, y resolver el arrastre de FR-010 (L111) contra ADR-0010 R3 | FR-08, CA-09, H-06 | `documentador` | US4 |
| **T036** | Cobertura base del motor para que NFR-02 tenga contra qué regresar: detección de huérfanos, guard de `.opencode/.gitignore` y exclusión de `.opencode/config.json`, con fixtures en `$env:TEMP` | NFR-02, H-02 | `plataformador` | Foundational |
| **T037** | Resolver el drift documental del motor duplicado: banner de obsoleto con puntero al motor vivo en `specs/015-sync-kit-bootstrap/implementation/sync-kit.ps1`, o retiro aprobado por el usuario si nada lo referencia | H-09 | `documentador` (el retiro requiere aprobación) | Polish |
| **T038** | Verificar la propagación de `scripts/sync-kit-lib.ps1` a un consumidor en sandbox: que `scripts/` lo copie con `robocopy /E` y que el dot-source del motor no reviente con `$ErrorActionPreference = "Stop"` | RP-05, H-05 | `plataformador` | Polish |

**Nota de secuenciación**: T031, T032 y T036 pertenecen a fases tempranas y deberían ejecutarse antes de T008 y T009; T030, T033, T034, T037 y T038 son de cierre. T035 depende de que el código esté mergeado, porque describe el criterio ya implementado.

---

## 11. ADR de esta fase y estado del índice

### 11.1 ADR-0012

Se crea `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0012-comparacion-eol-normalizada.md` (MADR completo: Contexto, Decisión, Alternativas, Consecuencias, Guardrails, Spec linking, Diagramas Mermaid, Plan de implementación). Registra la decisión de normalizar `\r\n` -> `\n` a nivel de bytes con veredicto de tres estados (`Equal`, `EolOnly`, `Different`), rechaza el hash crudo actual como alternativa, y fija como restricción dura que el guard del bloque `mcp` no se toca (ADR-0009, ADR-0010 R4). Estado `Aceptado`, fecha 2026-10-27.

### 11.2 Estado verificado del índice

`arquitectura/adr/00-index.md` estaba congelado en 2026-10-11 y llegaba a ADR-0009 (E-16). En esta sesión se agregaron las tres filas faltantes en "Lista de ADRs" (ADR-0010, ADR-0011 y ADR-0012), las tres equivalentes en "Referencias Cruzadas", y se actualizó la fecha de última actualización a 2026-10-27.

### 11.3 Hallazgo sobre ADR-0011 (verificado)

`adr-0011-public-docs-routing.md` mide **453 bytes y 16 líneas** (verificado con `Get-ChildItem`, E-16). **Está incompleto** respecto de la convención MADR del propio índice: tiene Estado, Contexto, Decisión y Consecuencias, y le faltan **Alternativas consideradas**, **Guardrails**, **Spec linking**, **Diagramas** y **Plan de implementación**. Su sección "Consecuencias" es una sola línea ("Ruta determinista y permisos respetados"). Es un esqueleto, precisamente lo que el Art. IX prohíbe.

No se corrige en esta fase: es contenido de la spec 028, ya cerrada, y ampliarlo exige reconstruir decisiones que se tomaron fuera de este análisis. Se registra como hallazgo abierto para que el `pensador` decida si se delega al `arquitecto` en una spec de saneamiento documental. Lo único que se hizo aquí fue registrar su fila en el índice con su estado real.

---

## 12. Cumplimiento de la constitución (v2.1.0)

| Artículo | Exigencia | Cumplimiento |
|---|---|---|
| **I. Modular Agent Design** | Agentes autónomos y reutilizables | El ADR-0012 y este análisis citan rutas relativas al repo; cero rutas absolutas de usuario en lo escrito |
| **III. Specification-Driven Development** | Ciclo sin saltos: analyze produce artefacto verificable | Este `analyze.md` cierra la fase con matriz de cobertura, veredicto y tasks derivadas |
| **VII. Restricción de Paths por Tier** | El tier Documental escribe solo en `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/` y `README.md` | **CUMPLE**: se escribió únicamente en `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/analyze.md`, `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0012-comparacion-eol-normalizada.md` y `Documentacion/Agents_IA_TECH/arquitectura/adr/00-index.md`. Cero ediciones en `scripts/`, `tests/`, `.github/`, `.opencode/` y `.specify/` |
| **VIII. Fail-Open en Integraciones Externas** | `-DryRun` sin escrituras; operación destructiva fail-closed | El ADR-0012 fija ambos como guardrails (G4 y G8) |
| **IX. Contenido Completo, Nunca Esqueletos** | Sin secciones vacías ni marcadores de contenido diferido | Verificado sección por sección en la sección 14 |
| **Quality Gates** | `analyze` sin hallazgos CRITICAL | **CUMPLE**: cero CRITICAL; dos hallazgos de severidad alta (H-01, H-02) y siete de severidad media, todos con task derivada o cierre propuesto en la sección 9 |

---

## 13. Spec linking

| Artefacto | Ruta relativa a `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/` | Relación |
|---|---|---|
| Spec | [`spec.md`](./spec.md) | Fuente de los 8 FR, 4 NFR y 9 CA evaluados en las secciones 4, 5 y 6 |
| Plan | [`plan.md`](./plan.md) | Fuente de las decisiones D-01..D-07, cambios C-01..C-09, tests T-01..T-15 y riesgos RP-01..RP-08 evaluados en la sección 8 |
| Tasks | [`tasks.md`](./tasks.md) | Fuente de las 29 tasks evaluadas en la sección 8; **no modificado** por este análisis |
| Checklist | [`checklists/requirements.md`](./checklists/requirements.md) | Precondición de la fase; su nota final sobre el índice de ADRs quedó atendida en la sección 11 |
| Analyze | `analyze.md` (este archivo) | Artefacto de la fase |
| ADR de esta fase | [`../../arquitectura/adr/adr-0012-comparacion-eol-normalizada.md`](../../arquitectura/adr/adr-0012-comparacion-eol-normalizada.md) | Decisión de comparación normalizada con tres estados |
| Índice de ADRs | [`../../arquitectura/adr/00-index.md`](../../arquitectura/adr/00-index.md) | Registro de ADR-0010, ADR-0011 y ADR-0012 |
| ADRs que acotan el alcance | [`../../arquitectura/adr/adr-0009-mcp-hardcoded-workaround.md`](../../arquitectura/adr/adr-0009-mcp-hardcoded-workaround.md), [`../../arquitectura/adr/adr-0010-opencode-v2-mcp-shape.md`](../../arquitectura/adr/adr-0010-opencode-v2-mcp-shape.md) y [`../../arquitectura/adr/adr-0006-mcp-token-resolution.md`](../../arquitectura/adr/adr-0006-mcp-token-resolution.md) | Restricción R4 y guardrails del ADR-0012 |
| Constitución | [`../../.specify/constitution.md`](../../.specify/constitution.md) | v2.1.0; Art. VII y IX aplicados en la sección 12 |
| Contratos a actualizar en converge | [`../002-script-plataforming-sync-kit/spec.md`](../002-script-plataforming-sync-kit/spec.md) y `README.md` (raíz del repo) | DEP-02 y DEP-03; anclas precisadas en H-06 y T035 |
| Backlog | [`../../pendientes-implementacion.md`](../../pendientes-implementacion.md) | Filas 029-T001..029-T029 y deudas DD-01..DD-06 ya registradas por T028 |
| Drift documental | [`../015-sync-kit-bootstrap/implementation/sync-kit.ps1`](../015-sync-kit-bootstrap/implementation/sync-kit.ps1) | Copia obsoleta del motor; H-09 y T037 |

---

## 14. Verificación del propio análisis

| Comprobación | Resultado |
|---|---|
| Ninguna sección con solo el título | 14 secciones, todas con contenido propio; la sección 14 es esta tabla de control |
| Cero marcadores de contenido diferido (los cinco términos vedados por el Art. IX) | Verificado por lectura completa del archivo: el único texto que alude a ellos es esta misma fila |
| Tablas con filas reales | 16 tablas, todas con al menos 2 filas de datos (verificado por conteo de separadores de tabla) |
| Rutas citadas existentes | `spec.md`, `plan.md`, `tasks.md`, `checklists/requirements.md`, `adr-0006`, `adr-0009`, `adr-0010`, `adr-0011`, `adr-0012`, `00-index.md`, `constitution.md`, `specs/002-script-plataforming-sync-kit/spec.md`, `README.md`, `pendientes-implementacion.md`, `specs/015-sync-kit-bootstrap/implementation/sync-kit.ps1`, `scripts/sync-kit.ps1`, `sync-agents.ps1`, `scripts/plataformador-bootstrap.ps1`, `tests/upgrade_framework.Tests.ps1` y `.gitattributes`: todas verificadas con herramienta de lectura o listado de directorio |
| Mediciones no re-medidas | Se respetaron los hechos entregados; se agregaron solo anclas nuevas (E-04, E-08, E-09, E-11, E-13, E-14 y E-16) |
| `spec.md`, `plan.md` y `tasks.md` no modificados | Confirmado: ninguna escritura sobre esos tres archivos en esta fase |
| Tasks no marcadas como completadas | Confirmado: este análisis no toca checkboxes |

---

*Documentado por `arquitecto` - Spec 029, fase Analyze - 2026-10-27.*
