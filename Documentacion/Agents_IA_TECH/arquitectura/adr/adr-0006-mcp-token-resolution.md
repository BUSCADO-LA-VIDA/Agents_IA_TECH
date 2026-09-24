# ADR-0006: Resolución de tokens MCP + `.env.mcp` portable + upgrade de herramientas + self-update + activación en el kit maestro

> **Estado**: Aceptado
> **Fecha**: 2026-09-24
> **Decisión**: Adoptar la **Opción C (híbrida)**: versionar la plantilla `opencode.json` con tokens / `{env:...}` (sin rutas absolutas), resolver esos tokens en **runtime** de forma **incondicional** e **idempotente** en `Ensure-OpenCodeMcp`, introducir `<root>/.env.mcp` (gitignored) como fuente de verdad portable, y usar el campo `environment` del MCP local (o la ruta real) como mecanismo efectivo de fallback. Añadir `-ForceUpgradeTools` y `-SkipSync` (modo kit seguro), reforzar `Update-Self`, y no registrar entradas MCP rotas.
> **Autor**: `arquitecto` (Fase Analyze — parte arquitectónica de `speckit-analyze`)
> **Fuente del plan**: Spec aprobada `007-mcp-token-resolution` (`specs/007-mcp-token-resolution/spec.md`) + `plan.md` (D1-D7)

---

## Contexto y problema

El bootstrap `scripts/plataformador-bootstrap.ps1` promete (vía el `_note` de la plantilla `opencode.json`) que los tokens de los MCPs `__CONTEXT_MODE_CMD__`, `__CODEBASE_MEMORY_CMD__`, `__MARKITDOWN_CMD__` se re-resolverán a rutas locales en runtime. Esa promesa **no se cumple**. El bug real:

1. **Tokens sin resolver en la plantilla versionada**: `opencode.json` contiene los tokens `__*_CMD__` con `enabled: false`. Se decidió (correctamente) no versionar rutas absolutas de la PC, pero falta el paso de resolución en runtime.
2. **`Ensure-OpenCodeMcp` no re-resuelve** (L358-360): si `opencode.json` ya tiene sección `mcp` y no se pasa `-Force`, emite `Write-OK "se conserva"` y **no entra** al bloque de re-resolución (L395-414). La re-resolución solo ocurre cuando se **crea** el bloque, no cuando ya existe.
3. **`-Force` deja los tokens intactos**: sobrescribe `opencode.json` copiando la plantilla tal cual; el bloque recién copiado puede quedar inconsistente con el resto de la config.
4. **El sync sobrescribe lo resuelto**: `Sync-TransversalKit` (L1897) copia `opencode.json` del maestro al local, pisando las rutas resueltas con la plantilla de tokens, perpetuando el bug.
5. **Paradoja del kit maestro**: es el **único** proyecto donde el bootstrap nunca corre (ejecutarlo dispararía el sync que se sobrescribiría a sí mismo) → sus MCPs quedan `enabled: false` permanentemente y los agentes del kit no tienen acceso a context-mode, codebase-memory, markitdown, graphify ni tokenslayer.

**Tensión de diseño central**: se necesita una fuente de rutas **portable** (que no se versione y sobreviva al sync entre máquinas/proyectos) **sin** depender de un comportamiento de OpenCode que no está documentado como garantía. La doc oficial de OpenCode documenta `command: [...]`, `environment: { VAR: value }`, `enabled`, `cwd`, `timeout`, y la interpolación `{env:VAR}` desde el **entorno del proceso** — pero **no** documenta la carga automática de un archivo `.env` ad-hoc. Esto se confirmó en `research.md` (R-01, R-06).

**Principio rector**:
> *"La plantilla versionada no contiene rutas absolutas de la PC; las rutas se resuelven en runtime de forma determinista e idempotente, con `.env.mcp` como fuente de verdad portable y `environment`/ruta real como mecanismo efectivo — sin depender de comportamiento no documentado de OpenCode."*

---

## Decisión

Adoptar la **Opción C — híbrida**, estructurada en 7 decisiones de diseño (D1-D7), con la resolución de tokens **incondicional**, **idempotente** y **fail-open**.

### D1 — Re-resolución de tokens SIEMPRE (RF-01 / RF-02)

**Problema**: el bloque de re-resolución (L395-414) vive dentro del `if/else` de creación; con `mcp` existente y sin `-Force` no corre.

**Decisión**: extraerlo a una fase **incondicional** tras el `if/else` de creación, con guarda `if ($null -ne $existing.mcp)`. Parche **quirúrgico por entrada**:
- Disparar la resolución cuando `command[0]` sea token `__*_CMD__` **o** `{env:*}` sin valor efectivo **o** ruta vacía.
- Modificar únicamente `entry.command` y `entry.enabled`; preservar `type`, `environment`, `cwd`, `timeout` y cualquier otra clave (round-trip JSON).
- No tocar entradas `enabled: true` con ruta real ya válida (retrocompatibilidad).
- `DryRun`: informa sin escribir.

### D2 — `.env.mcp` por proyecto + fallback efectivo (RF-03, R-01)

**Decisión**:
- Nueva función `Ensure-McpEnvFile -RootPath [-DryRun] [-Force]`: resuelve `context-mode`, `codebase-memory-mcp`, `markitdown` vía `Resolve-McpCommand` y crea `<root>/.env.mcp` con `CONTEXT_MODE_CMD=`, `CODEBASE_MEMORY_CMD=`, `MARKITDOWN_CMD=`. Idempotente (si existe, se conserva; `-Force` re-escribe). Añade `.env.mcp` a `.gitignore` (append con guard anti-duplicado).
- `opencode.json` (plantilla) referencia `["{env:CONTEXT_MODE_CMD}"]` y análogos; sin rutas absolutas versionadas.
- **Fallback (clave de R-01)**: dado que OpenCode **no** carga `.env.mcp` automáticamente, el mecanismo efectivo es el campo `environment` del MCP local (`{"CONTEXT_MODE_CMD": "<ruta real>"}`) **o** la ruta real en `command`. `.env.mcp` es la **fuente de verdad portable/legible**; en ningún caso queda un token `__*_CMD__` ni un `{env:...}` irresoluble.

### D3 — `-ForceUpgradeTools` (RF-04)

Nuevo switch que reinstala/actualiza las herramientas externas (`context-mode`, `codebase-memory-mcp`, `markitdown`, `graphifyy[mcp]`) y construye tokenslayer, con **fail-open**: cada paso en `try/catch`, exit code ≠ 0 → WARN + continuar. Sin el flag, no se intenta nada. Solo paquetes conocidos/publicados; tokenslayer solo si el clon existe (no clona terceros).

### D4 — `Update-Self` reforzado (RF-05) — NO reimplementar

`Update-Self` **ya existe** (L1721-1799) y **ya se invoca** antes del paso 1 (L2681-2684): allowlist de URL, auto-skip en el kit por `origin == RepoUrl`, SHA256, re-ejecución con `@script:PSBoundParameters`. Decisión: **no reimplementar**; solo endurecer la limpieza del temp dir en todos los `return` y confirmar el contrato en `quickstart.md`.

### D5 — Modo kit seguro `-SkipSync` (RF-06)

Nuevo switch `-SkipSync` (alias lógico documentado `-KitMode`) que **salta** el paso 3 (`Sync-TransversalKit`) conservando el resto (D1, D2, D6, D7). Permite activar los MCPs en el kit maestro **sin** disparar el sync que se sobrescribiría a sí mismo. Complementado con: revertir la plantilla a `{env:...}`/tokens y crear `.env.mcp` local gitignored en el kit.

### D6 — graphify y tokenslayer ausentes (RF-07)

**NO registrar entradas rotas**; emitir WARN accionable:
- graphify: si `python -m graphify.serve --help` falla → WARN con `uv tool install "graphifyy[mcp]"` y no registrar (ya implementado en `Configure-Graphify` L2523-2530).
- tokenslayer: si falta `mcp-server/build/index.js` → WARN con instrucciones de clonado+build y no registrar (ya implementado L449-452), respetando el containment bajo `<root>/proyect_ext/tokenslayer/`.
- Homogeneizar el patrón fail-open y garantizar que ninguna entrada `enabled: false` quede sin causa.

### D7 — Verificación y reporte final (RF-08)

Al final de `Ensure-OpenCodeMcp`, imprimir el bloque `mcp` resultante (solo rutas locales, sin secretos) + por entrada: `name`, `enabled: true|false` y `reason` (`ruta resuelta`, `token sin resolver`, `herramienta ausente (comando de instalación)`, `{env} resuelto`). En `DryRun`, imprimir el bloque que **resultaría**. Integrar una línea de `.env.mcp` en `Show-ExecutionSummary`.

---

## Alternativas consideradas

| Opción | Descripción | Veredicto |
|--------|-------------|:---------:|
| **A — Rutas absolutas commiteadas** | Versionar `opencode.json` con las rutas reales de la PC en `command`. Funciona localmente sin runtime. | ❌ **Rechazada**: viola RNF-01 (no commitear rutas absolutas), rompe portabilidad entre máquinas/usuarios, y el sync propaga rutas de una máquina a otra. |
| **B — Solo tokens / `{env:...}`** | Versionar solo tokens y confiar en que OpenCode resuelva `{env:...}` desde `.env.mcp` (o el entorno). | ❌ **Rechazada**: OpenCode **no** documenta la carga automática de `.env.mcp`; `{env:VAR}` con variable no seteada → string vacío → MCP roto. Depende de comportamiento no garantizado (R-01/R-06). |
| **C — Híbrida (ELEGIDA)** | Plantilla con tokens/`{env:...}` + resolución runtime incondicional + `.env.mcp` como fuente de verdad portable + `environment`/ruta real como mecanismo efectivo. | ✅ **Adoptada**: cumple RF-03 y RNF-01 sin depender de comportamiento no documentado; retrocompatible; idempotente; portable. |
| D — Reescribir `Ensure-OpenCodeMcp` completa | Refactor total de la función. | ❌ Rechazada: mayor riesgo de regresión (R4) y diff grande, contra la Ponytail ladder. |
| E — Excluir `opencode.json` del sync | No copiarlo nunca en `Sync-TransversalKit`. | ⚠️ Parcial: rompe la propagación de la plantilla base. Se sustituye por `-SkipSync` en el kit + ajuste documentado del manejo del sync (dentro del Fuera de Alcance permitido "excluir/ajustar"). |

Criterio de elección: **portabilidad** (fuente versionada sin rutas), **seguridad** (RNF-01, containment), **determinismo** (idempotencia), **robustez** (no depender de comportamiento no documentado) y **simplicidad** (parche quirúrgico, sin nuevas dependencias).

---

## Consecuencias

### Positivas

- **Bug cerrado de raíz**: la re-resolución corre siempre → los MCPs quedan `enabled: true` con rutas válidas; ya no se conservan tokens sin resolver.
- **Portabilidad real**: la plantilla versionada no contiene rutas absolutas; `.env.mcp` es la fuente de verdad por proyecto y se resuelve en runtime en cada máquina.
- **Kit maestro operativo**: `-SkipSync` activa los MCPs del kit sin la auto-sobrescritura del sync.
- **Idempotencia**: correr el bootstrap N veces produce un bloque `mcp` estable (conserva `.env.mcp`, no duplica entradas).
- **Degradación observable**: ninguna entrada rota sin causa; WARN con comando exacto de instalación; reporte final por entrada.
- **Reuse-first**: se validan y refuerzan piezas existentes (`Update-Self`, `Configure-Graphify`, guards de tokenslayer) en lugar de reimplementarlas.
- **Seguridad preservada**: `.env.mcp` y `.opencode/config.json` gitignored; containment de tokenslayer; allowlist de URL en self-update intacta.

### Negativas / Trade-offs

- **Doble fuente de rutas** (`command` `{env:...}` + `environment`/ruta real): añade un contrato que debe documentarse (`quickstart.md`) para evitar confusión sobre cuál gana. Mitigado con precedencia explícita: `{env:...}` vacío se trata como no resuelto y se sustituye por la ruta efectiva.
- **`-ForceUpgradeTools` ejecuta instalaciones de terceros**: riesgo supply-chain (R2). Mitigado: solo paquetes conocidos/publicados, fail-open y **excluido por defecto**.
- **El sync sigue siendo un punto de fricción sobre `opencode.json`** (R3): se mitiga con `-SkipSync` en el kit y el ajuste documentado del manejo del sync; un rediseño completo del sync queda **fuera de alcance**.
- **Sin framework de tests**: la validación es por escenarios reproducibles T-01..T-11 (repo sin runtime), no por cobertura automatizada del 80%.
- **Acoplamiento al script único**: todo el cambio cae en `plataformador-bootstrap.ps1` (2840 líneas), que ya es grande; se mitiga con parches aditivos mínimos.

---

## Guardrails (restricciones que el código/agentes deben cumplir)

> Definidos por el `arquitecto` para la fase de implementación. Todo agente que implemente este ADR debe respetarlos.

1. **Parche por entrada, no reescritura del JSON**: la re-resolución modifica solo `command` y `enabled`; el resto de `opencode.json` se preserva byte-a-byte (round-trip `ConvertFrom-Json | ConvertTo-Json -Depth 10`). Evita el riesgo R4.
2. **Determinismo e idempotencia**: `.env.mcp` se conserva si existe (solo `-Force` lo re-escribe); la doble invocación de `Ensure-OpenCodeMcp` (pasos 1 y 4) produce el mismo bloque `mcp` (0 duplicados, 0 corrupción).
3. **Nunca `{env:...}` ni `__*_CMD__` persistidos sin resolver**: si la variable no está en el entorno del proceso del MCP, se usa la ruta real o el campo `environment`; un token sin resolver solo puede quedar con `enabled: false` **y causa explícita**.
4. **Plantilla versionada sin rutas absolutas**: `opencode.json` commiteado usa solo tokens/`{env:...}`. `.env.mcp` gitignored. Verificable con `git check-ignore .env.mcp` (exit 0).
5. **Fail-open en todo lo externo**: self-update, upgrade de herramientas y registro de MCPs degradan con WARN y **nunca** abortan el bootstrap (RNF-04, hereda ADR-0004 guardrail 8).
6. **Containment de tokenslayer**: rutas bajo `<root>/proyect_ext/tokenslayer/`, sin `..` ni rutas externas (RNF-07); containment-check intacto.
7. **Seguridad del self-update**: allowlist `Test-TrustedGithubUrl` intacta; auto-skip en el kit; `-SkipSelfUpdate` operativo.
8. **Sin `npm install` de terceros automático**: prohibido salvo `-ForceUpgradeTools` (excepción acotada a paquetes publicados conocidos); tokenslayer solo se **construye** si el clon existe, nunca se clona.
9. **`-SkipSync` no altera `Update-Self`**: el auto-skip del kit sigue operando por detección de `origin`.
10. **Observabilidad obligatoria**: toda entrada `enabled: false` lleva causa; el reporte final lista `name`/`enabled`/`reason` por entrada (Principio V).
11. **Frontera de responsabilidad**: el cambio toca SOLO `scripts/plataformador-bootstrap.ps1`, `opencode.json` y `.gitignore`. **Nunca** `.opencode/config.json`, ni `Documentacion/<AppName>/` de ninguna app, ni código de aplicación.
12. **Conventional commits**: `fix(bootstrap):`, `feat(bootstrap):`, `docs(bootstrap):` por grupo lógico (RNF-06).

---

## Spec linking (trazabilidad)

| Artefacto | Relación con este ADR |
|-----------|----------------------|
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/spec.md` | Spec aprobada de la que deriva este ADR (RF-01..RF-08, RNF-01..RNF-07, SC-001..SC-007). |
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/plan.md` | Plan (D1-D7, Technical Context, Constitution Check, T-01..T-11, riesgos R1-R7). |
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/research.md` | Decisiones R-01..R-06 (carga de `.env.mcp`, alcance del bug, sync, self-update, guards, interpolación). |
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/data-model.md` | Entidades E1-E6 (opencode.json, bloque mcp, `.env.mcp`, switches, `.gitignore`, reporte). |
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/tasks.md` | Tareas T001-T907 (US1-US8 + polish), con dependencias y MVP. |
| `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/analyze.md` | Análisis arquitectónico de consistencia del que este ADR es la versión formal. |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` | Define el bootstrap, `Sync-TransversalKit` y la frontera kit↔app; este ADR ajusta su manejo de `opencode.json` y añade flags. |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md` | El flujo post-plataformado depende de MCPs activos; este ADR garantiza su resolución (contexto fresco). |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0005-agent-ssd.md` | Gobernanza de tiers/permisos; este ADR no toca agentes (solo tooling/config). |
| `scripts/plataformador-bootstrap.ps1` | Script objetivo: `Ensure-OpenCodeMcp`, `Resolve-McpCommand`, `Update-Self`, `Sync-TransversalKit`, `Configure-Graphify`, `Show-ExecutionSummary`, `param()`. |
| `opencode.json` | Plantilla versionada → `{env:...}` + `_note`; resuelto localmente en runtime. |
| `.gitignore` | Agrega `.env.mcp` (sección secrets). |
| `dependencias-manifest.yml` | Manifest de herramientas externas (`tokenslayer-mcp-server`, `graphify`). |
| `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` | Diseño base del bootstrap. |
| `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` | Re-indexación y memoria (consumidor del estado MCP). |

---

## Diagrama Mermaid — Resolución de tokens MCP (runtime, incondicional, fail-open)

> Flujo: plantilla versionada (tokens/`{env}`) → resolución runtime incondicional → `.env.mcp` + fallback `environment`/ruta real → MCPs activos; degradación con WARN si la herramienta falta.

```mermaid
flowchart TD
    A[opencode.json plantilla versionada<br/>command: __*_CMD__ / {env:*}<br/>enabled: false] --> B[Ensure-McpEnvFile<br/>resolver context-mode / codebase-memory / markitdown]

    B --> B1{Existe .env.mcp?}
    B1 -->|No| B2[Crear .env.mcp<br/>CONTEXT_MODE_CMD / CODEBASE_MEMORY_CMD / MARKITDOWN_CMD<br/>+ agregar a .gitignore]
    B1 -->|Sí| B3[Conservar - idempotente]
    B2 --> C
    B3 --> C

    C[Ensure-OpenCodeMcp<br/>re-resolución INCONDICIONAL] --> D{command es token<br/>o {env} vacío?}
    D -->|No, ruta real válida| D1[No tocar - retrocompatible]
    D -->|Sí| E{Herramienta resuelta<br/>por Resolve-McpCommand?}

    E -->|Sí| F[command: {env:...} o ruta real<br/>environment: ruta efectiva<br/>enabled: true]
    E -->|No| G[enabled: false<br/>WARN con comando de instalación<br/>NO registrar entrada rota]

    F --> H[Persistir JSON<br/>parche quirúrgico por entrada]
    G --> H
    D1 --> H

    H --> I[Reporte final<br/>bloque mcp + enabled/razón por entrada]
    I --> J[D7 + Show-ExecutionSummary<br/>línea .env.mcp]

    B -.->|"OpenCode NO carga .env.mcp automáticamente"| K[Fallback efectivo:<br/>environment / ruta real en command]
    K -.-> F

    subgraph Kit maestro
        L[plataformador-bootstrap.ps1 -SkipSync] --> M[Salta Sync-TransversalKit]
        M --> N[MCPs enabled: true<br/>sin auto-sobrescritura]
    end
```

---

## Plan de implementación por fases

### Fase documental (siguiente paso: `documentador`)

| Orden | Agente | Acción |
|-------|--------|--------|
| 1º | `arquitecto` | ✅ **Este ADR** (Opción C, D1-D7, alternativas, guardrails, spec linking, diagrama) + `analyze.md`. |
| 2º | `documentador` | Documentar el contrato de carga de `.env.mcp` y el ciclo de re-ejecución de `Update-Self` en `quickstart.md`; actualizar `00-indice.md` / `memoria-proyecto.md` si aplica. |
| 3º | `security-auditor` | Revisar implicaciones de seguridad (`-ForceUpgradeTools` supply-chain, `.env.mcp` gitignored, allowlist de URL). |

### Fase implementación

| Orden | Agente | Acción |
|-------|--------|--------|
| 4º | `plataformador` | Aplicar D1-D7 en `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`, respetando los guardrails. |
| 5º | `qa-senior` | Ejecutar la matriz T-01..T-11 (idempotencia, retrocompatibilidad, `.env.mcp`, kit seguro, herramientas ausentes, reporte); validar `git check-ignore .env.mcp`. |
| 6º | `gitflow` | Commits convencionales (`fix(bootstrap):`, `feat(bootstrap):`). |

### Fase validación

| Orden | Acción |
|-------|--------|
| 7º | Correr el bootstrap en un proyecto consumidor con tokens → verificar 100% de MCPs instalados en `enabled: true`. |
| 8º | Correr 2 veces + 1 con `-Force` → bloques `mcp` idénticos (SC-002). |
| 9º | Correr `.\scripts\plataformador-bootstrap.ps1 -SkipSync` en el kit maestro → MCPs activos, `Sync-TransversalKit` no ejecutado (SC-004). |
| 10º | `npx ecc-agentshield scan` → sin hallazgos nuevos en los archivos tocados. |

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/spec.md` — Spec aprobada `[MCP-TOKEN-RESOLUTION]`.
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/plan.md` — Plan (D1-D7, riesgos R1-R7).
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/research.md` — Decisiones R-01..R-06.
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/data-model.md` — Entidades E1-E6.
- `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/analyze.md` — Análisis arquitectónico de consistencia.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — Bootstrap/instalador único + `Sync-TransversalKit`.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md` — Flujo post-plataformado (MCPs activos).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0005-agent-ssd.md` — Gobernanza de agentes/tiers.
- `scripts/plataformador-bootstrap.ps1` — Script objetivo.
- `opencode.json` — Plantilla versionada con `{env:...}`.
- `.gitignore` — Regla `.env.mcp`.
- `dependencias-manifest.yml` — Manifest de herramientas externas.
