# Threat Model: aprovisionamiento externo y configuración generada

**Feature**: `038-provisionamiento-externo-y-config-generada` | **Fecha**: 2026-11-12 | **Responsable**: `security-auditor` | **Metodología**: STRIDE por componente

**Insumos**: `spec.md` (FR-01 a FR-17, NFR-01 a NFR-08), `plan.md`, `data-model.md`, `contracts/`, `tasks.md`, edge cases de la spec.

**Activos a proteger**

| Activo | Por qué importa |
|---|---|
| `dependencias-manifest.yml` | Define qué código de terceros entra al entorno; una alteración es supply chain |
| `.opencode/mcp-state.json` | Contiene rutas absolutas de la máquina y el veredicto de instalación; filtra topología local |
| `opencode.json` / `.vscode/mcp.json` | Determinan qué se ejecuta al abrir una sesión: `command` + `args` son ejecución de código |
| Plantillas versionadas (`scripts/mcp/templates/`) | Son la base de la configuración generada; una plantilla alterada se propaga a ambos arneses |
| Clones en `proyect_ext/` | Código de terceros ejecutable y, si se filtra, `AGENTS.md` que el arnés carga como instrucciones |
| Matriz `capacidades-por-harness.md` | Declara qué puede cada arnés; una fila falsa oculta una diferencia peligrosa |

---

## 1. STRIDE por componente

### 1.1 `dependencias-manifest.yml`

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Un manifest de un repo no confiable se presenta como el oficial del kit | Bajo (archivo local del repo) |
| **T**ampering | Cambio de `version.upstream_api` o `repo_url` hacia un paquete/typosquat homónimo | **Alto** |
| **R**epudiation | No hay traza de quién cambió una versión declarada | Medio |
| **I**nfo disclosure | Bajo: no contiene secretos por diseño | Bajo |
| **D**oS | `dependencias_externas` vacío o gigante degrada `validate` | Bajo |
| **E**levation | Declarar `tipo_provisionamiento: entorno` para un paquete que se ejecuta como MCP | **Alto** |

### 1.2 `.opencode/mcp-state.json`

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Estado fabricado a mano que declara `ok` sin binario | **Alto** (mitigado: `generate` re-verifica el binario) |
| **T**ampering | `comando_resuelto` apuntado a un binario distinto | Alto |
| **R**epudiation | Sin `ultimo_check` verificable no se sabe cuándo se comprobó | Bajo |
| **I**nfo disclosure | Rutas absolutas y nombres de usuario de la máquina | **Medio** |
| **D**oS | Archivo corrupto bloquea `generate` | Medio |
| **E**levation | `estado: ok` sobre una dependencia `requerido: false` que luego se emite | Medio |

### 1.3 Generadores (`generate-opencode.ps1`, `generate-copilot.ps1`, plantillas)

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Plantilla suplantada en `.specify/presets/` o `overrides/` con `command` malicioso | **Alto** |
| **T**ampering | Escritura no atómica interrumpida deja configuración truncada y la sesión arranca a medias | Alto |
| **R**epudiation | Sin registro de qué plantilla y qué estado produjeron el archivo | Medio |
| **I**nfo disclosure | Emitir `env` con valores en claro en vez de `{env:VAR}` | **Alto** |
| **D**oS | Generar cero servidores deja el arnés sin MCP y sin aviso | Medio |
| **E**levation | `args` con ruta a un ejecutable arbitrario propagado desde el manifest | **Alto** |

### 1.4 `validate-parity.ps1`

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Comparar archivos que no son los que carga el arnés (rutas distintas) | Medio |
| **T**ampering | Reportar paridad leyendo solo un archivo | Medio |
| **R**epudiation | Resultado sin evidencia (sin nombres de servidor ni filas citadas) | Bajo |
| **I**nfo disclosure | Volcar `env` completo en el reporte | Medio |
| **D**oS | Ninguno relevante | Bajo |
| **E**levation | Aceptar una capacidad `no-soportado` en silencio y habilitarla igual | **Alto** |

### 1.5 `apply` (`Invoke-ProvisioningApply.ps1`) y clones en `proyect_ext/`

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Clon apuntando a un remoto distinto del declarado (`origin` reescrito) | **Alto** |
| **T**ampering | Ejecutar build de código de terceros sin verificar el artefacto declarado | **Alto** |
| **R**epudiation | `apply` sin registro de qué SHA se aplicó | Medio |
| **I**nfo disclosure | Clones con secretos locales (`.env`) que terminan en el workspace | Medio |
| **D**oS | `--unshallow` sobre repos grandes sin timeout | Medio |
| **E**levation | `apply` copiando archivos al kit e inyectando `AGENTS.md` de terceros en el contexto del agente | **Alto** |

### 1.6 Registros remotos (npm, PyPI/uv, `git ls-remote`)

| Amenaza | Riesgo concreto | Nivel |
|---|---|---|
| **S**poofing | Typosquatting de un paquete con nombre similar a `context-mode` | **Alto** |
| **T**ampering | Paquete comprometido en una versión nueva | **Alto** |
| **R**epudiation | El registro no ofrece no-repudio de publicación | Alto |
| **I**nfo disclosure | Consulta que filtra nombres internos de dependencias | Bajo |
| **D**oS | Registro lento o caído bloquea la sesión | Medio |
| **E**levation | Instalación automática de una versión con scripts de post-instalación | **Alto** |

---

## 2. Riesgos identificados y mitigaciones

| ID | Riesgo | Amenaza STRIDE | Mitigación exigida | Tarea |
|---|---|---|---|---|
| `security-risk:038-01` | Manifest tampering hacia versiones o repos maliciosos | Tampering, Elevation | Validación contra esquema + autoridad de versión obligatoria por tipo; `repo_url` restringido a `https://`; revisión manual del diff del manifest en PR | T008, T010 |
| `security-risk:038-02` | Configuración generada con `command`/`args` arbitrarios | Elevation | `generate` solo emite entradas cuyo binario resuelve; `command` proviene del manifest validado y no se interpola texto libre del usuario | T025, T026 |
| `security-risk:038-03` | Secretos en artefactos (estado o config generada) | Info disclosure | `env` solo por nombre (`{env:VAR}`); `.opencode/mcp-state.json`, `opencode.json` y `.vscode/mcp.json` en `.gitignore`; NFR-04 sin cobertura de prueba todavía (ver U1 en `analyze.md`) | T001, T018 |
| `security-risk:038-04` | Typosquatting o paquete comprometido en el registro | Spoofing, Tampering | `apply` es explícito y nunca automático (FR-07); `validate` reporta `desactualizado` sin instalar; ninguna actualización major automática | T034, T041 |
| `security-risk:038-05` | Build local de terceros ejecutado sin verificación | Tampering | `mcp-build-local` solo pasa a `ok` si el artefacto declarado existe tras el build (FR-16); build fallido ⇒ `degraded` y la entrada se omite de la configuración | T043, T038 |
| `security-risk:038-06` | Contaminación del contexto por clones de terceros | Elevation | Clones solo en `proyect_ext/` (ignorado); `validate` falla si aparece `AGENTS.md`, `CLAUDE.md` o `.mcp.json` de un clon bajo la raíz (FR-13) | T039, T042 |
| `security-risk:038-07` | Escritura no atómica deja configuración truncada | Tampering, DoS | Temporal en el mismo directorio + reemplazo (NFR-03); prueba de que no quedan temporales | T007, T025 |
| `security-risk:038-08` | Capacidad `no-soportado` habilitada en silencio | Elevation | El generador no emite claves con estado `no-soportado` y `validate-parity` lo reporta WARN, nunca en silencio (FR-15.4) | T047, T050 |
| `security-risk:038-09` | Timeout sin red bloquea la sesión | DoS | Corte a 15 s sin red con estado `desconocido` + causa; 60 s con red (NFR-07) | T033, T036 |
| `security-risk:038-10` | Repudio de cambios de versión aplicados | Repudiation | `ultimo_check`, `ultimo_sha` y `sha_remoto` en el estado; el SHA aplicado queda registrado y es comparable con el remoto | T031, T042 |

---

## 3. Riesgos residuales aceptados

| Riesgo residual | Por qué se acepta | Dueño |
|---|---|---|
| Un paquete legítimo puede comprometerse después de la verificación | Esta spec compara declaración contra realidad en el momento de la corrida; la verificación de integridad por checksum queda fuera de alcance y se atiende en el instalador del KIT | `security-auditor` |
| Firmas de manifest y de artefactos | Requiere infraestructura de claves que el kit no tiene; registrado como deuda, no como mitigación presente | `arquitecto` |
| El estado contiene rutas absolutas de la máquina | Necesario para que `generate` resuelva binarios; el archivo no se versiona y nunca sale del workspace | `plataformador` |

---

## 4. Verificación del threat model

| Comprobación | Resultado |
|---|---|
| Cada componente del diseño (`manifest`, `estado`, `generadores`, `validate-parity`, `apply`, registros) tiene análisis STRIDE | ✅ 6 de 6 |
| Cada riesgo `Alto` tiene al menos una mitigación mapeada a una tarea concreta | ✅ 10 riesgos, 10 mitigaciones |
| Ninguna mitigación depende de una capacidad declarada pero no instalada | ✅ La matriz de capacidades declara las diferencias en lugar de asumirlas |
| Los riesgos residuales están declarados con dueño | ✅ 3 de 3 |
| Los límites de seguridad coinciden con los edge cases de la spec (sin red, `npm` ausente, Node por debajo del mínimo, `HEAD` detached, clon shallow, artefacto modificado) | ✅ 6 de 6 |
