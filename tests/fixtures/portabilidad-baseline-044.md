# Baseline F0 — Spec 044 (portabilidad: validación sin exclusiones de directorio)

**Fecha**: 2026-11-09
**Universo de medición**: `git ls-files` (todo archivo versionado, sin allowlist de directorios)
**Patrones**: construidos por concatenación de fragmentos (`('C:' + <separador> + 'Proyectos')`, etc.) para que el propio instrumento no se autoincumpla

## 1. Defecto del validador previo (Spec 039)

El validador `tests/validate-no-hardcoded-paths.Tests.ps1` versión 039 definía su universo con una **allowlist de rutas**:

| Ruta incluida | Consecuencia |
|---|---|
| `README.md`, `AGENTS.md` | Cubiertos |
| `scripts/*.ps1` | Cubierto, salvo autoexclusión de `plataformador-bootstrap.ps1` |
| `.github/**/*.md`, `.opencode/**/*.md`, `.doc_agents/*.md`, `Documentacion/**/*.md` | Cubiertos |
| **`tests/`** | **No cubierto** |
| **`.specify/`** | **No cubierto** |
| **`.mcp.json`, `opencode.json`** | **No cubierto** |
| **`.bootstrap-audit.log`** | **No cubierto** |

Resultado: el test daba verde con 34 archivos versionados contaminados. Falso negativo estructural, no un caso puntual.

## 2. Coincidencias antes de la remediación

| Grupo de artefacto | Archivos | Coincidencias |
|---|---:|---:|
| Artefactos de ejecución (audit log + `.specify/mcp-validation-*`) | 4 | 105 |
| Configuración de arnés con rutas resueltas (`opencode.json`, `.mcp.json`) | 2 | 21 |
| Código de detección autoexcluido (bootstrap + test) | 2 | 11 |
| Script con default de la máquina del autor | 1 | 1 |
| Fixture `tests/fixtures/baseline-036.md` | 1 | 2 |
| Documentación, bitácoras, specs, ADRs, threat models | 24 | 96 |
| **Total** | **34** | **236** |

## 3. Coincidencias después de la remediación

| Comprobación | Resultado |
|---|---|
| Grupos de patrón evaluados por Pester | 14 |
| Comprobaciones meta (universo poblado + sin allowlist) | 2 |
| Total | **16 en verde, 0 en rojo** |
| Archivos versionados en el universo | 764 |

## 4. Decisiones de remediación que afectan a este baseline

| Archivo | Acción | Motivo |
|---|---|---|
| `.bootstrap-audit.log` | Sale del índice git (`git rm --cached`); **no se reescribe** | Cadena de hashes append-only: reescribirla destruye la evidencia; versionarla publica `host`, `actor` y layout del FS |
| `opencode.json` | Sale del índice; se versiona `opencode.template.json` con tokens y `enabled: false` | El bootstrap no lo genera desde cero y el archivo resuelto es específico de la máquina (spec 038 D2) |
| `.specify/mcp-validation-*.md` | **Se conservan** versionados, con rutas redactadas a tokens | Son evidencia de la validación MCP previa: borrarlas destruye trazabilidad |
| `upgrade_framework.ps1` | Rutas fijas sustituidas por `Join-Path $PSScriptRoot ...` | Bug real: el script solo funcionaba en la máquina del autor |

## 5. Nota sobre interpretación

Un "verde" de este baseline significa **cero coincidencias en el universo completo**, no cero coincidencias en una lista elegida por el autor del test. Ese es exactamente el cambio que la Spec 044 introduce.
