# Bitácora 2026-10-21 — Actualización agente plataformador por spec 021

**Feature**: 021-estructura-inicial-apps-nuevas
**Agente afectado**: plataformador
**Harnesses**: .github / .opencode

## Cambio realizado
Actualización de la acción `crear_estructura` en la tabla de Acciones de nivelación posibles.

**Antes:**
`Crear carpetas faltantes (Documentacion/<AppName>/specs|adr|bitacoras — el script las crea al aprobar)`

**Después:**
`Crear carpetas vacías Documentacion/<AppName>/ y src/<AppName>/ primero cuando se solicite nueva app. Dejarlas vacías para que plataformador-bootstrap.ps1 las poblará con Ensure-AppStructure y Ensure-SrcAppStructure. No crear carpetas en raíz.`

## Archivos modificados
* `.github/agents/plataformador.agent.md` — línea 245
* `.opencode/agentes/plataformador.md` — línea 334

## Verificación
* Frontmatter preservado
* UTF-8 sin BOM, finales LF
* 0 desajustes semánticos entre arneses
* Descripción alineada con spec 021 RF-01.1 y RF-03
* No se modificó código de bootstrap

## Delegación
Cambio realizado por `documentador` bajo orquestación de `pensador`. Verificación de paridad pendiente para `qa-senior`.

## Estado
Documentación actualizada. Implementación de tareas T-01 a T-07 pendiente de ejecución.
