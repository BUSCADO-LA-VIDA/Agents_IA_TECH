# Feature Specification: 022-docker-patterns-metodologia — Patrones Docker transversales de metodología para el KIT

**Feature Branch**: `022-docker-patterns-metodologia`
**Created**: 2026-10-21
**Status**: Borrador
**Input**: Requisitos del usuario para estandarizar metodología Docker transversal basada en buenas prácticas extraídas de Boleteria Cardenales, sin configuraciones particulares ni claves sensibles.

---

## Problema

Las implementaciones del KIT usan Docker de forma heterogénea. Existen configuraciones específicas por proyecto, manejo inconsistente de secretos, edición manual de `.env`, montajes completos del código y falta de estándar para logging y recreación de contenedores. Esto genera riesgo de fuga de secretos, entornos no reproducibles y dificultad de mantenimiento. Se requiere una metodología transversal, aplicable a todas las implementaciones, que documente patrones seguros y reutilizables sin imponer configuraciones particulares.

## Objetivos

- Definir una metodología Docker transversal aplicable a todos los proyectos del KIT.
- Asegurar multi-entorno con el mismo código y uso de `.env` únicamente como plantilla.
- Establecer patrón unificado env_or_secret sin secretos en `.env`.
- Normalizar uso de Docker secrets como única vía para claves sensibles.
- Documentar entrypoint para configuración dinámica y evitar edición manual.
- Establecer criterios para recreación de contenedor, montajes quirúrgicos, logging estructurado y setup idempotente.
- Actualizar la skill `docker-patterns` con una sección de Metodología transversal.

## Requisitos funcionales

### FR-01: Documentar metodología multi-entorno con mismo código y .env solo como plantilla
La especificación debe describir el principio de un único `docker-compose.yml` por servicio y variación de entorno exclusivamente mediante variables de entorno. Se debe documentar que el archivo `.env` nunca se versiona con valores reales, únicamente existe `.env.example` o `.env.template` con claves vacías y comentarios descriptivos. El cambio de entorno se realiza cambiando el archivo `.env` local o las variables del host, sin modificar el código ni el compose.

### FR-02: Documentar patrón de configuración unificada env_or_secret con prioridad y sin secretos en .env
Se debe documentar el patrón `env_or_secret` que permite leer una variable desde entorno o desde Docker secret con prioridad definida: secret > env > default. La documentación debe indicar que `.env` solo contiene valores no sensibles y que cualquier valor sensible debe pasarse vía secret. Se debe incluir regla de prioridad y ejemplo de implementación en entrypoint sin exponer valores en logs.

### FR-03: Documentar uso de Docker secrets como única vía para claves sensibles
La especificación debe establecer que claves, tokens, passwords y certificados se gestionan exclusivamente mediante Docker secrets. Se debe documentar la creación manual del directorio `secrets/` por el operador, nunca automática por el KIT, y el montaje de secrets en `/run/secrets/` dentro del contenedor. Se prohíbe montar archivos `.env` con secretos y se prohíbe pasar secretos por variables de entorno visibles.

### FR-04: Documentar entrypoint para configuración dinámica sin edición manual
Se debe documentar un entrypoint estándar que al iniciar el contenedor lea variables de entorno, valide presencia de secrets, genere archivos de configuración internos y aplique defaults seguros. El entrypoint evita editar manualmente archivos dentro del contenedor y permite que cambios de entorno se apliquen con recreación del contenedor. Se debe describir el flujo de inicialización, validación y salida en caso de error.

### FR-05: Documentar recreación de contenedor para aplicar cambios de entorno
La especificación debe documentar que cualquier cambio en variables de entorno, secrets o archivos de configuración montados requiere `docker compose up -d --force-recreate` o equivalente. Se debe explicar por qué no basta con `up -d` y documentar el comando estándar para aplicar cambios de manera segura y reproducible.

### FR-06: Documentar montajes quirúrgicos y evitar mounts completos
Se debe documentar la práctica de montar únicamente los volúmenes necesarios: código fuente en desarrollo con montaje puntual, volúmenes nombrados para persistencia de datos, y evitar montar el directorio raíz del proyecto o directorios completos. Se debe indicar qué rutas montar, qué rutas nunca montar y cómo definir volúmenes en compose para propósitos de desarrollo y producción.

### FR-07: Documentar logging estructurado por servicio
La especificación debe establecer que cada servicio debe emitir logs en formato estructurado JSON o texto clave-valor con nivel, servicio y timestamp. Se debe documentar la configuración de `logging` en docker-compose para usar el driver `json-file` con rotación, y la recomendación de centralizar logs con un servicio de agregación opcional. Se debe prohibir logs con secretos.

### FR-08: Documentar setup idempotente con scripts
Se debe documentar scripts de setup idempotentes que inicialicen el entorno: crear red Docker, verificar dependencias, validar presencia de `.env.template`, listar secrets esperados sin crearlos, y ejecutar health checks. Los scripts deben poder ejecutarse múltiples veces sin efectos colaterales y deben devolver códigos de salida claros.

### FR-09: Documentar seguridad en capas para secretos y sesiones
La especificación debe documentar capas de seguridad: secretos fuera del contenedor, permisos 600 en archivos de secrets en host, uso de Docker secrets en lugar de variables, rotación de secrets sin modificar código, y separación de sesiones por entorno. Se debe indicar que las sesiones de usuario nunca se almacenan en volúmenes compartidos entre servicios.

### FR-10: Actualizar skill docker-patterns con sección Metodología transversal
Se debe actualizar la skill `docker-patterns` para incluir una sección `Metodología transversal` que resuma los patrones FR-01 a FR-09 con referencias a esta spec. La skill debe mantener ejemplos genéricos sin claves reales ni configuraciones particulares de Boleteria Cardenales.

## Requisitos no funcionales

- **RNF-01**: Documentación en español latino neutro, sin jerga regional.
- **RNF-02**: Contenido completo sin placeholders, TBD, TODO, pendiente o N/A.
- **RNF-03**: Ejemplos deben ser genéricos, sin claves reales ni datos sensibles.
- **RNF-04**: La spec no genera archivos de configuración ni crea directorios `secrets/` automáticamente.

## Restricciones

- No crear `docker-compose.yml` ni directorio `secrets/` automáticamente en nuevos proyectos.
- No incluir claves reales ni ejemplos de `.env` con datos sensibles.
- Solo metodología, no configuraciones particulares de Boleteria Cardenales.
- El contenido debe estar completo, sin placeholders.
- `.env` se usa solo como plantilla, nunca con valores reales versionados.

## Fuera de alcance

- Generar `docker-compose.yml` específicos por proyecto.
- Crear o poblar directorios `secrets/` con valores reales.
- Documentar stack tecnológico particular de Boleteria Cardenales.
- Implementar scripts de setup; solo documentar metodología.
- Configurar orquestadores externos como Kubernetes o Swarm.

## Dependencias

- Skill `docker-patterns` existente en el KIT.
- Acceso a la metodología base extraída de Boleteria Cardenales para buenas prácticas.
- Constitución del KIT y reglas de seguridad de secretos.

## Criterios de éxito

- **SC-01**: `spec.md` creado en `Documentacion/Agents_IA_TECH/specs/022-docker-patterns-metodologia/spec.md` con todas las secciones completas y sin placeholders.
- **SC-02**: FR-01 a FR-10 están descritos con criterios claros y verificables.
- **SC-03**: Las restricciones están explícitas y no se viola ninguna al redactar la spec.
- **SC-04**: No existen ejemplos con claves reales ni `.env` con datos sensibles.
- **SC-05**: La skill `docker-patterns` queda referenciada para actualización en FR-10.
- **SC-06**: La spec es reutilizable para todas las implementaciones del KIT sin configuraciones particulares.

---

*Fin de Spec 022 – Patrones Docker transversales de metodología.*
