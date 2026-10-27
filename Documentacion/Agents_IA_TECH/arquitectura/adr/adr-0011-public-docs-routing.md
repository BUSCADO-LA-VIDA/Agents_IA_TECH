# ADR-0011 - Public Docs Routing

## Estado
Aceptada

## Contexto
Se requiere distinguir documentación interna vs pública y garantizar rutas correctas.

## Decisión
* Documentación funcional pública → `src/<App>/docs/`
* README* → `src/<App>/README*.md`
* Documentación interna → `Documentacion/<AppName>/`
* `documentador` delega escritura a `developer` cuando la doc es pública.

## Consecuencias
Ruta determinista y permisos respetados.
