# 📖 Referencias y Atribuciones - Agents_IA_TECH

> Registro de proyectos, herramientas y fuentes externas utilizadas como base o inspiración.
> Mantenido para cumplir con derechos de autor y licencias.

## Proyectos de referencia

| Proyecto | URL | Licencia | Uso en Agents_IA_TECH |
|----------|-----|----------|----------------------|
| **Ponytail** | https://github.com/affaan-m/Ponytail | MIT | Principios de eficiencia: YAGNI, reutilización, mínimo código funcional |
| **spec-kit** | https://github.com/github/spec-kit | MIT | Capacidades de spec-driven development: spec generation, validation, spec→plan, spec→code, template system, versioning, linking, guardrails, multi-file orchestration, feedback loop |
| **graphify** | https://github.com/tomasgraph/graphify | (verificar) | Knowledge graph: convierte código/docs/imágenes en grafo de conocimiento persistente con god nodes, community detection y herramientas de query/path/explain |
| **context-mode** | https://github.com/mksglu/context-mode | Elastic License 2.0 (ELv2) | MCP que optimiza la ventana de contexto: indexación FTS5+BM25 de docs (`ctx_index`, `ctx_search`, `ctx_fetch_and_index`), ejecución sandbox (`ctx_execute`), agrupación de comandos (`ctx_batch_execute`), mantenimiento (`ctx_purge`, `ctx_stats`, `ctx_upgrade`, `ctx_doctor`). Guía: `Documentacion/Agents_IA_TECH/MCPs/context-mode.md` |
| **markitdown** (+ `markitdown-mcp`) | https://github.com/microsoft/markitdown | MIT | Herramienta de Microsoft que convierte cualquier formato (PDF, DOCX, PPTX, XLSX, HTML, CSV, JSON, XML, EPub, ZIP) a Markdown. 100% offline, sin IA. Paso 1 del pipeline del ecosistema de documentación sin IA. CLI: `markitdown file.pdf -o file.md`; MCP: `convert_to_markdown(uri)`. Guía: `Documentacion/Agents_IA_TECH/MCPs/markitdown.md` |
| **codebase-memory-mcp** | https://github.com/DeusData/codebase-memory-mcp | **MIT** ✅ (verificada 2026-09-12) | Servidor MCP que construye un grafo de conocimiento del código (bisturí quirúrgico). Herramientas: `index_repository`, `query`, `semantic_search`. Paso 2 del pipeline del ecosistema de documentación sin IA. Instalación: `npm install -g codebase-memory-mcp`. Guía: `Documentacion/Agents_IA_TECH/MCPs/codebase-memory-mcp.md`. **Licencia verificada por el `security-auditor`** (guardrail 8 del ADR-0001): MIT vía `npm view codebase-memory-mcp license`. |

## Capacidades de Specify vs Mis Agentes (Análisis de complementariedad)

| Capacidad | Specify (speckit) | Mis Agentes | Estado |
|-----------|-------------------|-------------|--------|
| **Spec generation** | ✅ `speckit-specify` | Pensador (orquesta) | **Complementa** — Pensador decide cuándo usar speckit-specify |
| **Spec validation** | ✅ `speckit-analyze` | Pensador (orquesta) | **Complementa** — Pensador valida coherencia cross-artifact |
| **Spec → Plan** | ✅ `speckit-plan` | Documentador (usa templates) | **Complementa** — Documentador usa speckit-plan |
| **Spec → Tasks** | ✅ `speckit-tasks` | Pensador → Documentador | **Complementa** — Pensador orquesta, Documentador ejecuta |
| **Spec → Code** | ✅ `speckit-implement` | Implementadores (api, frontend, devops) | **Complementa** — Implementadores ejecutan speckit-implement |
| **Template system** | ✅ `speckit-checklist` | Documentador | **Complementa** — Documentador usa plantillas |
| **Spec versioning** | ✅ `speckit-converge` | Documentador | **Complementa** — Documentador mantiene versiones |
| **Spec linking** | ✅ (implícito) | Arquitecto | **Complementa** — Arquitecto define trazabilidad |
| **Guardrails** | ✅ (implícito) | Arquitecto | **Complementa** — Arquitecto define restricciones |
| **Multi-file orchestration** | ✅ `speckit-implement` | Implementadores | **Complementa** — Implementadores coordinan |
| **Feedback loop** | ✅ `speckit-implement` | QA-senior + Implementadores | **Complementa** — QA valida contra spec |
| **SSH Debugging (hot)** | ❌ No | Pensador (lectura), Solucionador (escritura) | **ÚNICO EN MIS AGENTES** |
| **Plataformador (auditoría/nivelación)** | ❌ No | Plataformador | **ÚNICO EN MIS AGENTES** |
| **Gitflow (commits convencionales)** | ❌ No | Gitflow | **ÚNICO EN MIS AGENTES** |
| **Cross-agent orchestration** | ❌ No | Pensador | **ÚNICO EN MIS AGENTES** |
| **Persistencia sesiones (disk)** | ❌ No | Pensador + Documentador | **ÚNICO EN MIS AGENTES** |
| **Agentes documentales (4)** | ❌ No | Pensador, Arquitecto, Documentador, Security | **ÚNICO EN MIS AGENTES** |
| **Agentes implementadores (4)** | ❌ No | API, Frontend, DevOps, QA | **ÚNICO EN MIS AGENTES** |

## Conclusión del análisis

**Specify NO se duplica**. Mis agentes **complementan** Specify en:

1. **Orquestación completa** (Pensador) — ciclo plan→confirmar→ejecutar→actualizar→preguntar
2. **Depuración en caliente SSH** (Pensador lectura, Solucionador escritura)
3. **Auditoría/nivelación de proyectos** (Plataformador)
4. **Git operations automatizadas** (Gitflow)
5. **Estructura documental por app** (Documentación aislada por proyecto)
6. **Persistencia entre sesiones** (Archivos en disco, no memoria volátil)

**Flujo integrado**: Pensador decide → Specify ejecuta (spec/plan/tasks) → Mis agentes complementan (SSH, plataformador, gitflow, orchestración) → Documentador persiste → Implementadores ejecutan → QA valida → Gitflow commitea.

---

## Regla

**Siempre que se use código, patrones o conceptos de un proyecto externo, debe registrarse aquí con su licencia correspondiente.**