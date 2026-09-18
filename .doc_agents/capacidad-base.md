# 🏗️ Capacidad Base del Kit de Agentes (Transversal)

> **Catálogo central** de todas las capacidades que componen el kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/`).  
> El agente `plataformador` lo usa como fuente de verdad para auditar y nivelar **cada aplicación** del repo.

**Versión del kit**: 1.2.0  
**Última actualización**: 2026-09-19

---

## 1. Archivos transversales del kit (se copian entre proyectos/apps)

| Archivo/Carpeta | Obligatorio | Propósito |
|-----------------|:-----------:|-----------|
| `.github/copilot-instructions.md` | ✅ Sí | Reglas base de todos los agentes |
| `.github/agents/` | ✅ Sí | Definiciones de agentes para GitHub Copilot |
| `.github/prompts/` | ✅ Sí | Slash commands para GitHub Copilot |
| `.github/skills/` | ✅ Sí | Skills compartidas globalmente (77 skills) |
| `.opencode/agents/` | ✅ Sí | Definiciones de agentes para OpenCode |
| `.opencode/commands/` | ✅ Sí | Slash commands para OpenCode |
| `.opencode/config.json` | ✅ Sí | Configuración OpenCode |
| `AGENTS.md` | ✅ Sí | Documentación del kit |
| `opencode.json` | ✅ Sí | Configuración OpenCode |
| `README.md` | ✅ Sí | README del proyecto/repo |
| `sync-agents.ps1` | ✅ Sí | Script de sincronización del kit |
| `.doc_agents/` | ✅ Sí | **Estructura de documentación por aplicación** |
| `.specify/memory/constitution.md` | ✅ Sí | Constitución base del proyecto (speckit) |

---

## 2. Agentes del kit (10 + 1 plataformador)

| Agente | Plataforma | Versión | Tipo |
|--------|-----------|---------|------|
| `pensador` | GitHub + OpenCode | 1.0 | Documental |
| `arquitecto` | GitHub + OpenCode | 1.0 | Documental |
| `documentador` | GitHub + OpenCode | 1.0 | Documental |
| `security-auditor` | GitHub + OpenCode | 1.0 | Documental |
| `api-developer` | GitHub + OpenCode | 1.0 | Implementador |
| `frontend-developer` | GitHub + OpenCode | 1.0 | Implementador |
| `devops` | GitHub + OpenCode | 1.0 | Implementador |
| `qa-senior` | GitHub + OpenCode | 1.0 | Implementador (solo tests) |
| `gitflow` | GitHub + OpenCode | 1.0 | Tooling |
| `solucionador` | GitHub + OpenCode | 1.0 | Plataforma (SSH) |
| `plataformador` | GitHub + OpenCode | 1.0 | Plataforma (auditoría/nivelación) |

---

## 3. Documentación BASE por aplicación (cada app tiene la suya en `Documentacion/<AppName>/`)

| Ruta (relativa a `Documentacion/<AppName>/`) | Obligatorio | Propósito |
|----------------------------------------------|:-----------:|-----------|
| `00-indice.md` | ✅ Sí | Índice general de ESTA app |
| `idioma.md` | ✅ Sí | Configuración de idioma de ESTA app |
| `preferencias.md` | ✅ Sí | Memoria de preferencias del usuario para ESTA app |
| `preferencias-git.md` | ⚠️ Recomendado | Preferencias de flujo git para ESTA app |
| `referencias.md` | ⚠️ Recomendado | Atribución de fuentes externas de ESTA app |
| `roadmap.md` | ⚠️ Recomendado | Backlog de evolutivos de ESTA app |
| `soluciones-conocidas.md` | ✅ Sí | Repositorio de soluciones de ESTA app |
| `pendientes-implementacion.md` | ✅ Sí | Puente docs ↔ código de ESTA app |
| `capacidad-base.md` | ✅ Sí | Referencia a la capacidad base del kit (copia de referencia) |
| `memoria-proyecto.md` | ✅ Sí | Capacidades instaladas en ESTA app (mantenido por plataformador) |
| `agents/<nombre>/spec.md` | ⚠️ Recomendado | Spec individual de cada agente para ESTA app |
| `arquitectura/adr/` | ⚠️ Recomendado | ADRs de ESTA app |
| `arquitectura/diagramas/` | ⚠️ Recomendado | Diagramas Mermaid de ESTA app |
| `bitacoras/` | ⚠️ Recomendado | Bitácoras del solucionador para ESTA app |
| `specs/` | ✅ Sí* | **speckit escribe aquí** (spec/plan/tasks por feature) |
| `testing/` | 📝 Opcional | Solo si hay tests documentados en ESTA app |
| `seguridad/` | 📝 Opcional | Solo si hay auditorías en ESTA app |
| `despliegue/` | 📝 Opcional | Solo si hay docs de despliegue en ESTA app |

> *`specs/` es obligatoria si se usa speckit en la app.

---

## 4. Skills globales (`.github/skills/` — compartidas, NO se duplican por app)

77 skills disponibles, incluyendo:
- `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-converge`, `speckit-implement`, `speckit-analyze`, `speckit-checklist`, `speckit-clarify`, `speckit-constitution`, `speckit-taskstoissues`
- `codebase-memory` — Grafo de conocimiento del código
- `graphify` — Input a knowledge graph
- `agent-customization` — Creación/edición de agentes
- `chronicle` — Análisis de historial de sesiones
- `project-setup-info-local` — Scaffolding de proyectos
- `get-search-view-results` — Resultados de búsqueda VS Code
- `python-fact-grounded-coding`, `pylance-docs`, `pylance-refactoring`, `pylance-python-profiling`

---

## 5. MCP Servers recomendados

| Servidor | Estado | Integración |
|----------|--------|-------------|
| `codebase-memory-mcp` | ⚠️ Recomendado | Grafo de conocimiento del código. `npm install -g codebase-memory-mcp` |
| Otros MCP | 📝 Pendiente | Según necesidad de cada app |

---

## 6. Hooks de ciclo de vida (globales)

| Hook | Propósito |
|------|-----------|
| `sessionStart` | Leer `Documentacion/<AppName>/preferencias.md` de la app activa al inicio |
| `subagentStart` | Recordar restricciones de paths (solo `Documentacion/<AppName>/` para documentales) |

---

## 7. Reglas de sincronización (`sync-agents.ps1`)

El script `sync-agents.ps1` **solo sincroniza los archivos transversales del kit**:

```
Sincroniza (sobrescribe):
├── .github/
├── .opencode/
├── .doc_agents/
├── .specify/memory/constitution.md  (base)
├── AGENTS.md
├── opencode.json
├── README.md
└── sync-agents.ps1

NO toca (crea solo si no existe):
├── Documentacion/<AppName>/  ← NUNCA se sobrescribe
├── src/
├── tests/
└── .specify/ (salvo constitution.md base)
```

---

## 8. Capacidades del plataformador (ADR-0003 — instalador único)

> El `plataformador` **delega la mecánica en scripts** y **valida en dos momentos** (propone antes, verifica después). Fuente: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md`.

| Capacidad | Estado | Descripción |
|-----------|:------:|-------------|
| `bootstrap` (instalador único) | ✅ Definida | `scripts/plataformador-bootstrap.ps1`: sync kit (`Sync-TransversalKit`) + MCPs + índices + Spec-kit + Graphify. Determinista e idempotente, `-DryRun` siempre disponible. `sync-agents.ps1` queda como wrapper. |
| `speckit-por-app` | ✅ Definida | Resolución de app activa `Resolve-ActiveApp` (`-App` > `cwd` > `root`); `.specify` activo + `Documentacion/<AppName>/specs/` por app. Nunca inferencia ambigua. |
| `huerfanos` | ✅ Definida | Detección en `Sync-TransversalKit` + pregunta borrar/conservar; default seguro conservar con respaldo `revisar_manualmente\yyyymmdd\`; nunca auto-borrar ni tocar `Documentacion/<AppName>/` |
| `relocate` | 🟡 Pendiente de script | `scripts/relocate-apps-to-src.ps1` (standalone): reubicación a `src\<App>` con confirmación siempre obligatoria; el script crea la estructura al aprobar; `.venv` se reporta "a recrear". Tarea `[RELOCATE]` en curso. |
| `verificacion-pre-post` | ✅ Definida | El agente propone antes (auditoría + brecha + preguntas) y verifica después (esperado vs real, imports/paths, tests sugeridos). |
| `optimizacion-ia` | ✅ Definida | El script hace el trabajo pesado sin IA; el agente solo propone y verifica (MCPs primero, `-DryRun` previo, no re-analizar reportes). |

---

## Historial de cambios

| Fecha | Versión | Cambio |
|-------|:-------:|--------|
| 2026-07-25 | 1.0.0 | Creación inicial del catálogo |
| 2026-08-30 | 1.1.0 | Reestructuración: separación kit transversal vs doc por app (`.doc_agents/`) |
| 2026-09-19 | 1.2.0 | Alineación ADR-0003: §8 capacidades del plataformador (bootstrap, speckit-por-app, huérfanos, relocate, verificación pre/post, optimización IA) |