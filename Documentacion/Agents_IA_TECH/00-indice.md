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

---
### plataforma-bootstrap-instalador-unico
**Estado**: En planificación — fase documental lista; tareas de implementación T-I7/T-I8/T-V5/T-V6 pendientes  
**Ubicación**: specs/plataforma-bootstrap-instalador-unico/
**Objetivo**: Convertir `plataformador-bootstrap.ps1` en el instalador/actualizador único del ecosistema (sync kit transversal, configuración de MCPs, indexación, preparación de apps, Spec-kit y Graphify), respetando la frontera de no tocar `Documentacion/<AppName>/`
