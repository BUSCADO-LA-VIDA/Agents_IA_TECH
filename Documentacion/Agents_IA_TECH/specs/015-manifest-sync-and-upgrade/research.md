# Research: Sincronización y actualización de dependencias-manifest.yml

## Decisiones
- D-001: Usar manifest de referencia del KIT como fuente de verdad.
- D-002: Campo `upgrade` por herramienta con default true.
- D-003: Post-update hooks por herramienta.

## Hallazgos
- Manifest actual no tiene campo upgrade.
- `upgrade_framework.ps1` ya gestiona actualización pero sin switch.
