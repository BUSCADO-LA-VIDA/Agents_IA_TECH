# Validación QA: `tokenslayer-mcp-server` — fase validación `[TOKENSLAYER]`

> **Fecha**: 2026-09-18 | **Agente**: `qa-senior` (tarea `[TOKENSLAYER]`, paso `qa-senior`)
> **Server bajo prueba**: `proyect_ext/tokenslayer/mcp-server/build/index.js` (compilado por `devops`, commit `9a380c04`, tag v1.5.0)
> **Método**: protocolo MCP por stdio (`initialize` → `notifications/initialized` → `tools/call`), sin API keys, sin `apply_patch`, sin `clear_stats`, sin indexar carpetas con secrets.

## Comandos invocados (sin keys)

Todos contra `node <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js` por stdio (JSON-RPC):

1. `initialize` `{protocolVersion: "2024-11-05", clientInfo: qa-senior-test/1.0.0}` + `tools/list` — handshake y lista real de herramientas.
2. `tools/call get_stats {}` — baseline (antes de analizar) y acumulado (después).
3. `tools/call analyze_files {filePaths: [<absoluto>], maxTokens: 0, format: "text", expandable: true}` — un call por archivo (3 archivos).
4. `tools/call expand_node {nodeId: "<EXPAND de getLanguage en parser.ts>"}` — lazy-load de un nodo del esqueleto.
5. `tools/call analyze_files {filePaths: [stats.ts], maxTokens: 500, format: "skeleton"}` — sonda extra: valor de `format` fuera del enum del schema (el ejemplo de la guía usa `format="skeleton"`).

Archivos analizados (fuente propia del repo tokenslayer, sin secrets): `mcp-server/src/parser.ts`, `mcp-server/src/stats.ts`, `mcp-server/src/dashboard.ts`.

## Resultados por prueba

| # | Prueba | Resultado | Evidencia numérica |
|---|--------|-----------|--------------------|
| 0 | Handshake MCP (`initialize`) | ✅ PASS | `serverInfo: {name: "tokenslayer-mcp-server", version: "1.3.0"}`, `protocolVersion: "2024-11-05"`, responde sin colgarse |
| 1 | `tools/list` — nº y lista de herramientas | ✅ PASS | **8 herramientas** (la guía documenta 7): `analyze_files`, `analyze_workspace`, `analyze_dependency_chain`, `apply_patch`, `expand_node`, **`session_health` (extra)**, `get_stats`, `clear_stats` |
| 2 | `analyze_files` sobre `parser.ts` | ✅ PASS | Server: **92% (11400 → 869)** · 1282 líneas → esqueleto de 66 líneas · Original local: 1281 líneas / 45598 chars (~11400 tokens chars/4 — coincide con el conteo del server) |
| 3 | `analyze_files` sobre `stats.ts` | ✅ PASS | Server: **81% (4542 → 864)** · 539 líneas → esqueleto de 101 líneas · Original local: 538 líneas / 18165 chars (~4541 tokens — coincide) |
| 4 | `analyze_files` sobre `dashboard.ts` | ✅ PASS con advertencia | Server: **99% (6457 → 72)** · 575 líneas → esqueleto de 5 líneas, **pero el propio server emite aviso `[⚠ Low-yield skeleton]`**: el archivo parece envuelto en IIFE/closure (`renderHTML` líneas 63–574 colapsada a una firma) y el % alto es engañoso; recomienda grep/read por rangos. El server es honesto: no infla el ahorro útil. Para este archivo, el esqueleto NO sustituye lectura dirigida |
| 5 | `expand_node` (lazy-load, nodo `getLanguage` líneas 59–77 de `parser.ts`) | ✅ PASS | Devuelve `// parser.ts lines 59–77` con el fuente completo de la función, **idéntico al archivo** (verificado línea a línea; solo difiere `\r\n` vs `\n`) |
| 6 | `get_stats` acumulado | ✅ PASS | Tras 3 análisis: **20594 tokens ahorrados, 92% reducción** (22399 procesados → 1805 compactados, media 6865/archivo, 3 archivos únicos, lenguaje typescript). Tras la sonda extra (4º análisis): 24272 ahorrados, 90%. Aritmética interna verificada: 11400+4542+6457=22399; 869+864+72=1805; 20594/22399=91.95%→92% ✅ |
| 7 | Sonda `format="skeleton"` (fuera del enum `text\|json` del schema) | ✅ PASS (sin error) | El server **no rechaza** el valor: responde esqueleto en texto podado al budget (`maxTokens: 500` → "pruned to ~500 tokens", esqueleto completo era 875). Degradación graceful, más el aviso de cómo profundizar (`symbol`/`query`/`expand_node`/`maxTokens`). No se registró error |
| 8 | Registro en ambos harnesses (solo lectura) | ✅ PASS | `opencode.json`: clave `tokenslayer` (`type: local`, `node` + script compilado, `enabled: true`). `.vscode/mcp.json`: servidor `tokenslayer` (`command: node` + `args`, **`type: stdio`** ✅) |

Prohibiciones respetadas: `apply_patch` no ejecutado (ni siquiera `dryRun` en esta fase) · `clear_stats` no ejecutado (la medición sigue intacta en `~/.tokenslayer/stats.jsonl`, 4 registros) · no se indexaron `.env`/`*.pem`/`.opencode/config.json` · ninguna API key en argumentos.

## Ahorro observado vs. claim upstream (40–95%)

- **Observado genuino: 81–92%** (`stats.ts` 81%, `parser.ts` 92%) — **dentro del claim** ✅.
- El 99% de `dashboard.ts` queda **fuera de la comparación**: el propio server lo marca como low-yield engañoso. Comportamiento correcto y auditable.
- Nota metodológica: sin `targetModel`, el conteo es heurístico `chars/4` (verificado contra medición local exacta); la base es la misma a ambos lados, así que el % es comparable. Para conteo fiel BPE, pasar `targetModel` (`gpt-4o`/`gpt-4`/`claude`).

## Hallazgos previos del `devops` (verificación)

1. **Versión 1.3.0 vs tag v1.5.0 — CONFIRMADO**: handshake reporta `version: "1.3.0"` y `mcp-server/package.json` declara `"version": "1.3.0"`. La v1.5.0 corresponde a la **extensión VS Code** (`ajvikram.tokenslayer`), no al MCP server. Es skew de versiones entre ambos artefactos, no un fallo. **Para `documentador`**: aclararlo en `MCPs/tokenslayer.md` (versión del MCP server ≠ versión de la extensión).
2. **8 herramientas (extra `session_health`) — CONFIRMADO**: lista completa en la tabla de la prueba #1. `session_health` (Context Rot Score + recomendación de modelo, opera sobre transcripts de Claude Code en `~/.claude/projects/`) no está en la guía. **Para `documentador`**: documentar la 8ª herramienta en `MCPs/tokenslayer.md` (era 7, ahora 8).

## Bugs / drift para `devops` y `documentador` (no bloqueantes, no se corrigen desde QA)

- **BUG-1 (docs, `documentador`)**: `MCPs/tokenslayer.md` §5 dice 7 herramientas y no lista `session_health` → actualizar tabla a 8 + describirla.
- **BUG-2 (docs, `documentador`)**: `MCPs/tokenslayer.md` §5 lista los parámetros de `analyze_files` como `symbol, query, maxTokens, format, expand_node`. El schema real exige **`filePaths`** (requerido) y el flag se llama **`expandable`** (boolean); `expand_node` es otra herramienta. Además hay **`targetModel`** no documentado. El ejemplo `format="skeleton"` funciona por fallback graceful aunque el enum del schema solo admite `text|json` (verificado en prueba #7) — aclararlo o corregirlo.
- **BUG-3 (trazabilidad, `devops`/`documentador`)**: fijar en `dependencias-manifest.yml` que la versión pineada v1.5.0 es la de la **extensión/tag**, mientras que el **MCP server** se autodeclara 1.3.0, para evitar confusión futura.
- **Sin bugs funcionales en el server**: handshake, esqueletos, lazy-load, stats y presupuestos (`maxTokens`) funcionan según lo documentado; la aritmética de ahorro es exacta; el aviso low-yield demuestra honestidad en el reporte.

## Conclusión: ¿listo para uso?

**SÍ, listo para uso como capa de compactación previa (solo lectura: `analyze_*`, `expand_node`, `get_stats`)**, con las condiciones ya impuestas por el `security-auditor` (no indexar secrets, `dryRun` primero si algún día se usa `apply_patch`, extracción semántica desactivada). Ahorro real verificado 81–92%, dentro del claim 40–95%. Queda como deuda no bloqueante actualizar la guía (`MCPs/tokenslayer.md`: 8 herramientas, params reales de `analyze_files`, aclaración de versiones) — reportado arriba como BUG-1/2/3.
