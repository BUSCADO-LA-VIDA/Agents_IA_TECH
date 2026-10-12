# Implementation Plan: 021-sync-kit-agents

**Origen**: `spec.md` de esta spec. Enfoque: extracción mecánica primero (sin cambiar lógica), capas nuevas después, orquestador al final de cada incremento verificable.

## Estructura destino

```
scripts/
  sync-kit-agents.ps1
  sync/
    docs/sync-docs.ps1
    agents/sync-agents-github.ps1
    agents/sync-agents-opencode.ps1
    agents/sync-agents-vscode.ps1
    kit-files/sync-kit-files.ps1
    constitutions/sync-constitutions.ps1
    src-structure/sync-src-structure.ps1
    mcp/install.ps1
    mcp/lift-opencode.ps1
    mcp/lift-vscode.ps1
    indexing/run-indexing.ps1
    externals/resolve-externals.ps1
    lib/common.ps1            # logging + helpers compartidos (extraído, sin duplicar)
```

## Fases de implementación

### Fase 1 (esta entrega)
Estructura + `lib/common.ps1` (logging `Write-*/Show-ExecutionSummary` extraído de `sync-kit.ps1`) + `docs/sync-docs.ps1` + `agents/*.ps1` (3 harnesses, lógica robocopy+guards migrada) + orquestador esqueleto con F1–F5 que encadena `docs` y `agents`, `-DryRun` funcional, `-Only/-Skip`.

### Fase 2
`kit-files/`, `constitutions/` (migrar `Ensure-ConstitutionAppSync` conceptualmente: seed L2 + hook Publicado ya en bootstrap; aquí solo seed+verify), `src-structure/`.

### Fase 3
`mcp/install.ps1` (detecta npm/uv/python → instala ausentes → verifica versión → anota `.env.mcp`) + `mcp/lift-opencode.ps1` y `lift-vscode.ps1` (fusión aditiva + `graphify` regenerado + des-ignorar `.vscode/mcp.json`).

### Fase 4
`indexing/` (extraer `Index-CodebaseMemory`, `Index-ContextMode`, `Configure-Graphify`) + `externals/` (envolver Manifest modules + `Invoke-UpgradeFramework`, sin copia) + orquestador completo + prueba en 1 consumidor + deprecación de `sync-kit.ps1`.

## Constitution Check

`.specify/memory/constitution.md` existe con 9 artículos + VI proyect_ext (verificado 2026-10-12). Esta spec respeta Art-VII (los scripts nuevos caen en tier Plataforma; el orquestador no toca `Documentacion/<AppName>/` salvo reportes `.kit-last-sync.json` en destino, que es estado operativo, no documentación).

## Riesgos

- **R1**: Divergencia bootstrap↔nuevas capas (duplicación temporal). Mitigación: las capas importan/invocan, no duplican; el bootstrap sigue llamando hasta la deprecación.
- **R2**: `clean+replace` borra personalizaciones locales del consumidor. Mitigación: backup previo obligatorio + reporte; huérfanos default Conservar.
- **R3**: `.vscode/` entero está gitignored: des-ignorar solo `mcp.json` (`!.vscode/mcp.json`) o el sync no persiste. Incluido en fase 3.
