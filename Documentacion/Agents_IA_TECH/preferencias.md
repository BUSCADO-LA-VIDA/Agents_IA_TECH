# Preferencias del Usuario - Agents_IA_TECH

> **Memoria del proyecto.** Este archivo almacena las preferencias, reglas y decisiones del usuario para que los agentes mantengan el comportamiento entre sesiones.
> Los agentes deben **leerlo al inicio de cada sesión** y actualizarlo cuando el usuario exprese una nueva preferencia.

## Reglas activas

| Fecha | Regla | Categoría |
|-------|-------|-----------|
| 2026-07-25 | **Por defecto, subir a la rama original (master/main)**. No crear ramas nuevas sin preguntar explícitamente. | git |
| 2026-07-25 | **Toda decisión del usuario debe guardarse en un archivo.** Sin archivo no hay memoria. | workflow |
| 2026-07-25 | **Los comandos de git deben usar sintaxis de PowerShell** (`#` para comentarios, no `::`). | git |
| 2026-07-25 | **Todos los commits deben incluir la nota de atribución de IA al final del cuerpo.** Texto oficial registrado en el agente gitflow. | git |
| 2026-07-25 | **El inglés no es mi lengua nativa** — me apoyo en IA para redactar y comunicar ideas. | workflow |
| 2026-07-27 | **Estructura de Documentacion/**: `adr/` va dentro de `arquitectura/adr/`. `agents/` en inglés (no `agentes/`). `testing/`, `seguridad/`, `despliegue/` son carpetas opcionales — solo se crean si hay contenido. Las specs funcionales van en `specs/` (speckit). | estructura |
| 2026-07-29 | **.gitattributes obligatorio en todo proyecto**: agregar reglas `text eol=lf` para archivos Linux (`.dockerignore`, `.env.example`, `Dockerfile`, `Dockerfile-*`, `docker-compose.yml`, `init.sh`, `init-freeradius.sh`, `contrib/docker/*.conf`). Todos los implementadores deben verificar/crear este archivo al tocar un proyecto. | setup |
| 2026-08-05 | **Idioma de comunicación = Español Latino (neutro)**: el usuario quiere que todos los agentes le hablen en español latino neutro (sin regionalismos marcados de ningún país). | comunicación |
| 2026-08-05 | **Enlazar commits al terminar la implementación**: el usuario quiere que, una vez implementado, se generen los comandos de commit (convencionales) para registrar los cambios. El `gitflow` se encarga de esto al final del ciclo. | git |
| 2026-08-30 | **Estructura de documentación por aplicación**: Cada app tiene su propia carpeta `Documentacion/<AppName>/` aislada. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) se sincroniza con `sync-agents.ps1`. NUNCA se copia `Documentacion/<AppName>/` entre apps. | estructura |
| 2026-08-30 | **Pensador = Orquestador que complementa Specify**: No duplica Specify. Specify maneja spec generation/validation/plan/code/template/versioning/linking/guardrails/orchestration/feedback. Mis agentes añaden: SSH debugging, plataformador (auditoría/nivelación), gitflow (commits), orchestración cross-agent. | arquitectura |
| 2026-08-30 | **Persistencia de sesiones**: Guardar análisis/decisiones en disco. Al reiniciar VS Code, usar como base conceptual antes de borrar. Preguntar antes de borrar ("¿Querés guardar esta propuesta?"). | workflow |
| 2026-08-30 | **Ciclo obligatorio**: Plan aprobado → Documentar → Implementar. Siempre en ese orden. | workflow |
| 2026-08-30 | **Plataformador organiza documentación**: Es el agente que permite organizar la documentación del proyecto. | arquitectura |

## Historial de cambios

| Fecha | Descripción |
|-------|-------------|
| 2026-07-25 | Creación inicial. Reglas de git y persistencia de comportamiento. |
| 2026-08-05 | Añadidas preferencias de idioma (español latino neutro) y enlazado de commits tras implementación. |
| 2026-08-30 | Reestructuración: Pensador complementa Specify, persistencia de sesiones, ciclo obligatorio plan-doc-impl, plataformador organiza docs. |
| 2026-09-05 | **Ciclo Plan→Doc→Impl siempre vigente**: NUNCA permitir saltar de Plan a Implementar sin Documentar, NUNCA saltar de Documentar a Implementar sin confirmación del usuario, NUNCA permitir "solo ajustes" sin volver a Documentar si es necesario, SIEMPRE volver a Documentar si hay cambios de visión o errores. El orden es sagrado: Plan aprobado → Documentar → Implementar (siempre en ese orden) | workflow |
| 2026-09-05 | **Detección de causa raíz en debugging**: Siempre buscar causa raíz, no ajustes superficiales. Si error reaparece → regresar a causa raíz documentada, no a ajustes parciales. Documentar el fix siempre. | debugging |
| 2026-09-05 | **Reinicio automático al cambio de visión**: Si el usuario cambia de visión en cualquier punto del proceso → REINICIAR el ciclo completo desde el análisis inicial | workflow |
| 2026-09-05 | **Agente de dependencias externas**: El agente `upgrade_framework` se encarga de mantener actualizadas de forma segura las dependencias de proyectos comunitarios (spec-kit, graphify, etc.). Usa IA solo para analizar cómo los cambios afectan la integración existente, nunca repite flujos completos de análisis. | mantenimiento |