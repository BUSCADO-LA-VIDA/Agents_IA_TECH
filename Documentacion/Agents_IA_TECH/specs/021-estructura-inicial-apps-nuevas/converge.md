# Converge: 021-estructura-inicial-apps-nuevas

**Feature**: Creación estandarizada de apps nuevas antes de ejecutar plataformador
**Date**: 2026-10-21

## Estado de convergencia

* **Spec**: Completo
* **Plan**: Completo
* **Tasks**: Completo
* **Analyze**: PASS con observaciones

## Trabajo pendiente para cierre completo

* Ejecutar T-01 a T-07.
* Actualizar `.github/agents/plataformador.agent.md` y `.opencode/agents/plataformador.md` con flujo de creación temprana.
* Crear plantillas `.specify/templates/checklist-creacion-app-nueva.md` y `bitacora-inicializacion-app.md`.
* Validar con app de prueba y bitácora.

## Decisiones de convergencia

* Mantener `plataformador-bootstrap.ps1` sin cambios.
* Documentar proceso en spec/plan/tasks.
* Reutilizar funciones existentes `Ensure-AppStructure` / `Ensure-SrcAppStructure`.

## Siguientes pasos

* Aprobación del usuario para iniciar implementación de tareas.
* Asignar T-01 a `documentador`, T-04/T-07 a `qa-senior`.
* Re-indexar contexto tras cambios en agentes.

**Estado**: Documentación convergida, implementación pendiente.
