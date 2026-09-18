# Validación relocate a `src\` (RF-13 / criterio 9) — `qa-senior` (tarea `[RELOCATE]`)

- **Fecha**: 2026-09-19
- **Agente**: `qa-senior` (validación formal independiente; no corrige, solo reporta)
- **Alcance**: spec `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-13 + criterio nº 9) y checklist §5 de `seguridad/relocate.md` (18 ítems)
- **Implementación validada**: `scripts/relocate-apps-to-src.ps1` (503 líneas, standalone): `Confirm-AppRelocation` (L128-151), `Move-AppToSrc` (L161-299), MAIN `Invoke-AppRelocation` (L307-439), `Show-RelocationReport` (L441-499), guard MAIN L501; `param()` L31-35 (`-ProjectRoot`/`-AppDirs`/`-DryRun`)
- **Restricción cumplida**: cero movidos reales fuera de fixtures en `$env:TEMP` (`relocate-qa-fixture/`, limpiado después, verificado `Test-Path=False`); repo real solo con `-DryRun` (cero escrituras, `git status` idéntico, sin `src/` creado); `plataformador-bootstrap.ps1` no tocado por esta tarea; escrituras solo en este reporte + `pendientes-implementacion.md`
- **Entorno**: pwsh 7 (Windows), `Parser::ParseFile` del script = **0 errores**

## 1. Sintaxis + carga — PASS

- `Parser::ParseFile('scripts/relocate-apps-to-src.ps1')` → **0 errores**.
- Guard MAIN L501 (`if ($MyInvocation.InvocationName -ne '.')`): el script se dot-sourceó 3 veces en esta sesión (pruebas 3 y 5) y **nunca ejecutó el MAIN por cargar** (sin efectos laterales observados); fuera de funciones solo hay `param()`, helpers `Write-*`, `$DeniedAppNames` y `$ErrorActionPreference` — nada que actúe al cargar.

## 2. DryRun contra fixtures — PASS

- Fixture `$env:TEMP\relocate-qa-fixture` con `FakeApp1/` (1 archivo), `FakeApp2/` (1 archivo), `FakeAppVenv/` (`.venv/pyvenv.cfg` falso + `sub/mod.py`) y `Documentacion/senuelo.md` señuelo.
- `-DryRun` informó las 3 apps con origen/destino canónicos, conteo, tamaño y `.venv: Si (a recrear)` solo en `FakeAppVenv`, más comandos exactos de recreación (`python -m venv .venv`, `Activate.ps1`, `pip install -r requirements.txt`).
- Verificado: `Test-Path src/` = **False** (no creado), `FakeApp1/` intacta, `Documentacion/senuelo.md` intacto. Contraste en repo real (AppInexistenteXyz): `OMITIDA origen-inexistente`, sin `src/` creado.

## 3. Confirmación sin bypass — PASS

- **Sin flag de bypass por diseño**: `Get-Command *.Parameters.Keys` → solo `ProjectRoot`, `AppDirs`, `DryRun` (+ comunes); `Select-String 'Force|Bypass|-Yes|SkipConfirm'` solo matchea `-Force` de `Get-ChildItem`/`Get-Item`/`New-Item` (lectura/creación de `src\`, no confirmación) + guard `MyInvocation` L501.
- **No interactivo → `N`**: `Confirm-AppRelocation` dot-sourceada devolvió `'N'` con `WARN … fail-closed, criterio 9`. End-to-end con stdin redirigido: `OMITIDA (no-interactivo-no-mueve)`, `FakeApp1/` intacta.
- Ramas `S/N/T/C` verificadas por código L145-150 (`S`→mover, `T`→lote de restantes, `C`→cancela todo con `break`, default→`N`); prompt interactivo (`Read-Host`) no ejecutable en este harness (misma limitación documentada en validación de huérfanos).

## 4. Denylist + containment — PASS

- DryRun con 9 entradas hostiles → **9/9 `OMITIDA`, 0 simuladas**: `Documentacion`, `.specify`, `src`, `scripts`, `.git`, `.venv` suelto por denylist; `a/b`, `..`, `C:\Windows` por nombre-no-simple. Sin `src/` creado.
- Restantes de la denylist (`proyect_ext`, `.github`, `.opencode`, `.doc_agents`) verificados por código en `$DeniedAppNames` L50-53 (comparación `-contains`, case-insensitive).
- Containment-check L196-205 (origen dentro de `<ProjectRoot>`, destino dentro de `<ProjectRoot>\src\`, fail-closed) + rechazo de symlinks/junctions por `ReparsePoint` L216-226, por código (sin fixture symlink en Windows).

## 5. Movido real SOBRE FIXTURES + rollback — PASS

- `Move-AppToSrc 'MoveMe'` (3 archivos en `root.txt` + `sub1/a.txt` + `sub2/b.txt`) → Status **OK**, conteo antes=después (3=3), origen ausente, `src\MoveMe\` con estructura completa y contenido intacto (`root.txt` = `r`).
- Rollback documentado concreto en el resultado (`Move-Item -LiteralPath "src\MoveMe" -Destination ".\MoveMe"`); ejecutado manualmente → `MoveMe/` restaurada con subcarpetas y contenidos, `src/` vacía.
- Destino ocupado → `OMITIDA (destino-ocupado)`, origen intacto: nunca fusiona/sobrescribe.

## 6. Bootstrap intacto — PASS

- `git status` muestra `scripts/plataformador-bootstrap.ps1` modificado por trabajo previo `[PLATAFORMA]` (esperado).
- `git diff -- scripts/plataformador-bootstrap.ps1 | Select-String 'relocate|Move-AppToSrc|Confirm-AppRelocation|AppDirs'` → **0 matches**; el diff visible corresponde a `Reload-ProjectWindow` + fixes `Ensure-OpenCodeMcp` + comentario de recarga. **Nada de relocate en el bootstrap.**

## 7. Checklist de seguridad (`seguridad/relocate.md` §5, 18 ítems) — 17 PASS + 1 PARCIAL

| # | Ítem | Veredicto + evidencia |
|---|------|----------------------|
| 1 | `-DryRun` previo, cero escrituras | PASS — rama DryRun L345-352 solo informa; observado prueba 2 (sin `src/`, fixtures intactos) |
| 2 | Lista visible (origen/destino, tamaño, git) | PASS — lista numerada L323-340 con conteo/MB/`.venv`; aviso git-limpio L317-321 observado en repo real |
| 3 | Nombres simples | PASS — `Test-SimpleAppName` L79-93; observado `a/b`, `..`, `C:\Windows` rechazados |
| 4 | Denylist dura | PASS — L50-53 + L191-194; observado 6/6 en prueba 4, resto por código |
| 5 | Containment-check | PASS por código — L196-205 fail-closed |
| 6 | Symlinks no se siguen | PASS por código — L216-226 (`ReparsePoint` → OMITIDA); sin fixture en Windows |
| 7 | Origen existe + destino libre | PASS — L209-232; observado origen-inexistente y destino-ocupado |
| 8 | Procesos Python → abortar esa app | **PARCIAL** — L240-243 solo **avisa** (`WARN … cierra procesos`), no aborta → **H-1** |
| 9 | Confirmación S/N/T/C, sin bypass | PASS — prueba 3 |
| 10 | No interactivo no mueve | PASS — L356-374 + observado `no-interactivo-no-mueve` |
| 11 | Transacción por app + verificación + nunca sobrescribir | PASS — L252-298 (mover → contar → comparar); observado OK con 3=3 y destino-ocupado |
| 12 | Log + rollback concreto por app | PASS — objeto resultado L167-184 + `Rollback` L258; observado comando concreto en prueba 5 |
| 13 | Rollback desde el log, orden inverso, destino libre | PASS — informe L492-495 (orden inverso); destino-libre verificado por código en movido (L229), el rollback manual hereda el criterio documentado |
| 14 | `.venv` a recrear, comandos exactos | PASS — L477-487; observado en DryRun e informe |
| 15 | Post-movido imports/tests + commit atómico | PASS — L491 + L320; observado en informe (`Show-RelocationReport` ejecutado directamente) |
| 16 | Logs relativas + metadatos, sin contenido/secrets | PASS — `Get-RelativeLogPath` L55-65 usado en L206-207/L339/L463; `Select-String 'Get-Content|password|token|API_KEY'` → 0 matches |
| 17 | `Documentacion/` intacta, spec-kit en raíz, bootstrap intacto | PASS — `Documentacion` nunca aparece como candidata ni destino; pruebas 2 y 6 |
| 18 | `ecc-agentshield scan` | N/A — cambios no tocan `.github/` (solo `scripts/` + doc propia) |

## Bugs / hallazgos para `devops`

- **H-1 (no bloqueante, PARCIAL ítem 8)**: `Move-AppToSrc` L240-243 detecta procesos `python`/`pythonw` corriendo y avisa, pero **no aborta esa app**; `seguridad/relocate.md` §1.2 pedía abortar con aviso. La spec RF-13 no exige el abort (solo "git limpio recomendado" + reporte venv), por lo que no bloquea; queda a criterio de `devops` endurecerlo a `OMITIDA` o mantener el aviso.
- **Nota informativa (no bug)**: el script no fija exit codes explícitos (`$LASTEXITCODE` tras DryRun en fixture no-git reflejó el `git` interno, 128); en pwsh el EXIT del script es 0 salvo throw. Si se quiere señalizar omitidas/abortadas a un llamante, habría que añadir `exit` — fuera del alcance de RF-13.

## Conclusión

**PASS — listo para uso real como standalone** (pwsh ≥ 7): sintaxis 0 errores, DryRun con cero escrituras, sin bypass + no-interactivo fail-closed, denylist/traversal/containment verificados, movido con estructura preservada + rollback funcional, bootstrap intacto. Condiciones de uso: `-DryRun` previo, responder por app (`S`/`N`, `[T]` solo leída la lista), partir de git limpio + commit atómico tras tests, recrear `.venv` (no reutilizar el movido). H-1 pendiente de decisión de `devops`, no bloquea el rollout.
