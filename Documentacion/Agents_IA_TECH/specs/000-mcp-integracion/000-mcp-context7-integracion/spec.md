# Feature Specification: [000-mcp-context7-integracion] — Integración oficial de Context7 MCP en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/upstash/context7` — Herramienta MCP para documentación oficial actualizada

**Feature Branch**: `000-mcp-context7-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Requerimiento de integrar los 8 MCPs externos como *proyect_ext*, empezando por Context7 MCP. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y los proyectos consumidores necesitan acceder a documentación oficial actualizada de bibliotecas y frameworks sin alucinaciones. Context7 MCP es la fuente oficial que provee documentación verificada con citas y fecha.

Actualmente no existe una especificación formal para:
1. Habilitar Context7 MCP en `opencode.json` / `.vscode/mcp.json` con el patrón de tokens / `{env:...}` ya establecido por la spec 007.
2. Definir el procedimiento de instalación, verificación y fallback cuando la herramienta no está disponible.
3. Garantizar que la integración sea idempotente, fail-open y retrocompatible con el bootstrap `scripts/plataformador-bootstrap.ps1`.

Sin spec, la activación queda manual, propensa a errores y fuera de la gobernanza SSD.

**Impacto**: Sin Context7, los agentes pierden contexto actualizado, aumentan alucinaciones de APIs y se reduce la calidad de las respuestas.

---

## Objetivos

- Que Context7 MCP esté disponible y `enabled: true` en el kit maestro y en proyectos consumidores tras ejecutar el bootstrap.
- Que la integración siga el patrón de tokens / `.env.mcp` establecido por la spec 007.
- Que la instalación sea fail-open con WARN accionable si la herramienta no está instalada.
- Que la spec sea el artefacto de trazabilidad para los demás MCPs de la lista.

---

## Requisitos Funcionales

### RF-01 — Habilitar Context7 MCP en `opencode.json`

La plantilla versionada `opencode.json` DEBE incluir la entrada `context7` con:
- `type: "stdio"`
- `command: ["{env:CONTEXT7_CMD}"]`
- `args: ["--stdio"]`
- `enabled: false` en plantilla, promovido a `true` en runtime si la herramienta se resuelve.

**Criterios de aceptación**:
- Dado el bootstrap, cuando `CONTEXT7_CMD` está definido, entonces `enabled: true` y `command` resuelto.
- La plantilla versionada no contiene rutas absolutas.

### RF-02 — Resolución de ruta vía `.env.mcp`

El bootstrap DEBE resolver `context7` vía `Resolve-McpCommand` y crear/actualizar `.env.mcp` con `CONTEXT7_CMD`.

**Criterios de aceptación**:
- `.env.mcp` contiene `CONTEXT7_CMD=<ruta>` o está vacío + WARN.
- `opencode.json` referencia `{env:CONTEXT7_CMD}`.

### RF-03 — Fallback fail-open

Si `context7` no está instalado o `context7 --version` falla, el bootstrap NO debe registrar la entrada rota; debe emitir WARN con comando exacto de instalación:

`npm install -g @upstash/context7-mcp`

**Criterios de aceptación**:
- Herramienta ausente → entrada NO registrada + WARN accionable.
- Bootstrap continúa sin abortar.

### RF-04 — Paridad de configuración

La entrada DEBE existir en `.opencode/mcp.json` y `.vscode/mcp.json` con el mismo patrón.

**Criterios de aceptación**:
- Ambas configuraciones sincronizadas por `Sync-TransversalKit`.
- No se versiona ruta absoluta.

### RF-05 — Documentación de uso

`quickstart.md` DEBE incluir comando de verificación:

`context7 --list-sources` y ejemplo de consulta.

**Criterios de aceptación**:
- Usuario puede validar operación tras bootstrap.

---

## Requisitos No Funcionales

- **RNF-01 Seguridad**: No commitear rutas absolutas; `.env.mcp` gitignored.
- **RNF-02 Retrocompatibilidad**: No romper MCPs existentes.
- **RNF-03 Idempotencia**: Múltiples corridas no duplican entrada.
- **RNF-04 Fail-open**: Ausencia de herramienta = WARN, no aborta.
- **RNF-05 Conventional commits**.

---

## Fuera de Alcance

- Desarrollar o modificar el código de Context7 MCP.
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros 7 MCPs en esta spec — cada uno tendrá su propia spec.

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp`, `Resolve-McpCommand`.
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/spec.md` — patrón de tokens y `.env.mcp`.
- `opencode.json` plantilla versionada.
- Herramienta externa `@upstash/context7-mcp` (npm).

---

## Criterios de Éxito

- **SC-001**: Bootstrap deja `context7` `enabled: true` si la herramienta está instalada.
- **SC-002**: `git check-ignore .env.mcp` → 0 y plantilla sin rutas absolutas.
- **SC-003**: Herramienta ausente → WARN con comando exacto de instalación, bootstrap continúa.
- **SC-004**: Entrada presente en `.opencode/mcp.json` y `.vscode/mcp.json`.
- **SC-005**: Segunda corrida del bootstrap produce bloque `mcp` idéntico.

---

## Assumptions

- OpenCode soporta interpolación `{env:CONTEXT7_CMD}`.
- La herramienta se instala vía npm global y expone `context7 --stdio`.
- El usuario acepta instalar la herramienta externa manualmente si falla el auto-detect.

