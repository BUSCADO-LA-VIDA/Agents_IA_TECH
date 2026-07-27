# Pendientes de Implementación

> **Puente vivo entre documentación e implementación.**
> Mantenido por **todos los agentes** — cada uno en su rol:
> - **`pensador`** — Orquestador. Navega fuentes externas, filtra información. Genera y valida specs (spec generation + validation).
- **Documentales** (`arquitecto`, `documentador`, `security-auditor`) agregan tareas nuevas. El `documentador` usa templates por tipo, mantiene versionado de specs y genera planes de implementación (spec → plan).
- **Arquitecto** define spec linking (trazabilidad) y guardrails (restricciones).
> - **Implementadores** (`api-developer`, `frontend-developer`, `devops`) marcan como completadas y reportan bugs.
> - **QA** (`qa-senior`) escribe tests automáticos (unitarios, integración, API, E2E con Playwright navegando la app) y puede conectarse por SSH / queries a DB para diagnosticar. Crea tests repetibles que validan cada issue. Si encuentra un bug, lo documenta aquí y se lo pasa al desarrollador (NO lo corrige).
> - **Si hay un error sin spec** → el implementador crea la tarea y pide al documentador que la especifique (nunca improvisa).
> El implementador lo lee **primero** para saber exactamente qué hacer, sin recorrer todas las specs.

## Formato de cada tarea

```markdown
- [ ] `[Área]` **Título descriptivo**
  - **Qué implementar**: descripción concreta
  - **Basado en**: `Documentacion/specs/archivo-especifico.md` (ADR / Spec)
  - **Archivos esperados**: `src/ruta/al/archivo.ts`
  - **Prioridad**: alta / media / baja
```

---

## ⏳ Tareas pendientes

- [ ] `[MCP]` **Configurar agentes para usar codebase-memory-mcp**
  - **Qué implementar**: Ajustar instrucciones del `pensador`, `arquitecto` y `documentador` para que usen las herramientas MCP (index_repository, query, semantic_search, etc.)
  - **Basado en**: MCP instalado (codebase-memory-mcp)
  - **Prioridad**: media

---

## ✅ Tareas completadas

| Fecha | Tarea | Implementador |
|-------|-------|---------------|
| 2026-07-27 | Reorganizar estructura `Documentacion/`: mover `adr/` → `arquitectura/adr/`, `specs/` → `funcionalidades/`, actualizar specs del plataformador, arquitecto, documentador e índice | `pensador` |

---

## 📋 Historial de cambios del documento

| Fecha | Quién | Descripción |
|-------|-------|-------------|
| 2026-06-26 | system | Creación inicial del archivo |
