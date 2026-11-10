# Plan 046 — Generación portable de `opencode.json`

**Feature Branch**: `046-generacion-portable-opencode-json`
**Spec**: `spec.md` (Borrador aprobado para planificar el 2026-11-10)
**Estado**: Aprobado para implementación

---

## 1. Resumen

La generación de `opencode.json` ya existe y funciona (§1 del spec, validada en un destino temporal). El problema no es la generación: es que **el maestro del que copia contiene las rutas absolutas del autor** y dos entradas (`graphify`, `tokenslayer`) se resuelven contra el kit en vez de contra el destino. Este plan convierte el generador en un generador **portable por destino**.

## 2. Contexto técnico

| Elemento | Valor |
|---|---|
| Runtime | PowerShell 7+ |
| Generador | `scripts/sync/mcp/lift-opencode.ps1` (capa `mcp-lift-opencode`) |
| Orquestador | `scripts/sync-kit-agents.ps1` (F2, `-StageDir <kit> -RootPath <proyecto>`) |
| Resolvedor de tokens | `scripts/plataformador-bootstrap.ps1` → `Ensure-OpenCodeMcp` |
| Fuente de rutas locales | `.env.mcp` (gitignored) |
| Salida | `<proyecto>/opencode.json` |
| Backup | `<proyecto>/.kit-backup/<timestamp>/` |
| Pruebas | Pester 6 (`tests/`) sobre directorios temporales |

## 3. Constitution check

| Principio | Cumplimiento |
|---|---|
| Portabilidad del kit | El archivo distribuible (`opencode.template.json`) no contiene rutas de máquina |
| Un solo responsable por capa | La generación vive en `lift-opencode.ps1`; el bootstrap solo resuelve tokens |
| Fail-closed en escritura | JSON inválido → no se escribe; backup previo obligatorio |
| Sin secretos versionados | Los valores reales viven en `.env.mcp` |
| Reproducibilidad | Todo el flujo se prueba en directorios temporales |

## 4. Diseño

### 4.1 Orden de resolución del maestro

```text
1) <StageDir>/opencode.template.json      <- fuente portable (nueva)
2) <StageDir>/opencode.json               <- compatibilidad (maestro actual)
3) Si no existe ninguno -> ERROR accionable (no escribir)
```

Regla: si el maestro es la plantilla, el generador **copia los tokens tal cual** y deja `enabled: false`. La promoción a rutas locales la hace el bootstrap contra `.env.mcp`, nunca el sync.

### 4.2 Contenido escrito por el generador

| Clave | Origen | Transformación |
|---|---|---|
| `$schema`, `instructions`, `default_agent` | maestro | copia; `default_agent` se corrige si es `build` o desconocido |
| `mcp.timeout` | maestro | copia |
| `permission` | destino | se conserva si existe; si no, se copia del maestro |
| `model`, `small_model`, `lsp` | destino | se conservan siempre (son locales del usuario) |
| `mcp.servers.<nombre>.command` | maestro | copia literal; si el maestro es la plantilla, queda el token |
| `mcp.servers.graphify.command[último]` | **regenerado** | `<RootPath>/graphify-out/graph.json` con separadores `/` |
| `mcp.servers.tokenslayer.command` | **regenerado** | ruta relativa al proyecto si `proyect_ext/tokenslayer/mcp-server/build/index.js` existe; si no, `enabled:false` + WARN |
| entradas con `command[0]` inexistente en disco | destino | reparadas desde el maestro (regla actual) |

### 4.3 Regla de `graphify`

```powershell
$graphRel = 'graphify-out/graph.json'
$graphAbs = (Join-Path $RootPath $graphRel) -replace '\\', '/'
# Solo se reescribe el ÚLTIMO argumento del command; el resto del command se respeta.
```

Si el comando no tiene forma reconocible (`... -m graphify.serve <ruta>`), no se toca y se emite WARN.

### 4.4 Regla de `tokenslayer`

```powershell
$tsRel = 'proyect_ext/tokenslayer/mcp-server/build/index.js'
if (Test-Path (Join-Path $RootPath $tsRel)) {
    command = @($nodeCmd, $tsRel); enabled = $true
} else {
    enabled = $false; WARN accionable
}
```

`$nodeCmd`: `node` si resuelve por `PATH`; si no, el del maestro. No se inventa una ruta absoluta nueva.

### 4.5 Generación en el bootstrap

`Ensure-OpenCodeMcp` ya copia la plantilla cuando falta el archivo (añadido en la 044). Se completa:

| Caso | Comportamiento |
|---|---|
| No hay `opencode.json` y hay plantilla | copia + resolvedor de tokens + `default_agent` |
| No hay `opencode.json` ni plantilla | ERROR accionable: "ejecuta el sync o trae la plantilla"; no escribir |
| Hay `opencode.json` sin `mcp` | agrega el bloque desde plantilla y resuelve |
| Hay `opencode.json` con `mcp` | re-resuelve tokens existentes, conserva el resto |

### 4.6 Garantías de escritura

| Garantía | Implementación |
|---|---|
| Backup | `<Root>/.kit-backup/<yyyyMMdd-HHmmss>/opencode.json` antes de escribir |
| JSON válido | round-trip con `-Depth 10`; si falla, no se escribe y se emite ERROR |
| DryRun | cero escrituras; reporta claves que cambiarían |
| Idempotencia | segunda corrida = 0 cambios (`RESULT:mcp-opencode:sin-cambios`) |

## 5. Archivos a modificar

| Archivo | Cambio | Riesgo |
|---|---|---|
| `scripts/sync/mcp/lift-opencode.ps1` | maestro con fallback a plantilla; `graphify` por destino; `tokenslayer` relativo | Medio |
| `scripts/plataformador-bootstrap.ps1` | rama "sin archivo y sin plantilla" con ERROR accionable | Bajo |
| `scripts/sync-mcp-graphify.ps1` | alinear la regeneración de ruta con 4.3 (misma regla) | Bajo |
| `opencode.template.json` | completar entradas y `enabled:false` coherentes | Bajo |
| `tests/generacion-opencode.Tests.ps1` | nuevo: AC-1..AC-5 en temporales | Bajo |
| `Documentacion/Agents_IA_TECH/generacion-opencode-json.md` | actualizar flujo final y estado | Bajo |

## 6. Estrategia de test

| Nivel | Qué prueba | Método |
|---|---|---|
| Unitario | `graphify` se regenera con `$RootPath` | destino temporal, inspección del `command` |
| Unitario | `tokenslayer` relativo o degradado | destino con y sin `proyect_ext/tokenslayer` |
| Integración | destino vacío → 8 MCP y `default_agent` | `lift-opencode.ps1 -StageDir <kit> -RootPath <tmp>` |
| Integración | plantilla como maestro → sin rutas absolutas en el generado | `Select-String` sobre el archivo |
| Integración | JSON inválido no se escribe | fixture corrupto + backup intacto |
| Regresión | `opencode.json` del kit sigue funcionando | arranque del arnés con el archivo resuelto |
| DryRun | no escribe | mtime antes/después |

## 7. Mapa de aceptación

| AC | Verificación |
|---|---|
| AC-1 | test de integración en temporal (8 MCP, `pensador`) |
| AC-2 | `Select-String` de los patrones de la 044 sobre el generado |
| AC-3 | inspección del `command` de `graphify` |
| AC-4 | inspección de `tokenslayer` + salida WARN |
| AC-5 | bootstrap en temporal sin `opencode.json` |
| AC-6 | fixture de JSON corrupto |
| AC-7 | `.kit-backup/<ts>/opencode.json` existe |
| AC-8 | mtime sin cambios con `-DryRun` |

## 8. Tareas

| ID | Tarea | Depende de |
|---|---|---|
| T01 | Maestro con fallback a `opencode.template.json` (4.1) | — |
| T02 | Regenerar `graphify` con `$RootPath` (4.3) | T01 |
| T03 | `tokenslayer` relativo o degradado (4.4) | T01 |
| T04 | Bootstrap: ERROR accionable cuando no hay plantilla (4.5) | T01 |
| T05 | `tests/generacion-opencode.Tests.ps1` (AC-1..AC-5) | T02, T03 |
| T06 | Test de no-regresión del `opencode.json` del kit | T05 |
| T07 | Actualizar `generacion-opencode-json.md` y el índice | T05 |

## 9. Riesgos y rollback

| Riesgo | Mitigación | Rollback |
|---|---|---|
| Un destino ya nivelado cambia de contenido | `-DryRun` primero; backup por corrida | restaurar desde `.kit-backup/<ts>/opencode.json` |
| `node` no resuelve por `PATH` en el destino | fallback al `node` del maestro; si tampoco, `enabled:false` + WARN | mismo |
| Regenerar `graphify` rompe una entrada custom | solo se toca el último argumento cuando la forma es reconocible | mismo |
| La plantilla y el maestro divergen | test que compara claves gestionadas entre plantilla y generado | `git checkout` de la plantilla |

## 10. Orden de ejecución

1. T01 (contrato del maestro).
2. T02 y T03 en paralelo (archivos y reglas independientes).
3. T04 (bootstrap).
4. T05 cubre T01-T03; T06 verifica que no se rompe lo existente.
5. T07 documenta el flujo final.

Cierre: `Invoke-Pester tests/generacion-opencode.Tests.ps1` en verde y `opencode.json` del kit sin cambios de comportamiento.
