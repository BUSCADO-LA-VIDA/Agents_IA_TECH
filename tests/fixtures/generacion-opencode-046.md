# Fixture de generación — Spec 046 (T001-T003)

**Fecha**: 2026-11-11
**Objetivo**: dejar constancia reproducible de que el generador **no repara** la entrada `context-mode` cuando `opencode.json` usa la forma `mcp.servers.<nombre>`.

## Escenario

1. Directorio temporal con una copia de `scripts/`.
2. Semilla: `opencode.json` tomado del commit `e48c8c0` (estado previo a la corrección), con:

```json
"mcp": {
  "servers": {
    "context-mode": {
      "command": [
        "<NODE_HOME>/node.exe",
        "<NPM_GLOBAL>/node_modules/context-mode/build/cli.js"
      ]
    }
  }
}
```

3. `pwsh ./scripts/plataformador-bootstrap.ps1` (sin flags).

## Resultado observado

| Comprobación | Resultado |
|---|---|
| Exit code del bootstrap | `0` |
| `context-mode.command` antes | `node .../context-mode/build/cli.js` |
| `context-mode.command` después | **sin cambios** (sigue apuntando a `build/cli.js`) |
| `graphify` | **sí** se regeneró con la ruta del destino |
| `codebase-memory-mcp`, `markitdown`, `github`, `playwright`, `context7`, `tokenslayer` | sin cambios |

## Diagnóstico

`Ensure-OpenCodeMcp` recorre el bloque MCP con `$existing.mcp.PSObject.Properties[$name]`, es decir la forma legacy `mcp.<nombre>`. El archivo usa `mcp.servers.<nombre>`, de modo que el bucle no encuentra ninguna entrada y no re-resuelve nada. `graphify` sí cambia porque lo escribe otra función (`Configure-Graphify`).

Verificado en aislamiento: con la raíz correcta (`mcp.servers`) y la comprobación de existencia del script, la resolución produce `node <server.mjs> --agent opencode`.

## Consecuencia

El generador reproduce el MCP caído en cada corrida. La corrección va en el script (T004-T007) y se valida con la salida generada (T013-T014), no editando el archivo.
