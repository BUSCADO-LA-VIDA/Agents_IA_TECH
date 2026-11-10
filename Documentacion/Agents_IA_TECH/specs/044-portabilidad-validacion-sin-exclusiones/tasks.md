# Tasks 044 — Portabilidad real: validación sin exclusiones de directorio

**Spec**: `spec.md` · **Plan**: `plan.md` · **Branch**: `044-portabilidad-validacion-sin-exclusiones`

**Regla de ejecucion**: F0 -> F1 -> F2 -> F3 -> F4 -> F5 -> F6. F1 es el juez: antes de remediar, el validador debe estar reescrito y en rojo con la evidencia real. Ningun `[x]` se marca sin comando de verificacion ejecutado y su salida registrada.

**Formato**: `- [ ] Txxx [RF/AC] descripcion | verificar: comando`

---

## Fase 0 — Baseline (evidencia del antes)

- [x] T001 [RF-01, AC-1] Medir el estado actual con patrones por fragmentos y guardar el inventario en `tests/fixtures/portabilidad-baseline-044.md` (34 archivos, 236 coincidencias, tabla archivo -> coincidencias -> accion) | verificar: `git grep -I -F -c` por patron y tabla con filas reales
- [x] T002 [RF-01] Confirmar que el validador actual es fail-open: documentar en el baseline las 5 rutas que la allowlist deja fuera (`tests/`, `.specify/`, `.mcp.json`, `opencode.json`, `.bootstrap-audit.log`) | verificar: lectura del baseline

## Fase 1 — Validador (el juez)

- [x] T003 [RF-01, R1] Reescribir `tests/validate-no-hardcoded-paths.Tests.ps1`: universo = `git ls-files`, sin array de rutas | verificar: el archivo no contiene ninguna lista de paths (inspeccion)
- [x] T004 [RF-02, R3] Construir los patrones por concatenacion de fragmentos (unidad + separador, prefijos POSIX) sin literales | verificar: `git grep -I -F` de los literales prohibidos sobre el propio test devuelve vacio
- [x] T005 [RF-01, AC-3] Auto-inclusion: el propio archivo del test entra en el universo y pasa | verificar: ejecucion del test incluye el archivo en el conteo `N`
- [x] T006 [RF-01] Un `It` por patron con mensaje `archivo:linea -> contenido` | verificar: salida del test
- [x] T007 [RF-01] Fallback sin git: recorrido recursivo completo, sin exclusiones de directorio, descartando solo contenido binario (byte NUL) | verificar: ejecucion en un directorio sin `.git`
- [x] T008 [RF-03] Reescribir `-CheckHardcodedPaths` en `scripts/plataformador-bootstrap.ps1`: universo = todo el proyecto destino (git-first), patrones por fragmentos, `exit 1` con coincidencias, resumen `0/N` | verificar: `.\scripts\plataformador-bootstrap.ps1 -CheckHardcodedPaths -DryRun`
- [x] T009 [RF-12, AC-8] Señuelo: crear un archivo temporal con una ruta literal, comprobar deteccion y exit != 0, borrar el señuelo | verificar: exit code != 0 + linea reportada. **Ejecutado 2026-11-09**: proyecto temporal, bootstrap sin `-DryRun` → `exit=1` y `Documentacion\Demo\decoy.md:1 -> ...`

## Fase 2 — Artefactos de ejecucion

- [x] T010 [RF-04, D3] `git rm --cached .bootstrap-audit.log`; retirar la excepcion del `.gitignore` y agregar la regla de ignorado; conservar el archivo en disco | verificar: `git ls-files` no lo lista y `Test-Path` = True
- [x] T011 [RF-05, D4] Redactar `.specify/mcp-validation-spec.md`, `-plan.md`, `-tasks.md` a tokens, conservandolos versionados | verificar: siguen en `git ls-files` y sin rutas
- [x] T012 [RF-04] Documentar en el baseline que el log no se reescribe (cadena de hashes intacta) | verificar: lectura del baseline

## Fase 3 — Configuracion de arnes portable

- [x] T013 [RF-06, D2] `opencode.json` fuera del indice (`git rm --cached` + `.gitignore`); `opencode.template.json` versionado con `{env:<VAR>}` + `enabled: false` y los invariantes (`default_agent`, `permission`, `provider`, `plugin`, `model`, `theme`, `region`) | verificar: `git ls-files` no lista `opencode.json` y `ConvertFrom-Json` parsea la plantilla
- [x] T014 [RF-06] Mapear cada `<VAR>` a una clave existente de `.env.mcp` para que la re-resolucion del bootstrap funcione | verificar: tabla VAR -> clave en la bitacora. **Ejecutado 2026-11-10**: 9/9 variables de `opencode.template.json` existen en `.env.mcp` y no hay claves sin uso (`CODEBASE_MEMORY_CMD`, `CONTEXT_MODE_CMD`, `CONTEXT7_CMD`, `GITHUB_MCP_CMD`, `GRAPHIFY_CMD`, `MARKITDOWN_CMD`, `PLAYWRIGHT_MCP_CMD`, `SEMGREP_MCP_CMD`, `TOKENSLAYER_CMD`)
- [x] T015 [RF-07] `.mcp.json`: nombres en `PATH`, `npx -y` para context7/playwright, `${workspaceFolder}` para el grafo | verificar: `ConvertFrom-Json` y revision de cada entrada
- [ ] T016 [AC-6] Verificar arranque del arnes con la configuracion portable; si un MCP no resuelve, dejarlo `enabled: false` + WARN y registrarlo | verificar: bitacora con el resultado por MCP
- [ ] T017 [RF-06] Rollback documentado para ambas configs | verificar: seccion en la bitacora

## Fase 4 — Scripts y fixture

- [x] T018 [RF-08] `scripts/sync-mcp-graphify.ps1`: `$RootPath` por defecto derivado de `$PSScriptRoot`, sin literal | verificar: lectura del param block
- [x] T019 [RF-09] `tests/fixtures/baseline-036.md`: redactar las dos rutas a `$KitPath` preservando metricas, hashes y veredictos | verificar: diff limitado a las dos lineas de ruta

## Fase 5 — Redaccion documental

- [x] T020 [RF-10] Aplicar la convencion de tokens del plan §9 a los 24 archivos del inventario §2.6 | verificar: `git grep -I -F` de cada patron -> vacio
- [x] T021 [RF-10] Redactar el propio paquete 044 (spec, plan, tasks) para que no se autoincumpla | verificar: el test lo incluye y pasa
- [x] T022 [RF-10] Verificar que no se alteraron conclusiones: diff por archivo, solo lineas con rutas | verificar: `git diff --stat` + revision de hunks
- [x] T023 [RF-11] `CHANGELOG.md` y `00-indice.md`: entrada de la 044 | verificar: lectura y `git diff`

## Fase 6 — CI y cierre

- [x] T024 [RF-11, AC-10] `.github/workflows/portability.yml`: ejecutar el test en push y PR; fallar en rojo | verificar: YAML valido + run en verde
- [x] T025 [AC-1..AC-5] Validacion final de los criterios automaticos | verificar: salida del test + `git grep` vacio
- [x] T026 [AC-7] Bootstrap en proyecto limpio | verificar: `[OK] 0/N`. **Ejecutado 2026-11-10** tras push del kit: `[OK] Validacion -CheckHardcodedPaths: 0 coincidencias en 136 archivos versionados` (73 artefactos de runtime omitidos, `exit=0`)
- [x] T027 [AC-9] Regresion: 5 suites existentes | verificar: exit 0 en cada una. **Ejecutado 2026-11-09**: `harness-default` 0, `kit-sync-merge` 0, `kb-parity` 0, `mcp-refresh-parity` 0; `agents-parity` 1 por divergencia preexistente de `Agent-SSD` (documentada en el baseline 036)
- [ ] T028 [T15] Bitacora de la intervencion y commit conventional | verificar: `git log -1`

---

## Dependencias

| Tarea | Requiere |
|---|---|
| T003-T007 | T001 |
| T008, T009 | T003 |
| T010-T012 | T003 |
| T013-T017 | T003 |
| T018, T019 | T003 |
| T020-T023 | T003 (el test debe existir para medir) |
| T024-T028 | T003-T023 |

## Oportunidades de paralelismo

- T010/T011 (indice git) en paralelo con T013/T015 (configs): archivos disjuntos.
- T018/T019 en paralelo con T020: conjuntos de archivos disjuntos.
- T020 no se paraleliza con T023 (T023 resume T020).

## Estrategia de implementacion

El validador se escribe **antes** de cualquier remediacion y se ejecuta en rojo. Cada fase posterior reduce el numero de coincidencias y se vuelve a ejecutar. El cierre exige `0` coincidencias con el universo completo, no con un subconjunto.
