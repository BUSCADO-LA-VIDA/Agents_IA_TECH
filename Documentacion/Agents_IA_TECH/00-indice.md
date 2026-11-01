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
- ~~009-mcp-update-lifecycle~~: **ARCHIVADA/FUSIONADA en `020-mcp-config-operativa` (fase D, spec 035)** — Script independiente de actualización de MCPs con auto-actualización diaria. El script `scripts/update-mcp.ps1` que definía ya existe en disco y 020 lo congeló como baseline; su converge quedó desactualizado. Movida a `specs/archived/009-mcp-update-lifecycle/`.
- 010-secret-leak-remediation: Remediación de fuga de API key en historial Git y hardening de gitleaks
- **011-bootstrap-invokes-upgrade-framework: Bootstrap delega sync dependencias externas en upgrade_framework (fail-open, no hardcoded URLs)**
- **015‑MCP‑Integration‑Flow** – Flujo transversal de integración de MCP alineado con Spec 015. *Ubicación*: `specs/015-mcp-integration-flow/` (ACTIVA, operativa). *Estado*: Completado — flujo SSD completado, spec lista para producción y ACTIVA en `specs/`. `Cerrar` = completar flujo, NO archivar; `Archivar` (`specs/archived/`) solo al retirar del flujo.
- ~~**013‑MCP‑Integration‑Flow**~~ – **ARCHIVADA/FUSIONADA en `015-mcp-integration-flow` (fase D, spec 035)**. Integración del módulo ECC. Movida a `specs/archived/013-mcp-integration-flow/` con `NOTA-ARCHIVO.md`; sin contenido único que conservar (mismo flujo MCP/ECC que la canónica 015).
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
- `specs/013-ecc-integration-lifecycle/` — Ciclo de vida install/update/validate/uninstall con `ecc-sync.ps1`
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
- **Estado**: Completada/Cerrada — flujo SSD completo, lista para producción, permanece ACTIVA en `specs/` (archivar solo al retirar del flujo). Fase C (spec 035): absorbida por **ADR-0005** (Agent-SSD orquestador del flujo SSD) → estado **CERRADA-POR-ABSORCION-ADR**; nota en `NOTA-CONSOLIDACION.md`.
- **Ubicación**: specs/016-ssd-enforcement/ 
- **Objetivo**: Forzar flujo SSD+Speckit mediante reglas obligatorias en agents y gatekeeper en pensador.
- **Artefactos**: spec.md, plan.md, tasks.md, NOTA-CONSOLIDACION.md

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
- **Estado**: Especificada — ciclo Speckit completo (spec/plan/tasks/analyze/converge); **implementación NO ejecutada** (el `converge.md` dice "Converge completado, listo para implementación"). ⚠️ El índice marcaba "Completada" por error: el converge declara estado pre-implementación.
- **Ubicación**: specs/026-agente-developer-unico/
- **Objetivo**: Unificar implementadores en un agente developer con skills especializadas y context7
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 027 - Patrón estructura de proyecto
- **Estado**: En proceso — spec/plan/tasks/analyze/converge creados. **Decisión de dirección (fase D, spec 035, usuario 2026-11-01)**: `021-estructura-inicial-apps-nuevas` es la OPERATIVA (8 tasks pendientes de creación de apps); `027-patron-estructura-proyecto` se tratará como **patrón normativo** al que 021 referenciará (completar el patrón en iteración dedicada). En esta fase solo se registra la decisión de dirección; el patrón completo se implementa en otra iteración.
- **Ubicación**: specs/027-patron-estructura-proyecto/
- **Objetivo**: Estructura canónica obligatoria Documentacion/<App>/ + src/<App>/ y validación
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, pendientes-implementacion.md

## Especificación 021 - Estructura inicial de apps nuevas
- **Estado**: **En proceso / operativa** — 8 tasks pendientes reales de creación de apps. **NO archivada** (fase D, spec 035, usuario 2026-11-01): queda operativa. Orfanada del índice previamente (reportada por VAL-11); registrada ahora con esta entrada.
- **Ubicación**: specs/021-estructura-inicial-apps-nuevas/
- **Objetivo**: Estructura inicial canónica para apps nuevas (creación de apps con baseline Documentacion/<App>/ + src/<App>/ + constitution).
- **Artefactos**: spec.md, plan.md, tasks.md, y 8 tasks pendientes de creación de apps.
- **Decisión de dirección (fase D, spec 035)**: 021 es la OPERATIVA (8 tasks pendientes); `027-patron-estructura-proyecto` se tratará como patrón normativo al que 021 referenciará (ver entrada 027).

## Especificación plataforma-bootstrap-instalador-unico (no-numerada)
- **Estado**: **Completada** — `scripts/plataformador-bootstrap.ps1` instalador/actualizador único del kit; base de ADR-0003. Contiene `Ensure-OpenCodeDefaultAgent`, `Ensure-OpenCodeMcp`, `Ensure-OpenCodeConfig`, `Ensure-McpEnvFile` y demás pasos del flujo de montaje del arnés.
- **Ubicación**: specs/plataforma-bootstrap-instalador-unico/
- **Objetivo**: Nivelar el kit transversal en cualquier proyecto: clonar maestro, sincronizar transversales (.github/, .opencode/, .doc_agents/, scripts/), sincronizar AGENTS.md y opencode.json (merge por claves), instalar MCPs, documentar proyecto, crear estructura base.
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, scripts/plataformador-bootstrap.ps1.

## Normativa 022-docker-standard (no spec)
- **Estado**: **NORMATIVA obligatoria vigente** (no es una feature/spec) — `specs/022-docker-standard/standard.md` (351 líneas) define el estándar técnico Docker del kit: secretos como archivos en `secrets/` (nunca en `.env`), `.env` solo para configuración no sensible, Dockerfile multi-stage con usuario no root UID/GID 10001, `/healthz`, puertos, `.gitignore`/`.dockerignore`. Referencia: implementación real de `api_torniquetes`.
- **Ubicación**: `specs/022-docker-standard/standard.md` (sin `spec.md`: es normativa técnica, no feature).
- **Decisión (fase F, spec 035, usuario 2026-11-01)**: **se mantiene como NORMATIVA** — NO se archiva (es un estándar vigente y obligatorio del kit, no un duplicado). Se registra aquí para que deje de ser huérfana del VAL-11.
- **Relación**: complementa a la skill `docker-patterns`. `022-docker-patterns-metodologia` (borrador) → **ARCHIVADA (fase F, spec 035, usuario 2026-11-01)**: sus 10 FR de metodología Docker transversal ya están cubiertos por la skill `docker-patterns` (existente, 665 líneas, incluye secret management, Docker secrets, `.env` nunca commit, security, hardening); redundante con la skill. Movida a `specs/archived/022-docker-patterns-metodologia/` con [NOTA-ARCHIVO.md](specs/archived/022-docker-patterns-metodologia/NOTA-ARCHIVO.md).

## Especificación 023-copilot-mcp-actualizaciones - Actualizaciones Copilot MCP / frontmatter
- **Estado**: **ARCHIVADA (fase F, spec 035, usuario 2026-11-01)** — el tema (frontmatter MCP de agentes, paridad `.github`/`.opencode`, mcp-servers por agente) ya está gestionado por la regla 1b de cobertura MCP + la spec 020 (config MCP operativa) y el mecanismo de paridad de agentes. Sus tasks estaban completadas; sin feature futura única. (Sin entrada previa en el índice; se registra en la fase F.)
- **Ubicación**: `specs/archived/023-copilot-mcp-actualizaciones/` (movida con `git mv`).
- **Objetivo**: Documentar cambios de GitHub Copilot en agentes y MCP, y adaptar los agentes del KIT (mcp-servers por agente, frontmatter, paridad).
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, converge.md, [NOTA-ARCHIVO.md](specs/archived/023-copilot-mcp-actualizaciones/NOTA-ARCHIVO.md).

## Especificación 028 - Public Docs Routing
- **Estado**: Especificada — ciclo Speckit completo (spec/plan/tasks/analyze/converge) + ADR-0011 + skill public-documentation; **implementación NO ejecutada** (el `converge.md` dice "Lista para implementación vía speckit-implement"). ⚠️ El índice marcaba "Completada" por error.
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
- **Estado**: Especificada — Analyze **PASS con observaciones** (`arquitecto` + `security-auditor`), **Converge completado** 2026-10-29. **NÚCLEO absorbido por ADR-0013** (whitelist de escritura por capa/tipo de proyecto y agentes como orquestadores delgados). **Implementación del RESTO NO iniciada**: 66 tasks en `tasks.md`, 0 ejecutadas. Nota de consolidación parcial en `NOTA-CONSOLIDACION.md`. ⚠️ **No se cierra por completo ni se archiva**: queda como PENDIENTE-REAL.
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

## Especificación 034 - Arranque por defecto con agentes del kit
- **Estado**: Cerrado — flujo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge). T01-T13 + mitad de propagación T14-T20 cerradas. Decisión del usuario (2026-11-01): `pensador` como `default_agent`, respetando mecanismos nativos del arnés y con flujo idéntico entre `.github/` y `.opencode/`. Ampliación FR-14..FR-19 / CA-12..CA-15: propagación del arranque por `scripts/sync-kit.ps1` (D-07..D-09, sección 19 de la spec)
- **Ubicación**: `specs/034-arranque-agentes-por-defecto/`
- **Objetivo**: Que al montar el kit cada arnés arranque con un agente del kit en lugar de su agente incorporado: `default_agent: pensador` en OpenCode y regla always-on de enrutamiento en `AGENTS.md` + `.github/copilot-instructions.md` para VS Code Copilot, que no expone agente por defecto para agentes custom
- **Métricas**: 19 FR (FR-01..FR-19), 7 NFR, 4 historias de usuario, 15 CA (CA-01..CA-15), 9 decisiones (D-01..D-09), 20 tareas (T01-T20)
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `10 chequeos | OK: 9 | WARN: 1 | FAIL: 0`, exit code 0 (incorpora `VAL-10 Arranque por defecto valido`, severidad FAIL). Test de contrato `tests/harness-default.ps1`: exit code 0, fixture negativo con `default_agent: build` detectado. Test de contrato de propagación `tests/kit-sync-merge.ps1`: `OK: 7 escenarios`, exit 0. Parseo `PARSE-OK` de `scripts/sync-kit.ps1` y `tests/kit-sync-merge.ps1`. Defectos B-01/B-02 corregidos con el comparador local `Compare-KitFileState`. `Get-CanonicalTiers` corregido para anclarse en la cabecera `| Tier | Agents |` (la matriz nueva de `AGENTS.md` había degradado `VAL-04` a ~35 tiers falsos manteniendo el `[OK]`). `git diff` sin cambios en bloques `permission`. 19/19 FR con evidencia, 15/15 CA verificados, Constitución 5/5 PASS
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, tests/harness-default.ps1, tests/kit-sync-merge.ps1; `opencode.json` L5, sección de arranque en `AGENTS.md` L117 envuelta en `KIT-BLOCK` (L117/L143), enrutamiento en `.github/copilot-instructions.md`, sección en `README.md`, `Ensure-OpenCodeDefaultAgent` en `scripts/plataformador-bootstrap.ps1`, `VAL-10` en `scripts/validate-agents-skills.ps1`, `Compare-KitFileState`/`Merge-OpenCodeConfig`/`Merge-KitBlock`/whitelist de tests en `scripts/sync-kit.ps1`, `.gitignore` con `opencode.json.bak-*` y `AGENTS.md.bak-*`, retiro de `.opencode/agents/pensador/spec.md`
- **Riesgo residual abierto**: TM-04 cerrado por `.gitignore` (backups `opencode.json.bak-*` y `AGENTS.md.bak-*` fuera de git). Riesgos nuevos de propagación (TM-09 a TM-11) en residual Bajo. Sin residual Medio abierto

## Especificación 033 - Refresh de conocimiento e índices de MCP en la primera ejecución del día
- **Estado**: ⚠️ **Divergencia corregida (2026-11-01)** — el índice lo marcaba "En proceso, T01-T07 cerradas", pero en disco `tasks.md` tiene las 13 tareas en estado "Pendiente" (0 ejecutadas). Estado real: **Especificada / no iniciada en ejecución real** — ciclo SSD+Speckit completo en artefactos, pipeline definido (`pipeline-refresh-mcp.md`) pero sin tareas ejecutadas.
- **Ubicación**: `specs/033-refresh-conocimiento-mcp/`
- **Objetivo**: Que la primera ejecución del día dispare automáticamente el refresh de conocimiento e índices de todos los MCP del proyecto (`codebase-memory-mcp`, `graphify`, `context-mode`, `markitdown`, `tokenslayer`, `github`, `playwright`, `context7`), para que los agentes consulten información actualizada sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: Test de contrato `tests/mcp-refresh-parity.ps1`: exit code 0, fixture negativo detecta divergencia. Ejecución real del refresh (CA-01..CA-05, CA-07..CA-12) **pendiente** de primera ejecución del día
- **Artefactos**: spec.md, plan.md, tasks.md, analyze.md, threat-model.md, converge.md, pipeline-refresh-mcp.md, tests/mcp-refresh-parity.ps1
- **Limitación documentada**: la ejecución real depende de la primera ejecución del día (dependencia operativa, no de especificación); ninguna tarea está marcada como ejecutada en `tasks.md`


## Especificación 032 - Actualización de Knowledge Base tras spec validada
- **Estado**: ⚠️ **Divergencia corregida (2026-11-01)** — la spec **NO está cerrada ni implementada**: en disco `tasks.md` tiene las 13 tareas en estado "Pendiente" (0 ejecutadas) y el "Estado general" dice "quedan por ejecutar". El índice lo marcaba "Cerrado" por error. Estado real: **En proceso / Especificada** — pipeline creado (`pipeline-kb.md`) pero sin ejecutar.
- **Ubicación**: `specs/032-actualizacion-knowledge-base/`
- **Objetivo**: Que el cierre de una spec dispare la actualización de CodeBase (codebase-memory-mcp), Context (context-mode) y Graphify (graphify), para que los agentes consulten el contenido de specs validadas vía MCPs sin leer archivos directamente
- **Métricas**: 12 FR (FR-01..FR-12), 7 NFR, 4 historias de usuario, 12 CA (CA-01..CA-12)
- **Estado de verificación**: Test de contrato `tests/kb-parity.ps1`: exit code 0, fixture negativo detecta divergencia. Ejecución del pipeline de KB (CA-01..CA-05, CA-07..CA-12) **pendiente**: faltan herramientas MCP `graphify.extract`, `context-mode.ctx_index`, `codebase-memory-mcp.search_graph` en el catálogo
- **Artefactos**: spec.md, plan.md, tasks.md, pipeline-kb.md, analyze.md, threat-model.md, converge.md, tests/kb-parity.ps1
- **Limitación documentada**: la ejecución real del pipeline KB está pendiente por falta de herramientas MCP en el catálogo (T08-T10). El repositorio ya está indexado en codebase-memory-mcp (11,399 nodos) y graphify (4,973 nodos, 467 comunidades).

---

## Especificación 014 - Manifest versionado y sincronización entre módulos
- **Estado**: **Completada sin registro previo (CERRAR-COMPLETADA-SIN-REGISTRO)** — en disco `spec.md` (1.357 B) con plan/analyze/converge/data-model/quickstart/research y `tasks.md` (8 tareas cerradas, 8/0), pero ausente del índice. Registrada por la fase B de la spec 035 (consolidación del backlog). No es absorbida por un ADR.
- **Ubicación**: `specs/014-manifest-versionado-y-sincronizacion/`
- **Objetivo**: Manifest de versionado y sincronización entre módulos del kit.
- **Artefactos**: spec.md, plan.md, analyze.md, converge.md, data-model.md, quickstart.md, research.md, tasks.md.
- **Nota de fase F**: candidata a revisión contra `sync-kit` (auditoría §5.4/§5.6); renumeración no ejecutada (pendiente decisión fase F del plan 035).

## Especificación 019 - Guard de lastupdate de update-mcp
- **Estado**: **ARCHIVADA/FUSIONADA en `020-mcp-config-operativa` (fase D, spec 035)** — su guard (`lastupdate`) vive en `scripts/update-mcp.ps1`, el mismo que 020 congela como baseline. Sin contenido único pendiente. Movida a `specs/archived/019-update-mcp-lastupdate-guard/` con `NOTA-ARCHIVO.md`. (Previamente: Completada sin registro previo [CERRAR-COMPLETADA-SIN-REGISTRO], ausente del índice, registrada por la fase B de la spec 035.)
- **Ubicación**: `specs/archived/019-update-mcp-lastupdate-guard/`
- **Objetivo**: Get-State de `update-mcp.ps1` con formas válidas para el guard de lastupdate.
- **Artefactos**: spec.md, plan.md, tasks.md, NOTA-ARCHIVO.md.
- **Nota de solapamiento**: solapa con `020-mcp-config-operativa`/`009-mcp-update-lifecycle` (misma entidad `update-mcp.ps1`); la fusión de contenido (fase D) se ejecutó el 2026-11-01 aprobada por el usuario, archivando 019 y 009 en favor de 020.

## Especificación kit-generico (no-numerada) - Blindaje `.git` y alcance quirúrgico del kit
- **Estado**: **ARCHIVADA (fase F, spec 035, usuario 2026-11-01)** — absorbida por la spec 021 (sync por capas): los guards de alcance quirúrgico y blindaje de `.git` que pedía (allowlist/denylist de `.git`, rutas destructivas con containment-check) ya están implementados en la spec 021 con guards equivalentes; sus tareas quedaron marcadas "superada". Sin contenido único pendiente. (Antes: CERRAR-COMPLETADA-SIN-REGISTRO por la fase B de la spec 035.)
- **Ubicación**: `specs/archived/kit-generico/` (movida con `git mv`).
- **Objetivo**: Blindaje de `.git` + alcance quirúrgico del kit (generización transversal).
- **Artefactos**: spec.md, tasks.md, [NOTA-ARCHIVO.md](specs/archived/kit-generico/NOTA-ARCHIVO.md).

## Especificación solucion-generica (no-numerada) - Descontaminación del kit
- **Estado**: **ARCHIVADA (fase F, spec 035, usuario 2026-11-01)** — decisión de genericidad revertida parcialmente por ADR-0009 (hardcode) y órdenes del usuario; lo vigente (cero dominios concretos, cero rutas absolutas) ya está constitutionalizado en el constraint "Genericidad y Ausencia de Rutas Absolutas". Sin contenido único pendiente que no esté cubierto. (Antes: CERRAR-COMPLETADA-SIN-REGISTRO por la fase B de la spec 035.)
- **Ubicación**: `specs/archived/solucion-generica/` (movida con `git mv`).
- **Objetivo**: Descontaminación del kit (solución genérica transversal).
- **Artefactos**: spec.md, plan.md, tasks.md, [NOTA-ARCHIVO.md](specs/archived/solucion-generica/NOTA-ARCHIVO.md).

---

## Especificación 035 - Consolidación del Backlog de Specs
- **Estado**: En proceso — ciclo SSD+Speckit en curso (specify + plan aprobado; fases B/C/E/H ejecutadas; D/F fusiones y renumeraciones aprobadas puntualmente por el usuario el 2026-11-01; fase F de archivados ejecutada).
- **Ubicación**: `specs/035-consolidacion-backlog/`
- **Objetivo**: Limpiar y consolidar el backlog de specs del KIT: archivar obsoletas, consolidar absorbidas por ADR, fusionar duplicadas, indexar completadas sin registro, y dejar un único punto de la verdad (índice + backlog coherentes con el disco, con gate automático `VAL-11`).
- **Origen**: Auditoría `auditoria-specs-backlog.md` (2026-11-01) que detectó ~29+8 huérfanas, duplicados de numeración y divergencias disco↔índice.
- **Artefactos**: spec.md, plan.md, checklists/requirements.md (20/20 PASS), NOTA-CONSOLIDACION.md ×6, NOTA-ARCHIVO.md ×11 (7 fase E + 4 fase F), VAL-11 en `scripts/validate-agents-skills.ps1`.
- **Estado de verificación**: `scripts/validate-agents-skills.ps1` → `11 chequeos | OK: 9 | WARN: 1 | FAIL: 1` (VAL-11 reporta **1 huérfana**: `specs/plataforma-bootstrap-instalador-unico`, candidata a consolidación con ADR-0003 — decisión pendiente de fase F/iteración dedicada, fuera del alcance de las 4 archivadas de esta fase). Gate: las 4 archivadas de la fase F resolvieron sus huérfanas (7 → 1); queda 1 pendiente conocida.

### Specs archivadas (fase E, spec 035)

> Estas specs quedaron **obsoletas** y se movieron a `specs/archived/` (sin borrar, con `NOTA-ARCHIVO.md` y motivo). Referencia: auditoría §5.2 y spec 035.

- `000-mcp-integracion` (grupo de 8 sub-specs plantilla) → `specs/archived/000-mcp-integracion/` — absorbido por 020 + `opencode.json` real.
- `000-mcp-integration-standard` → `specs/archived/000-mcp-integration-standard/` — estándar absorbido por 020.
- `008-mcp-config-portable` → `specs/archived/008-mcp-config-portable/` — forma actual definida por ADR-0009/0010.
- `009-mcp-path-normalization` → `specs/archived/009-mcp-path-normalization/` — absorbida por ADR-0009/0010.
- `018-pensador-delegation-fix` → `specs/archived/018-pensador-delegation-fix/` — resuelto por 031; numeración duplicada.
- `metodologia-ssd-speckit` → `specs/archived/metodologia-ssd-speckit/` — tema cubierto por ADR-0005.
- `cambio-vision` → `specs/archived/cambio-vision/` — solo spec, sin numerar ni tasks.

### Fusiones de contenido (fase D, spec 035)

> Estas specs quedaron **fusionadas** en su canónica y se movieron a `specs/archived/` (sin borrar, con `NOTA-ARCHIVO.md` y motivo). Decisión aprobada por el usuario el 2026-11-01 (fase D de la spec 035). Referencia: spec 035.

- **`013-mcp-integration-flow` → `015-mcp-integration-flow` (canónica)** — `specs/archived/013-mcp-integration-flow/`. Ambas trataban el mismo flujo de integración MCP/ECC (ecc-orchestrator, sección MCP en agents, ci/ecc-pipeline, glosario). Sin contenido único que conservar. [NOTA-ARCHIVO](specs/archived/013-mcp-integration-flow/NOTA-ARCHIVO.md).
- **`009-mcp-update-lifecycle` → `020-mcp-config-operativa`** — `specs/archived/009-mcp-update-lifecycle/`. Superada por 020: el script `scripts/update-mcp.ps1` que definía YA EXISTE en disco y 020 lo congeló como baseline operativo vivo (su converge quedó desactualizado al decir que el script no existía). [NOTA-ARCHIVO](specs/archived/009-mcp-update-lifecycle/NOTA-ARCHIVO.md).
- **`019-update-mcp-lastupdate-guard` → `020-mcp-config-operativa`** — `specs/archived/019-update-mcp-lastupdate-guard/`. Su guard (`lastupdate`) vive en `scripts/update-mcp.ps1`, el mismo que 020 congela como baseline. Sin contenido único pendiente. [NOTA-ARCHIVO](specs/archived/019-update-mcp-lastupdate-guard/NOTA-ARCHIVO.md).
- **`002-script-plataforming-sync-kit` → sync-kit / `021-sync-kit-agents`** — `specs/archived/002-script-plataforming-sync-kit/`. Precursora del motor de sync: el mecanismo actual (`scripts/sync-kit.ps1` + `scripts/sync/` con 10 subcarpetas + spec 021-sync-kit-agents) ya implementa lo que esta spec describía. Archivar como superada. [NOTA-ARCHIVO](specs/archived/002-script-plataforming-sync-kit/NOTA-ARCHIVO.md).

### Fusiones de contenido (fase F, spec 035)

> Las 4 specs siguientes quedaron **archivadas/fusionadas en su canónica** en la fase F de la spec 035 y se movieron a `specs/archived/` (sin borrar, con `NOTA-ARCHIVO.md` y motivo). Decisión aprobada por el usuario el 2026-11-01. Referencia: spec 035.

- **`kit-generico` → `021-sync-kit-agents`** — `specs/archived/kit-generico/`. Absorbida por la spec 021 (sync por capas): los guards de alcance quirúrgico y blindaje de `.git` que pedía (allowlist/denylist de `.git`, rutas destructivas con containment-check) ya están implementados en la spec 021 con guards equivalentes; sus tareas quedaron marcadas "superada". Sin contenido único pendiente. [NOTA-ARCHIVO](specs/archived/kit-generico/NOTA-ARCHIVO.md).
- **`solucion-generica` → Constitution + ADR-0009** — `specs/archived/solucion-generica/`. Decisión de genericidad revertida parcialmente por ADR-0009 (hardcode) y órdenes del usuario; lo vigente (cero dominios concretos, cero rutas absolutas) ya está constitutionalizado en el constraint "Genericidad y Ausencia de Rutas Absolutas". Sin contenido único pendiente que no esté cubierto. [NOTA-ARCHIVO](specs/archived/solucion-generica/NOTA-ARCHIVO.md).
- **`022-docker-patterns-metodologia` → skill `docker-patterns`** — `specs/archived/022-docker-patterns-metodologia/`. Borrador cuyos 10 FR de metodología Docker transversal ya están cubiertos por la skill `docker-patterns` (existente, 665 líneas, incluye secret management, Docker secrets, `.env` nunca commit, security, hardening). Redundante con la skill; se archiva. [NOTA-ARCHIVO](specs/archived/022-docker-patterns-metodologia/NOTA-ARCHIVO.md).
- **`023-copilot-mcp-actualizaciones` → regla 1b + `020-mcp-config-operativa`** — `specs/archived/023-copilot-mcp-actualizaciones/`. Tema (frontmatter MCP de agentes, paridad `.github`/`.opencode`, mcp-servers por agente) ya gestionado por la regla 1b de cobertura MCP + la spec 020 (config MCP operativa) y el mecanismo de paridad de agentes. Sus tasks estaban completadas; sin feature futura única. [NOTA-ARCHIVO](specs/archived/023-copilot-mcp-actualizaciones/NOTA-ARCHIVO.md).

## Consolidación por ADR — specs absorbidas (fase C, spec 035)

> La fuente de verdad de la «forma actual de trabajo» son los ADRs implementados (ADR-0003..0013). Las specs siguientes quedaron **absorbidas** por un ADR; se consolidan con `NOTA-CONSOLIDACION.md` dentro de cada carpeta y se marcan **CERRADA-POR-ABSORCION-ADR**. No se archivan (siguen en `specs/` con nota). Referencia: auditoría §5.1 y spec 035.

### Contenido de `000-mcp-gobernanza` (sub-specs absorbidas)
- **007-mcp-token-resolution** — `specs/000-mcp-gobernanza/007-mcp-token-resolution/` — **CERRADA-POR-ABSORCION-ADR (ADR-0006)**. Resolución de tokens MCP: absorbida por ADR-0006 (resolución de tokens + `.env.mcp` portable). Completada en disco (46/0) sin índice; ahora registrada y cerrada. Avísase si queda verificación pendiente de evidence de tokens según ADR.
- **017-garantizar-mcp-activos** — `specs/000-mcp-gobernanza/017-garantizar-mcp-activos/` — **CERRADA-POR-ABSORCION-ADR (ADR-0006 + 020)**. Garantía de MCP activos: absorbida por ADR-0006 + `020-mcp-config-operativa` (baseline en vivo).

### Specs absorbidas (registradas ahora)
- **006-post-platforming-speckit** — `specs/006-post-platforming-speckit/` — **CERRADA-POR-ABSORCION-ADR (ADR-0004)**. Flujo post-plataformado→speckit (3 escenarios), re-indexación, Constitution por proyecto, memoria, graphify por app. Completada en disco (31/0) sin índice; ahora registrada y cerrada.
- **010-mcp-env-file-guarantee** — `specs/010-mcp-env-file-guarantee/` — **CERRADA-POR-ABSORCION-ADR (ADR-0006)**. Garantía de `.env.mcp` portable.
- **015-sync-kit-bootstrap** — `specs/015-sync-kit-bootstrap/` — **CERRADA-POR-ABSORCION-ADR (ADR-0003 + sync-kit)**. Bootstrap instalador/actualizador único. Completada en disco (10/0) sin índice; ahora registrada y cerrada.
- **016-ssd-enforcement** — `specs/016-ssd-enforcement/` — **CERRADA-POR-ABSORCION-ADR (ADR-0005)**. Cumplimiento del flujo SSD+Speckit vía Agent-SSD. Entre Indexar y cerrar: la auditoría la tenía como ABSORBIDA-POR-ADR (§5.1) a la vez que el índice la marcaba Completada. Se registra como cerrada por absorción del ADR-0005.

---

*Última actualización del índice: 2026-11-01 (fase F de la spec 035: archivadas kit-generico, solucion-generica, 022-docker-patterns, 023-copilot con NOTA-ARCHIVO; 022-docker-standard mantenida como normativa; etiqueta 013-ecc corregida). Antes (fase D, spec 035): fusionadas/archivadas 013→015, 009→020, 019→020, 002→sync-kit/021 con NOTA-ARCHIVO; registrada 021-estructura-inicial como OPERATIVA (8 tasks pendientes, resuelve una huérfana de VAL-11); registrada la decisión de dirección para 027 como patrón normativo al que 021 referenciará. Antes: corregidas divergencias 026/028/032/033; registradas 034 y 035; fases B/C/E de la spec 035: indexadas 014/019/kit-generico/solucion-generica, consolidadas absorciones por ADR, archivadas obsoletas a `specs/archived/`; VAL-11 en el validador).*

