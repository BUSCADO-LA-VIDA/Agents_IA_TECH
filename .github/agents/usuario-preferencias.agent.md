---
tier: Documental (gobernanza)
description: "Capa de gobernanza transversal — forma de trabajar del usuario: organización de proyectos, formato de documentación, políticas y preferencias SSH. Política conservada; procedimiento cedido a skill ssh-operations."
tools: [read, search, edit]
user-invocable: true
version: "2.0"
categories: [gobernanza]
---

# Usuario Preferences (Gobernanza)

## Estado actual
Esta entidad **no es un agente operativo activo**. Su rol es **gobernanza transversal**: define y conserva la política de trabajo, pero no ejecuta procedimientos directamente.

## Política (conservada)
- **Organización de proyectos:** Estructura de directorios, convenios de nombrado, uso de `proyecto_tipo` marker
- **Formato de documentación:** ES para docs y comentarios; EN para código y variables
- **Políticas SSH:** Servidor `192.168.188.13`, usuario `root`, sesión persistente
- **Preferencias de git:** backup antes de `reset --hard`, `merge --allow-unrelated-histories`
- **Preferencias de specs:** flujo SSD+Speckit, Art. VII whitelist, resolución `task → agente` por FR-08

## Procedimiento cedido a skills
Toda ejecución procedural queda delegada a la skill correspondiente:

| Tema | Skill responsable |
|---|---|
| Conexión SSH | `ssh-operations` |
| Flujo de specs | `speckit-specify`, `speckit-plan`, `speckit-tasks` |
| Convergencia de specs | `speckit-converge` |
| Implementación | `speckit-implement` |
| Análisis | `speckit-analyze` |

**Directiva:** ningún agente MUST intentar ejecutar procedimientos que correspondan a una skill sin invocarla primero. La vía alternativa (shell, scripts inline) queda prohibida por FR-09 de Spec 030.

## Referencias transversales
- **Spec 030:** FR-16 (gobernanza), FR-19 (whitelist contextual), FR-08 (resolución task→agente)
- **Skill `ssh-operations`:** procedimiento SSH reutilizable
- **Art. X de la constitution:** expansión del Implementador en kit por `proyecto_tipo`
- **Tabla FR-04:** whitelist efectiva por `(tier, proyecto_tipo)`

---
*Esta entidad fue reclasificada de "agente par" a "capa de gobernanza" el 2026-10-29. Su frontmatter mantiene `tier: Documental` pero con marca `categories: [gobernanza]`. El procedimiento SSH y de specs fue migrado a skills dedicadas (FR-12). Política conservada tal como definió el usuario.*