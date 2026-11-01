# Feature Specification: 002-script-plataforming-sync-kit — Scripts de sincronización y despliegue del kit

**Feature Branch**: `002-script-plataforming-sync-kit`

**Created**: 2026-10-07

**Status**: Draft

**Input**: Consolidación de la funcionalidad de sincronización y despliegue del kit `Agents_IA_TECH`, extrayendo de la spec 009 los componentes relacionados con scripts y despliegue, y documentando el protocolo completo para mantener los kits actualizados en todos los proyectos consumidores.

---

## Problema

El kit `Agents_IA_TECH` requiere mecanismos para:

1. **Actualizar MCPs independientemente** del bootstrap completo (`update-mcp.ps1`).
2. **Normalizar rutas MCP** a forward slashes para evitar errores `InvalidEscapeCharacter` en `opencode.json`.
3. **Sincronizar el kit transversal** (`.github/`, `.opencode/`, `.doc_agents/`, `scripts/`, `constitution.md`, etc.) en todos los proyectos.
4. **Auto-actualización diaria** de MCPs sin intervención manual.
5. **Integración con el agente `pensador`** para delegar tareas de actualización.

Actualmente, esta funcionalidad está dispersa en la spec 009 (MCP Update Lifecycle y Path Normalization) y no está documentada como un flujo independiente que pueda ser invocado por cualquier proyecto que implemente el kit.

---

## Objetivos

- **Q001**: Crear un script independiente `scripts/update-mcp.ps1` que gestione la instalación, actualización y activación de MCPs.
- **Q002**: Implementar normalización de rutas a forward slashes en la resolución de MCP para evitar errores JSON.
- **Q003**: Documentar el protocolo de sincronización del kit transversal usando `plataformador-bootstrap.ps1` (flujo completo, interfaz simplificada) o `sync-kit.ps1` directo (motor de sync).
- **Q004**: Establecer el mecanismo de auto-actualización diaria basada en `.bootstrap-state.json` y ventana de 24h.
- **Q005**: Integrar las tareas de actualización en el agente `pensador` y `.opencode/agents/pensador.md`.
- **Q006**: Asegurar que el archivo `AGENTS.md` raíz mantiene reglas generales y la personalización por proyecto está en `Documentacion/<AppName>/`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Actualizar MCPs de forma independiente (Priority: P1)

**Actor**: Usuario / Agente `pensador`

**Flujo**: El usuario ejecuta `pwsh scripts/update-mcp.ps1` y verifica que los MCPs quedan instalados/actualizados y habilitados.

**Criterio de aceptación**: QA puede listar y ejecutar suites de prueba sin configuración manual adicional, y el script reporta estado por MCP (`INSTALLED`, `UPDATED`, `UP_TO_DATE`, `ERROR`, `SKIPPED`).

**Acceptance Scenarios**:
1. **Given** un MCP desactualizado, **When** se ejecuta `update-mcp.ps1`, **Then** el MCP se actualiza a la última versión disponible.
2. **Given** un MCP no instalado, **When** se ejecuta `update-mcp.ps1`, **Then** el MCP se instala y queda habilitado.
3. **Given** un MCP ya actualizado, **When** se ejecuta `update-mcp.ps1`, **Then** el script informa "ya actualizado" y no realiza cambios.

---

### User Story 2 - Auto-actualización diaria (Priority: P2)

**Actor**: Sistema / Agente `pensador`

**Flujo**: El script verifica automáticamente si han pasado más de 24h desde la última actualización y actualiza los MCPs sin intervención manual, para garantizar que los MCPs siempre estén frescos.

**Criterio de aceptación**: Simulando `.bootstrap-state.json` antiguo y ejecutando el script; debe detectar que es necesario actualizar.

**Acceptance Scenarios**:
1. **Given** `.bootstrap-state.json` con última actualización hace >24h, **When** se ejecuta `update-mcp.ps1`, **Then** se actualizan los MCPs y se registra nueva fecha.
2. **Given** `.bootstrap-state.json` con última actualización hace <24h, **When** se ejecuta `update-mcp.ps1`, **Then** se omite la actualización y se informa "actualizado recientemente".

---

### User Story 3 - Sincronización del kit transversal (Priority: P2)

**Actor**: Agente `plataformador` / Usuario

**Flujo**: Ejecutar `plataformador-bootstrap.ps1` (flujo completo, paso 3 incluido) o `sync-kit.ps1` directo para sincronizar los archivos transversales (`.github/`, `.opencode/`, `.doc_agents/`, `scripts/`, `constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`, `upgrade_framework.ps1`) desde la fuente del kit (repositorio maestro en GitHub, o checkout local con `-KitPath`).

**Criterio de aceptación**: Los archivos transversales del proyecto coinciden con la fuente del kit; `Documentacion/<AppName>/` no se toca (frontera kit ↔ app).

**Acceptance Scenarios**:
1. **Given** ejecución de `plataformador-bootstrap.ps1`, **When** finaliza, **Then** los archivos `.github/`, `.opencode/`, `scripts/`, etc. están actualizados desde la fuente del kit.
2. **Given** proyecto con personalizaciones en `Documentacion/<AppName>/`, **When** se sincroniza, **Then** las personalizaciones se conservan y no se sobrescriben.
3. **Given** trabajo del kit sin pushear a GitHub, **When** se ejecuta `sync-kit.ps1 -KitPath <kit-local> -RootPath <proyecto> -Force`, **Then** el proyecto recibe rama + cambios locales (ej. `scripts/ecc-orchestrator.ps1` nuevo).

---

### User Story 4 - Integración con agente `pensador` (Priority: P2)

**Actor**: Agente `pensador`

**Flujo**: El agente `pensador` solicita la actualización de MCPs y el sistema invoca `update-mcp.ps1`, reportando el resultado en la sección correspondiente de `pendientes-implementacion.md`.

**Criterio de aceptación**: El agente `pensador` puede delegar la tarea y el flujo SSD+Speckit continúa con el estado actualizado.

**Acceptance Scenarios**:
1. **Given** el agente `pensador` solicita actualización de MCPs, **When** se ejecuta la tarea delegada, **Then** se invoca `update-mcp.ps1` y se reporta el estado en `pendientes-implementacion.md`.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE proporcionar un script independiente `scripts/update-mcp.ps1` que gestione instalación, actualización y activación de MCPs.
- **FR-002**: El sistema DEBE verificar la última fecha de actualización en `.bootstrap-state.json` y actualizar solo si han pasado más de 24h, salvo `-Force`.
- **FR-003**: El sistema DEBE registrar la fecha de última actualización en `.bootstrap-state.json` tras una actualización exitosa.
- **FR-004**: El sistema DEBE ser invocable desde `plataformador-bootstrap.ps1` sin duplicar lógica — ambos scripts usan funciones compartidas en `scripts/mcp-functions.ps1`.
- **FR-005**: El sistema DEBE ser invocable por el agente `pensador` mediante tarea delegada.
- **FR-006**: El sistema DEBE mantener idempotencia: ejecutar múltiples veces sin cambios si los MCPs ya están actualizados.
- **FR-007**: El sistema DEBE reportar estado por MCP: instalado, actualizado, ya actualizado, error.
  - Formato de reporte: línea por MCP con `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA`. Estados permitidos: `INSTALLED`, `UPDATED`, `UP_TO_DATE`, `ERROR`, `SKIPPED`.
- **FR-008**: El sistema DEBE respetar el inventario central `.env.mcp` y no crear rutas absolutas en archivos versionados.
- **FR-009**: El sistema DEBE verificar y actualizar `.env.mcp`: si encuentra valores, validar que sean rutas correctas; si están vacíos o incorrectos, resolver y actualizar con rutas reales.
- **FR-010**: El sistema DEBE actualizar `opencode.json` resolviendo tokens `{env:...}` a rutas reales y habilitando MCPs (`enabled: true`).
- **FR-011**: El sistema DEBE sincronizar el kit transversal en el flujo completo de `plataformador-bootstrap.ps1` (paso 3) o vía `sync-kit.ps1` directo, respetando la whitelist Art‑VII y sin tocar `Documentacion/<AppName>/`.
- **FR-012**: El archivo `AGENTS.md` raíz mantiene las reglas generales del kit. La personalización por proyecto debe gestionarse en `Documentacion/<AppName>/`.
- **FR-013**: El sistema DEBE aceptar un checkout local del kit como fuente de sincronización (`sync-kit.ps1 -KitPath <ruta>`), para replicar rama + cambios sin pushear. Solo acepta directorios locales con marcadores de kit (`scripts/`, `.github/`, `.opencode/`, `.doc_agents/`, `AGENTS.md`); jamás URLs ni el propio destino (fail-closed).
- **FR-014**: La interfaz del bootstrap es simplificada: sin parámetros (todo el flujo), `-DryRun` (demo sin escribir), `-Force` (sobrescribe archivos que difieren + incluye upgrade de herramientas externas). El modo kit seguro es automático (se omite el sync dentro del checkout maestro).

### Key Entities

- **`scripts/update-mcp.ps1`**: Script independiente de actualización de MCPs.
- **`.bootstrap-state.json`**: Archivo de estado con última fecha de actualización de MCPs.
- **`.env.mcp`**: Inventario central de rutas de MCPs, fuente única de verdad (portable, gitignored).
- **`scripts/mcp-functions.ps1`**: Funciones compartidas usadas por `update-mcp.ps1` y `plataformador-bootstrap.ps1`.
- **`plataformador-bootstrap.ps1`**: Bootstrap del proyecto que invoca `update-mcp.ps1` en su paso 4.
- **`sync-kit.ps1`**: Script de sincronización del kit transversal.
- **`AGENTS.md`**: Documentación de reglas generales del kit (raíz), no modificar para personalizaciones de proyecto.

### Dependencies

- **`scripts/mcp-functions.ps1`**: Funciones compartidas `Resolve-McpCommand`, `Ensure-McpEnvFile`, `Update-McpEnvFile`, `Ensure-OpenCodeMcp`.
- **`scripts/plataformador-bootstrap.ps1`**: Bootstrap que invoca `update-mcp.ps1` en su paso 4.
- **`sync-kit.ps1`**: Sincroniza el kit transversal.
- **`.env.mcp`**: Inventario central de rutas MCP.
- **`.bootstrap-state.json`**: Estado de última actualización.

### Criterios de Éxito *(mandatory)*

#### Resultados Medibles

- **SC-001**: El script `update-mcp.ps1` instala/actualiza los MCPs en menos de 2 minutos en una ejecución típica.
- **SC-002**: Tras ejecutar el script, el 100% de los MCPs instalados quedan `enabled: true` con rutas válidas.
- **SC-003**: La auto-actualización diaria se ejecuta correctamente cuando han pasado >24h desde la última actualización.
- **SC-004**: El bootstrap invoca `update-mcp.ps1` sin errores en el 100% de las ejecuciones.
- **SC-005**: El agente `pensador` puede solicitar actualización de MCPs y recibir reporte de estado.
- **SC-006**: La sincronización del kit transversal (paso 3 del bootstrap o `sync-kit.ps1` directo) completa exitosamente y conserva personalizaciones en `Documentacion/<AppName>/`.
- **SC-007**: El archivo `AGENTS.md` raíz no es modificado por las tareas de sincronización/actualización de MCPs.

---

## Edge Cases

- **EC-01**: Si un MCP falla al actualizar, el script continúa con los demás MCPs y reporta el error sin abortar.
- **EC-02**: Si `.bootstrap-state.json` no existe, el script lo crea con la fecha actual.
- **EC-03**: Si el usuario ejecuta con `-Force`, se fuerza actualización ignorando la ventana de 24h.
- **EC-04**: Si un MCP no está disponible en el repositorio, el script emite WARN y continúa.
- **EC-05**: Si el JSON de `opencode.json` queda corrupto tras la escritura, el script emite WARN y conserva el archivo anterior.
- **EC-06**: Si el agente `pensador` solicita actualización mientras hay una actualización en curso, el sistema encola la solicitud y la ejecuta después de completar la actualización actual.

---

## Assumptions

- Los MCPs se instalan desde fuentes conocidas y publicadas.
- El usuario tiene permisos de escritura en `scripts/` y raíz del proyecto.
- `.bootstrap-state.json` es gitignored y no se versiona.
- El script se ejecuta en PowerShell 7+ en Windows.
- El repositorio maestro está en `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH` (fuente por defecto del sync).
- Con trabajo del kit sin pushear, la fuente es el checkout local vía `sync-kit.ps1 -KitPath <kit-local>` (ver FR-013).

---

## Fuera de Alcance

- Desarrollar o modificar el código de los propios MCPs (solo su actualización/activación).
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros MCP externos en esta spec — cada uno tiene su propia spec.
- Modificar la lógica de bootstrap más allá de lo cubierto por esta spec (interfaz simplificada FR-014 + fuente local FR-013).

---

## Dependencias

- `scripts/mcp-functions.ps1` — Funciones compartidas (Resolve-McpCommand, Ensure-McpEnvFile, Update-McpEnvFile, Ensure-OpenCodeMcp).
- `scripts/plataformador-bootstrap.ps1` — Bootstrap que invoca update-mcp.ps1 en su paso 4.
- `sync-kit.ps1` — Sincroniza el kit transversal.
- `.env.mcp` — Inventario central de rutas MCP.
- `.bootstrap-state.json` — Estado de última actualización.

---

## Criterios de Éxito Adicionales

- El script `update-mcp.ps1` es idempotente: ejecutarlo múltiples veces no produce cambios si los MCPs ya están actualizados.
- El reporte de estado sigue el formato `MCP_NAME | ESTADO | VERSIÓN | RUTA | NOTA` exactamente.
- La sincronización del kit transversal conserva archivos en `Documentacion/<AppName>/` que no estaban en el repositorio maestro (personalizaciones por proyecto).
- El agente `pensador` puede delegar la tarea de actualización y el flujo SSD+Speckit continúa con el estado actualizado.

---