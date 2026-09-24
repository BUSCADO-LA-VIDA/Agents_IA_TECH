# 008-mcp-config-portable — Configuración dinámica y portable de MCPs

**Feature Branch**: `008-mcp-config-portable`  
**Fecha**: 2026-09-24  
**Estado**: Analizada / Solución documentada  
**Artefactos**: spec.md, plan.md, tasks.md, analyze.md

## 1. Problema original

Error JSON con `InvalidEscapeCharacter` en `opencode.json` por rutas absolutas hardcodeadas.

Antecedente de diseño:
- El kit mantenía `.opencode/config.json` (gitignored) creado por `Ensure-OpenCodeConfig` en `scripts/plataformador-bootstrap.ps1` con placeholders:
  - `__PEGAR_AQUI_TU_NVIDIA_API_KEY__`
  - `__PEGAR_AQUI_TU_DEEPINFRA_API_KEY__`
  - `__GITHUB_TOKEN_OPCIONAL__`
- Mecanismo obsoleto y riesgoso: invita a rellenar keys reales y commitearlas por accidente. OpenCode ya ofrece memoria segura vía `opencode auth login`.
- `opencode.json` versionado contenía rutas absolutas de la PC, rompiendo portabilidad entre proyectos/equipos y generando escapes inválidos en JSON.
- ADR-0006 (feature 007) estableció que OpenCode **NO** auto-carga `.env.mcp`. El mecanismo efectivo es campo `environment` o ruta real en `command`.
- Falta de inventario central de rutas de MCPs → divergencia entre arneses (OpenCode vs Copilot) y fallos de arranque.

## 2. Solución implementada

### 2.1 Restauración y bootstrap
- Restaurar `opencode.json` desde backup `opencode.json.backup` para recuperar plantilla portable sin rutas absolutas hardcodeadas.
- Ejecutar `scripts/plataformador-bootstrap.ps1` que:
  - Re-resuelve tokens desde `.env.mcp` (inventario central gitignored).
  - Genera configuración dinámica de MCPs en `opencode.json` usando mecanismo efectivo ADR-0006: `environment` o ruta real en `command`.
  - Promueve `enabled: true` solo cuando la ruta está resuelta; nunca persiste `{env:...}` ni `__*_CMD__` irresoluble.
  - Añade entrada `context-mode` al bloque `mcp` (antes solo en `plugin`).

### 2.2 Eliminación de `.opencode/config.json`
- Se elimina `Ensure-OpenCodeConfig` (RF-17 obsoleto).
- Reemplazo por `Migrate-OpenCodeSecrets`:
  - Si archivo existe con solo placeholders → se elimina / marca obsoleto con WARN.
  - Si contiene valores reales → **no se borra a ciegas**; se avisa cómo migrar a `opencode auth login` sin destruir credenciales.
  - Se mantiene detección defensiva de secrets versionados: WARN + `git rm --cached` + rotar keys.

### 2.3 Inventario central de rutas
- `.env.mcp` (raíz, gitignored) pasa de "fuente portable" a **inventario central dinámico** de rutas MCP.
- Variables ampliadas:
  - `CONTEXT_MODE_CMD`
  - `CODEBASE_MEMORY_CMD`
  - `MARKITDOWN_CMD`
  - `TOKENSLAYER_CMD`
  - `GRAPHIFY_CMD`
- Ciclo de vida implementado:
  - `Register-McpPath` → capturar al instalar
  - `Update-McpPath` → validar/actualizar al actualizar
  - `Remove-McpPath` → borrar al desinstalar, evitando rutas huérfanas

### 2.4 Validación de JSON
- Tras bootstrap, `opencode.json` es JSON válido, sin escapes inválidos.
- Plantilla versionada sin rutas absolutas; rutas resueltas en runtime.
- `.gitignore` cubre `.env.mcp` y `.opencode/config.json`.

## 3. Estado actual

**MCPs conectados**
- `context-mode` → conectado
- `codebase-memory-mcp` → conectado
- `tokenslayer` → conectado
- `graphify` → conectado

**MCPs con limitación**
- `markitdown` → timeout / no responde en este entorno. Requiere revisión de ruta/binario.

**Configuración**
- `opencode.json` portable, sin rutas absolutas hardcodeadas.
- Inventario en `.env.mcp` sincronizado.
- `opencode auth login` es la vía oficial para API keys (NVIDIA, DeepInfra). No hay placeholders en config versionada.

## 4. Guardrails cumplidos

- **No persistir rutas absolutas**: `opencode.json` versionado usa `{env:...}` / rutas relativas. Rutas reales solo en `.env.mcp` gitignored y resueltas en runtime.
- **Inventario central único**: `.env.mcp` es fuente única de rutas. OpenCode y Copilot consumen las mismas rutas → consistencia entre arneses.
- **Tokens en memoria segura**: API keys gestionadas con `opencode auth login`, nunca en archivos de config versionados ni placeholders locales.
- **No borrar a ciegas**: `.opencode/config.json` con valores reales no se elimina automáticamente; se migra con aviso.
- **Mecanismo efectivo de resolución**: uso de `environment` / ruta real en `command` según ADR-0006; nunca queda `{env:...}` irresoluble con `enabled: true`.
- **Exclusión del sync**: `.env.mcp` y `.opencode/config.json` excluidos de sync transversal y control de versiones.

## 5. Pasos de validación

1. **Restaurar backup**
   ```powershell
   Copy-Item opencode.json.backup opencode.json
   ```

2. **Ejecutar bootstrap**
   ```powershell
   pwsh scripts/plataformador-bootstrap.ps1
   ```

3. **Verificar JSON válido**
   ```powershell
   Get-Content opencode.json | ConvertFrom-Json | Out-Null
   Write-Host "JSON válido"
   ```

4. **Comprobar inventario**
   ```powershell
   Get-Content .env.mcp
   git check-ignore .env.mcp
   ```

5. **Validar MCPs habilitados**
   ```powershell
   # Tras bootstrap, revisar bloque mcp en opencode.json
   # enabled: true solo con ruta resuelta
   ```

6. **Confirmar exclusión git**
   ```powershell
   git status --ignored | Select-String ".env.mcp"
   ```

7. **Autenticar secrets**
   ```bash
   opencode auth login
   ```
   Confirmar que NVIDIA/DeepInfra se resuelven desde memoria segura, no desde archivos.

## Referencias
- spec.md
- plan.md
- tasks.md
- analyze.md
- ADR-0006 feature 007
- `scripts/plataformador-bootstrap.ps1`
- `Documentacion/Agents_IA_TECH/seguridad/kit-gaps.md`
- `Documentacion/Agents_IA_TECH/seguridad/blindaje-git.md`
