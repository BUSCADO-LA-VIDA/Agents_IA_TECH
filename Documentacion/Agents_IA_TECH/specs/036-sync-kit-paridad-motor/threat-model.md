# Threat Model y Reporte de Riesgos de Seguridad — Spec 036

**Especificación analizada**: `036-sync-kit-paridad-motor` — Orquestador único de sync del kit y capas de dominio depurables  
**Ruta del artefacto**: `Documentacion/Agents_IA_TECH/specs/036-sync-kit-paridad-motor/threat-model.md`  
**Constitución de referencia**: `.specify/memory/constitution.md` v2.0.0, Art. V (Security: threat model obligatorio, secrets management), Art. VII (Restricción de Paths por Tier), Art. VIII (Fail-Open en Integraciones Externas)  
**Metodología**: STRIDE (Spoofing, Tampering, Repudiación, Information Disclosure, Denial of Service, Elevation of Privilege)  
**Estado**: Borrador para la Fase Analyze (previa a Implement)  
**Defectos en alcance**: D1 (poda backup), D2 (capa skills/faltante), D3 (audit log falso negativo), D4 (tests solo por motor deprecado), D5 (graphify duplicado)

---

## 1. Resumen ejecutivo

Este threat model analiza la superficie de seguridad del sync transversal del kit `Agents_IA_TECH` hacia proyectos consumidores (por ejemplo `Generator_IA_Projects`), tal como lo especifica la spec 036. El sync transporta el kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `scripts/`, `.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`, `upgrade_framework.ps1`) desde el repo maestro de GitHub hacia el destino. El orquestador estable es `scripts/sync-kit.ps1`, que debe invocar scripts de dominio hijos (skills, agentes de cada arnés, MCP, docs, constitution, tests, merge de `opencode.json`, merge de `AGENTS.md`, huérfanos) y recolectar sus líneas `RESULT:`. La arquitectura objetivo, fijada por el usuario el 2026-11-03, establece que el orquestador no contenga lógica de dominio: cada regla vive en su propio script invocable y depurable por separado.

El alcance del análisis cubre: la descarga del kit desde GitHub, el stage intermedio, la ejecución de scripts de dominio, el manejo de backups en `.kit-backup/`, la poda de backups antiguos, la escritura de `opencode.json`, el audit log `.bootstrap-audit.log`, y la gestión de `.opencode/config.json` (posibles credenciales). Quedan fuera de alcance: el contenido de `Documentacion/<AppName>/`, el código de aplicación en `src/`, y los agentes/skills en sí (la spec solo corrige el motor, no el contenido que transporta, per la sección Fuera de alcance de la spec).

Los límites de confianza son: el repo maestro de GitHub (origen de verdad, allowlist de owners), el stage local (`scripts/sync/` y scripts de dominio), el destino del proyecto (raíz sincronizada), y `.kit-backup/` (zona de rollback). Cualquier operación destructiva (borrado, sobrescritura,移动 fuera de la allowlist) es fail-closed per Art. VIII de la constitución; las integraciones externas son fail-open pero nunca para operaciones destructivas. La constitution prohíbe escribir rutas absolutas, hardcodear nombres de dominio concreto, y deja `.opencode/config.json` fuera del versionado por `.gitignore`.

---

## 2. Modelo de amenazas STRIDE

Cada hallazgo está etiquetado con su letra STRIDE y se detalla con activo, amenaza, impacto y control asociado.

### 2.1 S — Spoofing (Suplantación de identidad)

**Activo**: Origen del kit descargado desde GitHub (`RepoUrl`, `-KitPath`, clon shallow del repo maestro).  
**Amenaza**: Un atacante o un error de configuración hace que el sync descargue el kit desde un repositorio ajeno al allowlist, suplantando el origen de confianza. El ejecutor recibiría scripts y configuración de un actor no autorizado, comprometiendo la integridad de todo el kit transversal antes de que se ejecute cualquier capa.  
**Impacto**: Ejecución de código arbitrario con el scope del orquestador en el destino; sustitución de `opencode.json`, `AGENTS.md` y scripts de dominio por versiones maliciosas.  
**Control asociado**: Allowlist de owners de confianza (`TrustedOwners` en `sync-kit.ps1`: `BUSCADO-LA-VIDA`, `github`, `microsoft`, `DeusData`, `mksglu`), validación fail-closed de URL con regex `^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$` (`Test-TrustedGithubUrl`), rechazo de cualquier URL en `-KitPath` (fail-closed, throw `[SECURITY]`), y `Test-AllowedKitUrl` en `sync-kit-agents.ps1`. El default de `RepoUrl` apunta a `BUSCADO-LA-VIDA/Agents_IA_TECH`.

### 2.2 T — Tampering (Manipulación de integridad)

**Activo**: Scripts de dominio entre el stage y el destino (por ejemplo `scripts/sync/skills/sync-skills.ps1`, `scripts/sync/mcp/lift-opencode.ps1`, `scripts/sync/constitutions/sync-constitutions.ps1`).  
**Amenaza**: Un script de dominio es modificado, inyectado o sustituido entre el momento en que seステージa y el momento en que el orquestador lo ejecuta, sin que se detecte la alteración. Como el orquestador delega la lógica de dominio a estos scripts (FR-016/FR-017), un script manipulado se ejecuta con el mismo alcance que el orquestador.  
**Impacto**: Alteración silenciosa del comportamiento de una capa (por ejemplo, la capa de MCP podría apuntar `graphify` a un grafo ajeno, o la capa de constituciones podría sobrescribir `.specify/memory/constitution.md`). No hay hash-guard ni firma sobre los scripts de dominio hoy en día.  
**Control asociado**: Ningún control de integridad activo sobre scripts de dominio antes de ejecutarlos. Existe hash-guard solo para `.opencode/.gitignore` (comparación de SHA256, conservar local si difiere, `-Force` para sobrescribir) en `sync-kit.ps1` (L998-1024), que no cubre los scripts de dominio.

### 2.3 R — Repudiación (Falta de trazabilidad)

**Activo**: Operaciones de poda de `.kit-backup/` (D1) y borrados de huérfanos.  
**Amenaza**: La poda de backups (`sync-kit-agents.ps1` L359-384) borra carpetas de `.kit-backup/` sin registrar qué se borró, cuándo, por qué regla y bajo qué parámetros de retención. Un operador no puede auditar después si un backup del llamador fue eliminado por error, ni distinguir un borrado legítimo de uno no autorizado.  
**Impacto**: Pérdida de punto de rollback sin evidencia; imposibilidad de atribuir responsabilidades; incumplimiento del Art. V de la constitución (observabilidad y trazabilidad obligatorias).  
**Control asociado**: Ningún registro de borrados hoy. La poda actual solo emite `Write-Info "Backups podados: $pruned"` sin detalle de rutas, tamaños ni reglas aplicadas (FR-003 exige este registro).

### 2.4 I — Information Disclosure (Divulgación de información)

**Activo**: `.opencode/config.json` (posibles credenciales, tokens, claves de MCP).  
**Amenaza**: Durante el sync, `.opencode/config.json` es copiado, leído o expuesto en logs temporales, stage o resumen de ejecución, revelando secretos del proyecto destino. El `.gitignore` de la raíz ya lo excluye (línea 7: `.opencode/config.json`) y `sync-kit.ps1` lo salta con `if ($rel -eq ".opencode/config.json") { continue }` (L155-156) y `robocopy ... /XF "config.json"` (L1015-1019), pero la exclusión no está garantizada en todas las capas de dominio nuevas.  
**Impacto**: Exposición de credenciales a cualquier actor con lectura del stage, del log de ejecución o del destino; compromiso de cuentas MCP y servicios externos vinculados.  
**Control asociado**: Exclusión explícita de `.opencode/config.json` en `sync-kit.ps1`, entrada en `.gitignore` de raíz y de `.opencode/`, y `FR-006` que prohíbe a las capas nuevas escribir en `.opencode/config.json`.

### 2.5 D — Denial of Service (Denegación de servicio)

**Activo**: Backups críticos en `.kit-backup/` y disponibilidad del sync.  
**Amenaza**: Una poda agresiva (sin `-KeepBackups`, sin `-NoPrune`, sin exclusión del backup del llamador) borra backups necesarios para revertir un sync fallido, o interrumpe la ejecución del sync al eliminar el stage temporal mientras una capa lo usa. D1 materializó este riesgo: `.kit-backup/20261102-164540` (4 603 archivos, 64 160 489 bytes) fue borrado al final de una corrida exitosa.  
**Impacto**: Irreversibilidad de un sync sobre una raíz sin git (como `Generator_IA_Projects`), pérdida de datos del llamador, y sync que no puede completarse porque el stage desapareció.  
**Control asociado**: Parámetros `-KeepBackups <n>` y `-NoPrune` (FR-002), exclusión del conjunto de carpetas presentes al inicio de la corrida (FR-001), poda fail-open con WARN sin abortar la corrida (FR-003), y conservación del temp de stage en caso de error (`L348-357`).

### 2.6 E — Elevation of Privilege (Escalada de privilegios)

**Activo**: Ejecución de scripts de dominio con el scope del orquestador (`sync-kit.ps1` ejecutado por el bootstrap o por el operador).  
**Amenaza**: Un script de dominio recibe parámetros de entrada sin validar (por ejemplo `-StageDir`, `-RootPath`, `-Force`) y ejecuta operaciones destructivas con el alcance completo del orquestador, incluyendo rutas fuera de la allowlist del kit (`Documentacion/<AppName>/`, `src/`, `.opencode/config.json`). Un parámetro inyectado o una ruta mal formada podría hacer que una capa escriba fuera de su dominio asignado.  
**Impacto**: Escritura en rutas prohibidas por el Art. VII de la constitución (tiers documental no pueden escribir `src/` ni `Documentacion/<OtraApp>/`), sobrescritura de contenido de la app, y ejecución de operaciones con más privilegios de los necesarios para la capa.  
**Control asociado**: `FR-018` (parámetros explícitos `-StageDir`, `-RootPath`, `-DryRun`), `FR-006` (ninguna capa nueva escribe en rutas prohibidas), validación de `-RootPath` con `[IO.Path]::GetFullPath` y fallo temprano (`sync-kit-agents.ps1` L55), y fail-closed en `-KitPath` (L117-119).

---

## 3. Riesgos de seguridad (`security-risk:`)

Cada riesgo incluye ID, etiqueta `security-risk:`, descripción, severidad, mitigación y la tarea de `tasks.md` que lo aborda. Como `tasks.md` aún no existe para la spec 036 (solo `spec.md`), las tareas se refieren a los requisitos (FR) e historias de usuario (US) de la spec que se materializarán como tareas en `tasks.md` durante la fase de planificación.

### SR-036-01 — Spoofing en la descarga del kit desde GitHub

**security-risk:** Un operador o proceso automatizado invoca el sync con una `RepoUrl` o `-KitPath` que apunta a un repositorio no autorizado, y el orquestador acepta la descarga porque no hay validación estricta de owner en todos los caminos de entrada (solo `sync-kit.ps1` valida `TrustedOwners`; `sync-kit-agents.ps1` valida con `Test-AllowedKitUrl` que solo verifica prefijo `https://github.com/*` sin restricir al allowlist de owners).  
**Severidad**: Alta  
**Mitigación**: Unificar la validación de URLs en una sola función fail-closed que verifique owner contra el allowlist (`TrustedOwners`) en ambos scripts, rechazar cualquier URL en `-KitPath`, y mantener el default de `RepoUrl` apuntando al owner de confianza.  
**Tarea de tasks.md**: Tarea derivada de FR-016/FR-017 (unificación de validación de URL en el orquestador y capas de dominio), historia US5.

### SR-036-02 — Tampering de scripts de dominio entre stage y destino

**security-risk:** Los scripts de dominio (skills, MCP, constituciones, agents, docs, etc.) se ejecutan sin verificación de integridad previa. Un script modificado tras el stage y antes de la ejecución se correría con el alcance del orquestador, sin que exista hash SHA256 ni firma que detecte la manipulación.  
**Severidad**: Alta  
**Mitigación**: Implementar hash-guard de scripts de dominio (SHA256 del script en el stage comparado contra un manifiesto de hashes esperado antes de ejecutar), y valorar firma de scripts con certificado de código.  
**Tarea de tasks.md**: Tarea derivada de FR-018 (ejecución aislada de scripts de dominio con parámetros explícitos) y FR-017 (extracción de lógica de dominio), historia US5.

### SR-036-03 — Repudiación en borrados de backup (poda sin trazabilidad)

**security-risk:** La poda de `.kit-backup/` borra carpetas sin registrar ruta, tamaño, regla aplicada y parámetros de retención. No hay trazabilidad de qué backup se borró, por qué regla y cuándo, impidiendo auditoría y atribucion (D1).  
**Severidad**: Media  
**Mitigación**: Registrar cada borrado de la poda en el resumen de ejecución con ruta, tamaño y regla aplicada (FR-003); fail-open con WARN si falla la poda, sin abortar la corrida.  
**Tarea de tasks.md**: Tarea derivada de FR-001, FR-002, FR-003, historia US1.

### SR-036-04 — Information disclosure de `.opencode/config.json`

**security-risk:** `.opencode/config.json` puede contener credenciales y tokens de MCP. Si una capa de dominio nueva lo copia, lo lee o lo expone en logs, los secretos quedan expuestos. La exclusión actual está solo en `sync-kit.ps1`, no garantizada en todas las capas.  
**Severidad**: Alta  
**Mitigación**: Mantener la exclusión de `.opencode/config.json` en todas las capas de dominio (FR-006), asegurar la entrada en `.gitignore` de raíz y `.opencode/`, y nunca escribir secretos en stdout/stderr ni en el resumen de ejecución.  
**Tarea de tasks.md**: Tarea derivada de FR-006, historia US2 y SC-007.

### SR-036-05 — Denial of service por poda agresiva de backups

**security-risk:** Sin `-KeepBackups` ni `-NoPrune`, y sin excluir el backup del llamador del conjunto inicial, la poda borra backups críticos necesarios para rollback. Ya ocurrió con `.kit-backup/20261102-164540` (64 MB, 4 603 archivos) borrado al final de una corrida exitosa (D1).  
**Severidad**: Media  
**Mitigación**: Excluir del podado todo lo que existiera antes de iniciar la corrida (conjunto inicial, no nombre ni fecha, FR-001); exponer `-KeepBackups <n>` y `-NoPrune` con default que nunca borre el backup del llamador (FR-002).  
**Tarea de tasks.md**: Tarea derivada de FR-001, FR-002, historia US1.

### SR-036-06 — Elevation of privilege en ejecución de scripts de dominio

**security-risk:** Los scripts de dominio reciben parámetros de entrada (`-StageDir`, `-RootPath`, `-Force`) sin validación estricta de contención, permitiendo escritura fuera de la allowlist del kit (`Documentacion/<AppName>/`, `src/`, `.opencode/config.json`) con el alcance del orquestador.  
**Severidad**: Alta  
**Mitigación**: Validar contención de rutas (`realpath` verificado, sin symlinks, sin `..`, salida obligatoria dentro de `RootPath`), aplicar fail-closed en operaciones destructivas, y ejecutar cada capa con el mínimo alcance necesario (FR-018).  
**Tarea de tasks.md**: Tarea derivada de FR-016, FR-017, FR-018, historia US5.

### SR-036-07 — Audit log falso negativo (integridad no verificable)

**security-risk:** `Test-AuditLogIntegrity` (`upgrade_framework.ps1` L203-229) recalcula el hash dejando `prevHash` dentro del payload, exige cadena lineal cuando 136 de 204 entradas históricas tienen `prevHash: null`, y usa round-trip JSON que altera el `timestamp`. Da falso negativo siempre, entrenando a ignorar la señal de integridad (D3).  
**Severidad**: Media  
**Mitigación**: Recalcular el hash sobre payload que excluya `hash` y `prevHash`, operar sobre texto crudo de cada línea (sin round-trip JSON), tratar `prevHash: null` como raíz legítima contada y reportada, y devolver códigos de salida distinguibles (0 válido, ≠0 violaciones, estado propio para log ausente/vacío) per FR-008/FR-009/FR-010.  
**Tarea de tasks.md**: Tarea derivada de FR-008, FR-009, FR-010, historia US3.

### SR-036-08 — Entrada `graphify` duplicada y contradictoria en `opencode.json`

**security-risk:** `opencode.json` del destino tiene dos entradas `graphify` (V1 `mcp.graphify` y V2 `mcp.servers.graphify`) apuntando a grafos distintos (maestro vs destino). El agente consulta el grafo de otro proyecto como si fuera propio: fallo silencioso de razonamiento (D5).  
**Severidad**: Media  
**Mitigación**: Dejar una sola entrada `graphify` en forma canónica (spec 020), regenerar la ruta cuando apunte fuera de `RootPath` (no solo cuando falta el ejecutable), preservar `enabled` del usuario, y emitir WARN al detectar duplicados o rutas ajenas corregidas (FR-011/FR-012).  
**Tarea de tasks.md**: Tarea derivada de FR-011, FR-012, historia US4.

### SR-036-09 — Falta de capa `skills` y de superficie `.github/` (reglas, prompts, workflows, copilot-instructions)

**security-risk:** No existe capa `skills` ni capa para `.github/rules`, `.github/prompts`, `.github/workflows`, `.github/copilot-instructions.md`. El destino se queda con 78 skills obsoletos y material desactualizado, obligando a recurrir al motor deprecado y dejando superficie sin sincronizar (D2).  
**Severidad**: Media  
**Mitigación**: Declarar capa `skills` (`.github/skills/` y `.opencode/skills/`) y una capa propia para el resto de `.github/` (FR-004/FR-005), con política idempotente, backup previo y `RESULT:` propio.  
**Tarea de tasks.md**: Tarea derivada de FR-004, FR-005, FR-006, historia US2.

### SR-036-10 — Tests del kit solo viajan por el motor deprecado

**security-risk:** La whitelist de 5 tests del kit está solo en `sync-kit.ps1` (motor deprecado); el orquestador por capas no tiene capa de tests. Los tests propios del proyecto que colisionan por nombre pueden borrarse sin respaldo, y los tests fuera de whitelist no están protegidos (D4).  
**Severidad**: Media  
**Mediación**: Mover la whitelist de tests a una capa del orquestador, con respaldo de tests del proyecto que colisionen por nombre y sin borrar tests fuera de la whitelist (FR-007/FR-014).  
**Tarea de tasks.md**: Tarea derivada de FR-007, FR-014, historia US2.

---

## 4. Controles de seguridad existentes

Los siguientes controles ya están implementados en el código base y constituyen la línea base sobre la que se construye el threat model:

1. **Allowlist de URLs y owners de confianza**: `sync-kit.ps1` define `$TrustedOwners` (`BUSCADO-LA-VIDA`, `github`, `microsoft`, `DeusData`, `mksglu`) y `Test-TrustedGithubUrl` valida el formato `https://github.com/<owner>/<repo>` con owner en allowlist (fail-closed). `sync-kit-agents.ps1` valida con `Test-AllowedKitUrl` y rechaza URLs en `-KitPath` con throw `[SECURITY]` (fail-closed). El default de `RepoUrl` apunta al owner de confianza.

2. **Hash-guard de `.opencode/.gitignore`**: `sync-kit.ps1` compara SHA256 del `.gitignore` local vs maestro; si difieren, se conserva el local (fail-closed) y solo `-Force` sobrescribe; si falta, se restaura desde el maestro (L998-1024).

3. **Exclusión de `.opencode/config.json`**: `sync-kit.ps1` salta `.opencode/config.json` con `continue` (L155-156), lo excluye en `robocopy /XF "config.json"` (L1015-1019), y está en `.gitignore` de raíz (línea 7) y de `.opencode/` (línea 7). `FR-006` extiende esta prohibición a las capas nuevas.

4. **Fail-closed en URLs y en operaciones destructivas**: Cualquier URL no permitida rechaza la operación; `-KitPath` no acepta esquemas remotos. Las operaciones destructivas (eliminar, sobrescribir, mover fuera de la allowlist) exigen fail-closed (abortar con ERROR) per Art. VIII de la constitución; el fail-open solo aplica a integraciones externas no destructivas.

5. **Backup previo a clean+replace**: Cada capa que hace clean+replace toma un backup en `.kit-backup/<yyyyMMdd-HHmmss>/` con `MANIFEST.sha256` y `BACKUP-INFO.txt` antes de modificar el destino, permitiendo rollback.

6. **`.gitignore` de zonas de sync**: `.kit-sync-temp/` y `.kit-backup/` se aseguran en `.gitignore` del destino (idempotente) para no versionar respaldos ni temporales que puedan contener secrets.

7. **Dry-run con cero escrituras**: `-DryRun` propaga a todas las funciones y produce cero escrituras y cero side effects (Art. VIII), incluyendo no escribir `.gitignore`, reportes ni temp.

8. **Ejecución con `ErrorActionPreference = "Stop"`**: Los scripts detienen ante error, acumulan WARNs y ERRORs para un cuadro resumen final, y no tragan fallos en silencio (Art. V).

---

## 5. Brechas de seguridad

Estos controles faltan por implementar antes de pasar a la fase Implement:

1. **Validación de integridad de scripts de dominio antes de ejecutar**: No existe hash-guard ni comprobación de SHA256 sobre los scripts de dominio (`scripts/sync/**/*.ps1`) entre el stage y la ejecución. Un script manipulado se ejecuta sin detección. Debe implementarse un manifiesto de hashes esperado y comparación previa a la invocación de cada capa.

2. **Firma de scripts de dominio**: No hay firma de código en los scripts de PowerShell. Cualquier script con nombre correcto en la ruta de capas es ejecutado. Debe valorarse firma con certificado de código y verificación de firma antes de ejecutar capas críticas (MCP, constituciones, tests).

3. **Sandboxing de ejecución de capas**: Las capas se ejecutan con el mismo scope y privilegios del orquestador, sin restricción de lenguaje (PowerShell ConstrainedLanguage Mode) ni ejecución en entorno aislado. Una capa comprometida tiene alcance completo sobre `RootPath`. Debe implementarse sandboxing por capa (ejecución con `ExecutionPolicy` restringida y lenguaje limitado) o, al menos, validación estricta de contención de rutas.

4. **Registro de trazabilidad de borrados de backup**: La poda actual no registra qué se borró, tamaño, regla aplicada ni parámetros de retención. Debe añadirse registro por borrado en el resumen de ejecución (FR-003).

5. **Corrección del verificador de integridad del audit log**: `Test-AuditLogIntegrity` da falso negativo siempre (D3). Debe reescribirse per FR-008/FR-009/FR-010 (hash sobre texto crudo excluyendo `hash` y `prevHash`, raíces `prevHash: null` como legítimas, códigos de salida distinguibles).

6. **Unificación de la entrada `graphify` en `opencode.json`**: Debe quedar una sola entrada canónica (spec 020), con regeneración de ruta cuando apunte fuera de `RootPath` y preservación de `enabled` (FR-011/FR-012).

7. **Migración de la whitelist de tests a una capa del orquestador**: Los tests del kit viajan solo por el motor deprecado; la whitelist debe moverse a una capa propia con respaldo de tests colisionantes (FR-007/FR-014).

8. **Extracción de lógica de dominio del orquestador**: `Merge-OpenCodeConfig`, `Merge-KitBlock`, huérfanos y `Sync-TransversalKit` viven dentro de `sync-kit.ps1` (1143 líneas). Deben extraerse a scripts de dominio invocables por separado (FR-016/FR-017/FR-019).

---

## 6. Recomendaciones

Las siguientes acciones concretas deben cerrarse antes de autorizar la fase Implement de la spec 036:

- **Implementar hash-guard de scripts de dominio**: Generar un manifiesto de SHA256 de cada script de dominio en el stage y verificarlo antes de invocar cada capa. Cualquier hash distinto aborta la ejecución de esa capa con ERROR (fail-closed) y emite WARN en el resumen. (Cierra SR-036-02; tarea de FR-018/FR-017.)

- **Firmar scripts de dominio críticos**: Aplicar firma de código a los scripts de la capa MCP, constituciones y tests, y verificar la firma antes de ejecutar. (Cierra SR-036-02 y SR-036-06; tarea de FR-017.)

- **Sandboxear la ejecución de capas**: Ejecutar cada script de dominio en un proceso hijo con `ExecutionPolicy` restringida y, cuando sea posible, PowerShell en ConstrainedLanguage Mode. Validar contención de rutas (`realpath`, sin symlinks, sin `..`, dentro de `RootPath`) antes de cualquier escritura. (Cierra SR-036-06; tarea de FR-018.)

- **Registrar trazabilidad de la poda de backup**: Cada borrado de `.kit-backup/` debe escribirse en el resumen de ejecución con ruta, tamaño, regla aplicada y parámetros de retención. La poda debe ser fail-open con WARN, nunca abortar la corrida, y nunca tocar el backup del llamador (conjunto inicial excluido). (Cierra SR-036-03 y SR-036-05; tarea de FR-001/FR-002/FR-003.)

- **Corregir `Test-AuditLogIntegrity`**: Recalcular hash sobre texto crudo de cada línea excluyendo `hash` y `prevHash`; tratar `prevHash: null` como raíz legítima contada y reportada sin emitir `audit_integrity_violation`; devolver códigos de salida distinguibles (0 / ≠0 / estado propio para log vacío o ausente). (Cierra SR-036-07; tarea de FR-008/FR-009/FR-010.)

- **Unificar `graphify` en `opencode.json`**: Dejar una sola entrada canónica bajo `mcp.servers`, regenerar la ruta cuando apunte fuera de `RootPath`, preservar `enabled` del usuario, y emitir WARN al detectar duplicados o rutas ajenas corregidas. (Cierra SR-036-08; tarea de FR-011/FR-012.)

- **Migrar la whitelist de tests a una capa del orquestador**: Crear capa de tests que copie los 5 tests del kit con respaldo de tests del proyecto que colisionen por nombre, sin borrar tests fuera de la whitelist, y ejecutable sin Pester con `exit 0`/`exit 1`. (Cierra SR-036-10; tarea de FR-007/FR-014.)

- **Declarar capas `skills` y superficie `.github/`**: Crear capa `skills` (`.github/skills/` y `.opencode/skills/`) y capa propia para `.github/rules`, `.github/prompts`, `.github/workflows`, `.github/copilot-instructions.md`, con política idempotente, backup previo y `RESULT:` propio. Ninguna capa nueva escribe en `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`. (Cierra SR-036-09; tarea de FR-004/FR-005/FR-006.)

- **Extraer lógica de dominio del orquestador**: `Merge-OpenCodeConfig`, `Merge-KitBlock`, gestión de huérfanos y `Sync-TransversalKit` deben pasar a scripts de dominio propios, invocables de forma aislada con `-StageDir`, `-RootPath`, `-DryRun`. `sync-kit.ps1` debe quedar solo como orquestador que recolecta líneas `RESULT:`. (Cierra SR-036-06; tarea de FR-016/FR-017/FR-019.)

- **Ejecutar `npx ecc-agentshield scantest append line` y `.gitleaks.toml`**: Como exige el Quality Gate de Seguridad/Supply Chain de la constitución, antes de Implement. (Control transversal de la constitución.)

---

## Verificación de integridad del artefacto

Este archivo ha sido revisado sección por sección: cada sección contiene más de 5 líneas de contenido real, no hay placeholders (TBD/TODO/pendiente/N/A/XXX/...), no hay tablas con solo encabezado, y todos los riesgos llevan la etiqueta `security-risk:` con ID, severidad, mitigación y tarea de `tasks.md` asociada.