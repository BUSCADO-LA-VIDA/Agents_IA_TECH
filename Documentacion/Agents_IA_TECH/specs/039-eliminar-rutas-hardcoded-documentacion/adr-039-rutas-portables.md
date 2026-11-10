# ADR-039: Patrón de Rutas Portables para Documentación y Scripts del Kit

**Status**: Accepted  
**Date**: 2026-11-09  
**Deciders**: `arquitecto`, `pensador`, `plataformador`  
**Related Specs**: Spec 039 — Eliminar rutas hardcoded de la documentación y hacer el kit portable  
**Supersedes**: N/A (new ADR)  
**Tags**: `portability`, `documentation`, `scripts`, `bootstrap`, `adr`

---

## Contexto

El kit **Agents_IA_TECH** es una herramienta redistribuible que se clona en máquinas de desarrolladores en rutas arbitrarias:
- Windows: `<HOME>\dev\kits\Agents_IA_TECH`, `<PROJECT_ROOT>\Agents_IA_TECH`, `C:\Kits\Agents_IA_TECH`
- Linux/macOS: `<HOME>/kits/<KIT_NAME>`, `/opt/Agents_IA_TECH`, `~/Agents_IA_TECH`

**Problema**: La documentación (`README.md`, `AGENTS.md`), scripts (`.ps1`, `.sh`) y artefactos generados (`.specify/`) contenían rutas absolutas hardcodeadas de la máquina del autor (`$KitPath`, `C:<sep>Proyectos\opencode`). Esto rompía la portabilidad: un usuario que clonara el kit en otra ubicación no podría seguir el README ni ejecutar los scripts sin editar archivos.

**Regla violada**: Un kit portable/distribuible **nunca** debe tener rutas absolutas de la máquina del autor en su documentación, scripts ni artefactos generados.

---

## Decisión

Adoptamos **tres patrones complementarios** para referenciar rutas en el kit, en orden de preferencia:

### 1. Variables con Comentario Explicativo (Documentación)

**Para**: `README.md`, `AGENTS.md`, cualquier `.md` en `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`

```markdown
# Variable de configuración — AJUSTA A TU ENTORNO
$ProjectRoot = "C:<sep>Proyectos\MiProyecto"  # <- ajusta a tu ruta
$KitPath = "..\Agents_IA_TECH"             # <- ajusta a tu ruta
```

**Reglas**:
- Toda variable que represente una ruta configurable **debe** llevar el comentario `# <- ajusta a tu ruta` en la misma línea
- Usar `$ProjectRoot` para la raíz del proyecto destino
- Usar `$KitPath` para la raíz del kit Agents_IA_TECH
- Preferir rutas relativas (`..\Agents_IA_TECH`, `./scripts`) cuando la relación posicional es fija

### 2. `$PSScriptRoot` / `$SCRIPT_DIR` (Scripts PowerShell/Bash)

**Para**: `sync-agents.ps1`, `scripts/*.ps1`, `scripts/*.sh`

```powershell
# scripts/plataformador-bootstrap.ps1
param(
    [string]$RootPath = ".",
    [string]$KitPath = $PSScriptRoot
)

# Si el script está en subcarpeta scripts/:
$KitPath = Split-Path $PSScriptRoot -Parent
```

```bash
# scripts/algo.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_PATH="$(dirname "$SCRIPT_DIR")"
```

**Reglas**:
- `$PSScriptRoot` (PowerShell) o `$SCRIPT_DIR` (Bash) **siempre** apunta al directorio del script en ejecución
- Para obtener la raíz del kit desde `scripts/`, usar `Split-Path $PSScriptRoot -Parent` (PowerShell) o `dirname "$SCRIPT_DIR"` (Bash)
- Exponer `-RootPath` y `-KitPath` como parámetros con defaults basados en `$PSScriptRoot`
- **Nunca** hardcodear `C:<sep>Proyectos\...`, `/<home>/...`, `/<Users>/...`

### 3. Parámetros de Línea de Comandos (Bootstrap / CLI)

**Para**: `plataformador-bootstrap.ps1`, cualquier punto de entrada CLI

```powershell
param(
    [Parameter(Mandatory=$false)]
    [string]$RootPath = ".",
    
    [Parameter(Mandatory=$false)]
    [string]$KitPath = $PSScriptRoot,
    
    [switch]$CheckHardcodedPaths
)
```

**Reglas**:
- Parámetros obligatorios solo si no hay default seguro
- Defaults derivados de `$PSScriptRoot` o `.` (directorio actual)
- Documentar en comment-based help (`.PARAMETER`) el propósito y valores esperados

---

## Patrones Prohibidos

| Patrón | Ejemplo | Por qué está prohibido |
|--------|---------|------------------------|
| Ruta absoluta Windows | `$KitPath` | Solo funciona en máquina del autor |
| Ruta absoluta Linux/macOS | `<HOME>/<KIT_NAME>` | Solo funciona en máquina del autor |
| Unidad fija Windows | `$KitPath` | Asume letra de unidad específica |
| Variable sin comentario | `$KitPath = "..\Agents_IA_TECH"` | Usuario no sabe que debe cambiarla |

---

## Validación Automatizada

### Test de Regresión (`tests/validate-no-hardcoded-paths.Tests.ps1`)

```powershell
$forbiddenPatterns = @(
    "C:<sep>Proyectos",
    "D:<sep>",
    "/<home>/",
    "/<Users>/"
)
# Escanea: README.md, AGENTS.md, scripts\*.ps1, .github\**\*.md, .opencode\**\*.md, .doc_agents\*.md, Documentacion\**\*.md
# Excepción: líneas comentadas (#) que contengan $KitPath o $ProjectRoot
```

### Bootstrap Validation Flag (`-CheckHardcodedPaths`)

```powershell
plataformador-bootstrap.ps1 -RootPath . -KitPath ..\Agents_IA_TECH -CheckHardcodedPaths
```

Escanea el **proyecto destino** (no el kit) en:
- `Documentacion\**\*.md`
- `.github\**\*.md`
- `.opencode\**\*.md`
- `.doc_agents\*.md`

Reporta: `Archivo:Línea → Contenido ofensivo`

---

## Consecuencias

### Positivas
- ✅ Kit 100% portable: clona en cualquier ruta, funciona sin editar documentación
- ✅ README copiable/pegable: usuario solo cambia 2-3 líneas marcadas con `# <- ajusta a tu ruta`
- ✅ Scripts robustos: usan `$PSScriptRoot`/parámetros, no rutas fijas
- ✅ Validación continua: test Pester en CI + flag opcional en bootstrap
- ✅ Consistencia: patrón único documentado en ADR, aplicado en todo el kit

### Negativas / Riesgos
- ⚠️ **Curva de aprendizaje**: Usuarios nuevos deben entender `$KitPath` vs `$ProjectRoot` vs `$PSScriptRoot`
- ⚠️ **Falsos positivos**: Comentarios legítimos con rutas de ejemplo podrían disparar validación (mitigado: excepción para `# $KitPath`/`$ProjectRoot`)
- ⚠️ **Mantenimiento**: Cambios en estructura de carpetas (ej. mover scripts/) requieren actualizar `Split-Path` logic
- ⚠️ **Artefactos externos**: Archivos generados durante desarrollo en `C:<sep>Proyectos\opencode\...` no están en repo y requieren limpieza manual única

### Neutrales
- Los scripts existentes (`plataformador-bootstrap.ps1`) ya usaban este patrón (ADR-0003) — esta decisión lo formaliza y extiende a documentación
- No rompe funcionalidad existente (NFR-03): `$PSScriptRoot` y parámetros son compatibles hacia atrás

---

## Implementación

| Archivo / Área | Patrón Aplicado | Tarea Spec 039 |
|----------------|-----------------|----------------|
| `README.md` | Variables `$KitPath`/`$ProjectRoot` + `# <- ajusta a tu ruta` | T004–T010 |
| `AGENTS.md` | Variables `$KitPath`/`$ProjectRoot` + rutas relativas `./.github/agents/` | T011–T013 |
| `sync-agents.ps1` | `$PSScriptRoot` + parámetros `-KitPath`/`-RootPath` | T014 |
| `scripts/plataformador-bootstrap.ps1` | `$PSScriptRoot` + parámetros + flag `-CheckHardcodedPaths` | T015, T019–T021 |
| `scripts/*.ps1` | `$PSScriptRoot`/`Split-Path` + header comment | T016, T018 |
| `tests/validate-no-hardcoded-paths.Tests.ps1` | Test automatizado de patrones prohibidos | T025–T030 |

---

## Referencias

- **ADR-0003**: Plataforma Bootstrap Instalador Único (patrón base `$PSScriptRoot`, parámetros)
- **ADR-0004**: Post-Plataformado Speckit (artefactos `.specify/` locales al proyecto)
- **ADR-0005**: Orquestación Speckit por `pensador`/`Agent-SSD`
- **Spec 039**: `Documentacion/Agents_IA_TECH/specs/039-eliminar-rutas-hardcoded-documentacion/spec.md`
- **Constitution**: `.specify/memory/constitution.md` (reglas de portabilidad, agentes documentales no escriben código)

---

## Historial de Cambios

| Versión | Fecha | Autor | Cambio |
|---------|-------|-------|--------|
| 1.0 | 2026-11-09 | `arquitecto` | Creación inicial — formaliza patrones de Spec 039 |