# Spec 018 – Pendientes con estados Scrum y control por Pensador

## Objetivo
Actualizar el mecanismo `pendientes-implementacion.md` para trabajar con estados Scrum humanos y permisos de actualización por agente, con Pensador como líder del equipo.

## Requisitos funcionales
- FR-001: `pendientes-implementacion.md` debe tener columnas Estado y Asignado a
- FR-002: Estados permitidos: Sin asignar, Pendiente, En Progreso, Finalizada, Finalizado QA, Finalizado Security, Cerrado
- FR-003: Pensador asigna tareas Sin asignar → Pendiente con Asignado a
- FR-004: Agentes solo pueden actualizar estado de tareas asignadas a ellos
- FR-005: Pensador puede reasignar y sincerar estados
- FR-006: Actualización automática post-fase por Agent-SSD
- FR-007: Todos los agentes deben leer pendientes-implementacion.md al inicio de fase

## Requisitos no funcionales
- NFR-001: Cumplir Constitución Art.VII whitelist paths
- NFR-002: No placeholders, contenido completo
- NFR-003: Actualización sincronizada en .github/ y .opencode/

## Alcance
Actualizar plantilla, migrar inventario vivo, actualizar 14 agentes en ambos harnesses, documentar flujo Scrum.
