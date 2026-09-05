# 🗺️ Roadmap - Agents_IA_TECH

> Backlog de evolutivos y mejoras futuras para el kit de agentes.
> El `pensador` y `plataformador` consultan este archivo para proponer siguiente pasos.

## Próximas mejoras (prioridad alta)

- [ ] **Persistencia de sesiones en disco**: Guardar análisis/planes/decisiones en `Documentacion/Agents_IA_TECH/sesiones/` para recuperarlas al reiniciar VS Code. El Pensador debe leer esto al inicio.
- [ ] **Integración Specify + Pensador completa**: Definir específicamente qué skills de speckit invoca Pensador y en qué orden.
- [ ] **Plataformador v2**: Auditoría automática contra `.doc_agents/capacidad-base.md` con reporte detallado y auto-nivelación opcional.
- [ ] **MCP codebase-memory-mcp**: Configurar agentes para usar grafo de conocimiento del código (index_repository, query, semantic_search).

## Mejoras medias

- [ ] **Sesiones con resumen automático**: Al compactar sesión, Pensador genera versión limpia del plan en `sesiones/YYYY-MM-DD-resumen.md`.
- [ ] **Bitácoras estructuradas**: Formato estándar para solucionador con búsqueda por tags.
- [ ] **Testing de agentes**: Tests automatizados para validar comportamiento de cada agente.
- [ ] **Documentación interactiva**: Diagramas Mermaid navegables en VS Code.

## Ideas futuras (baja prioridad)

- [ ] **Dashboard de estado del kit**: Visualización de qué capacidades están instaladas por proyecto.
- [ ] **Marketplace de skills**: Skills compartidas entre proyectos vía `.github/skills/`.
- [ ] **Integración con otros IDEs**: Cursor, Windsurf, etc.

## Completados

| Fecha | Item |
|-------|------|
| 2026-07-25 | Kit base de 11 agentes creado |
| 2026-07-27 | Estructura Documentacion/ reorganizada |
| 2026-08-05 | CI/CD: security-scan, spellcheck, .gitattributes |
| 2026-08-30 | Reestructuración: Pensador complementa Specify, doc por app, persistencia |