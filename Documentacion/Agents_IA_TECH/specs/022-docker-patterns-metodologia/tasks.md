# Tasks: 022-docker-patterns-metodologia

**Feature**: Patrones Docker transversales de metodología para el KIT
**Spec**: `022-docker-patterns-metodologia/spec.md`
**Plan**: `022-docker-patterns-metodologia/plan.md`
**Status**: Draft
**Created**: 2026-10-21

---

## Tareas de implementación

### T-01 Actualizar skill docker-patterns con sección Metodología transversal
**Descripción**: Actualizar la skill `docker-patterns` en `.github/skills/docker/docker-patterns/SKILL.md` y su réplica en `.opencode/skills/docker/docker-patterns/SKILL.md` añadiendo la sección `Metodología transversal`. La sección debe resumir los patrones FR-01 a FR-09 de la spec 022 con referencias directas a `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md` y a `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia-transversal.md`. Usar ejemplos genéricos sin claves reales ni configuraciones particulares de Boleteria Cardenales.
**Criterios de aceptación**:
* La skill contiene la sección `Metodología transversal` con subtítulos para FR-01 a FR-09.
* Se referencia la spec 022 y el patrón transversal creado en T-02.
* No existen placeholders, TBD, TODO, pendiente, N/A.
* Los ejemplos usan nombres genéricos `API_KEY`, `DB_PASSWORD` sin valores reales.
* No hay desajuste entre `.github` y `.opencode`.
**Asignado a**: devops
**Estado**: Pendiente

### T-02 Crear patrón transversal .doc_agents/patterns/docker-metodologia-transversal.md
**Descripción**: Crear el documento transversal `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia-transversal.md` que consolida la metodología Docker aplicable a todos los proyectos del KIT. El documento debe cubrir FR-01 Multi-entorno con mismo código y .env solo como plantilla, FR-02 Patrón env_or_secret con prioridad secret > env > default, FR-03 Uso de Docker secrets como única vía para claves sensibles, FR-04 Entrypoint para configuración dinámica, FR-05 Recreación de contenedor, FR-06 Montajes quirúrgicos, FR-07 Logging estructurado, FR-08 Setup idempotente, FR-09 Seguridad en capas. No generar docker-compose.yml ni directorio secrets automáticamente.
**Criterios de aceptación**:
* El archivo existe en la ruta indicada `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia-transversal.md` y contiene secciones completas para los nueve FR.
* `.env.example` o `.env.template` se describe como plantilla con claves vacías y comentarios descriptivos.
* Se documenta prioridad secret > env > default sin exponer valores en logs.
* Se prohíbe creación automática de directorio `secrets/` y se indica creación manual por operador.
* No existen placeholders ni datos sensibles.
* El idioma es español latino neutro.
**Asignado a**: arquitecto
**Estado**: Pendiente

### T-03 Crear checklist docker-metodologia.md
**Descripción**: Crear `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/docker-metodologia-checklist.md` con ítems verificables para auditoría de proyectos contra la metodología Docker transversal. Cada FR debe tener al menos un ítem de verificación.
**Criterios de aceptación**:
* El checklist incluye ítems verificables para FR-01 a FR-09 y FR-10.
* Cada ítem indica evidencia esperada, por ejemplo existencia de `.env.example`, ausencia de `.env` en git, documentación de prioridad env_or_secret, prohibición de secrets en variables visibles, comando de recreación estándar documentado, lista de rutas nunca montar, configuración de logging json-file con rotación, criterios de idempotencia.
* No existen placeholders.
* El checklist es ejecutable sin generar configuración.
**Asignado a**: documentador
**Estado**: Pendiente

### T-04 Actualizar definición de agentes devops y arquitecto para referenciar patrón
**Descripción**: Actualizar las definiciones de agentes `devops` y `arquitecto` en `.github/agents/` y `.opencode/agents/` para referenciar el patrón transversal Docker creado en T-02. Añadir en sección de MCPs y enfoque una referencia obligatoria a `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia-transversal.md` y a la spec 022. Mantener frontmatter y sincronía entre arneses.
**Criterios de aceptación**:
* Ambas definiciones de agente contienen referencia explícita al patrón transversal Docker.
* La referencia incluye ruta completa y mención a la spec 022.
* No hay desajuste entre `.github/agents/` y `.opencode/agents/`.
* El contenido está completo sin placeholders.
**Asignado a**: documentador
**Estado**: Pendiente

### T-05 Verificación qa-senior de completitud y ausencia de placeholders
**Descripción**: Revisar los artefactos generados en T-01 a T-04 para verificar completitud, ausencia de placeholders, cumplimiento de restricciones de la spec 022 y consistencia de referencias cruzadas. Aplicar checklist a un proyecto de ejemplo y confirmar que todos los ítems son evaluables sin generar configuración.
**Criterios de aceptación**:
* No existen cadenas TBD, TODO, pendiente, por definir, N/A, XXX en los artefactos.
* No se genera docker-compose.yml ni directorio secrets automáticamente.
* No hay ejemplos con claves reales ni .env con datos sensibles.
* La skill docker-patterns referencia correctamente spec y patrón transversal.
* El patrón transversal cubre FR-01 a FR-09 con contenido real mínimo tres líneas por sección.
* La verificación queda registrada con fecha y resultado PASS/FAIL.
**Asignado a**: qa-senior
**Estado**: Pendiente

### T-06 Actualizar 00-indice.md
**Descripción**: Actualizar `Documentacion/Agents_IA_TECH/00-indice.md` para registrar la spec 022-docker-patterns-metodologia, el patrón transversal `docker-metodologia.md` y el checklist creado. Incluir estado, fecha de creación y enlace a spec.md.
**Criterios de aceptación**:
* El índice contiene entrada para spec 022 con ruta completa `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md`.
* Se referencia el patrón transversal y el checklist.
* No hay placeholders ni enlaces rotos.
* El índice mantiene formato consistente con entradas existentes.
**Asignado a**: documentador
**Estado**: Pendiente

---

## Dependencias

* T-02 bloquea T-01 y T-04.
* T-02 bloquea T-03.
* T-01, T-03 y T-04 bloquean T-05.
* T-05 bloquea T-06.

## Criterios de cierre

* Skill `docker-patterns` actualizada con sección Metodología transversal sin desajustes entre arneses.
* Patrón transversal `docker-metodologia.md` creado con cobertura completa de FR-01 a FR-09 sin placeholders.
* Checklist `docker-metodologia-checklist.md` creado con ítems verificables para cada FR.
* Agentes `devops` y `arquitecto` referencian el patrón transversal.
* Verificación qa-senior concluye PASS sin placeholders ni datos sensibles.
* Índice 00-indice.md actualizado con referencias a spec, patrón y checklist.
