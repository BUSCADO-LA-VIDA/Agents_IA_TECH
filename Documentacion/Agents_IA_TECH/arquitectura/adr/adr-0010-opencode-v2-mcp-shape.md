# ADR-0010 — Forma V2 de `opencode.json` (mcp.servers + mcp.timeout.startup)

- **Estado**: Aceptada
- **Fecha**: 2026-10-18
- **Decide sobre**: la forma del bloque `mcp` y del bloque de proveedores en `opencode.json` del KIT
- **Sustituye/complementa**: ADR-0006 (resolución de tokens), ADR-0009 (rutas MCP hardcodeadas)
- **Bitácora**: `Documentacion/Agents_IA_TECH/bitacoras/2026-10-18-opencode-v2-mcp-fix.md`

---

## Contexto

El `opencode.json` del KIT se había escrito siguiendo la forma de OpenCode v1. La máquina tenía OpenCode **v2.0.32**, cuyo schema es estricto. La consecuencia práctica no era cosmética: los servidores MCP que arrancan lento fallaban de forma sistemática con `Request timed out`, y el modelo por defecto no resolvía.

Tres capas jugaron en contra:

1. La forma de `mcp` era V1 (servidores sueltos bajo `mcp`), aceptada por compatibilidad pero fuera del schema V2.
2. El control de tiempo disponible se escribía en un campo que V2 no interpreta en esa posición (`timeout` entero por servidor, en lugar de `mcp.timeout.startup`).
3. El modelo por defecto apuntaba a `groq-custom/llama-3.3-70b-versatile`, un proveedor que nunca se definió, y la credencial de Groq estaba vencida.

Resultado medido: **5 de 9 MCPs conectados, 4 con `Request timed out`** y un selector de modelos que no cargaba.

---

## Decisión

Se adopta la forma V2 estricta del schema oficial (`https://opencode.ai/config.json`) como forma canónica del `opencode.json` del KIT.

### Reglas que se fijan

| Regla | Contenido |
|---|---|
| **R1 — `mcp.servers`** | Todo servidor MCP vive bajo `mcp.servers.<nombre>`. Nunca directamente bajo `mcp`. El schema V2 admite solo `timeout` y `servers` en `mcp`. |
| **R2 — Tiempos con nombre** | El arranque se controla con `mcp.timeout.startup`, no con un entero por servidor. Valor KIT: `180000`. El entero por servidor no es equivalente y no se usa para arranque. |
| **R3 — Sin `enabled`** | La variante `Mcp.LocalConfigEncoded` no admite `enabled` y tiene `additionalProperties: false`. Para habilitar basta omitir el campo; para deshabilitar se usa `disabled: true`. |
| **R4 — Rutas absolutas** | Se mantiene ADR-0009: `command` con rutas absolutas y `node.exe` explícito, sin `{env:}` ni rutas relativas al cwd. |
| **R5 — Sin proveedores custom redundantes** | Si un proveedor builtin del catálogo de models.dev ya tiene credencial en `opencode auth`, no se declara custom. Se elimina `nvidia-custom` y `deepinfra-custom`. |
| **R6 — Credenciales fuera del archivo** | Ni `.env` ni secretos en el JSON. Las credenciales viven en `opencode auth` o en variables de entorno reales del proceso. |
| **R7 — Validación contra schema** | Cualquier cambio a `opencode.json` se valida con `jsonschema` contra el schema oficial antes de declararse terminado. "Es JSON válido" no es evidencia suficiente. |

### Valores adoptados

```jsonc
{
  "model": "opencode/deepseek-v4.1-flash-free",
  "small_model": "opencode/beam-free",
  "mcp": {
    "timeout": { "startup": 180000, "catalog": 120000, "execution": 900000 },
    "servers": {
      "<nombre>": { "type": "local", "command": ["<abs>", "..."] }
    }
  }
}
```

---

## Alternativas consideradas

### A. Mantener la forma V1 por compatibilidad

**Rechazada.** El shim V1 acepta el archivo, pero el campo de tiempo no se aplica en esa posición y el arranque queda en el default de 30 s. El síntoma (MCPs que fallan) persistiría. La compatibilidad implícita tampoco es una garantía: depende de que OpenCode conserve el shim.

### B. Subir solo el timeout y dejar el resto

**Rechazada por incompleta.** Habría dejado `provider` singular (V1), `region` inexistente y `enabled` en una posición donde el schema V2 no lo admite. Arregla el síntoma sin cerrar la causa, y el próximo que edite el archivo vuelve a tropezar.

### C. Bajar la exigencia: menos MCPs, menos arranque

**Rechazada.** Se podría desactivar `semgrep` para eliminar el arranque más lento. Se descarta porque el problema no era `semgrep`: era el deadline global aplicado a cinco servidores que sí arrancaban bien. Desactivar uno no sube los otros cuatro.

### D. Declarar `enabled: false` en vez de omitir

**Rechazada por ruido.** Equivalente al default y suma una línea por servidor que puede desincronizarse del default.

---

## Consecuencias

### Positivas

- **9 de 9 MCPs conectados**, verificado con `opencode mcp list` (antes 5 de 9).
- **0 errores** de validación contra el schema oficial.
- El modelo por defecto es **gratuito y verificado con una llamada real**: `opencode/deepseek-v4.1-flash-free`.
- Se eliminó una vía de fallo silencioso: `deepinfra-custom` con token vacío.
- Se eliminó el `.env`, que no tenía efecto y podía inyectar placeholders como credenciales.

### Negativas

- **R2 ata el KIT a una constante de arranque.** Si en otra máquina un MCP tarda más de 180 s, hay que ajustar. Se acepta: 180 s es holgado frente a los 25 s más altos medidos, y el valor es una sola línea.
- **R5 obliga a revisar `opencode auth` antes de agregar un proveedor.** Más lento que copiar un bloque `provider`, a cambio de no duplicar catálogos ni guardar tokens en archivos.
- **R7 agrega un paso de verificación.** Es deliberado: las tres fallas iniciales eran silenciosas y ninguna se detectó leyendo el archivo.

### Riesgo residual

El `opencode.json` es **trackeado en git** y `scripts/sync/mcp/lift-opencode.ps1` lo replica a los proyectos consumidores. Si el lift no reconoce `mcp.servers`, podría reintroducir la forma V1 en el destino. **Pendiente de verificar** (ver §Pendientes).

---

## Verificación

| Criterio | Resultado |
|---|---|
| `jsonschema` Draft 2020-12 contra el schema oficial | 0 errores |
| `opencode mcp list` | 9 conectados, 0 fallidos |
| Herramientas MCP visibles en el catálogo de la sesión | 9 de 9 |
| `opencode run` sin `--model` | `OK · build · deepseek-v4.1-flash-free` |
| Llamada real a modelo `:free` de OpenRouter | `OK` |
| Llamada real a `nvidia/deepseek-ai/deepseek-v4.1-flash` | `OK` |

## Pendientes

| # | Pendiente | Quién |
|---|---|---|
| P1 | Verificar que `scripts/sync/mcp/lift-opencode.ps1` preserva `mcp.servers` y `mcp.timeout` al fusionar contra un destino, y no reintroduce la forma V1 | `plataformador` |
| P2 | Decidir si `opencode.json` se commitea y se replica, o queda solo local | usuario |
| P3 | Renovar o eliminar la credencial de Groq, hoy vencida | usuario |
| P4 | Silenciar el WARN `failed to load plugin target=context-mode` con `"plugins": ["-context-mode"]`, si se considera ruido molesto | `plataformador` |
