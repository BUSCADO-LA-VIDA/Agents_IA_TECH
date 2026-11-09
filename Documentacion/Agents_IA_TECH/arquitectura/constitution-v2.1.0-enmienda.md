# Enmienda constitucional v2.0.0 → v2.1.0 — Configuración generada y aprovisionamiento por tipo

**Estado**: Propuesta redactada y aprobada por el usuario. **No aplicada**: el `edit` sobre `.specify/memory/constitution.md` devuelve `permission.rejected` al tier documental (deuda DD-01). Su aplicación corresponde a `plataformador`, único tier con `edit` sobre el nivel 1.

**Fecha**: 2026-11-07
**Tipo de incremento**: MINOR (nuevo principio/sección y guía materialmente ampliada)
**ADR que la justifica**: `ADR-0014` — `arquitectura/adr/adr-0014-configuracion-generada-y-provisionamiento-por-tipo.md`
**Spec de origen**: `specs/038-provisionamiento-externo-y-config-generada/spec.md`

## Motivo

La constitution vigente describe `opencode.json` como configuración versionada del arnés y ordena que los clones externos salgan bajo `<root>/proyect_ext/`. Ambas cosas quedaron superadas por hechos verificados el 2026-11-07:

- el archivo versionado declaraba una entrada (`context-mode` → `build/cli.js`) contra un binario inexistente;
- los clones de ECC y spec-kit, al vivir dentro de la raíz, inyectan sus `AGENTS.md` como instrucciones de la sesión;
- la comparación de actualización contra refs locales no detecta atraso (spec-kit en `1.0.7.dev0` frente a `v1.3.2`).

Sin enmienda, la spec 038 implementaría un modelo que contradice el texto constitucional vigente.

## Parche 1 — Art. IV (Copilot/Opencode Compatibility)

**Antes** (lista de viñetas, tras `agents/`):

```markdown
- **`agents/`**: espejo de agente compartido entre harnesses.
```

**Después** (se agrega una viñeta al final de la misma lista):

```markdown
- **`agents/`**: espejo de agente compartido entre harnesses.
- **Configuracion de arneses generada (v2.1.0)**: `opencode.json` y `.vscode/mcp.json` **no se versionan**. Se generan desde `dependencias-manifest.yml` + `.opencode/mcp-state.json` con una plantilla versionada y un generador por arnes; la paridad entre ambos se verifica, no se asume (ADR-0014). La forma canonica de los servidores es `mcp.servers.<nombre>` (ADR-0010) y una diferencia de capacidad no declarada es FAIL.
```

## Parche 2 — Art. VI (controles de clonación)

**Antes**:

```markdown
- **Containment**: realpath verificado, sin symlinks, sin `..`, salida obligatoria de `<root>/proyect_ext/`
```

**Después**:

```markdown
- **Containment**: realpath verificado, sin symlinks, sin `..`, y salida obligatoria del directorio de dependencias externas declarado en el manifest, **fuera de la raiz del workspace** (ADR-0014). Ningun archivo del clon se copia al kit por la via de actualizacion: la integracion es controlada (spec 039)
```

## Parche 3 — Art. VI (sección nueva, tras los controles de seguridad)

Se inserta como `#### Aprovisionamiento por tipo y verificacion declaracion-contra-realidad (v2.1.0)`:

```markdown
#### Aprovisionamiento por tipo y verificacion declaracion-contra-realidad (v2.1.0)

Toda dependencia externa declara `tipo_provisionamiento`, y su estado se verifica contra la realidad, no contra otra declaracion. **Capacidad declarada no es capacidad instalada.**

| Tipo | Que es | Autoridad de version |
|---|---|---|
| `kit-integrado` | Codigo de terceros que se integra de forma controlada dentro del kit | branch head (`git ls-remote`) |
| `kit-fuente` | Codigo de terceros que se consume como fuente o CLI | branch head (`git ls-remote`) |
| `mcp-workspace` | Servidor MCP instalado por workspace | registro del gestor de paquetes |
| `mcp-build-local` | Servidor MCP compilado desde un clon local | release + artefacto compilado |
| `entorno` | Runtime o herramienta base | gestor del sistema |

Reglas no negociables:

1. Tipo ausente o desconocido es FAIL; no se infiere por ruta ni por extension.
2. `git status` no es sonda de actualizacion: se consulta el remoto o el registro.
3. El estado por workspace vive en `.opencode/mcp-state.json`, no versionado, con escritura atomica.
4. Los verbos estan separados: `validate` (solo lectura, exit code), `apply` (explicito, fail-open a `degraded`), `generate` (escritura de configuracion).
5. `generate` emite solo entradas cuyo binario resuelve en esta maquina; nunca afirma una capacidad inexistente.
6. La configuracion de arneses se genera desde la plantilla y no se versiona; ver Art. IV.
7. Toda diferencia verificada entre lo que el kit declara o asume y lo que el arnes confirma es una **inconsistencia**, y se declara en `capacidades-por-harness.md` con estado de la capacidad, fuente, version, prueba y `spec_responsable`. Inconsistencia no declarada es FAIL; fila sin `spec_responsable` es WARN.
8. Una spec declara las inconsistencias que encuentra; no las corrige. Cada una se atiende en su propia spec.
```

## Parche 4 — Versión y registro de cambios

**Antes**:

```markdown
**Version**: 2.0.0 | **Ratified**: 2026-08-25 | **Last Amended**: 2026-10-03
```

**Después**:

```markdown
**Version**: 2.1.0 | **Ratified**: 2026-08-25 | **Last Amended**: 2026-11-07
```

Y se agrega, antes del `### Registro de cambios — v2.0.0 (2026-10-03)`:

```markdown
### Registro de cambios — v2.1.0 (2026-11-07)

**MINOR** — ADR-0014. Cuatro cambios:

1. **Art. IV**: la configuracion de arneses (`opencode.json`, `.vscode/mcp.json`) es **generada y no versionada**; se versionan plantilla y generador, y la paridad se verifica.
2. **Art. VI**: el containment de clones exige salida del directorio de dependencias externas **fuera de la raiz del workspace**; actualizar un clon no integra archivos.
3. **Art. VI**: seccion nueva de aprovisionamiento por tipo, con cinco tipos, autoridad de version por tipo, verbos separados y la regla "capacidad declarada no es capacidad instalada".
4. **Art. VI**: toda diferencia verificada entre lo declarado y lo real se registra con fuente, version, prueba y `spec_responsable`; una spec declara inconsistencias, no las corrige.

**Sin cambio de principios**: no se elimina ni redefine ningun articulo; los nueve siguen vigentes. Por eso el incremento es MINOR y no MAJOR.
```

## Verificación después de aplicar

1. `grep -n "Version"` sobre el nivel 1 devuelve `2.1.0` y `Last Amended: 2026-11-07`.
2. Los nueve artículos siguen presentes (I a IX) y el registro v2.0.0 se conserva.
3. `grep -n "proyect_ext/"` no conserva la frase "salida obligatoria de `<root>/proyect_ext/`" como containment.
4. El nivel 2 (`Documentacion/Agents_IA_TECH/.specify/constitution.md`) se replica desde el nivel 1 con el mismo contenido, según `Ensure-ConstitutionAppSync`.
5. `scripts/validate-agents-skills.ps1` sigue en `FAIL: 0`.

## Trazabilidad

| Elemento | Referencia |
|---|---|
| Decisión de arquitectura | `arquitectura/adr/adr-0014-configuracion-generada-y-provisionamiento-por-tipo.md` |
| Índice de ADRs | `arquitectura/adr/00-index.md` (fila ADR-0014) |
| Spec | `specs/038-provisionamiento-externo-y-config-generada/spec.md` (D1–D5, FR-01 a FR-17) |
| Tarea del backlog | `pendientes-implementacion.md` → `038-DOC-03` |
| Bloqueo actual | `edit` sobre `.specify/memory/constitution.md` → `permission.rejected`; deuda DD-01 |
