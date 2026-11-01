# Implementation Plan: 022-docker-patterns-metodologia

**Feature**: Patrones Docker transversales de metodología para el KIT
**Spec**: `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md`
**Branch**: `022-docker-patterns-metodologia`
**Status**: Plan
**Created**: 2026-10-21

---

## Resumen técnico

La especificación es documental y de metodología. No genera artefactos de configuración por proyecto. El plan define la actualización de la skill `docker-patterns` con una sección de Metodología transversal, la creación de documentación transversal en `.doc_agents/patterns/` y un checklist reutilizable. Se estandariza multi-entorno con mismo código, prioridad secret > env > default, uso exclusivo de Docker secrets para datos sensibles, entrypoint para configuración dinámica, recreación forzada de contenedores, montajes quirúrgicos, logging estructurado y setup idempotente. No se crea `docker-compose.yml` ni directorio `secrets/` automáticamente en nuevos proyectos.

## Arquitectura de solución

### Componentes involucrados

- Skill `docker-patterns` ubicada en `.github/skills/docker/docker-patterns/SKILL.md` y replica en `.opencode/skills/docker/docker-patterns/SKILL.md`.
- Documentación transversal `Documentacion/Agents_IA_TECH/.doc_agents/patterns/` para patrones reutilizables por todos los proyectos del KIT.
- `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md` como fuente de verdad.
- Checklist de verificación en `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/docker-metodologia-checklist.md`.

### Flujo propuesto

1. Consolidar los FR-01 a FR-09 en documento de metodología transversal.
2. Actualizar `docker-patterns` añadiendo sección `Metodología transversal` con resumen y referencias a la spec.
3. Crear `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia-transversal.md` con los patrones detallados.
4. Crear `docker-metodologia-checklist.md` con ítems verificables para auditoría de proyectos.
5. Validar que no se generen archivos de configuración ni directorios `secrets/` automáticamente.
6. Registrar la actualización en el índice de specs y en la bitácora de cambios del KIT.

## Decisiones de diseño

- **Solo metodología, cero configuración**: la spec y el plan no generan `docker-compose.yml`, `.env` con valores ni directorios `secrets/`. Solo documentan cómo hacerlo.
- **Skill como punto de entrada**: `docker-patterns` es el agente consultado por devops, api-developer y frontend-developer. La sección transversal debe resumir sin duplicar la spec.
- **Plantilla `.env` únicamente**: se documenta `.env.example` o `.env.template` con claves vacías y comentarios. Nunca se versiona `.env` con valores reales.
- **Prioridad de configuración**: secret > env > default. Implementación documentada en entrypoint, sin exponer valores en logs.
- **Creación manual de secrets**: el operador crea el directorio `secrets/` manualmente. El KIT nunca lo crea automáticamente.
- **Montajes quirúrgicos**: se prohíbe montar raíz del proyecto. Solo montajes puntuales de código, volúmenes nombrados para datos y volúmenes anónimos para dependencias.
- **Recreación forzada**: se documenta `docker compose up -d --force-recreate` como comando estándar para aplicar cambios de entorno.
- **Logging estructurado**: `json-file` con rotación, sin secretos en logs.
- **Setup idempotente**: scripts documentados, no implementados, con salida clara y sin efectos colaterales.

## Desglose técnico por FR

### FR-01 Multi-entorno con mismo código y .env solo como plantilla

- **Artefacto**: `docker-metodologia-transversal.md` sección Multi-entorno.
- **Contenido**: un único `docker-compose.yml` por servicio. Variación por archivos `.env` locales o variables del host. `.env.example` con claves vacías y comentarios. No versionar `.env` con valores.
- **Verificación**: checklist confirma existencia de `.env.example` y ausencia de `.env` en git.

### FR-02 Patrón env_or_secret con prioridad y sin secretos en .env

- **Artefacto**: sección Patrón de configuración unificada.
- **Contenido**: regla prioridad secret > env > default. Ejemplo de entrypoint que lee `/run/secrets/` primero, luego variables de entorno, luego defaults. No imprimir valores.
- **Verificación**: checklist verifica que documentación incluye regla de prioridad y prohibición de secretos en `.env`.

### FR-03 Uso de Docker secrets como única vía para claves sensibles

- **Artefacto**: sección Gestión de secretos.
- **Contenido**: claves, tokens, passwords y certificados solo via Docker secrets. Directorio `secrets/` creado manualmente por operador. Montaje en `/run/secrets/`. Prohibición de montar `.env` con secretos y de pasar secretos por variables visibles.
- **Verificación**: checklist verifica prohibición explícita y ausencia de creación automática.

### FR-04 Entrypoint para configuración dinámica sin edición manual

- **Artefacto**: sección Entrypoint estándar.
- **Contenido**: flujo de inicialización: leer env, validar presencia de secrets esperados, generar archivos de configuración internos, aplicar defaults seguros, salir con código de error si falta secreto crítico. Evita edición manual dentro del contenedor.
- **Verificación**: checklist verifica descripción de flujo y manejo de errores.

### FR-05 Recreación de contenedor para aplicar cambios de entorno

- **Artefacto**: sección Aplicación de cambios.
- **Contenido**: comando `docker compose up -d --force-recreate`. Explicación de por qué `up -d` no basta. Procedimiento seguro y reproducible.
- **Verificación**: checklist incluye comando estándar.

### FR-06 Montajes quirúrgicos y evitar mounts completos

- **Artefacto**: sección Volúmenes y montajes.
- **Contenido**: montar solo código fuente puntual en desarrollo, volúmenes nombrados para persistencia, evitar montar raíz del proyecto. Rutas permitidas y rutas prohibidas. Diferenciación desarrollo vs producción.
- **Verificación**: checklist verifica listado de rutas nunca montar.

### FR-07 Logging estructurado por servicio

- **Artefacto**: sección Logging.
- **Contenido**: logs en JSON o clave-valor con nivel, servicio y timestamp. Configuración `logging` en compose con driver `json-file` y rotación. Recomendación de agregador opcional. Prohibición de logs con secretos.
- **Verificación**: checklist verifica configuración de rotación y prohibición de secretos.

### FR-08 Setup idempotente con scripts

- **Artefacto**: sección Setup idempotente.
- **Contenido**: scripts documentados que crean red Docker, verifican dependencias, validan presencia de `.env.template`, listan secrets esperados sin crearlos, ejecutan health checks. Idempotencia y códigos de salida claros.
- **Verificación**: checklist verifica criterios de idempotencia.

### FR-09 Seguridad en capas para secretos y sesiones

- **Artefacto**: sección Seguridad en capas.
- **Contenido**: secretos fuera del contenedor, permisos 600 en host, uso de Docker secrets, rotación sin modificar código, separación de sesiones por entorno, sesiones nunca en volúmenes compartidos.
- **Verificación**: checklist verifica permisos y separación.

### FR-10 Actualizar skill docker-patterns con sección Metodología transversal

- **Artefacto**: actualización de `.github/skills/docker/docker-patterns/SKILL.md` y replica en `.opencode`.
- **Contenido**: sección `Metodología transversal` que resume FR-01 a FR-09 con referencia a `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md`. Ejemplos genéricos, sin claves reales ni configuraciones de Boleteria Cardenales.
- **Verificación**: skill contiene sección nueva, referencias correctas, sin datos sensibles.

## Dependencias

- Spec `022-docker-patterns-metodologia/spec.md` aprobada y completa.
- Skill `docker-patterns` existente en KIT.
- Constitución del KIT y reglas de seguridad de secretos.
- Estructura `.doc_agents/patterns/` disponible en el KIT transversal.

## Riesgos y mitigaciones

- **R1 Divergencia entre skill y documentación transversal**. Mitigación: actualizar ambas en el mismo ciclo y referenciar spec como fuente de verdad.
- **R2 Interpretación de que el KIT debe crear secrets o compose**. Mitigación: restricciones explícitas en spec y plan, checklist con verificación de no creación automática.
- **R3 Uso de `.env` con valores reales en proyectos nuevos**. Mitigación: checklist de auditoría y sección de metodología que prohíbe versionar `.env`.
- **R4 Fuga de secretos en logs**. Mitigación: documentación de logging estructurado con prohibición explícita y ejemplo de filtrado.
- **R5 Montajes completos del código en producción**. Mitigación: patrón de montajes quirúrgicos documentado y checklist de revisión.

## Estrategia de testing

La spec es documental, por lo que el testing es de verificación de contenido y consistencia.

- **Verificación de completitud**: revisar que `plan.md`, `docker-metodologia-transversal.md`, `checklist.md` y actualización de skill no contengan placeholders, TBD, TODO, pendiente, N/A.
- **Verificación de restricciones**: confirmar ausencia de creación automática de `docker-compose.yml` o directorio `secrets/`.
- **Verificación de seguridad**: buscar cadenas que contengan valores de ejemplo sensibles; solo se permiten claves genéricas como `API_KEY`, `DB_PASSWORD`.
- **Verificación de referencias cruzadas**: cada FR en spec referenciado en plan y en skill.
- **Verificación de idioma**: español latino neutro sin jerga regional.
- **Prueba de auditoría**: aplicar checklist a un proyecto de ejemplo del KIT y confirmar que todos los ítems son evaluables sin generar configuración.

## Consideraciones de seguridad

- Claves nunca en `.env`. `.env` solo como plantilla con valores vacíos.
- Secretos solo via Docker secrets montados en `/run/secrets/`.
- No pasar secretos por variables de entorno visibles.
- Permisos 600 en archivos de secrets en host.
- Entrypoint no debe registrar valores de secretos en logs ni stdout.
- Logging estructurado sin secretos.
- Rotación de secrets sin modificar código ni compose.
- Separación de sesiones por entorno y sin volumen compartido.

## Restricciones confirmadas

- No crear `docker-compose.yml` ni directorio `secrets/` automáticamente en nuevos proyectos.
- No incluir claves reales ni ejemplos de `.env` con datos sensibles.
- Solo metodología, sin configuraciones particulares de Boleteria Cardenales.
- Contenido completo sin placeholders.
- `.env` se usa solo como plantilla, nunca con valores reales versionados.

## Criterios de verificación

- `plan.md` creado en `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/` con todas las secciones completas.
- `docker-metodologia-transversal.md` creado en `.doc_agents/patterns/` con cobertura de FR-01 a FR-09.
- `docker-metodologia-checklist.md` creado con ítems verificables para cada FR.
- Skill `docker-patterns` actualizada con sección `Metodología transversal` y referencia a la spec.
- Ningún artefacto contiene placeholders ni datos sensibles.
- No se genera `docker-compose.yml` ni directorio `secrets/` automáticamente.
