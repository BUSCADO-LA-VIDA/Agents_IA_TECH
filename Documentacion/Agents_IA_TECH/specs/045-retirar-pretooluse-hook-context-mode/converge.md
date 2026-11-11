# Converge 045 — Retirar `PreToolUse` del hook `context-mode`

**Fecha**: 2026-11-11 · **Spec**: v2.0.0 · **Alcance**: regularización completa de una decisión ya aplicada

---

## 1. Resumen ejecutivo

La Spec 045 nació como hotfix: se retiró `PreToolUse` del registro de hooks editando el archivo, sin plan, tasks ni análisis, porque el arnés estaba bloqueado. Este ciclo convierte ese hotfix en una spec completa y descubre que **la decisión no estaba registrada donde corresponde**:

| Pieza | Estado real |
|---|---|
| Registro `.github/hooks/context-mode.json` | correcto (sin `PreToolUse`) |
| Generador `Ensure-ContextHooks` | **contradice la decisión**: sigue emitiendo `PreToolUse` |
| Validador `validar-mcps.ps1` | **contradice la decisión**: exige `PreToolUse` y falla hoy |
| Documentación | completa tras este ciclo |

Conclusión: la 045 no está cerrada. Está **especificada y documentada**, con dos tareas de código pendientes (T005, T006) que son las que hacen la decisión reproducible.

---

## 2. Consolidación de artefactos

| Artefacto | Contenido | Estado |
|---|---|---|
| `spec.md` v2.0.0 | Problema, evidencia (con versión y constante), alcance, RF-01..RF-07, AC-1..AC-9, riesgos, rollback, condición de re-habilitación, glosario | escrito |
| `plan.md` | Contexto técnico, constitution check, decisiones D1-D6, contratos de `Ensure-ContextHooks` y del validador, pruebas P1-P8, riesgos, orden de ejecución | escrito |
| `tasks.md` | 14 tareas en 5 fases, dependencias, paralelismo, estrategia y estado de cierre | escrito |
| `analyze.md` | Matriz RF→tarea→AC, hallazgos H1-H7, consistencia, STRIDE, veredicto | escrito |
| `converge.md` | Este documento | escrito |
| `bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md` | Diagnóstico original, rollback, seguimiento | existente, enlazado |
| `.github/hooks/context-mode.json.bak-20261109` | Las tres etapas anteriores | versionado como evidencia |

---

## 3. Matriz de cobertura

| RF | Tarea | AC | Evidencia disponible | Cubierto |
|---|---|---|---|---|
| RF-01 | T004 | AC-1 | `hooks.PSObject.Properties.Name` → `PostToolUse`, `SessionStart` | sí |
| RF-02 | T004 | AC-1 | igual al anterior | sí |
| RF-03 | T004b | AC-3 | `.bak-20261109` contiene `PreToolUse`, `PostToolUse`, `SessionStart` | sí |
| RF-04 | T001-T003, T010 | AC-5 | bitácora + §2 del spec | sí |
| RF-05 | T005, T007 | AC-6, AC-9 | — | **no** |
| RF-06 | T006, T008 | AC-7 | — | **no** |
| RF-07 | T011 | — | §7 del spec con comandos | sí |

Cobertura: **5/7 RF verificados**, 2/7 pendientes de código.

---

## 4. Resultados de los criterios de aceptación

| AC | Criterio | Resultado | Evidencia |
|---|---|---|---|
| AC-1 | Registro sin `PreToolUse` | **PASS** | claves del JSON: `PostToolUse`, `SessionStart` |
| AC-2 | JSON válido | **PASS** | `ConvertFrom-Json` sin error |
| AC-3 | Respaldo con 3 etapas | **PASS** | `.bak-20261109` leído |
| AC-4 | Lectura > 16 KB no denegada | **PENDIENTE** | requiere recargar la ventana del arnés; no verificable por el agente |
| AC-5 | Rollback documentado | **PASS** | §6 del spec + bitácora §Rollback |
| AC-6 | Generador sin `PreToolUse` | **FAIL (abierto)** | `Ensure-ContextHooks` L1445 aún lo declara |
| AC-7 | Validador alineado con la decisión | **FAIL (abierto)** | `validar-mcps.ps1` L230-235 lo exige; hoy imprime `[FAIL] Falta hook 'PreToolUse'` |
| AC-8 | Portabilidad 16/16 | **PASS** | `tests/validate-no-hardcoded-paths.Tests.ps1` |
| AC-9 | Registro ≡ salida del generador | **PENDIENTE** | depende de T005 |

**Resumen**: 5 PASS · 1 pendiente manual · 2 FAIL abiertos · 1 pendiente por dependencia.

---

## 5. Hallazgos nuevos (posteriores a `analyze.md`)

| ID | Hallazgo | Consecuencia |
|---|---|---|
| H8 | El nombre anterior (`...lecturas-bloqueadas`) ya estaba referenciado en `CHANGELOG.md`, `00-indice.md` y `pendientes-implementacion.md` | Se actualizan las tres referencias; el título histórico del CHANGELOG se conserva |
| H9 | `validar-mcps.ps1` no solo exige `PreToolUse`: también reporta `[FAIL]` por MCP no registrados en `.vscode/mcp.json` | Refuerza que H7 pertenece a la 046; el validador es hoy un semáforo en rojo permanente y eso le resta valor |
| H10 | El conteo de tareas de la spec anterior no existía (solo RF) | `pendientes-implementacion.md` citaba "5 de la 045 (RF)"; ahora hay 14 tareas reales con estado |

---

## 6. Archivos del cambio

| Archivo | Acción |
|---|---|
| `specs/045-hook-context-mode-lecturas-bloqueadas/` → `specs/045-retirar-pretooluse-hook-context-mode/` | renombre con `git mv` |
| `specs/045-.../spec.md` | reescrito (v1.0.0 → v2.0.0) |
| `specs/045-.../plan.md` | nuevo |
| `specs/045-.../tasks.md` | nuevo |
| `specs/045-.../analyze.md` | nuevo |
| `specs/045-.../converge.md` | nuevo |
| `00-indice.md` | título, ubicación, estado y artefactos de la sección 045 |
| `pendientes-implementacion.md` | fila 045, fase actual y conteo de tareas |
| `CHANGELOG.md` | ruta del artefacto en la entrada 1.2.0 |
| `bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md` | enlace a esta spec y al hallazgo H1 |

Sin cambios en código: la escritura de `Ensure-ContextHooks`, `validar-mcps.ps1` y la suite Pester queda delegada.

---

## 7. Tareas pendientes con causa

| Tarea | Causa | Responsable | Bloquea cierre |
|---|---|---|---|
| T005 | Requiere escribir en `scripts/` (fuera del dominio documental) | `developer` | sí |
| T006 | Igual | `developer` | sí |
| T007-T009 | Dependen de T005/T006 | `developer` | sí |
| T012 | Requiere recargar el arnés y abrir un documento grande | usuario | no (se declara pendiente) |

---

## 8. Veredicto

**La 045 queda especificada y documentada, no terminada.**

- Lo que se decidió (retirar `PreToolUse`) está aplicado en el registro y respaldado con evidencia reproducible.
- Lo que falta no es cosmético: el generador y el validador siguen afirmando lo contrario. Un `bootstrap -Force` reintroduce la etapa que bloqueaba el trabajo, y el validador marca FAIL en cada corrida.
- Con T005-T009 en verde y AC-4 confirmado, la spec pasa a `Cerrada` sin cambios adicionales.

**Estado propuesto**: `Aprobada — v2.0.0`, con `Implementación parcial (T005-T009 pendientes)`.

**No se archiva**: la spec permanece activa en `specs/` hasta cumplir su definición de terminado.
