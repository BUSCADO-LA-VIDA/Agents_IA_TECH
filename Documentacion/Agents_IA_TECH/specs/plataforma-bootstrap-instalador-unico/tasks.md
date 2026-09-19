# Tasks: `plataformador-bootstrap.ps1` — Instalador/Actualizador Único

> **Estado**: En planificación
> **Fecha**: 2026-09-17
> **Fuente**: `spec.md` + `plan.md` (esta carpeta) + ADR-0003
> **Autor**: `documentador` (fase documental — paso 2º)

---

## Tareas por agente

### Documentales

| ID | Agente | Tarea | Estado |
|----|--------|-------|--------|
| T-D1 | `arquitecto` | Crear ADR-0003 (modelo, resolución app activa, fusión `Sync-TransversalKit`, guardrails, diagrama, plan). | ✅ **COMPLETADA (2026-09-17)** |
| T-D2 | `documentador` | Crear spec/plan/tasks del bootstrap + actualizar `00-indice.md`, `referencias.md`, `pendientes-implementacion.md`. | ✅ **COMPLETADA (2026-09-17)** |
| T-D3 | `security-auditor` | Revisar descarga desde git (URLs, licencias, credenciales) y dejar recomendaciones en `Documentacion/Agents_IA_TECH/seguridad/`. | ✅ **COMPLETADA (2026-09-17)** — `seguridad/plataforma-bootstrap.md` |
| T-D4 | `documentador` | Documentar manejo de huérfanos `[HUERFANOS]`: RF-12 + flujo de decisión en `spec.md`, tasks T-I7/T-I8/T-V6, sección Actualización en `README.md`. | ✅ **COMPLETADA (2026-09-18)** — RF-12 + criterio 8 + diagrama con paso de huérfanos en `spec.md`; tasks T-I7/T-I8/T-V6 creadas; `README.md` (Actualización + huérfanos) actualizado |
| T-D5 | `documentador` | Documentar reubicación `[RELOCATE]` (plan aprobado 2026-09-19): RF-13 + criterio 9 en `spec.md`, sección de reubicación en `README.md`, adenda ADR-0003 (RNF-04 vs opt-in confirmado). | ✅ **COMPLETADA (2026-09-19)** — RF-13 (`Move-AppToSrc` + `Confirm-AppRelocation`; flags `-AppDirs`/`-DryRun`/`-ProjectRoot`, sin bypass; S/N/T/C, no-interactivo no mueve, venv a recrear, pre-chequeos + log + rollback manual + post-movido imports/tests, nunca `Documentacion/`, bootstrap intacto, integración futura separada) + criterio 9 en `spec.md`; sección Reubicación en `README.md` (versión 2026-09-19); adenda fechada en ADR-0003 |
| T-D6 | `documentador` | Documentar extensión `[RELOCATE]` auto-desactivar/reactivar venv + pausar git (plan aprobado 2026-09-19): RF-14 + criterio 10 en `spec.md`, sección Reubicación + venv activo en `README.md`. | ✅ **COMPLETADA (2026-09-19)** — RF-14 (`Suspend-AppLocks` + `Restore-AppLocks`; cada acción pregunta, sin bypass, `-Force` no aplica, No a todo = avisos, `-DryRun` informa sin mutar; venv en-sesión + `git.exe` puntuales con cwd verificado nunca `Code`; recrea + activa `src\<App>\.venv`, git se redescubre solo; mutar sesión del llamante documentado) + criterio 10 en `spec.md`; `README.md` actualizado (auto-desactivar/reactivar + pausar git, versión 2026-09-19) |
| T-D7 | `documentador` | Documentar limpieza de regenerables `[RELOCATE]` (plan aprobado 2026-09-19, decisión explícita: `.venv` se ELIMINA, no se mueve): RF-15 + criterio 11 en `spec.md`, sección Reubicación + `.venv` en `README.md`. | ✅ **COMPLETADA (2026-09-19)** — RF-15 (`Find-RegenerableDirs` + `Clear-RegenerableDirs`; allowlist fija Python + Node + general + `.venv/`; pregunta global antes de S/N/T/C, No = mueve todo; `.venv` activo → `deactivate` previo obligatorio vía RF-14; log sin respaldo; recreación `python -m venv` + `pip install` en `src\<App>\`; nunca `Documentacion/`; `-DryRun` informa, no borra) + criterio 11 en `spec.md`; `README.md` actualizado (limpieza + `.venv` se elimina y recrea + `deactivate` previo, versión 2026-09-19) |
| T-D8 | `documentador` | Documentar 3 gaps de auditoría real de Metatrader (plan aprobado 2026-09-19): RF-16 + RF-17 + RF-18 y criterios 12/13/14 en `spec.md`, sección MCPs + troubleshooting `config.json` en `README.md`. | ✅ **COMPLETADA (2026-09-19)** — RF-16 (`Ensure-OpenCodeMcp` registra tokenslayer 4º MCP `type: local` + `command: [node, <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js]` + `enabled: true`, fuente entrada `tokenslayer-mcp-server` en `dependencias-manifest.yml`; sin binario → WARN + instrucciones de compilar, no falla) + RF-17 (`Ensure-OpenCodeConfig` crea `.opencode/config.json` SOLO si no existe desde plantilla con PLACEHOLDERS, si existe no lo toca nunca, sigue gitignored, keys a mano documentadas) + RF-18 (`Repair-DocStructure` mueve docs sueltas de raíz a `Documentacion/<App>/` con confirmación por archivo S/N/T/C sin bypass, >50KB/tracking vivo solo se listan, nunca borra, `-DryRun` informa) + criterios 12/13/14 en `spec.md`; `README.md` actualizado (4º servidor + troubleshooting `config.json`, versión 2026-09-19) |
| T-D9 | `documentador` | Documentar instalación de Graphify `[GRAPHIFY-INSTALL]` (plan aprobado 2026-09-19): RF-19 + criterio 15 en `spec.md`, sección Graphify en `README.md`, marcar fase documental en `pendientes-implementacion.md`. | ✅ **COMPLETADA (2026-09-19)** — RF-19 (árbol MCP-preferido; investigación web sin clones: `tomasgraph/graphify` → 404, upstream real `Graphify-Labs/graphify` PyPI `graphifyy` MIT; SÍ expone MCP stdio embebido `python -m graphify.serve` con 7 herramientas; sin `bin/`/`lib/` → Rama B adaptada a install Python estilo `markitdown`; WARN sin fallo, `-DryRun` informa, pin en manifest; gaps: URL muerta + owner fuera de allowlist para `devops` con decisión del usuario, supply chain para `security-auditor`) + criterio 15 en `spec.md`; sección Graphify en `README.md` (versión 2026-09-19) |

### Implementación

| ID | Agente | Tarea | Estado |
|----|--------|-------|--------|
| T-I1 | `plataformador` | Refactorizar `plataformador-bootstrap.ps1`: implementar `Sync-TransversalKit`, resolución de app activa (`-App` + `cwd`), integración de Spec-kit y Graphify. | ✅ **COMPLETADA (2026-09-18)** |
| T-I2 | `plataformador` | Implementar la creación de `.specify` + `Documentacion/<AppName>/` por app. | ✅ **COMPLETADA (2026-09-18)** |
| T-I3 | `plataformador` | Implementar la preparación de apps en `src\AppXXX\` (descarga desde git, respetando `proyect_ext/spec-kit` en la raíz). | ✅ **COMPLETADA (2026-09-18)** |
| T-I4 | `devops` | Convertir `sync-agents.ps1` en wrapper que delega en `Sync-TransversalKit`. | ✅ **COMPLETADA (2026-09-18)** |
| T-I5 | `devops` | Configurar MCPs en todos los harnesses (plugin context-mode en `opencode.json`, hooks `.github/hooks/`, `.vscode/mcp.json`). | ✅ **COMPLETADA (2026-09-18)** |
| T-I6 | `qa-senior` | Escribir/ejecutar tests del script: idempotencia, `-DryRun`, clonado, actualización, estructura resultante, no-tocar-`Documentacion/<AppName>/`. | ✅ **COMPLETADA (2026-09-18)** — DryRun cero-escrituras verificado; reporte en `Documentacion/Agents_IA_TECH/testing/validacion-bootstrap-2026-09-18.md` |
| T-I7 | `devops` | Implementar manejo de huérfanos en `Sync-TransversalKit`: `Find-OrphanKitFiles` (detección vs clon maestro shallow en `.github/` `.opencode/` `.doc_agents/`) + `Invoke-OrphanDecision` (pregunta borrar/conservar/omitir + flag `-OrphanAction Borrar\|Conservar\|Preguntar`, default seguro Conservar) + movido versionado a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` (sufijo hora si la fecha existe) + informe de qué se movió y dónde; nunca `Documentacion/<AppName>/`; en `-DryRun` solo informa. | ⏳ Pendiente |
| T-I8 | `devops` | Agregar `revisar_manualmente/` a `.gitignore` (respaldo de huérfanos no versionado). NOTA: el `.gitignore` lo edita `devops`, esta task solo lo registra. | ⏳ Pendiente |

### Validación

| ID | Agente | Tarea | Estado |
|----|--------|-------|--------|
| T-V1 | `qa-senior` | Ejecutar `-DryRun` en `C:\Proyectos\Agents_IA_TECH` y `C:\Proyectos\Metatrader`; verificar que no toca `Documentacion/<AppName>/`. | ✅ **COMPLETADA (2026-09-18)** — ambos DryRun EXIT 0, cero escrituras, frontera respetada |
| T-V2 | `qa-senior` | Ejecutar sin `-DryRun`; verificar Spec-kit orientado a la app activa y Graphify configurado. | ✅ **COMPLETADA verificación estática (2026-09-18)** — lógica de `Configure-SpecKit` correcta; modo real NO ejecutado (pendiente si se requiere) |
| T-V3 | `qa-senior` | Validar que al cargar VS Code los agentes, MCPs y Spec-kit funcionan sin re-ejecutar scripts. | ✅ **COMPLETADA verificación estática (2026-09-18)** — `opencode.json` (plugin+3 MCPs), hooks (Pre/Post/SessionStart) y `.vscode/mcp.json` (3 servidores) correctos |
| T-V4 | `qa-senior` | Correr `npx ecc-agentshield scan` (seguridad `.github/`). | ✅ **COMPLETADA (2026-09-18)** — Grade A (98/100), 0 critical/high |
| T-V5 | `gitflow` | Commits convencionales al final. | ⏳ Pendiente |
| T-V6 | `qa-senior` | Tests de huérfanos en `-DryRun`: detección correcta vs maestro, nada se borra/mueve en DryRun, respaldo conserva estructura original, informe de movidos. | ⏳ Pendiente |

---

## Detalle de la tarea principal (bootstrap)

**Implementar Spec-kit + MCPs + Graphify en todos los proyectos, con `plataformador-bootstrap.ps1` como instalador/actualizador único.**

- [ ] `[PLATAFORMA]` **Implementar Spec-kit + MCPs + Graphify en todos los proyectos, con `plataformador-bootstrap.ps1` como instalador/actualizador único**
  - **Qué implementar**: Convertir `plataformador-bootstrap.ps1` en el instalador/actualizador único que: (1) implementa Spec-kit en todos los proyectos (incluido este como principal), (2) implementa los MCPs para todos los harnesses, (3) activa y usa los MCPs junto a Graphify y las aplicaciones de apoyo, (4) descarga las apps desde sus repos git y las coloca en `src\AppXXX\`, (5) crea `.specify` + `Documentacion\<AppName>\` por app, (6) resuelve rutas de spec-kit por app activa, (7) valida que el flujo se respeta desde la carga de VS Code sin re-ejecutar scripts.
  - **Basado en**: Plan aprobado por el usuario (2026-09-17) — 6 prioridades + decisiones de diseño + ADR-0003 + `specs/plataforma-bootstrap-instalador-unico/spec.md`.
  - **Decisiones del usuario (2026-09-17)**:
    - `sync-agents.ps1` → Opción A: absorber lógica como `Sync-TransversalKit`; queda como wrapper.
    - Repo maestro: `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`.
    - Apps como aplicaciones: `dwxconnect`, `fibonacci-scanner`, `operation_mt5`, `Telegram`, `trading_bot`. `proyect_ext/spec-kit` queda en la raíz.
    - Resolución de app activa: `-App` + `cwd`.
  - **Prioridad**: alta