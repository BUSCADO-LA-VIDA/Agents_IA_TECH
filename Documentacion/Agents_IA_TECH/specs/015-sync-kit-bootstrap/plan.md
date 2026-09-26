# Plan 015: Sync-Kit y Bootstrap separados

## Summary

Dividir `scripts/plataformador-bootstrap.ps1` en dos responsabilidades:
`scripts/sync-kit.ps1` (sincronizacion del kit transversal desde el repo
maestro) y `plataformador-bootstrap.ps1` (orquestacion del preflight). Ademas,
ampliar la sincronizacion para incluir `scripts/` y `scripts/modules/`, de modo
que los modulos del kit (`ManifestManager`, `ManifestHooks`, `YamlHelper`)
viajen a los proyectos derivados.

## Technical Context

- Lenguaje: PowerShell 7+ (pwsh). No funciona en Windows PowerShell 5.1.
- Control de versiones: Git (clone shallow `--depth 1`).
- Dependencias: `robocopy` (Windows), `git`, `pwsh`.
- Plataforma objetivo: Windows (win32).
- Sin dependencias externas de paquetes.

## Project Structure

```
scripts/
  sync-kit.ps1                    # NUEVO: sincronizacion standalone
  plataformador-bootstrap.ps1     # MODIFICADO: delega sync en sync-kit.ps1
  modules/
    Manifest/
      ManifestManager.psm1        # viaja con el kit (nuevo transversal)
      ManifestHooks.psm1
      ManifestReference.psm1
    Utils/
      YamlHelper.psm1
Documentacion/
  Agents_IA_TECH/
    specs/
      015-sync-kit-bootstrap/
        spec.md
        plan.md
        tasks.md
        research.md
        data-model.md
        quickstart.md
        analyze.md
        converge.md
        design.md                 # fuente de verdad para devops
```

## Fases del Cambio

### Fase 1: Documentacion (completada)

- T001: `design.md` con inventario de funciones, estructura de `sync-kit.ps1`,
  cambios en el bootstrap y matriz de trazabilidad.
- T002: ampliar `spec.md` con FR-005 (migracion) y FR-006 (ampliacion).
- T003: completar artefactos Speckit restantes.

### Fase 2: Implementacion (delegada a `devops`)

- T004: crear `scripts/sync-kit.ps1` (secciones 3.1-3.7 de `design.md`).
- T005: anadir `scripts/` a `$transversalDirs` (FR-004, FR-006).
- T006: eliminar del bootstrap las funciones migradas (1637-2010, 2182-2411).
- T007: reemplazar llamadas a `Sync-TransversalKit` por invocacion de
  `sync-kit.ps1`.
- T008: verificar AC-01 a AC-08.

### Fase 3: Verificacion (delegada a `qa-senior`)

- T009: ejecutar `sync-kit.ps1` en proyecto derivado.
- T010: ejecutar `plataformador-bootstrap.ps1 -DryRun`.

## Dependencias entre Fases

```
T001 -> T002 -> T003
T001 -> T004 -> T005
T004 -> T006 -> T007 -> T008
T008 -> T009
T008 -> T010
```

Fase 2 no puede empezar sin Fase 1 (T001 es prerequisito de T004).
Fase 3 no puede empezar sin Fase 2 (T008 es prerequisito de T009/T010).

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Duplicacion de logging bootstrap/sync-kit | Alta | Bajo | Aceptado: 30 lineas de logging puro |
| `sync-kit.ps1` sin funciones auxiliares | Media | Alto | Migrar todas las funciones de design.md seccion 2 |
| `robocopy` de `scripts/` sobrescribe scripts locales | Media | Medio | Documentar que `scripts/` es del kit |
| Huerfanos de `scripts/` como falsos positivos | Media | Bajo | `Find-OrphanKitFiles` no incluye `scripts/` |
| Perdida de self-update | Baja | Alto | `Update-Self` permanece en el bootstrap |

## Criterios de Aceptacion

| ID | Criterio |
|----|----------|
| AC-01 | `sync-kit.ps1` existe y es standalone |
| AC-02 | `sync-kit.ps1 -DryRun` no escribe nada |
| AC-03 | `sync-kit.ps1` copia `scripts/` al proyecto |
| AC-04 | `sync-kit.ps1` no toca `Documentacion/` |
| AC-05 | `sync-kit.ps1` excluye `.opencode/config.json` |
| AC-06 | `plataformador-bootstrap.ps1` invoca `sync-kit.ps1` |
| AC-07 | `plataformador-bootstrap.ps1 -SyncOnly` solo sincroniza |
| AC-08 | Huerfanos se manejan igual que antes |

## Archivos Exactos a Tocar

| Archivo | Accion | Responsable |
|---------|--------|-------------|
| `scripts/sync-kit.ps1` | Crear | `devops` |
| `scripts/plataformador-bootstrap.ps1` | Modificar (eliminar funciones, reemplazar llamadas) | `devops` |
| `Documentacion/Agents_IA_TECH/specs/015-sync-kit-bootstrap/*.md` | Crear/actualizar | `pensador` |

## Orden de Ejecucion

1. `pensador`: T001-T003 (documentacion).
2. `devops`: T004-T008 (implementacion).
3. `qa-senior`: T009-T010 (verificacion).
4. `gitflow`: commit final.
