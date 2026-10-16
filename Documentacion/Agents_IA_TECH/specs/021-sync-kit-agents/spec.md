# Feature Specification: 021-sync-kit-agents — Orquestador de sync por capas con stage temporal en proyecto

**Feature Branch**: `021-sync-kit-agents`
**Created**: 2026-10-12
**Status**: En implementación (fase 1)
**Input**: El mecanismo `sync-kit.ps1` (merge conservador + robocopy + SKIP sin `-Force`) no propaga actualizaciones a los proyectos consumidores. Se reescribe con metodología stage-temporal → clean+replace → plataformar, en capas desacopladas por carpeta.

---

## Problema

1. **Los updates no llegan**: archivos que difieren hacen SKIP sin `-Force`; directorios se fusionan con robocopy dejando huérfanos mezclados.
2. **Nada lo ejecuta solo**: requiere corrida manual por proyecto; sin reporte auditable ni señal de restart.
3. **Monolito incremental**: `plataformador-bootstrap.ps1` (145 KB) y `sync-kit.ps1` (37 KB) crecieron por agregados; nadie sabe qué tocar.
4. **MCPs frágiles al sync**: reescribir `opencode.json` rompe configs por proyecto (bug OpenCode #5299 impide tokens); `graphify` tiene ruta por proyecto.

## Objetivos

- Orquestador `scripts/sync-kit-agents.ps1` con 5 fases: Stage → Sync → Plataformar → Verify → Restart-flag.
- Capas desacopladas en subcarpetas de `scripts/`, una por función; por harness donde aplique.
- Regla de oro: **en el KIT se instala; en los proyectos se levanta** (binarios nunca se copian; definiciones MCP en fusión aditiva).
- Orden obligatorio tras sync: `install → lift → indexing → reload si hay flag`.

## Requisitos funcionales

### RF-01 — Stage temporal en proyecto
Clonar el repo (`--depth 1`, registrar commit+fecha) o validar `-KitPath` en `<destino>/.kit-sync-temp/<timestamp>/` (único por corrida). Asegurar regla gitignore para `.kit-sync-temp/`.

### RF-02 — Sync por capas en orden
`kit-files → agents/{harness} → docs → constitutions → src-structure → mcp/lift → externals`. Cada capa es un script invocable individualmente (`--Only <capa>`, `--Skip <capa>`).

### RF-03 — Clean+Replace con backup
Por directorio: borrar destino y copiar del stage. Por archivo: sobrescribir siempre. Backup previo en `<destino>/.kit-backup/<timestamp>/` (gitignored). Rollback = restaurar backup.

### RF-04 — Excepción `opencode.json` (fusión aditiva)
Añadir claves MCP del maestro que falten; reparar `command` solo si apunta a binario inexistente; preservar todo lo demás. `graphify` se regenera con el grafo del destino, nunca se copia.

### RF-05 — Preservaciones
Nunca tocar: `Documentacion/<AppName>/`, `.opencode/config.json`, `.opencode/.gitignore` local si difiere.

### RF-06 — Plataformar destino
Tras el sync, correr sobre el destino: `mcp/install` (verifica/instala binarios), `indexing` (código + docs), `verify`. El destino queda funcional, no solo copiado.

### RF-07 — Verify + reporte
Re-comparar hash destino vs stage por ítem; escribir `sync-report.json` + `.kit-last-sync.json` (commit, fecha, ítems) en destino.

### RF-08 — Restart flag + control externo
Si cambió `agents/`, `opencode.json` o `.opencode/`, escribir `.kit-restart-required` + línea `RESTART:VSCODE`. El controlador externo decide si reinicia. Temp se limpia en éxito; se conserva en fallo (forense).

### RF-09 — Compatibilidad con el llamador
Mantener firma y semántica que usa `Invoke-SyncKit` del bootstrap (`-RepoUrl`, `-RootPath`, `-DryRun`, `-Force`, `-KitPath`, `-OrphanAction`). `-DryRun` informa sin escribir en todas las fases.

## Requisitos no funcionales

- **RNF-01**: PowerShell 7+, fail-open en red/git (WARN + continúa donde sea seguro), fail-closed en seguridad (URLs no permitidas, validación de `-KitPath`).
- **RNF-02**: Idempotencia por fase (re-correr sin cambios = 0 escrituras, verificable por reporte).
- **RNF-03**: Sin dependencias nuevas (solo cmdlets + `git` + `robocopy` ya usados).
- **RNF-04**: Estatus git: `opencode.json` y `.vscode/mcp.json` trackeados (los ajusta el lift); `.env`, `.env.mcp`, `.opencode/config.json`, `.kit-sync-temp/`, `.kit-backup/` gitignored.

## Fuera de alcance

- Reescribir `plataformador-bootstrap.ps1` (solo se mantiene su llamada a sync; la migración de sus funciones internas es trabajo futuro).
- Deprecar `sync-kit.ps1` (tras probar el nuevo en 1 consumidor).
- MCPs de pago descartados (sentry/perplexity/pieces/testsprite) y desbloqueo de sentry (auth del usuario).

## Dependencias

- `sync-kit.ps1` (lógica de referencia: guards, allowlist de URLs, merge `opencode.json`).
- `plataformador-bootstrap.ps1` (`Invoke-SyncKit`, `Ensure-ConstitutionAppSync`, funciones `Index-*`, `Ensure-AppStructure`).
- Módulos `Manifest/*` (externals por manifest + re-integracion con copia).
- ADR-0009 (hardcodeo MCP), ADR-0006 (diseño de tokens), regla constitution 3 niveles (bitácora 2026-10-11).

## Criterios de éxito

- **SC-01**: `-DryRun` en el maestro lista plan completo sin escribir nada.
- **SC-02**: Sync a proyecto de prueba deja `sync-report.json` con 0 MISMATCH y `.kit-last-sync.json` con el commit.
- **SC-03**: Re-correr sync sin cambios produce 0 escrituras.
- **SC-04**: `opencode.json` del destino conserva sus claves locales y suma las nuevas del maestro.
- **SC-05**: Flag de restart aparece solo si cambió agents/opencode/.opencode.

