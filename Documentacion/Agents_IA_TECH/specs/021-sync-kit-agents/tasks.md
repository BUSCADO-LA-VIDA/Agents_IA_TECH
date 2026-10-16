# Tasks: 021-sync-kit-agents

## Fase 1
- [x] T001 Estructura `scripts/sync/` + `lib/common.ps1` (logging extraído) — Hecho 2026-10-12.
- [x] T002 `docs/sync-docs.ps1` (estructura Documentacion, harness-independiente) — Hecho 2026-10-12.
- [x] T003 `agents/sync-agents-{github,opencode,vscode}.ps1` (1 por harness) — Hecho 2026-10-12.
- [x] T004 Orquestador `sync-kit-agents.ps1` esqueleto F1–F5 con `--Only/--Skip`, `-DryRun`, reporte y flag restart — Hecho 2026-10-12.
- [x] T005 Verificación fase 1: `-DryRun` sin escrituras + parseo 0 errores — Hecho 2026-10-12.

## Fase 2
- [x] T006 `kit-files/` (scripts/, AGENTS.md, README.md, constitution raíz).
- [x] T007 `constitutions/` (seed L2 + verify 3 niveles).
- [x] T008 `src-structure/` (estructura `src/<App>` + `.specify`).

## Fase 3
- [x] T009 `mcp/install.ps1` portable por máquina.
- [x] T010 `mcp/lift-opencode.ps1` + `lift-vscode.ps1` (fusión aditiva + graphify regenerado + des-ignorar `.vscode/mcp.json`).

## Fase 4
- [x] T011 `indexing/` (extraer Index-* + Graphify, corre al iniciar harness).
- [x] T012 `externals/` (envolver Manifest modules + re-integrar contenido seleccionado con copia al KIT con tag de origen, segun modelo 2026-10-16: externo = cache, integrado viaja en git).
- [x] T013 Orquestador completo + prueba en 1 consumidor + deprecación `sync-kit.ps1`.




