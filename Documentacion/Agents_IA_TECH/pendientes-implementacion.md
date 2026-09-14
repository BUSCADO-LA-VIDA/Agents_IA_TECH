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

- [ ] `[MCP-ACTIVAR]` **Activar y usar los MCPs como herramienta primaria de consulta (ahorrar tokens)**
  - **Qué implementar**: Los MCPs (`context-mode`, `codebase-memory-mcp`, `markitdown`) están **instalados y configurados** en `.vscode/mcp.json`, pero **NO están disponibles como herramientas para los agentes** en la sesión actual. Por eso los agentes leen archivos directos (gastando más tokens). Este plan define lo que falta para **instalar, configurar y USAR** los MCPs de verdad.
  - **Basado en**: Plan aprobado por el usuario (2026-09-12) — activar MCPs + usar flujo de contexto. Decisión del usuario: "Si lees directo gastas más tokens. Define en el PLAN lo que falta primero para que instales, configures y uses los MCP."
  - **Fase A — Activar y verificar los MCPs (PRIORIDAD 1)**:
    - `plataformador`: Verificar instalación real de `context-mode`, `codebase-memory-mcp`, `markitdown-mcp` (responden `--version` y están en el `PATH`).
    - `plataformador`: **Reiniciar sesión de Copilot** (recargar ventana VS Code) para que `.vscode/mcp.json` se cargue y los MCPs se expongan como herramientas.
    - `plataformador`: Verificar que los MCPs aparecen como herramientas disponibles (`ctx_*`, `index_repository`, `query`, `semantic_search`, `convert_to_markdown`).
    - `plataformador`: Probar cada MCP con una consulta de prueba.
  - **Fase B — Configurar el uso de MCPs en los agentes (PRIORIDAD 2)**:
    - `documentador`: Actualizar `.github/copilot-instructions.md` con instrucción explícita: usar los MCPs (`ctx_search`, `index_repository`, `query`, `semantic_search`, `convert_to_markdown`) para consultar documentación/código en lugar de leer archivos directos cuando sea posible (ahorra tokens).
    - `documentador`: Actualizar specs de agentes con la instrucción de usar MCPs como herramienta primaria de consulta (no solo "optimización opcional").
    - `documentador`: Definir el flujo de re-indexación forzada (primera consulta → forzar re-indexación sin IA → luego consultar por MCP).
  - **Fase C — Completar los demás procesos (PRIORIDAD 3)**:
    - `upgrade_framework`: Flujo de actualización automática de herramientas externas.
    - `plataformador`: Implementar flujo de contexto con re-indexación forzada.
    - `gitflow`: Commits.
  - **Prioridad**: alta

- [ ] `[FLUJOS]` **Alinear flujos del kit: contexto (consultar Documentacion/) + actualización automática de herramientas externas**
  - **Qué implementar**: Definir y documentar dos flujos que faltan para que el kit funcione de forma coherente:
    1. **Flujo de contexto**: Todos los agentes consultan `Documentacion/Agents_IA_TECH/` (fuente de verdad) para saber en qué punto de la solución estamos. Los MCPs (context-mode, codebase-memory-mcp, markitdown) **optimizan** esa consulta, NO la reemplazan. Incluye **actualización de memoria/índice** cuando cambia la documentación (los MCPs no siempre están actualizados).
    2. **Flujo de actualización automática de herramientas externas**: Al agregar/quitar herramientas externas, `upgrade_framework` sabe exactamente qué hacer (no como hoy con graphify/MCP). El flujo concreto se define al momento de la implementación.
  - **Basado en**: Plan aprobado por el usuario (2026-09-12) — alinear flujos del kit
  - **Fase documental**:
    - `arquitecto`: ✅ **COMPLETADA (2026-09-12)** — ADR-0002 creado en `arquitectura/adr/adr-0002-flujos-kit.md` (contexto, decisión de ambos flujos, consecuencias, guardrails, spec linking, diagrama Mermaid **Flujo de contexto**, plan por fases). Actualizados `00-indice.md` (ADRs activos) y `pendientes-implementacion.md`.
    - `documentador`: ✅ **COMPLETADA (2026-09-12)** — Documentado el **flujo de contexto** (ADR-0002) en las specs de **todos los agentes** del kit: `pensador`, `plataformador`, `analista_tecnico`, `arquitecto`, `documentador`, `security-auditor`, `api-developer`, `frontend-developer`, `devops`, `qa-senior`, `gitflow` y `solucionador`. En cada spec se agregó una sección **"Flujo de contexto (ADR-0002)"** con: archivos de entrada obligatorios al iniciar una tarea (`00-indice.md`, `pendientes-implementacion.md`, `memoria-proyecto.md`, `preferencias.md`, `idioma.md`), la regla de que los MCPs (`context-mode`, `codebase-memory-mcp`, `markitdown`) **optimizan y NO reemplazan** la fuente de verdad, el orden de consulta (primero doc directa, luego MCPs), la **actualización de memoria/índice** (re-indexar + actualizar `analisis-memoria.md`) y el diagrama **Flujo de contexto** reutilizado del ADR-0002. En `pensador` se agregó además la responsabilidad 15 (flujo de contexto). En los implementadores se adaptó la lista de archivos a su rol (specs de feature, soluciones-conocidas en `solucionador`, sección "Completadas" en `gitflow`).
    - `security-auditor`: ✅ **COMPLETADA (2026-09-12)** — Revisión de seguridad de uso del **flujo de contexto** (ADR-0002, Flujo 1) creada en `Documentacion/Agents_IA_TECH/seguridad/flujo-contexto.md`. Analiza los 4 momentos de riesgo del flujo: **M-1** consultar `Documentacion/` (riesgo 🔴 Crítico de secrets/credenciales en la doc expuestos a todos los agentes; rutas privadas 🟠; datos personales 🟡; contenido no confiable 🟡), **M-2** MCPs como optimización (indexación de datos sensibles en FTS5/grafo — ya cubierto en `context-mode.md` y `ecosistema-documentacion.md`; MCPs no reemplazan la fuente de verdad 🟡), **M-3** actualización de memoria/índice (re-indexar propaga datos sensibles 🟠; índice desactualizado 🟡; `analisis-memoria.md` sin contenido sensible 🔵) y **M-4** acceso de todos los agentes (segmentar por rol 🟡; agentes con SSH sin credenciales en bitácoras 🟠; escritura restringida por rol 🟡). Incluye tabla de 14 riesgos→mitigación, recomendaciones de uso seguro, qué NO hacer y checklist. **Conclusión**: sin vulnerabilidades críticas que bloqueen la adopción, siempre que se respete la regla de **no escribir secrets en `Documentacion/`** (riesgo #1 🔴, mitigable con disciplina). Actualizado `pendientes-implementacion.md`.
  - **Fase implementación** (define el flujo concreto de actualización de herramientas):
    - `upgrade_framework`: Definir e implementar el flujo de actualización automática de herramientas externas (agregar/quitar/actualizar por carpeta).
    - `plataformador`: Implementar el flujo de contexto (consultar `Documentacion/` + validar MCPs + actualizar memoria/índice).
    - `gitflow`: Commits al final.
  - **Decisión del usuario (2026-09-12) — Re-indexación forzada + MCPs no instalados**: El usuario decidió que en la **primera consulta de cada sesión** se **fuerce la re-indexación** de los MCPs (`context-mode`, `codebase-memory-mcp`) y la actualización de `analisis-memoria.md` **antes** de que la IA consulte por MCP. La re-indexación es **procesamiento local sin IA** (FTS5/grafo, determinista y barato), por lo que no consume IA y garantiza índice/grafo **siempre fresco** → búsqueda por MCP más eficiente. Además, si un MCP **no está instalado** (no responde o no está en `.vscode/mcp.json`), se debe **instalarlo** (con confirmación del usuario) y **repetir el proceso de actualización de índices y grafos** antes de consultar. Flujo: **instalar → re-indexar → recién ahí consultar por MCP**. Esta decisión se incorporó al ADR-0002 (guardrails 4 y 5, diagrama Mermaid actualizado) y a las specs de `pensador` y `plataformador`.
  - **Prioridad**: alta

- [x] `[ECOSISTEMA]` **Ecosistema de documentación técnica sin IA de entrada (markitdown + graphify + codebase-memory-mcp + context-mode + analista_tecnico)**
  - **Qué implementar**: Pipeline de herramientas que generan documentación técnica sin IA de entrada (solo Python + MCP), IA solo bajo demanda, con archivo de memoria `analisis-memoria.md`. Nuevo agente `analista_tecnico` que orquesta el pipeline.
  - **Basado en**: `Documentacion/Agents_IA_TECH/README-ECOSISTEMA-DOCUMENTACION.md` (plan aprobado con 3 diagramas Mermaid reutilizables: pipeline, flujo del analista_tecnico, integración en arquitectura) + `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` (ADR-0001: arquitectura del pipeline, guardrails y spec linking)
  - **Fase documental**:
    - `arquitecto`: ✅ **COMPLETADA (2026-09-12)** — ADR-0001 creado en `arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` (contexto, decisión, consecuencias, guardrails, spec linking, plan por fases). Reutilizados diagramas **Pipeline** + **Integración en arquitectura**. Actualizados `00-indice.md` (ADRs activos) y `pendientes-implementacion.md`.
    - `documentador`: ✅ **AVANZADA (2026-09-12)** — Guías creadas en `MCPs/markitdown.md` (qué es, instalación `pip install 'markitdown[all]'` + `markitdown-mcp`, uso CLI `markitdown file.pdf -o file.md`, uso MCP `convert_to_markdown(uri)`, formatos soportados, integración en pipeline con diagrama **Pipeline** reutilizado, mantenimiento y buenas prácticas) y `MCPs/codebase-memory-mcp.md` (qué es, herramientas `index_repository`/`query`/`semantic_search`, instalación `npm install -g codebase-memory-mcp`, configuración, integración en pipeline con diagrama **Pipeline** reutilizado, uso por agentes documentales). Actualizados `referencias.md` (markitdown MIT, codebase-memory-mcp licencia a verificar), `memoria-proyecto.md` (ambos MCPs en integración), `roadmap.md` (integración del ecosistema), `00-indice.md` (estructura MCPs/ + tabla de MCPs), `pendientes-implementacion.md`.
    - `security-auditor`: ✅ **COMPLETADA (2026-09-12)** — Revisión de seguridad de uso creada en `Documentacion/Agents_IA_TECH/seguridad/ecosistema-documentacion.md` (análisis de riesgos de `markitdown` — XXE, ZIP bomb, HTML malicioso, PDF malformado — y de `codebase-memory-mcp` — indexación de secrets, datos sensibles, permisos del índice; tabla de riesgos→mitigación; recomendaciones de uso seguro; qué NO hacer; checklist; diagrama **Pipeline** reutilizado para señalar los puntos de entrada de datos PE-1 a PE-4). **Licencia de `codebase-memory-mcp` verificada: MIT** (guardrail 8 del ADR-0001 satisfecho; `npm view codebase-memory-mcp license` → MIT, repo https://github.com/DeusData/codebase-memory-mcp). Actualizados `referencias.md` (licencia MIT + URL), `00-indice.md` (tabla de MCPs).
  - **Fase implementación**:
    - `plataformador`: ✅ **COMPLETADA (2026-09-12)** — Instalado `markitdown` 0.1.7 (`pip install 'markitdown[all]'`, verificado `markitdown --version` → 0.1.7) y `markitdown-mcp` 0.0.1a3 (`pip install markitdown-mcp==0.0.1a3` + `pip install "mcp<2"` v1.30.0 por API FastMCP; verificado que arranca). `codebase-memory-mcp` 0.9.0 ya estaba instalado (`npm install -g codebase-memory-mcp`, verificado `codebase-memory-mcp --version` → 0.9.0). Creado `.vscode/mcp.json` con `markitdown` y `codebase-memory-mcp`. Hooks: no aplican a markitdown/codebase-memory-mcp (los hooks `.github/hooks/context-mode.json` son de context-mode, tarea `[MCP]` aparte). Actualizados `memoria-proyecto.md` (ambos MCPs 🟢 instalados) y `pendientes-implementacion.md`. **Nota**: `markitdown-mcp` de PyPI 0.0.1a1 es un stub sin servidor; la versión funcional es 0.0.1a3 (requiere `mcp<2`).
    - `upgrade_framework`: ✅ **COMPLETADA (2026-09-12)** — Registradas `markitdown` (0.1.7, MIT), `markitdown-mcp` (0.0.1a3, MIT) y `codebase-memory-mcp` (0.9.0, MIT) en `dependencias-manifest.yml` (fase implementación paso 5º). `graphify` marcada con licencia ⚠️ pendiente de verificar (guardrail 8 del ADR-0001). Actualizado historial del manifest.
    - `pensador` + documentales: ✅ **COMPLETADA (2026-09-12)** — Creada la spec del agente `analista_tecnico` en `agents/analista_tecnico/spec.md` (rol, responsabilidades, herramientas del pipeline, flujo con diagrama **Flujo del `analista_tecnico`** reutilizado, integración con diagrama **Integración en arquitectura** reutilizado, guardrails del ADR-0001, restricciones de paths, flujo típico, idioma, **regla dual-harness Copilot + OpenCode**). Creado el agente en **ambos harness**: `.github/agents/analista_tecnico.agent.md` (Copilot) y `.opencode/agents/analista_tecnico.md` (OpenCode). Creado `analisis-memoria.md` (archivo de memoria del pipeline). Actualizados `00-indice.md` (agente `analista_tecnico` 🟢 activo + estructura), `preferencias.md` (regla dual-harness) y `pendientes-implementacion.md`.
    - `gitflow`: Commits convencionales.
  - **Guardrails (ADR-0001)**: Sin IA de entrada por defecto (IA solo bajo demanda y preguntando al usuario); archivo de memoria `analisis-memoria.md` obligatorio (nunca re-analizar); orden de herramientas respetado; delegación no duplicación; retorno al `pensador`; respeto estructura SSD; reutilizar diagramas; verificar licencias; paths restringidos; validación de MCPs al iniciar sesión.
  - **Limpieza**: ✅ **DONE (2026-09-12)** — La carpeta vieja `Documentacion/Agents_IA_TECH/mcp/` (singular) fue **eliminada manualmente por el usuario**. Todas las referencias ya apuntan a `MCPs/` (plural). No quedan referencias a la carpeta vieja.
  - **Prioridad**: alta

- [x] `[ECOSISTEMA]` **Crear archivo de memoria `analisis-memoria.md` del pipeline**
  - **Qué implementar**: Crear `Documentacion/Agents_IA_TECH/analisis-memoria.md` que registre qué documentación fue convertida a MD (markitdown), indexada/graficada (graphify/codebase-memory-mcp), y qué requiere IA (y si ya fue analizada). Evita re-análisis.
  - **Basado en**: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` (sección "El archivo de memoria" + guardrail 2)
  - **Archivos esperados**: `Documentacion/Agents_IA_TECH/analisis-memoria.md`
  - **Estado**: ✅ **COMPLETADA (2026-09-12)** — Creado `Documentacion/Agents_IA_TECH/analisis-memoria.md` con estado del pipeline, registro detallado y cómo actualizarlo.
  - **Prioridad**: alta

- [x] `[ECOSISTEMA]` **Crear spec del agente `analista_tecnico`**
  - **Qué implementar**: Crear la spec del nuevo agente `analista_tecnico` (rol, responsabilidades, flujo, guardrails del ADR-0001, restricciones de paths) en `Documentacion/Agents_IA_TECH/agents/analista_tecnico/spec.md` y su `.agent.md` en `.github/agents/`. Reutilizar diagramas **Flujo del `analista_tecnico`** + **Integración en arquitectura**.
  - **Basado en**: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` (sección "El agente `analista_tecnico`" + guardrails) + `README-ECOSISTEMA-DOCUMENTACION.md`
  - **Archivos esperados**: `Documentacion/Agents_IA_TECH/agents/analista_tecnico/spec.md`, `.github/agents/analista_tecnico.agent.md`
  - **Estado**: ✅ **COMPLETADA (2026-09-12)** — Creada la spec en `agents/analista_tecnico/spec.md` y el `.agent.md` en `.github/agents/analista_tecnico.agent.md`. Diagramas **Flujo del `analista_tecnico`** + **Integración en arquitectura** reutilizados tal cual.
  - **Prioridad**: alta

- [x] `[MCP]` **Integrar context-mode como herramienta MCP del kit (instalación, configuración, uso y mantenimiento)**
  - **Qué implementar**: Integrar `context-mode` (https://github.com/mksglu/context-mode) como MCP listo para usar. Enfocado SOLO en instalación, configuración, utilización y mantenimiento de uso — NO desarrollo.
  - **Fase documental**:
    - `documentador`: ✅ **AVANZADA (2026-09-12)** — Guía práctica creada en `Documentacion/Agents_IA_TECH/MCPs/context-mode.md` (instalación, configuración en el kit, uso de herramientas `ctx_*`, mantenimiento: `ctx_purge` limpiar historial, `ctx_stats` ver stats, `ctx_upgrade` actualizar, `ctx_doctor` diagnosticar, opciones óptimas con menor uso de IA, seguridad). Actualizados `referencias.md` (licencia ELv2), `memoria-proyecto.md`, `roadmap.md`, `00-indice.md`, `pendientes-implementacion.md`.
    - `security-auditor`: ✅ **COMPLETADA (2026-09-12)** — Revisión breve de seguridad de uso creada en `Documentacion/Agents_IA_TECH/seguridad/context-mode.md` (ejecución sandbox, fetch de URLs/SSRF, datos indexados FTS5, licencia ELv2, hooks de VS Code, redacción de credenciales). Incluye tabla de riesgos→mitigación, recomendaciones de uso seguro, qué NO hacer y checklist.
  - **Fase implementación**:
    - `plataformador`: ✅ **COMPLETADA (2026-09-12)** — Registrado `context-mode` en `.vscode/mcp.json` (entrada `context-mode` con comando y descripción). Creados hooks `.github/hooks/context-mode.json` (PreToolUse, PostToolUse, SessionStart). Actualizado `memoria-proyecto.md` (context-mode 🟢 instalado + próximos pasos). **Nota**: la instalación real (`npm install -g context-mode`) requiere ejecutarse en terminal (Node >= 22.5) — pendiente de confirmación del usuario.
    - `upgrade_framework`: ✅ **COMPLETADA (2026-09-12)** — Registrado `context-mode` (v1.0.169, ELv2) en `dependencias-manifest.yml` (tipo MCP server, rol en pipeline, instalación, requisitos Node >= 22.5). Licencia ELv2 documentada (guardrail 8 del ADR-0001).
    - `pensador` + documentales: ✅ **COMPLETADA (2026-09-12)** — Ajustadas specs de `pensador` (responsabilidad 14: validar MCPs y documentación técnica), `plataformador` (sección "Validación de MCPs y documentación técnica" transparente), `arquitecto` (validar guías MCP + usar herramientas MCP) y `documentador` (documentar MCPs del ecosistema + usar herramientas MCP).
    - `gitflow`: Generar comandos de commit convencionales al final.
  - **Requisitos**: Node.js >= 22.5. Licencia ELv2 (source-available, no MIT).
  - **Prioridad**: alta
  - **Nota**: El routing de context-mode propone copiar su `copilot-instructions.md` encima del canónico del kit → FUSIONAR, no sobrescribir.

- [ ] `[MCP]` **Configurar agentes para usar codebase-memory-mcp**
  - **Qué implementar**: Ajustar instrucciones del `pensador`, `arquitecto` y `documentador` para que usen las herramientas MCP (index_repository, query, semantic_search, etc.)
  - **Estado actual**: 🟡 MCP `codebase-memory-mcp` en integración — guía creada en `Documentacion/Agents_IA_TECH/MCPs/codebase-memory-mcp.md` (2026-09-12). MCP aún no instalado (ver `Documentacion/Agents_IA_TECH/memoria-proyecto.md`)
  - **Siguiente paso**: Instalar MCP server (`npm install -g codebase-memory-mcp`) - tarea del `plataformador`
  - **Basado en**: `Documentacion/Agents_IA_TECH/MCPs/codebase-memory-mcp.md` + una vez instalado, ajustar specs en `agents/pensador/spec.md`, `agents/arquitecto/spec.md`, `agents/documentador/spec.md`
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

## ⏳ Nuevas Tareas Críticas - Reglas de Oro

- [ ] `[REGLA-ORO]` **Ciclo Plan→Doc→Impl siempre vigente**
  - **Qué implementar**: Asegurar que todos los agentes respeten el orden sagrado: Plan aprobado → Documentar → Implementar (nunca saltar fases)
  - **Qué hacer**: Al detectar que un agente quiere saltar directamente a implementar o documentar, el Pensador debe: (1) Verificar en qué fase se encuentra realmente, (2) Si no es la correcta → regresar a la fase apropiada, (3) Nunca permitir implementar sin documentación completa y aprobada
  - **Prioridad**: alta
  - **Nota**: Esta es la regla principal para evitar el ciclo roto donde se salta documentación y se van directamente a ajustes sin documentar ni controlar memoria.

- [ ] `[ERROR-ROOT]` **Detección de causa raíz en debugging**
  - **Qué implementar**: El Pensador y todos los agentes deben buscar la causa real, no quedarse en círculos de ajustes superficiales. Cuando hay errores: (1) Analizar el error completo, (2) Identificar causa raíz, (3) Documentar el fix, (4) Aplicar fix, (5) Verificar. Si el error reaparece → regresar a causa raíz, no a ajustes parciales.
  - **Prioridad**: alta
  - **Nota**: Evita el patrón "solo ajusta y sigue" que rompe la documentación y memoria.

- [ ] `[CAMBIO-VISION]` **Reinicio automático al cambio de visión**
  - **Qué implementar**: Si el usuario cambia de visión en cualquier punto del proceso → REINICIAR el ciclo completo desde el análisis inicial
  - **Qué hacer**: En cualquier fase, si el usuario indica que quiere cambiar de dirección → el Pensador debe regresar al Paso 2 (ANÁLISIS PRIMERO) y comenzar de nuevo
  - **Prioridad**: alta
  - **Nota**: Evita que se queden en trabajo inútil cuando el usuario ha cambiado de opinión.

- [ ] `[UPGRADE_FRAMEWORK]` **Implementar agente de actualización inteligente de framework**
  - **Qué implementar**: Crear el agente `upgrade_framework` que gestiona directorios de proyectos externos, sabe qué copiar dónde, aplica configuración necesaria y personalizaciones inteligentes, usando IA solo para análisis de impacto
  - **Basado en**: `Documentacion/Agents_IA_TECH/agents/upgrade_framework/spec.md`
  - **Archivos esperados**: Estructura completa en `Documentacion/Agents_IA_TECH/agents/upgrade_framework/`
  - **Prioridad**: alta

- [x] `[UPGRADE_EXECUTADO]` **Ejecutar actualización de herramientas externas vía upgrade_framework**
  - **Qué se ejecutó**: Agente `upgrade_framework` para actualizar herramientas externas listadas en dependencias-manifest.yml
  - **Basado en**: `Documentacion/Agents_IA_TECH/agents/upgrade_framework/spec.md`
  - **Resultado**: Actualización completada de spec-kit, graphify y otras dependencias listadas
  - **Fecha**: 2026-09-05
  - **Nota**: Se usó IA solo para análisis de impacto de integración, siguiendo las reglas de uso eficiente de IA