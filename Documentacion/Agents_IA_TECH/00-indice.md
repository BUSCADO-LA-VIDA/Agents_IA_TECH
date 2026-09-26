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

## Especificaciones en proceso
- **012-ecc-integration**: Integración selectiva de ECC como proyecto externo `proyect_ext/ECC`. Análisis comparativo y hoja de ruta en curso. Índice en `specs/012-ecc-indice.md`

---

## Spec #011 — Bootstrap Invokes upgrade_framework (Converge Completed)

**Fecha converge**: 2026-09-25  
**Estado**: Documental completo → Listo para implementación  
**Agente responsable**: `documentador` (solo documentación)

### Artefactos generados/actualizados
| Archivo | Versión | Estado |
|---------|---------|--------|
| `specs/011-bootstrap-invokes-upgrade-framework/spec.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/plan.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/tasks.md` | 1.0.0 | Draft |
| `specs/011-bootstrap-invokes-upgrade-framework/analyze.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md` | 1.0.0 | Completed |
| `specs/011-bootstrap-invokes-upgrade-framework/converge.md` | 1.0.0 | **Consolidado** |
| `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md` | 1.0.0 | Accepted |

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
- Security: T040-T064 (mitigaciones threat model)
