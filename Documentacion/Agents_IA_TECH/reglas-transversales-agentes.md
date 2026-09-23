# 🧭 Reglas Transversales de los Agentes

> **Gobernanza del kit** — Agents_IA_TECH
> **Última actualización**: 2026-09-12
> **Propósito**: Estas reglas se cumplen **SIEMPRE** al crear o modificar agentes, para que todos funcionen como se espera. Son la fuente de verdad sobre cómo debe comportarse cualquier agente del kit.

---

## 🎯 Principio rector

> **Todo agente del kit debe funcionar igual, indistintamente del arnés** (GitHub Copilot en `.github/agents/` u OpenCode en `.opencode/agents/`). Las reglas transversales se aplican a **ambos arneses** en paralelo.

---

## 🔌 Regla 1: Consultar los MCPs (obligatorio — ahorrar tokens)

> **Regla del usuario (2026-09-12)**: Leer archivos directos gasta más tokens. Los MCPs deben usarse como **herramienta primaria** de consulta cuando estén disponibles.

**Todo agente** debe consultar los MCPs como herramienta primaria antes de leer archivos directos:

| MCP | Herramientas | Para qué |
|-----|--------------|----------|
| **`context-mode`** | `ctx_search`, `ctx_index`, `ctx_fetch_and_index` | Búsqueda FTS5+BM25 sobre documentación indexada |
| **`codebase-memory-mcp`** | `index_repository`, `search_graph`, `query` | Grafo de conocimiento del código |
| **`markitdown`** | `convert_to_markdown` | Conversión de formatos a Markdown |

**Regla**: leer archivos directos gasta más tokens. Usar los MCPs primero; si no están disponibles, leer directo como fallback.

### Cómo se aplica

Cada agente (`.github/agents/<nombre>.agent.md` y `.opencode/agents/<nombre>.md`) debe incluir la sección estándar:

```markdown
## 🔌 Uso de MCPs (obligatorio — ahorrar tokens)
Consulta SIEMPRE los MCPs como herramienta primaria antes de leer archivos directos:
- `context-mode` → `ctx_search` (búsqueda FTS5+BM25 sobre documentación indexada), `ctx_index`, `ctx_fetch_and_index`
- `codebase-memory-mcp` → `index_repository`, `search_graph`, `query` (grafo de conocimiento del código)
- `markitdown` → `convert_to_markdown` (conversión de formatos a Markdown)
Regla: leer archivos directos gasta más tokens. Usar los MCPs primero; si no están disponibles, leer directo como fallback.
```

---

## 🧩 Regla 2: Estructura estándar de un agente

Todo agente debe seguir esta estructura mínima (en ambos arneses):

1. **Frontmatter** — `description` (cuándo usarlo), `tools`, `user-invocable` (Copilot) / `mode`, `temperature`, `permission` (OpenCode)
2. **Introducción** — quién es el agente y su misión
3. **Skills que utilizas** — skills relevantes a su rol
4. **Enfoque** — pasos de trabajo
5. **🔌 Uso de MCPs** — sección estándar (Regla 1)
6. **🌐 Idioma** — consultar `Documentacion/<proyecto>/idioma.md`
7. **Constraints** — qué NO hacer

---

## 🔄 Regla 3: Sincronización entre arneses

> **Regla del AGENTS.md**: el mismo agente existe en dos lugares — `.github/agents/<nombre>.agent.md` (Copilot) y `.opencode/agents/<nombre>.md` (OpenCode). **Ambos deben actualizarse en paralelo** cuando se modifica un agente.

- Al **crear** un agente → crear en ambos arneses.
- Al **modificar** un agente → modificar en ambos arneses.
- Al **eliminar** un agente → eliminar en ambos arneses.
- Las **skills** viven solo en `.github/skills/` (no hay espejo en OpenCode).

---

## 🏗️ Regla 4: Orquestación y delegación

- **Cada agente hace UNA cosa** y nada más.
- **El Documentador solo escribe documentos, nunca código** — si el usuario pide "cambiar algo", se interpreta como cambio en `Documentacion/`.
- **El implementador** solo escribe código, nunca documentación de especificaciones.
- **`Agent-SSD` (ADR-0005)**: orquestador del flujo SSD + ejecutor de comandos Speckit. El `pensador` delega en él las fases documentales del pipeline (specify, plan, tasks, analyze, converge, constitution). Puede escribir en `src/<App>/.specify/` (SOLO esa subcarpeta) + `Documentacion/<AppName>/specs/` + kit transversal. NUNCA implementa código ni auto-continúa el pipeline — reporta al `pensador` y el `pensador` valida/continúa con el usuario.
- **No mezcles responsabilidades** — si hace falta otro agente, invocalo explícitamente.
- **Autodelegación**: cuando un agente termine su tarea, debe decir "Listo. El siguiente paso debería hacerlo [nombre del agente]."
- **Los agentes orquestadores** (pensador, plataformador) deben hacer cumplir estas reglas a todos los agentes debajo de ellos.

---

## 📋 Regla 5: Persistencia del comportamiento

> **Regla obligatoria del kit**: TODO lo que el usuario decida que es transversal y sirve para futuras decisiones debe quedar en un archivo.

| Qué guardar | Dónde |
|-------------|-------|
| Preferencias de usuario | `Documentacion/<AppName>/preferencias.md` |
| Decisiones de diseño | ADR en `Documentacion/<AppName>/arquitectura/adr/` |
| Problemas resueltos en servidores | `Documentacion/<AppName>/soluciones-conocidas.md` |
| Ideas para el futuro | `Documentacion/<AppName>/roadmap.md` |
| **Reglas transversales de agentes** | **`Documentacion/<AppName>/reglas-transversales-agentes.md`** (este archivo) |

---

## ✅ Checklist al crear o modificar un agente

Antes de dar por terminado un agente nuevo o modificado, verificar:

- [ ] Existe en **ambos arneses** (`.github/agents/` y `.opencode/agents/`)
- [ ] Incluye la sección **"🔌 Uso de MCPs"** estándar (Regla 1)
- [ ] Sigue la **estructura estándar** (Regla 2)
- [ ] Respeta la **sincronización** entre arneses (Regla 3)
- [ ] Respeta la **orquestación y delegación** (Regla 4)
- [ ] Las decisiones transversales quedaron **persistidas** (Regla 5)
- [ ] Se actualizó `Documentacion/<AppName>/00-indice.md` si aplica
- [ ] Se actualizó `scripts/validar-mcps.ps1` si se agregó/quitaron MCPs
