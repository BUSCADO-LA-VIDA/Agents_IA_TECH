# Tasks: 021-estructura-inicial-apps-nuevas

**Feature**: Creación estandarizada de apps nuevas antes de ejecutar plataformador
**Spec**: `021-estructura-inicial-apps-nuevas/spec.md`
**Plan**: `021-estructura-inicial-apps-nuevas/plan.md`
**Status**: Draft
**Created**: 2026-10-21

---

## Tareas de documentación y proceso

### T-01 Actualizar definición del agente plataformador
**Descripción**: Reflejar en `.github/agents/plataformador.agent.md` y `.opencode/agents/plataformador.md` el paso de creación temprana de carpetas vacías.
**Criterios**:
* Sección "Flujo de creación de app nueva" documenta: crear `Documentacion/<App>/` y `src/<App>/` vacíos → registrar en manifest → ejecutar bootstrap.
* Incluir regla anti-raíz y advertencia si se detecta carpeta en raíz.
* Mantener frontmatter y 0 desajustes entre arneses.
**Asignado a**: documentador
**Estado**: Completada — Verificación qa-senior 2026-10-21 PASS

### T-02 Plantilla de bitácora de inicialización
**Descripción**: Crear plantilla reutilizable para registrar la creación de una app nueva.
**Ubicación**: `.specify/templates/bitacora-inicializacion-app.md`
**Contenido mínimo**: nombre app, fecha, usuario solicitante, estructura creada, manifest actualizado, resultado de bootstrap.
**Asignado a**: documentador
**Estado**: Pendiente

### T-03 Checklist de creación de app nueva
**Descripción**: Checklist operativo para el agente `plataformador`.
**Ubicación**: `.specify/templates/checklist-creacion-app-nueva.md`
**Items**:
* [ ] Solicitar nombre de app y validar único
* [ ] Crear `Documentacion/<App>/` vacío
* [ ] Crear `src/<App>/` vacío
* [ ] Actualizar `dependencias-manifest.yml` → `aplicaciones:`
* [ ] Ejecutar `plataformador-bootstrap.ps1 -DryRun`
* [ ] Ejecutar `plataformador-bootstrap.ps1`
* [ ] Verificar `00-indice.md` y `.specify/constitution.md`
* [ ] Crear bitácora de inicialización
**Asignado a**: documentador
**Estado**: Pendiente

### T-04 Validar con app de prueba
**Descripción**: Crear app de prueba `app-demo-check` siguiendo el flujo completo.
**Pasos**:
* Ejecutar T-01 a T-03 en una app de prueba
* Verificar que `Ensure-AppStructure` y `Ensure-SrcAppStructure` finalizan sin WARN
* Confirmar que `speckit-specify --app app-demo-check` resuelve ruta correcta
* Eliminar app de prueba tras verificación
**Asignado a**: qa-senior
**Estado**: Pendiente

### T-05 Actualizar spec del agente plataformador por app
**Descripción**: Cada app debe tener `Documentacion/<App>/agents/plataformador/spec.md` que refleje el flujo de creación.
**Criterio**: El spec por app referencia esta feature 021 y el checklist.
**Asignado a**: documentador
**Estado**: Pendiente

### T-06 Regla de lint anti-raíz
**Descripción**: Documentar en `AGENTS.md` y en `plataformador.agent.md` la regla anti-raíz: no crear carpetas de app en raíz del repo.
**Criterio**: Regla explicitada y ejemplo de WARN esperado.
**Asignado a**: pensador
**Estado**: Pendiente

### T-07 Prueba de regresión: speckit
**Descripción**: Verificar que Speckit sigue funcionando tras el cambio de proceso.
**Pasos**:
* Crear app nueva con flujo
* Ejecutar `speckit-specify`, `speckit-plan`, `speckit-tasks`
* Validar artefactos en `Documentacion/<App>/specs/`
**Asignado a**: qa-senior
**Estado**: Pendiente

---

## Dependencias
* T-01 bloquea T-05
* T-02 y T-03 bloquean T-04
* T-04 bloquea T-07

## Criterios de cierre
* Agente `plataformador` documentado con paso de creación temprana
* Checklist y plantilla de bitácora disponibles
* Prueba con app de prueba pasa sin WARN
* Speckit resuelve rutas correctamente
* 0 desajustes entre `.github` y `.opencode`
