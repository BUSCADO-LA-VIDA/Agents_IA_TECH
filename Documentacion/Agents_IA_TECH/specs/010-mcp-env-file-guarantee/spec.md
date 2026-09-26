# Feature Specification: [MCP-ENV-FILE-GUARANTEE] — Creación garantizada del archivo .env.mcp en bootstrap

**Feature Branch**: `010-mcp-env-file-guarantee`

**Created**: 2026-09-24

**Status**: Draft

**Input**: El usuario reportó que el bootstrap (`scripts/plataformador-bootstrap.ps1`) no crea el archivo `.env.mcp` en proyectos nuevos cuando falta, lo que puede causar fallos en la resolución de rutas de MCPs. Se requiere que el bootstrap garantice la existencia de `.env.mcp` con variables básicas, independientemente del flujo, y permita actualización forzada con `--force`.

## Problema

En proyectos totalmente nuevos donde el archivo `.env.mcp` no existe, el bootstrap actual puede no crearlo correctamente o dejarlo con valores vacíos, provocando que:
1. Las resoluciones de tokens `{env:...}` en `opencode.json` fallen al no encontrar las variables
2. Los MCPs no se habiliten correctamente por falta de rutas resueltas
3. Se requiera intervención manual del usuario para crear y poblar el archivo

Esto rompe la promesa de "bootstrap listo para usar" y aumenta la fricción de puesta en marcha.

## Objetivos

- **Creación garantizada**: El bootstrap DEBE crear `.env.mcp` si no existe, en cualquier punto de su ejecución
- **Variables básicas**: El archivo creado debe contener al mínimo las variables para los MCPs core del kit
- **Idempotencia**: Ejecutar el bootstrap múltiples veces no debe corromper un `.env.mcp` existente válido
- **Actualización forzada**: El flag `--force` DEBE permitir sobrescribir `.env.mcp` con la plantilla básica
- **Independencia del flujo**: La creación/garantía de `.env.mcp` debe ocurrir temprano en el bootstrap, antes de cualquier resolución de MCP

## Escenarios de Usuario y Testing

### Historia de Usuario 1 - Creación en proyecto nuevo (Prioridad: P1)

Como usuario del kit, quiero que al clonar el kit en un directorio nuevo y ejecutar el bootstrap por primera vez, el archivo `.env.mcp` se cree automáticamente con las variables básicas, para no tener que crearlo manualmente.

**Por qué esta prioridad**: Es esencial para la experiencia de "out-of-the-box". Sin ella, los usuarios nuevos encuentran fallos inmediatos.

**Prueba independiente**: Puede verificarse eliminando `.env.mcp` y ejecutando el bootstrap; el archivo debe aparecer con contenido.

**Escenarios de aceptación**:

1. **Given** un proyecto sin `.env.mcp`, **When** se ejecuta `plataformador-bootstrap.ps1`, **Then** se crea `.env.mcp` en la raíz del proyecto
2. **Given** un proyecto sin `.env.mcp`, **When** se ejecuta el bootstrap, **Then** el archivo contiene al menos las variables `CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`
3. **Given** un proyecto sin `.env.mcp`, **When** se ejecuta el bootstrap, **Then** no se requieren pasos manuales para crear el archivo

### Historia de Usuario 2 - Actualización forzada con --force (Prioridad: P2)

Como usuario del kit, quiero usar el flag `--force` con el bootstrap para regenerar `.env.mcp` con la plantilla básica, útil para corregir configuraciones corruptas o restablecer valores.

**Por qué esta prioridad**: Proporciona una manera segura de recuperar un estado conocido bueno sin eliminar manualmente el archivo.

**Prueba independiente**: Puede verificarse modificando `.env.mcp` y ejecutando el bootstrap con `--force`; el archivo debe volver a la plantilla básica.

**Escenarios de aceptación**:

1. **Given** un `.env.mcp` existente con valores personalizados, **When** se ejecuta `plataformador-bootstrap.ps1 -Force`, **Then** el archivo se sobrescribe con la plantilla básica
2. **Given** un `.env.mcp` corrupto o vacío, **When** se ejecuta el bootstrap con `--force`, **Then** el archivo se reemplaza por una versión válida
3. **Given** un `.env.mcp` válido, **When** se ejecuta el bootstrap sin `--force`, **Then** el archivo se conserva sin cambios

### Historia de Usuario 3 - Integración temprana en el flujo (Prioridad: P2)

Como usuario del kit, quiero que la garantía de existencia de `.env.mcp` ocurra temprano en el bootstrap, antes de cualquier intento de resolver rutas de MCPs, para asegurar que las subsiguientes etapas tengan el inventario disponible.

**Por qué esta prioridad**: Evita condiciones de carrera donde etapas posteriores asumen que `.env.mcp` existe pero aún no ha sido creado.

**Prueba independiente**: Puede verificarse revisando el orden de llamadas en el bootstrap y asegurando que `Ensure-McpEnvFile` se ejecuta antes de `Ensure-OpenCodeMcp` y otras funciones que dependen de `.env.mcp`.

**Escenarios de aceptación**:

1. **Given** el bootstrap ejecutándose, **When** se revisa el flujo de ejecución, **Then** `Ensure-McpEnvFile` se llama antes de cualquier función que lea desde `.env.mcp`
2. **Given** un proyecto sin `.env.mcp`, **When** se ejecuta el bootstrap, **Then** ninguna función falla por falta de `.env.mcp` durante su ejecución

## Requisitos

### Requisitos Funcionales

- **FR-001**: El bootstrap DEBE crear `.env.mcp` si no existe en la raíz del proyecto
- **FR-002**: El `.env.mcp` creado DEBE contener al menos las variables para `context-mode`, `codebase-memory-mcp` y `markitdown`
- **FR-003**: El bootstrap DEBE ser idempotente: ejecutarlo múltiples veces con un `.env.mcp` válido existente NO debe alterar su contenido útil
- **FR-004**: El bootstrap CON el flag `--force` DEBE sobrescribir `.env.mcp` con la plantilla básica de variables
- **FR-005**: La creación/garantía de `.env.mcp` DEBE ocurrir antes de cualquier función que intente resolver rutas de MCPs o leer desde el archivo

### Entidades Clave

- **`scripts/plataformador-bootstrap.ps1`**: Script de bootstrap que debe garantizar `.env.mcp`
- **`Ensure-McpEnvFile`**: Función interna responsable de la creación/garantía del archivo
- **`.env.mcp`**: Archivo de entorno gitignored que almacena las rutas de los MCPs
- **`--force`**: Flag del bootstrap que controla el comportamiento de sobrescritura

## Criterios de Éxito

### Resultados Medibles

- **SC-001**: En un proyecto nuevo sin `.env.mcp`, el bootstrap lo crea en <1 segundo
- **SC-002**: Tras la creación por bootstrap, `.env.mcp` contiene las 3 variables básicas con formato `NAME=value` (valores pueden estar vacíos inicialmente para ser resueltos en tiempo de ejecución)
- **SC-003**: Ejecutar el bootstrap 5 veces seguidas en un proyecto sin cambios no altera el contenido significativo de `.env.mcp`
- **SC-004**: Ejecutar el bootstrap con `--force` sobrescribe `.env.mcp` con la plantilla básica independientemente de su contenido previo
- **SC-005**: En el flujo de bootstrap, `Ensure-McpEnvFile` se ejecuta antes de `Ensure-OpenCodeMcp` y cualquier función que resuelva `{env:...}` desde `.env.mcp`

## Supuestos

- El usuario tiene permisos de escritura en la raíz del proyecto para crear `.env.mcp`
- El bootstrap se ejecuta en PowerShell 7+ en Windows
- Las variables en `.env.mcp` inicialmente pueden estar vacías o con placeholders; su resolución completa ocurre en etapas posteriores del bootstrap (vía `Ensure-OpenCodeMcp` y resolución de tokens)
- El formato de `.env.mcp` es `NAME=value` por línea, compatible con estándares de archivos `.env`

## Nota de Implementación

Esta feature asegura la **existencia y formato básico** de `.env.mcp`. La **población de valores reales** (rutas específicas del sistema) continúa siendo responsabilidad de funciones posteriores como `Ensure-OpenCodeMcp` que resuelven los comandos de MCPs y actualizan las variables en el archivo. Esta separación de responsabilidades mantiene el principio de responsabilidad única: `Ensure-McpEnvFile` asegura que el archivo exista con la estructura correcta; otras funciones aseguran que contenga valores útiles.