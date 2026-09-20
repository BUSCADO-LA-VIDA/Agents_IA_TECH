# 🔒 Seguridad del diseño: reubicación a `src\` (`relocate-apps-to-src.ps1`, RF-13)

> Revisión **de seguridad del DISEÑO** del script standalone de reubicación (RF-13 + criterio 9): mover apps de la raíz a `src\<App>` con `Move-AppToSrc` + `Confirm-AppRelocation` (flags `-AppDirs`/`-DryRun`/`-ProjectRoot`, sin bypass; S/N/T/C en interactivo, no-mueve en no interactivo; `.venv` reportado "a recrear"; pre-chequeos + log + rollback manual + post-movido; nunca `Documentacion/`; bootstrap intacto).
> Enfocada en: **mover código equivocado, `.venv` en uso, corte a mitad del movido, fatiga de confirmación (`[T]odos`), rollback incompleto y versionado parcial `src\<App>`**.
> Fuente: `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-13, criterio 9) y `pendientes-implementacion.md` (tarea `[RELOCATE]`, plan aprobado 2026-09-19).
> Autor: `security-auditor` (fase documental — tarea `[RELOCATE]`)

---

## 1. Análisis de riesgos del diseño de reubicación

### 1.1 Riesgo de mover el código equivocado (`-AppDirs` mal listado, typo)

`-AppDirs` acepta "cualquier proyecto" por lista libre o manifest. Un typo (mayúsculas vs minúsculas, guion vs guion bajo en el nombre de una app), una carpeta que ya no es una app (renombrada, vaciada, convertida en enlace) o un nombre que colisiona con otra carpeta de la raíz (`src`, `scripts`, `Documentacion`) desplaza código ajeno a `src\<App>`. El daño es máximo porque el movido es destructivo en origen (ya no está donde estaba) y el post-movido rompe imports/paths del proyecto entero.

**Puntos de validación necesarios:**
- **Lista visible antes de actuar**: por cada app, mostrar origen canónico, destino canónico, tamaño y estado git, antes de pedir S/N/T/C.
- **Pre-chequeos fail-closed por app**: origen existe y es directorio real; destino libre (si existe → abortar esa app, nunca fusionar/sobrescribir); `-AppDirs` solo acepta **nombres simples** (sin `\`, `/`, `..`, `:`, rutas absolutas).
- **`-DryRun` previo obligatorio en la práctica**: solo previsualiza (cero escrituras) y permite detectar el typo antes del modo real.
- Denylist explícita: nunca aceptar `Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext/spec-kit`, `.github/`, `.opencode/`, `.doc_agents/` como `-AppDirs` (ver 1.7).

### 1.2 Riesgo de `.venv` en uso durante el movido (movido parcial/corrupto)

`.venv/` contiene miles de archivos pequeños, algunos con **locks o handles abiertos** si hay un proceso Python corriendo (servidor, job, intérprete con `.dll`/`.pyd` cargados en Windows). `Move-Item` sobre un árbol con archivos bloqueados produce un **movido parcial**: parte queda en la raíz, parte en `src\<App>`, y el `.venv` queda inutilizable sin que el log refleje un éxito real.

**Puntos de validación:**
- **Pre-chequeo de procesos**: detectar intérpretes Python corriendo desde `<App>\.venv` (o con cwd dentro de la app) y **abortar esa app** con aviso ("cierra procesos Python primero") en lugar de mover a medias.
- **Advertencia explícita siempre**: aunque no haya locks detectables, recordar que `.venv` se mueve pero queda "a recrear" (paths absolutos internos rotos por diseño, RF-13).
- Mover `.venv` **junto con la app, nunca por separado**; no intentar "repararlo" in situ (recreación con comandos exactos, fuera del script).

### 1.3 Riesgo de corte a mitad del movido (pérdida de luz, kill del proceso)

Un corte (apagón, `Ctrl+C`, kill, cierre del terminal) entre el inicio y el fin del `Move-Item` deja el **estado mixto**: mitad en raíz, mitad en `src\<App>`. Sin criterio de "qué es éxito", el usuario no sabe si reintentar, revertir o continuar, y un segundo intento puede sobrescribir o duplicar.

**Puntos de validación:**
- **Transacción por app**: una app cada vez (nunca en paralelo); verificar post-movido (origen vaciado/ausente + destino completo) **antes de pasar a la siguiente**.
- **Log transaccional**: registrar por app `origen → destino + fecha + tamaño + estado (OK/ABORTADO/INTERRUMPIDO)`; ante estado ambiguo, el log dice qué reintentar.
- **Nunca sobrescribir**: si el destino existe al reintentar (resto de un corte previo) → abortar esa app y pedir resolución manual, no fusionar.
- Recomendar **corriente/UPS + terminal estable** para el modo real; `-DryRun` no necesita estas precauciones.

### 1.4 Riesgo de fatiga de confirmación (`[T]odos` usado sin leer = bypass de hecho)

La spec prohíbe el bypass por flag (sin `-Force`/`-Yes`), pero `[T]odos los restantes` en interactivo **equivale a un bypass voluntario**: el usuario lo pulsa sin leer la lista y el script mueve todo lo restante sin confirmación individual. Es el riesgo humano más probable.

**Puntos de validación:**
- Mantener la **prohibición de flag de bypass** (por diseño, RF-13) y documentarla en el README (ya existe).
- Mostrar la **lista completa numerada antes del primer prompt** (qué se va a mover, tamaños, estado git) para que `[T]` sea informado.
- `[T]` solo aplica a **los restantes pendientes**, nunca retroactivo; `[C]` cancela todo sin mover nada más; cada movido individual queda en log aunque venga de `[T]`.
- En modo **no interactivo (sin consola) → NO mover, informar** (fail-closed, criterio 9): ningún CI puede mover sin humano.

### 1.5 Riesgo de rollback incompleto (mover de vuelta sin el log exacto)

El rollback es **manual documentado** (mover `src\<App>` → raíz). Si el usuario lo hace "de memoria" (sin el log exacto, con otro nombre, a otra raíz, o después de haber creado archivos nuevos en `src\<App>`), el rollback deja **restos en ambos lados** y el repo queda peor que antes del corte o del movido erróneo.

**Puntos de validación:**
- El log es la **única fuente de verdad del rollback**: `origen exacto → destino exacto + fecha`; el informe post-movido debe incluir el **comando de rollback concreto por app** (no una instrucción genérica).
- Rollback **por app y en orden inverso**; verificar destino libre en raíz antes de devolver (si la raíz se reocupó → abortar con aviso, no sobrescribir).
- Advertir que lo creado **después** del movido dentro de `src\<App>` también se devuelve (o se pierde si se devuelve una copia vieja).

### 1.6 Riesgo de `src\<App>` versionado parcial (commit a medias, estado mixto raíz+src)

Tras mover 1 de N apps (o con `[N]o` en algunas), el repo queda en **estado mixto**: parte en raíz, parte en `src\`. Un commit en ese momento congela la mezcla en el historial: los imports rotos quedan versionados, el diff es enorme e irreversible sin `revert`, y otros clones obtienen el estado roto.

**Puntos de validación:**
- **Pre-chequeo `git limpio` recomendado** (criterio RF-13): si hay cambios sin commitear, advertir y sugerir commit/stash antes de mover.
- **Regla de commit atómico**: mover + verificar + commit en una sola unidad por app (o por lote confirmado); nunca commitear a medias del lote.
- Post-movido advierte **imports/paths/configs + tests a revisar** (criterio 9): no dar por terminado hasta que los tests pasen en la nueva ubicación.

### 1.7 Riesgo de alcance fuera de lo sagrado (`Documentacion/`, `.specify`, `proyect_ext/spec-kit`)

La spec ordena **nunca tocar `Documentacion/`** y dejar `proyect_ext/spec-kit` en la raíz. Pero `-AppDirs` es lista libre: si alguien lista `Documentacion`, `.specify` o `spec-kit`, el script obedecería y rompería el guardrail 1 (frontera kit ↔ app) y la decisión de la adenda ADR-0003.

**Puntos de validación:**
- **Denylist dura en código**: rechazar `Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext`, `.github/`, `.opencode/`, `.doc_agents/`, `.git`, `.venv` suelto como entrada de `-AppDirs` (fail-closed: abortar esa entrada con aviso).
- `-DryRun` debe demostrarlo: el informe permite verificar que ningún origen/destino cae en `Documentacion/<AppName>/`.

### 1.8 Riesgo de path traversal / escape de `src\` (entrada maliciosa o errónea en `-AppDirs`)

Si `-AppDirs` acepta `..\otra-carpeta`, rutas absolutas (`C:\...`) o un symlink/junction que apunta fuera del proyecto, el destino compuesto `src\<App>` puede resolverse **fuera de `src\`** y el `Move-Item` escribir en ubicación arbitraria.

**Puntos de validación:**
- Solo **nombres simples validados** (sin separadores ni `..` ni absolutas); rechazar symlinks/junctions como origen (o mover el enlace como tal con aviso, nunca escribir a través de él).
- **Containment-check**: tras componer origen y destino canónicos, verificar que el origen está dentro de `<ProjectRoot>` y el destino dentro de `<ProjectRoot>\src\` (fail-closed: si escapa, abortar ese movido).

### 1.9 Riesgo de fuga por log / informe (secret o ruta privada en consola)

El log (`origen → destino + fecha`) y el informe post-movido (tamaños, estado git, comandos de recreación del `.venv`) pueden volcar **rutas absolutas con nombre de usuario** (`C:\Users\<nombre>\...`) o variables de entorno con secrets si se copian tal cual al log o a `pendientes-implementacion.md`.

**Puntos de validación:**
- Logs e informes con **rutas relativas al `<ProjectRoot>` + metadatos** (tamaño, fecha); nunca contenido de archivos ni secrets.
- No `Get-Content` de código movido al informe; el log registra el movido, no su contenido.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Mover código equivocado** (`-AppDirs` mal listado, typo que apunta a otra carpeta) → desplaza código ajeno, rompe imports del proyecto | 🔴 Crítico | Lista visible (origen/destino canónicos, tamaño, estado git) antes de S/N/T/C; pre-chequeos fail-closed por app (origen existe, destino libre, nunca fusionar); `-AppDirs` solo **nombres simples**; denylist dura (§1.7); `-DryRun` previo. |
| 2 | **Corte a mitad del movido** (pérdida de luz, kill) → mitad en raíz, mitad en `src\`, estado ambiguo | 🔴 Crítico | Transacción **por app** (una cada vez + verificación post-movido antes de la siguiente); log transaccional (OK/ABORTADO/INTERRUMPIDO); **nunca sobrescribir** al reintentar (destino ocupado → abortar + resolución manual). |
| 3 | **`.venv` en uso** (procesos Python con archivos abiertos) → movido parcial/corrupto | 🟠 Alto | Pre-chequeo de procesos Python con cwd/handles en la app → **abortar esa app** con aviso; `.venv` se mueve con la app pero se reporta "a recrear" con comandos exactos; no recrear solo. |
| 4 | **Fatiga de confirmación** (`[T]odos` sin leer = bypass de hecho) → mueve todo sin revisión real | 🟠 Alto | Sin flag de bypass **por diseño**; lista completa numerada antes del primer prompt; `[T]` solo a restantes pendientes + log por app aunque venga de `[T]`; `[C]` cancela sin mover más; no interactivo → **NO mueve**. |
| 5 | **Rollback incompleto** (devolver sin el log exacto) → restos en ambos lados, peor que el inicio | 🟠 Alto | Log como única fuente de verdad (origen→destino+fecha); informe con **comando de rollback concreto por app**; rollback por app en orden inverso + verificar destino libre en raíz antes de devolver. |
| 6 | **`src\<App>` versionado parcial** (commit a medias) → mezcla raíz+src congelada en historial, clones rotos | 🟠 Alto | Pre-chequeo `git limpio` recomendado antes de mover; **commit atómico** (mover + verificar + commit por app/lote); post-movido advierte imports/paths/configs + tests antes de dar por terminado. |
| 7 | **Alcance fuera de lo sagrado** (`Documentacion/`, `.specify`, `proyect_ext/spec-kit` en `-AppDirs`) → viola guardrail 1 y adenda ADR-0003 | 🟠 Alto | **Denylist dura** (rechazar `Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext`, `.github/`, `.opencode/`, `.doc_agents/`, `.git`); `-DryRun` demuestra que nada cae en `Documentacion/<AppName>/`. |
| 8 | **Path traversal / escape de `src\`** (`..`, absoluta, symlink en `-AppDirs`) → escritura fuera del proyecto | 🟠 Alto | Solo nombres simples (rechazar separadores, `..`, absolutas); no seguir symlinks/junctions; **containment-check** (origen dentro de `<ProjectRoot>`, destino dentro de `<ProjectRoot>\src\`; fail-closed). |
| 9 | **Fuga por log/informe** (rutas absolutas con usuario, secrets en CI) | 🟡 Medio | Logs con **rutas relativas + metadatos** (tamaño, fecha); nunca contenido ni secrets; sin `Get-Content` del código movido al informe. |

---

## 3. Recomendaciones de uso seguro

1. **Usar `-DryRun` antes del modo real**; revisar que la lista solo contiene las apps queridas (origen/destino canónicos, tamaños) y nada de `Documentacion/`, `.specify` ni `proyect_ext/spec-kit`.
2. **Responder por app (`[S]`/`[N]`)**; usar `[T]odos` solo cuando se entiende cada entrada de la lista numerada. `[C]` ante cualquier duda.
3. **Cerrar procesos Python** que usen `<App>\.venv` antes de mover esa app (servidores, jobs, terminales con el venv activado).
4. **Partir de `git limpio`** (commit/stash previo) y hacer **commit atómico** por app o lote confirmado tras verificar tests en la nueva ubicación.
5. **No mover en CI ni en modo no interactivo**: por diseño no mueve (informa); no construir wrappers que simulen consola para forzar el movido.
6. **Recrear `.venv`** tras el movido con los comandos exactos del informe (no reutilizar el movido: sus paths absolutos están rotos).
7. **Guardar el log del movido** (origen→destino+fecha por app): es la única base válida para el rollback manual.
8. **Revisar imports/paths/configs + pasar tests** tras cada app antes de seguir con la siguiente (no dejar el repo en estado mixto sin verificar).

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO listar en `-AppDirs`** nada que no sea una app de la raíz (`Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext/spec-kit`, `.github/`, `.opencode/`, `.doc_agents/`, `.git`, `.venv` suelto).
- ❌ **NO pasar rutas con separadores, `..`, absolutas ni symlinks** en `-AppDirs` (solo nombres simples).
- ❌ **NO agregar un flag que saltee la confirmación** en wrappers o scripts propios (el sin-bypass es por diseño, RF-13).
- ❌ **NO usar `[T]odos` sin haber leído** la lista numerada completa (equivale a bypass de hecho).
- ❌ **NO mover con procesos Python corriendo** desde el `.venv` de la app (movido parcial/corrupto).
- ❌ **NO fusionar ni sobrescribir**: si el destino `src\<App>` existe (corte previo, reintento), no mover encima; resolución manual primero.
- ❌ **NO hacer rollback "de memoria"**: solo con el log exacto (origen→destino+fecha), por app y en orden inverso.
- ❌ **NO commitear a medias** del lote (estado mixto raíz+src en el historial); commit atómico tras verificar.
- ❌ **NO reutilizar el `.venv` movido** (paths absolutos rotos); recrearlo con los comandos del informe.
- ❌ **NO volcar contenido ni secrets** al log, a la consola de CI ni a `pendientes-implementacion.md` (solo rutas relativas + metadatos).
- ❌ **NO forzar el movido en modo no interactivo** (el no-mueve es fail-closed; no simular consola).
- ❌ **NO tocar `plataformador-bootstrap.ps1` en esta tarea** (standalone hasta validación OK; la integración es decisión futura separada).

---

## 5. Checklist de seguridad para la reubicación

- [ ] `-DryRun` previo: solo previsualiza, cero escrituras (verificable en tests).
- [ ] Lista visible antes de actuar (origen/destino canónicos, tamaño, estado git) por cada app.
- [ ] `-AppDirs` solo con **nombres simples** (sin `\`, `/`, `..`, `:`, absolutas).
- [ ] Denylist dura: `Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext`, `.github/`, `.opencode/`, `.doc_agents/`, `.git` rechazados como entrada.
- [ ] Containment-check: origen dentro de `<ProjectRoot>`, destino dentro de `<ProjectRoot>\src\` (fail-closed).
- [ ] Symlinks/junctions no se siguen al mover.
- [ ] Pre-chequeos por app: origen existe y es directorio real; **destino libre** (ocupado → abortar, nunca fusionar).
- [ ] Procesos Python con handles en la app detectados → **abortar esa app** con aviso.
- [ ] Confirmación S/N/T/C por app en interactivo; **sin flag de bypass** en el script ni en wrappers.
- [ ] No interactivo (sin consola) → **NO mueve, informa**.
- [ ] Transacción por app (una cada vez + verificación post-movido antes de la siguiente); nunca sobrescribir al reintentar.
- [ ] Log por app (`origen → destino + fecha + tamaño + estado`) + comando de rollback concreto en el informe.
- [ ] Rollback manual solo desde el log, por app y en orden inverso, verificando destino libre.
- [ ] `.venv` reportado "a recrear" con comandos exactos; no se recrea solo ni se reutiliza el movido.
- [ ] Post-movido advierte **imports/paths/configs + tests**; commit atómico tras verificar (no a medias).
- [ ] Logs/informes solo con **rutas relativas + metadatos**; sin contenido ni secrets.
- [ ] `Documentacion/` intacta; `proyect_ext/spec-kit` sigue en la raíz; bootstrap intacto (cero cambios en esta tarea).
- [ ] `npx ecc-agentshield scan` si los cambios tocan `.github/` (no esperado en esta tarea).

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** El diseño de RF-13 es fundamentalmente seguro para una operación destructiva en origen: script standalone (bootstrap intacto), sin flag de bypass por diseño, S/N/T/C por app con fail-closed en no interactivo, `-DryRun` que solo previsualiza, pre-chequeos + log transaccional + rollback manual documentado, `.venv` reportado "a recrear" en lugar de reparado a ciegas, y `Documentacion/` explícitamente fuera de alcance.

Los dos riesgos que deben **tratarse como severidad crítica innegociable** durante la implementación (a cargo de `devops`/`qa-senior`) son:

1. **Mover el código equivocado** (riesgo 1 🔴) — un typo en `-AppDirs` desplaza código ajeno y rompe el proyecto; la mitigación (nombres simples + lista visible + destino libre + denylist + `-DryRun` previo) debe quedar en los criterios de aceptación, no solo en la doc.
2. **Corte a mitad del movido** (riesgo 2 🔴) — el estado mixto raíz+src sin criterio de éxito es irrecuperable sin log; la mitigación (transacción por app + verificación post-movido + log OK/ABORTADO/INTERRUMPIDO + nunca sobrescribir) debe quedar en los criterios de aceptación, no solo en la doc.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- nombres simples + denylist dura + containment-check + destino libre (nunca fusionar/sobrescribir);
- transacción por app + log transaccional + rollback concreto por app desde el log;
- sin flag de bypass + S/N/T/C por app + no interactivo no mueve + `-DryRun` cero escrituras;
- pre-chequeo de `.venv` en uso (abortar con aviso) + reporte "a recrear" con comandos exactos;
- `git` limpio recomendado + commit atómico + post-movido con imports/paths/configs + tests;
- logs solo con rutas relativas y metadatos (sin contenido ni secrets);
- `qa-senior` valide con `-DryRun` + fixtures en `$env:TEMP` (S/N/T/C, no-interactivo no mueve, venv reportado, estructura preservada, bootstrap intacto) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — RF-13, criterio 9 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[RELOCATE]` (plan aprobado 2026-09-19).
- `Documentacion/Agents_IA_TECH/seguridad/huerfanos.md` — Formato y riesgos aplicables (containment-check, fuga por log, detector acotado, default seguro).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — Adenda 2026-09-19 (RNF-04 vs opt-in confirmado).
- `README.md` — Sección Reubicación (versión 2026-09-19).
