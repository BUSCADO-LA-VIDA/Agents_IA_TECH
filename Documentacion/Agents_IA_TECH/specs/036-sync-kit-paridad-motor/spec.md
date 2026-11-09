# Feature Specification: Orquestador único de sync del kit y capas de dominio depurables

**Feature Branch**: `036-sync-kit-paridad-motor`

**Created**: 2026-11-02

**Status**: Draft

**Input**: Cerrar los cinco defectos del sync del kit (deuda D1-D5 documentada al sincronizar `Generator_IA_Projects`): la poda que destruye el backup del llamador, la ausencia de capa para `skills`/`rules`/`prompts`/`workflows`/`copilot-instructions`/`tests`, la verificación de integridad del audit log que nunca puede pasar, y la doble entrada `graphify` contradictoria en `opencode.json`. Con una restricción de arquitectura fijada por el usuario (2026-11-03): `scripts/sync-kit.ps1` es el **orquestador** estable y cada dominio vive en su propio script, ejecutable y depurable por separado.

## Contexto

Entre el 2026-10-27 y el 2026-11-02 se sincronizó el kit transversal del maestro
`C:\Proyectos\Agents_IA_TECH` hacia `C:\Proyectos\Generator_IA_Projects`. La intervención se
registró en la bitácora
`Documentacion/Agents_IA_TECH/bitacoras/2026-11-02-sync-kit-generator-y-parche-kit-files.md`
y en `.bootstrap-audit.log` (entradas 205 `sync_kit_transversal_executed` y 206
`kit_patch_committed`, commit del parche `35da532`).

Durante esa intervención se corrigieron **dos** defectos del motor por capas (el sync sobrescribía
`AGENTS.md` y ninguna capa aplicaba `default_agent`) y se documentaron **cinco más** que no se
tocaron porque excedían el alcance autorizado. Esta spec cierra esos cinco.

El problema de fondo es de **paridad y de conexión**: existen dos motores y no son equivalentes.

| Motor | Estado | Cobertura |
|---|---|---|
| `scripts/sync-kit.ps1` | `[021-DEPRECATED]` **pero es el único invocado por el bootstrap** | Copia todo el kit transversal con `robocopy /E`, merge de `opencode.json`, merge de `AGENTS.md` por bloque y whitelist de tests |
| `scripts/sync-kit-agents.ps1` | **orquestador desconectado**: forma correcta, sin invocador (ver *Decisión de arquitectura*) | 12 capas en proceso hijo; **no** cubre skills, rules, prompts, workflows, `copilot-instructions.md` ni tests |

El efecto medido el 2026-11-02: tras ejecutar el motor por capas con `exit 0` y `ERRORs: 0`, el
destino seguía con **78 archivos de skills obsoletos**, 16 rules, 6 prompts, 5 workflows y
`copilot-instructions.md` desactualizados. Hubo que completar la superficie con el motor deprecado
(`sync-kit.ps1 -KitPath`, sin `-Force`). Un motor "vigente" que exige el deprecado para completarse
no es vigente: es un wrapper.

### Defectos en alcance

| ID | Defecto | Evidencia verificada |
|---|---|---|
| **D1** | La poda de `.kit-backup` destruye el backup del llamador | `sync-kit-agents.ps1` L359-384: al terminar con 0 errores ordena `.kit-backup/` por nombre descendente y hace `Select-Object -Skip 2`. Los backups creados *durante* la corrida tienen timestamp posterior, así que el backup tomado antes de empezar siempre cae en la poda. Caso real: `.kit-backup/20261102-164540` (4 603 archivos, 64 160 489 bytes, 0 discrepancias) fue borrado al final de la corrida; sobrevivieron solo `20261102-165039` (16 archivos) y `20261102-165040` (2 archivos). |
| **D2** | No existe capa `skills` (ni capa para el resto de `.github/`) | La lista `$script:Layers` declara 12 capas y ninguna es `skills`; `scripts/sync/skills/sync-skills.ps1` existe en disco pero solo aparece en un comentario de la L277. Consecuencia: `.github/skills` (89) y `.opencode/skills` (89) nunca se sincronizan desde el orquestador, y `.github/rules` (16), `.github/prompts` (6), `.github/workflows` (5) y `.github/copilot-instructions.md` tampoco tienen capa. |
| **D3** | `Test-AuditLogIntegrity` da falso negativo siempre | `upgrade_framework.ps1` L203-229: al recalcular el hash copia la entrada y elimina **solo** `hash`, dejando `prevHash` dentro del payload; el escritor (`Write-AuditEntry`, L166-201) calcula el hash sobre un payload que aún no tenía `hash` **ni** `prevHash`. Nunca puede coincidir, ni con sus propias entradas. Además exige una cadena lineal cuando 136 de las 204 entradas históricas tienen `prevHash: null` (escritores distintos hicieron append sin encadenar), y opera por round-trip `ConvertFrom-Json`/`ConvertTo-Json`, que convierte el `timestamp` ISO-8601 a `[DateTime]` y cambia el formato al re-serializar. |
| **D4** | Los tests del kit solo viajan por el motor deprecado | La whitelist de 5 tests (`tests/harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1`) está en `sync-kit.ps1`; el orquestador por capas no tiene capa de tests. En el destino quedaron 5 de 8 archivos de `tests/` (los 3 restantes fuera de whitelist, por diseño) y hubo que crearlos con el motor viejo. |
| **D5** | `opencode.json` con dos entradas `graphify` contradictorias | El destino tiene `mcp.servers.graphify` (forma V2) apuntando al grafo del **maestro** (`C:/Proyectos/Agents_IA_TECH/graphify-out/graph.json`) y `mcp.graphify` (forma V1) apuntando al grafo del **destino**. Dos servidores con el mismo nombre lógico y grafos distintos: el primero sirve el conocimiento del proyecto equivocado. `lift-opencode.ps1` solo regenera la ruta cuando `command[0]` no existe en disco, así que una ruta existente pero ajena nunca se corrige. |

## Decisión de arquitectura (usuario, 2026-11-03)

> **Origen**: instrucción directa del usuario, 2026-11-03. **Reemplaza** la premisa con la que se
> redactó originalmente esta spec, que trataba `sync-kit.ps1` como motor en retirada y a
> `sync-kit-agents.ps1` como flujo objetivo.

La arquitectura objetivo **no** es "un motor nuevo que reemplace a uno viejo". Es:

1. **Un orquestador con contrato estable**: `scripts/sync-kit.ps1` es el punto de entrada que invoca
   `plataformador-bootstrap.ps1` y el que el usuario ejecuta a mano. Su trabajo es **orquestar**, no
   implementar.
2. **Un script por dominio de acción**, con alcance limitado y específico, para que cada uno se
   pueda ejecutar y **depurar por separado** (skills, agentes de cada arnés, MCP, docs,
   constitution, tests, merge de `opencode.json`, merge de `AGENTS.md`, huérfanos).
3. **Cero lógica de dominio dentro del orquestador**: si una regla cambia, se cambia en su script,
   no en el orquestador.

**Motivo declarado por el usuario**: antes existió un único script monolítico y resultó
**inmantenible**. La mantenibilidad y la depurabilidad por unidad son requisitos, no preferencias.

### Estado real medido (2026-11-03)

| Hecho | Evidencia |
|---|---|
| `sync-kit.ps1` tiene 1143 líneas y 19 funciones, con **toda** la lógica pesada adentro: `Merge-OpenCodeConfig` (213 líneas), `Merge-KitBlock` (138), huérfanos (`Find-OrphanKitFiles`/`Remove-OrphanFiles`/`Move-OrphanFilesToBackup`/`Invoke-OrphanDecision`, ~340), `Sync-TransversalKit` (~280) | lectura del archivo |
| `sync-kit.ps1` está marcado `[021-DEPRECATED]` desde el commit `c56b56c` (2026-10-16, autor `pensador`), con la instrucción "no agregar funcionalidad aqui" | `git log -S'021-DEPRECATED' -- scripts/sync-kit.ps1` |
| `sync-kit-agents.ps1` tiene 386 líneas, es un orquestador puro de 12 capas y **no** tiene marca de deprecación | lectura + `git log` |
| El **único** invocador de producción (`plataformador-bootstrap.ps1` → `Invoke-SyncKit`, L2101-2139) llama a `sync-kit.ps1`; **ningún script invoca `sync-kit-agents.ps1`** | grep de invocadores |
| `scripts/sync/skills/sync-skills.ps1` existe pero **no figura** entre las 12 capas declaradas | lectura de `$script:Layers` (L67-86) |

**Diagnóstico**: la división en capas se ejecutó **a medias**. La duplicación actual no es "motor
viejo contra motor nuevo", sino **orquestador desconectado** (`sync-kit-agents.ps1`, correcto en
forma pero sin invocador) y **lógica de dominio viviendo dentro del script que el bootstrap sí
llama** (`sync-kit.ps1`). Esta spec completa esa división pendiente en la dirección que el usuario pidió: el
orquestador es `sync-kit.ps1`, las capas se invocan desde ahí, y todo lo que hoy es función interna
del orquestador se extrae a su script de dominio.

## User Scenarios & Testing

### User Story 1 - El backup pre-sync sobrevive a la corrida (Priority: P1)

Un operador toma un backup verificado del destino, ejecuta el sync y, al terminar, el backup sigue
en `.kit-backup/` con su manifiesto intacto, para poder revertir si el resultado no le sirve.

**Why this priority**: sin punto de rollback, cualquier sync sobre una raíz sin git (como
`Generator_IA_Projects`) es una operación irreversible. Es el defecto con mayor potencial de
pérdida real: ya se materializó una vez.

**Independent Test**: preparar un destino con 3 carpetas de backup previas, ejecutar el orquestador
sobre un stage de prueba y verificar que las 3 siguen existiendo con sus hashes intactos.

**Acceptance Scenarios**:

1. **Given** un `.kit-backup/` con 3 backups anteriores al inicio de la corrida, **When** el
   orquestador termina con 0 errores, **Then** los 3 siguen presentes y verificables.
2. **Given** una corrida con `-KeepBackups 2`, **When** termina, **Then** se conservan el backup
   del llamador más los 2 más recientes generados por las capas.
3. **Given** una corrida con `-NoPrune`, **When** termina, **Then** no se borra ninguna carpeta.
4. **Given** una poda que borra algo, **When** ocurre, **Then** queda registrado qué se borró y por
   qué regla, en el resumen de ejecución.

---

### User Story 2 - Un solo motor basta para dejar el kit sincronizado (Priority: P1)

El mantenedor ejecuta solo `sync-kit-agents.ps1` y el destino queda con divergencia 0 frente al
maestro en **toda** la superficie transversal, sin tener que recurrir después al motor deprecado.

**Why this priority**: es la razón de existir del orquestador. Mientras requiera el motor viejo, el
"flujo vigente" es una ficción y el próximo sync volverá a dejar 78 skills obsoletos.

**Independent Test**: sobre un destino vacío, ejecutar solo el orquestador y comparar por SHA-256
cada área contra el maestro: todas deben dar 0 distintos y 0 solo-en-destino.

**Acceptance Scenarios**:

1. **Given** un destino con skills desactualizados, **When** corre solo el orquestador, **Then**
   `.github/skills` y `.opencode/skills` quedan idénticos al maestro.
2. **Given** un destino con rules/prompts/workflows desactualizados, **When** corre solo el
   orquestador, **Then** `.github/rules`, `.github/prompts`, `.github/workflows` y
   `.github/copilot-instructions.md` quedan idénticos al maestro.
3. **Given** un destino sin la whitelist de tests, **When** corre solo el orquestador, **Then** los
   5 tests del kit aparecen en `tests/` y los tests propios del proyecto no se borran.
4. **Given** una segunda corrida inmediata, **When** termina, **Then** el RESULT de cada capa es
   `sin-cambios` y ningún archivo cambia de hash (idempotencia).

---

### User Story 3 - La integridad del audit log es verificable de verdad (Priority: P2)

Un auditor ejecuta el verificador sobre `.bootstrap-audit.log` y obtiene un resultado que
distingue entre "entrada corrupta" y "entrada raíz legítima", sin falsos negativos ni entradas
`audit_integrity_violation` espurias.

**Why this priority**: un verificador que siempre falla es peor que no tener verificador: entrena a
ignorar la señal de integridad y ensucia el propio log con eventos falsos.

**Independent Test**: correr el verificador sobre el log actual (206 entradas) y esperar exit 0 con
un reporte de raíces; luego corromper un byte de una entrada en una copia y esperar exit distinto de
0 señalando esa entrada.

**Acceptance Scenarios**:

1. **Given** el log actual con 206 entradas y 136 raíces históricas, **When** corre el verificador,
   **Then** devuelve 0 violaciones e informa cuántas raíces encontró.
2. **Given** una entrada alterada en una copia del log, **When** corre el verificador, **Then**
   detecta esa entrada concreta y no escribe `audit_integrity_violation` por las raíces.
3. **Given** una entrada cuyo `timestamp` se re-serializa, **When** se verifica, **Then** el hash
   sigue siendo válido (la verificación no depende del round-trip JSON).

---

### User Story 4 - Una sola entrada `graphify`, apuntando al grafo correcto (Priority: P2)

Tras el sync, `opencode.json` del destino declara `graphify` una sola vez y su ruta apunta al grafo
del **destino**, no al del maestro.

**Why this priority**: con dos entradas contradictorias, el agente consulta el grafo de otro
proyecto y recibe arquitectura ajena como si fuera propia — un fallo silencioso de razonamiento, no
un error visible.

**Independent Test**: leer `opencode.json` del destino, contar entradas `graphify` en todas las
formas (`mcp.servers.graphify`, `mcp.graphify`) y verificar que la ruta quede dentro de `RootPath`.

**Acceptance Scenarios**:

1. **Given** un destino con `mcp.servers.graphify` apuntando al grafo del maestro, **When** corre la
   capa, **Then** la ruta se regenera a `<RootPath>/graphify-out/graph.json`.
2. **Given** un destino con la forma V1 y la V2 a la vez, **When** corre la capa, **Then** queda una
   sola entrada y se emite WARN indicando cuál se conservó.
3. **Given** una entrada con `enabled: false` puesta por el usuario, **When** la capa regenera la
   ruta, **Then** `enabled` sigue en `false`.

### User Story 5 - Un orquestador, un script por dominio, depurable por separado (Priority: P1)

El mantenedor quiere cambiar la regla de un solo dominio (por ejemplo, cómo se fusiona `opencode.json`)
y poder editar, ejecutar y depurar **ese** script solo, sin arrastrar las otras once capas ni
depender de un archivo de 1143 líneas.

**Why this priority**: es el requisito de mantenibilidad declarado por el usuario y la razón por la
que el monolito anterior se abandonó. Sin esto, los otros cuatro arreglos vuelven a concentrarse en
el mismo archivo y el problema reaparece.

**Independent Test**: ejecutar cada script de dominio de forma aislada contra un fixture temporal,
sin pasar por el orquestador, y obtener su `RESULT:` propio con exit 0; y verificar que el
orquestador no define ninguna de las funciones de dominio.

**Acceptance Scenarios**:

1. **Given** el script de dominio de MCP, **When** se ejecuta solo con `-StageDir` y `-RootPath`
   sobre un fixture, **Then** completa y emite su `RESULT:` sin invocar el orquestador.
2. **Given** el orquestador, **When** se inspecciona su contenido, **Then** no contiene
   implementación de dominio (solo listado de capas, invocación, recolección de `RESULT:` y resumen).
3. **Given** el bootstrap, **When** sincroniza el kit, **Then** invoca al orquestador y este a las
   capas; no existe un segundo entry point que nadie llame.
4. **Given** un fallo en una capa, **When** el orquestador lo recibe, **Then** queda identificado por
   nombre de capa y es reproducible ejecutando esa capa sola con los mismos parámetros.

### Edge Cases

- **Backup del llamador con el mismo timestamp que el de una capa**: se compara contra el conjunto
  de carpetas presentes al inicio de la corrida, no contra el nombre; el empate no borra nada.
- **`.kit-backup/` con archivos sueltos (no carpetas)**: la poda ignora lo que no sea directorio con
  formato `yyyyMMdd-HHmmss` y lo reporta como no podable.
- **Poda interrumpida a mitad**: cada borrado es independiente y se registra; un fallo no revierte
  los anteriores ni aborta la corrida (fail-open, WARN).
- **Capa `skills` con una skill retirada en el maestro**: debe quedar huérfana en el destino, y el
  escáner de huérfanos debe reportarla con la misma acción (`Conservar`/`Mover`) que hoy usa el
  motor deprecado. Nunca se borra sin decisión explícita.
- **Capa de tests con un test propio del proyecto que colisiona de nombre** con uno del kit: el del
  kit gana (es contrato) y el del proyecto se respalda antes de reemplazarse.
- **Log sin ninguna entrada**: el verificador devuelve 0 violaciones (no hay nada que verificar) y
  lo informa como "log vacío", no como éxito silencioso.
- **Entrada del log sin `prevHash` en medio de la cadena**: se trata como raíz legítima, se cuenta y
  se reporta; no se emite violación.
- **`graphify` ausente por completo en el destino**: se crea con la ruta del destino; si
  `graphify-out/` no existe, se emite WARN y se deja la entrada sin crear (no se inventa una ruta a
  un grafo inexistente).
- **Dry-run del orquestador**: debe reportar el efecto de las capas nuevas (cuántos archivos
  cambiarían) sin escribir nada; hoy varias capas solo anuncian la acción sin calcular el diff.

## Requirements

### Functional Requirements

- **FR-001 (D1)**: La poda de `.kit-backup/` DEBE excluir toda carpeta que existiera antes de
  iniciar la corrida. El criterio es el conjunto inicial, no el nombre ni la fecha.
- **FR-002 (D1)**: El orquestador DEBE exponer `-KeepBackups <n>` (retención de las carpetas
  generadas por la corrida) y `-NoPrune` (desactiva la poda), con default que nunca borre el backup
  del llamador.
- **FR-003 (D1)**: Cada borrado de la poda DEBE quedar registrado en el resumen de ejecución con
  ruta, tamaño y regla aplicada; un fallo de poda DEBE ser fail-open con WARN y no abortar la
  corrida.
- **FR-004 (D2)**: El orquestador DEBE declarar una capa `skills` que sincronice
  `.github/skills/` y `.opencode/skills/` desde el stage, con política idempotente, backup previo y
  `RESULT:` propio.
- **FR-005 (D2)**: El orquestador DEBE cubrir `.github/rules/`, `.github/prompts/`,
  `.github/workflows/` y `.github/copilot-instructions.md` en una capa propia (o en `skills`,
  documentándolo), de modo que la superficie `.github/` completa tenga capa asignada.
- **FR-006 (D2)**: Ninguna capa nueva DEBE escribir en `Documentacion/<AppName>/`, `src/`,
  `.opencode/config.json` ni `tests/` fuera de la whitelist del kit.
- **FR-007 (D4)**: La whitelist de tests del kit DEBE moverse a una capa del orquestador, con
  respaldo de los tests del proyecto que colisionen por nombre y sin borrar tests fuera de la
  whitelist.
- **FR-008 (D3)**: `Test-AuditLogIntegrity` DEBE recalcular el hash sobre un payload que excluya
  `hash` **y** `prevHash`, y DEBE operar sobre el texto crudo de cada línea, no sobre un round-trip
  `ConvertFrom-Json`/`ConvertTo-Json`.
- **FR-009 (D3)**: La verificación DEBE validar autoconsistencia por entrada y tratar `prevHash:
  null` como raíz legítima (contada y reportada), sin exigir una cadena lineal completa y sin
  escribir `audit_integrity_violation` por raíces.
- **FR-010 (D3)**: El verificador DEBE devolver un código de salida distinguible entre "log válido"
  (0), "log con violaciones" (≠0) y "log ausente o vacío" (estado propio, informado).
- **FR-011 (D5)**: Las capas que gestionan `opencode.json` DEBEN dejar **una sola** entrada
  `graphify`, en la forma canónica de la spec 020, y DEBEN regenerar la ruta cuando apunte fuera de
  `RootPath`, no solo cuando el ejecutable falte.
- **FR-012 (D5)**: La regeneración de la ruta DEBE preservar el valor de `enabled` elegido por el
  proyecto y DEBE emitir WARN cuando detecte duplicados o una ruta ajena corregida.
- **FR-013**: Cada defecto corregido DEBE tener al menos un escenario de regresión en
  `tests/kit-sync-merge.ps1` (o en un `tests/sync-layers.ps1` nuevo) que falle antes del arreglo y
  pase después, sobre fixtures temporales y sin escribir en el repositorio.
- **FR-014**: La suite de tests del kit DEBE seguir siendo ejecutable sin Pester y con `exit 0` /
  `exit 1` como único contrato de resultado.
- **FR-015**: El sync real sobre un destino DEBE terminar con divergencia 0 frente al maestro en
  skills, rules, prompts, workflows, `copilot-instructions.md` y tests de la whitelist, **usando
  solo el orquestador por capas**.

### Arquitectura orquestador + dominios (decisión del usuario, 2026-11-03)

- **FR-016**: `scripts/sync-kit.ps1` DEBE ser el **único** orquestador del sync transversal: el
  punto de entrada que invoca `plataformador-bootstrap.ps1` y el que se ejecuta a mano. DEBE
  invocar cada dominio como script hijo y recolectar sus líneas `RESULT:`.
- **FR-017**: La lógica de dominio NO DEBE vivir en el orquestador. `Merge-OpenCodeConfig`,
  `Merge-KitBlock`, la gestión de huérfanos y `Sync-TransversalKit` DEBEN extraerse a scripts de
  dominio invocables por separado, conservando el comportamiento actual.
- **FR-018**: Cada script de dominio DEBE poder ejecutarse de forma aislada con parámetros
  explícitos (`-StageDir`, `-RootPath`, `-DryRun`) y devolver un estado legible, para permitir
  depuración individual sin correr el sync completo.
- **FR-019**: La marca `[021-DEPRECATED]` DEBE retirarse de `sync-kit.ps1` y no DEBE quedar ningún
  entry point huérfano que nadie invoque: o una capa está conectada al orquestador, o no existe.
- **FR-020**: El orquestador DEBE soportar `-Only` / `-Skip` / `-ListLayers`, de modo que el
  mantenedor pueda ver y ejecutar un dominio sin conocer la estructura de carpetas.

### Key Entities

- **Capa de sync**: entrada de `$script:Layers` con `Name`, `Script` y `AcceptsForce`; se ejecuta
  como proceso hijo y comunica su resultado por líneas `RESULT:<nombre>:<estado>`.
- **Backup**: carpeta `.kit-backup/<yyyyMMdd-HHmmss>/` con `MANIFEST.sha256` y `BACKUP-INFO.txt`;
  puede ser del llamador o generada por una capa.
- **Poda**: borrado de carpetas de backup que exceden la retención, con registro de lo borrado.
- **Whitelist de tests**: conjunto cerrado de tests del kit que viajan al destino aunque el
  proyecto tenga sus propios tests.
- **Entrada de audit log**: línea JSON con `timestamp`, `actor`, `host`, `action`, `manifestHash`,
  `details`, `hash` y `prevHash`; el hash cubre la entrada sin `hash` ni `prevHash`, encadenado al
  `prevHash`.
- **Raíz de cadena**: entrada con `prevHash: null`; legítima, contada, no violación.
- **Entrada `graphify`**: servidor MCP que sirve un grafo de conocimiento; su `command` termina en
  la ruta del `graph.json`, que debe pertenecer al `RootPath` sincronizado.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Con 3 backups previos en `.kit-backup/`, una corrida completa del orquestador deja los
  3 intactos (hash de `MANIFEST.sha256` idéntico antes y después). Antes del arreglo: 0 de 3
  sobreviven.
- **SC-002**: Ejecutando **solo** `scripts/sync-kit.ps1` (el orquestador) sobre el destino, la
  divergencia SHA-256 contra el maestro es 0 en `.github/skills` (89), `.opencode/skills` (89),
  `.github/rules` (16), `.github/prompts` (6), `.github/workflows` (5), `tests/` (5 de whitelist) y
  `.github/copilot-instructions.md`.
- **SC-003**: Un solo comando completa el sync: no queda un segundo motor al que recurrir para
  terminar el trabajo ni un script de capa sin invocador (0 scripts huérfanos en `scripts/sync/`).
- **SC-004**: Sobre el log real de 206 entradas, el verificador devuelve 0 violaciones e informa 136
  raíces; sobre una copia con 1 entrada alterada, detecta exactamente esa entrada y ninguna más.
- **SC-005**: `opencode.json` del destino contiene exactamente 1 entrada `graphify` y su ruta
  resuelta está dentro de `RootPath`; `enabled` conserva el valor previo en el 100 % de los casos
  probados.
- **SC-006**: La suite del kit pasa con `exit 0` y suma al menos 15 asserts nuevos respecto de los
  45 actuales (escenarios de D1-D5), con 0 `[FAIL]`.
- **SC-007**: Ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`
  (mtimes sin cambios antes/después en un destino de prueba con esas tres rutas presentes).
- **SC-008**: Un dry-run del orquestador reporta, para cada capa nueva, cuántos archivos cambiarían
  (número concreto, no "se sincronizarían") y no escribe ningún archivo.
- **SC-009**: **0** de las 4 funciones de dominio (`Merge-OpenCodeConfig`, `Merge-KitBlock`, la
  gestión de huérfanos, `Sync-TransversalKit`) queda definida dentro de `sync-kit.ps1`; las 4
  existen como script propio y se ejecutan de forma aislada sobre un fixture con exit 0.
- **SC-010**: Las 6 capas de la superficie restante (skills, rules, prompts, workflows,
  `copilot-instructions.md`, tests) se ejecutan individualmente con exit 0 y emiten su `RESULT:`
  propio; el orquestador las enumera con `-ListLayers` y no hay ningún script de capa sin invocador.

## Assumptions

- `scripts/sync-kit.ps1` es el **orquestador** (punto de entrada estable, el que invoca el bootstrap)
  y no se retira: se **adelgaza**. `sync-kit-agents.ps1` deja de ser un segundo orquestador
  competidor: su lista de capas se integra en el orquestador único o queda como módulo invocado por
  él — la forma exacta la decide el plan, no esta spec.
- El motor deprecado no se reescribe de cero: la lógica de valor que hoy tiene adentro
  (`Merge-OpenCodeConfig`, `Merge-KitBlock`, huérfanos, `Sync-TransversalKit`) se **mueve** a scripts
  de dominio, conservando comportamiento y tests.
- La forma canónica de `graphify` es la de la spec `020-mcp-config-operativa` (una entrada bajo
  `mcp.servers`, regeneración de ruta por capa). La convivencia V1/V2 del destino es un residuo a
  limpiar, no un diseño a preservar.
- El log `.bootstrap-audit.log` está versionado en el repo maestro y **no** se commitea en cada
  operación: se asume que puede llegar sucio al verificar, y el verificador debe tolerarlo.
- Las raíces históricas (`prevHash: null`) no se van a reparar retroactivamente: se aceptan como
  estado inicial y se cuentan.
- Los backups de la corrida pueden quedar en `.kit-backup/` o fuera de esa carpeta
  (`.kit-backup-manual/`); la poda solo gobierna `.kit-backup/`.
- Ninguna corrección de esta spec cambia el contenido de `AGENTS.md`: el merge por bloque
  `KIT-BLOCK` ya quedó resuelto y cubierto por los escenarios 8-10 del commit `35da532`.

## Fuera de alcance

- **Dry-run declarativo del motor deprecado** (`sync-kit.ps1` L903-922 retorna antes de calcular
  diff u huérfanos). Se corrige dentro de FR-018/FR-020 al extraer los dominios; el requisito aplica
  a todas las capas, no solo a las nuevas.
- Retirar `sync-kit.ps1` del repositorio. **Queda como orquestador** (FR-016); lo que se retira es el
  monolito, no el punto de entrada.
- Reescribir el historial de `.bootstrap-audit.log` para reconstruir una cadena lineal.
- Cualquier cambio en `Documentacion/<AppName>/`, `src/` o en los agentes/skills en sí: esta spec
  corrige el **motor**, no el contenido que transporta.

## Trazabilidad

| Defecto | Requisitos | Escenario de usuario | Criterio medible | Archivo a modificar |
|---|---|---|---|---|
| D1 | FR-001, FR-002, FR-003 | US1 | SC-001 | `scripts/sync-kit-agents.ps1` (L359-384) |
| D2 | FR-004, FR-005, FR-006 | US2 | SC-002, SC-007, SC-008 | `scripts/sync-kit-agents.ps1` (`$script:Layers`), `scripts/sync/skills/sync-skills.ps1` |
| D3 | FR-008, FR-009, FR-010 | US3 | SC-004 | `upgrade_framework.ps1` (`Test-AuditLogIntegrity`, L203-229) |
| D4 | FR-007, FR-014 | US2 | SC-002, SC-006 | `scripts/sync-kit-agents.ps1` (capa de tests) |
| D5 | FR-011, FR-012 | US4 | SC-005 | `scripts/sync/mcp/lift-opencode.ps1`, `scripts/sync/indexing/run-indexing.ps1` |
| Transversal | FR-013, FR-015 | US2 | SC-003, SC-006 | `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1` |
| Arquitectura orquestador + dominios | FR-016, FR-017, FR-018, FR-019, FR-020 | US5 | SC-009, SC-010 | `scripts/sync-kit.ps1` (orquestador), `scripts/sync-kit-agents.ps1` (lista de capas), `scripts/plataformador-bootstrap.ps1` (invocador) |

## Evidencia de origen

- Bitácora: `Documentacion/Agents_IA_TECH/bitacoras/2026-11-02-sync-kit-generator-y-parche-kit-files.md`
  (secciones 2.2-2.6 diagnóstico y 6 deuda técnica D1-D5).
- Auditoría: `.bootstrap-audit.log` entradas 204 (`sync_kit_transversal_authorized`), 205
  (`sync_kit_transversal_executed`, con `deuda_abierta: D1..D5`) y 206 (`kit_patch_committed`).
- Commit del parche previo: `35da532` — `fix(spec 021): complementar AGENTS.md y aplicar
  default_agent en el motor por capas` (6 archivos, 715 inserciones).
- Origen de la marca de deprecación: commit `c56b56c` (2026-10-16, autor `pensador`) —
  `feat(sync): fase 4 sync-kit-agents (indexing+externals, 12 capas, deprecacion)`. Marcó
  `sync-kit.ps1` pero nunca cableó el reemplazo: `plataformador-bootstrap.ps1` sigue invocando
  `sync-kit.ps1` vía `Invoke-SyncKit` (L2101-2139).
- Medición base: divergencia maestro→destino del 2026-11-02 antes y después del workaround
  (skills 89/89, rules 16, prompts 6, workflows 5, tests 5/8).
