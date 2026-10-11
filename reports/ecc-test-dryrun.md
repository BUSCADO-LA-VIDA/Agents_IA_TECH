# ECC orchestrator dry-run — evidencia (013-mcp T005 / 015-T004)

**Fecha**: 2026-10-09T20:53:14+02:00
**Commit KIT**: master `e22f266` (más fix pendiente de `ci/ecc-pipeline.yml`)
**Comando**: `.\scripts\ecc-orchestrator.ps1 -action status -dryrun`
**Salida**:
```text
[2026-10-09T20:53:14] action=status mcp=ecc dryrun=True status=ok detail=inactive
```
**Exit code**: 0

## Notas de la ejecución

- `detail=inactive`: no existe `proyect_ext/ECC/.ecc-levanta` (jamás corrió en modo real, que requiere aprobación del pensador). Correcto para dry-run.
- El pipeline `ci/ecc-pipeline.yml` invocaba `.\\scripts\\ecc-orchestrator.ps1 --dry-run` (sintaxis inválida: el parámetro es `-dryrun` y falta `-action`, obligatorio). Corregido a `.\scripts\ecc-orchestrator.ps1 -action status -dryrun`, agregado `actions/checkout@v4` (faltaba) y rama `master` (el repo usa master, no main). Report step reescrito en pwsh.
- Observación fuera de alcance: el modo real reenvía `& $slave -action $action` a `ecc-sync.ps1`, cuyo `ValidateSet` no incluye `status`. Solo afecta invocaciones reales con `action=status` (requieren aprobación); el dry-run y `status` no tocan ese camino.
