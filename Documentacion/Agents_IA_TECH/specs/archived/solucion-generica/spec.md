# Spec: Descontaminación del kit maestro — solución genérica (`solucion-generica`)

> **Estado**: Fase documental completada (2026-09-19)
> **Fuente**: Plan aprobado 2026-09-19 (descontaminación del kit maestro)
> **Autor**: `documentador` (fase documental)
> **Alcance de esta spec**: formalizar sin cambios los 7 RFs aprobados; el `devops` los implementa y el `qa-senior` los valida.

---

## Objetivo

Dejar el kit maestro **genérico y parametrizado**: cero nombres de dominio concreto y cero rutas absolutas en archivos versionados. Todo ejemplo usa nombres genéricos (`MiApp` / `AppFoo`) o tokens (`<tu-proyecto>`, `__NODE__`, etc.). La evidencia histórica se conserva; solo se descontamina el código vivo, plantillas y docs vigentes.

---

## Alcance exacto (lista cerrada del usuario)

Solo estos artefactos; nada fuera de esta lista:

1. `arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` (ADR-0003).
2. `specs/plataforma-bootstrap-instalador-unico/spec.md` + `tasks.md` (spec/tasks plataforma).
3. `pendientes-implementacion.md`.
4. `scripts/plataformador-bootstrap.ps1` — 3 puntos: línea ~L40, línea ~L57, línea ~L1993.
5. `dependencias-manifest.yml` (manifest del kit).
6. `README.md` (raíz).
7. Definiciones de agentes (`.github/agents/` ↔ `.opencode/agents/`).
8. `opencode.json` (MCP commands con rutas absolutas).

---

## Requisitos funcionales (NO cambiarlos, solo formalizar)

| ID | Requisito | Detalle |
|----|-----------|---------|
| **RF-S1** | **Cero dominio concreto fuera de historial** | Patrón de los nombres de dominio del proyecto (definido en el archivo de blocklist local no versionado `.opencode/local-domain-blocklist.txt`, gitignored) con cero matches en archivos versionados, **excepto** historial conservado: testing reports, notas de historial, evidencia de incidentes. Esas rutas/carpetas se conservan tal cual (ver Fuera de alcance). |
| **RF-S2** | **Cero rutas absolutas en versionados** | Patrón `C:\Proyectos\…`, `C:/Users/…` (ambas barras) con cero matches en archivos versionados. Sustituir por relativas al repo o tokens (`<tu-proyecto>`, `__NODE__`, etc.). |
| **RF-S3** | **`-Apps` default `@()` + descubrimiento** | `-Apps` por defecto `@()` (vacío explícito). Fuente de apps: explícito por flag, o manifest del proyecto, o descubrimiento `src/*`. Eliminar `$KnownApps` fijo y la lista fija en `Prepare-Apps`. |
| **RF-S4** | **Borrado/limpieza solo allowlist** | Borrado y limpieza solo sobre lo que se va a descargar/instalar (allowlist). Prohibido el patrón "todo lo que no es nuestro" (denylist abierta / borrado por exclusión). Fail-closed: lo no listado se conserva + aviso. |
| **RF-S5** | **Manifest sin apps concretas activas** | El manifest del kit no declara apps concretas activas. Define el formato + un ejemplo comentado. Cada proyecto define las suyas en su propio manifest/copia local. |
| **RF-S6** | **MCP commands como plantilla con tokens** | Entradas MCP con rutas absolutas en `opencode.json` pasan a plantilla con tokens + re-resolución al ejecutar el bootstrap (rutas reales solo en runtime local, jamás commiteadas). |
| **RF-S7** | **Test anti-regresión en QA/CI** | Test anti-regresión (grep de dominio + absolutas) en QA/CI que falla si reaparece cualquier patrón de RF-S1/RF-S2 en versionados fuera de las exclusiones de historial. |

---

## Criterios de aceptación

1. **AC-1 (RF-S1)**: grep del patrón de dominio (desde `.opencode/local-domain-blocklist.txt`) → 0 matches fuera de `testing/`, notas de historial y evidencia de incidentes (lista de exclusiones explícita en el test).
2. **AC-2 (RF-S2)**: grep de absolutas (`C:\Proyectos`, `C:/Users`, variantes con `/`) → 0 matches en versionados (`git ls-files` como universo); solo relativas o tokens.
3. **AC-3 (RF-S3)**: `Prepare-Apps` sin `$KnownApps` ni lista fija (`Select-String` 0 matches); `-Apps` default `@()`; con repo vacío no instala nada; con `src/MiApp` lo descubre.
4. **AC-4 (RF-S4)**: revisión por código — ninguna rutina destructiva opera por exclusión abierta; toda ruta borrada pertenece a la allowlist de descarga/instalación; caso fuera de allowlist → conservado + aviso (fixture).
5. **AC-5 (RF-S5)**: manifest del kit parsea válido, declara cero apps concretas activas y contiene formato + ejemplo comentado; un proyecto puede definir las suyas sin tocar el maestro.
6. **AC-6 (RF-S6)**: `opencode.json` versionado sin rutas absolutas (solo tokens/relativas); el bootstrap re-resuelve a rutas reales en ejecución local; `Parser`/JSON válido antes y después.
7. **AC-7 (RF-S7)**: test anti-regresión existe en QA/CI, PASS en limpio y FAIL provocado con fixture señuelo (un dominio + una absoluta) — verificado ambos sentidos.
8. **AC-8 (ejemplos)**: cero ejemplos con nombres de dominio en los 8 artefactos del alcance; solo `MiApp`/`AppFoo` o tokens; hallazgos modo-real anonimizados a `AppXXX`.

---

## Fuera de alcance

- **Reescribir historial: NO.** Testing reports, notas de historial y evidencia de incidentes se conservan tal cual (son exclusiones explícitas de RF-S1, no deuda).
- Reubicar apps a `src/` (cubierto por `[RELOCATE]`).
- Blindaje `.git` / matriz `.opencode` (cubierto por `[BLINDAJE-GIT]` / spec `kit-generico`).
- Huérfanos y respaldo `revisar_manualmente/` (cubierto por `[HUERFANOS]`).
- Auditoría supply-chain / licencias (rol de `security-auditor`).
- Nuevas features del bootstrap fuera de los 7 RFs.

---

## Dependencias

- `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-02/RF-05 frontera kit↔app; `Prepare-Apps`; `Sync-TransversalKit`).
- `specs/kit-generico/spec.md` (RF-B1..B4: allowlist + containment + fail-closed que RF-S4 reutiliza).
- `seguridad/plataforma-bootstrap.md` + `seguridad/kit-gaps.md` (condiciones que la implementación debe respetar).
- Tareas `[PLATAFORMA]`, `[RELOCATE]`, `[BLINDAJE-GIT]` en `pendientes-implementacion.md`.

---

## Referencias

- ADR-0003 (`arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md`).
- `scripts/plataformador-bootstrap.ps1` (puntos ~L40, ~L57, ~L1993).
- `dependencias-manifest.yml`, `README.md`, `opencode.json`, definiciones en `.github/agents/` y `.opencode/agents/`.

---

## Decisiones ya tomadas (registrar, no reabrir)

1. **Ejemplos genéricos `MiApp` / `AppFoo`**: todo ejemplo de app en código, docs y plantillas usa estos nombres; jamás un dominio concreto.
2. **Hallazgos modo-real se anonimizan a `AppXXX`**: los reportes de ejecuciones reales (conteos, locks, tamaños) se registran con `AppXXX`, sin el nombre real de la app del proyecto origen.
3. **Se conserva evidencia histórica**: testing reports, notas de historial y evidencia de incidentes quedan intactos y son exclusiones explícitas del grep anti-regresión (RF-S1/RF-S7).
