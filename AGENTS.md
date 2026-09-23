# AGENTS.md

> **What this repo is**: a portable kit of agents, skills, and prompts for GitHub Copilot (VS Code) and OpenCode. It is **not an application** — there is no `src/`, no build, no tests, no runtime. All code here is configuration: `.md` files that define agent behavior.

## Core facts an agent must know

- **Dual-tool target**: `.github/` is for GitHub Copilot; `.opencode/` is for OpenCode. Both define the same 11 agents + 6 slash commands, in parallel structures. Keep them in sync when editing agent definitions.

- **Skills globales** ⭐: Las skill (speckit-specify, speckit-plan, speckit-converge, etc.) son **compartidas globalmente** desde el workspace master (`.github\skills\`). No necesitas duplicarlas por proyecto - un solo conjunto de skills sirve para todos tus proyectos.

- **.specify por proyecto ⭐**: `.specify/` es **específico de cada proyecto** - contiene la constitución, principios y configuración particular de ese proyecto. Cada proyecto tiene el suyo propio (puede heredar de la base pero tiene customizaciones propias). Ubicación típica: `<proyecto>/.specify/memory/constitution.md.`

- **Estructura de documentación por aplicación ⭐**: Cada aplicación tiene su propia carpeta `Documentacion/<AppName>/` aislada. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) se copia/sincroniza entre proyectos. `Documentacion/<AppName>/` es **propia de cada app y NUNCA se copia**. Ver `.doc_agents/estructura-aplicacion.md`.

- **Agent road assignment** — 14 agents, five tiers:

  | Tier | Agents | Can write code? |
  |------|--------|:---:|
  | Documental | `pensador`, `arquitecto`, `documentador`, `security-auditor` | ❌ only `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` |
  | Documental extendido | `Agent-SSD` | ❌ only `src/<App>/.specify/` (SOLO esa subcarpeta), `Documentacion/<AppName>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` — orquestador del flujo SSD + ejecutor de comandos Speckit (ADR-0005) |
  | Implementador | `api-developer`, `frontend-developer`, `devops`, `qa-senior` | ✅ app code (`src/`, `tests/`) |
  | Tooling | `gitflow` | ✅ git operations, branching, PRs, reverts |
  | Plataforma | `solucionador`, `plataformador` | ✅ diagnostico remoto y nivelacion de proyectos |

## Commands

```powershell
# Sync kit transversal (.github/, .opencode/, .doc_agents/, .specify/memory/constitution.md, AGENTS.md, opencode.json, README.md, sync-agents.ps1)
# NUNCA toca Documentacion/<AppName>/
.\sync-agents.ps1

# Dry-run para ver qué cambiaría sin escribir
.\sync-agents.ps1 -DryRun

# Security scan (also runs in CI on .github/ changes)
npx ecc-agentshield scan
```

No `npm install`, no build, no tests — this repo has no runtime dependencies. `.opencode/package.json` only declares `@opencode-ai/plugin`.

## Where instruction sources live

- `opencode.json` → OpenCode config; `instructions` points to `.github/copilot-instructions.md`.
- **`.github/copilot-instructions.md` is the canonical base-rules file** — it is duplicated into `AGENTS.md` and `copilot-instructions.md` intentionally. When updating base rules, edit `copilot-instructions.md` first; it is the source the tools actually load.
- `.opencode/config.json` may contain credentials (NVIDIA API key). Do not print, commit, or echo it.
- `.doc_agents/estructura-aplicacion.md` — Define la estructura por aplicación (fuente de verdad para `plataformador` y agentes documentales).
- `.doc_agents/capacidad-base.md` — Catálogo central del kit transversal (fuente de verdad para `plataformador`).

## Editing agent definitions

- Same agent exists in two places: `.github/agents/<name>.agent.md` (Copilot) and `.opencode/agents/<name>.md` (OpenCode). Update both unless the change is tool-specific.
- Slash commands: `.github/prompts/<name>.prompt.md` ↔ `.opencode/commands/<name>.md`.
- Skills live only in `.github/skills/<category>/<name>/SKILL.md` (77 total) — no OpenCode mirror.

## Language protocol

Think in English, respond in Spanish, code/docs in English. Spanish domain terms keep their original name.

## Workflow conventions

- **Conventional commits** (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`).
- **Ponytail ladder**: YAGNI → reuse → stdlib → native feature → dependency → one-liner → then write minimum. `ponytail:` marks intentional simplifications.
- **Design-first flow**: when the user says "documentar", ask "¿código o especificaciones?" — código → developer documents inline; especificaciones → `pensador` orchestrates `arquitecto` → `documentador` → (optional) `security-auditor`, then asks before implementing. Full flowchart in `copilot-instructions.md`.
- **Plan → Document → Implement cycle**: El `pensador` orquesta este ciclo en este orden estricto. Si cambian las specs, el ciclo se reinicia desde la validación de specs. Testing sigue SSD y Spec-KIT. `ponytail:` marca simplificaciones intencionales.
- Functions < 50 lines, files < 400 lines, no nesting > 4 levels, no in-place mutation.

## Reglas transversales de los agentes (gobernanza)

> **Regla del usuario (2026-09-12)**: Todo agente del kit debe cumplir las reglas transversales definidas en `Documentacion/<AppName>/reglas-transversales-agentes.md`. Estas reglas se aplican **SIEMPRE** al crear o modificar agentes.

- **Consultar los MCPs** como herramienta primaria (Regla 1) — `context-mode` (`ctx_search`), `codebase-memory-mcp` (`search_graph`), `markitdown` (`convert_to_markdown`).
- **Estructura estándar** de agente (Regla 2) — frontmatter, introducción, skills, enfoque, MCPs, idioma, constraints.
- **Sincronización entre arneses** (Regla 3) — `.github/agents/` y `.opencode/agents/` en paralelo.
- **Orquestación y delegación** (Regla 4) — cada agente hace UNA cosa; los orquestadores hacen cumplir las reglas a los agentes debajo.
- **Persistencia del comportamiento** (Regla 5) — las decisiones transversales quedan en archivos.
- **Contexto mínimo necesario** — cada agente recibe solo el contexto necesario para ejecutar su tarea, sin sobrecargar.
- **Buenas prácticas** — seguir la Ponytail ladder, conventional commits, mínimo 80% cobertura, seguridad pre-commit.
- **Si un agente no está configurado correctamente** (falta sección MCPs, estructura, etc.) → llamar al agente correspondiente (`plataformador` para nivelar, `arquitecto`/`documentador` para specs) para que todo tenga la estructura correcta.

## What NOT to do

- Do not treat this repo as an app — no app entrypoints, no `src/` to trace.
- Do not edit `.opencode/config.json` credentials.
- Do not overwrite `Documentacion/<AppName>/` files during sync — cada app tiene su doc propia.
- Implementadores never improvise beyond specs — if a bug has no spec, they add a task to `pendientes-implementacion.md` and request the spec from a documental agent.
