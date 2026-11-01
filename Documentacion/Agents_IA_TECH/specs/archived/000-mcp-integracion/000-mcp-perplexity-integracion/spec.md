# Feature Specification: [000-mcp-perplexity-integracion] — Integración oficial de Perplexity MCP en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/perplexity-ai/mcp-server-perplexity` — Herramienta MCP de búsqueda web con IA (Perplexity)

**Feature Branch**: `000-mcp-perplexity-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Integración de 8 MCPs externos como proyect_ext. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y proyectos consumidores necesitan búsqueda web con IA y respuestas con fuentes para investigación gestionada por agentes. Perplexity MCP expone la API de Perplexity vía MCP.

Actualmente no existe especificación formal para habilitar Perplexity MCP con el patrón de tokens `{env:...}`, definir instalación/verificación/fallback, y garantizar idempotencia con el bootstrap. Sin spec, la activación queda manual y fuera de la gobernanza SSD.

**Impacto**: Sin Perplexity MCP, la investigación de agentes depende solo de fetch estático y pierde respuestas sintetizadas con citas.

**Nota**: La URL exacta del repositorio y del paquete de instalación debe verificarse contra la documentación oficial de Perplexity antes de implementar.

---

## Objetivos

- Que Perplexity MCP esté disponible y `enabled: true` tras ejecutar el bootstrap.
- Que la integración siga el patrón de tokens / `.env.mcp` de la spec 007.
- Que la instalación sea fail-open con WARN accionable.
- Que la spec sea trazable para el resto de MCPs.

---

## User Scenarios & Testing

### US1 — Agente investiga con búsqueda web
**Actor**: Agente documental (pensador/documentador)
**Flujo**: Bootstrap resuelve `PERPLEXITY_MCP_CMD` → entrada activa → agente consulta Perplexity MCP para investigación con fuentes.
**Criterio de aceptación**: Agente puede lanzar una consulta y recibir respuesta con fuentes sin configuración manual.

### US2 — Usuario valida operación
**Actor**: Desarrollador humano
**Flujo**: Tras bootstrap, ejecuta verificación documentada en `quickstart.md`.
**Criterio de aceptación**: `quickstart.md` incluye comando de verificación y ejemplo; confirmación en menos de 2 minutos.

---

## Requisitos Funcionales

### RF-01 — Habilitar Perplexity MCP en `opencode.json`
La plantilla versionada DEBE incluir la entrada `perplexity` con `type: "stdio"`, `command: ["{env:PERPLEXITY_MCP_CMD}"]`, y `enabled` controlado por runtime.
**Criterios de aceptación**: Dado el bootstrap, cuando `PERPLEXITY_MCP_CMD` está definido, entonces `enabled: true`. Plantilla sin rutas absolutas.

### RF-02 — Resolución de ruta vía `.env.mcp`
El bootstrap DEBE resolver `perplexity` vía `Resolve-McpCommand` y crear/actualizar `.env.mcp` con `PERPLEXITY_MCP_CMD`.
**Criterios de aceptación**: `.env.mcp` contiene `PERPLEXITY_MCP_CMD=<ruta>` o vacío + WARN. `opencode.json` referencia `{env:PERPLEXITY_MCP_CMD}`.

### RF-03 — Fallback fail-open
Si Perplexity MCP no está instalado o la verificación falla, el bootstrap NO registra la entrada rota; emite WARN accionable y continúa.
**Criterios de aceptación**: Herramienta ausente → entrada NO registrada + WARN con comando exacto. Bootstrap continúa.

### RF-04 — Paridad de configuración
La entrada DEBE existir en `.opencode/mcp.json` y `.vscode/mcp.json` con el mismo patrón, sincronizada por `Sync-TransversalKit`.
**Criterios de aceptación**: Ambas configuraciones idénticas; no se versiona ruta absoluta.

### RF-05 — Documentación de uso
`quickstart.md` DEBE incluir comando de verificación de Perplexity MCP y ejemplo de consulta.
**Criterios de aceptación**: Usuario puede validar operación tras bootstrap sin ayuda adicional.

---

## Requisitos No Funcionales

- **RNF-01 Seguridad**: No commitear rutas absolutas ni API keys; `.env.mcp` gitignored.
- **RNF-02 Retrocompatibilidad**: No romper MCPs existentes.
- **RNF-03 Idempotencia**: Múltiples corridas no duplican entrada.
- **RNF-04 Fail-open**: Ausencia de herramienta = WARN, no aborta.
- **RNF-05 Conventional commits**.

---

## Edge Cases

- **EC-01**: Token definido pero binario eliminado → WARN y no registrar entrada rota.
- **EC-02**: `.env.mcp` ausente → bootstrap lo crea con clave vacía + WARN.
- **EC-03**: Entrada pre-existente manual → bootstrap la respeta y no la duplica.
- **EC-04**: API key de Perplexity no configurada → WARN con instrucción de configurar `PERPLEXITY_API_KEY`; entrada permanece registrada si el binario existe.

---

## Fuera de Alcance

- Desarrollar o modificar Perplexity MCP.
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros 7 MCPs en esta spec.

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp`, `Resolve-McpCommand`.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md`.
- `AGENTS.md` y `.specify/memory/constitution.md` — gobernanza transversal.
- Herramienta externa Perplexity MCP (requiere API key).

---

## Criterios de Éxito

- **SC-001**: Bootstrap deja `perplexity` `enabled: true` si la herramienta está instalada.
- **SC-002**: `git check-ignore .env.mcp` → 0 y plantilla sin rutas absolutas ni API keys.
- **SC-003**: Herramienta ausente → WARN con comando exacto, bootstrap continúa.
- **SC-004**: Entrada presente en `.opencode/mcp.json` y `.vscode/mcp.json`.
- **SC-005**: Segunda corrida del bootstrap produce bloque `mcp` idéntico.

---

## Assumptions

- OpenCode soporta interpolación `{env:PERPLEXITY_MCP_CMD}`.
- La herramienta expone interfaz stdio y requiere API key de Perplexity.
- El usuario acepta instalar la herramienta externa manualmente si falla el auto-detect.
