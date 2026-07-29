# Spec: Agente `devops`

> **Propósito**: Configurar infraestructura, Docker, CI/CD y despliegues.

## Reglas fundamentales

**REUTILIZAR antes de crear**: buscar en el código existente antes de escribir algo nuevo.

**.gitattributes obligatorio**: al iniciar o modificar un proyecto, verificar que exista `.gitattributes` en la raíz con reglas `text eol=lf` para archivos Linux: `.dockerignore`, `.env.example`, `Dockerfile`, `Dockerfile-*`, `docker-compose.yml`, `init.sh`, `init-freeradius.sh`, `contrib/docker/*.conf`. Si no existe, crearlo.

## Skills utilizados

- `docker-patterns`
- `deployment-patterns`
- `kubernetes-patterns`
- `uncloud`
- `postgres-patterns`

**Restricción**: No implementar nada que no esté documentado primero.
