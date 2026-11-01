# Spec 013 – MCP Integration Flow (aligned with Spec 015)

## 1. Contexto
La especificación 013 define el flujo de integración del módulo ECC como proyecto externo. Esta versión alinea sus tareas con los requisitos transversales de la especificación 015 (flujo transversal de integración de MCP), garantizando que la incorporación de ECC respete la whitelist Art‑VII, actualice los agents y quede registrada en el índice 00‑indice.md.

## 2. Objetivo
- Clonar y exponer el repositorio ECC en `proyect_ext/ECC`.
- Añadir la sección `## 🎯 Rol Scrum: Integración MCP` a los 13 agents (`.github/agents/` y `.opencode/agents/`).
- Validar que los nuevos paths no violen la Constitución Art‑VII.
- Crear un orquestador `ecc‑orchestrator.ps1` en `scripts/ecc‑*`.
- Ejecutar un pipeline CI `dry‑run` y reportar éxito.
- Notificar a todos los agents de la nueva norma.
- Integrar la spec 013 en el índice 00‑indice.md.
- Completar la spec 013 — flujo SSD completo, lista para producción (operativa). NO archivar; archivado (`specs/archived/`) solo cuando se retire del flujo/proceso.

## 3. Alcance
- Modificaciones en `proyect_ext/ECC` (clonado, scripts).
- Actualización de frontmatter de agents.
- Validación de whitelist Art‑VII.
- Creación de scripts de CI/CD.
- Registro en `00‑indice.md`.

## 4. Requisitos previos
- Constitución v2.0.0 válida.
- Acceso de escritura a `.github/agents/` y `.opencode/agents/`.
- Permisos de ejecución de PowerShell.

## 5. Criterios de aceptación
1. Existe la carpeta `scripts/ecc‑*` con `ecc‑orchestrator.ps1`.
2. Todos los agents contienen la sección `## 🎯 Rol Scrum: Integración MCP` y la regla de aprobación explícita.
3. La whitelist Art‑VII no presenta paths no autorizados.
4. Pipeline CI `dry‑run` finaliza con código 0.
5. El índice 00‑indice.md incluye la entrada 013‑MCP‑Integration‑Flow.
6. La spec 013 se marca como Completada/Cerrada en `pendientes‑implementacion.md` — entendiendo `Cerrar` = flujo SSD completo, lista para producción, permanece ACTIVA en `specs/` (NO mover a `archived/`).

## 5. Dependencias
- Spec 015 (flujo transversal de integración de MCP).
- Acceso al repositorio ECC en `https://github.com/affaan-m/ECC.git`.
- PowerShell 7+.

## 7. Riesgos
- Duplicación de tareas con la spec 012‑ECC integration.
- Falta de aprobación del usuario antes de ejecutar tareas que modifican agents.

## 8. Métricas
- 1 carpeta `scripts/ecc‑*` creada.
- 13 agents actualizados.
- 0 violaciones de whitelist.
- Pipeline CI éxito 100 %.

## 9. Próximos pasos
1. Ejecutar `speckit‑specify` para generar el spec md (ya hecho).
2. Ejecutar `speckit‑plan` para generar el plan md.
3. Ejecutar `speckit‑tasks` para generar el tasks md (ver apartado 5).
4. Validar whitelist Art‑VII (Constitution Check).
5. Ejecutar pipeline CI dry‑run.
6. Notificar a agents y completar spec (dejar operativa, lista para producción).

## 10. Glosario del ciclo de vida (canónico en Spec 015, vinculante aquí y a futuro)

- **Completar / Cerrar**: terminar E‑01→E‑08 y T‑001→T‑008 sin saltar pasos; la spec queda lista para producción y permanece ACTIVA en `specs/013-mcp-integration-flow/`. El estado `Cerrado` en `pendientes-implementacion.md` significa flujo completo/operativo.
- **Archivar** (`specs/archived/`): SOLO cuando el usuario indique explícitamente que la spec se retira del flujo/proceso (reemplazo, cancelación, deprecación). El T008 de esta spec prohíbe `Move-Item` a `archived/`.
- **Retirar / quitar del flujo**: sinónimo de archivar; requiere instrucción explícita con motivo.
- **Operativa**: T008 verificado, entrada en `00-indice.md` y recuperable vía `ctx_search`.