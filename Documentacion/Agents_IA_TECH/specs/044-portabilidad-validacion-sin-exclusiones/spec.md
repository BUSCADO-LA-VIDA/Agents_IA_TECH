# Spec 044 — Portabilidad real: validación sin exclusiones de directorio

**Feature Branch**: `044-portabilidad-validacion-sin-exclusiones`

**Created**: 2026-11-09

**Status**: Borrador — pendiente de aprobación para pasar a `plan.md`

**Input**: Instrucción del usuario (2026-11-09): _"Por seguridad no excluyas ningún directorio"_. El Spec 039 se cerró declarando AC-1/AC-2 cumplidos, pero su universo de validación era una **lista fija de directorios** (`README.md`, `AGENTS.md`, `scripts/`, `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`). Esa lista dejó fuera `tests/`, `.specify/`, `.mcp.json`, `opencode.json` y `.bootstrap-audit.log`. Resultado: **34 archivos versionados siguen conteniendo rutas absolutas literales**, incluido el fixture `tests/fixtures/baseline-036.md` que disparó la detección del usuario.

**Relación con specs previos**:

| Spec | Relación |
|---|---|
| 039 | Su implementación se conserva, pero **AC-1/AC-2 quedan superados**: el universo pasa de "lista de directorios" a "todo archivo versionado (`git ls-files`)". 039 no se archiva: sigue activa y su test se reescribe aquí. |
| 038 (D2) | Se ejecuta la parte de D2 que habilita esta spec: `opencode.json` deja de contener rutas de la máquina del autor. |
| 007 / ADR-0010 | Reafirma R6: las rutas reales de MCP viven en `.env.mcp` (local, gitignored), nunca en archivos versionados. |
| archived/solucion-generica (RF-S2, RF-S7) | Retoma RF-S7 "grep anti-regresión sobre `git ls-files`", que era el criterio correcto y no se había implementado. |

---

## 1. Defecto detectado (causa raíz)

El test `tests/validate-no-hardcoded-paths.Tests.ps1` define su universo con una **allowlist de rutas**:

```powershell
$distributablePaths = @(
    "$kitRoot\README.md",
    "$kitRoot\AGENTS.md",
    "$kitRoot\scripts\*.ps1",
    "$kitRoot\.github\**\*.md",
    "$kitRoot\.opencode\**\*.md",
    "$kitRoot\.doc_agents\*.md",
    "$kitRoot\Documentacion\**\*.md"
)
```

Consecuencias medidas:

| # | Consecuencia | Efecto observable |
|---|---|---|
| C1 | Todo archivo fuera de la lista es invisible al test | `tests/`, `.specify/`, `.mcp.json`, `opencode.json`, `.bootstrap-audit.log` nunca se validan |
| C2 | El test se autoexcluye (`plataformador-bootstrap.ps1`) por contener los patrones como literales | La lógica de detección queda sin cobertura |
| C3 | Un "verde" del test no implica portabilidad | Falso negativo estructural: green test + kit contaminado |
| C4 | Excluir directorios es una decisión tomada por el autor del test, no una regla del producto | Cada directorio nuevo nace fuera de cobertura por defecto (fail-open) |

**Regla que se fija en esta spec**: el universo de validación es **cerrado por construcción** (`git ls-files`). No hay allowlist de directorios ni de archivos. Un archivo nuevo entra en cobertura automáticamente al ser versionado. Es **fail-closed**: si algo no se puede leer, la validación falla.

---

## 2. Inventario real (evidencia medida)

Comando reproducible (patrones construidos por concatenación para no autoincumplirse):

```powershell
$sep = [IO.Path]::DirectorySeparatorChar
$patterns = @(
  ('C:' + $sep + 'Proyectos'), ('C:' + '/' + 'Proyectos'),
  ('C:' + $sep + 'Users'),     ('C:' + '/' + 'Users'),
  ('D:' + $sep),
  ('/' + 'home' + '/'),
  ('/' + 'Users' + '/')
)
foreach ($p in $patterns) { git grep -I -F -c -e $p -- . }
```

Resultado al 2026-11-09: **34 archivos versionados, 236 coincidencias**. Clasificación por naturaleza y acción:

### 2.1 Artefactos de ejecución (no deben versionarse)

| Archivo | Coincidencias | Naturaleza | Acción |
|---|---:|---|---|
| `.bootstrap-audit.log` | 87 | Log encadenado por hash (append-only) con `host`, `actor`, rutas reales de la máquina | **Dejar de versionar** (`git rm --cached` + `.gitignore`). Reescribirlo rompería la cadena de hashes; versionarlo publica layout del FS y nombre de usuario |
| `.specify/mcp-validation-spec.md` | 15 | Salida de una corrida de validación MCP del autor | **Redactar** (se conserva versionado: es evidencia) |
| `.specify/mcp-validation-plan.md` | 3 | Ídem | **Redactar** |
| `.specify/mcp-validation-tasks.md` | 0 (referencia a rutas relativas) | Ídem | **Redactar** |

### 2.2 Configuración de arnés con rutas resueltas de la máquina del autor

| Archivo | Coincidencias | Contenido | Acción |
|---|---:|---|---|
| `opencode.json` | 12 | `command[]` de 8 MCP con rutas absolutas del perfil, del intérprete y del kit (`<HOME>/...`, `<PYTHON_HOME>/...`, `<KIT_ROOT>/...`) | **Convertir a portable** (nombres en `PATH` + `{env:...}` + rutas relativas al proyecto). Ver D2 |
| `.mcp.json` | 9 | Ídem para el arnés VS Code/Copilot | **Convertir a portable** (nombres en `PATH` + `${workspaceFolder}`) |

### 2.3 Código de detección (contiene los patrones como literales)

| Archivo | Coincidencias | Problema | Acción |
|---|---:|---|---|
| `scripts/plataformador-bootstrap.ps1` | 6 | Los patrones prohibidos están escritos literalmente; el test lo excluye para pasar | Construir patrones por concatenación de fragmentos (R3) |
| `tests/validate-no-hardcoded-paths.Tests.ps1` | 5 | Ídem | Reescritura completa: universo `git ls-files`, patrones por fragmentos (R1-R3) |

### 2.4 Scripts con rutas por defecto de la máquina del autor

| Archivo | Coincidencias | Problema | Acción |
|---|---:|---|---|
| `scripts/sync-mcp-graphify.ps1` | 1 | `[string]$RootPath = "<ruta absoluta del kit>"` | `$RootPath` derivado de `$PSScriptRoot` (raíz del kit) |

### 2.5 Fixture de baseline (disparador del hallazgo)

| Archivo | Coincidencias | Problema | Acción |
|---|---:|---|---|
| `tests/fixtures/baseline-036.md` | 2 | Documenta la ejecución sobre la raíz del kit y la ruta del audit log | **Redactar**: `$KitPath` y `$KitPath/.bootstrap-audit.log`; conservar todas las métricas y hashes (valor probatorio intacto) |

### 2.6 Documentación técnica (PII + rutas del autor)

| Archivo | Coincidencias | Acción |
|---|---:|---|
| `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/plan.md` | 21 | Redactar a notación no literal |
| `.../039-.../converge.md` | 20 | Ídem |
| `Documentacion/Agents_IA_TECH/README-ECOSISTEMA-DOCUMENTACION.md` | 19 | Rutas MCP → `<HOME>/...` |
| `.../039-.../tasks.md` | 19 | Ídem plan |
| `Documentacion/Agents_IA_TECH/seguridad/solucion-generica.md` | 12 | Evidencia de auditoría → redactar |
| `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/threat-model.md` | 10 | Ídem |
| `.../039-.../adr-039-rutas-portables.md` | 7 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/020-mcp-config-operativa/spec.md` | 7 | Tabla de MCPs → `<HOME>/...` |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0009-mcp-hardcoded-workaround.md` | 5 | Ídem |
| `Documentacion/Agents_IA_TECH/testing/validacion-solucion-generica-2026-09-19.md` | 5 | Ídem |
| `Documentacion/Agents_IA_TECH/00-indice.md` | 4 | Describe los patrones → notación no literal |
| `Documentacion/Agents_IA_TECH/specs/archived/solucion-generica/spec.md` | 3 | RF-S2 → notación no literal |
| `.../039-.../spec.md` | 3 | Ídem |
| `Documentacion/Agents_IA_TECH/mantenimiento-indices-mcp.md` | 3 | Rutas MCP → `<HOME>/...` |
| `.../039-.../threat-model-039-hardcoded-paths.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/020-mcp-config-operativa/plan.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/bitacoras/2026-10-11-mcp-github.md` | 2 | Redactar (bitácora histórica, no reescribir conclusiones) |
| `Documentacion/Agents_IA_TECH/specs/archived/000-mcp-integracion/000-mcp-github-integracion/tasks.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/030-whitelist-contextual-por-tipo-proyecto/spec.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/spec.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/bitacoras/2026-10-11-mcp-playwright.md` | 2 | Ídem |
| `CHANGELOG.md` | 2 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/036-sync-kit-paridad-motor/spec.md` | 1 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/archived/002-script-plataforming-sync-kit/tasks.md` | 1 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/qa-report.md` | 1 | Ídem |
| `Documentacion/Agents_IA_TECH/seguridad/007-mcp-token-resolution-threat-model.md` | 1 | Ídem |
| `Documentacion/Agents_IA_TECH/bitacoras/2026-11-02-sync-kit-generator-y-parche-kit-files.md` | 1 | Ídem |
| `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/tasks.md` | 1 | Ídem |

**Nota de método**: en documentación histórica (bitácoras, specs cerradas, ADRs, threat models) la redacción **no altera conclusiones, métricas ni hashes**; solo sustituye el valor de la ruta por su token (`<KIT_ROOT>`, `<HOME>`, `$KitPath`, `%USERPROFILE%`). Es una operación de privacidad, no una reescritura de historia.

---

## 3. Reglas deterministas

| ID | Regla | Verificación |
|---|---|---|
| R1 | El universo de validación es **todo archivo versionado** (`git ls-files`), cero exclusiones de directorio | El test no contiene listas de rutas |
| R2 | Se excluyen únicamente contenidos **no versionados** (`.git/`, artefactos locales) y archivos **binarios** (`git grep -I`) | Justificación técnica, no de conveniencia |
| R3 | Los archivos de detección **no pueden contener los patrones literales**: se construyen por concatenación de fragmentos | El test se valida a sí mismo (auto-inclusión) |
| R4 | Toda ruta real de la máquina vive en `.env.mcp` (local, gitignored) o en un artefacto de runtime gitignored | `git ls-files .env.mcp` = vacío |
| R5 | Los artefactos con `command[]` absoluto se expresan con nombre en `PATH`, `{env:...}` o ruta relativa al proyecto | `opencode.json` y `.mcp.json` legibles en otra máquina sin editar |
| R6 | Un archivo nuevo no requiere registrar nada: entra en cobertura al versionarse | `git add` + test = detectado |

---

## 4. Requisitos funcionales

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01 | `tests/validate-no-hardcoded-paths.Tests.ps1` se reescribe: universo = `git ls-files`, sin allowlist, auto-inclusión del propio test | **Must** |
| RF-02 | Patrones construidos por concatenación (`('C:' + $sep + 'Proyectos')`, `('/' + 'home' + '/')`, etc.) en test y bootstrap | **Must** |
| RF-03 | `scripts/plataformador-bootstrap.ps1 -CheckHardcodedPaths` escanea **todo el proyecto destino versionado** (usa `git ls-files` si hay repo; si no, recorrido completo sin exclusiones) | **Must** |
| RF-04 | `.bootstrap-audit.log` deja de versionarse (`git rm --cached`, regla en `.gitignore`, retirar `!.bootstrap-audit.log`) manteniendo su escritura local | **Must** |
| RF-05 | `.specify/mcp-validation-*.md` se redactan conservando el archivo (evidencia versionada) | **Must** |
| RF-06 | `opencode.json` deja de versionarse: se versiona `opencode.template.json` (tokens `{env:...}` + `enabled: false`) y el bootstrap genera/resuelve el archivo local | **Must** |
| RF-07 | `.mcp.json` deja de contener rutas absolutas: nombres en `PATH` y `${workspaceFolder}` para rutas del proyecto | **Must** |
| RF-08 | `scripts/sync-mcp-graphify.ps1`: `$RootPath` por defecto derivado de `$PSScriptRoot`, sin ruta literal | **Must** |
| RF-09 | `tests/fixtures/baseline-036.md` redactado a `$KitPath`, preservando métricas y hashes | **Must** |
| RF-10 | Documentación del inventario §2.6 redactada a tokens (`<KIT_ROOT>`, `<HOME>`, `%USERPROFILE%`, notación `C:<sep>Proyectos`) | **Must** |
| RF-11 | El test corre en CI y falla el build con cualquier coincidencia; mensaje con `archivo:línea → contenido` | **Must** |
| RF-12 | El bootstrap informa `[OK] 0 coincidencias en N archivos versionados` o lista las coincidencias y sale con código ≠ 0 | **Should** |

## 5. Requisitos no funcionales

| ID | Requisito |
|---|---|
| NFR-01 | El kit se clona en cualquier ruta y arnés (unidad ajena, home POSIX o home de macOS) y arranca sin editar archivos versionados |
| NFR-02 | Coste del test: < 10 s sobre 769 archivos versionados |
| NFR-03 | Cero regresiones en `tests/harness-default.ps1`, `tests/kit-sync-merge.ps1`, `tests/kb-parity.ps1`, `tests/mcp-refresh-parity.ps1`, `tests/agents-parity.ps1` |
| NFR-04 | El arnés en ejecución no se rompe: `opencode.json` resultante debe seguir siendo JSON válido y arrancar los MCP declarados en esta máquina |
| NFR-05 | Toda decisión de privacidad en docs es trazable: cada archivo redactado deja constancia del token usado |

---

## 6. Decisiones

| ID | Decisión | Justificación | Consecuencia |
|---|---|---|---|
| D1 | Universo = `git ls-files` | Cierra por construcción el fail-open de C4 y la lista de C1; coincide con archived/solucion-generica RF-S7 | El test deja de tener listas de paths |
| D2 | `opencode.json` **no se versiona**; se versiona `opencode.template.json` con tokens y `enabled: false` | Es config resuelta por máquina (spec 038 D2). Versionarla publica el layout del FS y se recontamina en cada bootstrap | El bootstrap copia la plantilla cuando falta `opencode.json` y la re-resolución promueve a rutas locales; un clon nuevo debe correr el bootstrap |
| D3 | `.bootstrap-audit.log` deja de versionarse, no se reescribe | Es append-only con cadena de hashes: reescribir destruye la evidencia. Versionarlo publica `host`, `actor` y layout del FS | El log sigue local; un clon nuevo empieza su propia cadena |
| D4 | `.specify/mcp-validation-*.md` se redactan, no se eliminan | Son evidencia versionada: borrarlas destruye trazabilidad de la validación MCP previa | Se conservan en el repo con rutas sustituidas por tokens |
| D5 | La redacción de docs históricas no altera conclusiones | Preserva trazabilidad de auditoría | Solo cambian literales de ruta |
| D6 | Sin exclusiones de directorio; sí exclusión de **binarios** | Un binario no es documentación ni configuración legible | `git grep -I` |

---

## 7. Criterios de aceptación

| ID | Criterio | Comando de verificación | Esperado |
|---|---|---|---|
| AC-1 | Cero rutas absolutas literales en **todo archivo versionado** | test Pester (RF-01) | `0` coincidencias |
| AC-2 | El test **no** contiene allowlist de directorios | revisión de `tests/validate-no-hardcoded-paths.Tests.ps1` | sin arrays de rutas; solo `git ls-files` |
| AC-3 | El test **se incluye a sí mismo** | grep del propio fichero en el universo | presente y limpio |
| AC-4 | Ningún archivo versionado (incluidos los `.specify/mcp-validation-*`) contiene rutas de la máquina del autor | test Pester (RF-01) | vacío |
| AC-5 | `.bootstrap-audit.log` no versionado y sigue escribiéndose local | `git ls-files .bootstrap-audit.log` → vacío; `Test-Path .bootstrap-audit.log` → `True` | cumplido |
| AC-6 | `opencode.json` arranca el arnés en esta máquina | `opencode` arranca con `default_agent: pensador` y los 8 MCP | sin errores |
| AC-7 | Bootstrap con `-CheckHardcodedPaths` en un proyecto limpio | `.\scripts\plataformador-bootstrap.ps1 -CheckHardcodedPaths -DryRun` | `[OK] 0 coincidencias` |
| AC-8 | Bootstrap detecta un señuelo | crear `.tmp-señuelo.md` con la ruta literal y ejecutar `-CheckHardcodedPaths` | exit ≠ 0 + `archivo:línea` |
| AC-9 | Suites existentes sin regresión | `pwsh -File tests/harness-default.ps1`; `kit-sync-merge`; `kb-parity`; `mcp-refresh-parity` | exit 0 |
| AC-10 | CI falla si se reintroduce una ruta | PR con señuelo | workflow rojo |

---

## 8. Fases de implementación

| Fase | Contenido | Agente |
|---|---|---|
| F0 | Baseline: ejecutar el test actual y guardar la lista de 34 archivos como evidencia previa | `qa-senior` |
| F1 | Reescribir test (RF-01, RF-02, RF-11) y bootstrap (RF-03, RF-12) | `qa-senior` + `plataformador` |
| F2 | Artefactos de ejecución: audit log, `.specify/mcp-validation-*` (RF-04, RF-05) | `plataformador` |
| F3 | Config de arnés portable: `opencode.json`, `.mcp.json` (RF-06, RF-07) + verificación de arranque (AC-6) | `plataformador` |
| F4 | Scripts (RF-08) y fixture (RF-09) | `plataformador` + `qa-senior` |
| F5 | Redacción documental (RF-10) | `documentador` |
| F6 | Validación final, CI y cierre (AC-1..AC-10) | `qa-senior` + `gitflow` |

**Orden obligatorio**: F1 antes de F2-F5 (el test es el juez). F5 al final para no redactar dos veces.

---

## 9. Riesgos y rollback

| Riesgo | Probabilidad | Impacto | Mitigación | Rollback |
|---|---|---|---|---|
| `opencode.json` portable rompe el arranque del arnés | Media | Alto | Probar en copia; mantener `.env.mcp` con las rutas reales; si un MCP no resuelve, dejarlo con `enabled: false` + WARN documentado | `git checkout -- opencode.json` |
| `git rm --cached .bootstrap-audit.log` se percibe como pérdida de evidencia | Baja | Medio | El archivo permanece en disco; se documenta en bitácora y en `CHANGELOG` | `git add -f .bootstrap-audit.log` |
| Redacción masiva de docs altera texto normativo | Baja | Medio | Solo se sustituyen literales de ruta; diff revisado por `documentador` y `security-auditor` | `git revert` del commit de F5 |
| El test `git ls-files` falla en un directorio sin repo git | Media | Bajo | Fallback a recorrido completo sin exclusiones | n/a |

---

## 10. Tareas

| ID | Tarea | Agente | Depende de |
|---|---|---|---|
| T01 | Baseline F0: capturar las 34 rutas + 236 coincidencias en `tests/fixtures/portabilidad-baseline.md` | `qa-senior` | — |
| T02 | Reescribir `tests/validate-no-hardcoded-paths.Tests.ps1` (universo `git ls-files`, patrones por fragmentos, auto-inclusión) | `qa-senior` | T01 |
| T03 | Añadir fallback sin git (recorrido completo, sin exclusiones) | `qa-senior` | T02 |
| T04 | Reescribir `-CheckHardcodedPaths` en el bootstrap (todo el proyecto, patrones por fragmentos, exit ≠ 0) | `plataformador` | T02 |
| T05 | `git rm --cached .bootstrap-audit.log`; `.gitignore`: quitar `!.bootstrap-audit.log`, añadir la regla de ignorado | `plataformador` | T02 |
| T06 | Redactar `.specify/mcp-validation-*.md` (conservar versionados) | `plataformador` | T05 |
| T07 | Portabilizar `opencode.json` (MCP por nombre en PATH, `{env:}`, relativas) y validar JSON | `plataformador` | T02 |
| T08 | Portabilizar `.mcp.json` (`PATH` + `${workspaceFolder}`) | `plataformador` | T07 |
| T09 | Verificar arranque del arnés con la config portable (AC-6) y documentar el resultado | `plataformador` | T08 |
| T10 | `scripts/sync-mcp-graphify.ps1`: `$RootPath` por defecto desde `$PSScriptRoot` | `plataformador` | T02 |
| T11 | Redactar `tests/fixtures/baseline-036.md` a `$KitPath` preservando métricas y hashes | `qa-senior` | T02 |
| T12 | Redactar los 24 archivos de documentación del inventario §2.6 | `documentador` | T02 |
| T13 | Actualizar `CHANGELOG.md` y `00-indice.md` con 044 | `documentador` | T12 |
| T14 | Configurar CI: workflow que ejecute el test y falle en rojo | `qa-senior` | T02 |
| T15 | Validación final AC-1..AC-10 + bitácora + commit conventional | `qa-senior` + `gitflow` | T03-T14 |

---

## 11. Notas

- Esta spec **no archiva la 039**: la deja activa y le amplía el criterio de aceptación. El cierre de 039 con pendientes fue el error que originó 044.
- La regla R1 es la que evita repetir el fallo: no se puede "arreglar" el test añadiendo un directorio a la lista, porque no hay lista.
- `opencode.json` portable es la única pieza con riesgo de indisponibilidad del arnés; por eso se implementa en copia y con rollback explícito (D2, §9).
- Toda la evidencia de esta spec se mide con el mismo comando reproducible de §2.

---

## 12. Fuera de alcance (specs separadas, decisión del usuario 2026-11-09)

| Cambio detectado durante la implementación | Spec | Motivo de la separación |
|---|---|---|
| El hook `context-mode` denegaba lecturas mayores de 16 KB y se reportaba como caída total de herramientas | **045** | Es un incidente operativo del arnés, no un problema de portabilidad del kit |
| La generación de `opencode.json` hereda rutas absolutas del maestro y no regenera `graphify`/`tokenslayer` por destino | **046** | Es un defecto del generador, no del validador de portabilidad |

Esta spec se limita a: universo de validación sin exclusiones, patrones, remediación de los archivos detectados y CI.

Las bitácoras y documentos de las specs 045 y 046 no forman parte del alcance de la 044.

