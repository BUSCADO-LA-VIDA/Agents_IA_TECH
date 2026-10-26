# Spec 026 - Agente developer único con skills especializadas

## Objetivo
Simplificar agentes de implementación a un único agente developer con skills especializadas y uso de context7.

## Requisitos funcionales
FR-01: Reemplazar api-developer, frontend-developer, devops, qa-senior por un agente developer único.
FR-02: Skills especializadas: docker-patterns, api-design, frontend-patterns, backend-patterns, devops-patterns, testing.
FR-03: Cada skill usa context7 para consultar documentación oficial en tiempo real.
FR-04: Agente developer decide qué skill invocar según dominio de tarea de tasks.md.
FR-05: Mantener paridad en .github y .opencode.

## Criterios de aceptación
* Agente developer único documentado.
* Skills referenciadas y testadas.
* No hay solapamiento de responsabilidades.
