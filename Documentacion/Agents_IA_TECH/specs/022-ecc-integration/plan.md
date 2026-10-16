# Implementation Plan: 022-ecc-integration

**Origen**: `spec.md` de esta spec. Enfoque: un único script idempotente que implementa RF-01..RF-03 y se re-ejecuta ante cada `ecc update`.

## Diseño

```
scripts/sync/skills/sync-skills.ps1
  param: [string]$RootPath, [switch]$DryRun, [switch]$Force
  origen ECC: <Root>/proyect_ext/ECC/skills/<nombre>/SKILL.md
  destino github: <Root>/.github/skills/<categoria>/<skill>/SKILL.md
  espejo opencode: <Root>/.opencode/skills/<categoria>/<skill>/SKILL.md
  rules: <Root>/.github/rules/ecc-{common,python}/ desde ECC rules/{common,python}/
```

Por cada skill del kit con contraparte ECC: conserva fachada (todo antes de la primera cabecera `## Profundidad ECC` o `---` de integración), elimina secciones viejas (puntero o integrada previa) y anexa contenido ECC fresco con tag del HEAD vigente. Con `-Force` re-integra aunque el tag coincida; sin `-Force` omite las ya integradas al mismo HEAD (compara tag). Espejo: copia destino github→opencode si difiere. Rules: verifica presencia + tag; si falta, copia.

## Constitution Check

`.specify/memory/constitution.md` con 9 artículos + VI (verificado 2026-10-12, vigente). Respeta Art-VII: el script es tier Plataforma; escribe en `.github/`, `.opencode/` (whitelist) y nunca en `Documentacion/<AppName>/` ni código de app.

## Riesgos

- **R1**: Divergencia manual posterior en espejos (alguien edita solo un harness). Mitigación: el script reporta deriva (`deriva:`) y la corrige.
- **R2**: ECC actualiza y el contenido integrado envejece. Mitigación: tag con HEAD permite detectar desactualización (`-Force` re-integra); futuro T012 lo automatiza post-update.
