# Converge 034 — Cierre del ciclo SSD+Speckit del arranque por defecto

## 1. Estado del ciclo

| Fase | Artefacto | Estado | Observaciones |
|---|---|---|---|
| Specify | `spec.md` | ✅ Completo | 18+ secciones, 19 FR, 7 NFR, 4 US, 15 CA, 9 decisiones (D-01..D-09), sección 19 de política de propagación |
| Plan | `plan.md` | ✅ Completo | Decisiones D1-D4 + D-07..D-09, mapeo FR/CA → componente → verificación, orden de implementación |
| Tasks | `tasks.md` | ✅ Completo | 20 tareas (T01-T20) en dos mitades; T14-T20 = mitad de propagación |
| Analyze | `analyze.md` | ✅ Completo | 19/19 FR con evidencia, 15/15 CA verificados, Constitución 5/5 PASS, defectos B-01/B-02 documentados en §6bis |
| Threat Model | `threat-model.md` | ✅ Completo | DFD, STRIDE completo, 11 riesgos (TM-01..TM-11), TM-04 cerrado, sin residual Medio |
| Implement | T01-T08 | ✅ Cerradas | Configuración, regla, test, `VAL-10`, bootstrap, higiene, README |
| Implement | T14-T20 | ✅ Cerradas | Mitad de propagación: marcadores, comparador local + merge por claves, regla de `default_agent`, `Merge-KitBlock`, whitelist de tests, `.gitignore`, `tests/kit-sync-merge.ps1` |
| Implement | T09-T11 | ✅ Cerradas | Analyze, threat model y converge |
| Gate | T13 | ✅ Ejecutado | Validador y ambos tests de contrato en verde (salida literal en §3) |
| Indexación | T12 | ✅ Cerrada | `00-indice.md` actualizado con la ampliación FR-14..FR-19 |

## 2. Cambios producidos

| Archivo | Cambio | Evidencia |
|---|---|---|
| `opencode.json` | `"default_agent"`: `build` → `pensador` (1 línea) | Lectura L5; `git diff --stat` = 2 ± |
| `AGENTS.md` | Sección `## Arranque por defecto del arnés` + matriz de enrutamiento (26 líneas) | Lectura L117-L141 |
| `.github/copilot-instructions.md` | Bloque de enrutamiento al agente del kit (7 líneas), sigue siendo puntero | `git diff --stat` |
| `README.md` | Sección "🚀 Arranque por defecto del arnés" (151 líneas) | `git diff --stat` |
| `scripts/plataformador-bootstrap.ps1` | `Ensure-OpenCodeDefaultAgent` + invocación (85 líneas) | Parseo OK; 6 casos aislados |
| `scripts/validate-agents-skills.ps1` | `VAL-10` (114 líneas) + fix de `Get-CanonicalTiers` | Validador: 10 chequeos |
| `tests/harness-default.ps1` | Nuevo test de contrato con fixture negativo | Exit 0 real; fixture exit 1 |
| `.opencode/agents/pensador/spec.md` | Eliminado (188 líneas obsoletas) | Listado del directorio: 13 agentes, sin carpeta `pensador\` |

### Mitad de propagación (T14-T20)

| Archivo | Cambio | Evidencia |
|---|---|---|
| `AGENTS.md` (raíz) | Sección de arranque envuelta en `<!-- KIT-BLOCK:START/END arranque-por-defecto -->` (L117/L143) | `grep KIT-BLOCK` en `AGENTS.md` |
| `scripts/sync-kit.ps1` | `Compare-KitFileState` (L466, corrige B-01/B-02), `Merge-OpenCodeConfig` (L512), `Merge-KitBlock` (L725); enganches `[MERGE]` (L1056/L1061); whitelist de tests (L1085) | `grep` + lectura; `PARSE-OK` |
| `scripts/sync-kit.ps1` | Ramas `[MERGE]` hacen `continue` antes de la regla SKIP; eliminado el guard viejo de `$merged` en la rama `Copy-Item`; sin código muerto | Lectura del bloque L1052-1078 |
| `.gitignore` | `+ opencode.json.bak-*` y `AGENTS.md.bak-*` | `git diff .gitignore` |
| `tests/kit-sync-merge.ps1` | Test plano (exit 0/1), 7 escenarios, fixtures en `$env:TEMP`, no escribe en el repo | `OK: 7 escenarios`, exit 0; `git status` sin cambios |

## 3. Gate de cierre

| Check | Comando | Resultado |
|---|---|---|
| Validador del kit | `pwsh -NoProfile -File scripts/validate-agents-skills.ps1` | `10 chequeos | OK: 9 | WARN: 1 | FAIL: 0`, exit 0 |
| `VAL-10` | incluido en el validador | `[OK] default_agent = 'pensador', agente del kit presente y con mode: primary` |
| `VAL-04` | incluido en el validador | `[OK] ... (Documental, Documental extendido, Implementador, Tooling, Plataforma)` |
| Test de contrato (local) | `pwsh -NoProfile -File tests/harness-default.ps1` | exit 0 |
| Fixture negativo (local) | incluido en el test | degradación a `build` detectada |
| Test de contrato (propagación) | `pwsh -NoProfile -File tests/kit-sync-merge.ps1` | **`OK: 7 escenarios`**, exit 0 |
| Parseo de scripts | `Parser::ParseFile` sobre `sync-kit.ps1` y `tests/kit-sync-merge.ps1` | `PARSE-OK` en ambos |
| Permisos intactos | `git diff --stat` | 0 cambios en frontmatter de agentes |
| No escritura en el repo por los tests | `git status --porcelain` antes/después | idéntico; sin backups ni archivos residuales |

Salida literal de la verificación de ejecución de la mitad de propagación (corrida por el developer en esta iteración):

```text
=== kit-sync-merge (spec 034): contrato de merge del sync del kit ===
[PASS] 1a Compare: identicos -> Equal
[PASS] 1b Compare: LF vs CRLF mismo contenido -> EolOnly
[PASS] 1c Compare: contenido distinto -> Different
[PASS] 1d Compare: BOM en uno solo -> Different
[PASS] 2a .. 2i Merge por claves (JSON válido, default_agent, 8 servidores mcp, $schema, instructions)
[PASS] 3a..3e default_agent (ausente/build/inexistente -> pensador; kit+primary -> preserva; -Force)
[PASS] 4a..4c idempotencia (segunda pasada byte-idéntica, sin backup nuevo)
[PASS] 5a..5f migración de sección sin marcadores
[PASS] 6a..6c marcadores presentes -> reemplazo
[PASS] 7a..7b marcadores corruptos -> fail-closed sin escribir
OK: 7 escenarios
EXIT=0
```

```text
=== harness-default (spec 034): arranque por defecto del arnes ===
--- Verificacion sobre el estado real ---
OK: arranque valido (pensador, primary, regla presente en ambos arneses)
--- Fixture negativo: default_agent = build ---
OK: el fixture negativo detecto la degradacion a build
RESULTADO: OK
EXIT=0
```

```text
PARSE-OK scripts/sync-kit.ps1
PARSE-OK tests/kit-sync-merge.ps1
```

### Verificación end-to-end de CA-14 (2026-11-01)

**Destino real (consumidor del kit):** `C:\Proyectos\Generator_IA_Projects`. Checkout válido del kit (presenta `scripts/`, `.github/`, `.opencode/`, `AGENTS.md`; también `sync-agents.ps1`, `opencode.json`, `Documentacion/`, `src/`).

**Comando ejecutado** (dry-run del motor con `-KitPath` = fuente local del kit para incluir los cambios sin pushear de la iteración 034; NO clona GitHub, NO escribe en el consumidor):

```powershell
pwsh -NoProfile -File C:\Proyectos\Agents_IA_TECH\scripts\sync-kit.ps1 -DryRun -RootPath C:\Proyectos\Generator_IA_Projects -KitPath C:\Proyectos\Agents_IA_TECH -OrphanAction Conservar
```

**Salida literal completa (exit code 0):**

```text
[STEP] sync-kit: sincronizando kit transversal en C:\Proyectos\Generator_IA_Projects
[STEP] Sincronizando kit transversal desde https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH...
[INFO] DryRun: fuente LOCAL del kit: C:\Proyectos\Agents_IA_TECH (sin clonar GitHub; incluye rama y cambios locales sin pushear)
[INFO] DryRun: copiaria .github/ -> C:\Proyectos\Generator_IA_Projects\.github\
[INFO] DryRun: copiaria .opencode/ -> C:\Proyectos\Generator_IA_Projects\.opencode\
[INFO] DryRun: copiaria .doc_agents/ -> C:\Proyectos\Generator_IA_Projects\.doc_agents\
[INFO] DryRun: copiaria scripts/ -> C:\Proyectos\Generator_IA_Projects\scripts\
[INFO] DryRun: copiaria .specify/memory/constitution.md -> C:\Proyectos\Generator_IA_Projects\.specify\memory\constitution.md
[INFO] DryRun: copiaria AGENTS.md -> C:\Proyectos\Generator_IA_Projects\AGENTS.md
[INFO] DryRun: copiaria opencode.json -> C:\Proyectos\Generator_IA_Projects\opencode.json
[INFO] DryRun: copiaria README.md -> C:\Proyectos\Generator_IA_Projects\README.md
[INFO] DryRun: copiaria sync-agents.ps1 -> C:\Proyectos\Generator_IA_Projects\sync-agents.ps1
[INFO] DryRun: copiaria upgrade_framework.ps1 -> C:\Proyectos\Generator_IA_Projects\upgrade_framework.ps1
[INFO] DryRun: excluiria .opencode/config.json (posibles credenciales, nunca se copia)
[INFO] DryRun: hash-guard .opencode/.gitignore: si el local existe y difiere del maestro se CONSERVA el local (fail-closed); solo -Force sobrescribe
[INFO] DryRun: NUNCA tocaria Documentacion/<AppName>/ (frontera kit <-> app)
[INFO] DryRun: copiaria la whitelist de tests del kit: tests/harness-default.ps1, tests/kit-sync-merge.ps1, tests/agents-parity.ps1, tests/kb-parity.ps1, tests/mcp-refresh-parity.ps1
[INFO] DryRun: NO trataria tests/ como directorio transversal (los tests propios de la app no se tocan)
[INFO] DryRun: detectaria huerfanos y aplicaria -OrphanAction Conservar

===============================================================
 RESUMEN DE LA EJECUCION (sync-kit)
===============================================================
 WARNs: 0
 ERRORs: 0
===============================================================
===EXITCODE: 0===
```

**Estado real del `opencode.json` del consumidor** (solo lectura, sin modificar; datos sobre los que el merge actuaría):

| Clave | Valor real en el consumidor | observación |
|---|---|---|
| `default_agent` | `build` | **Difiere** del maestro del kit (`pensador`): en un sync real, `Merge-OpenCodeConfig` (R-034/F-15) lo tomaría del maestro |
| `mcp` (presente) | `mcp` con `timeout`, `servers`, `graphify` | Se **conserva** por diseño del merge por claves (el maestro no lo gestiona); no se perdería |
| notas de interpretación | — | `Merge-OpenCodeConfig` preserva también `model`, `small_model`, `permission`, `lsp` y claves desconocidas del local; edita textualmente y preserva BOM + fin de línea del consumidor |

**Alcance de la confirmación y límite honesto:**

- El dry-run (bloque L903-L921 del motor) **sí** confirma de forma literal: (1) la whitelist de los 5 tests del kit viaja en el set transversal, (2) `opencode.json` y `AGENTS.md` están en el set transversal como ítems gestionados (aparecen como `copiaria`, no como error ni `SKIP`), (3) exit 0 con 0 WARN / 0 ERROR.
- El bloque dry-run **retorna antes** de la iteración por ítem, por lo que **no emite líneas literales `[MERGE]`**. El merge por claves / por bloque en un destino real se confirma por **lectura del motor**: rama `[MERGE]` en L1052-L1064 (hace `continue` antes de la regla SKIP, aplica con y sin `-Force`) y las funciones `Merge-OpenCodeConfig` (L512) y `Merge-KitBlock` (L725), además del contrato ya verde en `tests/kit-sync-merge.ps1` (`OK: 7 escenarios`, exit 0). No se ejecutó un sync real (modificador) sobre el consumidor por ser otra app; ese paso queda reservado a un ejecutor autorizado.

## 4. Hallazgo relevante del ciclo

Durante la implementación se detectó una **regresión silenciosa del gate**: la matriz de enrutamiento agregada a `AGENTS.md` cumplía el patrón que `Get-CanonicalTiers` usaba para derivar los tiers canónicos, con lo que `VAL-04` pasó de validar 5 tiers a validar ~35 entradas arbitrarias, **manteniendo el `[OK]`**. Un gate que aprueba cualquier cosa sin avisar es peor que un gate ausente.

Se corrigió en el mismo ciclo: el parseo de tiers ahora se ancla en la cabecera `| Tier | Agents |` y corta al abandonar esa tabla. Verificado con 5 casos (tabla real con tablas ajenas antes y después, sin cabecera, archivo inexistente, tabla de 2 filas, `AGENTS.md` real): en todos devuelve exactamente los 5 tiers canónicos.

### Hallazgo adicional de la mitad de propagación: defectos B-01 y B-02 (spec §19.5)

Al analizar la ampliación se detectaron dos defectos **bloqueantes** en la rama de archivos de raíz del sync, ambos corregidos e implementados:

- **B-01 (CommandNotFoundException)**: el sync llamaba a `Compare-KitFileContent`, función inexistente en `scripts/sync-kit.ps1` (solo vive en `scripts/sync-kit-lib.ps1`, spec 029, sin dot-source). Con `$ErrorActionPreference = "Stop"`, cada llamada lanzaba una excepción, el try externo la capturaba y el sync **abortaba en el primer archivo de raíz**, sin propagar nada. Se corrigió con el comparador local `Compare-KitFileState` (L466).
- **B-02 (desalineamiento de contrato)**: incluso con dot-source, el contrato no coincidía (`'Equal'/'EolOnly'` vs `$true/$false`), por lo que toda comparación caía en `[SKIP]`. `Compare-KitFileState` devuelve exactamente el contrato que el motor espera (`'Equal' | 'EolOnly' | 'Different'`), y está fijado por los escenarios 1a-1d del test T20.

Junto con la corrección: los enganches `[MERGE]` de `opencode.json` y `AGENTS.md` hacen `continue` antes de la rama SKIP (aplican con y sin `-Force`), y se eliminó el guard viejo de `$merged` que quedaba dentro de la rama `Copy-Item` (sin código muerto). El cambio de arranque pasó a ser reproducible y propagado, no una edición forzada.

## 5. Limitaciones de verificación

| Limitación | Causa | Alcance | Mitigación aplicada |
|---|---|---|---|
| No se ejecutó `plataformador-bootstrap.ps1` completo sobre un proyecto real | Requiere un proyecto de prueba y escribe sobre él; no autorizado en este ciclo | FR-07 completo | Función extraída del AST y ejecutada sobre 6 escenarios temporales; parseo del script completo |
| El fix de `Get-CanonicalTiers` no tiene caso en la suite Pester | La suite `tests/validate-agents-skills.Tests.ps1` no cubre esa función | Prevención de regresión futura | Verificación manual con 5 casos; deuda registrada en `analyze.md` §6 |
| El `pensador` no puede ejecutar comandos arbitrarios | Su `permission.bash` solo permite `git status/log/diff` y `scripts/validate-*` | Ejecución directa de los tests de contrato (`harness-default.ps1`, `kit-sync-merge.ps1`) | Delegación al developer/QA a través de la sesión heredada, con salida literal reportada y verificada por lectura |
| `tests/kit-sync-merge.ps1` (T20) fuera del dominio del pensador | Es un ejecutable del developer/QA; el análisis documenta el diseño pero no puede correrlo | Verificación de la mitad de propagación | El developer ejecutó el test en esta iteración: `OK: 7 escenarios`, exit 0, y `git status` tras ejecutar sin cambios (no escribe en el repo) |
| ~~No se ejecutó `sync-agents.ps1 -DryRun` completo contra un proyecto consumidor~~ **Satisfecha** | Requería un destino consumidor real; el usuario confirmó `C:\Proyectos\Generator_IA_Projects` como consumidor del kit. Ejecutado el dry-run con el motor del kit local (`-KitPath`) para incluir los cambios sin pushear de la iteración 034 | Verificación de CA-14 de punta a punta | Dry-run ejecutado el 2026-11-01 sobre `C:\Proyectos\Generator_IA_Projects` con el motor `C:\Proyectos\Agents_IA_TECH\scripts\sync-kit.ps1 -DryRun -RootPath <consumidor> -KitPath <kit> -OrphanAction Conservar`, exit 0 con 0 WARN / 0 ERROR. La salida confirma la whitelist de 5 tests del kit y que `opencode.json` / `AGENTS.md` viajan en el set transversal (detalle completo en §3, bloque "Verificación end-to-end de CA-14"). Nota: el bloque dry-run del motor (L903-L921) retorna antes de la iteración por ítem, por lo que la confirmación del merge por claves/bloque es por lectura de la rama `[MERGE]` (L1052-L1064) y de `Merge-OpenCodeConfig`/`Merge-KitBlock`; sin errores ni fallos en el dry-run |

## 6. Riesgo residual abierto

**TM-04 (cerrado en esta ampliación).** El `.gitignore` ahora incluye `opencode.json.bak-*` y `AGENTS.md.bak-*` (bloque 034), por lo que los backups del bootstrap y del sync quedan fuera de git. Residual tras cierre: **Bajo**.

Los riesgos nuevos de la mitad de propagación (TM-09 a TM-11 en `threat-model.md`) quedan todos en residual **Bajo**: SKIP silencioso de raíz eliminado por diseño (merge), edición textual del JSON mitigada con validación final + restore del backup + fail-closed, y aborto por función inexistente (B-01/B-02) mitigado con el comparador local `Compare-KitFileState` fijado por test y parseo.

## 7. Criterio de cierre

La spec 034 queda **ACTIVA** en `specs/` con este estado:

- Especificación completa: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `converge.md`.
- Implementación completa: T01-T08 (mitad local) y T14-T20 (mitad de propagación) cerradas con evidencia.
- Gate en verde y sin regresiones: 10 chequeos, FAIL 0; `harness-default.ps1` exit 0 (fixture negativo operativo); `kit-sync-merge.ps1` `OK: 7 escenarios`, exit 0; `PARSE-OK` en ambos scripts.
- Constitución: 5/5 PASS.
- Riesgos: 10 de 11 con residual Bajo; TM-04 cerrado; sin residual Medio abierto.

No se archiva: la spec permanece activa, según el ciclo de vida vigente del kit.

## 8. Próximos pasos

1. ~~Agregar la regla `opencode.json.bak-*` a `.gitignore`~~ **hecho en T19** (también `AGENTS.md.bak-*`); cierra TM-04.
2. Incorporar a `tests/validate-agents-skills.Tests.ps1` un caso que fije `Get-CanonicalTiers` frente a tablas ajenas (cierra la deuda de `analyze.md` §6).
3. Ejecutar el bootstrap completo en un proyecto de prueba y verificar el estado final de `opencode.json` (cierra la limitación de verificación de FR-07).
4. ~~Ejecutar `sync-agents.ps1 -DryRun` contra un proyecto consumidor para confirmar CA-14 de punta a punta (whitelist de tests + merge por claves/bloque en un destino real)~~ **hecho** el 2026-11-01 sobre `C:\Proyectos\Generator_IA_Projects` (ver bloque "Verificación end-to-end de CA-14" en §3). El dry-run del motor del kit local terminó con exit 0 y confirmó la whitelist de 5 tests en el set transversal; el merge por claves/bloque quedó confirmado por lectura de la rama `[MERGE]` (el bloque dry-run retorna antes de iterar por ítem). No se ejecutó un sync real (no modificador) sobre el consumidor por ser otra app: el merge se valida via test `kit-sync-merge.ps1` + lectura del motor.
5. Revisar el estado de las specs 029 y 030, que siguen abiertas según `00-indice.md`.
