# Mantenimiento de índices MCP y Graphify — Agents_IA_TECH

> **Propósito**: comandos exactos para actualizar los índices de los MCPs (`context-mode`, `codebase-memory-mcp`) y el grafo (`graphify`) **en este proyecto** (el kit maestro).
>
> **Regla**: este repo ES el kit maestro. **NO ejecutar `plataformador-bootstrap.ps1` sin `-DryRun`/`-VerifyOnly`** (el script clona el remoto y sobrescribe `.github/`, `.opencode/`, `.doc_agents/`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`). Para mantener los índices, usar los comandos de este documento.

---

## 1. Estado actual (referencia)

| Índice | Herramienta | Estado | Ubicación |
|--------|-------------|--------|-----------|
| Código | `codebase-memory-mcp` | `indexed` (16889 nodos, 73310 edges) | `~\.cache\codebase-memory-mcp\*.db` |
| Documentación | `context-mode` | `indexed` (90 archivos, 754 secciones) | `%APPDATA%\opencode\context-mode\content\*.db` |
| Grafo | `graphify` | `extracted` (13405 nodos, 29413 edges, 433 communities) | `graphify-out/graph.json` (gitignored) |

> Estado verificado el **2026-09-21** tras ejecutar la secuencia completa de la sección 5.

---

## 2. Actualizar índice de CÓDIGO (codebase-memory-mcp)

Indexa el repo completo en el grafo de conocimiento del código.

```powershell
# Indexar / re-indexar el proyecto — USAR --mode fast (ver nota crítica abajo)
codebase-memory-mcp cli index_repository --repo-path "C:/Proyectos/Agents_IA_TECH" --mode fast

# Verificar estado
codebase-memory-mcp cli index_status --project "C-Proyectos-Agents_IA_TECH"

# Listar proyectos indexados
codebase-memory-mcp cli list_projects
```

> ⚠️ **NOTA CRÍTICA — usar `--mode fast`**: el modo por defecto (`full`) **crashea** el worker de indexación (`exit_nonzero`, log vacío) por los archivos Python gigantes de `proyect_ext/spec-kit/` (hasta 701 KB: `tests/test_workflows.py`, `tests/test_presets.py`, `tests/test_extensions.py`). El modo `fast` filtra esos directorios automáticamente y completa la indexación.
>
> Directorios que `--mode fast` excluye solo (21): `.git`, `.vscode`, `graphify-out`, `scripts`, `proyect_ext/tokenslayer`, `proyect_ext/spec-kit/{.git,.specify,docs,examples,media,scripts}`, `proyect_ext/spec-kit/tests/integration`, `.specify/scripts`, `.opencode/{bin,lib,node_modules}`, `.github/context-mode`.
>
> **Flag correcto**: `--repo-path` (NO `--root_path` — ese es el nombre del argumento JSON interno y falla en CLI).

**Cuándo ejecutar**: tras cambios en código/config que alteren la estructura (nuevos agentes, skills, scripts).

**Nota**: el nombre del proyecto es `C-Proyectos-Agents_IA_TECH` (derivado de la ruta). Si cambia la ruta, cambia el nombre.

---

## 3. Actualizar índice de DOCUMENTACIÓN (context-mode)

Indexa `Documentacion/` en la base FTS5 para búsquedas BM25.

```powershell
# Indexar la documentación del proyecto
context-mode index "C:\Proyectos\Agents_IA_TECH\Documentacion" --project "C:\Proyectos\Agents_IA_TECH"

# Verificar (búsqueda de prueba)
context-mode search "post-plataformado" --project "C:\Proyectos\Agents_IA_TECH" --limit 3

# Diagnóstico
context-mode doctor
```

**Opciones útiles**:
- `--source <label>` — etiqueta de la fuente (default: `project:<dir>`)
- `--max-depth <n>` — profundidad de recursión (default: 5)
- `--max-files <n>` — tope de archivos (default: 200)
- `--ext <.md,.txt>` — allowlist de extensiones
- `--exclude <glob>` — excluir patrones (repetible)

**Cuándo ejecutar**: tras escribir/actualizar documentación (specs, ADRs, índices, memoria).

---

## 4. Actualizar GRAFO (graphify)

Grafo de conocimiento del proyecto (god nodes, communities). **Estructura-first** (ADR-0004): sin IA por defecto.

```powershell
# 1) Sin grafo previo -> extracción estructural (sin IA, sin secrets)
graphify extract "C:\Proyectos\Agents_IA_TECH" --code-only

# 2) Grafo existente -> actualización incremental (sin LLM)
graphify update "C:\Proyectos\Agents_IA_TECH"

# 3) Semántica con LLM (solo bajo demanda, requiere backend configurado)
graphify extract "C:\Proyectos\Agents_IA_TECH" --mode deep
```

**Consultas**:
```powershell
graphify query "como funciona el pipeline speckit" --graph "C:\Proyectos\Agents_IA_TECH\graphify-out\graph.json"
graphify god-nodes --top 10 --graph "C:\Proyectos\Agents_IA_TECH\graphify-out\graph.json"
graphify explain "pensador" --graph "C:\Proyectos\Agents_IA_TECH\graphify-out\graph.json"
```

**Cuándo ejecutar**: tras cambios estructurales grandes (nuevos agentes/skills, reorganización).

**Importante**: `graphify-out/` está en `.gitignore` (RF-011) — nunca se versiona.

---

## 5. Secuencia completa de mantenimiento

```powershell
# Desde C:\Proyectos\Agents_IA_TECH

# 1. Código (--mode fast: evita el crash del worker con proyect_ext/spec-kit)
codebase-memory-mcp cli index_repository --repo-path "C:/Proyectos/Agents_IA_TECH" --mode fast

# 2. Documentación
context-mode index "C:\Proyectos\Agents_IA_TECH\Documentacion" --project "C:\Proyectos\Agents_IA_TECH"

# 3. Grafo (primera vez: extract; siguientes: update)
graphify extract "C:\Proyectos\Agents_IA_TECH" --code-only
# o, si graphify-out/graph.json ya existe:
graphify update "C:\Proyectos\Agents_IA_TECH"

# 4. Verificación
codebase-memory-mcp cli index_status --project "C-Proyectos-Agents_IA_TECH"
context-mode search "speckit" --project "C:\Proyectos\Agents_IA_TECH" --limit 3
graphify god-nodes --top 5 --graph "C:\Proyectos\Agents_IA_TECH\graphify-out\graph.json"
```

---

## 6. Diagnóstico (sin modificar nada)

```powershell
# Solo verificar MCPs e índices (NO toca archivos)
.\scripts\plataformador-bootstrap.ps1 -VerifyOnly

# Ver qué haría el bootstrap sin ejecutar (NO toca archivos)
.\scripts\plataformador-bootstrap.ps1 -DryRun
```

---

## 6b. Troubleshooting

### codebase-memory: worker crashea (`exit_nonzero`, log vacío)

**Síntoma**:
```
{"status":"error","outcome":"exit_nonzero","hint":"Indexing worker crashed on a file..."}
```
El log del worker (`~\.cache\codebase-memory-mcp\logs\.worker-*.log`) está **vacío**.

**Causa**: archivos Python gigantes en `proyect_ext/spec-kit/` (hasta 701 KB). El modo `full` (default) los procesa y el worker crashea.

**Solución**: usar `--mode fast`:
```powershell
codebase-memory-mcp cli index_repository --repo-path "C:/Proyectos/Agents_IA_TECH" --mode fast
```

**Modos disponibles**:
| Modo | Qué hace |
|------|----------|
| `full` (default) | Todos los archivos + similarity/semantic edges → **crashea acá** |
| `moderate` | Archivos filtrados + similarity/semantic |
| `fast` | Archivos filtrados, sin similarity/semantic → **recomendado acá** |

### graphify: `extract` vs `update`

- **Sin `graphify-out/graph.json`** → `graphify extract <path> --code-only` (primera vez).
- **Con `graphify-out/graph.json`** → `graphify update <path>` (incremental, más rápido).
- Si un refactor borró código y el grafo quedó con menos nodos → `graphify update <path> --force`.

### context-mode: la búsqueda no encuentra nada

Verificar que la indexación se ejecutó con el `--project` correcto (debe coincidir con el cwd o la ruta absoluta del proyecto):
```powershell
context-mode index "C:\Proyectos\Agents_IA_TECH\Documentacion" --project "C:\Proyectos\Agents_IA_TECH"
context-mode search "speckit" --project "C:\Proyectos\Agents_IA_TECH" --limit 3
```

---

## 7. Qué NO hacer en este repo

| Acción | Por qué |
|--------|---------|
| `.\scripts\plataformador-bootstrap.ps1` (sin flags) | Clona el remoto y **sobrescribe** `.github/`, `.opencode/`, `.doc_agents/`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`. Si hay cambios locales sin commitear, se pierden. |
| `-SyncOnly` sin `-DryRun` | Igual que arriba (solo la fase de sync). |
| `-OrphanAction Borrar` | Puede borrar archivos locales no pusheados en `.github/`/`.opencode/`/`.doc_agents/`. |

**Protegido siempre** (aunque se ejecute el bootstrap):
- `Documentacion/<AppName>/` — frontera kit ↔ app, nunca se toca.
- `.opencode/config.json` — credenciales, nunca se copia ni se toca.
- `.opencode/.gitignore` — hash-guard: si difiere del maestro, conserva el local.

---

## 8. Referencias

- ADR-0004: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md`
- Spec 006: `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md`
- Estrategia Graphify por app: `Documentacion/Agents_IA_TECH/MCPs/graphify.md` (sección 12)
- Threat model: `Documentacion/Agents_IA_TECH/seguridad/post-plataformado.md`

---

**Última actualización**: 2026-09-21
