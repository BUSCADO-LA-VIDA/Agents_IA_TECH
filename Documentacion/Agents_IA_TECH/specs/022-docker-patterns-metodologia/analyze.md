# Análisis de consistencia Speckit 022-docker-patterns-metodologia

**Feature:** Patrones Docker transversales de metodología para el KIT
**Fecha de análisis:** 2026-10-21
**Artefactos revisados:**
- `spec.md` : C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\specs\022-docker-patterns-metodologia\spec.md
- `plan.md` : C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\specs\022-docker-patterns-metodologia\plan.md
- `tasks.md` : C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\specs\022-docker-patterns-metodologia\tasks.md

---

## 1. Consistencia entre spec.md, plan.md y tasks.md

### 1.1 Cobertura de requisitos funcionales

| FR | Descripción spec.md | Cobertura plan.md | Cobertura tasks.md | Estado |
|----|---------------------|-------------------|--------------------|--------|
| FR-01 | Multi-entorno con mismo código y .env solo como plantilla | Sección FR-01 Multi-entorno con mismo código y .env solo como plantilla. Artefacto docker-metodologia-transversal.md | T-02 crea documento transversal con FR-01 | Cubierto |
| FR-02 | Patrón env_or_secret con prioridad secret > env > default, sin secretos en .env | Sección FR-02 Patrón de configuración unificada | T-02 incluye patrón env_or_secret | Cubierto |
| FR-03 | Docker secrets como única vía para claves sensibles, creación manual | Sección FR-03 Uso de Docker secrets | T-02 prohíbe creación automática y documenta creación manual | Cubierto |
| FR-04 | Entrypoint para configuración dinámica sin edición manual | Sección FR-04 Entrypoint estándar | T-02 incluye sección Entrypoint | Cubierto |
| FR-05 | Recreación de contenedor para aplicar cambios de entorno | Sección FR-05 Recreación de contenedor | T-02 incluye sección Aplicación de cambios | Cubierto |
| FR-06 | Montajes quirúrgicos y evitar mounts completos | Sección FR-06 Montajes quirúrgicos | T-02 incluye sección Volúmenes y montajes | Cubierto |
| FR-07 | Logging estructurado por servicio sin secretos | Sección FR-07 Logging estructurado | T-02 incluye sección Logging | Cubierto |
| FR-08 | Setup idempotente con scripts | Sección FR-08 Setup idempotente | T-02 incluye sección Setup idempotente | Cubierto |
| FR-09 | Seguridad en capas para secretos y sesiones | Sección FR-09 Seguridad en capas | T-02 incluye sección Seguridad en capas | Cubierto |
| FR-10 | Actualizar skill docker-patterns con sección Metodología transversal | Sección FR-10 Actualizar skill docker-patterns | T-01 Actualizar skill docker-patterns | Cubierto |

**Resultado:** Los diez FR están presentes en los tres artefactos. No existen requisitos huérfanos.

### 1.2 Criterios de éxito

Spec SC-01 a SC-06 están reflejados en plan.md sección Criterios de verificación y en tasks.md Criterios de cierre.

- SC-01 spec completa sin placeholders → Verificado en T-05.
- SC-02 FR-01 a FR-10 descritos → Verificado en plan.
- SC-03 restricciones explícitas → Plan sección Restricciones confirmadas.
- SC-04 sin claves reales → Plan Estrategia de testing verifica seguridad.
- SC-05 skill referenciada → T-01.
- SC-06 reutilizable sin configuraciones particulares → Plan Decisiones de diseño Solo metodología, cero configuración.

### 1.3 Alineación de entregables

- **Skill docker-patterns:** spec FR-10, plan Artefacto actualización skill, tasks T-01. Coherente.
- **Patrón transversal:** spec FR-01 a FR-09, plan Artefacto `docker-metodologia-transversal.md` en `Documentacion/Agents_IA_TECH/.doc_agents/patterns/`, tasks T-02 crea `docker-metodologia.md` en misma ruta base.
- **Checklist:** plan menciona `checklist.md` en `.../specs/022-docker-patterns-metodologia/checklist.md`. Tasks T-03 crea `docker-metodologia-checklist.md` en misma carpeta.
- **Agentes devops y arquitecto:** tasks T-04 actualiza definiciones. Plan no detalla esta tarea pero es compatible con dependencia de patrón.

### 1.4 Inconsistencias detectadas

**INCONSISTENCIA-01 - Nombre de archivo patrón transversal**
- plan.md línea 28 y 29: `docker-metodologia-transversal.md`
- tasks.md línea 24-25: `docker-metodologia.md`
- Severidad: MEDIA
- Impacto: Riesgo de enlace roto entre skill y documentación.
- Recomendación: Unificar nombre a `docker-metodologia-transversal.md` en tasks.md y referencias de agentes.

**INCONSISTENCIA-02 - Nombre de checklist**
- plan.md línea 22: `checklist.md`
- tasks.md línea 36: `docker-metodologia-checklist.md`
- Severidad: BAJA
- Impacto: Confusión operativa.
- Recomendación: Adoptar `docker-metodologia-checklist.md` como nombre canónico y actualizar plan.md.

**INCONSISTENCIA-03 - Ruta de patrón en referencia de skill**
- tasks T-01 línea 14-15 referencia `Documentacion/Agents_IA_TECH/.doc_agents/patterns/docker-metodologia.md`
- plan referencia `docker-metodologia-transversal.md`
- Severidad: MEDIA
- Recomendación: Normalizar referencia.

No se detectan duplicaciones de requisitos ni conflictos de terminología. La prioridad de configuración secret > env > default se mantiene homogénea.

---

## 2. ADRs referenciados

Búsqueda en spec.md, plan.md, tasks.md: no existen referencias explícitas a ADR.

Búsqueda global en `Documentacion/Agents_IA_TECH/arquitectura/adr/` por términos docker/secret:
- Ningún ADR documenta específicamente la metodología Docker transversal de la spec 022.
- ADRs relacionados indirectamente con seguridad de secretos:
  - adr-0010-opencode-v2-mcp-shape.md: R6 Credenciales fuera del archivo. Ni `.env` ni secretos en el JSON.
  - adr-0006-mcp-token-resolution.md: Manejo de `.env.mcp` en sección secrets.
  - adr-0004-post-plataformado-speckit.md: Evita indexar secrets en Graphify.

**Conclusión:** La spec 022 no referencia ADRs existentes. No hay conflicto con arquitectura. Se recomienda registrar en plan una referencia explícita a adr-0010 para alineación de principio credenciales fuera de archivo.

---

## 3. Threat Model de seguridad de secretos

**Activo:** Claves, tokens, passwords, certificados gestionados por proyectos del KIT.

**Amenazas identificadas:**

### security-risk-01 - Fuga por versionado de .env con valores reales
- **Vector:** Operador copia `.env.example` a `.env` y se versiona accidentalmente.
- **Impacto:** Exposición de secretos en repositorio.
- **Controles spec:** FR-01 `.env` nunca se versiona con valores reales, únicamente `.env.example` o `.env.template` con claves vacías. RNF-04 y Restricción `.env` solo plantilla.
- **Verificación:** Checklist debe confirmar ausencia de `.env` en git.

### security-risk-02 - Secreto expuesto en variable de entorno visible
- **Vector:** Pasar secretos mediante `environment:` en compose o variables visibles en proceso.
- **Impacto:** Lectura vía `docker inspect`, `ps e`, logs.
- **Controles spec:** FR-02 patrón env_or_secret con prioridad secret > env > default. FR-03 prohíbe pasar secretos por variables visibles. FR-09 permisos 600 en host.
- **Mitigación:** Entrypoint lee `/run/secrets/` primero y no registra valores en logs.

### security-risk-03 - Creación automática de directorio secrets por el KIT
- **Vector:** Script o agente genera `secrets/` con valores por defecto.
- **Impacto:** Falsa sensación de seguridad, posible escritura de secretos en disco no protegido.
- **Controles spec:** Restricción No crear directorio `secrets/` automáticamente. FR-03 creación manual por operador.
- **Verificación:** T-05 verifica ausencia de creación automática.

### security-risk-04 - Montaje completo del proyecto expone archivos sensibles
- **Vector:** Bind mount de directorio raíz incluye `.env`, `secrets/`, credenciales locales.
- **Impacto:** Acceso desde contenedor a secretos fuera de alcance.
- **Controles spec:** FR-06 montajes quirúrgicos, evitar montar raíz del proyecto.
- **Verificación:** Checklist lista rutas nunca montar.

### security-risk-05 - Logging de secretos
- **Vector:** Servicio imprime variables o contenido de secret en stdout/stderr.
- **Impacto:** Secreto persistente en driver de logs, agregadores, backups.
- **Controles spec:** FR-07 logging estructurado sin secretos. FR-02 entrypoint sin exponer valores en logs.
- **Mitigación:** Formato JSON clave-valor con rotación, prohibición explícita.

### security-risk-06 - Persistencia de sesiones en volúmenes compartidos
- **Vector:** Volumen compartido entre servicios almacena sesiones de usuario.
- **Impacto:** Escalada lateral, acceso a sesiones de otro entorno.
- **Controles spec:** FR-09 separación de sesiones por entorno, sesiones nunca en volúmenes compartidos.

### security-risk-07 - Rotación de secretos requiere cambio de código/compose
- **Vector:** Secreto codificado en compose o imagen.
- **Impacto:** Inmovilidad operativa, ventana de exposición prolongada.
- **Controles spec:** FR-09 rotación sin modificar código ni compose, uso exclusivo de Docker secrets.

**Modelo de confianza:**
- Operador es responsable de crear `secrets/` manualmente con permisos 600.
- Entrypoint es componente de confianza que lee secrets y genera config interna efímera.
- Compose es declaración de infraestructura, no almacén de secretos.
- `.env` es plantilla pública, nunca secreta.

---

## 4. Riesgos etiquetados

### security-risk: Fuga de secretos por .env versionado
- Severidad: CRÍTICA
- Origen: FR-01, Restricción
- Evidencia: spec.md línea 27, 69
- Mitigación: checklist ausencia de `.env` en git, `.env.example` con valores vacíos.

### security-risk: Exposición de secretos en variables de entorno visibles
- Severidad: ALTA
- Origen: FR-02, FR-03
- Evidencia: spec.md línea 30-33
- Mitigación: patrón env_or_secret, montaje `/run/secrets/`, prohibición de variables visibles.

### security-risk: Creación automática de secrets por el KIT
- Severidad: ALTA
- Origen: Restricción línea 65, FR-03
- Evidencia: spec.md línea 33, plan.md línea 39
- Mitigación: T-05 verificación de no creación automática.

### security-risk: Logs con secretos
- Severidad: ALTA
- Origen: FR-07
- Evidencia: spec.md línea 45
- Mitigación: logging estructurado, prohibición explícita, entrypoint sin log de valores.

### security-risk: Montajes completos del código en producción
- Severidad: MEDIA
- Origen: FR-06
- Evidencia: spec.md línea 41-43
- Mitigación: patrón de montajes quirúrgicos, checklist de rutas prohibidas.

### security-risk: Permisos laxos en archivos de secrets en host
- Severidad: MEDIA
- Origen: FR-09
- Evidencia: spec.md línea 51
- Mitigación: permisos 600, documentación de seguridad en capas.

### security-risk: Divergencia de nombre de artefacto patrón transversal
- Severidad: MEDIA
- Origen: INCONSISTENCIA-01
- Impacto: enlaces rotos entre skill y documentación.
- Mitigación: unificar nombre.

### security-risk: Setup idempotente que lista secrets esperados
- Severidad: BAJA
- Origen: FR-08
- Evidencia: spec.md línea 47-49
- Nota: el script debe listar nombres de secrets esperados sin crearlos ni leer su contenido.

---

## 5. Verificación de restricciones

### Restricción R1: No crear docker-compose.yml ni directorio secrets automáticamente
- spec.md línea 65: No crear `docker-compose.yml` ni directorio `secrets/` automáticamente en nuevos proyectos.
- plan.md línea 35: Solo metodología, cero configuración.
- plan.md línea 39: Creación manual de secrets.
- tasks T-02 Criterios de aceptación línea 30: Se prohíbe creación automática de directorio `secrets/` e indica creación manual.
- tasks T-05 Criterios de aceptación línea 60: No se genera docker-compose.yml ni directorio secrets automáticamente.
- **Verificación:** CUMPLE. Ningún artefacto describe generación automática.

### Restricción R2: No incluir claves reales ni ejemplos de .env con datos sensibles
- spec.md RNF-03: Ejemplos genéricos sin claves reales.
- spec.md línea 66: No incluir claves reales ni ejemplos de `.env` con datos sensibles.
- plan.md línea 37: Plantilla `.env` únicamente con claves vacías.
- tasks T-01 Criterios línea 19: Ejemplos usan nombres genéricos `API_KEY`, `DB_PASSWORD` sin valores reales.
- tasks T-02 Criterios línea 28: `.env.example` con claves vacías y comentarios.
- **Verificación:** CUMPLE. No existen ejemplos sensibles en spec, plan, tasks.

### Restricción R3: Solo metodología, no configuraciones particulares de Boleteria Cardenales
- spec.md línea 67: Solo metodología, no configuraciones particulares.
- plan.md línea 13: No se crea docker-compose.yml ni directorio secrets automáticamente.
- **Verificación:** CUMPLE.

### Restricción R4: Contenido completo sin placeholders
- spec.md RNF-02: Contenido completo sin placeholders, TBD, TODO, pendiente o N/A.
- plan.md Verificación de completitud: revisar ausencia de placeholders.
- tasks T-05 Criterios línea 59: No existen cadenas TBD, TODO, pendiente, por definir, N/A, XXX.
- **Verificación:** Los tres artefactos no contienen placeholders visibles. Se recomienda auditoría automática de cadenas prohibidas antes de implementación.

### Restricción R5: .env se usa solo como plantilla, nunca con valores reales versionados
- spec.md línea 69: `.env` se usa solo como plantilla, nunca con valores reales versionados.
- spec FR-01 línea 27: `.env` nunca se versiona con valores reales.
- plan.md línea 37: `.env.example` con claves vacías.
- **Verificación:** CUMPLE.

### Restricción R6: No generar archivos de configuración
- spec fuera de alcance línea 73-76: No generar `docker-compose.yml` específicos por proyecto, no crear o poblar directorios `secrets/`.
- plan Restricciones confirmadas línea 146-147.
- **Verificación:** CUMPLE.

---

## 6. Resumen de hallazgos

- **Cobertura:** 10/10 FR cubiertos en spec, plan y tasks.
- **Consistencia:** Alta. Dos inconsistencias menores de nomenclatura de archivos.
- **Seguridad:** Threat model cubre vectores principales de fuga de secretos. Controles alineados con FR-01 a FR-09.
- **Restricciones:** Todas verificadas como cumplidas en los artefactos actuales.
- **ADRs:** Ninguna referencia explícita. No hay conflicto.

**Próximos pasos recomendados:**
1. Unificar nombre de artefacto patrón transversal a `docker-metodologia-transversal.md` en tasks.md y referencias.
2. Unificar nombre de checklist a `docker-metodologia-checklist.md` en plan.md.
3. Añadir referencia explícita a adr-0010-opencode-v2-mcp-shape.md R6 en plan como práctica de credenciales fuera de archivo.
4. Ejecutar auditoría automatizada de cadenas prohibidas TBD/TODO/pendiente/N/A/XXX antes de `/speckit-implement`.

---

*Fin de análisis speckit 022-docker-patterns-metodologia.*
