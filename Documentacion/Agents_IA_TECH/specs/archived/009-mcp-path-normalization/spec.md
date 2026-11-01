# Spec 009 - Normalización de rutas MCP a forward slashes

## Contexto
El error `InvalidEscapeCharacter` en `opencode.json` ocurre cuando las rutas MCP se escriben con backslashes Windows `\` y el parser JSON las interpreta como escapes inválidos.

Ejemplo de error:
```
InvalidEscapeCharacter at line 95, column 9
"command": ["C:\Users\tomas\AppData\Roaming\npm\context-mode.ps1"]
```

## Problema
- `plataformador-bootstrap.ps1` resuelve rutas con `Get-Command` que devuelve rutas Windows con `\`.
- Al serializar con `ConvertTo-Json` y escribir `opencode.json`, las rutas quedan con `\` que en JSON deben escaparse como `\\`.
- En algunos casos el archivo queda con backslashes sin escapar correctamente, provocando `InvalidEscapeCharacter`.

## Solución
Normalizar rutas a forward slashes `/` antes de asignarlas a `command` en `opencode.json`.

### Cambios requeridos en `scripts/plataformador-bootstrap.ps1`
1. **Normalizar rutas al resolver MCP**
   ```powershell
   $real = Resolve-McpCommand -ToolName $tokenMap[$name].Tool -Token $tokenMap[$name].Token
   if ($real) {
       $realNorm = $real -replace '\\','/'
       $entry.Value.command = @($realNorm)
   }
   ```

2. **Normalizar rutas para tokenslayer y graphify**
   ```powershell
   $nodeCmd.Source = $nodeCmd.Source -replace '\\','/'
   $pythonCmd.Source = $pythonCmd.Source -replace '\\','/'
   $graphCanonG = $graphCanonG -replace '\\','/'
   ```

3. **Normalizar al escribir JSON**
   Opcional: post-procesar el JSON antes de `Set-Content`:
   ```powershell
   $jsonOut = $existing | ConvertTo-Json -Depth 10
   $jsonOut = $jsonOut -replace '\\\\','/'
   Set-Content -Path $opencodePath -Value $jsonOut -Encoding UTF8
   ```

### Reglas
- Las rutas en `opencode.json` deben usar `/` siempre.
- `.env.mcp` mantiene rutas con `/` como fuente de verdad portable.
- No usar variables de entorno del sistema para resolver rutas MCP. Usar `.env.mcp` como fuente de verdad.

## Impacto
- Corrige `InvalidEscapeCharacter` en todos los proyectos.
- Hace `opencode.json` portable entre Windows/macOS/Linux.
- Evita regeneración de errores al sincronizar el kit maestro.

## Tareas
- [ ] Actualizar `plataformador-bootstrap.ps1` en kit maestro para normalizar rutas.
- [ ] Documentar en `Documentacion/Constitution_Wizard_Instructions.md`.
- [ ] Añadir test de validación JSON tras escritura.
