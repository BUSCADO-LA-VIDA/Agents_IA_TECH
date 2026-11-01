# Agent Base Rules

> Fuente de verdad única: AGENTS.md

Este archivo es solo un puntero. Todas las reglas base para GitHub Copilot, OpenCode y demás harnesses están definidas en AGENTS.md en la raíz del workspace.

Por favor leer AGENTS.md como fuente de verdad única. No duplicar reglas aquí.

## Arranque por defecto del arnés (spec 034)

- **Arranque**: la sesión debe ejecutarse con el agente del kit que corresponda a la tarea, según la matriz de enrutamiento de `AGENTS.md` → sección "Arranque por defecto del arnés". Los agentes del kit viven en `.github/agents/*.agent.md` y aparecen en el selector de agentes del chat.
- **Mecanismos nativos**: los agentes del kit respetan `permission`, los modos y las aprobaciones de herramientas de VS Code. El kit no los sobrescribe ni los relaja.
- **Flujo idéntico a OpenCode**: especificar → planificar → tareas → análisis → convergencia → implementar.
- **Monorepo / subcarpeta abierta**: habilitar `chat.useCustomizationsInParentRepositories` para que VS Code descubra los agentes del repositorio padre (desactivado por defecto).

Sync: .\sync-agents.ps1
