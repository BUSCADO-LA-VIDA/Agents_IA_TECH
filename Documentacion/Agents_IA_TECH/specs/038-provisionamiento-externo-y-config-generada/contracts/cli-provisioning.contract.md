# Contrato de CLI: aprovisionamiento externo

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Phase**: 1 | **Date**: 2026-11-12

Contrato de los comandos que esta feature expone al usuario y a otros scripts. Define entradas, salidas y exit codes. No es un manual de implementación: los cuerpos de los scripts viven en la fase `implement`.

---

## Principios del contrato

1. **Tres verbos separados** por efecto: `validate` (lee), `apply` (instala/actualiza), `generate` (escribe configuración). Un verbo nunca ejecuta el efecto de otro.
2. **Exit code contractual**: ningún verbo reporta éxito sin evidencia (NFR-05).
3. **El manifest es la entrada única**: ningún verbo acepta una lista de dependencias por parámetro que contradiga el manifest.
4. **Sin secretos en salida ni en artefactos**: las variables de entorno se referencian por nombre (NFR-04).

---

## `validate`

**Script**: `scripts/mcp/Get-ProvisioningState.ps1`

| Aspecto | Contrato |
|---|---|
| Entrada | `-Manifest <ruta>` (default `dependencias-manifest.yml`), `-Json`, `-Verbose` |
| Lee | manifest, clones en `proyect_ext/`, gestores de paquetes, repos remotos (`git ls-remote`, registro del gestor) |
| Escribe | solo `.opencode/mcp-state.json` (escritura atómica). Nunca configuración, nunca clones (NFR-01) |
| Salida | tabla legible (`--Json` ⇒ objeto `{ "dependencias": { "<nombre>": ProvisioningState } }`) |
| Exit 0 | todas las dependencias requeridas presentes y al día |
| Exit 1 | al menos una requerida ausente, degradada, con tipo inválido o con binario no resolubre |
| Exit 2 | manifest inválido contra `dependencias-manifest.schema.json` |
| WARN | dependencia opcional ausente (no cambia el exit code, FR-12) |
| Timeout | 60 s con red; sin red degrada a `desconocido` en < 15 s sin bloquear la sesión (NFR-07) |

**Ejemplo de invocación**

```powershell
pwsh -NoProfile -File scripts/mcp/Get-ProvisioningState.ps1 -Json
# exit 1 si context-mode apunta a un binario inexistente
```

---

## `apply`

**Script**: `scripts/mcp/Invoke-ProvisioningApply.ps1`

| Aspecto | Contrato |
|---|---|
| Entrada | `-Dependencia <nombre>` (repetible; sin valor ⇒ todas), `-DryRun`, `-Force`, `-Json` |
| `-DryRun` | muestra la operación por dependencia y no ejecuta ninguna escritura |
| `kit-integrado` / `kit-fuente` | solo operaciones git sobre `proyect_ext/<clon>`: `fetch` + `reset --hard <rama_seguida>`, o `fetch` del tag + `checkout` si está en tag; `--unshallow` si es shallow. **No copia nada al kit** (FR-14, D3/D4) |
| `mcp-workspace` | instalación con el gestor declarado (`npm`, `pip`/`uv`) |
| `mcp-build-local` | `fetch` + `checkout` + instalación de dependencias + build; el estado solo pasa a `ok` si el artefacto declarado existe después del build (FR-16) |
| `entorno` | verificación de versión mínima; no instala |
| Exit 0 | todas las dependencias solicitadas quedaron `ok` o `al-dia` |
| Exit 1 | al menos una quedó `degraded` con causa reportada; el resto completó (fail-open, FR-07) |
| Prohibido | ejecutarse como efecto secundario de `validate` o `generate` (FR-07) |

**Ejemplo de invocación**

```powershell
pwsh -NoProfile -File scripts/mcp/Invoke-ProvisioningApply.ps1 -Dependencia spec-kit -DryRun
pwsh -NoProfile -File scripts/mcp/Invoke-ProvisioningApply.ps1 -Dependencia spec-kit
```

---

## `generate`

**Scripts**: `scripts/mcp/generate-opencode.ps1` y `scripts/mcp/generate-copilot.ps1`

| Aspecto | Contrato |
|---|---|
| Entrada | `-Manifest <ruta>`, `-Template <ruta>` (plantilla versionada), `-Out <ruta>` (default por arnés), `-DryRun`, `-Json` |
| Precondición | el estado debe existir y ser legible; si no, se ejecuta la sonda antes de escribir |
| Regla dura | solo emite entradas cuyo binario resuelve; `missing`/`degraded` se omiten con WARN (FR-08) |
| Forma de salida | `mcp.servers.<nombre>` con `type: "stdio"`, `command`, `args`, `env` (FR-11) |
| Preservación | conserva las claves del usuario que no son `mcp.servers` (estructura, `default_agent`, `permission`, `plugin`) y no inventa valores (FR-10) |
| Atomicidad | archivo temporal en el mismo directorio + reemplazo (NFR-03) |
| Idempotencia | dos ejecuciones consecutivas ⇒ archivos idénticos byte a byte (NFR-02, SC-003) |
| Exit 0 | ambos archivos escritos (o simulados) y válidos contra el esquema del arnés |
| Exit 1 | plantilla ilegible, ninguna dependencia resolubre, o escritura fallida |
| Prohibido | escribir `opencode.json` o `.vscode/mcp.json` versionados: ambos entran en `.gitignore` (D2) |

**Ejemplo de invocación**

```powershell
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1 -DryRun
pwsh -NoProfile -File scripts/mcp/generate-opencode.ps1
pwsh -NoProfile -File scripts/mcp/generate-copilot.ps1
```

---

## `validate-parity`

**Script**: `scripts/mcp/validate-parity.ps1`

| Aspecto | Contrato |
|---|---|
| Entrada | `-Opencode <ruta>`, `-Copilot <ruta>`, `-Matrix <ruta>`, `-Json` |
| Compara | (a) conjunto de nombres bajo `mcp.servers` en ambos archivos; (b) `command`, `args`, `env` por nombre y `type` de cada entrada; (c) capacidades usadas por los agentes contra la matriz |
| Exit 0 | conjuntos de servidores idénticos y toda diferencia de capacidad declarada con fuente |
| Exit 1 | servidor presente en un arnés y ausente en el otro, o capacidad usada y no declarada (FR-15.1) |
| WARN | fila sin `spec_responsable` ⇒ inconsistencia documentada sin dueño (FR-15.2) |
| WARN | capacidad `no-soportado` no emitida en la configuración (FR-15.4) |
| Sin acción | fila con `spec_responsable` y `prueba` vacía ⇒ en trabajo (FR-15.3) |

**Ejemplo de invocación**

```powershell
pwsh -NoProfile -File scripts/mcp/validate-parity.ps1 -Json
```

---

## Matriz de exit codes (resumen)

| Código | `validate` | `apply` | `generate` | `validate-parity` |
|---|---|---|---|---|
| 0 | todo requerido al día | todo solicitado `ok`/`al-dia` | archivos generados y válidos | paridad y capacidades declaradas |
| 1 | requerido ausente/degradado/tipo inválido | al menos una `degraded` | plantilla o escritura fallida | servidor o capacidad no declarada |
| 2 | manifest inválido | manifest inválido | manifest inválido | matriz ilegible o inválida |

## Artefactos que este contrato referencia

- `dependencias-manifest.schema.json` — estructura del manifest.
- `mcp-state.schema.json` — estructura del estado por workspace.
- `mcp-server-config.schema.json` — estructura de una entrada `mcp.servers.<nombre>`.
- `capability-matrix.schema.json` — estructura de una fila de la matriz de capacidades.
