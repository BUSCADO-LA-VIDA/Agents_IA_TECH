# Spec 045 — Retirar `PreToolUse` del hook `context-mode`

**Feature Branch**: `045-retirar-pretooluse-hook-context-mode`

**Created**: 2026-11-09 · **Renombrada y completada**: 2026-11-11

**Status**: **Aprobada — v2.0.0**. Ciclo Speckit completo (specify → plan → tasks → analyze → converge). La retirada está aplicada en el registro; la política aún no vive en el generador ni en el validador (RF-05/RF-06, tareas T005/T006).

**Input**: reporte del usuario durante la implementación de la Spec 044: _"el hook `.github/hooks/context-mode.json` rechazó las herramientas, incluidas las consultas a GitHub Actions… es necesario corregir el hook o habilitar las herramientas"_.

**Renombre (2026-11-11)**: la carpeta se llamaba `045-hook-context-mode-lecturas-bloqueadas`, nombre que describía el **síntoma** (lecturas bloqueadas). El slug vigente describe la **decisión**: retirar la etapa `PreToolUse` del registro. Motivo: en este kit los slugs de spec nombran el cambio (`039-eliminar-rutas-hardcoded-documentacion`, `046-generacion-portable-opencode-json`), no el defecto.

---

## 1. Problema

El registro de hooks del arnés VS Code Copilot declaraba tres etapas: `PreToolUse`, `PostToolUse` y `SessionStart`.

La etapa `PreToolUse` puede devolver `permissionDecision: "deny"`. En la versión instalada de `context-mode` esa etapa denegaba cualquier `Read` de archivo por encima de **16 384 bytes**, con una política de "una sola lectura por archivo" pensada para forzar `ctx_execute`.

En un kit documental, donde las specs y bitácoras superan con frecuencia los 30 KB, la política bloquea el trabajo normal. El agente interpretó el bloqueo como una caída total de herramientas y lo reportó así al usuario.

### 1.1 Qué no era

| Hipótesis | Verificación | Conclusión |
|---|---|---|
| "Todas las herramientas rechazadas" | `Edit`, `Bash` y `mcp__github__list_workflows` respondían `allow` | Solo se denegaba `Read` de archivos grandes |
| "El hook está roto" | El hook devolvía la decisión esperada según su política | No estaba roto: aplicaba su diseño |
| "Falla GitHub Actions" | Las consultas MCP a GitHub nunca pasaron por `PreToolUse` | Afirmación incorrecta del reporte original |

---

## 2. Evidencia

Todo lo que sigue fue observado en esta máquina, no inferido. Se conserva la versión exacta del paquete porque la conclusión depende de ella.

### 2.1 Comportamiento observado (2026-11-09)

| Comprobación | Resultado |
|---|---|
| `Read` de archivo < 16 KB | `allow` |
| `Read` de un documento de 39 590 bytes | **`deny`** |
| `Edit` | `allow` |
| `Bash` (`git status`) | `allow` |
| `mcp__github__list_workflows` | `allow` |

Salida del `deny`:

```
context-mode: 39590-byte file, over the one-read limit.
Run ctx_execute(language, code, file="...") and print only the answer.
```

### 2.2 Configurabilidad del umbral

| Dato | Valor | Fuente |
|---|---|---|
| Constante del límite | `16384` (16 KB) | `hook.mjs` del paquete instalado |
| Variable de entorno para el umbral | **ninguna** | solo existe `CM_HOOK` para fallos del propio hook |
| Única etapa que puede denegar | `PreToolUse` | `Ll = { PreToolUse: [...] }` en `hook.mjs` |
| Versión inspeccionada | `context-mode 2.1.0` | `package.json` del paquete global |

La constante `16384` **sigue presente en 2.1.0**: la condición de re-habilitación (§7) no se ha cumplido con la versión actual.

### 2.3 Naturaleza del artefacto

`.github/hooks/context-mode.json` **está versionado** (`git ls-files`) **y es generado** por `Ensure-ContextHooks` (`scripts/plataformador-bootstrap.ps1`, L1436-1477). Esa función escribe las tres etapas, incluida `PreToolUse`:

```powershell
$hooksJson = [ordered]@{
    hooks = [ordered]@{
        PreToolUse   = @(@{ type = "command"; command = "context-mode hook vscode-copilot pretooluse" })
        PostToolUse  = @(@{ type = "command"; command = "context-mode hook vscode-copilot posttooluse" })
        SessionStart = @(@{ type = "command"; command = "context-mode hook vscode-copilot sessionstart" })
    }
}
```

Consecuencia: retirar `PreToolUse` **solo del archivo** es una corrección que el propio kit revierte en cuanto se ejecuta el bootstrap con `-Force` o en un clon nuevo donde el archivo no exista. La política debe vivir en el generador.

### 2.4 Contradicción con el validador

`scripts/validar-mcps.ps1` (L230-235) exige las tres etapas:

```powershell
$hookTypes = @("PreToolUse", "PostToolUse", "SessionStart")
foreach ($hookType in $hookTypes) {
    if ($hooks.hooks.$hookType) { Write-Ok "Hook '$hookType' configurado" }
    else { Write-Fail "Falta hook '$hookType' en $hooksPath" }
}
```

Corrida real del 2026-11-11 sobre el repo:

```
[FAIL] Falta hook 'PreToolUse' en .github/hooks/context-mode.json
Resultado: HAY FALLOS.
```

Es decir: el kit se contradice a sí mismo. El registro aplica una decisión y el validador la declara incumplimiento.

---

## 3. Alcance

El alcance se define por un criterio único: **qué debe cambiar para que la decisión sea reproducible y verificable**. Todo lo que no cumple ese criterio queda fuera, aunque sea deuda conocida.

### 3.1 Dentro de alcance

| Elemento | Acción |
|---|---|
| `.github/hooks/context-mode.json` | Retirar `PreToolUse`; conservar `SessionStart` y `PostToolUse` |
| `.github/hooks/context-mode.json.bak-20261109` | Conservar como evidencia del estado anterior (3 etapas) |
| `Ensure-ContextHooks` (bootstrap) | Emitir el registro **sin** `PreToolUse` (fuente de verdad de la política) |
| `scripts/validar-mcps.ps1` | Dejar de exigir `PreToolUse`; pasar a exigir su **ausencia** como guard de regresión |
| Bitácora de la intervención | Conservar y enlazar desde esta spec |
| Esta spec y sus artefactos | `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `converge.md` |

### 3.2 Fuera de alcance (con motivo)

| Elemento | Motivo |
|---|---|
| Re-habilitar `PreToolUse` | Requiere umbral configurable (§7). Mientras no exista, la decisión es retirarlo |
| Deriva de versiones en `validar-mcps.ps1` (`context-mode` 1.0.169 vs 2.1.0; `codebase-memory-mcp` 0.9.0 vs 0.10.8; `markitdown` 0.1.7 vs 0.1.8) | Es un defecto del validador, no del hook. Se registra como hallazgo H3 y se trata fuera de esta spec |
| Registro de los 3 MCP en `.vscode/mcp.json` que el validador echa en falta | Pertenece a la spec **046** (generación portable y `.mcp.json` ejecutable) y a G8/G9 |
| `opencode.json` y su generación | Spec **046** |
| Hooks equivalentes en otros arneses | Solo VS Code Copilot declara este registro (`context-mode hook vscode-copilot ...`); no hay equivalente en OpenCode |

---

## 4. Requisitos funcionales

| ID | Requisito | Prioridad | Estado |
|---|---|---|---|
| RF-01 | El registro `.github/hooks/context-mode.json` no declara `PreToolUse` | **Must** | cumplido (edición manual 2026-11-09) |
| RF-02 | Se conservan `SessionStart` (inyección de contexto) y `PostToolUse` (post-procesado) | **Must** | cumplido |
| RF-03 | Existe respaldo del registro anterior y rollback reproducible | **Must** | cumplido (`.bak-20261109`) |
| RF-04 | La razón de la retirada queda registrada con evidencia reproducible | **Must** | cumplido (bitácora + §2) |
| RF-05 | La política vive en el generador: `Ensure-ContextHooks` emite el registro sin `PreToolUse`; `-Force` y un clon nuevo reproducen la decisión | **Must** | **pendiente** (T005) |
| RF-06 | `validar-mcps.ps1` valida la política vigente: no falla por ausencia de `PreToolUse` y **falla si reaparece** | **Must** | **pendiente** (T006) |
| RF-07 | La condición para re-habilitar `PreToolUse` queda documentada y es verificable | **Should** | cumplido (§7) |

---

## 5. Criterios de aceptación

| ID | Criterio | Verificación | Estado |
|---|---|---|---|
| AC-1 | `PreToolUse` no figura en el registro | `ConvertFrom-Json` + comprobación de propiedad | cumplido |
| AC-2 | El JSON es válido | `Get-Content ... \| ConvertFrom-Json` | cumplido |
| AC-3 | El respaldo existe y contiene las 3 etapas | `Test-Path` + lectura del `.bak-20261109` | cumplido |
| AC-4 | Un `Read` de `.md` > 16 KB ya no se deniega | abrir un documento grande tras recargar la ventana del arnés | **pendiente** (requiere recarga, no verificable por el agente) |
| AC-5 | El rollback está documentado y es ejecutable | §6 de esta spec + bitácora §Rollback | cumplido |
| AC-6 | El generador produce el registro sin `PreToolUse` en un directorio temporal | ejecutar el bootstrap en temporal y leer la salida (no el archivo del proyecto) | **pendiente** (depende de T005) |
| AC-7 | El validador no falla por `PreToolUse` ausente y falla si se reintroduce | `validar-mcps.ps1` en verde sobre el repo + prueba negativa con el `.bak` sembrado | **pendiente** (depende de T006) |
| AC-8 | La suite de portabilidad sigue en verde | `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` → 16/16 | cumplido |
| AC-9 | El registro del repo es idéntico al que emite el generador | comparación byte a byte (normalizada) entre el archivo y la salida en temporal | **pendiente** (depende de T005 y T007) |

---

## 6. Riesgos y rollback

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Se pierde la capa que forzaba `ctx_execute` en lecturas grandes | alta | bajo | `ctx_search`/`ctx_execute` siguen disponibles como MCP; la política no era un control de seguridad, era una preferencia de consumo de tokens |
| El arnés no relee hooks hasta reiniciar | alta | medio | AC-4 documentado como verificación manual tras recarga |
| Un `bootstrap -Force` restaura `PreToolUse` | **alta mientras no se implemente RF-05** | alto | T005 mueve la política al generador; T007 prueba la salida generada |
| El validador marca FAIL en cada corrida | cierta hoy | medio | T006 alinea el validador con la decisión |
| Re-habilitar sin revisar el umbral | media | alto | §7 define la condición; `analyze.md` la convierte en guard |

Rollback (restaura las tres etapas y deja el validador en verde):

```powershell
Copy-Item .github/hooks/context-mode.json.bak-20261109 .github/hooks/context-mode.json -Force
```

Rollback completo (incluye generador): revertir T005 y T006 en el mismo commit.

---

## 7. Condición de re-habilitación

`PreToolUse` vuelve al registro **solo** si se cumple una de estas dos condiciones:

1. `context-mode` expone el umbral por configuración (variable de entorno o archivo de config del proyecto), de modo que se pueda fijar por encima del tamaño típico de la documentación del kit.
2. El umbral por defecto supera el tamaño máximo real de los documentos del kit.

Verificación de la condición 1 (hoy **no** se cumple):

```powershell
# La constante sigue fija en el paquete instalado
Select-String -Path "$env:APPDATA\npm\node_modules\context-mode\hook.mjs" -Pattern '16384'
```

Verificación de la condición 2:

```powershell
# Documento versionado más grande del kit
git ls-files '*.md' | ForEach-Object { [pscustomobject]@{ F = $_; B = (Get-Item $_).Length } } |
    Sort-Object B -Descending | Select-Object -First 5
```

Mientras ninguna se cumpla, el registro queda sin `PreToolUse` **por diseño** y esta spec documenta el motivo. Re-habilitarlo exige **spec nueva** (regla: cambio nuevo = spec nueva), no una edición del JSON.

---

## 8. Artefactos

| Artefacto | Ubicación | Estado |
|---|---|---|
| Especificación | `specs/045-retirar-pretooluse-hook-context-mode/spec.md` | este archivo, v2.0.0 |
| Plan técnico | `specs/045-retirar-pretooluse-hook-context-mode/plan.md` | escrito |
| Tareas | `specs/045-retirar-pretooluse-hook-context-mode/tasks.md` | escrito |
| Análisis | `specs/045-retirar-pretooluse-hook-context-mode/analyze.md` | escrito |
| Convergencia | `specs/045-retirar-pretooluse-hook-context-mode/converge.md` | escrito |
| Bitácora de la intervención | `bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md` | existente |
| Respaldo del registro | `.github/hooks/context-mode.json.bak-20261109` | existente, versionado como evidencia |

---

## 9. Glosario

| Término | Definición en este contexto |
|---|---|
| `PreToolUse` | Etapa del hook que se ejecuta antes de una herramienta y puede devolver `deny`. Es la única con capacidad de bloqueo |
| `PostToolUse` | Etapa posterior a la herramienta; transforma o resume la salida, no bloquea |
| `SessionStart` | Etapa de arranque de sesión; inyecta el contexto inicial del proyecto |
| Artefacto generado | Archivo producido por un script (`Ensure-ContextHooks`, `Ensure-OpenCodeMcp`). No se edita a mano: se corrige el generador y se prueba la salida |
| Política de una lectura | Regla de `context-mode` que permite una sola lectura por archivo y redirige a `ctx_execute` cuando el archivo supera el umbral |
