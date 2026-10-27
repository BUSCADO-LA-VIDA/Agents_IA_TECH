# Skill public-documentation

## Propósito
Validar ruta de documentación según visibilidad.

## Reglas
- Documentación funcional pública → `src/<App>/docs/`
- README* → `src/<App>/README*.md`
- Documentación interna → `Documentacion/<AppName>/`
- Si doc es pública, documentador delega escritura a developer.

## Flujo
1. Detectar tipo de doc solicitado.
2. Validar ruta según reglas.
3. Si pública, crear tarea para developer con ruta exacta.
4. Registrar en pendientes-implementacion.md.
