# Bitácora: 2026-11-02 — Sync del kit transversal a Generator_IA_Projects + parche del motor por capas

**Invocado por**: usuario (opción `[1] Sincronizar kit transversal — Quiero actualizar todo`)
**Agente**: `solucionador`
**Servidor / máquina**: TECH03 (local, no remoto)
**Origen**: `$KitPath` (repo maestro, commit `d0b89b9`)
**Destino**: `<PROJECT_ROOT>` (raíz **sin git**: sin rollback por VCS)

---

## 1. Problema

El proyecto `Generator_IA_Projects` tenía el kit transversal desactualizado: último sync
registrado el **2026-10-27** en `.kit-last-sync.json` con `"commit": "5513d37"`, mientras el
maestro había avanzado hasta `d0b89b9` (spec 034 cerrada, agentes por defecto, skills nuevas).

Síntomas concretos medidos con un diff SHA-256 maestro→destino:

| Superficie | Archivos distintos | Solo en maestro | Huérfanos |
|---|---:|---:|---:|
| `.github/` | 105 | 4 | 1 (runtime) |
| `.opencode/` | 89 | 2 | 1 real + 651 `node_modules` (falsos) |
| `.doc_agents/` | 0 | 0 | 0 |
| `scripts/` | 17 | 2 | 0 |
| Raíz (`AGENTS.md`, `opencode.json`, `README.md`, `constitution.md`) | 4 | 0 | — |
| `tests/` (whitelist del kit) | — | 5 | — |

Además `opencode.json` del destino tenía `"default_agent": "build"` — el *fallback silencioso*
que la spec 034 clasifica como fallo de configuración.

---

## 2. Diagnóstico

### 2.1 Hay dos motores de sync y no son equivalentes

| Motor | Estado | Qué hace |
|---|---|---|
| `scripts/sync-kit.ps1` | marcado `[021-DEPRECATED]` | Copia con `robocopy /E` + `Merge-OpenCodeConfig` + `Merge-KitBlock` |
| `scripts/sync-kit-agents.ps1` | flujo vigente (spec 021) | 12 capas en proceso hijo, cada una con su propia política |

El destino usaba el motor por capas (`.kit-last-sync.json` → `"tool": "sync-kit-agents"`), así que
la comparación de comportamiento se hizo contra ese.

### 2.2 Defecto A — la capa `kit-files` sobrescribía `AGENTS.md`

`scripts/sync/kit-files/sync-kit-files.ps1` trataba `AGENTS.md` con `Invoke-KitSingleFile`
(`Copy-Item -Force`), igual que `README.md`. Pero `AGENTS.md` es un archivo **compartido**:
contiene reglas del kit *y* contenido propio de cada proyecto. En cada sync del motor por capas
se destruía la parte del proyecto.

Contraste verificado: `opencode.json` **no** está en esa capa. Lo gestiona
`scripts/sync/mcp/lift-opencode.ps1` con fusión aditiva del bloque `mcp`. Es decir, la
afirmación inicial de que la capa sobrescribía *ambos* archivos era **incorrecta** para
`opencode.json`; el único destruido era `AGENTS.md`.

### 2.3 Defecto B — ninguna capa aplicaba `default_agent`

`lift-opencode.ps1` solo fusiona la clave `mcp`. Ninguna capa escribía `default_agent`,
`$schema` ni `instructions`. Por eso el destino seguía en `"build"` **aun habiendo terminado el
sync anterior con `RESULT:opencode:ok`**: verde no significaba correcto.

### 2.4 Defecto C — no existe capa `skills`

`scripts/sync-kit-agents.ps1` declara 12 capas (`kit-files`, `agents-github`, `agents-opencode`,
`agents-vscode`, `docs`, `constitutions`, `src-structure`, `mcp-install`, `mcp-lift-opencode`,
`mcp-lift-vscode`, `indexing`, `externals`). `scripts/sync/skills/sync-skills.ps1` **existe en
disco pero no figura en la lista** (solo aparece en un comentario de la línea 277). Consecuencia:
`.github/skills/` y `.opencode/skills/` nunca se sincronizan desde el orquestador.

### 2.5 Defecto D — la poda de backups destruye el backup del llamador

`sync-kit-agents.ps1` líneas 359-384: al terminar sin errores, ordena `.kit-backup/` por nombre
descendente y hace `Select-Object -Skip 2`, borrando todo lo anterior a las 2 carpetas más
recientes. Los backups creados **durante** la corrida tienen timestamp posterior, así que el
backup tomado por el operador antes de empezar es siempre candidato a poda. No hay opción para
desactivarla.

### 2.6 Defecto E — `Test-AuditLogIntegrity` da falso negativo siempre

`upgrade_framework.ps1` §`Test-AuditLogIntegrity` recalcula el hash copiando la entrada y
eliminando **solo** `hash`, dejando `prevHash` dentro del payload. Pero el escritor
(`Write-AuditEntry`) calcula el hash sobre un payload que **aún no tenía** `hash` ni `prevHash`.
Resultado: el verificador nunca puede coincidir, ni con sus propias entradas.

Estado real del log: 204 entradas, de las cuales **136 tienen `prevHash: null`** (raíces
históricas de distintos escritores). No es una cadena lineal verificable, y nunca lo fue.

---

## 3. Solución aplicada

### 3.1 Parche del motor (4 archivos, autorizado `[S]` estándar)

| Archivo | Cambio |
|---|---|
| `scripts/sync/lib/common.ps1` | Nueva función compartida `Merge-KitBlockFile`: complementa `AGENTS.md` por bloque delimitado `KIT-BLOCK`. Soporta múltiples bloques en el maestro, preserva BOM y CRLF, idempotente, fail-closed ante marcadores corruptos. Devuelve estado (`sin-cambios`/`ok`/`creado`/`omitido-item`). |
| `scripts/sync/kit-files/sync-kit-files.ps1` | `AGENTS.md` pasa de `Copy-Item -Force` a `Merge-KitBlockFile`. `README.md` y `constitution.md` siguen siendo 100 % del kit (clean+replace). `scripts/` conserva clean+replace (decisión del usuario). |
| `scripts/sync/mcp/lift-opencode.ps1` | Añade las claves gestionadas `$schema`, `instructions`, `default_agent` con las reglas de `Merge-OpenCodeConfig` (spec 034 §19.3): ausente→escribir, `build`→corregir, agente del kit `mode: primary`→respetar, desconocido→corregir, `-Force`→forzar. Contador `$managedChanges`, agregado a `RESULT:mcp-opencode:reparadas`. |
| `tests/kit-sync-merge.ps1` | Escenarios 8-10: la capa `kit-files` **corre de verdad** sobre fixtures temporales y se verifica que el contenido del proyecto sobrevive, que `README.md` sí se reemplaza, que `scripts/` mantiene clean+replace, la idempotencia y que `lift-opencode` aplica `default_agent` conservando `model` y `mcp.graphify`. |

Resultado de la suite: **45 asserts `[PASS]`, 0 `[FAIL]`, 10 escenarios, exit 0**, parseo limpio
de los 4 archivos.

### 3.2 Sincronización del destino

Paso 1 — motor por capas, limitado a la superficie transversal (6 de 12 capas):

```
pwsh -File scripts/sync-kit-agents.ps1 -RootPath <destino> -KitPath <maestro> `
  -Only "kit-files,agents-github,agents-opencode,agents-vscode,mcp-lift-opencode,mcp-lift-vscode"
```

Dry-run primero (exit 0, `ERRORs: 0`), luego real (exit 0, `ERRORs: 0`).
Se omitieron `docs`, `constitutions`, `src-structure`, `mcp-install`, `indexing` y `externals`
porque escriben en `Documentacion/<App>/`, `src/` o instalan dependencias — fuera del alcance
"kit transversal" y del guardarraíl del rol.

Paso 2 — completar la superficie que el motor por capas no cubre (skills, rules,
`copilot-instructions.md`, tests del kit) con el motor `sync-kit.ps1 -KitPath`, **sin `-Force`**:

- `.github/skills` 89, `.opencode/skills` 89, `.github/rules` 16, `.github/prompts` 6,
  `.github/agents` 14, `.opencode/agents` 13, `.opencode/commands` 6, `.github/workflows` 5.
- `tests/` → 5 archivos de la whitelist.
- Síntesis: `[OK] Kit transversal sincronizado. Documentacion/<AppName>/ NO fue tocada.`
- Huérfanos: `[OK] Sin huérfanos`.

---

## 4. Verificación

### 4.1 Divergencia final maestro → destino

| Área | Maestro | Destino | Distintos |
|---|---:|---:|---:|
| `.github/skills` | 89 | 89 | **0** |
| `.opencode/skills` | 89 | 89 | **0** |
| `.github/rules` | 16 | 16 | **0** |
| `.github/prompts` | 6 | 6 | **0** |
| `.github/agents` | 14 | 14 | **0** |
| `.opencode/agents` | 13 | 13 | **0** |
| `.opencode/commands` | 6 | 6 | **0** |
| `.github/workflows` | 5 | 5 | **0** |
| `tests` | 8 | 5 | **0** (3 fuera de whitelist, por diseño) |
| `.github/copilot-instructions.md` | — | — | **IGUAL** |

### 4.2 `opencode.json` del destino

- `default_agent`: **`pensador`** (antes `build`).
- `model`, `small_model`, `lsp`, `permission` intactos.
- `instructions` es **array**: `["AGENTS.md"]`.
- `mcp.servers`: 8 entradas; `mcp.graphify` local **preservado**, con su `enabled: true`.
- JSON parsea sin errores.
- Backup del merge: `opencode.json.bak-20261102T165428`.

### 4.3 `AGENTS.md` del destino

11 234 bytes, **1** `KIT-BLOCK:START` y **1** `KIT-BLOCK:END`, conserva `# AGENTS.md`,
`REGLAS CRÍTICAS`, `Core facts`, `## Commands`. El bloque `arranque-por-defecto` se **añadió al
final** (Caso C: el archivo no tenía esa sección ni marcadores), no se sobrescribió nada.
Backup: `AGENTS.md.bak-20261102T165038` (9 002 bytes, estado previo).

### 4.4 Guardarraíles

| Elemento | Resultado |
|---|---|
| `.opencode/config.json` | PRESENTE, 368 bytes, mtime 2026-10-04 — **no tocado** (solo tiene placeholders, sin keys reales) |
| `Documentacion/` | mtime 2026-10-26 — **no tocado** |
| `src/` | mtime 2026-11-02 12:14 (anterior a la intervención) — **no tocado** |
| `.doc_agents/` | 5 archivos, contenido idéntico (solo cambió el mtime del directorio por `robocopy /E`) |

### 4.5 Estado de backups

| Ruta | Archivos | Estado |
|---|---:|---|
| `.kit-backup/20261102-164540` | 4 603 | **PODADO Y PERDIDO** por el defecto D (era el backup pre-sync verificado) |
| `.kit-backup/20261102-165039` | 16 | superviviente (`.opencode/agents`, `.vscode`) |
| `.kit-backup/20261102-165040` | 2 | superviviente (`opencode.json`, `mcp-vscode.json`) |
| `.kit-backup-manual/20261102-165301` | 308 | **INVÁLIDO**: `.vscode/settings.json` copiado de 0 bytes (carrera con VS Code). No usar para rollback |
| `.kit-backup-manual/20261102-165415` | 306 | **VÁLIDO**: 305 verificados por SHA-256, 0 discrepancias |

Rollback disponible:

1. Estado inmediatamente posterior al sync → `.kit-backup-manual/20261102-165415`.
2. Estado previo del *código de sync* → `git show 5513d37:<ruta>` en el repo maestro
   (verificado con `git cat-file -e 5513d37^{commit}` → exit 0).
3. `AGENTS.md` previo → `AGENTS.md.bak-20261102T165038`.
4. `opencode.json` previo → `opencode.json.bak-20261102T165428`.

### 4.6 Acción pendiente del usuario

`.kit-restart-required` contiene `RESTART:VSCODE 2026-11-02T16:50:40` — hay que reiniciar
VS Code Copilot y OpenCode para que carguen los agentes nuevos.

---

## 5. Reflejo local

- [x] Completado — el parche se aplicó directamente en el repo maestro
      (`$KitPath`), que es la fuente del kit; no hubo copia divergente que reconciliar.
- Archivos locales modificados:
  - `scripts/sync/lib/common.ps1`
  - `scripts/sync/kit-files/sync-kit-files.ps1`
  - `scripts/sync/mcp/lift-opencode.ps1`
  - `tests/kit-sync-merge.ps1`
- Sin commit (pendiente de autorización).

### 5.1 Registro de auditoría

La intervención quedó registrada en `.bootstrap-audit.log` con **dos** entradas:

| # | `action` | Timestamp | Contenido |
|---|---|---|---|
| 204 | `sync_kit_transversal_authorized` | `2026-11-02T16:25:03` | autorización `[S]` estándar del usuario: operación, riesgo `indisponibilidad`, alcance, reversibilidad |
| 205 | `sync_kit_transversal_executed` | `2026-11-02T16:58:29` | resultado `exito`, motores usados, capas, parche aplicado, tests, backups, divergencia 0, deuda D1-D5, bitácora, commit y reinicio pendientes |

Cadena: la entrada 205 lleva `prevHash = 36843389…b850e8` (hash de la 204) y su propio
`hash = 33ce99af…2f220a14`, verificado recalculándolo desde el payload recuperado del texto en
disco (coincidencia byte a byte).

Nota de implementación: la verificación se hizo **por concatenación de texto**, no por
round-trip `ConvertTo-Json`/`ConvertFrom-Json`, porque `ConvertFrom-Json` convierte el
`timestamp` ISO-8601 a `[DateTime]` y al re-serializar cambia el formato — el mismo tipo de
trampa que hace que `Test-AuditLogIntegrity` (defecto D3) no pueda validar sus propias
entradas.

`git status --porcelain` del maestro en este punto:

```
 M .bootstrap-audit.log
 M scripts/sync/kit-files/sync-kit-files.ps1
 M scripts/sync/lib/common.ps1
 M scripts/sync/mcp/lift-opencode.ps1
 M tests/kit-sync-merge.ps1
?? Documentacion/Agents_IA_TECH/bitacoras/2026-11-02-sync-kit-generator-y-parche-kit-files.md
```

---

## 6. Deuda técnica detectada (no corregida en esta intervención)

| ID | Defecto | Impacto | Corrección propuesta |
|---|---|---|---|
| D1 | Poda de `.kit-backup` (`sync-kit-agents.ps1` L359-384) borra el backup del llamador | Pérdida del punto de rollback pre-sync | Excluir de la poda las carpetas anteriores al inicio de la corrida, o añadir `-KeepBackups <n>` con default que respete la más antigua de la sesión |
| D2 | No existe capa `skills` en el orquestador | `.github/skills` y `.opencode/skills` nunca se sincronizan (78 archivos quedaron obsoletos hasta el workaround) | Añadir `@{ Name="skills"; Script="sync/skills/sync-skills.ps1"; AcceptsForce=$true }` y cubrir `.github/rules`, `.github/prompts`, `copilot-instructions.md` en una capa `github-extras` |
| D3 | `Test-AuditLogIntegrity` de `upgrade_framework.ps1` | Falso negativo permanente + entradas `audit_integrity_violation` espurias | Eliminar también `prevHash` del payload al recalcular, y validar por entrada en vez de exigir cadena lineal |
| D4 | `tests/` del kit solo viaja por el motor deprecado (`sync-kit.ps1`) | El motor vigente no propaga los 5 tests de contrato | Mover la whitelist de tests a su propia capa |
| D5 | `opencode.json` tiene **dos** entradas graphify: `mcp.servers.graphify` (apunta al grafo del **maestro**: `$KitPath/graphify-out/graph.json`) y `mcp.graphify` (apunta al destino correcto) | Configuración duplicada y contradictoria; la primera sirve el grafo equivocado | Unificar en una sola entrada y hacer que la capa regenere la ruta siempre, no solo cuando `command[0]` no existe |

---

## 7. Resumen

El kit transversal de `Generator_IA_Projects` quedó sincronizado contra el maestro `d0b89b9`:
**divergencia 0** en skills (89+89), rules (16), prompts (6), agents (14+13), commands (6),
workflows (5) y `copilot-instructions.md`; `default_agent` corregido de `build` a `pensador`;
`AGENTS.md` complementado sin perder contenido; `mcp.graphify` local preservado; y
`Documentacion/`, `src/` y `.opencode/config.json` intactos.

El motor por capas quedó corregido para que el próximo sync no repita los defectos A y B.
Los defectos C, D y E (más D5) siguen abiertos y requieren spec propia.

**Pendiente de autorización**: commit del parche, y corrección de D1-D5.
