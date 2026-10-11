# Agents IA Tech Constitution
<!-- Constitution for IA agents project working with Copilot and Opencode -->

## Core Principles

### I. Modular Agent Design
Every agent must be self-contained, independently testable, and have a clear purpose. No organizational-only agents without well-defined interfaces and documentation. Agents should be reusable across different harnesses and projects.

"Un agente" significa un archivo de definicion completo y autonomo, con: proposito explicito, Skills que utiliza, herramientas que invoca, paths que puede escribir, Output esperado y criteria de exito. Un agente que solo coordina sin interfaz verificable no califica.

Cada agente pertenece a un **tier** (principio VII) y su definicion declara el tier en el que opera. La independencia exige ademas que el agente sea **reutilizable entre proyectos**: nada de rutas absolutas ni de supuestos sobre un unico repo (ver constraint de Genericidad).

### II. Orchestrator Pattern
A main orchestrator must coordinate all transversal agents, enabling communication and cooperation between them. The orchestrator defines the contract for agent interactions and ensures consistent behavior across the system.

El orquestador principal es el **`pensador`**. Segun ADR-0005, el `pensador` **nunca implementa codigo**: delega la ejecucion de los comandos Speckit en el **`Agent-SSD`** (tier documental extendido), valida los artefactos que devuelve y gobierna el ciclo de fases (specify → plan → tasks → analyze → converge → implement). El `Agent-SSD` **nunca auto-continua** a la fase siguiente: el pipeline lo gobierna el `pensador`. La razon del tier separado es que los agentes documentales no pueden escribir en `src/<App>/.specify/`, y ese subcarpeta es precisamente donde Speckit necesita escribir.

La matriz de delegacion es explicita y corta: `pensador` → Think Map → delega unico; `Agent-SSD` → ejecucion Speckit + documentacion de artefactos; implementadores (`api-developer`, `frontend-developer`, `devops`) → codigo; `qa-senior` → tests y veredictos; `security-auditor` → revisiones; `gitflow` → git; `solucionador` / `plataformador` → plataforma. Un agente que actua fuera de su fila no esta delegando: esta improvisando.

### III. Specification-Driven Development
All agent behavior must be defined in structured specifications (specs) before implementation. Specs must be machine-readable (JSON/YAML) and human-readable, serving as the single source of truth for agent behavior, capabilities, and interfaces.

Ciclo obligatorio y sin saltos: **specify → plan → tasks → analyze → converge → implement**. Cada fase produce un artefacto verificable antes de pasar a la siguiente. La especificacion vive en `Documentacion/<AppName>/specs/<NNN-slug>/` y los artefactos en cascada son `spec.md`, `plan.md`, `research.md`, `data-model.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `converge.md`, `quickstart.md`.

`speckit-converge` existe porque la spec y el codigo se desincronizan: vuelve a asentar el estado real del codigo contra lo especificado y agrega a `tasks.md` el trabajo faltante. Un `tasks.md` sin converge reciente es una asuncion, no un inventario.

### IV. Copilot/Opencode Compatibility
The project must work seamlessly with both GitHub Copilot and VS Code Opencode. Tool-agnostic design patterns must be used where possible, and any tool-specific integrations must be clearly documented and isolated.

Las definiciones de agentes son **simetricas en los dos harnesses**: `.github/agents/<agente>.agent.md` (Copilot VS Code) y `.opencode/agents/<agente>.md` (OpenCode). Editar una obliga a editar la otra en la misma ronda; si divergen, `qa-senior` lo reporta como NO PASS.

- **Skills**: globales y compartidas desde el workspace master (`.opencode/skills/`); no se duplican por proyecto.
- **`.specify/`**: especifico de cada proyecto (tipicamente `<proyecto>/.specify/memory/constitution.md`).
- **`Documentacion/<AppName>/`**: propia de cada app y **nunca se copia** entre proyectos. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) si se sincroniza, mediante `sync-agents.ps1`.
- **`agents/`**: espejo de agente compartido entre harnesses.

### V. Observability and Monitoring
All agent interactions, decisions, and errors must be fully observable. Structured logging, tracing, and monitoring are non-negotiable. Every agent must emit traceable events for its lifecycle events, decisions, and errors.

El bootstrap (`scripts/plataformador-bootstrap.ps1`) acumula WARNs y ERRORs durante toda la ejecucion y muestra un **cuadro resumen final** con conteo y lista, para que el operador no tenga que leer el log completo. El patron de logging es `Write-Info` / `Write-Warn` / `Write-Error` con prefijo `<Funcion>:`. Toda modificacion a un `.ps1` pasa por `Parser::ParseFile` con 0 errores como gate minimo.

Ningun fallo se traga en silencio: si un componente no se pudo verificar, el resultado es un WARN visible con la razon, no un exito aparente. La intervencion se registra en `Documentacion/<AppName>/bitacoras/<YYYY-MM-DD>-<titulo>.md`, y sin bitacora la intervencion no existio.

### VI. Gestión de Dependencias Externas y Estructura proyect_ext

Para gestionar eficientemente múltiples proyectos externos (spec-kit, graphify, herramientas de seguridad, etc.) sin comprometer la integridad del proyecto principal, se establece la siguiente estructura y protocolo:

#### Estructura de Directorios
- **proyect_ext/** - Directorio raíz para clonar y mantener todos los proyectos externos. Su contenido esta en `.gitignore` (`proyect_ext/*`); solo se versionan los archivos de referencia que el kit necesita (`dependencias-manifest.yml`).
  - **proyect_ext/spec-kit/** - Clon del repositorio https://github.com/github/spec-kit (origen de las 12 skills Speckit)
  - **proyect_ext/tokenslayer/** - Clon del proyecto tokenslayer (MCP server propio, se ejecuta con `node`)
  - **proyect_ext/[nombre-herramienta]/** - Cada proyecto externo en su propio subdirectorio
- **Manifest de Dependencias** - Archivo `dependencias-manifest.yml` en la raíz del proyecto, que lista todos los proyectos externos, sus versiones, URLs y componentes a copiar. Esta versionado: `.gitignore` lo re-incluye con `!dependencias-manifest.yml`.

#### Protocolo de Trabajo
1. **Clonación inicial**: Todos los proyectos externos se clonan bajo proyect_ext/ usando el manifest de dependencias
2. **Actualización controlada**: El agente `upgrade_framework` gestiona actualizaciones desde proyect_ext/ hacia el proyecto principal. **Ninguna URL se hardcodea en el bootstrap**: todo se resuelve desde el manifest. La invocacion es **opt-in** via el flag `-ForceUpgradeTools` y es **fail-open** (ver principio VIII)
3. **Integración dirigida**: Solo se copian los componentes necesarios (agentes, skills, scripts, configuración) desde proyect_ext/ a las rutas correctas en Agents_IA_TECH/
4. **Personalización preservada**: Los cambios de configuración del usuario en Agents_IA_TECH/ nunca se sobrescriben
5. **Manifest actualizado**: Después de cada actualización exitosa, se actualiza el manifest para reflejar las nuevas versiones

#### Archivo Manifest de Dependencias (dependencias-manifest.yml)
Este archivo se mantiene en la raíz del proyecto. En el **kit maestro no declara ninguna app concreta activa**: contiene el formato y un **ejemplo comentado** (`# EJEMPLO por proyecto — NO activar en el kit`). Cada proyecto declara las suyas. Estructura por dependencia:
```yaml
dependencias_externas:
  - nombre: spec-kit
    url: https://github.com/github/spec-kit
    rama: main
    version_actual: vX.Y.Z
    ultimo_check: YYYY-MM-DD
    componentes_a_copiar:
      - src/speckit-specify/ → .github/skills/speckit-specify/
      - src/speckit-plan/ → .github/skills/speckit-plan/
  - nombre: tokenslayer
    url: https://github.com/<owner>/tokenslayer
    rama: main
    version_actual: vA.B.C
    ultimo_check: YYYY-MM-DD
    componentes_a_copiar:
      - mcp-server/build/index.js → proyect_ext/tokenslayer/mcp-server/build/index.js
```

#### Origenes reales verificados de las herramientas del kit (2026-09-19)

| Herramienta | Origen verificado | Forma de instalacion | Licencia |
|---|---|---|---|
| **spec-kit** | `https://github.com/github/spec-kit` | `git clone` en `proyect_ext/spec-kit/` | MIT |
| **graphify** | `https://github.com/Graphify-Labs/graphify` — paquete PyPI **`graphifyy`** | **Via MCP**: `python -m graphify.serve <root>/graphify-out/graph.json`, transporte **stdio**. Instalacion preferida `uv tool install "graphifyy[mcp]"` (sin pin, siempre ultima version disponible); alternativa `pip install "graphifyy[mcp]"`. El manifest registra la version aplicada para detectar actualizaciones | Apache-2.0 / MIT (dual) |
| **tokenslayer** | manifest | `git clone` en `proyect_ext/tokenslayer/` + `node proyect_ext/tokenslayer/mcp-server/build/index.js` | segun manifest |

> **Correccion 2026-10-03 (v2.0.0)**: la URL `https://github.com/tomasgraph/graphify` registrada en la v1.0.0 esta **muerta (HTTP 404, verificado 2026-09-19)**, y el destino `bin/graphify → .opencode/bin/` quedo obsoleto al adoptarse la via MCP. **graphify no se clona**: se instala como paquete Python y expone su MCP server embebido (7 herramientas documentadas, 10 verificadas en la prctica). Los paths `bin/graphify` y `lib/graphify` del manifiesto deben considerarse obsoletos.

#### Controles de seguridad obligatorios en toda clonacion
Ninguna clonacion, descarga o build de dependencia externa ocurre sin estos controles:

- **Allowlist de origenes**: solo URLs de la allowlist, con verificacion de firma y checksum
- **Clone superficial**: `--depth=1`, `--no-recurse-submodules`
- **Limites**: tamano maximo de descarga, profundidad maxima y timeout estricto con kill en exceso
- **Containment**: realpath verificado, sin symlinks, sin `..`, salida obligatoria de `<root>/proyect_ext/`
- **Cero secrets en el manifest**: las credenciales van por variables de entorno o secret manager, nunca en el YAML
- **Sanitizacion del output de build**: se filtran tokens de stdout/stderr antes de loguearlos

### Beneficios de esta Estructura
- **Reproducibilidad**: Al clonar el repositorio principal, el manifest indica exactamente qué proyectos externos descargar
- **Actualizaciones controladas**: Cada proyecto externo se puede actualizar independientemente
- **Integración selectiva**: Solo se copian los componentes necesarios, evitando conflictos y bloat
- **Personalización preservada**: Los cambios locales del usuario nunca se pierden durante las actualizaciones
- **Rollback seguro**: Fácil de volver a versiones anteriores si una actualización causa problemas
- **Escalabilidad**: Fácil de agregar nuevos proyectos externos siguiendo el mismo patrón

### Responsabilidad del Agente upgrade_framework
El agente `upgrade_framework` es responsable de:
- Mantener actualizado el manifest de dependencias
- Gestionar el directorio proyect_ext/
- Ejecutar el flujo de integración dirigida desde proyect_ext/ hacia Agents_IA_TECH/
- Notificar al Pensador cuando las actualizaciones requieren revisión de orquetación

### VII. Restricción de Paths por Tier (No Negociable)

Este principio faltaba en la v1.0.0 pese a ser la regla mas aplicada del kit, por eso es articulo propio. Cada agente pertenece a un tier y cada tier tiene una **whitelist de escritura**. Escribir fuera de la whitelist es violacion de la constitution, no un bug menor.

| Tier | Agentes | Escribe codigo | Rutas permitidas |
|------|---------|:---:|---------------------|
| **Documental** | `pensador`, `arquitecto`, `documentador`, `security-auditor` | No | `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` |
| **Documental extendido** | `Agent-SSD` | No | `src/<App>/.specify/` (**solo esa subcarpeta**), `Documentacion/<AppName>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` |
| **Implementador** | `api-developer`, `frontend-developer`, `devops`, `qa-senior` | Si | `src/<App>/`, `tests/`, scripts de la app |
| **Tooling** | `gitflow` | Solo git | Ramas, commits, PRs, merges, reverts |
| **Plataforma** | `solucionador`, `plataformador` | Si | Diagnostico remoto y nivelacion de proyectos |

Reglas de aplicacion:
- Un agente **nunca** edita codigo de aplicacion si su tier es documental, ni siquiera un docstring o un comentario inline: eso es del agente implementador
- Un agente documental **nunca** toca `Documentacion/<OtraApp>/`: cada app esta aislada
- El `pensador` no implementa codigo en ningun caso; delega (ADR-0005)
- En el proyecto **kit** (sin `src/`), el `pensador` **puede** ejecutar Speckit directamente, porque sus artefactos van a `Documentacion/<AppName>/specs/`, que si esta en su whitelist

### VIII. Fail-Open en Integraciones Externas
Ninguna llamada a un servicio, clonado, descarga o MCP externo puede hacer fallar el bootstrap. El patron es obligatorio: **fail-open**, es decir `try/catch` + `Write-Warn` + `continue`, con exit code 0.

Consecuencias practicas:
- Un MCP caido se reporta degradado, no aborta la ejecucion
- Un token sin resolver deja la entrada en `enabled: false` con WARN visible, nunca rompe el JSON
- `-DryRun` propaga a todas las funciones y produce **cero escrituras** y cero side effects
- El operador ve el problema en el cuadro resumen final sin haber leido el log completo

El fail-open **nunca aplica a operaciones destructivas**: eliminar, sobrescribir o mover fuera de la allowlist exige **fail-closed** (abortar con ERROR). Eliminar, relocalizar o limpiar exige ademas confirmacion obligatoria, sin flag que la salte.

### IX. Contenido Completo, Nunca Esqueletos
Todo archivo creado o actualizado por un agente debe tener contenido real en cada seccion. No es guia de estilo, es regla de integridad.

- Prohibido entregar solo el encabezado, el titulo o la plantilla vacia
- Prohibido dejar secciones con solo el titulo y nada debajo
- Prohibidos placeholders: `TBD`, `TODO`, `pendiente`, `por definir`, `N/A`, `completar aqui`, `XXX`, `...`, o repetir el nombre de la seccion como contenido
- Prohibidas tablas con solo el encabezado y cero filas reales, y listas vacias o con un solo item generico
- Si una seccion no aplica, se escribe en una linea **por que** no aplica; nunca se deja vacia

**Verificacion obligatoria antes de dar por terminado un archivo**: (1) leer el archivo escrito, no confiar en la memoria de lo que se creyo escribir; (2) confirmar que ninguna seccion quedo con solo el titulo; (3) confirmar que no hay placeholders; (4) confirmar que las tablas tienen filas reales y las listas items concretos; (5) contar lineas de contenido real por seccion — si una seccion tiene menos de 3 lineas utiles, esta incompleta.

Corolario en la direccion opuesta: **prohibido marcar una tarea como completada si no esta realmente implementada y validada**, y prohibido dar informacion falsa o reportar exito sin evidencia. Un `tasks.md` que no refleja la realidad del codigo es un defecto: los checkboxes se marcan contra evidencia, no contra intencion.

## Additional Constraints

### Technology Stack Requirements
El kit es **configuracion, no aplicacion**: no hay `src/`, ni build, ni runtime de aplicacion.

- **Lenguajes**: PowerShell 7+ (`.ps1`, todos declaran `#requires -Version 7.0`) y Markdown (agentes, skills, documentacion). YAML para manifiestos (`dependencias-manifest.yml`) y JSON para configuracion de harness (`opencode.json`) y estado (`.bootstrap-state.json`).
- **Node.js** se usa **solo como runtime de un proyecto externo** (el MCP server de tokenslayer que vive en `proyect_ext/`), nunca para compilar el kit.
- **No hay TypeScript.** La v1.0.0 exigia TypeScript + Node.js 18+, lo que era un error: el kit no tiene runtime TS y `AGENTS.md` lo declaraba explicitamente. Corregido en v2.0.0.
- Ambos harnesses deben seguir funcionando tras cualquier cambio: OpenCode (`.opencode/`, agente por defecto `build`) y GitHub Copilot VS Code (`.github/`).
- Los MCPs del kit son: `context-mode`, `codebase-memory-mcp`, `markitdown`, `tokenslayer`, `graphify`.

### Agent Communication Protocols
All inter-agent communication must go through the main orchestrator (`pensador`). Direct agent-to-agent communication is prohibited unless explicitly authorized by the orchestrator. Communication contracts must be versioned and backward-compatible.

El unico agente con permiso de delegacion es el `pensador`. Todos los demas son **hojas ejecutoras**: invocan herramientas, no a otros agentes. Cuando un agente invoke a otro, `task: denied` en su definicion.

El orquestador gobierna las fases y **nunca auto-continua** a la siguiente sin validacion del usuario entre fases: la diferencia entre un pipeline gobernado y uno que se desboca esta exactamente ahi. Cuando un implementador encuentra un error sin spec, crea la tarea y pide especificacion; **nunca improvisa**.

### Genericidad y Ausencia de Rutas Absolutas
El kit maestro es **portable y reutilizable**: se distribuye a otros proyectos.

- **Cero nombres de dominio concreto** en codigo, plantillas y documentacion vigente. Se usan `MiApp`, `AppFoo`, `AppBar`, `AppBaz`, `AppQux`. Los nombres reales que aparecen en hallazgos de modo real se anonimizan **solo en el nombre** (`AppXXX`), nunca en numeros ni logs: los reportes de `testing/` y la evidencia de incidentes se conservan verbatim como fuente de verdad historica
- **Cero rutas absolutas** en todo archivo versionado: rutas relativas, o tokens que se re-resuelven en runtime. Las rutas de usuario (`C:\Users\<user>\...`) no se versionan jamas. Unicas excepciones: documentacion de historial y reportes de evidencia
- **Cero apps concretas activas** en el manifest maestro: se declara el formato y un ejemplo comentado
- Los comandos MCP se guardan como **plantilla con tokens** (p. ej. `__CONTEXT_MODE_CMD__`) y el bootstrap los re-resuelve en runtime. La plantilla arranca en `enabled: false` y el runtime promueve; un commit **nunca** fuerza `enabled: true` por resolucion

### Idioma
Comunicacion y documentacion en **espanol latino neutro**. Prohibido el voseo rioplatense (`querés` → `quieres`, `preguntá` → `pregunta`, `auditá` → `audita`, `crealo` → `créalo`) tanto en `.github/` como en `.opencode/`.

Los identificadores, nombres de funcion, claves de JSON y comandos se mantienen en ingles: el codigo se lee en un idioma y la documentacion en otro, y esa division es intencional. Los ejemplos pedagogicos si van en espanol, para que el lector del kit los entienda sin traducir.

Cuando un agente escribe en `.github/` y ese archivo tiene equivalente en `.opencode/`, ambos conservan el mismo idioma: la divergencia linguistica entre harnesses es un defecto, igual que la divergencia de contenido.

## Development Workflow

### Agent Lifecycle
1. Definir la especificacion en `Documentacion/<AppName>/specs/<NNN-slug>/spec.md` (agente `pensador`)
2. Generar `plan.md` + `tasks.md`, ejecutados por el `Agent-SSD` bajo delegacion del `pensador` (ADR-0005)
3. `analyze.md` (consistencia cruzada) + ADRs en `Documentacion/<AppName>/arquitectura/adr/` + threat model si hay superficie de seguridad
4. `converge.md` con la documentacion consolidada y trazabilidad completa requisito → tarea
5. Implementar asignando cada task de `tasks.md` al implementador segun su dominio; el `pensador` asigna, el implementador ejecuta
6. Validar con `qa-senior` (tests + quality gates); si encuentra un bug, lo documenta y lo pasa al desarrollador — **no lo corrige**
7. Commit con `gitflow` usando conventional commits; PR con code review obligatorio

### Code Review Requirements
All PRs must verify compliance with the constitution principles. Complexity must be justified and documented. No new agent may be merged without passing all constitution compliance checks.

Verificacion de compliance = checklist de los 9 principios **mas** la whitelist de paths del tier del agente que hizo el cambio (principio VII).

Un agente nuevo requiere ademas: spec en `Documentacion/<AppName>/agents/<agente>/spec.md`, definicion sincronizada en los dos harnesses, seccion Skills y seccion Idioma presentes, y veredicto PASS escrito del `qa-senior`. Sin ese veredicto, el agente no esta terminado por mas completo que parezca su definicion.

### Quality Gates
Los gates son **proporcionales a la superficie del cambio**. No se exige cobertura a lo que no tiene ejecucion.

| Cambio | Gate |
|--------|------|
| `.ps1` (scripts del kit o de la app) | `Parser::ParseFile` con **0 errores** de sintaxis |
| Funciones de `.ps1` | Tests Pester en `tests/*.Tests.ps1` para caminos felices y de fallo |
| Specs (`spec.md`, `plan.md`, `tasks.md`) | `speckit-analyze` sin hallazgos CRITICAL; checklist de requisitos aprobado |
| Agentes (`.github/` y `.opencode/`) | Sincronia entre harnesses + seccion Skills + seccion Idioma + veredicto `qa-senior` PASS escrito |
| Seguridad / supply chain | Threat model STRIDE + `npx ecc-agentshield scan` + `.gitleaks.toml` |
| Rutas destructivas | Allowlist + containment-check + fail-closed + test con fixture senuelo en `$env:TEMP` |
| Artefactos regenerables | `graphify-out/`, `.env.mcp`, `proyect_ext/*` **no** versionados (verificado con `git check-ignore`) |

> **Correccion 2026-10-03 (v2.0.0)**: la v1.0.0 exigia "Minimum 80% test coverage across all agents", gate inaplicable: los agentes son Markdown sin runtime, y el unico binario con tests es `tests/upgrade_framework.Tests.ps1` (Pester). La cobertura se mantiene como aspiracion para el codigo ejecutable, no como gate bloqueante.

## Governance

**Constitution supersedes all other practices.** Amendments require documentation, approval, and migration plan.

**Amendment Procedure:**
1. Proposer drafts principle/section revision in `Documentacion/<AppName>/`
2. Review period for all stakeholders
3. Architectural board approval required
4. Version increment follows semantic versioning:
   - MAJOR: Backward incompatible governance/principle removals or redefinitions
   - MINOR: New principle/section added or materially expanded guidance
   - PATCH: Clarifications, wording, typo fixes, non-semantic refinements

Un cambio de principio exige ademas **ADR** en `Documentacion/<AppName>/arquitectura/adr/` y entrada en su `00-index.md`.

Este documento se genera y revisa mediante el **Constitution Wizard**, que funciona como **cuestionario interactivo**: el agente pregunta bloque por bloque, el usuario responde, y la constitution se arma con esas respuestas.

**Version**: 2.0.0 | **Ratified**: 2026-08-25 | **Last Amended**: 2026-10-03

### Registro de cambios — v2.0.0 (2026-10-03)

**Correcciones factuales** (3):
1. **Stack real**: PowerShell 7+ + Markdown + YAML/JSON. Se elimina el requisito erroneo de TypeScript y Node.js 18+
2. **Ruta de documentacion**: `Documentacion/funcionalidades/` → `Documentacion/<AppName>/` (la primera no existe)
3. **Origen de graphify**: `https://github.com/tomasgraph/graphify` (404, verificado) → `https://github.com/Graphify-Labs/graphify` via PyPI `graphifyy`, instalacion por MCP. Se retira el destino obsoleto `bin/graphify → .opencode/bin/`

**Articulos nuevos** (3):
- **VII. Restricción de Paths por Tier** — tabla de whitelist por tier. Cubria la regla mas aplicada del kit, ausente en v1.0.0
- **VIII. Fail-Open en Integraciones Externas** — con el corolario de que el fail-open nunca aplica a operaciones destructivas (fail-closed)
- **IX. Contenido Completo, Nunca Esqueletos** — formaliza la regla de `AGENTS.md` con sus 5 pasos de verificacion

**Constraints nuevos** (2):
- **Genericidad y Ausencia de Rutas Absolutas** — formaliza RF-S1/RF-S2/RF-S6 de la spec `solucion-generica`
- **Idioma** — espanol latino neutro, prohibicion explicita del voseo en ambos harnesses

**Quality Gates**: tabla proporcional a la superficie del cambio, en reemplazo del gate de cobertura inaplicable.

**Workflow**: el ciclo de vida incorpora el tier `Agent-SSD` creado por ADR-0005.

**Pendiente para v3.0.0**: constitutionalizar formalmente el Constitution Wizard interactivo (12 bloques de preguntas) cuando el usuario lo priorice; hoy esta registrado como pendiente de prioridad baja.
