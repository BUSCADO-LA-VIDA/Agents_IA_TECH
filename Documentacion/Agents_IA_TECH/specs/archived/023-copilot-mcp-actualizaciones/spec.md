# Spec 023 - Actualizaciones Copilot Agents y MCP

## Resumen
Documentar cambios recientes en GitHub Copilot para agentes y MCP, y adaptar los agentes del KIT a las nuevas capacidades de frontmatter mcp-servers, herramientas y model policy.

## Motivo
Hubo cambios en Copilot en las últimas 5 actualizaciones relacionadas con agentes personalizados, MCP servers por agente, agent plugins 1.0 y configuración de frontmatter.

## Requisitos Funcionales
FR-01: Documentar soporte de mcp-servers en frontmatter de agentes personalizados.
FR-02: Documentar campos de frontmatter de agente: name, description, tools, mcp-servers, model, models, modelPolicy, reasoningEffort, include-custom-instructions, infer.
FR-03: Documentar Agent Plugins 1.0 con mcp.json esquema y variables ${PLUGIN_ROOT} / ${PLUGIN_DATA}.
FR-04: Documentar procesamiento de MCP por agente: prioridad custom agent > default > repository.
FR-05: Actualizar agentes .github/agents/*.agent.md y .opencode/agents/*.md para incluir sección MCPs compatible con nuevo schema.
FR-06: Asegurar que MCP servers declarados en agentes usan type local/http/streamable-http y env con secrets.
FR-07: Validar que agentes del KIT no rompen con nueva sintaxis de frontmatter.

## Requisitos No Funcionales
RNF-01: Documentación en español latino neutro.
RNF-02: Sin placeholders.
RNF-03: Artefactos en Documentacion/Agents_IA_TECH/specs/023-copilot-mcp-actualizaciones/

## Restricciones
- No modificar lógica de implementación de apps.
- Mantener paridad entre .github y .opencode.
- No exponer secretos en frontmatter.

## Criterios de Aceptación
SC-01: spec.md completo sin placeholders.
SC-02: plan.md, tasks.md, analyze.md, converge.md creados.
SC-03: Agentes actualizados con sección MCPs compatible.
SC-04: Verificación qa-senior PASS.
