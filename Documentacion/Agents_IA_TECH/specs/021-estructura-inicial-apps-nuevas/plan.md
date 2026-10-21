# Implementation Plan: 021-estructura-inicial-apps-nuevas

**Feature**: Creación estandarizada de apps nuevas antes de ejecutar plataformador
**Spec**: `021-estructura-inicial-apps-nuevas/spec.md`
**Status**: Draft
**Created**: 2026-10-19

---

## Resumen técnico

Formalizar el flujo de creación de una app nueva para que siempre se creen primero las carpetas vacías en `Documentacion/<AppName>/` y `src/<AppName>/`, y recién después se ejecute `plataformador-bootstrap.ps1`. El bootstrap ya contiene `Ensure-AppStructure` y `Ensure-SrcAppStructure`, por lo que no se modifica código, solo se documenta y se refuerza el comportamiento del agente `plataformador`.

## Arquitectura de solución

### Componentes involucrados
* `plataformador.agent.md` — definición del agente responsable de iniciar el flujo
* `scripts/plataformador-bootstrap.ps1` — funciones `Ensure-AppStructure` y `Ensure-SrcAppStructure` ya existentes
* `dependencias-manifest.yml` — registro de apps
* `.doc_agents/estructura-aplicacion.md` y `estructura-estandar.md` — fuente de verdad de rutas

### Flujo propuesto
1. Usuario solicita nueva app → `plataformador`
2. `plataformador` valida nombre, pregunta confirmación
3. Crear carpetas vacías:
   * `Documentacion/<AppName>/`
   * `src/<AppName>/`
4. Actualizar `dependencias-manifest.yml` → `aplicaciones: <AppName>`
5. Ejecutar `plataformador-bootstrap.ps1 -DryRun` para validar
6. Ejecutar `plataformador-bootstrap.ps1` real
7. Verificar salida de `Ensure-*` y crear bitácora de inicialización en `Documentacion/<AppName>/bitacoras/`

## Decisiones de diseño

* **No modificar el bootstrap**: `Ensure-AppStructure` y `Ensure-SrcAppStructure` ya implementan la creación correcta. La mejora es de proceso/agente, no de código.
* **Creación temprana vacía**: separar la creación de carpetas vacías del poblamiento de estructura. Evita que el agente improvise subcarpetas en raíz.
* **Registro en manifest obligatorio**: sin entrada en `aplicaciones:`, `Resolve-AppList` no detecta la app.
* **Idempotencia**: re-ejecutar bootstrap no debe romper nada existente.
* **Anti-raíz**: si se detecta carpeta de app en raíz, emitir WARN y abortar creación.

## Riesgos y mitigaciones

* **Riesgo**: Agente sigue creando en raíz por hábito. **Mitigación**: actualizar `plataformador.agent.md` con paso explícito de creación temprana y regla anti-raíz. Añadir checklist en spec.
* **Riesgo**: `dependencias-manifest.yml` queda desactualizado. **Mitigación**: paso 2 obligatorio en el plan y verificación post-bootstrap.
* **Riesgo**: Confusión entre `Documentacion_Publica/` dentro de la app y `Documentacion/<App>/` interna. **Mitigación**: documentar en la bitácora de inicialización.

## Tareas de implementación

1. Actualizar definición del agente `plataformador` en `.github/agents/` y `.opencode/agents/` con el paso de creación temprana.
2. Añadir checklist de creación de app nueva en `.specify/templates/` para reutilizar.
3. Crear plantilla de bitácora de inicialización de app.
4. Verificar con una app de prueba que el flujo `crear carpetas vacías → manifest → bootstrap` funciona sin WARN.
5. Documentar el flujo en `Documentacion/Agents_IA_TECH/specs/021-.../plan.md` y `tasks.md`.

## Criterios de verificación

* `Documentacion/<AppName>/00-indice.md` existe tras bootstrap
* `src/<AppName>/.specify/constitution.md` existe tras bootstrap
* `speckit-specify --app <AppName>` resuelve ruta correcta
* No existen carpetas de app en raíz fuera del kit transversal
* Bitácora de inicialización creada en `Documentacion/<AppName>/bitacoras/`

## Dependencias

* Spec 021 aprobada
* `plataformador-bootstrap.ps1` funciones existentes
* Estándares `.doc_agents/estructura-aplicacion.md`, `estructura-estandar.md`
