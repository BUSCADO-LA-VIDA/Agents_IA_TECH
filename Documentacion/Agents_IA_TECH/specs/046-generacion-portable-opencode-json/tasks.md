# Tasks 046 — Generación portable de `opencode.json`

**Spec**: `spec.md` · **Plan**: `plan.md` · **Branch**: `046-generacion-portable-opencode-json`

## Regla de oro (vinculante)

1. **Nunca** se edita `opencode.json`, `.env.mcp`, `.vscode/mcp.json` ni ningún artefacto generado "a mano". Esos archivos son **salida**.
2. Todo cambio se hace en el **script generador** (`scripts/plataformador-bootstrap.ps1`, `scripts/sync/mcp/lift-opencode.ps1`, `scripts/sync/opencode/sync-opencode-config.ps1`, `scripts/sync-mcp-graphify.ps1`).
3. Se prueba **lo que el script genera** en un directorio temporal: sembrar un archivo de entrada, ejecutar el generador, inspeccionar la salida.
4. Un cambio sin prueba de salida generada no se marca `[x]`.
5. Si el artefacto ya está corregido a mano en una máquina, se anota como **estado local no reproducible** hasta que el generador lo produzca.

**Formato**: `- [ ] Txxx [RF] descripcion | verificar: comando`

---

## Fase 0 — Reproducir el fallo (sin tocar artefactos)

- [x] T001 [RF-01] Sembrar en temporal un `opencode.json` con la forma `mcp.servers.<nombre>` y la entrada `context-mode` apuntando a un archivo inexistente (`build/cli.js`)
- [x] T002 [RF-01] Ejecutar el bootstrap en ese temporal y **registrar que no repara nada** (evidencia del defecto G5: el resolvedor itera `mcp.<nombre>`, no `mcp.servers.<nombre>`)
- [x] T003 [RF-01] Guardar la evidencia en `tests/fixtures/generacion-opencode-046.md` (antes/después por corrida)

## Fase 1 — El generador entiende la forma real

- [x] T004 [RF-01, G5] En `Ensure-OpenCodeMcp`, resolver la raíz MCP: si `mcp.servers` existe, iterar ahí; si no, en `mcp` (compatibilidad)
- [x] T005 [RF-01] Aplicar la misma raíz a: bucle de re-resolución, bloque `tokenslayer` y bloque de reporte
- [x] T006 [RF-02, G6] Añadir `Resolve-ContextModeCommand`: `node` + `server.mjs` + `--agent opencode` (context-mode 2.x); usarlo solo para `context-mode`
- [x] T007 [RF-03] Invalidar una entrada cuando el `command` referencia un `.js`/`.mjs` que no existe en disco (cambio de layout del paquete)

## Fase 2 — Portabilidad del contenido

- [ ] T008 [RF-04] Maestro = `opencode.template.json` cuando exista; fallback al `opencode.json` del stage
- [x] T009 [RF-04] Regenerar `graphify` con `$RootPath` del destino (no con el del stage)
- [ ] T010 [RF-05] `tokenslayer` relativo al proyecto o `enabled:false` + WARN
- [ ] T011 [RF-06, G7] `.env.mcp`: la clave de `context-mode` no puede ser un comando de un solo argumento; documentar el formato multi-arg que consume el resolvedor
- [ ] T012 [RF-07, G8] `.mcp.json` (VS Code): dejar de usar nombres que no se pueden spawnear en Windows (`context-mode`, `npx`) y `${workspaceFolder}`; pasar a plantilla + generación local

## Fase 3 — Pruebas de lo generado

- [x] T013 [RF-08] `tests/generacion-opencode.Tests.ps1`: temporal vacío → `opencode.json` con 8 MCP y `default_agent: pensador`
- [x] T014 [RF-08] Temporal con la entrada rota → el generador la repara a `node server.mjs --agent opencode`
- [ ] T015 [RF-08] Temporal con entrada `tokenslayer` sin build → `enabled:false` + WARN
- [x] T016 [RF-08] `graphify` apunta a `<RootPath>/graphify-out/graph.json`
- [ ] T017 [RF-08] JSON inválido → no se escribe; backup intacto
- [ ] T018 [RF-08] `-DryRun` no escribe y reporta las claves que cambiarían

## Fase 4 — Cierre

- [ ] T019 [RF-09] Ejecutar el generador en el proyecto real **sin editar el archivo a mano** y comparar con el estado actual
- [ ] T020 [RF-09] Actualizar `generacion-opencode-json.md` con el flujo final y el estado local no reproducible (si lo hay)
- [ ] T021 [RF-09] Regresión: validator de portabilidad 16/16 y suites del kit
- [ ] T022 [RF-09] Commit por spec + actualizar `pendientes-implementacion.md`

---

## Dependencias

| Tarea | Requiere |
|---|---|
| T004-T005 | T001, T002 |
| T006 | T004 |
| T007 | T004 |
| T008-T010 | T004 |
| T013-T018 | T004-T010 |
| T019-T022 | T013-T018 |

## Criterio de cierre

`opencode.json` en el proyecto real debe ser **generado** por el script con las 8 entradas correctas, y el test debe demostrarlo en un temporal. El archivo corregido a mano hoy (bitácora 2026-11-11) se considera estado local no reproducible hasta T019.
