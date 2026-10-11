# ECC — Ciclo de vida: actualización, rollback y corrección de errores (013 T010/T011)

**Alcance**: `scripts/ecc-sync.ps1` (`install`/`update`/`validate`/`uninstall`/`update-indexes`) + `scripts/ecc-orchestrator.ps1` (puerta de invocación con whitelist y modo real aprobado).
**Estado runtime**: `.ecc-state.json` (gitignored, regenerable). Clon externo: `proyect_ext/ECC/` (gitignored, regenerable).

## Proceso de actualización (T010)

1. **Validar baseline**: `.\scripts\ecc-sync.ps1 -Action validate` — informa `Rules/Skills/mcp-configs presentes` y termina exit 0 (si no hay estado, avisa `ECC no instalado` y también termina 0).
2. **Actualizar**: `.\scripts\ecc-sync.ps1 -Action update` — exige clon presente; hace `git fetch origin` + `git reset --hard origin/main` dentro de `proyect_ext/ECC`, registra `lastToolUpdate` en el estado y pide `update-indexes` después.
3. **Re-indexar**: `.\scripts\ecc-sync.ps1 -Action update-indexes` — re-indexa context-mode + codebase-memory-mcp + graphify y registra `lastIndexUpdate`.
4. **Modo orquestado**: toda invocación productiva pasa por `.\scripts\ecc-orchestrator.ps1 -action <tarea> [-mcp <nombre>]`; el modo real (`--run` documentado) requiere aprobación del pensador y deja marca en `proyect_ext/ECC/.ecc-levanta`. El dry-run (`-action status -dryrun`) nunca escribe y termina exit 0 (evidencia: `reports/ecc-test-dryrun.md`).

## Rollback probado (T009 — ejecutado 2026-10-09)

Secuencia verificada en vivo sobre el KIT, toda con exit 0:

| Paso | Comando | Resultado observado |
|---|---|---|
| 1. Baseline | `ecc-sync.ps1 -Action validate` | `WARN ECC no instalado` (sin estado), exit 0 |
| 2. Desinstalar | `ecc-sync.ps1 -Action uninstall` | `ECC desinstalado`; `proyect_ext/ECC` eliminado del FS |
| 3. Reinstalar | `ecc-sync.ps1 -Action install` | Clon `https://github.com/affaan-m/ECC.git` completo (`main`, limpio) + `.ecc-state.json` con `installed/version/path` |
| 4. Validar | `ecc-sync.ps1 -Action validate` | `Rules/Skills/mcp-configs: True/True/True`, `Validación completada` |

Conclusión: desinstalar + reinstalar es un rollback completo y seguro (el clon es regenerable desde el remoto; el estado se reconstruye). No se pierde nada propio: el KIT no versiona ni el clon ni el estado.

## Corrección de errores (T011)

| Síntoma | Causa | Corrección |
|---|---|---|
| `WARN ECC no instalado` en `validate` | Falta `.ecc-state.json` (nunca se corrió `install`, o se corrió `uninstall`) | `ecc-sync.ps1 -Action install` |
| `ERROR ECC no instalado` en `update`/`update-indexes` (exit 1) | Sin clon o sin estado | `install` primero; luego `update` |
| `slave-missing` en el orquestador (exit 2) | Falta `scripts/ecc-sync.ps1` | Re-sincronizar kit (`sync-kit.ps1 -Force`); el script es transversal |
| `slave-exit:<code>` en modo real | El esclavo falló | Leer el log del esclavo, corregir, reintentar con aprobación |
| ` Query: detail=inactive` en `status` | Sin marca `.ecc-levanta` (nunca hubo corrida real) | Normal en dry-run; no es error |
| Invocación `--dry-run` / sin `-action` | Sintaxis vieja: el parámetro es `-dryrun` y `-action` es obligatorio | `ecc-orchestrator.ps1 -action status -dryrun` (así está en `ci/ecc-pipeline.yml`) |
