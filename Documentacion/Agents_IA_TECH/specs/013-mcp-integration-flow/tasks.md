# Tasks 013 – MCP Integration Flow (aligned with Spec 015)

## T001 – Clonar ECC en proyect_ext/ECC
- **Descripción**: Clonar el repositorio `https://github.com/affaan-m/ECC.git` en la carpeta `proyect_ext/ECC`.
- **Comando**: `git clone https://github.com/affaan-m/ECC.git proyect_ext/ECC`
- **Estado**: `[ ] Pendiente`

## T002 – Crear estructura de carpetas scripts/ecc‑* y orquestador inicial
- **Descripción**: Crear el directorio `scripts/ecc‑` y generar el archivo `ecc-orchestrator.ps1` con los parámetros `--action`, `--mcp`, `--dry-run` y la validación de whitelist Art‑VII.
- **Comando**: 
  ```powershell
  New-Item -ItemType Directory -Path "scripts/ecc‑" -Force
  # (generar ecc-orchestrator.ps1 según spec 015)
  ```
- **Estado**: `[ ] Pendiente`

## T003 – Actualizar frontmatter de los 13 agents con la sección ## 🎯 Rol Scrum: Integración MCP
- **Descripción**: Para cada agent en `.github/agents/` y `.opencode/agents/` (pensador, arquitecto, security‑auditor, documentador, api‑developer, frontend‑developer, devops, qa‑senior, gitflow, plataformador, analista‑tecnico y los restantes), añadir al final del archivo la sección `## 🎯 Rol Scrum: Integración MCP` con las reglas obligatorias:
  - “Nunca ejecutar una tarea sin presentar el plan al usuario y obtener su aprobación explícita. Si el plan no está aprobado, detener y solicitar aprobación.”
  - “El pensador es el único que puede autorizar la transición de Plan → Implement.”
- **Comando**: (script PowerShell iterará sobre la lista de archivos y añadirá la sección si no existe).
- **Estado**: `[ ] Pendiente`

## T004 – Validar la whitelist Art‑VII de la Constitución tras añadir nuevos paths
- **Descripción**: Ejecutar `Constitution Check` y comprobar que los paths nuevos (scripts/ecc‑*, ecc‑orchestrator.ps1, etc.) están incluidos en la whitelist Art‑VII. Corregir cualquier path no autorizado.
- **Comando**: `speckit-constitution --check` (o el equivalente) y revisar el informe.
- **Estado**: `[ ] Pendiente`

## T005 – Ejecutar pipeline CI vacío y añadir primera prueba dry‑run
- **Descripción**: Crear un archivo `ci/ecc-pipeline.yml` (o equivalente) que invoque `.\\scripts\\ecc-orchestrator.ps1 --dry-run` y verifique que el código de salida sea 0. Registrar el resultado en `reports/ecc-test-dryrun.md`.
- **Comando**: 
  ```yaml
  name: ECC Dry‑run
  on: [push]
  jobs:
    dry-run:
      runs-on: windows-latest
      steps:
        - name: Run orchestrator dry‑run
          run: .\\scripts\\ecc-orchestrator.ps1 --dry-run
  ```
- **Estado**: `[ ] Pendiente`

## T006 – Notificar a todos los agents de la nueva norma
- **Descripción**: Realizar un commit que toque los frontmatter de los 13 agents (añadir o confirmar la sección `## 🎯 Rol Scrum: Integración MCP`) y añadir un mensaje en el repositorio indicando: “A partir de ahora todo nuevo MCP debe seguir el flujo E‑01 → E‑08”.
- **Comando**: 
  ```powershell
  git add .github/agents/*.md .opencode/agents/*.md
  git commit -m "feat: add MCP integration rules to agents (013‑T006)"
  git push
  ```
- **Estado**: `[ ] Pendiente`

## T007 – Integrar spec 013 en el índice 00‑indice.md
- **Descripción**: Añadir una entrada en `Documentacion/Agents_IA_TECH/00-indice.md` bajo la sección “Especificaciones activas”:
  ```
  - **013‑MCP‑Integration‑Flow** – Flujo de integración MCP alineado con Spec 015.
    *Ubicación*: `specs/013-mcp-integration-flow/`
    *Estado*: Completada/operativa — flujo SSD completo, lista para producción (NO archivada).
  ```
- **Comando**: Editar `00-indice.md` y añadir la línea correspondiente.
- **Estado**: `[ ] Pendiente`

## T008 – Completar spec 013 — flujo SSD completo, lista para producción (operativa)
- **Definición de términos (vinculante)**: `Completar/Cerrar` = terminar todo el flujo SSD+Speckit sin saltar pasos y dejar la spec lista para producción, permaneciendo ACTIVA en `specs/013-mcp-integration-flow/`. `Archivar` (`specs/archived/`) SOLO cuando se indique explícitamente que algo se retira del flujo/proceso.
- **Descripción**: Verificar E‑01→E‑08 completos, spec integrada en `00-indice.md`, agents actualizados y pipeline verde. La spec 013 PERMANECE ACTIVA y operativa. NO mover a `archived/`.
- **Comando**: Ningún `Move-Item`. Solo verificación y marcado en `pendientes-implementacion.md` (013‑T008 como [x] Completada/operativa).
- **Estado**: `[ ] Pendiente`