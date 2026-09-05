# 📋 Índice General del Repositorio: Agents_IA_TECH
*Última actualización: 2026-08-30*

> **Este archivo es el índice del REPOSITORIO COMPLETO** (kit de agentes transversal).  
> Para la documentación del PROYECTO ESPECÍFICO, ver `Documentacion/Agents_IA_TECH/00-indice.md`.  
> Los agentes leen **primero** el índice de su app/proyecto (`Documentacion/<AppName>/00-indice.md`).

## Qué es este repo

**Kit portable de agentes, skills y prompts** para GitHub Copilot (VS Code) y OpenCode.  
No es una aplicación — no hay `src/`, build, tests ni runtime. Todo es configuración (`.md` que define comportamiento de agentes).

## Estructura del repositorio (kit transversal)

```
Agents_IA_TECH/
├── .github/                    ← Agentes, prompts, skills para Copilot
│   ├── agents/                 ← 11 agentes (.agent.md)
│   ├── prompts/                ← 6 slash commands (.prompt.md)
│   ├── skills/                 ← 77 skills globales (compartidas)
│   └── copilot-instructions.md ← Reglas base (fuente canónica)
├── .opencode/                  ← Agentes, commands, config para OpenCode
│   ├── agents/                 ← 11 agentes (.md)
│   ├── commands/               ← 6 slash commands (.md)
│   └── config.json             ← Config OpenCode
├── .doc_agents/                ← 📐 **Estructura transversal del kit** (se copia entre proyectos)
│   ├── estructura-aplicacion.md    ← Estructura doc por app (fuente de verdad)
│   ├── capacidad-base.md           ← Catálogo central del kit (fuente de verdad)
│   ├── estructura-estandar.md      ← Estándar documental por app
│   ├── memoria-proyecto-template.md ← Template memoria-proyecto.md
│   └── sync-agents-template.ps1    ← Template script sync
├── .specify/                   ← Config speckit (constitución base)
│   └── memory/constitution.md
├── Documentacion/              ← 📁 Documentación POR PROYECTO/APP (NO se copia)
│   └── Agents_IA_TECH/         ← 📁 Doc PROPIA de ESTE proyecto (kit)
│       ├── 00-indice.md        ← Índice del PROYECTO (leer este)
│       ├── specs/              ← speckit escribe aquí
│       ├── arquitectura/adr/   ← ADRs
│       ├── agents/             ← Specs de cada agente
│       ├── bitacoras/          ← Bitácoras solucionador
│       ├── sesiones/           ← Persistencia entre reinicios VS Code
│       └── ... (ver Documentacion/Agents_IA_TECH/00-indice.md)
├── AGENTS.md                   ← Documentación del kit (para herramientas)
├── opencode.json               ← Config OpenCode
├── README.md                   ← README del repo
├── sync-agents.ps1             ← Script sincronización kit transversal
└── CLAUDE.md                   ← Config Claude Code (graphify)
```

## Componentes del kit

### Agentes (11)

| Agente | Tipo | Descripción |
|--------|------|-------------|
| `pensador` | Documental | **Orquestador principal** — complementa Specify, planifica, orquesta, persiste sesiones |
| `arquitecto` | Documental | ADRs, guardrails, spec linking, diagramas |
| `documentador` | Documental | Specs, templates, versionado, spec→plan, pendientes |
| `security-auditor` | Documental | OWASP, secrets, dependencias, guardrails seguridad |
| `api-developer` | Implementador | Backend/API, speckit-implement |
| `frontend-developer` | Implementador | UI/React/Next.js, speckit-implement |
| `devops` | Implementador | Docker, CI/CD, infra, speckit-implement |
| `qa-senior` | Implementador | Tests (unit/integration/E2E), feedback loop, SSH+DB |
| `gitflow` | Tooling | Git ops, conventional commits, PRs |
| `solucionador` | Plataforma | SSH remoto lectura+escritura (super poder) |
| `plataformador` | Plataforma | Auditoría/nivelación proyectos, graphify, doc obligatoria |

### Skills globales (77 en `.github/skills/`)

Incluyen: `speckit-*` (10), `codebase-memory`, `graphify`, `agent-customization`, `chronicle`, `project-setup-info-local`, `python-fact-grounded-coding`, `pylance-*`, y 60+ más.

### MCP recomendado

- `codebase-memory-mcp` — Grafo conocimiento código (`npm install -g codebase-memory-mcp`)

## Flujo de trabajo principal

```mermaid
flowchart TD
    A[Usuario: duda/solicitud] --> B[Pensador: analiza + plan]
    B --> C{Usuario aprueba plan?}
    C -->|No| B
    C -->|Sí| D[Pensador: orquesta Documentales]
    D --> E[Arquitecto: ADRs, guardrails]
    E --> F[Documentador: specs, plan, tasks (speckit)]
    F --> G[Security: auditoría si aplica]
    G --> H{Usuario: implementar?}
    H -->|No| I[Fin - docs listas]
    H -->|Sí| J[Pensador: orquesta Implementadores]
    J --> K[API / Frontend / DevOps]
    K --> L[QA-senior: tests + feedback loop]
    L --> M[Gitflow: commits convencionales]
    M --> N[Plataformador: si proyecto nuevo]
```

## Reglas clave

- **Documentación por app**: `Documentacion/<AppName>/` es propia, NUNCA se copia/sincroniza
- **Kit transversal**: `.github/`, `.opencode/`, `.doc_agents/`, `.specify/` SÍ se sincronizan con `sync-agents.ps1`
- **Pensador complementa Specify**: No duplica — orquesta speckit skills + mis agentes únicos
- **Ciclo obligatorio**: Plan aprobado → Documentar → Implementar (siempre en ese orden)
- **Persistencia**: Sesiones en `Documentacion/<AppName>/sesiones/` — leer al inicio, guardar antes de borrar
- **Paths documentales**: Solo `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`
- **Español latino neutro** en toda comunicación

## Sincronización del kit

```powershell
# Sincroniza SOLO kit transversal (NUNCA toca Documentacion/<AppName>/)
.\sync-agents.ps1
# Dry-run:
.\sync-agents.ps1 -DryRun
```

## Referencias rápidas

- Estructura por app: `.doc_agents/estructura-aplicacion.md`
- Capacidad base kit: `.doc_agents/capacidad-base.md`
- Estándar documental: `.doc_agents/estructura-estandar.md`
- Documentación proyecto: `Documentacion/Agents_IA_TECH/00-indice.md`
- Análisis Specify vs Agentes: `Documentacion/Agents_IA_TECH/referencias.md`
- Sesiones persistentes: `Documentacion/Agents_IA_TECH/sesiones/`