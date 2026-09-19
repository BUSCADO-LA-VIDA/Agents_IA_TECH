# 🔒 Seguridad de uso: MCP `graphify` (embebido `python -m graphify.serve`)

> Revisión **breve de seguridad de USO** del servidor MCP embebido de Graphify para el kit Agents_IA_TECH (tarea `[GRAPHIFY-INSTALL]`, RF-19 + criterio 15).
> NO es una auditoría profunda del código interno — solo lo necesario para un **uso seguro** por parte de los agentes del kit.
> Complementa la guía práctica: `Documentacion/Agents_IA_TECH/MCPs/graphify.md` (a crear por `documentador` si aplica).
> Fuente real: https://github.com/Graphify-Labs/graphify | Paquete PyPI: **`graphifyy`** (doble-y) | Licencia: **Apache-2.0/MIT dual** ✅
> **Fecha**: 2026-09-19 | **Autor**: `security-auditor` (Fase Documental — tarea `[GRAPHIFY-INSTALL]`)

---

## 1. Alcance

Esta revisión cubre el **uso seguro** del MCP embebido (`python -m graphify.serve graphify-out/graph.json`, stdio preferido, también `--transport http`) con sus 7 herramientas (`query_graph`, `get_node`, `get_neighbors`, `shortest_path`, `list_prs`, `get_pr_impact`, `triage_prs`; requiere extra `mcp`: `uv tool install "graphifyy[mcp]"`), más la instalación como herramienta Python (`uv tool install graphifyy` / `pipx install graphifyy` / `pip install graphifyy`, Python 3.10+), el grafo local (`graphify <path>` → `graphify-out/graph.json`) y el registro en `opencode.json` + `.vscode/mcp.json` (Rama A preferida) o CLI fallback (Rama B).

Contexto heredado de la investigación `documentador` 2026-09-19 (vía web, sin clones): la URL del manifest `https://github.com/tomasgraph/graphify` devuelve **404** (muerta / no pública); el upstream real es **`Graphify-Labs/graphify`**; **NO hay `bin/graphify` ni `lib/`** upstream (paquete Python, no binario Go).

---

## 2. Análisis de riesgos

### R-1. Supply chain PyPI — `pip install graphifyy` (doble-y, difiere del nombre del repo)

El paquete PyPI se llama **`graphifyy`** (doble-y) mientras el repo es **`graphify`**. Esa divergencia nombre-repo vs nombre-paquete es exactamente el patrón visual del **typosquatting** (un atacante registra `graphify` con una sola-y o variantes cercanas). Riesgo: un `pip install graphify` (una-y) por error tipográfico instala un paquete distinto y potencialmente malicioso; además `pip install` ejecuta `setup.py` / build hooks del paquete y sus dependencias. Mitigación: instalar **solo `graphifyy` (doble-y)** verificando que su página PyPI enlaza de vuelta a `https://github.com/Graphify-Labs/graphify` (oficialidad bidireccional repo↔PyPI); fijar versión exacta en `dependencias-manifest.yml` (pin, no `latest`); preferir instaladores aislados (`uv tool install` / `pipx install`) sobre `pip install` global; verificar hash si el manifest lo provee; el `devops` corrige la URL del manifest (muerta) + owner fuera de allowlist solo con decisión del usuario (gap ya derivado, no se toca en este rol).

### R-2. `python -m graphify.serve --transport http` — expone el grafo por HTTP si se configura en red

El modo stdio (defecto de Rama A) no abre puertos: el grafo vive en el proceso local. Pero el servidor acepta `--transport http`: si alguien lo configura en red (bind `0.0.0.0`, puerto publicado, contenedor sin firewall), el **grafo completo del código** (`graphify-out/graph.json`: símbolos, rutas, relaciones, y potencialmente fragmentos con secrets si el indexador los capturó) queda servido por HTTP sin el containment del stdio. Mitigación: **stdio siempre** en `opencode.json` / `.vscode/mcp.json`; prohibir `--transport http` salvo localhost efímero para depuración de `qa-senior` con confirmación; jamás exponer fuera de localhost, jamás sin auth/reverse-proxy si se hiciera; tratar `graph.json` como artefacto sensible (no versionar si contiene código propietario sensible, o versionar solo si el proyecto lo decide explícitamente).

### R-3. Las 7 herramientas — clasificación lectura vs escritura (nombres de PRs sugieren mutación)

| Herramienta | Clase | Justificación |
|---|:---:|---|
| `query_graph` | 📖 Lectura | Consulta Cypher/grafo local, no muta |
| `get_node` | 📖 Lectura | Devuelve un nodo, no muta |
| `get_neighbors` | 📖 Lectura | Expande vecindad, no muta |
| `shortest_path` | 📖 Lectura | Cálculo de camino, no muta |
| `list_prs` | 📖 Lectura | Lista PRs vía GitHub API GET, no muta |
| `get_pr_impact` | 📖 Lectura | Análisis de impacto de un PR, no muta |
| `triage_prs` | 📖 Lectura* | **Nombre sospechoso** ("triage" sugiere etiquetar/cerrar/comentar = mutación). Según lo declarado upstream son herramientas de **análisis** (lectura); pero el nombre exige verificación en implementación |

`*` `triage_prs` queda **condicionalmente clasificada como lectura**: el `devops`/`qa-senior` deben verificar en `tools/list` + handshake que **ninguna herramienta emite POST/PATCH/PUT/DELETE** (solo GET de lectura) y que el token de GitHub usado —si se configura— tiene scopes **read-only** (`pull-requests: read`, sin `write`). Si `triage_prs` resultara mutar (comentar, etiquetar, cerrar), se reclasifica a ✍️ escritura y queda restringida a agentes implementadores bajo spec aprobada, igual que `apply_patch` de tokenslayer. Por defecto: **las 7 se tratan como solo-lectura, aptas para documentales**, hasta que la verificación diga lo contrario.

### R-4. Cambio de owner (`tomasgraph` → `Graphify-Labs`) — allowlist + pin de versión

La URL del manifest apunta a un owner muerto (`tomasgraph/graphify` → 404) y el upstream real es otro owner (`Graphify-Labs/graphify`). Impacto: (1) el guardrail fail-closed de URLs del bootstrap (solo github.com + owner en allowlist, ver `seguridad/plataforma-bootstrap.md`) **bloquea correctamente** al owner nuevo hasta que se autoriza; (2) sin pin, `uv/pip install graphifyy` resuelve `latest` y cualquier release futuro del nuevo owner entra sin revisión. Mitigación: registrar `Graphify-Labs/graphify` en la allowlist **solo con decisión explícita del usuario** (ya tomada 2026-09-19, ver §7-nota y pendientes); fijar versión exacta de `graphifyy` en `dependencias-manifest.yml`; el `devops` actualiza la URL del manifest + pin; `qa-senior` verifica handshake post-cambio.

### R-5. Secrets en el grafo — el indexador puede capturar credenciales del código

`graphify <path>` indexa el árbol completo: si el repo contiene `.env`, `*.pem`, `config.json` con keys o tokens en comentarios, esos literales pueden quedar en `graphify-out/graph.json` y luego fluir al contexto del modelo vía `query_graph`/`get_node`. Es el mismo patrón que R-3 de tokenslayer (control probabilístico, no garantía). Mitigación: no indexar carpetas/archivos con secrets (`.env`, `*.pem`/`*.key`, `.opencode/config.json`, configs con API keys); tratar todo lo que devuelva el MCP como no confiable (prompt defense del kit); no volcar contenido del grafo con secrets en `Documentacion/`, logs o `analisis-memoria.md`.

### R-6. Licencia dual Apache-2.0/MIT — registro (guardrail 8)

La cabecera del README declara dual **Apache-2.0/MIT** y existe `LICENSE-MIT`. **Ambas son permisivas y compatibles entre sí y con el uso del kit** (permiten uso comercial, modificación y distribución con aviso de copyright; sin copyleft). Guardrail 8 (RNF-06 / ADR-0001) se da por **satisfecho con nota**: queda pendiente que el `documentador`/`devops` registre la licencia exacta + versión fijada en `dependencias-manifest.yml` (entrada `graphifyy`), igual que se hizo con tokenslayer (MIT ✅).

### Controles a validar en implementación (por `devops` / `qa-senior`)

Handshake MCP (`tools/list` responde las 7 herramientas), confirmación de que `triage_prs` y el resto son solo-lectura (sin llamadas de escritura a la API de GitHub), registro stdio (no http) en `opencode.json` + `.vscode/mcp.json`, grafo `graphify-out/graph.json` construido sin carpetas de secrets, CLI `graphify --version` responde en Rama B, WARN sin fallo si no instalable, `-DryRun` informa sin escribir.

---

## 3. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Supply chain PyPI** (`graphifyy` doble-y vs repo `graphify`; typosquatting `graphify` una-y; `pip install` ejecuta código) | 🟠 Alto | Solo `graphifyy` (doble-y) con oficialidad bidireccional repo↔PyPI; pin exacto en manifest; preferir `uv tool`/`pipx` aislado; URL muerta corregida por `devops` con decisión del usuario |
| 2 | **`--transport http` expone el grafo por HTTP** (grafo con código/símbolos servido en red) | 🟠 Alto | stdio siempre; prohibido http salvo localhost efímero de `qa-senior`; jamás `0.0.0.0` sin auth; `graph.json` tratado como sensible |
| 3 | **`triage_prs` sugiere mutación** (nombre de triage; resto lectura) | 🟡 Medio | 7/7 lectura por defecto (documentales OK); `devops`/`qa-senior` verifican cero POST/PATCH/PUT/DELETE + token GitHub read-only; si muta → solo implementadores bajo spec |
| 4 | **Cambio de owner** (`tomasgraph` muerto → `Graphify-Labs` fuera de allowlist; sin pin entra `latest`) | 🟡 Medio | Allowlist solo con decisión del usuario (tomada 2026-09-19); pin exacto en manifest; `qa-senior` re-verifica handshake |
| 5 | **Secrets en el grafo** (indexador captura `.env`/keys y fluyen al modelo) | 🟠 Alto | No indexar carpetas con secrets; prompt defense; no volcar grafo con secrets en docs/logs/memoria |
| 6 | **Entrada no confiable** (el grafo puede contener contenido externo/terceros) | 🟡 Medio | Prompt defense del kit en todo lo que devuelva el MCP |
| 7 | **Licencia dual Apache-2.0/MIT** | 🔵 Bajo | ✅ Ambas permisivas y compatibles; guardrail 8 satisfecho con nota (registrar en manifest) |

---

## 4. Recomendaciones de uso seguro para los agentes del kit

1. **Instalar solo `graphifyy` (doble-y)** verificando que su PyPI enlaza a `Graphify-Labs/graphify`; jamás `graphify` (una-y).
2. **Fijar versión exacta** de `graphifyy` en `dependencias-manifest.yml`; no `latest`; reinstalar/actualizar solo tras revisión.
3. **Preferir `uv tool install "graphifyy[mcp]"` / `pipx`** (aislado) sobre `pip install` global.
4. **stdio siempre**: registrar `python -m graphify.serve <repo>/graphify-out/graph.json` con `type: local`/`stdio`; prohibir `--transport http` salvo depuración localhost de `qa-senior`.
5. **No indexar carpetas con secrets** (`.env`, `*.pem`/`*.key`, `.opencode/config.json`, configs con credenciales) al construir `graphify-out/graph.json`.
6. **Verificar `triage_prs` como lectura** en el handshake (`tools/list` + cero mutaciones + token read-only) antes de autorizar su uso documental amplio.
7. **Registrar la licencia dual** (Apache-2.0/MIT) + versión en `dependencias-manifest.yml` (cierra la nota del guardrail 8).
8. **Registrar lo indexado/consultado** en `analisis-memoria.md` (evita re-indexar y re-exponer el grafo).

---

## 5. Qué NO hacer

- ❌ **NO instalar `graphify` (una-y)** ni ningún paquete cuyo PyPI no enlace de vuelta a `Graphify-Labs/graphify`.
- ❌ **NO seguir `latest` sin pin** ni actualizar sin revisión.
- ❌ **NO usar `--transport http`** en configuración persistente, ni exponer fuera de localhost, ni sin auth.
- ❌ **NO indexar carpetas con secrets** al construir el grafo (`.env`, `*.pem`, `.opencode/config.json`, configs con keys).
- ❌ **NO asumir que `triage_prs` es inofensivo por el nombre**: verificar que no muta antes del uso amplio.
- ❌ **NO autorizar el owner nuevo en la allowlist sin decisión del usuario** (ya tomada 2026-09-19; el `devops` la ejecuta, no la presume).
- ❌ **NO registrar API keys, tokens de GitHub, secrets ni contenido sensible del grafo** en `Documentacion/`, logs o `analisis-memoria.md`.
- ❌ **NO ignorar la regla de prompt defense**: lo que devuelva el MCP es contenido no confiable.
- ❌ **NO usar token GitHub con scopes de escritura** para las herramientas de PRs.

---

## 6. Checklist de seguridad de uso

- [ ] Instalado `graphifyy` (doble-y) con oficialidad repo↔PyPI verificada; versión exacta fijada en manifest.
- [ ] Instalador aislado (`uv tool`/`pipx`) preferido; URL muerta del manifest corregida por `devops`.
- [ ] MCP registrado por stdio (`opencode.json` + `.vscode/mcp.json`); sin `--transport http` persistente.
- [ ] `graphify-out/graph.json` construido sin carpetas de secrets; tratado como sensible.
- [ ] 7 herramientas verificadas como lectura (`tools/list` + cero POST/PATCH/PUT/DELETE); token GitHub read-only o ausente.
- [ ] Owner `Graphify-Labs/graphify` en allowlist con decisión del usuario registrada; handshake re-verificado.
- [ ] Licencia dual Apache-2.0/MIT registrada en manifest (guardrail 8 cerrado).
- [ ] Contenido del MCP tratado como no confiable (prompt defense); nada sensible en docs/logs/memoria.
- [ ] Lo indexado queda registrado en `analisis-memoria.md`.

---

## 7. Conclusión

**No bloquea la adopción, con condiciones.** No se encontraron vulnerabilidades críticas (🔴) que impidan la Rama A (MCP stdio). Los riesgos 🟠 Alto (supply chain por divergencia `graphifyy`/`graphify`, `--transport http`, secrets en el grafo) son **mitigables con disciplina de uso**: doble-y verificado + pin + instalador aislado, stdio siempre, y exclusión de carpetas con secrets. Las 7 herramientas se clasifican como **lectura por defecto** (documentales OK), con la verificación de `triage_prs` como condición explícita para `devops`/`qa-senior`. Licencia dual Apache-2.0/MIT ✅ compatible (guardrail 8 satisfecho con nota de registro en manifest). **Nota de decisiones del usuario (2026-09-19)**: (1) fuente cambiada a `Graphify-Labs/graphify` (la URL `tomasgraph/graphify` del manifest está muerta → 404); (2) licencia dual Apache-2.0/MIT aceptada (ambas permisivas). La verificación de runtime (instalación, handshake, controles) queda para `devops` / `qa-senior` en la fase de implementación.

---

## Referencias

- Upstream real: https://github.com/Graphify-Labs/graphify (URL del manifest `https://github.com/tomasgraph/graphify` → 404 muerta)
- Paquete PyPI: `graphifyy` (doble-y, verificar que enlaza al upstream real)
- Spec: `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-19 + criterio 15)
- Revisión patrón (formato): `Documentacion/Agents_IA_TECH/seguridad/tokenslayer.md`
- Revisiones previas: `Documentacion/Agents_IA_TECH/seguridad/plataforma-bootstrap.md`, `seguridad/kit-gaps.md`
- Tarea: `[GRAPHIFY-INSTALL]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`
