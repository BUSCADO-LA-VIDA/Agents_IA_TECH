# 🔒 Seguridad del diseño: 3 gaps de auditoría real — tokenslayer 4º MCP + plantilla `config.json` + reorganización docs sueltas (RF-16/17/18)

> Revisión **de seguridad del DISEÑO** de las extensiones RF-16 (`Ensure-OpenCodeMcp`), RF-17 (`Ensure-OpenCodeConfig`) y RF-18 (`Repair-DocStructure`) de `plataformador-bootstrap.ps1` (plan aprobado 2026-09-19; gaps detectados en auditoría real de Metatrader: el bootstrap solo registraba 3 MCPs, sin plantilla versionada de `.opencode/config.json`, docs sueltas en raíz fuera de `Documentacion/<App>/`).
> Enfocada en: **plantilla con placeholders que el usuario convierte en secrets y commitea, registro de un binario inexistente/comprometido, mover tracking vivo con click-through, mover un archivo que otro proceso tiene abierto**.
> Fuente: `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-16/17/18, criterios 12/13/14) y `pendientes-implementacion.md` (tarea `[PLATAFORMA]`, extensión T-D8).
> Complementa: `seguridad/plataforma-bootstrap.md` (diseño base: supply chain, secrets en configs, ejecución de scripts descargados, URLs, licencias, sobrescritura — no la sustituye) y `seguridad/tokenslayer.md` (revisión del MCP tokenslayer: `apply_patch`, supply chain clon+npm, secrets en esqueletos).
> Autor: `security-auditor` (fase documental — tarea `[PLATAFORMA]`, extensión RF-16/17/18)

---

## 1. Análisis de riesgos del diseño de las 3 extensiones

### 1.1 Riesgo de plantilla `config.json` con placeholders que el usuario reemplaza por secrets y luego commitea por error

`Ensure-OpenCodeConfig` crea `.opencode/config.json` desde una plantilla con PLACEHOLDERS que el usuario debe sustituir a mano por API keys / credenciales locales. El archivo sigue gitignored, pero el flujo normal invita al error clásico: el usuario edita la plantilla, pone su key real, y en el siguiente commit — o al tocar `.gitignore`, al usar `git add -A` / `git add -f`, o al copiar el proyecto — el archivo con el secret real acaba versionado. Una vez commiteado, el secret queda en el historial aunque se borre después (hay que rotarlo, no basta con eliminarlo). El riesgo se agrava porque la plantilla vive dentro del repo (el diff muestra los placeholders y "anima" a rellenarlos en el mismo archivo versionado) y porque el bootstrap, por diseño, no vuelve a tocar el archivo: nadie re-verifica su contenido tras la edición manual.

**Puntos de validación necesarios:**
- **Plantilla con placeholders imposibles de confundir con valores reales** (p. ej. `__PEGAR_AQUI_TU_API_KEY__`, nunca `sk-...`, strings vacías ni ejemplos con formato válido) + comentario inline en cada placeholder: "NO commitear con valor real — este archivo es local".
- **El flow recuerda el gitignore en cada paso**: el WARN/instrucción de `Ensure-OpenCodeConfig`, el `README.md` (troubleshooting `config.json`) y la plantilla misma mencionan que el archivo está gitignored y que `git add -f` lo rompería. (Hereda `plataforma-bootstrap.md` §1.4: configs del kit = plantillas sin secrets.)
- **Verificación defensiva**: si el bootstrap detecta que `.opencode/config.json` está trackeado por git (`git ls-files` lo lista) → WARN explícito "contiene posibles secrets versionados: revisar `git rm --cached` + rotar keys". Barato de implementar, detecta el error después de cometido.
- **`DryRun` informa sin escribir** (ya en criterio 13); si el archivo existe → no lo toca nunca, ni siquiera para "actualizar la plantilla" (ya en spec: evita pisar keys reales con placeholders).

### 1.2 Riesgo de registrar tokenslayer apuntando a un binario inexistente/comprometido

`Ensure-OpenCodeMcp` escribe en `opencode.json` un `command: [node, <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js]`. Esa ruta es **código que OpenCode ejecutará en cada sesión** (MCP `type: local`). Dos sub-casos: (a) **inexistente** — `build/index.js` no se compiló (se clonó sin `npm run build`, se borró `proyect_ext/` por ser gitignored, o el usuario corre el bootstrap en máquina nueva): el MCP falla al arrancar y, según el harness, puede bloquear la carga de `opencode.json` o degradar en silencio dejando al usuario sin el 4º MCP creyendo que lo tiene; (b) **comprometido** — alguien reemplazó `build/index.js` (o el `node` que lo ejecuta) por código malicioso: el bootstrap lo registraría sin más, y el payload correría con los permisos del usuario en cada sesión (lectura de archivos del proyecto vía `analyze_files`, exfiltración por red si el JS la implementa). `proyect_ext/` no se versiona por decisión explícita, así que no hay diff de repo que delate la sustitución.

**Puntos de validación necesarios:**
- **Fail-closed suave ya previsto (WARN + no falla)**: si el binario no existe → WARN + instrucciones de compilar (`npm install && npm run build`), no falla el bootstrap. Mantenerlo: nunca auto-compilar (`npm install` ejecuta scripts de terceros) ni registrar rutas alternativas sin validar.
- **Containment de la ruta registrada**: el `command` debe resolverse a ruta canónica **dentro de `<repo>/proyect_ext/tokenslayer/mcp-server/`** (nada de `..`, rutas absolutas externas, ni `node` resolviendo a un binario fuera del `PATH` esperado). Sin normalización, una entrada manipulada en el manifest o una variable de repo con `..` redirige la ejecución.
- **Verificación de integridad mínima**: comprobar que `build/index.js` existe + `package.json` del `mcp-server/` coincide con la versión fijada en el manifest (v1.5.0 / commit `9a380c04`); si hay skew (como el ya conocido server interno 1.3.0) → informar, no bloquear. Ideal: hash pinned del `build/index.js` conocido en el manifest (hereda hashing/pinning de `plataforma-bootstrap.md` §1.2).
- **Fuente del binario fijada**: la ruta deriva de la entrada `tokenslayer-mcp-server` en `dependencias-manifest.yml` (pin de versión + commit), no de un string suelto en el script. (Hereda `seguridad/tokenslayer.md`: supply chain clon+npm ya auditado; esta revisión cubre solo el registro.)

### 1.3 Riesgo de mover tracking vivo (87KB) aunque sea con confirmación — click-through sin leer

RF-18 protege los archivos >50KB o con tracking vivo listándolos en vez de moverlos, y exige OK explícito individual. Pero la confirmación por archivo S/N/T/C degrada con el volumen: ante 10–20 docs sueltas el usuario pulsa `[T]odos` en bucle y el "OK explícito individual" del `pendientes-*.md` de 87KB — el archivo que los implementadores leen primero como puente vivo doc→implementación — se autoriza sin haber leído qué significa moverlo (rutas rotas en specs que lo referencian, pérdida del ancla que otros agentes usan, reindexación de `context-mode` apuntando a la ruta vieja). `[T]` actúa como bypass de hecho sobre el archivo más crítico del kit.

**Puntos de validación necesarios:**
- **El tracking vivo nunca cae dentro del `[T]odos`**: el `T` aplica solo a docs rutinarias pequeñas; cada archivo >50KB o con tracking vivo exige su propia respuesta S/N individual, aunque el usuario ya haya pulsado `T` antes. (Precedente: `relocate-cleanup.md` §1.5 — el `.venv` nunca cae dentro del "sí a todo" de cachés.)
- **Advertencia específica antes de preguntar por el tracking vivo**: qué archivo es, quién lo consume (`pendientes-implementacion.md` lo leen los implementadores primero; moverlo rompe referencias), tamaño, y qué hay que actualizar tras moverlo (referencias en specs, reindexación). Decisión informada, no a ciegas.
- **Default seguro = No mover** (sin respuesta → se lista y se queda). Coherente con huérfanos default Conservar y relocate no-interactivo no mueve.
- **No-interactivo y `DryRun` fail-closed**: sin consola → solo lista, jamás mueve; `-DryRun` informa la lista con tamaños, cero escrituras (ya en criterio 14).

### 1.4 Riesgo de `Repair-DocStructure` moviendo un archivo que otro proceso tiene abierto

Mover un `.md` que otro proceso tiene abierto (VS Code con el archivo en el editor, `context-mode` indexándolo, un agente leyéndolo, un `git` en curso) produce resultados según el SO y el modo de apertura: en Windows `Move-Item` suele fallar con lock (error visible pero a mitad de una tanda S/N/T/C ya se movieron otros), y si el proceso lo tenía abierto por ruta, tras el movido guarda una **copia fantasma en la ruta vieja** (resucita el archivo que se creía movido → duplicado divergente). Peor: si el lector era el indexador, el índice queda apuntando a la ruta vieja sin error visible.

**Puntos de validación necesarios:**
- **Movido transaccional por archivo con verificación post-movido**: mover → verificar que el destino existe y el origen ya no → si el origen reaparece o el movido falla por lock, informar + rollback concreto de ese archivo (mover de vuelta), sin abortar toda la tanda en silencio. (Hereda transacción-por-app de `relocate.md` §1.3, aquí por archivo.)
- **Pre-chequeo barato de locks visibles**: si el archivo está bloqueado para mover (`Move-Item` lanzaría) → que el error se capture por archivo (try/catch individual), se informe "omitido por lock, reintentar tras cerrar el editor/indexador" y se continúe con el resto. Nunca un solo lock debe abortar o corromper la tanda.
- **Orden seguro**: mover primero las docs rutinarias; el tracking vivo y los grandes, al final y de uno en uno, con su confirmación separada (§1.3) — así un lock a mitad no deja medio kit movido.
- **`DryRun` lista sin tocar** (ya en criterio 14); el informe final enumera movidos/omitidos (por lock) / solo-listados (>50KB/tracking) por separado, sin ambigüedad.

### 1.5 Riesgo de alcance fuera de lo sagrado (mover algo que no es doc suelta)

El detector de "docs sueltas de raíz" trabaja sobre patrones (`00-indice.md`, `pendientes-*.md`, etc.). Un patrón amplio o una futura ampliación ad hoc puede cazar archivos que no son docs sueltas: `README.md` de la raíz (guía de despliegue, debe quedarse), `AGENTS.md`, `opencode.json`, o un `pendientes-*.md` que el usuario creó a propósito en la raíz como borrador. Moverlo "con confirmación" no consuela si la pregunta no muestra a dónde va ni por qué se clasificó como suelta.

**Puntos de validación necesarios:**
- **Allowlist de nombres exactos + destino explícito por archivo**: cada candidato muestra origen → destino (`Documentacion/<App>/` concreta) + motivo de clasificación antes de preguntar. Nada de globs amplios (`*.md` en raíz) ni recursivo.
- **`Documentacion/<AppName>/` como destino, nunca como fuente**: el escaneo solo mira la raíz (profundidad 0/1 documentada); jamás entra a `Documentacion/` a "reorganizar" dentro (frontera sagrada, guardrail 1).
- **Nunca borra** (ya en criterio 14): el movido fallido deja el original intacto; sin flag de borrado ni reutilización de `-Force` para esta función.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Plantilla `config.json` → secret commiteado** (placeholders sustituidos por keys reales + `git add -A`/`-f`, `.gitignore` tocado) → credenciales en historial (rotación obligada) | 🔴 Crítico | Placeholders inconfundibles (`__PEGAR_AQUI_...__`, nunca formato válido) + aviso inline "NO commitear"; flow recuerda el gitignore (WARN + README + plantilla); **detección defensiva: si está trackeado → WARN con `git rm --cached` + rotar**; si existe no se toca nunca; `DryRun` sin escritura. |
| 2 | **Binario tokenslayer inexistente/comprometido** (`build/index.js` sin compilar o sustituido; `proyect_ext/` sin versionar no delata el cambio) → MCP roto o ejecución de código malicioso en cada sesión | 🔴 Crítico | Sin binario → WARN + instrucciones de compilar, no falla (sin auto-`npm install`); **containment-check** (ruta canónica dentro de `proyect_ext/tokenslayer/mcp-server/`); verificación de versión fijada en manifest (v1.5.0/commit) + hash pinned ideal; fuente del manifest, no string suelto. |
| 3 | **Tracking vivo movido por click-through** (`pendientes-*.md` 87KB autorizado con `[T]` sin leer) → referencias rotas, agentes sin ancla, índice apuntando a ruta vieja | 🟠 Alto | **Tracking vivo fuera del `[T]odos`** (S/N individual siempre); advertencia específica (quién lo consume, qué actualizar tras moverlo); default No mover; no-interactivo/`DryRun` solo listan. |
| 4 | **Mover archivo abierto por otro proceso** (editor, indexador, git) → movido a medias, copia fantasma en ruta vieja, índice apuntando a ruta vieja | 🟠 Alto | Movido **transaccional por archivo** (mover → verificar destino/origen → rollback concreto); error de lock capturado por archivo (omitir + informar + continuar); tracking vivo/grandes al final de uno en uno; informe movidos/omitidos/solo-listados por separado. |
| 5 | **Alcance fuera de lo sagrado** (glob amplio caza `README.md`, `AGENTS.md`, borradores propios) → archivo movido fuera de su sitio | 🟠 Alto | Allowlist de nombres exactos + destino explícito por archivo (origen → `Documentacion/<App>/` + motivo) antes de preguntar; escaneo solo en raíz, nunca dentro de `Documentacion/`; nunca borra; `-Force` no aplica. |
| 6 | **Fuga por log** (rutas absolutas con usuario al informar movidos/omitidos) | 🟡 Medio | Logs con rutas relativas + metadatos (tamaño, fecha), nunca contenido; sin secrets (hereda `plataforma-bootstrap.md` §1.4 y `relocate.md` §1.9). |

---

## 3. Recomendaciones de uso seguro

1. **Pasar `-DryRun` primero** y leer la lista: qué registraría (tokenslayer con ruta exacta), si crearía `config.json`, y qué docs movería/listaría con tamaños. Cero escrituras.
2. **Compilar tokenslayer antes del bootstrap** (`cd proyect_ext/tokenslayer/mcp-server && npm install && npm run build`) si se quiere el 4º MCP; si el WARN aparece, seguirlo en vez de registrar una ruta rota a mano.
3. **No rellenar la plantilla `config.json` con keys reales hasta verificar `git check-ignore .opencode/config.json`**; ante la duda, responder No a mover y revisar el tracking vivo a mano.
4. **Cerrar el editor/indexador sobre las docs a mover** antes del modo real; si un archivo se omite por lock, reintentar tras cerrar, no forzarlo.
5. **Responder No por defecto ante la duda**, sobre todo en el tracking vivo: mover `pendientes-*.md` exige actualizar referencias y reindexar; hacerlo con prisa rompe más de lo que ordena.
6. **Si `config.json` ya se commiteó con secrets**: `git rm --cached`, rotar las keys (borrar no basta), y luego verificar el ignore. Tratarlo como incidente, no como limpieza.
7. **Guardar el informe final** (qué se registró/creó/movió/omitió): es la única prueba de lo autorizado y la base para auditar el click-through (§1.3).

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO poner secrets reales en la plantilla** ni ejemplos con formato válido (`sk-...`, URLs con token): solo placeholders inconfundibles.
- ❌ **NO commitear `.opencode/config.json`** (`git add -A`/`-f` sin revisar, tocar su línea en `.gitignore`): si ya pasó → `git rm --cached` + **rotar keys**.
- ❌ **NO tocar `.opencode/config.json` si ya existe** (ni "actualizar la plantilla" por encima de keys reales).
- ❌ **NO auto-compilar tokenslayer desde el bootstrap** (`npm install` ejecuta código de terceros): solo WARN + instrucciones.
- ❌ **NO registrar rutas MCP fuera de `proyect_ext/tokenslayer/mcp-server/`** (nada de `..`, absolutas externas, ni `node` inesperado): containment-check siempre.
- ❌ **NO meter el tracking vivo / >50KB en el `[T]odos`**: S/N individual siempre, default No.
- ❌ **NO usar `[T]odos` sin leer** el resumen (equivale a bypass de hecho sobre el archivo más crítico del kit).
- ❌ **NO agregar flag que saltee la confirmación** de `Repair-DocStructure` (ni reutilizar `-Force` del bootstrap: no aplica aquí).
- ❌ **NO reorganizar en modo no interactivo** (fail-closed: solo lista) ni simular consola para forzarlo.
- ❌ **NO escanear dentro de `Documentacion/`** ni borrar nada (esta función mueve o lista, jamás borra).
- ❌ **NO volcar contenido ni secrets** al log/consola/CI (solo rutas relativas + metadatos).

---

## 5. Checklist de seguridad para las 3 extensiones (extiende `plataforma-bootstrap.md` §5)

- [ ] `opencode.json` registra `tokenslayer` (`type: local`, `command: [node, <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js]`, `enabled: true`); firmas/estilo existentes intactos.
- [ ] Sin binario → WARN + instrucciones de compilar, sin fallar; jamás auto-`npm install`/`npm run build` desde el bootstrap.
- [ ] Ruta del binario con containment-check (canónica dentro de `proyect_ext/tokenslayer/mcp-server/`, sin `..` ni absolutas externas); fuente en `dependencias-manifest.yml` (versión/commit fijados).
- [ ] Plantilla `config.json` solo con PLACEHOLDERS inconfundibles + aviso inline de no commitear; jamás secrets reales en plantilla versionada.
- [ ] `Ensure-OpenCodeConfig` crea SOLO si no existe; si existe no lo toca nunca; el archivo sigue gitignored; el flow (WARN + README + plantilla) recuerda el gitignore.
- [ ] Detección defensiva: `config.json` trackeado por git → WARN con `git rm --cached` + rotar keys.
- [ ] `Repair-DocStructure` con confirmación por archivo S/N/T/C, sin bypass; `-Force` no aplica; nunca borra.
- [ ] Tracking vivo / >50KB: solo se listan por defecto; **fuera del `[T]odos`** (S/N individual con advertencia específica); default No mover.
- [ ] No-interactivo → solo lista, no mueve. `-DryRun` informa todo con cero escrituras.
- [ ] Movido transaccional por archivo (verificar destino + origen ausente; rollback concreto); lock capturado por archivo (omitir + informar + continuar); informe movidos/omitidos/solo-listados por separado.
- [ ] Allowlist de nombres exactos + destino explícito por archivo; escaneo solo en raíz, nunca dentro de `Documentacion/`; `Documentacion/<AppName>/` intacta como fuente.
- [ ] Logs solo rutas relativas + metadatos; sin contenido ni secrets.
- [ ] `qa-senior` valida con `-DryRun` + fixtures en `$env:TEMP` (binario ausente → WARN; `config.json` existente intacto + trackeado → WARN; señuelo >50KB/tracking fuera del `[T]`; archivo con lock omitido; `README.md`/`AGENTS.md` no cazados) antes del rollout.

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** Las 3 extensiones cierran gaps reales de la auditoría de Metatrader con los controles estructurales adecuados: WARN sin fallo ante binario ausente, plantilla solo-si-no-existe con placeholders y gitignore vigente, confirmación por archivo S/N/T/C sin bypass con grandes/tracking vivo solo listados, nunca borra, `-DryRun` sin escrituras.

Los dos riesgos que deben **tratarse como severidad crítica innegociable** durante la implementación (a cargo de `devops`/`qa-senior`) son:

1. **Plantilla → secret commiteado** (riesgo 1 🔴) — el gitignore existe pero el flow invita a rellenar y commitear; la mitigación (placeholders inconfundibles + recuerdo del gitignore en WARN/README/plantilla + **detección defensiva de trackeado con aviso de rotar** + no-tocar-si-existe) debe quedar en los criterios de aceptación, no solo en la doc.
2. **Binario inexistente/comprometido** (riesgo 2 🔴) — el bootstrap registra una ruta que OpenCode ejecutará cada sesión y `proyect_ext/` no se versiona; la mitigación (WARN sin auto-instalación + **containment-check** + versión fijada en manifest + hash pinned ideal) debe quedar en los criterios de aceptación, no solo en la doc.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- placeholders inconfundibles + recuerdo del gitignore + detección de `config.json` trackeado con aviso de `rm --cached` + rotación + no-tocar-si-existe;
- WARN sin fallo ni auto-compilación + containment-check de la ruta + pin de versión/commit en manifest;
- tracking vivo/>50KB fuera del `[T]odos` + S/N individual con advertencia + default No + no-interactivo/`DryRun` solo listan;
- movido transaccional por archivo + locks por archivo + allowlist exacta + nunca `Documentacion/` como fuente + nunca borra;
- `qa-senior` valide con `-DryRun` + fixtures en `$env:TEMP` (incluyendo señuelos: `config.json` trackeado que debe avisar, binario ausente que debe WARN, tracking señuelo fuera del `[T]`, archivo con lock omitido, `README.md` no cazado) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — RF-16/17/18, criterios 12/13/14 (fuente de esta revisión).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[PLATAFORMA]` (extensión T-D8, plan aprobado 2026-09-19).
- `Documentacion/Agents_IA_TECH/seguridad/plataforma-bootstrap.md` — Diseño base (formato heredado §§1-6; riesgos de supply chain, secrets, ejecución, URLs, licencias, sobrescritura; checklist §5 que este archivo extiende).
- `Documentacion/Agents_IA_TECH/seguridad/tokenslayer.md` — Revisión del MCP tokenslayer (`apply_patch`, supply chain clon+npm, secrets en esqueletos; licencia MIT ✅).
- `Documentacion/Agents_IA_TECH/seguridad/relocate.md` — Precedentes: transacción por unidad, `[T]odos` como bypass, fuga por log.
- `Documentacion/Agents_IA_TECH/seguridad/relocate-cleanup.md` — Precedente: irreversible fuera del "sí a todo" + default seguro (aplicado aquí al tracking vivo).
- `dependencias-manifest.yml` — Entrada `tokenslayer-mcp-server` (v1.5.0, commit `9a380c04`, fuente del binario para RF-16).
