# NOTA DE ARCHIVO

**Título**: Archivado de `022-docker-patterns-metodologia` — Metodología Docker transversal.

**Fecha**: 2026-11-01

**Fase**: F — Últimas migraciones/archivados del backlog (spec 035-consolidacion-backlog; decisión usuario 2026-11-01).

---

## Spec archivada

- **Dirección original**: `specs/022-docker-patterns-metodologia/`
- **Nueva ubicación**: `specs/archived/022-docker-patterns-metodologia/` (movido con `git mv`, preserva historial; reversible).
- **Contenido**: `spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `converge.md` — borrador con 10 FR de metodología Docker transversal.

## Motivo de archivado (decisión usuario fase F, spec 035)

- Veredicto: **ARCHIVAR / redundante con skill**.
- **Borrador cuyos 10 FR de metodología Docker transversal ya están cubiertos por la skill `docker-patterns`** (existente, 665 líneas, incluye secret management, Docker secrets, `.env` nunca commit, security, hardening). Redundante con la skill; se archiva.
- Decisión aprobada por el usuario el 2026-11-01 en el marco de la fase F de la spec 035.

## Contenido que se conserva en la canónica (referencia)

- La metodología Docker transversal que esta spec describía está cubierta por la skill **`docker-patterns`** (existente, 665 líneas) en ambos arneses: `.github/skills/docker/docker-patterns/SKILL.md` y `.opencode/skills/docker/docker-patterns/SKILL.md`. La skill incluye secret management (Docker secrets, `.env` nunca commit), security y hardening.
- El **estándar técnico obligatorio Docker del kit** (secreto en `secrets/`, `.env` solo no sensible, Dockerfile multi-stage con usuario no root UID/GID 10001, `/healthz`, puertos, `.gitignore`/`.dockerignore`) es la **normativa `022-docker-standard`** (ACTIVA en `specs/022-docker-standard/standard.md`, 351 líneas), complementaria a la skill, que se mantiene — NO se archiva.
- No hay artefactos en `022-docker-patterns-metodologia` que no estén ya cubiertos por la skill `docker-patterns` + la normativa `022-docker-standard`. Archivado por referenciación; no se duplica contenido.

## Estado

- **Estado**: ARCHIVADA (fuera del índice activo; reversible con `git mv` inverso).
- La referencia en `00-indice.md` fue actualizada en la fase F (spec 035): se registra la decisión de archivado con referencia a esta NOTA-ARCHIVO y ubicación `specs/archived/022-docker-patterns-metodologia/`, manteniendo `022-docker-standard` como normativa vigente.
