# Índice de Agents_IA_TECH

> Proyecto base de agentes y herramientas del ecosistema.
> Generado por plataformador-bootstrap.ps1.

## Componentes clave
- gents/
- .github/
- .opencode/
- scripts/
- Documentacion/Agents_IA_TECH/

## Objetivo
Asegurar que cada proyecto tenga su documentación, la estructura base y los MCPs listos antes de reorganizar archivos.

## Especificaciones activas
- 009-mcp-update-lifecycle: Script independiente de actualización de MCPs con auto-actualización diaria
- 010-secret-leak-remediation: Remediación de fuga de API key en historial Git y hardening de gitleaks
- **011-bootstrap-invokes-upgrade-framework: Bootstrap delega sync dependencias externas en upgrade_framework (fail-open, no hardcoded URLs)**
- **015‑MCP‑Integration‑Flow** – Flujo transversal de integración de MCP alineado con Spec 015. *Ubicación*: `specs/015-mcp-integration-flow/` (ACTIVA, operativa). *Estado*: Completado — flujo SSD completado, spec lista para producción y ACTIVA en `specs/`. `Cerrar` = completar flujo, NO archivar; `Archivar` (`specs/archived/`) solo al retirar del flujo.
- **013‑MCP‑Integration‑Flow** – Integración del módulo ECC alineada con Spec 015. *Ubicación*: `specs/013-mcp-integration-flow/` (ACTIVA, operativa). *Estado*: Completado — T001–T008 ejecutadas, spec lista para producción y ACTIVA en `specs/`. `Cerrar` = completar flujo, NO archivar.
- **017-pendientes-implementacion-por-app: Archivo vivo por proyecto con estado de tareas y responsables** — ✅ **Completado (T001-T016)**. Mecanismo implementado: `Ensure-PendientesImplementacion` en `scripts/plataformador-bootstrap.ps1` (crea el archivo desde plantilla si no existe + detecta obsoleto); sección obligatoria de actualización post-fase en `Agent-SSD` (`.github/` + `.opencode/`); plantilla en `Documentacion/templates/pendientes-implementacion-template.md`. **Regla de agregación multi-spec**: el archivo es un agregado del PROYECTO (consolida TODAS las `specs/*/tasks.md`), con IDs calificados `<spec-id>-T<nnn>` y sin auto-referencia del feature que implementa el mecanismo. Validado Art.VII/Art.IX (PASS).
- **018-pendientes-estados-scrum: Estados Scrum por agente y whitelist Art-VII por tier** - **En proceso (T001-T007 cerradas, T008-T009 en curso)**. Reglas `## Rol Scrum` + marcador `MCP-ROLE-v1` en 16 `.github` + 16 `.opencode`; campo `tier:` declarado en frontmatter de los 32 agentes (6 Documental, 1 Documental extendido, 4 Implementador, 1 Tooling, 4 Plataforma); plantilla con columnas Estado/Asignado a. *Ubicacion*: `specs/018-pendientes-estados-scrum/`.
- **020-mcp-config-operativa: Configuracion MCP operativa verificada en vivo (baseline)** - **Completado**. Congela `opencode.json` con 9 MCP hardcodeados (ADR-0009) + indices (codebase-memory ready 5.664 nodos, graphify 4.793 nodos 100%, context-mode 9 archivos) + procedimiento de verificacion viva y orden de diagnostico. *Ubicacion*: `specs/020-mcp-config-operativa/`.
- **021-sync-kit-agents: Orquestador de sync por capas (Stage temporal + clean+replace + plataformar)** - Fases 1-3 completas y verificadas (docs, agents x3, kit-files, constitutions, src-structure, mcp install+lift; 10 capas). Pendiente fase 4 (indexing, externals, prueba en consumidor). *Ubicacion*: `specs/021-sync-kit-agents/`.
- **022-ecc-integration: Integracion ECC por copia con espejo por harness via script** - `sync/skills/sync-skills.ps1` verificado (76 fachadas integradas + espejo 76/76 + rules). *Ubicacion*: `specs/022-ecc-integration/`.
- **023-ecc-workflows: Workflows CI propios derivados de ECC** - `validate-skills.yml` + `supply-chain-watch.yml`; 8 workflows ECC rechazados con dano documentado. *Ubicacion*: `specs/023-ecc-workflows/`.

## Especificaciones en proceso
- **012-ecc-integration**: Integración selectiva de ECC como proyecto externo `proyect_ext/ECC`. Análisis comparativo y hoja de ruta en curso. Índice en `specs/012-ecc-indice.md`

### Integración ECC — Familia de specs 012 y estado de tareas
**Objetivo**: Incorporar capacidades de ECC como proyecto externo en `proyect_ext/ECC` sin reemplazar flujo Speckit/SSD. Namespace `ecc-` obligatorio, paths permitidos por Constitución Art.VII.

**Specs relacionadas 012**:
- `specs/012-ecc-integration/` — Especificación base, spec.md, plan.md, tasks.md, guía-integracion-selectiva.md
- `specs/012-ecc-integration-lifecycle/` — Ciclo de vida install/update/validate/uninstall con `ecc-sync.ps1`
- `specs/012-ecc-mcp-bridge/` — Puente ECC ↔ MCPs y contrato de intercambio
- `specs/012-ecc-mcp-migration/` — Migración .env.mcp → mcp-configs/mcp-servers.json
- `specs/012-ecc-indice.md` — Índice central de familia 012

**Estado de tareas 012-ecc-integration** (según `pendientes-implementacion.md` actualizado 2026-10-04):
- Completadas T001-T007:
  - 012-T001 Clonar ECC en proyect_ext/ECC — `plataformador`
  - 012-T002 Inventariar carpetas clave ECC — `analista-tecnico`
  - 012-T003 Crear matriz de correspondencia ECC ↔ Agents_IA_TECH — `analista-tecnico`
  - 012-T004 Identificar capacidades ECC no presentes — `analista-tecnico`
  - 012-T005 Priorizar importación — `pensador`
  - 012-T006 Definir namespace y reglas de no-duplicación — `arquitecto`
  - 012-T007 Escribir guía de integración selectiva — `documentador`
- Pendientes:
  - 012-T008 Actualizar 00-indice.md con referencia a ECC — `documentador` — **en curso**
  - 012-T009 Registrar ADR de integración — `arquitecto`
  - 012-T010 Validar spec/plan/tasks con usuario — `pensador`
  - 012-T011 Congelar spec para refinamiento futuro — `pensador`

**Artefactos clave**:
- `specs/012-ecc-integration/spec.md` — FR-001 a FR-006, NFR-001 a NFR-003, criterios SC-001 a SC-005
- `specs/012-ecc-integration/plan.md` — Fases Análisis, Definición de alcance, Documentación, Preparación
- `specs/012-ecc-integration/guia-integracion-selectiva.md` — Procedimiento de importación con namespace ecc-, validaciones obligatorias
- `specs/012-ecc-integration/gaps-012-T004.md` y `priorizacion-012-T005.md` — Análisis de gaps y priorización

**Próximos pasos**:
1. Completar 012-T008 actualización de índice
2. Registrar ADR de integración 012-T009
3. Validación usuario 012-T010 y congelar spec 012-T011
4. Iniciar integración lifecycle 013 con `ecc-sync.ps1`

---

## Spec #011 — Bootstrap Invokes upgrade_framework (Converge Completed)

**Fecha converge**: 2026-09-25  
**Fecha revisión seguridad**: 2026-10-05  
**Estado**: Documental completo → Seguridad parcialmente validada  
**Estado seguridad**: T059 APROBADO con evidencia QA; T040-T058, T060-T064 sin evidencia verificable  
**Agente responsable**: `documentador` (solo documentación)

### Artefactos generados/actualizados
| Archivo | Versión | Estado |
|---------|---------|--------|
| `specs/011-bootstrap-invokes-upgrade-framework/spec.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/plan.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/tasks.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/analyze.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/converge.md` | 1.1.0 | **Consolidado + Security review 2026-10-05** |
| `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` | 1.0.0 | Accepted |
| `seguridad/qa-evidence-011-T059-dryrun.md` | 1.0.0 | APROBADO 2026-10-04 |

### Documentación transversal actualizada
| Archivo | Actualización |
|---------|---------------|
| `quickstart.md` | Sección 4: `-ForceUpgradeTools` — sync externo + tokenslayer + 4to MCP |
| `memoria-proyecto.md` | Nueva capacidad registrada con flags, comportamientos, referencias |
| `pendientes-implementacion.md` | Tareas T001-T031 + security-risk T040-T064 listas para implementar |

### Decisiones clave (ADR-0007)
1. **Delegación total** a `upgrade_framework` (SRP)
2. **Fail-open obligatorio** — exit code siempre 0
3. **Cero URLs hardcodeadas** — todo desde manifest
4. **Opt-in via `-ForceUpgradeTools`** — gating completo
5. **Primera ejecución copia manifest template** — idempotente
6. **Frontera kit↔app respetada** — `Documentacion/<AppName>/` intocable

### Guardrails (8 restricciones para implementación)
1. Fail-open en toda llamada externa (try/catch + WARN + continue)
2. No hardcodear URLs en bootstrap
3. `-DryRun` propaga y no escribe nada
4. Idempotencia: re-ejecutar no duplica ni rompe
5. Frontera kit↔app: NO tocar `Documentacion/<AppName>/`
6. Propagación correcta de flags (`-ForceUpgradeTools`, `-DryRun`, `-SkipSync`)
7. Logging estructurado (INFO/WARN/ERROR)
8. Containment de `proyect_ext/` bajo `<root>/proyect_ext/`

### Riesgos seguridad (Threat Model STRIDE)
- **11 CRITICAL** (supply chain, tampering, info disclosure, DoS, elevation)
- **9 HIGH** (identity, manifest immutability, timeouts, schema validation)
- **4 MEDIUM** (audit logging, locks)
- **1 LOW** (allowlist rotation)
- Todos etiquetados `security-risk:` en `tasks.md` para priorización automática

### Próximos pasos
Implementación por `api-developer` / `devops` / `qa-senior` siguiendo orden de dependencias:
- Fase A: T001→T002 (CLI upgrade_framework)
- Fase B: T010→T011→T012→T013 (Bootstrap integration)
- Fase C: T020→T021 (Manifest template)
- Fase D: T030→T031 (Integration tests)
- Security: T040-T058, T060-T064 pendientes de evidencia QA; T059 validado
- Acción inmediata: generar evidencias QA para T040-T058 y T060-T064 antes de cerrar seguridad 011

## Especificación 016 - Enforcement of SSD+Speckit Flow via Agents
- **Estado**: Completada/Cerrada — flujo SSD completo, lista para producción, permanece ACTIVA en `specs/` (archivar solo al retirar del flujo)
- **Ubicación**: specs/016-ssd-enforcement/ 
- **Objetivo**: Forzar flujo SSD+Speckit mediante reglas obligatorias en agents y gatekeeper en pensador.
- **Artefactos**: spec.md, plan.md, tasks.md

## Especificación 024 - Hooks de gobernanza y determinismo
- **Estado**: En proceso — spec/plan/tasks/analyze/converge creados
- **Ubicación**: specs/024-hooks-gobernanza-determinismo/
- **Objetivo**: Hooks pre-commit, gate PR, checksum Speckit y determinismo de harnesses
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 025 - Actualización automática herramientas externas
- **Estado**: En proceso — spec/plan/tasks/analyze/converge creados
- **Ubicación**: specs/025-actualizacion-herramientas-externas/
- **Objetivo**: Hook diario y CI semanal para upgrade_framework y propagación vía sync-kit
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 026 - Agente developer único
- **Estado**: Completada — flujo Speckit completo spec/plan/tasks/analyze/converge, agentes obsoletos eliminados y Constitución actualizada
- **Ubicación**: specs/026-agente-developer-unico/
- **Objetivo**: Unificar implementadores en un agente developer con skills especializadas y context7
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 027 - Patrón estructura de proyecto
- **Estado**: En proceso — spec/plan/tasks/analyze/converge creados
- **Ubicación**: specs/027-patron-estructura-proyecto/
- **Objetivo**: Estructura canónica obligatoria Documentacion/<App>/ + src/<App>/ y validación
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 028 - Public Docs Routing
- **Estado**: Completada — flujo Speckit completo spec/plan/tasks/analyze/converge/implement
- **Ubicación**: specs/028-public-docs-routing/
- **Objetivo**: Routing docs públicas a `src/<App>/docs/` y README a `src/<App>/README*.md`; delegación documentador→developer
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, ADR-0011-public-docs-routing.md, skill public-documentation

## Especificación 029 - Sync honesto: EOL normalizado y `-Force` efectivo
- **Estado**: En proceso — implementación iniciada. 37 tasks en `tasks.md`; **2 cerradas** (T028, T030); 35 pendientes. T036 fue **revertida de `[x]` a `[ ]`** el 2026-10-29 (nota en `tasks.md` L123) porque se había marcado apoyándose en `tests/upgrade_framework.Tests.ps1`, que no compila (DD-08). T025 y T036 están bloqueadas por DD-08
- **Ubicación**: `specs/029-sync-eol-y-force-real/`
- **Objetivo**: Que el sync distinga contenido igual / igual-salvo-EOL / distinto con mensajes observables, y que `-Force` y `-DryRun` sean flags explícitos de `Sync-TransversalKit` (sin dynamic scoping); escritura LF y bloque `mcp` local intacto
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, checklists/requirements.md. Fases 1-8 de `tasks.md`; Fase 8 (T030..T037) derivada de Analyze el 2026-10-28. T038 descartada con evidencia
- **Deudas abiertas** (registradas en `pendientes-implementacion.md`): **DD-08** (`tests/upgrade_framework.Tests.ps1` no compila: 4 errores de parseo, la suite del kit nunca corrió; bloquea T025, T036 y NFR-02 entero) y **DD-09** (NFR-02 se apoya en una suite que no toca el motor y no compila; hasta resolverlo NFR-02 es aspiración, no gate)

## Especificación 030 - Whitelist contextual por tipo de proyecto y agentes como orquestadores
- **Estado**: Especificada — Analyze **PASS con observaciones** (`arquitecto` + `security-auditor`), **Converge completado** 2026-10-29. **Implementación NO iniciada**: 66 tasks en `tasks.md`, 0 ejecutadas
- **Ubicación**: `specs/030-whitelist-contextual-por-tipo-proyecto/`
- **Objetivo**: Que la whitelist de escritura sea contextual al tipo de proyecto (`kit` | `consumidor`), determinista y sin fuga del kit hacia los consumidores; y replantear los agentes como orquestadores delgados con las capacidades de procedimiento en skills declaradas en el frontmatter
- **Métricas**: 23 FR (FR-01..FR-11, FR-02b, FR-12..FR-22), 12 CA (CA-01..CA-12), 6 NFR, 66 tasks, cobertura verificada 23/23 FR y 12/12 CA
- **Artefactos**: spec.md (1.1.0), plan.md (1.1.0), tasks.md (1.2.0), analyze.md (1.0.0), threat-model.md (1.0.0), checklists/requirements.md (1.0.0), converge.md. ADR-0013 aceptado y registrado en `arquitectura/adr/00-index.md`
- **Decisiones pendientes** (bloquean tasks): D-01 (`usuario-preferencias` vs Constitution → bloquea T020), D-02 (`plataformador` fragmentar → task no creada), D-03 (`gitflow` retirar o delgado → bloquea T021). D-04 resuelta: `Agent-SSD` y `pensador` NO se fusionan
- **Deudas registradas en converge.md**: 030-DD-01 (FR-11 sin cambio `C-NN` en el plan), 030-DD-02 (`terminal`/`execute` sin acotar en el consumidor), 030-DD-03 (anti-fuga del marcador sin test permanente), 030-DD-04 (skills nuevas sin validación de contenido; IP SSH propagable), 030-DD-05 ("workspace completo" del `developer` en kit sin denylist)

---

## Especificación 031 - Permisos, dominio y delegación de agentes
- **Estado**: Cerrado — flujo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model). CA-01..CA-12 todos cumplidos. Absorbe los borradores 034 (comportamiento), 035 (delegación) y 037 (permisos)
- **Ubicación**: `specs/031-permisos-y-dominio-de-agentes/`
- **Objetivo**: Que todo agente opere bajo un contrato único y verificable de dominio de escritura, prohibiciones absolutas, delegación y autorización de operaciones críticas (`[S]`/`[N]`/`[C]`), con sesión SSH única por servidor reutilizable y auditada
- **Métricas**: 24 FR (FR-01..FR-24), 7 NFR, 7 historias de usuario, 12 CA (CA-01..CA-12), matriz de permisos por operación y por agente
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0, FAIL=0 WARN=52 (solo VAL-09, aviso por diseño). Suite `tests/validate-agents-skills.Tests.ps1`: 20/20 en verde. Test de contrato `tests/agents-parity.ps1`: exit code 0, fixture negativo detecta divergencia. `analyze.md` y `threat-model.md` verificados (sin placeholders, sin secciones vacías). CA-01..CA-12 todos cumplidos
- **Paridad lograda**: los 13 agentes tienen cuerpo idéntico en `.github/agents/<n>.agent.md` y `.opencode/agents/<n>.md`; solo difiere el frontmatter nativo de cada arnés (`tools`/`user-invocable` vs `mode`/`temperature`/`permission`). `tier`, `description` y el conjunto de `skills` son iguales en ambos lados
- **Artefactos de esta iteración**: skill `threat-modeling` creada en ambos arneses; `tier` corregido en `pensador`, `security-auditor` y `usuario-preferencias`; `testing` reemplazada por `tdd-workflow` + `verification-loop` en `developer`; `dominio_check` y protocolo de autorización con `[S]`/`[N]`/`[C]` en ambos arneses; `plataformador` restaurado a su versión completa (474 líneas, `5513d37`) con `Enfoque` y `Constraints`; 8 agentes nivelados a la estructura de Regla 2 (38 violaciones cerradas)
- **Specs hermanos registrados**: 032 (actualización de Knowledge Base tras spec validada — ciclo SSD+Speckit completo, implementación parcial con limitaciones de herramientas MCP) y 033 (refresh de conocimiento e índices de MCP en la primera ejecución del día — ciclo SSD+Speckit completo, implementación T08-T10 pendiente de primera ejecución del día real)

## Especificación 033 - Refresh de conocimiento e índices de MCP en la primera ejecución del día
- **Estado**: En proceso — ciclo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge); implementación parcial: T01-T07 cerradas, T08-T10 pendientes de primera ejecución del día real
- **Ubicación**: `specs/033-refresh-conocimiento-mcp/`
- **Objetivo**: Que la primera ejecución del día dispare automáticamente el refresh de conocimiento e índices de todos los MCP del proyecto (`codebase-memory-mcp`, `graphify`, `context-mode`, `markitdown`, `tokenslayer`, `github`, `playwright`, `context7`), para que los agentes consulten información actualizada sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0. Test de contrato `tests/mcp-refresh-parity.ps1`: exit code 0, fixture negativo detecta divergencia. CA-06 cumplido; CA-01..CA-05, CA-07..CA-12 pendientes de ejecución real del refresh MCP
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, pipeline-refresh-mcp.md, tests/mcp-refresh-parity.ps1
- **Limitación documentada**: T08-T10 no se pueden completar hasta la próxima primera ejecución del día real (dependencia operativa, no de especificación)


## Especificación 032 - Actualización de Knowledge Base tras spec validada
- **Estado**: Cerrado — flujo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge). Implementación parcial: T01-T07 cerradas, T08-T10 con limitaciones (faltan herramientas MCP `graphify.extract`, `context-mode.ctx_index`, `codebase-memory-mcp.search_graph`)
- **Ubicación**: `specs/032-actualizacion-knowledge-base/`
- **Objetivo**: Que el cierre de una spec dispare la actualización de CodeBase (codebase-memory-mcp), Context (context-mode) y Graphify (graphify), para que los agentes consulten el contenido de specs validadas vía MCPs sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0. Test de contrato `tests/kb-parity.ps1`: exit code 0, fixture negativo detecta divergencia. CA-06 cumplido; CA-01..CA-05, CA-07..CA-12 pendientes de ejecución real de pipeline KB
- **Artefactos**: spec.md, plan.md, tasks.md, pipeline-kb.md, analyze.md, threat-model.md, converge.md, tests/kb-parity.ps1
- **Limitación documentada**: T08 no se completó al 100% por falta de herramientas MCP en el catálogo. El repositorio ya está indexado en codebase-memory-mcp (11,399 nodos) y graphify (4,973 nodos, 467 comunidades).

---

*Última actualización del índice: 2026-10-31 (registrada la spec 031; antes la última entrada era la 030).*

