# Feature Specification: [000-mcp-testsprite-integracion] — Integración oficial de TestSprite MCP en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/testsprite/testsprite-mcp` — Herramienta MCP para pruebas automatizadas TestSprite

**Feature Branch**: `000-mcp-testsprite-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Integración de 8 MCPs externos como proyect_ext. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y proyectos consumidores necesitan ejecutar pruebas automatizadas gestionadas por agentes QA sin configuración manual. TestSprite MCP es la herramienta externa que provee generación y ejecución de tests end-to-end.

Actualmente no existe especificación formal para:
1. Habilitar TestSprite MCP en `opencode.json` / `.vscode/mcp.json` con el patrón de tokens `{env:...}` establecido por la spec 007.
2. Definir instalación, verificación y fallback cuando la herramienta no está disponible.
3. Garantizar idempotencia y retrocompatibilidad con `scripts/plataformador-bootstrap.ps1`.

Sin spec, la activación queda manual, propensa a errores y fuera de la gobernanza SSD.

**Impacto**: Sin TestSprite, el agente `qa-senior` pierde la capacidad de orquestar pruebas automatizadas y el feedback loop de calidad queda manual.

---

## Objetivos

- Que TestSprite MCP esté disponible y `enabled: true` en el kit maestro y proyectos consumidores tras ejecutar el bootstrap.
- Que la integración siga el patrón de tokens / `.env.mcp` establecido por la spec 007.
- Que la instalación sea fail-open con WARN accionable si la herramienta no está instalada.
- Que la spec sea trazable para el resto de MCPs de la lista.

---

## User Scenarios & Testing

### US1 — QA ejecuta pruebas tras bootstrap
**Actor**: Agente `qa-senior`
**Flujo**: Bootstrap resuelve `TESTSPRITE_MCP_CMD` → entrada activa en opencode.json → QA invoca TestSprite MCP para generar y ejecutar tests.
**Criterio de aceptación**: QA puede listar y ejecutar suites de prueba sin configuración manual adicional.

### US2 — Usuario valida operación
**Actor**: Desarrollador humano
**Flujo**: Tras bootstrap, ejecuta verificación documentada en `quickstart.md`.
**Criterio de aceptación**: `quickstart.md` incluye comando de verificación y ejemplo de invocación; el usuario confirma operación en menos de 2 minutos.

### US3 — Proyecto nuevo hereda integración
**Actor**: Agente `plataformador`
**Flujo**: Bootstrap de proyecto nuevo copia plantilla con entrada TestSprite → resuelve token → activa si disponible.
**Criterio de aceptación**: Proyecto nuevo queda con TestSprite operativo sin pasos manuales fuera del bootstrap.

---

## Requisitos Funcionales

### RF-01 — Habilitar TestSprite MCP en `opencode.json`
La plantilla versionada `opencode.json` DEBE incluir la entrada `testsprite` con `type: "stdio"`, `command: ["{env:TESTSPRITE_MCP_CMD}"]`, y `enabled` controlado por runtime.
**Criterios de aceptación**: Dado el bootstrap, cuando `TESTSPRITE_MCP_CMD` está definido, entonces `enabled: true`. La plantilla versionada no contiene rutas absolutas.

### RF-02 — Resolución de ruta vía `.env.mcp`
El bootstrap DEBE resolver `testsprite` vía `Resolve-McpCommand` y crear/actualizar `.env.mcp` con `TESTSPRITE_MCP_CMD`.
**Criterios de aceptación**: `.env.mcp` contiene `TESTSPRITE_MCP_CMD=<ruta>` o está vacío + WARN. `opencode.json` referencia `{env:TESTSPRITE_MCP_CMD}`.

### RF-03 — Fallback fail-open
Si `testsprite` no está instalado o la verificación falla, el bootstrap NO registra la entrada rota; emite WARN accionable con comando de instalación y continúa sin abortar.
**Criterios de aceptación**: Herramienta ausente → entrada NO registrada + WARN con comando exacto. Bootstrap continúa.

### RF-04 — Paridad de configuración
La entrada DEBE existir en `.opencode/mcp.json` y `.vscode/mcp.json` con el mismo patrón, sincronizada por `Sync-TransversalKit`.
**Criterios de aceptación**: Ambas configuraciones idénticas; no se versiona ruta absoluta.

### RF-05 — Documentación de uso
`quickstart.md` DEBE incluir comando de verificación de TestSprite y ejemplo de consulta de suites.
**Criterios de aceptación**: Usuario puede validar operación tras bootstrap sin ayuda adicional.

---

## Requisitos No Funcionales

- **RNF-01 Seguridad**: No commitear rutas absolutas; `.env.mcp` gitignored.
- **RNF-02 Retrocompatibilidad**: No romper MCPs existentes.
- **RNF-03 Idempotencia**: Múltiples corridas no duplican entrada.
- **RNF-04 Fail-open**: Ausencia de herramienta = WARN, no aborta.
- **RNF-05 Conventional commits** en todos los cambios.

---

## Edge Cases

- **EC-01**: Token definido en `.env.mcp` pero binario eliminado → bootstrap emite WARN y no registra entrada rota.
- **EC-02**: `.env.mcp` ausente en proyecto consumidor → bootstrap lo crea solo con la clave `TESTSPRITE_MCP_CMD` vacía + WARN.
- **EC-03**: Entrada pre-existente manual en `opencode.json` → bootstrap la respeta y no la duplica.
- **EC-04**: Credenciales de TestSprite no configuradas → WARN con instrucción de autenticación, entrada permanece registrada si el binario existe.

---

## Fuera de Alcance

- Desarrollar o modificar el código de TestSprite MCP.
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros 7 MCPs en esta spec — cada uno tiene su propia spec.

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp`, `Resolve-McpCommand`.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md` — patrón de tokens y `.env.mcp`.
- `AGENTS.md` y `.specify/memory/constitution.md` — gobernanza transversal.
- Herramienta externa TestSprite MCP (npm).

---

## Criterios de Éxito

- **SC-001**: Bootstrap deja `testsprite` `enabled: true` si la herramienta está instalada.
- **SC-002**: `git check-ignore .env.mcp` → 0 y plantilla sin rutas absolutas.
- **SC-003**: Herramienta ausente → WARN con comando exacto de instalación, bootstrap continúa.
- **SC-004**: Entrada presente en `.opencode/mcp.json` y `.vscode/mcp.json`.
- **SC-005**: Segunda corrida del bootstrap produce bloque `mcp` idéntico.

---

## Assumptions

- OpenCode soporta interpolación `{env:TESTSPRITE_MCP_CMD}`.
- La herramienta se instala vía npm y expone interfaz stdio.
- El usuario acepta instalar la herramienta externa manualmente si falla el auto-detect.
