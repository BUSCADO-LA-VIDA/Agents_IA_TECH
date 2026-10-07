# Spec 016 - Enforcement of SSD+Speckit Flow via Agents

## 1. Contexto
El flujo SSD + Speckit ha sido saltado en múltiples ocasiones, generando ejecución de tareas sin aprobación previa del plan. Se requiere forzar el flujo mediante configuración de agents y checklist en `pendientes-implementacion.md`.

## 2. Objetivo
Garantizar que ningún agente ejecute tareas sin presentar el plan al usuario y obtener aprobación explícita, y que el `pensador` actúe como gatekeeper de la transición Plan → Implement.

## 3. Alcance
- Actualizar todos los agents en `.github/agents/` y `.opencode/agents/` con regla obligatoria en frontmatter y sección `## 🎯 Rol Scrum: Integración MCP`.
- Actualizar `pensador` para que presente plan y espere aprobación antes de delegar.
- Incorporar columna `Aprobación del plan` en `pendientes-implementacion.md`.

## 4. Requisitos
- Regla obligatoria en todos los agents: "Nunca ejecutar una tarea sin presentar el plan al usuario y obtener su aprobación explícita. Si el plan no está aprobado, detener y solicitar aprobación."
- Regla obligatoria: "El pensador es el único que puede autorizar la transición de Plan → Implement."
- `pensador` debe presentar plan y esperar respuesta Sí/No antes de delegar.
- `pendientes-implementacion.md` debe tener columna `Aprobación del plan` y marcarse antes de pasar a En progreso.

## 5. Criterios de aceptación
- Todos los agents contienen la regla en frontmatter y sección.
- `pensador` contiene lógica de gatekeeper.
- `pendientes-implementacion.md` tiene columna y se usa en nuevas specs.
- No hay ejecución de tareas sin aprobación.

## 6. Dependencias
- Spec 015 (flujo MCP).
- Constitución v2.0.

## 7. Riesgos
- Resistencia a cambios en agents.
- Duplicación de reglas.

## 8. Métricas
- 100% de agents actualizados.
- 0 tareas ejecutadas sin aprobación.
