# Feature Specification: 023-ecc-workflows — Workflows CI propios derivados de ECC

**Feature Branch**: `023-ecc-workflows`
**Created**: 2026-10-16
**Status**: Completado (implementado 2026-10-16, verificado YAML OK)
**Input**: Análisis 2026-10-16 de los 12 workflows de ECC: 2 adaptables con valor real, 8 rechazados con daño documentado, resto no aplicable.

---

## Problema

El kit publica skills (96) y consume dependencias externas sin ninguna validación automática en CI. ECC resuelve lo mismo con workflows propios, pero copiarlos tal cual rompería este repo (publican releases, anuncian en su Discord, queman minutos en schedules ajenos, importan su engine de tests).

## Objetivos

- Validar la estructura de las skills del kit en cada PR/push que las toque.
- Auditar periódicamente la superficie instalable (npm/uv) en modo solo-lectura.
- Dejar por escrito qué workflows ECC se rechazaron y por qué, para no re-evaluarlos.

## Requisitos funcionales

### RF-01 — `validate-skills.yml` (patrón taste adaptado, motor propio)
Dispara en PR/push con paths en `.github/skills/**`, `.opencode/skills/**` o el propio workflow, más `workflow_dispatch`. Valida con Python inline (sin dependencias): cada subdirectorio de skill trae `SKILL.md` con frontmatter `name:` + `description:`. Falla el job si hay errores. Timeout 5 min.

### RF-02 — `supply-chain-watch.yml` (adaptado al manifest del kit)
Schedule semanal (lunes 06:00 UTC) + manual. Solo lectura: `npm audit --omit=dev --audit-level=high` en `.opencode`, chequeo de resolubilidad PyPI de los paquetes fijados, presencia de `dependencias-manifest.yml` y su par en `proyect_ext/`. Hallazgos como `::warning::`, nunca como fallo duro (no bloquea por advisories de terceros).

### RF-03 — Rechazos documentados
NO copiar jamás: `ci.yml`, `release.yml`, `reusable-release.yml`, `generator-generic-ossf-slsa3-publish.yml` (publicarían paquetes/releases desde este repo), `release-announce.yml`, `discussion-announce.yml` (postean al Discord de ECC), `maintenance.yml`, `monthly-metrics.yml` (schedules ajenos). `reusable-test.yml`, `reusable-validate.yml`, `taste-skills.yml` solo como lectura del patrón (importan su engine `ecc_tasteforge`, inexistente aquí).

## Requisitos no funcionales

- **RNF-01**: Workflows con `permissions: contents: read`, checkout con `persist-credentials: false`, acciones pineadas por SHA.
- **RNF-02**: Sin secretos en logs ni en el repo (regla spec 010 + gitleaks v8 en CI).

## Fuera de alcance

- Motor de tests de skills con engine (no existe equivalente propio; la validación es estructural).
- `pip-audit` como dependencia dura (best-effort con warning si falta).

## Dependencias

- Spec 022 (las skills que valida), spec 010 (remediación de fugas), `.gitleaks.toml` v8 + Security Scan (cobertura de secretos ya existente).

## Criterios de éxito

- **SC-01**: Ambos YAML parsean (`yaml.safe_load`) con los jobs `validate` y `audit` respectivamente (verificado 2026-10-16).
- **SC-02**: `validate-skills.yml` en verde en el próximo push que toque skills (corrección: corre en CI, ver run).
- **SC-03**: Esta spec responde "por qué no copiamos X workflow" sin re-analizar.
