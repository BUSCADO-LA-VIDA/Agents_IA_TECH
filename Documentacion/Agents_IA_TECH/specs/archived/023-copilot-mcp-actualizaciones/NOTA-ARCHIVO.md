# NOTA DE ARCHIVO

**Título**: Archivado de `023-copilot-mcp-actualizaciones` — Actualizaciones Copilot MCP / frontmatter.

**Fecha**: 2026-11-01

**Fase**: F — Últimas migraciones/archivados del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/023-copilot-mcp-actualizaciones/`
- **Nueva ubicación**: `specs/archived/023-copilot-mcp-actualizaciones/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `converge.md` — FR-01..FR-05 aprox. sobre frontmatter de agentes Copilot, `mcp-servers` por agente y paridad `.github`/`.opencode`. Tasks completadas.

## Motivo de archivado (decisión usuario fase F, spec 035)

- Veredicto: **ARCHIVAR / tema ya gestionado**.
- **El tema (frontmatter MCP de agentes, paridad `.github`/`.opencode`, mcp-servers por agente) ya está gestionado** por la regla 1b de cobertura MCP + la spec 020 (config MCP operativa) y el mecanismo de paridad de agentes. Sus tasks estaban completadas; sin feature futura única.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase F de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- La **cobertura MCP obligatoria (Regla 1b)**: todo MCP registrado en `opencode.json` debe estar declarado en la sección "Uso de MCPs" de al menos un agente, con el nombre de sus herramientas. Es regla transversal vigente en `AGENTS.md`.
- La **config MCP operativa** vive en **`020-mcp-config-operativa`** (canónica, ACTIVA en `specs/`): baseline en vivo de `opencode.json` con los 9 MCPs (ADR-0009), procedimiento de verificación viva y orden de diagnóstico.
- El **mecanismo de paridad de agentes** `.github`/`.opencode` (mismos agentes, cuerpos idénticos, difiere solo el frontmatter nativo de cada arnés) está implementado y es verificable por `tests/agents-parity.ps1` (spec 031).
- No hay artefactos en `023-copilot-mcp-actualizaciones` que no estén ya cubiertos por 1b + 020 + paridad. Archivado por referenciación; no se duplica contenido.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- No tenía entrada propia en `00-indice.md` (tasks completadas sin registrar); se registra la decisión de archivado en la fase F (spec 035) con referencia a esta NOTA-ARCHIVO y ubicación `specs/archived/023-copilot-mcp-actualizaciones/`.
