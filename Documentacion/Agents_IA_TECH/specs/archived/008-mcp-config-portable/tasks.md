# Tasks: [008-mcp-config-portable]

**Feature**: `008-mcp-config-portable`  
**Date**: 2026-09-24  
**Status**: Draft  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)

---

## Phase 1: Foundation (Bloqueantes)

### Task 1: D1 — Reutilizar `.env.mcp` como inventario central
- **Descripción**: Asegurar que `.env.mcp` funcione como la fuente única de rutas de MCPs para el proyecto, ampliando la lista de variables actuales con las necesarias para MCP adicionales. Mantener el archivo gitignored y portátil por proyecto.
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1` (`Ensure-McpEnvFile`)
  - `.gitignore`
- **Criterio de aceptación**:
  - `.env.mcp` contiene al menos: `CONTEXT_MODE_CMD`, `CODEBASE_MEMORY_CMD`, `MARKITDOWN_CMD`, `TOKENSLAYER_CMD`, `GRAPHIFY_CMD`
  - El archivo es idempotente y se genera sin duplicados
  - No se crean archivos nuevos adicionales para el inventario
- **Dependencias**: Ninguna
- **Esfuerzo**: S

### Task 2: D2 — Ciclo de vida del inventario de rutas
- **Descripción**: Implementar tres funciones en el bootstrap para el ciclo de vida del inventario: registrar una ruta al instalar, validar/actualizar al actualizar, y borrar al desinstalar. Cada operación debe operar sobre `.env.mcp` de forma idempotente y segura.
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1`
- **Funciones propuestas**:
  - `Register-McpPath`
  - `Update-McpPath`
  - `Remove-McpPath`
- **Criterio de aceptación**:
  - Cuando un MCP se instala, su ruta queda capturada en `.env.mcp`
  - Cuando un MCP se actualiza, la ruta se valida y se actualiza si cambió
  - Cuando un MCP se desinstala, la ruta desaparece del inventario
  - Si la ruta no existe, no rompe el flujo: WARN + continue
- **Dependencias**: Task 1
- **Esfuerzo**: M

---

## Phase 2: Config dinámica portable (Aditivos)

### Task 3: D3 — Config dinámica en `opencode.json` + entrada `context-mode`
- **Descripción**: Ajustar la generación del bloque `mcp` para que use el inventario central de rutas y el mecanismo efectivo del ADR-0006: `environment` o ruta real en `command`. La plantilla versionada usa `enabled: false` por entrada; el bootstrap resuelve las rutas desde `.env.mcp` y promueve a `enabled: true` en runtime. La entrada `context-mode` debe existir dentro del bloque `mcp` y no solo como `plugin`.
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1` (`Ensure-OpenCodeMcp`)
  - `opencode.json`
- **Criterio de aceptación**:
  - `opencode.json` no contiene rutas absolutas del equipo del usuario
  - La config de MCPs se genera dinámicamente desde el bootstrap
  - `context-mode` aparece en `mcp` con `enabled: true` (promovido en runtime)
  - Los MCPs quedan con rutas válidas y consistentes con `.env.mcp`
  - No se persiste ningún `{env:...}` ni `__*_CMD__` sin resolver
- **Dependencias**: Task 1
- **Esfuerzo**: M

### Task 4: D1/FR-004 — Consistencia entre arneses (`.vscode/mcp.json` y `opencode.json`)
- **Descripción**: Mantener `Copilot` y `OpenCode` usando exactamente las mismas rutas de MCP. El bootstrap debe resolver ambas configuraciones desde el mismo inventario central (`.env.mcp`) para evitar divergencias entre arneses. (FR-004: inventario central para todos los arneses)
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1`
  - `.vscode/mcp.json` (si existe)
- **Criterio de aceptación**:
  - Ambos arneses usan las mismas rutas del inventario
  - La diferencia entre entornos es solo la ruta local resuelta, no la identidad del MCP
- **Dependencias**: Task 1, Task 3
- **Esfuerzo**: S

---

## Phase 3: Migración de secrets y permisos de seguridad

### Task 5: D4 — Eliminar `Ensure-OpenCodeConfig` y migrar a memoria segura
- **Descripción**: Eliminar el mecanismo obsoleto que crea `.opencode/config.json` con placeholders. Reemplazarlo por una migración defensiva que instruya a usar `opencode auth login`, sin borrar a ciegas un archivo con secrets reales.
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1` (`Ensure-OpenCodeConfig`, `Migrate-OpenCodeSecrets`)
- **Criterio de aceptación**:
  - Proyectos nuevos no crean `.opencode/config.json`
  - Si existe un archivo con placeholders, se elimina o marca obsoleto con WARN
  - Si existe un archivo con secrets reales, no se borra a ciegas; solo se informa y se recomienda migrar a `opencode auth login`
  - Se mantiene la detección defensiva de secrets versionados
- **Dependencias**: Ninguna
- **Esfuerzo**: M

### Task 6: D5 — Documentación de onboarding con `opencode auth login`
- **Descripción**: Actualizar la documentación de onboarding para que el usuario use la memoria segura de OpenCode para sus API keys, no placeholders ni archivos versionados.
- **Archivos**:
  - `Documentacion/Agents_IA_TECH/quickstart.md`
- **Criterio de aceptación**:
  - El usuario puede seguir instrucciones claras para autenticar con `opencode auth login`
  - Los tokens no aparecen en archivos versionados del repo
- **Dependencias**: Task 5
- **Esfuerzo**: XS

---

## Phase 4: Verificación y cierre

### Task 7: D6 — Verificación final de arranque de opencode
- **Descripción**: Añadir una validación final en el bootstrap para verificar que OpenCode puede arrancar con el conjunto actual de MCPs y que no quedan rutas rotas ni entradas `enabled: true` inválidas.
- **Archivos**:
  - `scripts/plataformador-bootstrap.ps1`
- **Criterio de aceptación**:
  - El bootstrap informa si los MCPs responden
  - Si un MCP falla, el error queda claramente reportado y no bloquea el resto del flujo
  - `opencode` puede arrancar correctamente con la config generada
- **Dependencias**: Task 3, Task 5
- **Esfuerzo**: S

### Task 8: D7 — Confirmar exclusión del sync y del control de versiones
- **Descripción**: Verificar que `.env.mcp` y cualquier archivo de secrets obsoleto quedan excluidos del sync transversal y del control de versiones, evitando que se propaguen por accidente.
- **Archivos**:
  - `.gitignore`
  - `scripts/plataformador-bootstrap.ps1` (`Sync-TransversalKit`)
- **Criterio de aceptación**:
  - `.env.mcp` es ignorado por git
  - `.opencode/config.json` no vuelve a aparecer en sincronizaciones transversales
- **Dependencias**: Task 5
- **Esfuerzo**: XS

---

## Phase 5: Validación integral

### Task 9: Validación idempotencia y escenarios de la feature
- **Descripción**: Ejecutar una validación final del bootstrap para comprobar escenarios clave de la especificación: instalación, actualización, desinstalación, generación dinámica, rutas rotas y arranque de OpenCode. Referenciar la matriz de tests T-01..T-13 del plan.md.
- **Archivos**: N/A (validación manual / escenarios de QA)
- **Criterio de aceptación**:
  - Los requisitos FR-001 a FR-008 se cumplen
  - Los success criteria SC-001 a SC-006 pasan
  - Los escenarios de US1 a US4 se ejecutan sin errores graves
  - El bootstrap es idempotente al repetirse
  - Matriz de validación T-01..T-13 (plan.md) ejecutada y documentada
- **Dependencias**: Tasks 1-8
- **Esfuerzo**: M

---

## Dependencias críticas (ruta crítica)
1. **Task 1 → Task 2 → Task 3 → Task 7**
   - Este es el camino principal para hacer que la configuración dinámica y portable de MCPs funcione en OpenCode y deje el sistema arrancable.
2. **Task 5 → Task 6 → Task 8**
   - Se encarga de eliminar el mecanismo obsoleto de secrets y asegurar la protección del repositorio.
3. **Task 3 + Task 5 + Task 8**
   - Conjuntamente aseguran que las rutas se resuelven bien y que no quedan secretos ni configs huérfanas.

---

## Riesgos y mitigación
- **Riesgo 1**: rutas absolutas persistidas manualmente en `opencode.json`  
  Mitigación: usar solo el inventario `.env.mcp` y resolver la configuración en runtime.
- **Riesgo 2**: `opencode auth login` no se usa en entornos con credenciales locales  
  Mitigación: mantener un WARN explícito y una instrucción de migración en vez de guardar tokens en archivos.
- **Riesgo 3**: rutas de MCP desactualizadas después de update  
  Mitigación: `Update-McpPath` + verificación final de arranque.
- **Riesgo 4**: rutas huérfanas tras desinstalación  
  Mitigación: `Remove-McpPath` y limpieza del inventario.

---

## Notas de simplificación
- `ponytail:` Se reutiliza `.env.mcp` como registro central en lugar de crear un nuevo archivo de inventario, porque ya existe y ya es la fuente de verdad del proyecto.
- `ponytail:` Se evita introducir nuevas librerías o dependencias: el cambio se hace en el bootstrap y en la configuración JSON existente.

---

## Siguiente fase del pipeline
- **Fase siguiente**: `speckit-analyze` / `analyze.md`
- **Objetivo**: revisar consistencia entre spec, plan y tasks, con foco en guardrails de seguridad y decisiones arquitectónicas del bootstrap.

---

## Validación ejecutada

*Sincronizado desde README.md 2026-09-24*

### Pasos de validación
1. Restaurar backup: `Copy-Item opencode.json.backup opencode.json`
2. Ejecutar bootstrap: `pwsh scripts/plataformador-bootstrap.ps1`
3. Verificar JSON válido: `Get-Content opencode.json | ConvertFrom-Json | Out-Null`
4. Comprobar inventario: `Get-Content .env.mcp` + `git check-ignore .env.mcp`
5. Validar MCPs habilitados: revisar bloque `mcp` en `opencode.json`, `enabled: true` solo con ruta resuelta
6. Confirmar exclusión git: `git status --ignored | Select-String ".env.mcp"`
7. Autenticar secrets: `opencode auth login`

### Estado de validación
- Restauración y bootstrap ejecutados.
- `opencode.json` JSON válido sin escapes inválidos.
- Inventario `.env.mcp` sincronizado y gitignored.
- MCPs conectados: `context-mode`, `codebase-memory-mcp`, `tokenslayer`, `graphify`.
- `markitdown` con limitación de timeout.
- Secrets gestionados vía `opencode auth login`.
