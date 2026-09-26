# Spec: Sincronización y actualización de dependencias-manifest.yml

**Versión**: 1.0
**Fecha**: 2026-09-25
**Estado**: Borrador
**Dependencia**: Requiere 014-auto-create-dependencias-manifest cerrado. Esta spec extiende 014 con sincronización, upgrade switch y post-update hooks.

## Objetivo
Garantizar que `dependencias-manifest.yml` esté presente, actualizado y refleje el estado real de las herramientas externas en `proyect_ext/`. El bootstrap debe leer el manifest, detectar si está vacío, desactualizado o incompleto, y sincronizarlo con la fuente de verdad del KIT, respetando el switch `upgrade` por herramienta.

## User Stories

### US1 — Manifest presente y completo
Como mantenedor, quiero que el bootstrap asegure que el manifest exista y contenga todas las herramientas externas definidas por el KIT, para evitar WARN y permitir despliegue consistente.

**Acceptance**
- Si no existe, se crea con todas las herramientas externas del KIT con `upgrade: true` por defecto.
- Si existe pero está vacío, se completa con las herramientas faltantes sin sobrescribir las existentes.

### US2 — Detección de actualización
Como mantenedor, quiero que el bootstrap compare la versión actual del manifest con la versión de referencia del KIT y actualice versiones, URLs y componentes a copiar.

**Acceptance**
- Se detecta diferencia en `version_actual` o `url`.
- Se actualiza el manifest manteniendo personalizaciones del usuario.

### US3 — Switch upgrade por herramienta
Como mantenedor, quiero poder desactivar la actualización de una herramienta específica con `upgrade: false`, para mantenerla fija.

**Acceptance**
- Si `upgrade: false`, no se actualiza la herramienta ni se cambia su versión.
- El conocimiento del proyecto se mantiene actualizado.

### US4 — Actualización de herramienta y conocimiento
Como mantenedor, quiero que al actualizar una herramienta se ejecuten los comandos de post-actualización: reindexar context-mode, reindexar codebase-memory, actualizar grafo graphify.

**Acceptance**
- Tras actualizar herramienta, se ejecuta el hook correspondiente.
- Se registra en log.

## Requisitos Funcionales
- FR-001: Leer `dependencias-manifest.yml` si existe, si no crear esqueleto completo.
- FR-002: Comparar manifest del proyecto con manifest de referencia del KIT.
- FR-003: Cada herramienta externa debe tener campo `upgrade: true|false` con default true.
- FR-004: Si `upgrade: true` y versión desactualizada, actualizar herramienta desde `proyect_ext/`.
- FR-005: Si `upgrade: false`, mantener versión y no actualizar herramienta.
- FR-006: Agregar herramientas nuevas del KIT al manifest existente sin sobrescribir.
- FR-007: Permitir remover herramientas marcadas como `remove: true` en referencia.
- FR-008: Ejecutar post-update hooks por herramienta: `context-mode index`, `codebase-memory index_repository`, `graphify update`.
- FR-009: Registrar cambios en log visible.

## Requisitos No Funcionales
- NFR-001: No sobrescribir personalizaciones del usuario.
- NFR-002: Operación idempotente.

## Criterios de Aceptación
- SC-001: Manifest siempre presente tras bootstrap.
- SC-002: Herramientas con `upgrade: true` quedan en última versión.
- SC-003: Herramientas con `upgrade: false` no se actualizan.
- SC-004: Post-update hooks ejecutados correctamente.
