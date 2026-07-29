# Preferencias del Usuario

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
| 2026-07-27 | **Estructura de Documentacion/**: `adr/` va dentro de `arquitectura/adr/`. `agents/` en inglés (no `agentes/`). `testing/`, `seguridad/`, `despliegue/` son carpetas opcionales — solo se crean si hay contenido. Las specs funcionales van en `funcionalidades/`. | estructura |
| 2026-07-29 | **.gitattributes obligatorio en todo proyecto**: agregar reglas `text eol=lf` para archivos Linux (`.dockerignore`, `.env.example`, `Dockerfile`, `Dockerfile-*`, `docker-compose.yml`, `init.sh`, `init-freeradius.sh`, `contrib/docker/*.conf`). Todos los implementadores deben verificar/crear este archivo al tocar un proyecto. | setup |

## Historial de cambios

| Fecha | Descripción |
|-------|-------------|
| 2026-07-25 | Creación inicial. Reglas de git y persistencia de comportamiento. |
