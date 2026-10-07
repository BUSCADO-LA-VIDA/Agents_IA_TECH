# Plan 013 – MCP Integration Flow

## Etapas (E‑01 → E‑08)

| Etapa | Descripción |
|---|---|
|**E‑01**|Clonar repositorio ECC en `proyect_ext/ECC` y verificar estructura.|
|**E‑02**|Crear carpeta `scripts/ecc‑*` y generar `ecc‑orchestrator.ps1`.|
|**E‑03**|Actualizar frontmatter de los 13 agents con `## 🎯 Rol Scrum: Integración MCP`.|
|**E‑04**|Validar whitelist Art‑VII de la Constitución tras añadir nuevos paths.|
|**E‑05**|Ejecutar pipeline CI `dry‑run` y confirmar éxito.|
|**E‑06**|Notificar a todos los agents de la nueva norma (commit + mensaje).|
|**E‑07**|Integrar la spec 013 en el índice 00‑indice.md.|
|**E‑08**|Completar spec 013 — flujo completo, lista para producción (operativa, permanece en `specs/`; archivar solo al retirar del flujo).|

## Tareas (T‑001 → T‑008)

| T‑ID | Tarea | Agente delegado | Estado |
|---|---|---|---|
|**T‑001**|Clonar ECC en `proyect_ext/ECC` (`git clone …`).|`plataformador`|Pendiente|
|**T‑002**|Crear carpeta `scripts/ecc‑*` y archivo `ecc‑orchestrator.ps1`.|`devops`|Pendiente|
|**T‑003**|Actualizar frontmatter de los 13 agents con `## 🎯 Rol Scrum: Integración MCP`.|Cada agent (`.github/agents/` + `.opencode/agents/`)|Pendiente|
|**T‑004**|Validar whitelist Art‑VII de la Constitución.|`pensador` (supervisión)|Pendiente|
|**T‑005**|Ejecutar pipeline CI `dry‑run` (`.\\scripts\\ecc‑orchestrator.ps1 --dry-run`).|`devops`|Pendiente|
|**T‑006**|Notificar a todos los agents (commit que toque sus frontmatter + mensaje).|`pensador` (comunicación)|Pendiente|
|**T‑007**|Integrar spec 013 en índice `00‑indice.md`.|`documentador`|Pendiente|
|**T‑008**|Completar spec 013 (flujo completo, operativa, lista para producción).|`pensador`|Pendiente|

## Recursos

- Acceso a `.github/agents/` y `.opencode/agents/`.
- Script `ecc‑orchestrator.ps1` (esqueleto ver spec md).
- Pipeline CI plantilla (`ci/ecc‑pipeline.yml`).
- Comando `Constitution Check` para validar whitelist.

## Validación

- Después de cada tarea, verificar el resultado esperado (archivo existente, sección añadida, código 0 en pipeline, índice actualizado).
- Si alguna tarea fallara, detener y solicitar aprobación del usuario según el flujo SSD.

## Aprobación

- El plan debe ser aprobado por el usuario antes de pasar a la fase de implementación (tasks → implement).
- Una vez aprobado, el `pensador` delegará las tareas a los agents correspondientes.