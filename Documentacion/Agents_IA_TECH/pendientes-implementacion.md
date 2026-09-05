# Pendientes de Implementación - Agents_IA_TECH

> **Puente vivo entre documentación e implementación.**
> Mantenido por **todos los agentes** — cada uno en su rol:
> - **`pensador`** — Orquestador. Navega fuentes externas, filtra información. Genera y valida specs (spec generation + validation). Complementa Specify.
> - **Documentales** (`arquitecto`, `documentador`, `security-auditor`) agregan tareas nuevas. El `documentador` usa templates por tipo, mantiene versionado de specs y genera planes de implementación (spec → plan).
> - **Arquitecto** define spec linking (trazabilidad) y guardrails (restricciones).
> - **Implementadores** (`api-developer`, `frontend-developer`, `devops`) marcan como completadas y reportan bugs.
> - **QA** (`qa-senior`) escribe tests automáticos (unitarios, integración, API, E2E con Playwright navegando la app) y puede conectarse por SSH / queries a DB para diagnosticar. Crea tests repetibles que validan cada issue. Si encuentra un bug, lo documenta aquí y se lo pasa al desarrollador (NO lo corrige).
> - **Si hay un error sin spec** → el implementador crea la tarea y pide al documentador que la especifique (nunca improvisa).
> El implementador lo lee **primero** para saber exactamente qué hacer, sin recorrer todas las specs.

## Formato de cada tarea

```markdown
- [ ] `[Área]` **Título descriptivo**
  - **Qué implementar**: descripción concreta
  - **Basado en**: `Documentacion/Agents_IA_TECH/archivo-especifico.md` (ADR / Spec)
  - **Archivos esperados**: `src/ruta/al/archivo.ts`
  - **Prioridad**: alta / media / baja
```

---

## ⏳ Tareas pendientes

- [ ] `[MCP]` **Configurar agentes para usar codebase-memory-mcp**
  - **Qué implementar**: Ajustar instrucciones del `pensador`, `arquitecto` y `documentador` para que usen las herramientas MCP (index_repository, query, semantic_search, etc.)
  - **Estado actual**: ❌ MCP `codebase-memory-mcp` no instalado (ver `Documentacion/Agents_IA_TECH/memoria-proyecto.md`)
  - **Siguiente paso**: Instalar MCP server (`npm install -g codebase-memory-mcp`) - tarea del `plataformador`
  - **Basado en**: Una vez instalado, ajustar specs en `agents/pensador/spec.md`, `agents/arquitecto/spec.md`, `agents/documentador/spec.md`
  - **Prioridad**: media
  - **Nota**: MCP habilita `index_repository`, `query`, `semantic_search` para búsquedas semánticas en el grafo de conocimiento. Los agentes documentales pueden usarlo para mejor contexturar specs y decisiones.

- [x] `[PERSISTENCIA]` **Sistema de persistencia de sesiones en disco**
  - **Qué implementar**: Pensador guarda análisis/planes/decisiones en `Documentacion/Agents_IA_TECH/sesiones/`. Al iniciar, lee la última sesión como base conceptual. Pregunta antes de borrar: "¿Querés guardar esta propuesta?"
  - **Infraestructura**: ✅ Completa - Folder `sesiones/` creado, sesión de ejemplo `2026-08-30-reestructuracion-completa.md`, regla en `preferencias.md`
  - **Basado en**: `Documentacion/Agents_IA_TECH/preferencias.md` (regla 2026-08-30)
  - **Archivos esperados**: `Documentacion/Agents_IA_TECH/sesiones/`, scripts de guardado/carga (convenio manual)
  - **Prioridad**: alta
  - **Nota**: La persistencia sigue el convenio de guardar archivos markdown en `sesiones/` con formato `YYYY-MM-DD-titulo.md`. Al iniciar VS Code, el Pensador lee la última sesión para recuperación de contexto.

- [x] `[SPECIFY]` **Definir integración explícita Pensador ↔ Specify (speckit skills)**
  - **Qué implementar**: Mapear qué skills de speckit invoca Pensador y en qué orden
  - **Integración definida**: ✅ Ya definida en `Documentacion/Agents_IA_TECH/referencias.md` con tabla complementariedad completa
  - **Orden de invocación Pensador → Specify**:
    1. `speckit-specify` → Generación de specs cuando el usuario solicita especificación
    2. `speckit-analyze` → Validación cross-artifact (spec ↔ plan ↔ tasks ↔ ADRs)
    3. `speckit-plan` → Generación de plan.md desde spec aprobada (orquesta Documentador)
    4. `speckit-tasks` → Generación de tasks.md desde plan aprobado (orquesta Documentador)
    5. `speckit-converge` → Verificación de implementación pendiente vs spec
    6. `speckit-implement` → Ejecución por parte de implementadores (api, frontend, devops)
    7. Feedback loop: QA-senior valida código implementado contra spec original
  - **Basado en**: `Documentacion/Agents_IA_TECH/referencias.md` (tabla complementariedad)
  - **Prioridad**: alta
  - **Notas**: Specify NO se duplica, los agentes complementan. Flujo integrado: Pensador decide → Specify ejecuta → Mis agentes complementan (SSH, plataformador, gitflow, orchestración) → Documentador persiste → Implementadores ejecutan → QA valida → Gitflow commitea

- [x] `[PLATAFORMADOR]` **Plataformador v2: Auditoría automática + reporte**
  - **Qué implementar**: Auditoría contra `.doc_agents/capacidad-base.md` con reporte detallado y auto-nivelación opcional (preguntar antes)
  - **Infraestructura**: ✅ El agente `plataformador` ya tiene capacidad de auditoría completa incluida en su spec (`agents/plataformador/spec.md`)
  - **Capacidades incluidas**:
    - Auditoría contra `.doc_agents/capacidad-base.md` (catálogo de kit)
    - Compara `Documentacion/Agents_IA_TECH/` contra `.doc_agents/estructura-estandar.md`
    - Detecta diferencias: archivos fuera de lugar, carpetas faltantes, huérfanos
    - Propone nivelación y pregunta antes de ejecutar
    - Orquesta `Arquitecto → Documentador → Security` para documentar proyecto
    - Integrates `graphify` para grafo de conocimiento
    - Actualiza `memoria-proyecto.md` con resultado
  - **Basado en**: `.doc_agents/capacidad-base.md`, `.doc_agents/estructura-aplicacion.md`, `.doc_agents/estructura-estandar.md`
  - **Prioridad**: alta
  - **Nota**: El agente plataformador puede ejecutarse manualmente o ser invocado por `pensador` al detectar proyecto nuevo/copiado o cambios en capacidad-base

---

## ✅ Tareas completadas

| Fecha | Tarea | Implementador |
|-------|-------|---------------|
| 2026-08-05 | Crear workflow de seguridad general (`security-scan.yml`) con gitleaks sobre todo el repo | `devops` |
| 2026-08-05 | Crear workflow de ortografía (`spellcheck.yml`) con codespell | `devops` |
| 2026-08-05 | Crear `.gitattributes` con normalización `eol=lf` | `devops` |
| 2026-08-05 | Actualizar `checkout`/`setup-node` a runtime node24 en `openwiki-update.yml` y `agentshield.yml` | `pensador` |
| 2026-07-27 | Reorganizar estructura `Documentacion/`: mover `adr/` → `arquitectura/adr/`, `specs/` → `funcionalidades/`, actualizar specs | `pensador` |
| 2026-08-30 | Mover documentación a `Documentacion/Agents_IA_TECH/`, crear análisis Specify vs Agentes, definir complementariedad | `pensador` |

---

## 📋 Historial de cambios del documento

| Fecha | Quién | Descripción |
|-------|-------|-------------|
| 2026-06-26 | system | Creación inicial del archivo |
| 2026-08-30 | pensador | Movido a Documentacion/Agents_IA_TECH/, agregadas tareas de persistencia e integración Specify |