# Spec 045 — Hook `context-mode` bloqueaba lecturas y se reportaba como caída total de herramientas

**Feature Branch**: `045-hook-context-mode-lecturas-bloqueadas`

**Created**: 2026-11-09

**Status**: **Implementada v1.0.0 (hotfix aplicado)** — regulariza un cambio ya ejecutado para desbloquear el trabajo; pendiente de decisión sobre re-habilitación condicionada (§7).

**Input**: Reporte del usuario durante la implementación de la Spec 044: _"el hook `.github/hooks/context-mode.json` rechazó las herramientas, incluidas las consultas a GitHub Actions… es necesario corregir el hook o habilitar las herramientas"_.

---

## 1. Problema

El registro de hooks del arnés VS Code Copilot declaraba tres etapas: `PreToolUse`, `PostToolUse` y `SessionStart`. La etapa `PreToolUse` puede devolver `permissionDecision: "deny"` y, de hecho, denegaba sistemáticamente cualquier lectura de archivo por encima de un umbral interno.

## 2. Evidencia recogida

| Comprobación | Resultado |
|---|---|
| `Read` de archivo < 16 KB | allow |
| `Read` de un documento de 39 590 bytes | **deny** |
| `Edit` | allow |
| `Bash` (`git status`) | allow |
| `mcp__github__list_workflows` | allow |

Salida del deny:

```
context-mode: 39590-byte file, over the one-read limit.
Run ctx_execute(language, code, file="...") and print only the answer.
```

Código instalado (`node_modules/context-mode/hook.mjs`):

| Dato | Valor |
|---|---|
| Constante del límite | `q = 16384` (16 KB) |
| Configurabilidad | **Ninguna**: no existe variable `CM_*` para el umbral (solo `CM_HOOK_FAULT`) |
| Único punto que puede denegar | etapa `PreToolUse` |

**Causa raíz**: no era un hook roto. Aplicaba una política de "una sola lectura por archivo" con techo de 16 KB, pensada para forzar `ctx_execute`. En un kit documental (specs y bitácoras de decenas de KB) eso bloquea el flujo normal, y el agente lo interpretó como fallo general del arnés.

## 3. Solución aplicada

| Archivo | Cambio |
|---|---|
| `.github/hooks/context-mode.json` | Se retira **solo** `PreToolUse`; se conservan `SessionStart` y `PostToolUse` |
| `.github/hooks/context-mode.json.bak-20261109` | Respaldo del registro anterior |
| `Documentacion/Agents_IA_TECH/bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md` | Bitácora de la intervención |

## 4. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01 | El registro de hooks no puede denegar lecturas por tamaño en este repo | **Must** — cumplido |
| RF-02 | Se conserva la inyección de contexto (`SessionStart`) y el post-procesado (`PostToolUse`) | **Must** — cumplido |
| RF-03 | Debe existir respaldo del registro previo y rollback documentado | **Must** — cumplido |
| RF-04 | La razón de la retirada queda registrada en bitácora con evidencia reproducible | **Must** — cumplido |
| RF-05 | Re-habilitar `PreToolUse` solo si el umbral es configurable o supera el tamaño de la documentación del kit | **Should** — pendiente (§7) |

## 5. Criterios de aceptación

| ID | Criterio | Verificación | Estado |
|---|---|---|---|
| AC-1 | `PreToolUse` no figura en el registro | lectura del JSON | cumplido |
| AC-2 | El JSON es válido | `ConvertFrom-Json` | cumplido |
| AC-3 | Respaldo presente | `Test-Path .github/hooks/context-mode.json.bak-20261109` | cumplido |
| AC-4 | Las lecturas grandes ya no se deniegan | lectura de un `.md` > 16 KB tras recargar ventana | **pendiente de recarga del arnés** |
| AC-5 | Rollback documentado | bitácora §Rollback | cumplido |

## 6. Riesgos y rollback

| Riesgo | Mitigación |
|---|---|
| Se pierde la capa que obligaba a `ctx_execute` en lecturas grandes | `ctx_search`/`ctx_execute` siguen disponibles como MCP; la política no era un control de seguridad |
| El arnés no relee hooks hasta reiniciar | Documentado: requiere recargar la ventana de VS Code |

Rollback:

```powershell
Copy-Item .github/hooks/context-mode.json.bak-20261109 .github/hooks/context-mode.json -Force
```

## 7. Seguimiento

Re-habilitar `PreToolUse` requiere una de estas dos condiciones:

1. Que `context-mode` exponga el umbral por configuración (variable de entorno o archivo de config del proyecto).
2. Que el umbral por defecto sea mayor que el tamaño máximo de los documentos del kit.

Mientras no se cumpla ninguna, el registro queda sin `PreToolUse` por diseño y esta spec documenta el motivo.
