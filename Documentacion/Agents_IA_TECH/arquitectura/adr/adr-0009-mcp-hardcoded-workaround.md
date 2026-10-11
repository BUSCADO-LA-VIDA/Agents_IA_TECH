# ADR-0009: Rutas MCP hardcodeadas en `opencode.json` (workaround bug OpenCode #5299)

> **Estado**: Aceptado (workaround temporal — revisar cuando OpenCode corrija #5299)
> **Fecha**: 2026-10-11
> **Decisión**: Adoptar la **Opción A** para el archivo `opencode.json` de este proyecto: los comandos MCP se escriben con **rutas absolutas hardcodeadas** (forward slashes) en lugar de tokens `{env:...}`. `.env.mcp` se conserva como **fuente de verdad documental** y entrada del bootstrap, pero deja de ser un mecanismo del que OpenCode dependa.
> **Autor**: `arquitecto` (Fase Analyze — decisiónTaken durante verificación en vivo)
> **Sustituye parcialmente a**: `ADR-0006` §D1/D2 (mecanismo de interpolación en `mcp.command`)

---

## Contexto y problema

Tras actualizar OpenCode a la versión 1.18.35, los MCP de este proyecto dejaron de levantarse. La causa turned out ser **doble e independiente**, y ambas hacen que la interpolación `{env:...}` en `mcp.command` sea inviable aquí.

### Problema 1 — `.env.mcp` nunca fue leído por OpenCode

El bootstrap (ADR-0006, D2) creó `<root>/.env.mcp` como fuente de verdad portable de rutas. El propio ADR ya lo anticipaba en su fallback (línea 47 y nota del diagrama, línea 179):

> *"OpenCode **no** carga `.env.mcp` automáticamente; el mecanismo efectivo es el campo `environment` del MCP local o la ruta real en `command`."*

En la práctica, `opencode.json` seguía teniendo `command: ["{env:CONTEXT_MODE_CMD}"]` esperando que OpenCode leyera `.env.mcp` — que nunca ocurre. El archivo era decorativo desde la perspectiva del runtime de OpenCode.

### Problema 2 — Bug OpenCode #5299 (interpolación inconsistente en `mcp.command`)

Issue abierto en `anomalyco/opencode` (#5299): la sustitución `{env:...}` falla de forma inconsistente para la入口 `command` de los MCP, incluso cuando la variable está correctamente exportada. Algunos servidores funcionan con el patrón exacto mientras otros, con la misma forma, fallan.

Evidencia en este proyecto — el mismo archivo `opencode.json` usa `{env:...}` en dos sitios con resultados distintos:

| Sección | Configuración | Resultado |
|---------|---------------|-----------|
| `provider.apiKey` | `{env:NVIDIA_API_KEY}` / `{env:DEEPINFRA_API_KEY}` | ✅ Funciona (resuelto desde el entorno del proceso) |
| `mcp.command` | `{env:CONTEXT_MODE_CMD}` y análogos | ❌ No levanta (bug #5299) |

### Problema 3 — MCP extendidos con rutas inexistentes

Al verificar `.env.mcp` contra el disco, se constató que ocho rutas (`TESTSPRITE_MCP_CMD`, `SENTRY_MCP_CMD`, `SEMGREP_MCP_CMD`, `PLAYWRIGHT_MCP_CMD`, `PIECES_MCP_CMD`, `PERPLEXITY_MCP_CMD`, `CONTEXT7_CMD`, `GITHUB_MCP_CMD`) apuntaban a ejecutables que **no existen** en la máquina. Esos MCP nunca estuvieron instalados; hardcodear rutas falsas solo habría convertido un error visible en uno silencioso.

---

## Decisión

Adoptar la **Opción A** para `opencode.json`: escribir los `command` de cada MCP con la **ruta absoluta real**, verificada contra el sistema de archivos, usando **forward slashes** (evita `InvalidEscapeCharacter` en JSON).

### MCP incluidos (los que existen en esta máquina)

| MCP | `command` hardcodeado | Verificación |
|-----|----------------------|--------------|
| `context-mode` | `C:/Users/tomas/AppData/Roaming/npm/context-mode.ps1` | ✅ archivo existe |
| `codebase-memory-mcp` | `C:/Users/tomas/.local/bin/codebase-memory-mcp.exe` | ✅ archivo existe |
| `markitdown` | `C:/Python314/Scripts/markitdown.exe` | ✅ archivo existe |
| `graphify` | `C:/Python314/python.exe -m graphify.serve C:/Proyectos/Agents_IA_TECH/graphify-out/graph.json` | ✅ `python`, módulo `graphify`, `graph.json` existen |
| `tokenslayer` | `node proyect_ext/tokenslayer/mcp-server/build/index.js` | ✅ `build/index.js` existe |

`graphify` usa un comando compuesto (intérprete + módulo + ruta del grafo) replicando el patrón del proyecto consumidor que sí funciona. `tokenslayer` se mantiene con ruta **relativa al proyecto** porque el entry point se referencia bajo `proyect_ext/` y no expone usuario.

### MCP excluidos

`testsprite`, `sentry`, `semgrep`, `playwright`, `pieces`, `perplexity`, `context7`, `github` quedan **fuera de `opencode.json`** hasta que se instalen en la máquina. No se registran entradas rotas (coherente con ADR-0006, guardrail 3 y D6).

### Papel restante de `.env.mcp`

`.env.mcp` se mantiene (reescrito con solo las rutas reales verificadas) por dos razones:

1. **Documentación legible**: cualquier agente o persona lee las rutas sin interpretar JSON.
2. **Entrada del bootstrap**: `plataformador-bootstrap.ps1` lo lee para reescribir rutas en otros proyectos (Opción C del flujo).

Pero deja de ser un mecanismo del que OpenCode dependa: **no se espera que OpenCode lo lea**, y el campo `_note` de `opencode.json` lo declara explícitamente.

---

## Alternativas consideradas

| Opción | Descripción | Veredicto |
|--------|-------------|:---------:|
| **A — Hardcodeado (ELEGIDA)** | Escribir las rutas reales verificadas en `mcp.command`. | ✅ **Adoptada**: los 5 MCP levantan y responden en vivo; sin dependencia del comportamiento no documentado de OpenCode; simple y determinista. |
| **B — Plugin que inyecta `.env`** | Añadir `@techdivision/opencode-plugin-shell-env` para que OpenCode lea un `.env` estándar. | ❌ **Rechazada por ahora**: agrega dependencia externa y **no está probado** que resuelva el bug #5299 en `mcp.command`. Reevaluar si el plugin se integra upstream. |
| **C — Solo tokens / `{env:...}`** | Mantener la plantilla con tokens y confiar en el entorno. | ❌ **Rechazada**: es exactamente la Opción A/B del ADR-0006 que hoy falla por #5299. El comportamiento de OpenCode no es una garantía en la que apoyarse. |
| **D — Excluir `opencode.json` del sync** | No propagar nunca la plantilla entre proyectos. | ⚠️ Descartada: rompe la propagación del kit base; el hardcodeo local ya resuelve el caso de uso inmediato. |

Criterio de elección: **funcionamiento verificable** (los 5 MCP responden en vivo), **determinismo** (no depender de un bug abierto), **realidad de los datos** (solo rutas verificadas en disco) y **simplicidad** (sin dependencias nuevas).

---

## Consecuencias

### Positivas

- **Los 5 MCP levantan y responden** — verificado en vivo en esta sesión (context-mode doctor OK; codebase-memory lista el proyecto indexado; graphify devuelve 4.793 nodos; tokenslayer reporta 24k tokens ahorrados).
- **Determinista**: no depende del comportamiento de interpolación de OpenCode ni de cargar `.env.mcp`.
- **Realista**: se eliminó la falsa expectativa de 8 MCP extendidos que nunca estuvieron instalados.
- **Portable vía bootstrap**: el flujo Opción C (`plataformador-bootstrap.ps1`) sigue siendo el mecanismo para otros proyectos, escribiendo rutas reales por proyecto.

### Negativas / Trade-offs

- **`opencode.json` deja de ser portable**: contiene rutas absolutas con el usuario `tomas`. Si este archivo se comparte o sube a un repo público, filtra la estructura de directorios local. Mitigado: el campo `_note` lo advierte; el archivo sigue gitignored en los flujos de despliegue.
- **Divergencia con la plantilla del kit**: el `opencode.json` del maestro difiere del distribuible (que mantiene `{env:...}`). Esto es intencional (el maestro tiene rutas reales; el distribuible las resuelve en runtime), pero conviene tenerlo presente al sincronizar.
- **Dependencia del bug #5299**: si OpenCode lo corrige, este workaround queda redundante. Debe revisarse cuando el issue cierre (ver "Cuándo reevaluar").
- **`tokenslayer` con ruta relativa**: depende de que el proceso se lance desde la raíz del proyecto. Es coherente con el entry point bajo `proyect_ext/` pero es una fragilidad latente si cambia el cwd.

---

## Guardrails

1. **Nunca hardcodear rutas que no existan en disco.** Antes de escribir un `command`, verificar `Test-Path` / existencia del entry point. Una ruta hardcodeada a un binario inexistente es peor que un token sin resolver (falla en silencio).
2. **Usar forward slashes** en las rutas JSON para evitar `InvalidEscapeCharacter`.
3. **No reintroducir `{env:...}` en `mcp.command`** mientras el bug #5299 esté abierto, salvo que se verifique en vivo que la interpolación funciona.
4. **MCP extendidos solo con instalación real**: no registrar entradas por "debería existir"; verificar primero.
5. **`.env.mcp` no es leído por OpenCode**: no escribir código que asuma lo contrario; su rol es documental + entrada del bootstrap.
6. **Verificación en vivo antes de declarar funcional**: un MCP se considera operativo solo si su tool responde, no solo si `enabled: true` figura en el JSON.

---

## Cuándo reevaluar (condiciones de salida del workaround)

Reevaluar este ADR cuando se cumpla **cualquiera** de estas:

1. OpenCode cierre el issue **#5299** con una versión que interpole `{env:...}` de forma consistente en `mcp.command` → volver a la Opción C del ADR-0006 (tokens + resolución runtime).
2. El plugin `@techdivision/opencode-plugin-shell-env` se integre upstream o se demuestre que resuelve #5299 → evaluar Opción B.
3. Se instale cualquiera de los 8 MCP extendidos → agregar su entrada con ruta verificada.

---

## Spec linking (trazabilidad)

| Artefacto | Relación con este ADR |
|-----------|----------------------|
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0006-mcp-token-resolution.md` | Decisión previa (Opción C, tokens/`{env:...}` + `.env.mcp` portable). Este ADR **sustituye el mecanismo de interpolación en `mcp.command`** por hardcodeo, tras confirmarse que `.env.mcp` no lo lee OpenCode (#5299). |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` | Define el bootstrap y la frontera kit↔app. El bootstrap (Opción C del flujo) sigue siendo el mecanismo de re-escritura para otros proyectos. |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md` | El flujo post-plataformado depende de MCPs activos; este ADR garantiza la operatividad en el maestro. |
| `opencode.json` (este proyecto) | Configuración efectiva: 5 MCP con rutas absolutas verificadas + `_note` que declara el workaround y la ausencia de los extendidos. |
| `.env.mcp` (este proyecto) | Reescrito con solo rutas reales verificadas; rol documental + entrada del bootstrap; se declara que OpenCode no lo lee. |
| `scripts/plataformador-bootstrap.ps1` | No modificado por este ADR; sigue siendo quien escribe rutas en proyectos. Sus `Resolve-McpCommand` / `Ensure-OpenCodeMcp` siguen siendo válidos para el flujo distribuible. |
| `Documentacion/Agents_IA_TECH/quickstart.md` | Debe documentar la Opción A para el maestro vs Opción C para el distribuible (pendiente de `documentador`). |
| `dependencias-manifest.yml` | Inventario de herramientas externas (`tokenslayer-mcp-server`, `graphify`) — referencia de qué MCP son instalables. |

---

## Referencias

- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0006-mcp-token-resolution.md` — ADR previo; mecanismo de tokens/`{env:...}` + `.env.mcp`.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — Bootstrap/instalador único + `Sync-TransversalKit`.
- Issue `anomalyco/opencode#5299` — `{env:...}` inconsistente en `mcp.command` (bug externo, no del kit).
- `scripts/plataformador-bootstrap.ps1` — `Resolve-McpCommand`, `Ensure-OpenCodeMcp`, `Configure-Graphify`.
- `opencode.json` / `.env.mcp` — Configuración efectiva del maestro (rutas reales verificadas).
