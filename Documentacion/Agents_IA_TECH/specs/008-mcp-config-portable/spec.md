# Feature Specification: [MCP-CONFIG-PORTABLE] — Configuración dinámica y portable de MCPs en OpenCode (eliminación de `.opencode/config.json` y uso de memoria segura)

**Feature Branch**: `008-mcp-config-portable`

**Created**: 2026-09-24

**Status**: Draft

**Input**: El usuario detectó que opencode se saltó el flujo y no creó esta feature. Debe documentar: (1) eliminación de `.opencode/config.json` (obsoleto, con placeholders `__PEGAR_AQUI_TU_NVIDIA_API_KEY__`, `__PEGAR_AQUI_TU_DEEPINFRA_API_KEY__`, `__GITHUB_TOKEN_OPCIONAL__`; los tokens NO van ahí, están en la memoria segura de opencode vía `opencode auth login`); (2) configuración dinámica de MCPs — NO hardcodear rutas absolutas en `opencode.json`, la configuración debe ser dinámica y portable entre proyectos/equipos, auto-creada desde `scripts/plataformador-bootstrap.ps1`; (3) mecanismo efectivo de resolución — según ADR-0006 (feature 007), OpenCode NO auto-carga `.env.mcp`, el mecanismo efectivo es el campo `environment` o ruta real en `command`; la feature 008 debe definir cómo el bootstrap genera la config dinámica portable; (4) tokens en memoria segura — los API keys (NVIDIA, DeepInfra, etc.) se gestionan con `opencode auth` (secure storage), NO en archivos de config versionados.

---

## Problema

El kit `Agents_IA_TECH` mantiene un archivo `.opencode/config.json` (gitignored) que el bootstrap (`Ensure-OpenCodeConfig` en `scripts/plataformador-bootstrap.ps1`) crea con **placeholders** (`__PEGAR_AQUI_TU_NVIDIA_API_KEY__`, `__PEGAR_AQUI_TU_DEEPINFRA_API_KEY__`, `__GITHUB_TOKEN_OPCIONAL__`) que el usuario debe rellenar **a mano** con sus API keys. Este mecanismo es **obsoleto y riesgoso** por varias razones:

1. **Los tokens NO van en archivos de config**: OpenCode ya ofrece **memoria segura** (secure storage) vía `opencode auth login`, que guarda las credenciales cifradas fuera del control de versiones. Mantener un archivo `.opencode/config.json` con placeholders invita al error clásico de rellenarlo con keys reales y commitearlo por accidente (riesgo 🔴 documentado en `seguridad/kit-gaps.md` §1.1 y `seguridad/blindaje-git.md` §1.1).
2. **Configuración no portable**: el mecanismo actual depende de que el usuario rellene a mano un archivo local por proyecto. No hay una fuente única y portable que se auto-genere desde el bootstrap.
3. **Mecanismo de resolución incompleto**: la feature 007 (ADR-0006) ya estableció que OpenCode **NO auto-carga `.env.mcp`** y que el mecanismo efectivo es el campo `environment` o la ruta real en `command`. La feature 008 debe **cerrar el ciclo**: eliminar el archivo obsoleto y definir cómo el bootstrap genera la config dinámica portable sin depender de archivos de secrets versionados.

**Impacto**: el kit mantiene un mecanismo de gestión de secrets obsoleto y riesgoso (`.opencode/config.json` con placeholders), que no aprovecha la memoria segura de opencode y que puede derivar en fuga de credenciales por commit accidental.

---

## Objetivos

- **Eliminar `.opencode/config.json`** como mecanismo de gestión de secrets: los API keys se gestionan con la **memoria segura** de opencode (`opencode auth login`), no en archivos de config versionados ni locales con placeholders.
- **Configuración dinámica y portable de MCPs**: `opencode.json` NO hardcodea rutas absolutas; la config se auto-genera desde `scripts/plataformador-bootstrap.ps1` de forma portable entre proyectos/equipos.
- **Mecanismo efectivo de resolución**: definir cómo el bootstrap genera la config dinámica portable usando el campo `environment` o la ruta real en `command` (según ADR-0006), sin depender de la auto-carga de `.env.mcp`.
- **Tokens en memoria segura**: los API keys (NVIDIA, DeepInfra, etc.) se gestionan con `opencode auth` (secure storage), nunca en archivos de config versionados.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Eliminar `.opencode/config.json` y migrar a memoria segura (Priority: P1)

Como usuario del kit, quiero que el bootstrap **deje de crear y mantener** `.opencode/config.json` con placeholders, y que mis API keys se gestionen con la **memoria segura** de opencode (`opencode auth login`), para no arriesgar una fuga de credenciales por commit accidental.

**Why this priority**: Es el riesgo de seguridad más crítico (🔴). Eliminar el archivo obsoleto cierra el vector de fuga de secrets de raíz.

**Independent Test**: Puede verificarse de forma independiente: tras la migración, el bootstrap **no crea** `.opencode/config.json` y, si el archivo existe, lo **elimina** (o lo ignora y avisa), y las keys se resuelven vía `opencode auth`.

**Acceptance Scenarios**:

1. **Given** un proyecto donde el bootstrap se ejecuta por primera vez, **When** corre `Ensure-OpenCodeConfig` (o su reemplazo), **Then** NO se crea `.opencode/config.json` con placeholders.
2. **Given** un proyecto que ya tiene `.opencode/config.json` con placeholders, **When** corre el bootstrap, **Then** el archivo se elimina (o se marca como obsoleto con WARN) y se instruye al usuario a usar `opencode auth login`.
3. **Given** un usuario que necesita configurar NVIDIA/DeepInfra, **When** sigue las instrucciones del bootstrap, **Then** usa `opencode auth login` (memoria segura) y NO rellena placeholders en un archivo versionado.

---

### User Story 2 - Configuración dinámica y portable de MCPs (Priority: P1)

Como usuario del kit, quiero que `opencode.json` **no contenga rutas absolutas** de mi PC y que la configuración de MCPs se **auto-genere** desde `scripts/plataformador-bootstrap.ps1` de forma portable, para que el kit funcione igual en cualquier proyecto/equipo sin editar rutas a mano.

**Why this priority**: Es el requisito central de portabilidad. Sin él, el kit no es reproducible entre máquinas/equipos.

**Independent Test**: Puede verificarse de forma independiente: `opencode.json` versionado no contiene ninguna ruta absoluta de la PC; el bootstrap genera la config dinámica con rutas resueltas en runtime.

**Acceptance Scenarios**:

1. **Given** el `opencode.json` versionado del kit, **When** se inspecciona, **Then** NO contiene rutas absolutas de la PC (solo tokens / `{env:...}` / rutas relativas).
2. **Given** un proyecto nuevo, **When** corre el bootstrap, **Then** se genera la config dinámica de MCPs con las rutas locales resueltas (vía `environment` o ruta real en `command`).
3. **Given** dos proyectos/equipos distintos, **When** ambos corren el bootstrap, **Then** cada uno obtiene su config dinámica local sin editar `opencode.json` a mano.
4. **Given** un MCP instalado, **When** el bootstrap captura su ruta, **Then** la ruta queda registrada en el inventario central y es usada por opencode y cualquier otro arnés (mismas rutas en todos los arneses).
5. **Given** un MCP que se actualiza, **When** el bootstrap valida su ruta, **Then** la ruta se actualiza en el inventario si cambió (nueva versión/ubicación).
6. **Given** un MCP que se desinstala, **When** el bootstrap borra su ruta, **Then** la ruta se elimina del inventario central para que no cause fallos por rutas huérfanas.
7. **Given** opencode que está fallando por MCPs rotos, **When** el bootstrap genera la config dinámica con rutas válidas, **Then** opencode puede arrancar correctamente.

---

### User Story 3 - Mecanismo efectivo de resolución (Priority: P2)

Como usuario del kit, quiero que el bootstrap genere la config dinámica usando el **mecanismo efectivo** de resolución (campo `environment` o ruta real en `command`, según ADR-0006), para que los MCPs queden `enabled: true` con rutas válidas sin depender de la auto-carga de `.env.mcp`.

**Why this priority**: Es el mecanismo que garantiza que los MCPs funcionen de verdad. Depende de la feature 007 (ya implementada), por lo que es P2 (complementa, no bloquea).

**Independent Test**: Puede verificarse de forma independiente: tras el bootstrap, cada MCP instalado queda `enabled: true` con ruta resuelta (vía `environment` o ruta real), sin tokens `__*_CMD__` ni `{env:...}` irresolubles.

**Acceptance Scenarios**:

1. **Given** un MCP instalado, **When** corre el bootstrap, **Then** su `command` queda con ruta real o `{env:...}` resuelto, y `enabled: true`.
2. **Given** un MCP con `{env:...}` cuya variable no está en el entorno, **When** corre el bootstrap, **Then** se sustituye por la ruta real o el campo `environment` (nunca queda un `{env:...}` irresoluble).
3. **Given** una herramienta MCP ausente, **When** corre el bootstrap, **Then** NO se registra una entrada rota y se emite WARN con el comando de instalación.

---

### User Story 4 - Tokens en memoria segura (Priority: P2)

Como usuario del kit, quiero que mis API keys (NVIDIA, DeepInfra, etc.) se gestionen con `opencode auth` (secure storage), para que nunca queden en archivos de config versionados ni en placeholders locales.

**Why this priority**: Complementa la US1 (eliminación del archivo). Es P2 porque depende de que el usuario use `opencode auth login`, pero el kit debe instruirlo y no ofrecer la alternativa riesgosa.

**Independent Test**: Puede verificarse de forma independiente: el kit no crea ningún archivo de secrets con placeholders; la documentación y el bootstrap instruyen a usar `opencode auth login`.

**Acceptance Scenarios**:

1. **Given** un usuario que configura sus keys, **When** sigue la guía del kit, **Then** usa `opencode auth login` y NO rellena placeholders en `.opencode/config.json`.
2. **Given** el kit, **When** se busca en la config versionada, **Then** NO hay API keys reales ni placeholders de secrets en archivos versionados.
3. **Given** un proyecto, **When** se verifica el estado de secrets, **Then** las keys viven en la memoria segura de opencode, no en archivos del repo.

---

### Edge Cases

- ¿Qué pasa si el usuario **ya tiene** `.opencode/config.json` con keys reales (no placeholders)? → El bootstrap debe **no borrarlo a ciegas** (podría perder credenciales) y avisar cómo migrar a `opencode auth login` (WARN + instrucciones), sin destruir datos.
- ¿Qué pasa si `opencode auth` no está disponible o el usuario no ha hecho login? → El bootstrap debe degradar con WARN accionable (instruir `opencode auth login`) y no fallar.
- ¿Qué pasa si el usuario **sí** rellenó placeholders con keys reales y las commiteó? → Detección defensiva: WARN con `git rm --cached` + rotar keys (ya previsto en `Ensure-OpenCodeConfig`; la feature 008 debe mantenerlo o migrarlo).
- ¿Qué pasa si un proyecto consumidor aún tiene `.opencode/config.json` versionado por error? → El bootstrap debe detectarlo y avisar (WARN + `git rm --cached` + rotar), sin borrar el archivo local automáticamente.
- ¿Qué pasa si el sync transversal copia un `.opencode/config.json` del maestro? → Debe excluirse siempre (ya previsto en `Sync-TransversalKit`); la feature 008 debe confirmar que la exclusión persiste tras eliminar el archivo.
- ¿Qué pasa si un MCP se **desinstala** pero su ruta queda en el inventario? → El bootstrap debe **borrar la ruta** del inventario central al desinstalar (FR-004c), para que no quede una ruta huérfana que cause fallos al arrancar opencode u otro arnés.
- ¿Qué pasa si un MCP se **actualiza** y su ruta cambia (nueva versión/ubicación)? → El bootstrap debe **validar y actualizar** la ruta en el inventario (FR-004b), de modo que todos los arneses usen la ruta nueva.
- ¿Qué pasa si un MCP **futuro** (aún no implementado) se agrega al kit? → El bootstrap debe poder **determinar y capturar** su ruta al instalarlo (FR-004a), sin requerir edición manual de `opencode.json`.
- ¿Qué pasa si un arnés (p. ej. Copilot) y opencode necesitan la misma ruta de MCP? → El inventario central garantiza que **todos los arneses usen las mismas rutas** (FR-004), evitando divergencias entre arneses.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE dejar de crear `.opencode/config.json` con placeholders como mecanismo de gestión de secrets. Los API keys se gestionan con la memoria segura de opencode (`opencode auth login`).
- **FR-002**: El sistema DEBE eliminar (o marcar como obsoleto con WARN) un `.opencode/config.json` existente que contenga solo placeholders, e instruir al usuario a usar `opencode auth login`.
- **FR-003**: El sistema DEBE **no borrar a ciegas** un `.opencode/config.json` existente que contenga valores reales (no placeholders); DEBE avisar cómo migrar a `opencode auth login` sin destruir credenciales.
- **FR-004**: El sistema DEBE actuar como **registro central / inventario dinámico de rutas de MCPs**. El `plataformador-bootstrap-instalador-unico` (`scripts/plataformador-bootstrap.ps1`) DEBE **determinar la ruta correcta** para cada MCP (los actuales y los futuros que se implementen) y **almacenarla** en una fuente única, de modo que **opencode y cualquier arnés** (Copilot, OpenCode, etc.) usen **las mismas rutas** (consistencia entre arneses). La configuración DEBE ser **dinámica y portable** (sin hardcodear rutas absolutas en `opencode.json`), y DEBE **permitir arrancar opencode** (que es el arnés que está fallando).
- **FR-004a**: El sistema DEBE **capturar la ruta** de cada MCP **al instalarlo** y registrarla en el inventario central.
- **FR-004b**: El sistema DEBE **validar la ruta** de cada MCP **al actualizarlo** y **actualizarla** en el inventario si cambió (p. ej. nueva versión, nueva ubicación).
- **FR-004c**: El sistema DEBE **borrar la ruta** de un MCP **al desinstalarlo** del inventario central, para que no queden rutas huérfanas que causen fallos.
- **FR-005**: El sistema DEBE usar el **mecanismo efectivo** de resolución (campo `environment` o ruta real en `command`, según ADR-0006) para que los MCPs queden `enabled: true` con rutas válidas, sin depender de la auto-carga de `.env.mcp`.
- **FR-006**: El sistema DEBE instruir al usuario a gestionar sus API keys (NVIDIA, DeepInfra, etc.) con `opencode auth` (secure storage), nunca en archivos de config versionados.
- **FR-007**: El sistema DEBE mantener la detección defensiva de secrets versionados (WARN con `git rm --cached` + rotar keys) si `.opencode/config.json` (o cualquier archivo de secrets) aparece trackeado por git.
- **FR-008**: El sistema DEBE mantener la exclusión de `.opencode/config.json` (y archivos de secrets) del sync transversal y del control de versiones.

### Key Entities *(include if feature involves data)*

- **`.opencode/config.json`**: Archivo local obsoleto con placeholders de secrets. La feature 008 lo elimina como mecanismo de gestión de secrets (o lo marca obsoleto). No debe versionarse.
- **Memoria segura de opencode (`opencode auth`)**: Almacenamiento cifrado de credenciales fuera del control de versiones. Es el destino de los API keys (NVIDIA, DeepInfra, etc.).
- **`opencode.json`**: Config principal de OpenCode. Debe ser portable (sin rutas absolutas), con la config de MCPs generada dinámicamente por el bootstrap.
- **`.env.mcp`**: Fuente de verdad portable de rutas MCP (de la feature 007). NO es auto-cargada por OpenCode; el mecanismo efectivo es `environment`/ruta real.
- **`scripts/plataformador-bootstrap.ps1`**: Script que actúa como **registro central / inventario dinámico de rutas de MCPs**. Determina la ruta correcta de cada MCP (actuales y futuros), la almacena en una fuente única, y la comparte con opencode y cualquier arnés. Gestiona el ciclo de vida de rutas: **capturar al instalar**, **validar/actualizar al actualizar**, **borrar al desinstalar**. También genera la config dinámica y portable de MCPs y gestiona la migración de secrets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tras la migración, el bootstrap NO crea `.opencode/config.json` con placeholders en el 100% de los proyectos nuevos.
- **SC-002**: Un `.opencode/config.json` existente con solo placeholders se elimina (o marca obsoleto con WARN) en el 100% de los casos, sin destruir credenciales reales.
- **SC-003**: `opencode.json` versionado NO contiene ninguna ruta absoluta de la PC en el 100% de los casos (verificable por inspección).
- **SC-003a**: El bootstrap actúa como **registro central de rutas de MCPs**: determina y almacena la ruta correcta de cada MCP (actuales y futuros) en una fuente única, y **todos los arneses** (opencode, Copilot, etc.) usan **las mismas rutas** en el 100% de los casos.
- **SC-003b**: Al **instalar** un MCP, el bootstrap **captura** su ruta en el inventario central en el 100% de los casos.
- **SC-003c**: Al **actualizar** un MCP, el bootstrap **valida** su ruta y la **actualiza** en el inventario si cambió, en el 100% de los casos.
- **SC-003d**: Al **desinstalar** un MCP, el bootstrap **borra** su ruta del inventario central en el 100% de los casos (sin rutas huérfanas que causen fallos).
- **SC-003e**: Tras el bootstrap, **opencode puede arrancar** correctamente (los MCPs quedan con rutas válidas, sin entradas rotas que impidan el arranque).
- **SC-004**: Tras el bootstrap, el 100% de los MCPs instalados quedan `enabled: true` con ruta resuelta (vía `environment` o ruta real), sin tokens `__*_CMD__` ni `{env:...}` irresolubles.
- **SC-005**: El kit instruye a usar `opencode auth login` para los API keys en el 100% de los flujos de configuración de secrets.
- **SC-006**: Ningún archivo de secrets (`.opencode/config.json` u otro) aparece trackeado por git tras la migración; si aparece, el sistema emite WARN con `git rm --cached` + rotar keys.

---

## Assumptions

- OpenCode ofrece **memoria segura** (secure storage) vía `opencode auth login` para gestionar API keys fuera del control de versiones (verificado en docs oficiales de OpenCode).
- La feature 007 (ADR-0006) ya está implementada y establece que OpenCode **NO auto-carga `.env.mcp`**; el mecanismo efectivo es el campo `environment` o la ruta real en `command`. La feature 008 **no reimplementa** ese mecanismo, solo lo usa y cierra el ciclo de eliminación del archivo obsoleto.
- El bootstrap (`scripts/plataformador-bootstrap.ps1`) es la fuente única que genera la config dinámica y portable de MCPs.
- Un `.opencode/config.json` con valores reales (no placeholders) puede contener credenciales del usuario; el sistema no debe borrarlo a ciegas.
- La eliminación de `.opencode/config.json` no rompe la resolución de `{env:NVIDIA_API_KEY}` / `{env:DEEPINFRA_API_KEY}` en `opencode.json`, porque esas variables se resuelven desde la memoria segura de opencode (o el entorno del proceso), no desde el archivo eliminado.

---

## Resumen de implementación

*Sincronizado desde README.md 2026-09-24*

### Problema original
- Error JSON con `InvalidEscapeCharacter` en `opencode.json` por rutas absolutas hardcodeadas.
- `.opencode/config.json` con placeholders `__PEGAR_AQUI_TU_NVIDIA_API_KEY__`, `__PEGAR_AQUI_TU_DEEPINFRA_API_KEY__`, `__GITHUB_TOKEN_OPCIONAL__` → mecanismo obsoleto y riesgoso.
- OpenCode NO auto-carga `.env.mcp` (ADR-0006).
- Falta de inventario central de rutas → divergencia entre arneses.

### Solución implementada
- Restauración de `opencode.json` desde backup y bootstrap que re-resuelve tokens desde `.env.mcp`.
- Eliminación de `Ensure-OpenCodeConfig` y reemplazo por `Migrate-OpenCodeSecrets` con migración defensiva.
- Inventario central `.env.mcp` ampliado con `CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`, `TOKENSLAYER_CMD`, `GRAPHIFY_CMD`.
- Ciclo de vida: `Register-McpPath`, `Update-McpPath`, `Remove-McpPath`.
- Validación JSON sin escapes inválidos.

### Estado actual
- MCPs conectados: `context-mode`, `codebase-memory-mcp`, `tokenslayer`, `graphify`.
- `markitdown` con limitación: timeout / no responde.
- `opencode.json` portable sin rutas absolutas.
- Secrets gestionados con `opencode auth login`.

### Guardrails cumplidos
- No persistir rutas absolutas.
- Inventario central único.
- Tokens en memoria segura.
- No borrar a ciegas.
- Mecanismo efectivo de resolución.
- Exclusión del sync.
