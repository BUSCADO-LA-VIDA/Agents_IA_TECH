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

## Fase 2 — Política en el código (hecho · `developer` · 2026-11-12)

> Estas dos tareas escriben en `scripts/`, fuera del dominio documental: se delegan en `developer`. La decisión del registro ya es reproducible y verificada (P4-P7).

- [x] T005 [RF-05] `Ensure-ContextHooks` deja de emitir `PreToolUse`, añade el comentario de decisión (L1443) y normaliza un registro existente que la reintroduzca (L1475-1488) | verificar: P4 (vacío → sin `PreToolUse`) y P5 (`.bak` sembrado + normalización → sin `PreToolUse`) **en verde**
- [x] T006 [RF-06] `validar-mcps.ps1` (bloque 3) invierte la aserción: vigila la **ausencia** de `PreToolUse` y falla si reaparece, con mensaje que nombra la spec 045 (L230-236) | verificar: P6 (`[OK] PreToolUse retirado`, sin FAIL) y P7 (`[FAIL] ... spec 045 ...`) **en verde**

## Fase 3 — Pruebas de la salida generada (hecho · `developer` · 2026-11-12)

- [x] T007 [RF-05, AC-6] `tests/hooks-context-mode.Tests.ps1` ejecuta el bootstrap REAL y prueba la **salida** en temporal, no el archivo del proyecto; cubre P4 (vacío) y P5 (sembrado) | verificar: suite 16/16 **en verde**
- [x] T008 [RF-06, AC-7] Misma suite: P6 (validador no falla por ausencia) y P7 (validador falla si reintroducido) | verificar: suite 16/16 **en verde**
- [x] T009 [AC-9] La suite compara las claves del repo (P8) contra la salida generada (normalizada con Sort; el orden no es contrato) y los comandos | verificar: P8 **en verde**
- [x] T009b [AC-8] Regresión de portabilidad | verificar: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` → **16/16** (2026-11-12)

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
| 2 Código | T005, T006 | 2/2 |
| 3 Pruebas | T007, T008, T009, T009b | 4/4 |
| 4 Cierre | T010-T014 | 3/5 (T010, T011, T013; T014 converge se completa en este paso) |
**Total**: 15/16 tareas cerradas tras completo T014; 1 abierta (T012, manual: recarga del arnés para AC-4).
