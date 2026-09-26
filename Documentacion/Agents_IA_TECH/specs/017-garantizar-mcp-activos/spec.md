# Spec: Garantizar MCP activos de forma transparente

**Versión**: 1.0
**Fecha**: 2026-09-25

## Objetivo
Forzar el uso de MCPs en labores diarias de forma transparente, verificando disponibilidad y auto-indexando.

## User Stories
### US1 — Verificación de MCPs
Como usuario, quiero que el bootstrap verifique que MCPs requeridos estén disponibles.

### US2 — Auto-indexación
Como usuario, quiero que al iniciar se re-indexe context-mode, codebase-memory y graphify si el índice es viejo.

## Requisitos Funcionales
- FR-001: Listar MCPs requeridos: context-mode, codebase-memory-mcp, graphify, markitdown.
- FR-002: Verificar disponibilidad y emitir WARN si falta.
- FR-003: Si índice tiene >1 día, re-indexar automáticamente.
- FR-004: Registrar en log.

## Criterios de Aceptación
- SC-001: MCPs verificados al inicio.
- SC-002: Re-indexación automática funciona.
