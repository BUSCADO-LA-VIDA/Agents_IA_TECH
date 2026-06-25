# Template .github — Portátil para cualquier proyecto

> **Creado:** 2026-06-25
> **Fuentes:** [Ponytail](https://github.com/DietrichGebert/ponytail) + [ECC](https://github.com/affaan-m/ECC)

## ¿Qué es?

Carpeta `.github/` lista para copiar a cualquier proyecto. Hace que **GitHub Copilot en VS Code** trabaje con reglas profesionales:

- **Ponytail** — escribe solo el código necesario (~54% menos)
- **ECC** — workflow, seguridad, testing, git convencional, prompts slash, AGENTS.md

> **Nota**: ECC tiene ~80 archivos para 14+ agentes. Este template incluye solo lo que aplica a **GitHub Copilot**: reglas (`copilot-instructions.md`), prompts (`/plan`, `/tdd`, etc.) y `AGENTS.md`. Para integración completa (Claude Code, Codex, Cursor) instala ECC directo con `npx ecc-universal install`.

## Instalación

```bash
# 1. Copiar a tu proyecto
cp -r template-github/.github/ /ruta/de/tu/proyecto/

# 2. ¡Listo! Funciona automáticamente al abrir el proyecto en VS Code
```

## Estructura

```
.github/
├── copilot-instructions.md    ← Reglas siempre activas (Ponytail + ECC)
├── prompts/                   ← Slash commands de ECC
│   ├── plan.prompt.md         → /plan     — Plan de implementación
│   ├── tdd.prompt.md          → /tdd      — TDD cycle
│   ├── security-review.md     → /security-review — Auditoría de seguridad
│   ├── build-fix.prompt.md    → /build-fix — Diagnosticar errores de build
│   └── refactor.prompt.md     → /refactor — Limpieza y simplificación
└── workflows/
    └── agentshield.yml        ← Escanea seguridad al modificar .github/

AGENTS.md                      ← ECC fallback para Copilot CLI
```

## Seguridad

Incluye **AgentShield** (`npx ecc-agentshield scan`) — escanea configuraciones de agentes en busca de secrets hardcodeados, permisos mal configurados y vulnerabilidades. Se ejecuta automáticamente en CI al modificar `.github/`.

## Personalización

Agrega tus reglas específicas del proyecto en:

- **`instructions/`** — Instrucciones de dominio (ej: `migracion-laravel.instructions.md`)
- **`skills/`** — Agentes especializados (ej: `implementar-modulo-laravel/SKILL.md`)

## Uso de Prompts

En **Copilot Chat** (Ctrl+Shift+I), escribe `/` y selecciona el prompt:

| Prompt | Cuándo usarlo |
|--------|---------------|
| `/plan` | Feature compleja — genera plan por fases |
| `/tdd` | Nueva feature o bug fix — ciclo TDD |
| `/security-review` | Antes de release — auditoría profunda |
| `/build-fix` | Error de build/CI — resolución sistemática |
| `/refactor` | Mantenimiento — limpieza de código muerto |

## Fuentes

- **[Ponytail](https://github.com/DietrichGebert/ponytail)** — MIT License
- **[ECC](https://github.com/affaan-m/ECC)** — MIT License
