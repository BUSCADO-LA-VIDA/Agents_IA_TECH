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

## Acciones de nivelación

| Acción | Descripción |
|--------|-------------|
| `crear_archivo` | Crear archivo faltante **desde plantilla incluida en el agente**. Cada archivo de Documentacion/ tiene su plantilla por defecto |
| `actualizar_agente` | Reemplazar `.agent.md` por versión nueva |
| `instalar_mcp` | Ejecutar comando de instalación de MCP server |
| `crear_estructura` | Crear carpetas faltantes (`Documentacion/adr/`, `Documentacion/agents/<nombre>/`) |
| `registrar_capacidad` | Marcar en memoria que una capacidad está presente |
| `eliminar_obsoleto` | Preguntar antes de borrar archivos que ya no aplican |

## Archivos que puede crear desde plantilla

| Archivo | Plantilla incluida |
|---------|-------------------|
| `Documentacion/00-indice.md` | ✅ Sí — en el agente |
| `Documentacion/idioma.md` | ✅ Sí — en el agente |
| `Documentacion/preferencias.md` | ✅ Sí — en el agente |
| `Documentacion/preferencias-git.md` | ✅ Sí — en el agente |
| `Documentacion/referencias.md` | ✅ Sí — en el agente |
| `Documentacion/roadmap.md` | ✅ Sí — en el agente |
| `Documentacion/pendientes-implementacion.md` | ✅ Sí — en el agente |
| `Documentacion/soluciones-conocidas.md` | ✅ Sí — en el agente |
| `Documentacion/capacidad-base.md` | ✅ Sí — en el agente |
| `Documentacion/memoria-proyecto.md` | ✅ Sí — en el agente |
