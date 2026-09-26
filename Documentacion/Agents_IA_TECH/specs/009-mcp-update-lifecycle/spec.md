# Feature Specification: MCP Update Lifecycle — Script independiente de actualización de MCPs con auto-actualización diaria

**Feature Branch**: `009-mcp-update-lifecycle`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "Crear un script independiente update-mcp.ps1 que gestione el ciclo de vida de instalación, actualización y activación de MCPs, con auto-actualización diaria y registro en .bootstrap-state.json, invocable por bootstrap y por el agente pensador."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Actualizar MCPs de forma independiente (Priority: P1)

Como usuario del kit, quiero ejecutar un script independiente `update-mcp.ps1` que instale, actualice y active los MCPs sin ejecutar todo el bootstrap, para mantener los MCPs frescos con un comando rápido.

**Why this priority**: Es el valor central de la feature. Permite mantener los MCPs actualizados sin el overhead del bootstrap completo.

**Independent Test**: Puede verificarse ejecutando `pwsh scripts/update-mcp.ps1` y comprobando que los MCPs quedan instalados/actualizados y habilitados.

**Acceptance Scenarios**:
1. **Given** un MCP desactualizado, **When** se ejecuta `update-mcp.ps1`, **Then** el MCP se actualiza a la última versión disponible.
2. **Given** un MCP no instalado, **When** se ejecuta `update-mcp.ps1`, **Then** el MCP se instala y queda habilitado.
3. **Given** un MCP ya actualizado, **When** se ejecuta `update-mcp.ps1`, **Then** el script informa "ya actualizado" y no realiza cambios.

---

### User Story 2 - Auto-actualización diaria (Priority: P2)

Como usuario del kit, quiero que el script verifique automáticamente si han pasado más de 24h desde la última actualización y actualice los MCPs sin intervención manual, para garantizar que los MCPs siempre estén frescos.

**Why this priority**: Reduce la fricción de mantenimiento y asegura consistencia entre proyectos.

**Independent Test**: Puede verificarse simulando una fecha antigua en `.bootstrap-state.json` y ejecutando el script; debe detectar que es necesario actualizar.

**Acceptance Scenarios**:
1. **Given** `.bootstrap-state.json` con última actualización hace >24h, **When** se ejecuta `update-mcp.ps1`, **Then** se actualizan los MCPs y se registra nueva fecha.
2. **Given** `.bootstrap-state.json` con última actualización hace <24h, **When** se ejecuta `update-mcp.ps1`, **Then** se omite la actualización y se informa "actualizado recientemente".

---

### User Story 3 - Integración con bootstrap y pensador (Priority: P2)

Como usuario del kit, quiero que `plataformador-bootstrap.ps1` invoque `update-mcp.ps1` y que el agente `pensador` pueda solicitar la actualización de MCPs, para tener un ciclo de vida unificado.

**Why this priority**: Asegura que la actualización sea parte del flujo estándar y no un proceso aislado.

**Independent Test**: Puede verificarse ejecutando el bootstrap y comprobando que llama a `update-mcp.ps1`; y simulando una petición del agente pensador.

**Acceptance Scenarios**:
1. **Given** ejecución de `plataformador-bootstrap.ps1`, **When** finaliza, **Then** invoca `update-mcp.ps1` y los MCPs quedan actualizados.
2. **Given** el agente `pensador` solicita actualización de MCPs, **When** se ejecuta la tarea, **Then** se invoca `update-mcp.ps1` y se reporta el resultado.

---

### Edge Cases

- ¿Qué pasa si un MCP falla al actualizar? → El script debe continuar con los demás MCPs y reportar el error sin abortar.
- ¿Qué pasa si `.bootstrap-state.json` no existe? → El script debe crearlo con la fecha actual.
- ¿Qué pasa si el usuario ejecuta con `-Force`? → Debe forzar actualización ignorando la ventana de 24h.
- ¿Qué pasa si un MCP no está disponible en el repositorio? → El script debe emitir WARN y continuar.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE proporcionar un script independiente `scripts/update-mcp.ps1` que gestione instalación, actualización y activación de MCPs.
- **FR-002**: El sistema DEBE verificar la última fecha de actualización en `.bootstrap-state.json` y actualizar solo si han pasado más de 24h, salvo `-Force`.
- **FR-003**: El sistema DEBE registrar la fecha de última actualización en `.bootstrap-state.json` tras una actualización exitosa.
- **FR-004**: El sistema DEBE ser invocable desde `plataformador-bootstrap.ps1` **sin duplicar lógica** — ambos scripts usan funciones compartidas en `scripts/mcp-functions.ps1`.
- **FR-005**: El sistema DEBE ser invocable por el agente `pensador` mediante tarea delegada.
- **FR-006**: El sistema DEBE mantener idempotencia: ejecutar múltiples veces sin cambios si los MCPs ya están actualizados.
- **FR-007**: El sistema DEBE reportar estado por MCP: instalado, actualizado, ya actualizado, error.
  - Formato de reporte: línea por MCP con `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA`. Estados permitidos: `INSTALLED`, `UPDATED`, `UP_TO_DATE`, `ERROR`, `SKIPPED`.
- **FR-008**: El sistema DEBE respetar el inventario central `.env.mcp` y no crear rutas absolutas en archivos versionados.
- **FR-009**: El sistema DEBE **verificar y actualizar** `.env.mcp`: si encuentra valores, validar que sean rutas correctas; si están vacíos o incorrectos, resolver y actualizar con rutas reales.
- **FR-010**: El sistema DEBE actualizar `opencode.json` resolviendo tokens `{env:...}` a rutas reales y habilitando MCPs (`enabled: true`).

### Key Entities

- **`scripts/update-mcp.ps1`**: Script independiente de actualización de MCPs.
- **`.bootstrap-state.json`**: Archivo de estado con última fecha de actualización de MCPs.
- **`.env.mcp`**: Inventario central de rutas de MCPs, fuente única de verdad.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El script `update-mcp.ps1` instala/actualiza los MCPs en menos de 2 minutos en una ejecución típica.
- **SC-002**: Tras ejecutar el script, el 100% de los MCPs instalados quedan `enabled: true` con rutas válidas.
- **SC-003**: La auto-actualización diaria se ejecuta correctamente cuando han pasado >24h desde la última actualización.
- **SC-004**: El bootstrap invoca `update-mcp.ps1` sin errores en el 100% de las ejecuciones.
- **SC-005**: El agente `pensador` puede solicitar actualización de MCPs y recibir reporte de estado.

## Assumptions

- Los MCPs se instalan desde fuentes conocidas y publicadas.
- El usuario tiene permisos de escritura en `scripts/` y raíz del proyecto.
- `.bootstrap-state.json` es gitignored y no se versiona.
- El script se ejecuta en PowerShell 7+ en Windows.
