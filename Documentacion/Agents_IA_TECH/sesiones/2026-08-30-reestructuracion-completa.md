# 📝 Sesiones Persistentes - Agents_IA_TECH

> **Base de conocimiento conceptual entre reinicios de VS Code.**
> El `pensador` guarda aquí análisis, planes, decisiones y resúmenes de cada sesión.
> Al iniciar nueva sesión, el Pensador **lee la última sesión** como base conceptual.
> **Antes de borrar/compactar**: el Pensador pregunta "¿Querés guardar esta propuesta?"

---

## Formato de entrada

```markdown
## <YYYY-MM-DD> <Título de la sesión>

**Contexto**: Qué se estaba haciendo
**Análisis**: Qué se analizó (arquitectura, specs, decisiones)
**Decisiones**: Qué se decidió (y por qué)
**Plan**: Qué se planeó hacer (pasos, agentes, orden)
**Estado**: Dónde quedó (completado, en progreso, bloqueado)
**Pendientes**: Qué queda por hacer
**Archivos clave**: Rutas a specs, ADRs, docs relevantes
```

---

## 2026-08-30 Reestructuración completa: Doc por app + Complementariedad Specify + Persistencia

**Contexto**: Usuario pidió corregir estructura de documentación (mover a `Documentacion/Agents_IA_TECH/`), recuperar análisis perdido de Specify vs Agentes, definir Pensador como orquestador que complementa Specify, y agregar persistencia de sesiones en disco.

**Análisis**:
- Documentación estaba en `Documentacion/` raíz (legacy) en lugar de `Documentacion/Agents_IA_TECH/` (por proyecto)
- Se perdió el análisis comparativo de capacidades Specify (speckit) vs Mis Agentes
- Pensador debe orquestar: Plan → Confirmar → Documentar (con Specify) → Implementar → Commit
- Specify maneja: spec generation, validation, spec→plan, spec→code, templates, versioning, linking, guardrails, orchestration, feedback loop
- Mis agentes complementan: SSH debugging (Pensador/Solucionador), Plataformador (auditoría/nivelación), Gitflow (commits), Cross-agent orchestration, Persistencia sesiones, Estructura doc por app
- Necesidad crítica: Persistir análisis/decisiones en disco para recuperar al reiniciar VS Code

**Decisiones**:
1. **Mover toda documentación a `Documentacion/Agents_IA_TECH/`** — nombre del proyecto
2. **Recuperar y documentar análisis Specify vs Agentes** en `referencias.md` (tabla complementariedad)
3. **Pensador = Orquestador principal** que invoca skills de speckit + mis agentes complementarios
4. **Plataformador = Organizador de documentación** (audita, nivelación, integra graphify)
5. **Crear `Documentacion/Agents_IA_TECH/sesiones/`** para persistencia entre reinicios
6. **Regla**: Antes de compactar/borrar → Preguntar "¿Querés guardar esta propuesta?"
7. **Ciclo obligatorio**: Plan aprobado → Documentar (Specify + mis agentes) → Implementar → Gitflow commit

**Plan ejecutado**:
1. ✅ Crear estructura `Documentacion/Agents_IA_TECH/` completa (specs, arquitectura, agents, bitacoras, sesiones)
2. ✅ Mover todos archivos base (00-indice, idioma, preferencias, referencias, roadmap, pendientes, soluciones, capacidad-base, memoria-proyecto)
3. ✅ Crear specs actualizados para todos los 11 agentes en `agents/<nombre>/spec.md`
4. ✅ Documentar complementariedad Specify vs Agentes en `referencias.md`
5. ✅ Actualizar `preferencias.md` con nuevas reglas (persistencia, ciclo obligatorio, orquestación)
6. ✅ Copiar capacidad-base y memoria-proyecto a `agents/plataformador/`
7. ✅ Crear directorio `sesiones/` para persistencia

**Estado**: Completado - Estructura base lista

**Pendientes** (en `pendientes-implementacion.md`):
- [ ] `[PERSISTENCIA]` Sistema de persistencia de sesiones en disco (Pensador guarda/lee `sesiones/`)
- [ ] `[SPECIFY]` Definir integración explícita Pensador ↔ Specify skills (qué skill cuándo)
- [ ] `[PLATAFORMADOR]` v2: Auditoría automática + reporte contra `.doc_agents/capacidad-base.md`
- [ ] `[MCP]` Configurar `codebase-memory-mcp` para agentes

**Archivos clave**:
- `Documentacion/Agents_IA_TECH/referencias.md` — Tabla complementariedad completa
- `Documentacion/Agents_IA_TECH/preferencias.md` — Reglas persistencia, ciclo, orquestación
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tareas priorizadas
- `Documentacion/Agents_IA_TECH/agents/pensador/spec.md` — Spec actualizada con integración Specify
- `Documentacion/Agents_IA_TECH/agents/plataformador/spec.md` — Spec actualizada con graphify + doc obligatoria