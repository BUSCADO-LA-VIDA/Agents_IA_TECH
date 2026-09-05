# 🏗️ Capacidad Base - Agents_IA_TECH (Referencia a .doc_agents/)

> **⚠️ Este archivo es una REFERENCIA LOCAL** a la capacidad base del kit transversal.  
> La **fuente de verdad única** está en **`.doc_agents/capacidad-base.md`**.  
> Este archivo se mantiene sincronizado manualmente o via `plataformador`.

**Versión del kit**: 1.1.0 (ver `.doc_agents/capacidad-base.md`)  
**Última sincronización**: 2026-08-30

---

## Resumen de capacidades del kit transversal

### 1. Archivos transversales (se copian entre proyectos)

| Archivo/Carpeta | Obligatorio | Propósito |
|-----------------|:-----------:|-----------|
| `.github/copilot-instructions.md` | ✅ Sí | Reglas base de todos los agentes |
| `.github/agents/` | ✅ Sí | Definiciones agentes Copilot |
| `.github/prompts/` | ✅ Sí | Slash commands Copilot |
| `.github/skills/` | ✅ Sí | 77 skills globales compartidas |
| `.opencode/agents/` | ✅ Sí | Definiciones agentes OpenCode |
| `.opencode/commands/` | ✅ Sí | Slash commands OpenCode |
| `.opencode/config.json` | ✅ Sí | Config OpenCode |
| `AGENTS.md` | ✅ Sí | Documentación del kit |
| `opencode.json` | ✅ Sí | Config OpenCode |
| `README.md` | ✅ Sí | README del repo |
| `sync-agents.ps1` | ✅ Sí | Script sincronización kit |
| `.doc_agents/` | ✅ Sí | **Estructura transversal del kit** |
| `.specify/memory/constitution.md` | ✅ Sí | Constitución base speckit |

### 2. Agentes del kit (11)

| Agente | Plataforma | Tipo |
|--------|-----------|------|
| `pensador` | GitHub + OpenCode | Documental (Orquestador) |
| `arquitecto` | GitHub + OpenCode | Documental |
| `documentador` | GitHub + OpenCode | Documental |
| `security-auditor` | GitHub + OpenCode | Documental |
| `api-developer` | GitHub + OpenCode | Implementador |
| `frontend-developer` | GitHub + OpenCode | Implementador |
| `devops` | GitHub + OpenCode | Implementador |
| `qa-senior` | GitHub + OpenCode | Implementador (tests) |
| `gitflow` | GitHub + OpenCode | Tooling |
| `solucionador` | GitHub + OpenCode | Plataforma (SSH) |
| `plataformador` | GitHub + OpenCode | Plataforma (auditoría) |

### 3. Documentación BASE por aplicación (en `Documentacion/<AppName>/`)

Ver `.doc_agents/capacidad-base.md` tabla completa. Resumen para Agents_IA_TECH:

| Ruta (en `Documentacion/Agents_IA_TECH/`) | Obligatorio |
|-------------------------------------------|:-----------:|
| `00-indice.md` | ✅ Sí |
| `idioma.md` | ✅ Sí |
| `preferencias.md` | ✅ Sí |
| `preferencias-git.md` | ⚠️ Recomendado |
| `referencias.md` | ⚠️ Recomendado |
| `roadmap.md` | ⚠️ Recomendado |
| `soluciones-conocidas.md` | ✅ Sí |
| `pendientes-implementacion.md` | ✅ Sí |
| `capacidad-base.md` | ✅ Sí (ref a .doc_agents/) |
| `memoria-proyecto.md` | ✅ Sí |
| `specs/` | ✅ Sí* |
| `arquitectura/adr/` | ⚠️ Recomendado |
| `arquitectura/diagramas/` | ⚠️ Recomendado |
| `agents/<nombre>/spec.md` | ⚠️ Recomendado |
| `bitacoras/` | ⚠️ Recomendado |

### 4. Skills globales (`.github/skills/` — 77 skills compartidas)

Incluyen: `speckit-*` (10), `chronicle`, `graphify`, `agent-customization`, `project-setup-info-local`, `codebase-memory`, `python-fact-grounded-coding`, `pylance-*`, y 60+ más.

### 5. MCP Servers recomendados

| Servidor | Estado |
|----------|--------|
| `codebase-memory-mcp` | ⚠️ Recomendado (pendiente configurar) |
| Otros | 📝 Según necesidad |

### 6. Hooks de ciclo de vida

| Hook | Propósito |
|------|-----------|
| `sessionStart` | Leer `Documentacion/Agents_IA_TECH/preferencias.md` al inicio |
| `subagentStart` | Recordar restricciones paths (solo `Documentacion/Agents_IA_TECH/` para documentales) |

---

## Ver también

- `.doc_agents/capacidad-base.md` — Fuente de verdad completa
- `.doc_agents/estructura-aplicacion.md` — Estructura por app
- `.doc_agents/estructura-estandar.md` — Estándar documental por app
- `.doc_agents/memoria-proyecto-template.md` — Template para memoria-proyecto.md
- `.doc_agents/sync-agents-template.ps1` — Template del script de sync