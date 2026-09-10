#!/usr/bin/env powershell
# Script para configurar validación de documentación en un proyecto
# Este script se ejecuta después de copiar el agente Pensador a un nuevo proyecto

param(
    [string]$ProyectoPath = ""
)

if (-not $ProyectoPath) {
    $ProyectoPath = Read-Host "Introduce la ruta del proyecto"
}

Write-Host "=== Configurando Validación de Documentación para Pensador ===" -ForegroundColor Cyan
Write-Host "Proyecto: $ProyectoPath`n" -ForegroundColor White

# 1. Verificar que existe la carpeta Documentacion
$docsPath = Join-Path $ProyectoPath "Documentacion"
if (-not (Test-Path $docsPath)) {
    Write-Host "Creando carpeta Documentacion..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
}

# 2. Crear o actualizar 00-indice.md con estructura de validación
$indicePath = Join-Path $docsPath "00-indice.md"
$indiceExists = Test-Path $indicePath

if (-not $indiceExists) {
    $indiceContent = @"
# 📋 Índice - $($ProyectoPath -split '\\' | Select-Object -Last)

> **Autoconfigurado por**: Script de validación del agente Pensador
> **Fecha**: $(Get-Date -Format "yyyy-MM-dd HH:mm")

## Resumen rápido
- Stack: [Pendiente de configurar]
- Agentes instalados: [Pendiente de configurar]
- Validación Pensador: Activa

> Ver `preferencias.md` para configuraciones detalladas.
"@
    $indiceContent | Set-Content -Path $indicePath -Encoding UTF8
    Write-Host "✓ 00-indice.md creado con estructura de validación" -ForegroundColor Green
} else {
    Write-Host "✓ 00-indice.md ya existe" -ForegroundColor Gray
}

# 3. Crear o actualizar pendientes-implementacion.md con formato estándar
$pendPath = Join-Path $docsPath "pendientes-implementacion.md"
$pendExists = Test-Path $pendPath

if (-not $pendExists) {
    $pendContent = @"
# Pendientes de Implementación - $($ProyectoPath -split '\\' | Select-Object -Last)

> **Puente vivo entre documentación e implementación.**
> Mantenido por **todos los agentes** — cada uno en su rol:
> - `pensador` — Orquestador. Navega fuentes externas, filtra información.
> - **Documentales** (`arquitecto`, `documentador`, `security-auditor`) agregan tareas nuevas.
> - **Arquitecto** define spec linking (trazabilidad) y guardrails (restricciones).
> - **Implementadores** (`api-developer`, `frontend-developer`, `devops`) marcan como completadas y reportan bugs.
> - **QA** (`qa-senior`) escribe tests automáticos (unitarios, integración, API, E2E con Playwright navegando la app) y puede conectarse por SSH / queries a DB para diagnosticar. Si encuentra un bug, lo documenta aquí y se lo pasa al desarrollador (NO lo corrige).
> El implementador lo lee **primero** para saber exactamente qué hacer, sin recorrer todas las specs.

## Formato de cada tarea

```markdown
- [ ] `[Área]` **Título descriptivo**
  - **Qué implementar**: descripción concreta
  - **Basado en**: `Documentacion/[proyecto]/archivo-especifico.md` (ADR / Spec)
  - **Archivos esperados**: `src/ruta/al/archivo.ts`
  - **Prioridad**: alta / media / baja
```

## ⏳ Tareas pendientes

- [ ] `[Pending]` **Configurar agente Pensador**
  - **Qué implementar**: Ejecutar script de validación y configurar estructura mínima
  - **Basado en**: Ninguno (configuración inicial)
  - **Archivos esperados**: Ninguno
  - **Prioridad**: alta
  - **Nota**: Esta tarea se completa después de ejecutar este script.

- [ ] `[Pending]` **Personalizar proyecto**
  - **Qué implementar**: Ajustar configuraciones específicas del proyecto
  - **Basado en**: `Documentacion/preferencias.md`
  - **Archivos esperados**: `Documentacion/preferencias.md`
  - **Prioridad**: media
"@
    $pendContent | Set-Content -Path $pendPath -Encoding UTF8
    Write-Host "✓ pendientes-implementacion.md creado con formato estándar" -ForegroundColor Green
} else {
    Write-Host "✓ pendientes-implementacion.md ya existe" -ForegroundColor Gray
}

# 4. Crear soluciones-conocidas.md si no existe
$solPath = Join-Path $docsPath "soluciones-conocidas.md"
if (-not (Test-Path $solPath)) {
    $solContent = @"
# 🛠️ Soluciones Conocidas - $($ProyectoPath -split '\\' | Select-Object -Last)

> Repositorio de soluciones documentadas y fixes aplicados a este proyecto.

| Fecha | Problema | Solución | Implementador |
|-------|----------|----------|---------------|
| -- | -- | -- | -- |
"@
    $solContent | Set-Content -Path $solPath -Encoding UTF8
    Write-Host "✓ soluciones-conocidas.md creado" -ForegroundColor Green
} else {
    Write-Host "✓ soluciones-conocidas.md ya existe" -ForegroundColor Gray
}

# 5. Actualizar capacidad-base.md para referenciar al kit
$capPath = Join-Path $docsPath "capacidad-base.md"
if (Test-Path $capPath) {
    # Verificar que tenga la referencia correcta
    $contenidoActual = Get-Content -Path $capPath -Encoding UTF8
    if (-not $contenidoActual -match "\.doc_agents") {
        $contenidoActual = @"
# 🏗️ Capacidad Base - [Nombre del Proyecto]

> **⚠️ Este archivo es una REFERENCIA LOCAL** a la capacidad base del kit transversal.
> La **fuente de verdad única** está en **`.doc_agents/capacidad-base.md`**.
> Este archivo se mantiene sincronizado manualmente o via `plataformador`.

**Versión del kit**: 1.1.0 (ver `.doc_agents/capacidad-base.md`)
**Última sincronización**: $(Get-Date -Format "yyyy-MM-dd")

---

## Resumen de capacidades del kit transversal

### 1. Archivos transversales del kit (se copian entre proyectos/apps)

| Archivo/Carpeta | Obligatorio | Propósito |
|-----------------|:-----------:|-----------|
| `.github/copilot-instructions.md` | ✅ Sí | Reglas base de todos los agentes |
| `.github/agents/` | ✅ Sí | Definiciones agentes para GitHub Copilot |
| `.github/prompts/` | ✅ Sí | Slash commands para GitHub Copilot |
| `.github/skills/` | ✅ Sí | Skills compartidas globalmente (77 skills) |
| `.opencode/agents/` | ✅ Sí | Definiciones agentes para OpenCode |
| `.opencode/commands/` | ✅ Sí | Slash commands para OpenCode |
| `.opencode/config.json` | ✅ Sí | Configuración OpenCode |
| `AGENTS.md` | ✅ Sí | Documentación del kit |
| `opencode.json` | ✅ Sí | Configuración OpenCode |
| `README.md` | ✅ Sí | README del proyecto/repo |
| `sync-agents.ps1` | ✅ Sí | Script de sincronización del kit |
| `.doc_agents/` | ✅ Sí | **Estructura transversal del kit** |
| `.specify/memory/constitution.md` | ✅ Sí | Constitución base del proyecto (speckit) |

### 2. Agentes del kit (10 + 1 plataformador)

| Agente | Plataforma | Versión | Tipo |
|--------|-----------|---------|------|
| `pensador` | GitHub + OpenCode | 1.0 | Documental |
| `arquitecto` | GitHub + OpenCode | 1.0 | Documental |
| `documentador` | GitHub + OpenCode | 1.0 | Documental |
| `security-auditor` | GitHub + OpenCode | 1.0 | Documental |
| `api-developer` | GitHub + OpenCode | 1.0 | Implementador |
| `frontend-developer` | GitHub + OpenCode | 1.0 | Implementador |
| `devops` | GitHub + OpenCode | 1.0 | Implementador |
| `qa-senior` | GitHub + OpenCode | 1.0 | Implementador (solo tests) |
| `gitflow` | GitHub + OpenCode | 1.0 | Tooling |
| `solucionador` | GitHub + OpenCode | 1.0 | Plataforma (SSH) |
| `plataformador` | GitHub + OpenCode | 1.0 | Plataforma (auditoría/nivelación) |

### 3. Documentación BASE por aplicación (cada app tiene la suya en `Documentacion/<AppName>/`)

| Ruta (relativa a `Documentacion/<AppName>/`) | Obligatorio | Propósito |
|----------------------------------------------|:-----------:|-----------|
| `00-indice.md` | ✅ Sí | Índice general de ESTA app |
| `idioma.md` | ✅ Sí | Configuración de idioma de ESTA app |
| `preferencias.md` | ✅ Sí | Memoria de preferencias del usuario para ESTA app |
| `preferencias-git.md` | ⚠️ Recomendado | Preferencias de flujo git para ESTA app |
| `referencias.md` | ⚠️ Recomendado | Atribución de fuentes externas de ESTA app |
| `roadmap.md` | ⚠️ Recomendado | Backlog de evolutivos de ESTA app |
| `soluciones-conocidas.md` | ✅ Sí | Repositorio de soluciones de ESTA app |
| `pendientes-implementacion.md` | ✅ Sí | Puente docs ↔ código de ESTA app |
| `capacidad-base.md` | ✅ Sí | Referencia a la capacidad base del kit (copia de referencia) |
| `memoria-proyecto.md` | ✅ Sí | Capacidades instaladas en ESTA app (mantenido por plataformador) |
| `agents/<nombre>/spec.md` | ⚠️ Recomendado | Spec individual de cada agente para ESTA app |
| `arquitectura/adr/` | ⚠️ Recomendado | ADRs de ESTA app |
| `arquitectura/diagramas/` | ⚠️ Recomendado | Diagramas Mermaid de ESTA app |
| `bitacoras/` | ⚠️ Recomendado | Bitácoras del solucionador para ESTA app |
| `specs/` | ✅ Sí* | **speckit escribe aquí** (spec/plan/tasks por feature) |
| `testing/` | 📝 Opcional | Solo si hay tests documentados en ESTA app |
| `seguridad/` | 📝 Opcional | Solo si hay auditorías en ESTA app |
| `despliegue/` | 📝 Opcional | Solo si hay docs de despliegue en ESTA app |

> *`specs/` es obligatoria si se usa speckit en la app.

### 4. Skills globales (`.github/skills/` — compartidas, NO se duplican por app)

77 skills disponibles, incluyendo:
- `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-converge`, `speckit-implement`, `speckit-analyze`, `speckit-checklist`, `speckit-clarify`, `speckit-constitution`, `speckit-taskstoissues`
- `codebase-memory` — Grafo de conocimiento del código
- `graphify` — Input a knowledge graph
- `agent-customization` — Creación/edición de agentes
- `chronicle` — Análisis de historial de sesiones
- `project-setup-info-local` — Scaffolding de proyectos
- `get-search-view-results` — Resultados de búsqueda VS Code
- `python-fact-grounded-coding`, `pylance-docs`, `pylance-refactoring`, `pylance-python-profiling`

### 5. MCP Servers recomendados

| Servidor | Estado | Integración |
|----------|--------|-------------|
| `codebase-memory-mcp` | ⚠️ Recomendado | Grafo de conocimiento del código. `npm install -g codebase-memory-mcp` |
| Otros MCP | 📝 Pendiente | Según necesidad de cada app |

### 6. Hooks de ciclo de vida (globales)

| Hook | Propósito |
|------|-----------|
| `sessionStart` | Leer `Documentacion/<AppName>/preferencias.md` de la app activa al inicio |
| `subagentStart` | Recordar restricciones de paths (solo `Documentacion/<AppName>/` para documentales) |

---
"@
    $contenidoActual | Set-Content -Path $capPath -Encoding UTF8
    Write-Host "✓ capacidad-base.md actualizado con referencia al kit" -ForegroundColor Green
} else {
    Write-Host "⚠ No se pudo actualizar capacidad-base.md" -ForegroundColor Yellow
}

# 6. Crear preferencias.md con reglas de validación
$prefPath = Join-Path $docsPath "preferencias.md"
$prefExists = Test-Path $prefPath

if (-not $prefExists) {
    $prefContent = @"
# 🎯 Preferencias - $($ProyectoPath -split '\\' | Select-Object -Last)

> **Preferencias del usuario para este proyecto.**
> Se lee automáticamente al iniciar el agente Pensador.

## Configuración de validación

### Orden sagrado obligatorio
El agente Pensador debe seguir este orden estricto:
1. [ ] **Plan** - Crear plan detallado antes de implementar
2. [ ] **Documentar** - Documentar antes de implementar
3. [ ] **Implementar** - Solo después de confirmar documentación

### Formato de tareas pendientes
Las tareas deben seguir el formato:
- [ ] `[Área]` **Título descriptivo**
  - **Qué implementar**: descripción concreta
  - **Basado en**: `Documentacion/archivo-especifico.md`
  - **Prioridad**: alta / media / baja

### Restricciones de paths
- Documentales SOLO pueden escribir en: `Documentacion/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`
- Implementadores SOLO pueden leer/escribir en: `src/`, `tests/` de la app

### Regla de oro
NUNCA saltar de Plan a Implementar sin Documentar. NUNCA saltar de Documentar a Implementar sin confirmación.

## Integración con spec-kit

Skills que el agente Pensador orquestará:
- `speckit-specify` - Generación de specs
- `speckit-plan` - Generación de plan desde spec
- `speckit-tasks` - Generación de tasks.md
- `speckit-analyze` - Validación cross-artifact
- `speckit-converge` - Verificar implementación vs spec
- `speckit-implement` - Delegar a implementadores

## Configuración SSH (SOLO LECTURA)

Para depuración en caliente:
- Conectar: `ssh usuario@ip` (pedir password al usuario)
- Solo comandos de lectura: `journalctl`, `systemctl status`, `docker ps`, etc.
- **NUNCA** modificar servidor → delegar a `solucionador`

---
"@
    $prefContent | Set-Content -Path $prefPath -Encoding UTF8
    Write-Host "✓ preferencias.md creado con reglas de validación" -ForegroundColor Green
} else {
    Write-Host "✓ preferencias.md ya existe" -ForegroundColor Gray
}

# 7. Resumen final
Write-Host "`n=== Configuración Completada ===" -ForegroundColor Cyan
Write-Host "El agente Pensador ahora validará automáticamente:" -ForegroundColor White
Write-Host "  ✓ Estructura de documentación (00-indice.md, pendientes-implementacion.md)" -ForegroundColor Green
Write-Host "  ✓ Formato estándar de tareas" -ForegroundColor Green
Write-Host "  ✓ Orden sagrado: Plan → Documentar → Implementar" -ForegroundColor Green
Write-Host "  ✓ Referencia al kit transversal (.doc_agents/)" -ForegroundColor Green
Write-Host "  ✓ Integración con spec-kit skills" -ForegroundColor Green
Write-Host "`nPara usar el agente Pensador:"
Write-Host "1. Reinicia VS Code"
Write-Host "2. El agente validará la documentación antes de cada fase" -ForegroundColor Green
Write-Host "3. Sigue el orden sagrado automáticamente" -ForegroundColor Green

Write-Host "`n¡Listo! El proyecto está configurado para el agente Pensador." -ForegroundColor Cyan