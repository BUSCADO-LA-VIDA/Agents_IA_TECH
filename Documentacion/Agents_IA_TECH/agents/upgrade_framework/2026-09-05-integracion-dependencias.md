# Reporte de Integración de Dependencias Externas

> **Fecha**: 2026-09-05
> **Agente**: `upgrade_framework`
> **Proyecto principal**: Agents_IA_TECH

## Resumen

Ejecución del proceso de actualización de herramientas externas según `dependencias-manifest.yml`. Este reporte documenta el análisis de impacto, la determinación de qué copiar y dónde, y el estado de la integración dirigida.

## Dependencias gestionadas

| Proyecto | URL | Rama | Estado |
|----------|-----|------|--------|
| **spec-kit** | https://github.com/github/spec-kit | main | ⏳ Pendiente de clonado |
| **graphify** | https://github.com/tomasgraph/graphify | main | ⏳ Pendiente de clonado |

## Fase 1: Análisis de impacto (IA)

### spec-kit
- **Origen**: `src/speckit-*/` en el repo spec-kit
- **Destino**: `.github/skills/speckit-*/` en Agents_IA_TECH
- **Componentes a copiar** (según manifest):
  - `src/speckit-specify/` → `.github/skills/speckit-specify/`
  - `src/speckit-plan/` → `.github/skills/speckit-plan/`
  - `src/speckit-tasks/` → `.github/skills/speckit-tasks/`
  - `src/speckit-converge/` → `.github/skills/speckit-converge/`
  - `src/speckit-implement/` → `.github/skills/speckit-implement/`
  - `src/speckit-analyze/` → `.github/skills/speckit-analyze/`
  - `src/speckit-checklist/` → `.github/skills/speckit-checklist/`
- **Impacto en integración**: Los skills speckit ya existen en `.github/skills/` con `SKILL.md`. La actualización reemplazaría el contenido de estos SKILL.md con la última versión del repo. **Riesgo bajo** — los skills son autocontenidos y no dependen de otros componentes del proyecto.
- **Nota**: El proyecto también tiene skills adicionales (`speckit-clarify`, `speckit-constitution`, `speckit-taskstoissues`) que no están en el manifest pero que probablemente provienen del mismo repo. Se deben verificar.

### graphify
- **Origen**: `bin/` y `lib/` en el repo graphify
- **Destino**: `.opencode/bin/` y `.opencode/lib/graphify/` en Agents_IA_TECH
- **Componentes a copiar** (según manifest):
  - `bin/graphify` → `.opencode/bin/`
  - `lib/` → `.opencode/lib/graphify/`
- **Impacto en integración**: Los directorios `.opencode/bin/` y `.opencode/lib/graphify/` **no existen actualmente** en Agents_IA_TECH. Esta es una **integración nueva** (primera vez). Se debe crear la estructura y copiar los componentes.

## Fase 2: Determinación de qué copiar y dónde

### Plantilla de integración spec-kit
```
proyect_ext/spec-kit/src/speckit-<nombre>/  →  .github/skills/speckit-<nombre>/
```
Se copia el contenido de cada directorio `speckit-*` (principalmente `SKILL.md` y archivos de plantilla) a su correspondiente `.github/skills/speckit-*/`.

### Plantilla de integración graphify
```
proyect_ext/graphify/bin/graphify  →  .opencode/bin/graphify
proyect_ext/graphify/lib/          →  .opencode/lib/graphify/
```
Se copia el binario/script `graphify` y la librería completa `lib/`.

## Fase 3: Estado de la integración

### Comandos de clonado requeridos

Para completar la integración, se deben ejecutar los siguientes comandos en PowerShell (Windows):

```powershell
# spec-kit
git clone --branch main https://github.com/github/spec-kit C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit

# graphify
git clone --branch main https://github.com/tomasgraph/graphify C:\Proyectos\Agents_IA_TECH\proyect_ext\graphify
```

### Comandos de copia dirigida (post-clonado)

```powershell
# spec-kit → .github/skills/
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-specify\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-specify\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-plan\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-plan\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-tasks\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-tasks\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-converge\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-converge\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-implement\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-implement\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-analyze\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-analyze\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\spec-kit\src\speckit-checklist\* C:\Proyectos\Agents_IA_TECH\.github\skills\speckit-checklist\

# graphify → .opencode/
Copy-Item -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\graphify\bin\graphify C:\Proyectos\Agents_IA_TECH\.opencode\bin\
Copy-Item -Recurse -Force C:\Proyectos\Agents_IA_TECH\proyect_ext\graphify\lib\* C:\Proyectos\Agents_IA_TECH\.opencode\lib\graphify\
```

## Fase 4: Personalizaciones inteligentes

- **spec-kit**: Los skills existentes en `.github/skills/` pueden tener personalizaciones locales. Antes de sobrescribir, se debe comparar el contenido y aplicar merge si hay personalizaciones del usuario.
- **graphify**: Integración nueva, no hay personalizaciones previas que preservar.

## Estado final

| Proyecto | Clonado | Integrado | Versión registrada |
|----------|---------|-----------|--------------------|
| spec-kit | ⏳ | ⏳ | v0.0.0 (pendiente) |
| graphify | ⏳ | ⏳ | v0.0.0 (pendiente) |

## Pendientes

- [ ] Ejecutar `git clone` de spec-kit y graphify en `proyect_ext/`
- [ ] Ejecutar la copia dirigida de componentes
- [ ] Registrar versiones reales obtenidas en `dependencias-manifest.yml`
- [ ] Actualizar `referencias.md` con las versiones usadas
