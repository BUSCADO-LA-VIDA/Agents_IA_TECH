# Plan: [SSD-SPECKIT-INTEGRACION]

**Versión**: 1.0
**Fecha**: 2026-09-19
**Estado**: Borrador
**Basado en**: spec.md v1.0

---

## Visión General

Implementar la integración completa SSD + Speckit + Graphify + MCPs en los 13 agentes del kit `Agents_IA_TECH` en **3 fases secuenciales**, siguiendo el principio **Documentar → Implementar → Validar**.

---

## Fase 1: Documental (Actual) — Semana 1
**Responsables**: `documentador`, `security-auditor`
**Entregables**: spec.md ✅, plan.md ✅, tasks.md ✅, seguridad/metodologia-ssd.md

| Task | Descripción | Agente | Estado |
|------|-------------|--------|--------|
| T-D1 | Crear spec.md / plan.md / tasks.md en `specs/metodologia-ssd-speckit/` | documentador | 🔄 En curso |
| T-D2 | Crear `Documentacion/Agents_IA_TECH/seguridad/metodologia-ssd.md` (threat model, riesgos, Art.V) | security-auditor | ⏳ Pendiente |

**Criterios de salida Fase 1**:
- 3 archivos spec/plan/tasks creados y consistentes
- Documento de seguridad validado por security-auditor
- Constitution check PASS sobre spec.md

---

## Fase 2: Implementación DevOps — Semana 2-3
**Responsable**: `devops` (con apoyo de `pensador` para validación)
**Entregables**: 13 .agent.md actualizados, 00-indice.md, MCPs/graphify.md

### 2.1 Actualización Agentes Documentales (4)

| Task | Agente | Cambios Clave |
|------|--------|---------------|
| T-D3 | pensador | Constitution check obligatorio, pipeline ordenado, MCPs/Graphify contexto previo, delegación explícita a arquitecto/documentador/security/implementadores |
| T-D4 | arquitecto | Skills: speckit-analyze; ADRs, guardrails, spec linking |
| T-D5 | documentador | Skills: speckit-converge; flujos, templates, versionado |
| T-D6 | security-auditor | Skills: speckit-analyze; threat model, security-risk en tasks |

### 2.2 Actualización Implementadores (4)

| Task | Agente | Cambios Clave |
|------|--------|---------------|
| T-D7a | api-developer | Skill: speckit-implement; expertise backend/API/DB/auth |
| T-D7b | frontend-developer | Skill: speckit-implement; expertise UI/state/a11y |
| T-D7c | devops | Skill: speckit-implement; expertise CI/CD/infra/obs |
| T-D7d | qa-senior | Skill: speckit-implement; expertise tests/quality gates |

### 2.3 Actualización Transversales (5)

| Task | Agente | Cambios Clave |
|------|--------|---------------|
| T-D8a | gitflow | Trigger: branching/PR en implement, merge en converge |
| T-D8b | plataformador | Trigger: nivelación proyectos, diagnóstico remoto |
| T-D8c | upgrade_framework | Trigger: migraciones versión framework |
| T-D8d | analista_tecnico | Trigger: investigación, POCs, evaluación librerías |
| T-D8e | solucionador | Trigger: debugging producción, incidentes, hotfixes |

### 2.4 Artefactos Transversales

| Task | Descripción |
|------|-------------|
| T-D9 | Actualizar `Documentacion/Agents_IA_TECH/specs/00-indice.md`: flujo unificado, tabla agentes/skills/speckit, rutas por app, enlace graphify.md |
| T-D10 | Crear `Documentacion/Agents_IA_TECH/specs/MCPs/graphify.md`: consultas previas, god nodes, communities, queries ejemplo |
| T-D11 | Implementar Constitution Wizard en pensador.agent.md (11 pasos interactivos, modo revisar/actualizar) |
| T-D12 | Actualizar 00-indice.md con documentación del Constitution Wizard |

**Criterios de salida Fase 2**:
- 13 .agent.md actualizados en `.github/agents/` y `.opencode/agents/`
- 00-indice.md y graphify.md creados
- `sync-agents.ps1 -DryRun` confirma solo kit transversal
- Constitution check PASS sobre todos los .agent.md

---

## Fase 3: Validación QA-Senior — Semana 4
**Responsable**: `qa-senior`
**Entrada**: Fase 2 completa

| Task | Descripción | Criterio PASS |
|------|-------------|---------------|
| T-D11a | Test Constitution check: `speckit-specify` falla sin constitution.md válido | 0 falsos positivos/negativos |
| T-D11b | Test Pipeline end-to-end: `specify → plan → tasks → analyze → converge → implement` completo | Artefactos generados en rutas correctas |
| T-D11c | Test Agentes complementan: cada agente invoca solo su skill Speckit declarada | Auditoría invocaciones = skills declaradas |
| T-D11d | Test Contexto previo: `pensador` consulta MCPs/Graphify/codebase-memory antes de cada fase | Logs muestran consultas en orden |
| T-D11e | Test Rutas por app: specs en `Documentacion/<AppName>/specs/`, código en `src/<AppName>/` | 0 archivos en ruta incorrecta |
| T-D11f | Test 00-indice.md: enlaces válidos, tabla completa, versión actualizada | 0 enlaces rotos, tabla = 13 agentes |
| T-D11g | Test graphify.md: queries ejecutables, god nodes documentados | Queries devuelven resultados |
| T-D11h | Test Constitution Wizard: wizard nuevo + modo revisar produce constitution.md válida | 5 casos cubiertos, 0 regresiones |

**Criterios de salida Fase 3**:
- Suite T-D11 completa: 0 fallos, 0 advertencias críticas
- Reporte de validación firmado por qa-senior
- Spec marcada como **DONE**

---

## Cronograma Resumido

| Semana | Fase | Entregable Clave |
|--------|------|------------------|
| 1 | Documental | spec.md, plan.md, tasks.md, seguridad/metodologia-ssd.md |
| 2-3 | Implementación | 13 .agent.md, 00-indice.md, MCPs/graphify.md |
| 4 | Validación | Suite T-D11 PASS, reporte QA |

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Constitution.md project_ext incompleto | Media | Alto | Validar en T-D1; bloquear Fase 2 si incompleto |
| Speckit CLI versión incompatible | Baja | Alto | Fixar versión en .specify/config; test en T-D11a |
| Devops no actualiza ambos .github/.opencode | Media | Medio | Checklist en T-D3 a T-D8; validar en sync-agents |
| MCPs no disponibles en entorno | Baja | Medio | Documentar fallback en graphify.md; mock en tests |

---

## Definición de Done (DoD)

- [ ] spec.md, plan.md, tasks.md creados y versionados
- [ ] seguridad/metodologia-ssd.md aprobado por security-auditor
- [ ] 13 .agent.md actualizados en ambos arneses (.github + .opencode)
- [ ] 00-indice.md y MCPs/graphify.md creados
- [ ] Constitution Wizard implementado en pensador.agent.md (11 pasos + modo revisar)
- [ ] sync-agents.ps1 -DryRun limpio
- [ ] Suite T-D11 (8 tests) PASS (incluye T-D11h Constitution Wizard)
- [ ] Reporte QA firmado
- [ ] Spec marcada DONE en 00-indice.md