# Spec 025 - Actualización automática herramientas externas

## Objetivo
Automatizar detección y propagación de actualizaciones de herramientas externas sin perder personalización.

## Requisitos funcionales
FR-01: Hook en pensador que en primera petición del día ejecute upgrade_framework --check si última verificación >24h.
FR-02: CI semanal que ejecute upgrade_framework --check y abra PR con cambios de versión.
FR-03: dependencías-manifest.yml versionado con version_actual, ultimo_check, repo.
FR-04: Actualización en proyectos destino vía sync-kit.ps1 que replica dependencias versionadas, no proyect_ext/.
FR-05: Log de actualización en Documentacion/<App>/seguridad/log-actualizaciones.md.

## Criterios de aceptación
* Hook diario ejecutable y con registro.
* CI crea PR automáticamente.
* Proyectos destino reciben versión actualizada sin overwrite de personalizaciones.
