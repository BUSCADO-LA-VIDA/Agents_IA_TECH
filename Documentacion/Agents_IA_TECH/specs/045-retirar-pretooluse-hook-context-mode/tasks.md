# Tasks 045 — Retirar `PreToolUse` del hook `context-mode`

**Spec**: `spec.md` v2.0.0 · **Plan**: `plan.md` · **Branch**: `045-retirar-pretooluse-hook-context-mode`

## Regla de oro (vinculante)

1. `.github/hooks/context-mode.json` es **artefacto generado** por `Ensure-ContextHooks`. No se edita a mano.
2. La política se cambia en el **generador** y se prueba **lo que genera** en un directorio temporal.
3. El validador se ajusta para **vigilar la decisión**, no para dejar de mirar.
4. Ninguna tarea se marca `[x]` sin evidencia de la salida real.

**Formato**: `- [ ] Txxx [RF] descripción | verificar: comando`

---

## Fase 0 — Evidencia (hecho)

- [x] T001 [RF-04] Registrar el comportamiento del hook de 2.1.0: único punto de `deny` = `PreToolUse`, umbral fijo `16384`, sin variable de entorno | verificar: `Select-String -Path "$env:APPDATA\npm\node_modules\context-mode\hook.mjs" -Pattern '16384|CM_HOOK'`
- [x] T002 [RF-04] Reproducir el bloqueo con un `Read` de 39 590 bytes y contrastar con `Edit`, `Bash` y MCP GitHub (todos `allow`) | verificar: bitácora `2026-11-09-hook-context-mode-bloqueo-read.md` §Diagnóstico
- [x] T003 [RF-04] Documentar la causa raíz: no era un hook roto, era su política de una lectura por archivo | verificar: `spec.md` §1.1

## Fase 1 — Registro sin `PreToolUse` (hecho)

- [x] T004 [RF-01, RF-02] Retirar `PreToolUse` del registro conservando `SessionStart` y `PostToolUse` | verificar: `(Get-Content .github/hooks/context-mode.json -Raw | ConvertFrom-Json).hooks.PSObject.Properties.Name` → `PostToolUse`, `SessionStart`
- [x] T004b [RF-03] Conservar el respaldo con las tres etapas | verificar: `(Get-Content .github/hooks/context-mode.json.bak-20261109 -Raw | ConvertFrom-Json).hooks.PSObject.Properties.Name` → `PreToolUse`, `PostToolUse`, `SessionStart`
- [x] T004c [RF-01] Verificar que el registro es JSON válido | verificar: `Get-Content .github/hooks/context-mode.json -Raw | ConvertFrom-Json`

## Fase 2 — Política en el código (pendiente · `developer`)

Estas dos tareas escriben en `scripts/`, fuera del dominio documental: se delegan en `developer` y no se ejecutan desde el `pensador`. Hasta que estén hechas, la decisión del registro no es reproducible.

- [ ] T005 [RF-05] `Ensure-ContextHooks` deja de emitir `PreToolUse` y añade el comentario de decisión con la condición de re-habilitación | verificar: bootstrap en temporal vacío → la salida no contiene la clave `PreToolUse`
- [ ] T006 [RF-06] `validar-mcps.ps1` (bloque 3) deja de exigir `PreToolUse`; pasa a exigirlo ausente y falla si reaparece, con mensaje que nombra la spec 045 | verificar: `pwsh -NoProfile -File scripts/validar-mcps.ps1` sin `[FAIL]` de hooks; luego, con el `.bak` sembrado, `[FAIL] PreToolUse reapareció`

## Fase 3 — Pruebas de la salida generada (pendiente · `developer`)

- [ ] T007 [RF-05, AC-6] `tests/hooks-context-mode.Tests.ps1`: P4 (temporal vacío → sin `PreToolUse`) y P5 (`.bak` sembrado + `-Force` → sigue sin `PreToolUse`) | verificar: `Invoke-Pester tests/hooks-context-mode.Tests.ps1` en verde
- [ ] T008 [RF-06, AC-7] Misma suite: P6 (validador en verde sobre el repo) y P7 (validador falla si `PreToolUse` reaparece) | verificar: ambas aserciones en verde
- [ ] T009 [AC-9] Comparar el registro del repo con la salida del generador (normalizada: sin BOM, sin CRLF, claves ordenadas) | verificar: comparación devuelve `$true`
- [ ] T009b [AC-8] Regresión de portabilidad | verificar: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` → 16/16

## Fase 4 — Cierre documental (parcial)

- [x] T010 [RF-04] Enlazar la bitácora existente con esta spec y dejar constancia del renombre | verificar: `bitacoras/2026-11-09-hook-context-mode-bloqueo-read.md` §Consecuencias
- [x] T011 [RF-07] Documentar la condición de re-habilitación con comandos verificables | verificar: `spec.md` §7
- [ ] T012 [AC-4] Verificar tras recargar la ventana del arnés que un `.md` > 16 KB se lee sin `deny` | verificar: abrir `specs/044-portabilidad-validacion-sin-exclusiones/spec.md` (20 KB) y comprobar que no hay `deny` — **requiere intervención del usuario**
- [ ] T013 Actualizar `00-indice.md`, `pendientes-implementacion.md` y `CHANGELOG.md` con el nombre nuevo y el estado real | verificar: `git grep -n "045-"` no muestra la ruta vieja
- [ ] T014 [AC-1..AC-9] `converge.md` firmado con la matriz de criterios y veredicto honesto | verificar: existe y declara el estado de cada AC

---

## Dependencias

| Tarea | Requiere |
|---|---|
| T005 | T004 (registro ya definido) |
| T006 | T005 (el validador vigila la política del generador) |
| T007 | T005 |
| T008 | T006 |
| T009 | T005 |
| T009b | independiente |
| T012 | intervención del usuario (recarga del arnés) |
| T013, T014 | T005, T006, T007, T008, T009 |

## Paralelismo

- T005 y T009b pueden ir en paralelo (archivos distintos).
- T006 y T007 comparten archivos: T007 consume la lógica de T006, por eso van en serie.
- T012 (manual) no bloquea T013/T014: se declara pendiente si no se ejecuta.

## Estrategia de implementación

1. `developer` aplica T005 y T006 en un solo commit temático (`fix(hooks): move PreToolUse policy into the generator`).
2. T007-T009 añaden la suite y la comparación generador↔repo.
3. `pensador` cierra T013/T014 y deja T012 en manos del usuario.
4. Ningún paso edita `.github/hooks/context-mode.json` a mano: el archivo ya está en el estado correcto y el generador debe reproducirlo.

## Estado de cierre

| Fase | Tareas | Hecho |
|---|---|---|
| 0 Evidencia | T001-T003 | 3/3 |
| 1 Registro | T004, T004b, T004c | 3/3 |
| 2 Código | T005, T006 | 0/2 |
| 3 Pruebas | T007, T008, T009, T009b | 0/4 |
| 4 Cierre | T010-T014 | 2/5 (T010, T011) |

**Total**: 8/14 tareas cerradas; 6 abiertas, de las cuales 4 son código (`developer`) y 2 requieren evidencia (T012 manual, T013/T014 dependen de las anteriores).
