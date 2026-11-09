# CHANGELOG — Agents_IA_TECH

> Registro de cambios del kit transversal Agents_IA_TECH. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y [Semantic Versioning](https://semver.org/lang/es/).

---

## [1.0.0] — 2026-11-09 — Spec 039: Eliminar rutas hardcoded y portabilidad del kit

### Added
- **Patrón de rutas portables (ADR-039)**: Tres patrones complementarios para referenciar rutas en documentación, scripts y bootstrap:
  1. **Documentación**: Variables `$KitPath` / `$ProjectRoot` con comentario obligatorio `# <- ajusta a tu ruta`
  2. **Scripts PowerShell**: `$PSScriptRoot` + parámetros `-RootPath` / `-KitPath` con defaults seguros
  3. **Bootstrap/CLI**: Parámetros con defaults derivados de `$PSScriptRoot`, incluyendo nuevo flag `-CheckHardcodedPaths`
- **Validación automatizada**: Test Pester `tests/validate-no-hardcoded-paths.Tests.ps1` que escanea patrones prohibidos (`C:\Proyectos`, `D:\`, `/home/`, `/Users/`) en todos los archivos distribuibles con excepción para comentarios documentando variables.
- **Bootstrap flag `-CheckHardcodedPaths`**: Escanea proyecto destino (`Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`) y reporta rutas absolutas con archivo:línea y contenido ofensivo.
- **Plantillas de referencia**: Headers estándar para scripts PowerShell/Bash, bloques de variables en README, parameter blocks para bootstrap.
- **Comandos de validación**: Reference card con grep/Select-String manuales, CI workflow YAML, y uso del bootstrap con validación.

### Changed
- **README.md**: Sección "sync-kit local" actualizada para usar `$KitPath` variable en lugar de `C:\Proyectos\Agents_IA_TECH` hardcodeado. Verificación completa de cero rutas absolutas.
- **AGENTS.md**: Eliminadas referencias a `C:\Proyectos\Agents_IA_TECH` y `C:\Proyectos\opencode`; reemplazadas por `$KitPath` y rutas relativas `./.github/agents/`, `./.opencode/agents/`.
- **Scripts del kit** (`sync-agents.ps1`, `scripts/*.ps1`): Reemplazadas rutas hardcodeadas por `$PSScriptRoot` / parámetros; agregado header comment estándar `# $KitPath = $PSScriptRoot`.
- **plataformador-bootstrap.ps1**: Agregado parámetro `[switch]$CheckHardcodedPaths` con lógica de escaneo y reporte; logging estructurado de parámetros usados (SEC-05); validación de subtree paths (SEC-03); detección de ejecución como Administrador (SEC-04).

### Removed
- **Artefactos de desarrollo externos**: Eliminados `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md` (contenían rutas de máquina de desarrollo, no distribuibles).

### Security
- **SEC-01**: Cero rutas absolutas en archivos distribuibles (validado por test Pester)
- **SEC-02**: Scripts usan `$PSScriptRoot`/parámetros, nunca rutas literales
- **SEC-03**: Bootstrap valida que `$KitPath`/`$RootPath` son directorios locales existentes y seguros (subtree check)
- **SEC-04**: Bootstrap detecta y advierte si se ejecuta con privilegios de Administrador
- **SEC-05**: Bootstrap emite log estructurado con parámetros usados (auditoría)
- **SEC-06**: Test de regresión emite lista de archivos escaneados (verbose mode)
- **SEC-07**: Artefactos de desarrollo eliminados y no distribuidos (`.gitignore` para `.specify/` runtime)
- **SEC-08**: `-CheckHardcodedPaths` con límites de rendimiento (timeout, max files, exclusiones)

### Documentation
- **Spec 039**: spec.md, plan.md, tasks.md, analyze.md, converge.md
- **ADR-039**: Patrón de Rutas Portables para Documentación y Scripts del Kit (Accepted)
- **Threat Model**: STRIDE analysis con 15 threats, 8 security requirements derivados
- **Quickstart**: 4 escenarios de validación (portabilidad, bootstrap check, README copiable, limpieza externa)
- **00-indice.md**: Entrada 039 añadida con estado **Aprobada — v1.0.0**

---

## [0.38.0] — 2026-11-07 — Spec 038: Provisionamiento Externo y Configuración Generada (Borrador)

### Added
- Spec 038 en estado Borrador: taxonomía de aprovisionamiento (5 tipos), sondas de versión, `.opencode/mcp-state.json`, verbos `validate`/`apply`/`generate`, generación dual OpenCode + Copilot con `validate-parity`.
- ADR-0014: Configuración Generada y Provisionamiento por Tipo.
- Constitution v2.1.0 enmienda (propuesta).

### Decisions
- Autoridad de versión `kit-integrado` = branch head (SHA), no release tag.
- `opencode.json` no se versiona: plantilla + generador dual.
- Clones externos (ECC, spec-kit) viven fuera de la raíz del workspace.
- Integración de código tercero = asistida por IA, no copia (separado en spec 039).

---

## [0.37.0] — 2026-11-05 — Spec 037: MCP .gitignore Fix (Implementada)

### Added
- Script `scripts/sync-gitignore.ps1` con catálogo de 6 bloques (dependencias, build, backups, caches, logs, sistema/editor).
- Test `tests/sync-gitignore.Tests.ps1` (14 asserts, PASS=14 FAIL=0).
- Operación idempotente y reversible (`-Sets`, `-WhatIf`, `-RemoveBlock`, `-PruneRules`, `-OnlyExcluded`, `-AllGitignore`).

### Fixed
- Patrón `**/.gitignore` no matcheaba `.gitignore` de raíz.
- Recorrido recursivo escribía en 196 `.gitignore` de terceros (revertido con `-RemoveBlock -PruneRules`).
- Reversión no entendía formato histórico bloque graphify (sin separador cierre).
- `*.log` ignoraba `.bootstrap-audit.log` (corregido con `!.bootstrap-audit.log`).

### Verified
- Segunda corrida en maestro y destino → `Archivos actualizados: 0`.
- `git ls-files -i -c --exclude-standard` sin regresiones.

---

## [0.36.0] — 2026-11-03 — Spec 036: Sync Kit Paridad Motor (Implementación Completada)

### Added
- Orquestador único `scripts/sync-kit.ps1` + capas de dominio (`sync/transversal`, `sync/kit-files`, `sync/skills`, `sync/rules`, `sync/prompts`, `sync/workflows`, `sync/agents`, `sync/mcp`, `sync/constitutions`, `sync/indexing`, `sync/docs`, `sync/kit-block`, `sync/externals`, `sync/backup-prune`).
- Tests: `tests/kit-sync-merge.ps1` (72 asserts), `tests/fixtures/baseline-036.md`.
- Backup pruning seguro (`sync-backup-prune.ps1`) que no borra backup previo del operador.
- Graphify con única entrada apuntando al grafo del destino.

### Fixed
- **D1**: Poda de `.kit-backup` borraba backup previo del operador.
- **D2/D4**: Ausencia de capas para skills, rules, prompts, workflows, copilot-instructions.md, 5 tests del kit.
- **D3**: `Test-AuditLogIntegrity` con falso negativo permanente (payload con `prevHash`, cadena no lineal, round-trip JSON altera `timestamp`).
- **D5**: Doble entrada graphify con ruta del maestro en el destino.

### Decision
- `scripts/sync-kit.ps1` es el orquestador estable; `sync-kit-agents.ps1` absorbido (marca `[021-DEPRECATED]` retirada).

### Known Debt
- Divergencia EOL (CRLF vs LF) en `.github/rules` y `tests/` al comparar bruto; al normalizar a LF, paridad 100%. Recomendación: alinear `core.autocrlf` + `.gitattributes` en repo maestro.

---

## [0.35.0] — 2026-11-01 — Spec 035: Consolidación Backlog (Ciclo SSD+Speckit Completo)

### Added
- Propagación del arranque por defecto vía `scripts/sync-kit.ps1` (D-07..D-09, FR-14..FR-19, CA-12..CA-15).
- `opencode.json` L5: `default_agent: "pensador"` propagado por sync.
- Sección arranque en `AGENTS.md` L117 envuelta en `KIT-BLOCK`.
- `Ensure-OpenCodeDefaultAgent` en `plataformador-bootstrap.ps1`.
- `VAL-10` en `scripts/validate-agents-skills.ps1`.
- `Compare-KitFileState`/`Merge-OpenCodeConfig`/`Merge-KitBlock`/whitelist en `scripts/sync-kit.ps1`.
- `.gitignore` con `opencode.json.bak-*` y `AGENTS.md.bak-*`.

---

## [0.34.0] — 2026-10-29 — Spec 034: Arranque Agentes por Defecto (En Proceso/Especificada)

### Added
- Pipeline `pipeline-kb.md` creado para propagación via sync-kit.
- Test `tests/harness-default.ps1` valida contrato arranque (paridad y valor válido).
- `opencode.json` declara `default_agent: "pensador"`.
- Sección en `README.md` y `AGENTS.md` (KIT-BLOCK).

---

## [0.33.0] — 2026-10-29 — Spec 030: Whitelist Contextual por Tipo de Proyecto (Especificada)

### Added
- ADR-0013 Accepted: Whitelist de escritura contextual al tipo de proyecto (`kit` | `consumidor`).
- Agentes replanteados como orquestadores delgados con capacidades en skills declaradas en frontmatter.
- 23 FR, 12 CA, 6 NFR, 66 tasks.
- Artefactos: spec.md (1.1.0), plan.md (1.1.0), tasks.md (1.2.0), analyze.md (1.0.0), threat-model.md (1.0.0), checklists/requirements.md (1.0.0), converge.md.
- NOTA-CONSOLIDACION.md con consolidación parcial.

### Decisions Pending (Bloquean Tasks)
- D-01: `usuario-preferencias` vs Constitution → bloquea T020
- D-02: `plataformador` fragmentar → task no creada
- D-03: `gitflow` retirar o delgado → bloquea T021
- D-04 Resuelta: `Agent-SSD` y `pensador` NO se fusionan

### Technical Debts (Registradas en Converge)
- 030-DD-01: FR-11 sin cambio `C-NN` en el plan
- 030-DD-02: `terminal`/`execute` sin acotar en el consumidor
- 030-DD-03: Anti-fuga del marcador sin test permanente
- 030-DD-04: Skills nuevas sin validación de contenido; IP SSH propagable
- 030-DD-05: "workspace completo" del `developer` en kit sin denylist

---

## [0.32.0] — 2026-10-18 — Spec 031: Permisos, Dominio y Delegación de Agentes (Finalizada)

### Added
- Contrato único verificable de dominio de escritura, prohibiciones absolutas, delegación y autorización `[S]`/`[N]`/`[C]`.
- Sesión SSH única por servidor reutilizable y auditada.
- 24 FR, 7 NFR, 7 historias usuario, 12 CA (CA-01..CA-12 todos cumplidos).
- Matriz de permisos por operación y por agente.

### Verified
- `scripts/validate-agents-skills.ps1` → `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0.
- `tests/validate-agents-skills.Tests.ps1`: 20/20 verde.
- `tests/agents-parity.ps1`: exit code 0, fixture negativo detecta divergencia.
- Paridad lograda: 13 agentes con cuerpo idéntico en `.github/agents/` y `.opencode/agents/`.

### Artifacts
- Skill `threat-modeling` creada en ambos arneses.
- `tier` corregido en `pensador`, `security-auditor`, `usuario-preferencias`.
- `testing` reemplazada por `tdd-workflow` + `verification-loop` en `developer`.
- `dominio_check` y protocolo autorización `[S]`/`[N]`/`[C]` en ambos arneses.
- `plataformador` restaurado a versión finalizada (474 líneas, `5513d37`).
- 8 agentes nivelados a estructura Regla 2 (38 violaciones resueltas).

---

## [0.31.0] — 2026-10-15 — Spec 028: Public Docs Routing (Especificada)

### Added
- Routing docs públicas a `src/<App>/docs/` y README a `src/<App>/README*.md`.
- Delegación `documentador` → `developer`.
- ADR-0011: Public Docs Routing.
- Skill `public-documentation`.
- Ciclo Speckit completo (spec/plan/tasks/analyze/converge).

---

## [0.30.0] — 2026-10-10 — Spec 027: Patrón Estructura Proyecto (En Proceso)

### Decision
- `021-estructura-inicial-apps-nuevas` = OPERATIVA (8 tasks pendientes creación apps).
- `027-patron-estructura-proyecto` = PATRÓN NORMATIVO al que 021 referenciará.

---

## [0.29.0] — 2026-10-05 — Spec 026: Agente Developer Único (Especificada)

### Status
- Ciclo Speckit completo (spec/plan/tasks/analyze/converge).
- **Implementación NO ejecutada** — converge dice "Converge finalizado, listo para implementación".
- Unificar implementadores en un agente `developer` con skills especializadas y context7.

---

## [0.28.0] — 2026-10-01 — Spec 025: Actualización Herramientas Externas (En Proceso)

### Objective
- Hook diario y CI semanal para `upgrade_framework` y propagación vía sync-kit.

---

## [0.27.0] — 2026-09-25 — Spec 024: Hooks Gobernanza Determinismo (En Proceso)

### Objective
- Hooks pre-commit, gate PR, checksum Speckit y determinismo de harnesses.

---

## [0.26.0] — 2026-09-20 — Spec 023: ECC Workflows (En Proceso)

### Objective
- Workflows CI propios derivados de ECC.

---

## [0.25.0] — 2026-09-18 — Spec 022: ECC Integration (Activa)

### Objective
- Integración ECC por copia con espejo por harness via script.

---

## [0.24.0] — 2026-09-15 — Spec 021: Sync Kit Agents (En Proceso)

### Objective
- Orquestador de sync por capas (Stage temporal + clean+replace + plataformar).

---

## [0.23.0] — 2026-09-12 — Spec 020: MCP Config Operativa (Finalizado)

### Objective
- Configuración MCP operativa verificada en vivo (baseline).

---

## [0.22.0] — 2026-09-10 — Spec 018: Pendientes Estados Scrum (En Proceso)

### Objective
- Estados Scrum por agente y whitelist Art-VII por tier.

---

## [0.21.0] — 2026-09-08 — Spec 017: Pendientes Implementación por App (En Proceso)

### Objective
- Archivo vivo por proyecto con estado de tareas y responsables.

---

## [0.20.0] — 2026-09-05 — Spec 016: SSD Enforcement / Detectar Install vs Update (En Proceso)

### Objective
- Forzar flujo SSD+Speckit vía agentes y guardkeeper en pensador.
- Detección instalación vs actualización del KIT.

---

## [0.19.0] — 2026-09-01 — Spec 015: MCP Integration Flow / Sync Kit Bootstrap (Activa / En Proceso)

### Objective
- Flujo SSD finalizado, spec lista para producción (MCP Integration Flow).
- Bootstrap y sincronización del kit transversal (Sync Kit Bootstrap).

---

## [0.18.0] — 2026-08-25 — Specs 012-014: ECC Integration Lifecycle / Manifest Versionado (En Proceso)

### Objective
- Ciclo de vida install/update/validate/uninstall con `ecc-sync.ps1`.
- Estándar manifiesto versionado y sincronización entre módulos.
- Integración selectiva ECC como proyecto externo en `proyect_ext/ECC`.
- Puente ECC ↔ MCPs y contrato de intercambio.
- Migración `.env.mcp` → `mcp-configs/mcp-servers.json`.

---

## [0.17.0] — 2026-08-20 — Spec 011: Bootstrap Invokes Upgrade Framework (Activa)

### Objective
- Bootstrap delega sync dependencias externas en `upgrade_framework` (fail-open, no hardcoded URLs).

---

## [0.16.0] — 2026-08-15 — Spec 010: Secret Leak Remediation (Finalizada)

### Fixed
- API key filtrada en `temp_opencode_output.txt` eliminada del historial Git.
- `.gitignore` y `.gitleaks.toml` configurados (allowlist gitleaks, rotación de clave, verificación `gitleaks detect`).

---

## [0.15.0] — 2026-08-10 — Spec 009: MCP Update Lifecycle (Archivada/Fusionada)

### Status
- Fusionada en `020-mcp-config-operativa` (fase D, spec 035).

---

## [0.14.0] — 2026-08-05 — Spec 006: Post-Platforming Speckit (En Proceso)

### Objective
- Flujo post-plataformado → speckit (3 escenarios) + re-indexación + Constitution por proyecto + memoria auto/manual.

---

## Versiones Anteriores (Pre-Changelog Formal)

| Versión | Fecha | Hito |
|---------|-------|------|
| 0.13.0 | 2026-07-15 | Spec 002-T035: Constitution 3 niveles + bootstrap sincroniza |
| 0.12.0 | 2026-07-01 | Spec 002: Plataforma Bootstrap Instalador Único (ADR-0003) |
| 0.11.0 | 2026-06-25 | Kit creado: agentes, skills, prompts, MCPs base |
| 0.10.0 | 2026-06-20 | Estructura dual harness (`.github/` + `.opencode/`) |
| 0.9.0 | 2026-06-15 | Primeros agentes: pensador, arquitecto, documentador, developer |
| 0.8.0 | 2026-06-10 | Speckit integrado (specify, plan, tasks, analyze, converge, implement) |
| 0.7.0 | 2026-06-05 | MCPs base: context-mode, codebase-memory-mcp, markitdown |
| 0.6.0 | 2026-06-01 | Constitution v1.0 + agentes Tier Documental |
| 0.5.0 | 2026-05-25 | Repo maestro GitHub: `BUSCADO-LA-VIDA/Agents_IA_TECH` |
| 0.4.0 | 2026-05-20 | Skills globales compartidas (`.github/skills/`) |
| 0.3.0 | 2026-05-15 | OpenCode support (`.opencode/`) |
| 0.2.0 | 2026-05-10 | GitHub Copilot agents (`.github/agents/`) |
| 0.1.0 | 2026-05-01 | Inicio del kit Agents_IA_TECH |

---

## Convenciones de Versionado

| Tipo | Formato | Cuándo |
|------|---------|--------|
| **Major** | `X.0.0` | Breaking changes en patrones de portabilidad, estructura de specs, o contratos de agente |
| **Minor** | `0.Y.0` | Nueva spec aprobada (converge completado), feature completa implementada |
| **Patch** | `0.0.Z` | Hotfixes, correcciones de bugs, actualizaciones de docs, limpieza de artefactos |

**Específico para Specs**:
- `0.x.x` = Pre-aprobación (Borrador → Plan → Tasks → Analyze → Converge)
- `1.0.0` = Converge completado, spec **Aprobada** para producción
- `1.x.x` = Post-implement (patches, hotfixes tras implementación)
- `2.0.0` = Breaking changes en patrones de portabilidad

---

## Referencias

- **Repositorio**: `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`
- **Índice**: `Documentacion/Agents_IA_TECH/00-indice.md`
- **Specs**: `Documentacion/Agents_IA_TECH/specs/`
- **ADRs**: `Documentacion/Agents_IA_TECH/arquitectura/adr/`
- **Constitution**: `.specify/memory/constitution.md` (nivel 1 kit) → `Documentacion/Agents_IA_TECH/.specify/constitution.md` (nivel 2 app)