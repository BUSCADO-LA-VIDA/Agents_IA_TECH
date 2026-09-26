# Registro de memoria

> Generado por plataformador-bootstrap.ps1
> Fecha: 2026-09-25

## Estado
- Proyecto: C:\Proyectos\Agents_IA_TECH
- Preparación del entorno: completada
- ReIndexación: completada tras converge spec #011

## Capacidades Registradas

### Bootstrap invoca upgrade_framework (Spec #011)
**Fecha**: 2026-09-25  
**Spec**: `011-bootstrap-invokes-upgrade-framework`  
**ADR**: `arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md`  
**Threat Model**: `specs/011-bootstrap-invokes-upgrade-framework/threat-model.md`  
**Converge**: `specs/011-bootstrap-invokes-upgrade-framework/converge.md`

#### Nueva capacidad
El script `plataformador-bootstrap.ps1` ahora delega el **100% de la sincronización de dependencias externas** al agente `upgrade_framework` antes del build de `tokenslayer`.

#### Flags nuevos
| Flag | Comportamiento |
|------|----------------|
| `-ForceUpgradeTools` | **Opt-in**: habilita invocación a `upgrade_framework` + build de `tokenslayer` + registro del 4to MCP (`tokenslayer.enabled: true`) |
| `-DryRun` | Propagado a `upgrade_framework` y copia de manifest — cero side effects |
| `-SkipSync` | Ortogonal — no afecta la invocación de `upgrade_framework` |

#### Comportamientos clave
- **Fail-open obligatorio**: Cualquier error en `upgrade_framework` (red, GitHub, uv, npm, permisos) → `WARN` + bootstrap continúa con **exit code 0**
- **Cero URLs hardcodeadas**: Bootstrap lee todas las fuentes desde `dependencias-manifest.yml`
- **Primera ejecución**: Copia plantilla `dependencias-manifest.yml` del kit maestro a raíz del proyecto (idempotente, no sobrescribe)
- **Frontera kit↔app**: `Documentacion/<AppName>/` **nunca** tocada

#### Verificación
```powershell
.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools
# → manifest copiado + proyect_ext/ clonado + tokenslayer compilado + 4to MCP registrado
```

#### Referencias
- Spec: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/spec.md`
- Plan: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/plan.md`
- Tasks: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/tasks.md` (T001-T031 + T040-T064 security-risk)
- Analyze: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/analyze.md`
- ADR-0007: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md`
- Threat Model: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/threat-model.md`
- Converge: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/converge.md`
- Quickstart: `Documentacion/Agents_IA_TECH/quickstart.md` (sección 4)
