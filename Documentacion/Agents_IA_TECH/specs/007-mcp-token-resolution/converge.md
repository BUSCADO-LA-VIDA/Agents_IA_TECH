# Converge: 007-mcp-token-resolution — Estado de convergencia documental

**Feature**: `007-mcp-token-resolution` (MCP-TOKEN-RESOLUTION)
**Fecha**: 2026-09-24
**Autor**: `documentador` (fase `speckit-converge`)
**Alcance**: consolidación documental de la feature. **Sin modificaciones de código** — la implementación corresponde a la fase 3 (`plataformador`).
**Ámbito**: ESTE proyecto (el kit). La documentación es **genérica para cualquier proyecto consumidor**; no referencia, nombra ni documenta ningún otro proyecto.

---

## 1. Resumen ejecutivo

La feature 007 está **documentalmente completa y apta para implementar**. El flujo SSD recorrió `specify → plan → tasks → analyze` (arquitecto + security-auditor) y esta fase `converge` (documentador). Los 5 ajustes del análisis arquitectónico (`analyze.md` §5) se aplicaron en `plan.md` y `tasks.md` (NO en `spec.md`, que permanece como fuente aprobada de requisitos).

- **Cobertura**: 8/8 RF, 7/7 RNF, 7/7 SC con tareas trazadas.
- **Ajustes A1-A5**: aplicados (dos requieren **código nuevo** en la implementación; ver §4).
- **Tareas de implementación**: 46 tareas en `tasks.md` (T001-T907), todas pendientes.
- **Veredicto**: **GO a fase Implement**, respetando los guardrails del ADR-0006.

---

## 2. Qué está documentado vs qué falta

### 2.1 Documentado (fase documental COMPLETA)

| Artefacto | Estado | Contenido |
|-----------|:------:|-----------|
| `spec.md` | ✅ | Problema (5 puntos), objetivos, RF-01..RF-08, RNF-01..RNF-07, SC-001..SC-007, fuera de alcance, dependencias. **Fuente aprobada — NO se modifica.** |
| `plan.md` | ✅ | D1-D7, Technical Context, Constitution Check (9/9), anclajes verificados, decisiones de diseño, cambios por archivo, T-01..T-11, riesgos R1-R7. **Ajustado por A1-A5.** |
| `research.md` | ✅ | R-01..R-06 (carga `.env.mcp`, alcance del bug, sync, self-update, guards, interpolación `{env}`). |
| `data-model.md` | ✅ | Entidades E1-E6 (`opencode.json`, bloque `mcp`, `.env.mcp`, switches, `.gitignore`, fila de reporte). |
| `tasks.md` | ✅ | 46 tareas T001-T907, 8 user stories (RF-01..RF-08), fases, dependencias, MVP, estrategia. **Ajustado por A1-A5.** |
| `analyze.md` | ✅ | Análisis arquitectónico de consistencia (8/8 RF, guardrails, ajustes A1-A5). |
| `quickstart.md` | 🟡 **PENDIENTE (T905)** | Guía de validación T-01..T-11 + contrato de carga `.env.mcp` + ciclo de re-ejecución `Update-Self`. Se produce **durante la implementación** (T905), no antes. |
| `adr-0006-mcp-token-resolution.md` | ✅ | ADR formal: Opción C híbrida, D1-D7, alternativas, 12 guardrails, spec linking, diagrama Mermaid, plan por fases. |
| `seguridad/007-mcp-token-resolution-threat-model.md` | ✅ | Threat model STRIDE, 8 `security-risk:`, 11 controles no negociables (CN-1..CN-11), checklist de cierre. |
| `00-indice.md` | ✅ | Entrada de la feature 007 agregada (spec/plan/tasks/analyze/converge + ADR-0006 + threat model). |
| `pendientes-implementacion.md` | ✅ | Tareas de la feature 007 registradas como pendientes. |

### 2.2 Falta (fase de IMPLEMENTACIÓN — no documental)

Todo el código. La feature es **single-file** y de tooling:

| Archivo | Cambio pendiente | Decisión |
|---------|------------------|----------|
| `scripts/plataformador-bootstrap.ps1` | 12 zonas (ver `plan.md` §Cambios por archivo) + A1 (guard del sync) + A2 (orden `Ensure-McpEnvFile` vs `Ensure-OpenCodeMcp`) | D1-D7 + A1-A5 |
| `opencode.json` | Plantilla → `{env:...}` sin rutas absolutas; `enabled` según A3 | D1, D2, A3 |
| `.gitignore` | Regla `.env.mcp` | D2 |

> **Nota**: `quickstart.md` (T905) es un artefacto documental que se produce **tarde** en la fase de implementación, cuando ya existen los escenarios ejecutables. Se marca como pendiente de implementación, no como gap documental.

---

## 3. Tareas pendientes de implementación (46)

Todas las tareas de `tasks.md` están pendientes (`[ ]`). La columna **Ajuste** indica si la tarea cubre uno de los 5 ajustes A1-A5 del `analyze.md` §5.

### Phase 1 — Setup (T001-T003)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T001 | Verificar líneas de anclaje del script | — |
| T002 | Confirmar estado de plantilla `opencode.json` + `.gitignore` | — |
| T003 | Confirmar commit a revertir `4a13718` | **A4** |

### Phase 2 — Foundational (T004-T005)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T004 | Switches `-ForceUpgradeTools` + `-SkipSync` en `param()` | — |
| T005 | Canal de razones por entrada MCP (D7) | — |

### Phase 3 — US1 · Re-resolución SIEMPRE (T101-T107) 🎯 MVP

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T101 | Neutralizar early "se conserva" (L358-360) | — |
| T102 | Extraer re-resolución a bloque incondicional (L395-414) | — |
| T103 | Condición: token `__*_CMD__` **o** `{env:*}` vacío **o** ruta vacía | **A5** |
| T104 | Parche quirúrgico por entrada (`command`/`enabled`) | — |
| T105 | No tocar `enabled: true` con ruta real (retrocompat) | — |
| T106 | `DryRun` informa sin escribir | — |
| T107 | Validar parseo del script (`Parser::ParseFile`) | — |

### Phase 4 — US2 · Idempotencia (T201-T203)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T201 | Idempotencia bloque `mcp` (2 corridas = 1) | — |
| T202 | `-Force` no deja `__*_CMD__` | — |
| T203 | Doble invocación (L2713/L2735) sin doble escritura; **comparar bloques paso 1 vs paso 4** | **A2** |

### Phase 5 — US3 · `.env.mcp` por proyecto (T301-T308) 🎯 MVP extendido

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T301 | `Ensure-McpEnvFile -RootPath [-DryRun] [-Force]` | **A2** |
| T302 | Idempotencia de `.env.mcp` | — |
| T303 | `.env.mcp` a `.gitignore` (append con guard) | — |
| T304 | Plantilla `$mcpConfig` → `{env:...}` | **A3** |
| T305 | Fallback R-01: `environment`/ruta real efectiva | **A5** |
| T306 | Invocar `Ensure-McpEnvFile` **incondicional ANTES** del paso 1 | **A2** |
| T307 | `opencode.json` versionado → `["{env:...}"]` sin absolutas | **A3** |
| T308 | Documentar `.env.mcp` en `_note` | — |

### Phase 6 — US4 · `-ForceUpgradeTools` (T401-T403)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T401 | Gate `-ForceUpgradeTools` en MAIN paso 2 | — |
| T402 | `try/catch` fail-open por herramienta | — |
| T403 | Reportar OK/WARN por herramienta | — |

### Phase 7 — US5 · Self-update (T501-T503)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T501 | Validar contrato de `Update-Self` (no reimplementar) | — |
| T502 | Endurecer limpieza temp en todos los `return` | — |
| T503 | Confirmar `DryRun`/`-SkipSelfUpdate` intactos | — |

### Phase 8 — US6 · Kit maestro (T601-T604)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T601 | Gate `-SkipSync` en MAIN paso 3 | — |
| T602 | Revertir `4a13718` (**ruta ÚNICA elegida**) | **A4** |
| T603 | `.env.mcp` local kit + MCPs activos (plantilla `enabled: false`) | **A3** |
| T604 | **AJUSTAR guard** del sync sobre `opencode.json` (merge/exclusión) — no solo documentar | **A1** |

### Phase 9 — US7 · graphify/tokenslayer ausentes (T701-T703)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T701 | Validar guard `Configure-Graphify` | — |
| T702 | Validar guard tokenslayer + containment | — |
| T703 | Homogeneizar fail-open; sin entradas rotas sin causa | — |

### Phase 10 — US8 · Reporte final (T801-T803)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T801 | Reporte final bloque `mcp` + `enabled`/razón | — |
| T802 | `DryRun` muestra bloque resultante | — |
| T803 | `Show-ExecutionSummary` con línea `.env.mcp` | — |

### Phase 11 — Polish (T901-T907)

| ID | Descripción breve | Ajuste |
|----|-------------------|:------:|
| T901 | Matriz completa T-01..T-11 | — |
| T902 | `git check-ignore .env.mcp` + sin absolutas | — |
| T903 | Idempotencia final end-to-end | — |
| T904 | Cierre de seguridad (`npx ecc-agentshield scan`) | — |
| T905 | `quickstart.md` (contrato `.env.mcp` + ciclo `Update-Self`) | — |
| T906 | Paridad `.github/` ↔ `.opencode/` (probable N/A) | — |
| T907 | Conventional commits | — |

**Total**: 3 + 2 + 7 + 3 + 8 + 3 + 3 + 4 + 3 + 3 + 7 = **46 tareas**.

### Cobertura de los ajustes A1-A5

| Ajuste | Severidad | Tareas que lo cubren | Requiere código nuevo |
|--------|:---------:|----------------------|:---------------------:|
| A1 (guard del sync sobre `opencode.json`) | MEDIO-ALTO | T604 | ✅ Sí |
| A2 (orden `Ensure-McpEnvFile`) | MEDIO | T301, T306, T203 | ✅ Sí |
| A3 (plantilla `enabled: false` + runtime `true`) | BAJO | T304, T307, T603 | ❌ Aclaración/alineación |
| A4 (ruta única de revert `4a13718`) | BAJO | T003, T602 | ❌ Decisión (revert selectivo) |
| A5 (`{env}` vacío = no resuelto) | BAJO | T103, T305 | ✅ Sí (refuerzo de condición) |

---

## 4. Los 5 ajustes del análisis aplicados

Los ajustes provienen de `analyze.md` §5. Se aplicaron **en `plan.md` y `tasks.md`** (endurecimiento), **sin tocar `spec.md`**.

### A1 (MEDIO-ALTO) — El sync SÍ sobrescribe `opencode.json`: ajustar el guard

**Hallazgo (verificado)**: `Sync-TransversalKit` copia `opencode.json` del maestro al local mediante `$transversalItems` (L1897, `Type = "File"`, copia plana). En consumidores (donde el sync SÍ corre), esto pisa el bloque `mcp` resuelto en runtime, perpetuando el bug. Documentar no lo elimina.

**Aplicado**:
- `plan.md` §D5: T604 elevado de "documentar" a **"ajustar el guard"**: el sync debe **preservar el bloque `mcp` resuelto localmente** (merge selectivo del bloque `mcp` desde el `opencode.json` local antes del overwrite) **o** **excluir `opencode.json` del overwrite** cuando ya exista local. Está dentro del "Fuera de Alcance permitido" de la spec ("excluir/ajustar el manejo de `opencode.json`").
- `tasks.md` T604: reescrita — el criterio done pasa de "comportamiento documentado en comentario" a "**el sync no pisa el bloque `mcp` resuelto; merge/exclusión implementado y verificado en consumidor**".
- `plan.md` §Riesgos R3: mitigación actualizada (ya no solo `-SkipSync` + documentación).

### A2 (MEDIO) — Fijar orden: `Ensure-McpEnvFile` incondicional ANTES del primer `Ensure-OpenCodeMcp`

**Hallazgo (verificado)**: `Ensure-OpenCodeMcp` se invoca **dos veces** (L2713 paso 1 y L2735 paso 4). Sin fijar el orden, `.env.mcp` puede no existir en la primera resolución → `{env:...}` vacío → resultado distinto entre pasos → rompe idempotencia (RF-02/SC-002).

**Aplicado**:
- `plan.md` §D2 y §"Cambios por archivo" (fila 8): `Ensure-McpEnvFile` se invoca **incondicionalmente antes** del paso 1 (`Ensure-OpenCodeMcp` L2713); el paso 4 es no-op sobre `mcp` ya resuelto.
- `tasks.md` T306: criterio fijado — `Ensure-McpEnvFile` corre **antes** de `Ensure-OpenCodeMcp` (orden determinista).
- `tasks.md` T203: se agrega la **comparación del bloque `mcp` entre paso 1 y paso 4** como criterio de idempotencia.

### A3 (BAJO) — Aclarar `enabled: false` en plantilla versionada, `true` en runtime

**Hallazgo**: aparente contradicción entre "plantilla versionada con `enabled: false`" y "kit con MCPs `enabled: true`".

**Aplicado**:
- `plan.md` §"Cambios por archivo" (`opencode.json`): aclarado que la **plantilla versionada** queda `enabled: false` (seguro por defecto, sin entorno), y que la **resolución local en runtime** (vía `.env.mcp`/ruta real de D1) la promueve a `enabled: true`. El `opencode.json` del kit commitea la plantilla (`enabled: false`) + su `.env.mcp` local (gitignored) que la habilita en runtime.
- `tasks.md` T307: aclarado que `enable: true` en la plantilla **NO aplica** al archivo versionado; T603 aclara que el kit activa por runtime, no forzando `enabled: true` en el commit.

### A4 (BAJO) — Fijar UNA sola ruta de revert del commit `4a13718`

**Hallazgo (verificado)**: `4a13718` está **aislado a `opencode.json`** (1 archivo, 8 insert / 7 delete). Elegir revert **o** edición, no ambas.

**Aplicado (decisión)**:
- `plan.md` §D5 y `tasks.md` T602: ruta **ÚNICA elegida = `git revert 4a13718`** (revert selectivo, ya que el commit es aislado). **NO** se ejecuta además la edición de T307 sobre el mismo contenido — T307 describe el estado objetivo y queda **subsumida** por el revert (si el revert no resultara limpio por cambios posteriores, el fallback documentado es `git checkout 4a13718^ -- opencode.json`, no la edición manual).
- `tasks.md` T003: criterio done fija el alcance del revert (verificado aislado).

### A5 (BAJO) — `{env:...}` con var vacía cuenta como NO resuelto

**Hallazgo**: `{env:VAR}` sin setear → string vacío → comando vacío → MCP roto silencioso.

**Aplicado**:
- `tasks.md` T103: la condición de re-resolución trata **`{env:*}` con variable vacía como NO resuelto** → dispara la sustitución.
- `tasks.md` T305: la sustitución por **ruta real/`environment` es obligatoria** cuando la var no está en el entorno del proceso del MCP; nunca queda un `{env:...}` irresoluble persistido.
- Alineado con el guardrail 3 del ADR-0006 y CN-3 del threat model.

---

## 5. Trazabilidad RF ↔ D ↔ T

| RF | Decisión(es) | Tareas | Ajuste asociado | SC |
|----|--------------|--------|:---------------:|:--:|
| RF-01 (re-resolución SIEMPRE) | D1 | T101-T107 | A5 | SC-001 |
| RF-02 (idempotencia) | D1 | T201-T203, T903 | A2 | SC-002 |
| RF-03 (`.env.mcp`) | D2 | T301-T308 | A2, A3, A5 | SC-003 |
| RF-04 (`-ForceUpgradeTools`) | D3 | T004, T401-T403 | — | — |
| RF-05 (self-update) | D4 | T501-T503 | — | SC-006 |
| RF-06 (kit maestro + sync) | D5 | T004, T601-T604 | **A1**, A3, A4 | SC-004 |
| RF-07 (graphify/tokenslayer ausentes) | D6 | T701-T703 | — | SC-005 |
| RF-08 (reporte final) | D7 | T005, T801-T803 | — | SC-007 |

**RNF**: RNF-01→T307/T902/T904 · RNF-02→T105/T203/T903 · RNF-03→T201/T302/T903 · RNF-04→T402/T502/T703 · RNF-05→T906 · RNF-06→T907 · RNF-07→T702.
**Controles de seguridad**: CN-1..CN-11 (threat model §7) ↔ guardrails 1-12 (ADR-0006) ↔ T902/T904/T702.

---

## 6. Guardrails de implementación (heredados del ADR-0006)

El implementador DEBE respetar: parche quirúrgico por entrada (no reescritura JSON); determinismo/idempotencia (`.env.mcp` conservado; 2 corridas = 1); nunca `{env}` ni `__*_CMD__` persistidos sin resolver; plantilla versionada sin rutas absolutas; fail-open en todo lo externo; containment de tokenslayer; allowlist de self-update intacta; sin `npm install` de terceros salvo `-ForceUpgradeTools`; `-SkipSync` no altera `Update-Self`; observabilidad obligatoria (`enabled: false` siempre con causa); frontera de responsabilidad (solo `scripts/plataformador-bootstrap.ps1`, `opencode.json`, `.gitignore`); conventional commits.

---

## 7. Orden de implementación (MVP incremental)

1. **Fase 1 Setup + Fase 2 Foundational** → base lista (T001-T005).
2. **US1 + US3** → **MVP**: re-resolución + `.env.mcp` (T101-T107, T301-T308). Validar T-02/T-03/T-04.
   → **STOP and VALIDATE**: proyecto consumidor con tokens queda con MCPs `enabled: true`. El bug queda cerrado.
3. **US2** → idempotencia probada.
4. **US4 + US5** → upgrades + self-update.
5. **US6** → kit maestro activado (con A1 en el guard del sync).
6. **US7 + US8** → degradación + reporte.
7. **Polish** → matriz completa + seguridad + commits.

---

## 8. Siguiente fase

**Implement** (`speckit-implement`), bajo responsabilidad del `plataformador` (tooling de plataforma), con `qa-senior` para la matriz T-01..T-11 y `gitflow` para los conventional commits. No hay bloqueos documentales; los 5 ajustes quedaron aplicados en `plan.md`/`tasks.md`.

---

## 9. Referencias

- `spec.md` — RF-01..RF-08, RNF, SC (fuente aprobada, no modificada).
- `plan.md` — D1-D7 + ajustes A1-A5.
- `tasks.md` — 46 tareas T001-T907 + ajustes A1-A5.
- `analyze.md` — análisis de consistencia + §5 (ajustes A1-A5).
- `research.md` — R-01..R-06.
- `data-model.md` — E1-E6.
- `../arquitectura/adr/adr-0006-mcp-token-resolution.md` — ADR (Opción C, guardrails, spec linking).
- `../seguridad/007-mcp-token-resolution-threat-model.md` — STRIDE + CN-1..CN-11.
- `../00-indice.md` — índice del proyecto.
- `../pendientes-implementacion.md` — puente docs ↔ implementación.
