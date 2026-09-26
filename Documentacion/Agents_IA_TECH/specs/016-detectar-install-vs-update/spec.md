# Spec: Detección de instalación vs actualización del KIT

**Versión**: 1.0
**Fecha**: 2026-09-25

## Objetivo
Permitir que `plataformador-bootstrap.ps1` determine si el proyecto es una instalación inicial del KIT o una actualización, y actuar en consecuencia para mantener operatividad.

## User Stories
### US1 — Detección de instalación
Como usuario, quiero que el bootstrap detecte instalación inicial y cree estructura base.

### US2 — Detección de actualización
Como usuario, quiero que el bootstrap detecte actualización y aplique migraciones sin perder personalización.

## Requisitos Funcionales
- FR-001: Verificar existencia de `.specify/memory/constitution.md` y `dependencias-manifest.yml`.
- FR-002: Si no existen, clasificar como instalación.
- FR-003: Si existen, comparar versión del KIT con versión registrada en manifest.
- FR-004: En instalación, crear estructura base y manifest completo.
- FR-005: En actualización, ejecutar sincronización de manifest y upgrade de herramientas.
- FR-006: Registrar modo detectado en log.

## Criterios de Aceptación
- SC-001: Instalación crea archivos base.
- SC-002: Actualización no sobrescribe personalizaciones.
