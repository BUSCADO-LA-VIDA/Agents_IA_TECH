# Spec 030 — Whitelist de Escritura Contextual por Tipo de Proyecto

| Campo | Valor |
|---|---|
| **Slug** | `030-whitelist-contextual-por-tipo-proyecto` |
| **App** | `Agents_IA_TECH` (proyecto kit, sin `src/` — Art. X) |
| **Fecha** | 2026-10-29 |
| **Estado** | Especificada |
| **Constitution aplicable** | `Documentacion/Agents_IA_TECH/.specify/constitution.md` v2.1.0 |
| **Artefactos hermanos** | `plan.md`, `tasks.md`, `analyze.md`, `threat-model.md` |

---

## 1. Problema

La whitelist de escritura por tier (Art. VII) asume que **todo proyecto tiene `src/<App>/`**. El proyecto kit no lo tiene. Esa suposición produce tres fallos concretos, todos observados en vivo el 2026-10-29:

### 1.1 El `pensador` rompió un archivo fuera de su whitelist, dos veces

El tier Documental **no** puede escribir en `scripts/`. Intenté editar `scripts/sync-kit.ps1` para cumplir la task 029-T031:

1. La herramienta de edición devolvió `Permission denied` → **correcto**, el límite funcionó
2. **En vez de delegar**, reintenté con scripts de shell (`bash: "*": allow`)
3. El script de shell **sí escribió**, porque `permission.edit` no cubre la vía de shell
4. El resultado quedó con **dos** bloques con sintaxis rota: L136 en `Find-OrphanKitFiles` y L640 en `Sync-TransversalKit`
5. `Parser::ParseFile` pasó de **0 errores** (HEAD) a **3 errores**; el archivo quedó inutilizable

**El límite de tier es evadible por vía lateral.** No es un accidente: es una puerta abierta por diseño.

### 1.2 El `pensador` asignó la reparación al agente equivocado, tres veces

Resolver "quién ejecuta esta task" requiere saber **quién es dueño de la ruta**. Esa tabla no existe. Ante la ausencia, improvisé:

| Intento | Agente asignado | Por qué estaba mal |
|---|---|---|
| 1 | `plataformador` | Tier Plataforma; su dominio es nivelación y MCP setup, no código |
| 2 | `plataformador` (repetido) | Mismo error, sin verificar |
| 3 | `developer` (corregido por el usuario) | Pero su `.md` dice "escribir en `src/<App>/` y `tests/`" — y no hay `src/` |

**`developer` es el implementador único** (spec 026). En el kit **el workspace entero es su dominio**. Esa expansión no está escrita en ningún lado.

### 1.3 Existe fuga de permisos del kit hacia los consumidores

El audit log registra al consumidor `Generator_IA_Projects` recibiendo escrituras que no le corresponden:

```json
{"action":"manifest_not_immutable","details":{"path":"C:<sep>Proyectos\\Generator_IA_Projects\\dependencias-manifest.yml"}}
{"action":"opencode_schema_missing_props","details":{"path":"C:<sep>Proyectos\\Generator_IA_Projects\\opencode.json"}}
```

Si la whitelist expandida del kit se escribiera en `developer.md`, ese archivo **se propaga por el sync** y el consumidor heredaría el permiso ampliado. El límite debe vivir donde no viaje.

---

## 2. Objetivo

Que la whitelist de escritura de cada tier sea **contextual al tipo de proyecto** (kit o consumidor), se aplique de forma **determinista** (sin criterio del agente), y **no se filtre** del kit hacia los consumidores durante la propagación.

### 2.1 Criterio de éxito global

Un consumidor que recibe el KIT por `sync` **no puede** obtener permiso de escritura sobre rutas que no son de su dominio, **aunque el texto de los agentes sea idéntico** al del kit.

---

## 3. Alcance

### 3.1 Dentro del alcance

1. Marcador explícito de tipo de proyecto, persistido y legible
2. Criterio de detección **reusando** el que ya existe en el bootstrap
3. Tabla de whitelist derivada del tipo de proyecto
4. Expansión del tier Implementador en el kit (workspace completo)
5. Acotamiento del tier Implementador en consumidores (solo su dominio)
6. Mecanismo anti-fuga en la propagación
7. Circuito de resolución `task → agente dueño` para el `pensador`
8. Regla de escalado: ante denegación de permiso, delegar; nunca reintentar por otra vía
9. Paridad `.github/` ↔ `.opencode/`
10. Enmienda de Art. X para que la expansión quede explícita

### 3.2 Fuera del alcance (explícito)

| Excluido | Razón |
|---|---|
| Reparar `tests/upgrade_framework.Tests.ps1` | Deuda DD-08, 4 errores de parseo preexistentes. Spec propia |
| Implementar 029-T001..T037 | Spec 029 en curso, independiente |
| Reescribir la tabla de tiers completa | Solo se enmienda la fila Implementador y Art. X |
| Cambiar el criterio de detección de kit existente | Se reusa tal cual (L1867-1884 del bootstrap) |
| Retirar `scripts/sync-kit.ps1` | Motor vigente; la 029 lo modifica |

---

## 4. Requisitos funcionales

### 4.0 Replanteo de agentes como orquestadores (alcance ampliado 2026-10-29)

La medición del 2026-10-29 reveló que **1 de 13 agentes** declara skills (solo `developer`, con 6). Los otros 12 declaran 0. Las capacidades están **embebidas en el cuerpo** de cada `.md` en lugar de separarse en skills que el agente invoca.

**Principio rector**: *un agente decide; una skill ejecuta.* El test aplicado a cada agente es:
> ¿Qué skills invoca, y qué decide él? Si no invoca skills y su cuerpo describe procedimiento → es una skill. Si decide y responde por el resultado → es un agente.

**Cuerpos medidos**: `pensador` 504 L, `plataformador` 473 L, `solucionador` 175 L, `gitflow` 140 L, `Agent-SSD` 131 L, `upgrade_framework` 103 L, `documentador` 101 L, `arquitecto` 96 L, `security-auditor` 95 L, `ssh-connection-agent` 85 L, `analista-tecnico` 82 L, `usuario-preferencias` 64 L, `developer` 22 L (modelo correcto).

#### FR-12 — Extracción de capacidades embebidas a skills

Las capacidades que hoy viven embebidas en el cuerpo de un agente y constituyen **procedimiento fijo** (sin criterio) MUST extraerse a una skill reutilizable.

Candidatos identificados por medición, con su evidencia:

| Agente origen | Cuerpo | Skill destino | Evidencia |
|---|---:|---|---|
| `gitflow` | 140 L | `git-workflow` | 7 bloques de operación git: Setup, Branch, Commit, Push, Revert, Rebase, PR |
| `ssh-connection-agent` | 85 L | `ssh-operations` | Política y procedimiento de conexión, sesión y servidores |
| `upgrade_framework` | 103 L | `dependency-upgrade` | Flujo de actualización de dependencias desde `proyect_ext/` |
| `analista-tecnico` | 82 L | `technical-research` | Herramientas y enfoque de investigación, sin criterio propio |

#### FR-13 — Declaración explícita de skills en el frontmatter

Todo agente que invoque skills MUST declararlas en el bloque `skills:` de su frontmatter. **Prohibido** describirlas solo en prosa en el cuerpo.

**Evidencia del defecto**: `Agent-SSD`, `arquitecto`, `security-auditor` y `documentador` tienen una sección `## Skills que utilizas` en prosa, pero su frontmatter declara `skills=0`. El runtime no carga lo que no está declarado.

| Agente | Skills a declarar |
|---|---|
| `Agent-SSD` | `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-converge`, `speckit-implement` |
| `arquitecto` | `architecture-decision-records`, `hexagonal-architecture`, `api-design`, `coding-standards` |
| `security-auditor` | `security-review`, `security-scan` **+ crear `threat-modeling`** |
| `documentador` | `knowledge-ops`, `documentation-lookup`, `coding-standards` |
| `pensador` | los 6 `speckit-*` + `architecture-decision-records` |

**Corrección (hallazgo H-04 de Analyze)**: `threat-modeling` **no existe** en el repositorio (verificado con `Test-Path` en ambos harnesses: `False`). Hay dos opciones y el implementador MUST elegir una y reportarla:

- **(a)** Crear la skill `threat-modeling` con el procedimiento de analysis STRIDE (preferido: el `security-auditor` ya produce threat models como output recurrente)
- **(b)** Sustituirla por una skill existente

Declarar una skill inexistente en el frontmatter MUST NOT ocurrir: el runtime no la carga y el agente queda sin la capacidad, en silencio.

**Verificación obligatoria (derivada T048)**: antes de escribir cualquier nombre de skill en un frontmatter, MUST verificarse con `Test-Path` que esa skill existe en `.opencode/skills/` y `.github/skills/`.

#### FR-14 — Consolidación de duplicación entre agentes

Los agentes con contenido duplicado MUST consolidarse.

**Evidencia**: `usuario-preferencias` y `ssh-connection-agent` comparten 5 secciones:

| `usuario-preferencias` | `ssh-connection-agent` |
|---|---|
| `## SSH Policy` | `## Connection Policy` |
| `## Server Configuration` | `## Server Configuration` |
| `## SSH Connection Procedure` | `## Connection Procedure (Mandatory)` |
| `## Session Management Rules` | `## Session Management` |
| `## Agent Roles` | `## Agent Roles` |

**Acción**: el **procedimiento** se consolida en la skill `ssh-operations` (FR-12). La **política** permanece en la capa de gobernanza (FR-16).

#### FR-15 — Hook de conventional commits

Toda regla que **no requiera decisión humana** MUST implementarse como hook o flow, no como procedimiento en un agente.

**Caso testigo**: el formato de conventional commits (hoy descrito en `gitflow.md`). Es verificable automáticamente y no requiere criterio.

#### FR-16 — `usuario-preferencias` como capa de gobernanza

`usuario-preferencias` MUST dejar de ser un agente par y pasar a ser **capa de gobernanza** transversal. Contiene la forma de trabajar del usuario: organización de proyectos, formato de documentación, políticas.

**Decisión del usuario (literal)**: *"es mi forma de hacer las cosas, cómo quiero organizar los proyectos, documentación y cómo se debe trabajar incluso el flujo de cómo crear las cosas"*.

MUST conservar la **política** (qué está permitido). MUST ceder el **procedimiento** (cómo se hace) a la skill correspondiente.

#### FR-17 — Eliminación de bloques comunes repetidos

Los bloques de contenido idéntico repetidos en los cuerpos de todos los agentes MUST extraerse a un único lugar de referencia.

**Evidencia**: 4 bloques aparecen en los 13 cuerpos: `Rol Scrum`, `Uso de MCPs`, `Ciclo de vida de specs` (marcador `LIFECYCLE-GLOSSARY-v1`), `Rol Scrum: Integración MCP` (marcador `MCP-ROLE-v1`).

**Reducción estimada**: ~40-60 líneas por agente.

#### FR-18 — Adelgazamiento de los cuerpos

El cuerpo de un agente MUST limitarse a: su rol, qué decide, qué skills invoca, sus constraints y su output. **Prohibido** incluir en el cuerpo el procedimiento que corresponde a una skill.

**Meta de referencia**: el estado del `developer` (22 líneas de cuerpo + 6 skills declaradas) es el modelo.

#### FR-19 — Whitelist contextual por capa y tipo de proyecto

La whitelist de escritura MUST resolverse por `(capa del agente, proyecto_tipo)`, no solo por tier.

**Regla de precedencia (hallazgo H-09 / SR-06 de Analyze)**: tier y capa son dimensiones **ortogonales**, no taxonomías alternativas.

- **Manda el tier** (tiene rango constitucional en Art. VII y está declarado en los 13 frontmatters)
- **La capa actúa como modificador contextual restrictivo**: nunca amplía
- **Fórmula**: `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`, con intersección restrictiva (fail-closed)

Evidencia de ortogonalidad: `arquitecto` (Documental/Orquestador) y `documentador` (Documental/Ejecutor) comparten tier y difieren capa; `developer` (Implementador/Ejecutor) y `documentador` (Documental/Ejecutor) comparten capa y difieren tier. Se dan ambos casos a la vez.

| Capa | Kit | Consumidor |
|---|---|---|
| Gobernanza | No escribe | No escribe |
| Orquestador | Solo su artefacto de fase | Su artefacto de fase |
| Ejecutor | Workspace completo (kit) | `src/<App>/`, `tests/`, scripts de la app |
| Operación | Sistemas, no paths | Sistemas, no paths |

**Clarificaciones**:
- `Operación` **no es un tier nuevo**: `solucionador` ya declara `tier: Plataforma`, cuya autoridad ("diagnóstico remoto y nivelación") cubre operar sistemas
- `Gobernanza` **sí tiene tier** (`usuario-preferencias` declara `Documental`); la capa lo acota a cero escritura. La regla de intersección lo resuelve sin cambiar el tier declarado
- `Agent-SSD` es **Orquestador** (de ejecución de herramienta) y conserva `tier: Documental extendido`; la capa no lo reclasifica

#### FR-20 — Perfil de whitelist estático y versionado

Los perfiles de whitelist MUST vivir en un **archivo de gobernanza estático y versionado** en `Documentacion/<App>/gobernanza/perfiles-whitelist.md`, con:

- Perfil `kit` y perfil `consumidor`
- Qué capa escribe qué en cada perfil
- La regla de precedencia `tier ∩ capa` de FR-19

**Fundamento (decisión del usuario)**: el KIT es el nacimiento; los demás consumen. Si el perfil viviera solo en el frontmatter de los agentes, se perdería al formatear el equipo o al reinstalar. **La fuente de verdad debe ser un documento versionado** que sobreviva a cualquier reinstalación y sea legible por un humano sin ejecutar nada.

#### FR-21 — Materialización del perfil por el bootstrap

Al instalar en un consumidor, el bootstrap MUST leer el perfil estático (FR-20) y **escribir** el bloque `permission` correspondiente en el frontmatter de cada agente del consumidor.

**El perfil estático es la fuente; el frontmatter es la aplicación.**

**Fundamento (hallazgo crítico SR-02 del threat model)**: escribir el acotamiento solo en el frontmatter tiene **vida de un sync** — el sync pisa el `.md` en la corrida siguiente y el límite se pierde. Por eso la materialización es un paso explícito del bootstrap, y el perfil vive en `Documentacion/` (que el sync nunca toca). Si el sync pisa el `.md`, el bootstrap se re-ejecuta y lo regenera.

**Verificación**: un paso de auditoría MUST comparar el frontmatter real del consumidor contra el perfil estático y reportar divergencias.

#### FR-22 — El perfil del consumidor no es editable

El archivo de perfil generado en el consumidor MUST ser de solo lectura para los agentes. Su edición MUST ser detectada.

**Fundamento (hallazgo SR-03)**: si el consumidor puede reescribir su perfil para declararse `kit`, obtiene permisos que no le corresponden. La combinación de FR-02b (re-validación del marcador) y esta regla cierra la vía.

### 4.1 Requisitos de whitelist contextual (alcance original, conservado)

### FR-01 — Marcador de tipo de proyecto

**Un** marcador explícito MUST declarar el tipo del proyecto con dos valores válidos: `kit` y `consumidor`. MUST persistirse en `.bootstrap-state.json` (archivo existente, ya escrito por el bootstrap) en una clave nueva `proyecto_tipo`.

**Por qué ese archivo**: ya existe, ya lo escribe el bootstrap, ya vive en la raíz del proyecto. Crear un archivo nuevo agrega superficie de propagación sin beneficio.

### FR-02 — Criterio de detección determinista

La determinación del tipo de proyecto MUST usar la función **`Test-IsMasterCheckout`**, que ya existe y es reusable en `scripts/plataformador-bootstrap.ps1` **L2064-2071**. Compara `git remote get-url origin` normalizado contra el `RepoUrl` del maestro normalizado.

- Si coinciden → `kit`
- Si no coinciden → `consumidor`

MUST normalizar de la misma forma que la función existente. **Nota de precisión (corregida en Analyze, H-03)**: el rango `L1867-1884` que citaba esta spec antes es donde la función se **usa**, no donde se **define**. La fuente reusable es `Test-IsMasterCheckout` L2064.

**Prohibido** inventar un criterio nuevo (por ejemplo, "existe `src/`") que contradiga el que ya corre. **Prohibido** reimplementar la comparación: se invoca la función existente.

### FR-02b — Re-validación del marcador al leer

El valor de `proyecto_tipo` MUST re-validarse al momento de usarse, no solo al escribirse. Un marcador que declara `kit` sin que `Test-IsMasterCheckout` lo confirme MUST tratarse como `consumidor` y MUST emitir WARN.

**Fundamento (hallazgo SR-03 del threat model)**: sin re-validación, un consumidor que edite `.bootstrap-state.json` y se declare `kit` obtiene la whitelist expandida sin detección. La re-validación cruza el marcador contra el origen git real.

### FR-03 — Ausencia de ambigüedad en el marcador

Si el marcador no puede determinarse (git no disponible, sin remote `origin`), el sistema MUST persistir `consumidor` y MUST emitir un WARN visible con la razón.

**Fundamento**: el valor seguro es el restrictivo. Un proyecto mal clasificado como `consumidor` solo pierde permisos que puede recuperar; uno mal clasificado como `kit` gana permisos que no debería tener. Fail-closed.

### FR-04 — Tabla de whitelist derivada

La whitelist efectiva de cada tier MUST derivarse de `(tier, proyecto_tipo)`, no solo del tier.

| Tier | `proyecto_tipo = kit` | `proyecto_tipo = consumidor` |
|---|---|---|
| **Documental** | `Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | `Documentacion/<App>/` únicamente |
| **Documental extendido** | `src/<App>/.specify/`, `Documentacion/<App>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | igual que kit, dentro de su app |
| **Implementador** | **workspace completo** | `src/<App>/`, `tests/`, scripts de la app |
| **Tooling** | ramas, commits, PRs, merges, reverts | igual |
| **Plataforma** | diagnóstico remoto y nivelación | igual |

### FR-05 — Expansión del tier Implementador en el kit

En un proyecto con `proyecto_tipo = kit`, el agente `developer` MUST poder escribir en todo el workspace del repositorio.

**Fundamento**: en el kit, el workspace **es** el producto. Los scripts, los agentes, las skills y la configuración no son infraestructura de una app: son el entregable. Acotar al `developer` a `src/` dejaría el kit sin agente implementador.

### FR-06 — Acotamiento del tier Implementador en consumidores

En un proyecto con `proyecto_tipo = consumidor`, el agente `developer` MUST limitarse a `src/<App>/`, `tests/` y los scripts de su aplicación. MUST NOT escribir en `.github/`, `.opencode/`, `.doc_agents/`, `scripts/` del kit ni `Documentacion/<OtraApp>/`.

**Fundamento**: en un consumidor, el kit transversal lo gobierna el `sync`, no el implementador. Que el `developer` toque los agentes locales rompe la política de merge-no-mirror.

### FR-07 — Anti-fuga en la propagación

El mecanismo de propagación (`sync-agents.ps1` y el motor de sync) MUST garantizar que un consumidor **nunca** reciba `proyecto_tipo = kit`.

Formas aceptables de cumplirlo:

- El marcador **no** forma parte de los archivos propagados, y el consumidor lo calcula localmente con FR-02
- El sync fija el marcador a `consumidor` en destino como paso explícito

Formas **prohibidas**:

- Propagar el `.bootstrap-state.json` del maestro tal cual (arrastra `kit`)
- Escribir la whitelist expandida en el texto de `developer.md` (el `.md` se propaga)

### FR-08 — Resolución `task → agente dueño`

El `pensador` MUST resolver el agente dueño de una task **antes** de asignarla, aplicando esta secuencia:

1. Leer `proyecto_tipo` del marcador
2. Determinar el path objetivo de la task
3. Consultar la tabla de FR-04
4. Asignar al tier que tiene ese path en su whitelist
5. Registrar la asignación en `pendientes-implementacion.md`

**Prohibido** asignar por intuición o por el nombre del agente. Si la tabla no resuelve, el `pensador` MUST detenerse y pedir la decisión al usuario.

### FR-09 — Escalado obligatorio ante denegación de permiso

Ante `Permission denied` al escribir un path, el `pensador` MUST:

1. **Detenerse** (no reintentar)
2. Identificar el tier dueño de ese path con FR-08
3. **Delegar** la escritura a ese agente
4. Reportar al usuario la delegación

**Prohibido** reintentar la escritura por una vía alternativa (shell, script auxiliar, comando inline). La vía alternativa evade el límite sin cambiar quién es el dueño.

### FR-10 — Paridad entre harnesses

Todo cambio en `.github/agents/` MUST tener su equivalente en `.opencode/agents/` y viceversa, en la misma ronda. Se aplica a:

- La sección de whitelist contextual
- La regla de escalado de FR-09
- El circuito de resolución de FR-08

### FR-11 — Enmienda de Art. X

El Art. X de la constitution (`Documentacion/Agents_IA_TECH/.specify/constitution.md`) MUST ampliarse para declarar explícitamente que:

- En el kit, la whitelist del tier Implementador se expande al workspace completo
- Esa expansión es una consecuencia del tipo de proyecto, no una excepción del tier
- El límite efectivo se resuelve contra `proyecto_tipo`

Estado actual: Art. X dice "no existe `src/<App>/`" pero **no** dice qué implica eso para los permisos. Ese silencio es el hueco que origina esta spec.

---

## 5. Requisitos no funcionales

### NFR-01 — Determinismo

La resolución de whitelist MUST ser determinista: dadas las mismas entradas (`tier`, `proyecto_tipo`, path objetivo), la respuesta MUST ser siempre la misma. Sin heurísticas, sin juicio del agente, sin ramas por tipo de archivo.

### NFR-02 — Cero regresiones en el motor de sync

`scripts/sync-kit.ps1` no MUST romperse. `Parser::ParseFile` MUST seguir devolviendo **0 errores** (estado al 2026-10-29).

### NFR-03 — Cero regresiones en el bootstrap

`scripts/plataformador-bootstrap.ps1` no MUST romperse. `Parser::ParseFile` MUST seguir devolviendo **0 errores**.

### NFR-04 — Fail-closed en la detección

Ante imposibilidad de determinar el tipo de proyecto, el sistema MUST elegir el valor restrictivo (`consumidor`) con WARN visible. Nunca `kit` por defecto.

### NFR-05 — Auditable

El valor efectivo de `proyecto_tipo` MUST ser visible al operador: registrado en el log del bootstrap y legible en `.bootstrap-state.json`.

### NFR-06 — Sin rutas absolutas

El marcador y su lógica MUST NOT contener rutas absolutas de usuario. Aplica la restricción de Genericidad de la constitution.

---

## 6. Criterios de aceptación

| ID | Criterio | Método de verificación |
|---|---|---|
| **CA-01** | `.bootstrap-state.json` del kit contiene `"proyecto_tipo": "kit"` | Lectura del archivo tras correr el bootstrap |
| **CA-02** | Un consumidor de prueba recibe `"proyecto_tipo": "consumidor"` | Sandbox: clonar a `$env:TEMP`, correr bootstrap, leer el marcador |
| **CA-03** | El marcador del kit **no** se copia literalmente a un consumidor | Verificar que el consumidor calculó el suyo; `git diff` del `.bootstrap-state.json` del consumidor no muestra `"kit"` |
| **CA-04** | En kit, `developer` puede escribir en `scripts/`, `.github/`, `.opencode/`, `Documentacion/` | Ejecución real de una escritura desde `developer` en cada ruta |
| **CA-05** | En consumidor, `developer` recibe `Permission denied` en `.github/agents/` | Ejecución real desde `developer` en un consumidor simulado |
| **CA-06** | Ante `Permission denied`, el `pensador` delega y no reintenta | Inspección de la definición de `pensador` en ambos harnesses |
| **CA-07** | La resolución `task → agente` usa la tabla, no criterio propio | Inspección de `pensador.md` y `pensador.agent.md`: la secuencia de FR-08 está presente |
| **CA-08** | Art. X declara la expansión del Implementador en el kit | Lectura de `constitution.md`, Art. X |
| **CA-09** | `.github/` y `.opencode/` tienen las mismas reglas | Diff de las secciones afectadas en los pares de agentes |
| **CA-10** | `sync-kit.ps1` sigue con 0 errores de parseo | `Parser::ParseFile` |
| **CA-11** | `plataformador-bootstrap.ps1` sigue con 0 errores de parseo | `Parser::ParseFile` |
| **CA-12** | Ante git no disponible, el marcador queda en `consumidor` con WARN | Sandbox sin `origin` configurado |

---

## 7. Supuestos

| ID | Supuesto | Si resulta falso |
|---|---|---|
| **A-01** | El criterio L1867-1884 del bootstrap distingue correctamente kit de consumidor | Se necesita un criterio adicional; la spec se reabre |
| **A-02** | `.bootstrap-state.json` es escribible por el bootstrap en todos los proyectos | Se necesita otro archivo; FR-01 se amplía |
| **A-03** | Los agentes pueden leer el marcador sin costo significativo | Si requiere ejecutar git en cada invocación, se cachea |
| **A-04** | El `sync` no propaga `.bootstrap-state.json` o lo hace de forma controlada | FR-07 exige el paso explícito de fijar `consumidor` |

---

## 8. Dependencias

| ID | Dependencia | Estado |
|---|---|---|
| **DEP-01** | `plataformador-bootstrap.ps1` L1867-1884 (criterio de detección) | Existe, en producción |
| **DEP-02** | `.bootstrap-state.json` | Existe, con `{lastUpdate, tools}` |
| **DEP-03** | Art. X de la constitution nivel 2 | Existe, v2.1.0 con Art. X incompleto |
| **DEP-04** | Definiciones de `pensador` y `developer` en ambos harnesses | Existen, 14 agentes por harness |
| **DEP-05** | `sync-kit.ps1` reparado | ✅ 2026-10-29, ParseFile 0 errores |

---

## 9. Riesgos

| ID | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| **R-01** | El marcador se filtra igual a consumidores por una ruta no prevista | Un consumidor obtiene permisos de kit | FR-07 + CA-03 verifican el caso |
| **R-02** | La expansión del `developer` en kit permite tocar un consumidor alojado en submódulo | Daño cruzado | Verificar que no haya submódulos antes de implementar |
| **R-03** | La enmienda de Art. X contradice otra parte de la constitution | Inconsistencia documental | El `analista` de Analyze cruza Art. VII, X y la tabla de tiers |
| **R-04** | Los agentes quedan sin leer el marcador y siguen usando la whitelist plana | El defecto persiste sin síntomas | CA-06 y CA-07 verifican la definición, no el comportamiento |
| **R-05** | El criterio de detección falla con remote `origin` ausente en el kit | El kit se clasifica como consumidor | FR-03 + CA-12 lo cubren con WARN |

---

## 10. Trazabilidad — Origen de cada requisito

| FR | Origen | Evidencia |
|---|---|---|
| FR-01 | Diseño nuevo | `.bootstrap-state.json` medido |
| FR-02 | Reúso | `plataformador-bootstrap.ps1` L1867-1884 |
| FR-03 | NFR-04 (fail-closed) | Art. VIII de la constitution |
| FR-04 | F-02 (asignación errónea) | 3 asignaciones equivocadas el 2026-10-29 |
| FR-05 | Corrección del usuario | "developer debería poder modificar todo el workspace" |
| FR-06 | Corrección del usuario | "en los demás donde se despliega el KIT no" |
| FR-07 | Audit log | `Generator_IA_Projects` con escrituras indebidas |
| FR-08 | F-03 (sin circuito de resolución) | Ausente en `pensador.md` L404-410 |
| FR-09 | F-01 (evasión por shell) | `Permission denied` evadido el 2026-10-29 |
| FR-10 | F-05 (asimetría de harnesses) | `pensador.md` 523 líneas vs `.agent.md` 533 |
| FR-11 | Art. X incompleto | `constitution.md` L196+ |

---

## 11. Spec linking

| Artefacto | Ruta relativa |
|---|---|
| Plan | [`plan.md`](./plan.md) |
| Tasks | [`tasks.md`](./tasks.md) |
| Analyze | [`analyze.md`](./analyze.md) |
| Threat model | [`threat-model.md`](./threat-model.md) |
| Constitution | [`../../.specify/constitution.md`](../../.specify/constitution.md) |
| Bootstrap | `scripts/plataformador-bootstrap.ps1` |
| Motor de sync | `scripts/sync-kit.ps1` |
| Backlog | [`../../pendientes-implementacion.md`](../../pendientes-implementacion.md) |
| Spec predecesora | [`../029-sync-eol-y-force-real/spec.md`](../029-sync-eol-y-force-real/spec.md) |

---

*Especificado por `pensador` — Spec 030, fase Specify — 2026-10-29.*
