# Bitácora 2026-10-18 — Corrección de `opencode.json` a OpenCode v2

**Alcance**: `opencode.json` de la raíz del KIT. Sin commit (decisión del usuario: "arreglar sin commitear").

**Motivo reportado por el usuario**: los modelos FREE no aparecen y hay "error de Token Inválido".

**Versión detectada**: OpenCode `v2.0.32` (channel `latest`), Python 3.14, Node en `C:\Program Files\nodejs`.

---

## 1. Diagnóstico: 5 defectos encontrados

Todos verificados con evidencia ejecutable, no por lectura de archivo.

### D1 — Modelo por defecto apuntando a un proveedor inexistente

Valor anterior: `"model": "groq-custom/llama-3.3-70b-versatile"`.

El objeto `provider` solo definía `nvidia-custom` y `deepinfra-custom`. **No existía ningún proveedor `groq-custom`**, por lo que el modelo por defecto no resolvía y el selector `/models` se caía.

Prueba real contra el proveedor builtin correcto:

```
groq/llama-3.3-70b-versatile  →  Error: The model `llama-3.3-70b-versatile` does not exist
                                 or you do not have access to it.
```

Conclusión: **la credencial de Groq está vencida o sin acceso**. No es un problema de configuración sino de la clave.

### D2 — `small_model` con formato inválido

Valores previos: `"groq-custom/llama-3.1-8b-instant"` y luego `"deepseek-ai/deepseek-v4-flash"`.

La referencia de modelo exige `provider/model`. El segundo valor **no tenía prefijo de proveedor**, por lo que tampoco resolvía.

### D3 — Token vacío por variable de entorno ausente

`deepinfra-custom` usaba `"apiKey": "{env:DEEPINFRA_API_KEY}"`. Inventario de variables:

| Variable | Estado |
|---|---|
| `NVIDIA_API_KEY` | presente (len 70) |
| `GROQ_API_KEY` | presente (len 20) — pero vencida |
| `DEEPSEEK_API_KEY` | presente (len 35) |
| `DEEPINFRA_API_KEY` | **ausente** |

Documentación de OpenCode: *"If the environment variable is not set, it will be replaced with an empty string."* → el proveedor quedaba con token vacío.

Además, `nvidia-custom` y `deepinfra-custom` **duplicaban** los proveedores builtin `nvidia` (41 modelos) y `deepinfra` (56 modelos), que ya tienen credencial guardada en `opencode auth`. Eran redundantes y solo aportaban una vía de fallo.

### D4 — Forma V1 de `mcp` en una config V2

El schema oficial (`https://opencode.ai/config.json`) establece:

- `mcp` admite **únicamente** `timeout` y `servers`. Los 9 servidores estaban colocados directamente bajo `mcp`.
- `mcp.timeout` admite **únicamente** `startup`, `catalog` y `execution`. El valor presente era un entero `120000`, que no aplica a ninguno de esos tres.
- El `anyOf` de `mcp.servers` resuelve a `Mcp.LocalConfigEncoded`, cuyos campos son `type, command, cwd, environment, disabled, codemode, timeout, protocol`. **`enabled` no existe en esa variante** y `additionalProperties` es `false`.
- `provider` (singular) es la forma V1; la forma V2 es `providers`, con `package` en lugar de `npm` y `settings` en lugar de `options`.
- `region` **no existe** en el schema.

### D5 — `startup` de MCP por debajo del tiempo real de arranque

`mcp.timeout.startup` por defecto es **30 s**. Medición del handshake `initialize` real, proceso por proceso:

| Servidor | Arranque medido | Diagnóstico |
|---|---|---|
| `context-mode` | 6,8 s | sano |
| `graphify` | 7,7 s | sano |
| `markitdown` | **21,2 s** | sano, pero el handshake completo (`initialize` + `tools/list`) se pasa de 30 s |
| `semgrep` | **> 25 s** | el único arranque realmente pesado |

Los cuatro "fallidos" **no estaban rotos**: el deadline global los bautizaba cuando arrancaban en paralelo junto a los otros cinco.

---

## 2. Correcciones aplicadas

| # | Corrección | Antes | Después |
|---|---|---|---|
| C1 | Servidores bajo `mcp.servers` | 9 claves directamente bajo `mcp` | `mcp.servers` con 9 entradas |
| C2 | Tiempos de MCP | `timeout: 120000` (entero, no aplicado) | `mcp.timeout: {startup: 180000, catalog: 120000, execution: 900000}` |
| C3 | Flag por servidor | `"enabled": true` (campo inexistente, `additionalProperties: false`) | omitido (por defecto `false` = habilitado) |
| C4 | `model` | `groq-custom/llama-3.3-70b-versatile` (proveedor inexistente) | `opencode/deepseek-v4.1-flash-free` |
| C5 | `small_model` | sin prefijo de proveedor | `opencode/beam-free` |
| C6 | Proveedores custom | `provider` singular con `nvidia-custom` y `deepinfra-custom` | eliminados; se usan los builtin con auth ya guardada |
| C7 | Campos no soportados | `region`, `plugin: []`, `_note` | eliminados |
| C8 | Ruta relativa de `tokenslayer` | `proyect_ext/...` (dependía del cwd) | absoluta con `node.exe` explícito |
| C9 | `.env` creado en la sesión anterior | plantilla con placeholders | **eliminado** |

### C9 en detalle — Autocorrección de un error previo

En la sesión del 2026-10-18 anterior se indicó al usuario que completara un archivo `.env` con sus API keys. **Esa indicación era incorrecta**: la documentación de OpenCode no soporta archivos `.env`; `{env:NAME}` se resuelve contra el entorno real del proceso. Un archivo `.env` no habría tenido efecto y, si alguna vez se leyera, habría inyectado placeholders como credenciales. El archivo fue eliminado.

Las credenciales reales se administran con `opencode auth` (almacén de credenciales de OpenCode) o con variables de entorno de Windows. El almacén ya contiene: OpenCode Go, OpenCode Console, Deep Infra, DeepSeek, Groq, Nvidia y OpenRouter.

---

## 3. Modelos FREE: cómo actualizar el listado

El listado de modelos **no estaba roto**: el catálogo expone **574 modelos**, de los cuales **16 son `:free`** de OpenRouter, más los free de OpenCode Zen.

El selector `/models` solo muestra modelos habilitados cuyo proveedor está disponible en el proyecto actual. Como el modelo por defecto apuntaba a un proveedor inexistente, la sesión arrancaba sin modelo válido y el selector se caía.

Modelos FREE verificados con llamada real (no solo con `opencode models`):

| Modelo | Resultado |
|---|---|
| `opencode/deepseek-v4.1-flash-free` | **OK** |
| `opencode/beam-free` | **OK** |
| `openrouter/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | **OK** |
| `nvidia/deepseek-ai/deepseek-v4.1-flash` | **OK** |
| `groq/llama-3.3-70b-versatile` | **FALLA** — credencial vencida |

Proveedores con modelos no gratuitos pero funcionales: `nvidia` (41), `deepinfra` (56), `deepseek` (2), `opencode` (41), `opencode-go` (29).

Comandos para refrescar el listado:

```bash
opencode models                      # catálogo completo, 574 entradas
opencode auth list                   # credenciales disponibles
opencode service restart             # fuerza recarga de config y catálogo
```

Para incorporar una credencial nueva: `opencode auth` y seguir el flujo, o `/connect` dentro de la TUI.

---

## 4. Verificación

### 4.1 Validación contra el schema oficial

```
VALIDACION SCHEMA: 0 errores -> opencode.json es V2 valido
```

Validado con `jsonschema` (Draft 2020-12) contra el schema descargado de `https://opencode.ai/config.json`. El script quedó en `%TEMP%\val_opencode.py`; es reproducible en cualquier momento bajando el schema y apuntándolo al archivo.

### 4.2 Estado de los MCPs

Antes de la corrección:

```
✓ codebase-memory-mcp  connected        ✗ context-mode  failed: Request timed out
✓ context7             connected        ✗ graphify      failed: Request timed out
✓ github               connected        ✗ markitdown    failed: Request timed out
✓ playwright           connected        ✗ semgrep       failed: Request timed out
✓ tokenslayer          connected
RESUMEN: conectados=5  fallidos=4
```

Después de la corrección:

```
✓ codebase-memory-mcp  connected    ✓ markitdown   connected
✓ context-mode         connected    ✓ playwright   connected
✓ context7             connected    ✓ semgrep      connected
✓ github               connected    ✓ tokenslayer  connected
✓ graphify             connected
RESUMEN: conectados=9  fallidos=0
```

Los 9 aparecen además en el catálogo de herramientas de la sesión.

### 4.3 Modelo por defecto

```
$ opencode run "Responde exactamente: OK"     # sin --model, usa la config
OK   > build · deepseek-v4.1-flash-free
```

---

## 5. Pendientes y riesgos

| # | Pendiente | Prioridad |
|---|---|---|
| P1 | El usuario debe reiniciar OpenCode (`opencode service restart`) para que la TUI recargue config y catálogo. El CLI ya recarga solo, pero la TUI puede mantener estado. | Alta |
| P2 | Credencial de Groq vencida: o se renueva en `groq.com/console` o se elimina de `opencode auth` para que no vuelva a ser el default por error. | Media |
| P3 | `opencode.json` sigue sin commitear, a pedido del usuario. Hay que decidir si se replica a los otros proyectos vía `sync-kit-agents.ps1`, que hoy escribiría la forma V2 correcta. | Media |
| P4 | WARN cosmético recurrente: `failed to load plugin target=context-mode`. OpenCode autodescubre el paquete npm global `context-mode` e intenta cargarlo como plugin, pero su `main` es un CLI de MCP, no un plugin. No bloquea nada. Se descarta explícitamente con `"plugins": ["-context-mode"]` si se quiere silenciar. | Baja |
| P5 | El `.env` que estaba en `.gitignore` ya no es necesario. La regla puede quedarse o retirarse; no aporta nada. | Baja |

## 6. Correccion de raiz: los agentes estaban incompletos, no los MCPs sobraban

### El error de razonamiento

Despues de la conversion a V2 se cruzo el uso documentado de cada MCP contra las 32 definiciones de agente. El resultado fue que 13 de 16 agentes declaraban solo 3 MCPs (`context-mode`, `codebase-memory-mcp`, `markitdown`) teniendo 8 instalados, y `tokenslayer`, `semgrep` y `context7` aparecian en 0 de 32.

**La primera lectura fue erronea**: ese cero se interpreto como "estos MCPs sobran" y se propusieron a retirada. La lectura correcta es la inversa: un MCP instalado que ningun agente declara es una **implementacion incompleta**, y la correccion corresponde al agente.

El usuario senalo el error de forma explicita: *"los agentes deben usarlos MCP instalados, es un error de implementacion de los MCP incompletos"*. `tokenslayer` y `context7` fueron restituidos de inmediato.

### Estado de los MCPs tras la correccion

| MCP | Agentes que lo declaran | Ruta valida tras `git clone` | Estado |
|---|---|---|---|
| `context-mode` | 16/16 (transversal) | si | activo |
| `codebase-memory-mcp` | 16/16 (transversal) | si | activo |
| `markitdown` | 16/16 (transversal) | si | activo |
| `graphify` | 16/16 (transversal) | no (`graphify-out/` gitignored) | activo |
| `tokenslayer` | 16/16 (transversal) | no (`proyect_ext/*` gitignored) | activo |
| `context7` | 10/16 (por rol) | si | activo |
| `github` | 6/16 (por rol) | si | activo |
| `playwright` | 3/16 (por rol) | si | activo |
| `semgrep` | 0/16 | si | **fuera de `opencode.json`, decision pendiente** |

### Correccion aplicada a los agentes

32 archivos (16 agentes x 2 arneses) actualizados. 12 agentes pasaron de 3 a 5-7 MCPs declarados, `pensador` de 4 a 6, y `ssh-connection-agent` y `usuario-preferencias` pasaron de no tener seccion a tener el bloque completo.

Verificado: **0 desajustes** entre `.github/agents/` y `.opencode/agents/`, frontmatter intacto en 32/32, UTF-8 sin BOM y finales de linea LF preservados.

### Evidencia de uso real (no solo declaracion)

Declarar un MCP no garantiza que el agente lo invoque. Se ejecuto `frontend-developer`, que antes no declaraba `context7`, pidiéndole documentacion vigente de Playwright:

```
execute  tools.context7["resolve-library-id"]({ libraryName: "Playwright", ... })
execute  tools.context7["query-docs"]({ libraryId: "/microsoft/playwright", ... })
-> locator.waitFor({ state: 'visible' })
```

El agente llamo las dos herramientas y devolvio la respuesta actualizada. Antes de la correccion no lo hacia.

### Regla antiorfanos incorporada al estandar

El fallo de origen estaba en el propio estandar de integracion: `RF-04 "Consumo por agentes"` exigia **documentar** el consumo, nunca **editar** las definiciones. Por eso `000-mcp-context7-integracion` pudo cerrar T01 a T05 en `[x]` sin que un solo agente declarara el MCP.

Correcciones aplicadas:

- `000-mcp-integracion-estandar.md`: `RF-04` reescrito (editar ambos arneses es obligatorio), `RF-07` nueva de verificacion anti-huerfano, `SC-005` y `SC-006`, diagrama de flujo con el paso, y `RF-03` corregido porque pedia `{env:XXX_CMD}` y `enabled: false`, que contradicen ADR-0009 y el schema V2.
- `.specify/templates/checklist-mcp-integracion.md`: checklist reutilizable con tabla de errores frecuentes.
- 4 specs MCP activas: `T07 Actualizar agentes afectados` y `T08 Verificacion anti-huerfano`.
- `AGENTS.md`: Regla 1 ampliada a los 8 MCPs y nueva **Regla 1b**.
- Spec 020: `RF-05` (cobertura obligatoria), `RF-06` (paridad entre arneses), `SC-04`.

La regla, textual: **si el cruce da cero agentes para un MCP instalado, el defecto esta en los agentes, no en el MCP.**

### Defecto de portabilidad (riesgo aceptado)

`opencode.json` esta trackeado en git, pero dos entradas apuntan a rutas absolutas dentro de directorios gitignorados:

| Entrada | Ruta | Regla de `.gitignore` |
|---|---|---|
| `tokenslayer` | `.../proyect_ext/tokenslayer/mcp-server/build/index.js` | `proyect_ext/*` (L23) |
| `graphify` | `.../graphify-out/graph.json` | `graphify-out/` (L31) |

En un clon nuevo esos dos servidores apuntan a archivos inexistentes. Se conservan por decision del usuario; la limitacion quedo documentada en `README.md`, con `graphify` registrado ademas como pendiente `020-T016`.

### Verificacion del estado final

```
VALIDACION SCHEMA: 0 errores -> opencode.json es V2 valido
cobertura MCP: 8 de 8 declarados por al menos un agente
huerfanos inversos: ninguno
desajustes entre arneses: 0
agentes con bloque MCP: 16/16

codebase-memory-mcp  context-mode  context7  github
graphify  markitdown  playwright  tokenslayer          -> 8/8 conectados, 0 fallidos

model: opencode/deepseek-v4.1-flash-free (gratuito, verificado)
small_model: opencode/beam-free (gratuito, verificado)
```

### Pendiente

`semgrep` esta instalado y con handshake verificado, pero quedo fuera de `opencode.json` y sin declaracion en agentes. Su `T07` quedo anotado como *pendiente de decision*: si se readmite, se declara en `security-auditor` y `qa-senior`; si se descarta, la spec debe marcarse obsoleta en vez de cerrada como completada. La misma correccion aplica a las specs de `sentry`, `perplexity`, `pieces` y `testsprite`, que quedaron en `[x]` con MCPs descartados.

## 7. Alcance de la intervención

La intervención se limitó a `C:\Proyectos\Agents_IA_TECH`. **No se modificó ningún otro proyecto**: `trading_bot` y `Generator_IA_Projects` siguen con su configuración en forma V1 y conservan sus propios MCPs.

Consecuencia conocida y **no resuelta**: `scripts/sync/mcp/lift-opencode.ps1` sigue iterando `@($master.mcp.PSObject.Properties)` tratando cada clave de `mcp` como un servidor. Con este maestro en V2 interpretará `servers` y `timeout` como nombres de MCP y corromperá el `opencode.json` de cualquier destino. Está registrado como `020-T010` y **debe resolverse antes de volver a correr el orquestador de sincronización**.

## 8. Archivos tocados

| Archivo | Accion |
|---|---|
| `opencode.json` | Forma V2 (`mcp.servers` + `mcp.timeout`), 8 MCPs, modelo default gratuito; validado con 0 errores contra el schema oficial |
| `.github/agents/*.md` (16) | Seccion "Uso de MCPs" ampliada al reparto transversal 5 + por rol |
| `.opencode/agents/*.md` (16) | Espejo exacto de los anteriores, 0 desajustes |
| `AGENTS.md` | Regla 1 ampliada a los 8 MCPs + nueva Regla 1b de cobertura obligatoria |
| `README.md` | Tabla de MCPs, reparto por rol y limitaciones de portabilidad |
| `.specify/templates/checklist-mcp-integracion.md` | Checklist reutilizable de integracion de MCP |
| `specs/000-mcp-integracion/000-mcp-integracion-estandar.md` | RF-04 reescrita, RF-07 nueva, RF-03 corregida, SC-005 y SC-006 |
| `specs/000-mcp-integracion/000-mcp-context7-integracion/` | `spec.md` addendum y `tasks.md` +T07 +T08 |
| `specs/000-mcp-integracion/000-mcp-semgrep-integracion/` | `spec.md` addendum y `tasks.md` +T07 (pendiente de decision) +T08 |
| `specs/000-mcp-integracion/000-mcp-playwright-integracion/tasks.md` | +T07 +T08 |
| `specs/000-mcp-integracion/000-mcp-github-integracion/tasks.md` | +T07 +T08 |
| `specs/020-mcp-config-operativa/spec.md` | RF-05, RF-06, SC-04, forma V2 y anulacion de la nota del `.env` |
| `arquitectura/adr/adr-0010-opencode-v2-mcp-shape.md` | Decision arquitectonica de la forma V2 (nuevo) |
| `pendientes-implementacion.md` | 6 tareas nuevas (`020-T010` a `020-T016`) |
| `bitacoras/2026-10-18-opencode-v2-mcp-fix.md` | Este documento (nuevo) |
| `.env` | **Eliminado**: OpenCode no lo lee, `{env:NAME}` se resuelve contra el entorno real del proceso |

No se toco codigo de aplicacion. No se modifico ningun otro proyecto. No se commiteo ni se pusheo en el momento de redactar esta bitacora.
