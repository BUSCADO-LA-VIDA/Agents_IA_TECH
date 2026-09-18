# Validación huérfanos (RF-12 / criterio 8) — `qa-senior` (T-V6, tarea `[HUERFANOS]`)

- **Fecha**: 2026-09-18
- **Agente**: `qa-senior` (validación formal independiente; no corrige, solo reporta)
- **Alcance**: spec `specs/plataforma-bootstrap-instalador-unico/spec.md` (RF-12 + criterio nº 8) y checklist §5 de `seguridad/huerfanos.md`
- **Implementación validada**: `Find-OrphanKitFiles` (L834-880), `Show-OrphanList` (L884-903), `Remove-OrphanFiles` (L908-947), `Move-OrphanFilesToBackup` (L955-1037), `Invoke-OrphanDecision` (L1045-1182) en `scripts/plataformador-bootstrap.ps1`; integración en `Sync-TransversalKit` (L1326-1327) + flag CLI `-OrphanAction` (default `Preguntar`, L42); `revisar_manualmente/` en `.gitignore` (L21-22)
- **Restricción cumplida**: cero ejecuciones en modo real sobre el repo (solo `-DryRun`); huérfanos reales solo en fixtures bajo `$env:TEMP` (`qa-t-v6/`, `qa-t-v6-backup/`, `qa-t-v6-del/`), limpiados después (verificado `Test-Path=False`); escrituras solo en este reporte + `pendientes-implementacion.md`
- **Entorno**: pwsh 7.6.6, `Parser::ParseFile` del bootstrap = **0 errores**

## 1. DryRun del bootstrap completo — PASS

- Comando: `scripts/plataformador-bootstrap.ps1 -DryRun -NoRestart -SkipInstall -SkipIndexing` → **EXIT 0**
- `git status --porcelain` **idéntico antes/después** (6 modificados + 1 untracked preexistentes: `.gitignore`, `pendientes-implementacion.md`, `spec.md`, `tasks.md`, `README.md`, `plataformador-bootstrap.ps1`, `?? seguridad/huerfanos.md`)
- `Test-Path revisar_manualmente/` = **False** (no se crea)
- Salida menciona detección simulada: `DryRun: detectaría huérfanos (local en .github/ .opencode/ .doc_agents/ no existentes en el maestro) y aplicaría -OrphanAction Preguntar (…; default seguro Conservar; sin borrar ni mover nada)`

## 2. DryRun de `sync-agents.ps1 -DryRun` (wrapper, default `Preguntar`) — PASS

- **EXIT 0**; delega en `Sync-TransversalKit` (`-SyncOnly`); misma lista de 8 transversales + `excluiría .opencode/config.json` + `NUNCA tocaría Documentacion/<AppName>/` + línea de huérfanos con `-OrphanAction Preguntar`
- `git status` idéntico; `revisar_manualmente/` no creada

## 3. Detección correcta (fixtures en `$env:TEMP`, funciones reales cargadas por AST sin ejecutar el MAIN) — PASS

- Maestro simulado: `.github/keep.md`, `.opencode/keep2.md`, `.doc_agents/keep3.md`. Local: keeps + `.github/orphan-only.md` + `.github/sub/nested-orphan.md` + `.opencode/real-orphan.md` + trampas (`.opencode/config.json` solo-local, `Documentacion/Agents_IA_TECH/should-not-touch.md`, `src/evil.md`)
- `Find-OrphanKitFiles` devolvió **exactamente** `.github/orphan-only.md | .github/sub/nested-orphan.md | .opencode/real-orphan.md` (3/3, sin diff) → archivo solo-local ✓, subcarpeta ✓, `config.json` excluido ✓, nada fuera de los 3 dirs ✓
- Maestro incompleto (falta `.opencode`) → **throw** `clon maestro incompleto… Se aborta la fase de huérfanos` ✓; `TempDir` inexistente → **throw** ✓
- Guardas `-DryRun` por ejecución: con `$script:DryRun=$true`, `Remove-OrphanFiles` y `Move-OrphanFilesToBackup` devuelven vacío con `WARN … -DryRun activo, no se borra/mueve nada (fail-closed)` y el fixture intacto ✓; `Invoke-OrphanDecision -OrphanAction Preguntar` en DryRun solo informa (`se PREGUNTARÍA [B]/[C]/[U]/[O]… default seguro: Conservar`) sin crear respaldo ✓

## 4. Estructura de respaldo preservada (modo real SOBRE FIXTURES, luego limpios) — PASS

- `Move-OrphanFilesToBackup` con `.github/a.md`, `.doc_agents/sub/b.md`, `.opencode/c.md` → destino `revisar_manualmente\20260918-091013\` (**sufijo de hora** porque la carpeta del día se pre-creó) con **estructura original preservada** y **contenidos intactos** (`NEW-B`, `NEW-C` verificados byte a byte); originales eliminados del fixture ✓
- Nunca sobrescribir: `OLD-A` preexistente en `revisar_manualmente\<día>\.github\a.md` **intacto**; `NEW-A` quedó en la carpeta con sufijo ✓ (variante `_02` mismo-destino verificada por código L1017-1028)
- Suplemento: `Remove-OrphanFiles` real borra solo el objetivo, deja el resto, rechaza `../escape.md` (`[RECHAZADO] … no se toca`), y loguea `[BORRADO] .github/bye.md (9 bytes, 2026-09-18 09:10, sha256:BBD2D1A211CB…)` ✓; `Move` con lista vacía no crea carpetas ✓

## 5. `.gitignore` — PASS

- `git check-ignore -v revisar_manualmente/` → `.gitignore:22:revisar_manualmente/` ✓; también cubre archivos anidados (`revisar_manualmente/nuevo-archivo.md` matchea L22) ✓

## 6. Checklist de seguridad (`seguridad/huerfanos.md` §5, 18 ítems) — 17 PASS + 1 PARCIAL

| # | Ítem | Veredicto + evidencia |
|---|------|----------------------|
| 1 | Default Conservar | PASS — L1100 (no interactivo→Conservar), L1110/L1148/L1150-1155 (sin confirmación→Conservar) |
| 2 | Lista visible (relativa, tamaño, fecha, motivo) | PASS — `Show-OrphanList` L890-902; observado en T3e (`- .github/orphan-only.md (9 bytes, 2026-09-18 09:10)`) |
| 3 | Decisión por archivo + omitir | PASS por código — L1119-1128 (`[B]/[C]/[O]` por archivo), L1139-1141 (omitir todo); interactivo no ejecutable en harness |
| 4 | Confirmación explícita Borrar interactivo | PASS por código — doble confirmación lote L1106-1110, por-archivo L1129-1138, `-OrphanAction Borrar` interactivo L1144-1148 |
| 5 | Borrar no interactivo exige `-Force` | PASS por código — L1149-1153 (sin `-Force` degrada a Conservar con WARN) |
| 6 | Log de lo borrado (ruta, hash, fecha, tamaño) | PASS — L944 + L1169; observado `[BORRADO] … sha256:BBD2D1A211CB…` |
| 7 | Maestro fallido/vacío → abortar | PASS — throws L848-860; observado T3b/T3c |
| 8 | Detector acotado allowlist | PASS — L855/L863-870 (3 dirs, excluye `config.json`, rechaza `..`); observado T3 |
| 9 | Destino con relativas validadas | PASS — L994-1002; observado `../escape.md` rechazado |
| 10 | Containment-check destino | PASS por código — L1012-1016 fail-closed |
| 11 | Symlinks no se siguen | PASS por código — L1007-1010 (mueve el enlace como tal); sin fixture symlink en Windows |
| 12 | Sufijo único + nunca sobrescribir + sin carpetas vacías | PASS — observado sufijo `-091013`, `OLD-A` intacto, `Move` vacío sin carpetas; variante `_02` por código L1017-1028 |
| 13 | `.gitignore` + advertencia no subir | PASS — L21-22 `.gitignore`, WARN L969-975 si falta, advertencia L1176 (no-commit + rotar secrets + no reintroducir) |
| 14 | Informe conservados origen+hash+fecha | **PARCIAL** — origen ✓ (`existen local, no existen en el maestro`), fecha/tamaño ✓, **hash por archivo ✗** (solo en borrados L944) → **H-1** |
| 15 | Logs solo relativas+metadatos, sin contenido | PASS — L944/L1034/L1169/L1173-1174; ningún `Get-Content` de huérfanos al informe |
| 16 | `-DryRun` solo informa | PASS — guardas L914-919/L961-966/L1078-1087 + early return L1242-1254; observado T1/T2/T3d/T3e |
| 17 | `sync-agents.ps1` default `Preguntar` | PASS — no reenvía `OrphanAction` (L63) → bootstrap default `Preguntar` (L42); observado T2 |
| 18 | `ecc-agentshield scan` | N/A para huérfanos (cambios no tocan `.github/`); corrido de oficio: **sin hallazgos** en `plataformador-bootstrap.ps1`/`sync-agents.ps1`/huérfanos. Nota: Grade C global por 262 criticals preexistentes en `proyect_ext/tokenslayer/package-lock.json` (patrón Azure-key en lock de tercero **gitignored**, fuera de alcance) → **H-2** |

## Bugs / hallazgos para `devops` (NO corregidos, por restricción)

1. **[H-1, menor, no bloqueante] Informe de conservados sin hash SHA256 por archivo** (checklist §5 ítem 14; riesgo 5 de `seguridad/huerfanos.md` pide origen+hash+fecha para revisión informada de posible huérfano malicioso). `Show-OrphanList` muestra ruta+tamaño+fecha pero no hash; el hash corto solo se loguea al borrar (L944). Sugerencia: agregar `sha256:<12ch>` en `Show-OrphanList` o en el informe de `Move-OrphanFilesToBackup`. No bloquea: el criterio 8 de la spec (mover preservando estructura + informar qué/dónde) se cumple.
2. **[H-2, informativo, fuera de alcance T-V6] `npx ecc-agentshield scan` da Grade C (64/100)** por 262 criticals `Azure storage account key` en `proyect_ext/tokenslayer/package-lock.json` (+3 high/7 medium en `.vscode/` de ese clon y 1 low `context-mode` sin versión pineada en `opencode.json`, ya conocidos). El clon es de terceros y está gitignored por política (no se versiona); casi con seguridad son falsos positivos de hashes `integrity` del lock. Se deriva a `security-auditor` para dictamen; **no toca a la implementación de huérfanos** (cero hallazgos en sus archivos).

## Conclusión de rollout

**SÍ, listo para rollout con la condición estándar**: usar `pwsh ≥ 7` y `-DryRun` previo antes del primer modo real (H-1 y H-2 no bloquean; H-2 es de otro componente). T-V6 queda **COMPLETADA**: detección exacta, guardas DryRun verificadas por código y ejecución, respaldo versionado con estructura preservada y sin sobrescrituras, `.gitignore` correcto, y 17/18 del checklist §5 en PASS (1 parcial menor reportado a `devops`).
