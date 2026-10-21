# Feature Specification: 021-estructura-inicial-apps-nuevas — Creación estandarizada de apps nuevas antes de ejecutar plataformador

**Feature Branch**: `021-estructura-inicial-apps-nuevas`
**Created**: 2026-10-19
**Status**: Draft
**Input**: Solicitud de usuario: los nuevos proyectos deben crear primero `Documentacion/<App>/` y `src/<App>/` según estándar, y recién ahí ejecutar `plataformador-bootstrap.ps1`. Evitar creación en raíz.

---

## Problema

Al pedir la creación de una app nueva con `plataformador`, el agente improvisaba y creaba una carpeta `demo/` en la raíz del repo, con subcarpetas internas ad-hoc. Eso rompe la estructura canónica:

* Documentación interna debe vivir en `Documentacion/<AppName>/`.
* Código debe vivir en `src/<AppName>/`.
* El bootstrap `plataformador-bootstrap.ps1` solo gestiona apps que ya existen en `src/*/`. No crea apps nuevas.

Resultado: apps fuera de estándar, `speckit` sin rutas válidas, `Ensure-AppStructure`/`Ensure-SrcAppStructure` no encuentran la app, y `Resolve-ActiveApp` cae a modo kit/root.

## Objetivos

* Formalizar el procedimiento de creación de una app nueva: estructura mínima obligatoria antes de invocar `plataformador-bootstrap.ps1`.
* Garantizar que `Documentacion/<AppName>/` y `src/<AppName>/` existan con los subdirectorios exigidos por `.doc_agents/estructura-aplicacion.md` y `.doc_agents/estructura-estandar.md`.
* Evitar creación de carpetas en la raíz del repo y asegurar compatibilidad con Speckit/SSD.
* Hacer explícita la precedencia de resolución de app activa: `-App` → `cwd` → root kit.

## Alcance

* Define el checklist mínimo de creación de app nueva.
* Define el orden de ejecución: 1) crear estructura base, 2) registrar app en `dependencias-manifest.yml` `aplicaciones:`, 3) ejecutar `plataformador-bootstrap.ps1`.
* No modifica el script del bootstrap; solo fija el proceso que debe precederlo.

## Requisitos funcionales

### RF-01 Estructura base obligatoria antes de bootstrap
Antes de ejecutar `plataformador-bootstrap.ps1`, la app debe existir con:
* `Documentacion/<AppName>/` con: `00-indice.md`, `pendientes-implementacion.md`, `specs/`, `arquitectura/adr/`, `bitacoras/`.
* `src/<AppName>/` con: directorio vacío y `.specify/` vacío o copiable.
* No se permite crear carpetas de app en la raíz del repo.

### RF-01.1 Creación temprana por el agente plataformador
Cuando el usuario solicite "crear un nuevo proyecto / nueva app", el agente `plataformador` debe **primero crear las carpetas vacías en las rutas correctas**:
* `Documentacion/<AppName>/`
* `src/<AppName>/`
y dejarlas vacías para que `plataformador-bootstrap.ps1` les asigne la estructura correcta con `Ensure-AppStructure` y `Ensure-SrcAppStructure`. No se debe crear `AppName/` en la raíz.

### RF-02 Registro en manifest
La app debe estar registrada en `dependencias-manifest.yml` bajo `aplicaciones: <AppName>`. Sin registro, `Resolve-AppList` no la detecta y el bootstrap la ignora.

### RF-03 Orden de ejecución
Secuencia obligatoria:
1. Agente `plataformador` crea carpetas vacías `Documentacion/<AppName>/` y `src/<AppName>/` en las rutas correctas.
2. Añadir app a `dependencias-manifest.yml` → `aplicaciones:`.
3. Ejecutar `plataformador-bootstrap.ps1` [opcional `-DryRun` para validar].
4. Verificar `Ensure-SrcAppStructure` y `Ensure-AppStructure` reporten OK.

### RF-04 Validación de rutas
Tras el bootstrap, debe cumplirse:
* `Documentacion/<AppName>/00-indice.md` existe y referencia la app.
* `src/<AppName>/.specify/constitution.md` existe (copiado desde `/.specify/`).
* `speckit-specify` resuelve `Documentacion/<AppName>/specs/` como destino.

### RF-05 Regla anti-raíz
El agente `plataformador` debe advertir con `Write-Warn` si detecta una carpeta con nombre de app en la raíz del repo y no en `Documentacion/`/`src/`.

## Requisitos no funcionales

* **RNF-01 Compatibilidad con SSD+Speckit**: La estructura creada debe permitir `specify → plan → tasks → analyze → converge → implement` sin errores de ruta.
* **RNF-02 Documentación**: La creación de estructura debe registrarse en `Documentacion/<AppName>/bitacoras/` con bitácora de inicialización.
* **RNF-03 Idempotencia**: Re-ejecutar el bootstrap no debe sobrescribir archivos existentes salvo con `-Force`.

## Criterios de aceptación

* **SC-01**: Una app nueva creada siguiendo RF-01 a RF-03 pasa `plataformador-bootstrap.ps1` sin WARN de estructura faltante.
* **SC-02**: `Documentacion/<AppName>/` y `src/<AppName>/` existen y cumplen el árbol mínimo de `.doc_agents/estructura-aplicacion.md`.
* **SC-03**: `speckit-specify --app <AppName>` escribe `spec.md` en `Documentacion/<AppName>/specs/<id>/spec.md`.
* **SC-04**: No existen carpetas de app en la raíz del repo fuera del kit transversal.
* **SC-05**: El agente `plataformador` documenta la secuencia en su `spec.md` de app.

## Fuera de alcance

* Modificación del `plataformador-bootstrap.ps1` para aceptar parámetro `-App`/`-NewApp` — queda como mejora futura.
* Creación automática de repositorio Git remoto.
* Generación de contenido de negocio dentro de la app.

## Dependencias

* `.doc_agents/estructura-aplicacion.md`
* `.doc_agents/estructura-estandar.md`
* `AGENTS.md` Regla de estructura por aplicación
* `scripts/plataformador-bootstrap.ps1` funciones `Ensure-AppStructure` y `Ensure-SrcAppStructure`
* ADR-0005 — Delegación SSD/Speckit

## Notas

La estructura canónica es:
```
Documentacion/<AppName>/
  00-indice.md
  pendientes-implementacion.md
  specs/
  arquitectura/adr/
  bitacoras/
src/<AppName>/
  .specify/  ← copiada desde /.specify/
```

Nunca crear `demo/` en raíz. Si el agente no encuentra una ruta válida, debe preguntar al usuario y no improvisar.

**Característica agregada por esta spec:**
Cuando el usuario pide "nuevo proyecto", el primer paso obligatorio del agente `plataformador` es crear las carpetas vacías en las rutas correctas `Documentacion/<AppName>/` y `src/<AppName>/`. Esas carpetas quedan vacías; la estructura correcta la asigna `plataformador-bootstrap.ps1` mediante `Ensure-AppStructure` y `Ensure-SrcAppStructure`. Esto evita creación en raíz y garantiza compatibilidad con Speckit/SSD desde el inicio.
