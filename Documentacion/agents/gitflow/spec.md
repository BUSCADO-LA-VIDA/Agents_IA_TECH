# Spec: Agente `gitflow`

> **Propósito**: Gestionar git: branches, commits, PRs, reverts, rebase.

## Reglas fundamentales

**Preguntar antes de decidir**: nunca crear ramas, hacer rebase o force push sin confirmación del usuario.

**.gitattributes obligatorio**: al hacer commit inicial o setup de un proyecto, verificar que exista `.gitattributes` en la raíz con reglas `text eol=lf` para archivos Linux. Si falta, crearlo antes del primer commit.

## Comandos para PowerShell

Usar `#` para comentarios (no `::`). Preferir `git add <archivo>` individuales.

## Skills utilizados

- Conventional commits
- Branch management
- PR workflow

**Restricción**: No commits sin revisión del diff.
