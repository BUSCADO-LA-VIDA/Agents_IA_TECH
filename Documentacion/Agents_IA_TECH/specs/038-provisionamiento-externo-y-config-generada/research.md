# Research: Aprovisionamiento externo por tipo y configuración generada

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Phase**: 0 (Outline & Research) | **Date**: 2026-11-12

**Input**: `spec.md` (FR-01 a FR-17, NFR-01 a NFR-08, decisiones D1-D5 del usuario, 2026-11-07) y `plan.md` (Technical Context).

**Estado de clarificaciones**: la spec cerró las cinco decisiones bloqueantes (D1-D5) en su sección "Decisiones de arquitectura del usuario". No queda ninguna clarificación abierta en el Technical Context. Las tareas de investigación de esta fase resuelven las incógnitas de *cómo* implementar esas decisiones, no *qué* hacer.

---

## R1 — Autoridad de versión para código de terceros integrado

**Unknown**: cómo determinar si un clon de `kit-integrado` o `kit-fuente` está al día, sin semver y sin confiar en refs locales.

**Decision**: la autoridad es el **SHA del branch head remoto**. La sonda compara `git rev-parse HEAD` del clon contra `git ls-remote <repo_url> refs/heads/<rama_seguida>`. El estado registra `rama_seguida`, `ultimo_sha`, `sha_remoto` y `ultimo_check`. Si el clon está en un tag (`detached`), la sonda usa el tag fijado como referencia e informa `detached` sin fallar.

**Rationale**: `git status` compara contra refs locales y por eso reporta `main...origin/main` sin divergencia mientras `spec-kit` está en `1.0.7.dev0` frente al release `v1.3.2` del 2026-11-06 (evidencia de la spec). El SHA remoto es el único dato que no depende del estado local del clon ni de un fetch reciente.

**Alternatives considered**:
- *Semver comparado con el último release tag*: descartado por D1 (la autoridad de `kit-integrado` es branch head; el versionado por release tag queda en backlog atado al instalador del KIT).
- *`git status` / `git rev-list --count`*: descartado, es exactamente el defecto documentado (miente sin red y sin fetch).
- *Checksum del árbol de trabajo*: descartado, cambia con cualquier edición local y no dice nada sobre el remoto.

---

## R2 — Esquema del manifest como única fuente de verdad

**Unknown**: qué campos debe tener cada entrada para cubrir los cinco tipos sin ramas ad hoc en el código.

**Decision**: `dependencias-manifest.yml` con raíz `dependencias_externas: []`. Cada entrada declara: `nombre`, `tipo_provisionamiento` (enum de cinco valores), `requerido` (bool), `ruta_local` (relativa, solo clones), `repo_url` y `rama_seguida` (solo clones), `gestor`/`paquete`/`comando` (solo MCP de workspace), `version.autoridad` con el valor que corresponde al tipo, y opcionalmente `version.archivo_local`, `version.campo_local` y `version.upstream_api`. El tipo es obligatorio y no se infiere por ruta ni extensión.

**Rationale**: una sola forma de declarar evita el defecto actual (manifest con `context-mode` v1.0.169 instalado 2.1.0 y `spec-kit` en `v0.0.0`). La autoridad de versión viaja con la dependencia, así que añadir un tipo nuevo no exige tocar el validador, solo el enum y su sonda.

**Alternatives considered**:
- *Un archivo de manifest por herramienta*: descartado, permite versiones contradictorias y rompe la atomicidad de versión.
- *Inferir el tipo por la ruta (`proyect_ext/` ⇒ clon)*: descartado por FR-01/FR-02; el tipo ausente debe ser FAIL, no una suposición.
- *YAML con `!include` o herencia*: descartado, la resolución del YAML tendría que implementarse a mano en PowerShell sin dependencia externa garantizada.

---

## R3 — Detección de binario resuelto y capacidades reales por servidor MCP

**Unknown**: cómo decide `generate` qué entradas emitir y cómo sabe `validate-parity` qué capacidades existen.

**Decision**: `generate` no confía en el estado: antes de escribir una entrada verifica que el `comando_resuelto` exista (`Test-Path` sobre la ruta resuelta o `Get-Command` sobre el nombre). Si no resuelve, emite WARN con el nombre y el comando declarado y omite la entrada (FR-08). Las capacidades se declaran en `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` con fuente y versión verificada; `validate-parity` cruza la columna de capacidad contra los usos de los agentes y falla si aparece una capacidad no declarada.

**Rationale**: el defecto raíz es "declaración contra declaración". Verificar el binario en el momento de escribir convierte cada entrada generada en una afirmación comprobada. La introspección automática de capacidades MCP no es fiable entre versiones (context-mode 2.1.0 expone `cli.mjs`, `server.mjs` y `opencode/plugin.js`, sin `build/`), así que la matriz se llena con evidencia citada, no con supuestos.

**Alternatives considered**:
- *Introspección del protocolo MCP para listar tools como "capacidades"*: descartado como fuente única; las herramientas del MCP no son las capacidades del arnés (delegación, hooks, permisos, frontmatter).
- *Confiar en `.opencode/mcp-state.json` sin re-verificar*: descartado por NFR-05 y por el riesgo "el estado se desincroniza del sistema real".
- *Fallar la generación completa si una entrada no resuelve*: descartado, viola FR-07/FR-08 (fail-open con WARN y omisión).

---

## R4 — Paridad entre arneses: qué se compara y dónde se corta

**Unknown**: cómo verificar que `opencode.json` y `.vscode/mcp.json` representan el mismo conjunto de servidores sin exigir que los dos formatos sean idénticos.

**Decision**: `validate-parity.ps1` compara (a) el **conjunto de nombres de servidor** bajo `mcp.servers` en ambos archivos, (b) los campos de cada entrada que deben coincidir (`command`, `args`, `env` referenciado por nombre, `type=stdio`) y (c) que toda diferencia de capacidad esté justificada por una fila de la matriz con estado distinto de `soportado`. El archivo de OpenCode usa `mcp.servers.<nombre>`; el de Copilot se genera con la misma fuente y se compara por campo, no por texto.

**Rationale**: los dos arneses tienen formatos distintos; comparar bytes daría falsos negativos. Comparar el conjunto de servidores y los campos de ejecución detecta el fallo relevante (un servidor presente en uno y ausente en el otro) y deja las diferencias de capacidad donde corresponden: la matriz versionada (FR-15, ADR-0014).

**Alternatives considered**:
- *Diff textual de los dos archivos*: descartado, formatos incompatibles.
- *Generar un archivo y copiarlo al otro*: descartado, produce divergencia silenciosa en cuanto un arnés cambie su esquema.
- *Un solo validador que también genere*: descartado, mezcla lectura y escritura (NFR-01).

---

## R5 — Estrategia de actualización por tipo de aprovisionamiento

**Unknown**: qué operación ejecuta `apply` en cada tipo sin contaminar el kit ni el contexto del agente.

**Decision**: `apply` es explícito y por tipo: (1) `kit-integrado` y `kit-fuente` → solo operaciones git sobre el clon en `proyect_ext/` (`fetch` + `reset --hard` a la rama seguida, o `fetch` del tag + `checkout` si está en tag; `--unshallow` si el clon es shallow), sin copiar ni sincronizar nada dentro del kit; (2) `mcp-workspace` → instalación con el gestor declarado (`npm`, `pip`/`uv`); (3) `mcp-build-local` → `fetch` + `checkout` + instalación de dependencias + build, y el estado solo pasa a `ok` si el artefacto declarado existe después del build; (4) `entorno` → verificación de versión mínima, sin instalar. Cada fallo deja `degraded` con causa, emite WARN y no aborta el resto (FR-07).

**Rationale**: D3 y D4 fijan que la integración al kit es manual y asistida por IA (spec 039); por eso `apply` se detiene en dejar el clon actualizado y aislado en `proyect_ext/`. Un `apply` que copiara archivos sería el mecanismo de la spec 039 y volvería a meter `AGENTS.md` de terceros en la raíz.

**Alternatives considered**:
- *`git pull` genérico*: descartado, falla con `HEAD` detached (tokenslayer en tag) y con clones shallow/grafted.
- *Reinstalar siempre en lugar de actualizar*: descartado, rompe la idempotencia (NFR-02) y multiplica el tiempo de `apply`.
- *Copiar el clon al kit dentro de `apply`*: descartado por D3/D4 y por FR-13 (aislamiento de clones).

---

## Consolidated findings

| ID | Decisión | Artefacto que la fija |
|---|---|---|
| R1 | SHA de branch head remoto como autoridad para clones | `contracts/mcp-state.schema.json`, `data-model.md` §ProvisioningState |
| R2 | Manifest con `tipo_provisionamiento` + `version.autoridad` obligatorios | `contracts/dependencias-manifest.schema.json` |
| R3 | Verificación de binario resuelto antes de emitir; capacidades con fuente y versión | `contracts/cli-provisioning.contract.md` (verbo `generate`), `data-model.md` §CapabilityMatrix |
| R4 | Paridad por conjunto de servidores y campos, no por texto | `contracts/cli-provisioning.contract.md` (verbo `validate-parity`) |
| R5 | Actualización por tipo, sin copia al kit | `contracts/cli-provisioning.contract.md` (verbo `apply`) |

**Verificación de la fase**: no quedan clarificaciones abiertas en el Technical Context; cada decisión tiene un artefacto de Phase 1 donde se materializa y una prueba asociada en `quickstart.md`.
