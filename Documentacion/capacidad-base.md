# 🏗️ Capacidad Base del Kit de Agentes

> **Catálogo central** de todas las capacidades que componen el kit.
> El agente `plataformador` lo usa como fuente de verdad para auditar y nivelar proyectos.

**Versión del kit**: 1.0.0
**Última actualización**: 2026-07-25

---

## 1. Archivos raíz del proyecto

| Archivo | Obligatorio | Propósito |
|---------|:-----------:|-----------|
| `.github/copilot-instructions.md` | ✅ Sí | Reglas base de todos los agentes |
| `.github/agents/` | ✅ Sí | Agentes para GitHub Copilot |
| `.opencode/agents/` | ✅ Sí | Agentes para OpenCode |
| `AGENTS.md` | ✅ Sí | Documentación del kit |
| `opencode.json` | ✅ Sí | Configuración OpenCode |
| `README.md` | ✅ Sí | README del proyecto |

## 2. Agentes (10)

| Agente | Plataforma | Versión |
|--------|-----------|---------|
| `pensador` | GitHub + OpenCode | 1.0 |
| `arquitecto` | GitHub + OpenCode | 1.0 |
| `documentador` | GitHub + OpenCode | 1.0 |
| `security-auditor` | GitHub + OpenCode | 1.0 |
| `api-developer` | GitHub + OpenCode | 1.0 |
| `frontend-developer` | GitHub + OpenCode | 1.0 |
| `devops` | GitHub + OpenCode | 1.0 |
| `qa-senior` | GitHub + OpenCode | 1.0 |
| `gitflow` | GitHub + OpenCode | 1.0 |
| `solucionador` | GitHub + OpenCode | 1.0 |

## 3. Documentación base del proyecto (`Documentacion/`)

| Ruta | Obligatorio | Propósito |
|------|:-----------:|-----------|
| `00-indice.md` | ✅ Sí | Índice general del proyecto |
| `idioma.md` | ✅ Sí | Configuración de idioma |
| `preferencias.md` | ✅ Sí | Memoria de preferencias del usuario |
| `preferencias-git.md` | ⚠️ Recomendado | Preferencias de flujo git |
| `referencias.md` | ⚠️ Recomendado | Atribución de fuentes externas |
| `roadmap.md` | ⚠️ Recomendado | Backlog de evolutivos |
| `soluciones-conocidas.md` | ✅ Sí | Repositorio de soluciones |
| `pendientes-implementacion.md` | ✅ Sí | Puente entre docs e implementación |
| `capacidad-base.md` | ✅ Sí | Catálogo central del kit |
| `memoria-proyecto.md` | ✅ Sí | Capacidades instaladas (mantenido por plataformador) |
| `agents/<nombre>/spec.md` | ⚠️ Recomendado | Spec individual de cada agente en `Documentacion/agents/<nombre>/spec.md` |
| `arquitectura/adr/` | ⚠️ Recomendado | Decisiones arquitectónicas en `Documentacion/arquitectura/adr/` |
| `bitacoras/` | ⚠️ Recomendado | Bitácoras del solucionador en `Documentacion/bitacoras/` |

## 4. Skills (`.github/skills/`)

*(77 skills disponibles. El instalador de codebase-memory-mcp también puede agregar skills propios)*

| Skill | Propósito |
|-------|-----------|
| `chronicle` | Análisis de historial de sesiones |
| `graphify` | Grafo de conocimiento del código |
| `agent-customization` | Creación/edición de agentes |
| ... | *(74 más)* |

## 5. MCP Servers

| Servidor | Estado | Integración |
|----------|--------|-------------|
| `codebase-memory-mcp` | ⚠️ Recomendado | Grafo de conocimiento del código. Instalar con `npm install -g codebase-memory-mcp` |
| Otros MCP | 📝 Pendiente | Según necesidad del proyecto |

## 6. Hooks de ciclo de vida

| Hook | Propósito |
|------|-----------|
| `sessionStart` | Leer preferencias.md al inicio |
| `subagentStart` | Recordar restricciones de paths |

---

## Historial de cambios

| Fecha | Versión | Cambio |
|-------|:-------:|--------|
| 2026-07-25 | 1.0.0 | Creación inicial del catálogo |
