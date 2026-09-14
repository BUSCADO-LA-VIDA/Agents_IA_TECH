# 🔧 Guía práctica: MCP `context-mode`

> Guía de **instalación, configuración, uso y mantenimiento** del servidor MCP `context-mode` en el kit Agents_IA_TECH.
> Esta guía NO cubre el desarrollo interno del MCP — solo su integración práctica en el kit.
> Fuente: https://github.com/mksglu/context-mode | Sitio: https://context-mode.com

---

## 1. Qué es y para qué sirve

`context-mode` es un **servidor MCP** que optimiza la ventana de contexto de los agentes de IA. En lugar de traer archivos, documentación o resultados de comandos completos al contexto, permite:

- **Indexar** documentación en un índice local FTS5 con ranking BM25 (búsqueda eficiente sin cargar todo).
- **Ejecutar** código en sandbox (solo el stdout entra al contexto).
- **Agrupar** múltiples comandos y búsquedas en una sola llamada.
- **Mantener** la continuidad de sesión y el estado del contexto.

**Datos clave**:

| Dato | Valor |
|------|-------|
| URL | https://github.com/mksglu/context-mode |
| Sitio | https://context-mode.com |
| Versión actual | v1.0.169 |
| Autor | Mert Köseoğlu (mksglu) |
| Licencia | **Elastic License 2.0 (ELv2)** — source-available, NO MIT |
| Lenguaje | TypeScript/JavaScript (Node.js ESM) |
| Requisito | **Node.js >= 22.5** (o Bun) |
| Instalación | `npm install -g context-mode` |
| Plataformas | VS Code Copilot, Claude Code, Gemini CLI, Cursor, OpenCode, JetBrains, GitHub Copilot CLI, Codex CLI, etc. |

> ⚠️ **Licencia ELv2**: es *source-available*, no open source en sentido estricto. No se puede ofrecer como SaaS ni quitar los avisos de licencia. Ver sección [Seguridad](#8-seguridad-de-uso).

---

## 2. Requisitos

- **Node.js >= 22.5** (o Bun). Verificar con:
  ```bash
  node --version
  ```
- Acceso a npm para la instalación global.
- VS Code con GitHub Copilot (para la configuración del kit).

---

## 3. Instalación

Instalar globalmente:

```bash
npm install -g context-mode
```

Verificar la instalación:

```bash
context-mode --version
```

---

## 4. Configuración en el kit

### 4.1 `.vscode/mcp.json`

Crear (o actualizar) el archivo `.vscode/mcp.json` en la raíz del proyecto:

```json
{
  "servers": {
    "context-mode": {
      "command": "context-mode",
      "type": "stdio"
    }
  }
}
```

> ⚠️ **`"type": "stdio"` es obligatorio** (decisión del usuario, 2026-09-12): especifica explícitamente el transporte del MCP. `stdio` (standard input/output) es el transporte por defecto para MCPs locales que se lanzan como proceso hijo vía `command`. Declararlo explícitamente hace la configuración más clara y evita ambigüedad si en el futuro se usara otro transporte (`sse`, `http`). **Incluirlo siempre al configurar `context-mode` en cualquier proyecto.**

### 4.2 Hooks de contexto

Crear el archivo `.github/hooks/context-mode.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "type": "command", "command": "context-mode hook vscode-copilot pretooluse" }
    ],
    "PostToolUse": [
      { "type": "command", "command": "context-mode hook vscode-copilot posttooluse" }
    ],
    "SessionStart": [
      { "type": "command", "command": "context-mode hook vscode-copilot sessionstart" }
    ]
  }
}
```

### 4.3 ⚠️ ADVERTENCIA: fusión de `copilot-instructions.md`

> **IMPORTANTE**: El routing de `context-mode` propone copiar su propio `copilot-instructions.md` encima de `.github/copilot-instructions.md`.

El kit **YA usa** `.github/copilot-instructions.md` como archivo **canónico de reglas base** (ver `AGENTS.md`). **NO sobrescribir** — hay que **FUSIONAR**:

1. Leer el `copilot-instructions.md` que propone `context-mode`.
2. Extraer solo las reglas de uso de las herramientas `ctx_*` y de mantenimiento.
3. Integrarlas en el `copilot-instructions.md` del kit **sin eliminar** las reglas base existentes (Ponytail, ECC, idioma, persistencia, seguridad, etc.).
4. Mantener `AGENTS.md` en sincronía con el archivo canónico.

> Regla del kit: `.github/copilot-instructions.md` es la fuente de verdad de reglas base. Cualquier integración externa debe **respetar y fusionar**, nunca reemplazar.

### 4.4 Reiniciar y verificar

1. Reiniciar VS Code.
2. En Copilot Chat, escribir `ctx stats` para verificar que el MCP responde.

---

## 5. Uso de las herramientas `ctx_*`

`context-mode` expone **11 herramientas** con prefijo `ctx_`:

| Herramienta | Qué hace |
|-------------|----------|
| `ctx_batch_execute` | Ejecuta múltiples comandos + búsquedas en UNA llamada (concurrencia 1-8) |
| `ctx_execute` | Ejecuta código en 12 lenguajes (JS, TS, Python, Shell, Ruby, Go, Rust, PHP, Perl, R, Elixir, C#). Solo el stdout entra al contexto |
| `ctx_execute_file` | Procesa archivos en sandbox. El contenido crudo nunca sale |
| `ctx_index` | Trocea markdown en FTS5 con ranking BM25 (títulos ponderados 5x, Porter stemming, corrección difusa) |
| `ctx_search` | Consulta contenido indexado con múltiples queries en una llamada |
| `ctx_fetch_and_index` | Fetch de URL → convierte a markdown → trocea → indexa. Cache TTL 24h |
| `ctx_stats` | Muestra ahorro de contexto, conteos de llamadas y estadísticas |
| `ctx_doctor` | Diagnostica instalación: runtimes, hooks, FTS5, versiones |
| `ctx_upgrade` | Actualiza a la última versión desde GitHub, reconstruye, reconfigura hooks |
| `ctx_purge` | Borra permanentemente todo el contenido indexado |
| `ctx_insight` | Abre el dashboard Insight alojado (analítica de org) |

---

## 6. Mantenimiento de uso

| Acción | Herramienta | Descripción |
|--------|-------------|-------------|
| **Limpiar historial** | `ctx_purge` | Borra permanentemente todo el contenido indexado |
| **Ver estadísticas** | `ctx_stats` | Ahorro de contexto, conteos de llamadas y estadísticas |
| **Actualizar** | `ctx_upgrade` | Actualiza a la última versión desde GitHub, reconstruye, reconfigura hooks |
| **Diagnosticar** | `ctx_doctor` | Diagnostica instalación: runtimes, hooks, FTS5, versiones |

---

## 7. Opciones óptimas con menor uso de IA

Para minimizar el consumo de tokens/IA, usar estas herramientas en lugar de leer archivos completos al contexto:

| Situación | Herramienta recomendada | Beneficio |
|-----------|------------------------|-----------|
| Ejecutar varios comandos/búsquedas | `ctx_batch_execute` | Agrupa en una sola llamada (concurrencia 1-8) |
| Analizar código sin traerlo al contexto | `ctx_execute` | "Think in code": programar el análisis en vez de leer archivos |
| Consultar documentación | `ctx_index` + `ctx_search` | Consulta docs sin traer todo al contexto (FTS5 + BM25) |
| Indexar docs externas | `ctx_fetch_and_index` | Fetch → markdown → índice con cache TTL 24h |

---

## 8. Seguridad de uso

- **Licencia ELv2**: source-available. No ofrecer como SaaS ni quitar avisos de licencia. Respetar los términos.
- **Ejecución sandbox**: `ctx_execute` / `ctx_execute_file` ejecutan código en sandbox; el contenido crudo no sale al contexto. Aun así, **no ejecutar código no confiable** sin revisión.
- **Fetch de URLs**: `ctx_fetch_and_index` descarga contenido externo. Tratar el contenido como **no confiable** (regla de prompt defense del kit).
- **Datos indexados**: `ctx_purge` borra permanentemente el contenido indexado. Usar con cuidado.
- **Dashboard Insight**: `ctx_insight` abre analítica alojada de org — revisar qué datos se comparten.

---

## 9. Validación de instalación y configuración

> **Script de validación**: `scripts/validar-mcps.ps1` (decisión del usuario, 2026-09-12).

Verifica que los MCPs del ecosistema de documentación sin IA estén **instalados, configurados y ejecutándose** correctamente. **Ejecutarlo siempre después de instalar o configurar los MCPs** en un proyecto.

### Qué valida

| # | Sección | Qué verifica |
|---|---------|--------------|
| 1 | Instalación y versión | Comando disponible en PATH + versión instalada vs. esperada (según `dependencias-manifest.yml`) |
| 2 | Configuración | `.vscode/mcp.json` con los MCPs registrados y `"type": "stdio"` presente |
| 3 | Hooks | `.github/hooks/context-mode.json` con `PreToolUse`, `PostToolUse`, `SessionStart` |
| 4 | Runtime | Ejecución real del MCP (responde sin colgarse) |

### Uso

```powershell
# Validación completa (instalación + configuración + runtime)
.\scripts\validar-mcps.ps1

# Validar un MCP específico
.\scripts\validar-mcps.ps1 -MCP context-mode
.\scripts\validar-mcps.ps1 -MCP codebase-memory-mcp,markitdown

# Omitir la prueba de runtime (más rápido)
.\scripts\validar-mcps.ps1 -SkipRuntime
```

### Exit codes

| Código | Significado |
|--------|-------------|
| `0` | Todos los MCPs validados correctamente |
| `1` | Al menos un MCP falló la validación |

### Notas técnicas

- **`context-mode --version` inicia el servidor MCP en modo stdio y se cuelga** (espera entrada). Por eso el script obtiene la versión del `package.json` del paquete npm global y usa `context-mode doctor` (que termina solo) para la prueba de runtime.
- **`markitdown --version`** imprime un warning de `pydub` (ffmpeg) antes de la versión; el script filtra la línea que contiene el patrón `X.Y.Z`.
- **`markitdown-mcp` no expone `--version`**; el script verifica la versión vía `pip show markitdown-mcp` y solo confirma que el binario existe en la prueba de runtime.
- En `.vscode/mcp.json`, el server de markitdown se llama `markitdown` (con command `markitdown-mcp`); `markitdown` (la librería CLI) no requiere registro en `mcp.json`.

---

## Referencias

- Repositorio: https://github.com/mksglu/context-mode
- Sitio oficial: https://context-mode.com
- Registro en el kit: `Documentacion/Agents_IA_TECH/referencias.md`
