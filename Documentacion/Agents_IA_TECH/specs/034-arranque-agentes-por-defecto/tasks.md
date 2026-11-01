# Tasks 034 — Arranque por defecto con agentes del kit

## Estado general

20 tareas (T01-T20), en dos mitades. **Mitad local** (T01-T08): configuración de arranque, verificación, aseguramiento en el montaje y documentación. **Mitad de propagación** (T14-T20): que ese cambio llegue a los proyectos consumidores por `scripts/sync-kit.ps1`, no por edición manual. T09-T13 son los artefactos del ciclo y el gate.

Cada tarea tiene criterio de aceptación verificable, no una afirmación.

### Por qué existe la segunda mitad

`sync-kit.ps1` sincroniza directorios con `robocopy /E` (`.github/`, `.opencode/`, `.doc_agents/`, `scripts/`) y archivos de raíz con una regla todo-o-nada: si el contenido es idéntico → `[OK]`, si difiere → `[SKIP]` y no escribe. Consecuencias medidas:

| Archivo | Mecanismo actual | ¿Llega al proyecto? |
|---|---|---|
| `.github/copilot-instructions.md` | `robocopy /E` sobre `.github/` | Sí |
| `scripts/validate-agents-skills.ps1` (VAL-10) | `robocopy /E` sobre `scripts/` | Sí |
| `scripts/plataformador-bootstrap.ps1` | idem | Sí |
| `opencode.json` (`default_agent`) | archivo raíz + regla SKIP | **No**: siempre difiere por el `mcp` local |
| `AGENTS.md` (sección nueva) | archivo raíz + regla SKIP | **No**: si el proyecto lo adaptó, difiere |
| `tests/harness-default.ps1` | no está en el manifiesto | **No**, nunca |

El resultado es un gate que **detecta** el problema (VAL-10 viaja en `scripts/`) pero no lo **repara**. T14-T19 cierran esa asimetría.

## Tareas

### T01 — Declarar `default_agent` con `pensador` en `opencode.json`

- **Agente asignado:** `developer`
- **Dependencias:** ninguna
- **Contenido:** cambiar `"default_agent": "build"` por `"default_agent": "pensador"` en `opencode.json`, conservando el resto de claves y el bloque `mcp` intacto. Backup previo del archivo.
- **Criterio de aceptación:** `opencode.json` es JSON válido; `default_agent` vale `pensador`; `mcp.servers` conserva los 8 MCP; no se reordena ninguna otra clave.
- **Estado:** Cerrada (verificado por lectura + `tests/harness-default.ps1` exit 0).

### T02 — Declarar la regla de arranque en `AGENTS.md`

- **Agente asignado:** `developer`
- **Dependencias:** ninguna
- **Contenido:** agregar la sección `## Arranque por defecto del arnés` con el texto normativo de la spec §10.2: arranque en OpenCode, arranque en VS Code, respeto de mecanismos nativos y flujo SSD+Speckit idéntico en ambos arneses.
- **Criterio de aceptación:** la sección existe, contiene las cuatro viñetas normativas y no duplica el cuerpo de reglas de `REGLA`/`Core facts`.
- **Estado:** Cerrada (sección en `AGENTS.md` + marcadores `KIT-BLOCK` aplicados).

### T03 — Enrutar `.github/copilot-instructions.md` al agente del kit

- **Agente asignado:** `pensador` (dominio `.github/**`)
- **Dependencias:** T02
- **Contenido:** mantener el archivo como puntero y agregar el recordatorio de enrutamiento: la sesión arranca con el agente del kit que corresponda a la tarea, según `AGENTS.md`; los agentes custom aparecen en el dropdown de VS Code.
- **Criterio de aceptación:** el archivo sigue declarando `AGENTS.md` como fuente de verdad única; agrega el enrutamiento sin duplicar reglas base.
- **Estado:** Cerrada (verificado por lectura + `tests/harness-default.ps1`).

### T04 — Crear `tests/harness-default.ps1`

- **Agente asignado:** `developer`
- **Dependencias:** T01, T02, T03
- **Contenido:** script PowerShell plano (exit 0/1) que verifique: `default_agent` existe y vale `pensador`; `.opencode/agents/pensador.md` existe y declara `mode: primary`; `AGENTS.md` contiene la sección de arranque; `.github/copilot-instructions.md` remite a `AGENTS.md`; `.opencode/agents/pensador/spec.md` no existe. Incluir fixture negativo que copie `opencode.json` a temporal con `default_agent: build` y confirme que se detecta.
- **Criterio de aceptación:** exit 0 sobre el estado real; exit 1 sobre el fixture negativo; sin dependencia de Pester.
- **Estado:** Cerrada (`tests/harness-default.ps1` exit 0, fixture negativo detecta `build`).

### T05 — Incorporar `VAL-10` al validador

- **Agente asignado:** `developer`
- **Dependencias:** T01, T04
- **Contenido:** agregar el chequeo `VAL-10 — arranque por defecto válido` en `scripts/validate-agents-skills.ps1`, con severidad FAIL: falla si `default_agent` falta, vale `build`, apunta a un agente inexistente o a un agente sin `mode: primary`.
- **Criterio de aceptación:** el validador reporta 10 chequeos; `VAL-10` en OK sobre el estado real; FAIL cuando se fuerza `build`; exit code 1 en ese caso.
- **Estado:** Cerrada (`validate-agents-skills.ps1` con `VAL-10` en OK, FAIL: 0).

### T06 — Asegurar el arranque desde el bootstrap

- **Agente asignado:** `developer`
- **Dependencias:** T01, T05
- **Contenido:** en `scripts/plataformador-bootstrap.ps1`, agregar el aseguramiento de `default_agent`: si falta o vale `build`, escribir `pensador`; si vale otro agente del kit, respetarlo; backup previo; validación JSON tras escribir; soporte `-DryRun`.
- **Criterio de aceptación:** `-DryRun` reporta la acción sin escribir; dos ejecuciones seguidas no duplican la clave; el bloque `mcp` queda intacto.
- **Estado:** Cerrada (`Ensure-OpenCodeDefaultAgent` en `plataformador-bootstrap.ps1`, 6 escenarios aislados + `PARSE-OK`).

### T07 — Higiene: retirar `.opencode/agents/pensador/spec.md`

- **Agente asignado:** `pensador` (dominio `.opencode/**`)
- **Dependencias:** ninguna
- **Contenido:** mover el contenido útil a `Documentacion/Agents_IA_TECH/` si aporta algo y eliminar la carpeta `.opencode/agents/pensador/`, que no es un agente y confunde el descubrimiento.
- **Criterio de aceptación:** `Test-Path .opencode/agents/pensador/spec.md` devuelve `False`; ningún agente del kit queda sin su archivo `.md` en `.opencode/agents/`.
- **Estado:** Cerrada (`.opencode/agents/pensador/spec.md` eliminado, verificado con `git status`).

### T08 — Documentar el arranque en `README.md`

- **Agente asignado:** `pensador` (dominio `**README.md`)
- **Dependencias:** T01, T02, T03
- **Contenido:** sección "Arranque por defecto" con: `default_agent: pensador` en OpenCode, comportamiento en VS Code, setting `chat.useCustomizationsInParentRepositories` para monorepos, y cómo cambiar de agente cuando el `pensador` deniega una edición.
- **Criterio de aceptación:** la sección existe, explica los tres arneses y no deja placeholders.
- **Estado:** Cerrada (sección de arranque en `README.md`, +151 líneas).

### T09 — Analyze cross-artifact

- **Agente asignado:** `arquitecto`
- **Dependencias:** T01..T08
- **Contenido:** `analyze.md` con matriz de trazabilidad FR/CA, Constitución Check y detección de vacíos.
- **Criterio de aceptación:** 13/13 FR y 11/11 CA mapeados; Constitución PASS; sin placeholders.
- **Estado:** Cerrada (ver `analyze.md`).

### T10 — Threat model

- **Agente asignado:** `security-auditor`
- **Dependencias:** T01..T08
- **Contenido:** `threat-model.md` con DFD, matriz STRIDE y registro de riesgos del arranque por defecto.
- **Criterio de aceptación:** matriz STRIDE completa con las 6 categorías; riesgos con mitigación y riesgo residual.
- **Estado:** Cerrada (ver `threat-model.md`).

### T11 — Converge y cierre

- **Agente asignado:** `documentador`
- **Dependencias:** T09, T10
- **Contenido:** `converge.md` con estado del ciclo, hallazgos, limitaciones y gate.
- **Criterio de aceptación:** `converge.md` completo; `00-indice.md` actualizado; spec ACTIVA en `specs/`.
- **Estado:** Cerrada (ver `converge.md`).

### T12 — Actualizar `00-indice.md`

- **Agente asignado:** `documentador`
- **Dependencias:** T11
- **Contenido:** entrada de la spec 034 con estado, ubicación, métricas y estado de verificación.
- **Criterio de aceptación:** la entrada existe y refleja el estado real, incluidas las limitaciones de ejecución.
- **Estado:** Cerrada (ver `00-indice.md`).

### T13 — Ejecutar el gate completo

- **Agente asignado:** `developer`
- **Dependencias:** T04, T05, T06, T19
- **Contenido:** ejecutar `scripts/validate-agents-skills.ps1`, `tests/harness-default.ps1` y `tests/kit-sync-merge.ps1` sobre el estado final; registrar la salida en `converge.md`.
- **Criterio de aceptación:** validador con `FAIL: 0`; ambos tests de contrato exit 0; fixture negativo de `harness-default` exit 1; fixture de marcadores corruptos detectado.
- **Estado:** Cerrada (validador `FAIL: 0`/`VAL-10` OK; `harness-default` exit 0 con fixture negativo; `kit-sync-merge` exit 0 con 7 escenarios; salida registrada en `converge.md`).

## Mitad de propagación (T14-T20)

### T14 — Envolver la sección de arranque con marcadores `KIT-BLOCK`

- **Agente asignado:** `developer` (fuera del dominio documental: `AGENTS.md` raíz)
- **Dependencias:** ninguna
- **Contenido:** en el `AGENTS.md` del maestro, envolver la sección `## Arranque por defecto del arnés` (incluida `### Matriz de enrutamiento por tarea`) entre `<!-- KIT-BLOCK:START arranque-por-defecto -->` y `<!-- KIT-BLOCK:END arranque-por-defecto -->`. No mover el contenido ni cambiar su redacción.
- **Criterio de aceptación:** existen exactamente un `START` y un `END` en el archivo; `START` aparece antes que `END`; el texto entre marcadores es idéntico al bloque previo salvo las dos líneas nuevas; el render del Markdown no cambia (los comentarios HTML no se muestran).
- **Estado:** Cerrada (marcadores verificados en `AGENTS.md` L117 y L143, START antes que END).
- **Nota:** sin esta tarea, `Merge-KitBlock` no tiene bloque que extraer del maestro y tendría que hardcodear el contenido, violando la fuente única.

### T15 — Comparador local + `Merge-OpenCodeConfig` en `sync-kit.ps1`

- **Agente asignado:** `developer`
- **Dependencias:** T01
- **Contenido:** dos partes, en el mismo archivo.
  1. **Comparador (corrige B-01 y B-02).** Agregar `Compare-KitFileState` en `scripts/sync-kit.ps1` (junto a las demás funciones, antes de `Sync-TransversalKit`), con contrato `'Equal' | 'EolOnly' | 'Different'`: lectura raw de ambos archivos, comparación exacta primero (incluye BOM y newline final), y si difieren, comparación tras normalizar `\r\n` → `\n` para distinguir `EolOnly`. Reemplazar la llamada a `Compare-KitFileContent` en la rama de archivos de raíz (L641) por `Compare-KitFileState`. **No** hacer dot-source de `sync-kit-lib.ps1`: eso es de la spec 029 y su ausencia en un consumidor nuevo rompería el sync antes de copiar `scripts/`.
  2. **Merge de `opencode.json`.** `Merge-OpenCodeConfig -Source <maestro> -Destination <local> -ProjectRoot <raíz> -Force`: sobrescribe `$schema`, `instructions` y `default_agent` desde el maestro; preserva `mcp`, `model`, `small_model`, `permission`, `lsp` y claves desconocidas. Se invoca **antes** de la regla SKIP, de modo que aplique con y sin `-Force`. Backup `opencode.json.bak-<yyyyMMddTHHmmss>` antes de escribir; validar el JSON resultante y restaurar el backup si falla; si el destino no parsea → no escribir + WARN (fail-closed).
- **Criterio de aceptación:** (a) `Compare-KitFileState` devuelve `Equal` con archivos idénticos, `EolOnly` con LF vs CRLF del mismo contenido, `Different` con contenido distinto y con BOM de un solo lado; (b) con `opencode.json` local divergente (8 servidores `mcp`, `default_agent: build`), sin `-Force`, el sync deja `default_agent` según D-09 y conserva los 8 servidores; (c) dos ejecuciones seguidas son idempotentes; (d) el backup se genera y queda ignorado por git; (e) el sync ya no aborta en el primer archivo de raíz.
- **Estado:** Cerrada (escenarios 1, 2 y 4 de `tests/kit-sync-merge.ps1` OK en ejecución real).
- **Nota:** sin la parte 1, la parte 2 es código inalcanzable (ver §19.5 de la spec).

### T16 — Regla de `default_agent` en el sync (FR-15)

- **Agente asignado:** `developer`
- **Dependencias:** T15
- **Contenido:** dentro de `Merge-OpenCodeConfig`, aplicar la tabla de §19.3 de la spec: ausente → escribir `pensador`; `build` → escribir `pensador` + WARN; agente del kit con `mode: primary` → preservar + INFO; agente inexistente o no-primary → escribir `pensador` + WARN; con `-Force` → siempre `pensador`.
- **Criterio de aceptación:** los cinco estados de la tabla producen la acción declarada, verificado en `tests/kit-sync-merge.ps1` con fixtures temporales; preservar un agente válido no emite WARN.
- **Estado:** Cerrada (escenario 3 de `tests/kit-sync-merge.ps1`, subcasos a-e, OK).

### T17 — `Merge-KitBlock` en `sync-kit.ps1`

- **Agente asignado:** `developer`
- **Dependencias:** T14
- **Contenido:** función que sincronice `AGENTS.md` por bloque delimitado, extrayendo el bloque del maestro entre `KIT-BLOCK:START arranque-por-defecto` y `KIT-BLOCK:END arranque-por-defecto`. Cubre los cinco casos de la tabla §19.4: marcadores presentes → reemplazar; sección sin marcadores → migrar y envolver; sección ausente → agregar al final + WARN; marcadores corruptos (desordenados, duplicados o sin cierre) → no escribir + WARN; destino ausente → copiar. Backup `AGENTS.md.bak-<timestamp>` antes de escribir.
- **Criterio de aceptación:** con un `AGENTS.md` local que tiene la sección sin marcadores y dos secciones propias adicionales, tras el sync la sección de arranque queda actualizada, envuelta en marcadores, y las dos secciones propias siguen presentes sin cambios; con marcadores corruptos no se escribe nada y se emite WARN.
- **Estado:** Cerrada (escenarios 5, 6 y 7 de `tests/kit-sync-merge.ps1` OK: migración, reemplazo y fail-closed).

### T18 — Whitelist de tests del kit en el manifiesto

- **Agente asignado:** `developer`
- **Dependencias:** ninguna
- **Contenido:** agregar al manifiesto de `sync-kit.ps1` la copia por nombre exacto de `tests/harness-default.ps1`, `tests/kit-sync-merge.ps1`, `tests/agents-parity.ps1`, `tests/kb-parity.ps1` y `tests/mcp-refresh-parity.ps1`. No agregar `tests/` como directorio. Si el archivo no existe en el maestro → INFO, no crear vacío.
- **Criterio de aceptación:** `sync-agents.ps1 -DryRun` lista los 5 tests del kit; un archivo cualquiera de `tests/` del proyecto (por ejemplo `upgrade_framework.Tests.ps1`) no aparece en el plan de copia; `tests/` no se trata como directorio transversal.
- **Estado:** Cerrada (whitelist en el manifiesto L1085-1104; no se agregó `tests/` como directorio).

### T19 — `.gitignore` para backups del sync y del bootstrap

- **Agente asignado:** `developer`
- **Dependencias:** T15, T17
- **Contenido:** agregar los patrones `opencode.json.bak-*` y `AGENTS.md.bak-*`. El bloque existente `opencode.json.backup.*` no coincide con el formato que generan el bootstrap y el sync (punto vs guion, `bak-` vs `backup.`).
- **Criterio de aceptación:** `git check-ignore -v opencode.json.bak-20261101T120000` y `git check-ignore -v AGENTS.md.bak-20261101T120000` devuelven una regla concreta; los backups reales quedan fuera de `git status`. Cierra TM-04.
- **Estado:** Cerrada (`git check-ignore` confirma `.gitignore:48` y `.gitignore:49`; TM-04 cerrado en `threat-model.md`).

### T20 — `tests/kit-sync-merge.ps1`

- **Agente asignado:** `developer`
- **Dependencias:** T15, T16, T17
- **Contenido:** script PowerShell plano (exit 0/1, sin Pester) con fixtures en `$env:TEMP`. Debe cubrir: (a) `opencode.json` divergente que recibe `default_agent` y conserva `mcp` con 8 servidores; (b) los 5 estados de `default_agent`; (c) `AGENTS.md` con sección sin marcadores → migración; (d) `AGENTS.md` con marcadores → reemplazo; (e) `AGENTS.md` con marcadores corruptos → no escribir; (f) idempotencia: segunda pasada no cambia nada. No escribe en el repositorio.
- **Criterio de aceptación:** exit 0 sobre los escenarios cubiertos; cada escenario imprime su nombre y resultado; ningún archivo del repositorio se modifica durante la ejecución (verificable con `git status` antes/después). El test cubre 7 grupos de escenarios (Compare, merge por claves, regla de default_agent, idempotencia, migración, reemplazo y fail-closed).
- **Estado:** Cerrada (`tests/kit-sync-merge.ps1` exit 0, "OK: 7 escenarios", sin escribir en el repo).

## Orden de ejecución

```
T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08
T14 → T15 → T16 → T17 → T18 → T19 → T20
T09 → T10 → T11 → T12 → T13
```

La mitad de propagación (T14-T20) se ejecuta **después** de la local porque depende de los valores ya fijados (T01 fija `pensador`) y **antes** del gate (T13), que la necesita para validar.

## Gate de cierre

| Check | Umbral |
|---|---|
| `scripts/validate-agents-skills.ps1` | `FAIL: 0`, exit 0, `VAL-10` en OK |
| `tests/harness-default.ps1` | exit 0 |
| `tests/kit-sync-merge.ps1` | exit 0, 7 escenarios |
| Fixture negativo (`default_agent: build`) | exit 1 |
| `sync-agents.ps1 -DryRun` | lista los 5 tests del kit; no toca `tests/` de la app |
| `git diff` sobre `permission` de agentes | cero líneas |
| `Test-Path .opencode/agents/pensador/spec.md` | `False` |
| `git check-ignore` sobre `*.bak-*` | regla encontrada |
