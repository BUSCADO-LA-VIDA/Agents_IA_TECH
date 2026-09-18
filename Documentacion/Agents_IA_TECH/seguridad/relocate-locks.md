# 🔒 Seguridad del diseño: auto-desactivar/reactivar venv + pausar git (`Suspend-AppLocks` + `Restore-AppLocks`, RF-14)

> Revisión **de seguridad del DISEÑO** de la extensión RF-14 de `relocate-apps-to-src.ps1` (RF-14 + criterio 10): `Suspend-AppLocks` (antes de mover: desactiva el venv en-sesión con confirmación + detiene `git.exe` puntuales con cwd verificado dentro de la app a mover, con confirmación; nunca el proceso `Code`) + `Restore-AppLocks` (tras mover: recrea el venv con confirmación si fue movido + activa el nuevo `src\<App>\.venv`; si la app no se movió, reactiva el mismo; git se redescubre solo, se informa). Cada acción pregunta, sin bypass, `-Force` no aplica, No a todo = avisos, `-DryRun` informa sin mutar. Mutar la sesión del llamante (`deactivate`/`Activate.ps1` en la misma sesión) es comportamiento esperado y documentado.
> Enfocada en: **mutación de la sesión del llamante, kill del `git.exe` equivocado (PID reutilizado), recreación del venv con `pip install` (ejecución de código + red + tiempo), reactivación de un venv distinto al esperado (ruta mal construida), y fatiga de confirmación (S sin leer)**.
> Fuente: `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-14, criterio 10) y `pendientes-implementacion.md` (tarea `[RELOCATE]`, extensión pedida por el usuario 2026-09-19).
> Complementa: `seguridad/relocate.md` (RF-13: movido, `.venv` en uso, corte, `[T]odos`, rollback, versionado parcial, alcance, traversal, fuga por log) — no la sustituye.
> Autor: `security-auditor` (fase documental — tarea `[RELOCATE]`, extensión RF-14)

---

## 1. Análisis de riesgos del diseño de `Suspend-AppLocks` + `Restore-AppLocks`

### 1.1 Riesgo de mutar la sesión del llamante (`deactivate` / dot-source `Activate.ps1`)

`Suspend` desactiva el venv activo y `Restore` reactiva otro (o el mismo) **en la misma sesión** donde corre el script. Eso cambia `PATH`, `VIRTUAL_ENV`, `PROMPT`/`prompt function` y variables auxiliares (`PYTHONHOME`, `_OLD_*`) del usuario **tras el script**: al terminar, la terminal ya no está como estaba (otro intérprete por defecto, otro prompt, `pip`/`python` resolviendo a otro sitio). Si el usuario tenía el venv para otro trabajo, o tenía variables ajustadas a mano, el cambio silencioso provoca ejecuciones posteriores contra el intérprete equivocado (instalar paquetes en el venv ajeno, correr tests con dependencias distintas).

**Puntos de validación necesarios:**
- **Comportamiento declarado, no sorpresa**: documentar en README + aviso en consola que la sesión **será mutada** (qué cambia: `PATH`, `VIRTUAL_ENV`, prompt) y que es reversible (`deactivate` + activar el anterior).
- **Guardar y mostrar el estado previo**: al suspender, registrar `VIRTUAL_ENV`/`CONDA_PREFIX` previo + `PATH` resumido (no volcar el `PATH` entero con rutas de usuario al log — solo qué venv estaba activo) e informar al restaurar cuál se activa.
- **Reactivación verificada**: tras dot-source, comprobar que `python`/`pip` resuelven dentro del venv esperado (ruta canónica bajo `src\<App>\.venv` o la original si no se movió); si no resuelve ahí → avisar y no dar por restaurado.
- **Solo venvs de apps a mover**: nunca desactivar/reactivar un venv ajeno al lote (p. ej. venv del proyecto fuera de candidatas o fuera del proyecto → solo aviso informativo, sin mutar).

### 1.2 Riesgo de matar el `git.exe` equivocado (PID reutilizado entre detección y kill)

El flujo es detectar (`Get-Process git` + cwd dentro de la app) → preguntar → matar. Entre la detección y el `Stop-Process` el SO puede **reutilizar el PID**: el `git` original terminó y otro proceso (u otro `git` de otra carpeta, o incluso un binario distinto si se filtra solo por nombre) ocupa el mismo Id. Verificar solo el cwd una vez no basta: se puede matar un `git` de otra app, un `git` del propio kit en mitad de un `commit`, o en el peor caso un proceso no-git si el filtro es laxo.

**Puntos de validación necesarios:**
- **Revalidación atómica en el momento del kill**: justo antes de `Stop-Process`, reobtener el proceso por `Id` y verificar **las tres cosas**: `ProcessName -eq 'git'` + `Id` coincide + `StartTime` coincide con la detección + cwd/exe sigue dentro de la app a mover. Si algo difiere → **abortar ese kill** con aviso (fail-closed), nunca matar "por si acaso".
- **Allowlist estricta de binario**: solo `git.exe` (nombre + ruta del ejecutable bajo Git para Windows o el `PATH` conocido); **denylist dura: nunca `Code.exe`/`Code - Insiders`**, nunca `pwsh`/`powershell`, nunca `python`. El filtro por nombre solo no es suficiente: comprobar `Path` del proceso cuando sea accesible.
- **Kill suave primero**: `CloseMainWindow`/espera breve + `Stop-Process` solo si sigue vivo; timeout corto; nunca `-Force` indiscriminado contra todo el lote de golpe.
- **Un kill por confirmación**: cada `git.exe` puntual se confirma (o lote explícito con lista de PID + cwd visibles); No a todo = aviso y el movido sigue con locks bajo responsabilidad del usuario (comportamiento ya especificado en RF-14).

### 1.3 Riesgo de recrear el venv + `pip install` (ejecuta código, necesita red, tarda)

`Restore-AppLocks` recrea con `python -m venv` y reinstala dependencias. `pip install` **ejecuta código arbitrario** (`setup.py`, build backends, hooks de `pyproject.toml`) de cada paquete, idealmente fijado pero en la práctica a veces con rangos abiertos (`>=`, `*`). Además **necesita red** (índice PyPI alcanzable) y **tarda minutos** (compilación de wheels, `numpy`/`cryptography`/etc.), tiempo durante el cual el repo queda en estado mixto si el usuario interrumpe. Si el `requirements.txt` no existe o está sin fijar, la recreación produce un entorno **distinto** al original (versiones nuevas, APIs rotas) y los tests posteriores fallan por causas ajenas al movido.

**Puntos de validación necesarios:**
- **Confirmación separada para recrear y para instalar**: una pregunta para `python -m venv` (barato, local) y otra para `pip install` (caro, red, ejecuta código). El usuario puede aceptar el venv vacío y reinstalar luego a mano.
- **Solo desde fuente fijada y dentro de la app**: instalar únicamente desde `requirements.txt`/`requirements.lock` **de la app movida** (ruta contenida en `src\<App>\`, verificada); si no hay manifiesto o hay rangos sin fijar → **avisar y no instalar** (venv vacío + instrucciones), nunca `pip install <paquete>` libre ni flags `--extra-index-url` no declarados.
- **Sin bypass, con tiempo visible**: informar duración estimada + necesidad de red antes de preguntar; `-DryRun` solo informa qué instalaría (cero red, cero ejecución).
- **Log sin secrets**: registrar qué manifiesto se usó + resultado (OK/OMITIDO/ERROR), nunca tokens de índices privados ni contenido de `.env`.

### 1.4 Riesgo de reactivar un venv distinto al esperado (ruta nueva mal construida)

La ruta del nuevo venv se **compone** (`<ProjectRoot>\src\<App>\.venv\Scripts\Activate.ps1`). Un error de composición (nombre de app con separador, `ProjectRoot` con `/` vs `\`, app renombrada entre suspend y restore, movido omitido con `[N]o` pero restore asumiendo movido) hace que el dot-source apunte a **un venv ajeno** (otra app, un `.venv` viejo huérfano) o a **una ruta inexistente** (error que deja la sesión sin venv y con `VIRTUAL_ENV` colgando). Dot-sourcer un `Activate.ps1` ajeno ejecuta su contenido en la sesión del llamante (modifica `PATH`/prompt con rutas de otro proyecto).

**Puntos de validación necesarios:**
- **Construcción canónica + containment-check**: componer con `Join-Path`, resolver a ruta canónica y verificar que cae dentro de `<ProjectRoot>\src\<App>\` (o la raíz original si la app no se movió); si escapa o no existe → **no dot-sourcer**, aviso + instrucciones manuales.
- **Verificar el artefacto antes de ejecutarlo**: el `Activate.ps1` debe existir y ser archivo real (no directorio, no symlink fuera del proyecto); opcionalmente comprobar que su padre contiene `pyvenv.cfg` (marca de venv real) antes del dot-source.
- **Coherencia suspend↔restore por app**: el restore de cada app usa el **resultado real** de esa app (movida / omitida / abortada del log), nunca asume "todas se movieron". App omitida con `[N]o` → reactiva el original, no el de `src\`.
- **Fallo seguro**: si la activación falla, restaurar el estado previo documentado (aviso de volver a activar el anterior a mano) en lugar de dejar la sesión a medias sin aviso.

### 1.5 Riesgo de fatiga de confirmación (tantas preguntas que el usuario responde S sin leer)

RF-14 multiplica las preguntas: por cada app, hasta 4 (desactivar, pausar git, recrear, reactivar) **además** de la S/N/T/C del movido (RF-13). Con 5 apps son ~25 prompts. El usuario entra en modo "S a todo" y autoriza kills e instalaciones sin leer, convirtiendo el sin-bypass en bypass de hecho (misma familia que el riesgo 4 de `relocate.md` con `[T]odos`).

**Puntos de validación necesarios:**
- **Resumen previo agrupado**: antes del primer prompt, mostrar la lista numerada de acciones pendientes (qué venv se desactivará, qué PIDs de `git` se pausarán con su cwd, qué venvs se recrearán/instalarán) para que cada S sea informado.
- **Granularidad con atajos seguros**: mantener confirmación por acción (sin flag de bypass, `-Force` no aplica) pero permitir respuestas de lote con alcance explícito y seguro (`[T]odos los restantes` solo para la acción actual, nunca transversal a desactivar+matar+instalar de golpe; `[C]` cancela todo).
- **No a todo = avisos, no silencio**: cada No deja aviso persistente en el informe final (qué quedó sin desactivar/sin pausar/sin recrear y qué riesgo asume el usuario), para que el "S sin leer" y el "N sin leer" queden ambos trazados.
- **Orden que minimiza preguntas inútiles**: no preguntar `pausar git` si no hay `git` detectado en esa app; no preguntar `recrear` si la app no se movió; no preguntar `reactivar` si no se desactivó nada.

### 1.6 Riesgos heredados de RF-13 que RF-14 agrava

- **`.venv` en uso (§1.2 de `relocate.md`)**: RF-14 lo mitiga (desactivar + pausar git) pero si el usuario dice No a todo, el movido sigue con locks → el aviso debe ser explícito ("mueves con locks activos, movido parcial posible").
- **`[T]odos` (§1.4 de `relocate.md`)**: un `[T]` al movido no debe propagarse automáticamente a kills/instalaciones; cada familia de acciones pregunta por separado.
- **Fuga por log (§1.9 de `relocate.md`)**: la lista de procesos (cwd, línea de comando) y el estado del venv pueden contener rutas con nombre de usuario o args con tokens → log con rutas relativas + PID/Id, nunca líneas de comando completas ni contenido de `.env`.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Matar `git.exe` equivocado** (PID reutilizado entre detección y kill; cwd verificado pero el proceso cambió) → mata un git ajeno o un proceso inocente, pierde operaciones en vuelo | 🔴 Crítico | Revalidación atómica pre-kill (`ProcessName` + `Id` + `StartTime` + cwd/exe dentro de la app; si difiere → abortar ese kill); allowlist solo `git.exe` (verificar `Path`), **denylist dura `Code`**; kill suave primero; un kill por confirmación; No = aviso. |
| 2 | **Mutar la sesión del llamante** (`deactivate`/dot-source `Activate.ps1` cambia prompt, `PATH`, `VIRTUAL_ENV` tras el script) → terminal posterior ejecuta contra el intérprete equivocado | 🟠 Alto | Comportamiento esperado y **documentado** (README + aviso en consola); guardar/mostrar estado previo; reactivación verificada (`python`/`pip` resuelven en el venv esperado); solo venvs de apps a mover. |
| 3 | **Recrear venv + `pip install` ejecuta código** (setup.py/hooks, versiones sin fijar) + necesita red + tarda minutos (interrupción = estado mixto) → entorno distinto al original o fallo a medias | 🟠 Alto | Confirmación **separada** venv (barato) vs `pip install` (caro/red/código); solo desde manifiesto **fijado dentro de la app** (contenido en `src\<App>\`); sin manifiesto/rangos abiertos → no instalar (venv vacío + instrucciones); `-DryRun` cero red/ejecución; log sin secrets. |
| 4 | **Reactivar venv distinto al esperado** (ruta nueva mal construida → dot-source de un venv ajeno o inexistente, ejecuta su `Activate.ps1` en la sesión) → `PATH`/prompt apuntando a otro proyecto o sesión rota | 🟠 Alto | Construcción canónica (`Join-Path` + containment-check en `src\<App>\`); verificar `Activate.ps1` existe + `pyvenv.cfg` hermano; restore según **resultado real por app** (movida→nuevo, omitida→original); fallo seguro con instrucciones de retorno. |
| 5 | **Fatiga de confirmación** (~4 preguntas × N apps + S/N/T/C del movido → S sin leer = bypass de hecho) → autoriza kills/instalaciones sin revisar | 🟠 Alto | Resumen previo agrupado (venvs + PIDs/cwd + recreaciones); sin bypass (`-Force` no aplica); atajos solo intra-acción (`[T]` de la acción actual, `[C]` global); No a todo = avisos persistentes en informe final; no preguntar lo inaplicable (sin git → sin pregunta de kill; no movida → sin recrear). |
| 6 | **Matar `Code` por error** (filtro por nombre laxo o PID reutilizado cae en el editor) → cierra el IDE con trabajo sin guardar | 🔴 Crítico (evitado por diseño) | Denylist dura `Code`/`Code - Insiders` en código + verificación de `Path`; ningún kill sin revalidación; documentado en criterio 10 ("nunca `Code`"). |
| 7 | **Fuga por log/informe** (cwd absolutos con usuario, líneas de comando con tokens, `PATH` entero) | 🟡 Medio | Logs con **rutas relativas + PID/Id**; nunca líneas de comando completas, contenido de `.env` ni secrets de índices privados. |

---

## 3. Recomendaciones de uso seguro

1. **Leer el resumen previo** (venvs a desactivar, PIDs de `git` con cwd, venvs a recrear) antes de responder la primera pregunta; usar `[C]` ante cualquier duda.
2. **Responder por acción, no en piloto automático**: el `[T]` de una acción no autoriza las demás; cada kill e instalación merece su S/N.
3. **Cerrar lo que puedas antes**: si ya cerraste editores/terminales con el venv activo y no hay `git` corriendo en la app, el script no preguntará lo inaplicable.
4. **Aceptar el venv vacío cuando haya dudas**: si el manifiesto no está fijado o no hay red, di Sí al `venv`, No al `pip install`, y reinstala luego a mano con el manifiesto revisado.
5. **No forzar en no interactivo**: por diseño no muta (informa); no envolver el script para simular respuestas.
6. **Tras el restore, verificar**: `where.exe python` / `python -c "import sys; print(sys.prefix)"` debe apuntar al venv esperado (`src\<App>\.venv` si se movió).
7. **Guardar el informe final** (qué se desactivó/pausó/recreó/reactivó + avisos de cada No): es la base para volver al estado previo a mano.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO matar por PID sin revalidar** (`ProcessName` + `StartTime` + cwd/exe en el momento del kill; PID solo no basta).
- ❌ **NO matar nunca `Code`/`Code - Insiders`**, `pwsh`/`powershell` ni `python` (solo `git.exe` con cwd verificado en la app).
- ❌ **NO agregar `-Force`/flag que saltee** las confirmaciones de desactivar/pausar/recrear/reactivar (`-Force` no aplica por diseño, criterio 10).
- ❌ **NO usar `[T]` transversal** (el `[T]` del movido no autoriza kills; el `[T]` de kills no autoriza instalaciones).
- ❌ **NO dot-sourcer `Activate.ps1` sin verificar** (ruta canónica contenida en la app + archivo existe + `pyvenv.cfg` hermano; si falla → no ejecutar, aviso + manual).
- ❌ **NO `pip install` sin manifiesto fijado** ni desde fuera de la app; nunca `pip install <paquete>` libre ni índices extra no declarados.
- ❌ **NO asumir "todas se movieron"** en el restore (cada app restaura según su resultado real: movida→nuevo, omitida/abortada→original).
- ❌ **NO mutar en `-DryRun` ni en no interactivo** (solo informar; fail-closed).
- ❌ **NO volcar líneas de comando, `PATH` entero ni secrets** al log o al informe (rutas relativas + PID/Id + resultado).
- ❌ **NO ocultar la mutación de sesión** (avisar siempre qué cambió y cómo revertirlo).

---

## 5. Checklist de seguridad para `Suspend-AppLocks` + `Restore-AppLocks`

- [ ] Cada acción pregunta por separado (desactivar, pausar, recrear, reactivar); **sin bypass**; `-Force` no aplica.
- [ ] Resumen previo agrupado (venvs + PIDs/cwd + recreaciones) antes del primer prompt.
- [ ] Solo venvs de apps a mover se desactivan/reactivan (ajenos → solo informativo, sin mutar).
- [ ] Estado previo guardado y mostrado (`VIRTUAL_ENV`/`CONDA_PREFIX` anterior); mutación de sesión documentada (README + consola).
- [ ] Kill solo `git.exe` con cwd verificado dentro de la app; **denylist dura `Code`** (nombre + `Path`).
- [ ] Revalidación atómica pre-kill (`ProcessName` + `Id` + `StartTime` + cwd/exe); difiere → abortar ese kill.
- [ ] Kill suave primero; un kill por confirmación; No a todo = aviso persistente (movido con locks bajo responsabilidad del usuario).
- [ ] Recreación con confirmación separada venv vs `pip install`; solo manifiesto fijado dentro de `src\<App>\`; sin manifiesto → venv vacío + instrucciones.
- [ ] Reactivación desde ruta canónica con containment-check + `Activate.ps1` existe + `pyvenv.cfg`; verificación post-activación (`python`/`pip` resuelven en el venv esperado).
- [ ] Restore por app según resultado real (movida→`src\<App>\.venv`, omitida→original); fallo seguro con instrucciones de retorno.
- [ ] `-DryRun` informa sin mutar (cero `deactivate`, cero kills, cero red/ejecución); no interactivo no muta.
- [ ] Logs/informes con rutas relativas + PID/Id + resultado; sin líneas de comando, sin `.env`, sin secrets.
- [ ] Informe final con avisos de cada No + cómo volver al estado previo; `npx ecc-agentshield scan` si tocan `.github/` (no esperado).

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** RF-14 reduce el riesgo principal de RF-13 (`.venv` en uso → movido parcial) a cambio de dos capacidades sensibles nuevas: **matar procesos** y **mutar la sesión del llamante**. Ambas son controlables con las mitigaciones de diseño ya especificadas (cada acción pregunta, sin bypass, nunca `Code`, No a todo = avisos, `-DryRun` no muta, mutación documentada) **más dos requisitos innegociables** que deben quedar en los criterios de aceptación de la implementación (a cargo de `devops`/`qa-senior`):

1. **Revalidación atómica pre-kill** (riesgo 1 🔴): `ProcessName` + `Id` + `StartTime` + cwd/exe verificados en el momento del kill; cualquier diferencia → abortar ese kill. Sin esto, el PID reutilizado convierte una pausa quirúrgica en un kill equivocado.
2. **Denylist dura `Code` + allowlist `git.exe`** (riesgo 6 🔴 por severidad si ocurriera): ningún filtro por nombre solo; verificación de `Path` y nunca matar el editor.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- confirmación por acción + sin bypass + `-Force` no aplica + resumen previo + No a todo = avisos persistentes;
- revalidación pre-kill + allowlist `git.exe` + denylist `Code` + kill suave;
- dot-source solo desde ruta canónica contenida en la app (`Activate.ps1` + `pyvenv.cfg`) + verificación post-activación + restore según resultado real por app;
- `pip install` solo con confirmación separada + manifiesto fijado dentro de la app (si no → venv vacío + instrucciones);
- `-DryRun`/no-interactivo sin mutación + logs con rutas relativas sin secrets;
- `qa-senior` valide con fixtures en `$env:TEMP` (cada acción pregunta, kill revalidado con PID reciclado simulado, `Code` nunca tocado, ruta maliciosa contenida, `-DryRun` cero mutación, No a todo = avisos) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — RF-14, criterio 10 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[RELOCATE]`, extensión RF-14 (pedido usuario 2026-09-19).
- `Documentacion/Agents_IA_TECH/seguridad/relocate.md` — Revisión RF-13 (riesgos base: `.venv` en uso, `[T]odos`, rollback, traversal, fuga por log).
- `Documentacion/Agents_IA_TECH/seguridad/huerfanos.md` — Formato y riesgos aplicables (containment-check, fuga por log, default seguro).
