# 🔧 Guía práctica: MCP `graphify`

> Guía de **instalación, configuración, uso y mantenimiento** del servidor MCP `graphify` en el kit Agents_IA_TECH.
> Esta guía NO cubre el desarrollo interno del MCP — solo su integración práctica en el kit.
> Fuente: https://github.com/Graphify-Labs/graphify | PyPI: `graphifyy` (MIT) | Versión instalada: **0.9.48**

---

## 1. Qué es y para qué sirve

`graphify` es una **herramienta CLI + servidor MCP** que construye **grafos de conocimiento** de código y arquitectura desde repositorios Git. Extrae nodos (funciones, clases, módulos, archivos) y aristas (llamadas, imports, herencia, flujo de datos) y expone 10 herramientas MCP para consultar el grafo en lenguaje natural, navegar comunidades, detectar nodos centrales (*god nodes*), analizar impacto de PRs y encontrar caminos más cortos.

**Datos clave**:

| Dato | Valor |
|------|-------|
| URL | https://github.com/Graphify-Labs/graphify |
| PyPI | `graphifyy` (paquete `graphifyy[mcp]`) |
| Licencia | **MIT** ✅ (compatible con guardrail 8 del ADR-0001) |
| Lenguaje | Python 3.10+ |
| Requisito | Python 3.10+, `uv` recomendado (o `pip`) |
| Versión instalada | **0.9.48** (pin exacto) |
| MCP server | `python -m graphify.serve <graph-path>` (stdio por defecto) |
| Herramientas MCP | **10** (verificadas en `tools/list`, 2026-09-19) |
| ¿Usa IA? | ❌ **No** — extracción AST local + análisis de grafo; la IA solo se usa en consultas `query_graph` bajo demanda |

> ✅ **Principio rector del ecosistema**: el trabajo pesado (extracción, construcción del grafo, detección de comunidades) lo hace una herramienta local **sin consumir tokens de IA**. La IA solo se usa bajo demanda en `query_graph` preguntando al usuario. Graphify es la capa de **conocimiento estructural** del ecosistema.

---

## 2. Requisitos

- **Python 3.10+** (verificar con `python --version`).
- `uv` (recomendado, aislamiento) o `pip`.
- Un cliente MCP compatible en cada harness (VS Code Copilot, OpenCode).
- `gh` CLI autenticado (`gh auth status`) para herramientas de PRs (`list_prs`, `get_pr_impact`, `triage_prs`).

---

## 3. Instalación

El paquete se instala vía **uv tool** (preferido, aislado, no contamina Python global) o **pip** alineado al mismo pin:

```bash
# Opción 1: uv tool (recomendado)
uv tool install "graphifyy[mcp]"

# Opción 2: pip (mismo pin exacto)
pip install "graphifyy[mcp]==0.9.48"
```

Verificación:

```bash
graphify --version
# → 0.9.48
```

> La instalación, registro en `opencode.json` + `.vscode/mcp.json` y verificación de handshake MCP las realiza el `devops` en la **fase de implementación** (tarea `[GRAPHIFY]` en `pendientes-implementacion.md`). Esta guía solo documenta el formato esperado.

---

## 4. MCP Server (stdio)

El servidor MCP se lanza como proceso hijo vía **stdio** (transporte por defecto). También soporta `--transport http` pero **NO usarlo en configuración persistente** por seguridad.

**Comando**:
```bash
python -m graphify.serve <graph-path>
```

> `<graph-path>` es opcional: cada herramienta acepta `project_path` si el grafo no está cargado. Se recomienda construir el grafo antes (ver sección 6).

### 4.1 `opencode.json` (harness OpenCode)

```json
{
  "mcp": {
    "graphify": {
      "type": "local",
      "command": ["python", "-m", "graphify.serve"],
      "enabled": true
    }
  }
}
```

### 4.2 `.vscode/mcp.json` (harness Copilot)

```json
{
  "servers": {
    "graphify": {
      "command": "python",
      "args": ["-m", "graphify.serve"],
      "type": "stdio"
    }
  }
}
```

> ⚠️ **`"type": "stdio"` es obligatorio** (decisión del usuario, 2026-09-12): especifica explícitamente el transporte del MCP. `stdio` es el transporte por defecto para MCPs locales que se lanzan como proceso hijo vía `command`. **Incluirlo siempre al configurar `graphify` en cualquier proyecto.**

### 4.3 Handshake y verificación

1. Reiniciar VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`) / recargar sesión OpenCode.
2. Handshake esperado:
   - `initialize` → `serverInfo: graphify 1.30.0`
   - `tools/list` → **10 herramientas** (ver sección 5)

---

## 5. 10 Herramientas (tools/list real 0.9.48)

| # | Herramienta | Parámetros clave | Qué hace |
|---|-------------|------------------|----------|
| 1 | `query_graph` | `query` (string), `project_path` (opcional) | Consultas en lenguaje natural sobre el grafo (ej: "¿qué funciones llaman a `auth.login`?") |
| 2 | `get_node` | `node_id` (string), `project_path` (opcional) | Obtener nodo completo por ID (metadatos, código, vecinos) |
| 3 | `get_neighbors` | `node_id` (string), `direction` (in/out/both), `max_depth` (int), `project_path` (opcional) | Vecinos de un nodo a N niveles (callers/callees, imports, data flow) |
| 4 | `get_community` | `community_id` (opcional), `project_path` (opcional) | Comunidad/módulo detectado (Leiden community detection). Sin ID → lista todas |
| 5 | `god_nodes` | `top_k` (int, default 10), `project_path` (opcional) | Nodos centrales (high centrality / high degree) — puntos de acoplamiento crítico |
| 6 | `graph_stats` | `project_path` (opcional) | Estadísticas del grafo: nodos, edges, densidad, comunidades, idiomas |
| 7 | `shortest_path` | `from_node` (string), `to_node` (string), `project_path` (opcional) | Camino más corto entre dos nodos (call chain, data flow) |
| 8 | `list_prs` | `repo` (string, ej: "owner/repo"), `state` (open/closed/all), `limit` (int) | Listar PRs del repo (requiere `gh auth`) |
| 9 | `get_pr_impact` | `pr_number` (int), `repo` (string), `project_path` (opcional) | Impacto de un PR en el grafo: nodos tocados, riesgo de ruptura, tests afectados |
| 10 | `triage_prs` | `repo` (string), `labels` (array), `project_path` (opcional) | Triage de PRs (solo lectura verificado: `gh pr list/view/diff`, **cero mutaciones**) |

> **Nota**: Todas las herramientas aceptan `project_path` opcional. Si no se proporciona y no hay grafo cargado, el servidor lo construye on-demand (más lento). Ver sección 6.

---

## 6. Construcción del grafo (pre-requisito para MCP)

El grafo se construye **fuera del MCP** con el CLI `graphify extract`. El MCP puede arrancar sin grafo, pero se recomienda construirlo para rendimiento.

```bash
# Sin indexar secrets (.env, *.pem, .opencode/config.json, etc.)
graphify extract <path> --code-only
# Output: graphify-out/graph.json
```

**Exclusiones de seguridad obligatorias** (añadir a `--exclude` o configurar en `.graphifyignore`):

```bash
graphify extract . --code-only \
  --exclude ".env" \
  --exclude "*.pem" \
  --exclude ".opencode/config.json" \
  --exclude ".github/workflows/*.yml" \
  --exclude "node_modules" \
  --exclude ".git"
```

> El grafo resultante (`graphify-out/graph.json`) se pasa al MCP vía `<graph-path>` en el comando de arranque, o las herramientas lo localizan automáticamente si está en la raíz del proyecto.

---

## 7. Uso por agentes

| Agente | Uso recomendado |
|--------|-----------------|
| `pensador` | Antes de cada `speckit-*`, consultar Graphify para arquitectura (`god_nodes`, `graph_stats`, `get_community`) y código (`query_graph`, `shortest_path`). Dimensiona el alcance sin escanear. |
| `arquitecto` | ADRs basados en `god_nodes` + `get_community` (módulos reales detectados por Leiden, no por carpetas). Análisis de acoplamiento real. |
| `documentador` | Flujos desde `query_graph` ("muéstrame el flujo de autenticación") + `shortest_path` (ruta entre componentes). |
| `api-developer` / `frontend-developer` | `get_node` + `get_neighbors` para contexto de implementación (qué llama a qué, tipos, contratos). |
| `qa-senior` | `get_pr_impact` + `triage_prs` para análisis de riesgo de PRs en CI. Verificar grafo actualizado tras merges. |
| `security-auditor` | `god_nodes` + `get_neighbors` para superficie de ataque; `query_graph` para patrones inseguros (eval, shell, SQL raw). |

> **Orden de consulta recomendado** (ahorro de tokens):
> 1. `graphify: graph_stats` / `god_nodes` → visión macro
> 2. `graphify: get_community` → módulos reales
> 3. `graphify: query_graph` / `shortest_path` → flujo específico
> 4. `graphify: get_node` / `get_neighbors` → detalle de implementación
> 5. Lectura directa / `codebase-memory-mcp` → solo lo identificado

---

## 8. Mantenimiento y buenas prácticas

| Práctica | Descripción |
|----------|-------------|
| **Reconstruir grafo** | Tras cambios significativos (nuevos módulos, refactors, merges grandes): `graphify extract <path> --code-only` |
| **Pin de versión** | Fijar en `dependencias-manifest.yml` (entrada `graphify`, PyPI `graphifyy`, **0.9.48**) |
| **Actualizar** | `uv tool upgrade graphifyy` + `pip install --upgrade "graphifyy[mcp]==<nueva>"` + actualizar pin en manifest |
| **Budget de tokens** | `query_graph` consume tokens de IA — acotar consultas, usar `god_nodes`/`get_community` primero (gratis, local) |
| **Registrar en memoria** | Tras analizar con Graphify, registrar en `Documentacion/<AppName>/analisis-memoria.md` qué ya fue analizado (evita re-análisis, guardrail 2 del ADR-0001) |
| **No re-analizar** | Si ya está registrado como analizado en `analisis-memoria.md`, no volver a ejecutar la consulta |
| **PRs** | `triage_prs` es solo-lectura — seguro en CI. `get_pr_impact` para gates de calidad. |

---

## 9. Seguridad de uso

> ⚠️ **La revisión formal la realiza el `security-auditor` en la fase documental (paso 2º de la tarea `[GRAPHIFY]`). Lo siguiente es el resumen de la investigación previa, pendiente de validación.**

- **SOLO stdio** (nunca `--transport http` en config persistente) — evita exposición de red.
- **No indexar carpetas con secrets**: `.env`, `*.pem`, `.opencode/config.json`, `.github/workflows/*.yml` → usar `--code-only` + exclusiones (ver sección 6).
- **`triage_prs` verificado solo-lectura**: usa `gh pr list/view/diff` (token `gh auth` en ambiente, **nada en args/configs**). Cero mutaciones.
- **Supply chain**: `graphifyy` oficialidad repo↔PyPI verificada (`project_urls` → Graphify-Labs/graphify, MIT).
- **Entrada no confiable**: el código grafiado puede contener patrones maliciosos — aplicar prompt defense (regla del kit) en `query_graph`.
- **Cache local**: `graphify-out/` contiene estructura del código — no commitear en repos públicos sin revisión.

---

## 10. Troubleshooting

| Problema | Solución |
|----------|----------|
| `graphify --version` no responde / command not found | Verificar `uv tool list` / `pip list \| findstr graphifyy`. Reinstalar con pin exacto. |
| MCP no aparece en `.vscode/mcp.json` | Reiniciar VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`). Verificar JSON válido. |
| Handshake falla / timeout | Verificar `python -m graphify.serve --help` → EXIT 0. Revisar Python version (3.10+). |
| `tools/list` devuelve 0 herramientas | El servidor no arrancó correctamente. Ver logs del MCP en Output panel (VS Code) / stdout (OpenCode). |
| `query_graph` lento / timeout | Construir grafo antes con `graphify extract` y pasarlo al MCP. Aumentar timeout en cliente MCP. |
| `list_prs` / `get_pr_impact` fallan | Verificar `gh auth status` → token válido con scopes `repo`, `read:org`. |
| Grafo desactualizado tras merge | Reconstruir: `graphify extract <path> --code-only`. Automatizar en CI post-merge. |

---

## 11. Validación de instalación y configuración

> **Script de validación**: `scripts/validar-mcps.ps1` (decisión del usuario, 2026-09-12).

Verifica que este MCP esté **instalado (pin 0.9.48), registrado en `opencode.json` + `.vscode/mcp.json` con `"type": "stdio"` en este último, y ejecutándose** correctamente (handshake + `tools/list` = 10). **Ejecutarlo siempre después de instalar o configurar los MCPs** en un proyecto.

```powershell
# Validación completa (instalación + configuración + runtime)
.\scripts\validar-mcps.ps1

# Validar solo este MCP (cuando el script lo soporte)
.\scripts\validar-mcps.ps1 -MCP graphify
```

> **Nota**: el script valida MCPs instalados vía gestor global (`--version` en PATH). `graphify` se instala vía `uv tool` / `pip`, por lo que el `devops` adapta o extiende la validación (comprobar `graphify --version` + handshake MCP) en la fase de implementación.

Detalle completo del script (qué valida, exit codes, notas técnicas): ver sección **9. Validación** en `Documentacion/Agents_IA_TECH/MCPs/context-mode.md`.

---

## Referencias

- Repositorio: https://github.com/Graphify-Labs/graphify
- PyPI: https://pypi.org/project/graphifyy/
- Registro en el kit: `Documentacion/Agents_IA_TECH/referencias.md` + `dependencias-manifest.yml` (entrada `graphify`)
- Plan del ecosistema: `Documentacion/Agents_IA_TECH/README-ECOSISTEMA-DOCUMENTACION.md`
- ADR: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md`
- Tarea: `[GRAPHIFY]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`
- Seguridad detallada: `Documentacion/Agents_IA_TECH/seguridad/graphify.md` (pendiente de creación por `security-auditor`)
---

## 12. Estrategia por app (ADR-0004)

> **Decisión 2026-09-20**: 1 grafo por app como primario + vista workspace on-demand. Estructura-first (sin IA por defecto).

### 12.1 Scope del grafo

| Scope | Ruta | Cuándo |
|-------|------|--------|
| **Por app (primario)** | src/<App>/graphify-out/graph.json | Pipeline diario speckit per-app |
| **Workspace unificado** | graphify-out/merged-graph.json | On-demand vía merge-graphs (análisis cross-app) |
| **Proyecto kit** | raíz del repo | El kit es el código (Agents_IA_TECH) |

### 12.2 Flujo estructura-first (detección de estado)

1. **Sin grafo** → graphify extract <scope> --code-only (estructura, sin IA, sin secrets)
2. **Grafo existe + código cambiado** → graphify update <scope> (incremental, sin LLM)
3. **Flag -GraphifyDeep** → graphify extract --mode deep (semántica con LLM, solo si hay backend configurado; si no, WARN y continúa)

### 12.3 Reglas

- graphify-out/ está en .gitignore — **nunca** se sube a repositorios (mitiga subir .env/claves/datos no requeridos). Costo aceptado: la extracción inicial gasta más tiempo/tokens.
- merge-graphs es **on-demand** (no persistente) — se construye solo cuando se necesita.
- Communities por-app son significativas; sin ruido del kit (.github/, .opencode/ no son código de app).
- Los 10 tools del MCP aceptan project_path (soporte nativo multi-grafo).
- Re-indexación con **aviso visible** "Re-indexando..." (RF-010) para que el usuario sepa que corre.
