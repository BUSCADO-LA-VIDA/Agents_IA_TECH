# Validación limpieza de regenerables incl. `.venv` (RF-15 / criterio 11) — `qa-senior` (tarea `[RELOCATE]`)

- **Fecha**: 2026-09-19
- **Agente**: `qa-senior` (validación formal independiente; bugs se REPORTAN, no se corrigen)
- **Alcance**: spec `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-15 + criterio nº 11) y checklist §5 de `seguridad/relocate-cleanup.md` (15 ítems)
- **Implementación validada**: `scripts/relocate-apps-to-src.ps1` (1733 líneas): `Find-RegenerableDirs` (L1075-1221), `Clear-RegenerableDirs` (L1234-1331), `Invoke-RegenerableCleanup` (L1350-1474), integración en MAIN L1523-1526, informe `.venv ELIMINADOS` L1699-1717; `param()` L41-46 (`-ProjectRoot`/`-AppDirs`/`-DryRun`)
- **Restricción cumplida**: cero borrados fuera de fixtures en `$env:TEMP\qa-relocate-cleanup` (limpiado después, verificado `Test-Path=False`); escrituras solo en este reporte + marca en `pendientes-implementacion.md`
- **Entorno**: pwsh 7.6.6 (Windows), `Parser::ParseFile` del script = **0 errores**

## 1. Sintaxis + carga segura — PASS

- `Parser::ParseFile('scripts/relocate-apps-to-src.ps1')` → **0 errores**.
- Dot-source carga `Find-RegenerableDirs`, `Clear-RegenerableDirs`, `Invoke-RegenerableCleanup` (`Get-Command` True ×3) y **nunca ejecuta el MAIN por cargar** (guard `if ($MyInvocation.InvocationName -ne '.')` L1731).

## 2. DryRun con fixtures señuelo — PASS

- Fixture `$env:TEMP\qa-relocate-cleanup\FixtureApp` con `__pycache__/`, `.pytest_cache/`, `node_modules/` (+ `package-lock.json`), `build/fuente.txt` (**commiteada en git**, repo init en el fixture), `.venv/` **sin manifiesto**, `dist-new/`, hija `Documentacion/notas.md`, `codigo.py`.
- `Find-RegenerableDirs` devolvió 5 entradas: `__pycache__`, `.pytest_cache`, `.venv` (`IsVenv=True`, `Manifest` vacío), `node_modules` (`NodeLock=package-lock.json`) como candidatas + `build` **EXCLUIDA** (`Excluded=True`, `Reason=versionado-no-se-toca`, con aviso "se EXCLUYE de la limpieza, no se toca; se mueve con la app"). `dist-new` y `Documentacion/` **ausentes** (sin substrings, sin recursivo ciego).
- E2E `-DryRun -AppDirs @('FixtureApp')`: resumen consolidado **ANTES** del plan (ruta relativa + nº archivos + MB + flags `SIN manifiesto (irreproducible)`, `lockfile: package-lock.json`, `Excluido (versionado, no se toca): FixtureApp\build`, avisos "`.venv` NUNCA entran en un 'si a todo'" y "si trabajas offline, di No"). Post-check: `src/` **no creado**, `__pycache__`/`.venv`/`build/fuente.txt`/`dist-new`/`Documentacion/notas.md` **intactos**.

## 3. Borrado real SOBRE FIXTURES + idempotencia — PASS

- Sobre `FixtureApp2` (`__pycache__/`, `.cache/`, `main.py`; interactivo simulado por override de `Test-IsInteractive` en sesión de fixture): `Clear-RegenerableDirs` → `Removed=2 Skipped=0`, ambas caches eliminadas, `main.py` **intacto**.
- Reintento inmediato → `Removed=0 Skipped=0` con "**ya limpio** (no existe); nada que borrar" por target, sin error (idempotente).

## 4. `.venv` activo y sin manifiesto — PASS

- **Activo simulado** (`$env:VIRTUAL_ENV` → `FixtureApp\.venv`, restaurado después, verificado vacío): `Find` marca `IsActive=True`; `Clear` → `Removed=0 Skipped=1` con "`.venv ACTIVADO` en esta terminal -> exige '`deactivate`' previo verificado (RF-14). Se SALTA este `.venv`, no se borra (**fail-closed**)", `pyvenv.cfg` **intacto**.
- **Sin manifiesto**: aviso + confirmación separada + rescate verificados por código L1452-1466 (warn "**IRREPRODUCIBLE**", comando `pip freeze` de rescate a `requirements-rescate-<fecha>.txt` ANTES de borrar, `Read-Host "¿Eliminar el .venv…?"` **por cada venv**, fuera del S/N global). Prompts `Read-Host` no ejecutables en vivo en este harness (misma limitación documentada que en validación RF-13).
- **No interactivo real** (`Test-IsInteractive=False` en este harness): `Clear` → `Removed=0 Skipped=1` ("NO se elimina … fail-closed"), fixture intacto.

## 5. Bootstrap y scripts intactos — PASS

- `git status` en repo real: modificados solo por trabajo previo documentado `[RELOCATE]`/`[PLATAFORMA]` (adr, pendientes, spec, tasks, README, `plataformador-bootstrap.ps1`); untracked esperados (`seguridad/relocate*.md`, `testing/validacion-relocate-2026-09-19.md`, `scripts/relocate-apps-to-src.ps1`). **Nada creado por esta sesión QA fuera de este reporte.**
- `git diff scripts/plataformador-bootstrap.ps1` → **0 adiciones** con `Regenerable|Find-Regenerable|Clear-Regenerable|Cleanup`: RF-15 no contamina el bootstrap.
- `param()` del script: solo `ProjectRoot, AppDirs, DryRun` (+ comunes). **Sin `-Force`, sin bypass**; la pregunta global acepta solo S/N (L1437-1441, default No → "se mueve todo").

## 6. Checklist `seguridad/relocate-cleanup.md` §5 (15 ítems) — 15/15 PASS

| # | Ítem | Veredicto + evidencia |
|---|------|----------------------|
| 1 | `-DryRun` lista candidatos exactos, cero escrituras/red | PASS — prueba 2 E2E (lista + tamaños + flags, `src/` no creado, todo intacto) |
| 2 | `Find` solo bajo apps validadas | PASS — `Invoke-RegenerableCleanup` filtra `Test-SimpleAppName` + denylist L1370-1373; `Documentacion` excluida como app (L1090) y como hija (L1138) |
| 3 | Allowlist exacta, sin substrings/recursivo/ampliaciones | PASS — `$exactNames -contains` L1141 + `-ieq` + UN nivel (`Get-ChildItem` sin `-Recurse` L1130); `dist-new` ausente y `mi_pkg.egg-info` matcheado por sufijo (verificado prueba extra) |
| 4 | Gate git-trackeado excluye con aviso | PASS — `git ls-files` L1146-1156; `build` trackeado excluido con aviso (prueba 2) |
| 5 | Pregunta global ANTES de S/N/T/C, default No, No = mueve todo | PASS — integración MAIN L1523-1526 (cleanup antes del plan); S/N solo, default No L1437-1441 |
| 6 | Confirmación separada por cada `.venv` | PASS por código — L1462 (`Read-Host` por venv) + aviso L1422; no ejecutable en vivo en este harness |
| 7 | `.venv` activo → `deactivate` previo, fail-closed | PASS — prueba 4 (IsActive + skip con aviso, intacto); re-chequeo de `$env:VIRTUAL_ENV` en `Clear` L1270-1283 |
| 8 | `.venv` sin manifiesto → aviso + separada + freeze previo | PASS por código — L1452-1454 (IRREPRODUCIBLE + `pip freeze` fuera del árbol) + L1462 |
| 9 | `node_modules`: lockfile + `patches/` + aviso offline | PASS — `NodeLock`/`NodePatches` L1179-1189 (lockfile y `patches/` verificados en fixtures), aviso `npm ci` red/tiempo L1424-1426 |
| 10 | `[T]` por fase; sin bypass; `-Force` no aplica | PASS — `param()` sin `-Force` (prueba 5); global S/N sin `T`; `T` solo en `Confirm-AppRelocation` del movido |
| 11 | No-interactivo no borra; por app secuencial; idempotente | PASS — prueba 4 (fail-closed) + prueba 3 (reintento "ya limpio") |
| 12 | Log por app + freeze de rescate | PASS — `Write-OK "Eliminado … (liberados … MB)"` L1317; comando freeze L1454 |
| 13 | Comandos de recreación exactos en `src\<App>\` + tests | PASS — informe `.venv ELIMINADOS` L1699-1717 observado en DryRun E2E (`python -m venv`, `Activate.ps1`, `pip install -r`) + aviso post-movido de tests |
| 14 | Containment; `Documentacion/` intacta; bootstrap intacto | PASS — containment `Clear` L1249-1265; hija `Documentacion/` excluida L1138 (fixture intacto); bootstrap sin.diff de cleanup (prueba 5) |
| 15 | Logs solo rutas relativas + metadatos | PASS — `Get-RelativeLogPath` en todos los logs (L66 + usos L1144 y ss.); sin volcado de contenido/freezes |

## 7. Bugs — ninguno

- **Sin bugs encontrados.** No se corrige nada (restricción `qa-senior`).
- Nota no bloqueante (heredada, fuera de alcance RF-15): el aviso de procesos Python en `Move-AppToSrc` sigue siendo solo aviso (H-1 ya reportado en `validacion-relocate-2026-09-19.md`).

## 8. Conclusión

**PASS — listo para uso real.** Las 6 pruebas PASS y el checklist 15/15 PASS con evidencia sobre fixtures en `$env:TEMP` (limpiados, `Test-Path=False`; `$env:VIRTUAL_ENV` restaurado). Condiciones de `relocate-cleanup.md` cumplidas: gate git-trackeado que conserva lo versionado, `.venv` activo fail-closed, `.venv` sin manifiesto con aviso + confirmación separada + rescate, DryRun/no-interactivo sin escrituras, bootstrap intacto. Uso recomendado: `-DryRun` primero, partir de git limpio, responder No ante la duda en `.venv`/`node_modules` offline.
