# Plan 015 – Flujo transversal de integración de MCP

## Fase 1: Specify
- Spec 015 creado con el flujo estándar de incorporación de MCP.

## Fase 2: Plan
- Definir las 8 etapas obligatorias (E‑01 a E‑08) y el patrón Orquestador ↔ Esclavos.
- Identificar los 13 agents que deben actualizarse.
- Establecer la plantilla de sección `🎯 Rol Scrum: Integración MCP`.

## Fase 3: Tasks
- T001 Crear estructura de carpetas `scripts/ecc‑*` y orquestador inicial.
- T002 Actualizar frontmatter de los 13 agents con la sección de integración MCP.
- T003 Validar Constitución Art‑VII whitelist tras añadir nuevos paths.
- T004 Ejecutar pipeline CI vacío y añadir primera prueba `dry‑run`.
- T005 Lanzar notificación a todos los agents de la nueva norma.
- T006 Integrar spec 015 en el índice `00-indice.md`.
- T007 Revisión trimestral por Pensador (checklist de mantenimiento).
- T008 Completar spec 015 — flujo SSD completo sin saltar pasos, lista para producción (operativa). NO archivar. Archivado (`specs/archived/`) solo cuando se retire del flujo/proceso.

## Fase 4: Analyze
- Revisar que todos los agentes tengan la sección obligatoria.
- Verificar que el orquestador y los scripts esclavos cumplan la plantilla.

## Fase 5: Converge
- Documentar el flujo completado en `00-indice.md`.
- Actualizar `CHANGELOG.md` en `scripts/`.

## Fase 6: Implement
- Aplicar los cambios a los agents y a la carpeta de scripts.
- Ejecutar la pipeline CI para validar que todo pasa.