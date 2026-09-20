# 🔒 Seguridad del diseño: manejo de huérfanos en `Sync-TransversalKit` (RF-12)

> Revisión **de seguridad del DISEÑO** del manejo de huérfanos (RF-12 + criterio 8 + diagrama): detectar archivos que existen en `.github/` `.opencode/` `.doc_agents/` local pero ya no existen en el clon maestro shallow, y **preguntar ¿borrar o conservar?** (conservar = mover a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` + informar; borrar = eliminar sin respaldo; default seguro = conservar; flag `-OrphanAction Borrar|Conservar|Preguntar`; en `-DryRun` solo informa).
> Enfocada en: **borrado erróneo, exposición de secrets en el respaldo, borrado desatendido, path traversal en el movido y persistencia de huérfanos maliciosos**.
> Fuente: `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-12, criterio 8, diagrama C2–C8) y `pendientes-implementacion.md` (tarea `[HUERFANOS]`, plan aprobado 2026-09-18).
> Autor: `security-auditor` (fase documental — tarea `[HUERFANOS]`)

---

## 1. Análisis de riesgos del diseño de manejo de huérfanos

### 1.1 Riesgo de borrar el archivo equivocado (falso positivo)

El detector compara **local vs clon maestro shallow**. Un falso positivo (archivo propio del usuario, personalización local legítima, skill local, config local con credenciales inyectadas, archivo temporal del IDE) clasificado como "huérfano" y borrado con la opción **Borrar** produce **pérdida irreversible de trabajo**. El daño es máximo porque "la implementación siempre queda limpia": no hay vuelta atrás sin respaldo.

**Puntos de validación necesarios:**
- **Default seguro Conservar** (jamás auto-borrar): sin flag ni respuesta, conservar.
- **Lista visible antes de actuar**: mostrar ruta completa, tamaño, fecha y motivo ("no está en el maestro") por cada huérfano, antes de pedir la decisión.
- **Decisión por archivo + opción "omitir"** (= propio, dejarlo en su lugar); el modo lote solo como atajo explícito, nunca como presunción.
- **Confirmación explícita para Borrar** (doble confirmación en interactivo; en no interactivo ver 1.3).
- Alcance del detector **limitado a la allowlist** (`.github/`, `.opencode/`, `.doc_agents/`); nunca `Documentacion/<AppName>/`, `src/`, `tests/`, `.specify` por app.

### 1.2 Riesgo de mover secrets a una carpeta visible / versionada por error

Un huérfano puede contener credenciales (p. ej. `opencode.json` local con API key, `.vscode/mcp.json` con tokens, skill local con secret hardcodeado). Al moverlo a `revisar_manualmente\yyyymmdd\`, el secret **sigue existiendo** pero en una ubicación nueva, más visible y fuera del control habitual. Si `revisar_manualmente/` se versiona por error (commit + push), el secret queda expuesto en el historial del repo.

**Puntos de validación:**
- `revisar_manualmente/` en **`.gitignore`** desde el día uno (regla no negociable) + verificación en el script (advertir si no está ignorada).
- **Advertencia explícita** al informar el movido: "revisa antes de subir; esta carpeta puede contener credenciales; no hacer commit de `revisar_manualmente/`".
- No volcar **contenido** de huérfanos a consola/log (solo rutas y metadatos); ver 1.7.
- El informe del movido debe recordar que el respaldo **no es borrado seguro**: si el huérfano contenía un secret, rotarlo.

### 1.3 Riesgo de borrado no interactivo peligroso (`-OrphanAction Borrar` desatendido)

El flag `-OrphanAction Borrar` permite borrar sin supervisión (CI, script desatendido, `plataformador-bootstrap.ps1` invocado por otro script). Un error de detección o un maestro temporalmente incompleto (clon shallow fallido/parcial) puede borrar en lote archivos legítimos **sin que nadie lo vea**.

**Puntos de validación:**
- `-OrphanAction Borrar` en modo no interactivo exige **confirmación adicional o `-Force` conjunto** (fail-closed: sin esa combinación, degradar a Conservar).
- **Log de lo borrado** (ruta, hash, fecha, tamaño) siempre que se borra, incluso en no interactivo.
- En no interactivo sin flag explícito → **Conservar** (default seguro también aplica aquí).
- Proteger contra maestro incompleto: si el clon maestro falló o está vacío, **abortar la fase de huérfanos** (no borrar nada) en lugar de tratar "todo lo local" como huérfano.

### 1.4 Riesgo de path traversal en el respaldo (escape de `revisar_manualmente\yyyymmdd\`)

El movido reconstruye `<ESTRUCTURA_ORIGINAL>` bajo `revisar_manualmente\yyyymmdd\`. Si la ruta de origen o la reconstrucción no se valida (p. ej. nombre con `..\`, ruta absoluta, symlink/junction), el `Move-Item` puede **escribir fuera del respaldo** y sobrescribir archivos arbitrarios del proyecto.

**Puntos de validación:**
- Trabajar solo con **rutas relativas** al raíz del kit transversal; rechazar rutas absolutas y cualquier segmento `..`.
- **Containment-check**: después de componer el destino, verificar que el path canónico sigue dentro de `revisar_manualmente\yyyymmdd\` (fail-closed: si escapa, abortar ese movido).
- No seguir **symlinks/junctions** al mover; mover el enlace como tal o abortar con aviso, nunca escribir a través de él.
- Crear la carpeta de destino (`yyyymmdd\`, sufijo de hora si existe) antes del movido y validar éxito por archivo.

### 1.5 Riesgo de huérfano malicioso (archivo plantado que se "conserva")

Un archivo plantado localmente (no viene del maestro: drop manual, exfiltración previa, skill maliciosa dejada por un repo comprometido) no se borra con **Conservar**: queda en `revisar_manualmente\` a la espera de revisión. Si el usuario lo reintegra al kit sin saber su origen, el código no confiable vuelve a cargarse (skills, hooks, instructions se ejecutan/interpretan).

**Puntos de validación:**
- Informar **origen y contexto** por cada huérfano conservado: "no está en el maestro", hash (SHA256), tamaño, fecha de modificación → revisión informada.
- Recordar que `revisar_manualmente/` está **fuera de los directorios de agentes** (no se auto-carga) y debe seguir así: **no reintroducir nada sin revisión manual** (misma regla que supply chain en `plataforma-bootstrap.md` riesgo 2).
- No ejecutar ni previsualizar con intérprete el contenido del huérfano durante el flujo (solo mover + metadatos).

### 1.6 Riesgo de colisión del respaldo versionado (pérdida de evidencia)

La spec prevé `yyyymmdd\` + sufijo de hora si la carpeta del día existe. Si dos ejecuciones el mismo día generan el mismo sufijo, o el movido sobrescribe un respaldo previo con igual nombre relativo, se **pierde la evidencia** de la primera ejecución (justo lo que el respaldo debía preservar).

**Puntos de validación:**
- Sufijo **determinista y único** (fecha + hora + minutos/segundos o contador incremental) y política **nunca sobrescribir**: si el destino existe, generar variante (`_HHmmss`, `_02`, …).
- Idempotencia: repetir el bootstrap sin huérfanos nuevos **no crea carpetas vacías** ni duplica respaldos.

### 1.7 Riesgo de fuga por log / informe (secret en consola)

El flujo "informa qué se movió y dónde" y el log de borrado (1.3) pueden volcar más de la cuenta: contenido del archivo, rutas absolutas con nombre de usuario (`C:\Users\<nombre>\…`), o diffs con credenciales. Eso queda en la consola, en logs de CI y en `pendientes-implementacion.md` si se copia el detalle.

**Puntos de validación:**
- Logs e informes con **rutas relativas + metadatos** (hash, tamaño, fecha); nunca contenido ni secrets.
- No `cat`/`Get-Content` de huérfanos al informe; no `-Verbose` con contenido.

### 1.8 Riesgo de alcance fuera de la allowlist (detector toca lo sagrado)

Si la enumeración de huérfanos no está acotada, puede clasificar como "huérfano" algo de `Documentacion/<AppName>/`, `src/`, `tests/` o `.specify` por app y borrarlo/moverlo, violando el guardrail 1 (frontera kit ↔ app) y el RNF-04.

**Puntos de validación:**
- El detector solo enumera dentro de `.github/`, `.opencode/`, `.doc_agents/`; cualquier path fuera → **excluido por diseño**.
- `-DryRun` debe demostrarlo: solo informa, sin borrar ni mover, y el informe permite verificar que ningún path cae en `Documentacion/<AppName>/`.

### 1.9 Riesgo de falso positivo por artefactos de la herramienta (`.opencode/node_modules/`)

El detector compara local vs clon maestro shallow. Los **artefactos de la herramienta OpenCode** — `.opencode/node_modules/`, `.opencode/package.json`, `.opencode/package-lock.json`, `.opencode/bun.lock`, `.opencode/lib/`, `.opencode/bin/` — son **dependencias locales instaladas** que el maestro no tiene (están gitignored). Sin exclusión, todo `node_modules/` local se reporta como huérfano y el usuario recibe una lista masiva de falsos positivos que no son del kit.

**Puntos de validación:**
- El detector **excluye por diseño** los artefactos de la herramienta dentro de `.opencode/`: `node_modules/` (cualquier nivel), `package.json`, `package-lock.json`, `bun.lock`, `lib/`, `bin/`, `config.json`.
- La exclusión está **acotada a `.opencode/`** — no excluye `.github/lib/`, `.doc_agents/lib/` ni contenido real del kit (`.opencode/agents/`, `.opencode/commands/`, `.opencode/skills/`).
- El helper `Test-ToolArtifactPath` (en `Find-OrphanKitFiles`) implementa esta exclusión; verificado por `qa-senior` en `-DryRun`.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Borrar archivo equivocado** (falso positivo: propio/personalización clasificada como huérfano) → pérdida irreversible | 🔴 Crítico | Default **Conservar** (jamás auto-borrar); lista visible (ruta, tamaño, fecha, motivo) antes de actuar; decisión por archivo + **omitir** (= propio en su lugar); confirmación explícita para Borrar; detector acotado a allowlist. |
| 2 | **Secrets movidos a carpeta visible** + `revisar_manualmente/` versionada por error → exposición en repo | 🔴 Crítico | `revisar_manualmente/` en **`.gitignore`** desde el día uno + advertencia de no subirla; informe recuerda rotar secrets si el huérfano los contenía; no volcar contenido a consola/log. |
| 3 | **Borrado no interactivo** (`-OrphanAction Borrar` desatendido, maestro incompleto) → borrado en lote sin supervisión | 🟠 Alto | `-OrphanAction Borrar` no interactivo exige **confirmación o `-Force` conjunto** (si no, degradar a Conservar); **log de lo borrado** (ruta, hash, fecha); sin flag → Conservar; si el clon maestro falló/vacío → **abortar fase de huérfanos**. |
| 4 | **Path traversal en el respaldo** (`..\`, absoluta, symlink) → escritura fuera de `revisar_manualmente\yyyymmdd\` | 🟠 Alto | Solo **rutas relativas validadas** (rechazar absolutas y `..`); **containment-check** del destino canónico (fail-closed); no seguir symlinks/junctions; crear y validar carpeta destino por archivo. |
| 5 | **Huérfano malicioso conservado** y reintegrado sin saber su origen → reintroduce código no confiable | 🟡 Medio | Informar **origen + hash + fecha** por huérfano ("no está en el maestro"); `revisar_manualmente/` fuera de dirs de agentes y **no reintroducir sin revisión**; no ejecutar/previsualizar huérfanos en el flujo. |
| 6 | **Colisión del respaldo versionado** (mismo día/sufijo) → sobrescribe evidencia previa | 🟡 Medio | Sufijo **único** (hora/minutos/segundos o contador) + política **nunca sobrescribir** (variante `_HHmmss`, `_02`…); no crear carpetas vacías (idempotencia). |
| 7 | **Fuga por log/informe** (contenido, rutas absolutas con usuario, secrets en CI) | 🟠 Alto | Informes y logs con **rutas relativas + metadatos** (hash, tamaño, fecha); nunca contenido ni secrets; sin `Get-Content` de huérfanos al informe. |
| 8 | **Alcance fuera de allowlist** (detector toca `Documentacion/<AppName>/`, `src/`, `tests/`) → viola guardrail 1 / RNF-04 | 🟠 Alto | Detector solo en `.github/`, `.opencode/`, `.doc_agents/`; resto **excluido por diseño**; `-DryRun` solo informa y permite verificar que ningún path cae en `Documentacion/<AppName>/`. |
| 9 | **Falso positivo por artefactos de la herramienta** (`.opencode/node_modules/`, `package.json`, `lib/`, `bin/`) → lista masiva de huérfanos que no son del kit | 🟡 Medio | Exclusión por diseño de artefactos de la herramienta dentro de `.opencode/` (`node_modules/`, `package*.json`, `bun.lock`, `lib/`, `bin/`, `config.json`) vía `Test-ToolArtifactPath`; acotada a `.opencode/`, sin tocar contenido real del kit. |
| 10 | **.github/context-mode/ propio de cada proyecto** → no se sincroniza, no aparece como huérfano; está en `.gitignore` y se conserva en local | 🟢 Bajo | El bootstrap excluye `.github/context-mode/` de la copia (`/XD "context-mode"`); `.gitignore` lo descarta; `Find-OrphanKitFiles` lo omite por allowlist; el usuario lo conserva o descarta en local sin afectar al kit. |

---

## 3. Recomendaciones de uso seguro

1. **Usar `-DryRun` antes de aplicar** cualquier sincronización con huérfanos; revisar que la lista solo contiene paths de `.github/`, `.opencode/`, `.doc_agents/` y ninguno de `Documentacion/<AppName>/`.
2. **Responder por archivo** (borrar / conservar / omitir) en interactivo; usar el modo lote solo cuando se entiende cada entrada de la lista.
3. **Dejar el default Conservar** salvo que se esté seguro de que el huérfano es basura del maestro (nunca invertir el default a Borrar en wrappers/scripts propios).
4. **No usar `-OrphanAction Borrar` en scripts desatendidos/CI** sin `-Force` consciente + log de lo borrado revisado después.
5. **Verificar `.gitignore` cubre `revisar_manualmente/`** antes del primer sync con huérfanos; si no está ignorada, no conservar hasta corregirla.
6. **Revisar `revisar_manualmente\yyyymmdd\` con el informe** (origen + hash + fecha) antes de reintroducir o borrar definitivamente; si había secrets, rotarlos.
7. **Aborta ante maestro incompleto**: si el clon shallow falló o viene vacío, no borrar nada (todo lo local parecería huérfano).
8. **Tratar lo conservado como no confiable** (misma regla que supply chain): no ejecutar ni reactivar huérfanos sin revisión manual.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO auto-borrar**: sin flag ni respuesta, nunca borrar (default siempre Conservar).
- ❌ **NO usar `-OrphanAction Borrar` desatendido** sin `-Force` conjunto + log de lo borrado.
- ❌ **NO borrar si el clon maestro falló o está vacío** (falso "todo es huérfano").
- ❌ **NO versionar `revisar_manualmente/`** (debe estar en `.gitignore`; no hacer commit/push de su contenido).
- ❌ **NO volcar contenido de huérfanos** a consola, logs de CI ni a `pendientes-implementacion.md` (solo rutas relativas + metadatos).
- ❌ **NO reintroducir huérfanos conservados al kit** sin revisión manual (origen + hash + fecha).
- ❌ **NO ejecutar ni previsualizar con intérprete** el contenido de un huérfano durante el flujo.
- ❌ **NO permitir que el detector salga de la allowlist** (`.github/`, `.opencode/`, `.doc_agents/`); nunca `Documentacion/<AppName>/`, `src/`, `tests/`, `.specify` por app.
- ❌ **NO construir el destino del respaldo con rutas sin validar** (absolutas, `..`, symlinks); sin containment-check no hay movido.
- ❌ **NO sobrescribir respaldos previos** (misma fecha/nombre) ni crear carpetas de respaldo vacías.
- ❌ **NO invertir el default a Borrar** en wrappers o scripts propios que invoquen al bootstrap.

---

## 5. Checklist de seguridad para el manejo de huérfanos

- [ ] Sin flag ni respuesta → **Conservar** (jamás auto-borrar).
- [ ] Lista visible antes de actuar (ruta relativa, tamaño, fecha, motivo "no está en el maestro") por cada huérfano.
- [ ] Decisión por archivo con opción **omitir** (= propio, se deja en su lugar).
- [ ] Confirmación explícita antes de **Borrar** en interactivo.
- [ ] `-OrphanAction Borrar` no interactivo exige **confirmación o `-Force`**; si no, degrada a Conservar.
- [ ] **Log de lo borrado** (ruta, hash, fecha, tamaño) en toda ejecución con Borrar.
- [ ] Si el clon maestro falló/vacío → **fase de huérfanos abortada**, nada se borra.
- [ ] Detector acotado a `.github/`, `.opencode/`, `.doc_agents/`; excluye `Documentacion/<AppName>/`, `src/`, `tests/`, `.specify`.
- [ ] Artefactos de la herramienta dentro de `.opencode/` excluidos por diseño (`node_modules/`, `package*.json`, `bun.lock`, `lib/`, `bin/`, `config.json`) — no aparecen como huérfanos.
- [ ] `.github/context-mode/` excluido por diseño — no es del kit transversal (es runtime local de cada proyecto).
- [ ] Destino del respaldo = `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` con **rutas relativas validadas** (sin absolutas ni `..`).
- [ ] **Containment-check**: el destino canónico queda dentro de `revisar_manualmente\yyyymmdd\` (fail-closed).
- [ ] Symlinks/junctions no se siguen al mover.
- [ ] Sufijo único si la carpeta del día existe (hora/contador) + **nunca sobrescribir** respaldo previo; sin huérfanos no se crean carpetas.
- [ ] `revisar_manualmente/` en **`.gitignore`** + advertencia de no subirla en cada informe de movido.
- [ ] Informe de conservados con **origen + hash + fecha** ("no está en el maestro"); nada se reintroduce sin revisión.
- [ ] Logs/informes solo con **rutas relativas + metadatos**; sin contenido ni secrets.
- [ ] `-DryRun` solo informa: no borra ni mueve (verificable en tests T-V6).
- [ ] `npx ecc-agentshield scan` sobre los cambios (si tocan `.github/`).

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** El diseño de RF-12 es fundamentalmente seguro: default Conservar, pregunta explícita con opción omitir para propios, respaldo versionado fuera de los directorios de agentes, flag `-OrphanAction` para no interactivo y `-DryRun` que solo informa, con `Documentacion/<AppName>/` explícitamente fuera de alcance.

Los dos riesgos que deben **tratarse como severidad crítica innegociable** durante la implementación (a cargo de `devops`/`qa-senior`) son:

1. **Borrar el archivo equivocado** (riesgo 1 🔴) — el falso positivo con **Borrar** es irreversible; la mitigación (default Conservar + lista visible + confirmación + detector acotado) debe quedar en los criterios de aceptación, no solo en la doc.
2. **Secrets en el respaldo versionado por error** (riesgo 2 🔴) — `revisar_manualmente/` en `.gitignore` + advertencia de no subirla + no volcar contenido a logs; es la mitigación más fácil de violar por descuido.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- default Conservar + confirmación explícita para Borrar + `-OrphanAction Borrar` no interactivo solo con `-Force`/confirmación + log de lo borrado + abortar si el maestro está incompleto;
- `revisar_manualmente/` en `.gitignore` + advertencia en cada informe + logs solo con rutas relativas y metadatos (sin contenido);
- rutas relativas validadas + containment-check + no seguir symlinks + nunca sobrescribir respaldo;
- informe de conservados con origen/hash/fecha + detector acotado a la allowlist (nunca `Documentacion/<AppName>/`);
- `qa-senior` valide en `-DryRun` (T-V6: detección correcta, nada se borra/mueve, estructura preservada en respaldo) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — RF-12, criterio 8, diagrama C2–C8 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[HUERFANOS]` (plan aprobado 2026-09-18).
- `Documentacion/Agents_IA_TECH/seguridad/plataforma-bootstrap.md` — Revisión previa del bootstrap (formato + riesgos 2/4/6 aplicables: supply chain, secrets, ejecución).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — ADR fuente (guardrails 1 y 3).
- `README.md` — Sección Actualización (pregunta borrar/conservar, respaldo `revisar_manualmente\yyyymmdd\`, default seguro, flag `-OrphanAction`).
