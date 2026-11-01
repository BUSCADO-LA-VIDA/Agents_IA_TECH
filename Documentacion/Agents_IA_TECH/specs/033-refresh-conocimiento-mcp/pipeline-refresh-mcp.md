# Pipeline de refresh MCP — Primera ejecución del día

## Objetivo

Documentar el pipeline determinista para refrescar los índices y bases de conocimiento de todos los MCP del proyecto en la primera ejecución del día: `codebase-memory-mcp`, `graphify`, `context-mode` y `tokenslayer`.

Principio rector: **sin IA de entrada**. Las herramientas se ejecutan primero; la IA solo actúa bajo demanda.

## Orden obligatorio del pipeline

```
codebase-memory-mcp → graphify → context-mode → tokenslayer
```

## Paso 1 — codebase-memory-mcp (reindexar repositorio)

**Cuándo:** Siempre, en la primera ejecución del día.

**Comando:**
```
codebase-memory-mcp index_repository <raiz-del-repositorio>
```

**Salida esperada:** Nodos y aristas reindexados en el grafo de conocimiento del código.

**MCP:** `codebase-memory-mcp` → `index_repository`, `search_graph`, `query`

---

## Paso 2 — graphify (actualizar comunidades)

**Cuándo:** Siempre, después de codebase-memory-mcp.

**Comandos:**
```
graphify extract --code-only <raiz-del-repositorio>
graphify query <consulta-de-comunidades>
```

**Salida esperada:** Comunidades actualizadas y nodos relevantes del grafo.

**MCP:** `graphify` → `extract`, `query`, `explain`

---

## Paso 3 — context-mode (indexar documentos)

**Cuándo:** Siempre, después de graphify.

**Comandos:**
```
context-mode ctx_index <documentos-del-proyecto>
context-mode ctx_search <consulta-de-contenido>
```

**Salida esperada:** Documentos indexados con búsqueda de texto completo (FTS5+BM25).

**MCP:** `context-mode` → `ctx_index`, `ctx_search`

---

## Paso 4 — tokenslayer (verificar estadísticas)

**Cuándo:** Siempre, después de context-mode.

**Comando:**
```
tokenslayer get_stats
```

**Salida esperada:** Estadísticas de ahorro de tokens del pipeline.

**MCP:** `tokenslayer` → `get_stats`

---

## Paso 5 — Registrar en 00-indice.md y bitácora

**Cuándo:** Siempre, después de que todos los MCPs respondan OK.

**Archivos a actualizar:**
- `Documentacion/Agents_IA_TECH/00-indice.md`: entrada con timestamp, hora, MCPs actualizados, resultado.
- `Documentacion/Agents_IA_TECH/bitacoras/YYYY-MM-DD-refresh-mcp.md`: detalle de comandos ejecutados y resultados.

**MCP:** Ninguno (escritura directa con edición quirúrgica `edit`).

---

## Reglas de ejecución

1. **Orden estricto:** No se salta ningún paso. Si un paso falla, se detiene y se reporta.
2. **Fail-closed:** Si cualquier MCP no responde o devuelve error, el refresh no se da por exitoso.
3. **Idempotencia:** Reejecutar el refresh el mismo día no duplica nodos ni documentos.
4. **Sin IA de entrada:** La IA solo se usa bajo demanda si falta información después de ejecutar todas las herramientas.
5. **Paridad de arneses:** El mismo pipeline se ejecuta en `.github/` y `.opencode/` con los mismos comandos.
6. **No secretos:** No se indexan credenciales, tokens ni datos sensibles en ningún índice de MCP.
7. **Primera ejecución del día:** El refresh solo se dispara automáticamente en la primera ejecución del día. En horarios no matutinos queda como operación manual opcional.

---

## Registro de ejecución (plantilla)

| Campo | Valor |
|---|---|
| Fecha | `<YYYY-MM-DD>` |
| Hora | `<HH:MM>` |
| Agente orquestador | `plataformador` |
| Agente ejecutor | `analista_tecnico` |
| MCPs actualizados | `codebase-memory-mcp`, `graphify`, `context-mode`, `tokenslayer` |
| Nodos indexados | `<numero>` |
| Errores | `<cantidad>` |
| Resultado | `OK` / `FALLO` |
| Bitácora | `Documentacion/Agents_IA_TECH/bitacoras/<fecha>-refresh-mcp.md` |
