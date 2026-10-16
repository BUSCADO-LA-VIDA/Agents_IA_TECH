# Bitacora 2026-10-16 — Integracion ECC: skills, rules, workflows

## Skills: fachadas conectadas, no duplicadas
- Auditoria: 76 subdirs con contraparte ECC (fichas ~2 KB vs ~20 KB) + 10 speckit-* propias sin contraparte.
- 0 referencias a ECC antes; ahora 76/76 con seccion `## Profundidad ECC` (-> `proyect_ext/ECC/skills/<nombre>/SKILL.md`, rutas relativas verificadas).
- Regla: fachada SSD manda; profundidad ECC se lee, no se copia (proyect_ext/ no se sincroniza).

## Workflows (decision por archivo)
- NUEVO `validate-skills.yml`: patron taste adaptado a motor propio (valida SKILL.md + frontmatter name/description). YAML OK.
- NUEVO `supply-chain-watch.yml`: audita superficie npm/uv del kit (solo lectura, semanal + manual). YAML OK.
- RECHAZADOS con evidencia: ci/release*/generator-*/announce/maintenance/monthly-metrics (publicarian desde este repo, postean a Discord ajeno, queman minutos).

## Rules
- Importados `rules/common/` (10) + `rules/python/` (6) a `.github/rules/ecc-{common,python}/`, verbatim salvo comentario alias `security-reviewer = security-auditor` en los 2 security.md.
- Resto de lenguajes bajo demanda via orquestador (referencia, no copia).
