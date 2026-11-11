# Bitácora: 2026-11-09 — El hook `context-mode` bloqueaba `Read` y se reportaba como "todas las herramientas rechazadas"

**Invocado por**: usuario (bloqueo reportado durante la implementación del Spec 044)
**Entorno**: VS Code Copilot (hooks de `.github/hooks/`), Windows, `context-mode` 2.1.0
**Problema**: un agente no pudo investigar ni corregir un fallo porque "el hook `.github/hooks/context-mode.json` rechazó las herramientas, incluidas las consultas a GitHub Actions".

## Diagnóstico

El hook registraba tres etapas, todas apuntando al CLI `context-mode`:

```json
{
  "hooks": {
    "PreToolUse":  [ { "command": "context-mode hook vscode-copilot pretooluse" } ],
    "PostToolUse": [ { "command": "context-mode hook vscode-copilot posttooluse" } ],
    "SessionStart":[ { "command": "context-mode hook vscode-copilot sessionstart" } ]
  }
}
```

Evidencia recogida con payloads reales contra `context-mode hook vscode-copilot pretooluse`:

| Herramienta probada | Resultado |
|---|---|
| `Read` de archivo pequeño (< 16 KB) | allow (stdout vacío, exit 0) |
| `Read` de `README.md` (39 590 bytes) | **deny** |
| `Edit` | allow |
| `Bash` (`git status`) | allow |
| `mcp__github__list_workflows` (GitHub Actions) | allow |

Salida del deny:

```text
context-mode: 39590-byte file, over the one-read limit.
Run mcp_context-mode_ctx_execute(language, code, file="...") and print only the answer.
```

Lectura del código instalado (`node_modules/context-mode/hook.mjs`):

- El límite es la constante `q = 16384` (16 KB), **hardcodeada**.
- No existe variable de entorno (`CM_*`) para ajustarlo; la única variable documentada es `CM_HOOK_FAULT`.
- El deny se emite como `permissionDecision: "deny"` desde la etapa `PreToolUse`.

**Causa raíz**: el hook no estaba roto. Aplicaba una política de "una sola lectura por archivo" con techo de 16 KB, pensada para forzar el uso de `ctx_execute`. En un kit documental (specs, bitácoras, ADRs de decenas de KB) esa política bloquea el flujo normal de lectura. El agente interpretó el deny como un fallo del hook y reportó "todas las herramientas rechazadas", cuando en realidad solo se denegaban las lecturas grandes.

## Solución aplicada

Se retiró **solo** la etapa `PreToolUse` del registro del hook (es la única que puede denegar una herramienta). Se conservan `SessionStart` (inyección de contexto) y `PostToolUse` (procesado de resultados).

Archivo modificado: `.github/hooks/context-mode.json`
Respaldo: `.github/hooks/context-mode.json.bak-20261109`

```json
{
  "hooks": {
    "PostToolUse": [ { "type": "command", "command": "context-mode hook vscode-copilot posttooluse" } ],
    "SessionStart":[ { "type": "command", "command": "context-mode hook vscode-copilot sessionstart" } ]
  }
}
```

## Verificación

| Comprobación | Resultado |
|---|---|
| JSON válido (`ConvertFrom-Json`) | OK |
| `PreToolUse` ya no está registrado | OK (solo quedan `PostToolUse` y `SessionStart`) |
| Respaldo del archivo previo | `.github/hooks/context-mode.json.bak-20261109` (365 bytes) |
| Payloads de `Edit`, `Bash` y MCP | allow (nunca estuvieron bloqueados) |

**Requiere recargar la ventana de VS Code** para que el arnés relea los hooks.

## Rollback

```powershell
Copy-Item .github\hooks\context-mode.json.bak-20261109 .github\hooks\context-mode.json -Force
```

## Consecuencias y seguimiento

- Se pierde la capa que obligaba a usar `ctx_execute` en lecturas grandes. No se pierde ninguna capacidad: `ctx_search`/`ctx_execute` siguen disponibles como MCP.
- Persisten `SessionStart` y `PostToolUse`, por lo que el contexto de sesión y el post-procesado de resultados siguen activos.
- Seguimiento propuesto (Spec 045): re-habilitar `PreToolUse` solo si el límite se puede configurar (variable de entorno o config del proyecto) y con un techo acorde al tamaño de la documentación del kit. Mientras el límite sea una constante interna de 16 KB, el registro queda deshabilitado por diseño y documentado aquí.

## Regularización como Spec 045 (2026-11-11)

Esta intervención se ejecutó como hotfix, sin ciclo Speckit previo. Se regulariza en la spec **`045-retirar-pretooluse-hook-context-mode`** (antes `045-hook-context-mode-lecturas-bloqueadas`), con:

| Artefacto | Contenido |
|---|---|
| `spec.md` v2.0.0 | Problema, evidencia, alcance, RF-01..RF-07, AC-1..AC-9, riesgos, rollback, condición de re-habilitación |
| `plan.md` | Decisiones D1-D6, contratos de `Ensure-ContextHooks` y de `validar-mcps.ps1`, pruebas P1-P8 |
| `tasks.md` | 14 tareas; 8 cerradas con evidencia, 6 abiertas |
| `analyze.md` | Cobertura RF→tarea→AC, hallazgos H1-H7, STRIDE, veredicto |
| `converge.md` | Matriz de AC y veredicto honesto (5 PASS, 2 FAIL abiertos, 2 pendientes) |

### Hallazgos que el hotfix no cubrió

| ID | Hallazgo | Consecuencia |
|---|---|---|
| H1 | `.github/hooks/context-mode.json` **es generado** por `Ensure-ContextHooks` (bootstrap L1436-1477), que sigue emitiendo `PreToolUse` | Un `bootstrap -Force` o un clon nuevo revierten esta intervención |
| H2 | `scripts/validar-mcps.ps1` (L230-235) **exige** `PreToolUse` y hoy imprime `[FAIL] Falta hook 'PreToolUse'` | El kit se contradice: el registro aplica la decisión y el validador la declara incumplimiento |

Ambos se corrigen moviendo la política al generador (T005) y alineando el validador como guard de regresión (T006). Hasta entonces, esta bitácora documenta una decisión que el propio kit no sostiene.

