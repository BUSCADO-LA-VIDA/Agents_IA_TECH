# Plan 023 - Actualizaciones Copilot Agents y MCP

## Resumen técnico
Actualizar documentación y agentes del KIT para alinearse con los últimos cambios de GitHub Copilot en agentes personalizados y MCP.

## Arquitectura de solución
* Documentar cambios en spec
* Actualizar agentes .github y .opencode con sección MCPs compatible
* Actualizar skill ssh-connection-agent con limitaciones Copilot
* Crear patrón de frontmatter mcp-servers

## Desglose técnico
FR-01: Resumen de cambios Copilot + MCP en documento de referencia
FR-02: Frontmatter agentes actualizado
FR-03: Agent Plugins 1.0 documentado
FR-04: Orden de procesamiento MCP documentado
FR-05: Agentes actualizados
FR-06: Validar tipo de MCP servers
FR-07: Validar paridad harnesses

## Dependencias
* Acceso a docs Copilot vía Context7
* Scripts sync-kit existentes

## Riesgos
* Cambios futuros en Copilot pueden romper compatibilidad
* Paridad entre harnesses

## Criterios de verificación
* spec completo sin placeholders
* Agentes actualizados
* Verificación qa-senior PASS
