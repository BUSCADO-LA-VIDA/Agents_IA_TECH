# Feature Specification: [000-mcp-pieces-integracion] — Integración oficial de Pieces MCP en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/pieces-app/pieces-mcp` — Herramienta MCP de memoria de contexto y snippets (Pieces)

**Feature Branch**: `000-mcp-pieces-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Integración de 8 MCPs externos como proyect_ext. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y proyectos consumidores necesitan memoria persistente de contexto, snippets y materiales guardados accesible desde agentes. Pieces MCP expone la memoria de Pieces (Long-Term Memory) vía MCP.

Actualmente no existe especificación formal para habilitar Pieces MCP con el patrón de tokens `{env:...}`, definir instalación/verificación/fallback, y garantizar idempotencia con el bootstrap. Sin spec, la activación queda manual y fuera de la gobernanza SSD.

**Impacto**: Sin Pieces MCP, los agentes pierden acceso a memoria de largo plazo del desarrollador y el contexto entre sesiones se reduce.

---

## Objetivos

- Que Pieces MCP esté disponible y `enabled: true` tras ejecutar el bootstrap.
- Que la integración siga el patrón de tokens / `.env.mcp` de la spec 007.
- Que la instalación sea fail-open con WARN accionable.
- Que la spec sea trazable para el resto de MCPs.

---

## User Scenarios & Testing

### US1 — Agente consulta memoria de contexto
**Actor**: Cualquier agente documental/implementador
**Flujo**: Bootstrap resuelve `PIECES_MCP_CMD` → entrada activa → agente consulta memoria de Pieces por snippets/materiales relevantes.
**Criterio de aceptación**: Agente puede buscar materiales guardados sin configuración manual.

### US2 — Usuario valida operación
**Actor**: Desarrollador humano
**Flujo**: Tras bootstrap, ejecuta verificación documentada en `quickstart.md`.
**Criterio de aceptación**: `quickstart.md` incluye comando de verificación y ejemplo; confirmación en menos de 2 minutos.

---

## Requisitos Funcionales

### RF-01 — Habilitar Pieces MCP en `opencode.json`
La plantilla versionada DEBE incluir la entrada `pieces` con `type: "stdio"`, `command: ["{env:PIECES_MCP_CMD}"]`, y `enabled` controlado por runtime.
**Criterios de aceptación**: Dado el bootstrap, cuando `PIECES_MCP_CMD` está definido, entonces `enabled: true`. Plantilla sin rutas absolutas.

### RF-02 — Resolución de ruta vía `.env.mcp`
El bootstrap DEBE resolver `pieces` vía `Resolve-McpCommand` y crear/actualizar `.env.mcp` con `PIECES_MCP_CMD`.
**Criterios de aceptación**: `.env.mcp` contiene `PIECES_MCP_CMD=<ruta>` o vacío + WARN. `opencode.json` referencia `{env:PIECES_MCP_CMD}`.

### RF-03 — Fallback fail-open
Si Pieces MCP no está instalado o la verificación falla, el bootstrap NO registra la entrada rota; emite WARN accionable y continúa.
**Criterios de aceptación**: Herramienta ausente → entrada NO registrada + WARN con comando exacto. Bootstrap continúa.

### RF-04 — Paridad de configuración
La entrada DEBE existir en `.opencode/mcp.json` y `.vscode/mcp.json` con el mismo patrón, sincronizada por `Sync-TransversalKit`.
**Criterios de aceptación**: Ambas configuraciones idénticas; no se versiona ruta absoluta.

### RF-05 — Documentación de uso
`quickstart.md` DEBE incluir comando de verificación de Pieces MCP y ejemplo de consulta.
**Criterios de aceptación**: Usuario puede validar operación tras bootstrap sin ayuda adicional.

---

## Requisitos No Funcionales

- **RNF-01 Seguridad**: No commitear rutas absolutas; `.env.mcp` gitignored.
- **RNF-02 Retrocompatibilidad**: No romper MCPs existentes.
- **RNF-03 Idempotencia**: Múltiples corridas no duplican entrada.
- **RNF-04 Fail-open**: Ausencia de herramienta = WARN, no aborta.
- **RNF-05 Conventional commits**.

---

## Edge Cases

- **EC-01**: Token definido pero binario eliminado → WARN y no registrar entrada rota.
- **EC-02**: `.env.mcp` ausente → bootstrap lo crea con clave vacía + WARN.
- **EC-03**: Entrada pre-existente manual → bootstrap la respeta y no la duplica.
- **EC-04**: Pieces OS no corriendo → WARN con instrucción de iniciar Pieces OS; entrada permanece registrada si el binario existe.

---

## Fuera de Alcance

- Desarrollar o modificar Pieces MCP.
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros 7 MCPs en esta spec.

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp`, `Resolve-McpCommand`.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md`.
- `AGENTS.md` y `.specify/memory/constitution.md` — gobernanza transversal.
- Herramienta externa Pieces MCP (requiere Pieces OS).

---

## Criterios de Éxito

- **SC-001**: Bootstrap deja `pieces` `enabled: true` si la herramienta está instalada.
- **SC-002**: `git check-ignore .env.mcp` → 0 y plantilla sin rutas absolutas.
- **SC-003**: Herramienta ausente → WARN con comando exacto, bootstrap continúa.
- **SC-004**: Entrada presente en `.opencode/mcp.json` y `.vscode/mcp.json`.
- **SC-005**: Segunda corrida del bootstrap produce bloque `mcp` idéntico.

---

## Assumptions

- OpenCode soporta interpolación `{env:PIECES_MCP_CMD}`.
- La herramienta requiere Pieces OS corriendo en la máquina.
- El usuario acepta instalar la herramienta externa manualmente si falla el auto-detect.
