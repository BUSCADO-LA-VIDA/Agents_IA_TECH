# Spec: Ciclo de vida de integración ECC

## User Story
Como mantenedor, quiero un proceso controlado para instalar, actualizar, validar y desinstalar ECC como proyecto externo en `proyect_ext/ECC`, con script de control, rama de prueba y validación de flujo, para que la integración sea repetible y segura.

## Contexto
ECC evoluciona constantemente. La integración debe ser gestionable en el tiempo, no un one-shot. Se requiere rama de prueba, script de control de integración, validación de flujo Speckit y manejo de errores.

## Requisitos Funcionales
FR-001: Crear rama `feature/ecc-integration` para pruebas.
FR-002: Crear script `scripts/ecc-sync.ps1` que controle install/update/uninstall de ECC.
FR-003: Script debe detectar versión actual de ECC, comparar con remoto y aplicar cambios selectivos.
FR-004: Validar que flujo Speckit y agentes `pensador` siguen funcionando tras integración.
FR-005: Corregir errores de duplicación de agentes/skills con namespace `ecc-`.
FR-006: Registrar estado de integración en `.ecc-state.json`.
FR-007: Permitir rollback a estado previo.

## Requisitos No Funcionales
NFR-001: Integración no modifica `src/<App>/`.
NFR-002: Cambios solo en `proyect_ext/ECC/` y adaptaciones en `Documentacion/`.
NFR-003: Proceso idempotente y reproducible.

## Criterios de Aceptación
SC-001: Rama de prueba creada y script `ecc-sync.ps1` existe.
SC-002: Script soporta comandos `install`, `update`, `validate`, `uninstall`.
SC-003: Validación de flujo Speckit pasa tras update.
SC-004: Matriz de comparación ECC ↔ Agents_IA_TECH documentada.
SC-005: Proceso de corrección de errores documentado.

## Riesgos
- Conflictos de nombres. Mitigación: namespace y allowlist.
- Rotura de flujo. Mitigación: validación automatizada y rama de prueba.
