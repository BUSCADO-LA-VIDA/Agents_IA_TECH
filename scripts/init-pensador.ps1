#!/usr/bin/env powershell
# Script de inicialización para copiar agente Pensador a nuevos proyectos
# Este script asegura que la validación de documentación y el orden sagrado estén en lugar

param(
    [string]$SourceProject = "c:\Proyectos\Agents_IA_TECH",
    [string]$TargetProject = ""
)

Write-Host "=== Inicialización del Agente Pensador ===`n" -ForegroundColor Cyan

# 1. Copiar spec.md del agente pensador
Write-Host "1. Copiando spec.md del agente pensador..." -ForegroundColor Yellow
$specSource = Join-Path $SourceProject ".github\agents\pensador\spec.md"
$specTarget = Join-Path $TargetProject ".github\agents\pensador\spec.md"

if (Test-Path $specSource) {
    Copy-Item -Path $specSource -Destination $specTarget -Force
    Write-Host "   ✓ spec.md copiado exitosamente" -ForegroundColor Green
} else {
    Write-Host "   ✗ Error: No se encontró $specSource" -ForegroundColor Red
    exit 1
}

# 2. Verificar y crear estructura de documentación obligatoria
Write-Host "`n2. Verificando estructura de documentación obligatoria..." -ForegroundColor Yellow

$requiredDocs = @(
    "Documentacion\00-indice.md",
    "Documentacion\pendientes-implementacion.md",
    "Documentacion\soluciones-conocidas.md",
    "Documentacion\capacidad-base.md"
)

$docsOk = $true
foreach ($doc in $requiredDocs) {
    $fullPath = Join-Path $TargetProject $doc
    if (-not (Test-Path $fullPath)) {
        Write-Host "   ✗ Faltando: $doc" -ForegroundColor Red
        $docsOk = $false
    } else {
        Write-Host "   ✓ $doc existe" -ForegroundColor Green
    }
}

if (-not $docsOk) {
    Write-Host "`n3. Creando estructura de documentación mínima..." -ForegroundColor Yellow
    
    # Crear directorios necesarios
    $docsDir = Join-Path $TargetProject "Documentacion"
    if (-not (Test-Path $docsDir)) {
        New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
        Write-Host "   ✓ Directorio Documentacion creado" -ForegroundColor Green
    }
    
    # Crear 00-indice.md si no existe
    $indicePath = Join-Path $docsDir "00-indice.md"
    if (-not (Test-Path $indicePath)) {
        $indiceContent = @"
# 📋 Índice - [Nombre del Proyecto]

> **Automatizado por**: Script de inicialización del agente Pensador
> **Fecha**: $(Get-Date -Format "yyyy-MM-dd")

## Resumen rápido
- Stack: [Pendiente de configurar]
- Agentes instalados: [Pendiente de configurar]

> Ver `Documentacion/preferencias.md` para configuraciones detalladas.
"@
        $indiceContent | Set-Content -Path $indicePath -Encoding UTF8
        Write-Host "   ✓ 00-indice.md creado" -ForegroundColor Green
    }
    
    # Crear pendientes-implementacion.md si no existe
    $pendPath = Join-Path $docsDir "pendientes-implementacion.md"
    if (-not (Test-Path $pendPath)) {
        $pendContent = @"
# Pendientes de Implementación - [Nombre del Proyecto]

> **Puente vivo entre documentación e implementación.**

## Formato de cada tarea
```markdown
- [ ] `[Área]` **Título descriptivo**
  - **Qué implementar**: descripción concreta
  - **Basado en**: `Documentacion/[proyecto]/archivo-especifico.md` (ADR / Spec)
  - **Archivos esperados**: `src/ruta/al/archivo.ts`
  - **Prioridad**: alta / media / baja
```

## ⏳ Tareas pendientes
- [ ] `[Pending]` **Título inicial**
  - **Qué implementar**: Estructura inicial del proyecto
  - **Basado en**: Ninguno
  - **Prioridad**: media
"@
        $pendContent | Set-Content -Path $pendPath -Encoding UTF8
        Write-Host "   ✓ pendientes-implementacion.md creado" -ForegroundColor Green
    }
    
    # Crear soluciones-conocidas.md si no existe
    $solPath = Join-Path $docsDir "soluciones-conocidas.md"
    if (-not (Test-Path $solPath)) {
        $solContent = @"
# 🛠️ Soluciones Conocidas - [Nombre del Proyecto]

> Repositorio de soluciones documentadas y fixes aplicados a este proyecto.

| Fecha | Problema | Solución | Implementador |
|-------|----------|----------|---------------|
| -- | -- | -- | -- |
"@
        $solContent | Set-Content -Path $solPath -Encoding UTF8
        Write-Host "   ✓ soluciones-conocidas.md creado" -ForegroundColor Green
    }
}

# 3. Verificar estructura de agentes
Write-Host "`n3. Verificando estructura de agentes..." -ForegroundColor Yellow

$agentsDir = Join-Path $TargetProject ".github\agents\pensador"
if (-not (Test-Path $agentsDir)) {
    New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
    Write-Host "   ✓ Directorio .github\agents\pensador creado" -ForegroundColor Green
}

# Copiar spec del agente si no existe
$agentSpec = Join-Path $agentsDir "spec.md"
if (-not (Test-Path $agentSpec)) {
    # Usar el spec.md que ya copiamos en el paso 1
    Write-Host "   ✓ spec.md del agente ya copiado en paso 1" -ForegroundColor Green
}

# 4. Verificar MCP codebase-memory
Write-Host "`n4. Verificando integración codebase-memory..." -ForegroundColor Yellow

$mcpPath = Join-Path $TargetProject ".specify\memory\constitution.md"
if (Test-Path $mcpPath) {
    Write-Host "   ✓ codebase-memory MCP configurado" -ForegroundColor Green
} else {
    Write-Host "   ⚠ codebase-memory MCP no configurado (opcional)" -ForegroundColor Yellow
    Write-Host "   Ejecutar: npm install -g codebase-memory-mcp" -ForegroundColor Gray
}

# 5. Resumen final
Write-Host "`n=== Resumen de Inicialización ===" -ForegroundColor Cyan
Write-Host "Proyecto objetivo: $TargetProject" -ForegroundColor White
Write-Host "Validación de documentación: $([boolean]::Parse($docsOk) ? "OK" : "Faltantes corregidos automáticamente")" -ForegroundColor White

Write-Host "`nPara usar el agente Pensador en este proyecto:"
Write-Host "1. Reinicia VS Code para cargar la nueva configuración"
Write-Host "2. El agente validará automáticamente la documentación antes de cada fase"
Write-Host "3. Sigue el orden sagrado: Plan → Documentar → Implementar" -ForegroundColor Green

Write-Host "`n¡Inicialización completada!" -ForegroundColor Cyan