# Spec: Blindaje `.git` + Alcance quirúrgico del kit (`kit-generico`)

> **Estado**: Fase documental completada (2026-09-19)
> **Fuente**: Plan aprobado 2026-09-19 (blindaje `.git` + alcance quirúrgico)
> **Autor**: `documentador` (fase documental)
> **Alcance de esta spec**: reglas transversales para `relocate-apps-to-src.ps1` (mover+limpiar) y `Sync-TransversalKit` (sync) en cualquier proyecto del ecosistema.

---

## Objetivo

Garantizar que **ninguna operación de mover, limpiar o sincronizar destruya jamás el historial git** (`.git`) ni se extralimite fuera de su alcance quirúrgico dentro de `.opencode/`.

---

## Hechos verificados (2026-09-19, no negociables)

1. **`.git` nunca se borra**: las operaciones de mover+limpiar usan allowlist sin `.git`, denylist explícita y gate de git-trackeado; cualquier path `.git` queda excluido con aviso.
2. **`.git` anidados reales existen**: `proyect_ext/spec-kit/.git` y `proyect_ext/tokenslayer/.git` (clones de terceros) — el test `.git`-intacto debe cubrirlos, no solo un `.git` raíz señuelo.
3. **`.opencode/.gitignore` del kit ya creado hoy**: `agents/` + `commands/` versionados, resto ignorado (runtime + secrets + artefactos).

---

## Requisitos funcionales

| ID | Requisito | Detalle |
|----|-----------|---------|
| **RF-B1** | **`.git` intacto en mover+limpiar** | `Move-AppToSrc` + `Clear-RegenerableDirs` preservan `.git` SIEMPRE: (1) allowlist de nombres exactos que NO contiene `.git`; (2) denylist explícita que incluye `.git`; (3) gate git-trackeado que excluye con aviso lo versionado; (4) containment-check confina cada operación a la app candidata. Test obligatorio: fixture con `.git` señuelo sobrevive a mover+limpiar (ver T-V). |
| **RF-B2** | **Matriz de alcance `.opencode`** | Alcance quirúrgico por subdirectorio (tabla abajo). Solo `agents/` y `commands/` se versionan y sincronizan. Todo lo demás es runtime/ignorado (nunca versionar, nunca borrar por sync) o secrets (nunca commitear, nunca loguear contenido). |
| **RF-B3** | **Condiciones `.gitignore` por nivel** | Raíz: ignora `.opencode/config.json`, `.vscode/*` salvo settings/extensions, `.env*`, regenerables (`proyect_ext/tokenslayer/`, `revisar_manualmente/`, `.opencode/node_modules/`). Anidado `.opencode/.gitignore` (provisto por el kit vía sync): ignora runtime (`node_modules`, `package.json`, `package-lock.json`, `bun.lock`), secrets (`config.json`) y artefactos (`lib/`, `bin/`). El kit provee el anidado vía sync; el proyecto no lo inventa. |
| **RF-B4** | **Guards en scripts para operaciones destructivas** | Toda operación destructiva (`Move-Item`, `Remove-Item`) solo actúa sobre allowlist exacta + containment-check superado; fail-closed (omitir + aviso) si el path cae fuera; prohibido `Remove-Item -Recurse` sobre la raíz `.opencode` (solo subpaths permitidos ya validados). Sin flag que saltee la confirmación donde aplique (relocate S/N/T/C). |

### RF-B2 — Matriz de alcance `.opencode`

| Subdirectorio / archivo | Estado | Regla |
|---|---|---|
| `agents/` | ✅ Versionar | Kit transversal, se sincroniza (sync). |
| `commands/` | ✅ Versionar | Kit transversal, se sincroniza (sync). |
| `mcp.json` | ⚙️ Generado | El script lo crea/registra; ignorado en raíz (vía `.vscode/`). |
| `config.json`-plantilla | ⚙️ Generado | El script la crea SOLO si no existe, con placeholders (RF-17); el real con secrets siempre ignorado. |
| `node_modules/` | 🚫 Runtime ignorado | Nunca versionar, nunca borrar por sync; limpieza solo vía allowlist de regenerables con confirmación. |
| `package.json` / `package-lock.json` / `bun.lock` | 🚫 Runtime ignorado | Nunca versionar ni borrar; se regeneran vía bootstrap/npm. |
| `lib/` / `bin/` | 🚫 Artefactos ignorados | Se regeneran vía bootstrap/pip; nunca versionar ni borrar por sync. |
| `config.json` con secrets | 🔴 Secreto ignorado | Ignorado siempre; nunca commitear; nunca leer ni imprimir su contenido en logs. |

---

## Requisitos no funcionales

| ID | Requisito |
|----|-----------|
| **RNF-B1** | **Fail-closed por defecto**: ante duda (path fuera de allowlist, lock, `.git` detectado) → omitir + avisar, jamás borrar/mover. |
| **RNF-B2** | **`-DryRun` informa, cero escrituras** en mover, limpiar y sync. |
| **RNF-B3** | **Logs con rutas relativas, sin contenido**: jamás volcar secrets ni contenido de `config.json`. |

---

## Criterios de aceptación

1. **AC-1 (`.git` sobrevive, triple fixture)**: mover+limpiar sobre fixture con **`.git` raíz señuelo + `.git` anidado señuelo + lock simulado** (proceso con cwd/handle dentro) deja ambos `.git` intactos (contenido idéntico antes/después, hash verificado); el caso lock → omitido con aviso, sin estado mixto.
2. **AC-2 (matriz respetada)**: `git ls-files .opencode` solo lista `agents/` + `commands/` (+ `.gitignore` anidado); runtime/secrets/artefactos están ignorados (`git check-ignore` OK).
3. **AC-3 (doble `.gitignore`)**: raíz ignora `.opencode/config.json` + `.vscode/*` + `.env*` + regenerables; `.opencode/.gitignore` ignora runtime + `config.json` + `lib/` + `bin/`; ambos verificados por `git check-ignore`.
4. **AC-4 (guards)**: `Select-String 'Remove-Item.*\.opencode[^/\\]'` sin matches sobre raíz `.opencode`; toda ruta destructiva pasa por allowlist + containment-check (revisión por código).
5. **AC-5 (fail-closed)**: path fuera de allowlist (p. ej. `.git`, `Documentacion/`) → omitido con aviso, sin mutación (test con fixture señuelo).
6. **AC-6 (secrets)**: ningún log/test vuelca contenido de `config.json`; `config.json` real nunca trackeado (`git ls-files` 0 matches).

---

## Fuera de alcance

- Recrear `.venv` rotos por mover (cubierto por RF-14/RF-15, no por esta spec).
- Cambiar el modelo maestro→copia-local de `Sync-TransversalKit` (solo se le añaden guards, no se rediseña).
- Auditoría supply-chain de dependencias (rol de `security-auditor`).
- Huérfanos fuera de `.github/` + `.opencode/agents,commands/` + `.doc_agents/` (cubierto por `[HUERFANOS]`).

---

## Dependencias

- `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-02/RF-05/RNF-04/RNF-05 frontera kit↔app; RF-12 huérfanos; RF-15 allowlist+gate; RF-16/17/18 gaps).
- `seguridad/relocate.md` + `relocate-cleanup.md` + `kit-gaps.md` (condiciones de seguridad que estos RF implementan).
- Tareas `[RELOCATE]` y `[PLATAFORMA]` en `pendientes-implementacion.md`.

---

## Referencias

- `.opencode/.gitignore` (anidado del kit, creado 2026-09-19).
- `.gitignore` raíz (secciones secrets, runtime `.opencode/node_modules/`, clones `proyect_ext/tokenslayer/`, `revisar_manualmente/`).
- `scripts/relocate-apps-to-src.ps1` (`Move-AppToSrc`, `Clear-RegenerableDirs`, denylist + containment-check + gate git-trackeado).
- `scripts/plataformador-bootstrap.ps1` (`Sync-TransversalKit`, `Ensure-OpenCodeConfig` RF-17).
