# Tasks: Blindaje `.git` + Alcance quirúrgico (`kit-generico`)

> **Fuente**: `spec.md` de esta carpeta (RF-B1..B4, plan aprobado 2026-09-19).
> **Roles**: T-D = `documentador` ✅ esta entrega; T-I = `devops`; T-V = `qa-senior`.

---

## Documentales (T-D)

- [x] **T-D1** — Spec `kit-generico/spec.md` (RF-B1..B4 + matriz `.opencode` + `.gitignore` por nivel + guards + 6 ACs + fuera de alcance + dependencias + referencias). ✅ 2026-09-19.
- [x] **T-D2** — `tasks.md` (este archivo) con T-D/T-I/T-V para RF-B1..B4. ✅ 2026-09-19.
- [x] **T-D3** — Entrada `[BLINDAJE-GIT]` en `pendientes-implementacion.md` con fase documental marcada. ✅ 2026-09-19.

## Implementación (T-I, `devops`)

- [ ] **T-I1 (RF-B1)** — Verificar/aplicar en `relocate-apps-to-src.ps1`: allowlist sin `.git` + denylist con `.git` + gate git-trackeado + containment-check en `Move-AppToSrc` y `Clear-RegenerableDirs`. Sin cambios de comportamiento fuera de guards.
- [ ] **T-I2 (RF-B2/B3)** — Verificar que `Sync-TransversalKit` solo sincroniza `agents/` + `commands/` (+ provee `.opencode/.gitignore` anidado vía sync); `mcp.json`/`config.json`-plantilla solo por script; runtime/artefactos/secrets jamás versionados ni borrados por sync.
- [ ] **T-I3 (RF-B4)** — Auditar `Remove-Item -Recurse` en ambos scripts: prohibido sobre raíz `.opencode`; toda ruta destructiva con allowlist + containment-check + fail-closed. `Parser::ParseFile` 0 errores + `git status` idéntico en DryRun.

## Validación (T-V, `qa-senior`)

- [ ] **T-V1 (RF-B1)** — Test obligatorio `.git` intacto con **triple fixture** en `$env:TEMP`: `.git` raíz señuelo + `.git` anidado señuelo (simula `proyect_ext/spec-kit/.git` y `proyect_ext/tokenslayer/.git`) + lock simulado (proceso con cwd/handle dentro) → mover+limpiar DryRun + real → **ambos `.git` idénticos (hash/contenido)** + log con aviso de exclusión; caso lock → omitido con aviso, sin estado mixto.
- [ ] **T-V2 (RF-B2/B3)** — `git ls-files .opencode` solo `agents/`+`commands/`(+anidado); `git check-ignore` OK para `config.json`, `node_modules/`, `package*.json`, `bun.lock`, `lib/`, `bin/`; raíz ignora `.opencode/config.json`, `.vscode/*`, `.env*`, regenerables.
- [ ] **T-V3 (RF-B4)** — Revisión por código: sin `Remove-Item -Recurse` sobre raíz `.opencode`; fixture señuelo fuera de allowlist (`.git`, `Documentacion/`) → omitido con aviso, cero mutación; ningún log vuelca contenido de `config.json`.
