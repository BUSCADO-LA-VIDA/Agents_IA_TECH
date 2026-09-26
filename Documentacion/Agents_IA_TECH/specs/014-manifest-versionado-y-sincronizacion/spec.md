# Spec 014: Manifest versionado y sincronización

Versión 1.0

Objetivo: Versionar dependencias-manifest.yml, sincronizar versiones con KIT y mantener MCPs actualizados.

## Requisitos
- FR-001: dependencias-manifest.yml debe versionarse, no estar en .gitignore
- FR-002: Manifest de referencia en proyect_ext/
- FR-003: Sincronización de versiones con upgrade switch
- FR-004: Hooks post-update por herramienta


## Arquitectura Modular
Estructura scripts/modules/Manifest y Utils creada. Requiere ajuste para nuevo flujo de versionado.

Archivos existentes:
- ManifestManager.psm1
- ManifestReference.psm1
- ManifestHooks.psm1
- YamlHelper.psm1

Estado: Pendiente de ajuste a nuevo flujo.

## Flujo de Instalación y Actualización
1. KIT base mantiene herramientas en proyect_ext/
2. Manifest de referencia versionado en proyect_ext/dependencias-manifest.yml
3. Proyectos derivados sincronizan manifest con referencia
4. Upgrade switch por herramienta
5. Hooks post-update ejecutan reindexación

## Requisitos No Funcionales
- Manifest versionado en git
- No sobrescribir personalizaciones
- Idempotente


## Estructura dependencias-manifest.yml
dependencias_externas:
  <herramienta>:
    version_actual: 'x.y.z'
    upgrade: true|false
    url: '...'
    rama: 'main'
aplicaciones:
  <app>:
    version_actual: 'x.y.z'
    upgrade: true|false

