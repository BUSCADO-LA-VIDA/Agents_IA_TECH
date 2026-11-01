# Guía de propagación del kit Agents_IA_TECH (spec 035)

> Propagar el kit transversal de un proyecto consumidor sin romper nada. Requiere `PowerShell 7+` y el kit maestro sincronizado localmente.

## 1. Qué propaga el sync (y qué no)

`scripts/sync-kit.ps1` (invocado vía `sync-agents.ps1`) sincroniza únicamente los **archivos transversales del kit**. Nunca toca `Documentacion/<AppName>/` de ninguna aplicación.

| Viaja (sobreescribe/merge) | NO viaja (intacto en el proyecto) |
|---|---|
| `.github/` (agentes, skills, copilot-instructions) | `Documentacion/<AppName>/` (documentación de cada app) |
| `.opencode/` (agentes, skills, config) | `src/` de las apps |
| `.doc_agents/` | `tests/` de las apps (excepto whitelist) |
| `scripts/` | `.opencode/config.json` (credenciales, nunca se copia) |
| `AGENTS.md` (merge por bloque `KIT-BLOCK`) | Cualquier archivo no listado abajo |
| `opencode.json` (merge por claves: `$schema`, `instructions`, `default_agent` del kit; `mcp`, `model`, `permission`, `lsp` del proyecto se preservan) | |
| `README.md`, `sync-agents.ps1`, `upgrade_framework.ps1`, `.specify/memory/constitution.md` | |

### Whitelist de tests del kit (solo estos viajan)
- `tests/harness-default.ps1`
- `tests/kit-sync-merge.ps1`
- `tests/agents-parity.ps1`
- `tests/kb-parity.ps1`
- `tests/mcp-refresh-parity.ps1`

## 2. Antes de propagar (checklist de seguridad)

- [ ] El kit maestro tiene los cambios commiteados (`git status --porcelain` limpio en el maestro).
- [ ] El proyecto consumidor tiene sus cambios commiteados o está dispuesto a aceptar sobrescrituras de archivos transversales.
- [ ] Se ejecuta **primero en modo `-DryRun`** (no escribe nada) para revisar qué cambiaría.
- [ ] Se conoce el `default_agent` del proyecto consumidor (el sync respeta agentes del kit con `mode: primary`; con `-Force` se sobrescribe a `pensador`).

## 3. Cómo ejecutar el sync (modo seguro)

Desde la raíz del proyecto consumidor:

```powershell
# 1) Dry-run: simula sin escribir nada. Revisa la salida antes de continuar.
pwsh -NoProfile -File scripts/sync-agents.ps1 -DryRun

# 2) Si el DryRun muestra lo esperado, ejecutar de verdad:
pwsh -NoProfile -File scripts/sync-agents.ps1

# 3) Forzar sobrescritura de default_agent (solo si se quiere imponer pensador):
pwsh -NoProfile -File scripts/sync-agents.ps1 -Force
```

### Parámetros
| Parámetro | Efecto |
|---|---|
| `-DryRun` | Simula sin escribir nada. Úsalo siempre primero. |
| `-Force` | Sobreescribe `default_agent` a `pensador` incluso si el proyecto tiene otro agente del kit con `mode: primary`. Sin él, se respetan agentes válidos del kit. |
| `-KitPath <ruta>` | Usa un checkout local del kit como fuente en lugar de clonar desde GitHub (útil para propagar cambios sin pushear). |

## 4. Paso a paso contra un proyecto de prueba (ejemplo: Generator_IA_Projects)

Desde la raíz del kit (o del proyecto consumidor):

```powershell
# Opción A: desde el kit maestro, apuntando al consumidor
pwsh -NoProfile -File scripts/sync-agents.ps1 -DryRun -KitPath C:\Proyectos\Agents_IA_TECH -RootPath C:\Proyectos\Generator_IA_Projects

# Opción B: desde dentro del proyecto consumidor
cd C:\Proyectos\Generator_IA_Projects
pwsh -NoProfile -File sync-agents.ps1 -DryRun
```

**Qué revisar en la salida del DryRun:**
- `[MERGE] opencode.json (merge por claves)` — no `[SKIP]`, significa que aplicará el merge de claves.
- `[MERGE] AGENTS.md (bloque delimitado)` — aplica la regla del bloque `KIT-BLOCK`.
- `copiaria la whitelist de tests del kit` — confirma que los tests del kit viajan.
- `NUNCA tocaria Documentacion/<AppName>/` — confirma la frontera de aislamiento.
- `WARNs: 0`, `ERRORs: 0`, `===EXITCODE: 0===` — sin errores.

Si el DryRun está limpio, ejecuta sin `-DryRun` para aplicar de verdad.

## 5. Qué verificar después de aplicar

| Verificación | Comando | Resultado esperado |
|---|---|---|
| `opencode.json` tiene `default_agent: pensador` | `Get-Content opencode.json \| ConvertFrom-Json` | `default_agent` vale `pensador` (o el agente del kit que tenía el proyecto, si era válido y no se usó `-Force`) |
| `mcp` del proyecto se conserva | `Get-Content opencode.json \| ConvertFrom-Json` | `mcp.servers` conserva los servidores del proyecto |
| `AGENTS.md` tiene el bloque `KIT-BLOCK` | `Select-String -Path AGENTS.md -Pattern 'KIT-BLOCK'` | Aparecen `<!-- KIT-BLOCK:START ... -->` y `<!-- KIT-BLOCK:END ... -->` |
| `tests/` del kit viajó | `Get-ChildItem tests/harness-default.ps1, tests/kit-sync-merge.ps1` | Ambos archivos existen |
| `tests/` de la app no se tocó | `git status --porcelain tests/` | Solo los tests del kit (si aplican), no los de la app |

## 6. Gate de calidad: `scripts/validate-agents-skills.ps1`

Después de propagar, ejecuta el validador en el proyecto consumidor:

```powershell
pwsh -NoProfile -File scripts/validate-agents-skills.ps1
```

**Resultados esperados:**
- `FAIL: 0` — ningún fallo crítico.
- `VAL-10` (arranque por defecto) en `[OK]` — `default_agent` apunta a un agente del kit con `mode: primary`.
- `VAL-11` (coherencia backlog-disco) — puede mostrar WARN si hay specs declaradas como Cerradas pero con tareas pendientes; eso es informativo, no bloqueante.

## 7. Reglas de oro

1. **Siempre `-DryRun` primero.** Nunca ejecutes el sync real sin haber revisado la salida del DryRun.
2. **Nunca propagues sobre un proyecto con cambios sin commitear** a menos que estés dispuesto a aceptar sobrescrituras de archivos transversales.
3. **Nunca edites archivos transitorios en el proyecto consumidor.** Los archivos del kit (`.github/`, `.opencode/`, `scripts/`, `opencode.json`, `AGENTS.md`) son gestionados por el kit maestro. Los cambios locales se perderán en el próximo sync.
4. **`Documentacion/<AppName>/` es sagrada.** El sync nunca la toca. Cada app es dueña de su documentación.

## 8. ¿Qué hacer si algo sale mal?

| Síntoma | Causa probable | Solución |
|---|---|---|
| `default_agent` cambió a `pensador` y no querías | Se ejecutó sin `-Force` y el proyecto tenía `build` o un agente no válido | Edita `opencode.json` en el proyecto y restaura tu agente preferido (si es del kit con `mode: primary`, se respetará en futuros syncs sin `-Force`) |
| `AGENTS.md` se sobrescribió | El bloque `KIT-BLOCK` se actualizó; el resto del archivo se conserva | Revisa qué cambió en el bloque; el resto del archivo está intacto |
| `tests/` de la app se modificó | No debería ocurrir; `tests/` de la app no viaja en el sync | Revisa `git status` en el proyecto consumidor; si algo cambió, revierte |
| `VAL-11` reporta WARN de divergencia | El índice declara una spec como Cerrada pero tiene tasks pendientes | Revisa la spec en `00-indice.md` y corrige el estado o completa las tareas |

---

**Estado del kit (2026-11-01):** ciclo 035 completo y commiteado. El kit está listo para propagarse a proyectos consumidores. Ejecuta siempre el `-DryRun` primero.