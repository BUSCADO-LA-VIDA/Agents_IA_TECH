# Converge 044 — Portabilidad con validación sin exclusiones

**Spec**: `spec.md` · **Plan**: `plan.md` · **Tasks**: `tasks.md` · **Analyze**: `analyze.md`

**Fecha**: 2026-11-09 (AC ejecutados 2026-11-09/10) · **Versión**: 1.1.0

---

## 1. Resumen ejecutivo

| Elemento | Resultado |
|---|---|
| Validador reescrito | Sí: universo `git ls-files`, 14 grupos + 2 comprobaciones meta, auto-inclusión |
| Comprobaciones en verde | **16/16** sobre 764 archivos versionados |
| Criterios automáticos (AC-1..AC-5) | **PASS** |
| Criterio de detección (AC-8) | **PASS** (`exit 1` con señuelo) |
| Regresión (AC-9) | **PASS** 4/5 suites; 1 divergencia preexistente documentada |
| Criterio de proyecto limpio (AC-7) | **NO CONCLUYENTE** (ver §5, H4) |
| Arranque del arnés (AC-6) | Pendiente de reinicio del arnés |
| CI (AC-10) | Workflow creado; no ejecutado en remoto |

## 2. Consolidación de artefactos

| Artefacto | Estado | Contenido |
|---|---|---|
| `spec.md` | v1.1.0 | 12 RF, 5 NFR, 6 decisiones, 10 AC, §12 fuera de alcance (045/046) |
| `plan.md` | v1.0.0 | Diseño del validador, patrones, configs, redacción, estrategia de test |
| `tasks.md` | v1.0.0 | 28 tareas; 23 completadas, 5 pendientes con causa |
| `analyze.md` | v1.0.0 | 8 hallazgos, cobertura 12/12 RF y 10/10 AC, veredicto PASS con A1 corregido |
| `tests/fixtures/portabilidad-baseline-044.md` | nuevo | Evidencia antes/después (34 archivos / 236 coincidencias → 0) |
| `.github/workflows/portability.yml` | nuevo | CI matriz Linux + Windows |

## 3. Matriz de cobertura

| Requisito | Tareas | AC | Estado |
|---|---|---|---|
| RF-01 universo `git ls-files` | T003, T005, T006 | AC-1, AC-2, AC-3 | Cumplido |
| RF-02 patrones por fragmentos | T004 | AC-1 | Cumplido |
| RF-03 bootstrap sobre todo el proyecto | T008 | AC-7, AC-8 | Cumplido en código; AC-7 no concluyente |
| RF-04 audit log fuera de versionado | T010, T012 | AC-5 | Cumplido |
| RF-05 `.specify/mcp-validation-*` redactados y conservados | T011 | AC-4 | Cumplido (corregido: no se eliminan) |
| RF-06 `opencode.json` fuera del índice + plantilla | T013 | AC-6 | Cumplido; verificación de arranque pendiente |
| RF-07 `.mcp.json` portable | T015 | AC-6 | Cumplido |
| RF-08 scripts sin default del autor | T018 | AC-1 | Cumplido (incluye `init-pensador.ps1` y `cleanup-legacy-docs.ps1`) |
| RF-09 fixture 036 redactado | T019 | AC-1 | Cumplido |
| RF-10 redacción documental | T020, T021, T022 | AC-1, AC-4 | Cumplido (62 archivos `.md`) |
| RF-11 CI | T024 | AC-10 | Cumplido en código |
| RF-12 bootstrap informa `0/N` | T008 | AC-7 | Cumplido en código |

## 4. Resultados de los criterios de aceptación

| AC | Comando / método | Resultado |
|---|---|---|
| AC-1 | `Invoke-Pester tests\validate-no-hardcoded-paths.Tests.ps1` | **PASS** — 16/16, 0 coincidencias |
| AC-2 | inspección del test | **PASS** — sin array de rutas; universo `git ls-files` |
| AC-3 | comprobación meta "auto-inclusión" | **PASS** — el test se incluye y pasa |
| AC-4 | mismo test (grupos 1-12) | **PASS** — 0 rutas de la máquina del autor |
| AC-5 | `git ls-files .bootstrap-audit.log` → vacío; `Test-Path` → True | **PASS** — fuera del índice, en disco |
| AC-6 | arranque con `opencode.json` resuelto | **PENDIENTE** — requiere reiniciar el arnés |
| AC-7 | bootstrap `-CheckHardcodedPaths` en proyecto limpio | **NO CONCLUYENTE** — ver H4 |
| AC-8 | señuelo en directorio temporal + bootstrap sin `-DryRun` | **PASS** — detecta y sale con código 1 |
| AC-9 | 5 suites (`harness-default`, `kit-sync-merge`, `agents-parity`, `kb-parity`, `mcp-refresh-parity`) | **PASS** 4/5 exit 0; `agents-parity` exit 1 por divergencia preexistente de `Agent-SSD` |
| AC-10 | workflow `portability.yml` | **Creado**; sin ejecución en remoto |

## 5. Hallazgos nuevos (posteriores a `analyze.md`)

| ID | Severidad | Hallazgo | Resolución |
|---|---|---|---|
| H1 | **HIGH** | El validador comparaba con `Ordinal` (sensible a mayúsculas). `scripts/init-pensador.ps1` tenía una ruta con la unidad en minúsculas y **pasaba el test** | Comparación `OrdinalIgnoreCase` para rutas Windows; default del script sustituido por `$PSScriptRoot`; 2 documentos en minúsculas redactados |
| H2 | MEDIUM | Al hacer todo case-insensitive, `/<Users>/` producía falsos positivos en endpoints de API (`/api/v1/users/{id}`) | Comparación partida: Windows sin distinguir, POSIX distinguiendo |
| H3 | **HIGH** | `cleanup-legacy-docs.ps1` (versionado) tenía rutas de la máquina y ejecutaba `Remove-Item -Recurse -Force` sin confirmación | Reescrito: raíz desde `$PSScriptRoot`, dry-run por defecto, `-Confirm` para aplicar |
| H4 | MEDIUM | AC-7 no es concluyente antes de commit/push: el bootstrap de un proyecto limpio **sincroniza el kit publicado**, así que valida el remoto (versión antigua) y no el working tree | AC-7 se re-ejecuta después del commit; queda registrado como pendiente con causa |
| H5 | LOW | El inventario §2.6 del spec (24 archivos) era incompleto: la pasada real tocó 62 `.md` | Asumido: el universo lo fija el validador, no una lista escrita a mano |
| H6 | MEDIUM | El universo es `git ls-files`: un documento **no versionado todavía** no se valida. La primera corrida "16/16" fue sobre un universo sin los specs 044/045/046 (aún untracked) | Tras `git add`, aparecieron 6 grupos rojos en los propios artefactos de la 044; redactados y verificado 16/16 con 781 archivos versionados. Regla operativa: validar **después** de `git add` |

## 6. Archivos del cambio (resumen)

| Grupo | Archivos |
|---|---|
| Validador y CI | `tests/validate-no-hardcoded-paths.Tests.ps1`, `.github/workflows/portability.yml` |
| Scripts | `scripts/plataformador-bootstrap.ps1`, `scripts/sync-mcp-graphify.ps1`, `scripts/sync-gitignore.ps1`, `scripts/sync/mcp/install.ps1`, `scripts/sync/transversal/sync-transversal.ps1`, `scripts/init-pensador.ps1`, `cleanup-legacy-docs.ps1`, `upgrade_framework.ps1` |
| Config | `.gitignore`, `.mcp.json`, `opencode.template.json`; `opencode.json` y `.bootstrap-audit.log` fuera del índice |
| Fixtures | `tests/fixtures/baseline-036.md`, `tests/fixtures/portabilidad-baseline-044.md` |
| Documentación | 62 `.md` redactados + `generacion-opencode-json.md` (derivado a 046) |

## 7. Tareas pendientes con causa

| ID | Estado | Causa |
|---|---|---|
| T009 | **Completada** | Señuelo ejecutado en proyecto temporal: `exit 1` y `archivo:línea` |
| T014 | Pendiente | Requiere validar el mapeo VAR → clave de `.env.mcp` en una corrida real del resolvedor |
| T016 | Pendiente | Requiere reinicio del arnés para releer `opencode.json` |
| T017 | Pendiente | Documentar rollback de ambas configuraciones en bitácora |
| T026 | **Bloqueada por H4** | Re-ejecutar después del commit |
| T027 | **Completada** | 5 suites ejecutadas; 4 en verde + 1 divergencia preexistente |
| T028 | Parcial | `converge.md` escrito; commit pendiente de aprobación |

## 8. Veredicto

**Portabilidad del repo: cumplida y verificada.** El validador es fail-closed, no tiene allowlist y ahora también detecta rutas en minúsculas. Quedan dos verificaciones que no dependen de código: AC-6 (reinicio del arnés) y AC-7 (post-commit).

**No se cierra la spec** hasta ejecutar AC-6 y AC-7 y registrar el commit. Los cambios de las specs 045 y 046 quedan fuera de este cierre.
