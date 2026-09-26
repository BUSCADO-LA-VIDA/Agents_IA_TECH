# Spec 015: Sync-Kit y Bootstrap separados

Objetivo: Dividir bootstrap en sync-kit y bootstrap para descargar código actual y ejecutar correctamente. Migrar y ampliar capacidades de sincronización desde repos.

## User Stories
US1: Como mantenedor, quiero sincronizar código desde repo para ejecutar bootstrap con versión actual.
US2: Como mantenedor, quiero que módulos se sincronicen con proyectos.
US3: Como mantenedor, quiero migrar capacidades existentes a nuevo flujo.

## Requisitos Funcionales
FR-001: sync-kit.ps1 descarga código desde repo
FR-002: Incluye carpetas necesarias para kit
FR-003: bootstrap.ps1 ejecuta con código actualizado
FR-004: Sincroniza módulos con proyectos
FR-005: Migra capacidades existentes
FR-006: Amplía sincronización desde repos

## Criterios de Aceptación
SC-001: sync-kit.ps1 descarga código correctamente
SC-002: bootstrap.ps1 ejecuta con código actualizado
SC-003: Módulos sincronizados con proyectos
SC-004: Capacidades migradas
SC-005: Sincronización ampliada

## Criterios de Aceptación
SC-001: sync-kit.ps1 descarga código correctamente
SC-002: bootstrap.ps1 ejecuta con código actualizado
SC-003: Módulos sincronizados con proyectos

## Edge Cases
- Repo no accesible
- Módulos faltantes

## Non-goals
- No modificar lógica de bootstrap existente

## Dependencias Externas
- Git repo
- PowerShell 7+

## Métricas de Éxito
- Sincronización exitosa
- Bootstrap ejecuta sin errores

