# 🧠 Memoria del Proyecto - Agents_IA_TECH

> **Registro de capacidades instaladas en ESTE proyecto.**
> Mantenido por el agente `plataformador`. Se actualiza en cada auditoria/nivelacion.

**Proyecto**: Agents_IA_TECH  
**Última auditoría**: 2026-08-30  
**Kit de agentes versión**: 1.1.0

---

## Capacidades instaladas

| Categoría | Capacidad | Versión | Estado | Última actualización |
|-----------|-----------|:-------:|:------:|:--------------------:|
| Agente | `pensador` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `arquitecto` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `documentador` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `security-auditor` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `api-developer` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `frontend-developer` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `devops` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `qa-senior` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `gitflow` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `solucionador` | 1.0 | ✅ Instalado | 2026-08-30 |
| Agente | `plataformador` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `00-indice.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `idioma.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `preferencias.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `preferencias-git.md` | 1.0 | ✅ Instalado | 2026-07-25 |
| Documentación | `roadmap.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `soluciones-conocidas.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `pendientes-implementacion.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `referencias.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `capacidad-base.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `memoria-proyecto.md` | 1.1 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/pensador/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/arquitecto/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/documentador/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/security-auditor/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/api-developer/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/frontend-developer/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/devops/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/qa-senior/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/gitflow/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/solucionador/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| Documentación | `agents/plataformador/spec.md` | 1.0 | ✅ Instalado | 2026-08-30 |
| MCP | `codebase-memory-mcp` | - | ❌ Pendiente | - |
| Kit Transversal | `.github/` | 1.1 | ✅ Sincronizado | 2026-08-30 |
| Kit Transversal | `.opencode/` | 1.1 | ✅ Sincronizado | 2026-08-30 |
| Kit Transversal | `.doc_agents/` | 1.1 | ✅ Sincronizado | 2026-08-30 |
| Kit Transversal | `.specify/memory/constitution.md` | base | ✅ Instalado | 2026-08-30 |

---

## Diferencias detectadas vs capacidad-base (.doc_agents/)

| Archivo/Carpeta | Esperado | Actual | Acción requerida |
|-----------------|----------|--------|------------------|
| `Documentacion/Agents_IA_TECH/specs/` | Existe | ✅ Creada | OK |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/` | Existe | ✅ Creada | OK |
| `Documentacion/Agents_IA_TECH/arquitectura/diagramas/` | Existe | ✅ Creada | OK |
| `Documentacion/Agents_IA_TECH/bitacoras/` | Existe | ✅ Creada | OK |
| `Documentacion/Agents_IA_TECH/agents/plataformador/capacidad-base.md` | Existe | ❌ Falta | Copiar desde `.doc_agents/capacidad-base.md` |
| `Documentacion/Agents_IA_TECH/agents/plataformador/memoria-proyecto.md` | Existe | ❌ Falta | Copiar este archivo allí también |
| MCP `codebase-memory-mcp` | Instalado | ❌ No | `npm install -g codebase-memory-mcp` y configurar agentes |

---

## Próximos pasos sugeridos (para plataformador)

1. Copiar `.doc_agents/capacidad-base.md` → `Documentacion/Agents_IA_TECH/agents/plataformador/capacidad-base.md`
2. Copiar este archivo → `Documentacion/Agents_IA_TECH/agents/plataformador/memoria-proyecto.md`
3. Instalar y configurar `codebase-memory-mcp` para agentes
4. Definir integración explícita Pensador ↔ Specify skills
5. Implementar sistema de persistencia de sesiones en disco

---

## Historial de auditorías

| Fecha | Versión kit | Resultado | Acciones tomadas |
|-------|-------------|-----------|------------------|
| 2026-07-25 | 1.0.0 | Auditoría inicial | Creación capacidades base |
| 2026-08-30 | 1.1.0 | Reestructuración completa | Movido a Documentacion/Agents_IA_TECH/, análisis Specify vs Agentes, nueva estructura |