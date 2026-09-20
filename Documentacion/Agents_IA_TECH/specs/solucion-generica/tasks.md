# Tasks: Descontaminación del kit maestro (`solucion-generica`)

> **Fuente**: `spec.md` de esta carpeta (RF-S1..RF-S7, plan aprobado 2026-09-19).
> **Roles**: T-D = `documentador` ✅ esta entrega; T-I = `devops`; T-V = `qa-senior`.

---

## Documentales (T-D)

- [x] **T-D1** — Spec `solucion-generica/spec.md` (objetivo + RF-S1..RF-S7 formalizados + 8 ACs + fuera de alcance + dependencias + referencias + decisiones `MiApp`/`AppFoo`, `AppXXX`, historial conservado). ✅ 2026-09-19.
- [x] **T-D2** — `plan.md` (3 fases) + `tasks.md` (este archivo, T-D/T-I/T-V). ✅ 2026-09-19.
- [x] **T-D3** — Entrada `[SOLUCION-GENERICA]` en `pendientes-implementacion.md` con fase documental marcada. ✅ 2026-09-19.

## Implementación (T-I, `devops` — uno por archivo de la lista cerrada)

- [ ] **T-I1 (bootstrap L40/L57/L1993)** — `scripts/plataformador-bootstrap.ps1`: RF-S2 (absolutas → relativas/tokens), RF-S3 (default `@()`, sin `$KnownApps`/lista fija en `Prepare-Apps`, manifest o `src/*`), RF-S4 (destructivas solo allowlist de descarga/instalación), RF-S6 (lo que aplique a comandos generados). `Parser::ParseFile` 0 errores.
- [ ] **T-I2 (manifest)** — `dependencias-manifest.yml` (RF-S5): sin apps concretas activas; formato + ejemplo comentado; cada proyecto define las suyas.
- [ ] **T-I3 (`opencode.json`)** — RF-S6: rutas absolutas → plantilla con tokens + re-resolución al ejecutar el bootstrap; JSON válido.
- [ ] **T-I4 (ADR-0003)** — `arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md`: RF-S1 (cero dominio fuera de historial) + RF-S2 (cero absolutas) + ejemplos a `MiApp`/`AppFoo`.
- [ ] **T-I5 (spec/tasks plataforma)** — `specs/plataforma-bootstrap-instalador-unico/spec.md` + `tasks.md`: mismo barrido RF-S1/S2; historial citado, no reescrito.
- [ ] **T-I6 (README)** — `README.md`: ejemplos y rutas a genéricas/relativas o tokens (RF-S1/S2); sin apps concretas como propias del kit.
- [ ] **T-I7 (agentes)** — `.github/agents/` ↔ `.opencode/agents/`: mismo barrido RF-S1/S2 en sync (ambos harnesses idénticos en lo tocado).
- [ ] **T-I8 (pendientes)** — `pendientes-implementacion.md`: higiene RF-S1/S2 en entradas vigentes; historial y evidencia intactos.

## Validación (T-V, `qa-senior`)

- [ ] **T-V1 (RF-S1/S2)** — Grep dominio + absolutas sobre `git ls-files`: 0 matches fuera de exclusiones (testing reports, notas de historial, evidencia de incidentes listadas explícito).
- [ ] **T-V2 (RF-S3/S4)** — `Prepare-Apps`: default `@()` + fuente explícita/manifest/`src/*` + 0 matches `$KnownApps`/lista fija; destructiva con fixture fuera de allowlist → conservado + aviso.
- [ ] **T-V3 (RF-S5/S6/S7)** — Manifest sin apps activas + ejemplo comentado; `opencode.json` sin absolutas + re-resolución verificada; test anti-regresión en QA/CI PASS en limpio y FAIL provocado con señuelo (ambos sentidos).
