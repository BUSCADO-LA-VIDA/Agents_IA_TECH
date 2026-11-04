# Analyze 036 — Consistencia y arquitectura del orquestador único de sync del kit

**Spec**: `036-sync-kit-paridad-motor`  
**Ruta del archivo**: `Documentacion\Agents_IA_TECH\specs\036-sync-kit-paridad-motor\analyze.md`  
**Constitución de referencia**: `.specify\memory\constitution.md` v2.0.0 (Constitution Check PASS: 9 artículos + Art. VI)  
**Estado del flujo**: spec leída y completa (393 líneas, 20 FR, 10 SC, 5 US, 9 edge cases). `plan.md` y `tasks.md` de la spec 036 **no se encontraron en disco** en la ruta esperada (ver hallazgo H-01 en §1). El `pendientes-implementacion.md` inventaria 7 tareas de esta spec (`036-T000`..`036-T005` + `TRANS-001`), no 28.

---

## 1. Consistencia spec ↔ plan ↔ tasks

### 1.1. Verificación de requisitos funcionales (FR-001 a FR-020)

La spec declara 20 FR agrupados en 6 bloques: D1 (poda), D2 (capas skills/.github), D3 (audit log), D4 (tests del kit), D5 (graphify) y arquitectura orquestador+dominios (FR-016 a FR-020). Cada FR se traza a uno o más Success Criteria (SC) y a una User Story (US) según la tabla de trazabilidad del §8 de la spec (líneas 370-378).

| FR | Defecto | User Story | Criterios medibles | Archivo a modificar (según spec) |
|----|---------|------------|--------------------|----------------------------------|
| FR-001 | D1 | US1 | SC-001 | `scripts/sync-kit-agents.ps1` (L359-384) |
| FR-002 | D1 | US1 | SC-001 | `scripts/sync-kit-agents.ps1` (L359-384) |
| FR-003 | D1 | US1 | SC-001 | `scripts/sync-kit-agents.ps1` (L359-384) |
| FR-004 | D2 | US2 | SC-002 | `scripts/sync-kit-agents.ps1` (`$script:Layers`), `scripts/sync/skills/sync-skills.ps1` |
| FR-005 | D2 | US2 | SC-002, SC-007 | `scripts/sync-kit-agents.ps1` (`$script:Layers`) |
| FR-006 | D2 | US2 | SC-007 | `scripts/sync-kit-agents.ps1` (todas las capas nuevas) |
| FR-007 | D4 | US2 | SC-002, SC-006 | `scripts/sync-kit-agents.ps1` (capa de tests) |
| FR-008 | D3 | US3 | SC-004 | `upgrade_framework.ps1` (`Test-AuditLogIntegrity`, L203-229) |
| FR-009 | D3 | US3 | SC-004 | `upgrade_framework.ps1` (`Test-AuditLogIntegrity`, L203-229) |
| FR-010 | D3 | US3 | SC-004 | `upgrade_framework.ps1` (`Test-AuditLogIntegrity`, L203-229) |
| FR-011 | D5 | US4 | SC-005 | `scripts/sync/mcp/lift-opencode.ps1`, `scripts/sync/indexing/run-indexing.ps1` |
| FR-012 | D5 | US4 | SC-005 | `scripts/sync/mcp/lift-opencode.ps1`, `scripts/sync/indexing/run-indexing.ps1` |
| FR-013 | Transversal | US2 | SC-003, SC-006 | `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1` nuevo |
| FR-014 | Transversal | US2 | SC-006 | `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1` nuevo |
| FR-015 | Transversal | US2 | SC-003 | Ejecución real del orquestador sobre destino |
| FR-016 | Arquitectura | US5 | SC-003, SC-009 | `scripts/sync-kit.ps1`, `scripts/plataformador-bootstrap.ps1` |
| FR-017 | Arquitectura | US5 | SC-009 | `scripts/sync-kit.ps1` + scripts de dominio extraídos |
| FR-018 | Arquitectura | US5 | SC-009, SC-010 | scripts de dominio (`-StageDir`, `-RootPath`, `-DryRun`) |
| FR-019 | Arquitectura | US5 | SC-003, SC-009 | `scripts/sync-kit.ps1`, `scripts/sync-kit-agents.ps1` |
| FR-020 | Arquitectura | US5 | SC-010 | `scripts/sync-kit.ps1` (`-Only` / `-Skip` / `-ListLayers`) |

### 1.2. Trazabilidad de User Stories a Success Criteria

- **US1** (backup sobrevive, P1) → SC-001: 3 de 3 backups previos intactos tras corrida completa.
- **US2** (solo motor basta, P1) → SC-002 (divergencia 0 en skills/rules/prompts/workflows/copilot-instructions/tests), SC-003 (0 scripts huérfanos, un solo comando), SC-006 (suite pasa con exit 0 y ≥15 asserts nuevos), SC-007 (no toca Documentacion/src/config.json), SC-008 (dry-run reporta diff concreto).
- **US3** (audit log verificable, P2) → SC-004: 0 violaciones sobre 206 entradas, 136 raíces reportadas, detección exacta de entrada alterada.
- **US4** (una sola graphify, P2) → SC-005: exactamente 1 entrada graphify, ruta dentro de RootPath, `enabled` preservado 100 % de los casos.
- **US5** (un orquestador, depurable, P1) → SC-009 (0 funciones de dominio dentro del orquestador, 4 scripts propios con exit 0), SC-010 (6 capas de superficie restante con exit 0 y RESULT propio, -ListLayers funcional).

### 1.3. Hallazgos de consistencia

**H-01 — `plan.md` y `tasks.md` de la spec 036 no existen en disco.**  
El `00-indice.md` (línea 205) declara explícitamente: "Plan y tasks pendientes: los ejecuta la fase siguiente del flujo SSD." Al ejecutar `glob **/036-sync-kit-paridad-motor/*` solo se devuelve `spec.md`. Por lo tanto no fue posible verificar que cada FR tenga su tarea en `tasks.md` ni que cada tarea tenga su FR de origen contra los archivos reales. Este es un bloqueo para pasar a la fase Converge: sin `tasks.md` no hay inventario verificable de qué tarea implementa qué FR.

**H-02 — Discrepancia de volumen de tareas.**  
El usuario indica que `tasks.md` tiene 28 tareas (F0-F8 + TRANS-001), pero el `pendientes-implementacion.md` solo inventaria 7 tareas de esta spec (`036-T000` a `036-T005` más `TRANS-001`). Ambas cifras no coinciden, lo que impide confirmar la cobertura completa de los 20 FR. Se debe crear `tasks.md` con al menos una tarea por FR (mínimo 20 tareas derivadas) antes de implementar.

**H-03 — FR-013 y FR-014 apuntan a un archivo de tests que puede no existir.**  
La spec permite `tests/kit-sync-merge.ps1` o un `tests/sync-layers.ps1` nuevo. Ninguno de los dos fue confirmado como existente para esta spec. Si se elige el archivo nuevo, debe crearse antes de marcar FR-013/FR-014 como cubiertos.

**H-04 — FR-010 requiere 3 códigos de salida distinguibles.**  
El verificador de audit log debe devolver 0 (válido), ≠0 (violaciones) y un estado propio (ausente/vacío). Ninguna tarea existente en `pendientes-implementacion.md` menciona este contrato de salida, por lo que falta una tarea dedicada.

**H-05 — FR-018 exige `-DryRun` que calcule diff real.**  
El edge case del spec (línea 226) advierte que varias capas solo anuncian la acción sin calcular el diff. SC-008 exige que el dry-run reporte un número concreto de archivos que cambiarían. Esto es un requerimiento de implementación que debe reflejarse como tarea explícita por cada capa nueva.

**Conclusión de la sección**: la spec es interna y autosuficiente (todos los FR tienen US y SC asignados), pero la consistencia cruzada con `plan.md` y `tasks.md` no puede completarse hasta que esos dos archivos se creen en `Documentacion\Agents_IA_TECH\specs\036-sync-kit-paridad-motor\`.

---

## 2. ADRs (Architecture Decision Records)

Cada ADR sigue la plantilla: título, estado, contexto, decisión, consecuencias, alternativas consideradas.

### ADR-036-01 — Orquestador único `sync-kit.ps1` en lugar de dos motores competidores

**Título**: Un único orquestador de sync transversal: `scripts/sync-kit.ps1`.  
**Estado**: Aprobado (decisión de usuario, 2026-11-03).  
**Contexto**: Existen dos motores sin paridad. `scripts/sync-kit.ps1` (1143 líneas, 19 funciones) está marcado `[021-DEPRECATED]` desde el commit `c56b56c` (2026-10-16) pero es el único invocado por `plataformador-bootstrap.ps1` vía `Invoke-SyncKit` (L2101-2139). `scripts/sync-kit-agents.ps1` (386 líneas) es un orquestador puro de 12 capas sin marca de deprecación, pero ningún script lo invoca: es un orquestador desconectado. Tras ejecutar el motor por capas con exit 0 y ERRORs: 0, el destino seguía con 78 skills obsoletos, 16 rules, 6 prompts, 5 workflows y `copilot-instructions.md` desactualizados, obligando a completar la superficie con el motor deprecado. Un motor "vigente" que exige el deprecado para completarse no es vigente: es un wrapper.  
**Decisión**: `scripts/sync-kit.ps1` es el único orquestador del sync transversal: punto de entrada que invoca `plataformador-bootstrap.ps1` y el que el usuario ejecuta a mano. Se retira la marca `[021-DEPRECATED]`. Su trabajo es orquestar, no implementar: no contiene lógica de dominio. `scripts/sync-kit-agents.ps1` deja de ser un segundo orquestador competidor; su lista de capas se integra en el orquestador único o queda como módulo invocado por él.  
**Consecuencias**: El bootstrap llama a un solo entry point; el operador ejecuta un solo comando para dejar el kit sincronizado; la mantenibilidad mejora al dividir el monolito en scripts de dominio depurables por separado; se elimina el riesgo de que el motor "vigente" requiera al deprecado para completar el trabajo.  
**Alternativas consideradas**: (a) Mantener `sync-kit-agents.ps1` como orquestador y retirar `sync-kit.ps1` — rechazado porque el bootstrap y el usuario invocan `sync-kit.ps1` y cambiar el entry point rompe contratos establecidos; (b) Crear un tercer motor nuevo — rechazado porque aumentaría lafragmentación y el usuario pidió un orquestador estable existente; (c) Mantener ambos motores con paridad forzada — rechazado porque perpetúa la duplicación de lógica y el mantenimiento de dos caminos.

### ADR-036-02 — Layout plano `scripts/sync-<dominio>.ps1` (no anidado en `scripts/sync/`)

**Título**: Scripts de dominio en la raíz de `scripts/`, con nombre plano `scripts/sync-<dominio>.ps1`.  
**Estado**: Aprobado (derivado de la decisión de arquitectura del usuario, 2026-11-03).  
**Contexto**: Hoy existe `scripts/sync/skills/sync-skills.ps1` en disco pero no figura entre las 12 capas declaradas de `$script:Layers` (L67-86 de `sync-kit-agents.ps1`). La lógica de dominio vive como funciones internas del monolito `sync-kit.ps1` (`Merge-OpenCodeConfig` 213 líneas, `Merge-KitBlock` 138, huérfanos ~340, `Sync-TransversalKit` ~280). Extraer esas funciones a scripts anidados bajo `scripts/sync/<dominio>/` replicaría la estructura actual y ocultaría los puntos de entrada.  
**Decisión**: Cada dominio de acción vive en su propio script plano bajo `scripts/`, con nombre `scripts/sync-<dominio>.ps1` (por ejemplo `scripts/sync-skills.ps1`, `scripts/sync-github-extras.ps1`, `scripts/sync-tests-kit.ps1`, `scripts/sync-mcp-graphify.ps1`, `scripts/sync-backup-prune.ps1`). Los 4 bloques extraídos del orquestador también se convierten en scripts planos: `opencode-config`, `kit-block`, `orphans`, `transversal`. Cada uno es invocable por separado y emite su propia línea `RESULT:`.  
**Consecuencias**: Cada script de dominio puede ejecutarse y depurarse de forma aislada contra un fixture temporal; el orquestador solo lista capas, invoca hijos y recolecta `RESULT:`; la superficie de scripts en `scripts/` crece pero con nombres predecibles y sin anidamiento innecesario; cero lógica de dominio queda dentro de `sync-kit.ps1`.  
**Alternativas consideradas**: (a) Mantener `scripts/sync/<dominio>/sync-<dominio>.ps1` (anidado) — rechazado porque oculta el entry point y dificulta la depuración individual; (b) Un solo script `scripts/sync-domains.ps1` con parámetro de dominio — rechazado porque viola el requisito de depuración por unidad y concentra lógica; (c) Mantener las funciones dentro del orquestador — rechazado por FR-017 y SC-009.

### ADR-036-03 — Regla "el motor no se auto-sincroniza" (excluir `sync-kit*.ps1`, `sync-*.ps1`, `lib/` de clean+replace)

**Título**: El motor de sync no se auto-sobreescribe: `sync-kit*.ps1`, `sync-*.ps1` y `lib/` quedan excluidos de las operaciones de clean+replace.  
**Estado**: Aprobado (derivado de FR-016, FR-017 y del principio VIII de la constitución).  
**Contexto**: La capa `clean+replace` de `sync-kit.ps1` copia todo el kit transversal con `robocopy /E` y hace merge de `opencode.json` y `AGENTS.md`. Si esa misma capa aplicara clean+replace sobre los scripts del motor que se está ejecutando, podría borrar el orquestador en ejecución o sobrescribir scripts de dominio mientras están cargados en memoria, corrompiendo la corrida en curso. Además, los scripts de sync son parte del kit transversal y no deben tratarse como contenido de destino reemplazable.  
**Decisión**: Se establece la regla inviolable de que las operaciones de clean+replace del motor excluyen explícitamente `sync-kit*.ps1`, `sync-*.ps1` y el directorio `lib/`. Estos archivos son infraestructura del motor, no contenido de aplicación. La exclusión se declara como allowlist estática en el orquestador y se respeta en cada capa de dominio que realice copia o reemplazo de archivos.  
**Consecuencias**: El orquestador en ejecución nunca se borra a sí mismo ni se sobrescribe durante la corrida; los scripts de dominio permanecen intactos tras el sync; el riesgo de corromper el motor en tiempo de ejecución se elimina; se añade una comprobación de seguridad que debe probarse con fixtures en `$env:TEMP`.  
**Alternativas consideradas**: (a) No excluir nada y confiar en que `robocopy` no bloquea archivos en uso — rechazado porque PowerShell bloquea archivos `.ps1` en ejecución y la corrupción sería silenciosa; (b) Excluir solo `sync-kit.ps1` — rechazado porque insuficiente: `sync-*.ps1` y `lib/` también son motor; (c) Auto-sincronizar el motor al inicio de cada corrida — rechazado porque introduce una operación destructiva sin confirmación y viola el principio VIII (fail-open nunca aplica a operaciones destructivas).

### ADR-036-04 — Bootstrap con `-SyncKit` opt-in puro (instalación y sync son operaciones distintas)

**Título**: El flag `-SyncKit` del bootstrap es opt-in y solo dispara el sync; instalación y sync son operaciones separadas.  
**Estado**: Aprobado (derivado de la constitución §VI y §VIII, y de la decisión de arquitectura).  
**Contexto**: La constitución §VI establece que la integración de herramientas externas es opt-in vía `-ForceUpgradeTools` y fail-open. Actualmente el bootstrap mezcla instalación de herramientas con sync del kit. No hay un flag claro que distinga "instalar el kit" de "sincronizar el kit". La decisión de usuario (2026-11-03) fija que `scripts/sync-kit.ps1` es el punto de entrada para el sync a mano y que el bootstrap lo invoca.  
**Decisión**: Se conserva `-SyncKit` como flag opt-puro del bootstrap: cuando se pasa, el bootstrap invoca al orquestador `sync-kit.ps1` y nada más; no instala herramientas, no clona dependencias, no reescribe configuración fuera del alcance del sync. La instalación de herramientas externas sigue siendo una operación distinta, gestionada por `upgrade_framework` y gated por `-ForceUpgradeTools`. `-SyncKit` nunca se activa por defecto ni forza instalaciones.  
**Consecuencias**: El operador controla cuándo se ejecuta el sync; no hay side effects de instalación inadvertidos; la separación permite ejecutar solo el sync sobre un destino ya instalado; el contrato de salida del bootstrap (exit 0 con WARNs/ERRORs acumulados) se mantiene.  
**Alternativas consideradas**: (a) Hacer `-SyncKit` obligatorio en cada bootstrap — rechazado porque forzaría sync en entornos donde solo se quiere instalar; (b) Un solo flag `-InstallAndSync` — rechazado porque mezcla responsabilidades y viola la separación instalación/sync; (c) Detectar automáticamente si hay que sincronizar — rechazado porque introduce lógica implícita y side effects no declarados.

### ADR-036-05 — `sync-kit-agents.ps1` absorbe sus capas o se retira como entry point competidor

**Título**: `scripts/sync-kit-agents.ps1` deja de ser entry point: sus 12 capas se integran en el orquestador único o se retiran.  
**Estado**: Aprobado (derivado de FR-019 y de la decisión de arquitectura).  
**Contexto**: `sync-kit-agents.ps1` tiene 386 líneas, es un orquestador puro de 12 capas, sin marca de deprecación, pero ningún script lo invoca. Es un "orquestador huérfano": forma correcta, sin invocador. Su lista de capas no cubre skills, rules, prompts, workflows, `copilot-instructions.md` ni tests. Mantener dos entry points genera confusión: el operador no sabe cuál ejecutar, y el "flujo vigente" es una ficción mientras requiera el motor deprecado para completarse.  
**Decisión**: O bien `sync-kit-agents.ps1` aporta su lista de 12 capas al orquestador único (`sync-kit.ps1`) y se convierte en módulo invocado por él, o bien se retira como entry point. No puede quedar un script de capa sin invocador (SC-003 exige 0 scripts huérfanos en `scripts/sync/`). Si se integra, sus capas se declaran en `$script:Layers` del orquestador y se ejecutan como procesos hijos con recolección de `RESULT:`.  
**Consecuencias**: Cero entry points huérfanos; el operador ejecuta un solo comando; la lista de capas es única y consistente; el mantenimiento se concentra en un orquestador; se elimina el riesgo de que el operador invoque el motor incorrecto y quede con paridad incompleta.  
**Alternativas consideradas**: (a) Retirar `sync-kit-agents.ps1` del repositorio — rechazado porque su lista de capas tiene valor y puede reutilizarse como referencia; (b) Mantenerlo como orquestador paralelo con paridad — rechazado porque perpetúa la duplicación y el usuario pidió un único orquestador; (c) Convertirlo en librería de funciones sin entry point — aceptada como parte de la decisión (absorbe sus capas o se retira).

---

## 3. Guardrails

Reglas que la implementación debe respetar sin excepción:

**G-01 — No tocar `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json` de apps.**  
Ninguna capa de sync, ni el orquestador, escribe en `Documentacion/<AppName>/`, en `src/` ni en `.opencode/config.json` de ninguna aplicación consumidora. El kit transversal se sincroniza entre `.github/` y `.opencode/` del kit maestro, pero el contenido de cada app permanece aislado. Esto se verifica con SC-007 (mtimes sin cambios antes/después en un destino de prueba con esas tres rutas presentes). FR-006 lo declara explícitamente: ninguna capa nueva escribe en esas rutas ni en `tests/` fuera de la whitelist del kit.

**G-02 — Cada script de dominio ejecuta aislado con `-StageDir -RootPath -DryRun`.**  
Todos los scripts de dominio (`sync-skills`, `sync-github-extras`, `sync-tests-kit`, `sync-mcp-graphify`, `sync-backup-prune` y los 4 extraídos `opencode-config`, `kit-block`, `orphans`, `transversal`) aceptan los parámetros explícitos `-StageDir`, `-RootPath` y `-DryRun`. Con `-DryRun` producen cero escrituras y cero side effects (constitución §VIII). Cada uno devuelve su propio `RESULT:<nombre>:<estado>` con exit 0 sobre fixture temporal, sin pasar por el orquestador (FR-018, US5).

**G-03 — El orquestador no define lógica de dominio.**  
`scripts/sync-kit.ps1` queda adelgazado: solo declara el listado de capas (`$script:Layers` con `Name`, `Script`, `AcceptsForce`), invoca cada dominio como proceso hijo, recolecta líneas `RESULT:` y emite el resumen de ejecución. Las 4 funciones de dominio (`Merge-OpenCodeConfig`, `Merge-KitBlock`, gestión de huérfanos, `Sync-TransversalKit`) se extraen a scripts propios (SC-009: 0 de esas 4 funciones queda definida dentro del orquestador). FR-017 lo exige y la constitución Art. II (patrón orquestador) lo refuerza: el orquestador define el contrato, no la implementación.

**G-04 — Poda de backup excluye carpetas pre-existentes al inicio de la corrida.**  
El conjunto de carpetas de `.kit-backup/` presentes al iniciar la corrida se captura como línea base antes de cualquier operación. La poda solo puede borrar carpetas generadas durante la corrida que excedan la retención (`-KeepBackups <n>`). Una carpeta del llamador presente al inicio nunca se borra, independientemente de su nombre, fecha o timestamp (FR-001, FR-002, FR-003, SC-001). El empate de timestamp entre backup del llamador y de una capa no borra nada (edge case del spec).

**G-05 — Exit codes distinguibles para el verificador de audit log.**  
`Test-AuditLogIntegrity` devuelve exit 0 si el log es válido, exit ≠0 si hay violaciones, y un estado propio (informado) si el log está ausente o vacío (FR-010, SC-004). Nunca se escribe `audit_integrity_violation` por raíces legítimas (`prevHash: null`); las raíces se cuentan y se reportan. La verificación opera sobre texto crudo de cada línea, sin round-trip `ConvertFrom-Json`/`ConvertTo-Json` (FR-008, FR-009).

---

## 4. Especificación de scripts de dominio a crear

Cada script declara parámetros, contrato de salida `RESULT:` y comportamientos esperados. El formato de salida sigue el patrón del spec (§Key Entities): `RESULT:<nombre-capa>:<estado>` donde `estado ∈ {sin-cambios, actualizado, error, omitido}`.

### 4.1. Scripts nuevos (6 scripts, 5 nombres + 1 capa compuesta)

#### 4.1.1. `scripts/sync-skills.ps1` (capa `skills`)

**Parámetros**: `-StageDir` (ruta del stage con skills del maestro), `-RootPath` (raíz del destino), `-DryRun` (switch, cero escrituras), `-Force` (switch, sobrescribe sin preguntar).  
**Contrato de salida**: `RESULT:skills:sin-cambios` si no hay diferencias; `RESULT:skills:actualizado` si se copiaron skills; `RESULT:skills:error` si falla la copia o el backup.  
**Comportamientos esperados**: Sincroniza `.github/skills/` y `.opencode/skills/` desde el stage con política idempotente. Hace backup previo de los skills existentes en `.kit-backup/<timestamp>/`. Nunca escribe en `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`. En dry-run reporta cuántos archivos cambiarían (número concreto, SC-008). Idempotente: segunda corrida inmediata emite `sin-cambios` y ningún archivo cambia de hash (US2, escenario 4).  
**FR de origen**: FR-004. **SC**: SC-002.

#### 4.1.2. `scripts/sync-github-extras.ps1` (capa `.github` restante: rules, prompts, workflows, copilot-instructions.md)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:github-extras:sin-cambios`, `RESULT:github-extras:actualizado`, `RESULT:github-extras:error`.  
**Comportamientos esperados**: Cubre `.github/rules/`, `.github/prompts/`, `.github/workflows/` y `.github/copilot-instructions.md` en una sola capa (documentado en FR-005). Política idempotente con backup previo. Cada sub-dominio (rules, prompts, workflows, copilot-instructions.md) se sincroniza independientemente dentro del script. No toca rutas protegidas (G-01). Dry-run reporta diff concreto por sub-dominio.  
**FR de origen**: FR-005, FR-006. **SC**: SC-002, SC-007.

#### 4.1.3. `scripts/sync-tests-kit.ps1` (capa de tests del kit, whitelist de 5 tests)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:tests-kit:sin-cambios`, `RESULT:tests-kit:actualizado`, `RESULT:tests-kit:error`.  
**Comportamientos esperados**: Mueve la whitelist de 5 tests (`tests/harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1`) desde `sync-kit.ps1` a esta capa. Respaldar tests del proyecto que colicionen por nombre antes de reemplazarlos (el del kit gana, es contrato). Nunca borra tests fuera de la whitelist. Ejecutable sin Pester, exit 0 / exit 1 como único contrato (FR-014).  
**FR de origen**: FR-007, FR-014. **SC**: SC-002, SC-006.

#### 4.1.4. `scripts/sync-mcp-graphify.ps1` (capa graphify, unificación de entrada)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:mcp-graphify:sin-cambios`, `RESULT:mcp-graphify:actualizado`, `RESULT:mcp-graphify:error`.  
**Comportamientos esperados**: Deja exactamente 1 entrada `graphify` en `opencode.json`, en la forma canónica de la spec 020 (`mcp.servers.graphify`). Regenera la ruta cuando apunte fuera de `RootPath`, no solo cuando el ejecutable falte. Preserva `enabled` elegido por el proyecto (FR-012). Emite WARN al detectar duplicados (V1 y V2 a la vez) o una ruta ajena corregida, indicando cuál se conservó. Si `graphify` está ausente por completo, se crea con la ruta del destino; si `graphify-out/` no existe, se emite WARN y no se inventa ruta a grafo inexistente (edge case).  
**FR de origen**: FR-011, FR-012. **SC**: SC-005.

#### 4.1.5. `scripts/sync-backup-prune.ps1` (capa de poda de backup)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-KeepBackups <n>`, `-NoPrune`.  
**Contrato de salida**: `RESULT:backup-prune:sin-cambios`, `RESULT:backup-prune:actualizado`, `RESULT:backup-prune:error`.  
**Comportamientos esperados**: Captura el conjunto de carpetas de `.kit-backup/` presentes al inicio de la corrida como línea base. Excluye esas carpetas de la poda (FR-001). Expone `-KeepBackups <n>` (retención de carpetas generadas por la corrida) y `-NoPrune` (desactiva la poda), con default que nunca borre el backup del llamador (FR-002). Cada borrado queda registrado en el resumen con ruta, tamaño y regla aplicada (FR-003). Fallo de poda es fail-open con WARN, no aborta la corrida. Poda interrumpida a mitad: cada borrado independiente, se registra, no revierte anteriores (edge case). Archivos sueltos en `.kit-backup/` (no directorios con formato `yyyyMMdd-HHmmss`) se ignoran y reportan como no podables.  
**FR de origen**: FR-001, FR-002, FR-003. **SC**: SC-001.

#### 4.1.6. (6º dominio compuesto) `scripts/sync-audit-log.ps1` — verificación de integridad del audit log

Nota: la spec ubica `Test-AuditLogIntegrity` en `upgrade_framework.ps1` (L203-229), no como script nuevo. Se incluye aquí para completar la trazabilidad de D3.  
**Parámetros**: `-LogPath` (ruta a `.bootstrap-audit.log`), `-DryRun`.  
**Contrato de salida**: `RESULT:audit-log:valido` (exit 0), `RESULT:audit-log:violaciones` (exit ≠0), `RESULT:audit-log:vacio-o-ausente` (estado propio).  
**Comportamientos esperados**: Recalcula hash sobre payload que excluya `hash` y `prevHash` (FR-008). Opera sobre texto crudo de cada línea, sin round-trip JSON (FR-008). Trata `prevHash: null` como raíz legítima, contada y reportada (FR-009). No escribe `audit_integrity_violation` por raíces. Sobre 206 entradas reales devuelve 0 violaciones e informa 136 raíces (SC-004). Sobre copia con 1 entrada alterada detecta exactamente esa entrada.  
**FR de origen**: FR-008, FR-009, FR-010. **SC**: SC-004.

### 4.2. Scripts extraídos del orquestador (4 scripts)

#### 4.2.1. `scripts/sync-opencode-config.ps1` (extraído: `Merge-OpenCodeConfig`)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:opencode-config:sin-cambios`, `RESULT:opencode-config:actualizado`, `RESULT:opencode-config:error`.  
**Comportamientos esperados**: Extrae la función `Merge-OpenCodeConfig` (213 líneas hoy dentro de `sync-kit.ps1`) a un script propio, conservando el comportamiento actual: merge de `opencode.json` del stage contra el destino, preservando claves del proyecto, sin duplicar entradas (especialmente `graphify`). Conserva la forma canónica de la spec 020. No toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json` de apps.  
**FR de origen**: FR-017. **SC**: SC-009.

#### 4.2.2. `scripts/sync-kit-block.ps1` (extraído: `Merge-KitBlock`)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:kit-block:sin-cambios`, `RESULT:kit-block:actualizado`, `RESULT:kit-block:error`.  
**Comportamientos esperados**: Extrae `Merge-KitBlock` (138 líneas hoy dentro de `sync-kit.ps1`): merge del bloque `KIT-BLOCK` en `AGENTS.md` por bloque, ya resuelto y cubierto por los escenarios 8-10 del commit `35da532` (asunción de la spec). No modifica contenido de `AGENTS.md` fuera del bloque `KIT-BLOCK`.  
**FR de origen**: FR-017. **SC**: SC-009.

#### 4.2.3. `scripts/sync-orphans.ps1` (extraído: gestión de huérfanos)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:orphans:sin-cambios`, `RESULT:orphans:actualizado`, `RESULT:orphans:error`.  
**Comportamientos esperados**: Extrae `Find-OrphanKitFiles`, `Remove-OrphanFiles`, `Move-OrphanFilesToBackup`, `Invoke-OrphanDecision` (~340 líneas hoy dentro de `sync-kit.ps1`). Nunca borra sin decisión explícita (edge case de skills retiradas en el maestro: quedan huérfanas y el escáner las reporta con acción `Conservar`/`Mover`). Conserva el comportamiento actual del motor deprecado.  
**FR de origen**: FR-017. **SC**: SC-009.

#### 4.2.4. `scripts/sync-transversal.ps1` (extraído: `Sync-TransversalKit`)

**Parámetros**: `-StageDir`, `-RootPath`, `-DryRun`, `-Force`.  
**Contrato de salida**: `RESULT:transversal:sin-cambios`, `RESULT:transversal:actualizado`, `RESULT:transversal:error`.  
**Comportamientos esperados**: Extrae `Sync-TransversalKit` (~280 líneas hoy dentro de `sync-kit.ps1`): copia del kit transversal con `robocopy /E`, respetando la regla "el motor no se auto-sincroniza" (ADR-036-03: excluye `sync-kit*.ps1`, `sync-*.ps1`, `lib/`). No toca rutas protegidas.  
**FR de origen**: FR-017. **SC**: SC-009.

---

## 5. Riesgos identificados

Cada riesgo incluye impacto y mitigación.

### R-001 — Bootstrap descarga `sync-kit.ps1` como archivo único (descarga incompleta al adelgazar)

**Impacto**: Alto. Si el bootstrap descarga `sync-kit.ps1` como archivo único y la descarga se interrumpe o está incompleta (por el adelgazamiento del script), el orquestador queda corrupto y cualquier sync posterior falla o se ejecuta con lógica parcial. Esto afecta a todos los destinos que se sincronicen tras el cambio.  
**Mitigación**: Verificar checksum del archivo descargado antes de invocarlo; si el checksum no coincide, abortar con ERROR (fail-closed, operación destructiva) y no ejecutar el sync. Mantener una copia de respaldo local de la versión anterior hasta que la nueva se valide con `Parser::ParseFile` (0 errores de sintaxis).  
**Detectado en**: análisis de la decisión de arquitectura y del estado real medido (sync-kit.ps1 tiene 1143 líneas y 19 funciones).

### R-002 — Capa clean+replace borra el orquestador en ejecución

**Impacto**: Crítico. Si la capa `Sync-TransversalKit` aplica clean+replace sin excluir `sync-kit*.ps1`, `sync-*.ps1` y `lib/`, puede sobrescribir o borrar el orquestador mientras está cargado en memoria, corrompiendo la corrida en curso y dejando el destino sin motor funcional.  
**Mitigación**: Aplicar ADR-036-03 como allowlist estática: `sync-kit*.ps1`, `sync-*.ps1` y `lib/` quedan excluidos de cualquier operación de clean+replace. Probar con fixture en `$env:TEMP` que el orquestador en ejecución no se modifique tras una corrida completa.  
**Detectado en**: ADR-036-03 y constitución §VIII (fail-open nunca aplica a operaciones destructivas).

### R-003 — `sync-kit-agents.ps1` entry point huérfano

**Impacto**: Medio. Si `sync-kit-agents.ps1` queda en el repositorio sin invocador y sin integración al orquestador único, persiste la confusión de dos motores y SC-003 (0 scripts huérfanos) no se cumple. Un operador podría invocarlo por error y obtener paridad incompleta.  
**Mitigación**: Integrar sus 12 capas en `$script:Layers` de `sync-kit.ps1` o retirar el script como entry point. Verificar con `grep` que ningún script invoca `sync-kit-agents.ps1` directamente y que `-ListLayers` del orquestador enumera todas las capas sin huérfanos.  
**Detectado en**: estado real medido (ningún script invoca `sync-kit-agents.ps1`) y FR-019.

### R-004 — `Test-AuditLogIntegrity` falso negativo

**Impacto**: Alto. El verificador actual nunca puede pasar (elimina solo `hash` dejando `prevHash`, exige cadena lineal con 136 raíces, opera por round-trip JSON que altera el `timestamp`). Un verificador que siempre falla entrena a ignorar la señal de integridad y ensucia el log con eventos `audit_integrity_violation` espurios.  
**Mitigación**: Reescribir `Test-AuditLogIntegrity` para recalcular hash sobre texto crudo excluyendo `hash` y `prevHash`, tratar `prevHash: null` como raíz legítima sin exigir cadena lineal, y devolver exit codes distinguibles (0 / ≠0 / vacío-ausente). Validar sobre el log real de 206 entradas (0 violaciones, 136 raíces) y sobre copia con 1 entrada alterada (detección exacta).  
**Detectado en**: D3 del spec y SC-004.

### R-005 — Dry-run que no calcula diff (solo anuncia la acción)

**Impacto**: Medio. SC-008 exige que el dry-run del orquestador reporte, para cada capa nueva, cuántos archivos cambiarían (número concreto). Si las capas solo anuncian "se sincronizarían" sin calcular el diff, el operador no puede planificar el impacto y el requisito SC-008 no se cumple.  
**Mitigación**: Cada script de dominio debe implementar un modo dry-run que compare SHA-256 o listas de archivos entre stage y destino y reporte el número concreto de archivos que cambiarían, sin escribir. El orquestador agrega estos números en su resumen. Probar con fixture temporal y verificar cero escrituras.  
**Detectado en**: edge case del spec (línea 226) y SC-008.

---

## 6. Métricas de éxito

Los 10 criterios SC de la spec mapeados a tareas verificables. Cada SC tiene un criterio de aceptación concreto y medible.

| SC | Criterio medible (spec) | Tarea verificable asociada | FR de origen | Medida de éxito |
|----|-------------------------|----------------------------|--------------|-----------------|
| SC-001 | Con 3 backups previos en `.kit-backup/`, una corrida completa deja los 3 intactos (hash de `MANIFEST.sha256` idéntico antes y después). Antes del arreglo: 0 de 3 sobreviven. | Ejecutar orquestador sobre destino de prueba con 3 carpetas de backup previas; verificar que las 3 siguen presentes con hashes intactos. | FR-001, FR-002, FR-003 | 3/3 backups intactos; hash de `MANIFEST.sha256` idéntico antes/después. |
| SC-002 | Ejecutando solo `scripts/sync-kit.ps1` sobre el destino, divergencia SHA-256 contra el maestro es 0 en `.github/skills` (89), `.opencode/skills` (89), `.github/rules` (16), `.github/prompts` (6), `.github/workflows` (5), `tests/` (5 de whitelist) y `.github/copilot-instructions.md`. | Ejecutar solo el orquestador sobre destino vacío o con divergencia; comparar por SHA-256 cada área contra el maestro. | FR-004, FR-005, FR-007 | 0 archivos distintos y 0 solo-en-destino en cada área listada. |
| SC-003 | Un solo comando completa el sync: no queda un segundo motor al que recurrir ni un script de capa sin invocador (0 scripts huérfanos en `scripts/sync/`). | Revisar `scripts/sync/` y confirmar que todo script de capa tiene invocador en el orquestador; `grep` confirma que ningún script invoca `sync-kit-agents.ps1` directamente. | FR-016, FR-019 | 0 scripts huérfanos; 1 entry point de sync. |
| SC-004 | Sobre el log real de 206 entradas, el verificador devuelve 0 violaciones e informa 136 raíces; sobre copia con 1 entrada alterada, detecta exactamente esa entrada y ninguna más. | Correr verificador sobre `.bootstrap-audit.log` actual; luego corromper un byte en una copia y verificar detección exacta. | FR-008, FR-009, FR-010 | exit 0 con 136 raíces sobre el log real; exit ≠0 detectando 1 entrada alterada sobre la copia. |
| SC-005 | `opencode.json` del destino contiene exactamente 1 entrada `graphify` y su ruta resuelta está dentro de `RootPath`; `enabled` conserva el valor previo en el 100 % de los casos probados. | Leer `opencode.json` del destino, contar entradas `graphify` en todas las formas, verificar ruta dentro de RootPath y `enabled` preservado. | FR-011, FR-012 | 1 entrada graphify; ruta dentro de RootPath; `enabled` preservado 100 %. |
| SC-006 | La suite del kit pasa con `exit 0` y suma al menos 15 asserts nuevos respecto de los 45 actuales (escenarios de D1-D5), con 0 `[FAIL]`. | Ejecutar suite de tests del kit sin Pester; contar asserts nuevos (mínimo 15) y verificar 0 fallos. | FR-013, FR-014 | exit 0; ≥15 asserts nuevos; 0 `[FAIL]`. |
| SC-007 | Ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json` (mtimes sin cambios antes/después en destino de prueba con esas tres rutas presentes). | Ejecutar orquestador sobre destino de prueba con esas rutas; comparar mtimes antes y después. | FR-006 | mtimes sin cambios en las 3 rutas protegidas. |
| SC-008 | Un dry-run del orquestador reporta, para cada capa nueva, cuántos archivos cambiarían (número concreto, no "se sincronizarían") y no escribe ningún archivo. | Ejecutar orquestador con `-DryRun`; verificar que cada capa reporta número concreto y que no hay escrituras (mtimes intactos). | FR-018, edge case dry-run | Número concreto por capa; cero escrituras. |
| SC-009 | 0 de las 4 funciones de dominio (`Merge-OpenCodeConfig`, `Merge-KitBlock`, huérfanos, `Sync-TransversalKit`) queda definida dentro de `sync-kit.ps1`; las 4 existen como script propio y se ejecutan de forma aislada sobre un fixture con exit 0. | Inspeccionar `sync-kit.ps1` y confirmar ausencia de esas 4 funciones; ejecutar cada script extraído sobre fixture con exit 0. | FR-017, FR-018 | 0 funciones de dominio en el orquestador; 4 scripts propios con exit 0 sobre fixture. |
| SC-010 | Las 6 capas de la superficie restante (skills, rules, prompts, workflows, `copilot-instructions.md`, tests) se ejecutan individualmente con exit 0 y emiten su `RESULT:` propio; el orquestador las enumera con `-ListLayers` y no hay ningún script de capa sin invocador. | Ejecutar cada capa de dominio aislada con `-StageDir -RootPath -DryRun` sobre fixture; verificar `RESULT:` y exit 0; ejecutar `-ListLayers` del orquestador. | FR-018, FR-020 | 6 capas con exit 0 y `RESULT:`; `-ListLayers` funcional; 0 scripts sin invocador. |

---

## 7. Verificación de cumplimiento constitucional

- **Art. II (Orquestator Pattern)**: `sync-kit.ps1` es el orquestador principal; coordina capas de dominio sin implementar lógica (ADR-036-01, ADR-036-02, FR-016, FR-017). ✅
- **Art. IV (Copilot/Opencode Compatibility)**: los cambios son en scripts `.ps1` comunes a ambos harnesses; no hay divergencia entre `.github/` y `.opencode/`. ✅
- **Art. V (Observability)**: cada capa emite `RESULT:`; el orquestador recolecta y resume; la poda registra cada borrado; el verificador de audit log reporta raíces y violaciones. ✅
- **Art. VII (Restricción de Paths por Tier)**: este archivo (`analyze.md`) es documento del arquitecto (tier Documental) y se escribe solo en `Documentacion/<AppName>/specs/`, dentro de su whitelist. No toca `src/` ni código de aplicación. ✅
- **Art. VIII (Fail-Open)**: la poda de backup es fail-open con WARN; las operaciones destructivas (clean+replace) excluyen el motor y no se auto-sincronizan (ADR-036-03). ✅
- **Art. IX (Contenido Completo)**: este archivo rellena todas las secciones con contenido real; no hay placeholders ni tablas vacías. ✅

---

## 8. Estado y bloqueos para la siguiente fase

**Estado del analyze**: completo. Todas las secciones tienen contenido real; no hay placeholders.

**Bloqueos para pasar a Converge/Implement**:
1. `plan.md` y `tasks.md` de la spec 036 no existen en disco (H-01). Deben crearse antes de implementar, con al menos una tarea por cada uno de los 20 FR.
2. La discrepancia de volumen de tareas (7 en `pendientes-implementacion.md` vs 28 declaradas por el usuario) debe resolverse (H-02).
3. FR-013/FR-014 requieren confirmar si se usa `tests/kit-sync-merge.ps1` existente o se crea `tests/sync-layers.ps1` (H-03).
4. Falta tarea dedicada para el contrato de 3 exit codes del verificador de audit log (FR-010, H-04).
5. Cada capa nueva necesita tarea explícita de dry-run con cálculo de diff real (FR-018, SC-008, H-05).

**Responsable sugerido**: `plataformador` (tier Implementador) para los scripts de dominio; `pensador` para la creación de `plan.md`/`tasks.md` y la actualización de `pendientes-implementacion.md`.

---
*Fin del analyze 036. Generado por el agente `arquitecto` en la Fase Analyze del pipeline Speckit.*
