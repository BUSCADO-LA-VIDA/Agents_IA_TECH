# Analyze 017 — Pendientes de implementación por proyecto

**Ejecutado por**: `arquitecto` + `security-auditor` (under delegación del `pensador`)  
**Basado en**: `spec.md` + `plan.md` + `tasks.md` del feature 017  
**Fecha**: 2026-10-04

## Análisis de consistencia cruzada

### Verificación de spec.md vs plan.md vs tasks.md
- **spec.md** define el feature: pendientes-implementacion.md por proyecto, contenido vivo, sin placeholders, whitelist de paths.
- **plan.md** define el plan: 10 tareas accionables, contexto previo obligatorio, validación en puntos de decisión, actualización automática después de cada fase.
- **tasks.md** define las tasks: T001-T010, todas con descripción, responsable, dependencias, done cuando criteria cumplido.

**Consistencia**: Todas coherentes. El spec define el "qué", el plan define el "cómo" y las tasks definen los pasos accionables. No hay contradicciones.

### Vinculación con Constitution (Artículos relevantes)
- **Art.I Library-First**: El feature 017 trata `pendientes-implementacion.md` como una "librería" de estado por proyecto — está disponible para todos los agentes que necesiten saber el estado.
- **Art.II CLI Interface**: El pipeline Speckit es la interfaz CLI para interactuar con el feature. Comandos: `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-converge`, `speckit-implement`.
- **Art.III Test-First (TDD)**: Las validaciones de placeholders (T005) y rutas absolutas (T008) son tests que se ejecutan en cada fase. Si fallan, la fase se detiene hasta corregirse.
- **Art.IV Simplicity**: El template es simple: 6 secciones obligatorias, ninguna opcional. Sin complejidad innecesaria.
- **Art.V Security**: Threat model considerado en T005 (placeholders pueden esconder bugs) y T008 (rutas absolutas pueden filtrar secrets). El archivo vive en `Documentacion/<AppName>/` — whitelist segura.
- **Art.VI project_ext**: Si el proyecto tiene `proyect_ext/` configurado, el template no toca esos archivos. El `pensador` solo escribe en `Documentacion/<AppName>/`.
- **Art.VII Simplicity (refuerzo)**: Máximo 3 proyectos activos por sesión (RF-07). El archivo por proyecto evita confusiones.
- **Art.VIII Anti-Abstraction**: Speckit commands son directos, no hay frameworks de abstracción interpuestos. El `pensador` delega en `Agent-SSD` para la ejecución, pero la lógica es directa.
- **Art.IX Integration-First**: El archivo `pendientes-implementacion.md` se integra con todas las fases del pipeline (se actualiza después de cada una). Los tests reales (qa-senior) validan que el archivo se actualiza correctamente.

### Hallazgos
1. **Contexto previo no documentado en la spec**: El spec.md menciona el contexto previo pero no lo tiene como una task explícita. **Recomendación**: Agregar T003 al tasks.md (ya hecho).
2. **Validación de placeholders es crítica**: Constitution Art.IX prohíbe placeholders. La validación T005 es el gate principal. Si no se cumple, no se continúa.
3. **Rutas absolutas son un riesgo de seguridad**: T008 aborda esto. Las rutas absolutas de usuario (`C:\Users\tomas\...`) no deben versionarse. Los comandos MCP usan tokens (`__CONTEXT_MODE_CMD__`).
4. **Aislamiento por app es nuevo**: No existía anteriormente (se perdió en la migración a Specs). Este feature 017 lo recupera.
5. **El archivo "vivo" es el objetivo principal**: T010 resume el propósito. El archivo debe responder "qué hay que hacer", "qué se está haciendo", "qué se terminó" y "quién lo hace" sin que el usuario pregunte.

### ADRs propuestos (Architecture Decision Records)
No se proponen nuevos ADRs para este feature, ya que las decisiones ya están documentadas en la constitution y el propio spec.md. Los ADRs relevantes ya existen:
- ADR-0005: Orquestación y delegación (pensador → Agent-SSD → implementadores)
- ADR-0007: Bootstrap delega upgrade_framework (converge completed)

### Threat Model STRIDE (análisis rápido)
| Amenaza | Clasificación | Comentario |
|---------|--------------|------------|
| **Spoofing** | LOW | El archivo es por proyecto, aislado. No hay autenticación, pero el aislamiento lo protege. |
| **Tampering** | MEDIUM | Si un agente documental escribe fuera de `Documentacion/<AppName>/`, viola Constitution VII. El pipeline debe detectarlo y detenerse. |
| **Repudiation** | LOW | Los eventos del pipeline se loguean en bitácoras (`Documentacion/<AppName>/bitacoras/`). |
| **Information Disclosure** | MEDIUM | El archivo contiene información del proyecto (tareas, responsables). Si `Documentacion/<AppName>/` se comparte públicamente, la información queda expuesta. El archivo está aislado por app. |
| **Denial of Service** | LOW | El pipeline se detiene si hay placeholders o rutas absolutas. No hay operaciones costosas sobre el archivo. |
| **Elevation of Privilege** | LOW | Los agentes documentales tienen whitelist restrictiva. No pueden elevar privilegios fuera de su tier. |

### Riesgos identificados y mitigaciones
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Un agente escribe `Documentacion/<OtraApp>/` | MEDIUM | ALTO (viola aislamiento) | Constitution Art.VII whitelist. El pipeline valida paths antes de escribir. |
| El archivo tiene placeholders TBD/TODO | ALTO | ALTO (constitution violation) | Validación T005 en cada fase. Si se detecta, pipeline se detiene. |
| Rutas absolutas en el template | MEDIUM | MEDIUM (security risk) | Validación T008. Si se detectan, se convierten a relativas o se usa tokens. |
| El archivo no se actualiza en una fase | MEDIUM | MEDIUM (pipeline bug) | T006 prueba el pipeline completo. Si falla, se reporta y se corrige. |
| Confusión entre proyectos (mismo `pendientes-implementacion.md`) | BAJO | ALTO (información mezclada) | Cada proyecto tiene su propio `Documentacion/<AppName>/pendientes-implementacion.md`. El `pensador` valida el `AppName` antes de escribir. |

### Recomendaciones para la implementación
1. **T005 (validación de placeholders)** es la tarea más crítica — debe aprobarse antes de continuar con el pipeline.
2. **T008 (rutas absolutas)** es el segundo más crítico — evita fugas de secrets.
3. **T003 (contexto previo obligatorio)** asegura que el pipeline siempre tenga contexto antes de ejecutar.
4. **T010 (archivo vivo)** es el objetivo final — el usuario deja de preguntar "qué sigue" y "quién lo hace".
5. Probar T006 (prueba completa del pipeline) en un proyecto de antes de hacer merge a main.

### Checklist de aprobación para pasar a Converge
- [ ] T001 completada: estructura de specs existe
- [ ] T002 completada: lógica de update automática en pipeline
- [ ] T003 completada: contexto previo obligatorio en cada fase
- [ ] T004 completada: template de pendientes-implementacion.md creado
- [ ] T005 completada: validación de placeholders prohibidos
- [ ] T006 por probar: pipeline completo en proyecto de prueba
- [ ] T007 completada: regla de aislamiento documentada
- [ ] T008 completada: sin rutas absolutas en template
- [ ] T009 completada: sección "Próxima tarea" en estado general
- [ ] T010 completada: archivo cumple su propósito de "vivo"

**Estado**: A la espera de aprobación del usuario para pasar a la fase de Converge.