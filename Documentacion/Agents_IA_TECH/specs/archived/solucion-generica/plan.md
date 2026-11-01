# Plan: Descontaminación del kit maestro (`solucion-generica`)

> **Fuente**: `spec.md` de esta carpeta (RF-S1..RF-S7, plan aprobado 2026-09-19).
> **Autor**: `documentador` (fase documental).

---

## Fase 1 — Documental (`documentador` ✅ esta entrega)

1. Spec `solucion-generica/spec.md` (objetivo + RF-S1..RF-S7 formalizados + 8 ACs + fuera de alcance + dependencias + referencias + decisiones).
2. `plan.md` (este archivo, 3 fases).
3. `tasks.md` (T-D / T-I por archivo / T-V).
4. Entrada `[SOLUCION-GENERICA]` en `pendientes-implementacion.md` con fase documental marcada.

## Fase 2 — Implementación (`devops`)

Orden sugerido por archivo de la lista cerrada (ver `tasks.md` T-I1..T-I8):

1. `scripts/plataformador-bootstrap.ps1` (L40 + L57 + L1993: RF-S2/S3/S4/S6).
2. `dependencias-manifest.yml` (RF-S5).
3. `opencode.json` (RF-S6: plantilla con tokens).
4. ADR-0003 + spec/tasks plataforma (ejemplos → `MiApp`/`AppFoo`, RF-S1/S2).
5. `README.md` (ejemplos + rutas → genéricas/relativas o tokens).
6. Definiciones de agentes `.github/` ↔ `.opencode/` (mismo barrido, en sync).
7. `pendientes-implementacion.md` (higiene de entradas viejas sin reescribir historial).

Reglas: solo los 8 artefactos; `Parser::ParseFile` 0 errores + JSON/YAML válidos; `-DryRun` sin escrituras donde aplique; anonimizar hallazgos modo-real a `AppXXX`.

## Fase 3 — Validación (`qa-senior`)

1. T-V1: grep dominio + absolutas → 0 fuera de exclusiones (RF-S1/S2).
2. T-V2: funcional `Prepare-Apps` (default `@()`, manifest, descubrimiento `src/*`, sin `$KnownApps`) + allowlist destructiva (RF-S3/S4).
3. T-V3: manifest sin apps activas + `opencode.json` plantilla + re-resolución bootstrap + test anti-regresión en QA/CI en ambos sentidos (RF-S5/S6/S7).

Reporte en `Documentacion/Agents_IA_TECH/testing/validacion-solucion-generica-<fecha>.md`. Cierre solo con 3 fases en PASS.
