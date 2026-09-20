# 🔒 Seguridad del diseño: blindaje `.git` + alcance quirúrgico `.opencode` (`[BLINDAJE-GIT]`, RF-B1..B4)

> Revisión **de seguridad del DISEÑO** de los guards transversales para mover+limpiar+sync (RF-B1 `.git` intacto, RF-B2 matriz `.opencode`, RF-B3 `.gitignore` por nivel, RF-B4 guards destructivas + fail-closed; RNF-B1/B2/B3; AC-1..AC-6).
> Enfocada en: **secret commiteado por `.gitignore` ausente/mal ignorado, borrado fuera de allowlist por path mal construido, supply chain en `lib/`/`bin/` ignorados, sync que pisa el `.gitignore` local con versión vieja, test `.git`-intacto sin anidados**.
> Fuente: `Documentacion/Agents_IA_TECH/specs/kit-generico/spec.md` (RF-B1..B4, 6 ACs) + `tasks.md` (T-D/T-I/T-V) y `pendientes-implementacion.md` (tarea `[BLINDAJE-GIT]`, plan aprobado 2026-09-19).
> Autor: `security-auditor` (fase documental — tarea `[BLINDAJE-GIT]`)

---

## 1. Análisis de riesgos del diseño del blindaje

### 1.1 Riesgo de `config.json` con API keys commiteado por `.gitignore` ausente o mal ignorado (secret en historial = rotación obligatoria)

El archivo real con secrets existe hoy (`.opencode/config.json`, 367 bytes) pero **no está trackeado** (`git ls-files` → 0 matches para `config.json`) y su contenido local son **placeholders** (`has-PLACEHOLDER=True`, sin patrón `sk-`), verificado sin volcar contenido. La doble cobertura existe: raíz `.gitignore` L7 (`.opencode/config.json`) + anidado `.opencode/.gitignore` L8 (`config.json`), ambos confirmados por `git check-ignore -v` (OK en `config.json`, `node_modules`, `lib/`, `bin/`, `package.json`).

**Pero hay un hallazgo que degrada la garantía**: el anidado **se auto-ignora a sí mismo** (`.opencode/.gitignore` L6: `​.gitignore`), de modo que `git check-ignore -v .opencode/.gitignore` responde "ignorado por su propia L6" y `git ls-files .opencode` **no lo lista** (solo `agents/` + `commands/`). El archivo que provee la protección de secrets es **invisible a git**: nadie nota por `git diff`/`status` si se degrada, y el flujo `Ensure-OpenCodeConfig` (RF-17, plantilla→keys reales) invita al error clásico — `git add -A` / `git add -f`, tocar la línea del `.gitignore` raíz, o copiar el proyecto — que mete el secret al historial. Una vez commiteado, **borrar no basta: hay que rotar las keys** (hereda `kit-gaps.md` §1.1).

**Puntos de validación necesarios:**
- **Placeholders inconfundibles** en la plantilla (`__PEGAR_AQUI_...__`, nunca formato válido) + aviso inline "NO commitear" (ya exigido en `kit-gaps.md`, extender a esta spec).
- **Detección defensiva de trackeado**: si `git ls-files` lista `config.json` → WARN explícito con `git rm --cached` + **rotar keys** (hoy previsto solo en `Ensure-OpenCodeConfig`; extender a sync y a T-V2/AC-6).
- **Hacer visible el anidado**: quitar la línea auto-ignore L6 (el `.gitignore` anidado **debe versionarse** — es kit, no runtime; AC-2 lo presupone al listar "+anidado") o, si se mantiene ignorado, fijarlo con `git add -f` + documentarlo. Sin esto, T-V2/AC-3 no pueden auditarlo por git.
- **`DryRun` sin escritura** (RNF-B2) + "si existe no se toca nunca" (RF-17) ya en spec; mantener.

### 1.2 Riesgo de borrado fuera de allowlist por path mal construido (containment evadido con `..` o symlink)

`Move-AppToSrc` trae los controles estructurales correctos (verificados por código en `scripts/relocate-apps-to-src.ps1`): **nombres simples** (`Test-SimpleAppName`, L277) + **denylist dura con `.git`** (L63, L281-283) + **containment-check léxico** origen-dentro-de-raíz / destino-dentro-de-`src\` con fail-closed (L286-295) + **rechazo de symlink/junction en origen** (L305-316) + **destino libre, nunca fusionar** (L318-322). `Clear-RegenerableDirs` opera solo sobre objetos ya filtrados por allowlist exacta de UN nivel sin `-Recurse` en la enumeración (`Find-RegenerableDirs` L1104-1141, `Documentacion` excluida L1090/L1138) + **gate git-trackeado** que excluye con aviso lo versionado + **containment por app** (L1250-1265) + **fail-closed** en DryRun/no-interactivo/`.venv` activo (L1285-1311); el único `Remove-Item -Recurse -Force` de limpieza (L1314) actúa solo sobre `$fullCanon` ya validado.

**Gaps residuales:**
- La contención depende de que `Test-SimpleAppName` rechace de verdad `..`, separadores, `:` y absolutas — **asumido, no verificado en esta revisión** (auditoría por código de `Select-String`, sin ejecución). `GetFullPath` es **léxico, no resuelve enlaces**: un symlink interior (p. ej. un `node_modules` que es junction a fuera) pasa el prefijo léxico y llega a `Remove-Item -Recurse -Force`. En origen el symlink se rechaza (L305), pero **por target en `Clear` no hay chequeo de `ReparsePoint`**.
- El movido traslada la app **entera** (L350 `Move-Item` del directorio): un `.git` anidado se preserva **por traslado, no por exclusión** — correcto mientras no haya locks (ver §1.5).

**Puntos de validación necesarios:**
- `qa-senior` prueba señuelos `..`, absoluta, `C:\...`, symlink/junction como `-AppDirs` y como hijo `node_modules`-enlace → **omitidos con aviso, cero mutación** (AC-4/AC-5, T-V3).
- Añadir chequeo `ReparsePoint` por target en `Clear-RegenerableDirs` (misma regla que origen L305) o documentar "no se siguen enlaces" también para limpieza.
- Prohibición vigente de `Remove-Item -Recurse` sobre raíz `.opencode` (RF-B4/AC-4): los 5 `Remove-Item` hallados en scripts son sobre `$tempDir` (bootstrap L1593/L1667, temp efímero), `$full` huérfano validado (L1277) y `$fullCanon`/`$newVenvFull` validados (relocate L962/L1314) — **ninguno sobre raíz `.opencode`** ✅ (verificación por código 2026-09-19).

### 1.3 Riesgo de `lib/`/`bin/` con binarios no verificados que el MCP ejecuta (supply chain en runtime ignorado = invisible a git)

Estado medido 2026-09-19: `.opencode/lib/graphify` **vacío** (0 archivos), `.opencode/bin/` **vacío**, `node_modules/` con 7 directorios, `package.json` con una sola dependencia (`@opencode-ai/plugin` 1.18.31). Todo ello **ignorado por git** (`check-ignore` OK vía anidado) → **invisible al versionado y al diff**: si mañana el bootstrap deposita ahí binarios (graphify u otros), ningún `git status` delatará una sustitución, y el MCP (`type: local`) **los ejecutará cada sesión** con permisos del usuario (lectura vía `analyze_files`, red si el JS la implementa).

Agravante: a diferencia de tokenslayer (pin v1.5.0 + commit `9a380c04` en manifest + verificación de versión, ver `kit-gaps.md` §1.2), para `lib/`/`bin/` **no hay pin, hash ni verificación de integridad previstos** en RF-B2/B3 ni en el bootstrap. Hoy el riesgo es **latente, no activo** (vacío = nada que explotar), pero la puerta queda abierta por diseño.

**Puntos de validación necesarios:**
- **Fijar fuente en manifest** (versión + commit + hash pinned del artefacto esperado) para todo lo que se deposite en `lib/`/`bin/`, como ya se exige al binario tokenslayer.
- **Containment-check** de la ruta registrada/ejecutada (canónica dentro de `proyect_ext/...` o `.opencode/lib|bin/`, sin `..` ni absolutas externas) + WARN sin auto-instalación (`npm install` ejecuta código de terceros — no auto-compilar desde el bootstrap).
- Documentar el estado "vacío hoy" como baseline en T-I2 para que T-V2 detecte cualquier aparición no declarada.

### 1.4 Riesgo de sincronización que pisa el `.opencode/.gitignore` local con versión vieja del kit (pierde `config.json`)

`Sync-TransversalKit` (`scripts/plataformador-bootstrap.ps1` L1607-1656) copia `.opencode/` **entero** con `robocopy /E` (L1630-1632): sin `/MIR` → **no borra extras locales** ✅, pero **sí sobrescribe archivos modificados** con la versión del maestro, excluyendo solo `config.json` (`/XF "config.json"` L1632 + confirmación L1652-1656 ✅). A diferencia de los *files* transversales (hash + guard `-Force`: si difiere se conserva local, L1637-1646), los *dirs* **no tienen guard de fusión**: un `.opencode/.gitignore` local endurecido (p. ej. con la línea `config.json` reforzada) se **pisa silenciosamente** con un `.gitignore` viejo del maestro que quizá no la trae → el siguiente commit desprotege los secrets. El daño es silencioso por el §1.1 (anidado no trackeado → **ningún diff lo muestra**).

**Puntos de validación necesarios:**
- Excluir `.gitignore` del overwrite ciego (misma clase que `config.json`) **o** aplicarle el guard de files (hash: igual→OK, difiere→conservar local + aviso, solo `-Force` sobrescribe).
- Quitar el auto-ignore L6 para que el anidado sea auditable (ver §1.1); T-V2 debe verificar `git check-ignore` **después de un sync** con fixture de `.gitignore` local más nuevo que el del maestro (regresión dedicada, hoy ausente en T-V1..V3).

### 1.5 Riesgo de test `.git`-intacto que no cubre `.git` anidados (solo raíz)

El repo tiene **`.git` anidados reales** (medido 2026-09-19): `proyect_ext/spec-kit/.git` y `proyect_ext/tokenslayer/.git` (clones de terceros). T-V1/AC-1 piden "fixture con `.git` señuelo" en singular, **sin exigir anidados, locks ni gate git-trackeado sobre ellos**. Dos evidencias de que el caso importa: (a) el hallazgo de modo real `[RELOCATE]` — `Move-Item` en `dwxconnect` abortó por **lock transitorio de `git.exe` de VS Code sobre el `.git` anidado oculto** (0 errores de acceso, 0 read-only; el `.git` oculto por sí solo no bloquea, pero el lock sí); (b) la **discrepancia de conteo** 259 anunciados vs 37 files + 19 dirs reales, atribuible a que `Get-AppSizeInfo` cuenta el `.git` oculto — lo que puede hacer **fallar la verificación post-movido** (L368-376 exige conteo idéntico antes/después) aunque el movido sea correcto, o enmascarar una pérdida real.

**Puntos de validación necesarios:**
- T-V1 con **triple fixture**: `.git` raíz señuelo + `.git` anidado señuelo + lock simulado (proceso con cwd/handle dentro) → mover+limpiar DryRun + real → **ambos `.git` idénticos (hash/contenido)** + log con aviso de exclusión; el caso lock → omitido con aviso, sin estado mixto.
- Decidir y documentar si `Get-AppSizeInfo` **excluye `.git`** del conteo (recomendado: el historial no es "contenido de la app" y su lock transitorio no debe tumbar la verificación) o lo cuenta con tolerancia a locks; registrar la decisión en la spec para que `qa-senior` no la reabra en cada validación.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **`config.json` commiteado** (`.gitignore` ausente/tocado, `git add -f`, plantilla→keys reales) → secrets en historial, **rotación obligada** | 🔴 Crítico | Doble ignore (raíz L7 + anidado L8, `check-ignore` OK hoy) + placeholders inconfundibles + recuerdo del gitignore en WARN/README/plantilla + **detección de trackeado → `git rm --cached` + rotar** (extender `kit-gaps.md` a sync) + **quitar auto-ignore L6** (anidado versionable y auditable); AC-6/T-V2. |
| 2 | **Borrado fuera de allowlist** (`..`/absoluta/symlink evaden containment) → escritura/borrado fuera del proyecto | 🟠 Alto | Nombres simples + denylist con `.git` + containment léxico fail-closed + rechazo de symlinks (origen ✅, extender a targets de `Clear`) + destino libre + DryRun/no-interactivo sin mutación; señuelos en T-V3 (AC-4/AC-5). |
| 3 | **Supply chain en `lib/`/`bin/` ignorados** (binario sustituido, invisible a git) → el MCP lo ejecuta cada sesión | 🟠 Alto | Baseline "vacío hoy" + **pin + hash en manifest** + containment de la ruta registrada + WARN sin auto-`npm install`; nada se ejecuta sin verificar (extiende `tokenslayer.md`/`kit-gaps.md` §1.2 a `lib/`/`bin/`). |
| 4 | **Sync pisa `.gitignore` local** (`robocopy /E` sobrescribe, solo excluye `config.json`, dirs sin hash-guard) → pierde la línea `config.json` y desprotege el siguiente commit, en silencio | 🟠 Alto | Excluir `.gitignore` del overwrite o aplicarle guard hash/`-Force` como a files + quitar auto-ignore L6 + **regresión T-V2 post-sync** con fixture local-más-nuevo. |
| 5 | **Test `.git`-intacto sin anidados/locks** → `.git` anidado dañado o verificación post-movido falseada por conteo/lock | 🟡 Medio | T-V1 triple (raíz + anidado + lock) con hash antes/después + aviso en log; **decidir conteo de `.git` en `Get-AppSizeInfo`** (recomendado: excluir) y documentarlo. |

---

## 3. Recomendaciones de uso seguro

1. **Antes de rellenar `config.json` con keys reales**: `git check-ignore -v .opencode/config.json` debe responder ignorado; si alguna vez aparece en `git ls-files`, tratarlo como **incidente** (`git rm --cached` + rotar keys, borrar no basta).
2. **Pasar `-DryRun` primero** en mover, limpiar y sync; leer la lista (orígenes/destinos canónicos, tamaños, qué se excluiría por denylist/gate) con cero escrituras (RNF-B2).
3. **No usar `git add -A` / `git add -f` a ciegas** en este repo: revisar `git status` y confirmar que `config.json`, `node_modules/`, `lib/`, `bin/` siguen ignorados.
4. **No tocar la línea `config.json` del `.gitignore`** (ni raíz ni anidado) sin re-verificar `check-ignore` después; tras cada sync, re-verificar (hasta que T-I2 cierre el guard del §1.4).
5. **Responder por app (`[S]`/`[N]`)**; `[T]odos` solo con la lista numerada leída; `[C]` ante la duda; en no-interactivo no se mueve/borra nada (fail-closed).
6. **Cerrar procesos Python y `git` sobre la app** antes del modo real (locks en `.git`/`.venv` → movido parcial o verificación fallida); partir de `git limpio` y commit atómico tras verificar tests en la nueva ubicación.
7. **Tratar `lib/`/`bin/` como no confiable hasta el pin**: no depositar ni ejecutar binarios ahí sin entrada en manifest (versión + commit + hash); lo vacío hoy no se "rellena a mano".
8. **Guardar el log** (origen→destino + avisos de exclusión `.git`/trackeado): es la única base del rollback y la evidencia para T-V1/T-V3.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO commitear `.opencode/config.json`** (ni con `git add -f`, ni tocando su línea del ignore); si ya pasó → `git rm --cached` + **rotar keys**.
- ❌ **NO poner secrets reales en plantillas** ni ejemplos con formato válido (`sk-...`); solo placeholders inconfundibles.
- ❌ **NO mantener el auto-ignore** del anidado (`.opencode/.gitignore` L6 `​.gitignore`): el archivo de protección debe ser visible a git.
- ❌ **NO pasar `-AppDirs` con `..`, absolutas, separadores ni symlinks** (solo nombres simples); ni listar `Documentacion`, `.specify`, `src`, `scripts`, `proyect_ext`, `.github/`, `.opencode/`, `.doc_agents/`, `.git`, `.venv` suelto.
- ❌ **NO agregar flags que salteen confirmaciones** ni wrappers que simulen consola para forzar mover/borrar en no-interactivo.
- ❌ **NO usar `[T]odos` sin leer** la lista (equivale a bypass de hecho).
- ❌ **NO depositar binarios en `lib/`/`bin/` sin pin+hash en manifest** ni registrar rutas MCP fuera de containment.
- ❌ **NO auto-compilar desde el bootstrap** (`npm install` ejecuta código de terceros): solo WARN + instrucciones.
- ❌ **NO sobrescribir `.opencode/.gitignore` local en sync** sin hash-guard/`-Force` consciente (hasta T-I2, verificar `check-ignore` post-sync a mano).
- ❌ **NO hacer `Remove-Item -Recurse` sobre raíz `.opencode`** (RF-B4); solo subpaths validados por allowlist + containment.
- ❌ **NO volcar contenido de `config.json`** ni de código a logs/consola/CI (solo rutas relativas + metadatos).
- ❌ **NO validar `.git`-intacto solo con raíz**: exigir anidado + lock en T-V1.

---

## 5. Checklist de seguridad del blindaje (para `devops`/`qa-senior`, mapea AC-1..AC-6)

- [ ] AC-1/T-V1: fixture con **`.git` raíz + anidado señuelo** → mover+limpiar DryRun + real → ambos idénticos (hash/contenido) + aviso de exclusión en log; lock simulado → omitido sin estado mixto.
- [ ] AC-2/T-V2: `git ls-files .opencode` solo `agents/` + `commands/` (**+ anidado tras quitar auto-ignore L6**); `config.json`, `node_modules/`, `package*.json`, `bun.lock`, `lib/`, `bin/` con `check-ignore` OK.
- [ ] AC-3/T-V2: raíz ignora `.opencode/config.json` + `.vscode/*` + `.env*` + regenerables; anidado ignora runtime + `config.json` + `lib/` + `bin/`; ambos verificados por `check-ignore` **también después de un sync** (regresión §1.4).
- [ ] AC-4/T-V3: `Select-String 'Remove-Item.*\.opencode[^/\\]'` sin matches sobre raíz `.opencode`; toda ruta destructiva con allowlist + containment (origen ✅ + targets de `Clear` con `ReparsePoint`).
- [ ] AC-5/T-V3: señuelos fuera de allowlist (`.git`, `Documentacion/`, `..`, absoluta, symlink) → omitidos con aviso, cero mutación.
- [ ] AC-6/T-V2: ningún log/test vuelca contenido de `config.json`; `config.json` real nunca trackeado; **detección de trackeado → WARN + `rm --cached` + rotar** implementada en bootstrap y sync.
- [ ] `Test-SimpleAppName` rechaza `..`/separadores/`:`/absolutas (prueba directa, no asumida).
- [ ] `Get-AppSizeInfo`: decisión documentada sobre `.git` en el conteo (recomendado: excluir) para que la verificación post-movido no falle por locks/transitorios.
- [ ] `lib/`/`bin/`: baseline vacío registrado + pin + hash en manifest + containment antes de depositar nada ejecutable.
- [ ] Sync: `.gitignore` con guard hash/`-Force` o exclusión del overwrite (verificado con fixture local-más-nuevo).
- [ ] `-DryRun` en mover/limpiar/sync: cero escrituras (verificable por `git status` idéntico + `src/` no creado).
- [ ] Logs solo rutas relativas + metadatos; sin contenido ni secrets.
- [ ] `npx ecc-agentshield scan` si los cambios tocan `.github/` (rutina del kit).

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** El diseño RF-B1..B4 es estructuralmente correcto —allowlist sin `.git` + denylist con `.git` + gate git-trackeado + containment fail-closed + matriz quirúrgica + doble ignore + `config.json` excluido del sync— y **el estado medido hoy es seguro**: `config.json` con placeholders y sin trackear, matriz respetada (`ls-files` solo `agents/`+`commands/`), runtime/secrets/artefactos ignorados (`check-ignore` OK en los 5), y ningún `Remove-Item` sobre raíz `.opencode`.

Los dos riesgos que deben **tratarse como innegociables** en T-I/T-V (a cargo de `devops`/`qa-senior`) son:

1. **Secret commiteado (riesgo 1 🔴)** — el doble ignore existe pero el anidado auto-ignorado lo vuelve inauditable y el flujo plantilla→keys invita al `add -f`; la mitigación (quitar auto-ignore L6 + placeholders + recuerdo del gitignore + **detección de trackeado con `rm --cached` + rotación** en bootstrap **y** sync) debe quedar en los criterios de aceptación, no solo en la doc.
2. **Sync que pisa el `.gitignore` local (riesgo 4 🟠, el más probable)** — `robocopy /E` sin hash-guard para dirs sobrescribe la protección con versiones viejas en silencio; la mitigación (excluir `.gitignore` o guard hash/`-Force` + regresión post-sync) debe quedar en T-I2/T-V2 antes del primer sync contra un maestro desactualizado.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- quitar auto-ignore L6 + detección de `config.json` trackeado con aviso de rotar + placeholders inconfundibles + no-tocar-si-existe (riesgo 1);
- `ReparsePoint` por target en `Clear` + señuelos `..`/absoluta/symlink en T-V3 + veto de `Remove-Item` sobre raíz `.opencode` (riesgo 2);
- pin + hash en manifest + containment para `lib/`/`bin/` antes de que dejen de estar vacíos (riesgo 3);
- guard hash/`-Force` o exclusión para `.gitignore` en sync + regresión post-sync (riesgo 4);
- T-V1 triple (raíz + anidado + lock) + decisión documentada del conteo de `.git` (riesgo 5);
- `qa-senior` valida todo lo anterior con fixtures en `$env:TEMP` antes del rollout real.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/kit-generico/spec.md` — RF-B1..B4, RNF-B1..B3, AC-1..AC-6 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/specs/kit-generico/tasks.md` — T-D/T-I/T-V (T-I1..I3, T-V1..V3 pendientes de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[BLINDAJE-GIT]` (plan aprobado 2026-09-19).
- `Documentacion/Agents_IA_TECH/seguridad/relocate.md` — Precedentes: nombres simples + denylist + containment + transacción por app + fuga por log.
- `Documentacion/Agents_IA_TECH/seguridad/relocate-cleanup.md` — Precedente: allowlist exacta + gate git-trackeado + `.venv` fuera del "sí a todo".
- `Documentacion/Agents_IA_TECH/seguridad/kit-gaps.md` — Precedentes: plantilla→secret + binario sin verificar + tracking fuera del `[T]` (formato heredado §§1-6).
- `Documentacion/Agents_IA_TECH/seguridad/huerfanos.md` — Precedentes: default seguro + containment + `revisar_manualmente/` en ignore.
- `.gitignore` (raíz, L7 `​.opencode/config.json`) y `.opencode/.gitignore` (anidado, L6 auto-ignore + L8 `config.json`) — evidencia medida 2026-09-19.
- `scripts/relocate-apps-to-src.ps1` (`Move-AppToSrc` L260-379, `Clear-RegenerableDirs` L1234-1331) y `scripts/plataformador-bootstrap.ps1` (`Sync-TransversalKit` L1560-1669) — código auditado por lectura.
