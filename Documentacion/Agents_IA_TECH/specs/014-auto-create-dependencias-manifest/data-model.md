# Data Model: Auto-crear dependencias-manifest.yml

## Entidades

### dependencias-manifest.yml
- **Path**: `<project_root>/dependencias-manifest.yml`
- **Tipo**: Archivo YAML
- **Campos**:
  - `dependencias_externas`: lista vacía
  - `aplicaciones`: lista vacía
- **Validación**: YAML válido, secciones presentes.

### ManifestSkeleton
- **Propiedades**:
  - `header`: string comentario
  - `dependencias_externas`: array vacío
  - `aplicaciones`: array vacío

## Relaciones
- `plataformador-bootstrap.ps1` → crea/lee `dependencias-manifest.yml`
- `Read-DependenciasManifest` → parsea sección `aplicaciones`

## Reglas de validación
- No crear si archivo existe.
- Contenido debe ser YAML parseable.
