# Analyze: 007-mcp-token-resolution — Análisis arquitectónico de consistencia

**Feature**: `007-mcp-token-resolution`
**Fecha**: 2026-09-24
**Autor**: `arquitecto` (parte arquitectónica de `speckit-analyze`)
**Alcance**: análisis spec ↔ plan ↔ tasks. **Sin modificaciones de código** (solo lectura). Este documento vive en `Documentacion/Agents_IA_TECH/specs/007-mcp-token-resolution/`.
**Artefactos analizados**: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`.

---

## 1. Cobertura de requisitos funcionales

Cada RF-01..RF-08 se mapea a decisiones de diseño (D1-D7) y a tareas ejecutables.

| RF | Decisión(es) | Tareas | Cobertura | Observación |
|----|--------------|--------|:---------:|-------------|
| RF-01 (re-resolución SIEMPRE) | D1 | T101, T102, T103, T104, T105, T106 | ✅ Completa | MVP; bloqueante. |
| RF-02 (idempotencia) | D1 | T201, T202, T203, T903 | ✅ Completa | Depende de RF-01. |
| RF-03 (`.env.mcp` por proyecto) | D2 | T301, T302, T303, T304, T305, T306, T307, T308 | ✅ Completa | Fallback R-01 cubierto por T305. |
| RF-04 (`-ForceUpgradeTools`) | D3 | T004, T401, T402, T403 | ✅ Completa | `param()` en T004 es prerequisito. |
| RF-05 (self-update) | D4 | T501, T502, T503 | ✅ Completa | Validación (no reimplementación) — correcto. |
| RF-06 (MCPs en kit maestro) | D5 | T004, T601, T602, T603, T604 | ✅ Completa | Depende de RF-03. |
| RF-07 (graphify/tokenslayer ausentes) | D6 | T701, T702, T703 | ✅ Completa | Mayormente validación de guards existentes. |
| RF-08 (reporte final) | D7 | T005, T801, T802, T803 | ✅ Completa | Depende de RF-01/RF-03. |

**Resultado**: 8/8 RF con cobertura de tareas. Ningún requisito funcional huérfano.

### Requisitos no funcionales

| RNF | Cubierto por | Estado |
|-----|--------------|:------:|
| RNF-01 (no commitear rutas absolutas) | T307, T902, T904 | ✅ |
| RNF-02 (retrocompatibilidad) | T105, T203, T903 | ✅ |
| RNF-03 (idempotencia) | T201, T302, T903 | ✅ |
| RNF-04 (fail-open) | T402, T502, T703 | ✅ |
| RNF-05 (sync entre arneses) | T906 | ✅ (probablemente N/A, justificado) |
| RNF-06 (conventional commits) | T907 | ✅ |
| RNF-07 (containment tokenslayer) | T702 | ✅ |

### Criterios de éxito (SC)

| SC | Cubierto por | Estado |
|----|--------------|:------:|
| SC-001 | T102-T105, T201 | ✅ |
| SC-002 | T201, T903 | ✅ |
| SC-003 | T303, T902 | ✅ |
| SC-004 | T601, T603 | ✅ |
| SC-005 | T701, T702, T703 | ✅ |
| SC-006 | T501, T503 | ✅ |
| SC-007 | T801, T803 | ✅ |

---

## 2. Consistencia de decisiones (D1-D7 ↔ RF)

| Decisión | Alineada con | Consistente con research | Veredicto |
|----------|--------------|:------------------------:|:---------:|
| D1 (re-resolución incondicional) | RF-01, RF-02 | R-02 | ✅ |
| D2 (`.env.mcp` + fallback) | RF-03 | R-01, R-06 | ✅ |
| D3 (`-ForceUpgradeTools`) | RF-04 | — | ✅ |
| D4 (self-update: validar) | RF-05 | R-04 | ✅ |
| D5 (`-SkipSync` kit seguro) | RF-06 | R-03 | ✅ |
| D6 (graphify/tokenslayer) | RF-07 | R-05 | ✅ |
| D7 (reporte final) | RF-08 | R-05 | ✅ |

**Hallazgo positivo**: el plan evita reimplementar lo que ya existe (D4 `Update-Self` L1721-1799, D6 `Configure-Graphify` L2523-2530, tokenslayer L449-452). Coherente con la Ponytail ladder (reuse antes de reescribir) y con la restricción anti-sobre-ingeniería.

---

## 3. Gaps, ambigüedades y contradicciones

### 3.1 Gap de secuencia — `Ensure-McpEnvFile` con `-Force` vs generación de `{env:...}` (MEDIO)

**Descripción**: T305 (fallback R-01) exige que, cuando la variable `{env:...}` no sea resoluble, se use `environment` o ruta real. Pero el `opencode.json` versionado (T307) usa `["{env:CONTEXT_MODE_CMD}"]`. El plan no fija **quién gana** si `.env.mcp` existe con valor vacío y `environment` tiene ruta real: el orden de precedencia `command` `{env}` (vacío → comando vacío) vs `environment` no está explícito.

**Recomendación**: en `Ensure-OpenCodeMcp`, la condición de re-resolución debe tratar el caso "`{env:...}` con variable vacía" como **no resuelta** y reemplazar por ruta real (no dejar el `{env:...}` vacío). T103 ya menciona "`{env:*}` sin valor efectivo"; **reforzar** que la sustitución por ruta real/`environment` es obligatoria cuando la var no está en el entorno del proceso. Documentar el contrato en `quickstart.md` (T905 ya lo prevé).

### 3.2 Ambigüedad — contradicción aparente spec vs plan sobre `enabled: true` en plantilla (BAJO)

**Descripción**: spec RF-06 dice que la "plantilla versionada NO contiene rutas absolutas (solo tokens / `{env:...}`)" y SC-004 dice que el kit queda con MCPs `enabled: true`. El plan (tabla `opencode.json` #2) dice "mantener `enabled: true` para las entradas resueltas (entorno local)". Pero la plantilla **versionada** es la misma que la del kit maestro; si el kit commitea `enabled: true` con `{env:...}`, la plantilla versionada tendría `enabled: true` sin rutas — lo cual es coherente (no hay ruta absoluta), pero **contradice** el estado inicial "tokens + `enabled: false`" descrito en spec L17 y en T304.

**Recomendación**: aclarar que:
- La **plantilla versionada** mantiene `enabled: false` (seguro por defecto, sin entorno).
- La **resolución local** (`.env.mcp` o ruta real vía D1) promueve a `enabled: true`.
- El kit maestro commitea la plantilla con `{env:...}` + `enabled: false` y su `.env.mcp` local (gitignored) lo habilita en runtime.

T304 ya fija plantilla `enabled=$false`; la tabla del plan #2 puede leerse como contradicción. **Alineación requerida**: dejar explícito que `enabled: true` en `opencode.json` versionado **no aplica** a la plantilla base, solo al `opencode.json` resuelto local del kit (que es el mismo archivo pero con el override runtime). El commit del kit no debe forzar `enabled: true` en la plantilla versionada.

### 3.3 Ambigüedad — doble invocación de `Ensure-OpenCodeMcp` (pasos 1 y 4) y orden con `Ensure-McpEnvFile` (MEDIO)

**Descripción**: T306 deja "paso 1 y/o paso 4" sin fijar. Si `.env.mcp` debe existir **antes** de que `Ensure-OpenCodeMcp` resuelva `{env:...}`, el orden importa (R7 del plan lo reconoce parcialmente). Con la doble invocación (L2713 y L2735), una primera corrida sin `.env.mcp` resuelve `{env:...}` → vacío → ruta real; la segunda corrida con `.env.mcp` ya creado podría resolver distinto. Esto es una **fuente potencial de no-idempotencia** (choca con RF-02/SC-002).

**Recomendación**: fijar `Ensure-McpEnvFile` **incondicionalmente antes** del primer `Ensure-OpenCodeMcp` (paso 1), y que la segunda invocación (paso 4) sea no-op sobre `mcp` ya resuelto (T105 la protege). Preferir resolución determinista: si la var está en `.env.mcp` **y** en el entorno, el resultado debe ser el mismo bloque; si no está en el entorno, ruta real fija (no `{env}` vacío). Añadir a T203 la comparación de bloques entre paso 1 y paso 4.

### 3.4 Ambigüedad — alcance del revert `4a13718` (BAJO)

**Descripción**: T602 dice revertir `4a13718` "coordinado con T307 para no duplicar". T003 ya delimita el revert a la plantilla `opencode.json`. Riesgo de doble aplicación del mismo cambio (revert + edición manual) generando conflicto de commit.

**Recomendación**: definir una **única** ruta de ejecución: o `git revert 4a13718` (si el commit es aislado) **o** la edición de T307; no ambas. Registrar en `research.md` el contenido del commit para decidir. Si el commit mezcla otros archivos, usar `git checkout 4a13718^ -- opencode.json` (revert selectivo) y documentar.

### 3.5 Ambigüedad — `Sync-TransversalKit` sobre `opencode.json` (MEDIO)

**Descripción**: R3 del plan y T604 dicen "documentar (sin rediseñar)" que el sync no pise `opencode.json` resuelto. Pero la spec (Fuera de Alcance L129) dice "Rediseñar el sync transversal más allá de **excluir/ajustar** el manejo de `opencode.json`". Hay tensión: T604 solo documenta; si el sync efectivamente sobrescribe (R-03 confirmado), documentar **no elimina** el bug en consumo normal (no-kit) donde el sync corre.

**Recomendación**: elevar T604 de "documentar" a **"ajustar el guard"**: si `Sync-TransversalKit` copia `opencode.json`, debe preservar el bloque `mcp` resuelto localmente (merge, no overwrite) o excluir `opencode.json` del copiado cuando ya exista local. Esto está **dentro** del Fuera de Alcance permitido ("excluir/ajustar"). Sin este ajuste, RF-06 se cumple solo en el kit (vía `-SkipSync`) pero el bug persiste en consumidores que corren el sync. **Gap real de cobertura de RF-06 en consumidores**.

### 3.6 Observación — `_note` y documentación de la fuente de verdad (BAJO)

T308 actualiza `_note`. El plan no exige que `_note` diferencie plantilla vs resuelto. Consistente con el resto; sin acción bloqueante, pero conviene que `_note` describa el contrato `.env.mcp` + fallback (T905).

---

## 4. Guardrails arquitectónicos (Clean Architecture, simplicidad, anti-abstracción)

### 4.1 Fronteras de capas y responsabilidad

- **Tooling de plataforma aislado**: todo el cambio cae en `scripts/plataformador-bootstrap.ps1` (capa de plataforma) + `opencode.json`/`.gitignore` (config). **No** toca agentes, skills, ni `Documentacion/<AppName>/`. ✅ Respeta las fronteras del kit y la Regla de containment documental.
- **No se crean agentes**: coherente con Constitution Check (Plan §Constitution Check, Principio I). ✅
- **Frontera kit ↔ app**: `-SkipSync` preserva `Documentacion/<AppName>/` (nunca tocada) y evita la auto-sobrescritura del kit. ✅ Hereda ADR-0003 guardrail 1.

### 4.2 Simplicidad y anti-abstracción (Ponytail ladder)

- **Reuse sobre rewrite**: D4/D6 validan código existente (`Update-Self`, `Configure-Graphify`, guards tokenslayer) en lugar de reimplementar. ✅ Correcto.
- **Parche quirúrgico por entrada** (T104): modifica solo `command`/`enabled`, preserva el resto. Minimiza el diff y evita el riesgo R4 (corrupción JSON). ✅
- **Sin nuevas dependencias**: 7 parches aditivos sobre 1 script. ✅
- **Función nueva mínima**: `Ensure-McpEnvFile` es la única función nueva; su contrato (`-RootPath`, `-DryRun`, `-Force`) sigue el patrón de las existentes. ✅
- **Riesgo de sobre-abstracción**: ninguno detectado. La tentación de hacer un "resolutor genérico de tokens" no aparece; el plan se limita a los 3-5 MCPs conocidos. ✅

### 4.3 Guardrails específicos que el implementador DEBE respetar

1. **Parche por entrada, no reescritura del JSON completo**: round-trip `ConvertFrom-Json | ConvertTo-Json -Depth 10` preservando claves ajenas (T104). Evita R4.
2. **Determinismo e idempotencia**: `Ensure-McpEnvFile` conserva el archivo si existe (T302); re-resolución produce el mismo bloque en corridas N y N+1 (T201/T203). Obligatorio dado el modelo de doble invocación.
3. **Fail-open en todo lo externo**: upgrades (T402), self-update (T502), registro de MCPs (T703) → WARN, nunca abortar. Hereda RNF-04 y ADR-0004 guardrail 8.
4. **Seguridad de rutas**: containment de tokenslayer bajo `<root>/proyect_ext/tokenslayer/` sin `..` (T702/RNF-07); allowlist de URL en self-update intacta (T904/R-04).
5. **Fuente versionada sin rutas absolutas**: plantilla solo con `{env:...}`/tokens (T307/T902/RNF-01). `.env.mcp` gitignored (T303/T904).
6. **No ejecutar `npm install` de terceros salvo `-ForceUpgradeTools`**: excepción explícita acotada a paquetes publicados conocidos (Plan Constraints L54, D3).
7. **Trazabilidad**: cada entrada `enabled: false` con causa (T801/T703/E6). Refuerza el Principio V (Observabilidad).
8. **Conventional commits** por grupo lógico (T907/RNF-06), sin tocar `.opencode/config.json`.

### 4.4 Alineación con Principios de la Constitution

| Principio | Evaluación arquitectónica |
|-----------|---------------------------|
| I. Modular Agent Design | ✅ No se crean/modifican agentes. |
| II. Orchestrator Pattern | ✅ No altera orquestación. |
| III. Specification-Driven | ✅ Spec 007 precede; plan deriva de ella. |
| IV. Copilot/Opencode Compatibility | ✅ Mantiene paridad de patrón `.opencode`/`opencode.json` ↔ `.vscode/mcp.json`. |
| V. Observability | ✅ D7 + `$script:Warnings`/`Errors` + razón por entrada. |
| VI. proyect_ext / Dependencias | ✅ Containment intacto. |
| Quality Gate 80% | ⚠️ Justificado (repo sin runtime de tests) — sustituido por matriz T-01..T-11 determinista. |

---

## 5. Veredicto de consistencia

**CONSISTENTE CON OBSERVACIONES** (apto para implementar con ajustes previos).

- **Cobertura**: 8/8 RF, 7/7 RNF, 7/7 SC con tareas trazadas. D1↔D7 alineadas con RF. ✅
- **Sin violaciones arquitectónicas**: parche quirúrgico, reuse-first, fail-open, containment, sin abstracción innecesaria. ✅
- **Sin contradicciones bloqueantes**: las detectadas son de redacción/orden y se resuelven ajustando plan/tasks (no la spec).

### Ajustes recomendados antes de implementar (por prioridad)

| # | Ajuste | Severidad | Tarea afectada |
|---|--------|:---------:|----------------|
| A1 | Elevar T604 de "documentar" a "ajustar guard" del sync sobre `opencode.json` (merge/exclusión) para cerrar RF-06 en consumidores, no solo en el kit. | **MEDIO-ALTO** | T604 |
| A2 | Fijar el orden: `Ensure-McpEnvFile` incondicional **antes** del primer `Ensure-OpenCodeMcp`; prohibir `{env:...}` vacío persistido (usar ruta real/`environment`). | **MEDIO** | T301, T306, T305, T203 |
| A3 | Resolver la aparente contradicción `enabled: true` en plantilla versionada: plantilla `enabled: false`; el kit commitea plantilla y usa `.env.mcp` local para `enabled: true` runtime. | BAJO | Plan tabla `opencode.json`, T307/T603 |
| A4 | Definir ruta única para el revert `4a13718` (revert selectivo **o** edición T307, no ambas). | BAJO | T602, T003 |
| A5 | Reforzar T103: `{env:...}` con var vacía cuenta como **no resuelto** → sustitución obligatoria por ruta real/`environment`. | BAJO | T103, T305 |

Ningún ajuste requiere reescribir la spec; se resuelven en `plan.md`/`tasks.md` (endurecimiento) antes o durante la Fase 3.

---

## 6. Referencias

- `spec.md` — fuente de los RF-01..RF-08, RNF, SC.
- `plan.md` — D1-D7, Technical Context, estrategia de pruebas T-01..T-11, riesgos R1-R7.
- `tasks.md` — T001-T907, fases por user story, dependencias.
- `research.md` — R-01..R-06 (resolución de incógnitas).
- `data-model.md` — E1-E6 (entidades de configuración).
- `../arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — bootstrap/fronteras kit↔app.
- `../arquitectura/adr/adr-0004-post-plataformado-speckit.md` — memória/re-indexación (consumidor del estado MCP).
- `../arquitectura/adr/adr-0005-agent-ssd.md` — gobernanza de tiers y permisos.
- `../arquitectura/adr/adr-0006-mcp-token-resolution.md` — ADR derivado de este análisis.
