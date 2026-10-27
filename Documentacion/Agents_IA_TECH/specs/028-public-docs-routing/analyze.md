# Analyze 028 - Public Docs Routing

## Consistencia de artefactos

### spec.md vs plan.md vs tasks.md
- FR-01 Docs funcionales públicas → src/<App>/docs/ : presente en spec y plan.
- FR-02 README*.md → src/<App>/ : presente en spec y plan.
- FR-03 Docs internas → Documentacion/<AppName>/ : consistente.
- FR-04 Delegación documentador→developer : presente en tasks.

Sin discrepancias.

## Validación Constitución

- Art.VII Restricción de Paths por Tier: actualizado a `developer` único.
- Art.VII nota de routing docs públicas añadida.
- Tier Documental no escribe en src/<App>/docs/ → delegación correcta.
- Cumple Art.IX Integration-First.

## ADRs enlazados

- ADR-0011-public-docs-routing.md aceptada.
- ADR-0005 Speckit delegation referencia Agent-SSD.

## Threat Model STRIDE

- **Spoofing**: riesgo de docs públicas en ruta interna. Mitigado por skill public-documentation que valida ruta.
- **Tampering**: escritura no autorizada en src/<App>/docs/. Mitigado por whitelist developer.
- **Info disclosure**: docs internas expuestas como públicas. Mitigado por validación pre-commit.

Riesgos etiquetados:
- security-risk-028-01 rutas invertidas
- security-risk-028-02 permisos developer

## Hallazgos

- No se detectaron placeholders.
- Todos los artefactos referencian `src/<App>/docs/` y `src/<App>/README*.md`.
- Flujo Speckit alineado con hooks gobernanza Spec 024.

## Decisión

Aprobado para converge.
