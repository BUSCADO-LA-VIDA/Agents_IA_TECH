---
description: "Task list — aprovisionamiento externo por tipo y configuración generada"
---

# Tasks: Aprovisionamiento externo por tipo y configuración generada

**Input**: Documentos de diseño en `/Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/`

**Prerequisites**: `plan.md` (requerido), `spec.md` (requerido para historias de usuario), `research.md`, `data-model.md`, `contracts/`

**Tests**: Sí. La spec exige verificación medible (SC-001 a SC-013) y la constitución (Art. V y IX) no admite afirmaciones sin evidencia; cada historia de usuario lleva sus pruebas Pester escritas antes de la implementación.

**Organization**: tareas agrupadas por historia de usuario para permitir implementación y prueba independientes. Los identificadores de archivo usan rutas relativas a la raíz del repositorio.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: puede ejecutarse en paralelo (archivos distintos, sin dependencias de tareas incompletas)
- **[Story]**: historia de usuario a la que pertenece la tarea (US1-US5)
- Cada descripción incluye la ruta exacta del archivo

## Path Conventions

- Proyecto único (kit de configuración): `scripts/`, `tests/`, `Documentacion/` en la raíz del repositorio.
- No existe `src/<App>` para esta feature: el código nuevo vive en `scripts/mcp/`.
- Artefactos de la feature: `Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: infraestructura declarativa que consumen todos los verbos (manifest, plantillas versionadas, reglas de ignore, matriz de capacidades).

- [ ] T001 Configurar `.gitignore`: ignorar `opencode.json`, `.vscode/mcp.json`, `.opencode/mcp-state.json` y `proyect_ext/*`, re-incluyendo `!dependencias-manifest.yml` en `/.gitignore`
- [ ] T002 Escribir `dependencias-manifest.yml` con las 11 dependencias reales (ECC, spec-kit, context-mode, codebase-memory-mcp, markitdown, graphify, context7, github, playwright, tokenslayer, runtime) y su `version.autoridad` por tipo en `/dependencias-manifest.yml`
- [ ] T003 [P] Crear plantilla versionada de OpenCode con estructura, `default_agent`, `permission` y `plugin`, sin `mcp.servers` en `scripts/mcp/templates/opencode.template.json`
- [ ] T004 [P] Crear plantilla versionada de Copilot VS Code equivalente en `scripts/mcp/templates/copilot.template.json`
- [ ] T005 [P] Crear `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` con las 4 capacidades iniciales, fuente, versión verificada, prueba vacía y `spec_responsable` 040-043
- [ ] T006 [P] Crear `scripts/mcp/` con `.gitkeep` y verificar que ninguna ruta absoluta de máquina aparece en los archivos de T001-T005

**Checkpoint**: manifest, plantillas y matriz existen y son válidos como YAML/JSON; todavía ningún verbo los consume.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: código compartido que necesitan los tres verbos. Sin esta fase ninguna historia de usuario puede implementarse.

**⚠️ CRITICAL**: ninguna tarea de US-1 a US-5 puede empezar antes de completar esta fase.

- [ ] T007 Implementar `scripts/mcp/Provisioning.Common.ps1`: lectura del manifest, resolución de comando (`Get-Command`/`Test-Path`), escritura atómica (temporal + `Move-Item -Force`), salida tabla/`-Json` y helper `Write-Warn` con causa
- [ ] T008 Implementar `scripts/mcp/Validate-Manifest.ps1`: valida `dependencias-manifest.yml` contra `contracts/dependencias-manifest.schema.json`, nombres duplicados y autoridad de versión incompatible con el tipo; exit `2` si es inválido
- [ ] T009 [P] Escribir `tests/provisioning-foundation.Tests.ps1`: contrato de `Provisioning.Common` (escritura atómica no deja temporales) y de `Validate-Manifest` (tipo ausente ⇒ exit 2), con las funciones declaradas dentro de `BeforeAll`
- [ ] T010 [P] Escribir `tests/provisioning-foundation.Tests.ps1` (segundo `Describe`): el manifest real del repositorio valida con exit `0` y cubre el 100% de las dependencias declaradas (SC-005)
- [ ] T011 Conectar `Validate-Manifest.ps1` al inicio de los tres verbos y al bootstrap, de modo que un manifest inválido aborte antes de cualquier escritura

**Checkpoint**: manifest validado y utilidades compartidas probadas — las historias pueden empezar en paralelo.

---

## Phase 3: User Story 1 - Detectar configuración mentirosa antes de abrir la sesión (Priority: P1) 🎯 MVP

**Goal**: un comando de solo lectura que responde "¿están instaladas y en la versión/commit esperado?" con un exit code, sin escribir configuración.

**Independent Test**: `pwsh -NoProfile -File scripts/mcp/Get-ProvisioningState.ps1 -Json` devuelve exit `1` y nombra `context-mode` como ausente cuando su entrada apunta a `build/cli.js` inexistente, y no modifica ningún archivo versionado.

### Tests for User Story 1 ⚠️

> **NOTE: escribir estas pruebas primero y verificar que fallan antes de implementar**

- [ ] T012 [P] [US1] Prueba de contrato: entrada con `tipo_provisionamiento` desconocido ⇒ FAIL nombrando la dependencia (FR-02) en `tests/provisioning-validate.Tests.ps1`
- [ ] T013 [P] [US1] Prueba de integración: `context-mode` declarado contra un binario inexistente ⇒ exit `1` y estado `missing` con causa (SC-001) en `tests/provisioning-validate.Tests.ps1`
- [ ] T014 [P] [US1] Prueba: `validate` no modifica archivos versionados (`git status --porcelain` sin entradas de configuración) en `tests/provisioning-validate.Tests.ps1`

### Implementation for User Story 1

- [ ] T015 [US1] Implementar sondas `mcp-workspace` (registro del gestor) y `entorno` (`runtime`) en `scripts/mcp/Get-ProvisioningState.ps1`
- [ ] T016 [US1] Implementar sonda `branch-head` con `git rev-parse HEAD` vs `git ls-remote refs/heads/<rama_seguida>`, informando `detached` y `shallow` sin fallar en `scripts/mcp/Get-ProvisioningState.ps1`
- [ ] T017 [US1] Implementar sonda `release+artefacto` para `mcp-build-local` verificando el artefacto compilado declarado en `scripts/mcp/Get-ProvisioningState.ps1`
- [ ] T018 [US1] Persistir el estado con los siete valores admitidos, `causa` obligatoria en `degraded`/`desconocido` y `requerido` copiado del manifest en `.opencode/mcp-state.json`
- [ ] T019 [US1] Implementar la tabla legible por defecto y la salida `-Json` con `{ "dependencias": { ... } }` en `scripts/mcp/Get-ProvisioningState.ps1`
- [ ] T020 [US1] Contratar los exit codes `0`/`1`/`2` y el WARN de opcional ausente sin cambio de código de salida en `scripts/mcp/Get-ProvisioningState.ps1`

**Checkpoint**: US-1 funciona sola — con `validate` se detecta la configuración mentirosa actual sin escribir nada (MVP entregable).

---

## Phase 4: User Story 2 - Generar la configuración del arnés desde la realidad de la máquina (Priority: P1)

**Goal**: un clon + `generate` produce `opencode.json` y `.vscode/mcp.json` con el mismo conjunto de servidores, sin entradas cuyo binario no resuelve, con paridad verificada.

**Independent Test**: `generate-opencode.ps1` y `generate-copilot.ps1` generan ambos archivos y `validate-parity.ps1` devuelve exit `0`; una segunda ejecución produce hashes idénticos y ninguna clave plana `mcp.<nombre>`.

### Tests for User Story 2 ⚠️

- [ ] T021 [P] [US2] Prueba de contrato: dependencia `missing` no se emite y produce WARN con nombre y comando declarado (FR-08) en `tests/provisioning-generate.Tests.ps1`
- [ ] T022 [P] [US2] Prueba de idempotencia: dos `generate` consecutivos dan el mismo SHA256 (SC-003) en `tests/provisioning-generate.Tests.ps1`
- [ ] T023 [P] [US2] Prueba de forma canónica: ningún archivo generado contiene `mcp.<nombre>` plano y toda entrada declara `type: "stdio"` (SC-008) en `tests/provisioning-generate.Tests.ps1`
- [ ] T024 [P] [US2] Prueba de paridad: servidor presente en un solo arnés ⇒ `validate-parity` exit `1` (SC-004) en `tests/provisioning-generate.Tests.ps1`

### Implementation for User Story 2

- [ ] T025 [US2] Implementar `scripts/mcp/generate-opencode.ps1`: plantilla + estado, omisión de no resolubles, preservación de claves ajenas a `mcp.servers`, escritura atómica
- [ ] T026 [US2] Implementar `scripts/mcp/generate-copilot.ps1` con la misma fuente y equivalencia de campos
- [ ] T027 [US2] Implementar `scripts/mcp/validate-parity.ps1`: conjunto de nombres, campos de ejecución por servidor y cruce con la matriz de capacidades
- [ ] T028 [US2] Retirar la escritura de la forma plana `mcp.<nombre>` de `Ensure-OpenCodeMcp` y `Configure-Graphify` en `scripts/plataformador-bootstrap.ps1`, delegando en los generadores
- [ ] T029 [US2] Ajustar `scripts/sync-mcp-graphify.ps1` y `scripts/sync/indexing/run-indexing.ps1` para escribir `mcp.servers.graphify`
- [ ] T030 [US2] Añadir `-DryRun` a ambos generadores mostrando el diff de claves por servidor sin escribir

**Checkpoint**: clon + `generate` deja el workspace con configuración correcta y paridad verificada; la sesión arranca con los MCP requeridos operativos (SC-002).

---

## Phase 5: User Story 3 - Saber si el código de terceros integrado está al día (Priority: P2)

**Goal**: `validate` reporta `ok`/`al-dia`/`desactualizado` con SHA, versión y fecha, comparando contra el remoto real.

**Independent Test**: para `ECC`, `spec-kit` y `context-mode`, la salida de `validate` coincide con `git ls-remote` y con el registro del gestor consultados a mano (SC-006), dentro del presupuesto de tiempo de NFR-07.

### Tests for User Story 3 ⚠️

- [ ] T031 [P] [US3] Prueba: clon con SHA local distinto del remoto ⇒ `desactualizado` con `ultimo_sha`, `sha_remoto` y `ultimo_check` en `tests/provisioning-updates.Tests.ps1`
- [ ] T032 [P] [US3] Prueba: `version_instalada` distinta de `version_ultima` ⇒ `desactualizado` (caso `context-mode` 1.0.169 vs 2.1.0) en `tests/provisioning-updates.Tests.ps1`
- [ ] T033 [P] [US3] Prueba de presupuesto: sonda sin red termina en menos de 15 s y deja `desconocido` con causa (NFR-07) en `tests/provisioning-updates.Tests.ps1`

### Implementation for User Story 3

- [ ] T034 [US3] Implementar consulta a `version.upstream_api` por tipo (registro npm, PyPI/uv, `git ls-remote`, release del repo) en `scripts/mcp/Get-ProvisioningState.ps1`
- [ ] T035 [US3] Clasificar el estado comparando declarado contra observado y registrar `fuente` consultada en `.opencode/mcp-state.json`
- [ ] T036 [US3] Aplicar timeouts por sonda (60 s con red, 15 s de corte sin red) y degradar a `desconocido` sin bloquear la sesión
- [ ] T037 [US3] Reportar en la tabla la diferencia concreta (`actual → latest`) y el SHA corto para clones

**Checkpoint**: US-1 y US-3 juntas responden "¿está al día?" con evidencia remota, sin instalar nada.

---

## Phase 6: User Story 4 - Actualizar sin contaminar el contexto del agente (Priority: P2)

**Goal**: `apply` actualiza por tipo sin copiar nada al kit, deja `degraded` con causa si falla una dependencia y no aborta el resto.

**Independent Test**: `Invoke-ProvisioningApply.ps1 -Dependencia spec-kit` deja el SHA local igual al remoto sin que aparezca ningún `AGENTS.md`/`CLAUDE.md`/`.mcp.json` de terceros bajo la raíz (SC-009).

### Tests for User Story 4 ⚠️

- [ ] T038 [P] [US4] Prueba: build local fallido ⇒ estado `degraded` con causa, resto de dependencias continúa (FR-07/FR-16) en `tests/provisioning-apply.Tests.ps1`
- [ ] T039 [P] [US4] Prueba: tras `apply` de un clon no existe `AGENTS.md` de terceros bajo la raíz y el clon sigue en `proyect_ext/` (SC-009) en `tests/provisioning-apply.Tests.ps1`
- [ ] T040 [P] [US4] Prueba: `-DryRun` no ejecuta ninguna escritura ni operación git de actualización en `tests/provisioning-apply.Tests.ps1`

### Implementation for User Story 4

- [ ] T041 [US4] Implementar `scripts/mcp/Invoke-ProvisioningApply.ps1` con `-Dependencia`, `-DryRun` y `-Force`, sin efecto secundario desde `validate` ni `generate`
- [ ] T042 [US4] Implementar actualización de clones: `fetch` + `reset --hard <rama_seguida>`, `checkout` de tag si `detached`, `--unshallow` si shallow, sin copiar al kit
- [ ] T043 [US4] Implementar instalación `mcp-workspace` con el gestor declarado (`npm`, `pip`, `uv`) y `mcp-build-local` con build verificado por artefacto
- [ ] T044 [US4] Verificación de runtime mínimo para `entorno` (por ejemplo `context-mode` exige Node `>=24.15.0`) con WARN explícito, sin instalar

**Checkpoint**: el workspace se actualiza por tipo y el contexto del agente queda limpio de clones de terceros.

---

## Phase 7: User Story 5 - Publicar la diferencia de capacidades entre arneses (Priority: P3)

**Goal**: la matriz de capacidades es la fuente de verdad de las diferencias entre arneses y el validador la hace cumplir.

**Independent Test**: añadir una capacidad usada por un agente y ausente de la matriz hace que `validate-parity` devuelva exit `1`; una fila sin `spec_responsable` produce WARN (SC-013).

### Tests for User Story 5 ⚠️

- [ ] T045 [P] [US5] Prueba: capacidad usada y no declarada ⇒ exit `1` (FR-15.1) en `tests/provisioning-capabilities.Tests.ps1`
- [ ] T046 [P] [US5] Prueba: fila sin `spec_responsable` ⇒ WARN sin cambiar el exit code (FR-15.2) en `tests/provisioning-capabilities.Tests.ps1`
- [ ] T047 [P] [US5] Prueba: capacidad `no-soportado` no se emite como clave y se reporta WARN (FR-15.4) en `tests/provisioning-capabilities.Tests.ps1`

### Implementation for User Story 5

- [ ] T048 [US5] Completar `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` con las 4 capacidades, mecanismo por arnés, fuente, versión verificada y `spec_responsable` (040-043)
- [ ] T049 [US5] Validar la matriz contra `contracts/capability-matrix.schema.json` y deducir el estado de corrección desde `spec_responsable` + `prueba`
- [ ] T050 [US5] Implementar en `scripts/mcp/validate-parity.ps1` el cruce capacidad usada por agente ⇒ fila declarada, y el WARN de fila sin dueño

**Checkpoint**: las cuatro inconsistencias declaradas tienen dueño (040-043) y cualquier capacidad nueva sin declarar rompe el validador.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: documentación de referencia, regresión completa y cierre del ciclo.

- [ ] T051 [P] Escribir `Documentacion/Agents_IA_TECH/provisionamiento-externo.md`: matriz de sondas por tipo, comandos concretos y contrato de exit codes (FR-17, SC-012)
- [ ] T052 [P] Ejecutar `quickstart.md` QS1-QS6 y registrar el resultado de cada escenario en el mismo archivo
- [ ] T053 [P] Actualizar `Documentacion/Agents_IA_TECH/00-indice.md` y `pendientes-implementacion.md` con el estado real de la 038
- [ ] T054 Regresión de agentes y skills: `pwsh -NoProfile -File scripts/validate-agents-skills.ps1` con `FAIL: 0` (SC-011)
- [ ] T055 Regresión de portabilidad: `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` con 16/16 (SC-007)
- [ ] T056 Ejecutar las cinco suites `tests/provisioning-*.Tests.ps1` completas y registrar el conteo PASS/FAIL
- [ ] T057 `/speckit-analyze` y `/speckit-converge` sobre el estado implementado, actualizando `analyze.md`, `threat-model.md` y `converge.md`
- [ ] T058 Commit convencional con autorización explícita del usuario: `feat(provisioning): spec-038 external provisioning by type and generated config`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias; puede empezar de inmediato.
- **Foundational (Phase 2)**: depende de Setup; BLOQUEA todas las historias.
- **User Stories (Phase 3-7)**: dependen de Foundational. US-1 y US-2 pueden ir en paralelo; US-3 depende de US-1 (misma sonda), US-4 depende de US-1 (estado) y US-5 depende de US-2 (validador de paridad).
- **Polish (Phase 8)**: depende de todas las historias que se quieran entregar.

### User Story Dependencies

- **US-1 (P1)**: sin dependencias tras Phase 2 — entrega el MVP.
- **US-2 (P1)**: sin dependencias tras Phase 2 — puede ir en paralelo con US-1; comparte el estado que produce `validate`, por lo que conviene ejecutar `validate` antes de validar la paridad.
- **US-3 (P2)**: extiende la sonda de US-1; requiere T015-T017.
- **US-4 (P2)**: requiere el estado de US-1 (T018) para decidir qué actualizar.
- **US-5 (P3)**: requiere `validate-parity` de US-2 (T027).

### Within Each User Story

- Las pruebas se escriben y FALLAN antes de la implementación.
- El manifest y las plantillas antes que los generadores.
- `validate` antes de `apply` (el estado es la entrada de la decisión).
- `generate` antes de `validate-parity` (no se valida paridad de archivos inexistentes).
- Cada historia se valida de forma independiente antes de pasar a la siguiente prioridad.

### Parallel Opportunities

- T003, T004, T005, T006 en paralelo (archivos distintos sin dependencias).
- T009 y T010 en paralelo (mismos archivos de prueba pero `Describe` distintos, coordinados por el mismo autor).
- T012, T013, T014 en paralelo (pruebas de US-1).
- T021, T022, T023, T024 en paralelo (pruebas de US-2).
- T031, T032, T033 en paralelo (pruebas de US-3).
- T038, T039, T040 en paralelo (pruebas de US-4).
- T045, T046, T047 en paralelo (pruebas de US-5).
- T051, T052, T053 en paralelo (documentación distinta).

---

## Parallel Example: User Story 2

```powershell
# Lanzar juntas las pruebas de US-2 (archivos de prueba independientes por caso)
Task: "Prueba de contrato: dependencia missing no se emite (FR-08) en tests/provisioning-generate.Tests.ps1"
Task: "Prueba de idempotencia: dos generate dan el mismo SHA256 (SC-003)"
Task: "Prueba de forma canónica: sin mcp.<nombre> plano y type stdio (SC-008)"
Task: "Prueba de paridad: servidor en un solo arnés ⇒ exit 1 (SC-004)"

# Luego, los generadores en paralelo (archivos distintos):
Task: "Implementar scripts/mcp/generate-opencode.ps1"
Task: "Implementar scripts/mcp/generate-copilot.ps1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1 (Setup) y Phase 2 (Foundational).
2. Completar Phase 3 (US-1).
3. **PARAR y VALIDAR**: `Get-ProvisioningState.ps1 -Json` detecta el defecto de `context-mode` con exit `1` sin escribir configuración (SC-001).
4. Demostrar el gate antes de generar configuración.

### Incremental Delivery

1. Setup + Foundational → base lista.
2. US-1 → gate de solo lectura (MVP).
3. US-2 → configuración generada con paridad verificada.
4. US-3 → sonda de actualización con evidencia remota.
5. US-4 → actualización por tipo sin contaminar el contexto.
6. US-5 → matriz de capacidades declarada y validada.
7. Cada incremento deja el repositorio en verde (`validate-agents-skills.ps1` FAIL: 0, portabilidad 16/16).

### Parallel Team Strategy

1. El equipo completa Setup + Foundational.
2. Con Foundational listo: una persona toma US-1 y otra US-2.
3. Al cerrar US-1 y US-2: US-3 y US-4 en paralelo; US-5 después de `validate-parity`.
4. La documentación de cierre (T051-T053) acompaña cada incremento, no se acumula al final.

---

## Notes

- [P] tasks = archivos distintos, sin dependencias.
- La etiqueta [Story] mapea cada tarea a una historia para trazabilidad con `spec.md` y `quickstart.md`.
- Las pruebas se declaran dentro de `BeforeAll` en Pester 6.2.0: las funciones de nivel de archivo no se resuelven.
- Cada tarea de verificación entrega evidencia: comando ejecutado y resultado, no una afirmación.
- No se crea commit sin autorización explícita del usuario (regla vinculante del repositorio).
- Evitar: tareas vagas, dos tareas escribiendo el mismo archivo en paralelo, dependencias cruzadas que rompan la independencia de las historias.
