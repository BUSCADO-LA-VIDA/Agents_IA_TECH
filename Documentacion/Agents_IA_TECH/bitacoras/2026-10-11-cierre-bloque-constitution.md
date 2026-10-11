# Bitacora 2026-10-11 — Cierre bloque constitution 002-T032..T035

## T032 — Hook implementado (delegado a `plataformador`, verificado por `pensador`)
- Funcion `Ensure-ConstitutionAppSync` en `scripts/plataformador-bootstrap.ps1` L2394 (~135 lineas, tags `[002-CONSTITUTION]`), invocada en `Prepare-Apps` L2575.
- Cubre: siembra nivel 2 desde raiz si falta (conserva salvo `-Force`); copia nivel 2 -> nivel 3 solo si existe `src/<App>` (nunca desde la raiz); append idempotente de `.specify/constitution.md` en `src/<App>/.gitignore`; fail-open por app; respeta `$DryRun`/`$Force`; solo helpers existentes.
- Verificacion propia: 3 coincidencias del nombre, 42 tags, 0 errores de parseo, DryRun ejecuta el hook (WARN esperado: sin apps en este kit).
- Nivel 2 sembrado manualmente: `Documentacion/Agents_IA_TECH/.specify/constitution.md`, SHA256 identico al original (`89CFE451...A84A55B5`), 194 lineas.

## T033 — Tres ubicaciones verificadas
- L1 `.specify/memory/constitution.md`: EXISTE. L2 `Documentacion/Agents_IA_TECH/.specify/constitution.md`: EXISTE, hash igual. L3 `src/<App>`: N/A (el kit no tiene `src/`).

## T034 — Gitignore segun la regla del usuario
- Raiz `.gitignore` NO ignora `constitution.md`: correcto (el original del KIT se versiona).
- El hook agrega la regla en `src/<App>/.gitignore` cuando exista src.
- Desviacion honesta vs la descripcion original de T034 (pedia ignorar la raiz): rige la regla del usuario del 2026-10-11.

## T035 — Ruta documentada en AGENTS.md L100
- Agregado el bullet "Ruta constitution en 3 niveles (002-T035)" tras la linea de `.specify por proyecto`.

## Error propio corregido (regla de integridad)
- Al actualizar `specs/002-.../tasks.md` marque por error T026/T027/T028/T029 en lugar de T032-T035 (las 4 primeras `[ ]` del archivo en vez de las 4 correspondientes).
- Detectado en la verificacion posterior, revertidas las 4 a `[ ]` y marcadas las correctas (L58/L64/L70/L76). Estado final verificado linea por linea.

## Cambios
- `pendientes-implementacion.md`: 002-T032/T033/T034/T035 -> `[x]`/Si (lineas 84-87).
- `specs/002-script-plataforming-sync-kit/tasks.md`: T032-T035 -> `[x]` con evidencia.
- `AGENTS.md` L100: ruta 3 niveles. `scripts/plataformador-bootstrap.ps1`: hook (via delegado).
- Bitacora previa `2026-10-11-bloque-constitution.md` queda como registro intermedio (decia [ ] antes del hook); esta la sustituye como cierre.
