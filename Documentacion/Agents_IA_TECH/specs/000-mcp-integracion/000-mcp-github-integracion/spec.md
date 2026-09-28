# Feature Specification: [000-mcp-github-integracion] — Integración oficial de GitHub MCP Server en el kit maestro y proyectos consumidores

**Origen**: `https://github.com/github/github-mcp-server` — Herramienta MCP para operaciones de repositorio GitHub

**Feature Branch**: `000-mcp-github-integracion`

**Created**: 2026-09-28

**Status**: Draft

**Input**: Integración de 8 MCPs externos como proyect_ext. No se desarrollará el MCP, solo se usará.

---

## Problema

El kit maestro y proyectos consumidores necesitan interactuar con repositorios GitHub de forma segura y trazable desde agentes.

Actualmente no existe especificación formal para:
1. Habilitar GitHub MCP en opencode.json / .vscode/mcp.json con patrón de tokens {env:...}
2. Definir instalación, verificación y fallback
3. Garantizar idempotencia y retrocompatibilidad con bootstrap

Sin spec, la activación queda manual y fuera de gobernanza SSD.

---

## Objetivos

- GitHub MCP disponible y enabled:true tras bootstrap
- Integración sigue patrón tokens / .env.mcp de spec 007
- Instalación fail-open con WARN accionable
- Spec trazable para los demás MCPs

---

## Requisitos Funcionales

### RF-01 — Habilitar GitHub MCP en opencode.json
Entrada `github` con type stdio, command `{env:GITHUB_MCP_CMD}`, args, enabled controlado.

### RF-02 — Resolución vía .env.mcp
Bootstrap resuelve GITHUB_MCP_CMD y actualiza .env.mcp

### RF-03 — Fallback fail-open
Si no instalado, emitir WARN con comando de instalación y continuar

### RF-04 — Paridad de configuración
Presente en .opencode/mcp.json y .vscode/mcp.json

### RF-05 — Documentación de uso
quickstart.md incluye verificación `github --list-repos`

---

## Requisitos No Funcionales

- Seguridad: no commitear rutas absolutas, .env.mcp gitignored
- Retrocompatibilidad
- Idempotencia
- Fail-open
- Conventional commits

---

## Fuera de Alcance

- Desarrollar/modificar GitHub MCP Server
- Cambiar mecanismo de interpolación OpenCode

---

## Dependencias

- scripts/plataformador-bootstrap.ps1
- Documentacion/Agents_IA_TECH/specs/000-mcp-gobernanza/007-mcp-token-resolution/spec.md
- Herramienta externa @github/github-mcp-server

---

## Criterios de Éxito

- SC-001: Bootstrap deja github enabled:true si herramienta instalada
- SC-002: .env.mcp gitignored y plantilla sin rutas absolutas
- SC-003: Ausente → WARN con comando instalación
- SC-004: Entrada presente en ambas configuraciones
- SC-005: Idempotencia

---

## Assumptions

- OpenCode soporta {env:GITHUB_MCP_CMD}
- Herramienta instalada vía npm y expone github --stdio
