# Spec: [SSD-SPECKIT-INTEGRACION]

**Versión**: 1.0
**Fecha**: 2026-09-19
**Estado**: Borrador
**Autor**: documentador

---

## Objetivo

Integrar el uso diario transparente de **SSD (Spec-Driven Development)** + **Speckit** + **Graphify** + **MCPs** en el flujo de trabajo de **TODOS los 13 agentes** del kit `Agents_IA_TECH`, garantizando:

- Constitution FIRST: verificación obligatoria de `.specify/memory/constitution.md` (**6 artículos (I–VI, con VI=proyect_ext)**) ANTES de cualquier comando `speckit-*`
- Pipeline Speckit ordenado y estricto: `specify → plan → tasks → analyze → converge → implement`
- Cada agente **complementa** (no duplica) las capacidades de Speckit según su rol
- MCPs + Graphify + codebase-memory como **contexto previo obligatorio** antes de cada `speckit-*`
- Rutas de guardado por aplicación respetadas: `src/<app>/` (código) + `Documentacion/<app>/specs/` (spec/plan/tasks/ADRs)

---

## Requisitos Funcionales (RF)

### RF-01: Constitution Check Obligatorio
**Descripción**: Antes de ejecutar cualquier comando `speckit-*`, el agente `pensador` debe verificar que `.specify/memory/constitution.md` existe y pasa el check (**6 artículos (I–VI, con VI=proyect_ext)**).
**Criterio**: Si el check falla, el pipeline se detiene y se reporta el artículo violado.

### RF-02: Pipeline Speckit Ordenado
**Descripción**: El pipeline completo debe ejecutarse en orden estricto: `specify → plan → tasks → analyze → converge → implement`. No se puede saltar fases.
**Criterio**: Cada fase produce su artefacto correspondiente (`spec.md`, `plan.md`, `tasks.md`, `analyze.md`, `converge.md`, código implementado).

### RF-03: Agente Pensador — Orquestación Completa
**Descripción**: `pensador` orquesta el pipeline completo:
1. Consulta MCPs + Graphify + codebase-memory **antes** de cada `speckit-*`
2. Ejecuta `speckit-specify` → valida spec.md
3. Ejecuta `speckit-plan` → valida plan.md
4. Ejecuta `speckit-tasks` → valida tasks.md
5. Ejecuta `speckit-analyze` → delega a `arquitecto` + `security-auditor`
6. Ejecuta `speckit-converge` → delega a `documentador`
7. Ejecuta `speckit-implement` → delega a implementadores según expertise
**Criterio**: Pensador nunca implementa código; solo orquesta y valida.

### RF-04: Agente Arquitecto — ADRs, Guardrails, Spec Linking
**Descripción**: `arquitecto` complementa `speckit-analyze`:
- Crea/actualiza ADRs en `Documentacion/<app>/specs/adr/`
- Define guardrails arquitectónicos (patrones, límites, dependencias)
- Vincula spec.md ↔ plan.md ↔ tasks.md ↔ ADRs (traceabilidad bidireccional)
**Criterio**: Cada decisión arquitectónica queda registrada en ADR con enlace a tasks.md.

### RF-05: Agente Documentador — Flujos, Templates, Versionado
**Descripción**: `documentador` complementa `speckit-converge`:
- Genera/actualiza flujos de trabajo en `Documentacion/<app>/specs/`
- Mantiene templates de spec/plan/tasks/ADR
- Versiona artefactos (semver en cabecera de cada archivo)
**Criterio**: `speckit-converge` produce documentación consolidada lista para implementadores.

### RF-06: Agente Security-Auditor — Threat Model, Riesgos
**Descripción**: `security-auditor` complementa `speckit-analyze`:
- Genera threat model (STRIDE) por feature
- Identifica riesgos de seguridad en tasks.md (etiqueta `security-risk:`)
- Valida cumplimiento Art.V (Security) de constitution
**Criterio**: Cada task con riesgo de seguridad tiene mitigación documentada.

### RF-07: Agentes Implementadores (4) — Expertise sobre Tasks
**Descripción**: Los 4 implementadores ejecutan `speckit-implement` según su expertise:
- `api-developer`: backend, APIs, DB, auth
- `frontend-developer`: UI, state, componentes, accesibilidad
- `devops`: CI/CD, infra, containers, observabilidad
- `qa-senior`: tests, quality gates, contract testing
**Criterio**: Cada implementador solo toca tasks de su dominio; `pensador` asigna.

### RF-08: Agentes Transversales (5) — Cuándo Entran
**Descripción**: Los 5 transversales intervienen en momentos específicos:
- `gitflow`: branching/PRs en `speckit-implement` + merge en `converge`
- `plataformador`: nivelación de proyectos, diagnóstico remoto
- `upgrade_framework`: migraciones de versión de framework
- `analista_tecnico`: investigación técnica, POCs, evaluación librerías
- `solucionador`: debugging producción, incidentes, hotfixes
**Criterio**: Cada transversal tiene trigger explícito en tasks.md.

### RF-09: MCPs + Graphify + Codebase-Memory como Contexto Previo
**Descripción**: Antes de **CADA** `speckit-*`, `pensador` consulta:
- `codebase-memory`: arquitectura, dependencias, callers/callees, clusters
- `graphify`: conocimiento persistente del proyecto (god nodes, communities)
- MCPs disponibles: `context-mode` (ctx_search), `markitdown` (convert_to_markdown)
**Criterio**: Log de consultas previas visible en cada fase del pipeline.

### RF-10: Rutas de Guardado por Aplicación
**Descripción**: Estricta separación por app:
- Código: `src/<AppName>/`
- Specs/Plans/Tasks/ADRs: `Documentacion/<AppName>/specs/`
- Kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/`) sincronizado vía `sync-agents.ps1`
**Criterio**: `Documentacion/<AppName>/` **NUNCA** se toca en sync.

### RF-11: Skills Declaradas en .agent.md
**Descripción**: Cada agente declara sus skills Speckit en su definición (`.github/agents/<name>.agent.md` y `.opencode/agents/<name>.md`):
- `pensador`: speckit-specify, speckit-plan, speckit-tasks, speckit-analyze, speckit-converge, speckit-implement
- `arquitecto`: speckit-analyze
- `documentador`: speckit-converge
- `security-auditor`: speckit-analyze
- Implementadores: speckit-implement
- Transversales: skills según trigger
**Criterio**: `speckit-*` solo invocable si skill declarada.

### RF-12: 00-indice.md Actualizado
**Descripción**: `Documentacion/<AppName>/specs/00-indice.md` mantiene:
- Tabla de specs activas con estado
- Mapeo agente ↔ skill Speckit ↔ fase pipeline
- Rutas por app
- Enlace a graphify.md
**Criterio**: Actualizado automáticamente en `speckit-converge`.

### RF-13: graphify.md Creado
**Descripción**: `Documentacion/<AppName>/specs/graphify.md` documenta:
- Cómo consultar Graphify antes de cada fase
- God nodes relevantes del proyecto
- Communities detectadas
- Queries de ejemplo para contexto previo
**Criterio**: Creado en fase documental, actualizado en `converge`.

### RF-14: Constitution Wizard — Asistente Interactivo de Creación
**Descripción**: `pensador` incluye un **wizard interactivo** para crear/actualizar `.specify/memory/constitution.md` desde cero o adaptar existente. No es solo "check" — es **guiado paso a paso** (como el plan) con plantilla estructurada:
1. **Tipo de proyecto**: Nuevo / Existente a migrar al formato
2. **Objetivo de la solución**: Qué hace, problema que resuelve, usuarios
3. **Arquitectura objetivo**: # componentes/apps, monolito vs microservicios, límites
4. **Stack tecnológico**: Lenguaje(s), framework(s), runtime(s)
5. **Metodología de programación**: Confirmar SSD + Speckit + TDD + Clean Architecture (o la que elija)
6. **Base de datos**: Tipo (SQL/NoSQL), engine, migraciones, multi-tenancy
7. **Despliegue**: Docker/K8s/serverless/bare-metal, CI/CD, entornos
8. **Estructura de carpetas**: Estándar `src/<app>/` + `Documentacion/<app>/` o personalizada
9. **Artículos de Constitution (**6 artículos (I–VI, con VI=proyect_ext)**)**: Para cada uno, el wizard pregunta:
   - Art.I Modular Agent Design: ¿Cada feature como componente autocontenido? ¿Interfaces claras?
   - Art.II Orchestrator Pattern: ¿Orquestador principal? ¿Contrato de interacción entre agentes?
   - Art.III Specification-Driven Development: ¿Specs antes de implementar? ¿TDD y coverage mínimo?
   - Art.IV Copilot/Opencode Compatibility: ¿Funciona en ambos harnesses? ¿Integraciones tool-specific aisladas?
   - Art.V Observability and Monitoring: ¿Logging estructurado? ¿Trazabilidad de decisiones y errores?
   - Art.VI proyect_ext: ¿Dependencias externas en proyect_ext/? ¿Manifest actualizado?
10. **Guardrails adicionales**: Reglas específicas del proyecto (naming, security, observability)
11. **Validación final**: Resumen completo → usuario confirma → se escribe constitution.md

**Criterio**: Wizard produce constitution.md válida (**6 artículos (I–VI, con VI=proyect_ext)**) con respuestas del usuario; si ya existe, ofrece "revisar y actualizar" sección por sección.

---

## Criterios de Aceptación (mínimo 10)

| ID | Criterio | Verificación |
|----|----------|--------------|
| AC-01 | Constitution check PASS antes de cualquier `speckit-*` | Test automatizado: `speckit-specify` falla si constitution.md ausente/inválido |
| AC-02 | Pipeline Speckit end-to-end funcional | Test: `specify → plan → tasks → analyze → converge → implement` completa sin errores |
| AC-03 | Cada agente complementa (no duplica) Speckit | Auditoría: revisar .agent.md → skills declaradas coinciden con RF-03 a RF-08 |
| AC-04 | MCPs/Graphify enriquecen contexto previo en cada fase | Log de `pensador` muestra consultas a codebase-memory, graphify, context-mode antes de cada `speckit-*` |
| AC-05 | Rutas por app respetadas (src/ + Documentacion/) | Test: artefacts generados en `Documentacion/<AppName>/specs/`, código en `src/<AppName>/` |
| AC-06 | Skills Speckit declaradas en 13 .agent.md | Grep: cada .agent.md contiene skills correspondientes (RF-11) |
| AC-07 | 00-indice.md actualizado con flujo unificado + tabla agentes/skills | Verificación visual + test de enlaces rotos |
| AC-08 | graphify.md creado con queries de ejemplo | Archivo existe en `Documentacion/<AppName>/specs/graphify.md` |
| AC-09 | Tests QA PASS (Constitution check + pipeline + agentes + contexto) | `qa-senior` ejecuta suite y reporta 0 fallos |
| AC-10 | Sync-agents.ps1 no toca Documentacion/<AppName>/ | Dry-run confirma solo kit transversal copiado |
| AC-11 | Constitution Wizard funcional y produce constitution.md válida | Test: wizard interactivo completa 11 pasos → genera constitution.md con **6 artículos (I–VI, con VI=proyect_ext)**; si existe, modo "revisar y actualizar" funciona |

---

## Matriz de trazabilidad RF↔task↔agente

> Tabla explícita única (corrección BUG-5, 2026-09-19). Matriz reconstruida del reporte QA `Documentacion/Agents_IA_TECH/testing/validacion-ssd-speckit-2026-09-19.md` (T-V2): 0 RFs huérfanos, 0 tasks sin agente.

| RF | Task(s) | Agente(s) |
|----|---------|-----------|
| RF-01 | T-I1 | `pensador` |
| RF-02 | T-I1 | `pensador` |
| RF-03 | T-I1 | `pensador` |
| RF-04 | T-I2 | `arquitecto` |
| RF-05 | T-I3 | `documentador` |
| RF-06 | T-I4 + T-D2 | `security-auditor` |
| RF-07 | T-I5, T-I6, T-I7, T-I8 | `api-developer`, `frontend-developer`, `devops`, `qa-senior` |
| RF-08 | T-I9, T-I10, T-I11, T-I12, T-I13 | `gitflow`, `plataformador`, `upgrade_framework`, `analista_tecnico`, `solucionador` |
| RF-09 | T-I1 | `pensador` |
| RF-10 | T-I14 | `devops` |
| RF-11 | T-I1..T-I13 (todas) | los 13 agentes |
| RF-12 | T-I14 | `devops` |
| RF-13 | T-I15 | `devops` |
| RF-14 | T-I16 + T-I17 | `pensador` + `devops` |

Nota: todas las T-I* las implementa `devops` sobre los archivos del agente indicado; T-D2 la implementa `security-auditor`.

---

## Fuera de Alcance

- Modificación de Speckit core (upstream)
- Cambios a constitution.md base (gestionado por proyecto)
- Implementación de features de negocio (solo metodología)
- UI para visualización de pipeline (solo CLI/agents)

---

## Dependencias

- `.specify/memory/constitution.md` (base + project_ext)
- Speckit CLI instalado y en PATH
- MCPs: `context-mode`, `codebase-memory`, `markitdown`, `graphify`
- Kit `Agents_IA_TECH` v13 agentes sincronizado

---

## Referencias

- AGENTS.md (gobernanza agentes)
- copilot-instructions.md (reglas base)
- .doc_agents/estructura-aplicacion.md (rutas por app)
- .doc_agents/capacidad-base.md (catálogo kit transversal)
- Documentacion/<AppName>/reglas-transversales-agentes.md (reglas usuario 2026-09-12)