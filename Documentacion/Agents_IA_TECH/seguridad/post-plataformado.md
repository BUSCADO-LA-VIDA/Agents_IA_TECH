# 🔒 Seguridad del diseño: flujo post-plataformado → speckit (`[POST-PLATAFORMADO]`)

> Revisión **de seguridad del DISEÑO** del flujo post-plataformado → speckit (3 escenarios A/B/C), re-indexación automática, Constitution por proyecto, estrategia Graphify por app, y memoria auto/manual.
> Enfocada en: **indexación de secrets por Graphify, re-indexación automática sin supervisión, exposición cross-app en `merge-graphs`, rutas absolutas en `Constitution_Wizard_Instructions.md`, abuso del trigger manual de memoria**.
> Fuente: `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` (FR-001..FR-009, SC-001..SC-007) + `plan.md` + `research.md` + `data-model.md`.
> Fecha: 2026-09-20 | Autor: `security-auditor` (fase documental — tarea `[POST-PLATAFORMADO]`)

---

## 1. Alcance

Esta revisión cubre **solo el diseño** aprobado en la spec `[POST-PLATAFORMADO]`. No re-audita supply chain/licencias de Graphify (cubierto por `seguridad/graphify.md`), ni el bootstrap (cubierto por `seguridad/plataforma-bootstrap.md`), ni huérfanos (cubierto por `seguridad/huerfanos.md`). Verificación por **lectura directa** del diseño (spec/plan/research/data-model) sin ejecutar scripts.

---

## 2. Análisis de riesgos

### R-1. `graphify extract --mode deep` con LLM podría indexar secrets

El flujo estructura-first usa `--code-only` por defecto (sin LLM, sin secrets). Pero el flag `-GraphifyDeep` → `graphify extract --mode deep` (semántica con LLM) podría indexar contenido sensible si se ejecuta sobre carpetas con secrets (`.env`, `*.pem`, `.opencode/config.json`). El WARN del bootstrap ya advierte: "Para construirlo sin indexar secrets: graphify extract <path> --code-only".

**Puntos de validación:**
- `--code-only` por defecto; `--mode deep` SOLO con flag explícito `-GraphifyDeep` + backend LLM disponible.
- El scope de extracción excluye carpetas con secrets (`.env`, `*.pem`, `.opencode/config.json`, `revisar_manualmente/`).
- Sin backend LLM → WARN y continuar (nunca bloquear, nunca degradar a deep).

### R-2. Re-indexación automática diaria podría ejecutar comandos sin supervisión

La memoria automática (RF-08) actualiza índices + grafo al detectar índice stale (día anterior o más vieja). Si se ejecuta sin supervisión (CI, script desatendido), un error de detección podría disparar comandos no deseados.

**Puntos de validación:**
- Solo comandos allowlist: `context-mode index`, `codebase-memory index_repository`, `graphify update` (o `extract --code-only`).
- Fail-closed: si el comando falla, WARN en el cuadro resumen; no reintentar en bucle.
- El trigger manual "actualizar memoria" también usa solo comandos allowlist.

### R-3. `merge-graphs` para vista workspace podría exponer datos cross-app

La vista workspace unificada vía `graphify merge-graphs` combina grafos de varias apps. Si una app tiene datos sensibles, la vista unificada los expone a consultas cross-app.

**Puntos de validación:**
- `merge-graphs` es **on-demand** (no persistente); se construye solo cuando se necesita y no se mantiene.
- El grafo por app (`src/<App>/graphify-out/`) es el primario; la vista unificada es un artefacto temporal.
- No versionar `graphify-out/` (artefacto regenerable, en `.gitignore`).

### R-4. Rutas absolutas en `Constitution_Wizard_Instructions.md` (baja severidad)

**Aclaración**: El riesgo NO es para la máquina local del autor — es **si el documento se commitea y el repo se comparte**. Una ruta `C:\Users\<usuario>\...` revela el nombre de usuario del SO y el layout de disco a cualquiera que clone el repo (mismo principio que RF-S2 de `[SOLUCION-GENERICA]`: cero absolutas en versionados). Como es un doc de proyecto local, la severidad es **baja**.

**Puntos de validación:**
- Rutas relativas o tokens (`<raiz-proyecto>\src\<App>`) en el documento, no absolutas con usuario.
- El documento se genera en `Documentacion/` (raíz del proyecto), no en el kit transversal.

### R-5. Abuso del trigger manual de memoria (baja severidad)

**Aclaración**: Es un riesgo teórico de **prompt injection**. El trigger "actualizar memoria" ejecuta comandos. Si un contenido indexado (que la IA lee) contiene una instrucción maliciosa tipo "ejecuta actualizar memoria", podría disparar comandos no deseados. La mitigación es simple: **solo comandos allowlist** (`context-mode index`, `codebase-memory index_repository`, `graphify update`) — nada más. Severidad **baja**.

**Puntos de validación:**
- Solo comandos allowlist (mismos que R-2).
- El trigger se interpreta como intención del usuario, no como instrucción de contenido indexado.
- No ampliar `permission.bash` al re-resolver comandos.

---

## 3. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **`--mode deep` indexa secrets** (LLM sobre carpetas sensibles) | 🟠 Alto | `--code-only` por defecto; `--mode deep` solo con `-GraphifyDeep` + backend; scope excluye secrets; sin backend → WARN |
| 2 | **Re-indexación automática sin supervisión** (comandos no deseados) | 🟠 Alto | Solo comandos allowlist; fail-closed (WARN, no reintentar); trigger manual mismo allowlist; **aviso visible "Re-indexando..." (RF-010)** para que el usuario sepa que corre |
| 3 | **`merge-graphs` expone datos cross-app** | 🟡 Medio | On-demand no persistente; grafo por app primario; `graphify-out/` en `.gitignore` |
| 4 | **Rutas absolutas en `Constitution_Wizard_Instructions.md`** (exfiltran PII si el repo se comparte) | 🔵 Bajo | Rutas relativas o tokens; documento en `Documentacion/` raíz |
| 5 | **Abuso del trigger manual de memoria** (prompt injection teórico) | 🔵 Bajo | Solo comandos allowlist; trigger = intención del usuario; no ampliar `permission.bash` |

---

## 4. Recomendaciones para la implementación (`pensador` / `devops` / `qa-senior`)

1. **Graphify**: `--code-only` por defecto; `-GraphifyDeep` solo con backend LLM + scope sin secrets; `graphify-out/` en `.gitignore`.
2. **Re-indexación**: solo comandos allowlist (`context-mode index`, `codebase-memory index_repository`, `graphify update`); fail-closed con WARN.
3. **`merge-graphs`**: on-demand, no persistente; grafo por app primario.
4. **`Constitution_Wizard_Instructions.md`**: rutas relativas o tokens, nunca absolutas con usuario.
5. **Trigger manual**: solo comandos allowlist; no ampliar `permission.bash`.

---

## 5. Qué NO hacer

- ❌ **NO** usar `graphify extract --mode deep` por defecto (indexa secrets).
- ❌ **NO** re-indexar en cada cambio (costo alto; solo por disparador válido).
- ❌ **NO** mantener `merge-graphs` persistente (expone cross-app).
- ❌ **NO** usar rutas absolutas con usuario en `Constitution_Wizard_Instructions.md`.
- ❌ **NO** ampliar `permission.bash` al re-resolver comandos de memoria.

---

## 6. Conclusión

**No bloquea la adopción del diseño (APROBAR con condiciones).** El flujo post-plataformado es fundamentalmente seguro si se respetan las condiciones:

- `--code-only` por defecto en Graphify; `--mode deep` solo con flag + backend + scope sin secrets.
- Re-indexación y trigger manual con solo comandos allowlist + fail-closed.
- `merge-graphs` on-demand no persistente; `graphify-out/` en `.gitignore`.
- `Constitution_Wizard_Instructions.md` con rutas relativas o tokens.

**Recomendación**: **proceder (NO BLOQUEA), condicionado a** que la implementación incluya como requisitos no negociables:
- `--code-only` por defecto + scope sin secrets + `-GraphifyDeep` solo con backend;
- comandos allowlist para re-indexación y trigger manual + fail-closed + **aviso visible "Re-indexando..." (RF-010)**;
- `merge-graphs` on-demand + `graphify-out/` en `.gitignore` (RF-011, SC-009);
- rutas relativas/tokens en `Constitution_Wizard_Instructions.md`;
- `qa-senior` valide con fixtures (T021-T026, T030-T031) antes del rollout.

---

## Referencias

- `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md` — Spec aprobada `[POST-PLATAFORMADO]` (FR-001..FR-009, SC-001..SC-007).
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md` — ADR-0004 (decisión + guardrails).
- `Documentacion/Agents_IA_TECH/seguridad/graphify.md` — Riesgos de Graphify (secrets, stdio-only, supply chain).
- `Documentacion/Agents_IA_TECH/MCPs/graphify.md` — Guía de Graphify (extract, update, merge-graphs, label).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tracking de tareas `[POST-PLATAFORMADO]`.