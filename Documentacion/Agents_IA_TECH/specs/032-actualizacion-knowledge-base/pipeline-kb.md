# Pipeline de actualización de Knowledge Base (KB)

## Objetivo

Documentar el pipeline determinista para indexar una spec cerrada en la Knowledge Base del proyecto: CodeBase (`codebase-memory-mcp`), Context (`context-mode`) y Graphify (`graphify`).

Principio rector: **sin IA de entrada** (sin IA de entrada). Las herramientas se ejecutan primero; la IA solo actúa bajo demanda.

## Orden obligatorio del pipeline

```
markitdown → graphify → codebase-memory-mcp → context-mode
```

## Paso 1 — markitdown (convertir a Markdown si es necesario)

**Cuándo:** Si la spec no está en formato Markdown (PDF, DOCX, HTML, etc.).

**Comando:**
```
markitdown convert_to_markdown --uri <ruta-a-la-spec>
```

**Salida esperada:** Archivo Markdown con el contenido de la spec.

**MCP:** `markitdown` → `convert_to_markdown`

---

## Paso 2 — graphify (extraer nodos y comunidades)

**Cuándo:** Siempre, después de markitdown (o directamente si la spec ya está en Markdown).

**Comandos:**
```
graphify extract --code-only <ruta-a-la-spec>
graphify query <consulta-de-comunidades>
```

**Salida esperada:** Nodos extraídos y comunidades detectadas relacionadas con la spec.

**MCP:** `graphify` → `extract`, `query`, `explain`

---

## Paso 3 — codebase-memory-mcp (indexar nodos y aristas)

**Cuándo:** Siempre, después de graphify.

**Comandos:**
```
codebase-memory-mcp index_repository <ruta-a-la-spec>
codebase-memory-mcp query <consulta-de-nodos-de-la-spec>
```

**Salida esperada:** Nodos y aristas indexados en el grafo de conocimiento del código.

**MCP:** `codebase-memory-mcp` → `index_repository`, `search_graph`, `query`

---

## Paso 4 — context-mode (indexar para búsqueda FTS5+BM25)

**Cuándo:** Siempre, después de codebase-memory-mcp.

**Comandos:**
```
context-mode ctx_index <ruta-a-la-spec>
context-mode ctx_search <consulta-de-contenido-de-la-spec>
```

**Salida esperada:** Documento indexado con búsqueda de texto completo.

**MCP:** `context-mode` → `ctx_index`, `ctx_search`

---

## Paso 5 — Registrar en 00-indice.md y bitácora

**Cuándo:** Siempre, después de que todos los MCPs respondan OK.

**Archivos a actualizar:**
- `Documentacion/Agents_IA_TECH/00-indice.md`: entrada con timestamp, spec, MCPs actualizados, resultado.
- `Documentacion/Agents_IA_TECH/bitacoras/YYYY-MM-DD-actualizacion-kb-<spec>.md`: detalle de comandos ejecutados y resultados.

**MCP:** Ninguno (escritura directa con edición quirúrgica `edit`).

---

## Reglas de ejecución

1. **Orden estricto:** No se salta ningún paso. Si un paso falla, se detiene y se reporta.
2. **Fail-closed:** Si cualquier MCP no responde o devuelve error, la actualización no se da por exitosa.
3. **Idempotencia:** Reejecutar el pipeline sobre una spec ya indexada no duplica nodos ni documentos.
4. **Sin IA de entrada:** La IA solo se usa bajo demanda si falta información después de ejecutar todas las herramientas.
5. **Paridad de arneses:** El mismo pipeline se ejecuta en `.github/` y `.opencode/` con los mismos comandos.
6. **No secretos:** No se indexan credenciales, tokens ni datos sensibles en ningún índice de KB.

---

## Registro de ejecución (plantilla)

| Campo | Valor |
|---|---|
| Spec indexada | `<nombre-de-la-spec>` |
| Fecha | `<YYYY-MM-DD>` |
| Agente orquestador | `plataformador` |
| Agente ejecutor | `analista_tecnico` |
| MCPs actualizados | `codebase-memory-mcp`, `context-mode`, `graphify` |
| Nodos indexados | `<numero>` |
| Errores | `<cantidad>` |
| Resultado | `OK` / `FALLO` |
| Bitácora | `Documentacion/Agents_IA_TECH/bitacoras/<fecha>-actualizacion-kb-<spec>.md` |
