# Generación de `opencode.json` — dónde está y cómo se valida

**Spec asociada**: `046-generacion-portable-opencode-json` (los defectos G1-G4 de este documento son su alcance).

**Fecha**: 2026-11-09
**Decisión de origen**: Spec 038 D2 — `opencode.json` **no se versiona**; se genera con la configuración de cada máquina.

---

## 1. Regla

| Archivo | ¿Se versiona? | Motivo |
|---|---|---|
| `opencode.json` | **No** | Contiene rutas resueltas de la máquina (intérprete, npm global, `PATH` local). Versionarlo publica el layout del FS y se recontamina en cada ejecución |
| `opencode.template.json` | **Sí** | Fuente portable: tokens `{env:...}`, `default_agent`, `permission`, timeouts, entradas MCP con `enabled: false` |
| `.env.mcp` | **No** (gitignored) | Rutas reales por máquina; fuente que consume el resolvedor |

## 2. Quién crea `opencode.json` (validado en el repo)

| Pieza | Ruta | Qué hace | Cuándo corre |
|---|---|---|---|
| **Generador/merge de la capa** | `scripts/sync/mcp/lift-opencode.ps1` | Si el destino **no tiene** `opencode.json`, lo **crea desde el maestro** (`-StageDir`). Si existe sin bloque `mcp`, lo agrega. Repara entradas cuyo `command[0]` no existe en disco. Reescribe la ruta del grafo para `graphify` | Capa `mcp-lift-opencode` del sync |
| **Orquestador de capas** | `scripts/sync-kit-agents.ps1` (`F2 — Plataformar`) | Invoca la capa con `-StageDir <kit> -RootPath <proyecto>` | `sync-kit-agents.ps1` (actualización / plataformado) |
| **Merge de claves gestionadas** | `scripts/sync/opencode/sync-opencode-config.ps1` | Fija `$schema`, `instructions`, `default_agent` desde el maestro; conserva `mcp`, `model`, `permission`, `lsp` del proyecto | Invocado por el sync |
| **Entrada `graphify`** | `scripts/sync-mcp-graphify.ps1` | Consolida la entrada `graphify` en `mcp.servers` (una sola, sin duplicados) | Sync (`036`) |
| **Bloque `mcp` + re-resolución de tokens** | `scripts/plataformador-bootstrap.ps1` → `Ensure-OpenCodeMcp` | Crea la sección `mcp` con plantilla `{env:...}` + `enabled:false` y **re-resuelve** contra `.env.mcp`/entorno a rutas locales; fija `default_agent: pensador` con backup previo | Bootstrap (instalación / nivelación) |
| **Chequeo de herramientas** | `scripts/update-mcp.ps1` | **No genera** `opencode.json`; verifica que las rutas de `.env.mcp` existan y actualiza `.bootstrap-state.json` | Actualización periódica (ventana 24 h) |

## 3. Cómo se ejecuta

```powershell
# A) Vía actualización / plataformado (recomendado): capa mcp-lift-opencode dentro del sync
.\scripts\sync-kit-agents.ps1 -RootPath . [-DryRun] [-Force]
.\scripts\sync-kit-agents.ps1 -ListLayers            # para ver las capas

# B) Vía bootstrap (instalación o nivelación del proyecto)
.\scripts\plataformador-bootstrap.ps1 [-DryRun]

# C) Individual (solo esta capa)
.\scripts\sync\mcp\lift-opencode.ps1 -StageDir <ruta-del-kit> -RootPath <ruta-del-proyecto> [-DryRun]
```

## 4. Validación reproducible

Se ejecutó el generador contra un directorio temporal vacío, con el kit como maestro:

```powershell
$tmp = Join-Path $env:TEMP ('oc-validate-' + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
.\scripts\sync\mcp\lift-opencode.ps1 -StageDir (Get-Location).Path -RootPath $tmp
Get-Content (Join-Path $tmp 'opencode.json') -Raw | ConvertFrom-Json | Select-Object default_agent
```

Resultado observado:

| Comprobación | Resultado |
|---|---|
| El archivo se crea cuando no existe | **Sí** (`opencode.json creado: True`) |
| `default_agent` | `pensador` |
| Entradas `mcp.servers` generadas | 8 (`context-mode`, `codebase-memory-mcp`, `markitdown`, `graphify`, `github`, `playwright`, `tokenslayer`, `context7`) |
| Salida de la capa | `RESULT:mcp-opencode:anadidas` |
| Backup previo cuando el archivo existe | `<Root>/.kit-backup/<timestamp>/` |

**Conclusión: la generación está implementada y es ejecutable de forma individual, en el sync y en el bootstrap.**

## 5. Defectos detectados en la validación

| # | Defecto | Evidencia | Impacto |
|---|---|---|---|
| G1 | El archivo generado **hereda las rutas absolutas del maestro** (`command[]` se copia tal cual) | `context-mode -> <NODE_HOME>/node.exe <HOME>/...` | El destino queda atado a la máquina del autor; es la vía por la que se recontamina el repo del consumidor |
| G2 | La ruta del grafo de `graphify` **no se regenera al destino**: queda apuntando al kit | `graphify -> ... -m graphify.serve <KIT_ROOT>/graphify-out/graph.json` en un destino temporal | El MCP sirve el grafo del kit, no el del proyecto; contradice el comentario de cabecera de la capa |
| G3 | `tokenslayer` apunta a la ruta absoluta del kit, no a una resolución relativa/local | `tokenslayer -> node <KIT_ROOT>/proyect_ext/tokenslayer/.../index.js` | En otro proyecto la ruta no existe; el MCP no arranca |
| G4 | `plataformador-bootstrap.ps1` no crea el archivo si falta (solo advierte), salvo que exista `opencode.template.json` (fallback añadido en la Spec 044) | `Ensure-OpenCodeMcp`, aviso "No existe opencode.json…" | Depende de la capa de sync; en un proyecto recién clonado sin sync previo, el bootstrap solo advierte |

## 6. Corrección propuesta (pendiente de aprobación)

1. **Maestro portable**: que `-StageDir`/maestro sea `opencode.template.json` cuando exista, de modo que el generador escriba tokens y el bootstrap resuelva a rutas locales (G1).
2. **Regenerar `graphify` con `$RootPath`** del destino, no con el del stage (G2).
3. **`tokenslayer`**: registrar con ruta relativa al proyecto cuando el directorio exista en el destino; si no, dejar la entrada `enabled:false` con WARN (G3).
4. **Bootstrap**: si no hay `opencode.json`, generar desde `opencode.template.json` y luego re-resolver (G4, ya implementado como fallback en la Spec 044; falta el caso sin plantilla).

## 7. Estado

- Generación: **implementada y validada** (§4).
- Portabilidad del contenido generado: **no resuelta** (§5, G1-G3).
- `opencode.json` en este repo: **versionado todavía**; la Spec 044 exige sacarlo del índice para que el validador quede en 0 coincidencias. Pendiente de decisión del usuario.
