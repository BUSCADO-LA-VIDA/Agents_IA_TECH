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

---

## Addendum 2026-10-18 — Paridad incompleta y retiro pendiente de decisión

La tarea **T04 "Paridad configuraciones"** de esta spec se dio por cumplida (`[x]`) tras verificar que el MCP aparecía en `opencode.json` y `.vscode/mcp.json`. Esa verificación era **insuficiente**: cubría la capa de configuración, no la capa de agentes.

El 2026-10-18, al cruzar los MCPs registrados contra las 32 definiciones de agente, `semgrep` resultó **0 de 32**: ningún agente del kit lo declaraba en su sección "Uso de MCPs", pese a estar instalado y con handshake verificado.

El mismo cruce llevó a retirar el MCP de `opencode.json` bajo el criterio erróneo de que "cero usos" significaba "sobra". **Ese razonamiento fue corregido**: un MCP instalado que ningún agente declara es una implementación incompleta, y la corrección corresponde al agente, no al retiro del MCP. `context7` y `tokenslayer` fueron restituidos por ese motivo.

**Estado actual**: `semgrep` está instalado en la máquina pero **no está en `opencode.json`** y no figura en el reparto de agentes de la spec 020 (RF-05). Queda abierta la decisión de readmitirlo junto con su declaración en `security-auditor` y `qa-senior`.

**Nuevo criterio de cierre** (incorporado a la spec 020 como RF-05): una integración de MCP no se cierra por tener la entrada en la configuración, sino por tener **al menos un agente que lo declare con el nombre de sus herramientas**.
