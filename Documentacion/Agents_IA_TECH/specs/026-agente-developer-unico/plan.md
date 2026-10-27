# Plan 026 - Agente developer único con skills especializadas

## 1. Technical Context - actualizado

### Stack tecnológico
- Kit Agents_IA_TECH: PowerShell 7+, Markdown, YAML/JSON
- Harness dual: `.github/agents/` y `.opencode/agents/`
- Skills globales en `.github/skills/` y `.opencode/skills/`
- MCPs activos: context-mode, codebase-memory-mcp, markitdown, tokenslayer, graphify

### Entidades / Agentes afectados
- Agentes a unificar: `api-developer.agent.md`, `frontend-developer.agent.md`, `devops.agent.md`, `qa-senior.agent.md`
- Agente destino: `developer.agent.md` / `developer.md`
- Constitución: `.specify/memory/constitution.md` Art.VII Restricción de Paths por Tier
- Índice: `Documentacion/Agents_IA_TECH/00-indice.md`
- Backlog: `pendientes-implementacion.md`

### Integraciones
- Sync kit: `scripts/sync-kit-agents.ps1` con capas agents-github, agents-opencode
- Speckit: flujo specify → plan → tasks → analyze → converge → implement
- Context7: consulta documentación oficial en tiempo real por cada skill

### Desconocidos resueltos
- Necesidad de compatibilidad hacia atrás: NO requerida, el agente developer reemplaza completamente
- Impacto en proyectos consumidores: sync-kit-agents eliminará agentes huérfanos mediante clean+replace

## 2. Constitution Check

- Art.I Library-First: Mantener skills como librerías standalone
- Art.II CLI Interface: No aplica a agente documental
- Art.III Test-First: Validación vía QA-senior en flujo Speckit
- Art.IV Simplicity: Reduce de 4 agentes implementadores a 1
- Art.V Security: Sin cambios de superficie de seguridad
- Art.VI project_ext: Sin dependencias externas nuevas
- Art.VII Paths: Actualizar whitelist Implementador a `developer` único
- Art.VIII Anti-Abstraction: Uso directo de skills, sin capa adicional
- Art.IX Integration-First: Paridad harnesses verificada

**Resultado**: PASS con actualización requerida en Art.VII

## 3. Arquitectura

**Patrón**: Agente implementador unificado con skills especializadas
- `developer` decide skill a invocar según dominio de tarea de `tasks.md`
- Skills: docker-patterns, api-design, frontend-patterns, backend-patterns, devops-patterns, testing, public-documentation
- Uso obligatorio de context7 para documentación oficial

**Flujo**
1. Pensador asigna tarea en pendientes-implementacion.md
2. Developer recibe tarea, identifica dominio
3. Invoca skill especializada + context7
4. Implementa en `src/<App>/` y `tests/`
5. Actualiza estado a Cerrado

## 4. Fases de implementación

### Fase 0: Research
- Validar skills existentes en `.github/skills/` y `.opencode/skills/`
- Confirmar disponibilidad context7

### Fase 1: Diseño
- data-model.md: estructura agente developer, mapeo skills → dominios
- contracts: paridad harnesses `.github` ↔ `.opencode`
- quickstart.md: validación de invocación de skill con context7

### Fase 2: Tareas
- Crear/actualizar agente developer
- Actualizar constitución Art.VII
- Eliminar agentes obsoletos
- Sincronizar harnesses
- Validar sync-kit-agents

**Artefactos generados**: research.md, data-model.md, contracts/, quickstart.md
