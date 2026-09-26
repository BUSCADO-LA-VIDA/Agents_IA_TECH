# AGENTS.md

> Fuente de verdad única de reglas base para todos los harness (GitHub Copilot VS Code, OpenCode, Codex, Claude Code, Cursor, Windsurf).
> Este repo es un kit portable de agentes, skills y prompts. No es una aplicación: no hay `src/`, build, tests ni runtime. Todo es configuración (`.md`).
> Si algún otro archivo (`.github/copilot-instructions.md`, `CLAUDE.md`, `.cursorrules`, etc.) contiene reglas base, es solo un puntero a este archivo.

---

## REGLAS CRÍTICAS (leer primero, sin excepción)

> Regla del usuario (2026-09-26) - Integridad de trabajo:
> - NUNCA marcar una tarea como completada `[x]` si no está realmente implementada y validada.
> - NUNCA dar información falsa ni reportar éxito sin evidencia.
> - Si faltan permisos para editar, pedirlos explícitamente antes de actuar.
> - Siempre verificar la escritura de archivos leyendo después de escribir.
> - No avanzar de fase sin completar y verificar la anterior.
> - Auto-verificar los cambios antes de reportar.
> - Si algo no se pudo hacer o verificar, decirlo explícitamente. No inventar.

> Regla del usuario (2026-09-26) - Contenido completo, nunca esqueletos:
>
> Esta regla aplica a TODO archivo que un agente cree o actualice, sin
> excepción: documentos SDD/SpecKit (analyze, converge, specify, plan, tasks,
> implement, checklist, constitution, data-model, quickstart, research),
> especificaciones, ADRs, READMEs, bitácoras, roadmaps, informes, y cualquier
> archivo de documentación o configuración generado.
>
> PROHIBIDO entregar solo el esqueleto, encabezado, título o plantilla vacía.
> PROHIBIDO dejar secciones con solo el título y nada debajo.
> PROHIBIDO usar placeholders: TBD, TODO, pendiente, por definir, N/A,
> completar aquí, XXX, "..." o repetir el nombre de la sección como contenido.
> PROHIBIDO entregar tablas con solo el encabezado y cero filas reales.
> PROHIBIDO entregar listas vacías o con un solo item genérico.
>
> Si el archivo tiene secciones estándar (plantilla), TODAS deben quedar
> rellenas con el contenido real del proyecto. Si una sección no aplica,
> escribir en una línea POR QUÉ no aplica. Nunca dejarla vacía.
>
> Ejemplo de lo que NO se debe hacer:
>
>     # Analyze 015
>     Análisis de consistencia
>
>     # Converge 015
>     Convergencia
>
>     # Data Model 015
>     Estructura de sync-kit
>
> Ejemplo de lo que SI se debe hacer: cada sección con su análisis, hallazgos,
> decisiones, referencias a specs/ADRs, tablas con filas reales, diagramas
> Mermaid cuando aplique, tareas derivadas y métricas concretas.
>
> VERIFICACIÓN OBLIGATORIA antes de dar por terminado cualquier archivo:
> 1. Leer el archivo escrito (no confiar en la memoria de lo que se creyó
>    escribir; abrirlo y leerlo).
> 2. Confirmar que ninguna sección quedó con solo el título.
> 3. Confirmar que no hay placeholders (TBD, TODO, pendiente, etc.).
> 4. Confirmar que las tablas tienen filas reales y las listas tienen items
>    concretos.
> 5. Contar líneas de contenido real por sección. Si una sección tiene menos
>    de 3 líneas útiles, probablemente está incompleta: revisarla.
> 6. Si algo quedó incompleto o no se pudo rellenar por falta de información,
>    NO marcarlo como terminado. Decirlo explícitamente y pedir lo que falta.
>
> Si el usuario pide "un resumen", "un borrador" o "algo rápido", esta regla
> sigue aplicando: se entrega completo o se avisa que se entrega parcial a
> propósito y por qué. Nunca se entrega esqueleto disfrazado de documento.

> Regla del usuario (2026-09-12) - Gobernanza de agentes:
> Todo agente del kit debe cumplir las reglas transversales. Se aplican SIEMPRE al crear o modificar agentes.

### Reglas transversales de los agentes (gobernanza)

- Consultar los MCPs como herramienta primaria (Regla 1): `context-mode` (`ctx_search`), `codebase-memory-mcp` (`search_graph`), `markitdown` (`convert_to_markdown`).
- Estructura estándar de agente (Regla 2): frontmatter, introducción, skills, enfoque, MCPs, idioma, constraints.
- Sincronización entre arneses (Regla 3): `.github/agents/` y `.opencode/agents/` en paralelo.
- Orquestación y delegación (Regla 4): cada agente hace UNA cosa; los orquestadores hacen cumplir las reglas a los agentes debajo.
- Persistencia del comportamiento (Regla 5): las decisiones transversales quedan en archivos.
- Contexto mínimo necesario: cada agente recibe solo el contexto necesario, sin sobrecargar.
- Buenas prácticas: Ponytail ladder, conventional commits, mínimo 80% cobertura, seguridad pre-commit.
- Contenido completo: todo archivo generado por cualquier agente debe tener contenido real en cada sección. Prohibido esqueletos vacíos, plantillas sin rellenar, tablas vacías o placeholders (TBD/TODO/pendiente/N/A).
- Si un agente no está configurado correctamente (falta sección MCPs, estructura, etc.), llamar al agente correspondiente (`plataformador` para nivelar, `arquitecto`/`documentador` para specs).

---

## Core facts an agent must know

- Dual-tool target: `.github/` para GitHub Copilot; `.opencode/` para OpenCode. Ambos definen los mismos 11 agentes + 6 slash commands en estructuras paralelas. Mantenerlos sincronizados al editar definiciones de agentes.

- Skills globales: las skills (speckit-specify, speckit-plan, speckit-converge, etc.) son compartidas globalmente desde el workspace master (`.github/skills/`). No duplicar por proyecto.

- .specify por proyecto: `.specify/` es específico de cada proyecto. Contiene la constitución, principios y configuración particular. Ubicación típica: `<proyecto>/.specify/memory/constitution.md`.

- Estructura de documentación por aplicación: cada aplicación tiene su propia carpeta `Documentacion/<AppName>/` aislada. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) se copia/sincroniza entre proyectos. `Documentacion/<AppName>/` es propia de cada app y NUNCA se copia. Ver `.doc_agents/estructura-aplicacion.md`.

- Agent road assignment: 14 agentes, cinco tiers.

  | Tier | Agents | Can write code? |
  |------|--------|:---:|
  | Documental | `pensador`, `arquitecto`, `documentador`, `security-auditor` | No. Solo `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` |
  | Documental extendido | `Agent-SSD` | No. Solo `src/<App>/.specify/` (esa subcarpeta), `Documentacion/<AppName>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`. Orquestador del flujo SSD + ejecutor de comandos Speckit (ADR-0005) |
  | Implementador | `api-developer`, `frontend-developer`, `devops`, `qa-senior` | Sí. App code (`src/`, `tests/`) |
  | Tooling | `gitflow` | Sí. Git operations, branching, PRs, reverts |
  | Plataforma | `solucionador`, `plataformador` | Sí. Diagnóstico remoto y nivelación de proyectos |

---

## Commands

```powershell
# Sync kit transversal (.github/, .opencode/, .doc_agents/, .specify/memory/constitution.md, AGENTS.md, opencode.json, README.md, sync-agents.ps1)
# NUNCA toca Documentacion/<AppName>/
.\sync-agents.ps1

# Dry-run para ver qué cambiaría sin escribir
.\sync-agents.ps1 -DryRun

# Security scan (also runs in CI on .github/ changes)
npx ecc-agentshield scan