# Implementation Plan: 023-ecc-workflows

**Origen**: `spec.md` de esta spec. Enfoque: archivos nuevos autocontenidos, cero ediciones a workflows existentes.

## Diseño

- `.github/workflows/validate-skills.yml`: triggers por paths + `workflow_dispatch`; job `validate` (ubuntu, 5 min) con Python inline que recorre `.github/skills/<cat>/<skill>/SKILL.md` y `.opencode/skills/*.md` exigiendo frontmatter `name:`/`description:`; exit 1 con lista si hay errores.
- `.github/workflows/supply-chain-watch.yml`: cron semanal + manual; job `audit` (ubuntu, 10 min): `npm audit` en `.opencode`, resolubilidad PyPI de paquetes fijados, presencia de manifests; todo como `::warning::`, nada bloqueante.

## Constitution Check

`.specify/memory/constitution.md` con 9 artículos + VI (vigente). Respeta Art-VII (workflows = CI del kit, tier Plataforma/Tooling) y Art-IX (secretos: solo lectura, sin credenciales).

## Riesgos

- **R1**: Falsos positivos bloqueantes. Mitigación: supply-chain solo advierte; validate solo falla por estructura realmente rota.
