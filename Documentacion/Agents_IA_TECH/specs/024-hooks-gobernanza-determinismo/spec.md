# Spec 024 - Hooks de gobernanza y determinismo de harnesses

## Objetivo
Garantizar determinismo total del flujo de desarrollo con IA, paridad de harnesses y gobernanza de seguridad.

## Problema actual
* No hay pre-commit obligatorio de seguridad.
* Gate de paridad .github ↔ .opencode no existe.
* Artefactos Speckit se generan manualmente sin checksum.
* speckit-analyze, speckit-checklist, speckit-clarify, speckit-taskstoissues, speckit-version no se ejecutan como comandos.

## Requisitos funcionales
FR-01: Pre-commit hook ejecutable que corra ecc-agentshield scan + gitleaks + validación constitution.
FR-02: Gate PR automático que falle si speckit-analyze reporta CRITICAL o diff harnesses != 0.
FR-03: Checksum SHA256 de spec.md, plan.md, tasks.md almacenado en .specify/checksums.json y validado en pre-commit.
FR-04: Hook diario que ejecute upgrade_framework --check en primera petición del día.
FR-05: Validar speckit-version al inicio de sesión y abortar si versión incompatible.
FR-06: Integrar speckit-checklist como gate de aceptación.
FR-07: Integrar speckit-clarify antes de speckit-plan.
FR-08: Integrar speckit-taskstoissues al finalizar tasks.md.

## Requisitos no funcionales
* Idempotente, reproducible.
* Fail-closed.
* Documentación completa sin placeholders.

## Criterios de aceptación
* Hook pre-commit instalado en .git/hooks/pre-commit.
* CI gate valida analyze y paridad.
* Checksums presentes y validados.
* Todos los skills Speckit invocados en flujo.
