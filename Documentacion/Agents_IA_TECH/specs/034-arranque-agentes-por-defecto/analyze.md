# Analyze 034 — Consistencia cross-artifact spec.md ↔ plan.md ↔ tasks.md + Constitución

## 1. Objetivo

Verificar que `spec.md`, `plan.md` y `tasks.md` de la spec `034-arranque-agentes-por-defecto` sean consistentes entre sí, con la Constitución del proyecto y con el estado real del repositorio tras la implementación. Se ejecuta con el artefacto ya construido, para que el análisis no valide una intención sino un hecho.

## 2. Metodología

1. **Extracción**: se listaron 19 FR, 7 NFR, 4 historias de usuario y 15 CA de `spec.md` (13 FR y 11 CA de la mitad local + FR-14..FR-19 y CA-12..CA-15 de la mitad de propagación).
2. **Mapeo a plan**: cada FR/CA se cruzó con una decisión o componente del `plan.md`.
3. **Mapeo a tasks**: cada FR/CA se cruzó con una tarea de `tasks.md`.
4. **Verificación en reposo**: se ejecutaron las verificaciones reales (validador, test de contrato, `git diff`, parseo de scripts) y se leyó el resultado en disco.
5. **Constitución Check**: se verificaron los artículos aplicables contra evidencia, no contra la declaración de la spec.
6. **Detección de vacíos**: se reporta todo FR/CA sin evidencia y toda tarea sin requisito de origen.

## 3. Matriz de trazabilidad FR → plan → tasks → evidencia

| FR | plan.md | tasks.md | Evidencia real | Estado |
|---|---|---|---|---|
| FR-01 `default_agent` = agente del kit | D1, D2 | T01 | `opencode.json` línea 5: `"default_agent": "pensador"` | ✅ Cumplido |
| FR-02 Agente del kit existe y es `mode: primary` | D1 | T01, T04 | `.opencode/agents/pensador.md` con `mode: primary`; VAL-10 en OK | ✅ Cumplido |
| FR-03 Fallo si falta / no-primary / `build` | D4 | T04, T05 | Fixture negativo detectado; VAL-10 con severidad FAIL | ✅ Cumplido |
| FR-04 Regla de arranque en `AGENTS.md` | D1, D3 | T02 | `AGENTS.md` L117 `## Arranque por defecto del arnés` + 5 viñetas normativas | ✅ Cumplido |
| FR-05 `copilot-instructions.md` enruta sin duplicar | D1 | T03 | Bloque "Arranque por defecto del arnés (spec 034)" de 4 viñetas; sigue remitiendo a `AGENTS.md` | ✅ Cumplido |
| FR-06 Regla equivalente en ambos arneses | D1, D4 | T04 | `tests/harness-default.ps1` verifica ambos archivos; exit 0 | ✅ Cumplido |
| FR-07 Bootstrap asegura `default_agent` | D2 | T06 | `Ensure-OpenCodeDefaultAgent` (+85 líneas); parseo OK | ✅ Cumplido |
| FR-08 Bootstrap respeta elección del usuario | D2 | T06 | Caso 3 probado: `arquitecto` no se pisa ("ya declara default_agent = 'arquitecto'; se conserva") | ✅ Cumplido |
| FR-09 Sin cambios en bloques `permission` | D3 | T01..T06 | `git diff --stat`: no hay cambios en frontmatter de agentes; única baja es `spec.md` huérfano | ✅ Cumplido |
| FR-10 `VAL-10` como FAIL en el validador | D4 | T05 | `VAL-10 - Arranque por defecto valido` en la salida del validador | ✅ Cumplido |
| FR-11 `tests/harness-default.ps1` con fixture negativo | D4 | T04 | Exit 0 real + fixture `build` detectado | ✅ Cumplido |
| FR-12 Retirar `.opencode/agents/pensador/spec.md` | D3 | T07 | El directorio `.opencode/agents/` lista 13 agentes, sin carpeta `pensador\` | ✅ Cumplido |
| FR-13 `README.md` documenta el arranque | D1 | T08 | Sección "🚀 Arranque por defecto del arnés" (+151 líneas) | ✅ Cumplido |
| FR-14 Merge por claves de `opencode.json` en el sync | D07, D08 | T15 | `Merge-OpenCodeConfig` en `scripts/sync-kit.ps1` (L512) gestiona `$schema`, `instructions` y `default_agent`; preserva `mcp`, `model`, `small_model`, `permission`, `lsp` | ✅ Cumplido |
| FR-15 Regla de `default_agent` en el sync | D09, §19.3 | T16 | Tabla de 5 estados en `Merge-OpenCodeConfig` (ausente/build/inexistente → corrige; kit+primary → preserva; `-Force` → sobrescribe); casos 3a-3e del test | ✅ Cumplido |
| FR-16 `AGENTS.md` por bloque delimitado | D08, §19.4 | T17 | `Merge-KitBlock` (L725) con casos A/B/C/D (reemplazar, migrar, agregar, fail-closed); escenarios 5, 6 y 7 del test | ✅ Cumplido |
| FR-17 Whitelist de tests del kit en el manifiesto | D08 | T18 | `$kitTestWhitelist` en `Sync-TransversalKit` (L1085) copia por nombre exacto 5 tests; nunca trata `tests/` como directorio transversal | ✅ Cumplido |
| FR-18 `.gitignore` cubre backups de sync y bootstrap | D07, T19 | T19 | `.gitignore` agrega `opencode.json.bak-*` y `AGENTS.md.bak-*` (bloque 034); cierra TM-04 | ✅ Cumplido |
| FR-19 `tests/kit-sync-merge.ps1` con fixtures temporales | D07-D09 | T20 | Test plano exit 0/1, 7 escenarios, `OK: 7 escenarios`, no escribe en el repo (verificado con `git status`) | ✅ Cumplido |

**Resultado FR: 19/19 cumplidos con evidencia verificable.**

## 4. Matriz de trazabilidad CA → verificación

| CA | Verificación ejecutada | Resultado |
|---|---|---|
| CA-01 | Lectura de `opencode.json` | ✅ `"default_agent": "pensador"` |
| CA-02 | Test de contrato sobre `.opencode/agents/pensador.md` | ✅ `mode: primary` presente |
| CA-03 | `tests/harness-default.ps1` | ✅ exit 0 |
| CA-04 | Fixture negativo con `build` | ✅ degradación detectada |
| CA-05 | `AGENTS.md` | ✅ sección presente en L117 |
| CA-06 | `.github/copilot-instructions.md` | ✅ remite a `AGENTS.md` y declara el arranque |
| CA-07 | `Ensure-OpenCodeDefaultAgent` con 6 casos aislados | ✅ corrige `build`, agrega si falta, respeta otro agente, WARN con JSON inválido, WARN sin archivo, `-DryRun` no escribe |
| CA-08 | `git diff --stat` | ✅ 0 cambios en `permission` o frontmatter de agentes |
| CA-09 | `scripts/validate-agents-skills.ps1` | ✅ `VAL-10` en OK; resumen `10 chequeos | OK: 9 | WARN: 1 | FAIL: 0` |
| CA-10 | Listado de `.opencode/agents/` | ✅ sin `pensador\spec.md` |
| CA-11 | `README.md` | ✅ sección de arranque con OpenCode, VS Code, monorepo y cambio de agente |
| CA-12 | `tests/kit-sync-merge.ps1` escenarios 2 y 3 | ✅ `opencode.json` divergente con 8 `mcp.servers` conservados y `default_agent: build → pensador`, sin `-Force` |
| CA-13 | `tests/kit-sync-merge.ps1` escenarios 5 y 6 | ✅ sección de arranque en `AGENTS.md` actualizada/envuelta preservando el resto del archivo |
| CA-14 | Manifesto `$kitTestWhitelist` + `git status` | ✅ whitelist de 5 tests en el sync; `tests/` no se trata como directorio transversal |
| CA-15 | `.gitignore` | ✅ `opencode.json.bak-*` y `AGENTS.md.bak-*` presentes (cierra TM-04) |

**Resultado CA: 15/15 verificados.**

## 5. Constitución Check

| Artículo | Requisito | Evidencia | Estado |
|---|---|---|---|
| Art. III — Test-First | Cada FR con verificación concreta; gate que bloquea el cierre | 19/19 FR con evidencia; `tests/harness-default.ps1` + `VAL-10` con severidad FAIL + `tests/kit-sync-merge.ps1` | PASS |
| Art. IV/VII — Simplicidad | Una clave de configuración y una regla; sin capa nueva | 1 línea en `opencode.json`, 1 sección en `AGENTS.md`, 0 agentes nuevos | PASS |
| Art. V — Seguridad | No se amplían permisos; default con el agente más restrictivo | `pensador` es el agente con `permission` más acotado; FR-09 verificado con `git diff` | PASS |
| Art. IX — Integration-First | Verificación contra el estado real, no contra supuestos | Validador ejecutado, test de contrato ejecutado, bootstrap validado por parseo y 6 casos aislados | PASS |
| Art. X — Kit sin `src/` | Dominio declarado por agente; sin asumir estructura de aplicación | Spec §5 declara dominio por agente; ninguna tarea toca `src/` | PASS |

**Resultado Constitución: 5/5 PASS.**

## 6. Detección de vacíos y contradicciones

| Área | Hallazgo | Severidad | Resolución |
|---|---|---|---|
| `Get-CanonicalTiers` (VAL-04) | La "Matriz de enrutamiento por tarea" agregada a `AGENTS.md` cumplía el patrón de tabla que el validador usaba para derivar tiers, y la lista canónica pasó de 5 a ~35 entradas: VAL-04 quedó casi vacuo **aun reportando `[OK]`** | Alta | Corregido: el parseo ahora se ancla en la cabecera `\| Tier \| Agents \|` y corta al salir de esa tabla. Verificado: VAL-04 vuelve a listar exactamente los 5 tiers, y el caso de prueba con tablas ajenas antes y después devuelve 5 |
| Regresión no cubierta por test automatizado | El fix de `Get-CanonicalTiers` no tiene un caso en `tests/validate-agents-skills.Tests.ps1` | Media | Se verificó manualmente con 5 casos (tabla real + tablas ajenas, sin cabecera, archivo inexistente, tabla de 2 filas, `AGENTS.md` real). Queda como deuda: incorporar el caso a la suite Pester |
| Ejecución del bootstrap completo | No se ejecutó `plataformador-bootstrap.ps1` completo sobre un proyecto real, solo `Ensure-OpenCodeDefaultAgent` aislada y validación de parseo | Media | Documentado en `converge.md` como limitación de verificación; la función se probó en 6 escenarios |
| Apariencia visual de `AGENTS.md` | La nueva sección no lleva separador `---` antes de `## Commands`; el separador quedó antes de la sección nueva | Baja | No afecta el render ni el parseo; se deja así para no ampliar el diff |
| Ejecución del test de contrato de propagación | `tests/kit-sync-merge.ps1` es un ejecutable del dominio del developer/QA; el `pensador` tiene `bash` denegado para `tests/*` | Media | La verificación de ejecución la lleva a cabo el developer/QA (a través de la sesión heredada), con salida literal registrada en `converge.md`; el pensador documenta el defecto B-01/B-02 y el diseño sin poder ejecutar la suite |

**Resultado vacíos: 1 hallazgo alto detectado y corregido en el mismo ciclo, 2 deudas de verificación registradas, 2 limitaciones documentadas.**

## 6bis. Longitudinal — mitad de propagación (T14-T20) y defecto B-01/B-02

La ampliación 034 (FR-14..FR-19, CA-12..CA-15, D-07..D-09, T14-T20, sección 19 de la spec) convierte el arranque por defecto en un comportamiento **propagable y reproducible** a través de `scripts/sync-kit.ps1`, en lugar de depender de una edición manual en cada proyecto. El diseño y las decisiones están en `spec.md` §19.3 (regla de `default_agent`), §19.4 (marcadores del bloque de `AGENTS.md`) y §19.5 (defecto B-01/B-02).

La verificación de esta mitad dejó dos hallazgos longitudinales:

### Defecto B-01 — llamada a función inexistente que abortaba el sync

Antes de esta ampliación, la rama de archivos de raíz de `Sync-TransversalKit` llamaba a `Compare-KitFileContent`, que **no se define** en `scripts/sync-kit.ps1` (solo vive en `scripts/sync-kit-lib.ps1`, spec 029, sin dot-source). Con `$ErrorActionPreference = "Stop"` (L44), cada llamada lanzaba `CommandNotFoundException`, el `try` externo la capturaba y el sync **abortaba en el primer archivo de raíz** sin propagar nada. Se corrigió reemplazando esa llamada por `Compare-KitFileState`, función local del propio script.

### Defecto B-02 — desalineamiento de contrato Equal/EolOnly vs true/false

Además, aunque se hubiera hecho el dot-source, el contrato no coincidía: el motor comparaba contra `'Equal'` / `'EolOnly'`, mientras que `Compare-KitFileContent` de la librería devuelve `$true` / `$false`. Toda comparación habría caído en la rama `else` → `[SKIP]` siempre, y el sync nunca habría escrito un archivo de raíz. El comparador local `Compare-KitFileState` devuelve exactamente `'Equal' | 'EolOnly' | 'Different'`, que es el contrato que el motor ya esperaba (L1066-1073). Ambos defectos se documentan en `spec.md` §19.5 y se fijan con los escenarios 1a-1d del test T20.

### Coherencia de la implementación verificada

- `[MERGE]` para `opencode.json` (L1056) y `AGENTS.md` (L1061) se resuelven **antes** de la regla SKIP y hacen `continue`, por lo que aplican con y sin `-Force`.
- El guard viejo de `$merged` (que estaba dentro de la rama `Copy-Item`) fue eliminado; no queda código muerto ni referencias a `Compare-KitFileContent`.
- Fail-closed: en `Merge-OpenCodeConfig` y `Merge-KitBlock`, si el local no parsea (JSON inválido / marcadores corruptos) no se escribe nada; si el resultado no valida, se restaura el backup.
- La whitelist de tests (L1085) copia por nombre exacto y nunca crea archivos vacíos.

**Estados en disco (verificados en esta iteración por el developer/QA):** `Compare-KitFileState` (L466), `Merge-OpenCodeConfig` (L512), `Merge-KitBlock` (L725), enganches `[MERGE]` (L1056/L1061), whitelist (L1085), `.gitignore` (+`opencode.json.bak-*` y `AGENTS.md.bak-*`), `tests/kit-sync-merge.ps1` (7 escenarios), `tests/harness-default.ps1` (existente).

## 7. Verificación de calidad del contenido

| Criterio | Resultado |
|---|---|
| Placeholders (TBD, TODO, N/A, XXX, `...`) | 0 en `spec.md`, `plan.md`, `tasks.md` |
| Secciones con solo título | 0 |
| Tablas con filas reales | Todas las tablas tienen datos verificables |
| Listas con items concretos | Todas |
| Afirmaciones sin evidencia | 0: cada FR/CA cita archivo y línea o salida de comando |

## 8. Dictamen

**PASS con deuda registrada.**

La spec 034 (mitad local + mitad de propagación) está implementada y verificada:

- 19/19 FR cumplidos con evidencia en disco (13 de la mitad local + FR-14..FR-19 de la propagación).
- 15/15 CA verificados (11 de la mitad local + CA-12..CA-15 de la propagación).
- 5/5 artículos de la Constitución en PASS.
- Gate en verde: `10 chequeos | OK: 9 | WARN: 1 | FAIL: 0`, exit 0; `tests/harness-default.ps1` exit 0 con fixture negativo operativo; `tests/kit-sync-merge.ps1` exit 0, `OK: 7 escenarios`.
- Defectos B-01/B-02 de la propagación detectados, corregidos con el comparador local `Compare-KitFileState` y fijados por test.
- Regresión de VAL-04 detectada durante el propio ciclo y corregida antes de cerrar.

**Deuda abierta**: (1) incorporar a `tests/validate-agents-skills.Tests.ps1` un caso que fije el comportamiento de `Get-CanonicalTiers` frente a tablas ajenas; (2) la verificación de ejecución de los tests de contrato de propagación (`kit-sync-merge.ps1`, `harness-default.ps1`) la corre el developer/QA, porque está fuera del dominio de ejecución del pensador.
