# Spec 037 — Sincronización de `.gitignore`: lo que no debe versionarse

## Estado: **Implementada** (2026-11-05)

## Ubicación
`Documentacion/Agents_IA_TECH/specs/037-mcp-gitignore-fix/`

## Decisión de arquitectura (usuario, 2026-11-05)
Dos decisiones del usuario originaron esta spec y su ampliación:

1. **Decisión inicial**: al actualizar la estructura de un proyecto, `graphify-out/` (cache regenerable con `graphify update`) se sube a Git porque no está en `.gitignore`. Eso viola RF-011 de la Spec 036 ("`graphify-out/` nunca se sube a repositorios") y agrega ruido al historial.
2. **Ampliación (misma sesión)**: "quiero agregar al `.gitignore` todas las carpetas que no deben ir al repositorio ni deben estar versionadas". El alcance deja de ser solo graphify y pasa a ser un **catálogo de bloques** de exclusión (dependencias, entornos virtuales, artefactos de build, backups del kit, caches, logs, sistema/editor).

## Objetivo
Que cualquier proyecto gestionado por el kit tenga un `.gitignore` que excluya de forma determinista todo lo que no debe versionarse, sin tocar archivos de terceros y con una operación reversible.

El alcance concreto es:
- Aplicar un catálogo de 6 bloques identificados por cabecera, de forma idempotente.
- Aplicarlo **solo a raíces de proyecto** (la ruta indicada y todo directorio que tenga su propio `.git`), nunca dentro de dependencias o entornos virtuales.
- Poder revertir exactamente lo aplicado, incluido el formato histórico del bloque graphify.
- Verificar todo con un test de contrato ejecutable sin Pester.

## Ámbito de aplicación
- Repo maestro `Agents_IA_TECH`.
- Proyectos destino sincronizados con el kit (verificado sobre `Generator_IA_Projects`).
- Raíces de proyecto: raíz del workspace, `Documentacion/`, `src/<App>/` y cualquier subcarpeta que tenga su propio `.git`.

## Fundamentación (RF-011 + Spec 036)
La Spec 036 fijó el requisito ("`graphify-out/` nunca se sube"). Esta spec lo **operacionaliza** y lo generaliza: no alcanza con documentar la regla, hace falta un mecanismo ejecutable, idempotente y verificable que la garantice en cada repo, y que además cubra el resto de artefactos no versionables.

## Problema actual (diagnóstico)
- El directorio `graphify-out/` no está necesariamente en `.gitignore` de los proyectos.
- El usuario reporta que "al actualizar la estructura del proyecto, lo agrega a Git, algo que realmente no aporta".
- No existía verificación automática ni mecanismo de aplicación.
- Durante la primera implementación de esta misma spec se detectó un defecto propio: el recorrido recursivo tocaba `.gitignore` **dentro** de `vendor/`, `.venv/`, `node_modules/`, `.git/`, `.pytest_cache/` y backups del kit (283 archivos, 196 en rutas de terceros). Ese overreach está corregido y revertido; queda documentado como lección.

## Consecuencias si no se corrige
- Inclusión accidental de caches y dependencias en commits.
- Ruido en pull requests e historial.
- Violación de RF-011 en auditorías futuras.
- Dificultad para distinguir cambios reales de artefactos regenerables.

## Solución implementada

### Script `scripts/sync-gitignore.ps1`
- Catálogo de 6 bloques, cada uno identificado por su línea de cabecera:
  1. `# 1. Dependencias y entornos virtuales` → `node_modules/`, `.venv/`, `venv/`, `__pycache__/`, `*.py[cod]`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.tox/`, `vendor/`
  2. `# 2. Artefactos de build` → `dist/`, `build/`, `out/`, `coverage/`, `*.tsbuildinfo`
  3. `# 3. Backups y temporales del kit` → `.kit-backup/`, `.kit-backup-manual/`, `.kit-sync-temp/`, `opencode.json.bak-*`, `AGENTS.md.bak-*`
  4. `# 4. Caches de herramientas del kit (graphify)` → `graphify-out/*`, `.playwright-mcp/`
  5. `# 5. Logs y temporales` → `*.log`, `!.bootstrap-audit.log`, `logs/`, `tmp/`, `temp/`
  6. `# 6. Sistema y editor` → `Thumbs.db`, `.DS_Store`, `.idea/`
- Selección por defecto: **raíces de proyecto** (la ruta indicada + todo directorio con su propio `.git`, hasta profundidad 8).
- Exclusiones duras (nunca se recorre ni se escribe en): `.git`, `node_modules`, `.venv`, `venv`, `env`, `site-packages`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, `.tox`, `vendor`, `dist`, `build`, `bin`, `obj`, `target`, `packages`, `.next`, `.nuxt`, `.cache`, `.terraform`, `graphify-out`, `.kit-backup`, `.kit-backup-manual`, `.kit-sync-temp`, `revisar_manualmente`, `proyect_ext`.
- Parámetros: `-Path`, `-Sets` (`all|deps|build|kit|graphify|logs|os`), `-WhatIf`, `-Force`, `-AllGitignore`, `-OnlyExcluded`, `-RemoveBlock`, `-PruneRules`, `-Exclude`.
- Nunca ejecuta `git add`/`git commit`, nunca genera graphify, nunca modifica el contenido de `graphify-out/`.

### Test `tests/sync-gitignore.Tests.ps1`
Contrato sin Pester, `exit 0`/`exit 1`, 14 asserts sobre fixtures temporales. Cubre: existencia del script, aplicación del catálogo, preservación del contenido propio, idempotencia, exclusiones, ausencia de `.gitignore`, reversión de ambos formatos y filtro por `-Sets`.

### Reversión
`-RemoveBlock` elimina los bloques reconocidos por cabecera, soportando el formato actual (separador de cierre) y el histórico (sin cierre). `-PruneRules` elimina líneas de regla huérfanas que dejaron versiones intermedias. `-OnlyExcluded` limita la operación a las rutas que no debieron tocarse.

## Requisitos funcionales (FR)

| ID | Requisito | Estado |
|----|-----------|--------|
| FR-037-01 | `scripts/sync-gitignore.ps1` existe y es ejecutable | Cumplido |
| FR-037-02 | Agrega el bloque `graphify-out/*` a cada `.gitignore` seleccionado que no lo tenga | Cumplido |
| FR-037-03 | Es idempotente: N ejecuciones no duplican bloques | Cumplido |
| FR-037-04 | No altera el contenido propio del `.gitignore` ni el de `graphify-out/` | Cumplido |
| FR-037-05 | Maneja sin error la ausencia de `.gitignore` | Cumplido |
| FR-037-06 | `tests/sync-gitignore.Tests.ps1` valida FR-037-01..FR-037-05 | Cumplido |
| FR-037-07 | Nunca escribe dentro de `node_modules`, `.git`, `.venv`, `vendor`, caches ni backups del kit | Cumplido |
| FR-037-08 | Aplica el catálogo completo de carpetas no versionables en las raíces de proyecto | Cumplido |
| FR-037-09 | `-RemoveBlock` revierte exactamente lo agregado, en ambos formatos de bloque, y `-PruneRules` limpia restos | Cumplido |

## Criterios de éxito (SC)

| ID | Criterio | Evidencia |
|----|----------|-----------|
| SC-037-01 | El script existe y ejecuta | `pwsh -File scripts/sync-gitignore.ps1 -WhatIf` responde con conteos |
| SC-037-02 | `.gitignore` raíz del maestro contiene la regla graphify | Bloque `# 4. ...` presente (el archivo ya tenía `graphify-out/` desde la 036; el set detecta y no duplica) |
| SC-037-03 | Raíces del destino con catálogo aplicado | 13 archivos actualizados en `Generator_IA_Projects` (raíz + `Documentacion/` + 11 apps) |
| SC-037-04 | Idempotencia verificada | Segunda corrida sobre ambos repos: `Archivos actualizados: 0` |
| SC-037-05 | Test en verde | `PASS=14 FAIL=0` |
| SC-037-06 | Sin regresión en el kit | `tests/harness-default.ps1` → `RESULTADO: OK`; paridad de cuerpo de `developer` intacta |
| SC-037-07 | Sin archivos versionados que queden ignorados por las reglas nuevas | `git ls-files -i -c --exclude-standard` no reporta `.bootstrap-audit.log` (negación aplicada) |
| SC-037-08 | Overreach revertido | 196 `.gitignore` de rutas de terceros limpiados; solo quedan 3 con `graphify-out/` que lo tenían legítimamente desde la 036 |

## Restricciones (Constraints)
- ❌ NUNCA se agrega lógica de generación de graphify al script ni al orquestador.
- ❌ NUNCA se modifica el contenido real de `graphify-out/`.
- ❌ NUNCA se commitea automáticamente.
- ❌ NUNCA se escribe dentro de dependencias, entornos virtuales, backups ni metadatos de git.
- ✅ Los bloques son idempotentes y reversibles por cabecera.
- ✅ El bloque graphify conserva el formato acordado en la Spec 036.

## Assumptions
- Cada raíz de proyecto tiene (o debería tener) su `.gitignore`.
- `graphify-out/*` es suficiente como patrón de exclusión del cache.
- El usuario tiene permisos de escritura sobre los `.gitignore` de sus proyectos.

## Fuera de alcance
- Ejecutar `git add`/`git commit`.
- Integrar la invocación en `scripts/sync-kit.ps1` (T037-005, opcional, backlog).
- Crear `.gitignore` donde no existe (se reporta y se continúa).

## Lecciones registradas
- Un `Get-ChildItem -Recurse` sin política de exclusión escribe en 196 archivos ajenos. La exclusión por segmento de ruta y la selección por raíz de proyecto son obligatorias, no opcionales.
- La reversión debe tolerar el formato histórico: si el revertedor solo entiende el formato nuevo, deja líneas huérfanas.
- Un `*.log` genérico rompe la auditoría: `.bootstrap-audit.log` debe quedar negado explícitamente.

## Referencias
- Spec 036, RF-011: `graphify-out/` nunca se sube a repositorios.
- AGENTS.md: dominio de escritura por agente (implementadores → `scripts/`, `tests/`).
- OpenCode docs: `mode` por defecto es `all`; la delegación se controla con `permission.task`.
- Script: `scripts/sync-gitignore.ps1`.
- Test: `tests/sync-gitignore.Tests.ps1`.
