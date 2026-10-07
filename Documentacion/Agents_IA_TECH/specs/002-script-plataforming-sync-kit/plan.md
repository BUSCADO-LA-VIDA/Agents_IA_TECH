# Plan 002 – Scripts de sincronización y despliegue del kit

**Objetivo**: Consolidar y documentar la funcionalidad de sincronización y despliegue del kit `Agents_IA_TECH` en todos los proyectos consumidores, extrayendo de la spec 009 los componentes relacionados con scripts y despliegue, e implementando el flujo completo para mantener los kits actualizados.

### Fase 1: Crear script independiente `update-mcp.ps1`
- **T001**: Esqueleto del script con parámetros `-Force`, `-DryRun`, `-Tools`
- **T002**: Lógica de detección MCP usando `mcp-functions.ps1`
- **T003**: Lógica de instalación/update por MCP usando funciones compartidas
- **T004**: Reporte por MCP con formato `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA`
- **T005**: Validación de idempotencia (no duplicar si ya actualizado)
- **T006**: Actualización de `.env.mcp` (validar valores existentes, resolver vacíos/incorrectos)
- **T007**: Actualización de `opencode.json` resolviendo `{env:...}` a rutas reales y habilitando (`enabled: true`)

### Fase 2: Auto-actualización diaria
- **T008**: Implementar ventana de 24h en `.bootstrap-state.json` read/write
- **T009**: Lógica de check 24h window en `update-mcp.ps1`
- **T010**: Override `-Force` para forzar actualización ignorando ventana

### Fase 3: Integración con bootstrap y pensador
- **T010**: Modificar `plataformador-bootstrap.ps1` para invocar `update-mcp.ps1` (paso 4)
- **T011**: Agregar regla de actualización a `.github/agents/pensador.agent.md`
- **T012**: Agregar regla de actualización a `.opencode/agents/pensador.md`
- **T013**: Documentar integración en `quickstart.md`

### Fase 4: Sincronización del kit transversal
- **T014**: Sincronizar `.github/` desde repositorio maestro
- **T015**: Sincronizar `.opencode/` desde repositorio maestro
- **T016**: Sincronizar `.doc_agents/` desde repositorio maestro
- **T017**: Sincronizar `scripts/` desde repositorio maestro
- **T018**: Sincronizar `.specify/memory/constitution.md` desde repositorio maestro
- **T019**: Sincronizar `AGENTS.md` desde repositorio maestro
- **T020**: Sincronizar `opencode.json` desde repositorio maestro
- **T021**: Sincronizar `README.md` desde repositorio maestro
- **T022**: Sincronizar `sync-agents.ps1` desde repositorio maestro
- **T022**: Sincronizar `upgrade_framework.ps1` desde repositorio maestro

### Fase 5: Validación y Convergence
- **T022**: Validar idempotency y reporting
- **T023**: Actualizar documentación en `specs/002-script-plataforming-sync-kit/`
- **T024**: Ejecutar escenarios de validación quickstart
- **T024**: Verificar que `AGENTS.md` raíz no es modificado por sincronización
- **T025**: Converge documentación y actualizar `00-indice.md`

### Dependencies & Execution Order

- Phase 1 (T001-T007) debe completarse antes que Phase 2 (T008-T009)
- Phase 1 y Phase 2 deben completarse antes que Phase 3 (T010-T013)
- Phase 3 y Phase 4 pueden ejecutarse en paralelo
- Phase 5 (T022-T025) depende de tener completadas Phases 1-4
- T014-T021 (sincronización) pueden ejecutarse en paralelo entre sí
- T022-T025 (validación) dependen de T001-T021

### Parallel Opportunities

- T002, T003 pueden ejecutarse en paralelo (ambos son scripting)
- T004 puede ejecutarse después de T002 o T003
- T008, T009 pueden ejecutarse en paralelo
- T010 puede ejecutarse después de T009
- T011, T012 pueden ejecutarse en paralelo
- T014-T021 (sincronización de carpetas) pueden ejecutarse en paralelo
- T022-T025 (validación) pueden ejecutarse en paralelo después de tener los scripts listos

### Execution Order Recommended

1. **Phase 1**: T001-T007 (crear update-mcp.ps1 y funciones compartidas)
2. **Phase 2**: T008-T009 (auto-actualización diaria)
3. **Phase 3**: T010-T013 (integración con bootstrap y pensador)
4. **Phase 4**: T014-T021 (sincronización del kit transversal en proyectos)
5. **Phase 5**: T022-T025 (validación y convergence)

---

## Parallel Execution Matrix

| Tarea | Puede paralelarse con | Comentario |
|---|---|---|
| T002 | T003 | Ambos son creación de scripting |
| T008 | T009 | Ambos son lógica de ventana de tiempo |
| T011 | T012 | Ambos son reglas de agente |
| T014-T021 | Entre sí | Sincronización de carpetas independientes |
| T022-T025 | Entre sí | Validación y convergence |

---

## Risks & Mitigation

- **R001**: Script `update-mcp.ps1` deja algunos MCPs desactualizados.
  - **Mitigation**: Implementar validación exhaustiva en FR-007 y re-ejecutar si es necesario.
- **R002**: Sincronización sobrescribe personalizaciones en `Documentacion/<AppName>/`.
  - **Mitigation**: El script respeta la frontera kit↔app; personalizaciones están en `Documentacion/<AppName>/` y se conservan.
- **R003**: `opencode.json` queda corrupto tras escritura.
  - **Mitigation**: Implementar validación JSON posterior (FR-010) y rollback conservador.

---