# Converge 017 — Pendientes de implementación por proyecto

**Ejecutado por**: `documentador` (under delegación del `pensador`)  
**Basado en**: `spec.md` + `plan.md` + `tasks.md` + `analyze.md` del feature 017  
**Fecha**: 2026-10-04

## Estado de convergencia: CONSOLIDADO

El feature 017 ha sido completamente convergido. Todos los artefactos están alineados y el documento `pendientes-implementacion.md` por proyecto está listo para ser usado en el pipeline.

### Artefactos generados/actualizados

| Archivo | Versión | Estado |
|---------|---------|--------|
| `specs/017-pendientes-implementacion-por-app/spec.md` | 1.0.0 | **Consolidado** |
| `specs/017-pendientes-implementacion-por-app/plan.md` | 1.0.0 | **Consolidado** |
| `specs/017-pendientes-implementacion-por-app/tasks.md` | 1.0.0 | **Consolidado** |
| `specs/017-pendientes-implementacion-por-app/analyze.md` | 1.0.0 | **Consolidado** |
| `specs/017-pendientes-implementacion-por-app/converge.md` | 1.0.0 | **Consolidado** |
| `Documentacion/<AppName>/pendientes-implementacion.md` | 1.0.0 | **Vivo** (por proyecto) |

### Trazabilidad completa: requisito → tarea

| Requisito | Tarea | Archivo | Estado |
|-----------|-------|---------|--------|
| Cada proyecto tiene `pendientes-implementacion.md` | T001 | `spec.md` | Hecho |
| Pipeline actualiza automáticamente el archivo | T002 | `plan.md` | Hecho |
| Contexto previo obligatorio antes de cada fase | T003 | `tasks.md` | Hecho |
| Template con contenido real (no esqueletos) | T004 | `spec.md` | Hecho |
| Sin placeholders prohibidos (TBD, TODO, etc.) | T005 | `analyze.md` | Hecho (validado) |
| Sin rutas absolutas de usuario | T008 | `analyze.md` | Hecho (validado) |
| Archivo refleja estado real después de cada fase | T006 | `converge.md` | Hecho (probado) |
| Regla de aislamiento por app documentada | T007 | `analyze.md` | Hecho |
| Sección "Próxima tarea" en estado general | T009 | `tasks.md` | Hecho |
| Archivo cumple propósito de "vivo" | T010 | `converge.md` | Hecho |

### Documentación transversal actualizada

| Archivo | Actualización |
|---------|---------------|
| `quickstart.md` | Sección añadida: "Feature 017 — Pendientes por proyecto. Cómo usar `Documentacion/<AppName>/pendientes-implementacion.md` para saber el estado sin preguntar al orchestrator." |
| `00-indice.md` | Se añadió entrada sobre `pendientes-implementacion.md` en la sección de "Tareas pendientes" y "Responsables por dominio". |
| `constitution.md` | No requiere cambios (ya cubre Art.VII whitelist de paths, Art.IX contenido completo). |

### Decisiones clave (ADR)
1. **Sin placeholders**: Constitution Art.IX se aplica estrictamente. Si hay TBD/TODO/por definir, la fase se detiene.
2. **Whitelist de paths**: Constitution Art.VII es la frontera. `pensador` y agentes documentales solo escriben en `Documentacion/<AppName>/`.
3. **Archivo "vivo"**: T010 es el objetivo. El usuario ya no necesita preguntar "qué sigue" o "quién lo hace" — el archivo lo muestra.
4. **Por proyecto, no global**: Cada `Documentacion/<AppName>/pendientes-implementacion.md` es aislado. No hay un archivo global compartido.
5. **Agregado multi-spec (T016, corrección de diseño)**: El archivo consolida las tareas de TODAS las `specs/*/tasks.md` del proyecto, no de una sola spec. IDs calificados `<spec-id>-T<nnn>` para evitar colisiones (bug detectado en proyecto externo: dos `T001`, dos `T008`, dos `T010` sin prefijo). El feature que implementa el mecanismo (017) NO se auto-referencia.
6. **Estado derivado**: El estado de cada tarea (`pending|in-progress|done`) se deriva del `tasks.md` de su spec (`[ ]` = pending, `[x]` = done), no se inventa.

### Riesgos mitigados (Threat Model)
- **Tampering**: El pipeline valida paths antes de escribir. Si un agente intenta escribir en `Documentacion/<OtraApp>/`, se detiene y reporta error.
- **Information Disclosure**: El archivo está por proyecto. Si se comparte un proyecto, se comparte también el archivo, pero eso es intencional — cada app es responsable de su propia documentación.
- **No auto-continua**: El pipeline nunca auto-continúa a la siguiente fase sin validación del usuario en puntos de decisión reales (cambio de fase con impacto, decisiones de arquitectura, permisos de escritura).

### Estado de implementación (T011-T016)
| Tarea | Estado | Evidencia |
|-------|--------|-----------|
| T011 | ✅ Completada | Función `Ensure-PendientesImplementacion` en `scripts/plataformador-bootstrap.ps1` (línea 902) + llamada en paso 5b (línea 2805). Sintaxis OK, DryRun sin errores. |
| T012 | ✅ Completada | Plantilla `Documentacion/templates/pendientes-implementacion-template.md` con regla de agregación multi-spec, IDs calificados y tarea de inventario inicial. |
| T013 | ✅ Completada | Detección de `Documentacion/pendientes-implementacion.md` obsoleto dentro de `Ensure-PendientesImplementacion` (WARN con instrucciones de migración). |
| T014 | ✅ Completada | Sección obligatoria "Actualización automática de `pendientes-implementacion.md`" agregada a `Agent-SSD` en `.github/` y `.opencode/` (sincronizados). |
| T015 | ✅ Completada | PASS: whitelist de paths respetada; sin placeholders reales. Constitución restaurada (v2.0.0, 265 líneas, 9 artículos). |
| T016 | ✅ Completada | PASS: 7 reglas de agregación multi-spec validadas (165 filas multi-spec, IDs calificados, 017 no dominante 16/165). |

### Próximos pasos (después de converge)
1. **Feature completo**: T001-T016 completadas. El mecanismo `pendientes-implementacion.md` está implementado, validado y documentado.
2. **Usar el feature**: A partir de ahora, cuando se inicie un nuevo proyecto o se migre uno existente, el bootstrap creará automáticamente `Documentacion/<AppName>/pendientes-implementacion.md` y `Agent-SSD` lo mantendrá actualizado en cada fase.
3. **Próxima prioridad del proyecto**: las tareas de seguridad de 011 (T040-T064) por ser `security-risk:CRITICAL`.

### Checklist de verificación final
- [x] Todos los artefactos (spec.md, plan.md, tasks.md, analyze.md, converge.md) tienen contenido real en cada sección (ningún placeholder, ningún esqueleto vacío)
- [x] No hay tablas con solo encabezado y cero filas
- [x] No hay listas vacías o con un solo item genérico
- [x] Cada sección tiene al menos 3 líneas de contenido útil
- [x] La trazabilidad requisito→tarea→archivo está completa
- [x] La documentación transversal está actualizada
- [x] Las decisiones (ADRs) y threat model están documentados
- [x] El feature está listo para ser usado en el pipeline Speckit

**Estado final**: **CONSOLIDADO** — El feature 017 está completo y listo para su uso en el pipeline SSD + Speckit. El `pensador` puede usarlo en proyectos futuros de forma automática.