# 🧩 Modelo de Skills: Copilot vs OpenCode

> **Propósito**: Documentar cómo se gestionan las skills en cada harness del kit, por qué OpenCode **no usa el campo `skills:`** en los agentes (y el error de validación que causaba), y cuál es su **equivalente funcional**.
> **Fecha**: 2026-09-20 | **Autor**: `pensador` (fase documental)

---

## 1. El problema: `Validation: Unsupported parameter(s): skills`

Los agentes del kit se definen en **dos harnesses en paralelo**:

- `.github/agents/<name>.agent.md` → **GitHub Copilot**
- `.opencode/agents/<name>.md` → **OpenCode**

Algunos agentes de OpenCode declaraban un campo `skills:` en el frontmatter YAML (copiado de la definición de Copilot). **OpenCode no reconoce ese campo** y al validar el agente lanza:

```
Validation: Unsupported parameter(s): skills
```

**Causa raíz**: `skills:` es un campo **exclusivo de GitHub Copilot**. OpenCode tiene un modelo de skills **distinto** (ver §2).

---

## 2. ¿Tiene equivalente en OpenCode? SÍ — pero con mecanismo distinto

| Aspecto | GitHub Copilot (`.github/agents/*.agent.md`) | OpenCode (`.opencode/agents/*.md`) |
|---------|-----------------------------------------------|-------------------------------------|
| **Declaración en el agente** | Campo `skills:` (lista de nombres) | **NO existe** — causa el error de validación |
| **Definición de la skill** | `SKILL.md` en `.github/skills/<cat>/<name>/` | `SKILL.md` en `.opencode/skills/<name>/` (o `.claude/skills/`, `.agents/skills/`) |
| **Descubrimiento** | El agente lista sus skills en el frontmatter | OpenCode descubre skills vía el **tool nativo `skill`** (las lista en `<available_skills>`) |
| **Carga** | Automática al agente | **On-demand**: el agente llama `skill({ name: "..." })` |
| **Control de acceso por agente** | Campo `skills:` | **`permission.skill`** en el frontmatter (glob patterns) |

### Campos que OpenCode SÍ reconoce en el frontmatter de agente

- `description` (requerido)
- `mode` (`primary` | `subagent`)
- `temperature`
- `permission` (con claves `read`, `edit`, `bash`, `task`, `skill`, `webfetch`, etc.)
- `model`
- `tools` (deprecated — usar `permission`)
- `prompt`
- `version`, `user-invocable` (opcionales)

**Cualquier otro campo** se pasa directamente al provider como opción de modelo (no se valida como campo de agente).

---

## 3. El equivalente funcional: `permission.skill` + tool `skill`

En OpenCode, para que un agente pueda usar una skill:

1. **La skill debe existir** como `SKILL.md` en `.opencode/skills/<name>/` (o `.claude/skills/`, `.agents/skills/`). El frontmatter debe tener `name` y `description` (requeridos).
2. **El agente debe tener permiso** para cargarla vía `permission.skill` en su frontmatter.

### Ejemplo — antes (Copilot, campo `skills:`)

```yaml
skills:
  - speckit-specify
  - speckit-plan
```

### Ejemplo — después (OpenCode, `permission.skill`)

```yaml
permission:
  skill:
    "speckit-specify": allow
    "speckit-plan": allow
```

O con wildcard para todas las speckit:

```yaml
permission:
  skill:
    "speckit-*": allow
```

### Valores de `permission.skill`

| Valor | Comportamiento |
|-------|----------------|
| `allow` | La skill se carga inmediatamente |
| `deny` | La skill se oculta del agente, acceso rechazado |
| `ask` | Se pide aprobación al usuario antes de cargar |

---

## 4. Ubicación de las skills en el kit

| Harness | Ubicación de skills | ¿OpenCode las descubre? |
|---------|---------------------|--------------------------|
| Copilot | `.github/skills/<cat>/<name>/SKILL.md` | ❌ No |
| OpenCode | `.opencode/skills/<name>/SKILL.md` | ✅ Sí |
| OpenCode (alternativa) | `.claude/skills/<name>/SKILL.md` | ✅ Sí |
| OpenCode (alternativa) | `.agents/skills/<name>/SKILL.md` | ✅ Sí |

> **Importante**: OpenCode **NO** descubre skills desde `.github/skills/`. Por eso las skills speckit se **duplican** en `.opencode/skills/` (ver §5).

---

## 5. Decisión de implementación (2026-09-20)

Para que OpenCode pueda cargar las skills speckit:

1. **Se quitó** el campo `skills:` de los 6 agentes de OpenCode que lo tenían (`pensador`, `analista_tecnico`, `gitflow`, `plataformador`, `solucionador`, `upgrade_framework`).
2. **Se reemplazó** por `permission.skill` con los patrones de las skills que cada agente debe poder cargar.
3. **Se duplicaron** las 10 skills speckit de `.github/skills/` a `.opencode/skills/` (mismo `SKILL.md`, mismo frontmatter con `name` + `description`).

### Agentes de OpenCode actualizados

| Agente | `permission.skill` |
|--------|---------------------|
| `pensador` | `speckit-*` (todas) |
| `analista_tecnico` | `speckit-specify`, `speckit-analyze` |
| `gitflow` | `speckit-implement`, `speckit-converge` |
| `plataformador` | `speckit-analyze` |
| `solucionador` | `speckit-analyze`, `speckit-implement` |
| `upgrade_framework` | `speckit-plan`, `speckit-implement` |

### Skills speckit duplicadas en `.opencode/skills/`

`speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-converge`, `speckit-implement`, `speckit-checklist`, `speckit-clarify`, `speckit-constitution`, `speckit-taskstoissues`.

---

## 6. Sincronización entre harnesses (regla transversal)

Los agentes `.github/` y `.opencode/` deben mantenerse **en paralelo**, pero **no son byte-idénticos** en el frontmatter. Diferencias legítimas por harness:

| Campo | Copilot | OpenCode |
|-------|---------|----------|
| `skills:` | ✅ Sí | ❌ No (usar `permission.skill`) |
| `mode: primary` | N/A | ✅ Sí |
| `user-invocable` | N/A | ✅ Sí |

**Regla**: al editar un agente, actualizar ambos harnesses, pero respetando el modelo de skills de cada uno. El **cuerpo** (instrucciones, enfoque, constraints) debe ser idéntico; el **frontmatter** puede diferir en los campos específicos de cada harness.

---

## 7. Qué NO hacer

- ❌ **NO** usar `skills:` en agentes de OpenCode — causa `Validation: Unsupported parameter(s): skills`.
- ❌ **NO** esperar que OpenCode descubra skills desde `.github/skills/` — no las lee.
- ❌ **NO** borrar `.opencode/skills/` al sincronizar — son la copia que OpenCode necesita.
- ❌ **NO** duplicar skills en `.github/skills/` y `.opencode/skills/` con contenido divergente — mantenerlas idénticas.
