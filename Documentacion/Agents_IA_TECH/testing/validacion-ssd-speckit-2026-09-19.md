# Validación [SSD-SPECKIT-INTEGRACION] — T-V1 a T-V8

**Fecha**: 2026-09-19 | **Agente**: `qa-senior` | **Alcance**: solo lectura + escritura en `testing/` y `pendientes-implementacion.md` (bugs se reportan, no se corrigen)
**Contexto**: `devops` completó 13 agentes + pensador con Constitution Wizard en ambos harnesses, `00-indice.md` con flujo unificado + tabla 13 agentes + Wizard, `MCPs/graphify.md`. Spec: `specs/metodologia-ssd-speckit/spec.md` (13 RFs + RF-14 + 11 ACs). Seguridad `seguridad/metodologia-ssd.md`: no bloquea, con condiciones.
**Método**: sin ejecutar speckit real contra proyectos productivos; fixtures en `$env:TEMP` donde aplica; T-V2 por trazabilidad.

## Resumen PASS/FAIL

| ID | Prueba | Veredicto |
|----|--------|-----------|
| T-V1 | Constitution check | **PASS** (re-validado 2026-09-19 tras corrección BUG-1: constitución 6 artículos I–VI = criterio; scripts OK; cero "9 artículos") |
| T-V2 | Pipeline end-to-end (trazabilidad) | **PASS** (con observación BUG-5) |
| T-V3 | Agentes complementan | **PASS** (con observaciones BUG-2, BUG-3) |
| T-V4 | Contexto previo | **PASS** (con observación BUG-4) |
| T-V5 | Rutas por app | **PASS** (alcance código; Metatrader no verificable desde este repo — BUG-6) |
| T-V6 | 00-indice.md | **PASS** |
| T-V7 | graphify.md | **PASS** |
| T-V8 | Constitution Wizard | **PASS** |

## Evidencia por prueba

### T-V1 Constitution check — PASS (re-validado 2026-09-19 tras corrección BUG-1)
- `.specify/memory/constitution.md` **existe** y contiene **6 artículos** (I Modular L6, II Orchestrator L9, III SSD L12, IV Compat L15, V Observability L18, **VI proyect_ext L21**) = criterio vigente "**6 artículos (I–VI, con VI=proyect_ext)**" (spec.md Objetivo/RF-01/RF-14/AC-11, tasks.md T-I16/T-V8, 00-indice.md mermaid + Wizard paso 9, seguridad/metodologia-ssd.md R-1 + Referencias). Criterio y constitución coinciden. → **BUG-1 CERRADO**.
- Cero ocurrencias de "9 artículos" en los 5 archivos (`spec.md`, `plan.md`, `tasks.md`, `00-indice.md`, `seguridad/metodologia-ssd.md` — `Select-String` 0 matches). ✅
- `.specify/scripts/powershell/` contiene `create-new-feature.ps1`, `setup-plan.ps1`, `setup-tasks.ps1` (+ `check-prerequisites.ps1`, `common.ps1`, `resolve-template.ps1`). **Scripts PASS**.
- OBS menor nueva (no bloquea, para `documentador`): `tasks.md` T-V8 paso 2 (L312) dice "modificar Art.VII" — con 6 artículos (I–VI) Art.VII no existe; debería citar un artículo existente (p. ej. Art.VI).

### T-V2 Pipeline end-to-end (trazabilidad) — PASS
- `tasks.md` cubre: T-D1 (spec/plan/tasks), T-D2 (seguridad), **T-I1..T-I13** (los 13 agentes), T-I14 (00-indice), T-I15 (graphify.md), T-I16/T-I17 (Wizard), T-V1..T-V8.
- Matriz RF↔task↔agente reconstruida: RF-01/02/09→T-I1 (`devops`/pensador); RF-03→T-I1; RF-04→T-I2 (arquitecto); RF-05→T-I3 (documentador); RF-06→T-I4 + T-D2 (security-auditor); RF-07→T-I5/I6/I7/I8 (4 implementadores); RF-08→T-I9/I10/I11/I12/I13 (5 transversales); RF-10→T-I14 (rutas); RF-11→todas las T-I; RF-12→T-I14; RF-13→T-I15; RF-14→T-I16/I17. **0 RFs huérfanos, 0 tasks sin agente.**
- Observación: no existe una tabla explícita única RF↔task↔agente; el mapeo es implícito por descripciones (solo T-D1 cita "RF-01 a RF-13"). → **BUG-5** (menor, no bloquea).

### T-V3 Agentes complementan — PASS
- `grep speckit-` por agente (idéntico en ambos harnesses): `pensador`=6 skills (`specify,plan,tasks,analyze,converge,implement`, 39 menciones); implementadores `api-developer,frontend-developer,devops,qa-senior`=solo `speckit-implement`; documentales `arquitecto,security-auditor`=solo `speckit-analyze`, `documentador`=solo `speckit-converge`; transversales `gitflow`=implement+converge, `plataformador`=analyze, `upgrade_framework`=plan+implement, `analista_tecnico`=specify+analyze, `solucionador`=analyze+implement. Coincide con la tabla del 00-indice. Ningún implementador tiene skills documentales ni viceversa.
- Observaciones: (a) `.github/agents/`=13 archivos vs `.opencode/agents/`=**15** (`ssh-connection-agent.md`, `usuario-preferencias.md` sin skills speckit, fuera de la tabla de 13) → **BUG-2**; (b) `tasks.md` T-I11/T-I12 nombran `upgrade-framework.agent.md` / `analista-tecnico.agent.md` con guiones, los archivos reales usan guion bajo → **BUG-3** (menor).

### T-V4 Contexto previo — PASS
- Ambos `pensador` (`.github` L68-100, `.opencode` L81+) contienen la sección "Contexto Previo MCPs / Graphify / codebase-memory (**OBLIGATORIO antes de CADA fase**)" con consultas `codebase-memory` (`get_architecture`,`search_graph`,`trace_path`) + `graphify` (`extract`,`query`) + `context-mode` + `markitdown`, formato de log por fase, reglas "NUNCA ejecutes `speckit-*` sin Contexto Previo" y nodos de contexto previo en el diagrama por fase.
- El literal **"Conectar a elementos" no existe** (0 matches en ambos) — el paso existe bajo el nombre "Contexto Previo". → **BUG-4** (naming, menor).

### T-V5 Rutas por app — PASS (alcance verificable por código)
- Este repo (kit) **no tiene `src/`** (`Test-Path`=False — esperado: no es host de apps). Specs SÍ en `Documentacion/Agents_IA_TECH/specs/` (`metodologia-ssd-speckit/spec|plan|tasks.md` presentes). Los `src/<app>` x5 de Metatrader no son verificables desde este repo. → **BUG-6** (alcance).
- `Sync-TransversalKit` (`scripts/plataformador-bootstrap.ps1` L1567+): allowlist = `.github/,.opencode/,.doc_agents/` + 5 archivos (`.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`); mensaje DryRun explícito "NUNCA tocaría `Documentacion/<AppName>/`". **`Documentacion/` nunca es fuente. Verificado por código.**

### T-V6 00-indice.md — PASS
- Fecha `2026-09-19` (L2) ✓; tabla "Agentes / Skills Speckit / Fase Pipeline / Trigger" con **13 filas** ✓ (coincide con T-V3); bloque `mermaid flowchart LR` desde L117 (Constitution Check→contexto→specify→…→implement) ✓; referencias a `specs/metodologia-ssd-speckit/spec.md` (L179) y `MCPs/graphify.md` (L180) — ambos archivos **existen** ✓; sección Wizard 11 pasos + tabla RF-14 ✓.

### T-V7 graphify.md — PASS
- `Documentacion/Agents_IA_TECH/MCPs/graphify.md` existe (13089 bytes) y documenta las **10/10 herramientas** (`query_graph,get_node,get_neighbors,get_community,god_nodes,graph_stats,shortest_path,list_prs,get_pr_impact,triage_prs`, L117-126) con params, queries por fase y notas stdio-only / `triage_prs` solo-lectura.
- `graphify --version` → **`graphify 0.9.48`** en esta máquina ✓.

### T-V8 Constitution Wizard — PASS
- Ambos `pensador` documentan sección "Constitution Wizard (**11 pasos** interactivos + modo revisar/actualizar) — RF-14": Pasos 1/11..11/11 + bloque "Modo REVISAR Y ACTUALIZAR" (`.github` L103-183, `.opencode` L114-183).
- `spec.md` contiene **RF-14** (L121+, 11 pasos + criterio "9 artículos + Art.VI") y **AC-11** (wizard 11 pasos → constitution válida; modo revisar) ✓.

## Bugs reportados (NO corregidos — restricción de paths qa-senior)

| ID | Severidad | Prueba | Descripción |
|----|-----------|--------|-------------|
| BUG-1 | 🔴 Alta | T-V1 | `constitution.md` del repo tiene 6 artículos (I–VI), no "9 + Art.VI". El criterio T-V1/AC-11/mermaid ("9 artículos + Art.VI") no casa con la constitución real de Agents_IA_TECH. Decidir: (a) extender constitución a 9 artículos spec-kit, o (b) corregir el criterio a 6 + Art.VI. Responsable: `pensador`+`documentador` (+`devops` si hay cambio de criterio en tasks). **✅ RESUELTO vía (b) + RE-VALIDADO 2026-09-19**: criterio = 6 artículos en spec/00-indice/seguridad, cero "9 artículos", T-V1 → PASS. |
| BUG-2 | 🟠 Media | T-V3 | `.opencode/agents/` tiene 15 archivos vs 13 en `.github/` (`ssh-connection-agent.md`, `usuario-preferencias.md` sin skills speckit, fuera de la tabla del 00-indice). Aclarar si pertenecen al kit (entonces darles skills/trigger o declararlas explícitamente fuera del pipeline) o excluirlas del conteo. Responsable: `devops` (+`documentador`). |
| BUG-3 | 🟢 Baja | T-V3 | `tasks.md` T-I11/T-I12 citan `upgrade-framework.agent.md` y `analista-tecnico.agent.md` (guiones); archivos reales con guion bajo. Responsable: `documentador`. |
| BUG-4 | 🟢 Baja | T-V4 | Literal "Conectar a elementos" inexistente; el paso se llama "Contexto Previo MCPs/Graphify/codebase-memory". Unificar nombre o corregir el criterio T-V4. Responsable: `documentador`. |
| BUG-5 | 🟢 Baja | T-V2 | Sin tabla explícita única RF↔task↔agente; mapeo implícito por descripciones T-I. Sugerido: añadir matriz explícita en `tasks.md` o `plan.md`. Responsable: `documentador`. |
| BUG-6 | 🟢 Baja | T-V5 | `src/<app>` x5 de Metatrader + ejecución `find`/`sync-agents -DryRun` no verificables desde este repo. Validar T-V5 completa en el proyecto Metatrader con fixtures. Responsable: `qa-senior` (siguiente ronda). |

## Conclusión

**8/8 PASS (re-validado 2026-09-19 tras corrección BUG-1). Veredicto global: GO con observaciones no bloqueantes** — BUG-1 cerrado (constitución real de 6 artículos = criterio corregido en spec/00-indice/seguridad, cero "9 artículos", scripts OK). Resto sin cambios: 13 agentes con skills correctas en ambos harnesses, contexto previo obligatorio por fase, Wizard de 11 pasos + modo revisar, 00-indice con tabla/diagrama/enlaces/fecha, graphify.md con las 10 tools + CLI 0.9.48 operativo, y frontera `Documentacion/<AppName>/` garantizada por código. Quedan abiertos como no bloqueantes: BUG-2..BUG-6 (menores/alcance, ver tabla) + OBS nueva T-V8 "Art.VII" (L312, para `documentador`). La revisión de `security-auditor` (`seguridad/metodologia-ssd.md`) ya dictaminó **no bloquea, con condiciones** — esas 10 condiciones son requisitos de la fase de implementación, puerta de salida antes del rollout.
