# Spec: Agente `plataformador`

> **Propósito**: Auditar, nivelar y replataformar proyectos para mantener la estructura de capacidades del kit de agentes.

## Flujo

1. Leer `capacidad-base.md`
2. Leer `memoria-proyecto.md` (si existe)
3. Auditar proyecto actual
4. **Si el proyecto es nuevo o no tiene Documentacion/ → preguntar datos al usuario**:
   - Nombre del proyecto, stack, lenguaje, BD, framework
   - Idioma para docs y commits
   - Rama principal
5. Generar informe de brecha
6. Proponer nivelación y preguntar antes de ejecutar
7. Crear archivos usando las plantillas con los datos recopilados
8. Actualizar `memoria-proyecto.md`
9. Preguntar por commit

## Disparadores

- `pensador` lo invoca al detectar proyecto nuevo o recién copiado
- El usuario dice "replataforma este proyecto"
- El usuario dice "actualiza mis agentes"
- Detecta que `capacidad-base.md` cambió desde la última auditoría
- **Siempre que se ejecuta**, verifica estructura de Documentacion/ contra `.doc_agents/estructura-estandar.md` (carpeta oculta con punto, raíz del repo)

## Verificación de estructura

Cada ejecución del plataformador debe:

1. Leer `.doc_agents/estructura-estandar.md` (documentación transversal)
2. Comparar la estructura real de `Documentacion/` contra el estándar
3. Detectar archivos fuera de lugar, carpetas faltantes, archivos huérfanos
4. Si hay diferencias → preguntar al usuario si reorganizar
5. Si reorganiza → mover archivos, actualizar 00-indice.md, registrar en memoria

## Acciones de nivelación

| Acción | Descripción |
|--------|-------------|
| `crear_archivo` | Crear archivo faltante **desde plantilla incluida en el agente** |
| `actualizar_agente` | Reemplazar `.agent.md` por versión nueva |
| `instalar_mcp` | Ejecutar comando de instalación de MCP server (`npm install -g`, `codebase-memory-mcp install`) |
| `crear_estructura` | Crear carpetas faltantes |
| `registrar_capacidad` | Marcar en memoria que una capacidad está presente |
| `eliminar_obsoleto` | Preguntar antes de borrar archivos que ya no aplican |
| `retroalimentar_pensador` | Dejar tarea en pendientes-implementacion.md para que pensador ajuste agentes |
| `reorganizar_docs` | Reestructurar documentación existente al formato agents/<nombre>/spec.md |

## Flujo MCP

1. Detectar qué MCP servers están disponibles globalmente
2. Comparar contra capacidad-base.md
3. Preguntar al usuario: "¿Cuáles querés instalar?" (con checkboxes)
4. Instalar los seleccionados
5. Registrar decisión en memoria-proyecto.md (instalado o rechazado)
6. Agregar tarea en pendientes-implementacion.md para que pensador ajuste agentes

## Flujo reorganización docs

1. Leer `.doc_agents/estructura-estandar.md` (fuente de verdad transversal)
2. Detectar si el proyecto tiene `Documentacion/<proyecto>/` con la estructura BASE:
   - 8 archivos raíz (00-indice, idioma, preferencias, etc.)
   - 4 carpetas base obligatorias: `arquitectura/`, `funcionalidades/`, `agents/`, `bitacoras/`
   - 3 carpetas base opcionales: `testing/`, `seguridad/`, `despliegue/` (solo se crean si el proyecto tiene contenido para ellas)
3. Si faltan carpetas base obligatorias → crearlas (aunque estén vacías)
4. Si faltan carpetas base opcionales → NO crear automáticamente; se crean cuando algún agente produzca contenido que vaya allí
4. Si `adr/` está en la raíz → mover a `arquitectura/adr/`
5. Si hay `agentes/` → renombrar a `agents/` (inglés)
6. Detectar archivos sueltos en la raíz que no sigan el formato
7. Proponer al usuario reorganizar
8. Mover archivos a sus carpetas correspondientes
9. Actualizar 00-indice.md y memoria-proyecto.md

### Estructura BASE (propuesta para todos los proyectos)

```
Documentacion/<proyecto>/
├── 00-indice.md
├── idioma.md
├── preferencias.md
├── preferencias-git.md
├── referencias.md
├── roadmap.md
├── pendientes-implementacion.md
├── soluciones-conocidas.md
├── arquitectura/
│   ├── adr/
│   └── diagramas/
├── funcionalidades/
├── agents/
├── bitacoras/
│
├── testing/          ← opcional (solo si hay contenido)
├── seguridad/        ← opcional (solo si hay contenido)
└── despliegue/       ← opcional (solo si hay contenido)
```

### Reglas de reorganización

1. Las 4 carpetas base obligatorias **siempre se crean** desde el inicio del proyecto, aunque estén vacías. Las 3 opcionales (`testing/`, `seguridad/`, `despliegue/`) solo se crean cuando haya contenido que colocar en ellas.
2. `adr/` vive dentro de `arquitectura/adr/` — nunca en la raíz
3. `agents/` se nombra en inglés — nunca `agentes/`
4. Si una carpeta base necesita subcarpetas (ej: `testing/e2e/`), se crean dentro de la carpeta base, nunca en la raíz
5. Los archivos raíz son los únicos permitidos en la raíz de `Documentacion/<proyecto>/` — todo lo demás va en una carpeta base
6. Si el proyecto tiene estructura distinta → preguntar al usuario antes de reorganizar, nunca asumir

## Archivos que puede crear desde plantilla

| Archivo | Plantilla incluida |
|---------|-------------------|
| `Documentacion/<proyecto>/00-indice.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/idioma.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/preferencias.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/preferencias-git.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/referencias.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/roadmap.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/pendientes-implementacion.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/soluciones-conocidas.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/agents/plataformador/capacidad-base.md` | ✅ Sí — en el agente |
| `Documentacion/<proyecto>/agents/plataformador/memoria-proyecto.md` | ✅ Sí — en el agente |

### Carpetas base obligatorias (siempre se crean, sin plantilla)

| Carpeta | Contenido inicial |
|---------|-------------------|
| `arquitectura/adr/` | Vacía — el arquitecto crea los ADRs |
| `arquitectura/diagramas/` | Vacía — el arquitecto crea los diagramas |
| `funcionalidades/` | Vacía — el documentador crea las specs |
| `agents/` | Vacía — se puebla con specs de agentes |
| `bitacoras/` | Vacía — el solucionador la puebla |

### Carpetas base opcionales (solo se crean si hay contenido)

| Carpeta | Quién la puebla | Cuándo se crea |
|---------|-----------------|----------------|
| `testing/` | `qa-senior` — tests automatizados | Se crea cuando `qa-senior` genere el primer test |
| `seguridad/` | `security-auditor` — auditorías | Se crea cuando `security-auditor` genere la primera auditoría |
| `despliegue/` | `devops` — infraestructura | Se crea cuando `devops` genere el primer documento de despliegue |
