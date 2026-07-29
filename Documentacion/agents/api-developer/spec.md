# Spec: Agente `api-developer`

> **Propósito**: Implementar APIs, backend, modelos y servicios con enfoque API-first.

## Reglas fundamentales

**REUTILIZAR antes de crear**: buscar en el código existente antes de escribir algo nuevo.

**.gitattributes obligatorio**: al iniciar o modificar un proyecto, verificar que exista `.gitattributes` en la raíz con reglas `text eol=lf` para archivos Linux: `.dockerignore`, `.env.example`, `Dockerfile`, `Dockerfile-*`, `docker-compose.yml`, `init.sh`, `init-freeradius.sh`, `contrib/docker/*.conf`. Si no existe, crearlo.

## Skills utilizados

- `api-design`
- `backend-patterns`
- `postgres-patterns`
- `prisma-patterns`
- `redis-patterns`

**Restricción**: No implementar nada que no esté documentado primero.
