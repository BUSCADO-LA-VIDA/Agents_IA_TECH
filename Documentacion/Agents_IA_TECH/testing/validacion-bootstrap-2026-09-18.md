# Validación bootstrap instalador único — `qa-senior` (T-I6, T-V1–T-V4)

- **Fecha**: 2026-09-18
- **Agente**: `qa-senior` (solo lectura + DryRun; ningún modo real ejecutado)
- **Alcance**: spec `specs/plataforma-bootstrap-instalador-unico/` (criterios 1–7), condición 4 de `seguridad/plataforma-bootstrap.md`
- **Restricción**: sin escrituras fuera de `Documentacion/Agents_IA_TECH/testing/`, `pendientes-implementacion.md` y `tasks.md` de la spec

## Comandos ejecutados (todos en `pwsh` 7.6.6 salvo indicación)

1. `git status --porcelain` (ANTES) — `C:\Proyectos\Agents_IA_TECH`
2. `scripts/plataformador-bootstrap.ps1 -DryRun -NoRestart -SkipInstall -SkipIndexing` (raíz Agents_IA_TECH) → EXIT 0
3. `git status --porcelain` (DESPUÉS) → idéntico al ANTES
4. `sync-agents.ps1 -DryRun` → EXIT 0; `git status` idéntico
5. `scripts/plataformador-bootstrap.ps1 -DryRun -NoRestart -SkipInstall -SkipIndexing -ProjectRoot C:\Proyectos\Metatrader` → EXIT 0
6. `npx ecc-agentshield scan -p C:\Proyectos\Agents_IA_TECH` → EXIT 0, Grade A (98/100)
7. Lectura estática: `Configure-SpecKit` (líneas 1246–1299), `Resolve-ActiveApp` (950–1012), `opencode.json`, `.github/hooks/context-mode.json`, `.vscode/mcp.json`

## T-I6 + T-V1 (DryRun Agents_IA_TECH) — PASS

- `git status` ANTES == DESPUÉS (cero escrituras; el diff preexistente — `00-indice.md`, `referencias.md`, `dependencias-manifest.yml`, `opencode.json`, `sync-agents.ps1`, untracked `adr-0003`, `seguridad/plataforma-bootstrap.md`, `specs/`, `scripts/plataformador-bootstrap.ps1`, `Documentacion/index-preflight.md` — no cambió).
- Salida verificada:
  - (a) PASS — Sync lista los 8 transversales: `.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`
  - (b) PASS — `DryRun: excluiría .opencode/config.json (posibles credenciales, nunca se copia)`
  - (c) PASS — `DryRun: NUNCA tocaría Documentacion/<AppName>/ (frontera kit <-> app)`
  - (d) PASS — `App activa: root` (cwd = raíz, sin coincidencia; esperado)
  - (e) PASS — `.specify activo (kit/root)` + `Specs dir: .../Documentacion/Agents_IA_TECH/specs`
  - (f) PASS — 5 WARN de apps ausentes (5 apps del proyecto), sin clonar (RNF-06, esperado)
  - (g) PASS — `proyect_ext/spec-kit queda en la raíz (no se mueve)`; existe en disco (`.devcontainer`, `.github`, `.specify`, `bundles`, `docs`, …)
  - (h) PASS — `Graphify disponible en: .../.opencode/lib/graphify`
- `sync-agents.ps1 -DryRun` → EXIT 0, delega en `Sync-TransversalKit` (`-SyncOnly`), misma lista de 8 items, `git status` idéntico. Criterio 7 PASS.

## T-V1 2ª parte (DryRun Metatrader) — PASS

- El parámetro `-ProjectRoot` **sí existe** (línea 27 del script); se usó `-ProjectRoot C:\Proyectos\Metatrader` → EXIT 0.
- Metatrader **no es repo git** (`fatal: not a git repository`), por lo que la verificación es por salida, no por diff:
  - Las 5 apps **sí existen en raíz** (5 apps del proyecto) → `se respeta su ubicación, RNF-04; no se mueve nada` + solo líneas `DryRun: aseguraría Documentacion/<app>/`.
  - Sync declara `NUNCA tocaría Documentacion/<AppName>/`; ninguna línea de la salida escribe en `Documentacion/` real (todo `DryRun:`).
  - `proyect_ext/spec-kit queda en la raíz` OK; Graphify OK (`C:\Proyectos\Metatrader\.opencode\lib\graphify`).
  - `Documentacion/` de Metatrader intacta (directorios listados sin cambios: `agents`, `Agents_IA_TECH`, `bitacoras`, `ecosistema`, `fibo-scanner`, `telegram`).

## T-V2 (Spec-kit por app activa, estático) — PASS

`Configure-SpecKit` (líneas 1246–1299), lógica correcta:
- `root` → `SpecDir=<Root>/.specify`, `SpecsDir=<Root>/Documentacion/Agents_IA_TECH/specs`. Correcto (RF-08, criterio 5).
- `-App <app>` → `AppDir=<Root>/src/<app>` (fallback `<Root>/<app>`, fallback raíz con WARN), `SpecDir=<AppDir>/.specify` (creado desde base solo si existe base; si no, WARN y sigue), `SpecsDir=<Root>/Documentacion/<app>/specs` (asegurado vía `Ensure-Directory`, que en DryRun no escribe). Correcto.
- `cwd` dentro de app → resuelto antes por `Resolve-ActiveApp` (precedencia `-App` > `cwd` anclado a `src/<app>` o `<raíz>/<app>` > `root`), con segunda pasada por segmento exacto anti-falsos-positivos. Correcto.
- Sin defectos lógicos. Modo real **no ejecutado** (fuera de alcance de esta validación; queda pendiente si se quiere verificar escritura real).

## T-V3 (flujo desde carga VS Code, estático) — PASS

- (a) PASS — `opencode.json` JSON válido: `plugin: ["context-mode"]` + `mcp` con los 3 servidores (`context-mode`, `codebase-memory-mcp`, `markitdown`, todos `enabled: true`).
- (b) PASS — `.github/hooks/context-mode.json` válido con `PreToolUse`, `PostToolUse`, `SessionStart`.
- (c) PASS — `.vscode/mcp.json` válido con los 3 servidores (`markitdown`, `codebase-memory-mcp`, `context-mode`, tipo `stdio`).
- Extra: `context-mode doctor` (invocado por el propio bootstrap en paso 10) → PASS general; 2 WARN no bloqueantes: `Legacy MCP registration` (`mcp.context-mode` redundante con el plugin) y `npm (MCP): local vunknown, latest v1.0.169` (actualización disponible).

## T-V4 (security scan) — PASS

- `npx ecc-agentshield scan -p C:\Proyectos\Agents_IA_TECH` → **Grade A (98/100)**, 22 archivos, 3 hallazgos: 0 critical, 0 high, 2 medium, 1 low. EXIT 0.
  - Medium: `.vscode/settings.json` sin bloque `permissions`; sin `PreToolUse` hooks de seguridad (el kit usa `.github/hooks/context-mode.json`, no `settings.json` — hallazgo de alcance limitado).
  - Low: plugin `context-mode` en `opencode.json` sin versión pineada.
- Nota: sin `-p` el scan apunta a `~/.claude` (Grade B, 2 critical de prompt-defense en `CLAUDE.md` global) — **fuera del alcance** de esta spec (es config global del usuario, no del repo).

## Bugs / hallazgos para `devops`/`plataformador` (NO corregidos, por restricción)

1. **[H-1, severidad media-baja] `plataformador-bootstrap.ps1` no parsea en Windows PowerShell 5.1** (`powershell.exe`): `ParserError` (`MissingArgument`, `MissingArgument`, llaves) por caracteres especiales/encoding (backticks, em-dash, `↔`). En **pwsh 7.6.6 funciona (EXIT 0)**. Acción sugerida: guardar el script en UTF-8 con BOM o declarar requisito `pwsh >= 7` en la cabecera del script y en la spec. No bloquea si el rollout usa pwsh.
2. **[H-2, informativo] WARN `context-mode doctor`**: registro MCP legacy redundante + actualización a v1.0.169 disponible. Acción sugerida: `context-mode upgrade` y revisar `ctx_upgrade` (no bloqueante).
3. **[H-3, conocido, condición de seguridad] Licencia de `graphify` pendiente** (guardrail 8; ya registrado en `seguridad/plataforma-bootstrap.md`). El script correctamente **no descarga** Graphify sin validación (fail-closed). Cerrar la licencia antes de copiarlo al kit.
4. **[H-4, informativo] `ecc-agentshield` sin `-p` escanea `~/.claude`**, no el repo. Documentar invocar siempre con `-p <repo>`.

## Conclusión de rollout

**Sí con condiciones**: el bootstrap en DryRun cumple los criterios 3, 4, 5, 6, 7 (idempotencia real —criterio 2— y proyecto-nuevo/apps-descargadas —criterio 1 parcial— no son verificables en DryRun por diseño).
Condiciones antes del modo real:
1. Usar **pwsh ≥ 7** (H-1) o corregir encoding.
2. Primer modo real con `-DryRun` previo + `git status` antes/después, empezando por proyecto de prueba (Metatrader ya validado en DryRun).
3. Cerrar licencia pendiente de `graphify` (H-3) antes de integrarlo al kit (el script ya lo bloquea por diseño).
4. Opcional no bloqueante: atender H-2 y los 3 hallazgos LOW/MEDIUM del scan.
