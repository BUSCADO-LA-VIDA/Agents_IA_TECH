# Bitácora: 2026-11-09/10 — Spec 044: portabilidad con validación sin exclusiones

**Invocado por**: usuario (cierre del flujo Speckit de la spec 044)
**Alcance**: repositorio del kit, sin servidores remotos ni servicios en producción
**Commits**: `de42ff4`, `5414087`, `c1203cb`, `6d850b3`, `6f6fbf3`, `32444c5` (push a `origin/master`)

## 1. Problema que se atacó

El validador de portabilidad de la spec 039 declaraba su universo con una **lista fija de directorios**. Todo lo que no estaba en la lista era invisible (`tests/`, `.specify/`, `.mcp.json`, `opencode.json`, `.bootstrap-audit.log`), y además el propio test se autoexcluía para poder pasar. Resultado: verde con **34 archivos versionados contaminados** y 236 coincidencias.

## 2. Cambios aplicados

| Área | Cambio |
|---|---|
| Validador | Universo `git ls-files` (sin allowlist), auto-inclusión, fallback sin git, patrones por concatenación de fragmentos |
| Comparación | Windows sin distinguir mayúsculas (NTFS); POSIX distinguiendo (`/users/` de una API no es un home) |
| Bootstrap | `-CheckHardcodedPaths` sobre todo el proyecto, `exit 1` con coincidencias, filtro de artefactos de runtime con normalización de separadores |
| Config | `opencode.json` fuera del índice + `opencode.template.json` portable; `.mcp.json` con nombres en `PATH` y `${workspaceFolder}` |
| Artefactos | `.bootstrap-audit.log` fuera del índice (no se reescribe); `.specify/mcp-validation-*` redactados y conservados |
| Scripts | Defaults del autor sustituidos por `$PSScriptRoot` en `sync-mcp-graphify`, `init-pensador`, `upgrade_framework`, `cleanup-legacy-docs` (este último ahora dry-run por defecto) |
| Documentación | 62 `.md` redactados con tokens (`$KitPath`, `<HOME>`, `<PROJECT_ROOT>`, `<PYTHON_HOME>`, `<NODE_HOME>`) |
| CI | `.github/workflows/portability.yml` (matriz Linux + Windows) |

## 3. Verificación

| Comprobación | Resultado |
|---|---|
| `Invoke-Pester tests/validate-no-hardcoded-paths.Tests.ps1` | **16/16 en verde** sobre 781 archivos versionados |
| `harness-default`, `kit-sync-merge`, `kb-parity`, `mcp-refresh-parity` | exit 0 |
| `agents-parity` | exit 1 — divergencia **preexistente** de `Agent-SSD` (documentada en baseline 036) |
| Señuelo en proyecto temporal (sin `-DryRun`) | detectado, `exit=1` |
| Bootstrap en proyecto limpio con el kit publicado | `0 coincidencias en 136 archivos versionados`, 73 artefactos de runtime omitidos, `exit=0` |
| JSON de `opencode.json`, `opencode.template.json`, `.mcp.json`, hook | válidos |

## 4. Rollback

### 4.1 Código y documentación

```powershell
# Deshacer el bloque completo de la 044 (manteniendo los commits de 045/046)
git revert --no-commit de42ff4 6f6fbf3 32444c5
git commit -m "revert: spec 044 block"
```

### 4.2 Configuración del arnés

```powershell
# opencode.json salió del índice pero sigue en disco. Si se corrompió, recuperar
# la versión que estaba versionada antes de la 044:
git show e48c8c0:opencode.json > opencode.json

# .mcp.json versionado: volver a la versión anterior
git show e48c8c0:.mcp.json > .mcp.json

# Hook context-mode (spec 045): restaurar el registro con PreToolUse
Copy-Item .github/hooks/context-mode.json.bak-20261109 .github/hooks/context-mode.json -Force
```

### 4.3 Audit log

```powershell
# Volver a versionarlo (no recomendado: publica host, actor y rutas reales)
git add -f .bootstrap-audit.log
```

## 5. Pendiente al cierre de esta bitácora

| Ítem | Estado |
|---|---|
| AC-6: arranque del arnés tras reiniciar | Pendiente (requiere recargar la ventana; no verificable desde el agente) |
| T016: verificación del arranque | Pendiente, depende de AC-6 |
| AC-4 de la spec 045: lecturas > 16 KB | Pendiente, depende del mismo reinicio |
| 044: cierre formal | Pendiente de AC-6 |
| 046: `tasks.md` e implementación (G1-G4) | Pendiente |

## 6. Nota de método

El validador solo ve archivos **versionados**: una corrida en verde sobre el working tree no garantiza nada si los documentos nuevos aún no están en el índice. La regla operativa que queda es validar **después** de `git add`.
