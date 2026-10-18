# Feature Specification: 020-mcp-config-operativa — Configuración MCP operativa verificada en vivo

**Feature Branch**: `020-mcp-config-operativa`
**Created**: 2026-10-11
**Status**: Completado (documental — congela la configuración que levanta los 9 MCP)
**Input**: Sesión de verificación 2026-10-11. Esta spec NO instala nada: congela como referencia la configuración de `opencode.json` + binarios + índices que se verificó funcionando en vivo.

---

## Problema

El kit sufrió reiteradas regresiones de MCP (tokens `{env:...}` sin resolver por bug OpenCode #5299, shims `.ps1` que rompen stdio, binarios inexistentes registrados, timeouts por CPU saturada). Cada incidente obligaba a re-diagnosticar desde cero porque no existía una referencia congelada de "la configuración que funciona".

## Objetivos

- Dejar por escrito la configuración exacta (`opencode.json`, rutas, versiones) que levanta los 9 MCP el 2026-10-11.
- Definir el procedimiento de verificación viva por MCP (handshake stdio + llamada real).
- Servir de baseline para detectar regresiones futuras (comparar contra este documento).

## Configuración congelada (verificada 2026-10-11)

### `opencode.json` — bloque `mcp` (9 entradas, todas `enabled: true`)

| MCP | `command` hardcodeado | Versión verificada |
|-----|----------------------|-------------------|
| `context-mode` | `C:/Program Files/nodejs/node.exe` + `.../npm/node_modules/context-mode/build/cli.js` | responde `Usage:` RC=0 |
| `codebase-memory-mcp` | `C:/Users/tomas/.local/bin/codebase-memory-mcp.exe` | 0.9.0 |
| `markitdown` | `C:/Python314/Scripts/markitdown.exe` | markitdown-mcp 0.0.1a7 |
| `graphify` | `C:/Python314/python.exe -m graphify.serve C:/Proyectos/Agents_IA_TECH/graphify-out/graph.json` | graphifyy 0.9.48 |
| `tokenslayer` | `node proyect_ext/tokenslayer/mcp-server/build/index.js` | build presente |
| `github` | `C:/Users/tomas/.local/bin/github-mcp-server.exe stdio` | v2.0.2 oficial, 46 tools |
| `playwright` | `node .../@playwright/mcp/cli.js` | v1.64.0, 25 tools |
| `semgrep` | `C:/Users/tomas/.local/bin/semgrep.exe mcp` | CLI 1.180.0, 7 tools |
| `context7` | `node .../@upstash/context7-mcp/dist/index.js` | 2 tools |

Reglas (ADR-0009): rutas absolutas con forward slashes; entry-point JS directo en vez de shim `.ps1`; `0` tokens `{env:}` en `mcp.command`; los 8 MCP extendidos originales sin binario NO se registran (solo github/playwright/semgrep/context7 que sí están instalados; sentry bloqueado, perplexity/pieces/testsprite pendientes de keys/apps).

### Índices (verificados 2026-10-11)

| Índice | Estado | Métrica |
|--------|--------|---------|
| codebase-memory (`C-Proyectos-Agents_IA_TECH`) | `ready` | 5.664 nodos, 6.157 aristas, head `012bf36` |
| graphify (`graphify-out/graph.json`) | 100% extraído | 4.793 nodos, 4.717 aristas, 460 comunidades, 4.6 MB |
| context-mode (`content/`) | 9 archivos | — |

### Secretos

- `GITHUB_TOKEN` vive en el entorno del host (nunca en archivos). `.env` del proyecto es plantilla gitignored con la clave vacía.
- `.env.mcp` contiene solo rutas de comandos, sin secretos.

## Requisitos funcionales

- **RF-01**: `opencode.json` commiteado con las 9 entradas hardcodeadas y `enabled: true` (necesario para que `sync-kit` lo distribuya).
- **RF-02**: Ninguna entrada MCP sin binario verificado en disco (guardrail 1 de ADR-0009).
- **RF-03**: Procedimiento de verificación viva documentado en `plan.md` (handshake + llamada real por MCP).
- **RF-04**: Ante MCP apagado, orden de diagnóstico: 1) `opencode.log` (timeout vs transport error), 2) procesos filtrados (CPU), 3) shim `.ps1` vs node directo, 4) reload OpenCode.

## Fuera de alcance

- Instalar perplexity/pieces/testsprite (pendientes de keys/apps del usuario) y desbloquear sentry (hang + auth interactiva).
- Corregir el bug OpenCode #5299 (externo; salida del workaround ADR-0009).

## Criterios de éxito

- **SC-01**: Los 9 MCP responden handshake stdio en vivo (hecho 2026-10-11 para 8/9; markitdown verificado por binario + uso en pipeline).
- **SC-02**: `git status` limpio salvo `opencode.json` local si difiere de la plantilla commiteada (documentar la divergencia).
- **SC-03**: Esta spec permanece como baseline: cualquier regresión futura se diagnostica comparando contra ella.

---

## Addendum 2026-10-16 — Cambios posteriores al congelamiento

- `timeout: 120000` en las entradas MCP (el default de 5000 ms causaba timeouts masivos en arranques en frio; opcion documentada en opencode.ai/docs/mcp-servers).
- Sentry local eliminado (binarios colgados) y luego retirado del maestro al descartarse los MCP de pago; queda documentada la alternativa remota oficial con OAuth.
- Entrada `plugin: [context-mode]` eliminada (el paquete npm no exporta plugin valido; el servidor MCP ya provee las tools).
- Comandos `.ps1` reemplazados por `node <cli.js>` directo en context-mode/playwright/context7 (el envoltorio pwsh rompia el transporte stdio).
- Estado vigente: 9 MCP (5 base + github, playwright, semgrep, context7); sentry/perplexity/pieces/testsprite descartados por pago.

---

## Addendum 2026-10-18 — Forma V2 y regla de cobertura en los agentes

### Corrección de forma: `mcp.servers`

La tabla de la sección "Configuración congelada" describe la forma V1. OpenCode **v2.0.32** usa otra, y el schema es estricto (`additionalProperties: false`). La forma vigente es:

```jsonc
{
  "mcp": {
    "timeout": { "startup": 180000, "catalog": 120000, "execution": 900000 },
    "servers": {
      "<nombre>": { "type": "local", "command": ["<abs>", "..."] }
    }
  }
}
```

Cambios obligatorios respecto de la forma congelada:

| Antes (V1) | Ahora (V2) | Motivo |
|---|---|---|
| servidores sueltos bajo `mcp` | bajo `mcp.servers` | el schema V2 solo admite `timeout` y `servers` en `mcp` |
| `timeout: 120000` (entero) por servidor | `mcp.timeout.startup` / `catalog` / `execution` | el entero no controla el arranque; el default de `startup` es 30 s |
| `"enabled": true` | omitido | `Mcp.LocalConfigEncoded` no admite `enabled`; para deshabilitar existe `disabled` |
| `provider` singular con `nvidia-custom` y `deepinfra-custom` | proveedores builtin | los custom duplicaban el catálogo, y `deepinfra-custom` usaba una variable de entorno ausente, es decir token vacío |

`startup` se sube a 180 s porque la medición real dio 21,2 s para `markitdown` y más de 25 s para `semgrep`: con el default de 30 s, los servidores que arrancan bien fallan igual cuando se levantan en paralelo. Detalle y alternativas en `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0010-opencode-v2-mcp-shape.md`.

### Corrección de la sección "Secretos"

La línea que afirma *".env del proyecto es plantilla gitignored con la clave vacía"* queda **anulada**. OpenCode no soporta archivos `.env`: `{env:NAME}` se resuelve contra el entorno real del proceso y una variable no definida se reemplaza por cadena vacía. El `.env` fue eliminado del kit. Las credenciales se administran con `opencode auth` o con variables de entorno de Windows.

### RF-05 — Cobertura obligatoria en las definiciones de agente (nuevo)

> **Todo MCP instalado y registrado en `opencode.json` debe estar declarado en la sección "Uso de MCPs" de los agentes que lo usan, con el nombre de sus herramientas. Un MCP instalado que ningún agente declara es una implementación incompleta: se corrige el agente, no se retira el MCP.**

El defecto que motivó el requisito: el 2026-10-18 se cruzaron los MCPs registrados contra las 32 definiciones de agente (`.github/agents/` y `.opencode/agents/`) y el resultado fue que **13 de 16 agentes declaraban solo 3 MCPs (`context-mode`, `codebase-memory-mcp`, `markitdown`) teniendo 8 instalados**. Solo `pensador` declaraba un cuarto. `tokenslayer`, `semgrep` y `context7` no aparecían en ningún agente.

La lectura errónea fue tratar ese cero como prueba de que los MCPs sobraban. La lectura correcta es la inversa: los agentes estaban incompletos.

### Reparto vigente (8 MCPs, 16 agentes)

**Transversales a los 16** — `context-mode`, `codebase-memory-mcp`, `markitdown`, `graphify`, `tokenslayer`.

| MCP | Agentes que lo declaran además de los transversales |
|---|---|
| `context7` | `Agent-SSD`, `analista_tecnico`, `api-developer`, `arquitecto`, `documentador`, `frontend-developer`, `pensador`, `plataformador`, `qa-senior`, `upgrade_framework` |
| `github` | `api-developer`, `devops`, `frontend-developer`, `gitflow`, `plataformador`, `security-auditor` |
| `playwright` | `devops`, `frontend-developer`, `qa-senior` |

`ssh-connection-agent` y `usuario-preferencias` no tenían sección de MCPs; se les agregó el bloque completo con los 5 transversales.

### RF-06 — Paridad entre arneses y verificación

> Los bloques MCP de `.github/agents/` y `.opencode/agents/` deben ser idénticos para el mismo agente. La verificación compara el bloque extraído de ambos archivos y exige 0 desajustes.

Aplicado el 2026-10-18 a los 32 archivos (16 agentes × 2 arneses): 0 desajustes, frontmatter intacto, UTF-8 sin BOM y finales de línea LF preservados.

### SC-04 — Nuevo criterio de éxito

- **SC-04**: Cada MCP de `opencode.json` aparece en al menos un bloque "Uso de MCPs" de agente. Cobertura al 2026-10-18: 8 de 8 MCPs declarados, con reparto transversal 5 + específico por rol.

### Pendiente

`semgrep` está instalado en la máquina y quedó fuera del reparto de RF-05 por decisión del usuario, que solo confirmó la devolución de `context7` y `tokenslayer`. Sigue abierta la decisión de readmitirlo, junto con su declaración en `security-auditor` y `qa-senior`, que son los dos agentes que lo usarían.
