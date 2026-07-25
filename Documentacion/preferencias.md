# Preferencias del Usuario

> **Memoria del proyecto.** Este archivo almacena las preferencias, reglas y decisiones del usuario para que los agentes mantengan el comportamiento entre sesiones.
> Los agentes deben **leerlo al inicio de cada sesión** y actualizarlo cuando el usuario exprese una nueva preferencia.

## Reglas activas

| Fecha | Regla | Categoría |
|-------|-------|-----------|
| 2026-07-25 | **Por defecto, subir a la rama original (master/main)**. No crear ramas nuevas sin preguntar explícitamente. | git |
| 2026-07-25 | **Toda decisión del usuario debe guardarse en un archivo.** Sin archivo no hay memoria. | workflow |
| 2026-07-25 | **Los comandos de git deben usar sintaxis de PowerShell** (`#` para comentarios, no `::`). | git |

## Historial de cambios

| Fecha | Descripción |
|-------|-------------|
| 2026-07-25 | Creación inicial. Reglas de git y persistencia de comportamiento. |
