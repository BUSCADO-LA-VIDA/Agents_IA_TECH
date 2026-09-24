# Feature Specification: [MCP-TOKEN-RESOLUTION] — Resolución de tokens MCP + .env por proyecto + upgrade de herramientas + self-update + activación en el kit maestro

**Feature Branch**: `007-mcp-token-resolution`

**Created**: 2026-09-24

**Status**: Draft

**Input**: Bug reportado en proyectos consumidores: la plantilla MCP versionada conserva tokens sin resolver (`__CONTEXT_MODE_CMD__`, `__CODEBASE_MEMORY_CMD__`, `__MARKITDOWN_CMD__`) y `enabled: false`, y el bootstrap (`scripts/plataformador-bootstrap.ps1`) no los re-resuelve ni con `-Force`. El kit maestro es el único proyecto donde el bootstrap nunca corre, por lo que sus MCPs quedan deshabilitados permanentemente.

---

## Problema

El bootstrap plataforma proyectos y promete (en el `_note` de la plantilla) que los tokens de los MCPs se re-resolverán a rutas locales en runtime. Esa promesa **no se cumple**:

1. **Tokens sin resolver en la plantilla versionada**: `opencode.json` contiene los tokens `__CONTEXT_MODE_CMD__`, `__CODEBASE_MEMORY_CMD__`, `__MARKITDOWN_CMD__` con `enabled: false`. Se decidió no versionar rutas absolutas (correcto), pero falta el paso de resolución.
2. **`Ensure-OpenCodeMcp` no re-resuelve** (L359-360): si `opencode.json` ya tiene sección `mcp` y no se pasa `-Force`, hace `Write-OK "se conserva"` y **no entra** al bloque de re-resolución (L395-414). La re-resolución solo ocurre cuando se **crea** el bloque `mcp`, no cuando ya existe.
3. **`-Force` deja los tokens intactos**: sobrescribe `opencode.json` copiando la plantilla tal cual; la re-resolución posterior (L395-414) solo actúa si el valor del comando es exactamente el token — pero el bloque recién copiado puede quedar inconsistente con el resto de la config.
4. **El sync sobrescribe lo resuelto**: el sync transversal (L1897) copia `opencode.json` del maestro al local, sobrescribiendo las rutas resueltas con la plantilla de tokens (o SKIP si difiere), perpetuando el bug.
5. **Paradoja del kit maestro**: es el ÚNICO proyecto donde el bootstrap nunca corre (ejecutarlo dispararía el sync que se sobrescribiría a sí mismo) → sus MCPs quedan `enabled: false` permanentemente.

**Impacto**: los agentes del kit no tienen acceso a las herramientas MCP (context-mode, codebase-memory, markitdown, graphify, tokenslayer) en el proyecto maestro, degradando la calidad del contexto y del trabajo agéntico.

---

## Objetivos

- Que la re-resolución de tokens MCP ocurra **siempre** en `Ensure-OpenCodeMcp`, conservando el resto de la configuración de `opencode.json`.
- Que el bootstrap sea **idempotente**: correrlo N veces no duplica ni corrompe el bloque `mcp`.
- Introducir **`.env.mcp` por proyecto** (gitignored) como fuente de rutas resueltas; `opencode.json` referencia `{env:...}` (interpolación soportada por OpenCode).
- **Forzar upgrade** de las herramientas MCP externas con un flag explícito y fail-open.
- **Auto-actualizar el bootstrap** desde el maestro (con flag de escape y auto-skip en el kit).
- **Activar los MCPs en el kit maestro** sin disparar el sync que se sobrescribiría a sí mismo.
- **Degradar con WARN accionable** cuando una herramienta MCP no está instalada/compilada, en lugar de registrar una entrada rota.

---

## Requisitos Funcionales

### RF-01 — Re-resolución de tokens SIEMPRE

La re-resolución de tokens en `Ensure-OpenCodeMcp` DEBE ejecutarse en toda corrida del bootstrap, **no solo cuando se crea el bloque `mcp`**. El parche es quirúrgico y **DEBE preservar** las demás claves del `opencode.json` existente (`providers`, `permission`, `model`, `region`, `plugin`, etc.). Las entradas `enabled: true` que ya tienen ruta real NO se tocan.

**Criterios de aceptación**:
- Dado un `opencode.json` con sección `mcp` presente (sin `-Force`), cuando corre el bootstrap, entonces los tokens se re-resuelven a rutas reales y NO se reporta "se conserva" dejando tokens.
- Dado un `opencode.json` con claves `providers`/`permission`/`model`/`region`/`plugin`, cuando corre el bootstrap, entonces esas claves permanecen inalteradas.

### RF-02 — Idempotencia

Correr el bootstrap dos o más veces DEBE producir un bloque `mcp` estable: sin entradas duplicadas, sin corrupción, sin degradación de rutas ya resueltas.

**Criterios de aceptación**:
- Dado un proyecto ya resuelto, cuando se corre el bootstrap por segunda vez, entonces el bloque `mcp` resultante es equivalente al de la primera corrida (mismas claves, mismas rutas, sin duplicados).
- Dado un proyecto ya resuelto, cuando se corre el bootstrap con `-Force`, entonces el bloque `mcp` no queda con tokens sin resolver.

### RF-03 — `.env.mcp` por proyecto

El bootstrap DEBE crear `<proyecto>/.env.mcp` la primera vez, conteniendo las rutas resueltas `CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`. `opencode.json` DEBE referenciar `{env:CONTEXT_MODE_CMD}` (y análogos) en lugar de rutas absolutas. `.env.mcp` DEBE agregarse a `.gitignore` y NUNCA commitearse. El bootstrap DEBE incluirlo en el cuadro resumen final.

**Criterios de aceptación**:
- Dado un proyecto sin `.env.mcp`, cuando corre el bootstrap, entonces se crea `.env.mcp` con las tres variables y se agrega a `.gitignore`.
- Dado un `opencode.json` resuelto por `.env.mcp`, entonces el comando del MCP es `["{env:CONTEXT_MODE_CMD}"]` (no una ruta absoluta).
- `git check-ignore .env.mcp` devuelve 0 (ignorado).
- El cuadro resumen final lista `.env.mcp`.

### RF-04 — Forzar upgrade de herramientas externas

El bootstrap DEBE soportar el flag `-ForceUpgradeTools` que reinstala/actualiza `context-mode`, `codebase-memory-mcp`, `markitdown`, `graphifyy[mcp]` y construye tokenslayer. El comportamiento DEBE ser **fail-open**: ante fallo de una herramienta → WARN y continúa con las demás.

**Criterios de aceptación**:
- Dado `-ForceUpgradeTools`, cuando corre el bootstrap, entonces intenta actualizar cada herramienta y reporta OK/WARN por cada una.
- Dado que el upgrade de una herramienta falla (sin red, sin permisos), cuando corre el bootstrap, entonces se emite WARN y el bootstrap NO aborta.
- Sin `-ForceUpgradeTools`, no se intenta ningún upgrade.

### RF-05 — Self-update del bootstrap

El bootstrap DEBE implementar `Update-Self`: clon shallow del maestro → comparar SHA256 del propio `.ps1` → si difiere, sobrescribir el local con la versión del maestro y re-ejecutar preservando `$PSBoundParameters`. DEBE ser **fail-open**, soportar `-SkipSelfUpdate` y auto-saltarse cuando el repo local ES el kit maestro. La lógica de actualización DEBE incluir `scripts/plataformador-bootstrap.ps1`.

**Criterios de aceptación**:
- Dado un proyecto consumidor con un bootstrap desactualizado y red disponible, cuando corre, entonces se actualiza y re-ejecuta con los mismos argumentos.
- Dado el kit maestro o `-SkipSelfUpdate`, cuando corre, entonces NO se intenta self-update.
- Dado fallo de clon (sin red), cuando corre, entonces WARN y continúa con la versión local.

### RF-06 — Activar MCPs en el kit maestro

Se DEBE revertir el commit `4a13718` (volver a la plantilla con tokens versionados), crear `.env.mcp` local en el kit (gitignored), y `opencode.json` DEBE usar `{env:...}`. El bootstrap DEBE ofrecer un **modo kit seguro** (`-SkipSync` o `-KitMode`) para resolver/validar los MCPs en el kit maestro **sin** disparar el sync que se sobrescribiría a sí mismo.

**Criterios de aceptación**:
- Dado el kit maestro, cuando corre el bootstrap en modo kit seguro, entonces los MCPs se resuelven a `enabled: true` y NO se dispara el sync transversal.
- La plantilla versionada NO contiene rutas absolutas (solo tokens / `{env:...}`).
- `opencode.json` del kit queda con MCPs activos.

### RF-07 — Manejo de graphify y tokenslayer

Si `python -m graphify.serve --help` falla, el bootstrap NO DEBE registrar la entrada de graphify + DEBE emitir WARN con el comando exacto de instalación (`uv tool install "graphifyy[mcp]"`). Si falta `mcp-server/build/index.js` de tokenslayer, NO DEBE registrar la entrada + DEBE emitir WARN con instrucciones de clonado + build. (Mismo patrón que el `WARN` ya existente para tokenslayer.)

**Criterios de aceptación**:
- Dado que graphify no está instalado, cuando corre el bootstrap, entonces NO se registra la entrada y se muestra el comando exacto de instalación.
- Dado que falta `mcp-server/build/index.js`, cuando corre el bootstrap, entonces NO se registra tokenslayer y se muestran las instrucciones de clonado+build.
- En ambos casos, el bootstrap continúa (fail-open).

### RF-08 — Verificación y reporte final

Al terminar, el bootstrap DEBE imprimir el bloque `mcp` resultante + un resumen de qué entradas quedaron `enabled: true/false` y por qué.

**Criterios de aceptación**:
- Al final de una corrida, la salida incluye el bloque `mcp` resuelto y, por cada entrada, su estado `enabled` y la razón.
- Una entrada `enabled: false` siempre viene acompañada de la causa (token no resuelto, herramienta ausente, etc.).

---

## Requisitos No Funcionales

- **RNF-01 (Seguridad)**: NO commitear rutas absolutas de la PC en la plantilla versionada; tokens / `{env:...}` son la fuente versionada y se resuelven en runtime. `.env.mcp` y `.opencode/config.json` DEBEN estar gitignored.
- **RNF-02 (Retrocompatibilidad)**: No romper proyectos que ya tienen `opencode.json` resuelto (con rutas reales o `{env:...}`); el bootstrap debe conservarlos.
- **RNF-03 (Idempotencia)**: Múltiples corridas producen el mismo resultado (ver RF-02).
- **RNF-04 (Fail-open)**: Self-update, upgrade de herramientas y registro de MCPs degradan con WARN, nunca abortan el bootstrap.
- **RNF-05 (Sincronización entre arneses)**: Cambios de agentes/reglas transversales sincronizados `.github/` ↔ `.opencode/` (Regla 3), si aplica.
- **RNF-06 (Conventional commits)**: Los commits siguen conventional commits.
- **RNF-07 (Containment)**: Rutas registradas de tokenslayer deben quedar bajo `<root>/proyect_ext/tokenslayer/` (sin `..` ni rutas externas).

---

## Fuera de Alcance

- Cambiar el mecanismo de interpolación `{env:...}` de OpenCode (se usa tal cual lo soporta OpenCode).
- Compilar automáticamente tokenslayer (ejecutar `npm install` de terceros está prohibido; solo instrucciones).
- Rediseñar el sync transversal más allá de excluir/ajustar el manejo de `opencode.json`.
- Resolver tokens MCP de terceros no listados (solo context-mode, codebase-memory-mcp, markitdown, tokenslayer, graphify).

---

## Dependencias

- `scripts/plataformador-bootstrap.ps1` — `Ensure-OpenCodeMcp` (L345), `Update-Self` (L1721), sync transversal (L1897), `Resolve-McpCommand`, `Ensure-OpenCodeConfig` (L503).
- `opencode.json` — plantilla con tokens + interpolación `{env:...}`.
- `dependencias-manifest.yml` — entradas `tokenslayer-mcp-server` y herramientas externas.
- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — bootstrap, `Sync-TransversalKit`, `Resolve-ActiveApp`.
- `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` — re-indexación y memoria.
- Commit `4a13718` — a revertir (RF-06).

---

## Criterios de Éxito

### Measurable Outcomes

- **SC-001**: Correr el bootstrap en un proyecto con `opencode.json` ya existente deja el 100% de los MCPs instalados resueltos a `enabled: true` con rutas válidas (o `{env:...}` resoluble), sin conservar tokens.
- **SC-002**: Dos corridas consecutivas del bootstrap producen un bloque `mcp` idéntico (0 duplicados, 0 corrupciones).
- **SC-003**: `git check-ignore .env.mcp` devuelve 0 y la plantilla versionada no contiene ninguna ruta absoluta de la PC.
- **SC-004**: El kit maestro queda con sus 5 MCPs activos (`enabled: true`) sin ejecutar el sync transversal.
- **SC-005**: Ante herramienta MCP ausente, el bootstrap NO registra una entrada rota y emite el comando exacto de instalación en el 100% de los casos.
- **SC-006**: Un proyecto consumidor con bootstrap desactualizado se auto-actualiza desde el maestro y re-ejecuta con los mismos argumentos (cuando hay red), en el 100% de los intentos.
- **SC-007**: El resumen final enumera el estado `enabled` de cada MCP y su razón, en el 100% de las corridas.

---

## Assumptions

- OpenCode soporta interpolación `{env:VARIABLE}` en los comandos MCP (verificado en docs).
- Las herramientas MCP (context-mode, codebase-memory-mcp, markitdown, graphify, tokenslayer) pueden resolverse vía `Get-Command` o están instaladas localmente.
- El proyecto tiene git disponible para self-update (si no, se salta con WARN).
- El kit maestro se reconoce por su `remote origin` igual a la URL del maestro.
- El sync transversal excluye `.opencode/config.json` por seguridad y deberá tratar `opencode.json` de forma que no pise lo resuelto.
