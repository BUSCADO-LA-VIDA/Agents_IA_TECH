# Índice de Agents_IA_TECH

> Proyecto base de agentes y herramientas del ecosistema.
> Generado por plataformador-bootstrap.ps1.

## Componentes clave
- gents/
- .github/
- .opencode/
- scripts/
- Documentacion/Agents_IA_TECH/

## Objetivo
Asegurar que cada proyecto tenga su documentación, la estructura base y los MCPs listos antes de reorganizar archivos.

## Especificaciones activas
- 009-mcp-update-lifecycle: Script independiente de actualización de MCPs con auto-actualización diaria
- 010-secret-leak-remediation: Remediación de fuga de API key en historial Git y hardening de gitleaks
- **011-bootstrap-invokes-upgrade-framework: Bootstrap delega sync dependencias externas en upgrade_framework (fail-open, no hardcoded URLs)**
- **015‑MCP‑Integration‑Flow** – Flujo transversal de integración de MCP alineado con Spec 015. *Ubicación*: `specs/015-mcp-integration-flow/` (ACTIVA, operativa). *Estado*: Completado — flujo SSD completado, spec lista para producción y ACTIVA en `specs/`. `Cerrar` = completar flujo, NO archivar; `Archivar` (`specs/archived/`) solo al retirar del flujo.
- **013‑MCP‑Integration‑Flow** – Integración del módulo ECC alineada con Spec 015. *Ubicación*: `specs/013-mcp-integration-flow/` (ACTIVA, operativa). *Estado*: Completado — T001–T008 ejecutadas, spec lista para producción y ACTIVA en `specs/`. `Cerrar` = completar flujo, NO archivar.
- **017-pendientes-implementacion-por-app: Archivo vivo por proyecto con estado de tareas y responsables** — ✅ **Completado (T001-T016)**. Mecanismo implementado: `Ensure-PendientesImplementacion` en `scripts/plataformador-bootstrap.ps1` (crea el archivo desde plantilla si no existe + detecta obsoleto); sección obligatoria de actualización post-fase en `Agent-SSD` (`.github/` + `.opencode/`); plantilla en `Documentacion/templates/pendientes-implementacion-template.md`. **Regla de agregación multi-spec**: el archivo es un agregado del PROYECTO (consolida TODAS las `specs/*/tasks.md`), con IDs calificados `<spec-id>-T<nnn>` y sin auto-referencia del feature que implementa el mecanismo. Validado Art.VII/Art.IX (PASS).

## Especificaciones en proceso
- **012-ecc-integration**: Integración selectiva de ECC como proyecto externo `proyect_ext/ECC`. Análisis comparativo y hoja de ruta en curso. Índice en `specs/012-ecc-indice.md`

### Integración ECC — Familia de specs 012 y estado de tareas
**Objetivo**: Incorporar capacidades de ECC como proyecto externo en `proyect_ext/ECC` sin reemplazar flujo Speckit/SSD. Namespace `ecc-` obligatorio, paths permitidos por Constitución Art.VII.

**Specs relacionadas 012**:
- `specs/012-ecc-integration/` — Especificación base, spec.md, plan.md, tasks.md, guía-integracion-selectiva.md
- `specs/012-ecc-integration-lifecycle/` — Ciclo de vida install/update/validate/uninstall con `ecc-sync.ps1`
- `specs/012-ecc-mcp-bridge/` — Puente ECC ↔ MCPs y contrato de intercambio
- `specs/012-ecc-mcp-migration/` — Migración .env.mcp → mcp-configs/mcp-servers.json
- `specs/012-ecc-indice.md` — Índice central de familia 012

**Estado de tareas 012-ecc-integration** (según `pendientes-implementacion.md` actualizado 2026-10-04):
- Completadas T001-T007:
  - 012-T001 Clonar ECC en proyect_ext/ECC — `plataformador`
  - 012-T002 Inventariar carpetas clave ECC — `analista-tecnico`
  - 012-T003 Crear matriz de correspondencia ECC ↔ Agents_IA_TECH — `analista-tecnico`
  - 012-T004 Identificar capacidades ECC no presentes — `analista-tecnico`
  - 012-T005 Priorizar importación — `pensador`
  - 012-T006 Definir namespace y reglas de no-duplicación — `arquitecto`
  - 012-T007 Escribir guía de integración selectiva — `documentador`
- Pendientes:
  - 012-T008 Actualizar 00-indice.md con referencia a ECC — `documentador` — **en curso**
  - 012-T009 Registrar ADR de integración — `arquitecto`
  - 012-T010 Validar spec/plan/tasks con usuario — `pensador`
  - 012-T011 Congelar spec para refinamiento futuro — `pensador`

**Artefactos clave**:
- `specs/012-ecc-integration/spec.md` — FR-001 a FR-006, NFR-001 a NFR-003, criterios SC-001 a SC-005
- `specs/012-ecc-integration/plan.md` — Fases Análisis, Definición de alcance, Documentación, Preparación
- `specs/012-ecc-integration/guia-integracion-selectiva.md` — Procedimiento de importación con namespace ecc-, validaciones obligatorias
- `specs/012-ecc-integration/gaps-012-T004.md` y `priorizacion-012-T005.md` — Análisis de gaps y priorización

**Próximos pasos**:
1. Completar 012-T008 actualización de índice
2. Registrar ADR de integración 012-T009
3. Validación usuario 012-T010 y congelar spec 012-T011
4. Iniciar integración lifecycle 013 con `ecc-sync.ps1`

---

## Spec #011 — Bootstrap Invokes upgrade_framework (Converge Completed)

**Fecha converge**: 2026-09-25  
**Fecha revisión seguridad**: 2026-10-05  
**Estado**: Documental completo → Seguridad parcialmente validada  
**Estado seguridad**: T059 APROBADO con evidencia QA; T040-T058, T060-T064 sin evidencia verificable  
**Agente responsable**: `documentador` (solo documentación)

### Artefactos generados/actualizados
| Archivo | Versión | Estado |
|---------|---------|--------|
| `specs/011-bootstrap-invokes-upgrade-framework/spec.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/plan.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/tasks.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/analyze.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/converge.md` | 1.1.0 | **Consolidado + Security review 2026-10-05** |
| `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` | 1.0.0 | Accepted |
| `seguridad/qa-evidence-011-T059-dryrun.md` | 1.0.0 | APROBADO 2026-10-04 |

### Documentación transversal actualizada
| Archivo | Actualización |
|---------|---------------|
| `quickstart.md` | Sección 4: `-ForceUpgradeTools` — sync externo + tokenslayer + 4to MCP |
| `memoria-proyecto.md` | Nueva capacidad registrada con flags, comportamientos, referencias |
| `pendientes-implementacion.md` | Tareas T001-T031 + security-risk T040-T064 listas para implementar |

### Decisiones clave (ADR-0007)
1. **Delegación total** a `upgrade_framework` (SRP)
2. **Fail-open obligatorio** — exit code siempre 0
3. **Cero URLs hardcodeadas** — todo desde manifest
4. **Opt-in via `-ForceUpgradeTools`** — gating completo
5. **Primera ejecución copia manifest template** — idempotente
6. **Frontera kit↔app respetada** — `Documentacion/<AppName>/` intocable

### Guardrails (8 restricciones para implementación)
1. Fail-open en toda llamada externa (try/catch + WARN + continue)
2. No hardcodear URLs en bootstrap
3. `-DryRun` propaga y no escribe nada
4. Idempotencia: re-ejecutar no duplica ni rompe
5. Frontera kit↔app: NO tocar `Documentacion/<AppName>/`
6. Propagación correcta de flags (`-ForceUpgradeTools`, `-DryRun`, `-SkipSync`)
7. Logging estructurado (INFO/WARN/ERROR)
8. Containment de `proyect_ext/` bajo `<root>/proyect_ext/`

### Riesgos seguridad (Threat Model STRIDE)
- **11 CRITICAL** (supply chain, tampering, info disclosure, DoS, elevation)
- **9 HIGH** (identity, manifest immutability, timeouts, schema validation)
- **4 MEDIUM** (audit logging, locks)
- **1 LOW** (allowlist rotation)
- Todos etiquetados `security-risk:` en `tasks.md` para priorización automática

### Próximos pasos
Implementación por `api-developer` / `devops` / `qa-senior` siguiendo orden de dependencias:
- Fase A: T001→T002 (CLI upgrade_framework)
- Fase B: T010→T011→T012→T013 (Bootstrap integration)
- Fase C: T020→T021 (Manifest template)
- Fase D: T030→T031 (Integration tests)
- Security: T040-T058, T060-T064 pendientes de evidencia QA; T059 validado
- Acción inmediata: generar evidencias QA para T040-T058 y T060-T064 antes de cerrar seguridad 011

## Especificación 016 - Enforcement of SSD+Speckit Flow via Agents
- **Estado**: Completada/Cerrada — flujo SSD completo, lista para producción, permanece ACTIVA en `specs/` (archivar solo al retirar del flujo)
- **Ubicaci�n**: specs/016-ssd-enforcement/ 
- **Objetivo**: Forzar flujo SSD+Speckit mediante reglas obligatorias en agents y gatekeeper en pensador.
- **Artefactos**: spec.md, plan.md, tasks.md

