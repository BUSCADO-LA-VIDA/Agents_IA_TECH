# 🔒 Seguridad del diseño: Integración SSD + Speckit + Graphify + MCPs en 13 agentes

> Revisión **de seguridad del DISEÑO** de la spec `[SSD-SPECKIT-INTEGRACION]` (`Documentacion/Agents_IA_TECH/specs/metodologia-ssd-speckit/spec.md`: 13 RFs + 10 ACs).
> Evalúa riesgos de **gates Constitution no válidos**, **specs desactualizadas**, **drift Constitution**, **Speckit sin contexto**, **agentes huérfanos**, **rutas por app desincronizadas**, **supply chain Speckit**, **Graphify MCP expuesto**, **secrets en grafo**, **Tokenslayer apply_patch sin auditoría**.
> Complementa: `seguridad/tokenslayer.md` + `seguridad/graphify.md` + `seguridad/kit-gaps.md` (formato §§1-7 heredado).
> **Fecha**: 2026-09-19 | **Autor**: `security-auditor` (Fase Documental — tarea `[SSD-SPECKIT-INTEGRACION]`)

---

## 1. Análisis de riesgos

### R-1. Gates Constitution no válidos — speckit-plan valida con reglas viejas

`speckit-plan` ejecuta checks contra los **6 artículos (I–VI, con VI=proyect_ext)**. Si `.specify/memory/constitution.md` sufre **drift** (edición local sin sync con la base, o sync fallido), los gates **pasan con reglas obsoletas**. El pipeline continúa y `speckit-tasks` genera tareas que violan la constitution real. No hay re-verificación automática tras cada fase; el check es **solo al inicio** (RF-01). Mitigación: re-ejecutar Constitution check en **cada fase** (`speckit-plan`, `speckit-analyze`, `speckit-converge`), no solo en `specify`; fallar rápido si hash del constitution.md cambió desde el inicio del pipeline.

### R-2. Specs desactualizadas — spec.md/plan.md/tasks.md divergentes de la realidad

Speckit genera artefactos **una vez**; si el código cambia (implementadores, hotfixes, `solucionador`), **no hay re-generación automática**. `speckit-converge` consolida docs pero no valida que `tasks.md` refleje el estado real del código. Un implementador puede completar una task que ya no existe en el código, o `qa-senior` testear contra tasks obsoletas. `pensador` orquesta pero no detecta drift post-implementación. Mitigación: `speckit-analyze` debe incluir **diff real vs spec** (codebase-memory: `detect_changes` + `trace_path`); si hay divergencia > umbral, reiniciar ciclo desde `specify` (ya en spec: "si cambian specs, ciclo se reinicia desde validación" — hacerlo **obligatorio y automatizado**).

### R-3. Drift Constitution — `.specify/memory/constitution.md` por app vs base

Cada app tiene su `.specify/memory/constitution.md` (hereda de base + customizaciones). `sync-agents.ps1` **NO toca `.specify/`** (solo kit transversal). Si el usuario edita la constitution local de una app y no propaga a la base (o viceversa), `speckit-*` usa **reglas inconsistentes** entre apps. `pensador` consulta la constitution de la app activa (RF-09) pero no compara con la base. Mitigación: `speckit-specify` debe **validar hash** de la constitution local vs base registrada en `dependencias-manifest.yml` (entrada `constitution-base`); alertar si difieren y pedir confirmación antes de continuar.

### R-4. Speckit sin contexto — Llamar speckit-* sin consultar MCPs/Graphify/codebase-memory

RF-09 exige consultas previas **antes de CADA `speckit-*`**, pero es **responsabilidad del `pensador`** (no enforceado por Speckit). Si `pensador` omite consultas (error, prisa, fallback), `speckit-plan`/`analyze`/`converge` operan con **info incompleta** → decisiones arquitectónicas sin ver callers/callees, clusters, god nodes, ADRs previos. El log de consultas (AC-04) es **solo auditoría post-hoc**, no gate. Mitigación: `pensador` debe **fallar si no hay log de consulta previa** para la fase actual; integrar `codebase-memory.search_graph` + `graphify.query_graph` + `ctx_search` como **pre-condición dura** en el wrapper de cada `speckit-*`.

### R-5. Agentes huérfanos — Agentes que no invocan speckit-* en su fase

13 agentes, 6 fases Speckit. RF-03 a RF-08 mapean agentes a fases, pero **no hay verificación automática** de que cada agente declare e invoque su skill Speckit correspondiente. Un agente nuevo o modificado puede **no tener skill declarada** (RF-11) o no invocarla → gap en pipeline (ej: `security-auditor` no valida mitigaciones en `tasks.md` durante `speckit-analyze`, `gitflow` no branching en `implement`). AC-03 audita `.agent.md` pero es **check estático**, no runtime. Mitigación: `pensador` valida **en runtime** que el agente asignado a la fase tiene la skill declarada **y** la invoca (hook en `speckit-*` que registre qué agente/skill ejecutó); alertar si fase completada sin skill esperada.

### R-6. Rutas por app no respetadas — Código en `src/<app>/` pero specs en `Documentacion/<app>/specs/` desincronizadas

RF-10 exige separación estricta: código en `src/<AppName>/`, specs en `Documentacion/<AppName>/specs/`. `sync-agents.ps1` **no toca `Documentacion/<AppName>/`** (correcto). Pero `speckit-*` no valida que la spec generada corresponda al código en `src/<AppName>/`. Un `speckit-specify` corrido desde app A puede escribir spec en app B si `pensador` resuelve mal la app activa (RF-09: "resolución por directorio de trabajo actual + flag `-App`"). Mitigación: `speckit-specify`/`plan`/`tasks` deben **inyectar `AppName` en metadatos** del artefacto y validar que `file_path` del artefacto empieza por `Documentacion/<AppName>/specs/`; fallar si mismatch.

### R-7. Supply chain Speckit — `proyect_ext/spec-kit` clonado sin verificación de integridad

`proyect_ext/spec-kit` es **submódulo/clon** del repo upstream Speckit. El bootstrap lo clona/actualiza (RF-15 en `plataforma-bootstrap`). `speckit-*` scripts se ejecutan **directamente desde ese clon**. Si el upstream publica release malicioso, o el clon se compromete (commit history reescrito, tag movido), los agentes ejecutan código no verificado. No hay **pin de versión/commit** ni hash verificado en `dependencias-manifest.yml` para spec-kit (sí para tokenslayer, graphify). Mitigación: registrar `spec-kit` en `dependencias-manifest.yml` con **commit SHA fijado**; `speckit-*` wrappers validan hash antes de ejecutar; actualización solo tras revisión de `devops`/`qa-senior`.

### R-8. Graphify MCP expuesto — `--transport http` expone grafo arquitectura en red

Graphify MCP (instalado vía `[GRAPHIFY-INSTALL]`) expone `python -m graphify.serve --transport http`. Si se configura mal (bind `0.0.0.0`, puerto publicado, contenedor sin firewall), el **grafo completo** (`graphify-out/graph.json`: símbolos, rutas, relaciones, potencialmente secrets si el indexador los capturó — R-5 de `graphify.md`) queda servido por HTTP. RF-09 usa Graphify como contexto previo; `pensador` lo consulta vía MCP stdio (Rama A), pero nada impide que un agente o script registre el MCP con http. Mitigación: **prohibir `--transport http` en configuración persistente** (solo stdio en `opencode.json` + `.vscode/mcp.json`); validación en `Configure-Graphify` (devops) que rechaza registro http; `qa-senior` testea que `tools/list` solo responde por stdio.

### R-9. Secrets en grafo — Graphify indexa código → secrets quedan en grafo accesible vía MCP

`graphify <path>` indexa el árbol completo (R-5 de `graphify.md`). Si el repo contiene `.env`, `*.pem`, `config.json` con keys, tokens en comentarios, esos literales quedan en `graphify-out/graph.json` y fluyen al contexto del modelo vía `query_graph`/`get_node`. Mismo patrón que `tokenslayer` R-3 (control probabilístico, no garantía). RF-09 usa Graphify **antes de cada `speckit-*`** → secrets pueden exponerse **repetidamente** en cada fase del pipeline. Mitigación: **excluir carpetas/archivos con secrets** al construir el grafo (`.env`, `*.pem`/`*.key`, `.opencode/config.json`, configs con API keys); `pensador` trata resultado MCP como **no confiable** (prompt defense); no volcar contenido del grafo en `Documentacion/`, logs, `analisis-memoria.md`.

### R-10. Tokenslayer `apply_patch` — Escritura estructural sin revisión humana en pipeline Speckit

`tokenslayer-mcp-server` expone `apply_patch` (R-1 de `tokenslayer.md`): escribe archivos por node ID (`replace`/`insert_after`/`delete`). En pipeline Speckit, `speckit-implement` delega a implementadores que **pueden usar `apply_patch`**. Si un implementador (o `pensador` mal orquestando) invoca `apply_patch` **sin `dryRun: true` previo** o sin revisar diff, cambios **no auditados** entran en `src/<AppName>/`. `speckit-converge` consolida docs pero no audita patches aplicados. `security-auditor` valida mitigaciones en `tasks.md` (RF-06) pero **no intercepta** `apply_patch` en runtime. Mitigación: **restringir `apply_patch` (`dryRun: false`) solo a implementadores bajo spec aprobada**; `pensador` exige diff previo + aprobación en log; `qa-senior` verifica que todo patch aplicado tiene `dryRun: true` → diff revisado → `dryRun: false` en trazabilidad.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Gates Constitution no válidos** (drift → gates pasan con reglas viejas; check solo al inicio) | 🔴 Crítico | Re-ejecutar Constitution check en **cada fase** (`plan`, `analyze`, `converge`); fallar si hash cambió desde inicio |
| 2 | **Specs desactualizadas** (artefactos Speckit no se regeneran tras cambios de código) | 🔴 Crítico | `speckit-analyze` integra `detect_changes` + `trace_path`; divergencia > umbral → reiniciar ciclo desde `specify` (automatizado) |
| 3 | **Drift Constitution** (constitution local vs base inconsistente entre apps) | 🟠 Alto | `speckit-specify` valida hash local vs base en `dependencias-manifest.yml`; alertar + confirmar si difieren |
| 4 | **Speckit sin contexto** (pensador omite consultas MCPs/Graphify/codebase-memory previas) | 🟠 Alto | **Pre-condición dura**: wrapper de cada `speckit-*` falla si no hay log de consulta `search_graph` + `query_graph` + `ctx_search` |
| 5 | **Agentes huérfanos** (agente no invoca skill Speckit en su fase → gap en pipeline) | 🟠 Alto | `pensador` valida **runtime**: agente asignado tiene skill declarada **y** la invoca (hook registra ejecución); alertar si fase sin skill |
| 6 | **Rutas por app desincronizadas** (speckit escribe spec en app equivocada por resolución errónea de app activa) | 🟠 Alto | `speckit-*` inyectan `AppName` en metadatos + validan `file_path` empieza por `Documentacion/<AppName>/specs/`; fallar si mismatch |
| 7 | **Supply chain Speckit** (`proyect_ext/spec-kit` clonado sin pin/hash verificado) | 🟠 Alto | Registrar `spec-kit` en `dependencias-manifest.yml` con **commit SHA fijado**; wrappers validan hash antes de ejecutar |
| 8 | **Graphify MCP expuesto** (`--transport http` en red expone grafo arquitectura + secrets) | 🟠 Alto | **Prohibir http** en config persistente (solo stdio); `Configure-Graphify` rechaza registro http; `qa-senior` testea stdio-only |
| 9 | **Secrets en grafo** (Graphify indexa `.env`/keys → fluyen al modelo en cada fase Speckit) | 🟠 Alto | Excluir carpetas con secrets al construir grafo; prompt defense en resultados MCP; no volcar grafo en docs/logs/memoria |
| 10 | **Tokenslayer `apply_patch` sin auditoría** (implementador aplica patch sin `dryRun` previo / diff revisado) | 🟠 Alto | `apply_patch` (`dryRun: false`) solo implementadores bajo spec aprobada; `pensador` exige diff + aprobación en log; `qa-senior` traza `dryRun→diff→apply` |

---

## 3. Recomendaciones de uso seguro para los agentes del kit

1. **Constitution check en cada fase**: envolver `speckit-plan`, `speckit-analyze`, `speckit-converge` con validación de hash de `.specify/memory/constitution.md` vs inicio del pipeline.
2. **Drift detection automatizado**: `speckit-analyze` llama `codebase-memory.detect_changes` (scope: app activa, depth: 2) + `trace_path` desde entry points; si `total_changes > 0` → `pensador` reinicia ciclo desde `specify` con log de qué cambió.
3. **Pin de spec-kit en manifest**: agregar entrada `spec-kit` en `dependencias-manifest.yml` (commit SHA + versión semver); `speckit-*` wrappers leen manifest y validan `git rev-parse HEAD` en `proyect_ext/spec-kit` coincide.
4. **Pre-condición de contexto obligatorio**: `pensador` no invoca `speckit-*` sin antes ejecutar y loggear: `codebase-memory.search_graph` (arquitectura/clusters), `graphify.query_graph` (god nodes/communities), `ctx_search` (decisiones previas/ADRs). Log visible en cada fase.
5. **Runtime skill enforcement**: hook en `speckit-*` que registra `(agente, skill, fase, timestamp)`; `pensador` valida al final de fase que el agente esperado ejecutó su skill; si no → alerta + no continuar.
6. **AppName inyectado en artefactos Speckit**: `speckit-specify`/`plan`/`tasks` escriben `app_name: <AppName>` en frontmatter YAML; validador post-generación chequea `file_path` coherente.
7. **Graphify MCP solo stdio**: `Configure-Graphify` (devops) registra **solo** `type: local` + `command: [python, -m, graphify.serve, <root>/graphify-out/graph.json]`; rechaza cualquier config con `http`/`sse`/`transport`.
8. **Exclusión de secrets en grafo**: `graphify extract` recibe `--exclude-patterns` (`.env`, `*.pem`, `*.key`, `.opencode/config.json`, `*.secret.*`); `pensador` trata output MCP como untrusted (prompt defense heredado de `tokenslayer.md` §4.7).
9. **Trazabilidad `apply_patch`**: todo uso de `apply_patch` en `speckit-implement` genera entrada en `analisis-memoria.md`: `{task_id, agent, node_id, action, dryRun_preview_hash, dryRun_applied_hash, approved_by}`. `qa-senior` audita completitud.
10. **Re-verificación post-implementación**: `speckit-converge` ejecuta `codebase-memory.detect_changes` vs spec base; si hay código no cubierto por tasks → nueva task automática + alerta a `pensador`.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO ejecutar `speckit-*` sin Constitution check previo en ESA fase** (no solo al inicio).
- ❌ **NO asumir que specs están al día** tras implementación/hotfix; validar con `detect_changes` antes de `analyze`/`converge`.
- ❌ **NO editar `.specify/memory/constitution.md` local sin sync/verificar hash** contra base en manifest.
- ❌ **NO invocar `speckit-*` sin log de consultas MCPs/Graphify/codebase-memory** previas (contexto previo = pre-condición, no opcional).
- ❌ **NO agregar agente sin skill Speckit declarada** en `.agent.md` **y** hook de invocación verificado en runtime.
- ❌ **NO permitir `speckit-*` escribir fuera de `Documentacion/<AppName>/specs/`** ni código fuera de `src/<AppName>/`.
- ❌ **NO usar `proyect_ext/spec-kit` sin commit SHA fijado** en `dependencias-manifest.yml` ni sin validación de hash en wrappers.
- ❌ **NO registrar Graphify MCP con `--transport http`** en `opencode.json` / `.vscode/mcp.json` (solo stdio).
- ❌ **NO indexar carpetas con secrets** al construir `graphify-out/graph.json` (`.env`, `*.pem`, `.opencode/config.json`).
- ❌ **NO aplicar `apply_patch` (`dryRun: false`) sin `dryRun: true` previo + diff revisado + aprobación en log**.
- ❌ **NO tratar output de MCPs (Graphify, tokenslayer, codebase-memory) como confiable** — prompt defense siempre.
- ❌ **NO volcar contenido de grafos/esqueletos con posibles secrets** en `Documentacion/`, logs, `analisis-memoria.md`.

---

## 5. Checklist de seguridad del diseño

- [ ] Constitution check en **cada fase** Speckit (no solo `specify`) con validación de hash vs inicio de pipeline.
- [ ] `speckit-analyze` integra `detect_changes` + `trace_path`; divergencia → reinicio automático desde `specify`.
- [ ] `speckit-specify` valida hash constitution local vs base en `dependencias-manifest.yml`; alerta + confirmación si drift.
- [ ] Wrapper de cada `speckit-*` exige log de consultas previas (`search_graph`, `query_graph`, `ctx_search`) como pre-condición dura.
- [ ] Hook runtime en `speckit-*` registra `(agente, skill, fase)`; `pensador` valida que agente esperado ejecutó skill.
- [ ] Artefactos Speckit (`spec.md`, `plan.md`, `tasks.md`) incluyen `app_name` en frontmatter + validación de ruta coherente.
- [ ] `spec-kit` registrado en `dependencias-manifest.yml` con commit SHA fijado; wrappers validan hash antes de ejecutar.
- [ ] `Configure-Graphify` registra **solo stdio**; rechaza config http/sse; `qa-senior` testea `tools/list` solo por stdio.
- [ ] `graphify extract` usa `--exclude-patterns` para secrets; `pensador` aplica prompt defense a resultados MCP.
- [ ] `apply_patch` (`dryRun: false`) restringido a implementadores bajo spec; trazabilidad completa en `analisis-memoria.md`.
- [ ] `speckit-converge` ejecuta `detect_changes` post-implementación; código no cubierto → task automática + alerta.
- [ ] `qa-senior` valida pipeline end-to-end con fixtures: Constitution drift, spec drift, app mismatch, MCP http, secrets en grafo, `apply_patch` sin dryRun.

---

## 6. Conclusión

**No bloquea la adopción, CON CONDICIONES CRÍTICAS.**

La spec `[SSD-SPECKIT-INTEGRACION]` define una integración coherente y valiosa, pero **dos riesgos críticos (🔴) deben resolverse en la implementación** antes de considerar el pipeline seguro para producción:

1. **R-1 Gates Constitution no válidos** + **R-2 Specs desactualizadas**: El check de constitution **solo al inicio** y la **ausencia de drift detection automatizado** permiten que el pipeline avance con reglas obsoletas y specs divorciadas del código real. **Requisito innegociable**: Constitution check en cada fase + `detect_changes` integrado en `speckit-analyze` con reinicio automático.

2. **R-4 Speckit sin contexto** + **R-5 Agentes huérfanos**: La responsabilidad del `pensador` de consultar MCPs/Graphify **no es enforceada** (solo log post-hoc), y no hay **validación runtime** de que cada agente invoque su skill Speckit. **Requisito innegociable**: Pre-condición dura de contexto en wrappers `speckit-*` + hook de registro de skill ejecutado por fase.

Los 6 riesgos 🟠 Alto (drift constitution, rutas por app, supply chain spec-kit, Graphify http, secrets en grafo, `apply_patch` sin auditoría) son **mitigables con controles de implementación** (pins en manifest, validaciones de ruta, stdio-only, exclusiones, trazabilidad), pero **deben materializarse en código**, no solo en documentación.

**Recomendación**: **PROCEDER (NO BLOQUEA)**, condicionado a que la fase de implementación (`devops`/`qa-senior`) incluya como **requisitos no negociables** en los criterios de aceptación:

- Constitution check por fase + hash validation
- Drift detection automatizado con reinicio de ciclo
- Pre-condición de contexto obligatoria en wrappers Speckit
- Runtime skill enforcement con hook de auditoría
- AppName inyectado y validado en artefactos
- Spec-kit pinned en manifest + hash verificado
- Graphify MCP stdio-only enforceado en configuración
- Exclusión de secrets en grafo + prompt defense
- Trazabilidad completa `apply_patch` (dryRun → diff → apply)
- Post-implementation drift check en `converge`

La validación de `qa-senior` con fixtures que cubran **todos los 10 riesgos** (incluyendo señuelos: constitution drift, spec drift, app mismatch, MCP http, secrets en grafo, `apply_patch` sin dryRun) es **puerta de salida obligatoria** antes de rollout.

---

## Referencias

- Spec: `Documentacion/Agents_IA_TECH/specs/metodologia-ssd-speckit/spec.md` (13 RFs + 10 ACs)
- Revisiones previas (formato §§1-7): `seguridad/tokenslayer.md`, `seguridad/graphify.md`, `seguridad/kit-gaps.md`, `seguridad/plataforma-bootstrap.md`
- ADR-0003: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md`
- Constitución: `.specify/memory/constitution.md` (**6 artículos (I–VI, con VI=proyect_ext)**)
- Kit governance: `AGENTS.md`, `copilot-instructions.md`, `.doc_agents/estructura-aplicacion.md`, `.doc_agents/capacidad-base.md`
- Tarea: `[SSD-SPECKIT-INTEGRACION]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` (marcar T-D2)

---

**T-D2 completado** — Revisión de seguridad creada en `seguridad/metodologia-ssd.md`.