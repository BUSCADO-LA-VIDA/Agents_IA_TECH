# Bitacora 2026-10-16 — Gitlink huerfano rompia checkout en CI

## Causa real (log del step aportado por el usuario)
`fatal: No url found for submodule path proyect_ext/spec-kit in .gitmodules` en la fase de limpieza de auth del checkout: el indice tenia un gitlink `160000` sin archivo `.gitmodules` (nunca existio).

## Fix
- `git rm --cached proyect_ext/spec-kit`: elimina el puntero stale, conserva los archivos en disco (los gestiona upgrade_framework via manifest, no git).
- 0 gitlinks restantes en el indice.
- `validate-skills.yml` ya tenia `workflow_dispatch`: re-runs a demanda disponibles.
