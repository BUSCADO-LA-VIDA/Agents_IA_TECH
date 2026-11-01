Conclusión primero: **La Spec 018, tal como está, no debe implementarse. Contiene un error fundamental que hace que todo el diseño sea inviable.**

La documentación oficial de OpenCode y los issues de la comunidad confirman tres hechos que invalidan las suposiciones centrales de la Spec:

1. **La delegación anidada (Nivel 2 y 3) está rota en OpenCode.** El issue #8114 demuestra que, tras la refactorización de permisos, **ningún subagente puede invocar otros subagentes**, independientemente de la configuración de `permission: { task: "allow" }` . Esto invalida directamente los FR-004, FR-005, FR-006, FR-007 y FR-012.

2. **El orden de las reglas de permisos es crítico y contraintuitivo.** La documentación oficial confirma que las reglas se evalúan de arriba hacia abajo y **la última regla que coincide es la que gana** . Un `"*": deny` colocado al final anula todas las reglas de lista blanca anteriores .

3. **El Pensador no necesita `bash` para ejecutar Speckit.** Dar `bash` al Pensador abre la misma puerta de bypass que intentas cerrar. Agent-SSD existe precisamente para ejecutar comandos.

---

## Versión corregida de la Spec (para pegar en el archivo)

```
# Spec 018: Pensador Delegation and Permission Fix (v2)

**Version**: 2.0
**Date**: 2026-09-26
**Status**: Draft (corregido tras análisis de documentación oficial de OpenCode)
**Feature Directory**: `Documentacion/Agents_IA_TECH/specs/018-pensador-delegation-fix/`

---

## Documentación oficial de referencia (consultar OBLIGATORIAMENTE antes de implementar)

| Recurso | URL | Relevancia |
|---------|-----|-----------|
| OpenCode Agents | https://opencode.ai/docs/agents/ | Definición de primary agents vs subagents, modo, configuración Markdown/JSON  |
| OpenCode Permissions | https://opencode.ai/docs/permissions/ | Sintaxis de reglas granulares, orden de evaluación (último match gana), wildcards, lista de permisos disponibles  |
| OpenCode Config (subagent_depth) | https://opencode.ai/docs/config/ | Límite de profundidad de delegación anidada. Default: 1  |
| Issue #8114 | https://github.com/anomalyco/opencode/issues/8114 | Bug confirmado: `task: allow` no funciona en subagentes anidados  |
| Issue #28879 | https://github.com/anomalyco/opencode/issues/28879 | Bug: archivos `.md` de agentes en `modes/` fuerzan `mode: primary`, ignorando `mode: subagent`  |

**Nota crítica para el implementador**: Antes de editar cualquier frontmatter, verificar la versión de OpenCode. Ejecutar `opencode --version`. Si la versión es >= v1.1.15, el bug #8114 está presente y **ningún subagente puede delegar a otro subagente**. El diseño debe asumir **delegación de UN SOLO NIVEL** (Pensador → todos los demás).

---

## Cambios respecto a v1.0

| Sección | Cambio | Razón |
|---------|--------|-------|
| FR-003 | **ELIMINADO**. Pensador NO tiene bash para Speckit | `bash` permite bypass de `edit: deny`. Agent-SSD ejecuta Speckit. |
| FR-004/005/006 | **ELIMINADOS**. Documentales mantienen `task: deny` | Violan "cada agente hace UNA cosa". Son hojas ejecutoras. |
| FR-007 | **MODIFICADO**. Agent-SSD mantiene `task: deny` | La delegación anidada no funciona (issue #8114). Pensador invoca secuencialmente. |
| FR-012 | **MODIFICADO**. Profundidad = 1 (delegación plana) | `subagent_depth: 2+` no funciona por issue #8114. |
| FR-014 | **MODIFICADO**. Verificación obligatoria en prompts, no en sistema | No hay mecanismo de harness para verificar escritura. |

---

## Introducción (actualizada)

El kit define 14 agentes en 5 tiers. El análisis reveló que el diseño original asumía una **cadena de delegación anidada** (Pensador → Agent-SSD → Arquitecto) que **es inviable en OpenCode** debido a limitaciones confirmadas de la plataforma.

**Restricción arquitectónica fundamental**:
- **Delegación de un solo nivel**: El Pensador es el único orquestador que usa `task`. Todos los demás agentes son **hojas ejecutoras** con `task: deny`.
- **El Pensador invoca secuencialmente**: Para ejecutar Specify → Plan → Tasks, el Pensador llama a Agent-SSD tres veces (una por fase). No hay delegación en cadena.

---

## User Stories (corregidas)

### US1 — Pensador como Único Orquestador
El Pensador es el único agente que puede usar `task`. Invoca agentes de forma **secuencial y plana**: Agent-SSD (SpecKit), arquitecto (ADRs), security-auditor (threat model), documentador (converge), implementadores.

### US2 — Agentes Documentales como Hojas Ejecutoras
Arquitecto, documentador y security-auditor **NO delegan**. Reciben una tarea del Pensador, la ejecutan, y devuelven el control. Si necesitan input de otro documental, lo solicitan al Pensador (quien decide la siguiente invocación).

### US3 — Agent-SSD como Ejecutor de Speckit
Agent-SSD ejecuta comandos Speckit (`speckit-specify`, `speckit-plan`, etc.) y escribe los artefactos. **No delega**. El Pensador lo invoca una vez por fase.

### US4 — Consistencia Cross-Harness
La matriz de permisos para los 14 agentes es idéntica entre `.github/agents/` y `.opencode/agent/`.

### US5 — Fail-Closed y Verificación Real
Ningún agente reporta "creado/verificado" sin leer el archivo después de escribirlo (`Test-Path` + `Get-Content`). Si falla, reporta el error explícitamente.

---

## Functional Requirements (corregidos)

### FR-001: Pensador — Solo Orquestación
Pensador MUST tener:
```yaml
permission:
  edit:
    "*": deny
  task:
    "*": deny
    "Agent-SSD": allow
    "api-developer": allow
    "frontend-developer": allow
    "devops": allow
    "qa-senior": allow
    "gitflow": allow
    "plataformador": allow
    "solucionador": allow
    "arquitecto": allow
    "documentador": allow
    "security-auditor": allow
  bash:
    "*": ask
    "git status*": allow
    "git log*": allow
    "git diff*": allow
    "rg *": allow
    "grep *": allow
    "Get-Content *": allow
    "Get-ChildItem *": allow
    "Test-Path *": allow
  read:
    "*": allow
```
**Pensador NO tiene `bash` para Speckit.** Esa capacidad es de Agent-SSD.
**Pensador NO tiene `write`/`edit`.** El tool no debe existir en su contexto (si OpenCode lo soporta, usar `tools: { write: false, edit: false }`).

### FR-002: Pensador Delegación Secuencial
Pensador MUST invocar agentes **de uno en uno**, esperando el resultado antes de invocar el siguiente. No hay delegación en paralelo desde el Pensador hacia el mismo pipeline.

### FR-003: Agent-SSD — Ejecutor de Speckit
Agent-SSD MUST tener:
```yaml
permission:
  edit:
    "*": deny
    "src/*/.specify/**": allow
    "Documentacion/**/specs/**": allow
    ".github/**": allow
    ".opencode/**": allow
  bash:
    "*": deny
    "pwsh *resolve-template*": allow
    "pwsh *.specify/scripts/*": allow
    "powershell *resolve-template*": allow
    "powershell *.specify/scripts/*": allow
    "Get-Content *": allow
    "Get-ChildItem *": allow
    "Test-Path *": allow
  task:
    "*": deny
  read:
    "*": allow
```
Agent-SSD **NO delega**. Ejecuta Speckit y reporta al Pensador.

### FR-004: Agentes Documentales — Hojas Ejecutoras
Arquitecto, documentador y security-auditor MUST tener:
```yaml
permission:
  edit:
    "*": deny
    "Documentacion/**": allow
    ".github/**": allow
    "**README.md": allow
  bash:
    "*": deny
  task:
    "*": deny
  read:
    "*": allow
```
**Sin `task`.** Son hojas. Si necesitan algo de otro documental, lo piden al Pensador.

### FR-005: Implementadores — Escritura Acotada a su Dominio
Cada implementador MUST tener edit restringido a su dominio:
- `api-developer`: `src/**`, `tests/**`
- `frontend-developer`: `src/**`, `tests/**`
- `devops`: `src/**`, `tests/**`, configs de infra
- `qa-senior`: `tests/**`, `Documentacion/**/pendientes-implementacion.md`

Todos con `task: "*": deny`.

### FR-006: Cross-Harness Consistency
La matriz de permisos (edit, task, bash, read) para los 14 agentes MUST ser idéntica entre `.github/agents/<agent>.md` y `.opencode/agent/<agent>.md`.

### FR-007: Verificación Obligatoria de Escritura (Fail-Closed)
Todo agente que escriba un archivo MUST:
1. Después de escribir, ejecutar `Test-Path <ruta>`.
2. Si `Test-Path` es `False`, reportar "ERROR: archivo no creado" y NO continuar.
3. Si `True`, ejecutar `Get-Content <ruta>` y confirmar que el contenido es el esperado.
4. Si el contenido está vacío o es incorrecto, reportar "ERROR: contenido incorrecto" y NO continuar.
5. Solo si ambas verificaciones pasan, reportar "creado y verificado".

**Esta regla MUST estar en el prompt de cada agente que escribe.** No hay enforcement de sistema posible.

### FR-008: Subagent Depth = 1
`opencode.json` MUST tener `"subagent_depth": 1` (default). No intentar configurar 2+.

---

## Non-Functional Requirements

### NFR-001: Separación de Tiers por Permisos
- Documentales (Pensador, Agent-SSD, arquitecto, documentador, security-auditor): NO escriben en `src/` excepto Agent-SSD en `src/*/.specify/`.
- Implementadores: NO escriben en `Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`.

### NFR-002: Allowlists Explícitas
`task` y `bash` MUST usar allowlists explícitas. Wildcards (`*`) PROHIBIDOS para delegación y comandos.

### NFR-003: Deny by Default
Todo permiso no concedido explícitamente MUST ser `deny`.

### NFR-004: Orden de Reglas de Permisos
En cada bloque `permission`, la regla `"*"` MUST ir PRIMERO. Las reglas específicas van DESPUÉS. (OpenCode: último match gana) .

### NFR-005: Fail-Closed
Delegación a target no permitido → error explícito, NO éxito alucinado.
Escritura fallida → error explícito, NO "creado y verificado".

---

## Acceptance Criteria (corregidos)

| ID | Criterio | Verificación |
|----|----------|-------------|
| AC-001 | Pensador NO puede escribir en `src/` | Intento de write → permission denied |
| AC-002 | Pensador invoca Agent-SSD para `speckit-specify` | Pensador llama Agent-SSD → spec.md existe en `specs/` |
| AC-003 | Pensador invoca Agent-SSD para `speckit-plan` | Pensador llama Agent-SSD → plan.md existe |
| AC-004 | Pensador invoca arquitecto para ADRs | Pensador llama arquitecto → ADR existe |
| AC-005 | Pensador invoca security-auditor para threat model | Pensador llama security-auditor → threat-model.md existe |
| AC-006 | Pensador invoca documentador para converge | Pensador llama documentador → converge.md existe |
| AC-007 | Pensador invoca implementadores para código | Pensador llama api-developer → código en `src/` |
| AC-008 | Agent-SSD NO delega | Agent-SSD intenta `task` → permission denied |
| AC-009 | Arquitecto NO delega | Arquitecto intenta `task` → permission denied |
| AC-010 | Permisos idénticos en ambos harnesses | Diff `.github/agents/` vs `.opencode/agent/` → 0 diferencias |
| AC-011 | Verificación de escritura falla correctamente | Agente escribe, verifica con Test-Path, si falla reporta error |
| AC-012 | `subagent_depth` = 1 en opencode.json | Leer opencode.json → `"subagent_depth": 1` |

---

## Scope

**In Scope:**
- Matriz de permisos para los 14 agentes en ambos harnesses
- Delegación secuencial del Pensador (plana, un nivel)
- Verificación obligatoria de escritura en prompts de agentes que escriben
- Configuración de `subagent_depth: 1`

**Out of Scope:**
- `bash` para el Pensador (eliminado)
- `task` para agentes documentales (eliminado)
- Delegación anidada (imposible por issue #8114)
- Cambios en prompts de comportamiento (solo permisos)
- Implementación de comandos Speckit (ya existen)

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| OpenCode ignora `tools: { write: false }` y expone write igual | Usar `edit: "*": deny` como respaldo. Auditar logs. |
| Bug #8114 persiste en versión del usuario | Diseño plano no depende de delegación anidada. |
| Regla `"*"` mal ordenada anula allowlists | Documentar orden obligatorio. Validar en `sync-agents.ps1`. |
| Pensador alucina éxito | Verificación obligatoria en prompt (FR-007). |

---

## Implementación correcta (resumen ejecutivo)

| Agente | edit | task | bash |
|--------|------|------|------|
| pensador | `"*": deny` | allowlist: Agent-SSD, arquitecto, documentador, security-auditor, 4 implementadores, gitflow, plataformador, solucionador | `"*": ask` + solo lectura |
| Agent-SSD | `src/*/.specify/**`, `Documentacion/**/specs/**`, resto deny | `"*": deny` | `"*": deny` + speckit CLI |
| arquitecto | `Documentacion/**`, `.github/**`, resto deny | `"*": deny` | `"*": deny` |
| documentador | `Documentacion/**`, `.github/**`, resto deny | `"*": deny` | `"*": deny` |
| security-auditor | `Documentacion/**`, `.github/**`, resto deny | `"*": deny` | `"*": ask` (solo herramientas auditoría) |
| api-developer | `src/**`, `tests/**`, resto deny | `"*": deny` | `"*": ask` + build |
| frontend-developer | `src/**`, `tests/**`, resto deny | `"*": deny` | `"*": ask` + build |
| devops | `src/**`, `tests/**`, resto deny | `"*": deny` | `"*": ask` + docker |
| qa-senior | `tests/**`, `Documentacion/**/pendientes-implementacion.md`, resto deny | `"*": deny` | `"*": ask` + test runners |
| gitflow | `.github/**`, `.opencode/**`, root configs | `"*": deny` | `"*": ask` + git |
| plataformador | `"*": allow` (con `-DryRun` obligatorio en prompt) | `"*": deny` | `"*": ask` + scripts |
| solucionador | `Documentacion/**`, `scripts/**` | `"*": deny` | `"*": ask` + ssh |
| analista-tecnico | `Documentacion/**`, `.github/**`, `.doc_agents/**` | `"*": deny` | `"*": deny` |
| upgrade-framework | `proyect_ext/**`, `.github/**`, `Documentacion/**` | `"*": deny` | `"*": ask` + git |
```

---

## Prompt para que Copilot implemente esto

Pega esto en Copilot después de guardar la Spec v2:

```
TAREA
=====
Implementar Spec 018 v2: corregir permisos de los 14 agentes según el diseño
de delegación PLANO (un solo nivel). El Pensador es el único orquestador.

DOCUMENTACIÓN OBLIGATORIA (leer antes de tocar nada)
=====================================================
1. https://opencode.ai/docs/agents/ → tipos de agente, modo primary/subagent
2. https://opencode.ai/docs/permissions/ → orden de reglas (último match gana)
3. https://opencode.ai/docs/config/ → subagent_depth
4. https://github.com/anomalyco/opencode/issues/8114 → bug de delegación anidada

PRINCIPIO ARQUITECTÓNICO (no negociable)
=========================================
- Delegación de UN SOLO NIVEL: Pensador → todos los demás.
- Ningún otro agente usa `task`.
- El Pensador NO tiene bash para Speckit (eso es de Agent-SSD).
- El Pensador NO tiene write/edit.

PASOS
=====
1. Leer opencode.json. Confirmar que subagent_depth: 1 (o agregarlo).
2. Para cada uno de los 14 agentes, abrir las dos copias:
   - .github/agents/<name>.agent.md
   - .opencode/agent/<name>.md (verificar la ruta exacta)
3. Aplicar la matriz de permisos de la Spec v2 (tabla final).
4. En cada bloque permission, la regla "*" va PRIMERO.
5. Para agentes que escriben (Agent-SSD, implementadores, documentales,
   gitflow, plataformador, solucionador, upgrade-framework):
   agregar al prompt (no al frontmatter) la regla de verificación:
   "Después de escribir, ejecutar Test-Path + Get-Content.
    Si Test-Path es False, reportar ERROR y NO continuar."
6. Verificar que ambos harnesses tengan permisos idénticos.
7. Reportar en tabla: agente | edit | task | bash | verificado.

RESTRICCIONES
=============
- No toques Documentacion/<AppName>/.
- No agregues bash al Pensador para Speckit.
- No agregues task a agentes documentales.
- Usa UTF-8 sin BOM.
- Responde en español.
```

---

## Una advertencia final

La Spec v1 asumía que OpenCode soporta delegación anidada. **No lo hace en las versiones actuales** (bug #8114, confirmado desde v1.1.15 hasta v1.1.19+). Si tu versión de OpenCode es anterior a v1.1.15, el bug puede no estar presente. **Verifica con `opencode --version` antes de decidir entre el diseño anidado (v1) y el plano (v2).**

Si estás en v1.1.15+, **el diseño plano es la única opción viable**. No hay workaround para #8114 a nivel de configuración.