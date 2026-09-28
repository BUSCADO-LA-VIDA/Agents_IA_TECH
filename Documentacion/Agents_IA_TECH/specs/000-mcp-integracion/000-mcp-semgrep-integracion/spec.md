# Feature Specification: [000-mcp-semgrep-integracion] — Integración oficial de Semgrep MCP en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/semgrep/mcp` — Herramienta MCP para análisis estático de seguridad (Semgrep)

**Feature Branch**: `000-mcp-semgrep-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Integración de 8 MCPs externos como proyect_ext. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y proyectos consumidores necesitan análisis estático de seguridad (SAST) gestionado por agentes. Semgrep MCP expone capacidades de scanning de Semgrep vía MCP, complementando al agente `security-auditor`.

Actualmente no existe especificación formal para habilitar Semgrep MCP con el patrón de tokens `{env:...}`, definir instalación/verificación/fallback, y garantizar idempotencia con el bootstrap. Sin spec, la activación queda manual y fuera de la gobernanza SSD.

**Impacto**: Sin Semgrep MCP, el análisis de seguridad automatizado pierde la capacidad de escanear código desde los agentes y las vulnerabilidades se detectan tarde.

---

## Objetivos

- Que Semgrep MCP esté disponible y `enabled: true` tras ejecutar el bootstrap.
- Que la integración siga el patrón de tokens / `.env.mcp` de la spec 007.
- Que la instalación sea fail-open con WARN accionable.
- Que la spec sea trazable para el resto de MCPs.

---

## User Scenarios & Testing

### US1 — Security auditor escanea código
**Actor**: Agente `security-auditor`
**Flujo**: Bootstrap resuelve `SEMGREP_MCP_CMD` → entrada activa → auditor invoca Semgrep MCP para escanear el repo y obtener hallazgos.
**Criterio de aceptación**: Auditor puede lanzar un scan y recibir hallazgos estructurados sin configuración manual.

### US2 — Usuario valida operación
**Actor**: Desarrollador humano
**Flujo**: Tras bootstrap, ejecuta verificación documentada en `quickstart.md`.
**Criterio de aceptación**: `quickstart.md` incluye comando de verificación y ejemplo de scan; confirmación en menos de 2 minutos.

---

## Requisitos Funcionales

### RF-01 — Habilitar Semgrep MCP en `opencode.json`
La plantilla versionada DEBE incluir la entrada `semgrep` con `type: "stdio"`, `command: ["{env:SEMGREP_MCP_CMD}"]`, y `enabled` controlado por runtime.
**Criterios de aceptación**: Dado el bootstrap, cuando `SEMGREP_MCP_CMD` está definido, entonces `enabled: true`. Plantilla sin rutas absolutas.

### RF-02 — Resolución de ruta vía `.env.mcp`
El bootstrap DEBE resolver `semgrep` vía `Resolve-McpCommand` y crear/actualizar `.env.mcp` con `SEMGREP_MCP_CMD`.
**Criterios de aceptación**: `.env.mcp` contiene `SEMGREP_MCP_CMD=<ruta>` o vacío + WARN. `opencode.json` referencia `{env:SEMGREP_MCP_CMD}`.

### RF-03 — Fallback fail-open
Si Semgrep MCP no está instalado o `semgrep --version` falla, el bootstrap NO registra la entrada rota; emite WARN accionable y continúa.
**Criterios de aceptación**: Herramienta ausente → entrada NO registrada + WARN con comando exacto. Bootstrap continúa.

### RF-04 — Paridad de configuración
La entrada DEBE existir en `.opencode/mcp.json` y `.vscode/mcp.json` con el mismo patrón, sincronizada por `Sync-TransversalKit`.
**Criterios de aceptación**: Ambas configuraciones idénticas; no se versiona ruta absoluta.

### RF-05 — Documentación de uso
`quickstart.md` DEBE incluir comando de verificación de Semgrep y ejemplo de scan.
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
- **EC-04**: Token de API de Semgrep Cloud no configurado → WARN con instrucción; scans locales siguen funcionando si el binario existe.

---

## Fuera de Alcance

- Desarrollar o modificar Semgrep MCP.
- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode.
- Integrar los otros 7 MCPs en esta spec.

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp`, `Resolve-McpCommand`.
- `Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md`.
- `AGENTS.md` y `.specify/memory/constitution.md` — gobernanza transversal.
- Herramienta externa Semgrep MCP (Semgrep / npm).

---

## Criterios de Éxito

- **SC-001**: Bootstrap deja `semgrep` `enabled: true` si la herramienta está instalada.
- **SC-002**: `git check-ignore .env.mcp` → 0 y plantilla sin rutas absolutas.
- **SC-003**: Herramienta ausente → WARN con comando exacto, bootstrap continúa.
- **SC-004**: Entrada presente en `.opencode/mcp.json` y `.vscode/mcp.json`.
- **SC-005**: Segunda corrida del bootstrap produce bloque `mcp` idéntico.

---

## Assumptions

- OpenCode soporta interpolación `{env:SEMGREP_MCP_CMD}`.
- La herramienta expone interfaz stdio y binario verificable con `semgrep --version`.
- El usuario acepta instalar la herramienta externa manualmente si falla el auto-detect.
