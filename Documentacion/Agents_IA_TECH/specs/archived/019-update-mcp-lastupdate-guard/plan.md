# Plan 019 – Guard de Get-State en update-mcp.ps1 + limpieza de invocación

**Objetivo**: Eliminar el fallo `No se encuentra la propiedad "lastUpdate"` en toda ejecución real de `scripts/update-mcp.ps1` con estado preexistente, y quitar el flag muerto `-Quick` de la llamada de cola del bootstrap.

### Fase 1: Endurecer `Get-State` + parse (FR-001, FR-002, FR-003)

- **T001**: Reescribir `Get-State` para capturar el parseo en variable local y devolver `$null` si falta la propiedad `lastUpdate` (guard por forma; el guard por tipo `-isnot` no discrimina valores deserializados). Devolver el objeto tal cual si es válido. Hacer el parse de `lastUpdate` `DateTime`-aware (aceptar `[DateTime]` directo, sin re-parse cultural). No tocar el resto del flujo (guard de línea 14, ventana 24h, reporte y `Save-State` quedan iguales).
- **T002**: Verificar sintaxis con `Parser::ParseFile` (0 errores).

### Fase 2: Limpiar invocación del bootstrap (FR-004)

- **T003**: Cambiar `& $updateScript -Quick` por `& $updateScript` (sin argumentos; el default aplica la ventana de 24h) y verificar que no queden referencias a `-Quick` en el bootstrap.

### Fase 3: Validación en vivo (SC-001, SC-002, SC-004)

- **T004**: Ejecución real con estado stale (>24h): debe terminar exit 0, imprimir reporte y dejar `lastUpdate` de hoy.
- **T005**: Envenenar el estado con `["x"]` y ejecutar con `-Force`: debe terminar exit 0 y dejar objeto válido `{lastUpdate, tools}` (auto-sanado).
- **T006**: Confirmar `-DryRun` sigue sin escribir y la salida temprana `UP_TO_DATE` intacta (FR-004).

### Dependencies & Execution Order

- T001 antes que T002 (código antes que verificación de sintaxis).
- T003 independiente de T001-T002 (archivos distintos), pero se verifica junto.
- T004-T006 después de T001-T003 (validan el cambio aplicado).

### Risks & Mitigation

- **R001**: El fix altera el comportamiento con archivo inexistente.
  - **Mitigation**: T004 cubre ambos casos (stale e inexistente por construcción del guard); el camino `$null` → re-init no se toca.
- **R002**: Proyectos consumidores con copias viejas del script siguen fallando.
  - **Mitigation**: Fuera de alcance por diseño; se propagan vía sync del kit (spec 002) en la próxima actualización.
