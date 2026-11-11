# Índice de Agents_IA_TECH

> Proyecto base de agentes y herramientas del ecosistema.
> Generado por plataformador-bootstrap.ps1.

## Componentes clave
- .github/
- .opencode/
- .doc_agents/
- scripts/
- Documentacion/Agents_IA_TECH/

## Objetivo
Asegurar que cada proyecto tenga su documentación, la estructura base y los MCPs listos antes de reorganizar archivos.

## Especificaciones activas

### 006-post-platforming-speckit
**Estado**: En proceso  
**Ubicación**: specs/006-post-platforming-speckit/
**Objetivo**: Flujo post-plataformado → speckit (3 escenarios) + re-indexación + Constitution por proyecto + memoria auto/manual

### 009-mcp-update-lifecycle
**Estado**: ARCHIVADA/FUSIONADA en `020-mcp-config-operativa` (fase D, spec 035)  
**Ubicación**: specs/archived/009-mcp-update-lifecycle/

### 010-mcp-env-file-guarantee
**Estado**: En proceso  
**Ubicación**: specs/010-mcp-env-file-guarantee/
**Objetivo**: Creación garantizada del archivo `.env.mcp` en el bootstrap

### 010-secret-leak-remediation
**Estado**: Finalizada — tareas T001-T015 resueltas; `temp_opencode_output.txt` removido del historial y `.gitignore`/`.gitleaks.toml` configurados  
**Ubicación**: specs/010-secret-leak-remediation/
**Objetivo**: Eliminar la API key filtrada en `temp_opencode_output.txt` del historial Git y prevenir futuras fugas (allowlist de gitleaks, rotación de clave, verificación con `gitleaks detect`)

### 011-bootstrap-invokes-upgrade-framework
**Estado**: Activa  
**Ubicación**: specs/011-bootstrap-invokes-upgrade-framework/
**Objetivo**: Bootstrap delega sync dependencias externas en upgrade_framework (fail-open, no hardcoded URLs)

### 012-ecc-integration
**Estado**: En proceso  
**Ubicación**: specs/012-ecc-integration/
**Objetivo**: Integración selectiva de ECC como proyecto externo en `proyect_ext/ECC`

### 012-ecc-mcp-bridge
**Estado**: En proceso  
**Ubicación**: specs/012-ecc-mcp-bridge/
**Objetivo**: Puente ECC ↔ MCPs y contrato de intercambio

### 012-ecc-mcp-migration
**Estado**: En proceso  
**Ubicación**: specs/012-ecc-mcp-migration/
**Objetivo**: Migración .env.mcp → mcp-configs/mcp-servers.json

### 013-ecc-integration-lifecycle
**Estado**: En proceso  
**Ubicación**: specs/013-ecc-integration-lifecycle/
**Objetivo**: Ciclo de vida install/update/validate/uninstall con `ecc-sync.ps1`

### 014-manifest-versionado-y-sincronizacion
**Estado**: En proceso  
**Ubicación**: specs/014-manifest-versionado-y-sincronizacion/
**Objetivo**: Estándar de manifiesto versionado y sincronización entre módulos del kit

### 015-sync-kit-bootstrap
**Estado**: En proceso  
**Ubicación**: specs/015-sync-kit-bootstrap/
**Objetivo**: Bootstrap y sincronización del kit transversal

### 015-mcp-integration-flow
**Estado**: Activa — flujo SSD finalizado, spec lista para producción  
**Ubicación**: specs/015-mcp-integration-flow/

### 016-detectar-install-vs-update
**Estado**: En proceso  
**Ubicación**: specs/016-detectar-install-vs-update/
**Objetivo**: Detección de instalación vs actualización del KIT

### 016-ssd-enforcement
**Estado**: En proceso  
**Ubicación**: specs/016-ssd-enforcement/
**Objetivo**: Forzar flujo SSD+Speckit vía agentes y guardkeeper en pensador

### 017-pendientes-implementacion-por-app — Pendientes de implementación por proyecto
- **Estado**: En proceso / Especificada — `tasks.md` tiene T001-T020; varias tareas pendientes (no todas marcadas como finalizadas). El índice se marcó erróneamente como finalizada. Estado real: espec definida y planificada, tareas en ejecución.
- **Ubicación**: specs/017-pendientes-implementacion-por-app/
- **Objetivo**: Archivo vivo por proyecto con estado de tareas y responsables.
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

### 018-pendientes-estados-scrum
**Estado**: En proceso  
**Ubicación**: specs/018-pendientes-estados-scrum/
**Objetivo**: Estados Scrum por agente y whitelist Art-VII por tier

### 020-mcp-config-operativa
**Estado**: Finalizado  
**Ubicación**: specs/020-mcp-config-operativa/
**Objetivo**: Configuración MCP operativa verificada en vivo (baseline)

### 021-sync-kit-agents
**Estado**: En proceso  
**Ubicación**: specs/021-sync-kit-agents/
**Objetivo**: Orquestador de sync por capas (Stage temporal + clean+replace + plataformar)

### 022-ecc-integration
**Estado**: Activa  
**Ubicación**: specs/022-ecc-integration/
**Objetivo**: Integración ECC por copia con espejo por harness via script

### 023-ecc-workflows — En proceso / Especificada
- **Estado**: En proceso  
- **Ubicación**: specs/023-ecc-workflows/
- **Objetivo**: Workflows CI propios derivados de ECC

### 024-hooks-gobernanza-determinismo
**Estado**: En proceso  
**Ubicación**: specs/024-hooks-gobernanza-determinismo/
**Objetivo**: Hooks pre-commit, gate PR, checksum Speckit y determinismo de harnesses

### 025-actualizacion-herramientas-externas
**Estado**: En proceso  
**Ubicación**: specs/025-actualizacion-herramientas-externas/
**Objetivo**: Hook diario y CI semanal para upgrade_framework y propagación vía sync-kit

### 026-agente-developer-unico
- **Estado**: Especificada — ciclo Speckit completo (spec/plan/tasks/analyze/converge); **implementación NO ejecutada** (el `converge.md` dice "Converge finalizado, listo para implementación"). ⚠️ El índice marcaba "Finalizada" por error: el converge declara estado pre-implementación.
- **Ubicación**: specs/026-agente-developer-unico/
- **Objetivo**: Unificar implementadores en un agente developer con skills especializadas y context7
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

### 027-patron-estructura-proyecto
- **Estado**: En proceso — spec/plan/tasks/analyze/converge creados. **Decisión de dirección (fase D, spec 035, usuario 2026-11-01)**: `021-estructura-inicial-apps-nuevas` es la OPERATIVA (8 tasks pendientes de creación de apps); `027-patron-estructura-proyecto` se tratará como **patrón normativo** al que 021 referenciará (completar el patrón en otra iteración).
- **Ubicación**: specs/027-patron-estructura-proyecto/
- **Objetivo**: Estructura canónica obligatoria Documentacion/<App>/ + src/<App>/ y validación
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

### 028-public-docs-routing
- **Estado**: Especificada — ciclo Speckit completo (spec/plan/tasks/analyze/converge) + ADR-0011 + skill public-documentation; **implementación NO ejecutada** (el `converge.md` dice "Lista para implementación vía speckit-implement"). ⚠️ El índice marcaba "Completada" por error.
- **Ubicación**: specs/028-public-docs-routing/
- **Objetivo**: Routing docs públicas a `src/<App>/docs/` y README a `src/<App>/README*.md`; delegación documentador→developer
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, ADR-0011-public-docs-routing.md, skill public-documentation

### 029-sync-eol-y-force-real
- **Estado**: **En proceso** — implementación iniciada. 37 tasks en `tasks.md`; 2 resueltas (T028, T030); 35 pendientes. T036 fue revertida de `[x]` a `[ ]` el 2026-10-29 porque se había marcado apoyándose en `tests/upgrade_framework.Tests.ps1`, que no compila (DD-08). T025 y T036 están bloqueadas por DD-08.
- **Ubicación**: `specs/029-sync-eol-y-force-real/`
- **Objetivo**: Que el sync distinga contenido igual / igual-salvo-EOL / distinto con mensajes observables, y que `-Force` y `-DryRun` sean flags explícitos de `Sync-TransversalKit` (sin dynamic scoping); escritura LF y bloque `mcp` local intacto
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, checklists/requirements.md. Fases 1-8 de `tasks.md`; Fase 8 (T030..T037) derivada de Analyze el 2026-10-28. T038 descartada con evidencia

### 030-whitelist-contextual-por-tipo-proyecto
- **Estado**: **Especificada** — Analyze PASS con observaciones (`arquitecto` + `security-auditor`), Converge finalizado 2026-10-29. **NÚCLEO absorbido por ADR-0013** (whitelist de escritura por capa/tipo de proyecto y agentes como orquestadores delgados). **Implementación del RESTO NO iniciada**: 66 tasks en `tasks.md`, 0 ejecutadas. Nota de consolidación parcial en `NOTA-CONSOLIDACION.md`. **No se cierra por completo ni se archiva**: queda como PENDIENTE-REAL.
- **Ubicación**: `specs/030-whitelist-contextual-por-tipo-proyecto/`
- **Objetivo**: Que la whitelist de escritura sea contextual al tipo de proyecto (`kit` | `consumidor`), determinista y sin fuga del kit hacia los consumidores; y replantear los agentes como orquestadores delgados con las capacidades de procedimiento en skills declaradas en el frontmatter
- **Métricas**: 23 FR (FR-01..FR-11, FR-02b, FR-12..FR-22), 12 CA (CA-01..CA-12), 6 NFR, 66 tasks, cobertura verificada 23/23 FR y 12/12 CA
- **Artefactos**: spec.md (1.1.0), plan.md (1.1.0), tasks.md (1.2.0), analyze.md (1.0.0), threat-model.md (1.0.0), checklists/requirements.md (1.0.0), converge.md. ADR-0013 aceptado y registrado en `arquitectura/adr/00-index.md`
- **Decisiones pendientes** (bloquean tasks): D-01 (`usuario-preferencias` vs Constitution → bloquea T020), D-02 (`plataformador` fragmentar → task no creada), D-03 (`gitflow` retirar o delgado → bloquea T021). D-04 resuelta: `Agent-SSD` y `pensador` NO se fusionan
- **Deudas registradas en converge.md**: 030-DD-01 (FR-11 sin cambio `C-NN` en el plan), 030-DD-02 (`terminal`/`execute` sin acotar en el consumidor), 030-DD-03 (anti-fuga del marcador sin test permanente), 030-DD-04 (skills nuevas sin validación de contenido; IP SSH propagable), 030-DD-05 ("workspace completo" del `developer` en kit sin denylist)

---

## Especificación 031 - Permisos, dominio y delegación de agentes
- **Estado**: Finalizada — flujo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge). CA-01..CA-12 todos cumplidos. Absorbe los borradores 034 (comportamiento), 035 (delegación) y 037 (permisos)
- **Ubicación**: specs/031-permisos-y-dominio-de-agentes/
- **Objetivo**: Que todo agente opere bajo un contrato único y verificable de dominio de escritura, prohibiciones absolutas, delegación y autorización de operaciones críticas (`[S]`/`[N]`/`[C]`), con sesión SSH única por servidor reutilizable y auditada
- **Métricas**: 24 FR (FR-01..FR-24), 7 NFR, 7 historias de usuario, 12 CA (CA-01..CA-12), matriz de permisos por operación y por agente
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0, FAIL=0 WARN=52 (solo VAL-09, aviso por diseño). Suite `tests/validate-agents-skills.Tests.ps1`: 20/20 en verde. Test de contrato `tests/agents-parity.ps1`: exit code 0, fixture negativo detecta divergencia. `analyze.md` y `threat-model.md` verificados (sin placeholders, sin secciones vacías). CA-01..CA-12 todos cumplidos
- **Paridad lograda**: los 13 agentes tienen cuerpo idéntico en `.github/agents/<n>.agent.md` y `.opencode/agents/<n>.md`; solo difiere el frontmatter nativo de cada arnés (`tools`/`user-invocable` vs `mode`/`temperature`/`permission`). `tier`, `description` y el conjunto de `skills` son iguales en ambos lados
- **Artefactos de esta iteración**: skill `threat-modeling` creada en ambos arneses; `tier` corregido en `pensador`, `security-auditor` y `usuario-preferencias`; `testing` reemplazada por `tdd-workflow` + `verification-loop` en `developer`; `dominio_check` y protocolo de autorización con `[S]`/`[N]`/`[C]` en ambos arneses; `plataformador` restaurado a su versión finalizada (474 líneas, `5513d37`) con `Enfoque` y `Constraints`; 8 agentes nivelados a la estructura de Regla 2 (38 violaciones resueltas)
- **Specs hermanos registrados**: 032 (actualización de Knowledge Base tras spec validada — ciclo SSD+Speckit completo, implementación parcial con limitaciones de herramientas MCP) y 033 (refresh de conocimiento e índices de MCP en la primera ejecución del día — ciclo SSD+Speckit completo, implementación T08-T10 pendiente de primera ejecución del día real)

## Especificación 032 - Actualización de Knowledge Base tras spec validada
- **Estado**: **En proceso / Especificada** — en disco `tasks.md` tiene las 13 tareas en estado "Pendiente" (0 ejecutadas) y el "Estado general" dice "quedan por ejecutar". Estado real: **En proceso / Especificada** — pipeline creado (`pipeline-kb.md`) pero sin ejecutar.
- **Ubicación**: `specs/032-actualizacion-knowledge-base/`
- **Objetivo**: Que el cierre de una spec dispare la actualización de CodeBase (codebase-memory-mcp), Context (context-mode) y Graphify (graphify), para que los agentes consulten el contenido de specs validadas vía MCPs sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: Test de contrato `tests/kb-parity.ps1`: exit code 0, fixture negativo detecta divergencia. Ejecución del pipeline de KB (CA-01..CA-05, CA-07..CA-12) **pendiente**: faltan herramientas MCP `graphify.extract`, `context-mode.ctx_index`, `codebase-memory-mcp.search_graph` en el catálogo
- **Artefactos**: spec.md, plan.md, tasks.md, pipeline-kb.md, analyze.md, threat-model.md, converge.md, tests/kb-parity.ps1
- **Limitación documentada**: la ejecución real del pipeline KB está pendiente por falta de herramientas MCP en el catálogo (T08-T10). El repositorio ya está indexado en codebase-memory-mcp (11,399 nodos) y graphify (4,973 nodos, 467 comunidades).

## Especificación 033 - Refresh de conocimiento e índices de MCP en la primera ejecución del día
- **Estado**: ⚠️ Divergencia corregida (2026-11-01) — el índice lo marcaba "En proceso, T01-T07 resueltas", pero en disco `tasks.md` tiene las 13 tareas en estado "Pendiente" (0 ejecutadas). Estado real: **Especificada / no iniciada en ejecución real** — ciclo SSD+Speckit completo en artefactos, pipeline definido (`pipeline-refresh-mcp.md`) pero sin tareas ejecutadas.
- **Ubicación**: `specs/033-refresh-conocimiento-mcp/`
- **Objetivo**: Que la primera ejecución del día dispare automáticamente el refresh de conocimiento e índices de todos los MCP del proyecto (`codebase-memory-mcp`, `graphify`, `context-mode`, `markitdown`, `tokenslayer`, `github`, `playwright`, `context7`), para que los agentes consulten información actualizada sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: Test de contrato `tests/mcp-refresh-parity.ps1`: exit code 0, fixture negativo detecta divergencia. Ejecución real del refresh (CA-01..CA-05, CA-07..CA-12) **pendiente** de primera ejecución del día
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, pipeline-refresh-mcp.md, tests/mcp-refresh-parity.ps1
- **Limitación documentada**: la ejecución real depende de la primera ejecución del día (dependencia operativa, no de especificación); ninguna tarea está marcada como ejecutada en `tasks.md`

---

### 034-arranque-agentes-por-defecto
- **Estado**: **En proceso / Especificada** — en disco `tasks.md` tiene las 13 tareas en estado "Pendiente" (0 ejecutadas) y el "Estado general" dice "quedan por ejecutar". Estado real: **En proceso / Especificada** — pipeline creado (`pipeline-kb.md`) pero sin ejecutar.
- **Ubicación**: `specs/034-arranque-agentes-por-defecto/`
- **Objetivo**: Que el cambio de "arranque por defecto con agentes propios" **se propague por los scripts de actualización del kit**, no solo por edición manual.
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, tests/harness-default.ps1, tests/kit-sync-merge.ps1; `opencode.json` L5, sección de arranque en `AGENTS.md` L117 envuelta en `KIT-BLOCK` (L117/L143), enrutamiento en `.github/copilot-instructions.md`, sección en `README.md`, `Ensure-OpenCodeDefaultAgent` en `scripts/plataformador-bootstrap.ps1`, `VAL-10` en `scripts/validate-agents-skills.ps1`, `Compare-KitFileState`/`Merge-OpenCodeConfig`/`Merge-KitBlock`/whitelist de tests en `scripts/sync-kit.ps1`, `.gitignore` con `opencode.json.bak-*` y `AGENTS.md.bak-*`, retiro de `.opencode/agents/pensador/spec.md`

### 035-consolidacion-backlog
- **Estado**: **En proceso** — ciclo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge). T01-T20 finalizadas. Decisión del usuario (2026-11-01): `pensador` como `default_agent`, respetando mecanismos nativos del arnés y con flujo idéntico entre `.github/` y `.opencode/`. Ampliación FR-14..FR-19 / CA-12..CA-15: propagación del arranque por `scripts/sync-kit.ps1` (D-07..D-09, sección 19 de la spec)
- **Ubicación**: `specs/035-consolidacion-backlog/`
- **Objetivo**: Que el cambio de "arranque por defecto con agentes propios" **se propague por los scripts de actualización del kit**, no solo por edición manual.
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, tests/harness-default.ps1, tests/kit-sync-merge.ps1; `opencode.json` L5, sección de arranque en `AGENTS.md` L117 envuelta en `KIT-BLOCK` (L117/L143), enrutamiento en `.github/copilot-instructions.md`, sección en `README.md`, `Ensure-OpenCodeDefaultAgent` en `scripts/plataformador-bootstrap.ps1`, `VAL-10` en `scripts/validate-agents-skills.ps1`, `Compare-KitFileState`/`Merge-OpenCodeConfig`/`Merge-KitBlock`/whitelist de tests en `scripts/sync-kit.ps1`, `.gitignore` con `opencode.json.bak-*` y `AGENTS.md.bak-*`, retiro de `.opencode/agents/pensador/spec.md`

### 036-sync-kit-paridad-motor
- **Estado**: **Implementación completada** — ciclo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge → implement F0-F8). Defectos D1-D5 corregidos y validados (SC-001..SC-010). Pendiente: verificación de paridad maestro→destino con el orquestador único (SC-002), commit con gitflow y TRANS-001 (gate mecánico, responsable `pensador`).
- **Deuda EOL (backlog)**: Divergencia restante documentada es solo fin de línea (CRLF vs LF) en `.github/rules` y `tests/` al comparar bruto; al normalizar a LF, paridad es 100% en todas las 7 áreas. Recomendación: alinear `core.autocrlf` + `.gitattributes` en el repo maestro para que futuros clones/ syncs dejen el contenido 100% idéntico sin necesidad de normalización posterior. Este punto queda abierto como deuda de backlog hasta que se normalice la configuración git del maestro.
- **Ubicación**: `specs/036-sync-kit-paridad-motor/`
- **Decisión de arquitectura (usuario, 2026-11-03)**: `scripts/sync-kit.ps1` es el **orquestador** estable (punto de entrada que invoca el bootstrap) y cada dominio es un script propio, ejecutable y depurable por separado. La marca `[021-DEPRECATED]` (commit `c56b56c`, 2026-10-16) se retira: nunca se cableó el reemplazo y el "deprecado" siguió siendo el único invocado. `sync-kit-agents.ps1` deja de ser un orquestador competidor y aporta su lista de capas al orquestador único.
- **Objetivo**: Llevar el sync del kit a **un orquestador + capas de dominio**: que un solo comando deje el kit transversal sincronizado, que el backup del llamador sobreviva a la poda, que la verificación del audit log sea capaz de validar sus propias entradas y que `graphify` quede con una única entrada apuntando al grafo del destino. Sin lógica de dominio dentro del orquestador.
- **Defectos cubiertos**: D1 poda de `.kit-backup` que borra el backup previo del operador; D2/D4 ausencia de capas para `skills`, `rules`, `prompts`, `workflows`, `copilot-instructions.md` y los 5 tests del kit; D3 `Test-AuditLogIntegrity` con falso negativo permanente (payload con `prevHash`, cadena no lineal y round-trip JSON que altera el `timestamp`); D5 doble entrada `graphify` con la ruta del maestro en el destino.
- **Artefactos**: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `converge.md`; scripts `sync-kit.ps1` (orquestador), `sync-kit-agents.ps1` (absorbido), `sync-skills.ps1`, `sync-github-extras.ps1`, `sync-tests-kit.ps1`, `sync-mcp-graphify.ps1`, `sync-backup-prune.ps1`, `sync/{opencode,kit-block,orphans,transversal}/*.ps1`; `tests/kit-sync-merge.ps1` (72 asserts), `tests/fixtures/baseline-036.md`; corrección en `upgrade_framework.ps1` (Test-AuditLogIntegrity) y fix de regresión `.gitignore` (`.kit-backup/`, `.kit-sync-temp/`).

### 037-mcp-gitignore-fix
- **Estado**: **Implementada** — ciclo SSD+Speckit completo (spec → plan → tasks → implement → verificación). Script y test en verde (`PASS=14 FAIL=0`), idempotencia confirmada en maestro y destino. Deuda declarada: T037-005 (integrar la invocación en el orquestador `sync-kit.ps1`) queda como backlog opcional.
- **Ubicación**: `Documentacion/Agents_IA_TECH/specs/037-mcp-gitignore-fix/`
- **Decisión de arquitectura (usuario, 2026-11-05)**: el alcance no es solo `graphify-out/*` sino **todo lo que no debe versionarse**. El script aplica un catálogo de 6 bloques (dependencias y entornos virtuales, artefactos de build, backups y temporales del kit, caches de herramientas incluido graphify, logs y temporales, sistema y editor) **solo a raíces de proyecto**, nunca dentro de `node_modules`, `.git`, `.venv`, `vendor`, caches ni backups.
- **Objetivo**: que cualquier proyecto gestionado por el kit excluya de forma determinista lo que no debe versionarse, con operación idempotente y reversible, sin tocar archivos de terceros ni commitear nada.
- **Defectos encontrados y corregidos durante la implementación**: (a) el patrón `**/.gitignore` no matcheaba el `.gitignore` de raíz; (b) el recorrido recursivo escribió en 196 `.gitignore` de rutas de terceros del destino (revertido con `-RemoveBlock -PruneRules`); (c) la reversión no entendía el formato histórico del bloque graphify (sin separador de cierre) y dejaba líneas huérfanas; (d) `*.log` habría ignorado `.bootstrap-audit.log`, versionado por gobernanza (corregido con `!.bootstrap-audit.log`).
- **Artefactos**: `spec.md`, `plan.md`, `tasks.md`; `scripts/sync-gitignore.ps1` (catálogo, exclusiones duras, `-Sets`/`-WhatIf`/`-RemoveBlock`/`-PruneRules`/`-OnlyExcluded`/`-AllGitignore`), `tests/sync-gitignore.Tests.ps1` (14 asserts sin Pester); `.gitignore` raíz del maestro y 13 raíces de `Generator_IA_Projects` actualizadas.
- **Verificación**: `tests/sync-gitignore.Tests.ps1` → `PASS=14 FAIL=0`; `tests/harness-default.ps1` → `RESULTADO: OK`; segunda corrida en ambos repos → `Archivos actualizados: 0`; `git ls-files -i -c --exclude-standard` sin regresiones nuevas.

---
### plataforma-bootstrap-instalador-unico
**Estado**: En planificación — fase documental lista; tareas de implementación T-I7/T-I8/T-V5/T-V6 pendientes  
**Ubicación**: specs/plataforma-bootstrap-instalador-unico/
**Objetivo**: Convertir `plataformador-bootstrap.ps1` en el instalador/actualizador único del ecosistema (sync kit transversal, configuración de MCPs, indexación, preparación de apps, Spec-kit y Graphify), respetando la frontera de no tocar `Documentacion/<AppName>/`

### 038-provisionamiento-externo-y-config-generada
- **Estado**: **Borrador** (2026-11-07) — `spec.md` y `checklists/requirements.md` escritos; pendiente aprobación del usuario para pasar a `plan.md`.
- **Ubicación**: `specs/038-provisionamiento-externo-y-config-generada/`
- **Decisión de arquitectura (usuario, 2026-11-07)**: (1) autoridad de versión de `kit-integrado` = **branch head** (SHA), no release tag; el versionado semántico queda en backlog atado al instalador del KIT; (2) `opencode.json` **no se versiona**: plantilla + generador para OpenCode y otro para GitHub Copilot, con paridad verificada; (3) el clon de ECC y spec-kit vive **fuera de la raíz del workspace**; (4) la integración de código de terceros es **integración asistida por IA**, no copia, y se separa en la spec 039.
- **Objetivo**: que cualquier workspace responda con un comando de solo lectura si sus dependencias externas están instaladas y al día según su tipo, y que la configuración de los arneses se **genere** desde esa fuente en lugar de mantenerse a mano.
- **Alcance**: taxonomía de aprovisionamiento (5 tipos) con declaración obligatoria en el manifest; sondas de versión por tipo; estado por workspace `.opencode/mcp-state.json`; verbos `validate` / `apply` / `generate`; generación dual OpenCode + Copilot con `validate-parity`; matriz `capacidades-por-harness.md` con cuatro estados y fuente obligatoria; aislamiento del clon externo; forma canónica única `mcp.servers`; documento `provisionamiento-externo.md`.
- **Evidencia que la origina**: `context-mode` declarado contra `build/cli.js` inexistente (instalado 2.1.0 usa `cli.mjs`); manifest con `context-mode` v1.0.169 y `spec-kit` `v0.0.0` sin verificación; ECC, context7, playwright y github no declarados; `git status` no detecta que spec-kit está en `1.0.7.dev0` frente a `v1.3.2`; dos formas de configuración conviviendo (`mcp.servers` y `mcp.<nombre>`); `AGENTS.md` de clones externos inyectados en la sesión; `.github/hooks/` documentado pero inexistente.
- **Fuera de alcance (backlog)**: versionado por release tag/semver; integración controlada de `kit-integrado` (spec 039); **las cuatro inconsistencias que la matriz declara (specs 040–043, una por inconsistencia)**; instalador único del KIT; evaluación con respuestas reales del LLM.
- **Artefactos actuales**: `spec.md`, `checklists/requirements.md`; `arquitectura/adr/adr-0014-configuracion-generada-y-provisionamiento-por-tipo.md`; `arquitectura/constitution-v2.1.0-enmienda.md` (propuesta, pendiente de aplicar).
- **Preparación de las specs 040–043**: la matriz registra en cada capacidad su estado (`soportado`, `equivalente-distinto`, `soportado-con-limite`, `no-soportado`), su `spec_responsable` y su `prueba`. `validate-parity` devuelve FAIL si un agente usa una capacidad no declarada, y WARN si una fila no tiene `spec_responsable`. 038 no corrige ninguna de esas inconsistencias.
- **Próximo paso**: `plataformador` aplica la enmienda v2.1.0 (el tier documental tiene `edit` denegado sobre `.specify/`), y después `Agent-SSD` ejecuta `speckit-plan`.

### 039-eliminar-rutas-hardcoded-documentacion
- **Estado**: **Aprobada — v1.0.0** (2026-11-09) — Ciclo Speckit completo (spec → plan → tasks → analyze → converge). Converge aprobado para implementación. **AC-1/AC-2 superados por la Spec 044** (universo de validación pasa de lista de directorios a `git ls-files`); no se archiva.
- **Ubicación**: `specs/039-eliminar-rutas-hardcoded-documentacion/`
- **Objetivo**: Eliminar todas las rutas absolutas hardcodeadas (`$KitPath`, `C:<sep>Proyectos\opencode`) de la documentación (`README.md`, `AGENTS.md`, `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`), scripts (`sync-agents.ps1`, `scripts/*.ps1`), y artefactos generados; reemplazarlas por variables con comentarios explicativos (`$KitPath`, `$ProjectRoot` + `# <- ajusta a tu ruta`), rutas relativas, o parámetros de línea de comandos (`-RootPath`, `-KitPath`, `-CheckHardcodedPaths`); agregar validación en el bootstrap; limpiar artefactos de prueba con rutas locales; y agregar test de regresión automatizado.
- **Métricas**: 8 RF (RF-01..RF-08), 3 NFR, 5 AC, 35 tareas, 1 ADR (ADR-039), 1 Threat Model. Cobertura 100% RFs y ACs.
- **Artefactos**: spec.md (1.0.0), plan.md (1.0.0), tasks.md (1.0.0), analyze.md (1.0.0), converge.md (1.0.0), adr-039-rutas-portables.md (1.0), threat-model-039-hardcoded-paths.md (1.0), quickstart.md (1.0.0).
- **Patrones clave (ADR-039)**:
  1. **Documentación**: `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` / `$ProjectRoot = "C:<sep>Proyectos\MiProyecto"  # <- ajusta a tu ruta`
  2. **Scripts PowerShell**: `$PSScriptRoot` + parámetros `-RootPath`/`-KitPath` (defaults seguros)
  3. **Scripts Bash**: `$SCRIPT_DIR` / `dirname "$SCRIPT_DIR"` para raíz del kit
  4. **Bootstrap**: `param([string]$RootPath = ".", [string]$KitPath = $PSScriptRoot, [switch]$CheckHardcodedPaths)`
- **Validación**: Test Pester `tests/validate-no-hardcoded-paths.Tests.ps1` (patrones: `C:<sep>Proyectos`, `D:<sep>`, `/<home>/`, `/<Users>/`; excepción: comentarios `#` con `$KitPath`/`$ProjectRoot`); bootstrap flag `-CheckHardcodedPaths` escanea proyecto destino.
- **Limpieza externa (one-time)**: Eliminar `C:<sep>Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md`.
- **Próximo paso**: `/speckit-implement` (delegado a `Agent-SSD` bajo orquestación `pensador`): `documentador` → README.md + AGENTS.md; `plataformador` → scripts + bootstrap + limpieza; `qa-senior` → test Pester + CI.
### 044-portabilidad-validacion-sin-exclusiones
- **Estado**: **Implementada — v1.0.0** (2026-11-09) — spec, plan, tasks y analyze completos; implementación aplicada y validacion automatica en verde (16/16 Pester); AC-7, AC-8 y AC-9 pendientes de ejecucion manual; sin commit.
- **Ubicación**: `specs/044-portabilidad-validacion-sin-exclusiones/`
- **Objetivo**: sustituir el validador de portabilidad basado en una allowlist de directorios por uno fail-closed cuyo universo es `git ls-files` (todo archivo versionado), y remediar las 236 coincidencias en 34 archivos que la Spec 039 dejó pasar.
- **Causa raíz**: el validador de la 039 decidía su propio universo. Cualquier lista de rutas es fail-open: cada directorio nuevo nace fuera de cobertura, y el test se autoexcluía para poder pasar.
- **Métricas**: 12 RF (RF-01..RF-12), 5 NFR, 6 decisiones (D1-D6), 10 AC (AC-1..AC-10), 28 tareas (T001..T028), 8 hallazgos de analyze.
- **Artefactos**: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `tests/fixtures/portabilidad-baseline-044.md`.
- **Patrones prohibidos (definición final)**: raíz de proyectos, perfil de usuario, intérprete Python y runtime Node de la máquina del autor, unidad ajena completa y prefijos de home POSIX. No se prohíbe toda ruta con letra de unidad: los ejemplos genéricos de las skills son documentación legítima y no filtran el layout.
- **Validación**: `tests/validate-no-hardcoded-paths.Tests.ps1` (universo `git ls-files`, 14 grupos + 2 meta, auto-inclusión) y `scripts/plataformador-bootstrap.ps1 -CheckHardcodedPaths` (fail-closed, exit 1). CI: `.github/workflows/portability.yml`.
- **Relación con la 039**: la 039 sigue activa; la 044 amplía su criterio de aceptación (el universo pasa de lista de directorios a conjunto versionado). No se archiva ninguna.
- **Fuera de alcance (separado por decisión del usuario, 2026-11-09)**: el hook `context-mode` → spec **045**; la generación portable de `opencode.json` (G1-G4) → spec **046**. La 044 se limita a validador, patrones, remediación y CI.

### 045-retirar-pretooluse-hook-context-mode
- **Estado**: **Aprobada — v2.0.0** (2026-11-11) — ciclo Speckit completo (spec → plan → tasks → analyze → converge). Implementación **parcial**: registro y documentación cerrados; `Ensure-ContextHooks` y `validar-mcps.ps1` todavía contradicen la decisión (T005-T006, delegadas a `developer`). AC-4 pendiente de recarga del arnés.
- **Ubicación**: `specs/045-retirar-pretooluse-hook-context-mode/`
- **Renombre**: antes `045-hook-context-mode-lecturas-bloqueadas`. El slug describe ahora **la decisión** (retirar `PreToolUse`), no el síntoma (lecturas bloqueadas).
- **Problema**: `PreToolUse` de `context-mode` devolvía `permissionDecision: "deny"` para cualquier archivo de más de 16 384 bytes (constante interna `16384`, sin variable de entorno; sigue fija en `context-mode 2.1.0`). En este kit, specs y bitácoras superan ese tamaño, así que el agente reportaba "todas las herramientas rechazadas".
- **Evidencia**: `Read` de 39 590 bytes → deny; `Edit`, `Bash` y `mcp__github__list_workflows` → allow. El bloqueo nunca afectó a GitHub Actions.
- **Decisión**: se retira solo `PreToolUse` del registro `.github/hooks/context-mode.json`; se conservan `SessionStart` y `PostToolUse`. Respaldo `.github/hooks/context-mode.json.bak-20261109`.
- **Hallazgo crítico (H1)**: el registro **es generado** por `Ensure-ContextHooks` (bootstrap L1436-1477), que aún emite `PreToolUse`. Un `bootstrap -Force` o un clon nuevo revierten la decisión: la política debe vivir en el generador.
- **Hallazgo crítico (H2)**: `validar-mcps.ps1` (L230-235) exige `PreToolUse` y hoy imprime `[FAIL] Falta hook 'PreToolUse'`: el kit se contradice a sí mismo.
- **Artefactos**: `spec.md` (v2.0.0), `plan.md`, `tasks.md` (14 tareas, 8 cerradas), `analyze.md`, `converge.md`, bitácora `bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md`.
- **Rollback**: `Copy-Item .github/hooks/context-mode.json.bak-20261109 .github/hooks/context-mode.json -Force`.
- **Seguimiento**: re-habilitar `PreToolUse` solo si el umbral pasa a ser configurable o supera el tamaño máximo de la documentación; exige **spec nueva**, no una edición del JSON.

### 046-generacion-portable-opencode-json
- **Estado**: **Borrador con plan y tasks** (2026-11-10) — `spec.md`, `plan.md` y `tasks.md` escritos (22 tareas); pendiente implementación. Incluye la regla de oro: los artefactos generados no se editan a mano.
- **Ubicación**: `specs/046-generacion-portable-opencode-json/`
- **Validado**: la generación de `opencode.json` existe y funciona (`scripts/sync/mcp/lift-opencode.ps1`, capa `mcp-lift-opencode` de `sync-kit-agents.ps1`, modo individual y bootstrap). En un destino vacío crea el archivo con `default_agent: pensador` y 8 entradas `mcp.servers`.
- **Defectos (G1-G4)**: el generado hereda las rutas absolutas del maestro; `graphify` no se regenera al destino; `tokenslayer` apunta al kit; el bootstrap no crea el archivo si falta y no hay plantilla.
- **Alcance**: maestro = `opencode.template.json`; regeneración de `graphify` con `$RootPath`; `tokenslayer` relativo o degradado con WARN; generación desde plantilla en el bootstrap; backup y `-DryRun` obligatorios.
- **Relación**: ejecuta la parte pendiente de 038 D2 y resuelve 020-T016 y 036 D5.


