# Threat Model — Feature `007-mcp-token-resolution`

**Feature Branch**: `007-mcp-token-resolution`
**Agente**: `security-auditor`
**Metodología**: STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)
**Alcance**: parte de seguridad de `speckit-analyze` para la feature 007 del kit.
**Ámbito**: ESTE proyecto (el kit). El threat model es **genérico para cualquier proyecto consumidor**; no referencia, nombra ni documenta ningún otro proyecto.

---

## 1. Resumen ejecutivo

La feature 007 resuelve tokens MCP (`__*_CMD__` / `{env:...}`) en `opencode.json`, introduce `.env.mcp` por proyecto y agrega dos capacidades que ejecutan **código de terceros o del maestro**: `-ForceUpgradeTools` (instala/actualiza paquetes) y `Update-Self` (clona el maestro, sobrescribe el propio `.ps1` y lo re-ejecuta). Estas dos últimas concentran el riesgo real de la feature (supply chain y ejecución de código arbitrario). El resto son riesgos de integridad de configuración (parche del JSON) y de divulgación de estructura local (`.env.mcp`).

**Veredicto**: la feature es **aprobable** con los controles no negociables de la sección 7. Todo el diseño ya opta por **fail-open + WARN**, acotado y con allowlist; el riesgo residual se acepta explícitamente cuando el operador pasa los flags opt-in (`-ForceUpgradeTools`) y confía en la allowlist de self-update.

---

## 2. Superficies de ataque

### 2.1 `.env.mcp` (por proyecto, gitignored)

- **Contenido**: rutas absolutas locales (`CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`). **No son secretos**, pero revelan estructura del sistema de archivos del host (nombres de usuario, unidades, ubicaciones).
- **Riesgo**: commitearlo accidentalmente → divulgar la disposición local del entorno en el repositorio versionado.
- **Mitigación**: `.gitignore` con `.env.mcp` + verificación (`git check-ignore .env.mcp` → exit 0). La plantilla versionada **nunca** contiene rutas absolutas (solo tokens / `{env:...}`).

### 2.2 `-ForceUpgradeTools` (supply chain)

- **Contenido**: instala/actualiza paquetes de terceros (`context-mode`, `codebase-memory-mcp`, `markitdown`, `graphifyy[mcp]`) y ejecuta build de tokenslayer.
- **Riesgo**: paquete comprometido, typosquatting, ejecución de código en el host durante `npm install`/`pip install`/`uv tool install`/`npm run build`.
- **Mitigación**: solo fuentes oficiales publicadas (npm/pip/uv) con nombres exactos y conocidos; **fail-open con WARN** (un fallo no aborta); **no auto-ejecutar** builds de terceros fuera de la ruta controlada; el flag es **opt-in** (por defecto no se instala nada).

### 2.3 `Update-Self` (auto-actualización del bootstrap)

- **Contenido**: clon shallow del maestro → compara SHA256 del propio `.ps1` → si difiere, sobrescribe el local y **re-ejecuta** preservando `$PSBoundParameters`.
- **Riesgo**: MITM del repo o maestro comprometido → sobrescritura del `.ps1` y **ejecución de código arbitrario** en el host.
- **Mitigación**: HTTPS; **allowlist** de URL del maestro (`Test-TrustedGithubUrl`); comparación **SHA256**; **fail-open** (sin red → WARN, sigue local); escape `-SkipSelfUpdate`; auto-skip cuando el repo local ES el kit maestro.

### 2.4 `{env:...}` en `opencode.json`

- **Contenido**: interpolación de variables de entorno en el comando MCP. Si la variable no está seteada → **string vacío** → MCP con comando vacío.
- **Riesgo**: fallo silencioso (MCP no arranca, confusión operacional, falso "resuelto").
- **Mitigación**: fallback a **ruta real** / campo `environment` del MCP local + **WARN** accionable; en ningún caso queda un token `__*_CMD__` sin resolver.

### 2.5 Parche quirúrgico del JSON (`opencode.json`)

- **Contenido**: re-resolución incondicional que parchea entradas `mcp` sobre un JSON existente.
- **Riesgo**: corromper `opencode.json` y perder claves ajenas (`permission`, `providers`, `model`, `region`, `plugin`).
- **Mitigación**: **idempotencia** (múltiples corridas → mismo bloque); **backup** previo; **validación JSON post-escritura**; parche por entrada limitado a `command`/`enabled` (preserva el resto).

---

## 3. Análisis STRIDE

| Superficie | S | T | R | I | D | E |
|------------|---|---|---|---|---|---|
| `.env.mcp` | — | Commit accidental de rutas resueltas | — | **Divulgación de estructura local** (Alta probabilidad, Bajo impacto) | — | — |
| `-ForceUpgradeTools` | **Typosquatting / paquete suplantado** | Paquete comprometido modifica el entorno | Trazabilidad limitada del upgrade | Instalación de código malicioso | Fallo de red/permisos (fail-open evita DoS) | **Ejecución de código en el host** (build/install) |
| `Update-Self` | **MITM / maestro suplantado** | `.ps1` sobrescrito con contenido no confiable | Sin firma del artefacto (solo SHA256 del clon) | — | Clon fallido (fail-open evita DoS) | **Ejecución de código arbitrario** tras re-ejecución |
| `{env:...}` | — | Var no seteada → comando vacío | Estado MCP ambiguo | Fallo silencioso | MCP no disponible | — |
| Parche JSON | — | Corrupción de `opencode.json` | Sin backup → pérdida de config | — | Config rota | — |

**Mapeo a controles**: las celdas de mayor severidad (S/E en `-ForceUpgradeTools` y `Update-Self`) se mitigan con fuentes oficiales, allowlist, HTTPS y SHA256. Las de T/I en `.env.mcp` y JSON se mitigan con `.gitignore`, backup y validación.

---

## 4. Riesgos etiquetados `security-risk:`

| `security-risk:` | Severidad | Superficie | Descripción | Mitigación | Control |
|------------------|-----------|-----------|-------------|------------|---------|
| `security-risk: env-mcp-commit` | **Media** | `.env.mcp` | Commit accidental de rutas absolutas locales → revela estructura del host. | `.env.mcp` en `.gitignore` + `git check-ignore .env.mcp` (exit 0); plantilla versionada sin rutas absolutas. | CN-1, CN-2 |
| `security-risk: env-mcp-empty-var` | **Media** | `{env:...}` | Var no seteada → string vacío → MCP con comando vacío (fallo silencioso). | Fallback a ruta real / `environment` + WARN accionable; nunca dejar token irresoluble. | CN-3 |
| `security-risk: force-upgrade-supply-chain` | **Alta** | `-ForceUpgradeTools` | Paquete de terceros comprometido / typosquatting durante install o build. | Solo fuentes oficiales publicadas con nombres exactos; fail-open con WARN; opt-in por defecto. | CN-4, CN-5 |
| `security-risk: force-upgrade-auto-build` | **Media** | `-ForceUpgradeTools` | Ejecución de `npm install && npm run build` de terceros sin confirmación. | No auto-ejecutar builds de terceros fuera del clon conocido; fail-open; reporte OK/WARN por herramienta. | CN-5 |
| `security-risk: self-update-mitm` | **Alta** | `Update-Self` | MITM del repo o maestro comprometido → sobrescritura del `.ps1` y ejecución de código arbitrario. | HTTPS + allowlist `Test-TrustedGithubUrl` + SHA256 + fail-open + `-SkipSelfUpdate` + auto-skip en kit. | CN-6, CN-7 |
| `security-risk: json-patch-corruption` | **Media** | Parche JSON | Parche no idempotente corrompe `opencode.json` y pierde `permission`/`providers`. | Parche por entrada (`command`/`enabled`); backup previo; validación JSON post-escritura; idempotencia (2 corridas = 1). | CN-8, CN-9 |
| `security-risk: tokenslayer-path-escape` | **Baja** | tokenslayer | Ruta de tokenslayer fuera del containment (con `..` o externa) permitiría ejecutar un binario ajeno. | Containment-check existente: ruta bajo `<root>/proyect_ext/tokenslayer/`, sin `..` (RNF-07). | CN-10 |
| `security-risk: config-secret-disclosure` | **Media** | Credenciales | Exposición de credenciales/API keys de la config del entorno. | `.opencode/config.json` y `.env.mcp` gitignored; sin credenciales en la plantilla versionada; sin secretos en el reporte final (solo rutas locales). | CN-1, CN-11 |

**Convención de severidad**: Alta = ejecución de código o compromiso del host; Media = integridad/divulgación con impacto acotado y controlable; Baja = escape de containment ya mitigado por diseño.

---

## 5. Fallos silenciosos → trazas observables

Todo fallo degrada con **WARN** y deja traza (alineado con Principio V, Observabilidad):

- MCP con `enabled: false` **siempre** acompañado de causa (token sin resolver, herramienta ausente, `{env}` irresoluble).
- Reporte final imprime el bloque `mcp` resultante + `enabled` + razón por entrada (solo rutas locales, **sin secretos**).
- Upgrades y self-update reportan OK/WARN por ítem; un fallo **nunca** aborta el bootstrap (fail-open).

---

## 6. Riesgo residual aceptado

- Con `-ForceUpgradeTools` activado y red disponible, el host ejecutará código de paquetes de terceros: el riesgo se **acepta** por ser opt-in y limitado a fuentes oficiales conocidas.
- `Update-Self` confía en la allowlist del maestro y en la integridad del repo remoto por HTTPS. La ausencia de **firma criptográfica** del artefacto (más allá de SHA256 del propio clon) se **acepta** como límite conocido; mitigado con `-SkipSelfUpdate` y auto-skip en el kit.

---

## 7. Controles no negociables (alineados con Art. V de la Constitution)

- **CN-1** — `.env.mcp` y `.opencode/config.json` **DEBEN** estar en `.gitignore` y **NUNCA** commitearse.
- **CN-2** — La plantilla versionada (`opencode.json`) **NO DEBE** contener rutas absolutas de la PC (solo tokens / `{env:...}`).
- **CN-3** — Ninguna entrada MCP puede quedar con token irresoluble: `{env:...}` sin valor efectivo **DEBE** caer a ruta real/`environment` + WARN.
- **CN-4** — `-ForceUpgradeTools` **DEBE** operar solo con nombres exactos de paquetes oficiales publicados (npm/pip/uv); sin auto-instalación por defecto.
- **CN-5** — Instalaciones y builds **DEBEN** ser fail-open: fallo → WARN + continuar; nunca abortar el bootstrap.
- **CN-6** — `Update-Self` **DEBE** validar la URL del maestro contra allowlist (`Test-TrustedGithubUrl`) sobre HTTPS y comparar **SHA256** antes de sobrescribir.
- **CN-7** — `Update-Self` **DEBE** soportar `-SkipSelfUpdate` y auto-saltarse cuando el repo local ES el kit maestro.
- **CN-8** — El parche de `opencode.json` **DEBE** ser quirúrgico (solo `command`/`enabled`) y **preservar** `permission`, `providers`, `model`, `region`, `plugin`.
- **CN-9** — El bootstrap **DEBE** ser idempotente: dos corridas consecutivas producen un bloque `mcp` equivalente (0 duplicados, 0 corrupción).
- **CN-10** — Las rutas de tokenslayer **DEBEN** quedar bajo `<root>/proyect_ext/tokenslayer/`, sin `..` ni rutas externas (RNF-07).
- **CN-11** — El reporte final **NO DEBE** incluir secretos; solo rutas locales y estado `enabled`.

---

## 8. Checklist de verificación de seguridad (para el cierre de la feature)

- [ ] `git check-ignore .env.mcp` → exit 0 (CN-1).
- [ ] `Select-String -Pattern 'C:\\|/Users/'` sobre la plantilla `opencode.json` → sin coincidencias (CN-2).
- [ ] Bloque `mcp` tras 2 corridas consecutivas: equivalente, 0 tokens `__*_CMD__`, 0 `{env:...}` irresoluble (CN-3, CN-9).
- [ ] Con `-ForceUpgradeTools` sin red: WARN por herramienta y bootstrap continúa (CN-4, CN-5).
- [ ] `Update-Self` con repo/URL no allowlisted: no clona (CN-6); con `-SkipSelfUpdate` o en el kit: no intenta (CN-7).
- [ ] Diff de `opencode.json` limitado al bloque `mcp`; `permission`/`providers`/`model`/`region`/`plugin` intactos (CN-8).
- [ ] Containment de tokenslayer verificado bajo `proyect_ext/tokenslayer/` (CN-10).
- [ ] Reporte final sin secretos; toda entrada `enabled: false` con causa (CN-11, Principio V).
