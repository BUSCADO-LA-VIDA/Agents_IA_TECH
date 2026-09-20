# Validación `[SOLUCION-GENERICA]` — T-V1..T-V3 (2026-09-19)

> **Rol**: `qa-senior` (solo valida y reporta; no modifica código de aplicación).
> **Alcance validado**: T-I1..T-I8 de `devops` (script sin defaults de dominio, allowlist sin
> `tomasecastro`/`tomasgraph`, manifest con ejemplo comentado, docs a `MiApp`/`AppFoo`,
> `opencode.json` con tokens, pendientes anonimizados).
> **Restricción de paths respetada**: solo se escribe en `testing/` + `pendientes-implementacion.md`.
> Bugs se REPORTAN, no se corrigen.

## T-V1 — Grep de dominio sobre trackeados (`git ls-files`, 246 archivos) — **PASS**

Patrón (case-sensitive, igual que RF-S1): los 5 nombres de dominio del proyecto (lista en `specs/solucion-generica/spec.md` RF-S1)
Comando: `git grep -n -E "<patrón-dominio-RF-S1>" -- .`
Total: 8 líneas en 4 archivos. Ninguna dentro de los 8 artefactos de la lista cerrada,
salvo la nota de historial del manifest (exclusión explícita).

| # | Ruta:línea | Veredicto |
|---|------------|-----------|
| 1 | `Documentacion/Agents_IA_TECH/testing/validacion-bootstrap-2026-09-18.md:27,36,39,45` (4 líneas) | ✅ ESPERADO — historial testing (exclusión explícita RF-S1/RF-S7) |
| 2 | `dependencias-manifest.yml:119` (comentario `# [2026-09-17] Registradas las 5 aplicaciones…`) | ✅ ESPERADO — nota de historial del manifest (exclusión explícita; historial conservado como comentario) |
| 3 | `scripts/relocate-apps-to-src.ps1:25,26,1533` (ejemplos `-AppDirs @("trading_bot", "Telegram")`) | ✅ ESPERADO — fuera de alcance reportado (otra tarea `[RELOCATE]` en curso) |
| 4 | `Documentacion/Agents_IA_TECH/seguridad/relocate.md:14` (typo `Telegram` vs `telegram`, `trading_bot` vs `trading-bot`) | ⚠️ NO-ESPERADO → **BUG-1** (menor, fuera de lista cerrada; va a siguiente ronda) |
| 5 | `.github/skills/docker/deployment-patterns/SKILL.md:64` (`Discord, Telegram, email`) | ⚠️ FALSO POSITIVO → **BUG-2** (info; `Telegram` como canal genérico, no dominio; ver Bugs) |
| 6 | `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` | ✅ 0 matches (anonimización verificada) |
| 7 | 8 artefactos lista cerrada (ADR-0003, spec/tasks plataforma `spec.md`+`tasks.md`, bootstrap, README raíz, `.github/agents/`, `.opencode/agents/`) | ✅ 0 matches |

## T-V2 — Genérico funcional (fixtures en `$env:TEMP`, limpiados) — **PASS**

- `Parser::ParseFile("scripts/plataformador-bootstrap.ps1")` → **0 errores** (solo lectura).
- `Select-String "KnownApps|<patrón-dominio-RF-S1>"` en bootstrap → **0 matches**.
- `-Apps` default `@()` verificado L40 + L1989; `Resolve-AppList` = manifest `aplicaciones:` → `src/*` → vacía + WARN (L63-81).
- **Caso A (vacío, sin manifest-apps ni `src/`)** → `-DryRun -ProjectRoot $empty`:
  `WARN "Sin apps en manifest ni en src/; lista vacía…"`, `WARN "Sin apps que preparar (lista vacía…). Nada que instalar."`,
  `INFO "DryRun: Prepare-Apps solo informa, no escribe nada."`; ficheros 0→0 (cero escrituras). ✅
- **Caso B (`src/MiApp/` + `.specify` base)** → `-DryRun`: `OK App 'MiApp' existe en: …\src\MiApp`,
  `DryRun: aseguraría Documentacion/MiApp/`, `DryRun: copiar …\.specify -> …\src\MiApp\.specify`,
  `OK Estructura src/<App>/ con .specify completada para: MiApp`; ficheros 4→4. ✅
- **Caso C (`-Apps @("AppFoo")` explícito)** → `WARN App 'AppFoo' no encontrada… (no se clona nada, RNF-06)`,
  `DryRun: crear directorio …\src\AppFoo`, `DryRun: copiar … -> …\src\AppFoo\.specify`,
  `DryRun: asegurar Documentacion/AppFoo/`, `OK … completada para: AppFoo`; ficheros 2→2. ✅
- Fixtures eliminados (`FIXTURES-CLEANED`). ✅

## T-V3 — Absolutas + anti-regresión — **PASS**

- **Absolutas en los 8 archivos** (`C:/Users/`, `C:\Proyectos\`, `C:/Proyectos/`, `Python314`):
  `git grep` sobre `README.md`, `opencode.json`, `dependencias-manifest.yml`,
  `adr-0003-….md`, `spec.md`+`tasks.md` plataforma, `pendientes-implementacion.md`,
  `plataformador-bootstrap.ps1`, `.github/agents/`, `.opencode/agents/`, `.doc_agents/` →
  **0 matches**. ✅
- `opencode.json` **válido** (`ConvertFrom-Json` OK); tokens presentes
  `__CONTEXT_MODE_CMD__` (L66), `__CODEBASE_MEMORY_CMD__` (L73), `__MARKITDOWN_CMD__` (L80);
  las 3 entradas con token en `enabled: false` degradado + `_note` RF-S6 (L62);
  `tokenslayer`/`graphify` a relativas (`node proyect_ext/…`, `python -m graphify.serve`);
  `permission.bash` intacto (sin ampliaciones). ✅
- `$TrustedOwners` (bootstrap L87-93) = `BUSCADO-LA-VIDA, github, microsoft, DeusData, mksglu`;
  `tomasecastro|tomasgraph` → **0 matches** en el script. ✅
- **Manifest**: cero apps concretas activas (sección `aplicaciones:` solo como EJEMPLO comentado
  L102-111 con `MiApp` + `# EJEMPLO por proyecto — NO activar en el kit`); `Read-DependenciasManifest`
  devuelve `@()` sin sección activa (caso A lo confirma en runtime). ✅
- **Anti-regresión ambos sentidos**: limpio → PASS (T-V1 0 + este T-V3 0);
  señuelo en `$env:TEMP` (`trading_bot`, `C:\Proyectos\X`, `C:/Users/tomas/y`) → ambos patrones
  hacen match (FAIL provocado), señuelo eliminado. Control positivo real: `plan.md` L36/L47
  (`C:\Proyectos\Metatrader`, `C:\Proyectos\Agents_IA_TECH`) sí matchean el patrón. ✅

## Bugs (REPORTADOS, no corregidos — restricción de paths `qa-senior`)

- **BUG-1 (menor, siguiente ronda `[RELOCATE]`-docs)**: `seguridad/relocate.md:14` usa nombres de
  dominio (`Telegram`, `trading_bot`) como ejemplo de typo. Archivo fuera de la lista cerrada de 8;
  higienizar a genéricos (`AppFoo`/`app-foo`) cuando se toque esa doc.
- **BUG-2 (info, patrón)**: `Telegram` como token del grep da falso positivo en
  `.github/skills/docker/deployment-patterns/SKILL.md:64` (canal de notificación genérico, no app
  de dominio). Considerar afinar el patrón (p. ej. exigir contexto app/ruta) o lista de exclusión
  para skills genéricas. No bloquea.
- **Fuera de alcance confirmados (no bugs, ya reportados o por diseño)**:
  `specs/plataforma-bootstrap-instalador-unico/plan.md:36,47` (absolutas `C:\Proyectos\…` —
  `plan.md` no está en la lista cerrada, que cubre solo `spec.md`+`tasks.md`);
  `README-ECOSISTEMA-DOCUMENTACION.md:225-227,237-247,259-281,312,331,334` (absolutas —
  fuera de la lista cerrada); `relocate-apps-to-src.ps1` ejemplos (otra tarea en curso);
  historial testing/notas manifest/evidencia (exclusiones explícitas RF-S1).

## Conclusión — **GO** ✅

**T-V1 PASS, T-V2 PASS, T-V3 PASS.** La descontaminación T-I1..T-I8 queda validada:
cero dominio y cero absolutas en los 8 artefactos (salvo historial excluido explícito),
bootstrap genérico funcional en los 3 fixtures DryRun con cero escrituras,
`opencode.json` plantilla con tokens + allowlist sin owners personales.
BUG-1/BUG-2 menores, no bloqueantes → siguiente ronda. Listo para commit.
