# Spec: Auto-crear dependencias-manifest.yml si falta en bootstrap

**Versión**: 1.1
**Fecha**: 2026-09-25
**Estado**: Refinado
**Autor**: pensador

**Nota de refinamiento**: Esta spec absorbe los requisitos de sincronización y upgrade inicialmente planteados en 015-manifest-sync-and-upgrade. Los requisitos base de creación de esqueleto se mantienen en 014. Los requisitos de sincronización con referencia del KIT, switch `upgrade`, add/remove de herramientas y post-update hooks se trasladan a 015 como fase posterior.

---

## Objetivo

Definir el comportamiento del KIT `Agents_IA_TECH` para que `plataformador-bootstrap.ps1` no falle ni emita warnings cuando un proyecto no posee `dependencias-manifest.yml`. El bootstrap debe crear un esqueleto mínimo del manifest en la raíz del proyecto, sin forzar contenido, preservando la regla de que el manifest es del proyecto y no del KIT, y permitiendo que `upgrade_framework` y `Read-DependenciasManifest` continúen.

**Contexto**: Actualmente `Read-DependenciasManifest` solo avisa y devuelve `@()`. El bootstrap muestra WARN y `upgrade_framework` no prepara apps. El usuario exige que todo se cree con Speckit para validar despliegues y no forzar cambios.

---

## User Scenarios & Testing

### User Story 1 — Bootstrap en proyecto sin manifest (Priority: P1)

El usuario ejecuta `plataformador-bootstrap.ps1` en un proyecto nuevo o existente que no tiene `dependencias-manifest.yml`. El bootstrap debe detectar la ausencia y crear un esqueleto mínimo sin sobrescribir si ya existe.

**Why this priority**: Es el caso que genera WARN hoy y bloquea la preparación de apps.

**Independent Test**: Puede probarse creando un proyecto vacío sin manifest y ejecutando bootstrap; verificar que se crea el archivo con estructura válida y sin contenido forzado.

**Acceptance Scenarios**:
1. **Given** un proyecto sin `dependencias-manifest.yml`, **When** se ejecuta bootstrap, **Then** se crea `dependencias-manifest.yml` con secciones `dependencias_externas:` y `aplicaciones:` vacías y comentarios de ejemplo.
2. **Given** un proyecto con `dependencias-manifest.yml` existente, **When** se ejecuta bootstrap, **Then** no se sobrescribe y se usa el existente.
3. **Given** el manifest esqueleto creado, **When** `Read-DependenciasManifest` lo lee, **Then** devuelve lista vacía sin error y sin WARN.

---

### User Story 2 — No forzar contenido del proyecto (Priority: P1)

El KIT no debe imponer apps ni dependencias externas concretas al proyecto. El esqueleto debe ser genérico y dejar `licencia: pendiente de verificar` para que el usuario lo complete.

**Why this priority**: Respeta la regla de que el manifest es del proyecto y evita mezclar proyectos.

**Independent Test**: Verificar que el esqueleto creado no contiene URLs ni nombres de apps del KIT.

**Acceptance Scenarios**:
1. **Given** esqueleto creado, **When** se inspecciona el contenido, **Then** no contiene apps concretas del KIT, solo comentarios de ejemplo.
2. **Given** esqueleto creado, **When** el usuario edita el manifest, **Then** los cambios se preservan en ejecuciones posteriores.

---

### Edge Cases

- ¿Qué pasa si el directorio raíz no es escribible? → Se emite WARN y se continúa sin crear archivo.
- ¿Qué pasa si el archivo existe pero está vacío? → Se mantiene y se lee como vacío.
- ¿Qué pasa si el usuario ejecuta bootstrap con `-ForceUpgradeTools`? → El esqueleto se crea una sola vez, no se regenera.
- ¿Qué pasa si el manifest tiene solo `dependencias_externas` y no `aplicaciones`? → `Read-DependenciasManifest` devuelve lista vacía sin error.

---

## Requirements

### Functional Requirements

- **FR-001**: El sistema DEBE detectar la ausencia de `dependencias-manifest.yml` en la raíz del proyecto antes de invocar `Read-DependenciasManifest`.
- **FR-002**: El sistema DEBE crear un esqueleto mínimo de `dependencias-manifest.yml` si no existe, con encabezado, sección `dependencias_externas:` vacía y sección `aplicaciones:` vacía, con comentarios de ejemplo.
- **FR-003**: El sistema NO DEBE sobrescribir un `dependencias-manifest.yml` existente.
- **FR-004**: El esqueleto creado DEBE ser genérico, sin apps ni dependencias concretas del KIT, y con `licencia: pendiente de verificar` en los comentarios de ejemplo.
- **FR-005**: Tras crear el esqueleto, `Read-DependenciasManifest` DEBE leerlo sin error y devolver lista vacía.
- **FR-006**: El bootstrap DEBE mostrar un aviso visible cuando crea el esqueleto: "Creando esqueleto dependencias-manifest.yml...".

### Key Entities

- **dependencias-manifest.yml**: Archivo YAML en raíz del proyecto.
- **aplicaciones**: Sección del manifest con apps del proyecto.
- **dependencias_externas**: Sección del manifest con herramientas externas.
- **plataformador-bootstrap.ps1**: Script del KIT que orquesta bootstrap.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: En proyectos sin manifest, el bootstrap crea `dependencias-manifest.yml` en el 100% de los casos.
- **SC-002**: El archivo creado contiene las secciones `dependencias_externas:` y `aplicaciones:` y es YAML válido.
- **SC-003**: No se sobrescribe un manifest existente en el 100% de los casos.
- **SC-004**: `Read-DependenciasManifest` devuelve lista vacía sin WARN tras crear esqueleto.
- **SC-005**: El esqueleto no contiene apps concretas del KIT.

---

## Assumptions

- El bootstrap se ejecuta con permisos de escritura en la raíz del proyecto.
- El manifest es del proyecto, no del KIT; el KIT solo provee esqueleto genérico.
- El usuario completará el manifest con sus propias apps y dependencias.
- No se requiere backend LLM para crear el esqueleto.

---

## Dependencias

- `specs/011-bootstrap-invokes-upgrade-framework/spec.md` — flujo de bootstrap y preparación de apps.
- `Documentacion/Agents_IA_TECH/reglas-transversales-agentes.md` — regla de no mezclar proyectos.
- `scripts/plataformador-bootstrap.ps1` — función `Read-DependenciasManifest`.
