# 🔒 Seguridad del diseño: limpieza de regenerables incl. `.venv` (`Find-RegenerableDirs` + `Clear-RegenerableDirs`, RF-15)

> Revisión **de seguridad del DISEÑO** de la extensión RF-15 de `relocate-apps-to-src.ps1` (RF-15 + criterio 11): `Find-RegenerableDirs` (escanea apps candidatas contra allowlist de nombres exactos + mide tamaños) + `Clear-RegenerableDirs` (elimina con confirmación global única, log de lo eliminado, sin respaldo). Allowlist fija Python + Node + general **más `.venv/`** (decisión explícita 2026-09-19: se ELIMINA por comando, no se mueve; se recrea después en `src\<App>`). Pregunta global de limpieza ANTES de S/N/T/C por app; No = mueve todo. `.venv` activo → `deactivate` previo obligatorio vía RF-14. Nunca `Documentacion/`; `-DryRun` informa, no borra.
> Enfocada en: **borrado no-regenerable por coincidencia de nombre, `.venv` activado en terminal, `.venv` sin `requirements.txt` (irreproducible), `node_modules` con parches/bins offline, fatiga de confirmación (global + S/N/T/C + recreaciones)**.
> Fuente: `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-15, criterio 11) y `pendientes-implementacion.md` (tarea `[RELOCATE]`, limpieza aprobada 2026-09-19).
> Complementa: `seguridad/relocate.md` (RF-13: movido, corte, `[T]odos`, rollback, alcance, traversal, fuga por log) y `seguridad/relocate-locks.md` (RF-14: `deactivate`, kill `git.exe`, `pip install`, reactivación) — no las sustituye.
> Autor: `security-auditor` (fase documental — tarea `[RELOCATE]`, extensión RF-15)

---

## 1. Análisis de riesgos del diseño de limpieza

### 1.1 Riesgo de borrar algo no-regenerable por coincidencia de nombre (`build/` con fuentes, `dist/` versionado)

La allowlist contiene nombres genéricos y de alta colisión: `build/`, `dist/`, `coverage/`, `.cache/`. En muchos proyectos `build/` o `dist/` **no son regenerables**: contienen fuentes generadas a mano, artefactos versionados a propósito (releases sin CI que los regenere), o scripts de empaquetado que solo existen ahí. `*.egg-info/` puede ser el único manifiesto de versión si no hay `pyproject.toml` versionado. El borrado es **irreversible por diseño** (log sin respaldo) y el detector por nombre exacto no distingue "regenerable real" de "carpeta con el mismo nombre pero contenido propio".

**Puntos de validación necesarios:**
- **Match por nombre exacto + nivel, nunca por substring ni recursivo ciego**: `Find-RegenerableDirs` solo reconoce el nombre exacto en la allowlist y solo bajo `<App>\` (profundidad 1, o profundidades documentadas p. ej. `<App>\src\build` excluido). `dist-new`, `Build`, `BUILD/` no matchean (comparación exacta, case-insensitive documentada en Windows pero sin normalizar a lo loco).
- **Gate `git` antes de borrar**: si la ruta candidata está **trackeada por git** (`git ls-files` la lista) → NO es regenerable en este proyecto → **excluir con aviso** ("`dist/` versionado a propósito, se conserva y se mueve con la app"). Regenerable de verdad casi nunca está trackeado (está en `.gitignore`); lo trackeado es señal de contenido propio.
- **Mostrar contenido resumido antes de la pregunta global**: por cada candidato, ruta relativa + tamaño + nº de archivos + estado git (trackeado/ignorado/sin repo). El usuario decide informado, no a ciegas.
- **`DryRun` demuestra la allowlist**: el informe lista exactamente qué se borraría y qué se excluye por git-trackeado, verificable en tests con fixtures.

### 1.2 Riesgo de eliminar el `.venv` ACTIVADO en la terminal (PATH roto a mitad de ejecución)

Si `$env:VIRTUAL_ENV` apunta a `<App>\.venv` y el script elimina ese árbol, la sesión queda con un `PATH` que referencia un intérprete inexistente: `python`/`pip` fallan o resuelven a otro intérprete del sistema, y todo lo posterior (incluido el movido y la recreación) corre en el entorno equivocado. Peor: si `Restore-AppLocks` reactiva después, el estado intermedio ya contaminó comandos.

**Puntos de validación necesarios:**
- **Orden innegociable: detectar → `deactivate` (RF-14, con confirmación) → recién entonces limpiar.** `Clear-RegenerableDirs` jamás toca un `.venv` cuyo path canónico coincide con `$env:VIRTUAL_ENV` (comparación canónica case-insensitive) sin `deactivate` previo verificado (`$env:VIRTUAL_ENV` vacío tras desactivar).
- **Reutilizar `Test-ActiveVenv` / `Suspend-AppLocks`**: no duplicar la detección; la limpieza consume el mismo estado (activo/inactivo/ajeno) ya validado. Venv ajeno al lote → solo aviso, sin mutar (heredado de RF-14).
- **Fail-closed**: si el `deactivate` fue rechazado (No) o no hay `deactivate` disponible → **excluir ese `.venv` de la limpieza con aviso persistente** (se mueve con la app como en RF-13, o se deja; nunca borrar activo).
- **`DryRun` informa el estado del venv** (activo/inactivo) sin mutar, como ya hace el aviso de venv activado.

### 1.3 Riesgo de eliminar `.venv` sin `requirements.txt` (entorno irreproducible → pérdida de trabajo)

Borrar el `.venv` es barato; reconstruirlo solo es posible si existe **manifiesto fijado** (`requirements.txt` / `requirements.lock` / `pyproject.toml` con pin). Sin manifiesto, o con rangos abiertos (`>=`, `*`), la recreación produce un entorno distinto (versiones nuevas, APIs rotas) o directamente imposible (paquetes instalados a mano, desde ruedas locales, desde índices privados, con parches). El trabajo de meses ajustando dependencias se pierde sin respaldo.

**Puntos de validación necesarios:**
- **Pre-chequeo de reproducibilidad por app antes de borrar su `.venv`**: existe manifiesto dentro de la app (`requirements.txt`/`lock`/`pyproject.toml`) → informar nombre + nº de paquetes fijados; NO existe → **aviso explícito "irreproducible" + confirmación separada** (no cubierta por la pregunta global) o exclusión por defecto. Nunca borrar a ciegas el único entorno que funciona.
- **Congelar antes de borrar (barato, local, sin red)**: si hay `pip` operativo en el venv, generar `pip freeze` a un archivo temporal **fuera** del árbol a borrar (p. ej. `<App>\.venv-freeze-<fecha>.txt`, excluido de la limpieza y movido con la app) antes de eliminar. Si la recreación falla, el freeze es la receta de rescate.
- **Confirmación separada para `pip install`** (heredado de RF-14 §1.3): recrear el venv vacío es local y barato; instalar es red + ejecuta código → preguntas distintas, el usuario puede aceptar el venv vacío y reinstalar luego.
- **Informe post-movido con comandos exactos en la ruta nueva** (`python -m venv` + `pip install -r` en `src\<App>\`) + nota de qué manifiesto se usó y qué quedó sin fijar.

### 1.4 Riesgo de `node_modules` con parches manuales o bins offline necesarios

`node_modules/` no siempre es 100 % regenerable: `patch-package` deja parches en `patches/` (si están commiteados se regeneran; si no, se pierden), hay bins nativos compilados que tardan o requieren toolchain offline no disponible, y dependencias de registros privados/inaccesibles (`npm install` falla sin red/VPN). Borrar sin comprobar convierte un `npm ci` de 2 minutos en una tarde de compilación o en un proyecto que no arranca offline.

**Puntos de validación necesarios:**
- **Pre-chequeos Node por app**: existe `package.json` + lockfile (`package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`) → informar; existe `patches/` + dependencia `patch-package` en `package.json` → verificar parches commiteados (`git status` limpio en `patches/`, heredado del pre-chequeo git limpio RF-13) → si hay parches sin commitear → **aviso + excluir `node_modules` de esa app o exigir commit primero**.
- **Advertir coste offline/red**: la pregunta global o el informe deben recordar que `node_modules` se reconstruye con `npm ci` (red + tiempo); si el usuario trabaja offline → que diga No a la limpieza de esa app.
- **No borrar otros dirs de build con contenido propio**: `.next/` y `coverage/` son regenerables típicos, pero si están trackeados (§1.1) se conservan. `dist/`/`build/` de Node caen bajo la misma gate git-trackeado.

### 1.5 Riesgo de fatiga de confirmación (global + S/N/T/C por app + recreaciones = aceptar todo sin leer)

El flujo acumula capas de preguntas: (1) global de limpieza, (2) S/N/T/C por app del movido, (3) `Suspend` (desactivar venv + pausar git por acción), (4) `Restore` (recrear + instalar + activar). Son **decenas de prompts** en un proyecto con 5 apps. El usuario aprende a pulsar `S`/`T` en bucle y la confirmación deja de ser un control: autoriza el borrado irreversible del `.venv` sin haber leído el resumen, acepta `pip install` sin mirar el manifiesto, y usa `[T]odos` como bypass de hecho (riesgo ya documentado en `relocate.md` §1.4, aquí agravado por la irreversibilidad del borrado).

**Puntos de validación necesarios:**
- **Pregunta global informada y reversible por defecto**: mostrar ANTES el resumen agregado (nº de dirs, tamaño total a liberar, lista por app con estado venv/manifiesto) + default seguro = **No limpiar** (sin respuesta → no borra; coherente con huérfanos default Conservar y relocate no-interactivo no mueve).
- **Separar lo irreversible de lo rutinario**: UNA confirmación global para regenerables típicos (cachés, `__pycache__`, `coverage`) + **confirmación separada y explícita para `.venv`** (irreversible sin manifiesto) por cada app afectada. El `.venv` nunca cae dentro del "sí a todo" de cachés.
- **`[T]odos` no cruza de fase**: el `T` del movido (RF-13) no implica sí a la limpieza ni a `pip install`, y viceversa. Cada fase tiene su propio alcance de lote, documentado en el prompt ("`[T]` aplica solo a esta pregunta").
- **No-interactivo y `DryRun` fail-closed**: sin consola → informa, no borra (igual que relocate no mueve); `-DryRun` lista todo lo que borraría con tamaños, cero escrituras, cero red.
- **Log de cada decisión**: qué se respondió (S/N/T/C) por fase y app queda en el log transaccional; ante duda el usuario puede auditar qué autorizó.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Borrar no-regenerable por coincidencia de nombre** (`build/` con fuentes, `dist/` versionado, `*.egg-info` único manifiesto) → pérdida irreversible (sin respaldo) | 🔴 Crítico | Allowlist de **nombres exactos + nivel** (sin substrings, sin recursivo ciego); **gate git-trackeado → excluir con aviso** (lo versionado se conserva y se mueve); resumen por candidato (ruta relativa + tamaño + estado git) antes de preguntar; `DryRun` demuestra la allowlist. |
| 2 | **Eliminar `.venv` ACTIVADO** (`PATH`/`VIRTUAL_ENV` apuntando al árbol borrado) → sesión rota, comandos posteriores contra intérprete equivocado | 🔴 Crítico | Orden innegociable **detectar → `deactivate` (RF-14) → limpiar**; `Clear` jamás toca el venv activo sin `deactivate` verificado (comparación canónica); No/sin-`deactivate` → **excluir ese `.venv` con aviso**; reutilizar `Test-ActiveVenv`/`Suspend-AppLocks`, no duplicar. |
| 3 | **`.venv` sin manifiesto (irreproducible)** → entorno perdido, recreación distinta o imposible (paquetes a mano, ruedas locales, índices privados) | 🟠 Alto | Pre-chequeo de manifiesto por app (existe/no-existe informado); sin manifiesto → **aviso "irreproducible" + confirmación separada** o exclusión; **`pip freeze` de rescate** a archivo fuera del árbol antes de borrar; `pip install` con confirmación separada (RF-14); informe con comandos exactos en `src\<App>\`. |
| 4 | **`node_modules` con parches/bins offline** (`patch-package` sin commitear, nativos compilados, registro privado) → `npm ci` falla o tarda, proyecto no arranca | 🟠 Alto | Pre-chequeos Node (lockfile + `patches/` + `patch-package` en `package.json`); parches sin commitear → aviso + exigir commit o excluir; advertir coste red/tiempo y caso offline en el prompt/informe; misma gate git-trackeado para `.next/`/`coverage/`/`dist/`/`build/`. |
| 5 | **Fatiga de confirmación** (global + S/N/T/C + suspend/restore = decenas de prompts) → aceptar todo sin leer; `[T]` como bypass de hecho sobre un borrado irreversible | 🟠 Alto | Resumen agregado ANTES de la pregunta global + **default No limpiar**; **confirmación separada para `.venv`** (nunca dentro del "sí a todo" de cachés); `[T]` con alcance solo de su fase; no-interactivo no borra; `DryRun` cero escrituras; log de cada decisión por fase y app. |
| 6 | **Corte a mitad de la limpieza** (kill/Ctrl+C entre borrados) → algunas apps limpias y otras no; reintento ambiguo | 🟡 Medio | Limpieza **por app, secuencial** (una cada vez, como el movido); log por app (qué se borró + tamaño + fecha); reintento idempotente (si ya no existe → informar "ya limpio", no error); nunca reintentar borrando fuera de la allowlist. (Hereda transacción-por-app de `relocate.md` §1.3.) |
| 7 | **Alcance fuera de lo sagrado** (allowlist aplicada al proyecto entero en vez de a apps candidatas) → borra `Documentacion/`, `.specify`, `src\` ajeno | 🟠 Alto | `Find` solo escanea **apps candidatas** (`-AppDirs` ya validados: nombres simples + denylist + containment de RF-13); containment-check del borrado (ruta canónica dentro de `<App>\`); `Documentacion/` y `.specify` nunca en el árbol de búsqueda; `DryRun` lo demuestra. |
| 8 | **Fuga por log** (rutas absolutas con usuario, `pip freeze` con URLs privadas de índices) | 🟡 Medio | Logs con **rutas relativas + metadatos** (tamaño, fecha), nunca contenido; el freeze de rescate se guarda como archivo, no se vuelca al log; sin secrets ni tokens de índices en consola/log. (Hereda `relocate.md` §1.9.) |

---

## 3. Recomendaciones de uso seguro

1. **Pasar `-DryRun` primero** y leer la lista de candidatos: verificar que solo hay regenerables reales (nada trackeado, ningún `build/`/`dist/` con fuentes) y los tamaños cuadran.
2. **Partir de `git limpio`** (commit/stash previo, RF-13): así los parches `patch-package`, los manifiestos y los `dist/` versionados están a salvo en el historial antes de borrar nada.
3. **Responder No por defecto ante la duda** en la pregunta global; limpiar cachés primero y decidir `.venv`/`node_modules` app por app con su confirmación separada.
4. **Cerrar/desactivar venvs activos** antes de la limpieza (`deactivate`; RF-14 `Suspend-AppLocks` lo cubre con confirmación). Nunca borrar el venv de la terminal en uso.
5. **Verificar el manifiesto** de cada app con `.venv` (`requirements.txt`/`lock` fijado) y el lockfile + `patches/` commiteado de cada app con `node_modules` antes de aceptar su borrado.
6. **Guardar el `pip freeze` de rescate** (se genera solo antes de borrar; conservarlo con la app movida hasta que la recreación pase tests).
7. **Recrear en la ruta nueva** (`src\<App>\.venv`, `npm ci` en `src\<App>\`) con los comandos exactos del informe; pasar tests antes de dar la app por terminada.
8. **Guardar el log de limpieza** (qué se borró por app + decisiones S/N/T/C): es la única prueba de qué se autorizó y la base para auditar la fatiga (§1.5).

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO ampliar la allowlist "de paso"** (agregar `*.log`, `out/`, `temp/`, `assets/` o patrones con comodines amplios): cada nombre nuevo es una colisión futura; la lista es fija y cualquier ampliación es decisión documentada aparte.
- ❌ **NO matchear por substring ni borrar recursivo ciego** (`-Include *build*`, `-Recurse` sin nivel): solo nombres exactos bajo `<App>\`.
- ❌ **NO borrar lo git-trackeado**: si `git ls-files` lo lista, se conserva y se mueve con la app, sin excepciones.
- ❌ **NO borrar el `.venv` activo** sin `deactivate` previo verificado; ni el venv ajeno al lote.
- ❌ **NO borrar `.venv` sin manifiesto** sin aviso "irreproducible" + confirmación separada + `pip freeze` de rescate previo.
- ❌ **NO meter el `.venv` en el "sí a todo"** de cachés: confirmación separada siempre.
- ❌ **NO borrar `node_modules` con `patches/` sin commitear** ni sin lockfile; ni asumir red disponible para `npm ci`/`pip install` (preguntar por el caso offline).
- ❌ **NO usar `[T]odos` sin leer** el resumen agregado (equivale a bypass de hecho sobre un borrado irreversible); `[T]` de una fase no autoriza otras fases.
- ❌ **NO agregar flag que saltee la confirmación** (ni reutilizar `-Force` del bootstrap para la limpieza: `-Force` no aplica, como en RF-14).
- ❌ **NO limpiar en modo no interactivo** (fail-closed: informa, no borra) ni simular consola para forzarlo.
- ❌ **NO escanear fuera de las apps candidatas** (nunca `Documentacion/`, `.specify`, `src\` ajeno, raíz del proyecto).
- ❌ **NO volcar contenido, freezes ni secrets** al log/consola/CI (solo rutas relativas + metadatos).
- ❌ **NO tocar `plataformador-bootstrap.ps1` en esta tarea** (standalone hasta validación OK; heredado de RF-13).

---

## 5. Checklist de seguridad para la limpieza (extiende `relocate.md` §5)

- [ ] `-DryRun` lista candidatos exactos (ruta relativa + tamaño + estado git) con cero escrituras, cero red.
- [ ] `Find` solo bajo apps candidatas validadas (`-AppDirs` con nombres simples + denylist + containment de RF-13).
- [ ] Allowlist fija de nombres exactos (Python + Node + general + `.venv/`); sin substrings, sin recursivo ciego, sin ampliaciones ad hoc.
- [ ] Gate git-trackeado: lo versionado se excluye con aviso (se conserva y se mueve).
- [ ] Pregunta global ANTES de S/N/T/C, con resumen agregado visible; default seguro = No limpiar; No = mueve todo (comportamiento anterior).
- [ ] Confirmación separada y explícita para cada `.venv` (fuera del "sí a todo" de cachés).
- [ ] `.venv` activo → `deactivate` previo obligatorio y verificado (RF-14); sin `deactivate` → excluir con aviso persistente.
- [ ] `.venv` sin manifiesto → aviso "irreproducible" + confirmación separada + `pip freeze` de rescate previo fuera del árbol.
- [ ] `node_modules`: lockfile + `patches/` commiteado verificados; aviso de coste red/tiempo y caso offline.
- [ ] `[T]` con alcance solo de su fase; sin flag de bypass; `-Force` no aplica a la limpieza.
- [ ] No interactivo → informa, no borra. Limpieza por app, secuencial, idempotente al reintentar.
- [ ] Log por app (qué se borró + tamaño + fecha + decisiones) sin respaldo (regenerables) pero con freeze de rescate para venvs.
- [ ] Tras mover: comandos de recreación exactos en `src\<App>\` (`python -m venv` + `pip install -r` fijado; `npm ci`) + tests antes de cerrar.
- [ ] Containment del borrado (ruta canónica dentro de `<App>\`); `Documentacion/` intacta; bootstrap intacto.
- [ ] Logs solo rutas relativas + metadatos; sin contenido, freezes ni secrets.

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** La limpieza es el paso correcto antes del movido (mover gigas regenerables es absurdo cuando se recrean con dos comandos en la ruta nueva), y el diseño trae los controles estructurales adecuados: allowlist fija de nombres exactos, pregunta global antes de S/N/T/C con salida No = comportamiento anterior, `deactivate` previo vía RF-14, log sin respaldo pero documentado como tal, recreación con comandos exactos en `src\<App>`, nunca `Documentacion/`, `-DryRun` sin borrado.

Los dos riesgos que deben **tratarse como severidad crítica innegociable** durante la implementación (a cargo de `devops`/`qa-senior`) son:

1. **Borrar no-regenerable por coincidencia de nombre** (riesgo 1 🔴) — `build/`/`dist/` con fuentes o versionados se pierden sin respaldo; la mitigación (nombres exactos + nivel + **gate git-trackeado que excluye con aviso** + resumen visible + `DryRun` demostrable) debe quedar en los criterios de aceptación, no solo en la doc.
2. **Eliminar el `.venv` activado** (riesgo 2 🔴) — rompe la sesión a mitad de ejecución y contamina todo lo posterior; la mitigación (orden detectar → `deactivate` verificado → limpiar, fail-closed excluyendo el venv activo, reutilizando `Test-ActiveVenv`/`Suspend-AppLocks`) debe quedar en los criterios de aceptación, no solo en la doc.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- nombres exactos + nivel + gate git-trackeado (lo versionado se conserva) + containment a apps candidatas;
- `deactivate` previo verificado para el venv activo (fail-closed: excluir con aviso si se rechaza);
- pre-chequeo de manifiesto + `pip freeze` de rescate + confirmación separada para `.venv` sin manifiesto;
- pre-chequeos Node (lockfile + `patches/` commiteado) + aviso offline/red;
- pregunta global informada con default No + confirmación separada para `.venv` + `[T]` por fase + no-interactivo no borra + `DryRun` cero escrituras/red;
- log por app + comandos de recreación exactos en `src\<App>\` + tests antes de cerrar;
- `qa-senior` valide con `-DryRun` + fixtures en `$env:TEMP` (incluyendo señuelos: `build/` trackeado que debe conservarse, venv activo que debe excluirse, venv sin manifiesto con aviso, `patches/` sin commitear) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — RF-15, criterio 11 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[RELOCATE]` (limpieza aprobada 2026-09-19, `.venv` se elimina).
- `Documentacion/Agents_IA_TECH/seguridad/relocate.md` — RF-13 (formato heredado §§1-6 + riesgos de movido, `[T]odos`, rollback, traversal, fuga por log).
- `Documentacion/Agents_IA_TECH/seguridad/relocate-locks.md` — RF-14 (`deactivate`, kill `git.exe`, `pip install`, reactivación; §1.3 recreación y §1.5 fatiga aplican aquí).
- `Documentacion/Agents_IA_TECH/seguridad/huerfanos.md` — Default seguro + confirmación para lo destructivo (precedente aplicado al default No limpiar).
