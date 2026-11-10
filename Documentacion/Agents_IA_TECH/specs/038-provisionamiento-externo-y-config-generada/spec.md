# Spec 038 — Aprovisionamiento externo por tipo y configuración generada

**Feature Branch**: `038-provisionamiento-externo-y-config-generada`

**Created**: 2026-11-07

**Status**: Borrador — pendiente de aprobación para pasar a `plan.md`

**Input**: Decisión del usuario (2026-11-07): controlar instalación y actualización de las dependencias de `proyect_ext` **según su tipo**, detectar si están al día, y dejar de versionar `opencode.json` para generarlo desde una fuente única, con un segundo generador para GitHub Copilot y paridad verificada entre ambos.

## Ubicación

`Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/`

## Decisiones de arquitectura del usuario (2026-11-07)

| # | Decisión | Consecuencia en esta spec |
|---|---|---|
| D1 | **Autoridad de versión de `kit-integrado` = branch head** (commit más reciente de la rama seguida), no release tag | Se comparan SHA, no semver. El versionado por release tag + semver queda en backlog, atado al instalador del KIT |
| D2 | **`opencode.json` no se versiona**: se versiona plantilla + generador. Un generador para OpenCode y otro para GitHub Copilot, que deben mantenerse sincronizados | Se agrega `scripts/mcp/generate-opencode.ps1`, `scripts/mcp/generate-copilot.ps1` y `scripts/mcp/validate-parity.ps1`; `opencode.json` pasa a `.gitignore` |
| D3 | **El clon de ECC y spec-kit se descarga en `proyect_ext/` e integra al KIT de forma manual** | Ningún `AGENTS.md` de un clon externo puede quedar en una ruta que el arnés cargue como instrucciones |
| D4 | **La integración de `kit-integrado` es asistida por IA, no un script de copia** | Esta spec se limita a aprovisionar y detectar; el proceso de integración es la spec 039 |
| D5 | Toda diferencia de capacidad entre arneses **se declara con fuente y versión**; una diferencia no declarada es FAIL | Artefacto `capacidades-por-harness.md` + validador de paridad |

## Problema y evidencia

El estado real del repositorio hoy contradice lo que el repositorio declara. Evidencia recolectada el 2026-11-07:

| Hecho | Evidencia |
|---|---|
| `context-mode` está declarado contra un binario que no existe | `opencode.json` apunta a `.../context-mode/build/cli.js`; la versión instalada 2.1.0 tiene `cli.mjs`, `server.mjs` y `opencode/plugin.js`, sin `build/` ni `cli.js` |
| El manifest declara versiones que nadie verifica | `dependencias-manifest.yml` declara `context-mode` v1.0.169 (instalado: 2.1.0) y `spec-kit` `v0.0.0` con `ultimo_check 2026-09-05` |
| El manifest omite dependencias que el arnés sí carga | ECC, context7, playwright y github no figuran como dependencia declarada, aunque existen en `opencode.json` |
| `git status` no sirve como sonda de actualización | Los tres clones responden `main...origin/main` sin divergencia, comparando contra refs locales; spec-kit está en `1.0.7.dev0` frente al release `v1.3.2` del 2026-11-06 |
| Dos formas de configuración conviven | `opencode.json` usa `mcp.servers`; `Ensure-OpenCodeMcp` y `Configure-Graphify` del bootstrap escriben la forma plana `mcp.<nombre>`; `run-indexing.ps1` registra `graphify` en forma plana |
| El clon de `kit-integrado` contamina el contexto de la sesión | `proyect_ext/ECC/AGENTS.md` y `proyect_ext/spec-kit/AGENTS.md` se inyectan como instrucciones de sesión |
| La capacidad declarada no coincide con la instalada | `MCPs/context-mode.md` §4.2 documenta `.github/hooks/context-mode.json`; `.github/hooks/` no existe |

El patrón común: **el repositorio declara, la máquina no verifica**. Esta spec convierte la declaración en un gate.

## Objetivo

Que cualquier workspace gestionado por el kit pueda responder, con un comando de solo lectura y un código de salida:

1. ¿Qué dependencias externas requiere este proyecto y de qué tipo son?
2. ¿Están instaladas y en la versión/commit esperado?
3. ¿La configuración del arnés (`opencode.json`, `.vscode/mcp.json`) refleja la realidad de esta máquina y no una declaración vieja?
4. ¿Qué diferencia de capacidad existe entre arneses, y está declarada?

Y que la configuración de los arneses se **genere** desde esa fuente, en vez de mantenerse a mano.

## Alcance

- Taxonomía de aprovisionamiento por tipo y su declaración obligatoria en el manifest.
- Sondas de versión declarativas por tipo, con `branch head` como autoridad para código de terceros integrado.
- Estado por workspace (`.opencode/mcp-state.json`, no versionado).
- Tres verbos con contratos separados: `validate` (solo lectura, exit code), `apply` (instalación/actualización explícita, fail-open), `generate` (escritura de configuración).
- Generación de `opencode.json` y `.vscode/mcp.json` desde una fuente única + validador de paridad.
- Matriz de capacidades por arnés con cuatro estados y fuente obligatoria.
- Aislamiento del clon de `kit-integrado` en `proyect_ext/` e integración manual al KIT.
- Documento de referencia con la matriz de sondas y comandos por tipo.

**Fuera de alcance** (registrado en `pendientes-implementacion.md`, no en esta spec):

- Versionado semántico por release tag y tags firmados.
- El proceso de integración de código de terceros al kit (inventario diferencial, evaluación, libro mayor, lista negra) → spec 039.
- La **corrección** de las cuatro inconsistencias que la matriz declara (delegación anidada, hooks de sesión, superficie de subagentes en runtime, frontmatter de Copilot) → specs 040 a 043, una por inconsistencia.
- Instalador único del KIT (`plataforma-bootstrap-instalador-unico`).
- Evaluación con respuestas reales del LLM.

**Regla de corte**: una spec atiende **un** error de diseño o de implementación. 038 deja la declaración y el gate; no arregla el comportamiento de ninguno de los cuatro casos que declara.

## Glosario: tipos de aprovisionamiento

| Tipo | Definición | Dependencias actuales | Autoridad de versión |
|---|---|---|---|
| `kit-integrado` | Código de terceros que se **integra de forma controlada** dentro del kit (no se copia tal cual, no se ejecuta desde el clon) | ECC | branch head (`git ls-remote`) del repo de origen |
| `kit-fuente` | Código de terceros que se **consume como fuente/herramienta** (CLI, plantillas) y se actualiza desde su repo | spec-kit | branch head del repo de origen; el clon puede estar en una rama o en un tag |
| `mcp-workspace` | Servidor MCP que se instala **por workspace** y se configura en el arnés | context-mode, codebase-memory-mcp, markitdown, graphify, context7, github, playwright | registro del gestor de paquetes (npm/PyPI) o release del binario |
| `mcp-build-local` | Servidor MCP cuyo binario se **compila** desde un clon local | tokenslayer | release del repo de origen + verificación del artefacto compilado |
| `entorno` | Runtime o herramienta base que no es dependencia del arnés | Node, Python, PowerShell, git | gestor del sistema |

Un tipo desconocido o ausente **no se asume**: es FAIL de `validate` (FR-02).

## User Scenarios & Testing

### US-1 — Detectar configuración mentirosa antes de abrir la sesión (P1)

Como operador del kit, quiero correr un comando de solo lectura que me diga si la configuración del arnés apunta a binarios que existen, antes de iniciar una sesión y descubrir el fallo en caliente.

**Why this priority**: es el defecto activo. `context-mode` está roto en este repositorio y nadie lo detectó hasta que el MCP falló. Sin esto, las otras historias no tienen gate.

**Independent Test**: ejecutar `validate` sobre un workspace con la entrada `context-mode` apuntando a `build/cli.js` inexistente y verificar que reporta `FAIL`, identifica el servidor, el comando declarado y el motivo, y devuelve exit code distinto de cero.

**Acceptance Scenarios**:

1. **Given** un `opencode.json` con una entrada `mcp.servers.X.command` que no resuelve en el sistema de archivos, **When** se ejecuta `validate`, **Then** el resultado incluye una fila `X` con estado `missing`, el comando declarado y exit code ≠ 0.
2. **Given** un `opencode.json` con todas las entradas resolubles y al día, **When** se ejecuta `validate`, **Then** el resultado es `ok` en todas las filas y exit code 0.
3. **Given** un `opencode.json` que no existe, **When** se ejecuta `validate`, **Then** reporta `absent` como estado propio (no como FAIL de servidor) y exit code ≠ 0.
4. **Given** una ejecución de `validate`, **When** termina, **Then** ningún archivo del workspace fue modificado (mtime sin cambios).

### US-2 — Generar la configuración del arnés desde la realidad de la máquina (P1)

Como operador, quiero que `opencode.json` y `.vscode/mcp.json` se generen desde el manifest más el estado real, para que no vuelva a existir una entrada declarada contra un binario inexistente.

**Why this priority**: elimina la causa raíz del defecto; el archivo versionado es la razón por la que una ruta absoluta de otra máquina sobrevive meses.

**Independent Test**: en un workspace sin `opencode.json`, ejecutar `generate` y verificar que produce un archivo válido con las entradas cuyo binario resuelve y que omite, con WARN, las que no.

**Acceptance Scenarios**:

1. **Given** el estado con `context-mode` marcado `missing`, **When** se ejecuta `generate`, **Then** la entrada `context-mode` **no** se escribe en `opencode.json` y se emite un WARN que la nombra.
2. **Given** los mismos datos, **When** se ejecuta `generate` dos veces, **Then** el segundo archivo es idéntico al primero (idempotencia byte a byte).
3. **Given** un `opencode.json` generado y un `.vscode/mcp.json` generado, **When** se ejecuta `validate-parity`, **Then** ambos exponen el mismo conjunto de servidores y la misma forma canónica.
4. **Given** una clave no generable por el arnés (por ejemplo `permission` con globs de path en Copilot), **When** se genera el archivo de ese arnés, **Then** la clave se omite y la matriz de capacidades la declara como `no-soportado` o `equivalente-distinto`.

### US-3 — Saber si el código de terceros integrado está al día (P2)

Como responsable del kit, quiero saber si `main` del repositorio de origen avanzó desde el commit que integre, sin comparar versiones semánticas.

**Why this priority**: habilita el disparador de la spec 039. Sin esta señal, la integración manual se hace a ciegas o nunca.

**Independent Test**: sobre un clon con `HEAD` conocido y un remoto con commits posteriores, ejecutar la sonda y verificar que reporta `desactualizado` con el SHA local, el SHA remoto y la fecha de consulta.

**Acceptance Scenarios**:

1. **Given** un clon cuyo `HEAD` coincide con `refs/heads/main` remoto, **When** se consulta, **Then** el estado es `al-dia` y se registran `ultimo_sha` y `ultimo_check`.
2. **Given** un clon cuyo `HEAD` difiere del remoto, **When** se consulta, **Then** el estado es `desactualizado`, se listan ambos SHA y se registra la rama seguida.
3. **Given** ausencia de red o remoto inaccesible, **When** se consulta, **Then** el estado es `desconocido` con WARN, no `al-dia` ni FAIL silencioso.
4. **Given** un clon en `HEAD` detached o shallow, **When** se consulta, **Then** la sonda no falla por esa condición y reporta la condición detectada.

### US-4 — Actualizar sin contaminar el contexto del agente (P2)

Como responsable del kit, quiero que el clon de una dependencia `kit-integrado` o `kit-fuente` se descargue en `proyect_ext/` y se integre al KIT de forma manual, de modo que sus `AGENTS.md` dejen de inyectarse como instrucciones de la sesión.

**Why this priority**: hoy la sesión recibe instrucciones de dos repositorios de terceros. Es contaminación activa del contexto, no un riesgo teórico.

**Independent Test**: ejecutar la actualización y verificar que (a) el clon se actualizó, (b) no existe ningún `AGENTS.md`, `CLAUDE.md` ni `.mcp.json` de ese clon bajo la raíz del workspace, y (c) la sesión no incorpora instrucciones nuevas desde esas rutas.

**Acceptance Scenarios**:

1. **Given** un clon dentro de la raíz del workspace, **When** se ejecuta la migración, **Then** el clon se mueve a `proyect_ext/`, se registra la ruta nueva en el estado y se emite evidencia de la ruta anterior.
2. **Given** un clon en `proyect_ext/`, **When** se ejecuta la actualización, **Then** solo se ejecutan operaciones git sobre el clon; ningún archivo se copia al kit.
3. **Given** que la actualización falla (red, permisos, conflicto), **When** termina, **Then** el estado queda `degraded` con la causa, y el workspace sigue operable.

### US-5 — Publicar la diferencia de capacidades entre arneses (P3)

Como responsable del kit, quiero una matriz que declare qué capacidad tiene cada arnés, con fuente y versión, para que una limitación se documente una vez y no reaparezca como bug en cada sincronización.

**Why this priority**: el kit sostiene dos arneses con contratos distintos. Sin matriz, la paridad se convierte en supuestos (y en afirmaciones falsas, como la de "Copilot no tiene subagentes").

**Independent Test**: ejecutar el validador de capacidades sobre una matriz incompleta y verificar que emite FAIL por capacidad usada en un agente pero no declarada.

**Acceptance Scenarios**:

1. **Given** un agente del kit que usa `mode: subagent` y una matriz que no declara la capacidad de subagentes, **When** se valida, **Then** el resultado es FAIL indicando capacidad, agente y arnés.
2. **Given** una capacidad declarada `equivalente-distinto`, **When** se valida, **Then** la matriz contiene el mapeo explícito entre la clave de un arnés y la del otro.
3. **Given** una capacidad declarada `soportado-con-limite`, **When** se valida, **Then** la fila cita fuente y versión del límite.
4. **Given** una fila con estado `no-soportado`, **When** se genera la configuración de ese arnés, **Then** la clave no se emite y el WARN la referencia.

## Requirements

### Funcionales

**FR-01 — Taxonomía declarada.** Toda dependencia externa del proyecto declara `tipo_provisionamiento` con uno de los cinco valores del glosario. El manifest es la única fuente: no se infiere el tipo por ruta ni por extensión.

**FR-02 — Tipo ausente o desconocido = FAIL.** `validate` devuelve FAIL y nombra la dependencia cuando `tipo_provisionamiento` falta o no pertenece a la taxonomía. No se asume un tipo por defecto.

**FR-03 — Sonda de versión declarativa.** Cada dependencia declara cómo se determina su versión: `version.autoridad` (`branch-head` para `kit-integrado` y `kit-fuente`; `gestor-paquetes` para `mcp-workspace`; `release+artefacto` para `mcp-build-local`; `runtime` para `entorno`), `archivo_local` y `campo_local` cuando corresponda, `repo_url`, `rama_seguida` y `upstream_api`. La sonda es de solo lectura.

**FR-04 — Comparación por SHA para código de terceros.** Para `kit-integrado` y `kit-fuente`, el estado se calcula comparando `git rev-parse HEAD` del clon contra `git ls-remote <repo_url> refs/heads/<rama_seguida>`. Se registran `rama_seguida`, `ultimo_sha`, `sha_remoto` y `ultimo_check`. No se compara semver ni se usa `git status` como sonda.

**FR-05 — Estado por workspace.** El resultado de toda sonda se persiste en `.opencode/mcp-state.json` (no versionado), con una entrada por dependencia que contenga: `tipo`, `requerido`, `comando_resuelto`, `version_instalada`, `version_ultima`, `fuente`, `estado`, `ultimo_check` y, cuando aplique, `rama_seguida` y `ultimo_sha`. El archivo se escribe de forma atómica (temporal + reemplazo).

**FR-06 — Verbo `validate`.** Solo lectura, sin escritura de archivos del proyecto ni de configuración, salvo el propio estado. Devuelve tabla legible y exit code: `0` todo requerido presente y al día; `≠0` al menos un requerido ausente, degradado o con tipo inválido. Un opcional ausente es WARN y no cambia el exit code.

**FR-07 — Verbo `apply`.** Instala o actualiza solo con invocación explícita. Fail-open: un fallo por dependencia deja `estado: degraded` con la causa, emite WARN y no aborta el resto. Nunca se ejecuta como efecto secundario de `validate` ni de `generate`.

**FR-08 — Verbo `generate`.** Escribe la configuración del arnés desde el estado. Regla dura: **solo se emiten entradas cuyo binario resuelve**. Una dependencia con `estado: missing` no se escribe y se emite WARN con su nombre y el comando declarado.

**FR-09 — Generación dual desde una fuente única.** `scripts/mcp/generate-opencode.ps1` produce `opencode.json` y `scripts/mcp/generate-copilot.ps1` produce `.vscode/mcp.json`, ambos desde el manifest + el estado. `scripts/mcp/validate-parity.ps1` compara los dos archivos generados y falla si el conjunto de servidores o sus nombres difieren.

**FR-10 — `opencode.json` no versionado.** El repositorio versiona la plantilla (estructura, `default_agent`, `permission`, `plugin`) y el generador; el archivo final entra en `.gitignore`. El generador preserva las claves del usuario que no son `mcp.servers` y no inventa valores.

**FR-11 — Forma canónica única.** Toda escritura de configuración usa `mcp.servers.<nombre>`. La forma plana `mcp.<nombre>` se considera legacy: ningún script la escribe y `validate` la reporta como FAIL con la ruta y la línea. Quedan alcanzados por esta regla `Ensure-OpenCodeMcp`, `Configure-Graphify`, `sync-mcp-graphify.ps1` y `run-indexing.ps1`.

**FR-12 — Declaración de `requerido` por MCP.** El manifest del proyecto marca `requerido: true|false` por servidor. `validate` devuelve FAIL si falta uno requerido y WARN si falta uno opcional. El estado persiste el valor para que la política no dependa del contexto de ejecución.

**FR-13 — Aislamiento del clon.** Los clones de `kit-integrado` y `kit-fuente` se descargan en `proyect_ext/` y se integran al KIT de forma manual. La ruta se declara en el manifest y en el estado. `validate` falla si un clon declarado queda dentro de la raíz o si existe un `AGENTS.md`, `CLAUDE.md` o `.mcp.json` de ese clon bajo la raíz.

**FR-14 — Actualización sin copia.** El verbo de actualización de `kit-integrado` y `kit-fuente` ejecuta únicamente operaciones git sobre el clon (fetch/reset según el tipo y la rama seguida) y actualiza el estado. No copia, no sincroniza y no escribe archivos dentro del kit: la integración es la spec 039.

**FR-15 — Matriz de capacidades por arnés.** Se versiona `Documentacion/Agents_IA_TECH/capacidades-por-harness.md`. Cada fila documenta una capacidad y lleva estas columnas obligatorias: capacidad, mecanismo en OpenCode, mecanismo en Copilot, estado de la capacidad (`soportado`, `equivalente-distinto`, `soportado-con-limite`, `no-soportado`), fuente (documentación o issue), versión verificada, prueba y spec responsable.

Se denomina **inconsistencia** a toda diferencia verificada entre lo que el kit declara o asume y lo que el arnés confirma: una capacidad declarada que no está instalada, un mecanismo documentado que no existe en el runtime, o dos arneses que no ofrecen el mismo mecanismo para la misma capacidad.

El estado de corrección de cada inconsistencia no se guarda en una columna propia: se deduce de `spec_responsable` y `prueba`.

| Situación de la fila | Estado deducido | Acción del validador |
|---|---|---|
| `spec_responsable` vacío | Documentada, sin spec que la corrija | WARN: la inconsistencia está declarada y ninguna spec la va a corregir |
| `spec_responsable` con valor y `prueba` vacía | En trabajo | Sin acción: hay una spec responsable |
| `spec_responsable` con valor y `prueba` completa | Corregida | Sin acción: la prueba demuestra el cierre |

Reglas de validación:

1. Si un agente del kit usa una capacidad que no aparece en la matriz, `validate-parity` devuelve FAIL: es una diferencia no declarada.
2. Si una fila no tiene `spec_responsable`, `validate-parity` devuelve WARN: la inconsistencia está documentada, pero ninguna spec la va a corregir.
3. Si una fila tiene `spec_responsable` y `prueba` vacía, no hay error ni advertencia: está en trabajo.
4. El generador no emite una clave cuyo estado de capacidad sea `no-soportado` y `validate-parity` la reporta como WARN, nunca en silencio.

Esta spec **declara y valida** la matriz; **no corrige** las inconsistencias que declara. Cada una se atiende en su propia spec, con su propio error de diseño o implementación (ver "Inconsistencias declaradas").

**FR-16 — Build local verificable.** Para `mcp-build-local`, `apply` ejecuta fetch del tag o rama, checkout, instalación de dependencias y build; el estado solo pasa a `ok` si el artefacto declarado existe después del build. Un build fallido deja `degraded` y `generate` omite la entrada.

**FR-17 — Documento de referencia.** Se versiona `Documentacion/Agents_IA_TECH/provisionamiento-externo.md` con la matriz de sondas por tipo (cómo se detecta instalado, cuál es la última, cómo se actualiza), los comandos concretos y el contrato de exit codes.

### Inconsistencias declaradas que esta spec no corrige

Las cuatro inconsistencias siguientes se atienden en **cuatro specs distintas**. 038 las declara en la matriz (FR-15) y verifica que la declaración exista; no toca el diseño ni la implementación de ninguna. Se registran aquí para no perder el detalle al separarlas.

| # | Inconsistencia | Evidencia | Estado de la capacidad | Spec responsable | Por qué no entra en 038 |
|---|---|---|---|---|---|
| 1 | **Delegación anidada en OpenCode** | `subagent_depth` default 1; el spec archivado `018-pensador-delegation-fix` registra el issue #8114: en ciertas versiones ningún subagente puede invocar otro. El kit asume delegación de un solo nivel (Pensador → todos) | `soportado-con-limite` | 040 | Es límite del tool, con tope y versión a citar. Corregirlo exige cambiar el modelo de delegación del kit, no la configuración del arnés |
| 2 | **Hooks de sesión no instalados** | `specs/012-ecc-integration/matriz-comparacion.md` dice "Sin hooks de sesión"; `.github/hooks/` no existe en disco, aunque `MCPs/context-mode.md` §4.2 documenta crearlo | `no-soportado` (en el kit, no en el arnés) | 041 | Es capacidad declarada y nunca instalada. Instalarla cambia gobernanza, permisos y el contrato de sesión: tiene su propio threat model |
| 3 | **Superficie de subagentes en el runtime** | El `subagent` de esta sesión expone solo `explore` y `general`; bitácora del 2026-11-05. Es la superficie del tool en este runtime, no el modelo de agentes; `developer` sí es delegable en OpenCode real porque `mode` sin declarar vale `all` | `equivalente-distinto` | 042 | Es configuración del runtime anfitrión, no del kit. 038 solo puede declarar la diferencia |
| 4 | **Paridad de frontmatter con Copilot** | Copilot no tiene `mode: primary/subagent` ni `permission` con globs: la paridad de frontmatter es imposible | `equivalente-distinto` + `no-soportado` por clave | 043 | Exige definir la paridad a nivel de capacidad y reescribir el frontmatter de los 14 agentes; es un cambio de modelo de agentes, no de aprovisionamiento |

**Lección que queda escrita**: la lección no es "Copilot no puede". Es **capacidad declarada ≠ capacidad instalada**. Los dos defectos que originan esta spec son el mismo patrón: la entrada `context-mode` declarada contra un binario inexistente y los hooks documentados sin `.github/hooks/`. Por eso `validate` compara **declaración contra realidad**, nunca declaración contra declaración.

### No funcionales

**NFR-01 — Solo lectura por defecto.** `validate` no escribe archivos del proyecto, configuración de arneses ni clones. Solo actualiza `.opencode/mcp-state.json`.

**NFR-02 — Idempotencia.** Dos ejecuciones consecutivas de `generate` producen archivos byte a byte idénticos. Dos ejecuciones de `apply` sobre dependencias al día no cambian nada y no emiten warnings nuevos.

**NFR-03 — Escritura atómica.** Toda escritura de configuración usa archivo temporal en el mismo directorio + reemplazo. Una interrupción no deja un archivo truncado.

**NFR-04 — Sin secretos en artefactos.** Ni el estado ni los archivos generados contienen tokens, claves ni rutas de credenciales. Las variables de entorno se referencian por nombre.

**NFR-05 — Fail-open, nunca fail-silent.** Todo fallo de sonda, red o instalación produce estado explícito (`degraded` / `desconocido`) y WARN con causa. Nunca se reporta `ok` sin evidencia.

**NFR-06 — Portabilidad de rutas.** Las rutas absolutas de la máquina viven solo en el estado no versionado y en los archivos generados no versionados. El manifest y la plantilla usan rutas relativas o nombres de comando resolubles.

**NFR-07 — Tiempo de `validate`.** La sonda completa sobre las dependencias actuales termina en menos de 60 segundos con red disponible; sin red, degrada a `desconocido` en menos de 15 segundos y no bloquea la sesión.

**NFR-08 — Paridad de arneses.** Todo cambio en la plantilla o en el generador de un arnés se refleja en el otro en la misma tarea, o queda declarado como `no-soportado` en la matriz.

## Key Entities

### `dependencias-manifest.yml` — entrada de dependencia

```yaml
dependencias_externas:
  - nombre: ECC
    tipo_provisionamiento: kit-integrado
    requerido: false
    repo_url: https://github.com/affaan-m/ECC
    rama_seguida: main
    ruta_local: proyect_ext/ECC        # descarga en proyect_ext/ e integración manual al KIT
    version:
      autoridad: branch-head
      archivo_local: VERSION
      campo_local: null
      upstream_api: null
  - nombre: context-mode
    tipo_provisionamiento: mcp-workspace
    requerido: true
    gestor: npm
    paquete: context-mode
    comando: context-mode
    version:
      autoridad: gestor-paquetes
      upstream_api: https://registry.npmjs.org/context-mode/latest
```

### `.opencode/mcp-state.json` — estado por workspace (no versionado)

```json
{
  "context-mode": {
    "tipo": "mcp-workspace",
    "requerido": true,
    "comando_resuelto": "<HOME>/<usuario>/AppData/Roaming/npm/node_modules/context-mode/cli.mjs",
    "version_instalada": "2.1.0",
    "version_ultima": "2.1.0",
    "fuente": "https://registry.npmjs.org/context-mode/latest",
    "estado": "ok",
    "ultimo_check": "2026-11-07T12:00:00Z"
  },
  "ECC": {
    "tipo": "kit-integrado",
    "requerido": false,
    "rama_seguida": "main",
    "ultimo_sha": "b92f181b",
    "sha_remoto": "b92f181b",
    "estado": "al-dia",
    "ultimo_check": "2026-11-07T12:00:00Z"
  }
}
```

Estados admitidos: `ok`, `al-dia`, `desactualizado`, `missing`, `degraded`, `desconocido`, `absent`. Ningún otro valor es válido.

### Matriz de capacidades (`capacidades-por-harness.md`)

Fila = capacidad. Columnas obligatorias: capacidad, mecanismo OpenCode, mecanismo Copilot, estado, fuente, versión verificada, prueba. Las cuatro capacidades iniciales a relevar son: subagentes/delegación, hooks/eventos de sesión, permisos de escritura por path y skills por frontmatter. La matriz se completa con evidencia de la versión instalada, no con supuestos.

## Success Criteria

- **SC-001**: `validate` detecta el defecto actual de `context-mode` (entrada contra `build/cli.js` inexistente) y devuelve exit code distinto de cero, sin modificar archivos.
- **SC-002**: `generate` produce un `opencode.json` válido sin la entrada rota, y ese archivo permite iniciar sesión con los MCP requeridos operativos.
- **SC-003**: dos ejecuciones consecutivas de `generate` dan archivos idénticos (hash igual).
- **SC-004**: `validate-parity` reporta el mismo conjunto de servidores en `opencode.json` y `.vscode/mcp.json`, con diferencias de capacidad justificadas por la matriz.
- **SC-005**: el manifest declara tipo y autoridad de versión para el 100% de las dependencias externas existentes; ninguna queda sin tipo.
- **SC-006**: la sonda de ECC y spec-kit responde `al-dia` o `desactualizado` con SHA y fecha, y coincide con lo que devuelve el remoto en una verificación manual.
- **SC-007**: ningún archivo de configuración versionado contiene una ruta absoluta de la máquina (`<HOME>\...`).
- **SC-008**: ninguna escritura de configuración usa la forma plana `mcp.<nombre>`; `validate` la detecta como FAIL si reaparece.
- **SC-009**: no existe ningún `AGENTS.md`, `CLAUDE.md` ni `.mcp.json` de un clon externo bajo la raíz del workspace.
- **SC-010**: la matriz de capacidades cubre las cuatro capacidades iniciales con fuente y versión, y `validate-parity` falla si se usa una capacidad no declarada.
- **SC-011**: `validate-agents-skills.ps1` sigue en verde (`FAIL: 0`) después de los cambios.
- **SC-012**: el documento `provisionamiento-externo.md` permite, sin leer código, ejecutar la sonda y la actualización de cada tipo.
- **SC-013**: `validate-parity` devuelve FAIL cuando un agente usa una capacidad que la matriz no declara, y WARN cuando una fila no tiene `spec_responsable`. Las cuatro inconsistencias actuales tienen spec responsable asignada (040 a 043), por lo que no generan WARN.

## Edge cases

| Caso | Comportamiento esperado |
|---|---|
| Sin red | Estado `desconocido` + WARN; exit code distinto de cero solo si un requerido queda indeterminado; no se aborta la sesión |
| `npm` no disponible | `validate` reporta `missing` con causa, no excepción sin capturar |
| Node por debajo del mínimo del paquete (`context-mode` exige `>=24.15.0`) | WARN explícito de prerrequisito; la entrada no se genera si el runtime no cumple |
| Clon con `HEAD` detached (tokenslayer en tag) | La sonda usa el tag fijado como referencia, informa `detached` y no falla por eso |
| Clon shallow/grafted | La sonda informa `shallow`; `apply` usa fetch del tag o `--unshallow` según el tipo |
| Artefacto compilado modificado en local (tokenslayer) | `apply` reconstruye; si el build falla, `degraded` y la entrada se omite de la configuración |
| `opencode.json` inexistente | Estado `absent`; `generate` lo crea desde la plantilla |
| Usuario editó un archivo generado | `generate` lo sobrescribe; el archivo está en `.gitignore` y la fuente es el generador |
| Dos arneses en el mismo workspace | Ambos archivos se generan desde la misma fuente; `validate-parity` es obligatorio |
| Ruta con espacios o no ASCII | Los generadores citan y escapan correctamente; verificado con al menos una ruta con espacio |
| Ejecución concurrente | Escritura atómica; la última ejecución gana y no deja archivos temporales |
| Dependencia requerida ausente | FAIL con exit code ≠ 0 y nombre de la dependencia |

## Dependencies and assumptions

- **Supuestos**: el workspace tiene git, PowerShell 7 y un gestor de paquetes por tipo; el usuario puede escribir en `proyect_ext/` para la descarga de dependencias externas (requisito para FR-13); existe red al menos para `apply` y para las sondas de actualización.
- **Dependencias**: `.specify/memory/constitution.md` (Art. I, II, V, IX), `dependencias-manifest.yml`, `scripts/plataformador-bootstrap.ps1`, `scripts/validate-agents-skills.ps1` (VAL-07), `scripts/sync-mcp-graphify.ps1`, `scripts/sync/opencode/sync-opencode-config.ps1`, `scripts/sync/indexing/run-indexing.ps1`.
- **Requisito de gobernanza**: la generación de configuración modifica el modelo de `opencode.json`; exige enmienda MINOR de la constitution (v2.0.0 → v2.1.0) y un ADR antes de la fase `plan`, según Art. VI y el procedimiento de decisiones transversales.

## Risks

| Riesgo | Impacto | Mitigación |
|---|---|---|
| El generador sobrescribe personalizaciones del usuario en `opencode.json` | Alto | Solo gestiona `mcp.servers`; el resto de claves se preserva desde la plantilla y se valida el resultado |
| La matriz de capacidades se llena con supuestos | Alto | Fuente y versión obligatorias; sin evidencia la fila no entra |
| Mover el clon rompe rutas cableadas en scripts o en el estado | Medio | Búsqueda de referencias antes del movimiento; el estado registra ruta anterior y nueva |
| El estado se desincroniza del sistema real | Medio | `validate` compara declaración contra realidad en cada corrida; `generate` no confía en el estado sin verificar el binario |
| Un `apply` automático introduce una versión que rompe el arnés | Medio | `apply` es explícito; `generate` omite lo que no resuelve; reversión por tipo documentada |

## Review & Acceptance Checklist

- [x] Sin necesidades de clarificación pendientes: las cinco decisiones bloqueantes están resueltas por el usuario (D1–D5)
- [x] La spec describe el qué y el porqué, no el cómo de implementación (nombres de script y claves son contratos, no diseño de código)
- [x] Cada historia de usuario es testeable de forma independiente
- [x] Los requisitos funcionales son verificables y tienen criterio de aceptación asociado
- [x] Los criterios de éxito son medibles (SC-001 a SC-013)
- [x] Los casos borde están enumerados con comportamiento esperado
- [x] El fuera de alcance está registrado y no se mezcla con el alcance
- [x] Los tipos de aprovisionamiento están definidos con autoridad de versión por tipo
- [x] La deuda de gobernanza (enmienda de constitution + ADR) está declarada como requisito de la siguiente fase
