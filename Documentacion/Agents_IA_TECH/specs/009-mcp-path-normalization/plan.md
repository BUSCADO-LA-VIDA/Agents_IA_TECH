# Plan 009 - Normalización de rutas MCP a forward slashes

## Objetivo
Corregir InvalidEscapeCharacter en opencode.json normalizando rutas MCP a forward slashes.

## Fases
1. **Specify**: Spec creada
2. **Plan**: Este documento
3. **Tasks**: Generar tasks.md
4. **Analyze**: Revisar impacto en bootstrap
5. **Converge**: Documentar cambios
6. **Implement**: Modificar scripts/plataformador-bootstrap.ps1

## Cambios técnicos
- Normalizar rutas al resolver MCP
- Normalizar rutas tokenslayer/graphify
- Validar JSON tras escritura

## Archivos afectados
- scripts/plataformador-bootstrap.ps1
