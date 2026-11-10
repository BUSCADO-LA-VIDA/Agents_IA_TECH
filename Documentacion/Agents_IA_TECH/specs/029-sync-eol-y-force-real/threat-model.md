# Threat Model — Spec 029: Sync honesto (EOL normalizado y `-Force` efectivo)

**Spec**: `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/spec.md`
**Plan**: `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/plan.md`
**Fecha**: 2026-10-27
**Agente**: `security-auditor` (tier Documental, Art. VII)
**Constitution aplicable**: `Documentacion/Agents_IA_TECH/.specify/constitution.md` v2.1.0 — Art. V (Observabilidad), Art. VII (paths por tier), Art. VIII (fail-open / fail-closed)
**Metodo**: STRIDE sobre la superficie declarada + revision de codigo por lectura (`scripts/sync-kit.ps1` L440-713, `sync-agents.ps1` L1-66, `opencode.json`, `.gitattributes`) y del diseno de la lib en `plan.md` §3.
**Modo de trabajo**: solo lectura sobre `scripts/`. No se ejecuto el motor ni ningun test; ninguna afirmacion de comportamiento futuro se basa en ejecucion, se basa en lectura de codigo y de diseno. Donde la conclusion depende de una ejecucion que no se hizo, se marca explicitamente.

---

## 1. Alcance y supuestos

### 1.1 Componente bajo analisis

El objeto es el motor de sync transversal del kit (`scripts/sync-kit.ps1`, funcion `Sync-TransversalKit`, L452-704) en la version que introduce la spec 029, y el archivo nuevo `scripts/sync-kit-lib.ps1` descrito en `plan.md` §3. Cuatro cambios concretos definen la superficie:

| # | Cambio | Ubicacion | Efecto sobre la superficie de ataque |
|---|---|---|---|
| a | Comparacion por contenido normalizado (`\r\n` → `\n`) en vez de hash de bytes | C-03, C-04 (L589-601, L640-649) | Cambia la **decision** de copiar o no copiar por razon de contenido: es el unico cambio que puede convertir una copia en no-copia comparando bytes |
| b | Merge del bloque `mcp` extraido a `Merge-KitOpencodeJson` en `scripts/sync-kit-lib.ps1`, propagado por `robocopy` a N consumidores | C-01, C-05 (tras L44, L651-671) | Introduce un archivo **ejecutable** nuevo en la ruta de propagacion y un punto de ejecucion implicita (dot-source) |
| c | `-Force` y `-DryRun` como parametros explicitos | C-02, C-07 (L453-458, L712) | Cambia el mecanismo que decide si se **sobrescribe** o si se **escribe** |
| d | Escritura de `opencode.json` en LF via `[IO.File]::WriteAllText` | C-05, `Write-KitJsonFile` | Cambia el mecanismo de escritura del archivo de configuracion del agente |

Activo central no obvio: `opencode.json` **no es un archivo de datos, es el archivo de configuracion del agente**. Contiene `permission` (allowlists de `bash`/`edit`), `model`, `instructions` y `mcp.servers.<n>.command`. Escribirlo es escribir la politica de ejecucion del agente. Todo el analisis de la superficie "escritura" y "merge mcp" se apoya en esa premisa.

### 1.2 Limites del modelo

**Se modela**:

- El flujo `sync-agents.ps1` → `pwsh -NoProfile -File scripts/sync-kit.ps1` → `Sync-TransversalKit` → `robocopy`/`Copy-Item`/`WriteAllText` sobre el proyecto consumidor.
- Las tres fronteras de confianza de §3.
- Los cuatro cambios de la tabla anterior y su interaccion (por ejemplo: como un resultado `EolOnly` cambia el destino del guard `opencode.json`).

**NO se modela, y por que**:

| Fuera de alcance | Razon |
|---|---|
| `scripts/plataformador-bootstrap.ps1` y su registro de MCP | FA-02 de la spec lo excluye explicitamente; su superficie ya fue tratada en el threat model de la spec 011 |
| `scripts/sync/*` (flujo 021, 13 capas) | No esta cableado (cero invocaciones) y `scripts/sync/` no se propaga a consumidores (`sync-kit-files.ps1` L8-9). Un fix ahi no llega a ningun consumidor: D-02 del plan, con evidencia |
| Seguridad del transporte git/HTTPS y autenticidad de GitHub | Fuera del control del kit; se asume que `git clone --depth 1` sobre `https://github.com/<owner allowlisted>/<repo>` garantiza lo que git garantiza. La allowlist de owners (`Test-TrustedGithubUrl`, L93-101) se audita solo como control existente, no se rediseña |
| Cadena de suministro de los MCP server (`context-mode`, `graphify`, `tokenslayer`, etc.) | Son paquetes de terceros instalados por npm/PyPI/node; su compromiso no pasa por este cambio |
| El runtime de OpenCode (`#5299`, interpretacion del schema V2) | Es un componente externo; ADR-0009 y ADR-0010 ya documentan el workaround y sus condiciones de salida |
| Seguridad del puesto de trabajo (malware local, usuario con privilegios de admin, EDR ausente) | Si el atacante ya ejecuta codigo como el usuario, el sync es irrelevante como vector: el atacante puede escribir `opencode.json` directamente. Todo el modelo asume ausencia de compromiso previo del host |
| Proceso de revision humana del repo maestro (quien aprueba un PR) | Es control organizativo, no tecnico; se referencia en §3 y §6 pero no se puede verificar desde el codigo |

### 1.3 Supuestos verificados y supuestos asumidos

| ID | Supuesto | Estado |
|---|---|---|
| A-01 | `opencode.json` esta **trackeado** en el kit maestro, por lo que una perdida de contenido es recuperable por git en el maestro | **Verificado** en este repo: `git ls-files --error-unmatch opencode.json` devuelve la ruta (trackeado), `git check-ignore` no lo ignora |
| A-02 | En proyectos consumidores `opencode.json` puede estar **gitignored** (ADR-0009 §Consecuencias: "el archivo sigue gitignored en los flujos de despliegue"). Ahi el bloque `mcp` es la unica copia de las rutas absolutas de la maquina | **Asumido** desde ADR-0009; no verificable desde este repo porque los consumidores no estan en este arbol |
| A-03 | `.gitattributes` fija `*.json text eol=lf` y `*.md text eol=lf`, pero **no** declara `*.ps1` | **Verificado**: `.gitattributes` L2-6 tiene `yml`, `yaml`, `json`, `md`, `.env.example`; ningun patron `*.ps1` |
| A-04 | El operador es un unico usuario interactivo en Windows con PowerShell 7 y `core.autocrlf=true` | **Asumido** desde spec A-03 y plan §1.3 |
| A-05 | El consumidor tiene `git` disponible (se usa en `Find-OrphanKitFiles` y en la deteccion de `config.json` trackeado), pero el sync **no requiere** que el consumidor sea un repo git | **Verificado** en codigo: los usos de git son opcionales o defensivos (L684-690) |

---

## 2. Activos protegidos

| ID | Activo | Donde vive | Por que importa | Confidencialidad | Integridad | Disponibilidad |
|---|---|---|---|---|---|---|
| **AC-01** | Integridad de `opencode.json` del consumidor | `<RootPath>/opencode.json` | Es la politica de ejecucion del agente: `permission.bash."*"`, `permission.edit`, `instructions`, `model`, `mcp.servers.*.command`. Un byte cambiado cambia lo que el agente puede hacer | Alta | **Critica** | Critica |
| **AC-02** | Bloque `mcp` local (rutas absolutas por maquina) | `opencode.json` → `mcp` | Segun ADR-0009 y ADR-0010 R4 las rutas son absolutas y no portables. Si se pierde, los MCP del consumidor dejan de arrancar y hay que re-ejecutar el bootstrap. En consumidores con el archivo gitignored (A-02) **no hay otra copia** | Media (revela layout del FS) | **Critica** | Critica |
| **AC-03** | Integridad del codigo que se propaga a N consumidores | `scripts/`, `.github/`, `.opencode/`, `.doc_agents/` | Un cambio en el maestro se ejecuta en todos los consumidores en la siguiente corrida. El radio de impacto no es 1 maquina, es N | Media | **Critica** | Alta |
| **AC-04** | Confidencialidad de rutas y claves de MCP | `opencode.json` (`mcp.servers.*.command`, `environment`), `.env.mcp` | Las rutas absolutas revelan usuario y estructura del FS (`<HOME>/...`). Las claves de proveedor **no** deben estar en el JSON (ADR-0010 R6), pero el archivo es el lugar natural donde un descuido las pondria | **Alta** | Media | Baja |
| **AC-05** | `.opencode/.gitignore` como control de secretos | `<RootPath>/.opencode/.gitignore` | Su unica funcion es impedir que `.opencode/config.json` (posibles credenciales) se versione. Es un control de seguridad, no un archivo de configuracion | Baja | **Alta** | Media |
| **AC-06** | Cadena de suministro del kit (provenance del maestro) | GitHub `BUSCADO-LA-VIDA/Agents_IA_TECH` + allowlist local | Todo lo anterior depende de que el contenido del maestro sea el revisado. Si el maestro se compromete, el sync es el repartidor | Media | **Critica** | Alta |
| **AC-07** | Trazabilidad de la operacion (que se copio, que se salteo, con que commit) | salida de `Write-Info`/`Write-OK`/`Write-Warn` + `$commitHash` (L539-560) | Sin trazas no hay forense ni distincion entre "no habia cambios" y "no se pudo comparar". Art. V lo exige | Baja | Alta | Media |
| **AC-08** | Integridad de `Documentacion/<AppName>/` de cada consumidor | `<RootPath>/Documentacion/` | Frontera kit ↔ app: el sync **nunca** debe tocarla. Es el activo que la lista blanca `$transversalDirs` (L482) protege | Alta | **Critica** | Media |

Nota sobre AC-08: la spec 029 no toca la lista blanca, y el analisis confirma que ninguno de los cuatro cambios la amplia. Se incluye como activo porque cualquier propuesta de control de §7 debe preservarla (es el criterio para descartar controles que "copien la carpeta del proyecto para comparar").

---

## 3. Fronteras de confianza

```
[F1] Repo maestro (GitHub, owner allowlisted)
      |  git clone --depth 1   (o -KitPath: checkout LOCAL, sin git)
      v
[F2] %TEMP%\agents-sync-temp  (o el checkout indicado en -KitPath)
      |  robocopy /E, Copy-Item, Merge-KitOpencodeJson + WriteAllText
      v
[F3] Worktree del consumidor (<RootPath>)
      |  el usuario ejecuta pwsh -File scripts/sync-kit.ps1
      v
[F4] Codigo en ejecucion (dot-source de sync-kit-lib.ps1 desde $PSScriptRoot)

Frontera lateral: [F3]/Documentacion/  ||  [F3]/scripts/   (whitelist L482)
```

| ID | Frontera | Que la cruza | Control existente | Debilidad estructural |
|---|---|---|---|---|
| **F1→F2** | Maestro → clon temporal | Contenido de git (codigo, config, agentes, skills) | `-notlike "https://github.com/*"` + `Test-TrustedGithubUrl` con allowlist de 5 owners (L85-101, L472-477); `--depth 1` | La allowlist valida el **owner**, no el contenido ni el commit. Cualquier rama del repo permitido es aceptable. No hay pin de commit ni verificacion de firma |
| **F2→F3** | Clon temporal → worktree del consumidor | Bytes de archivos; y en el caso de `opencode.json`, **estructura JSON interpretada** | `robocopy /E` con `/XF config.json`, `/XD context-mode`, lista blanca de items (L563-574) | `robocopy` no pregunta, no compara y no respeta `-Force` en directorios. La unica excepcion es `.opencode/.gitignore` (guard L589-601) y `opencode.json` (merge L651-671) |
| **F2b→F3** | `-KitPath` (checkout local) → worktree | Contenido **no commiteado** de una rama de trabajo | Rechazo de URLs/esquemas (L518), `Test-Path` de marcadores de kit (L526-531), rechazo de `KitPath == RootPath` (L534-537) | Valida la **forma** de la ruta, no la **procedencia** ni la autoria del contenido. Un worktree con cambios sin revisar es una fuente valida |
| **F3→F4** | Archivo en disco → codigo en ejecucion | `scripts/sync-kit.ps1` (invocado explicitamente) y, con la 029, `scripts/sync-kit-lib.ps1` (dot-source **implicito** en cada corrida) | `Test-Path` + `throw` (T003, fail-closed) | El dot-source convierte un archivo de datos en codigo sin firma, sin hash y sin pin. Es la novedad de mayor impacto estructural del cambio (SR-06) |
| **Lateral** | `Documentacion/` ↔ `scripts/` | Nada, por diseno | Lista blanca L482 + `$transversalFiles` L483-490 | Ninguna encontrada: `Documentacion/` no figura en ninguno de los dos listados, y `Find-OrphanKitFiles` opera solo sobre el clon. El tier Documental (este agente) puede escribir en `Documentacion/` y **no** en `scripts/`: el entregable de §7 no puede implementarse a si mismo |

Observacion de frontera relevante para el modelo: **`opencode.json` cruza F2→F3 dos veces con dos reglas distintas**. Si el contenido difiere y no hay `-Force`, no cruza (se conserva el local). Si hay `-Force`, cruza **parcialmente**: solo las claves fuera de `mcp`. Esa asimetria es la que sostiene SR-01 y SR-02, y es la razon por la que el activo AC-01 no puede tratarse como "un archivo mas".

---

## 4. Analisis STRIDE

| Categoria | Amenaza concreta | Vector | Superficie | Impacto | Prob. | Severidad |
|---|---|---|---|---|---|---|
| **Spoofing** | Un `opencode.json` de maestro sustituido (commit malicioso, rama no revisada servida por `-KitPath`, o repo del owner comprometido) se presenta como "la plantilla oficial" y el merge lo adopta | Contenido del maestro en F1/F2b | merge mcp | Config del agente reemplazada en N consumidores: `model`/`provider` a un endpoint del atacante, `instructions` con prompt injection, `plugin` con codigo npm | Media | **Critica** |
| **Tampering** | El merge reescribe `opencode.json` completo (round-trip JSON) sin escritura atomica ni backup: una interrupcion deja JSON truncado, y la serializacion puede alterar el contenido preservado (formato de numeros, escapes, profundidad > 10) | Proceso interrumpido / `ConvertTo-Json` | escritura / merge mcp | Perdida del bloque `mcp` local (sin otra copia si el archivo esta gitignored) o corrupcion silenciosa de la config | Media | **Alta** |
| **Repudiation** | `Merge-KitOpencodeJson` devuelve `'Error'` sin causa y el operador ve `[WARN] ... (...)` sin poder poblar el parentesis; ambos caminos (`Merged`, `Error`) emiten mensajes que no permiten reconstruir que se escribio | Atributo de retorno empobrecido (plan §3) vs contrato de mensajes (plan §4) | merge mcp | No hay forma de distinguir "merge correcto" de "merge correcto pero truncado"; el post-mortem de un `opencode.json` roto no tiene evidencia | Alta | **Media** |
| **Information disclosure** | El merge preserva y reescribe `mcp.servers.*.command` con rutas absolutas; si el consumidor commitea `opencode.json`, se publican `<HOME>/<usuario>/...`. Ademas un archivo de master con `provider.*.apiKey` se propaga a N consumidores | Merge + commit del consumidor / plantilla del maestro | merge mcp / escritura | Fuga de layout del FS y, en el peor caso, de credenciales commiteadas en N repos (ADR-0010 R6 lo prohibe y nada lo verifica en el sync) | Media | **Alta** |
| **Denial of service** | `Get-KitContentHash` materializa el archivo completo con `ReadAllBytes` y luego construye una copia en `List<byte>` + `ToArray`: hasta ~3x el tamano en memoria, sin limite. Un destino con un archivo enorme, un symlink a un device o un archivo bloqueado detiene el sync (que ademas se traga el error en `catch { Write-Warn }`, L698) | Archivo destino controlado localmente | comparacion | Sync colgado / OOM; con `catch` externo, ademas falla **en silencio** y el operador cree que sincronizo | Baja | **Media** |
| **Elevation of privilege** | El bloque `mcp` local se preserva **por diseno** en cada sync: un `mcp.servers.<x>.command` plantado una vez sobrevive todas las sincronizaciones y se ejecuta al arrancar OpenCode. El sync es, funcionalmente, un mecanismo de persistencia que el atacante no necesita mantener | Escritura unica en el `mcp` local | merge mcp | Persistencia de ejecucion bajo la identidad del usuario; el guard `[GUARD] ... PRESERVADO` reporta exito | Media | **Alta** |

Lectura de la matriz: la categoria con mas severidad no es la que introduce el cambio (comparacion) sino la que el cambio **congela** (merge del `mcp`). Las cuatro filas con severidad Alta/Critica comparten una causa: `opencode.json` se trata como "archivo con una excepcion" cuando en realidad es politica de ejecucion. El detalle explotable esta en §5.

---

## 5. Amenazas priorizadas

Convencion: cada amenaza lleva su etiqueta `security-risk:` en la linea de titulo extendida para que el `pensador` pueda filtrarlas por prefijo. La columna "Task que la mitiga" apunta a `tasks.md` de la 029; `sin cobertura` significa que ninguna de las 29 tasks la reduce.

### SR-01 — El merge adopta del maestro todo lo que no es `mcp`, sin validar claves ni schema

`security-risk:CRITICAL` · Superficie: **merge mcp** · Activos: AC-01, AC-03, AC-06

| Campo | Valor |
|---|---|
| Descripcion | `Merge-KitOpencodeJson` quita `mcp` del origen y le inyecta el `mcp` del destino. **Todo el resto del objeto** (`model`, `small_model`, `permission`, `instructions`, `plugin`/`plugins`, `provider`, `lsp`, `$schema`) viene del maestro sin comparacion, sin allowlist de claves y sin validacion contra `https://opencode.ai/config.json` |
| Escenario de abuso | 1. Se mergea al maestro (o se sirve por `-KitPath`) un `opencode.json` con `"plugin": ["paquete-atacante"]` o `"provider": {"x": {"options": {"baseURL": "https://atacante/v1"}}}`. 2. Un consumidor corre `-Force` (o no tiene diferencias y el guard aplica). 3. El merge escribe la config con `mcp` local y el resto del atacante. 4. OpenCode arranca, carga el plugin (ejecucion de codigo) o enruta las conversaciones al endpoint del atacante. 5. El mensaje visible es `[OK] [GUARD] bloque mcp local PRESERVADO`, que describe exactamente lo unico que **no** cambio |
| Control existente | `Test-TrustedGithubUrl` (owner en allowlist) acota el **origen**, no el contenido. El guard `mcp` no inspecciona el resto del objeto. Nada valida el schema, aunque ADR-0010 R7 lo exige ("cualquier cambio a `opencode.json` se valida con `jsonschema` antes de declararse terminado") |
| Control propuesto | (a) Allowlist de claves adoptables en el merge: `$schema`, `model`, `small_model`, `lsp`, `permission` con valores **iguales o mas restrictivos**; `plugin`/`plugins`, `provider`, `instructions` **nunca** se adoptan ciegamente: si difieren, `[WARN]` y se conserva el local. (b) Validacion `jsonschema` Draft 2020-12 del resultado **antes** de escribir, con aborto a `'Error'` (fail-closed). (c) Mensaje que enumere las claves modificadas, no solo que `mcp` se preservo |
| Task que la mitiga | **sin cobertura** en `tasks.md`. T019/T-10 solo verifica que `mcp` se conserva; ninguna task restringe ni reporta el resto del objeto |
| Verificacion propuesta | Test nuevo con un `srcJson` que contenga `plugin` inesperado → el resultado no debe contenerlo (o debe conservarlo solo si era identico al local) + validacion de schema del archivo resultante |

### SR-02 — El camino `NoLocalMcp` termina en `Copy-Item`: el consumidor **si** adopta el `mcp` del maestro

`security-risk:HIGH` · Superficie: **merge mcp** · Activos: AC-02, AC-04, AC-01

| Campo | Valor |
|---|---|
| Descripcion | Si el destino no tiene `mcp`, `Merge-KitOpencodeJson` devuelve `'NoLocalMcp'` y **no escribe**; T020 mapea ese estado a "caer a `Copy-Item`", que copia el archivo del maestro **completo, incluido su bloque `mcp`**. El resultado contradice el invariante que el plan §3 declara como nota de seguridad ("Nunca adopta el `mcp` del maestro (ADR-0009)") y el FR-05 |
| Escenario de abuso | 1. Consumidor nuevo (o que borro el `mcp` al limpiar credenciales). 2. Corre el sync con `-Force`. 3. `NoLocalMcp` → `Copy-Item` → el `opencode.json` del consumidor queda con `mcp.servers.*.command = "<HOME>/AppData/Roaming/npm/..."` y `"$KitPath/proyect_ext/tokenslayer/..."`. 4. Los MCP no arrancan (rutas inexistentes en esa maquina) y ademas queda publicado en el repo del consumidor el layout del FS del autor del kit. 5. El log dice `[FILE] opencode.json`, sin ninguna marca de que se importo el `mcp` ajeno |
| Control existente | Ninguno efectivo. El guard de merge L652 exige `Test-Path $dst`, que se cumple; el estado `NoLocalMcp` se interpreta como "no hay nada que proteger", no como "no puedo proteger" |
| Control propuesto | Tratar `NoLocalMcp` como **caso de bootstrap**, no de sync: escribir sin `mcp` (o con `mcp` vacio) y emitir `[WARN] opencode.json: sin bloque mcp local; se instala la plantilla SIN mcp. Ejecuta plataformador-bootstrap.ps1 -SkipSync para generar los MCP de esta maquina`. Cambiar el estado devuelto a `'CopiedWithoutMcp'` para que el mapeo sea explicito |
| Task que la mitiga | **Sin cobertura del comportamiento**: T019/T-11 verifica que la **funcion** no escribe, y T020 cablea el `Copy-Item`. La combinacion reproduce el comportamiento inseguro y el test unitario pasa en verde (falsa sensacion de cobertura). No hay task que cubra el efecto end-to-end (T026 cubre CA-01..CA-06, ninguno de los cuales mira este caso) |
| Verificacion propuesta | Test de integracion en sandbox: destino sin `mcp` + `-Force` → el resultado **no** debe contener ningun `command` del maestro; debe contener `mcp` ausente o vacio y un WARN accionable |

### SR-03 — Escritura no atomica de `opencode.json`: perdida del `mcp` local o corrupcion del JSON

`security-risk:HIGH` · Superficie: **escritura** · Activos: AC-01, AC-02

| Campo | Valor |
|---|---|
| Descripcion | `Write-KitJsonFile` usa `[IO.File]::WriteAllText`, que **trunca el archivo destino y luego escribe**. No hay archivo temporal + `Move-Item`/`File.Replace`, ni backup `.bak`, ni `try/finally` de restauracion. Si el proceso muere entre el truncado y el final de la escritura (kill, corte de energia, excepcion de disco lleno, cierre de sesion), el resultado es un `opencode.json` vacio o truncado. En consumidores donde el archivo esta gitignored (A-02) el bloque `mcp` **no tiene otra copia** y hay que rehacer el bootstrap |
| Escenario de abuso | No requiere atacante: es un fallo de disponibilidad autoinfligido. Con atacante local, el vector es indirecto: llenar el disco o bloquear el handle en el instante exacto agranda la ventana. El dano se materializa al siguiente arranque de OpenCode: config invalida → todos los MCP caidos y el agente sin `permission` declarada (comportamiento por defecto, que puede ser mas permisivo o mas restrictivo, pero es **otro** comportamiento) |
| Control existente | Ninguno. `Set-Content` (version actual, L662) tampoco era atomico: **no es una regresion**, es el mismo defecto que D-06 hereda al cambiar de API. Mitigante parcial: en el kit maestro el archivo esta trackeado (A-01) y `git checkout -- opencode.json` lo recupera; en consumidores con gitignore, no |
| Control propuesto | Escribir a `<Path>.tmp` en el mismo directorio, `[IO.File]::Replace()` cuando el destino existe (atomico en NTFS, preserva ACL) y `Move-Item -Force` como fallback; `try/finally` que borre el `.tmp`. Emitir `[WARN]` si el `.tmp` sobrevive a la corrida (senal de interrupcion) |
| Task que la mitiga | **sin cobertura**. T018 (T-08/T-09) valida EOL y fidelidad del contenido, no la atomicidad; T019/T-12 valida LF. Ninguna task prueba una interrupcion |
| Verificacion propuesta | Test que inyecte un fallo de escritura (por ejemplo, un `.tmp` preexistente como directorio, o un handle abierto) y verifique que el `opencode.json` original queda **intacto**; inspeccion de que no se usa `WriteAllText` directo sobre el destino |

### SR-04 — `-Force` declarado pero no propagado: sobrescritura que deja de ocurrir en silencio

`security-risk:MEDIUM` · Superficie: **flags** · Activos: AC-03

| Campo | Valor |
|---|---|
| Descripcion | Es RP-01 del plan, visto como amenaza. Al agregar `[switch]$Force` al `param` de `Sync-TransversalKit`, la variable `$Force` que hoy resuelve por dynamic scoping al parametro del script pasa a resolver al parametro local, con default `$false`. Si el entrypoint (L712) no pasa `-Force:$Force`, `-Force` deja de tener efecto **sin error**: el motor conserva los archivos locales para siempre |
| Escenario de abuso | 1. El implementador aplica C-02 y omite C-07 (o lo aplica en una rama que despues se reescribe). 2. Los tests T-01..T-12 de la lib pasan (no tocan el entrypoint). 3. El operador corre `.\sync-agents.ps1 -Force` creyendo que actualiza el kit. 4. Cada transversal distinto reporta `[SKIP] ... usa -Force`, pero `-Force` ya se paso. 5. El consumidor queda con codigo de agente viejo indefinidamente: si el maestro publico un fix de seguridad, no llega. La consecuencia de seguridad es **stale code con apariencia de actualizado** |
| Control existente | El dynamic scoping actual funciona por accidente: es precisamente el defecto que la spec corrige. No hay assert de comportamiento sobre la sobrescritura real |
| Control propuesto | El que ya propone el plan (T014 + AST) **mas** una verificacion de comportamiento: en sandbox, un archivo distinto + `-Force` debe quedar sobrescrito (no solo "declarar el parametro") |
| Task que la mitiga | **Cubierta**: T013 (firma), T014 (propagacion en L712), T015 (T-13, AST de la firma), T016 (T-14, AST del `CommandAst`), T026 (end-to-end). Residual: T-14 verifica que el argumento **existe**, no que su valor sea el switch del script; `-Force:$true` hardcodeado pasaria el test y forzaria sobrescritura siempre (ver SR-14) |
| Verificacion propuesta | `Select-String -Path scripts/sync-kit.ps1 -Pattern 'Sync-TransversalKit -RepoUrl.*-Force:\$Force'` + sandbox con archivo distinto y `-Force` verificando el contenido final |

### SR-05 — `-DryRun` perdido: escritura real cuando el operador pidio simulacion

`security-risk:MEDIUM` · Superficie: **flags** · Activos: AC-01, AC-02

| Campo | Valor |
|---|---|
| Descripcion | Mismo mecanismo que SR-04, con peor consecuencia. `-DryRun` hoy se lee por dynamic scoping dentro de `Sync-TransversalKit` (L492). Al declararlo como parametro, si no se propaga, el `return` temprano de L508 no se ejecuta y **el sync escribe de verdad**: `robocopy /E`, `Copy-Item`, merge y `WriteAllText` sobre el worktree del consumidor |
| Escenario de abuso | 1. Un wrapper (funcion, job, script de CI) define `$DryRun = $false` en su scope. 2. Invoca el motor. 3. Con dynamic scoping actual, el motor leería el `$false` del wrapper (fallo ya posible hoy). Con el parametro explicito y sin propagacion, `$DryRun` local es `$false` siempre y el fallo es **determinista**, no dependiente del wrapper. 4. El operador cree haber simulado; el worktree ya fue modificado, y con `-Force` implicito no, pero con `robocopy` sobre directorios (que no respeta `-Force`) si |
| Control existente | `-DryRun` retorna en L492 antes de cualquier efecto. Es el unico control y depende del binding correcto de la variable |
| Control propuesto | Declarar y propagar (ya en el plan) + un test de comportamiento que compare el hash del arbol destino antes/despues, que es lo que hace T017. Agregar ademas una guarda defensiva al inicio de la funcion que falle cerrado si el parametro no fue provisto por el entrypoint: no es trivial en PowerShell, por lo que se acepta el test como control principal |
| Task que la mitiga | **Cubierta**: T013, T014, T017 (CA-05 con hash del directorio). Residual: T017 corre el sandbox con el codigo final; si la propagacion se rompe despues, el test lo detecta, pero solo en la combinacion exacta que prueba |
| Verificacion propuesta | `Invoke-Pester tests/sync-kit-lib.Tests.ps1 -TestName 'T-14'` + sandbox T017 con hash SHA256 del arbol completo antes y despues |

### SR-06 — `sync-kit-lib.ps1` se propaga por `robocopy` y se ejecuta por dot-source: nuevo punto de ejecucion sin provenance

`security-risk:MEDIUM` · Superficie: **merge mcp** (import) / frontera F3→F4 · Activos: AC-03, AC-06

| Campo | Valor |
|---|---|
| Descripcion | El archivo nuevo viaja a todos los consumidores porque `scripts/` es transversal completo (L482, `robocopy /E` en L567/L637). A partir de la 029, `sync-kit.ps1` hace dot-source de el **en cada invocacion**, antes de cualquier validacion de URL, allowlist o `-KitPath`. Un archivo que hasta ayer era "un script mas" pasa a ser un modulo obligatorio, y su ausencia o su contenido alteran la ejecucion de todo el motor |
| Escenario de abuso | 1. Se mergea en el maestro un `sync-kit-lib.ps1` con una linea adicional en `Get-KitNormalizedBytes` (por ejemplo, una llamada de red o un `Set-Content` sobre `$env:USERPROFILE\.ssh\authorized_keys`). 2. Un consumidor corre `sync-agents.ps1` por cualquier motivo. 3. El dot-source ejecuta el payload **antes** de que el sync haga nada, con la identidad del operador. 4. El sync reporta `[OK]` y el operador no tiene ninguna senal. Variante sin PR malicioso: `-KitPath` permite apuntar a un worktree con cambios sin commitear, que se convierte en la fuente de codigo ejecutado por todos los consumidores de esa corrida |
| Control existente | `Test-TrustedGithubUrl` valida owner y esquema, no contenido ni commit. No hay firma, checksum ni pin. El unico control real es la revision humana del PR en el maestro, que es organizativo y no verificable desde el codigo |
| Control propuesto | (a) Registrar en el log, al inicio de cada corrida, `SHA256` de `sync-kit-lib.ps1` y `sync-kit.ps1` junto al `commitHash` (ya se imprime el commit en L545/L560, falta el hash del modulo). (b) Cuando la fuente sea `-KitPath`, exigir `git status --porcelain scripts/` vacio o emitir un `[WARN]` explicito de "codigo sin commitear". (c) A mediano plazo, manifiesto de hashes por archivo transversal (DD-05 del plan ya registra el drift por hash crudo; esto es el mismo mecanismo aplicado a integridad) |
| Task que la mitiga | **sin cobertura**. T003 solo exige `Test-Path` + `throw` (existencia), no provenance. Ninguna task imprime ni compara el hash del modulo |
| Verificacion propuesta | Inspeccion de que la linea `[INFO]` de arranque incluye el SHA256 del modulo; en sandbox, modificar un byte del `sync-kit-lib.ps1` de origen y confirmar que el sync lo reporta como cambio de modulo y no como `[OK]` |

### SR-07 — Archivo homonimo en el consumidor: `robocopy` lo pisa sin aviso

`security-risk:MEDIUM` · Superficie: **merge mcp** (propagacion) · Activos: AC-03

| Campo | Valor |
|---|---|
| Descripcion | `scripts/sync-kit-lib.ps1` es un nombre generico. Si un consumidor ya tenia un archivo con ese nombre (propio, de otro kit, o plantado por un atacante), el `robocopy /E` de `scripts/` lo sobrescribe **sin `-Force`, sin comparacion y sin WARN**. En la direccion contraria, mientras exista, ese archivo es el que se dot-sourcea en la corrida anterior a ser pisado |
| Escenario de abuso | 1. Atacante con escritura en `<consumidor>/scripts/` crea un `sync-kit-lib.ps1` con payload. 2. La proxima vez que el operador corre el sync, el payload se ejecuta **antes** de que el sync lo sobrescriba (el dot-source ocurre al cargar `sync-kit.ps1`, el `robocopy` ocurre dentro de la funcion). 3. El archivo malicioso es reemplazado por el legitimo, borrando la evidencia del contenido, aunque no del efecto. El sync no emite ningun mensaje sobre ese archivo |
| Control existente | Ninguno para `scripts/`: el unico guard por archivo es `.opencode/.gitignore` (L589-601). `Find-OrphanKitFiles` detecta archivos **que no existen en el maestro**, por lo que un homonimo existente en el maestro jamas se reporta como huerfano |
| Control propuesto | Antes de `robocopy` sobre `scripts/`, detectar colisiones: si el archivo local existe y su hash **no** coincide con ninguna version conocida del maestro, emitir `[WARN] scripts/sync-kit-lib.ps1 local difiere y sera sobrescrito` y registrar el hash previo. Barato y coherente con el patron `[GUARD]` que ya existe |
| Task que la mitiga | **sin cobertura**. Ninguna task menciona colisiones en `scripts/`; T003 asume que el archivo simplemente aparece |
| Verificacion propuesta | Sandbox: sembrar un `scripts/sync-kit-lib.ps1` distinto en el destino y confirmar que la corrida emite `[WARN]` con el hash previo y el nuevo |

### SR-08 — El fail-closed del dot-source puede degradarse en silencio si se ubica dentro del `try`

`security-risk:MEDIUM` · Superficie: **flags** (orden de ejecucion) / F3→F4 · Activos: AC-03, AC-07

| Campo | Valor |
|---|---|
| Descripcion | T003 pide `Test-Path` + `throw` "antes de cualquier llamada a las funciones de la lib". Pero el motor envuelve **todo** el cuerpo de `Sync-TransversalKit` en `try { ... } catch { Write-Warn "Error en Sync-TransversalKit: $_" }` (L513, L698). Si el dot-source se coloca dentro de ese `try` (o dentro de la funcion), el `throw` se convierte en un `[WARN]` y la corrida termina con exit code 0: el sync "no hizo nada" pero el resumen final no lo distingue de "no habia cambios". Con `$ErrorActionPreference = "Stop"` a nivel script el throw si aborta, pero solo si esta **fuera** del try |
| Escenario de abuso | No requiere atacante: un refactor que mueva el bloque por "ordenar el archivo" convierte un fallo ruidoso en un fallo silencioso. Es la peor clase de regresion en una herramienta de integridad, porque el operador pierde la senal exactamente cuando el motor esta roto |
| Control existente | `sync-agents.ps1` propaga el exit code (`pwsh -File ...; exit $LASTEXITCODE`, L65-66), lo que hace que un `throw` top-level sea visible como fallo del proceso. Depende de la ubicacion del bloque, que ningun test fija |
| Control propuesto | Colocar el dot-source inmediatamente despues de `$ErrorActionPreference = "Stop"` (L44) y **antes** de la definicion de las funciones; `throw` con mensaje accionable que incluya la ruta esperada. Test que ejecute `pwsh -File scripts/sync-kit.ps1` en un sandbox sin la lib y verifique exit code != 0 |
| Task que la mitiga | **Parcial**: T003 codifica la forma (Test-Path + throw), pero no hay ninguna task que verifique el **comportamiento** (exit code != 0 y ausencia de `[OK]` final). El riesgo depende de la posicion del bloque, que el codigo puede cambiar sin romper ningun test |
| Verificacion propuesta | Sandbox: copiar `sync-kit.ps1` a un directorio sin la lib, ejecutar, verificar exit code != 0 y que la salida contiene la ruta esperada; ademas inspeccion de que la linea del dot-source tiene numero de linea menor que la primera `function` |

### SR-09 — `ConvertTo-Json -Depth 10` trunca y reescribe: corrupcion silenciosa de la config

`security-risk:MEDIUM` · Superficie: **escritura** · Activos: AC-01, AC-02

| Campo | Valor |
|---|---|
| Descripcion | El merge no es un parche textual: parsea, modifica y reserializa. `ConvertTo-Json -Depth 10` convierte en **string** cualquier estructura mas profunda que 10 niveles. Ademas la reserializacion no garantiza identidad byte a byte: formato de numeros (un `1.0` sale `1`), escapes de caracteres no ASCII, y el `\n` final que RP-04 ya identifico. CA-06 pide que el bloque `mcp` quede "byte-identico", proposito que un round-trip JSON no puede garantizar por construccion |
| Escenario de abuso | 1. El `opencode.json` local o el del maestro incorpora una clave anidada profunda (por ejemplo `provider.<x>.models.<y>.options.extra.<z>`). 2. Se corre `-Force`. 3. La clave queda como string; el schema de OpenCode la rechaza o la ignora. 4. El mensaje dice `[GUARD] mcp PRESERVADO` y el operador no mira el resto. 5. El sintoma aparece dias despues como "el modelo no resuelve", sin relacion aparente con el sync |
| Control existente | `-Depth 10` es un margen deliberado sobre la profundidad actual del archivo (4 niveles en `mcp.servers.<n>.command`). No hay validacion de schema ni comparacion semantica del resultado |
| Control propuesto | Validar el resultado contra `https://opencode.ai/config.json` antes de escribir (mismo control que SR-01(b): un solo remedio cubre ambos). Sustituir CA-06 "byte-identico" por "semanticamente identico" y testearlo comparando los objetos parseados, no los bytes: hoy el criterio es inverificable y empuja a escribir un test que pase por la razon equivocada |
| Task que la mitiga | **sin cobertura**. T018/T-09 prueba un round-trip con el `opencode.json` real, que es superficial y por tanto no ejercita la truncacion; T019/T-10 compara propiedades, no bytes |
| Verificacion propuesta | Test con un objeto de 12 niveles: el resultado debe ser `'Error'` (o conservar el objeto), nunca un string; test de schema del archivo resultante; test de igualdad semantica del subarbol `mcp` |

### SR-10 — El bloque `mcp` preservado es persistencia: el sync protege lo que el atacante planto

`security-risk:MEDIUM` · Superficie: **merge mcp** · Activos: AC-01, AC-02

| Campo | Valor |
|---|---|
| Descripcion | El guard existe por una razon legitima (ADR-0009: rutas absolutas por maquina) y FR-05 lo congela. El efecto colateral es que `mcp.servers.<n>.command` es la unica parte de `opencode.json` que **ningun** sync corrige. Un atacante con una sola oportunidad de escritura la usa ahi: sobrevive a todos los syncs futuros, a los `-Force`, y el motor emite `[OK] [GUARD] ... PRESERVADO` como confirmacion |
| Escenario de abuso | 1. Fase 1: se agrega `mcp.servers.updater.command = ["<HOME>/<u>/AppData/Local/Temp/u.exe"]`. 2. El operador corre el sync (rutina). 3. El mensaje confirma que el bloque se preservo. 4. Cada vez que OpenCode arranca, ejecuta `u.exe`. 5. Ningun control del kit compara el `mcp` local contra un baseline, ni verifica que los `command` apunten a archivos existentes y esperados |
| Control existente | El merge conserva el `mcp` del destino (correcto por ADR-0009). El bootstrap `Ensure-OpenCodeMcp` re-resuelve tokens y valida `Test-Path`, pero **no corre en cada sync** y el kit maestro lo salta por diseno (`-SkipSync`, ADR-0006 D5). No hay baseline del `mcp` |
| Control propuesto | (a) Emitir en cada merge un `[INFO]` con el inventario del `mcp` preservado: nombre y primer elemento de `command`. Es una linea, no un control, pero convierte un bloque opaco en evidencia revisable. (b) Registrar el hash canonico del bloque `mcp` en un archivo de estado y avisar cuando cambie sin que el operador haya corrido el bootstrap. (c) No implementar (b) en esta spec: requiere diseño de estado y queda como deuda con disparador |
| Task que la mitiga | **sin cobertura** por diseño. T019/T-10 fija el comportamiento actual como contrato, lo que es correcto para FR-05, y deja el control de tampering fuera del alcance. Se acepta como riesgo residual (§6) con la mitigacion (a) recomendada |
| Verificacion propuesta | Inspeccion del mensaje de merge: debe listar los servidores preservados; test que verifique que el mensaje contiene los nombres del `mcp` local |

### SR-11 — `ReadAllBytes` sin limite: DoS por memoria y clasificacion erronea de contenido binario

`security-risk:MEDIUM` · Superficie: **comparacion** · Activos: AC-01 (indirecto: bloquea el sync)

| Campo | Valor |
|---|---|
| Descripcion | `Get-KitContentHash` hace `[IO.File]::ReadAllBytes($Path)` y `Get-KitNormalizedBytes` construye un `List<byte>` del mismo tamano y luego `ToArray()`: hasta ~3x el tamano del archivo en memoria, sin limite. El motor anterior comparaba con `Get-FileHash`, que no materializa el contenido completo en un unico array. Ademas, la normalizacion byte a byte se aplica sin distinguir texto de binario: un archivo binario cuyos unicos bytes distintos sean `0D` antes de `0A` se clasifica `EolOnly` y **no se copia** |
| Escenario de abuso | 1. Un archivo destino grande (o un symlink a un device/archivo de red) llega a la ruta de un transversal. 2. El sync lo lee dos veces por archivo (hash normalizado + hash crudo) y en el peor caso mantiene tres copias. 3. OOM o cuelgue. 4. El `catch` externo (L698) convierte el fallo en `[WARN] Error en Sync-TransversalKit` con exit code 0: el operador cree que sincronizo. Variante de integridad: un binario en la lista de transversales se clasifica `EolOnly` y se omite la copia que correspondia |
| Control existente | Ninguno. `Get-FileHash` con `-LiteralPath` (L641-642, C-06) tampoco tenia limite de tamano, pero no amplificaba memoria. La lista actual de transversales es solo texto (`.md`, `.json`, `.ps1`), lo que reduce la probabilidad del caso binario a "si alguien agrega un item" |
| Control propuesto | (a) Leer por streaming en `Get-KitContentHash`: abrir `FileStream`, leer en bloques de 64 KB, normalizar el bloque y alimentar un `IncrementalHash`; elimina las tres copias y el limite de tamano. (b) Limite duro configurable (por ejemplo 16 MB) con `[WARN]` y salto del archivo, no con aborto. (c) Rechazar explicitamente archivos con bytes NUL en los primeros 1 KB y emitir `[WARN] contenido binario: se compara por bytes crudos` |
| Task que la mitiga | **sin cobertura**. T004 (T-01..T-06) prueba semantica de comparacion con archivos minusculos; T007 (T-15) prueba ausencia de efectos secundarios. Ninguna prueba tamano, binarios ni memoria |
| Verificacion propuesta | Test con un archivo de 64 MB generado en `$env:TEMP`: la comparacion debe completarse y el pico de memoria no debe superar ~2x el bloque de lectura; test con bytes NUL → clasificacion `Different` (nunca `EolOnly`) |

### SR-12 — TOCTOU entre la comparacion y la escritura

`security-risk:LOW` · Superficie: **comparacion → escritura** · Activos: AC-01

| Campo | Valor |
|---|---|
| Descripcion | La secuencia es: comparar (`Compare-KitFileContent`) → decidir → leer de nuevo (merge) → escribir. Entre la comparacion y `WriteAllText` o `Copy-Item`, el archivo destino puede cambiar: otro proceso, el editor del operador, o una segunda instancia del sync. No hay lock ni verificacion de que el archivo leido sea el escrito (no se comparan `LastWriteTime`/tamano) |
| Escenario de abuso | 1. El operador edita `opencode.json` mientras corre el sync. 2. La comparacion dice `Different`; el merge lee la version nueva, inyecta el `mcp` de esa version y escribe. 3. Los cambios manuales a claves **fuera** de `mcp` se pierden (el resto viene del maestro). No es explotable por un tercero sin acceso de escritura, y con acceso de escritura el atacante ya puede escribir el archivo el mismo |
| Control existente | El merge **relee** el destino en lugar de reusar el objeto de la comparacion, lo que reduce la ventana a la que hay entre la lectura y la escritura. `-DryRun` no escribe |
| Control propuesto | Ninguno en esta spec. Se documenta como riesgo aceptado (§6): el costo de un lock (archivo de lock, manejo de locks huerfanos, comportamiento en `-DryRun`) supera el beneficio para una herramienta monousuario |
| Task que la mitiga | **sin cobertura** deliberada. T007 (T-15) verifica que la comparacion no escribe, no que la escritura sea consistente con lo comparado |
| Verificacion propuesta | No aplica test; se verifica por inspeccion que el merge relee el destino (ya lo hace) y que no se reutiliza un objeto leido antes de la comparacion |

### SR-13 — Junction o symlink en el destino escribe fuera de `$RootPath`

`security-risk:LOW` · Superficie: **escritura** · Activos: AC-08, AC-01

| Campo | Valor |
|---|---|
| Descripcion | `WriteAllText`, `Copy-Item` y `robocopy` siguen junctions y symlinks. Si `<RootPath>/opencode.json` es un junction a otro proyecto (patron real cuando se comparte config entre repos), el merge escribe en el destino real, **fuera** de `$RootPath`. La frontera kit ↔ app (AC-08) se rompe sin que ningun mensaje lo indique |
| Escenario de abuso | 1. El operador (o un script de despliegue) crea `opencode.json` como junction a `C:<sep>Proyectos/OtraApp/opencode.json` para compartir la config. 2. El sync del kit A hace merge y escribe en el proyecto B. 3. B recibe un `mcp` que no es el suyo y pierde el propio. No requiere atacante; con atacante local, permite redirigir la escritura a una ruta que el operador no asocia con el sync |
| Control existente | Ninguno. El motor no inspecciona `LinkType` en ningun punto del flujo de escritura. ADR-0006 usa containment explicito para `proyect_ext/`, pero ese control no se aplica al destino del sync |
| Control propuesto | En `Write-KitJsonFile` y antes de `Copy-Item` sobre archivos transversales: `(Get-Item -LiteralPath $Path -Force).LinkType` no nulo → `[WARN] destino es un enlace (LinkType=X, Target=Y); se escribe igual` o abortar el archivo segun se decida. Preferible el WARN: abortar romperia instalaciones legitimas |
| Task que la mitiga | **sin cobertura**. Ninguna task considera enlaces; la palabra `symlink` no aparece en `tasks.md` |
| Verificacion propuesta | Sandbox Windows: crear `opencode.json` como junction a otro directorio, correr el merge y verificar que se emite el WARN y que el `journal` de la operacion nombra el target real |

### SR-14 — Higiene de flags: `-Force:$true` pasa el test AST y la normalizacion cambia la semantica de encoding

`security-risk:LOW` · Superficie: **flags** + **escritura** · Activos: AC-01, AC-03

| Campo | Valor |
|---|---|
| Descripcion | Dos efectos secundarios de bajo impacto que el diseño no fija. (1) T-14 verifica que el `CommandAst` del entrypoint **contiene** `-Force`; no verifica que su valor sea `$Force`. Un `-Force:$true` hardcodeado satisface el test y convierte el sync en sobrescritura permanente, incluido el guard de `.opencode/.gitignore`. (2) `Write-KitJsonFile` escribe UTF-8 **sin BOM**: si el `opencode.json` del consumidor tenia BOM, el merge se lo quita. Es correcto para `.gitattributes`, pero es una transformacion de encoding que el operador no pidio y que ningun test declara |
| Escenario de abuso | (1) Un "fix" apurado para que `-Force` funcione en un wrapper escribe `-Force:$true` y pasa CI. Desde ahi, todo sync pisa `.opencode/.gitignore` y los transversales distintos, incluida personalizacion legitima del consumidor; el daño es acumulativo y silencioso. (2) Un consumidor con BOM ve un diff de un byte en cada merge que no puede explicar; el ruido erosiona la confianza en el criterio de tres estados que la spec 029 construye |
| Control existente | (1) T016 (T-14) valida presencia. (2) T018 (T-08) valida `0 \r\n` y `1 \n` final, no el BOM. T004 (T-05) fija que un BOM de un solo lado es `Different`, o sea que el sistema **detecta** el BOM pero no declara que el merge lo elimina |
| Control propuesto | (1) Endurecer T-14: el argumento debe ser `-Force:$Force` (o `-Force:([bool]$Force)`), comparando el texto del `CommandAst` y no solo el nombre. (2) Agregar a T-08 una asercion de BOM ausente en la salida y documentarlo en el contrato de mensajes del plan §4 |
| Task que la mitiga | **Parcial**: T016 cubre la presencia; la forma del valor no esta cubierta. T018 cubre EOL; el BOM no |
| Verificacion propuesta | AST: extraer el `CommandParameterAst` `Force` y comparar su `Argument.Extent.Text` con `$Force`; test de BOM: escribir un fixture con `EF BB BF` y verificar que el resultado no lo tiene |

### SR-15 — La causa del fallo del merge se pierde: `'Error'` sin mensaje

`security-risk:LOW` · Superficie: **merge mcp** · Activos: AC-07

| Campo | Valor |
|---|---|
| Descripcion | El contrato de mensajes (plan §4) promete `[WARN] [GUARD] opencode.json: no se pudo mergear el bloque mcp local (...); se conserva el local sin sobrescribir.` con el motivo entre parentesis. Pero `Merge-KitOpencodeJson` devuelve solo la cadena `'Error'` (`catch { return 'Error' }`), sin el objeto de excepcion. El llamador no tiene de donde sacar el motivo: el parentesis queda vacio o se rellena con texto generico. Viola Art. V ("ningun fallo se traga en silencio") |
| Escenario de abuso | No es explotable; es un defecto de evidencia. Un consumidor cuyo `opencode.json` no es JSON estricto (comentarios, comas finales) fallara el merge en **cada** corrida con un WARN mudo, y ni el operador ni un auditor posterior pueden distinguir "JSON invalido" de "permiso denegado" o "disco lleno". El diagnostico se hace a ciegas y el archivo queda congelado sin que nadie sepa por que |
| Control existente | El `catch` externo del motor imprime `$_` (L667, version actual). Al extraer la funcion se pierde ese contexto: es una regresion de observabilidad introducida por el refactor |
| Control propuesto | Devolver un objeto en lugar de una cadena: `[pscustomobject]@{ Status='Error'; Message=$_.Exception.Message }`, o aceptar un `[ref]` de salida. El llamador compone el mensaje con `Message`. Alternativa minima: `return "Error: $($_.Exception.Message)"` y que el llamador use el sufijo despues de los dos puntos |
| Task que la mitiga | **sin cobertura**. T019 verifica los tres estados (`Merged`, `NoLocalMcp`, `Error`) como cadenas; no verifica que el mensaje final contenga la causa. T020 mapea `'Error'` a un `Write-Warn` sin motivo |
| Verificacion propuesta | Test: `opencode.json` destino con JSON invalido → estado `Error` **y** mensaje que contiene un fragmento identificable de la causa (por ejemplo `ConvertFrom-Json`) |

### SR-16 — Riesgo de enmascaramiento de la normalizacion (evaluado y acotado)

`security-risk:LOW` · Superficie: **comparacion** · Activos: AC-01, AC-03

| Campo | Valor |
|---|---|
| Descripcion | Se evaluo explicitamente si `\r\n` → `\n` puede ocultar contenido malicioso o un cambio real. **Conclusion: no puede, por construccion**, con tres salvedades que se documentan porque el plan las trata como "limite aceptado" sin enumerar el efecto operativo. (i) La normalizacion elimina **solo** `0x0D` inmediatamente seguido de `0x0A`; cualquier byte agregado, quitado o cambiado en otra posicion altera el hash normalizado y produce `Different`. Inyeccion de lineas (`\n` + payload) → `Different`. Cambio dentro de un string JSON (escape `\r\n` de dos caracteres) → los bytes `5C 72 5C 6E` no se tocan → `Different`. (ii) Un archivo UTF-16 **no** se normaliza nunca (en UTF-16LE el CRLF es `0D 00 0A 00`: el `0D` va seguido de `00`), por lo que la comparacion cae a `Different`: falla del lado seguro (exige `-Force`), no del inseguro. (iii) Un binario con `0D` antes de `0A` se clasifica `EolOnly` y se omite la copia (ver SR-11) |
| Escenario de abuso | El unico escenario realista no es tecnico sino cognitivo: `[OK] ... solo difiere el fin de linea` es un mensaje de exito, y un operador puede leerlo como "el archivo esta actualizado respecto del maestro". Lo esta en contenido, que es exactamente lo que el mensaje afirma, pero no en EOL ni en el bloque `mcp` (que nunca se actualiza por diseño). La confusion es de expectativa, no de bytes |
| Control existente | NFR-04 prohibe trim, colapso de lineas y reordenamiento: la unica operacion permitida es la eliminacion de `0x0D` antes de `0x0A`, y D-03 lo implementa sobre `byte[]` sin pasar por `Encoding.GetString` (que sustituye bytes invalidos y podria colapsar binarios distintos) |
| Control propuesto | Mantener el alcance de NFR-04 sin ampliarlo. Texto del mensaje: `[OK] <label> - contenido identico; solo difiere el fin de linea (no se reescribe)`, que afirma contenido y no "actualizado". Documentar en spec 002 (FR-08, T022) que `EolOnly` no implica que el archivo sea byte-identico al del maestro |
| Task que la mitiga | **Cubierta en lo tecnico**: T004 (T-01..T-06) fija los cinco casos limite, incluidos BOM y `\r` suelto. T008 (C-04) prohibe `switch` para que `continue` no salga del bucle. **Sin cobertura** la parte de redaccion del mensaje: T011 actualiza el bloque `# Uso:` pero ninguna task fija el texto exacto de los tres mensajes |
| Verificacion propuesta | T-02/T-04/T-06 en verde + lectura del texto emitido en el sandbox de T026 comparandolo con el contrato del plan §4 |

### 5.1 Amenazas evaluadas y descartadas

Se listan para que no se reabran sin evidencia nueva; cada descarte tiene su razon verificable.

| Hipotesis | Veredicto | Razon |
|---|---|---|
| El cambio degrada el guard de `.opencode/.gitignore` y permite versionar `config.json` con credenciales | **Descartada** | T009 solo deja de activar el hold cuando el resultado es `EolOnly`, y `EolOnly` significa contenido **identico**: no hay linea que perder. Ademas L609-622 restauran el archivo si falta y avisan si no contiene la linea `config.json`. El control de AC-05 se mantiene |
| `EolOnly` permite que el maestro imponga un `opencode.json` con `mcp` ajeno sin `-Force` | **Descartada** | En `EolOnly` no se escribe nada (`continue` en los tres casos, C-04). El unico camino de escritura de `opencode.json` sigue siendo `-Force` o el merge, y ambos pasan por `Merge-KitOpencodeJson` |
| La normalizacion hace que un cambio real de contenido se reporte como `EolOnly` | **Descartada por construccion** | Eliminar `0D` antes de `0A` es una funcion determinista sobre el resto de los bytes: si el hash normalizado difiere, hay un byte distinto que no es ese par. Formalizado en SR-16 y cubierto por T-03/T-05/T-06 |
| `WriteAllText` amplia permisos del archivo en Windows | **Descartada** | El archivo existe (el merge exige `Test-Path`), y abrir un archivo existente para escritura preserva su ACL; la herencia solo aplicaria a la creacion, que en este camino no ocurre. Si el archivo fuera de solo lectura, la excepcion la captura el `catch` → `'Error'` → local preservado (fail-closed) |
| `-KitPath` es un vector nuevo de la 029 | **Descartada como novedad** | Existe desde la spec 002 (`[002-KITPATH]`, L514-545) y no lo modifica esta spec. Su riesgo se absorbe en SR-06 como amplificador, no como hallazgo propio |
| `robocopy` sobre `scripts/` puede tocar `Documentacion/` | **Descartada** | Origen y destino son `<kit>/scripts` y `<RootPath>/scripts`; `Documentacion/` no aparece en `$transversalDirs` ni en `$transversalFiles`, y `robocopy` no sube de nivel. AC-08 no esta expuesto por este cambio |

---

## 6. Riesgos residuales aceptados

| ID | Riesgo residual | Justificacion | Quien lo acepta |
|---|---|---|---|
| RR-01 | El merge adopta del maestro todo lo que no es `mcp` (SR-01) sin allowlist de claves ni validacion de schema | Es el comportamiento **actual** (hoy `-Force` copia el archivo entero, que es peor); la 029 no lo empeora y FR-05/FA-01 excluyen rediseñar el guard. El control real es la revision del PR en el maestro, que es donde debe vivir la decision de que claves publica el kit | `arquitecto` (por FA-01 y ADR-0010 R4) + usuario como owner del repo maestro |
| RR-02 | El camino `NoLocalMcp` importa el `mcp` del maestro (SR-02) | Se detecta, se documenta y se propone correccion, pero cambiar el estado devuelto o el mapeo de T020 excede el alcance de "no cambiar comportamiento del guard" (FR-05). Aceptarlo deja un consumidor nuevo con MCP rotos pero **visibles** en el siguiente arranque de OpenCode, no silenciosos | `arquitecto`; requiere task nueva, no se resuelve en esta spec |
| RR-03 | Escritura no atomica de `opencode.json` (SR-03) | No es regresion (`Set-Content` tampoco era atomico) y el patron de escritura atomica es un cambio de infraestructura de la lib que conviene introducir con su propio test. Mitigante actual: en el maestro el archivo esta en git (A-01) | `plataformador` como implementador + `arquitecto` |
| RR-04 | Persistencia via `mcp` preservado (SR-10) | Es una consecuencia inevitable de ADR-0009 mientras las rutas sean absolutas. El control propuesto (a) es un `[INFO]` de inventario, no una barrera; una barrera real exige baseline con estado, que es deuda con disparador | `arquitecto` + usuario |
| RR-05 | TOCTOU entre comparacion y escritura (SR-12) | Herramienta monousuario, ejecucion interactiva, ventana de milisegundos y sin escenario de escalada (quien puede escribir el archivo ya puede escribirlo directamente). Un lock agrega un modo de fallo nuevo (locks huerfanos) | `security-auditor` |
| RR-06 | Junction/symlink en el destino escribe fuera de `$RootPath` (SR-13) | Requiere una configuracion deliberada del operador (compartir `opencode.json` entre proyectos) que el kit no promueve. Se recomienda el `[WARN]`, no el aborto, porque abortar rompe instalaciones legitimas | `security-auditor` |
| RR-07 | Un token sin resolver o una ruta inexistente en el `mcp` preservado no se detecta en el sync | El sync no es el lugar: `Ensure-OpenCodeMcp` del bootstrap es quien valida `Test-Path` y resuelve tokens (ADR-0006 D1/D2). Duplicar esa logica en el merge crearia dos fuentes de verdad | `arquitecto` |
| RR-08 | `-KitPath` permite propagar codigo sin commitear (SR-06) | Es una funcion pedida y documentada (`[002-KITPATH]`) para replicar ramas de trabajo a consumidores. El control propuesto es un `[WARN]` con el estado de `git status`, no una prohibicion: el operador que usa `-KitPath` lo hace a proposito | usuario (feature owner) |

Los riesgos residuales RR-01, RR-02 y RR-03 son los que un revisor futuro debe encontrar primero: afectan AC-01/AC-02, los dos activos con integridad critica.

---

## 7. Verificacion de controles

Cada control propuesto en §5 con su forma de comprobacion. Donde la comprobacion ya existe en `tasks.md`, se cita el ID; donde no existe, se marca `test nuevo` y se indica que habria que agregarlo a `tasks.md` (no se agrega aqui: este agente no edita `tasks.md`).

| Control | Amenaza | Como se comprueba | Evidencia esperada | Task / origen |
|---|---|---|---|---|
| Normalizacion limitada a `\r\n` → `\n` sobre bytes | SR-16 | Pester: T-01 byte-identicos, T-02 LF vs CRLF, T-03 contenido distinto, T-04 EOL mixto, T-05 BOM de un lado, T-06 `\r` suelto | 6 asserts con los tres estados posibles, sin `switch` | T004 (existe) |
| Prohibicion de `switch` en el bloque de decision | SR-16 / RP-02 | Inspeccion: el bloque de C-04 no contiene `switch`; `continue` a nivel `foreach` | Lectura de `scripts/sync-kit.ps1` en el rango de C-04 | T008 (existe) |
| `-DryRun` con cero escrituras | SR-05 | Pester + sandbox: hash SHA256 del arbol destino antes/despues de `-DryRun` | Hashes identicos | T017 (existe), T026 paso 2 |
| `-Force` declarado en la firma | SR-04 | AST: `FunctionDefinitionAst` de `Sync-TransversalKit` contiene `DryRun` y `Force` | Test verde; si falta, rojo | T015 / T-13 (existe) |
| `-Force` propagado desde el entrypoint | SR-04 | AST: el `CommandAst` del entrypoint incluye `-Force` | Test verde | T016 / T-14 (existe) |
| `-Force` propagado **con el valor correcto** | SR-14 | AST: el `CommandParameterAst` `Force` tiene `Argument.Extent.Text` igual a `$Force` | Test rojo si aparece `-Force:$true` | **test nuevo** |
| Merge conserva el `mcp` del destino | SR-01, SR-10 | Pester T-10: origen `mcp=A`, destino `mcp=B` → resultado `mcp=B`, resto del origen | Igualdad semantica del subarbol `mcp` (no byte a byte, ver SR-09) | T019 / T-10 (existe) |
| Merge no escribe cuando no hay `mcp` local | SR-02 | Pester T-11: estado `NoLocalMcp` y archivo sin cambios | Hash del archivo intacto tras la llamada a la **funcion** | T019 / T-11 (existe, cobertura incompleta: no cubre el `Copy-Item` del llamador) |
| Merge **end-to-end** sin `mcp` local no importa el ajeno | SR-02 | Sandbox: destino sin `mcp`, correr con `-Force`, buscar cualquier `command` del maestro en el resultado | 0 coincidencias con las rutas del maestro; WARN accionable | **test nuevo** |
| Escritura LF con `\n` final unico | SR-14 | Pester T-08: 0 `\r\n`, exactamente 1 `\n` final, sin BOM | 3 asserts | T018 / T-08 (existe; falta el assert de BOM) |
| Round-trip fiel del `opencode.json` real | SR-09 | Pester T-09: contenido identico al original **normalizado** | Comparacion normalizada | T018 / T-09 (existe, no ejercita profundidad > 10) |
| Validacion de schema del resultado | SR-01, SR-09 | Comando: `jsonschema -i opencode.json https://opencode.ai/config.json` (ADR-0010 R7) | 0 errores; si hay, el merge debe devolver `Error` | **sin test ni task** |
| Escritura atomica | SR-03 | Sandbox con fallo inducido (`.tmp` preexistente como directorio) y verificacion de que el destino queda intacto | Destino con el hash previo | **sin test ni task** |
| Dot-source fail-closed de verdad | SR-08 | Sandbox: copiar `sync-kit.ps1` sin la lib, `pwsh -NoProfile -File`, capturar `$LASTEXITCODE` | Exit code != 0 y mensaje con la ruta esperada; **nunca** `[OK]` final | T003 parcial (solo forma); **test nuevo** |
| Hash del modulo en el log de arranque | SR-06 | Comando: correr el sync y leer la linea `[INFO]` inicial | SHA256 de `sync-kit-lib.ps1` + `commitHash` | **sin cobertura** |
| Colision de archivo en `scripts/` reportada | SR-07 | Sandbox: sembrar un `sync-kit-lib.ps1` distinto en el destino | `[WARN]` con hash previo y hash nuevo | **sin cobertura** |
| Mensaje de merge con la causa del error | SR-15 | Pester: destino con JSON invalido → estado `Error` y mensaje con fragmento de la causa | Test verde | **sin cobertura** |
| Sin regresiones en el resto del motor | Todos | `Invoke-Pester tests/` completo, incluido `upgrade_framework.Tests.ps1` | Suite verde | T025 (existe) |
| Paridad Windows/Linux sin `[Environment]::NewLine` | SR-16 | Inspeccion: `Select-String -Pattern 'Environment\]::NewLine' scripts/` vacio; T-02/T-04 sin ramas por plataforma | 0 coincidencias | T004 (parcial), FR-07 |

Comandos de verificacion reproducibles, sin red y sin tocar el repo real (NFR-03):

```powershell
# 1. Suite de la lib (contrato de comparacion, merge y flags)
Invoke-Pester tests/sync-kit-lib.Tests.ps1

# 2. Presencia y forma de la propagacion de flags
Select-String -Path scripts/sync-kit.ps1 -Pattern 'Sync-TransversalKit -RepoUrl .*-DryRun:\$DryRun -Force:\$Force'

# 3. Dot-source antes de las funciones (fail-closed temprano)
Select-String -Path scripts/sync-kit.ps1 -Pattern 'sync-kit-lib\.ps1|^function '

# 4. Ausencia de dependencia de plataforma en la escritura
Select-String -Path scripts/sync-kit-lib.ps1 -Pattern 'NewLine|Set-Content'

# 5. Efecto sobre el archivo real (solo tras merge, CA-04)
git diff --stat -- opencode.json

# 6. Integridad del JSON resultante (ADR-0010 R7)
jsonschema -i opencode.json https://opencode.ai/config.json
```

---

## 8. Veredicto de seguridad

### Veredicto: **PASS con observaciones**

La spec 029 **no introduce ninguna vulnerabilidad nueva explotable** en las superficies que declara, y en dos de ellas mejora el estado de seguridad:

1. **Mejora real en deteccion**: hoy tres archivos transversales reportan `[SKIP]` en cada corrida por puro ruido de EOL. Ese ruido entrena al operador a ignorar `[SKIP]`, que es el **unico** mensaje que indica "hay un cambio real que no se aplico". Eliminar el falso positivo (CA-01) convierte `[SKIP]` en una senal significativa: es un control de deteccion que hoy no funciona por fatiga de alertas.
2. **Mejora en determinismo de flags**: `-Force` y `-DryRun` dejan de depender del dynamic scoping. El caso peligroso (escribir cuando se pidio simular) queda fijado por parametro explicito y por test.

Las cuatro amenazas de severidad Alta/Critica (SR-01, SR-02, SR-03, SR-10) son **preexistentes** y el cambio las conserva o las congela:

| Amenaza | Relacion con la 029 | Bloquea el merge de la 029 |
|---|---|---|
| SR-01 (el merge adopta el resto del maestro) | Preexistente; hoy `-Force` copia el archivo **entero**, que es estrictamente peor. La 029 no lo empeora | No |
| SR-02 (`NoLocalMcp` → `Copy-Item` importa el `mcp` del maestro) | Preexistente; T019/T-11 lo **fija como contrato** a nivel de funcion, y T020 mantiene el fallback. Riesgo de que el test verde se confunda con cobertura | **No bloquea el codigo, si bloquea la propagacion** |
| SR-03 (escritura no atomica) | Preexistente (`Set-Content` tampoco era atomico). D-06 cambia la API sin cambiar la garantia | No |
| SR-10 (persistencia via `mcp` preservado) | Es el proposito declarado de FR-05/ADR-0009, no un efecto colateral | No |

### Condiciones antes de propagar a consumidores por `sync`

No son condiciones para el merge en el maestro (el codigo no empeora nada), sino para ejecutar el sync **contra proyectos consumidores**, donde el radio de impacto es N:

| # | Condicion | Motivo | Cobertura actual |
|---|---|---|---|
| C-01 | Verificar en sandbox que un destino **sin** `mcp` no termina con los `command` del maestro (SR-02) | Es el unico camino donde el sync importa rutas de otra maquina; hoy no tiene test end-to-end | Sin cobertura |
| C-02 | Decidir explicitamente si CA-06 "byte-identico" se reescribe como "semanticamente identico" (SR-09) | El criterio actual es inverificable con un round-trip JSON; un test escrito contra el pasara o fallara por razones equivocadas | Sin cobertura |
| C-03 | Confirmar que el dot-source esta **fuera** del `try` de `Sync-TransversalKit` y que un `pwsh -File` sin la lib devuelve exit code != 0 (SR-08) | Un `throw` dentro del `try` se convierte en `[WARN]` con exit 0: fallo silencioso del motor completo | T003 solo forma |
| C-04 | Emitir el SHA256 de `sync-kit-lib.ps1` en el log de arranque (SR-06) | Es la unica evidencia de que el codigo ejecutado es el que se reviso, y cuesta una linea | Sin cobertura |

### Que convertiria el veredicto en FAIL

- Que el dot-source se implemente **dentro** del `try` de `Sync-TransversalKit` o dentro de una funcion: convierte el fail-closed en fail-open silencioso (Art. VIII exige fail-closed para operaciones destructivas, y el sync lo es).
- Que `-Force` se propague con un valor literal (`-Force:$true`) o que se elimine el `param` de `Sync-TransversalKit` sin reemplazo: sobrescritura permanente o no-op permanente, ambos silenciosos.
- Que el merge escriba el archivo **antes** de decidir el estado (es decir, que `Write-KitJsonFile` se llame fuera del camino `'Merged'`): rompe el fail-closed de AC-01 y CA-06.
- Que la normalizacion se amplie mas alla de `\r\n` → `\n` (trim, colapso de lineas, reordenamiento de claves): ahi si se enmascaran cambios reales y NFR-04 queda violado.
- Que se modifique el guard `mcp` para que `-Force` lo pise (FA-01): propagaria rutas de otra maquina a todos los consumidores.

### Declaracion de limitaciones de esta auditoria

- No se ejecuto `scripts/sync-kit.ps1`, ningun test Pester, ni el sandbox. Los comportamientos descritos se derivan de lectura de codigo (L440-713, `sync-agents.ps1` L1-66) y del diseno de `plan.md` §3. Un comportamiento que dependa de la implementacion real de `ConvertTo-Json`/`ConvertFrom-Json` (SR-09, SR-15) queda enunciado como riesgo de diseño, no como hallazgo medido.
- No se verifico el contenido de ningun proyecto consumidor: A-02 (que `opencode.json` este gitignored alli) es un supuesto tomado de ADR-0009, no una medicion. Si en un consumidor el archivo **si** esta trackeado, SR-03 baja de Alto a Medio y RR-03 se mitiga con `git checkout`.
- No se audito `scripts/plataformador-bootstrap.ps1` ni `scripts/sync/*`: fuera de alcance por FA-02 y D-02.
- Los controles propuestos en §5 y §7 **no estan implementados**: este documento es un analisis, no una remediacion. Ninguna task de `tasks.md` se marco como completada y ninguna se modifico.

---

## 9. Etiquetado para `pensador` / `pendientes-implementacion.md`

Lista consolidada con el prefijo `security-risk:` para filtrar. Se respeta el estado real: ninguna de estas entradas esta implementada.

```markdown
# Riesgos de seguridad - Spec 029 (sync EOL normalizado y -Force efectivo)

## CRITICAL
- [ ] SR-01: El merge de opencode.json adopta del maestro todo lo que no es `mcp` (permission, plugin, instructions, provider, model) sin allowlist de claves ni validacion de schema; un maestro comprometido controla la politica de ejecucion de N consumidores (security-risk:CRITICAL) — sin cobertura en tasks.md

## HIGH
- [ ] SR-02: `NoLocalMcp` cae a Copy-Item y el consumidor adopta el bloque `mcp` del maestro con rutas absolutas de otra maquina; contradice la nota de seguridad del plan y ADR-0009 guardrail 1 (security-risk:HIGH) — T019 cubre la funcion, no el fallback
- [ ] SR-03: `WriteAllText` no es atomico; interrupcion a mitad de escritura deja opencode.json truncado y, en consumidores con el archivo gitignored, el bloque `mcp` no tiene otra copia (security-risk:HIGH) — sin cobertura
- [ ] SR-10: El `mcp` local preservado por diseño es persistencia para un `command` plantado; sobrevive todos los syncs y el motor reporta `[GUARD] PRESERVADO` (security-risk:HIGH) — sin cobertura por diseño (FR-05)

## MEDIUM
- [ ] SR-04: `-Force` declarado sin propagar se vuelve no-op silencioso y el consumidor queda con codigo viejo con apariencia de actualizado (security-risk:MEDIUM) — T013/T014/T015/T016
- [ ] SR-05: `-DryRun` no propagado escribe cuando el operador pidio simulacion (security-risk:MEDIUM) — T013/T014/T017
- [ ] SR-06: `sync-kit-lib.ps1` viaja por robocopy y se ejecuta por dot-source sin provenance; `-KitPath` admite codigo sin commitear (security-risk:MEDIUM) — sin cobertura
- [ ] SR-07: Un `scripts/sync-kit-lib.ps1` homonimo en el consumidor es pisado por robocopy sin WARN, y su version es la que se ejecuta en la corrida previa (security-risk:MEDIUM) — sin cobertura
- [ ] SR-08: Si el dot-source fail-closed cae dentro del `try` del motor, el `throw` se degrada a WARN con exit 0 (security-risk:MEDIUM) — T003 cubre la forma, no el comportamiento
- [ ] SR-09: `ConvertTo-Json -Depth 10` trunca estructuras profundas y la reserializacion no garantiza byte-identidad; CA-06 es inverificable tal como esta escrito (security-risk:MEDIUM) — sin cobertura
- [ ] SR-11: `ReadAllBytes` sin limite ni streaming: hasta ~3x el tamano en memoria, DoS con archivos grandes y clasificacion `EolOnly` de contenido binario (security-risk:MEDIUM) — sin cobertura

## LOW
- [ ] SR-12: TOCTOU entre comparacion y escritura (security-risk:LOW) — riesgo aceptado
- [ ] SR-13: Junction/symlink en el destino escribe fuera de `$RootPath` y rompe la frontera kit-app (security-risk:LOW) — sin cobertura
- [ ] SR-14: `-Force:$true` satisface el test AST; el merge elimina el BOM sin declararlo (security-risk:LOW) — T016 parcial, T018 parcial
- [ ] SR-15: `'Error'` sin causa pierde el motivo del fallo del merge y viola Art. V (security-risk:LOW) — sin cobertura
- [ ] SR-16: La normalizacion no enmascara contenido (verificado por construccion); residual de expectativa en el mensaje `[OK] ... solo difiere el fin de linea` (security-risk:LOW) — T004 cubre lo tecnico
```

### Resumen numerico

| Severidad | Cantidad | IDs |
|---|---:|---|
| Critical | 1 | SR-01 |
| High | 3 | SR-02, SR-03, SR-10 |
| Medium | 7 | SR-04, SR-05, SR-06, SR-07, SR-08, SR-09, SR-11 |
| Low | 5 | SR-12, SR-13, SR-14, SR-15, SR-16 |
| **Total** | **16** | SR-01 a SR-16 |

| Cobertura en `tasks.md` | Cantidad | IDs |
|---|---:|---|
| Cubierta (total o parcialmente con test verificable) | 5 | SR-04, SR-05, SR-08 (parcial), SR-14 (parcial), SR-16 (parcial) |
| **Sin cobertura** | **11** | SR-01, SR-02, SR-03, SR-06, SR-07, SR-09, SR-10, SR-11, SR-12, SR-13, SR-15 |

Los huecos que importan, en orden: **SR-01** (el merge es la puerta de entrada de configuracion del maestro a N consumidores), **SR-02** (unico camino que importa rutas de otra maquina, con test unitario que da falsa seguridad), **SR-03** (perdida irreversible del `mcp` local en consumidores sin git) y **SR-08** (un `throw` mal ubicado convierte el motor en fail-open silencioso).

---

*Generado por `security-auditor` — spec 029 threat model STRIDE.*
*Basado en: spec.md, plan.md §3/§6/§8, tasks.md, constitution v2.1.0 (Art. V, VII, VIII), ADR-0006, ADR-0009, ADR-0010 y lectura de `scripts/sync-kit.ps1` L440-713.*
