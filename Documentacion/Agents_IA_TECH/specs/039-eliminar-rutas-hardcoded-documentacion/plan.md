# Implementation Plan: Eliminar rutas hardcoded de la documentación y hacer el kit portable

**Branch**: `039-eliminar-rutas-hardcoded-documentacion` | **Date**: 2026-11-09 | **Spec**: Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/spec.md

**Input**: Feature specification from Spec 039 — eliminar todas las rutas absolutas hardcodeadas (`C:\Proyectos\Agents_IA_TECH`, `C:\Proyectos\opencode`) de `README.md`, `AGENTS.md`, scripts `.ps1`/`.sh`, y artefactos generados; reemplazarlas por variables con comentarios explicativos, rutas relativas, o parámetros de línea de comandos; agregar validación en el bootstrap; limpiar artefactos de prueba con rutas locales; y agregar test de regresión.

---

## Summary

**Primary Requirement**: El kit Agents_IA_TECH es una aplicación redistribuible que debe funcionar en cualquier máquina sin rutas fijas. Actualmente contiene rutas absolutas hardcodeadas de la máquina del autor (`C:\Proyectos\Agents_IA_TECH`, `C:\Proyectos\opencode`) en documentación, scripts y artefactos generados, lo que rompe la portabilidad.

**Technical Approach**: 
1. **Escaneo y reemplazo sistemático** — Buscar `C:\\Proyectos` en todos los archivos distribuibles (`.md`, `.ps1`, `.sh` en `README.md`, `AGENTS.md`, `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`, `scripts/`) y reemplazar por variables `$KitPath`, `$ProjectRoot`, `$PSScriptRoot` con comentarios `# <- ajusta a tu ruta`, o rutas relativas (`..\Agents_IA_TECH`, `./scripts`).
2. **Validación en bootstrap** — Extender `plataformador-bootstrap.ps1` con switch `-CheckHardcodedPaths` que escanee el proyecto destino y reporte rutas absolutas sospechosas antes de completar el plataformado.
3. **Limpieza de artefactos** — Eliminar `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md` (artefactos de prueba con rutas de la máquina de desarrollo).
4. **Test de regresión** — Crear `tests/validate-no-hardcoded-paths.Tests.ps1` que valide `grep -r "C:\\\\Proyectos" ...` devuelve 0 resultados en archivos distribuibles.

---

## Technical Context

**Language/Version**: PowerShell 5.1+ / PowerShell 7+ (scripts del kit), Markdown (documentación)

**Primary Dependencies**: 
- `plataformador-bootstrap.ps1` (script principal de bootstrap, ya usa `$PSScriptRoot` y parámetros `-RootPath`, `-KitPath`)
- `sync-agents.ps1` (script de sincronización del kit transversal)
- Git (para control de versiones del kit)

**Storage**: Sistema de archivos local (scripts, documentación, configuración)

**Testing**: Pester 5+ (PowerShell testing framework) para `tests/validate-no-hardcoded-paths.Tests.ps1`

**Target Platform**: Windows (PowerShell), Linux/macOS (PowerShell Core / Bash equivalents), cualquier ruta de clonación (`/home/user/kits/Agents_IA_TECH`, `D:\Kits\Agents_IA_TECH`, `C:\Users\X\Agents_IA_TECH`)

**Project Type**: Kit de agentes redistribuible / herramienta de configuración de proyectos (CLI + documentación + plantillas)

**Performance Goals**: 
- Escaneo de rutas hardcodeadas en < 2 segundos para proyecto típico (~500 archivos)
- Bootstrap con `-CheckHardcodedPaths` añade < 500ms al tiempo total

**Constraints**: 
- No romper funcionalidad existente del bootstrap ni del sync-kit (NFR-03)
- Variables en README deben ser copiables/pegables y solo requerir cambiar líneas marcadas con `# <- ajusta...` (NFR-02)
- Kit debe funcionar sin editar documentación tras clonar en cualquier ruta (NFR-01)

**Scale/Scope**: 
- Archivos a revisar: ~50 archivos `.md` en `README.md`, `AGENTS.md`, `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`
- Scripts a revisar: ~10 scripts `.ps1` en `scripts/` y raíz
- Artefactos a limpiar: 2 archivos en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution Source**: `.specify/memory/constitution.md` (kit root) → replicada a `Documentacion/Agents_IA_TECH/.specify/constitution.md` por `sync-kit.ps1` → copiada a `src/<App>/.specify/constitution.md` en runtime.

| Regla Constitucional | Cumplimiento | Justificación / Acción |
|---|---|---|
| **Agentes documentales no escriben código** (Tier Documental) | ✅ Cumple | Tareas T01, T02 asignadas a `documentador` (solo documentación). T03, T04, T05 a `plataformador` (scripts/bootstrap). T06, T07 a `qa-senior` (tests). |
| **Orquestación por `pensador`** (ADR-0005) | ✅ Cumple | `pensador` gobierna el flujo: spec → plan → tasks → analyze → converge → implement. `Agent-SSD` ejecuta comandos Speckit bajo delegación. |
| **Ciclo obligatorio sin saltos** | ✅ Cumple | Este plan es salida de fase `plan` (speckit-plan). Siguiente: `tasks` (speckit-tasks) → `analyze` → `converge` → `implement`. |
| **Contenido completo, sin placeholders** | ✅ Cumple | Este plan rellena todas las secciones con contenido real, sin TBD/TODO/pendiente. |
| **Estructura specs por app** | ✅ Cumple | Spec y plan en `Documentacion/Agents_IA_TECH/specs/039-.../` (aislado por app). |
| **Sync-kit no toca Documentacion/<AppName>/** | ✅ Cumple | Este spec es propio de Agents_IA_TECH, no se sincroniza entre proyectos. |

**Gate Status**: ✅ **PASS** — No hay violaciones que requieran justificación en Complexity Tracking.

---

## Project Structure

### Documentation (this feature)

```text
specs/039-eliminar-rutas-hardcoded-documentacion/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (not required - no NEEDS CLARIFICATION)
├── data-model.md        # Phase 1 output (not applicable - no data entities)
├── quickstart.md        # Phase 1 output (validation guide for portability)
├── contracts/           # Phase 1 output (not applicable - no external interfaces)
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
# Kit Agents_IA_TECH - Estructura real afectada por este plan
Agents_IA_TECH/                    # Raíz del kit (variable $KitPath)
├── README.md                      # T01: Reemplazar rutas absolutas
├── AGENTS.md                      # T02: Reemplazar rutas absolutas
├── sync-agents.ps1                # T03: Verificar sin rutas hardcoded
├── scripts/
│   ├── plataformador-bootstrap.ps1  # T03, T04: Agregar -CheckHardcodedPaths
│   └── ... (otros scripts .ps1)     # T03: Verificar sin rutas hardcoded
├── .github/
│   ├── agents/                    # T01/T02: Revisar agentes .md
│   ├── skills/                    # T01/T02: Revisar skills .md
│   └── rules/                     # T01/T02: Revisar rules .md
├── .opencode/
│   ├── agents/                    # T01/T02: Revisar agentes .md
│   └── skills/                    # T01/T02: Revisar skills .md
├── .doc_agents/                   # T01/T02: Revisar .md
├── Documentacion/
│   └── Agents_IA_TECH/            # T01/T02: Revisar specs, docs .md
│       └── specs/
│           └── 039-.../           # Este spec/plan
├── tests/
│   └── validate-no-hardcoded-paths.Tests.ps1  # T06: Test de regresión
└── .specify/
    ├── memory/
    │   └── constitution.md        # Fuente constitution (nivel 1)
    ├── scripts/
    │   └── powershell/
    │       ├── setup-plan.ps1
    │       ├── setup-tasks.ps1
    │       ├── common.ps1
    │       └── check-prerequisites.ps1
    └── templates/
        ├── plan-template.md
        ├── tasks-template.md
        ├── spec-template.md
        └── checklist-template.md
```

**Artefactos externos a limpiar (T05)**:
```
C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\
├── mcp-validation-plan.md         # ELIMINAR - contiene rutas C:\Proyectos\opencode
└── mcp-validation-tasks.md        # ELIMINAR - contiene rutas C:\Proyectos\opencode
```

**Structure Decision**: Estructura single-project (kit redistribuible). No hay backend/frontend/api móviles. El kit se clona completo y se usa `plataformador-bootstrap.ps1` para instalar en proyectos destino.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| N/A | Constitution Check PASS — no violations | N/A |

---

## Phase 0: Research (Optional - No NEEDS CLARIFICATION)

**Status**: SKIPPED — El spec no tiene `NEEDS CLARIFICATION` en Technical Context. Todas las decisiones técnicas están definidas:
- Variables a usar: `$KitPath`, `$ProjectRoot`, `$PSScriptRoot`, parámetros `-RootPath`, `-KitPath` (ya existentes en bootstrap)
- Patrón de comentarios: `# <- ajusta a tu ruta` (ya usado en README línea 22)
- Validación: `grep -r "C:\\\\Proyectos"` en archivos distribuibles
- Test framework: Pester (estándar PowerShell en el kit)

**Decisiones documentadas en spec**:
- ADR-0003: Bootstrap ya usa `$PSScriptRoot` y parámetros → documentación debe reflejar ese patrón
- ADR-0004: Artefactos `.specify/` generados por bootstrap deben ser locales al proyecto, no contener rutas de máquina generadora
- Patrón correcto ya existe en README: `$KitPath = "..\Agents_IA_TECH"` (sección "Alternativa sin red")

---

## Phase 1: Design & Contracts

### Data Model — NOT APPLICABLE

Este feature no introduce entidades de datos, modelos de base de datos, ni estado persistente. Es una refactorización de documentación y scripts para portabilidad. No se genera `data-model.md`.

### Contracts — NOT APPLICABLE

El kit no expone APIs externas, endpoints, CLIs públicas para terceros, ni grammars. Los scripts son internos (`plataformador-bootstrap.ps1`, `sync-agents.ps1`). No se genera carpeta `contracts/`.

### Quickstart Validation Guide → `quickstart.md`

```markdown
# Quickstart: Validar Portabilidad del Kit (Spec 039)

## Prerrequisitos
- PowerShell 5.1+ o PowerShell 7+
- Git
- Kit clonado en ubicación arbitraria (ej: `/home/user/kits/Agents_IA_TECH`, `D:\Kits\Agents_IA_TECH`)

## Escenario 1: Verificar cero rutas absolutas en archivos distribuibles

```powershell
# Desde la raíz del kit clonado
cd <ruta-kit-clonado>

# Test automático (T06/T07)
Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed
# Debe pasar: 0 resultados para "C:\\Proyectos" en README.md, AGENTS.md, scripts/, .github/, .opencode/, .doc_agents/, Documentacion/
```

### Validación manual (grep)

```powershell
# Debe devolver 0 líneas (o solo comentarios con variable $KitPath/$ProjectRoot)
Select-String -Pattern "C:\\\\Proyectos" -Path README.md, AGENTS.md, scripts\*.ps1, .github\**\*.md, .opencode\**\*.md, .doc_agents\*.md, Documentacion\**\*.md -Recurse
```

## Escenario 2: Bootstrap detecta rutas hardcoded en proyecto destino

```powershell
# En un proyecto NUEVO (vacío o existente) donde se va a instalar el kit
cd <proyecto-destino>

# Ejecutar bootstrap con validación
<ruta-kit-clonado>\scripts\plataformador-bootstrap.ps1 -RootPath . -KitPath <ruta-kit-clonado> -CheckHardcodedPaths

# Salida esperada si el proyecto destino tiene rutas C:\Proyectos en su Documentacion/:
# ⚠️  ADVERTENCIA: Se detectaron rutas absolutas hardcodeadas en:
#    Documentacion/MiApp/specs/001-xyz/spec.md:15  →  $ProjectRoot = "C:\Proyectos\MiApp"
#    .github/agents/mi-agente.agent.md:42           →  C:\Proyectos\Agents_IA_TECH
# Acción recomendada: Reemplace por variables $KitPath/$ProjectRoot con comentario "# <- ajusta a tu ruta"
```

## Escenario 3: README copiable/pegable en proyecto nuevo

```powershell
# 1. Copiar README.md a proyecto nuevo
Copy-Item <ruta-kit>\README.md <proyecto-nuevo>\README.md

# 2. Editar SOLO las líneas marcadas con "# <- ajusta a tu ruta"
#    $ProjectRoot = "C:\Proyectos\MiProyecto"  # <- ajusta a tu ruta
#    $KitPath = "..\Agents_IA_TECH"             # <- ajusta a tu ruta

# 3. Comandos del README deben funcionar sin más cambios
#    Ejemplo: .\scripts\plataformador-bootstrap.ps1 -RootPath $ProjectRoot -KitPath $KitPath
```

## Criterios de Éxito
- ✅ Test Pester pasa (0 rutas absolutas en archivos del kit)
- ✅ Bootstrap con `-CheckHardcodedPaths` reporta solo en proyecto destino, nunca en el kit mismo
- ✅ README funciona copiando y cambiando solo 2-3 variables marcadas
```

---

## Architecture Decisions (ADR References)

| ADR | Título | Relevancia para este Plan |
|---|---|---|
| **ADR-0003** | Plataforma Bootstrap Instalador Único | Bootstrap ya usa `$PSScriptRoot`, `-RootPath`, `-KitPath`. La documentación (README, AGENTS.md) debe reflejar ese patrón: variables con comentarios, no rutas literales. |
| **ADR-0004** | Post-Plataformado Speckit | Artefactos generados en `.specify/` (plan.md, tasks.md, etc.) deben ser locales al proyecto destino. Los archivos `mcp-validation-plan.md` y `mcp-validation-tasks.md` en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` violan esto: son artefactos de prueba con rutas de la máquina de desarrollo → **T05 los elimina**. |
| **ADR-0005** | Orquestación Speckit por `pensador`/`Agent-SSD` | Este plan lo genera `Agent-SSD` bajo delegación de `pensador`. Las tareas T01-T07 se ejecutarán en fase `implement` por los agentes asignados (documentador, plataformador, qa-senior). |

---

## File Modifications Needed

### T01 — `README.md` (Agente: `documentador`)

| Línea/Sección Actual | Cambio Requerido |
|---|---|
| L22: `$ProjectRoot = "C:\Proyectos\MiProyecto"` | Mantener variable pero asegurar comentario `# <- ajusta a tu ruta` (ya existe) |
| Sección "Alternativa sin red": `C:\Proyectos\Agents_IA_TECH` | Reemplazar por `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta` (patrón ya correcto en esa sección) |
| Sección "sync-kit local": `C:\Proyectos\Agents_IA_TECH` | Reemplazar por `$KitPath` variable |
| Cualquier otra ruta `C:\Proyectos\...` o `D:\...` | Reemplazar por variable `$KitPath`/`$ProjectRoot` o ruta relativa `./scripts`, `../Agents_IA_TECH` |

**Archivos de referencia en README que pueden tener rutas**: comandos de ejemplo, rutas a scripts, referencias a `.specify/`.

### T02 — `AGENTS.md` (Agente: `documentador`)

| Ubicación | Cambio Requerido |
|---|---|
| Cualquier ruta `C:\Proyectos\Agents_IA_TECH` o `C:\Proyectos\opencode` | Reemplazar por `$KitPath` con comentario `# <- ajusta a tu ruta` o ruta relativa |
| Referencias a `.github/agents/`, `.opencode/agents/` | Usar rutas relativas desde raíz del kit (`./.github/agents/`) |
| Ejemplos de rutas en agentes (`pensador`, `plataformador`, etc.) | Variables `$KitPath`, `$ProjectRoot` |

**Alcance**: Todo el archivo `AGENTS.md` (reglas base del kit).

### T03 — Scripts en `scripts/` y raíz (Agente: `plataformador`)

| Script | Rutas Hardcodeadas a Eliminar | Reemplazo |
|---|---|---|
| `sync-agents.ps1` | `C:\Proyectos\Agents_IA_TECH` en rutas de origen/destino | `$PSScriptRoot` (raíz del kit) o parámetro `-KitPath` |
| `scripts/plataformador-bootstrap.ps1` | Verificar que no tenga rutas fijas; ya usa `$PSScriptRoot` | Confirmar y documentar patrón |
| `scripts/*.ps1` (otros) | Cualquier `C:\Proyectos\...` | `$PSScriptRoot`, `$KitPath`, o parámetros |
| `*.sh` (si existen) | `/home/...`, `/Users/...` | `$SCRIPT_DIR`, variables de entorno |

**Patrón obligatorio en scripts**:
```powershell
# Al inicio de cada script distribuible
$KitPath = $PSScriptRoot  # Raíz del kit (donde está este script)
# O si el script está en subcarpeta:
$KitPath = Split-Path $PSScriptRoot -Parent
```

### T04 — `plataformador-bootstrap.ps1`: Agregar `-CheckHardcodedPaths` (Agente: `plataformador`)

**Nuevo parámetro**:
```powershell
[switch]$CheckHardcodedPaths
```

**Implementación**:
```powershell
if ($CheckHardcodedPaths) {
    $targetDocPaths = @(
        "Documentacion\**\*.md",
        ".github\**\*.md", 
        ".opencode\**\*.md",
        ".doc_agents\*.md"
    )
    $hardcodedPaths = @()
    foreach ($pattern in $targetDocPaths) {
        $matches = Get-ChildItem -Path $RootPath -Recurse -Filter $pattern -ErrorAction SilentlyContinue |
                   Select-String -Pattern "C:\\\\Proyectos|D:\\\\|/home/|/Users/" -ErrorAction SilentlyContinue
        if ($matches) { $hardcodedPaths += $matches }
    }
    if ($hardcodedPaths) {
        Write-Warning "ADVERTENCIA: Se detectaron rutas absolutas hardcodeadas en el proyecto destino:"
        $hardcodedPaths | ForEach-Object { Write-Warning "  $($_.Path):$($_.LineNumber)  →  $($_.Line.Trim())" }
        Write-Warning "Acción recomendada: Reemplace por variables \$KitPath/\$ProjectRoot con comentario '# <- ajusta a tu ruta'"
    } else {
        Write-Host "✅ Validación -CheckHardcodedPaths: No se detectaron rutas absolutas en documentación del proyecto destino."
    }
}
```

**Ubicación en script**: Al final del bootstrap, después de copiar archivos, antes de mensaje de éxito.

### T05 — Eliminar artefactos en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` (Agente: `plataformador`)

| Archivo | Acción |
|---|---|
| `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` | **ELIMINAR** (archivo de prueba con rutas locales) |
| `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-tasks.md` | **ELIMINAR** (archivo de prueba con rutas locales) |

**Nota**: Estos archivos están FUERA del repo del kit (en `C:\Proyectos\opencode\...`). El agente `plataformador` debe ejecutar la limpieza en la máquina de desarrollo donde se generaron. No están en el repo Git del kit.

### T06 — Test `tests/validate-no-hardcoded-paths.Tests.ps1` (Agente: `qa-senior`)

```powershell
# tests/validate-no-hardcoded-paths.Tests.ps1
<#
.SYNOPSIS
    Valida que el kit no contenga rutas absolutas hardcodeadas en archivos distribuibles.
.DESCRIPTION
    Escanea README.md, AGENTS.md, scripts/, .github/, .opencode/, .doc_agents/, Documentacion/
    buscando patrones de rutas absolutas Windows (C:\Proyectos, D:\), Linux (/home/, /Users/).
    Debe devolver 0 resultados (excepto líneas de comentario con variable $KitPath/$ProjectRoot).
#>

Describe "Kit Portability - No Hardcoded Absolute Paths" {
    $kitRoot = (Split-Path $PSScriptRoot -Parent)
    $distributablePaths = @(
        "$kitRoot\README.md",
        "$kitRoot\AGENTS.md",
        "$kitRoot\scripts\*.ps1",
        "$kitRoot\.github\**\*.md",
        "$kitRoot\.opencode\**\*.md",
        "$kitRoot\.doc_agents\*.md",
        "$kitRoot\Documentacion\**\*.md"
    )

    $forbiddenPatterns = @(
        "C:\\\\Proyectos",      # Rutas Windows del autor
        "D:\\\\",               # Otras unidades Windows
        "/home/",               # Rutas Linux home
        "/Users/"               # Rutas macOS Users
    )

    foreach ($pattern in $forbiddenPatterns) {
        It "No contiene patrón '$pattern' en archivos distribuibles" {
            $matches = @()
            foreach ($path in $distributablePaths) {
                $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue -Recurse
                foreach ($file in $files) {
                    $lines = Select-String -Path $file.FullName -Pattern $pattern -ErrorAction SilentlyContinue
                    foreach ($line in $lines) {
                        # Permitir solo si es comentario con variable $KitPath o $ProjectRoot
                        $lineText = $line.Line.Trim()
                        if (-not ($lineText.StartsWith("#") -and ($lineText -like "*`$KitPath*" -or $lineText -like "*`$ProjectRoot*"))) {
                            $matches += "$($file.FullName):$($line.LineNumber) → $lineText"
                        }
                    }
                }
            }
            $matches | Should -BeNullOrEmpty -Because "Se encontraron rutas absolutas hardcodeadas no permitidas: $($matches -join '; ')"
        }
    }
}
```

### T07 — Ejecutar test y confirmar 0 rutas absolutas (Agente: `qa-senior`)

```powershell
# Ejecución en CI y local
cd <raiz-kit>
Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed -PassThru
# Debe mostrar: Tests Passed: 4 (uno por patrón), Failed: 0
```

---

## Test Strategy

### Niveles de Prueba

| Nivel | Qué Valida | Herramienta | Cuándo |
|---|---|---|---|
| **Unitario (T06/T07)** | Cero rutas `C:\Proyectos`, `D:\`, `/home/`, `/Users/` en archivos del kit | Pester 5+ (`tests/validate-no-hardcoded-paths.Tests.ps1`) | Pre-commit, CI, post-implement |
| **Integración (T04 manual)** | Bootstrap `-CheckHardcodedPaths` detecta rutas en proyecto destino | PowerShell manual / script | Pre-release, validación usuario |
| **Funcional (README)** | README copiable/pegable funcionando solo cambiando variables marcadas | Manual (usuario nuevo) | Documentación release |

### Cobertura de Patrones Prohibidos

| Patrón | Archivos Escaneados | Excepción Permitida |
|---|---|---|
| `C:\\Proyectos` | README.md, AGENTS.md, scripts/*.ps1, .github/**/*.md, .opencode/**/*.md, .doc_agents/*.md, Documentacion/**/*.md | Línea comentada (`#`) que contiene `$KitPath` o `$ProjectRoot` |
| `D:\\` | Mismo conjunto | Misma excepción |
| `/home/` | Mismo conjunto | Misma excepción |
| `/Users/` | Mismo conjunto | Misma excepción |

### CI Integration

Agregar a pipeline CI (GitHub Actions / Azure DevOps / etc.):
```yaml
- name: Validate No Hardcoded Paths
  run: |
    cd ${{ github.workspace }}
    Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1 -Output Detailed -EnableExit
  shell: pwsh
```

---

## Acceptance Criteria Verification

| AC # | Criterio de Aceptación (del Spec) | Verificación en Plan | Test Asociado |
|---|---|---|---|
| **AC-1** | `grep -r "C:\\\\Proyectos" README.md AGENTS.md scripts/ --include="*.md" --include="*.ps1"` → 0 resultados (excepto comentarios con variable) | T01, T02, T03 eliminan rutas; T06 test automatiza verificación | `validate-no-hardcoded-paths.Tests.ps1` (patrón `C:\\\\Proyectos`) |
| **AC-2** | `grep -r "C:\\\\Proyectos" .github/ .opencode/ .doc_agents/ Documentacion/ --include="*.md"` → 0 resultados | T01, T02 cubren estos directorios; T06 test automatiza | `validate-no-hardcoded-paths.Tests.ps1` (patrón `C:\\\\Proyectos` en paths extendidos) |
| **AC-3** | README copiable a `/home/user/mi-proyecto` o `D:\Proyectos\mi-proyecto` funcionando cambiando solo variables marcadas | T01 usa patrón `$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta`; quickstart.md valida escenario | Quickstart Escenario 3 (manual) |
| **AC-4** | Artefactos `.specify/mcp-validation-*.md` en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` no existen | T05 elimina explícitamente estos 2 archivos | Verificación manual post-T05 (`Test-Path` en ambas rutas → False) |
| **AC-5** | Test `tests/validate-no-hardcoded-paths.Tests.ps1` pasa en CI | T06 crea test; T07 ejecuta y confirma pass | CI pipeline ejecuta T07 automáticamente |

### Checklist de Verificación Pre-Entrega

- [ ] T01: `README.md` — 0 rutas absolutas, variables con `# <- ajusta a tu ruta`
- [ ] T02: `AGENTS.md` — 0 rutas absolutas
- [ ] T03: `scripts/*.ps1`, `sync-agents.ps1` — usan `$PSScriptRoot`/parámetros, sin `C:\Proyectos`
- [ ] T04: `plataformador-bootstrap.ps1` tiene `-CheckHardcodedPaths` funcional
- [ ] T05: `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` **ELIMINADO**
- [ ] T05: `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-tasks.md` **ELIMINADO**
- [ ] T06: `tests/validate-no-hardcoded-paths.Tests.ps1` creado y pasa localmente
- [ ] T07: Test pasa en CI (GitHub Actions configurado)
- [ ] Quickstart.md valida los 3 escenarios (portabilidad, bootstrap check, README copiable)

---

## Task Summary (T01-T07) con Asignación de Agentes

| ID | Tarea | Agente | Archivos Afectados | Dependencias |
|---|---|---|---|---|
| **T01** | Revisar `README.md` completo y reemplazar rutas absolutas por variables/rutas relativas | `documentador` | `README.md` | Ninguna |
| **T02** | Revisar `AGENTS.md` y eliminar rutas absolutas | `documentador` | `AGENTS.md` | Ninguna |
| **T03** | Revisar scripts en `scripts/` y raíz: buscar `C:\Proyectos\Agents_IA_TECH` y reemplazar por `$PSScriptRoot` o parámetros | `plataformador` | `sync-agents.ps1`, `scripts/*.ps1` | T01/T02 (patrón de variables) |
| **T04** | Agregar validación `-CheckHardcodedPaths` en `plataformador-bootstrap.ps1` | `plataformador` | `scripts/plataformador-bootstrap.ps1` | T03 (scripts limpios) |
| **T05** | Eliminar `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md` | `plataformador` | Archivos externos en `C:\Proyectos\opencode\...` | Ninguna (limpieza máquina dev) |
| **T06** | Agregar test en `tests/validate-no-hardcoded-paths.Tests.ps1` | `qa-senior` | `tests/validate-no-hardcoded-paths.Tests.ps1` | T01-T03 (archivos ya limpios) |
| **T07** | Ejecutar test y confirmar 0 rutas absolutas en archivos distribuibles | `qa-senior` | Ejecución CI/local | T06 (test existe) |

**Orden de ejecución recomendado**: T01 → T02 → T03 → T04 → T05 → T06 → T07

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Romper comandos de ejemplo en README al cambiar rutas | Media | Alto | Probar cada comando del README tras cambios (T01 manual + T07 automatizado) |
| Scripts usan `$PSScriptRoot` incorrectamente si se mueven de carpeta | Baja | Medio | Usar `Split-Path $PSScriptRoot -Parent` para subir a raíz del kit; documentar en comentarios |
| `-CheckHardcodedPaths` da falsos positivos en comentarios legítimos | Media | Bajo | Excepción en test: permitir líneas `#` que contengan `$KitPath` o `$ProjectRoot` |
| Usuario no ejecuta `-CheckHardcodedPaths` y porta rutas a su proyecto | Media | Medio | Documentar en README y quickstart; hacer flag default en futuro si se adopta ampliamente |
| Artefactos T05 no accesibles (máquina distinta) | Baja | Bajo | `plataformador` documenta pasos manuales si no están en máquina actual |

---

## Referencias Cruzadas

- **Spec**: `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/spec.md`
- **ADR-0003**: Plataforma Bootstrap Instalador Único (patrón `$PSScriptRoot`, parámetros)
- **ADR-0004**: Post-Plataformado Speckit (artefactos locales al proyecto)
- **ADR-0005**: Orquestación Speckit por `pensador`/`Agent-SSD`
- **Constitution**: `.specify/memory/constitution.md` → `Documentacion/Agents_IA_TECH/.specify/constitution.md`
- **Quickstart**: `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/quickstart.md` (generado en Phase 1)
- **Tasks**: `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/tasks.md` (próxima fase: speckit-tasks)