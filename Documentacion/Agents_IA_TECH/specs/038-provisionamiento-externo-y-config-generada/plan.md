# Implementation Plan: Aprovisionamiento externo por tipo y configuración generada

**Branch**: `038-provisionamiento-externo-y-config-generada` | **Date**: 2026-11-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/spec.md`

**Note**: Template sembrado por `.specify/scripts/powershell/setup-plan.ps1 -Json` (BRANCH resuelta: `038-provisionamiento-externo-y-config-generada`); rellenado por la fase `speckit-plan`.

## Summary

El repositorio declara dependencias externas que la máquina no verifica: `context-mode` apunta a `build/cli.js` (inexistente en 2.1.0), `dependencias-manifest.yml` declara versiones que nadie compara y `opencode.json` convive con la forma plana `mcp.<nombre>` que escriben `Ensure-OpenCodeMcp`, `Configure-Graphify` y `run-indexing.ps1`. Esta spec convierte la declaración en un gate.

Enfoque técnico: una **taxonomía de cinco tipos de aprovisionamiento** (`kit-integrado`, `kit-fuente`, `mcp-workspace`, `mcp-build-local`, `entorno`) declarada en `dependencias-manifest.yml`; **sondas de solo lectura** con autoridad de versión por tipo (SHA de branch head para código de terceros, registro del gestor para MCP de workspace, release + artefacto para builds locales); un **estado por workspace** no versionado (`.opencode/mcp-state.json`); y **tres verbos con contratos separados**: `validate` (solo lectura, exit code), `apply` (instalación explícita, fail-open) y `generate` (escritura de configuración de arnés desde la realidad verificada). La configuración de los dos arneses se **genera** desde una fuente única (`scripts/mcp/generate-opencode.ps1`, `scripts/mcp/generate-copilot.ps1`) y su paridad se **verifica** con `scripts/mcp/validate-parity.ps1`, nunca se asume (ADR-0014).

## Technical Context

**Language/Version**: PowerShell 7+ (`pwsh`) para sondas, generadores y validadores; Node.js `>=24.15.0` (prerrequisito de `context-mode` 2.1.0); Python 3 (markitdown-mcp); YAML para el manifest y JSON para estado y configuración generada.

**Primary Dependencies**: `context-mode` 2.1.0 (npm, `mcp-workspace`), `codebase-memory-mcp` (npm, `mcp-workspace`), `markitdown-mcp` 0.0.1a3 (PyPI, `mcp-workspace`), `graphify` (`mcp-workspace`), `context7` (`mcp-workspace`), `github` (`mcp-workspace`), `playwright` (`mcp-workspace`), `tokenslayer` (`mcp-build-local`), `ECC` (`kit-integrado`, clon en `proyect_ext/ECC`), `spec-kit` (`kit-fuente`, clon en `proyect_ext/spec-kit`), runtime `entorno` (Node, Python, PowerShell, git).

**Storage**: `dependencias-manifest.yml` versionado en la raíz (única fuente de verdad, `!dependencias-manifest.yml` re-incluido en `.gitignore`); `.opencode/mcp-state.json` no versionado (estado por workspace, escritura atómica); `opencode.json` y `.vscode/mcp.json` generados y no versionados; clones de terceros en `proyect_ext/` (ignorado salvo el manifest).

**Testing**: Pester 6.2.0 (`tests/*.Tests.ps1`, funciones declaradas dentro de `BeforeAll`), `scripts/validate-agents-skills.ps1` (VAL-07, debe quedar `FAIL: 0`), `tests/validate-no-hardcoded-paths.Tests.ps1` (portabilidad, 16/16), y el validador de paridad nuevo (`scripts/mcp/validate-parity.ps1`).

**Target Platform**: Windows con PowerShell 7 como plataforma primaria de ejecución; portabilidad a Linux/macOS exigida por NFR-06 (ninguna ruta absoluta de máquina en artefactos versionados; rutas absolutas solo en estado y archivos generados no versionados).

**Project Type**: kit de configuración y automatización (no aplicación): scripts PowerShell, plantillas versionadas y documentación. No hay `src/<App>` de runtime para esta feature.

**Performance Goals**: sonda completa (`validate`) en menos de 60 s con red disponible y degradación a `desconocido` en menos de 15 s sin red (NFR-07); `generate` idempotente byte a byte entre ejecuciones consecutivas (NFR-02, SC-003).

**Constraints**: sin secretos en estado ni en artefactos generados (NFR-04); escritura atómica temporal + reemplazo (NFR-03); fail-open con estado explícito, nunca fail-silent (NFR-05); `generate` solo emite entradas cuyo binario resuelve (FR-08); `type=stdio` y forma canónica `mcp.servers.<nombre>` obligatorios (FR-11, ADR-0010); sin rutas absolutas hardcodeadas en archivos versionados (SC-007); ninguna escritura automática como efecto secundario de `validate` (NFR-01).

**Scale/Scope**: 11 dependencias externas actuales en 5 tipos; 2 arneses (OpenCode y GitHub Copilot VS Code); 14 agentes del kit sujetos a validación de capacidades; 4 capacidades iniciales en la matriz (`subagentes/delegación`, `hooks/eventos de sesión`, `permisos de escritura por path`, `skills por frontmatter`); 3 verbos y 2 generadores.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitución vigente: `Agents IA Tech Constitution` v2.1.0 (registro de cambios 2026-11-07 y 2026-10-03). La enmienda MINOR v2.0.0 → v2.1.0 que esta spec exige como requisito de gobernanza **ya está registrada** en `.specify/memory/constitution.md` ("Aprovisionamiento por tipo y verificacion declaracion-contra-realidad (v2.1.0)", Art. VI), junto con la decisión de configuración generada (ADR-0014) y la forma canónica (ADR-0010).

| Principio | Cómo lo cumple esta feature | Veredicto |
|---|---|---|
| I. Modular Agent Design | Cada verbo (`validate`, `apply`, `generate`) y cada sonda por tipo es una unidad con propósito único y verificable; ningún script coordina sin interfaz comprobable | PASS |
| II. Orchestrator Pattern | `pensador` gobierna el ciclo; `Agent-SSD` ejecuta los comandos Speckit; `developer` implementa scripts; `plataformador` ejecuta el aprovisionamiento. Ningún agente actúa fuera de su fila | PASS |
| III. Specification-Driven Development | Artefactos en cascada: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `tasks.md`, `analyze.md`, `threat-model.md`, `converge.md` | PASS |
| IV. Copilot/Opencode Compatibility | Dos generadores desde una fuente única y `validate-parity` obligatorio; diferencia de capacidad no declarada = FAIL (FR-09, FR-15) | PASS |
| V. Observability and Monitoring | Estado explícito por dependencia, exit codes contratados, WARN con causa, matriz de capacidades versionada con fuente y versión | PASS |
| VI. Gestión de Dependencias Externas y proyect_ext | `proyect_ext/` como único destino de clones (FR-13); manifest versionado como única fuente (FR-01/FR-02); aprovisionamiento por tipo v2.1.0 aplicado tal cual | PASS |
| VII. Restricción de Paths por Tier | Los artefactos viven en `Documentacion/Agents_IA_TECH/`; el código de implementación en `scripts/` y `tests/` queda para el tier implementador | PASS |
| VIII. Fail-Open en Integraciones Externas | `apply` deja `degraded` con causa y no aborta el resto (FR-07); sin red → `desconocido` + WARN (edge case) | PASS |
| IX. Contenido Completo, Nunca Esqueletos | Cada artefacto se entrega con contenido real: sin marcadores diferidos, sin secciones vacías, tablas con filas reales | PASS |
| Genericidad y Ausencia de Rutas Absolutas | Manifest y plantilla usan rutas relativas o comandos resolubles; rutas absolutas solo en estado y archivos generados no versionados (NFR-06, SC-007) | PASS |

**Gate**: sin violaciones. No hay Complexity Tracking obligatorio (ver sección siguiente).

**Re-evaluación post-diseño (tras Phase 1)**: PASS. El diseño de contratos (`contracts/`) mantiene la forma canónica `mcp.servers.<nombre>`, no introduce rutas absolutas en artefactos versionados y no añade un cuarto verbo que rompa la separación leer/instalar/escribir.

## Project Structure

### Documentation (this feature)

```text
Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/
├── spec.md              # Especificación (input, 368 líneas)
├── requirements.md      # Requisitos consolidados de la spec
├── plan.md              # Este archivo (setup-plan.ps1 + speckit-plan)
├── research.md          # Phase 0 output (Decision / Rationale / Alternatives)
├── data-model.md        # Phase 1 output (entidades, campos, validaciones, transiciones)
├── quickstart.md        # Phase 1 output (escenarios ejecutables QS1-QS6)
├── contracts/           # Phase 1 output (contratos de CLI y esquemas JSON)
│   ├── cli-provisioning.contract.md
│   ├── dependencias-manifest.schema.json
│   ├── mcp-state.schema.json
│   ├── mcp-server-config.schema.json
│   └── capability-matrix.schema.json
├── analyze.md           # Phase 4 output (/speckit-analyze)
├── threat-model.md      # Phase 4 output (STRIDE, security-auditor)
├── converge.md          # Phase 5 output (/speckit-converge)
├── checklists/          # Checklist de calidad del ciclo
└── tasks.md             # Phase 3 output (/speckit-tasks, NO lo crea speckit-plan)
```

### Source Code (repository root)

```text
scripts/
├── mcp/
│   ├── generate-opencode.ps1      # Genera opencode.json desde manifest + estado
│   ├── generate-copilot.ps1       # Genera .vscode/mcp.json desde manifest + estado
│   ├── validate-parity.ps1        # Paridad de arneses + capacidades declaradas
│   ├── Get-ProvisioningState.ps1  # Sondas de solo lectura por tipo (validate)
│   ├── Invoke-ProvisioningApply.ps1 # Instalación/actualización explícita (apply)
│   └── Validate-Manifest.ps1      # Validación del manifest contra contrato
├── plataformador-bootstrap.ps1    # Bootstrap existente: pierde la escritura plana mcp.<nombre>
├── validar-mcps.ps1               # Validador existente: se alinea con validate-parity
├── validate-agents-skills.ps1     # VAL-07 (debe seguir FAIL: 0)
├── sync-mcp-graphify.ps1          # Ajuste: forma canónica mcp.servers.<nombre>
└── sync/indexing/run-indexing.ps1 # Ajuste: registra graphify en forma canónica

tests/
├── provisioning-validate.Tests.ps1     # US-1: detección de configuración mentirosa
├── provisioning-generate.Tests.ps1     # US-2: generación dual + idempotencia
├── provisioning-updates.Tests.ps1      # US-3: sonda de actualización por tipo
├── provisioning-apply.Tests.ps1        # US-4: apply fail-open y aislamiento
├── provisioning-capabilities.Tests.ps1 # US-5: matriz de capacidades y gaps
└── validate-no-hardcoded-paths.Tests.ps1 # Regresión de portabilidad (16/16)

dependencias-manifest.yml          # Única fuente de verdad (versionado)
.opencode/mcp-state.json           # Estado por workspace (no versionado)
opencode.json / .vscode/mcp.json   # Generados, no versionados
proyect_ext/                       # Clones externos (ignorado salvo manifest)
```

**Structure Decision**: el repositorio es un kit de configuración, no una aplicación: no se crea `src/<App>`. El código nuevo vive en `scripts/mcp/` (una responsabilidad por archivo, un verbo por script) y las pruebas en `tests/` con Pester. La documentación de la feature vive exclusivamente bajo `Documentacion/Agents_IA_TECH/`, cumpliendo el gate "Documentation First" que aplica `check-prerequisites.ps1`.

## Complexity Tracking

> Sección obligatoria del template; se completa aun sin violaciones para dejar constancia de las decisiones que añaden piezas.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Ninguna violación de la constitución | El diseño no requiere excepciones a los nueve principios | N/A — no aplica supresión de gates |
| Dos generadores (OpenCode y Copilot) en lugar de uno | Cada arnés tiene formato, claves y reglas de resolución de binario distintas; un único archivo con ramas por arnés mezcla dos contratos y rompe la verificación de paridad | Un solo generador parametrizado: la paridad se volvería una comparación interna del mismo código, no una verificación entre artefactos independientes (ADR-0014) |
| Tres verbos separados (`validate`/`apply`/`generate`) | Separa leer, instalar y escribir; `validate` debe ser seguro por defecto y `generate` no puede confiar en el estado sin verificar el binario | Un único comando con flags: obligaría a que la operación de solo lectura comparta código de escritura, violando NFR-01 |
| Estado en `.opencode/mcp-state.json` adicional al manifest | El manifest declara lo esperado; el estado registra lo observado en esta máquina (paths resueltos, SHA, último check) y no puede versionarse | Reusar el manifest como estado: mezclaría declaración con realidad, que es exactamente el defecto que esta spec corrige |

## Phase 0 outcome (resumen — detalle en `research.md`)

| Incógnita | Decisión |
|---|---|
| Autoridad de versión para código de terceros | SHA de branch head (`git ls-remote`), no semver ni `git status` |
| Esquema del manifest | `dependencias_externas[]` con `tipo_provisionamiento`, `requerido`, `version.autoridad` y autoridad por tipo |
| Cómo detecta `generate` que un binario resuelve | Sonda previa obligatoria (`validate`) + verificación puntual del comando resuelto antes de escribir la entrada |
| Paridad entre arneses | Comparación de conjuntos de servidores y nombres; capacidades justificadas por matriz versionada |
| Estrategia de actualización | `apply` explícito por tipo: git fetch/reset para clones, gestor de paquetes para MCP de workspace, fetch+checkout+build para build local |

## Phase 1 outcome (resumen — detalle en los artefactos)

| Artefacto | Contenido |
|---|---|
| `research.md` | Cinco decisiones R1-R5 con rationale y alternativas descartadas |
| `data-model.md` | `DependencyManifest`, `ExternalDependency`, `ProvisioningState`, `McpServerConfig`, `CapabilityMatrix` con validaciones y transiciones de estado |
| `contracts/` | Contrato de CLI de los tres verbos + cuatro esquemas JSON |
| `quickstart.md` | Seis escenarios ejecutables (QS1-QS6) con comando, salida esperada y criterio de éxito |

## Next Steps

1. `/speckit-tasks` → `tasks.md` desde `tasks-template.md` (fase por historia de usuario).
2. `/speckit-analyze` → `analyze.md` + `threat-model.md` (consistencia y STRIDE).
3. `/speckit-converge` → `converge.md` (estado real del código contra lo especificado).
4. `/speckit-implement` → implementación delegada a `developer` y `plataformador`.
