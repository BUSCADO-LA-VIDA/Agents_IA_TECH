# Analyze: 021-estructura-inicial-apps-nuevas

**Feature**: Creación estandarizada de apps nuevas antes de ejecutar plataformador
**Spec**: spec.md
**Plan**: plan.md
**Tasks**: tasks.md
**Date**: 2026-10-21

## Consistencia entre artefactos

* **Spec vs Plan**: Alineados. RF-01.1 de creación temprana está reflejado en flujo del plan.
* **Plan vs Tasks**: T-01 a T-07 cubren las decisiones del plan. No hay tareas huérfanas.
* **Cobertura de arquitectura**: No se modifica `plataformador-bootstrap.ps1`. Se usa `Ensure-AppStructure` y `Ensure-SrcAppStructure` existentes. Sin impacto en dependencias.
* **Seguridad**: No introduce secretos. No cambia permisos. Regla anti-raíz reduce riesgo de estructura corrupta.

## Riesgos identificados

* **Riesgo**: Agente `plataformador` no actualiza ambos arneses simultáneamente → desajuste. **Mitigación**: T-01 exige 0 desajustes y revisión por `qa-senior`.
* **Riesgo**: Usuario sigue pidiendo creación directa sin pasar por checklist. **Mitigación**: T-03 checklist reutilizable y T-06 regla anti-raíz.
* **Riesgo**: Manifest no se actualiza. **Mitigación**: Paso explícito en checklist y verificación post-bootstrap.

## Decisión arquitectónica

No se requiere ADR nueva. La solución reutiliza funciones existentes del bootstrap y estandariza proceso. Si en el futuro se necesita parámetro `-NewApp`, se abrirá ADR específica.

## Resultado del análisis

**PASS** con observaciones:
* Documentación completa. Falta ejecución de tareas T-01 a T-07.
* No hay conflictos con especificaciones previas.
* Compatible con SSD+Speckit.
