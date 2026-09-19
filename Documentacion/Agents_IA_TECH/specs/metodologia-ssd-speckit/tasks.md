# Tasks: [SSD-SPECKIT-INTEGRACION]

**Versión**: 1.0
**Fecha**: 2026-09-19
**Estado**: Borrador
**Basado en**: spec.md v1.0, plan.md v1.0

---

## Convenciones

- **T-D\<N\>**: Task Documental (Fase 1)
- **T-I\<N\>**: Task Implementación (Fase 2)
- **T-V\<N\>**: Task Validación (Fase 3)
- **Prioridad**: P0 (bloqueante), P1 (crítico), P2 (importante), P3 (nice-to-have)
- **Estimación**: en horas ideales (1h = 1 hora foco sin interrupciones)

---

## Fase 1: Documental

### T-D1: Crear spec.md / plan.md / tasks.md ✅
- **Prioridad**: P0
- **Estimación**: 3h
- **Agente**: documentador
- **Descripción**: Crear los 3 archivos base en `Documentacion/Agents_IA_TECH/specs/metodologia-ssd-speckit/` siguiendo estructura definida en spec.md (RF-01 a RF-13, AC-01 a AC-10)
- **Pasos**:
  1. Crear directorio `specs/metodologia-ssd-speckit/`
  2. Escribir spec.md con Objetivo, 13 RFs, 10+ ACs, Fuera de alcance, Dependencias, Referencias
  3. Escribir plan.md con 3 fases, cronograma, riesgos, DoD
  4. Escribir tasks.md (este archivo) con todas las tasks desglosadas
  5. Verificar Constitution check PASS sobre spec.md
- **Criterio Done**: 3 archivos creados, formato consistente, Constitution check PASS
- **Dependencias**: Ninguna
- **Artefactos**: spec.md, plan.md, tasks.md

### T-D2: Crear seguridad/metodologia-ssd.md
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: security-auditor
- **Descripción**: Documentar threat model (STRIDE), riesgos de seguridad por fase Speckit, validación Art.V (Security) de constitution
- **Pasos**:
  1. Analizar 6 fases Speckit para identificar superficies de ataque
  2. Aplicar STRIDE por fase (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)
  3. Definir etiqueta `security-risk:` para tasks.md
  4. Mapear mitigaciones a Art.V constitution
  5. Guardar en `Documentacion/Agents_IA_TECH/seguridad/metodologia-ssd.md`
- **Criterio Done**: Threat model completo, riesgos etiquetados, Art.V cubierto
- **Dependencias**: T-D1 (spec.md debe existir)
- **Artefactos**: seguridad/metodologia-ssd.md

---

## Fase 2: Implementación DevOps

### T-I1: Actualizar pensador.agent.md
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: devops
- **Archivos**: `.github/agents/pensador.agent.md`, `.opencode/agents/pensador.md`
- **Cambios requeridos**:
  - Añadir skills: `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-converge`, `speckit-implement`
  - Añadir sección "Constitution Check": paso obligatorio antes de CUALQUIER speckit-*
  - Añadir sección "Pipeline Orquestado": orden estricto specify→plan→tasks→analyze→converge→implement
  - Añadir sección "Contexto Previo MCPs/Graphify": consultas obligatorias a codebase-memory, graphify, context-mode, markitdown ANTES de cada fase
  - Añadir sección "Delegación Explícita": matriz fase → agente(s) delegado(s)
  - Actualizar frontmatter: version, skills, mcp_servers
- **Criterio Done**: Ambos archivos idénticos en skills/estructura, Constitution check documentado, delegación clara
- **Dependencias**: T-D1, T-D2
- **Validación**: `grep -c "speckit-" <archivo>` = 6 skills

### T-I2: Actualizar arquitecto.agent.md
- **Prioridad**: P0
- **Estimación**: 1.5h
- **Agente**: devops
- **Archivos**: `.github/agents/arquitecto.agent.md`, `.opencode/agents/arquitecto.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-analyze`
  - Añadir sección "ADR Management": creación/actualización ADRs en `Documentacion/<app>/specs/adr/`
  - Añadir sección "Guardrails": patrones, límites, dependencias permitidas
  - Añadir sección "Spec Linking": traceabilidad bidireccional spec.md↔plan.md↔tasks.md↔ADRs
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, 3 secciones nuevas, frontmatter actualizado
- **Dependencias**: T-I1

### T-I3: Actualizar documentador.agent.md
- **Prioridad**: P0
- **Estimación**: 1.5h
- **Agente**: devops
- **Archivos**: `.github/agents/documentador.agent.md`, `.opencode/agents/documentador.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-converge`
  - Añadir sección "Flujos y Templates": generación/actualización en `Documentacion/<app>/specs/`
  - Añadir sección "Versionado": semver en cabecera de cada artefacto
  - Añadir sección "00-indice.md": actualización automática en converge
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, 3 secciones nuevas, frontmatter actualizado
- **Dependencias**: T-I1

### T-I4: Actualizar security-auditor.agent.md
- **Prioridad**: P0
- **Estimación**: 1.5h
- **Agente**: devops
- **Archivos**: `.github/agents/security-auditor.agent.md`, `.opencode/agents/security-auditor.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-analyze`
  - Añadir sección "Threat Model": STRIDE por feature en fase analyze
  - Añadir sección "Security-Risk Tags": etiquetado `security-risk:` en tasks.md
  - Añadir sección "Art.V Validation": checklist Constitution Art.V
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, 3 secciones nuevas, frontmatter actualizado
- **Dependencias**: T-I1, T-D2

### T-I5: Actualizar api-developer.agent.md
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/api-developer.agent.md`, `.opencode/agents/api-developer.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-implement`
  - Añadir sección "Expertise": backend, APIs, DB, auth, migraciones
  - Añadir sección "Trigger": tasks.md con etiqueta `domain: backend` o `domain: api`
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, expertise y trigger documentados
- **Dependencias**: T-I1

### T-I6: Actualizar frontend-developer.agent.md
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/frontend-developer.agent.md`, `.opencode/agents/frontend-developer.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-implement`
  - Añadir sección "Expertise": UI, state management, componentes, accesibilidad (WCAG)
  - Añadir sección "Trigger": tasks.md con etiqueta `domain: frontend` o `domain: ui`
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, expertise y trigger documentados
- **Dependencias**: T-I1

### T-I7: Actualizar devops.agent.md (agente implementador)
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/devops.agent.md`, `.opencode/agents/devops.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-implement`
  - Añadir sección "Expertise": CI/CD, infraestructura, contenedores, observabilidad
  - Añadir sección "Trigger": tasks.md con etiqueta `domain: devops` o `domain: infra`
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, expertise y trigger documentados
- **Dependencias**: T-I1

### T-I8: Actualizar qa-senior.agent.md (agente implementador)
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/qa-senior.agent.md`, `.opencode/agents/qa-senior.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-implement`
  - Añadir sección "Expertise": testing (unit/integration/e2e), quality gates, contract testing
  - Añadir sección "Trigger": tasks.md con etiqueta `domain: qa` o `domain: test`
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, expertise y trigger documentados
- **Dependencias**: T-I1

### T-I9: Actualizar gitflow.agent.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/gitflow.agent.md`, `.opencode/agents/gitflow.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-implement` (para branching/PR) + `speckit-converge` (para merge)
  - Añadir sección "Triggers":
    - `speckit-implement`: crear branch `feature/<task-id>`, abrir PR
    - `speckit-converge`: merge a main, tag semver, changelog
  - Actualizar frontmatter
- **Criterio Done**: Skills declaradas, triggers documentados
- **Dependencias**: T-I1, T-I3

### T-I10: Actualizar plataformador.agent.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/plataformador.agent.md`, `.opencode/agents/plataformador.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-analyze` (para diagnóstico)
  - Añadir sección "Triggers":
    - Nivelación de proyectos (sync-agents, constitution drift)
    - Diagnóstico remoto (health checks, codebase-memory)
  - Actualizar frontmatter
- **Criterio Done**: Skill declarada, triggers documentados
- **Dependencias**: T-I1

### T-I11: Actualizar upgrade_framework.agent.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/upgrade_framework.agent.md`, `.opencode/agents/upgrade_framework.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-plan` (para plan de migración) + `speckit-implement` (para ejecutar)
  - Añadir sección "Triggers":
    - Detección versión framework obsoleta (codebase-memory)
    - Plan de migración en tasks.md con etiqueta `domain: upgrade`
  - Actualizar frontmatter
- **Criterio Done**: Skills declaradas, triggers documentados
- **Dependencias**: T-I1

### T-I12: Actualizar analista_tecnico.agent.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/analista_tecnico.agent.md`, `.opencode/agents/analista_tecnico.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-specify` (para investigación) + `speckit-analyze` (para POCs)
  - Añadir sección "Triggers":
    - Investigación técnica previa a specify
    - POCs y evaluación librerías (markitdown para docs externos)
  - Actualizar frontmatter
- **Criterio Done**: Skills declaradas, triggers documentados
- **Dependencias**: T-I1

### T-I13: Actualizar solucionador.agent.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivos**: `.github/agents/solucionador.agent.md`, `.opencode/agents/solucionador.md`
- **Cambios requeridos**:
  - Añadir skill: `speckit-analyze` (root cause) + `speckit-implement` (hotfix)
  - Añadir sección "Triggers":
    - Incidentes producción → analyze para RCA
    - Hotfixes → implement con fast-track (skip converge si crítico)
  - Actualizar frontmatter
- **Criterio Done**: Skills declaradas, triggers documentados, fast-track documentado
- **Dependencias**: T-I1

### T-I14: Actualizar 00-indice.md
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: devops
- **Archivo**: `Documentacion/Agents_IA_TECH/specs/00-indice.md`
- **Cambios requeridos**:
  - Sección "Flujo Unificado SSD+Speckit": diagrama mermaid phases + agentes
  - Tabla "Agentes / Skills Speckit / Fase Pipeline": 13 filas x 4 columnas
  - Sección "Rutas por App": `src/<app>/` + `Documentacion/<app>/specs/`
  - Enlace a `MCPs/graphify.md`
  - Versionado semver en cabecera
- **Criterio Done**: Tabla completa 13 agentes, rutas documentadas, enlaces válidos
- **Dependencias**: T-I1 a T-I13

### T-I15: Crear MCPs/graphify.md
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: devops
- **Archivo**: `Documentacion/Agents_IA_TECH/specs/MCPs/graphify.md`
- **Contenido requerido**:
  - "Cómo consultar Graphify antes de cada fase Speckit": pasos exactos
  - "God Nodes relevantes": lista con qualified_name y descripción
  - "Communities detectadas": clusters de Leiden con labels
  - "Queries de ejemplo para contexto previo":
    - Pre-specify: arquitectura general, entry points
    - Pre-plan: dependencias, clusters afectados
    - Pre-tasks: callers/callees, hotspots
    - Pre-analyze: ADRs existentes, guardrails
    - Pre-converge: docs existentes, templates
    - Pre-implement: tests existentes, patrones código
  - Comandos `graphify` y `codebase-memory-mcp_search_graph` de ejemplo
- **Criterio Done**: Queries ejecutables, god nodes documentados, communities listadas
- **Dependencias**: T-I1 (pensador debe saber consultar)

### T-I16: Implementar Constitution Wizard en pensador.agent.md
- **Prioridad**: P0
- **Estimación**: 3h
- **Agente**: devops
- **Archivos**: `.github/agents/pensador.agent.md`, `.opencode/agents/pensador.md`
- **Cambios requeridos**:
  - Añadir sección "Constitution Wizard": wizard interactivo 11 pasos (ver RF-14)
  - Paso 1: Tipo proyecto (Nuevo / Existente a migrar)
  - Paso 2: Objetivo solución (qué hace, problema, usuarios)
  - Paso 3: Arquitectura objetivo (# componentes, monolito/microservicios, límites)
  - Paso 4: Stack tecnológico (lenguaje, framework, runtime)
  - Paso 5: Metodología (confirmar SSD+Speckit+TDD+Clean Architecture o elegida)
  - Paso 6: Base de datos (tipo, engine, migraciones, multi-tenancy)
  - Paso 7: Despliegue (Docker/K8s/serverless/bare-metal, CI/CD, entornos)
  - Paso 8: Estructura carpetas (estándar src/<app>/ + Documentacion/<app>/ o custom)
  - Paso 9: Artículos Constitution (**6 artículos (I–VI, con VI=proyect_ext)**) — preguntas por artículo con ejemplos
  - Paso 10: Guardrails adicionales (naming, security, observability, etc.)
  - Paso 11: Resumen + confirmación → escribe constitution.md
  - Modo "revisar y actualizar": si constitution.md existe, recorre sección por sección
  - Validación: salida = constitution.md con **6 artículos (I–VI, con VI=proyect_ext)**
- **Criterio Done**: Wizard funcional end-to-end, produce constitution.md válida, modo revisar funciona
- **Dependencias**: T-I1 (pensador base actualizado)

### T-I17: Actualizar 00-indice.md con Constitution Wizard
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: devops
- **Archivo**: `Documentacion/Agents_IA_TECH/specs/00-indice.md`
- **Cambios requeridos**:
  - Añadir entrada "Constitution Wizard" en tabla de features
  - Documentar 11 pasos del wizard
  - Enlazar a RF-14 en spec.md
- **Criterio Done**: Wizard documentado en índice, enlace a spec.md
- **Dependencias**: T-I16

### T-V8: Test Constitution Wizard
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: qa-senior
- **Descripción**: Verificar Constitution Wizard funcional
- **Pasos**:
   1. Ejecutar wizard en proyecto nuevo (sin constitution.md) → completar 11 pasos → verificar constitution.md generada con **6 artículos (I–VI, con VI=proyect_ext)**
   2. Ejecutar wizard en proyecto con constitution.md existente → modo "revisar y actualizar" → modificar Art.VI (proyect_ext) → verificar cambio persistido
  3. Verificar que constitution.md generada pasa Constitution Check (RF-01)
  4. Verificar que wizard pregunta por cada artículo con ejemplos claros
  5. Verificar que guardrails adicionales se añaden como sección extra
- **Criterio Done**: 5 casos cubiertos, constitution.md válida en todos, 0 regresiones
- **Dependencias**: T-I16, T-V1

---

---

## Fase 3: Validación QA-Senior

### T-V1: Test Constitution Check
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: qa-senior
- **Descripción**: Verificar que `speckit-specify` falla si `.specify/memory/constitution.md` ausente o inválido (falta Art.VI project_ext)
- **Pasos**:
  1. Backup constitution.md
  2. Eliminar constitution.md → ejecutar `speckit-specify` → verificar error claro
  3. Restaurar constitution.md sin Art.VI → ejecutar → verificar error Art.VI
  4. Restaurar completo → ejecutar → verificar PASS
- **Criterio Done**: 3 casos cubiertos, 0 falsos positivos/negativos
- **Dependencias**: Fase 2 completa

### T-V2: Test Pipeline End-to-End
- **Prioridad**: P0
- **Estimación**: 3h
- **Agente**: qa-senior
- **Descripción**: Ejecutar pipeline completo en feature de prueba mínima
- **Pasos**:
  1. `pensador` ejecuta `speckit-specify` → spec.md generado
  2. `pensador` ejecuta `speckit-plan` → plan.md generado
  3. `pensador` ejecuta `speckit-tasks` → tasks.md generado
  4. `pensador` ejecuta `speckit-analyze` → delega a arquitecto + security → analyze.md
  5. `pensador` ejecuta `speckit-converge` → delega a documentador → converge.md
  6. `pensador` ejecuta `speckit-implement` → delega a implementador → código en `src/<app>/`
  7. Verificar artefactos en `Documentacion/<app>/specs/`
- **Criterio Done**: 6 fases completadas, artefactos en rutas correctas, 0 errores
- **Dependencias**: T-V1

### T-V3: Test Agentes Complementan (No Duplican)
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: qa-senior
- **Descripción**: Auditoría de invocaciones Speckit vs skills declaradas
- **Pasos**:
  1. Para cada uno de los 13 agentes: `grep "speckit-" .github/agents/<name>.agent.md`
  2. Verificar que cada agente solo tiene skills de su rol (tabla plan.md Fase 2)
  3. Verificar que NO hay skills duplicadas entre agentes del mismo tier
  4. Verificar que `pensador` tiene las 6 skills (orquesta todo)
- **Criterio Done**: Matriz skills/agente = plan.md, 0 duplicaciones, 0 skills faltantes
- **Dependencias**: Fase 2 completa

### T-V4: Test Contexto Previo MCPs/Graphify
- **Prioridad**: P0
- **Estimación**: 2h
- **Agente**: qa-senior
- **Descripción**: Verificar que `pensador` consulta MCPs/Graphify/codebase-memory ANTES de cada fase
- **Pasos**:
  1. Ejecutar pipeline T-V2 con logging habilitado
  2. Capturar logs de `pensador` (stdout/stderr o archivo log)
  3. Verificar secuencia por fase:
     - Pre-specify: `codebase-memory-mcp_get_architecture`, `graphify` query, `ctx_search`
     - Pre-plan: `codebase-memory-mcp_search_graph` (dependencias), `ctx_search`
     - Pre-tasks: `codebase-memory-mcp_trace_path` (callers), `graphify` query
     - Pre-analyze: `codebase-memory-mcp_query_graph` (ADRs), `ctx_search`
     - Pre-converge: `ctx_search` (docs/templates), `graphify` query
     - Pre-implement: `codebase-memory-mcp_search_code` (tests/patrones), `ctx_search`
- **Criterio Done**: 6 fases x ≥1 consulta MCP/Graphify = ≥6 consultas logueadas en orden
- **Dependencias**: T-V2

### T-V5: Test Rutas por App
- **Prioridad**: P0
- **Estimación**: 1h
- **Agente**: qa-senior
- **Descripción**: Verificar separación estricta src/ vs Documentacion/
- **Pasos**:
  1. Ejecutar `find Documentacion/Agents_IA_TECH/specs -name "*.md" | grep -v "00-indice.md" | grep -v "graphify.md"`
  2. Verificar que TODOS los spec/plan/tasks/analyze/converge están en `Documentacion/<AppName>/specs/`
  3. Ejecutar `find src -name "*.md"` → debe estar vacío (solo código)
  4. Verificar que `sync-agents.ps1 -DryRun` NO lista archivos en `Documentacion/Agents_IA_TECH/`
- **Criterio Done**: 0 specs en src/, 0 código en Documentacion/, sync limpio
- **Dependencias**: Fase 2 completa

### T-V6: Test 00-indice.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: qa-senior
- **Descripción**: Validar 00-indice.md completo y funcional
- **Pasos**:
  1. Verificar existencia de tabla 13 agentes x 4 columnas (Agente, Skill Speckit, Fase Pipeline, Trigger)
  2. Verificar enlaces internos (spec.md, plan.md, tasks.md, graphify.md, seguridad/metodologia-ssd.md)
  3. Verificar versionado semver en cabecera
  4. Verificar sección "Flujo Unificado" con diagrama mermaid renderizable
- **Criterio Done**: Tabla completa, 0 enlaces rotos, versión presente, mermaid válido
- **Dependencias**: T-I14

### T-V7: Test graphify.md
- **Prioridad**: P1
- **Estimación**: 1h
- **Agente**: qa-senior
- **Descripción**: Validar graphify.md usable
- **Pasos**:
  1. Ejecutar cada query de ejemplo en `codebase-memory-mcp_search_graph` o `graphify`
  2. Verificar que devuelven resultados (no vacíos)
  3. Verificar god nodes listados existen en grafo
  4. Verificar communities coinciden con `codebase-memory-mcp_get_architecture` clusters
- **Criterio Done**: ≥6 queries ejecutables, god nodes válidos, communities consistentes
- **Dependencias**: T-I15

---

## Resumen de Tasks

| ID | Fase | Agente | Prioridad | Estimación | Dependencias |
|----|------|--------|-----------|------------|--------------|
| T-D1 | 1 | documentador | P0 | 3h | - |
| T-D2 | 1 | security-auditor | P0 | 2h | T-D1 |
| T-I1 | 2 | devops | P0 | 2h | T-D1, T-D2 |
| T-I2 | 2 | devops | P0 | 1.5h | T-I1 |
| T-I3 | 2 | devops | P0 | 1.5h | T-I1 |
| T-I4 | 2 | devops | P0 | 1.5h | T-I1, T-D2 |
| T-I5 | 2 | devops | P0 | 1h | T-I1 |
| T-I6 | 2 | devops | P0 | 1h | T-I1 |
| T-I7 | 2 | devops | P0 | 1h | T-I1 |
| T-I8 | 2 | devops | P0 | 1h | T-I1 |
| T-I9 | 2 | devops | P1 | 1h | T-I1, T-I3 |
| T-I10 | 2 | devops | P1 | 1h | T-I1 |
| T-I11 | 2 | devops | P1 | 1h | T-I1 |
| T-I12 | 2 | devops | P1 | 1h | T-I1 |
| T-I13 | 2 | devops | P1 | 1h | T-I1 |
| T-I14 | 2 | devops | P0 | 2h | T-I1..T-I13 |
| T-I15 | 2 | devops | P0 | 2h | T-I1 |
| T-I16 | 2 | devops | P0 | 3h | T-I1 |
| T-I17 | 2 | devops | P1 | 1h | T-I16 |
| T-V1 | 3 | qa-senior | P0 | 1h | Fase 2 |
| T-V2 | 3 | qa-senior | P0 | 3h | T-V1 |
| T-V3 | 3 | qa-senior | P0 | 2h | Fase 2 |
| T-V4 | 3 | qa-senior | P0 | 2h | T-V2 |
| T-V5 | 3 | qa-senior | P0 | 1h | Fase 2 |
| T-V6 | 3 | qa-senior | P1 | 1h | T-I14 |
| T-V7 | 3 | qa-senior | P1 | 1h | T-I15 |
| T-V8 | 3 | qa-senior | P0 | 2h | T-I16, T-V1 |

**Total estimado**: ~36.5h ideales

---

## Orden de Ejecución Recomendado

```
T-D1 → T-D2
    → T-I1 → T-I2, T-I3, T-I4, T-I5, T-I6, T-I7, T-I8 (paralelo)
           → T-I9, T-I10, T-I11, T-I12, T-I13 (paralelo, tras T-I1,T-I3)
           → T-I14, T-I15, T-I16 (tras todos T-I*)
           → T-I17 (tras T-I16)
    → T-V1 → T-V2 → T-V4
         → T-V3, T-V5 (paralelo, tras Fase 2)
         → T-V6, T-V7 (paralelo, tras T-I14, T-I15)
         → T-V8 (tras T-I16, T-V1)
```

---

## Notas de Implementación

- **Paralelismo**: Tasks marcadas "paralelo" pueden ejecutarse concurrentemente por devops
- **Sync**: Tras cada task T-I*, ejecutar `.\sync-agents.ps1 -DryRun` para verificar
- **Commits**: Un commit por task (conventional: `feat(agent): add speckit skills to <name>`)
- **Constitution**: Verificar check PASS tras cada modificación a .agent.md