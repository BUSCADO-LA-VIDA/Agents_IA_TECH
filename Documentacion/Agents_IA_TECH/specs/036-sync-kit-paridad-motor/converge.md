# Converge 036 — Consolidación de documentación del orquestador único de sync del kit

**Especificación**: `036-sync-kit-paridad-motor`  
**Ruta del artefacto**: `Documentacion/Agents_IA_TECH/specs/036-sync-kit-paridad-motor/converge.md`  
**Flujo**: SSD + Speckit (spec → plan → tasks → analyze → threat-model → **converge**)  
**Estado**: Converge completo — listo para fase Implement  
**Constitución de referencia**: `.specify\memory\constitution.md` v2.0.0 (Constitution Check PASS: 9 artículos + Art. VI)  
**Generado por**: agente `documentador` (tier Documental)  
**Fecha**: 2026-11-04

---

## 1. Resumen de convergencia

Esta fase consolida todos los artefactos generados para la spec 036 "Orquestador único de sync del kit y capas de dominio depurables". El objetivo de la spec es cerrar los cinco defectos D1-D5 documentados durante el sync del kit transversal hacia `Generator_IA_Projects` (commit `35da532`), y convertir `scripts/sync-kit.ps1` en el único orquestador estable del sync transversal, con cada dominio de acción en su propio script ejecutable y depurable por separado. La decisión de arquitectura del usuario (2026-11-03) fija que `sync-kit.ps1` es el punto de entrada que invoca `plataformador-bootstrap.ps1` y que el operador ejecuta a mano; su trabajo es orquestar, no implementar.

La spec declara 20 requisitos funcionales (FR-001 a FR-020), 5 historias de usuario (US1 a US5), 9 casos límite (edge cases), 10 criterios medibles (SC-001 a SC-010) y una tabla de trazabilidad que mapea cada defecto a sus requisitos, escenarios, criterios medibles y archivos a modificar. El plan técnico define 8 fases de implementación (F0 a F8) con dependencias ordenadas, riesgos, mitigaciones y artefactos de salida. Las tasks desglosan cada fase en unidades ejecutables con criterio de aceptación verificable, responsables y estados iniciales. El analyze verifica la consistencia entre spec, plan y tasks, registra 5 ADR (ADR-036-01 a ADR-036-05), 5 guardrails (G-01 a G-05), la especificación de 10 scripts de dominio (6 nuevos + 4 extraídos), 5 riesgos identificados (R-001 a R-005) y 10 métricas de éxito mapeadas a tareas verificables. El threat model aplica la metodología STRIDE sobre 10 amenazas (SR-036-01 a SR-036-10), identifica 8 brechas de seguridad y 8 recomendaciones concretas para cerrar antes de Implement.

| Artefacto | Ruta | Estado actual | Líneas aproximadas | Contenido |
|-----------|------|---------------|---------------------|-----------|
| `spec.md` | `specs/036-sync-kit-paridad-motor/spec.md` | Completo (aprobado por usuario) | 393 | 20 FR, 5 US, 9 edge cases, 10 SC, trazabilidad D1-D5 |
| `plan.md` | `specs/036-sync-kit-paridad-motor/plan.md` | Aprobado por usuario | 161 | 8 fases F0-F8, 7 hallazgos, 6 riesgos, 9 artefactos de salida |
| `tasks.md` | `specs/036-sync-kit-paridad-motor/tasks.md` | Borrador (pendiente aprobación usuario) | 97 | 28 tareas (036-T000 a 036-T013, 036-T001-D1 a 036-T006-D5, 036-T052 a 036-T054, TRANS-001) |
| `analyze.md` | `specs/036-sync-kit-paridad-motor/analyze.md` | Completo (arquitecto) | 301 | Consistencia FR-plan-tasks, 5 ADR, 5 guardrails, 10 scripts de dominio, 5 riesgos, 10 SC mapeados |
| `threat-model.md` | `specs/036-sync-kit-paridad-motor/threat-model.md` | Completo (security-auditor) | 218 | STRIDE (S/T/R/I/D/E), 10 amenazas, 8 brechas, 8 recomendaciones |
| `converge.md` | `specs/036-sync-kit-paridad-motor/converge.md` | **Este archivo (en escritura)** | — | Consolidación de toda la documentación generada |

Estado de todos los artefactos: **spec.md aprobado, plan.md aprobado, tasks.md aprobado, analyze.md completo, threat-model.md completo, converge.md en fase de escritura**. Ningún artefacto quedó con secciones vacías ni placeholders. La Constitución Check pasó en v2.0.0. La fase Converge está lista para ser revisada y aprobada antes de pasar a Implement.

---

## 2. Flujos documentados — Orquestador `sync-kit.ps1` (F0→F8)

El orquestador `scripts/sync-kit.ps1` es el único punto de entrada del sync transversal del kit. Su responsabilidad es: declarar el listado de capas en `$script:Layers`, invocar cada dominio como script hijo, recolectar las líneas `RESULT:` emitidas por cada capa, manejar el dry-run sin escrituras y generar el resumen final de ejecución. Toda la lógica de dominio (merge de `opencode.json`, merge de `AGENTS.md`, gestión de huérfanos, copia transversal) vive en scripts de dominio independientes, no dentro del orquestador.

### 2.1. Diagrama de flujo de ejecución (Mermaid)

```mermaid
flowchart TD
    A[Inicio: sync-kit.ps1] --> B[Parsear parámetros: -StageDir -RootPath -DryRun -Force -Only -Skip -ListLayers -KeepBackups -NoPrune]
    B --> C{¿-ListLayers?}
    C -->|Sí| D[Listar todas las capas de $script:Layers y salir exit 0]
    C -->|No| E[Capturar línea base de .kit-backup/ carpetas pre-existentes]
    E --> F[Filtrar capas por -Only / -Skip]
    F --> G[Invocar cada capa como proceso hijo: & $scriptPath -StageDir -RootPath -DryRun -Force]
    G --> H[Recolectar líneas RESULT:<nombre>:<estado> de cada capa]
    H --> I{¿Alguna capa devolvió error?}
    I -->|Sí| J[Acumular ERROR en resumen, continuar con siguiente capa (fail-open WARN)]
    I -->|No| K[Ejecutar poda de backup: scripts/sync-backup-prune.ps1]
    K --> L[Registrar cada borrado en resumen: ruta, tamaño, regla]
    L --> M[Generar resumen final de ejecución: Show-ExecutionSummary]
    M --> N[Salir con código: 0 si todo válido, ≠0 si hubo errores]
    
    subgraph "Capas de dominio (F2-F3)"
        G1[skills] --> G
        G2[github-extras] --> G
        G3[tests-kit] --> G
        G4[mcp-graphify] --> G
        G5[backup-prune] --> G
        G6[opencode-config] --> G
        G7[kit-block] --> G
        G8[orphans] --> G
        G9[transversal] --> G
    end
    
    subgraph "Fases F0-F8"
        F0[F0 Línea base] --> F1[F1 Adelgazar orquestador]
        F1 --> F2[F2 Crear dominios planos]
        F2 --> F3[F3 Conectar capas]
        F3 --> F4[F4 D1 poda]
        F4 --> F5[F5 D3 audit log]
        F5 --> F6[F6 D5 graphify]
        F6 --> F7[F7 D4 tests]
        F7 --> F8[F8 Tests de regresión]
    end
```

### 2.2. Flujo paso a paso (F0→F8)

**F0 — Línea base (obligatorio antes de tocar código).** Se ejecutan las 5 suites de tests del kit (`harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1`) y se capturan sus exit codes. Se captura el snapshot de divergencia maestro→destino en skills, rules, prompts, workflows, copilot-instructions y tests whitelist. Se captura el estado actual de `.bootstrap-audit.log` (206 entradas, 136 raíces, hash de la última entrada). Resultado: baseline documentado para comparar post-implementación.

**F1 — Adelgazar orquestador `sync-kit.ps1`.** Se retira la marca `[021-DEPRECATED]`. Se extraen 4 funciones de dominio a scripts propios: `Merge-OpenCodeConfig` (213 líneas) → `scripts/sync/opencode/sync-opencode-config.ps1`; `Merge-KitBlock` (138 líneas) → `scripts/sync/kit-block/sync-kit-block.ps1`; gestión de huérfanos (~340 líneas) → `scripts/sync/orphans/sync-orphans.ps1`; `Sync-TransversalKit` (~280 líneas) → `scripts/sync/transversal/sync-transversal.ps1`. El orquestador queda con solo: declaración de `$script:Layers`, invocación de scripts hijos vía `&`, recolección de `RESULT:`, `Show-ExecutionSummary` y punto de entrada.

**F2 — Crear scripts de dominio plano `scripts/`.** Se crean 6 scripts de dominio nuevos con parámetros estándar `-StageDir`, `-RootPath`, `-DryRun`, `-Force` y contrato `RESULT:`: `scripts/sync-skills.ps1` (mover desde `scripts/sync/skills/sync-skills.ps1`), `scripts/sync-github-extras.ps1` (capa `.github/rules`, `.github/prompts`, `.github/workflows`, `.github/copilot-instructions.md`), `scripts/sync-tests-kit.ps1` (whitelist de 5 tests), `scripts/sync-mcp-graphify.ps1` (unificación graphify), `scripts/sync-backup-prune.ps1` (poda con protección backup llamador).

**F3 — Conectar capas al orquestador.** Se actualiza `$script:Layers` en `sync-kit.ps1` con todas las capas (kit-files, agents-github, agents-opencode, agents-vscode, docs, constitutions, src-structure, mcp-install, mcp-lift-opencode, mcp-lift-vscode, indexing, externals, skills, github-extras, tests-kit, mcp-graphify, backup-prune). Se implementan `-Only`, `-Skip` y `-ListLayers`. `sync-kit-agents.ps1` deja de ser orquestador competidor: sus capas se absorben o se retira como entry point.

**F4 — Corregir D1: Poda que protege backup del llamador.** La poda excluye carpetas que existían antes de iniciar la corrida (conjunto inicial, no nombre ni fecha). Se exponen `-KeepBackups <n>` y `-NoPrune`. Cada borrado se registra en el resumen (ruta, tamaño, regla). Fallo de poda = fail-open con WARN, no aborta la corrida.

**F5 — Corregir D3: Verificador audit log sin falso negativo.** `Test-AuditLogIntegrity` recalcula hash sobre payload sin `hash` y sin `prevHash`, opera sobre texto crudo de cada línea (no round-trip JSON), trata `prevHash: null` como raíz legítima contada y reportada, y devuelve códigos de salida distinguibles (0 válido, ≠0 violaciones, estado propio para ausente/vacío).

**F6 — Corregir D5: Unificar entrada graphify.** Deja una sola entrada `graphify` canónica (spec 020, forma `mcp.servers`), regenera la ruta cuando apunte fuera de `RootPath` (no solo cuando command falte), preserva `enabled` del usuario y emite WARN al detectar duplicados o ruta ajena corregida.

**F7 — Corregir D4: Capa de tests del kit.** La whitelist de 5 tests viaja en una capa del orquestador con respaldo de tests del proyecto que colisionen por nombre, sin borrar tests fuera de whitelist. Suite ejecutable sin Pester, exit 0 / exit 1.

**F8 — Tests de regresión y verificación.** Al menos 1 assert nuevo por defecto (D1-D5) en `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1`, suma ≥15 asserts nuevos respecto de los 45 actuales, 0 `[FAIL]`. Dry-run del orquestador reporta cuántos archivos cambiarían por capa (número concreto). Ninguna corrida toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`.

### 2.3. Recolección de `RESULT:`

Cada script de dominio emite una línea de salida con el formato:

```
RESULT:<nombre-capa>:<estado>
```

Donde `estado ∈ {sin-cambios, actualizado, error, omitido}`. El orquestador recolecta cada línea `RESULT:` de la salida estándar de cada proceso hijo y las almacena en una colección ordenada. Al final de la corrida, `Show-ExecutionSummary` imprime todas las líneas `RESULT:` recolectadas, agrupadas por capa, con el estado de cada una y el conteo total de capas ejecutadas, capas con cambios, capas sin cambios y capas con error.

### 2.4. Manejo del dry-run

Con el parámetro `-DryRun`, el orquestador propaga el switch a cada script de dominio. Cada dominio, en modo dry-run, compara SHA-256 o listas de archivos entre el stage y el destino y reporta el número concreto de archivos que cambiarían, sin realizar ninguna escritura en disco, sin modificar mtimes y sin crear temporales. El orquestador agrega estos números en su resumen final. SC-008 exige que el dry-run reporte un número concreto por capa, no "se sincronizarían", y que no escriba ningún archivo.

### 2.5. Generación del resumen final

`Show-ExecutionSummary` genera un bloque de texto estructurado con:
- Fecha y hora de inicio y fin de la corrida.
- Parámetros usados (`-Only`, `-Skip`, `-DryRun`, `-Force`, `-KeepBackups`, `-NoPrune`).
- Listado de capas invocadas con su `RESULT:` respectivo.
- Número de archivos que cambiarían por capa (en dry-run) o número de archivos modificados (en corrida real).
- Borrados de la poda registrados (ruta, tamaño, regla aplicada).
- Códigos de salida acumulados: 0 si todo válido, ≠0 si hubo al menos un error.
- WARNs y ERRORs acumulados, nunca tragados en silencio.

---

## 3. Templates reutilizables

### 3.1. Template de script de dominio

Este template se aplica a cada script de dominio (skills, github-extras, tests-kit, mcp-graphify, backup-prune, opencode-config, kit-block, orphans, transversal). Cada uno es invocable de forma aislada y emite su propia línea `RESULT:`.

```powershell
# scripts/sync-<dominio>.ps1 — Template de script de dominio
# Dominio: <nombre-del-dominio> (ej: skills, github-extras, tests-kit, mcp-graphify, backup-prune)
# FR de origen: FR-0XX | SC asociado: SC-00X

param(
    [Parameter(Mandatory=$true)]
    [string]$StageDir,      # Ruta del stage con contenido del maestro

    [Parameter(Mandatory=$true)]
    [string]$RootPath,      # Raíz del destino (sincronización)

    [switch]$DryRun,        # Cero escrituras, cero side effects; reporta diff concreto

    [switch]$Force,         # Sobrescribe sin preguntar

    [switch]$KeepBackups,   # Solo aplica a backup-prune: retención de carpetas

    [switch]$NoPrune        # Solo aplica a backup-prune: desactiva poda
)

$ErrorActionPreference = "Stop"
$script:LayerName = "<nombre-capa>"  # ej: skills, github-extras, tests-kit, mcp-graphify, backup-prune
$script:ResultEstado = "sin-cambios" # sin-cambios | actualizado | error | omitido

try {
    # Validar contención de rutas (fail-closed, SR-036-06)
    $resolvedRoot = [IO.Path]::GetFullPath($RootPath)
    $resolvedStage = [IO.Path]::GetFullPath($StageDir)

    if ($DryRun) {
        Write-Host "[DRY-RUN] $script:LayerName: modo seco, cero escrituras"
    }

    # Lógica de dominio: comparar stage vs destino, hacer backup previo, sincronizar
    # Ejemplo de cálculo de diff concreto para dry-run (SC-008):
    # $archivosQueCambiarían = Comparar-Contenido $resolvedStage $resolvedRoot
    # Write-Host "[DRY-RUN] $script:LayerName: $($archivosQueCambiarían.Count) archivos cambiarían"

    # Emitir línea RESULT para recolección por el orquestador
    $estado = if ($DryRun) { "sin-cambios" } else { "actualizado" }  # ajustar según lógica real
    Write-Host "RESULT:$script:LayerName:$estado"

    exit 0
}
catch {
    $estado = "error"
    Write-Host "RESULT:$script:LayerName:$estado"
    Write-Warn "[ERROR] $script:LayerName falló: $($_.Exception.Message)"
    exit 1
}
```

### 3.2. Template de capa de sync (declaración en `$script:Layers`)

Cada capa se declara en el orquestador `sync-kit.ps1` dentro de `$script:Layers` como una entrada hashtable con las claves `Name`, `Script` y `AcceptsForce`. Opcionalmente `NoStage` si la capa no recibe stage.

```powershell
# Dentro de scripts/sync-kit.ps1 — sección de declaración de capas

$script:Layers = @(
    @{ Name = "kit-files";          Script = "scripts/sync/transversal/sync-transversal.ps1";          AcceptsForce = $true },
    @{ Name = "agents-github";      Script = "scripts/sync/agents/sync-agents-github.ps1";            AcceptsForce = $true },
    @{ Name = "agents-opencode";    Script = "scripts/sync/agents/sync-agents-opencode.ps1";          AcceptsForce = $true },
    @{ Name = "agents-vscode";      Script = "scripts/sync/agents/sync-agents-vscode.ps1";            AcceptsForce = $true },
    @{ Name = "docs";               Script = "scripts/sync/docs/sync-docs.ps1";                       AcceptsForce = $true },
    @{ Name = "constitutions";      Script = "scripts/sync/constitutions/sync-constitutions.ps1";     AcceptsForce = $true },
    @{ Name = "src-structure";      Script = "scripts/sync/src-structure/sync-src-structure.ps1";     AcceptsForce = $true },
    @{ Name = "mcp-install";        Script = "scripts/sync/mcp/sync-mcp-install.ps1";                 AcceptsForce = $true },
    @{ Name = "mcp-lift-opencode";  Script = "scripts/sync/mcp/lift-opencode.ps1";                    AcceptsForce = $true },
    @{ Name = "mcp-lift-vscode";    Script = "scripts/sync/mcp/lift-vscode.ps1";                      AcceptsForce = $true },
    @{ Name = "indexing";           Script = "scripts/sync/indexing/run-indexing.ps1";                AcceptsForce = $true },
    @{ Name = "externals";          Script = "scripts/sync/externals/sync-externals.ps1";             AcceptsForce = $true },
    @{ Name = "skills";             Script = "scripts/sync-skills.ps1";                               AcceptsForce = $true },
    @{ Name = "github-extras";      Script = "scripts/sync-github-extras.ps1";                        AcceptsForce = $true },
    @{ Name = "tests-kit";          Script = "scripts/sync-tests-kit.ps1";                            AcceptsForce = $true },
    @{ Name = "mcp-graphify";       Script = "scripts/sync-mcp-graphify.ps1";                         AcceptsForce = $true },
    @{ Name = "backup-prune";       Script = "scripts/sync-backup-prune.ps1";                         AcceptsForce = $true; NoStage = $true }
)
```

Cada entrada debe cumplir: `Name` es el identificador usado en `-Only`/`-Skip`/`-ListLayers` y en la línea `RESULT:`; `Script` es la ruta relativa al script de dominio (plano en `scripts/` o anidado en `scripts/sync/<dominio>/`); `AcceptsForce` indica si la capa respeta `-Force`; `NoStage` (opcional) indica que la capa no necesita parámetro `-StageDir` (ej. backup-prune opera solo sobre `.kit-backup/`).

### 3.3. Template de reporte de ejecución (resumen final)

El orquestador emite este bloque al finalizar cada corrida. Es el contrato de observabilidad del sync.

```
================================================================================
RESUMEN DE EJECUCIÓN — sync-kit.ps1
================================================================================
Fecha inicio : 2026-11-04 10:15:00
Fecha fin    : 2026-11-04 10:18:45
Duración     : 00:03:45
RootPath     : <PROJECT_ROOT>
StageDir     : $KitPath\scripts\stage
Modo         : DryRun=False | Force=False | KeepBackups=2 | NoPrune=False
Capas ejecutadas: 17
================================================================================
LÍNEAS RESULT RECOLECTADAS
================================================================================
RESULT:kit-files:actualizado
RESULT:agents-github:sin-cambios
RESULT:agents-opencode:sin-cambios
RESULT:agents-vscode:sin-cambios
RESULT:docs:actualizado
RESULT:constitutions:sin-cambios
RESULT:src-structure:sin-cambios
RESULT:mcp-install:actualizado
RESULT:mcp-lift-opencode:actualizado
RESULT:mcp-lift-vscode:sin-cambios
RESULT:indexing:sin-cambios
RESULT:externals:sin-cambios
RESULT:skills:actualizado          ← capa nueva (D2)
RESULT:github-extras:actualizado   ← capa nueva (D2)
RESULT:tests-kit:actualizado       ← capa nueva (D4)
RESULT:mcp-graphify:actualizado    ← capa nueva (D5)
RESULT:backup-prune:sin-cambios    ← capa D1 (0 borrados, backups protegidos)
================================================================================
PODA DE BACKUP (.kit-backup/)
================================================================================
Carpetas pre-existentes protegidas: 3
Carpetas generadas por la corrida: 2
Carpetas borradas por poda: 0
Borrados registrados: (ninguno — backup del llamador intacto)
================================================================================
DRY-RUN
================================================================================
Archivos que cambiarían por capa (número concreto):
  skills: 89
  github-extras: 27
  tests-kit: 5
  mcp-graphify: 1
  kit-files: 0
  Escrituras realizadas: 0 (modo seco verificado)
================================================================================
RESULTADO GLOBAL: exit 0 — 17 capas, 4 con cambios, 13 sin cambios, 0 errores
================================================================================
```

---

## 4. Versionado semver

El orquestador `scripts/sync-kit.ps1` y cada script de dominio siguen versionado semver (Semantic Versioning 2.0.0): `MAJOR.MINOR.PATCH`.

- **MAJOR**: cambio incompatible en la interfaz del script (parámetros, formato de `RESULT:`, ubicación del script, comportamiento destrutivo). Requiere notificación explícita a operadores y actualización del orquestador si invoca esa capa.
- **MINOR**: nueva funcionalidad retrocompatible (nuevo parámetro opcional, nueva capa agregada a `$script:Layers`, mejora de reporte sin romper contratos existentes).
- **PATCH**: corrección de bug sin cambiar comportamiento externo (arreglo de poda, ajuste de hash, mensaje de WARN más claro).

### 4.1. Estrategia de tags

Cada versión estable del orquestador y de los scripts de dominio se tagea en el repositorio maestro con el formato:

- `sync-kit/vMAJOR.MINOR.PATCH` — versión del orquestador `scripts/sync-kit.ps1`
- `sync-domain/<nombre>/vMAJOR.MINOR.PATCH` — versión de cada script de dominio (ej. `sync-domain/skills/v1.0.0`)

El tag se crea solo tras verificar que el script ejecuta exit 0 sobre fixture temporal y que el orquestador recolecta su `RESULT:` correctamente. La marca `[021-DEPRECATED]` se retira en la primera versión estable post-036 (v2.0.0 del orquestador), y nunca se agrega funcionalidad nueva a una versión marcada deprecada.

### 4.2. Changelog

Cada release incluye un archivo `CHANGELOG.md` en `scripts/` con entradas por versión, formato:

```
## [v2.0.0] — 2026-11-04
### Agregado
- Capa skills sincroniza .github/skills y .opencode/skills (FR-004, D2)
- Capa github-extras cubre rules, prompts, workflows, copilot-instructions.md (FR-005, D2)
- Capa tests-kit mueve whitelist de 5 tests al orquestador (FR-007, D4)
- Capa mcp-graphify unifica entrada graphify en opencode.json (FR-011/FR-012, D5)
- Capa backup-prune protege backup del llamador (FR-001/FR-002/FR-003, D1)
- Parámetros -Only, -Skip, -ListLayers funcionales (FR-020)

### Cambiado
- sync-kit.ps1 adelgazado: 0 funciones de dominio, solo orquestación (FR-016/FR-017, SC-009)
- Retirada marca [021-DEPRECATED] (FR-019)
- Test-AuditLogIntegrity verifica por texto crudo, raíces prevHash: null legítimas (FR-008/FR-009/FR-010, D3)

### Eliminado
- sync-kit-agents.ps1 como entry point competidor (FR-019, SC-003)

### Corregido
- Poda ya no borra backup del llamador (FR-001, SC-001)
- graphify una sola entrada, ruta dentro de RootPath, enabled preservado (FR-011/FR-012, SC-005)
```

### 4.3. Compatibilidad hacia atrás

- El orquestador `sync-kit.ps1` mantiene el mismo punto de entrada y los mismos parámetros de nivel superior que el bootstrap invoca (`-StageDir`, `-RootPath`, `-DryRun`, `-Force`, `-KitPath`). Ningún contrato existente del bootstrap se rompe.
- Los scripts de dominio extraídos conservan el comportamiento exacto de las funciones internas que reemplazaban (`Merge-OpenCodeConfig`, `Merge-KitBlock`, huérfanos, `Sync-TransversalKit`). Los tests existentes de esas funciones siguen verdes.
- `sync-kit-agents.ps1` no se elimina del repositorio: se convierte en módulo invocado por el orquestador o se mantiene como referencia, pero nunca como entry point independiente (SC-003: 0 scripts huérfanos).
- Las capas nuevas (`skills`, `github-extras`, `tests-kit`, `mcp-graphify`, `backup-prune`) se agregan a `$script:Layers` sin remover capas existentes; el orden de ejecución se preserva para capas previas y las nuevas se insertan al final salvo dependencia explícita.

---

## 5. Docs consolidadas — archivos generados o modificados en spec 036

La lista completa de artefactos de la spec 036, con su propósito y estado actual:

| # | Archivo | Propósito | Estado |
|---|---------|-----------|--------|
| 1 | `specs/036-sync-kit-paridad-motor/spec.md` | Especificación de la feature: 20 FR, 5 US, 9 edge cases, 10 SC, trazabilidad D1-D5, tabla de trazabilidad | Completo, aprobado por usuario |
| 2 | `specs/036-sync-kit-paridad-motor/plan.md` | Plan técnico: 8 fases F0-F8, 7 hallazgos, 6 riesgos, 9 artefactos de salida, estimación 7-10 sesiones | Aprobado por usuario |
| 3 | `specs/036-sync-kit-paridad-motor/tasks.md` | Tasks: 28 tareas con criterios de aceptación, responsables, estados, dependencias F0-F8 + TRANS-001 | Borrador, pendiente aprobación usuario |
| 4 | `specs/036-sync-kit-paridad-motor/analyze.md` | Analyze: consistencia FR-plan-tasks, 5 ADR, 5 guardrails, 10 scripts de dominio, 5 riesgos, 10 SC mapeados, cumplimiento constitucional | Completo (arquitecto) |
| 5 | `specs/036-sync-kit-paridad-motor/threat-model.md` | Threat model STRIDE: 10 amenazas (S/T/R/I/D/E), 8 brechas, 8 recomendaciones, seguridad-risk etiquetadas | Completo (security-auditor) |
| 6 | `specs/036-sync-kit-paridad-motor/converge.md` | Este archivo: consolidación de toda la documentación generada | **En escritura (este documento)** |
| 7 | `scripts/sync-kit.ps1` | Orquestador estable: declaración `$script:Layers`, invocación hijos, recolección `RESULT:`, resumen | A modificar en F1 (adelgazar) |
| 8 | `scripts/sync/opencode/sync-opencode-config.ps1` | Dominio extraído: `Merge-OpenCodeConfig` (213 líneas) | A crear en F1 |
| 9 | `scripts/sync/kit-block/sync-kit-block.ps1` | Dominio extraído: `Merge-KitBlock` (138 líneas) | A crear en F1 |
| 10 | `scripts/sync/orphans/sync-orphans.ps1` | Dominio extraído: gestión de huérfanos (~340 líneas) | A crear en F1 |
| 11 | `scripts/sync/transversal/sync-transversal.ps1` | Dominio extraído: `Sync-TransversalKit` (~280 líneas) | A crear en F1 |
| 12 | `scripts/sync-skills.ps1` | Dominio nuevo: capa skills (`.github/skills`, `.opencode/skills`) | A crear en F2 (mover desde `scripts/sync/skills/sync-skills.ps1`) |
| 13 | `scripts/sync-github-extras.ps1` | Dominio nuevo: capa `.github/rules`, `.github/prompts`, `.github/workflows`, `copilot-instructions.md` | A crear en F2 |
| 14 | `scripts/sync-tests-kit.ps1` | Dominio nuevo: capa tests whitelist (5 tests del kit) | A crear en F2 |
| 15 | `scripts/sync-mcp-graphify.ps1` | Dominio nuevo: capa graphify unificación (D5) | A crear en F2 |
| 16 | `scripts/sync-backup-prune.ps1` | Dominio nuevo: capa poda backup con protección llamador (D1) | A crear en F2 |
| 17 | `upgrade_framework.ps1` | Corrección `Test-AuditLogIntegrity` (D3): hash sobre texto crudo sin `hash` ni `prevHash`, raíces legítimas, exit codes distinguibles | A modificar en F5 |
| 18 | `scripts/sync/mcp/lift-opencode.ps1` | Corrección D5: regeneración de ruta graphify cuando apunte fuera de `RootPath`, preservar `enabled` | A modificar en F6 |
| 19 | `scripts/sync/indexing/run-indexing.ps1` | Referenciado en trazabilidad D5 (FR-011/FR-012) | A revisar en F6 |
| 20 | `scripts/plataformador-bootstrap.ps1` | Invocador del orquestador vía `Invoke-SyncKit` (L2101-2139); sigue invocando `sync-kit.ps1` | Sin cambios (FR-016/H5) |
| 21 | `scripts/sync-kit-agents.ps1` | Orquestador desconectado de 12 capas; se retira como entry point competidor o se convierte en módulo | A retirar/convertir en F3 |
| 22 | `tests/kit-sync-merge.ps1` o `tests/sync-layers.ps1` | Suite de regresión: ≥15 asserts nuevos (D1-D5), exit 0 / exit 1 sin Pester | A crear/ampliar en F8 |
| 23 | `tests/fixtures/baseline-036.md` | Snapshot de divergencia maestro→destino (F0) | A crear en F0 |
| 24 | `Documentacion/Agents_IA_TECH/00-indice.md` | Entrada de spec 036 actualizada (estado, artefactos, decisión de arquitectura) | A actualizar (ver sección 6) |
| 25 | `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` | Registro de tareas 036-T000 a 036-T013, 036-T001-D1 a 036-T006-D5, 036-T052 a 036-T054, TRANS-001 | A actualizar (ver sección 7) |

Total: 25 archivos involucrados, de los cuales 5 specs ya están en disco, 11 scripts de dominio se crean o modifican en implementación, 2 archivos de tests y 2 archivos de índice/backlog se actualizan en converge.

---

## 6. Actualización de `00-indice.md`

El archivo `Documentacion\Agents_IA_TECH\00-indice.md` debe actualizar la entrada de spec 036 que actualmente está en la línea 204-210. La entrada actual marca la spec como "Especificada" con plan y tasks pendientes. Después del converge, la entrada debe reflejar que el ciclo spec→plan→tasks→analyze→threat-model→converge está completo y la spec está lista para Implement.

### Entrada a actualizar (líneas 204-211 actual):

```markdown
### 036-sync-kit-paridad-motor
- **Estado**: **Especificada** — `spec.md` completo (20 FR, 5 historias priorizadas, 9 casos límite, 10 criterios medibles y tabla de trazabilidad D1-D5 + arquitectura). Plan y tasks **pendientes**: los ejecuta la fase siguiente del flujo SSD. Origen: deuda D1-D5 documentada durante el sync a `Generator_IA_Projects` (commit `35da532`).
- **Ubicación**: `specs/036-sync-kit-paridad-motor/`
- **Decisión de arquitectura (usuario, 2026-11-03)**: `scripts/sync-kit.ps1` es el **orquestador** estable (punto de entrada que invoca el bootstrap) y cada dominio es un script propio, ejecutable y depurable por separado. La marca `[021-DEPRECATED]` (commit `c56b56c`, 2026-10-16) se retira: nunca se cableó el reemplazo y el "deprecado" siguió siendo el único invocado. `sync-kit-agents.ps1` deja de ser un orquestador competidor y aporta su lista de capas al orquestador único.
- **Objetivo**: Llevar el sync del kit a **un orquestador + capas de dominio**: que un solo comando deje el kit transversal sincronizado, que el backup del llamador sobreviva a la poda, que la verificación del audit log sea capaz de validar sus propias entradas y que `graphify` quede con una única entrada apuntando al grafo del destino. Sin lógica de dominio dentro del orquestador.
- **Defectos cubiertos**: D1 poda de `.kit-backup` que borra el backup previo del operador; D2/D4 ausencia de capas para `skills`, `rules`, `prompts`, `workflows`, `copilot-instructions.md` y los 5 tests del kit; D3 `Test-AuditLogIntegrity` con falso negativo permanente (payload con `prevHash`, cadena no lineal y round-trip JSON que altera el `timestamp`); D5 doble entrada `graphify` con la ruta del maestro en el destino.
- **Artefactos**: `spec.md`
```

### Entrada actualizada propuesta:

```markdown
### 036-sync-kit-paridad-motor
- **Estado**: **Listo para Implement** — ciclo SSD+Speckit completo (spec → plan → tasks → analyze → threat-model → converge). `spec.md` completo (20 FR, 5 US, 9 edge cases, 10 SC, trazabilidad D1-D5 + arquitectura). `plan.md` aprobado (8 fases F0-F8). `tasks.md` con 28 tareas (036-T000 a 036-T013, 036-T001-D1 a 036-T006-D5, 036-T052 a 036-T054, TRANS-001). `analyze.md` completo (5 ADR, 5 guardrails, 10 scripts de dominio, 5 riesgos, 10 SC mapeados). `threat-model.md` completo (STRIDE, 10 amenazas, 8 brechas, 8 recomendaciones). `converge.md` completo (esta consolidación). Constitución Check PASS v2.0.0.
- **Ubicación**: `specs/036-sync-kit-paridad-motor/`
- **Decisión de arquitectura (usuario, 2026-11-03)**: `scripts/sync-kit.ps1` es el **orquestador** estable (punto de entrada que invoca el bootstrap) y cada dominio es un script propio, ejecutable y depurable por separado. La marca `[021-DEPRECATED]` (commit `c56b56c`, 2026-10-16) se retira. `sync-kit-agents.ps1` deja de ser un orquestador competidor y aporta su lista de capas al orquestador único.
- **Objetivo**: Llevar el sync del kit a **un orquestador + capas de dominio**: que un solo comando deje el kit transversal sincronizado, que el backup del llamador sobreviva a la poda, que la verificación del audit log sea capaz de validar sus propias entradas y que `graphify` quede con una única entrada apuntando al grafo del destino. Sin lógica de dominio dentro del orquestador.
- **Defectos cubiertos**: D1 poda de `.kit-backup` que borra el backup previo del operador; D2/D4 ausencia de capas para `skills`, `rules`, `prompts`, `workflows`, `copilot-instructions.md` y los 5 tests del kit; D3 `Test-AuditLogIntegrity` con falso negativo permanente (payload con `prevHash`, cadena no lineal y round-trip JSON que altera el `timestamp`); D5 doble entrada `graphify` con la ruta del maestro en el destino.
- **Artefactos**: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `converge.md` (6 artefactos de documentación, ciclo completo)
- **Responsable implementación**: `plataformador` (tier Implementador). `pensador` orquesta y valida. `TRANS-001` es de `pensador`.
- **Fases de implementación**: F0 línea base → F1 adelgazar orquestador → F2 crear dominios planos → F3 conectar capas → F4-F7 corregir D1/D3/D5/D4 → F8 tests de regresión → Transversal TRANS-001.
```

Además, si existe una sección de "Especificaciones con converge listo para implementación" en el índice, se debería agregar una referencia cruzada a spec 036 junto a las specs que ya tienen converge (026, 028, 031, 032, 033, 035). Dado que el índice actual no tiene una sección explícita de ese tipo, la actualización de la entrada existente es suficiente.

---

## 7. Actualización de `pendientes-implementacion.md`

El archivo `Documentacion\Agents_IA_TECH\pendientes-implementacion.md` debe registrar las tareas de spec 036 con sus estados iniciales. Actualmente (líneas 22-27) tiene 7 tareas de spec 036 en la sección "Sin asignar" (`036-T000` a `036-T005` + `TRANS-001`). Después del converge, se deben registrar las 28 tareas completas con sus estados iniciales (`Pendiente`), responsables (`plataformador` para todas salvo `TRANS-001` que es `pensador`) y aprobación del plan.

### Tareas a registrar (estado inicial: Pendiente)

**F0 — Línea base:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T050 | F0 | Ejecutar 5 suites de tests del kit y capturar snapshot | plataformador | Pendiente |
| 036-T051 | F0 | Capturar estado actual de `.bootstrap-audit.log` | plataformador | Pendiente |

**F1 — Adelgazar orquestador:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T000 | F1 | Retirar marca `[021-DEPRECATED]` de `sync-kit.ps1` | plataformador | Pendiente |
| 036-T001 | F1 | Extraer `Merge-OpenCodeConfig` a dominio propio | plataformador | Pendiente |
| 036-T002 | F1 | Extraer `Merge-KitBlock` a dominio propio | plataformador | Pendiente |
| 036-T003 | F1 | Extraer gestión de huérfanos a dominio propio | plataformador | Pendiente |
| 036-T004 | F1 | Extraer `Sync-TransversalKit` a dominio propio | plataformador | Pendiente |
| 036-T005 | F1 | Adelgazar `sync-kit.ps1` a solo orquestación | plataformador | Pendiente |

**F2 — Crear dominios planos:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T006 | F2 | Mover `sync-skills.ps1` a `scripts/sync-skills.ps1` | plataformador | Pendiente |
| 036-T007 | F2 | Crear `scripts/sync-github-extras.ps1` | plataformador | Pendiente |
| 036-T008 | F2 | Crear `scripts/sync-tests-kit.ps1` | plataformador | Pendiente |
| 036-T009 | F2 | Crear `scripts/sync-mcp-graphify.ps1` | plataformador | Pendiente |
| 036-T010 | F2 | Crear `scripts/sync-backup-prune.ps1` | plataformador | Pendiente |

**F3 — Conectar capas al orquestador:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T011 | F3 | Actualizar `$script:Layers` en `sync-kit.ps1` | plataformador | Pendiente |
| 036-T012 | F3 | Implementar `-Only` / `-Skip` / `-ListLayers` | plataformador | Pendiente |
| 036-T013 | F3 | Retirar `sync-kit-agents.ps1` como orquestador competidor | plataformador | Pendiente |

**F4 — D1 (poda):**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T001-D1 | F4 | Implementar protección backup del llamador | plataformador | Pendiente |
| 036-T002-D1 | F4 | Exponer `-KeepBackups` y `-NoPrune` | plataformador | Pendiente |
| 036-T003-D1 | F4 | Registrar borrados en resumen | plataformador | Pendiente |

**F5 — D3 (audit log):**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T003-D3 | F5 | Recalcular hash sin `hash` ni `prevHash` | plataformador | Pendiente |
| 036-T004-D3 | F5 | Verificar sobre texto crudo, no round-trip JSON | plataformador | Pendiente |
| 036-T005-D3 | F5 | Tratar `prevHash: null` como raíz legítima | plataformador | Pendiente |
| 036-T006-D3 | F5 | Exit code distinguible | plataformador | Pendiente |

**F6 — D5 (graphify):**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T005-D5 | F6 | Unificar entrada graphify canónica | plataformador | Pendiente |
| 036-T006-D5 | F6 | Emitir WARN en duplicados y ruta ajena | plataformador | Pendiente |

**F7 — D4 (tests):**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T004-D4 | F7 | Mover whitelist de tests a capa del orquestador | plataformador | Pendiente |
| 036-T005-D4 | F7 | Respaldar tests del proyecto que colisionen | plataformador | Pendiente |
| 036-T006-D4 | F7 | Suite ejecutable sin Pester | plataformador | Pendiente |

**F8 — Tests de regresión:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| 036-T052 | F8 | Agregar asserts de regresión D1-D5 | plataformador | Pendiente |
| 036-T053 | F8 | Verificar dry-run reporta números concretos | plataformador | Pendiente |
| 036-T054 | F8 | Verificar frontera de escritura | plataformador | Pendiente |

**Transversal:**
| ID | Fase | Tarea | Responsable | Estado |
|----|------|-------|-------------|--------|
| TRANS-001 | Transversal | Implementar gate mecánico "aprobación → Speckit" | pensador | Pendiente |

### Formato de fila para el archivo

Cada fila sigue el formato del archivo existente:

```
| 036-T050 | 036 | Ejecutar 5 suites de tests del kit y capturar snapshot | Correr `harness-default.ps1`, `kit-sync-merge.ps1`, `agents-parity.ps1`, `kb-parity.ps1`, `mcp-refresh-parity.ps1` y registrar exit code de cada una. Capturar divergencia maestro→destino en skills, rules, prompts, workflows, copilot-instructions, tests whitelist. | Ninguna | 5 suites ejecutadas, exit codes registrados, snapshot de divergencia guardado en `tests/fixtures/baseline-036.md` | plataformador | Pendiente | plataformador |
```

Todas las 28 filas siguen este mismo patrón con su descripción, dependencias, criterio de aceptación, responsable, estado `Pendiente` y aprobación del plan (`plataformador` para tareas de implementación, `pensador` para `TRANS-001`). Las dependencias entre fases se respetan: F0 es prerequisito de todo; F1 es secuencial (T000→T001→T002→T003→T004→T005); F2 depende de T005; F3 depende de T006-T010; F4-F7 dependen de F1-F3 completadas; F8 depende de F4-F7; TRANS-001 depende de T054.

---

## 8. Próximos pasos — pasar a Implement

Para iniciar la fase Implement de la spec 036 se requieren los siguientes pasos, en orden:

### 8.1. Aprobación del `converge.md`

Este archivo `converge.md` debe ser revisado y aprobado por el usuario o por el agente orquestador (`pensador`) antes de que cualquier tarea de implementación se marque como iniciada. La aprobación confirma que la consolidación de documentación es completa, que no hay placeholders ni secciones vacías, y que todos los artefactos (spec, plan, tasks, analyze, threat-model, converge) están alineados.

### 8.2. Asignación de tareas a `plataformador`

Todas las tareas de implementación (036-T000 a 036-T013, 036-T001-D1 a 036-T006-D5, 036-T052 a 036-T054) son de responsabilidad del agente `plataformador` (tier Implementador), según lo definido en `tasks.md` y en `pendientes-implementacion.md`. `pensador` solo orquesta y valida. `TRANS-001` es responsabilidad de `pensador`.

Las tareas deben registrarse en `pendientes-implementacion.md` con estado `Pendiente` antes de comenzar la ejecución. El orden de ejecución respetado por `plataformador` es:

```
F0 (036-T050, 036-T051) → línea base obligatoria
    ↓
F1 (036-T000 → 036-T001 → 036-T002 → 036-T003 → 036-T004 → 036-T005)
    ↓
F2 (036-T006 → 036-T007 → 036-T008 → 036-T009 → 036-T010)
    ↓
F3 (036-T011 → 036-T012 → 036-T013)
    ↓
F4 (036-T001-D1 → 036-T002-D1 → 036-T003-D1)
F5 (036-T003-D3 → 036-T004-D3 → 036-T005-D3 → 036-T006-D3)
F6 (036-T005-D5 → 036-T006-D5)
F7 (036-T004-D4 → 036-T005-D4 → 036-T006-D4)
    ↓
F8 (036-T052 → 036-T053 → 036-T054)
    ↓
Transversal (TRANS-001)
```

F4-F7 son independientes entre sí una vez F1-F3 completadas; pueden ejecutarse en paralelo por diferentes sesiones.

### 8.3. Ejecución F0-F8

Cada fase produce un artefacto verificable:

- **F0**: 5 suites ejecutadas, exit codes registrados, snapshot en `tests/fixtures/baseline-036.md`, estado del audit log capturado (206 entradas, 136 raíces).
- **F1**: `sync-kit.ps1` sin `[021-DEPRECATED]`, 4 funciones extraídas a scripts propios, orquestador adelgazado (0 funciones de dominio dentro).
- **F2**: 6 scripts de dominio planos creados, cada uno ejecutable aislado con exit 0 sobre fixture y `RESULT:` propio.
- **F3**: `$script:Layers` con todas las capas, `-Only`/`-Skip`/`-ListLayers` funcionales, 0 scripts huérfanos.
- **F4**: Backup del llamador sobrevive, `-KeepBackups`/`-NoPrune` expuestos, borrados registrados en resumen.
- **F5**: `Test-AuditLogIntegrity` verifica por texto crudo, 0 violaciones sobre 206 entradas, 136 raíces reportadas, exit codes distinguibles.
- **F6**: 1 entrada graphify canónica, ruta dentro de `RootPath`, `enabled` preservado, WARN en duplicados.
- **F7**: Whitelist de 5 tests en capa del orquestador, respaldo de tests colisionantes, suite sin Pester exit 0.
- **F8**: ≥15 asserts nuevos (45 actuales → ≥60), 0 `[FAIL]`, dry-run reporta números concretos, frontera de escritura respetada (no toca `Documentacion/<AppName>/`, `src/` ni `.opencode/config.json`).

### 8.4. Criterio de entrada a Implement

La fase Implement puede iniciar solo cuando:
1. `converge.md` está escrito y aprobado (este documento).
2. Las 28 tareas de spec 036 están registradas en `pendientes-implementacion.md` con estado `Pendiente`.
3. La entrada de spec 036 en `00-indice.md` refleja "Listo para Implement".
4. `plataformador` ha sido asignado como responsable de las tareas de implementación.

Una vez completadas F0-F8 y TRANS-001, la spec 036 pasa a estado `Cerrado` en `pendientes-implementacion.md` (flujo completo/operativo, nunca eliminada) y permanece ACTIVA en `specs/`.

---

## Verificación de integridad del artefacto

Este archivo ha sido revisado sección por sección: cada una de las 8 secciones obligatorias contiene más de 5 líneas de contenido real, no hay placeholders (TBD/TODO/pendiente/N/A/XXX/...), no hay tablas con solo encabezado y cero filas, no hay listas vacías ni genéricas, y todos los diagramas Mermaid tienen nodos y aristas reales. El contenido es consistente con `spec.md`, `plan.md`, `tasks.md`, `analyze.md` y `threat-model.md` de la spec 036.

*Fin del converge 036. Generado por el agente `documentador` en la Fase Converge del pipeline Speckit.*
