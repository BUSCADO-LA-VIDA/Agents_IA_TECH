# Research: Auto-crear dependencias-manifest.yml si falta en bootstrap

## Decisiones

### D-001: Crear esqueleto mínimo sin forzar contenido
**Decisión**: Crear archivo con encabezado y secciones vacías `dependencias_externas:` y `aplicaciones:` con comentarios de ejemplo.
**Rationale**: Cumple FR-002 y FR-004, no fuerza apps del KIT, permite que `Read-DependenciasManifest` funcione.
**Alternativas consideradas**: Crear manifest con apps por defecto del KIT → rechazado por regla de no mezclar proyectos.

### D-002: No sobrescribir manifest existente
**Decisión**: Verificar existencia con `Test-Path` antes de crear.
**Rationale**: Respeta personalización del usuario.
**Alternativas**: Sobrescribir siempre → rechazado.

### D-003: Aviso visible al crear esqueleto
**Decisión**: `Write-Host` con mensaje "Creando esqueleto dependencias-manifest.yml..."
**Rationale**: Cumple FR-006 y observabilidad.

## Hallazgos

- `Read-DependenciasManifest` en `scripts/plataformador-bootstrap.ps1` líneas 169-193 solo avisa y devuelve `@()`.
- `upgrade_framework.ps1` tiene función similar.
- Manifest de referencia en `C:\Proyectos\Agents_IA_TECH\dependencias-manifest.yml` usa formato con `dependencias_externas:` y sección `aplicaciones:` comentada.
- No hay dependencias externas para crear YAML; se usa texto plano.

## Riesgos

- Permisos de escritura en raíz del proyecto → manejar con try/catch y WARN.
