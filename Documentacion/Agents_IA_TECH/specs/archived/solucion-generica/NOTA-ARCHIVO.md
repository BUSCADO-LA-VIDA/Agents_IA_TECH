# NOTA DE ARCHIVO

**Título**: Archivado de `solucion-generica` (no-numerada) — Descontaminación del kit.

**Fecha**: 2026-11-01

**Fase**: F — Últimas migraciones/archivados del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/solucion-generica/`
- **Nueva ubicación**: `specs/archived/solucion-generica/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: `spec.md` (6.802 B, RF-S1..RF-S6), `plan.md` y `tasks.md` (14 tareas cerradas, 14/0). Sin analyze/converge.

## Motivo de archivado (decisión usuario fase F, spec 035)

- Veredicto: **ARCHIVAR / parcialmente revertida**.
- **Decisión de genericidad revertida parcialmente por ADR-0009 (hardcode) y órdenes del usuario**: lo vigente (cero dominios concretos, cero rutas absolutas) ya está constitutionalizado en el constraint "Genericidad y Ausencia de Rutas Absolutas". Sin contenido único pendiente que no esté cubierto.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase F de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- El constraint **"Genericidad y Ausencia de Rutas Absolutas"** está en la Constitution del kit (`.specify/memory/constitution.md`), que formaliza exactamente RF-S1/RF-S2/RF-S6 de esta spec: cero dominios concretos, cero rutas absolutas.
- La decisión de hardcode de los 9 MCPs y la forma actual de configuración están registrados en **ADR-0009** (`arquitectura/adr/adr-0009*.md`, aceptado): el alcance de genericidad que aplica quedó definido ahí y en la Constitution.
- No hay artefactos en `solucion-generica` que no estén ya cubiertos por la Constitution + ADR-0009. Archivado por referenciación; no se duplica contenido.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La entrada correspondiente en `00-indice.md` fue actualizada en la fase F (spec 035): de "CERRAR-COMPLETADA-SIN-REGISTRO" a estado **ARCHIVADA (fase F)** con referencia a esta NOTA-ARCHIVO y ubicación `specs/archived/solucion-generica/`.
