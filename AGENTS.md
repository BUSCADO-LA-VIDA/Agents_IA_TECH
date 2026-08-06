# AGENTS.md

> **What this repo is**: a portable kit of agents, skills, and prompts for GitHub Copilot (VS Code) and OpenCode. It is **not an application** — there is no `src/`, no build, no tests, no runtime. All code here is configuration: `.md` files that define agent behavior.

## Core facts an agent must know

- **Dual-tool target**: `.github/` is for GitHub Copilot; `.opencode/` is for OpenCode. Both define the same 11 agents + 6 slash commands, in parallel structures. Keep them in sync when editing agent definitions.
- **Agent road assignment** — 9 agents, three tiers:

  | Tier | Agents | Can write code? |
  |------|--------|:---:|
  | Documental | `pensador`, `arquitecto`, `documentador`, `security-auditor` | ❌ only `Documentacion/`, `.github/`, `.opencode/`, `README.md` |
  | Implementador | `api-developer`, `frontend-developer`, `devops`, `qa-senior` | ✅ app code |
  | Tooling | `gitflow` | ✅ git operations, branching, PRs, reverts |
| Plataforma | `solucionador`, `plataformador` | ✅ diagnostico remoto y nivelacion de proyectos |

## Commands

```powershell
# Sync .github/ from upstream (overwrites .github/, creates-only in Documentacion/)
.\sync-agents.ps1

# Security scan (also runs in CI on .github/ changes)
npx ecc-agentshield scan
```

No `npm install`, no build, no tests — this repo has no runtime dependencies. `.opencode/package.json` only declares `@opencode-ai/plugin`.

## Where instruction sources live

- `opencode.json` → OpenCode config; `instructions` points to `.github/copilot-instructions.md`.
- **`.github/copilot-instructions.md` is the canonical base-rules file** — it is duplicated into `AGENTS.md` and `copilot-instructions.md` intentionally. When updating base rules, edit `copilot-instructions.md` first; it is the source the tools actually load.
- `.opencode/config.json` may contain credentials (NVIDIA API key). Do not print, commit, or echo it.

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
- Functions < 50 lines, files < 400 lines, no nesting > 4 levels, no in-place mutation.

## What NOT to do

- Do not treat this repo as an app — no app entrypoints, no `src/` to trace.
- Do not edit `.opencode/config.json` credentials.
- Do not overwrite `Documentacion/` files during sync.
- Implementadores never improvise beyond specs — if a bug has no spec, they add a task to `pendientes-implementacion.md` and request the spec from a documental agent.
