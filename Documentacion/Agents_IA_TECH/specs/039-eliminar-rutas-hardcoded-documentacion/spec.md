# Spec 039 — Eliminar rutas hardcoded de la documentación y hacer el kit portable

**Feature Branch**: `039-eliminar-rutas-hardcoded-documentacion`

**Created**: 2026-11-09

**Status**: Borrador — pendiente de aprobación para pasar a `plan.md`

**Input**: El usuario detectó rutas absolutas hardcodeadas (`C:\Proyectos\Agents_IA_TECH`, `C:\Proyectos\opencode`) en `README.md` y en artefactos generados. El kit es una aplicación redistribuible que debe funcionar en cualquier máquina sin rutas fijas.

---

## Problema y evidencia

| Archivo / Ubicación | Ruta hardcodeada | Impacto |
|---|---|---|
| `README.md` (línea 22) | `$ProjectRoot = "C:\Proyectos\MiProyecto"` | Ejemplo con ruta absoluta en lugar de variable genérica |
| `README.md` (sección "Alternativa sin red") | `C:\Proyectos\Agents_IA_TECH` | Ruta absoluta al kit maestro; no funciona si el kit está en otra ubicación |
| `README.md` (sección sync-kit local) | `C:\Proyectos\Agents_IA_TECH` | Idem |
| `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` | Rutas absolutas en artefactos generados | Los artefactos del bootstrap no deben contener rutas de la máquina que los generó |
| `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-tasks.md` | Idem | Idem |

**Regla violada**: Un kit portable/distribuible **nunca** debe tener rutas absolutas de la máquina del autor en su documentación, scripts ni artefactos generados. Todas las rutas deben ser:
- Relativas al proyecto (`./`, `../`, `src/`, etc.)
- Variables de entorno (`$KitPath`, `$ProjectRoot`, `$env:KIT_ROOT`)
- Parámetros pasados al script (`-RootPath`, `-KitPath`)

---

## Objetivo

1. **Eliminar** todas las rutas absolutas hardcodeadas (`C:\...`, `D:\...`, `/home/...`, etc.) de:
   - `README.md`
   - `AGENTS.md`
   - Cualquier archivo `.md` en `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`
   - Scripts `.ps1` / `.sh` que se distribuyen con el kit

2. **Reemplazar** por:
   - Variables con comentarios explicativos (`$KitPath = "..\Agents_IA_TECH"  # <- ajusta a tu ruta`)
   - Rutas relativas (`./scripts`, `../Agents_IA_TECH`)
   - Parámetros de línea de comandos (`-RootPath`, `-KitPath`)

3. **Agregar validación** en el bootstrap (`plataformador-bootstrap.ps1`) que detecte y avise si hay rutas absolutas en la documentación del proyecto destino.

4. **Limpiar** los artefactos generados en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` que contienen rutas de la máquina de desarrollo.

---

## Requisitos funcionales (RF)

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01 | `README.md`: cero rutas absolutas. Usar `$ProjectRoot`, `$KitPath` con comentarios "ajusta a tu ruta" | **Must** |
| RF-02 | `README.md`: sección "Alternativa sin red" usa ruta relativa `..\Agents_IA_TECH` o variable `$KitPath` | **Must** |
| RF-03 | `README.md`: sección sync-kit local usa variable `$KitPath` | **Must** |
| RF-04 | `AGENTS.md`: revisar y eliminar rutas absolutas si las hay | **Must** |
| RF-05 | Scripts del kit (`scripts/*.ps1`): no hardcodear `C:\Proyectos\Agents_IA_TECH`; usar `$PSScriptRoot` o parámetros | **Must** |
| RF-06 | Bootstrap: validación opcional (`-CheckHardcodedPaths`) que escanee `Documentacion/`, `.github/`, `.opencode/` del proyecto destino y reporte rutas absolutas sospechosas | **Should** |
| RF-07 | Limpiar `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md` (artefactos de prueba con rutas locales) | **Must** |
| RF-08 | Agregar test en `tests/` que valide: `grep -r "C:\\\\Proyectos" README.md AGENTS.md scripts/ --include="*.md" --include="*.ps1"` → 0 resultados (excepto comentarios de ejemplo con variable) | **Should** |

---

## Requisitos no funcionales (NFR)

| ID | Requisito |
|---|---|
| NFR-01 | El kit debe poder clonarse en cualquier ruta (`/home/user/kits/Agents_IA_TECH`, `D:\Kits\Agents_IA_TECH`, `C:\Users\X\Agents_IA_TECH`) y la documentación seguir siendo válida sin editar |
| NFR-02 | Un usuario nuevo debe poder seguir el README copiando/pegando y solo cambiando las variables marcadas con `# <- ajusta...` |
| NFR-03 | No romper funcionalidad existente del bootstrap ni del sync-kit |

---

## Decisiones de arquitectura (ADR related)

- **ADR-0003** (Plataforma Bootstrap Instalador Único): el bootstrap ya usa `$PSScriptRoot` y parámetros `-RootPath`, `-KitPath`. La documentación debe reflejar ese patrón.
- **ADR-0004** (Post-Plataformado Speckit): los artefactos generados por el bootstrap en `.specify/` deben ser locales al proyecto, no contener rutas de la máquina que los generó.

---

## Tareas derivadas (para `tasks.md`)

| ID | Tarea | Agente |
|---|---|---|
| T01 | Revisar `README.md` completo y reemplazar rutas absolutas por variables/rutas relativas | `documentador` |
| T02 | Revisar `AGENTS.md` y eliminar rutas absolutas | `documentador` |
| T03 | Revisar scripts en `scripts/` que se distribuyen: buscar `C:\Proyectos\Agents_IA_TECH` y reemplazar por `$PSScriptRoot` o parámetros | `plataformador` |
| T04 | Agregar validación `-CheckHardcodedPaths` en `plataformador-bootstrap.ps1` | `plataformador` |
| T05 | Eliminar `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\mcp-validation-plan.md` y `mcp-validation-tasks.md` | `plataformador` |
| T06 | Agregar test en `tests/validate-no-hardcoded-paths.Tests.ps1` | `qa-senior` |
| T07 | Ejecutar test y confirmar 0 rutas absolutas en archivos distribuibles | `qa-senior` |

---

## Criterios de aceptación

1. `grep -r "C:\\\\Proyectos" README.md AGENTS.md scripts/ --include="*.md" --include="*.ps1"` devuelve **0 resultados** (o solo líneas de comentario con variable `$KitPath`/`$ProjectRoot`)
2. `grep -r "C:\\\\Proyectos" .github/ .opencode/ .doc_agents/ Documentacion/ --include="*.md"` devuelve **0 resultados**
3. `README.md` se puede copiar a un proyecto en `/home/user/mi-proyecto` o `D:\Proyectos\mi-proyecto` y funciona cambiando solo las variables marcadas
4. Los artefactos `.specify/mcp-validation-*.md` en `C:\Proyectos\opencode\src\Agents_IA_TECH\.specify\` no existen (limpiados)
5. Test `tests/validate-no-hardcoded-paths.Tests.ps1` pasa en CI

---

## Notas

- Este spec ataca la **portabilidad real** del kit. No es cosmético: un usuario que clone el kit en Linux o en otra unidad de Windows no puede seguir el README si tiene rutas de `C:\Proyectos\Agents_IA_TECH`.
- La variable `$ProjectRoot` en el ejemplo del README (línea 22) es aceptable **solo** porque tiene el comentario `# <- cambia esto a tu ruta` y es una variable, no una ruta literal en los comandos siguientes.
- La sección "Alternativa sin red" ya usa `$KitPath = "..\Agents_IA_TECH"` — ese patrón es el correcto y debe extenderse a todo el README.