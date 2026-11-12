# Data Model: Aprovisionamiento externo por tipo y configuración generada

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Phase**: 1 (Design & Contracts) | **Date**: 2026-11-12

**Fuente**: `spec.md` §Key Entities (FR-01 a FR-17) y `research.md` (R1-R5).

---

## Resumen de entidades

| Entidad | Archivo | Versionado | Propósito |
|---|---|---|---|
| `DependencyManifest` | `dependencias-manifest.yml` | Sí | Declaración de todas las dependencias externas y su autoridad de versión |
| `ExternalDependency` | entrada de `dependencias_externas[]` | Sí (vive en el manifest) | Una dependencia con su tipo de aprovisionamiento y sonda |
| `ProvisioningState` | `.opencode/mcp-state.json` | No | Resultado observado por workspace: instalado, última versión, estado |
| `McpServerConfig` | `opencode.json` / `.vscode/mcp.json` | No (generado) | Entrada de servidor MCP emitida solo si el binario resuelve |
| `CapabilityMatrix` | `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` | Sí | Fila por capacidad con mecanismo, estado, fuente y versión verificada |

Relaciones: `DependencyManifest` 1:N `ExternalDependency`; `ExternalDependency` 1:1 `ProvisioningState` (por nombre); `ExternalDependency` con tipo `mcp-workspace` o `mcp-build-local` 1:1 `McpServerConfig` (solo si el binario resuelve); `McpServerConfig` N:M `CapabilityMatrix` vía el nombre de servidor.

---

## 1. `DependencyManifest`

**Campos**

| Campo | Tipo | Obligatorio | Validación |
|---|---|---|---|
| `version_manifest` | string semver | Sí | `^\d+\.\d+\.\d+$` |
| `updated` | string ISO8601 | Sí | `AAAA-MM-DDTHH:MM:SSZ`, no futuro |
| `dependencias_externas` | array `ExternalDependency` | Sí | mínimo 1 elemento; `nombre` único (case-insensitive) |

**Validaciones derivadas de requisitos**: FR-01 exige que toda dependencia declare su tipo; FR-02 convierte un tipo ausente o fuera de enum en FAIL de `validate`; NFR-06 prohíbe rutas absolutas en el manifest. El manifest se valida al inicio de todo verbo contra `contracts/dependencias-manifest.schema.json`.

**Ciclo de vida**: se edita solo a mano o por `apply` de actualización; nunca lo escribe `generate`.

---

## 2. `ExternalDependency`

**Campos comunes**

| Campo | Tipo | Obligatorio | Validación |
|---|---|---|---|
| `nombre` | string | Sí | `^[a-zA-Z0-9._-]+$`, único en el manifest |
| `tipo_provisionamiento` | enum | Sí | uno de `kit-integrado`, `kit-fuente`, `mcp-workspace`, `mcp-build-local`, `entorno` |
| `requerido` | boolean | Sí | si `true` y falta ⇒ exit code ≠ 0; si `false` y falta ⇒ WARN (FR-12) |
| `ruta_local` | string relativa | Solo clones | debe empezar por `proyect_ext/`; sin unidad ni `\\` inicial (FR-13, NFR-06) |
| `repo_url` | string URL | Solo clones | `^https://` |
| `rama_seguida` | string | Solo clones | no vacío; admite `main`, `master` o tag fijado |
| `gestor` | enum | Solo `mcp-workspace` | `npm`, `pypi`, `uv` |
| `paquete` | string | Solo `mcp-workspace` | no vacío |
| `comando` | string | MCP y entorno | nombre resolubre en `PATH` o ruta relativa |
| `version.autoridad` | enum | Sí | `branch-head` (clones), `gestor-paquetes` (mcp-workspace), `release+artefacto` (mcp-build-local), `runtime` (entorno) |
| `version.archivo_local` | string | No | ruta relativa dentro del clon |
| `version.campo_local` | string\|null | No | nombre de campo si el archivo es JSON/YAML |
| `version.upstream_api` | string URL\|null | No | endpoint de consulta de última versión |

**Reglas por tipo** (una fila por tipo, sin ramas implícitas):

| Tipo | Campos exigidos además de los comunes | Autoridad de versión admitida |
|---|---|---|
| `kit-integrado` | `repo_url`, `rama_seguida`, `ruta_local` | `branch-head` |
| `kit-fuente` | `repo_url`, `rama_seguida`, `ruta_local` | `branch-head` |
| `mcp-workspace` | `gestor`, `paquete`, `comando`, `version.upstream_api` | `gestor-paquetes` |
| `mcp-build-local` | `repo_url`, `ruta_local`, `comando`, `version.archivo_local` (artefacto) | `release+artefacto` |
| `entorno` | `comando` | `runtime` |

**Validación cruzada**: la autoridad declarada debe corresponder al tipo; una combinación distinta es FAIL nombrando la dependencia y el campo (FR-03).

---

## 3. `ProvisioningState`

**Archivo**: `.opencode/mcp-state.json` (no versionado, escritura atómica temporal + reemplazo, NFR-03).

**Campos por entrada**

| Campo | Tipo | Obligatorio | Origen |
|---|---|---|---|
| `tipo` | enum de cinco valores | Sí | manifest |
| `requerido` | boolean | Sí | manifest (persistido para no depender del contexto de ejecución, FR-12) |
| `comando_resuelto` | string (ruta absoluta) | No | sonda; ausente si no resuelve |
| `version_instalada` | string\|null | No | sonda |
| `version_ultima` | string\|null | No | sonda remota |
| `fuente` | string | No | registro o `repo_url` consultado |
| `estado` | enum | Sí | ver transiciones |
| `ultimo_check` | ISO8601 | Sí | reloj de la máquina |
| `rama_seguida` | string | Solo clones | manifest |
| `ultimo_sha` | string (7-40 hex) | Solo clones | `git rev-parse HEAD` |
| `sha_remoto` | string (7-40 hex) | Solo clones | `git ls-remote` |

**Estados admitidos**: `ok`, `al-dia`, `desactualizado`, `missing`, `degraded`, `desconocido`, `absent`. Cualquier otro valor es inválido y hace fallar la lectura del estado.

**Transiciones válidas**

```text
(inexistente) --validate--> absent        (config del arnés no existe)
(inexistente) --validate--> missing       (dependencia requerida no instalada)
absent/missing --apply----> ok            (instalación o build correcto)
ok --validate-------------> al-dia        (clon: SHA local == SHA remoto)
ok --validate-------------> desactualizado (clon: SHA distinto / paquete con versión nueva)
ok --validate-------------> desconocido   (sin red o sonda indeterminada)
missing --apply-----------> degraded      (fallo de instalación con causa)
ok --apply---------------> degraded       (build local falla o artefacto no existe)
degraded --apply----------> ok            (reintento exitoso)
```

Ninguna transición produce `ok` sin evidencia (NFR-05). `validate` es el único verbo que escribe el estado por defecto (FR-06, NFR-01).

---

## 4. `McpServerConfig`

**Archivos**: `opencode.json` (`mcp.servers.<nombre>`) y `.vscode/mcp.json` (generado desde la misma fuente). Ninguno se versiona (D2, FR-10, ADR-0014).

| Campo | Tipo | Obligatorio | Validación |
|---|---|---|---|
| `type` | string | Sí | exactamente `"stdio"` (D5, FR-11) |
| `command` | string | Sí | debe resolver en el momento de generar (FR-08) |
| `args` | array string | No | sin rutas absolutas cuando el comando es resolubre por nombre |
| `env` | object string→string | No | solo nombres de variable y referencias `{env:VAR}`; nunca secretos (NFR-04) |
| `enabled` | boolean | No | por defecto `true` |

**Regla dura**: una dependencia con `estado` `missing` o `degraded` no se emite; se emite WARN con nombre y comando declarado. La forma plana `mcp.<nombre>` es legacy y `validate` la reporta como FAIL con ruta y línea (FR-11, SC-008).

**Idempotencia**: dos `generate` consecutivos producen archivos byte a byte idénticos (NFR-02, SC-003); el generador preserva las claves de usuario que no son `mcp.servers` (FR-10).

---

## 5. `CapabilityMatrix`

**Archivo**: `Documentacion/Agents_IA_TECH/capacidades-por-harness.md` (versionado, FR-15).

**Columnas obligatorias**

| Columna | Tipo | Validación |
|---|---|---|
| `capacidad` | string | no vacía; única por fila |
| `mecanismo_opencode` | string | `no-soportado` si no existe |
| `mecanismo_copilot` | string | `no-soportado` si no existe |
| `estado` | enum | `soportado`, `equivalente-distinto`, `soportado-con-limite`, `no-soportado` |
| `fuente` | string URL o referencia | obligatoria; sin fuente la fila no entra |
| `version_verificada` | string | versión del arnés o del tool donde se verificó |
| `prueba` | string | vacía = en trabajo; completa = corregida |
| `spec_responsable` | string `NNN` o vacío | vacío ⇒ WARN (inconsistencia documentada sin dueño) |

**Capacidades iniciales obligatorias (4)**: `subagentes/delegación`, `hooks/eventos de sesión`, `permisos de escritura por path`, `skills por frontmatter`.

**Estado deducido** (no se guarda en columna propia, FR-15):

| `spec_responsable` | `prueba` | Estado deducido | Acción del validador |
|---|---|---|---|
| vacío | cualquiera | Documentada, sin spec que la corrija | WARN |
| con valor | vacía | En trabajo | sin acción |
| con valor | completa | Corregida | sin acción |

**Reglas del validador**: capacidad usada por un agente y ausente de la matriz ⇒ FAIL; fila con estado `no-soportado` no se emite como clave en la configuración generada y se reporta WARN, nunca en silencio (FR-15.4).

---

## Invariantes globales

1. Todo `estado: ok` tiene evidencia de sonda en la misma corrida (NFR-05).
2. Ningún artefacto versionado contiene ruta absoluta de máquina (NFR-06, SC-007).
3. Ningún artefacto generado ni estado contiene tokens, claves o rutas de credenciales (NFR-04).
4. `generate` no escribe una entrada cuyo `command` no resuelve (FR-08).
5. `validate` no escribe configuración ni clones (NFR-01).
6. El conjunto de nombres de servidor de `opencode.json` y `.vscode/mcp.json` es idéntico, salvo diferencia justificada por la matriz (FR-09, SC-004).
