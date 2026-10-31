# Perfiles de Whitelist Estáticos y Versionados

**Fuente de verdad:** este archivo es la fuente de verdad para la resolución de whitelist. No se modifica por corridas de `sync` ni por formateo de agente. Si el bootstrap necesita actualizar un frontmatter, lee este perfil y aplica la regla `(tier, proyecto_tipo)`.

---

## 1. Perfil `kit`

| Tier | Whitelist efectiva (kit) | Comentario |
|---|---|---|
| **Documental** | `Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | Sin `src/` ni `scripts/` (es un proyecto de specs, no de código) |
| **Documental extendido** | `src/<App>/.specify/`, `Documentacion/<App>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | Expansión del `.specify` kit a un proyecto de specs |
| **Implementador** | **workspace completo** | `developer` puede escribir en todo el repositorio (todos los paths). Es una consecuencia de `proyecto_tipo = kit`, no una excepción del tier. |
| **Tooling** | ramas, commits, PRs, merges, reverts | Operaciones sobre el repo git; no paths de ficheros |
| **Plataforma** | diagnóstico remoto y nivelación | Sobre sistemas operativos, no paths del repo |

**Regla de precedencia (FR-19):** `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`.  
En el kit, `proyecto_tipo = kit`, el modificador `kit` no expande más allá del workspace: la intersección con el tier da el resultado de la tabla. Nunca amplía.

---

## 2. Perfil `consumidor`

| Tier | Whitelist efectiva (consumidor) | Comentario |
|---|---|---|
| **Documental** | `Documentacion/<App>/` únicamente | Solo la docs de la aplicación. Sin `.github/`, `.opencode/`, `.doc_agents/` del kit. |
| **Documental extendido** | `Documentacion/<App>/specs/` (dentro de su app) | Igual que kit, pero confinado al árbol de su aplicación. |
| **Implementador** | `src/<App>/`, `tests/`, scripts de la app | `developer` está acotado a `src/`, tests y scripts propios. **MUST NOT** escribir en `.github/`, `.opencode/`, `.doc_agents/` del kit ni `Documentacion/<OtraApp>/`. |
| **Tooling** | ramas, commits, PRs, merges, reverts | Operaciones sobre el repo de la aplicación. |
| **Plataforma** | diagnóstico remoto y nivelación | Sobre sistemas, no paths del repo. |

**Regla de precedencia (FR-19):** `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`.  
En consumidor, `proyecto_tipo = consumidor`, el modificador `consumidor` **restringe** el tier: un `Implementador` que en kit tendría workspace completo, en consumidor se acota a `src/<App>/`, `tests/` y scripts propios.

---

## 3. Regla de resoluci️n (FR-19)

**Fórmula:** `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`, con intersección restrictiva (fail-closed).

**Cuadro resumido:**

| Tier | `proyecto_tipo = kit` | `proyecto_tipo = consumidor` |
|---|---|---|
| **Documental** | `Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | `Documentacion/<App>/` únicamente |
| **Documental extendido** | `src/<App>/.specify/`, `Documentacion/<App>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` | `Documentacion/<App>/specs/` (dentro de su app) |
| **Implementador** | **workspace completo** | `src/<App>/`, `tests/`, scripts de la app |
| **Tooling** | ramas, commits, PRs, merges, reverts | igual |
| **Plataforma** | diagnóstico remoto y nivelación | igual |

**Claves:**
- **Manda el tier** (rango constitucional en Art. VII, declarado en frontmatters).
- **La capa actúa como modificador restrictivo:** nunca amplía.
- **Fail-closed:** ante duda, valor restrictivo (`consumidor`).
- **Paridad harnesses:** idéntica tabla en `.github/agents/` y `.opencode/agents/`.

---

## 4. Materialización por el Bootstrap (FR-21)

Al instalar en un consumidor, el bootstrap:
1. Lee el perfil `gobernanza/perfiles-whitelist.md` (sección `proyecto_tipo = consumidor`).
2. Escribe el bloque `permission` correspondiente en el frontmatter de cada agente del consumidor.
3. Fija `proyecto_tipo: consumidor` en `.bootstrap-state.json`.

**El perfil estático es la fuente; el frontmatter es la aplicación.** Si el sync pisara el `.md`, el bootstrap se re-ejecuta y lo regenera.

---

## 5. Verificación de divergencias (obligatorio)

Un paso de auditoría MUST comparar el frontmatter real del consumidor contra el perfil estático y reportar divergencias. Si un agente declara un `permission` que contradice el perfil, el sistema debe:
- Emitir WARN con el nombre del agente y la sección en conflicto.
- No aplicar la escritura prohibida.
- Registrar el evento en `.bootstrap-audit.log`.

---

## 6. Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-10-29 | Perfil inicial creado con tablas FR-04 y FR-19 | `pensador` |