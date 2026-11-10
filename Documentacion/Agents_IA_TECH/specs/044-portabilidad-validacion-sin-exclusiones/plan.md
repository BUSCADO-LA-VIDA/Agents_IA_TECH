# Plan 044 — Portabilidad real: validación sin exclusiones de directorio

**Feature Branch**: `044-portabilidad-validacion-sin-exclusiones`

**Created**: 2026-11-09

**Spec**: `spec.md` (v1.0.0 aprobada por el usuario el 2026-11-09)

**Estado**: Aprobado para implementación

---

## 1. Resumen

Sustituir el validador de portabilidad por uno **fail-closed cuyo universo es `git ls-files`**: todo archivo versionado entra en cobertura automáticamente, sin allowlist de directorios ni de archivos. Remediar las 236 coincidencias detectadas en 34 archivos versionados (§2 del spec) y fijar el mecanismo para que la reincidencia sea imposible.

La causa raíz no es "faltaban directorios en la lista": es que **existía una lista**. Cualquier lista de rutas es fail-open por diseño, porque cada directorio nuevo nace fuera de cobertura.

## 2. Contexto técnico

| Elemento | Valor |
|---|---|
| Runtime de validación | PowerShell 7+ / Pester 5+ (ya usado en `tests/`) |
| Fuente del universo | `git ls-files` (fallback: recorrido recursivo completo) |
| Detección | Coincidencia literal (`-F`), patrones construidos por concatenación |
| Binarios | Excluidos por contenido (`git grep -I`); no por extensión ni por directorio |
| Plataformas | Windows, Linux y macOS (separadores normalizados en los fragmentos) |
| Config de arnés | `opencode.json` (tokens `{env:...}` + `enabled: false`), `.mcp.json` (PATH + `${workspaceFolder}`) |
| Regresión | Suites existentes de `tests/` (5 scripts) |

## 3. Constitution check

| Principio | Cumplimiento |
|---|---|
| Portabilidad del kit | El criterio de aceptación pasa a ser independiente de la máquina y del sistema operativo |
| Fail-closed por defecto | Si el universo no se puede construir, el test falla; si un archivo no se puede leer, el test falla |
| Trazabilidad | Cada archivo redactado conserva sus métricas, hashes y conclusiones; solo cambia el literal de ruta |
| Seguridad de la información | Se elimina la exposición del nombre de usuario del SO y del layout del disco del autor |
| Sin regresión funcional | Las suites existentes deben seguir en verde; el arranque del arnés se verifica aparte |
| Contenido completo | Este plan y sus artefactos derivados no usan placeholders |

## 4. Diseño del validador

### 4.1 Universo

```powershell
# 1) Fuente primaria: git (solo archivos versionados -> distribuibles)
$out = & git ls-files
# 2) Fallback sin repo git: recorrido completo, sin exclusiones de directorio
Get-ChildItem -LiteralPath $Root -Recurse -File -Force
```

Regla: **no hay array de rutas**. El unico filtro admitido es de contenido (binario), nunca de ubicacion.

### 4.2 Patrones

Construidos por fragmentos para que el propio validador se autovalide (R3):

```powershell
$bs = [string][char]92          # backslash sin literal
$fs = '/'
$patterns = @(
  ('C:' + $bs + 'Proyectos'), ('C:' + $fs + 'Proyectos'),
  ('D:' + $bs + 'Proyectos'), ('D:' + $fs + 'Proyectos'),
  ('C:' + $bs + 'Users' + $bs), ('C:' + $fs + 'Users' + $fs),
  ('C:' + $bs + 'Python314'), ('C:' + $fs + 'Python314'),
  ('C:' + $bs + 'Program Files'), ('C:' + $fs + 'Program Files'),
  ('D:' + $bs), ('D:' + $fs),
  ($fs + 'home' + $fs), ($fs + 'Users' + $fs)
)
```

Cobertura: rutas de la maquina del autor (raiz de proyectos, perfil de usuario, interprete Python, runtime Node) y unidades ajenas al clon (prefijo `D:`), mas los prefijos de home POSIX. **No** se prohibe toda ruta con letra de unidad: los ejemplos genericos de las skills (unidad + carpetas plantilla) son documentacion legitima y no filtran nada. La lista se cierra sobre lo que rompe portabilidad o expone el layout real.

### 4.3 Auto-inclusion

El archivo del test entra en el universo como cualquier otro (esta versionado). Si alguien escribe un patron literal dentro del test, el test se pone rojo a si mismo. Esto elimina la necesidad del `continue` que hoy exceptua a `plataformador-bootstrap.ps1`.

### 4.4 Salida y semantica de fallo

| Contexto | Salida | Codigo |
|---|---|---|
| Pester (CI/local) | `Should -BeNullOrEmpty` con lista `archivo:linea -> contenido` | test rojo |
| Bootstrap `-CheckHardcodedPaths` | lista de coincidencias + resumen | `exit 1` si hay coincidencias, `0` si no |
| DryRun del bootstrap | informa sin escribir | `0` |

### 4.5 Fallback sin git

Si `git` no existe o el directorio no es repo: recorrido recursivo, se descarta solo el contenido binario (byte NUL) y nada mas. El fallback **no excluye** `.git` por nombre: si `.git` existe es porque hay repo, y entonces se usa la rama git.

## 5. Portabilidad de `opencode.json` (no versionado + plantilla)

| Entrada | Situacion actual | Destino |
|---|---|---|
| `context-mode` | binario del usuario + cli.js absolutos | `{env:CONTEXT_MODE_CMD}` + `enabled:false` |
| `codebase-memory-mcp` | ejecutable del usuario absoluto | `{env:CODEBASE_MEMORY_CMD}` + `enabled:false` |
| `markitdown` | interprete absoluto del autor | `{env:MARKITDOWN_CMD}` + `enabled:false` |
| `graphify` | interprete + grafo del kit absolutos | `{env:GRAPHIFY_CMD}` + `enabled:false` |
| `github` | binario del usuario absoluto | `{env:GITHUB_MCP_CMD}` + `enabled:false` |
| `playwright` | interprete + cli absolutos | `{env:PLAYWRIGHT_MCP_CMD}` + `enabled:false` |
| `tokenslayer` | interprete + ruta del kit absolutos | `{env:TOKENSLAYER_CMD}` + `enabled:false` |
| `context7` | interprete + cli absolutos | `{env:CONTEXT7_CMD}` + `enabled:false` |

El archivo con rutas reales (`opencode.json`) **no se versiona**: se agrega a `.gitignore` y se retira del indice con `git rm --cached`. Se versiona `opencode.template.json`, que es la fuente portable. Invariantes que no se tocan: `default_agent: pensador`, `permission`, `provider`, `plugin`, `model`, `region`, `theme`.

Mecanismo de promocion (ya existe en el bootstrap, `Ensure-OpenCodeMcp`): la re-resolucion lee `.env.mcp`/entorno, sustituye el token por la ruta real y pone `enabled: true`. Var ausente = no resuelto = queda degradado con WARN, nunca con token crudo.

Generacion: si el proyecto no tiene `opencode.json`, el bootstrap copia `opencode.template.json` y luego re-resuelve tokens a rutas locales. Verificacion: `ConvertFrom-Json` sobre plantilla y sobre el archivo generado. Rollback: `git checkout -- opencode.json` (si estaba versionado) o borrar el generado.

## 6. Portabilidad de `.mcp.json`

| Entrada | Destino |
|---|---|
| `context7` | `npx -y @upstash/context7-mcp --stdio` |
| `github` | `github-mcp-server stdio` (PATH) |
| `playwright` | `npx -y @playwright/mcp` |
| `semgrep` | `semgrep mcp` (PATH) |
| `graphify` | `python -m graphify.serve ${workspaceFolder}/graphify-out/graph.json` |
| `context-mode`, `codebase-memory-mcp`, `markitdown` | ya estaban por nombre en PATH, sin cambios |

Rollback: `git checkout -- .mcp.json`.

## 7. Artefactos de ejecucion

| Archivo | Accion | Motivo |
|---|---|---|
| `.bootstrap-audit.log` | `git rm --cached` + regla de ignorado + retirar la excepcion existente | Log encadenado por hash: reescribir rompe la cadena; versionar publica `host`, `actor` y layout del FS. Sigue escribiendose local |
| `.specify/mcp-validation-spec.md` | Redaccion a tokens (se conserva versionado) | Evidencia de la validacion MCP previa: borrarla destruye trazabilidad |
| `.specify/mcp-validation-plan.md` | Redaccion a tokens | Idem |
| `.specify/mcp-validation-tasks.md` | Redaccion a tokens | Idem |

`.gitignore`: se retira la linea que hoy re-incluye el audit log y se agregan las dos reglas nuevas.

## 8. Correcciones de codigo

| Archivo | Cambio |
|---|---|
| `scripts/sync-mcp-graphify.ps1` | `$RootPath` por defecto derivado de `$PSScriptRoot` (raiz del kit), sin literal |
| `scripts/plataformador-bootstrap.ps1` | `-CheckHardcodedPaths` sobre todo el proyecto destino (git-first), patrones por fragmentos, exit != 0 con coincidencias, resumen `0/N` |
| `tests/validate-no-hardcoded-paths.Tests.ps1` | Reescritura completa (§4) |
| `tests/fixtures/baseline-036.md` | Rutas redactadas a `$KitPath`; metricas y hashes intactos |
| `.github/workflows/portability.yml` | CI: ejecuta el test en push y PR |

## 9. Redaccion documental

Convencion unica, aplicada en este orden (de mas especifico a mas generico) para no encadenar reemplazos:

| Clase | Valor original | Token |
|---|---|---|
| Raiz del kit | ruta absoluta al checkout del kit | `$KitPath` (en PowerShell) / `<KIT_ROOT>` (en prosa y JSON) |
| Raiz de otro proyecto | ruta absoluta a otro repo del autor | `<PROJECT_ROOT>` |
| Home del usuario | prefijo de home con nombre de usuario | `<HOME>` |
| Interprete Python | ruta absoluta al interprete | `<PYTHON_HOME>` |
| Runtime Node | ruta absoluta a Node | `<NODE_HOME>` |
| Unidad de disco | letra + separador | `<DRIVE>:` |
| Prefijo POSIX de home | separador + `home`/`Users` + separador | `/<home>/`, `/<Users>/` |

Alcance: los 24 archivos del inventario §2.6 del spec + `CHANGELOG.md` + `00-indice.md` + este mismo paquete de artefactos. No se alteran conclusiones, tablas de metricas, hashes ni veredictos.

## 10. Estrategia de test

| Nivel | Que prueba | Herramienta | Cuando |
|---|---|---|---|
| Unitario | El universo es `git ls-files` y no hay allowlist | Pester (introspeccion del AST del propio test) | pre-commit |
| Unitario | Cero coincidencias en todo el universo | Pester, un `It` por patron | pre-commit, CI |
| Integracion | `-CheckHardcodedPaths` detecta un señuelo y devuelve exit != 0 | Pester sobre un directorio temporal | CI |
| Integracion | `-CheckHardcodedPaths` en proyecto limpio devuelve `[OK] 0/N` | Pester | CI |
| Regresion | Las 5 suites existentes siguen verdes | scripts de `tests/` | CI |
| Funcional | Clon en ruta arbitraria arranca sin editar archivos versionados | manual documentado en quickstart | cierre |

## 11. Verificacion de criterios de aceptacion

| AC | Verificacion | Evidencia |
|---|---|---|
| AC-1 | Pester, patrones §4.2 | salida del test |
| AC-2 | Inspeccion del test: sin arrays de rutas | diff |
| AC-3 | El propio archivo aparece en el universo y pasa | salida del test |
| AC-4 | `git grep` de las dos clases de ruta del autor | consola vacia |
| AC-5 | `git ls-files` no lo lista; `Test-Path` local si | consola |
| AC-6 | Arranque del arnes tras portabilizar | captura/bitacora |
| AC-7 | Bootstrap `-CheckHardcodedPaths -DryRun` | `[OK] 0/N` |
| AC-8 | Señuelo temporal | exit != 0 + `archivo:linea` |
| AC-9 | 5 suites | exit 0 |
| AC-10 | Workflow falla con señuelo | run rojo |

## 12. Tareas

| ID | Tarea | Agente | Depende de | Archivos |
|---|---|---|---|---|
| T01 | Baseline de coincidencias | `qa-senior` | — | `tests/fixtures/portabilidad-baseline-044.md` |
| T02 | Reescribir validador | `qa-senior` | T01 | `tests/validate-no-hardcoded-paths.Tests.ps1` |
| T03 | Fallback sin git | `qa-senior` | T02 | idem |
| T04 | `-CheckHardcodedPaths` completo | `plataformador` | T02 | `scripts/plataformador-bootstrap.ps1` |
| T05 | Audit log fuera de versionado | `plataformador` | T02 | `.gitignore`, indice git |
| T06 | Redactar `.specify/mcp-validation-*` | `plataformador` | T05 | `.specify/mcp-validation-*.md` |
| T07 | `opencode.json` portable | `plataformador` | T02 | `opencode.json` |
| T08 | `.mcp.json` portable | `plataformador` | T07 | `.mcp.json` |
| T09 | Verificar arranque | `plataformador` | T08 | bitacora |
| T10 | `sync-mcp-graphify.ps1` | `plataformador` | T02 | `scripts/sync-mcp-graphify.ps1` |
| T11 | Fixture 036 redactado | `qa-senior` | T02 | `tests/fixtures/baseline-036.md` |
| T12 | Redaccion de 24 docs | `documentador` | T02 | inventario §2.6 |
| T13 | Indice y CHANGELOG | `documentador` | T12 | `00-indice.md`, `CHANGELOG.md` |
| T14 | CI | `qa-senior` | T02 | `.github/workflows/portability.yml` |
| T15 | Validacion final + commit | `qa-senior` + `gitflow` | T03..T14 | repo |

## 13. Riesgos

| Riesgo | Mitigacion | Rollback |
|---|---|---|
| `opencode.json` con tokens deja MCP deshabilitados en un clon nuevo hasta correr el bootstrap | Comportamiento documentado; el bootstrap promueve a `enabled: true` al resolver. Verificar JSON valido | `git checkout -- opencode.json` |
| El test se vuelve demasiado estricto y bloquea PRs legitimos | Los patrones son rutas absolutas, no texto libre; cualquier excepcion debe ser un token, no una ruta | ajustar patrones |
| Redaccion masiva altera texto normativo | Solo se sustituyen literales de ruta; diff revisado archivo por archivo | `git revert` |
| `git rm --cached .bootstrap-audit.log` se percibe como perdida de evidencia | El archivo permanece en disco; se documenta en bitacora | `git add -f` |
| Fallback sin git recorre directorios enormes | Solo se usa cuando no hay repo git | n/a |

## 14. Estrategia de ejecucion

1. F0 baseline (T01) — deja evidencia medible del antes.
2. F1 validador + bootstrap (T02, T03, T04) — el juez antes de tocar el resto.
3. F2 artefactos de ejecucion (T05, T06) — reduce el universo a lo distribuible.
4. F3 config de arnes (T07, T08, T09) — la pieza con riesgo de indisponibilidad.
5. F4 scripts y fixture (T10, T11).
6. F5 redaccion documental (T12, T13) — al final, cuando ya se sabe que el test es el juez.
7. F6 CI y cierre (T14, T15).

Paralelizable: T10 y T11 con T07/T08 (archivos disjuntos). T12 no puede paralelizarse con T13 (T13 depende del resultado).
