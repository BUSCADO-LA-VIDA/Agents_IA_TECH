# 📋 Índice del Proyecto: Agents_IA_TECH
*Última actualización: 2026-08-30*

> Este archivo es la **memoria del proyecto** para los agentes. Lo leen primero para entender el contexto sin escanear todo. Los agentes documentales lo mantienen actualizado automáticamente.

## Stack
- Framework: (kit de agentes — sin framework de aplicación)
- Lenguaje: Markdown / YAML
- Base de datos: (ninguna — es configuración de agentes)
- Infraestructura: GitHub Copilot + OpenCode

## CI/CD (GitHub Actions)
- `agentshield.yml` — Security scan de configs de agentes (`ecc-agentshield`, solo `.github/**`)
- `security-scan.yml` — Detección de secrets (gitleaks) sobre todo el repo (push/PR)
- `spellcheck.yml` — Revisión de ortografía (codespell) sobre `.md`/`.yaml`/`.yml` (push/PR)

## Estructura del proyecto

```
Documentacion/
└── Agents_IA_TECH/           ← 📁 Carpeta PROPIA de ESTE proyecto
    ├── 00-indice.md          ← 📋 Este archivo
    ├── idioma.md             ← 🌐 Config de idioma
    ├── preferencias.md       ← 👤 Preferencias usuario
    ├── preferencias-git.md   ← 🏷️ Flujo git
    ├── referencias.md        ← 📖 Fuentes externas
    ├── roadmap.md            ← 🗺️ Backlog evolutivos
    ├── pendientes-implementacion.md ← 📋 Puente docs ↔ código
    ├── soluciones-conocidas.md ← 📚 Soluciones recurrentes
    ├── capacidad-base.md     ← 🏗️ Ref. a .doc_agents/capacidad-base.md
    ├── memoria-proyecto.md   ← 🧠 Capacidades instaladas (plataformador)
    ├── analisis-memoria.md   ← 📝 Memoria del pipeline de documentación (analista_tecnico)
    │
    ├── specs/                ← 📋 speckit ESCRIBE AQUÍ (spec/plan/tasks)
    │   └── ...
    │
    ├── MCPs/                 ← 🔌 Guías de integración de MCPs
    │   ├── context-mode.md   ←   Guía práctica MCP context-mode
    │   ├── markitdown.md     ←   Guía práctica markitdown (+ markitdown-mcp)
    │   └── codebase-memory-mcp.md ← Guía práctica MCP codebase-memory-mcp
    │
    ├── README-ECOSISTEMA-DOCUMENTACION.md ← 🧠 Plan ecosistema doc sin IA de entrada (aprobado)
    │
    ├── arquitectura/         ← 📐 Decisiones arquitectura
    │   ├── adr/              ←   ADRs
    │   └── diagramas/        ←   Diagramas Mermaid
    │
    ├── agents/               ← 🤖 Config agentes para ESTE proyecto
    │   ├── pensador/spec.md
    │   ├── arquitecto/spec.md
    │   ├── documentador/spec.md
    │   ├── security-auditor/spec.md
    │   ├── analista_tecnico/spec.md ← 🧠 Nuevo agente (pipeline doc sin IA)
    │   ├── api-developer/spec.md
    │   ├── frontend-developer/spec.md
    │   ├── devops/spec.md
    │   ├── qa-senior/spec.md
    │   ├── gitflow/spec.md
    │   ├── solucionador/spec.md
    │   └── plataformador/
    │       ├── spec.md
    │       ├── capacidad-base.md
    │       └── memoria-proyecto.md
    │
    ├── bitacoras/            ← 📝 Bitácoras solucionador
    │
    ├── testing/              ← 🧪 Opcional — tests documentados
    ├── seguridad/            ← 🔒 Opcional — auditorías
    └── despliegue/           ← 🚀 Opcional — docs despliegue
```

> **Regla**: `Documentacion/Agents_IA_TECH/` es **propia de este proyecto**. NUNCA se copia ni sobrescribe. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) SÍ se sincroniza con `sync-agents.ps1`.

## ADRs activos
<!-- Listar ADRs en Documentacion/Agents_IA_TECH/arquitectura/adr/ -->
- `adr-0001-ecosistema-documentacion-sin-ia.md` — Ecosistema de documentación técnica sin IA de entrada (pipeline de 4 herramientas + agente `analista_tecnico` + archivo de memoria `analisis-memoria.md`). **Aceptado 2026-09-12**.

## Features activas (specs)
<!-- Listar specs en Documentacion/Agents_IA_TECH/specs/ -->
- (ninguna aún)

## Agentes del kit

| Agente | Rol | Estado |
|--------|-----|--------|
| `pensador` | Orquestador del ciclo completo: plan -> confirmar -> ejecutar -> actualizar -> preguntar. Complementa Specify (no duplica). 🔌 Puede depurar en caliente vía SSH (solo lectura) | ✅ Actualizado 2026-08-30 |
| `arquitecto` | Decisiones de arquitectura, ADRs, patrones, guardrails, spec linking | 🟢 Activo |
| `documentador` | Documentación de specs, flujos, ADRs, template system, spec versioning | 🟢 Activo |
| `security-auditor` | Revisión de seguridad en diseños | 🟢 Activo |
| `api-developer` | Implementación backend/API | 🟢 Activo |
| `frontend-developer` | Implementación frontend/UI | 🟢 Activo |
| `devops` | Infraestructura, Docker, CI/CD | 🟢 Activo |
| `qa-senior` | Tests automatizados (unit, integración, E2E), feedback loop | 🟢 Activo |
| `gitflow` | Git operations, branching, PRs, commits convencionales | 🟢 Activo |
| `solucionador` | 🔧 Diagnóstico y solución de problemas via SSH en servidores remotos | 🟢 Activo 2026-07-25 |
| `plataformador` | 🏗️ Auditoría, nivelación y replataformado de proyectos contra capacidad-base. Organiza documentación. | 🟢 Activo 2026-07-25 |
| `upgrade_framework` | 🔧 Mantenedor inteligente de dependencias externas. Gestiona proyect_ext/, clona/actualiza proyectos externos (spec-kit, graphify, etc.), y ejecuta integraciones dirigidas desde proyect_ext/ hacia Agents_IA_TECH/ usando plantillas predefinidas. Usa IA solo para analizar impacto de integración. | 🟢 Activo 2026-09-05 |
| `analista_tecnico` | 🧠 Orquesta el pipeline de documentación técnica sin IA de entrada (markitdown → graphify/codebase-memory-mcp → context-mode). Invocado por el `pensador`; retorna a él al terminar. Respeta SSD. | � Activo 2026-09-12 |

## Convenciones del proyecto

- **Pensador = Orquestador principal** que complementa Specify, no lo duplica
- **Specify maneja**: spec generation, validation, spec→plan, spec→code, template system, versioning, linking, guardrails, multi-file orchestration, feedback loop
- **Mis agentes complementan**: SSH debugging (pensador, solucionador), plataformador (auditoría/nivelación), gitflow (commits), orchestración cross-agent- **Mantenedor de dependencias**: `dependencias` - verifica y actualiza de forma segura proyectos comunitarios externos sin repetir análisis de flujos- **Persistencia obligatoria**: Toda decisión/preferencia en archivo. Sin archivo no hay memoria entre sesiones.
- **Plan aprobado → Documentar → Implementar** (siempre en ese orden)
- **Español latino neutro** en toda comunicación

## MCPs del kit

| MCP | URL | Estado | Uso |
|-----|-----|--------|-----|
| `context-mode` | https://github.com/mksglu/context-mode | 🟡 En integración (2026-09-12) | Optimiza ventana de contexto: indexación FTS5+BM25 de docs (`ctx_index`, `ctx_search`, `ctx_fetch_and_index`), ejecución sandbox (`ctx_execute`), continuidad de sesión, mantenimiento (`ctx_purge`, `ctx_stats`, `ctx_upgrade`, `ctx_doctor`). Licencia ELv2. Requiere Node >= 22.5. |
| `codebase-memory-mcp` | https://github.com/DeusData/codebase-memory-mcp | � Instalado (2026-09-12) | Grafo de conocimiento del código (`index_repository`, `query`, `semantic_search`). Paso 2 del pipeline del ecosistema. Instalado: `npm install -g codebase-memory-mcp` (v0.9.0). Registrado en `.vscode/mcp.json`. Licencia **MIT** ✅ (verificada 2026-09-12). Guía: `MCPs/codebase-memory-mcp.md` |
| `markitdown` (+ `markitdown-mcp`) | https://github.com/microsoft/markitdown | 🟢 Instalado (2026-09-12) | Convierte cualquier formato (PDF, DOCX, PPTX, XLSX, HTML, etc.) a Markdown. 100% offline, sin IA. Paso 1 del pipeline del ecosistema. Instalado: `pip install 'markitdown[all]'` (v0.1.7) + `markitdown-mcp` 0.0.1a3 (requiere `mcp<2`). Registrado en `.vscode/mcp.json`. Licencia MIT. Guía: `MCPs/markitdown.md` |

> **Regla MCP**: Los agentes validan al iniciar sesión si la documentación técnica y los MCPs asociados existen; si falta alguno, lo instalan o lo reportan de forma transparente.