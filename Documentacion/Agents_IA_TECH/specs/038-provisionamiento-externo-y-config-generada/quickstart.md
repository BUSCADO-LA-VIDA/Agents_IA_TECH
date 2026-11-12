# Quickstart: validación de aprovisionamiento externo

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Phase**: 1 | **Date**: 2026-11-12

Guía de validación ejecutable. Cada escenario prueba un requisito de la spec y termina con un resultado observable. Los detalles de estructura están en `data-model.md` y los contratos en `contracts/`; aquí solo van comandos y salidas esperadas.

**Prerrequisitos**: workspace con `git`, PowerShell 7 (`pwsh`) y al menos un gestor de paquetes (`npm`); `.opencode/mcp-state.json` puede no existir (se crea en QS1); `dependencias-manifest.yml` presente en la raíz.

---

## QS1 — `validate` detecta la configuración mentirosa (SC-001)

**Prueba**: FR-01, FR-02, FR-06, FR-08 · NFR-01

```powershell
pwsh -NoProfile -File scripts/mcp/Get-ProvisioningState.ps1 -Json
$LASTEXITCODE
```

**Esperado**:
- Tabla/JSON con una entrada por dependencia del manifest; `context-mode` reportado con su `comando_resuelto` real o `missing` con causa.
- Exit code `1` porque hay una dependencia requerida sin binario resolubre.
- `git status --porcelain` sin cambios de configuración: `validate` solo escribió `.opencode/mcp-state.json` (ignorado).

**Falla si**: exit `0` con `context-mode` declarado contra un binario inexistente, o si aparece cualquier archivo versionado modificado.

---

## QS2 — `generate` produce configuración válida y sin la entrada rota (SC-002, SC-007)

**Prueba**: FR-08, FR-10, FR-11 · NFR-03, NFR-06

```powershell
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1 -DryRun
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1
pwsh -NoProfile -File scripts/mcp/generate-copilot.ps1
Get-Content opencode.json -Raw | ConvertFrom-Json | Select-Object -ExpandProperty mcp | Select-Object -ExpandProperty servers | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
Select-String -Path opencode.json,'.vscode/mcp.json' -Pattern 'mcp\.(?!servers)[A-Za-z0-9_-]+"' 
```

**Esperado**:
- `opencode.json` sin la entrada cuyo binario no resuelve; WARN con el nombre y el comando declarado que la omitió.
- Todas las entradas bajo `mcp.servers` con `type: "stdio"` y `command` resolubre.
- El `Select-String` no devuelve coincidencias: no hay forma plana `mcp.<nombre>` (SC-008).
- Abrir una sesión de OpenCode en el workspace arranca con los MCP requeridos operativos.

**Falla si**: aparece una entrada con `build/cli.js`, una clave `mcp.<nombre>` plana, o un `command` que no resuelve.

---

## QS3 — Idempotencia byte a byte (SC-003)

**Prueba**: NFR-02

```powershell
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1
(Get-FileHash opencode.json -Algorithm SHA256).Hash
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1
(Get-FileHash opencode.json -Algorithm SHA256).Hash
```

**Esperado**: los dos hashes son idénticos. Igual procedimiento para `.vscode/mcp.json`.

**Falla si**: el hash cambia entre corridas (timestamps u orden de claves no deterministas).

---

## QS4 — Paridad de arneses y capacidades declaradas (SC-004, SC-013)

**Prueba**: FR-09, FR-15

```powershell
pwsh -NoProfile -File scripts/mcp/validate-parity.ps1 -Json
$LASTEXITCODE
```

**Esperado**:
- Exit `0`: el conjunto de nombres bajo `mcp.servers` es idéntico en `opencode.json` y `.vscode/mcp.json`.
- Cada diferencia de capacidad aparece justificada en `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` con fuente y versión.
- Las cuatro inconsistencias declaradas tienen `spec_responsable` (`040`, `041`, `042`, `043`) ⇒ sin WARN de dueño.

**Falla si**: un servidor existe en un arnés y no en el otro, o una capacidad usada por un agente no está en la matriz (exit `1`).

---

## QS5 — `apply` sobre un clon: SHA al día y aislamiento (SC-006, SC-009)

**Prueba**: FR-04, FR-13, FR-14 · D3

```powershell
pwsh -NoProfile -File scripts/mcp/Invoke-ProvisioningApply.ps1 -Dependencia spec-kit -DryRun
pwsh -NoProfile -File scripts/mcp/Invoke-ProvisioningApply.ps1 -Dependencia spec-kit
git -C proyect_ext/spec-kit rev-parse HEAD
git ls-remote https://github.com/github/spec-kit refs/heads/main
Get-ChildItem -Path . -Recurse -Include AGENTS.md,CLAUDE.md,.mcp.json |
  Where-Object { $_.FullName -notlike '*proyect_ext*' -and $_.FullName -notlike '*node_modules*' }
```

**Esperado**:
- El SHA local del clon coincide con el SHA remoto de la rama seguida (o `al-dia` si ya coincidía).
- El `Get-ChildItem` no devuelve ningún `AGENTS.md`, `CLAUDE.md` ni `.mcp.json` proveniente de un clon (SC-009).
- `apply` no copió ni escribió archivos dentro del kit: solo operaciones git sobre `proyect_ext/spec-kit`.

**Falla si**: un `AGENTS.md` de terceros aparece bajo la raíz, o el SHA local difiere del remoto tras un `apply` que reportó `al-dia`.

---

## QS6 — Sin red: degradación explícita y no bloqueante (NFR-07, NFR-05)

**Prueba**: edge case "Sin red" · FR-07

```powershell
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -File scripts/mcp/Get-ProvisioningState.ps1 -Json
$sw.Elapsed.TotalSeconds
$LASTEXITCODE
```

Ejecutar con la red deshabilitada (o bloqueando el registro con un proxy inválido).

**Esperado**:
- Termina en menos de 15 s.
- Las dependencias remotas quedan `desconocido` con `causa` poblada (el esquema la exige para ese estado).
- Exit code ≠ 0 solo si un requerido queda indeterminado; nunca una excepción sin capturar ni un `ok` sin evidencia.

**Falla si**: la corrida se cuelga, lanza excepción no controlada, o reporta `ok`/`al-dia` sin sonda remota.

---

## Matriz de trazabilidad escenario → requisito

| Escenario | Requisitos cubiertos | Criterio de éxito |
|---|---|---|
| QS1 | FR-01, FR-02, FR-06, FR-08, NFR-01 | SC-001 |
| QS2 | FR-08, FR-10, FR-11, NFR-03, NFR-06 | SC-002, SC-007, SC-008 |
| QS3 | NFR-02 | SC-003 |
| QS4 | FR-09, FR-15 | SC-004, SC-010, SC-013 |
| QS5 | FR-04, FR-13, FR-14 | SC-006, SC-009 |
| QS6 | FR-07, NFR-05, NFR-07 | edge case "Sin red" |

## Regresión obligatoria al cerrar la feature

```powershell
pwsh -NoProfile -File scripts/validate-agents-skills.ps1   # FAIL: 0 (SC-011)
Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1   # 16/16 (SC-007)
Invoke-Pester tests/provisioning-*.Tests.ps1                # suites de US-1 a US-5
```
