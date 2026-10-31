# Tasks 031 — Permisos, dominio y delegación de agentes

## Estado general
Spec 031 definida y nivelación ejecutada y verificada (validador verde). Todas las tareas T01–T15 están cerradas: nivelación de agentes, test de contrato (CA-10/CA-12), verificación de no-escritura del validador (CA-11), analyze (arquitecto), threat model (security-auditor) y converge/cierre (documentador).

## Tareas

### T01 — Nivelar `pensador` (Documental)
- **Agente asignado:** `pensador` (estructural), `plataformador` (ejecución de edición)
- **Dependencias:** ninguna
- **Contenido:** `dominio_check` con 3 opciones + espera de input + excepción solo por sesión; protocolo `[S]/[N]/[C]`; nunca escribe código; frontmatter con tier Documental y skills `speckit-*`; sección Enfoque, MCPs, Idioma, Constraints.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; `dominio_check` presente con las 3 opciones exactas en ambos `pensador`.
- **Estado:** Cerrado — verificado (validador OK).

### T02 — Nivelar `solucionador` (Plataforma)
- **Agente asignado:** `solucionador`
- **Dependencias:** ninguna
- **Contenido:** protocolo `[S]/[N]/[C]`, prohibiciones absolutas (`rm -rf /`, formateo, pérdida total de datos, borrar BD sin backup), sesión SSH única reutilizable cerrada solo por el usuario, backup verificado + rollback declarado.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; CA-07 y CA-08 cumplidos.
- **Estado:** Cerrado — verificado (validador OK).

### T03 — Nivelar `security-auditor` (Documental)
- **Agente asignado:** `security-auditor`
- **Dependencias:** ninguna
- **Contenido:** introducción, skills (`security-review`, `security-scan`, `threat-modeling`, `speckit-analyze`, `hipaa-compliance`, `healthcare-phi-compliance`, `defi-amm-security`, `llm-trading-agent-security`), enfoque, MCPs, idioma, constraints. Nunca escribe código ni aplica parches.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; threat-modeling declarado y resoluble.
- **Estado:** Cerrado — verificado (validador OK).

### T04 — Nivelar `usuario-preferencias` (Documental)
- **Agente asignado:** `usuario-preferencias`
- **Dependencias:** ninguna
- **Contenido:** introducción (capa de gobernanza), skills (`speckit-specify`, `speckit-analyze`, `documentation-lookup`, `knowledge-ops`), enfoque, MCPs, idioma, constraints. Nunca ejecuta procedimientos; solo cita política y delega.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses.
- **Estado:** Cerrado — verificado (validador OK).

### T05 — Nivelar `plataformador` (Plataforma)
- **Agente asignado:** `plataformador`
- **Dependencias:** ninguna
- **Contenido:** restauración de versión completa de `5513d37` (358 líneas) + adición de `Enfoque` y `Constraints`; tier Plataforma; skills `speckit-*`, `documentation-lookup`, `knowledge-ops`, `architecture-decision-records`.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses; cuerpo idéntico `.github/` ↔ `.opencode/`.
- **Estado:** Cerrado — verificado (validador OK).

### T06 — Nivelar `upgrade_framework` (Plataforma)
- **Agente asignado:** `upgrade_framework`
- **Dependencias:** ninguna
- **Contenido:** skills (`speckit-plan`, `speckit-implement`, `architecture-decision-records`, `verification-loop`), enfoque, idioma, constraints; principio de trabajo pesado determinista + IA solo para análisis de impacto.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses.
- **Estado:** Cerrado — verificado (validador OK).

### T07 — Nivelar `gitflow` (Tooling)
- **Agente asignado:** `gitflow`
- **Dependencias:** ninguna
- **Contenido:** skills (`speckit-implement`, `speckit-converge`), idioma, enfoque; regla crítica nunca decidas solo; comandos PowerShell; constraints de git.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses.
- **Estado:** Cerrado — verificado (validador OK).

### T08 — Nivelar `Agent-SSD` (Documental extendido)
- **Agente asignado:** `Agent-SSD`
- **Dependencias:** ninguna
- **Contenido:** skills 6 speckit (`specify`, `plan`, `tasks`, `analyze`, `converge`, `constitution`), enfoque del ciclo SSD, matriz de responsabilidades, donde escriben los artefactos.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses.
- **Estado:** Cerrado — verificado (validador OK).

### T09 — Nivelar `analista_tecnico` (Documental)
- **Agente asignado:** `analista_tecnico`
- **Dependencias:** ninguna
- **Contenido:** skills (`speckit-specify`, `speckit-analyze`, `documentation-lookup`, `knowledge-ops`), enfoque pipeline sin IA de entrada, idioma, constraints, permisos de edición acotados.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses.
- **Estado:** Cerrado — verificado (validador OK).

### T10 — Nivelar `arquitecto` y `documentador` (Documental)
- **Agente asignado:** `arquitecto`, `documentador`
- **Dependencias:** ninguna
- **Contenido:** sección Idioma en `.opencode`, sección Constraints en `.github`, skills resueltas, enfoque, MCPs.
- **Criterio de aceptación:** VAL-08 = 0 en ambos arneses para ambos agentes.
- **Estado:** Cerrado — verificado (validador OK).

### T11 — Test de contrato `.github` ↔ `.opencode` (CA-10/CA-12)
- **Agente asignado:** `developer` (único escritor de código), revisado por `pensador`
- **Dependencias:** T01..T10 cerradas
- **Contenido:** crear `tests/agents-parity.Tests.ps1` que:
  1. Para cada uno de los 13 agentes, lea `.github/agents/<n>.agent.md` y `.opencode/agents/<n>.md`.
  2. Verifique que el cuerpo (sin frontmatter) sea idéntico línea por línea entre ambos arneses.
  3. Verifique que `tier`, `description` y el conjunto de `skills` del frontmatter coincidan.
  4. Verifique que cada agente tenga las secciones de Regla 2: introducción, skills, enfoque, MCPs, idioma, constraints.
  5. Fixture negativo: incluir un caso con un archivo divergente (sección modificada en un solo arnés) que deba fallar.
- **Criterio de aceptación:** test pasa en verde sobre el árbol actual (20 agentes, 13 pares); el fixture negativo hace fallar el test cuando se introduce una divergencia; el validador sigue en `FAIL=0`.
- **Estado:** Cerrado — verificado (exit code 0, fixture negativo OK).

### T12 — Verificación de no-escritura del validador (CA-11)
- **Agente asignado:** `pensador` (valida), `developer` (ejecuta la comprobación)
- **Dependencias:** T11 cerrada
- **Contenido:** ejecutar `scripts/validate-agents-skills.ps1` y confirmar `git status` limpio después (el validador es solo lectura; no escribe archivos).
- **Criterio de aceptación:** exit code 0; `git status` limpio tras ejecutar el validador.
- **Estado:** Cerrado — verificado (validador no escribe archivos).

### T13 — Converge y cierre de 031
- **Agente asignado:** `documentador` (orquesta), `pensador` (valida)
- **Dependencias:** T11, T12, T14, T15 cerradas
- **Contenido:** actualizar `00-indice.md` y `pendientes-implementacion.md`; confirmar que la spec queda ACTIVA en `specs/` (no archivar); verificar que no hay placeholders ni secciones vacías en los archivos generados.
- **Criterio de aceptación:** validador en verde; `git status` limpio; `00-indice.md` refleja cierre de nivelación; spec 031 activa y completa.
- **Estado:** Cerrado — verificado.

### T14 — Analyze cross-artifact (arquitecto)
- **Agente asignado:** `arquitecto`
- **Dependencias:** T01..T13 cerradas
- **Contenido:** `specs/031-permisos-y-dominio-de-agentes/analize.md` — análisis de consistencia spec.md ↔ plan.md ↔ tasks.md + Constitución (Art. III, IV/V, VII, IX, X). Matriz de trazabilidad FR → plan → tasks → verificación; matriz de trazabilidad CA → verificación; Constitución Check; detección de vacíos y contradicciones; verificación de calidad del contenido (sin placeholders, sin secciones vacías).
- **Criterio de aceptación:** `analyze.md` generado con contenido real; 24/24 FR mapeados; 12/12 CA verificados; 5/5 artículos de Constitución PASS; sin placeholders ni secciones vacías.
- **Estado:** Cerrado — verificado.

### T15 — Threat model (security-auditor)
- **Agente asignado:** `security-auditor`
- **Dependencias:** T01..T13 cerradas
- **Contenido:** `specs/031-permisos-y-dominio-de-agentes/threat-model.md` — diagrama de flujo de datos (DFD), matriz STRIDE (6 categorías), registro de riesgos (10 riesgos TM-01..TM-10), DFD de operaciones críticas, casos borde mapeados a amenazas, controles y mitigaciones, conclusión del threat model.
- **Criterio de aceptación:** `threat-model.md` generado con contenido real; matriz STRIDE completa; registro de riesgos con mitigaciones; sin placeholders ni secciones vacías.
- **Estado:** Cerrado — verificado.

## Orden de ejecución

T11 → T12 → T13 → T14 → T15. Las tareas T01–T10 ya están cerradas; no se reejecutan.

## Gate de cierre

- `scripts/validate-agents-skills.ps1`: `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0.
- `tests/agents-parity.ps1`: pasa en verde; fixture negativo detecta divergencia unilateral.
- `analyze.md`: consistencia cross-artifact verificada; sin placeholders ni secciones vacías.
- `threat-model.md`: matriz STRIDE y registro de riesgos completos; sin placeholders ni secciones vacías.
- `git status`: limpio después de ejecutar validador y test.
