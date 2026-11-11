# Spec 046 — Generación portable de `opencode.json` (maestro sin rutas y regeneración por destino)

**Feature Branch**: `046-generacion-portable-opencode-json`

**Created**: 2026-11-09

**Status**: **Borrador** — pendiente de aprobación para pasar a `plan.md`.

**Input**: Instrucción del usuario (2026-11-09): _"`opencode.json` no se versiona, se debe crear basado en su script, que se ejecuta al actualizar o plataformar o al ejecutarse individual, con la configuración correspondiente. Esto está hecho, puede validarlo"_. La validación confirmó que la generación existe y funciona, pero que el contenido generado hereda rutas absolutas del maestro.

**Relación con otras specs**:

| Spec | Relación |
|---|---|
| 038 (D2) | Ejecuta la parte pendiente de D2: maestro portable + generación por destino |
| 044 | Sacó `opencode.json` del índice y versionó `opencode.template.json`; esta spec cierra el circuito de generación |
| 020-T016 | Resuelve el pendiente de portabilidad de `graphify` |
| 036 (D5) | Consolida la entrada canónica de `graphify` y su ruta por destino |

---

## 1. Qué está implementado (validado)

| Pieza | Ruta | Función |
|---|---|---|
| Generador/merge | `scripts/sync/mcp/lift-opencode.ps1` | Crea `opencode.json` desde el maestro si falta; agrega `mcp` si falta; repara entradas con `command[0]` inexistente |
| Orquestación | `scripts/sync-kit-agents.ps1` (capa `mcp-lift-opencode`, F2) | Invoca con `-StageDir <kit> -RootPath <proyecto>` |
| Claves gestionadas | `scripts/sync/opencode/sync-opencode-config.ps1` | `$schema`, `instructions`, `default_agent` |
| Entrada graphify | `scripts/sync-mcp-graphify.ps1` | Consolida una sola entrada |
| Tokens + arranque | `scripts/plataformador-bootstrap.ps1` (`Ensure-OpenCodeMcp`) | Plantilla `{env:...}` + re-resolución a rutas locales + `default_agent` |

**Validación ejecutada**: destino temporal vacío, `-StageDir <kit>`. Resultado: archivo creado, `default_agent = pensador`, 8 entradas `mcp.servers`, `RESULT:mcp-opencode:anadidas`, backup previo cuando el archivo existe.

## 2. Defectos detectados

| ID | Defecto | Evidencia | Impacto |
|---|---|---|---|
| G1 | El generado hereda `command[]` del maestro tal cual | entradas con rutas absolutas del autor en el destino | Recontaminación del repo del consumidor; MCP caídos en otra máquina |
| G2 | `graphify` no se regenera al destino | `graphify` apunta a `<KIT_ROOT>/graphify-out/graph.json` en un proyecto distinto | El MCP sirve el grafo del kit |
| G3 | `tokenslayer` apunta a la ruta absoluta del kit | `node <KIT_ROOT>/proyect_ext/.../index.js` | No existe en otro proyecto |
| G4 | El bootstrap no crea el archivo si falta y no hay plantilla | rama `else` de `Ensure-OpenCodeMcp` | Un clon sin sync previo queda sin `opencode.json` |
| G5 | El resolvedor de `Ensure-OpenCodeMcp` itera `mcp.<nombre>` (forma legacy) y **no ve** `mcp.servers.<nombre>` | archivo real con `mcp.servers`: la entrada rota nunca se repara | El generador no corrige nada de lo que sí usa OpenCode 2 |
| G6 | `context-mode` 2.x cambió de layout: el bin es el CLI y el servidor MCP es `server.mjs --agent <id>` | `Cannot find module .../build/cli.js` | MCP caído y el generador lo reproduce |
| G7 | `markitdown-mcp 0.0.1a8` exige `mcp>=2.1.1`, pero `gptme` exige `mcp<2` | `ModuleNotFoundError: mcp.server.mcpserver` | Dos paquetes incompatibles: el pin del kit (`0.0.1a3`) es la salida |
| G8 | `.mcp.json` usa `context-mode`, `npx` y `${workspaceFolder}` | spawn real: `ENOENT` para shims; `${...}` no se expande | MCP de VS Code caídos: los nombres "portables" no son ejecutables |
| G9 | Hay artefactos generados que siguen **versionados**: `.vscode/mcp.json` e `index-preflight.md` | la corrida T019 los reescribió (el primero con rutas absolutas) y hubo que restaurarlos | Churn en cada corrida y riesgo de contaminar el repo: deben dejar de versionarse o estabilizarse |

## 3. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01 | El maestro de generación es `opencode.template.json` (portable), no el `opencode.json` resuelto del kit | **Must** |
| RF-02 | El generador escribe tokens `{env:...}` y `enabled: false` cuando el destino no tiene el archivo | **Must** |
| RF-03 | La re-resolución a rutas locales ocurre solo en el destino, contra `.env.mcp`/entorno, con `enabled: true` si resuelve | **Must** |
| RF-04 | `graphify` se regenera con `$RootPath` del destino (`<proyecto>/graphify-out/graph.json`) | **Must** |
| RF-05 | `tokenslayer` se registra con ruta relativa al proyecto si el directorio existe; si no, `enabled: false` + WARN | **Must** |
| RF-06 | Si no hay `opencode.json`, el bootstrap lo genera desde la plantilla (con o sin sync previo) | **Must** |
| RF-07 | Round-trip JSON con `-Depth` suficiente; si el resultado no parsea, no se escribe y se emite ERROR | **Must** |
| RF-08 | Backup previo en `<Root>/.kit-backup/<timestamp>/` antes de cualquier escritura | **Must** |
| RF-09 | El generado no contiene rutas absolutas de la máquina que lo generó, salvo las que resuelva la re-resolución local explícita | **Should** |
| RF-10 | Modo `-DryRun` sin escrituras y con reporte de claves que cambiarían | **Must** |

## 4. Criterios de aceptación

| ID | Criterio | Verificación |
|---|---|---|
| AC-1 | Destino vacío → `opencode.json` creado con 8 MCP y `default_agent: pensador` | ejecución en directorio temporal |
| AC-2 | El archivo generado **no** contiene rutas del kit ni del autor antes de la re-resolución | `Select-String` sobre el generado |
| AC-3 | `graphify` apunta a `<RootPath>/graphify-out/graph.json` | inspección del `command` |
| AC-4 | `tokenslayer` relativo o `enabled:false` con WARN | inspección + salida |
| AC-5 | Sin `opencode.json` y con plantilla, el bootstrap lo crea | ejecución del bootstrap en temporal |
| AC-6 | JSON final válido o no se escribe | `ConvertFrom-Json` + caso negativo |
| AC-7 | Backup creado antes de escribir | `Test-Path .kit-backup/<ts>` |
| AC-8 | `-DryRun` no escribe y reporta cambios | mtime sin cambios |

## 5. Tareas

| ID | Tarea | Agente |
|---|---|---|
| T01 | Maestro = `opencode.template.json` en `lift-opencode.ps1` (fallback al maestro actual si no existe) | `plataformador` |
| T02 | Regenerar `graphify` con `$RootPath` del destino | `plataformador` |
| T03 | `tokenslayer` relativo o degradado con WARN | `plataformador` |
| T04 | Bootstrap: generar desde plantilla cuando falta el archivo | `plataformador` |
| T05 | Test Pester: generación en temporal, AC-1..AC-4 | `qa-senior` |
| T06 | Test de no-regresión: `opencode.json` del kit sigue funcionando | `qa-senior` |
| T07 | Documentar en `generacion-opencode-json.md` el flujo final | `documentador` |

## 6. Riesgos

| Riesgo | Mitigación | Rollback |
|---|---|---|
| Cambiar el maestro altera el contenido generado en proyectos ya nivelados | `-DryRun` primero; backup por corrida | restaurar desde `.kit-backup/<ts>` |
| Tokens `{env:...}` no resueltos dejan MCP deshabilitados | El resolvedor del bootstrap promueve a `enabled:true`; var ausente = degradado con WARN | `git checkout` del generado |
| `graphify` relativo depende de `cwd` = raíz del proyecto | Verificar con ejecución real; si no, dejar absoluto resuelto por el bootstrap | mismo |

## 7. Regla de oro (vinculante)

Un artefacto generado **no se edita a mano**. `opencode.json`, `.env.mcp` y `.vscode/mcp.json` son *salida* de los scripts.

| Situación | Acción correcta | Acción prohibida |
|---|---|---|
| Falta una entrada o está mal en `opencode.json` | Ajustar el generador (`Ensure-OpenCodeMcp`, `lift-opencode`, `sync-opencode-config`) y volver a generarlo | Editar el JSON del proyecto |
| Una ruta de MCP cambió | Ajustar el resolvedor y `.env.mcp` (fuente), regenerar | Poner la ruta a mano |
| Hace falta verificar | Ejecutar el generador en un temporal y **probar la salida** | Copiar el archivo corregido de otra máquina |

Estado local no reproducible (2026-11-11): la entrada `context-mode` del `opencode.json` del proyecto se corrigió a mano para desbloquear el arnés. Se considera deuda: T019 la regenera con el script y T013-T018 lo prueban.

## 8. Estado

- Generación: implementada y validada (§1).
- Portabilidad del contenido generado: **no resuelta** (G1-G8).
- Esta spec es la que cierra el circuito; no se implementa sin aprobación.
