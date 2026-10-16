# Feature Specification: 022-ecc-integration — Integración ECC por copia con espejo por harness vía script

**Feature Branch**: `022-ecc-integration`
**Created**: 2026-10-16
**Status**: En implementación
**Input**: Decisiones 2026-10-16 del usuario: (1) el externo es caché de descarga, el contenido integrado viaja en git; (2) sin duplicación funcional pero con espejo por harness (precedente: 10 speckit-* idénticas 10/10); (3) todo por script reutilizable, no copias manuales.

---

## Problema

1. Las 76 skills técnicas del kit eran fachadas SSD (~2 KB) desconectadas de la profundidad ECC (~20 KB): el agente nunca llegaba al conocimiento técnico.
2. `.opencode/skills` solo tenía las 10 speckit propietarias: los agentes OpenCode no veían ninguna skill técnica.
3. Las integraciones se hicieron con comandos manuales ad-hoc, sin script reutilizable ni spec que las gobierne.

## Objetivos

- Script `scripts/sync/skills/sync-skills.ps1` que integre y espeje de forma idempotente y re-ejecutable.
- Toda skill técnica del kit con su profundidad ECC integrada y espejada en ambos harnesses.
- Cero copias manuales desde esta spec en adelante.

## Requisitos funcionales

### RF-01 — Integración con copia y tag
Por cada skill del kit con contraparte en `proyect_ext/ECC/skills/<nombre>/SKILL.md`: fachada SSD intacta arriba + contenido ECC anexado debajo con cabecera de trazabilidad (ECC HEAD sha + fecha + nota de caché). Idempotente (re-correr no duplica).

### RF-02 — Espejo por harness
`.opencode/skills/<categoria>/<skill>/SKILL.md` idéntico a su par `.github`. Las 10 speckit-* ya lo cumplen; el script las verifica y reporta deriva.

### RF-03 — Rules con tag
`.github/rules/ecc-{common,python}/` copiados de ECC con tag de origen + alias `security-reviewer = security-auditor`. (Ya ejecutado 2026-10-16; el script lo verifica/repara.)

### RF-04 — Exclusiones
Nunca integrar: workflows de release/comunidad ECC, espejos de harnesses ajenos (`.adal`, `.kimi`, etc.), `.github` propio de ECC, `rules/` por lenguaje salvo pedido explícito.

## Requisitos no funcionales

- **RNF-01**: PowerShell 7+, fail-open por skill, `-DryRun` sin escrituras.
- **RNF-02**: `proyect_ext/` (gitignored) nunca se commitea; solo el contenido integrado viaja en git.
- **RNF-03**: Tamaño acotado y reportado (referencia: 1.1 MB en 76 skills).

## Fuera de alcance

- Importar agentes especialistas `ecc-*` (decisión pendiente del usuario).
- Re-integración tras `ecc update` (futuro: T012 de spec 021 invoca este script).
- Desbloqueo de sentry / MCPs de pago descartados.

## Dependencias

- `proyect_ext/ECC` actualizado (HEAD `b92f181b` al integrar; el script registra el HEAD vigente en cada corrida).
- Spec 021 (el script vive en `scripts/sync/` y reutiliza `lib/common.ps1`).

## Criterios de éxito

- **SC-01**: 76/76 fachadas con contenido integrado + tag, 0 punteros viejos.
- **SC-02**: Espejo `.opencode` idéntico al `.github` técnico (hash por archivo).
- **SC-03**: Re-corrida idempotente (0 escrituras).
- **SC-04**: `validate-skills.yml` en verde (toda skill con SKILL.md + frontmatter name/description).
