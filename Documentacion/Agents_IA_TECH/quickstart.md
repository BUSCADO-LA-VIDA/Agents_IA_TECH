# Quickstart — Agents_IA_TECH

> Guía rápida para poner en marcha el kit de agentes y herramientas en cualquier proyecto.

---

## 1. Prerrequisitos

| Herramienta | Versión mínima | Verificación |
|-------------|----------------|--------------|
| PowerShell | 7+ (`pwsh`) | `pwsh --version` |
| Git | 2.30+ | `git --version` |
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| uv | 0.1+ | `uv --version` |
| Python | 3.11+ | `python --version` |

---

## 2. Instalación Rápida (Proyecto Nuevo)

```powershell
# 1. Clonar el kit maestro
git clone https://github.com/<tu-org>/Agents_IA_TECH.git
cd Agents_IA_TECH

# 2. Ejecutar bootstrap (sincroniza kit, MCPs, índices)
.\scripts\plataformador-bootstrap.ps1

# 3. Verificar MCPs registrados
cat opencode.json | jq '.mcp[] | {name: .name, enabled: .enabled}'
```

---

## 3. Flags Principales del Bootstrap

| Flag | Descripción | Default |
|------|-------------|---------|
| `-ForceUpgradeTools` | **Sincroniza dependencias externas + compila tokenslayer + registra 4to MCP** (ver sección 4) | `false` |
| `-DryRun` | Simula ejecución sin escribir archivos ni llamadas de red | `false` |
| `-SkipSync` | Omite sincronización del kit transversal (modo seguro para consumidores) | `false` |

---

## 4. `-ForceUpgradeTools`: Sync Externo + Tokenslayer + 4to MCP

### Qué hace

Cuando ejecutas:
```powershell
.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools
```

El bootstrap realiza **automáticamente** en una sola pasada:

1. **Copia `dependencias-manifest.yml`** si no existe (plantilla del kit maestro → raíz del proyecto)
2. **Invoca `upgrade_framework`** que clona/actualiza `proyect_ext/`:
   - `proyect_ext/spec-kit/` desde `github.com/github/spec-kit`
   - `proyect_ext/tokenslayer/` desde `github.com/ajvikram/TokenSlayer`
   - `graphify` via `uv tool install graphifyy[mcp]`
3. **Compila `tokenslayer`** (`npm ci --ignore-scripts && npm run build` en `proyect_ext/tokenslayer/mcp-server`)
4. **Registra el 4to MCP** en `opencode.json`: `"tokenslayer.enabled": true`

### Comportamiento Fail-Open (Obligatorio)

> **El bootstrap NUNCA falla por errores en operaciones externas.**

| Escenario | Comportamiento |
|-----------|----------------|
| Fallo de red / GitHub rate limit | `WARN: upgrade_framework failed: <razón> — continuing bootstrap` |
| Permisos denegados | `WARN: upgrade_framework failed: access denied — continuing bootstrap` |
| `uv` no instalado | `WARN: upgrade_framework failed: uv not found — continuing bootstrap` |
| Build de tokenslayer falla | `WARN: tokenslayer build failed — continuing bootstrap` |
| **Cualquier error** | **Bootstrap continúa → exit code SIEMPRE 0** |

### Primera Ejecución (Proyecto Consumidor Limpio)

```powershell
# Proyecto fresco (ej. trading_bot) SIN:
# - dependencias-manifest.yml
# - proyect_ext/
# - opencode.json con tokenslayer

.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools

# Salida esperada:
# INFO: Sync-TransversalKit completed
# INFO: dependencias-manifest.yml not found — copying from master template
# INFO: Invoking upgrade_framework for external dependency sync...
# INFO: Cloning proyect_ext/spec-kit/ from github.com/github/spec-kit
# INFO: Cloning proyect_ext/tokenslayer/ from github.com/ajvikram/TokenSlayer
# INFO: Installing graphify via uv tool install graphifyy[mcp]
# OK: upgrade_framework completed successfully
# INFO: Building tokenslayer (--ignore-scripts)...
# OK: tokenslayer build complete
# INFO: Registering MCP: tokenslayer.enabled=true
# OK: Bootstrap completed successfully
```

### Re-ejecución (Idempotencia)

```powershell
# Segunda ejecución en el mismo proyecto
.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools

# Comportamiento:
# - Manifest NO se sobrescribe (usuario pudo personalizarlo)
# - upgrade_framework hace git pull / uv tool upgrade en clones existentes
# - Tokenslayer rebuild solo si fuentes cambiaron (incremental)
# - Sin duplicados, sin errores
```

### Verificación Post-Ejecución

```powershell
# 1. Manifest copiado
Test-Path dependencias-manifest.yml

# 2. Estructura proyect_ext/
Get-ChildItem proyect_ext/
# Debería mostrar: spec-kit/, tokenslayer/

# 3. Tokenslayer compilado
Test-Path proyect_ext/tokenslayer/mcp-server/build/index.js

# 4. 4to MCP registrado en opencode.json
$mcp = Get-Content opencode.json | ConvertFrom-Json
$mcp.mcp | Where-Object { $_.name -eq 'tokenslayer' } | Select-Object name, enabled, command

# 5. graphify instalado
uv tool list | Select-String graphify
```

### DryRun (Simulación Segura)

```powershell
# Ver qué PASARÍA sin ejecutar nada
.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools -DryRun

# Comportamiento:
# - Solo logs informativos ("DryRun: would invoke upgrade_framework...")
# - CERO side effects: no git, no uv, no npm, no escrituras en FS
# - Exit code 0
```

---

## 5. Flujo Típico por Proyecto

```mermaid
flowchart TD
    A[Clonar kit / Copiar a proyecto] --> B{¿Proyecto nuevo?}
    B -->|Sí| C[Bootstrap básico\n.\scripts\plataformador-bootstrap.ps1]
    B -->|No| D[Bootstrap con -SkipSync\n.\scripts\plataformador-bootstrap.ps1 -SkipSync]
    C --> E{¿Necesitas tools externas?}
    D --> E
    E -->|Sí (tokenslayer, spec-kit, graphify)| F[Bootstrap con -ForceUpgradeTools\n.\scripts\plataformador-bootstrap.ps1 -ForceUpgradeTools]
    E -->|No| G[Listo - Solo kit + MCPs base]
    F --> H[Verificar: tokenslayer.build + 4to MCP + graphify]
    G --> H
```

---

## 6. Estructura Esperada Post-Bootstrap

```
<project-root>/
├── .github/                    # Kit transversal (agents, skills, prompts)
├── .opencode/                  # Kit transversal (agents, commands)
├── .doc_agents/                # Documentación de agentes
├── .specify/                   # Constitution + templates (por app en src/<App>/.specify/)
├── scripts/                    # Scripts de bootstrap, relocate, etc.
├── dependencias-manifest.yml   # Manifest de deps externas (copiado del kit si no existía)
├── proyect_ext/                # Deps externas clonadas (solo con -ForceUpgradeTools)
│   ├── spec-kit/
│   ├── tokenslayer/
│   │   └── mcp-server/build/index.js  # Compilado
│   └── (graphify via uv tool)
├── opencode.json               # MCPs registrados (tokenslayer.enabled: true con -ForceUpgradeTools)
├── Documentacion/
│   └── <AppName>/              # Documentación POR APLICACIÓN (nunca tocada por bootstrap)
└── src/
    └── <AppName>/              # Código de la aplicación
        └── .specify/           # Constitution + specs por app
```

---

## 7. Comandos de Verificación Rápida

```powershell
# Kit sincronizado
.\sync-agents.ps1 -DryRun

# Security scan
npx ecc-agentshield scan

# MCPs registrados
cat opencode.json | jq '.mcp[] | {name: .name, enabled: .enabled, type: .type}'

# Estado de índices (context-mode + graphify)
ctx_search "bootstrap"  # si context-mode indexado
# graphify stats si grafo existe
```

---

## 8. Troubleshooting Común

| Problema | Solución |
|----------|----------|
| `pwsh` no encontrado | Instalar PowerShell 7+: `winget install Microsoft.PowerShell` |
| `uv` no encontrado | `pip install uv` o `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Permisos en `proyect_ext/` | Ejecutar como admin o verificar ownership: `icacls proyect_ext /grant Users:F` |
| `tokenslayer` build falla | Verificar Node 18+ y npm 9+; limpiar `node_modules` y reintentar |
| `graphify` no instala | Verificar Python 3.11+ y `uv` actualizado; `uv tool upgrade graphifyy[mcp]` |
| Exit code ≠ 0 | **Nunca debería pasar** — reportar bug (fail-open es obligatorio) |

---

## 9. Referencias

- **Spec #011**: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/spec.md`
- **ADR-0007**: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md`
- **Threat Model**: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/threat-model.md`
- **Converge**: `Documentacion/Agents_IA_TECH/specs/011-bootstrap-invokes-upgrade-framework/converge.md`

---

*Última actualización: 2026-09-25 — spec #011 converge*