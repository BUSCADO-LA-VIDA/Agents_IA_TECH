# Research: 007-mcp-token-resolution

**Feature**: `007-mcp-token-resolution`
**Date**: 2026-09-24
**Plan**: [plan.md](./plan.md)

Hallazgos y decisiones que resuelven las incógnitas del Technical Context. Base: lectura del código real (`scripts/plataformador-bootstrap.ps1`, 2840 líneas), `opencode.json`, `.gitignore`, y docs oficiales de OpenCode.

---

## R-01 — ¿OpenCode carga `<root>/.env.mcp` automáticamente?

**Decision**: NO asumirlo. El mecanismo efectivo es el campo `environment` del MCP local + rutas reales en `command`; `.env.mcp` se mantiene como **fuente de verdad portable/legible**.

**Rationale**: La doc oficial de OpenCode (`/docs/mcp-servers`) documenta:
- `command: [...]` para el MCP local.
- `environment: { VAR: value }` para variables del proceso del servidor.
- `enabled`, `cwd`, `timeout`.

La interpolación `{env:VAR}` sustituye variables del **entorno del proceso** (se usa ya `{env:NVIDIA_API_KEY}`). La doc **no** documenta carga automática de un `.env` ad-hoc (`opencode.json` no tiene campo `.env`). Un archivo llamado `.env.mcp` no aparece en el contrato público.

**Alternatives considered**:
1. **Confiar en `.env.mcp` + `{env:...}` solo** — riesgo de string vacío → MCP roto. Rechazado (R1 del plan).
2. **Solo rutas reales en `command`** (comportamiento actual) — funciona pero no es portable ni es "fuente de verdad" legible. Insuficiente para RF-03.
3. **Híbrido (elegido)**: `.env.mcp` como fuente de verdad + `environment` (o ruta real) como mecanismo efectivo. Cumple RF-03 y RNF-01 sin depender de un comportamiento no documentado.

**Impact**: D2 incorpora fallback explícito. `quickstart.md` documenta el contrato (exportar vars o confiar en `environment`).

---

## R-02 — ¿Por qué la re-resolución de tokens no corre siempre?

**Decision**: Mover el bloque de re-resolución (L395-414) a una fase **incondicional** tras el `if/else` de creación.

**Rationale**: Verificado en el código:
- L358-360: `if ($existing.mcp -and -not $Force) { Write-OK "...se conserva..." }` — rama temprana que **no entra** al `else` de creación (L361-393).
- L395-414 está **después** del `if/else` pero condicionado a `if (-not $DryRun -and ($null -ne $existing.mcp))`; sin embargo, con `mcp` existente sin `-Force`, la plantilla no se re-asigna, y la re-resolución solo actúa sobre `$existing.mcp` (que sí existe) — **pero** el guard real del bug es que cuando `mcp` existe, los tokens no están presentes (ya se resolvieron antes) o quedan `__*_CMD__` sin re-resolver porque la condición del token `$cmd0 -eq $tokenMap[$name].Token` falla si el valor es `{env:...}` o una ruta. La corrección es que la re-resolución **evalúe tanto `__*_CMD__` como `{env:...}` y rutas vacías**, y corra siempre.

**Alternatives considered**:
1. Solo eliminar el early-return de L359-360 — insuficiente: no cubre el caso `{env:...}`.
2. Reescribir `Ensure-OpenCodeMcp` completa — mayor riesgo de regresión (R4). Rechazado.
3. **Parche quirúrgico por entrada (elegido)**: tocar solo `command` y `enabled`.

**Impact**: D1.

---

## R-03 — ¿El sync sobrescribe `opencode.json` resuelto?

**Decision**: Sí, es un riesgo real (RF-06 punto 4). Mitigar con `-SkipSync` en el kit y tratando `opencode.json` en `Sync-TransversalKit`.

**Rationale**: Verificado en `Sync-TransversalKit` (L1801-1900+): `$transversalFiles` (L1851-1857) incluye `opencode.json`, y `$transversalItems` (L1873-1883) lo copia del clon a `$RootPath` (`Type = "File"`). Esto pisa lo resuelto en runtime. El script `plataformador-bootstrap.ps1` **NO** está en esa lista (brecha que cubre `Update-Self`).

**Alternatives considered**:
1. Excluir `opencode.json` del sync — rompe la propagación de la plantilla base. 
2. Hash-guard como `.opencode/.gitignore` — posible pero más complejo; excede el alcance ("Fuera de Alcance": no rediseñar el sync más allá de excluir/ajustar el manejo de `opencode.json`).
3. **`-SkipSync` + documentar el ajuste (elegido)**.

**Impact**: D5, R3.

---

## R-04 — ¿`Update-Self` ya cumple RF-05?

**Decision**: Sí, en su mayor parte. Solo endurecer limpieza de temp.

**Rationale**: Verificado `Update-Self` (L1721-1799):
- `DryRun` informa (L1727-1730). ✅
- Allowlist URL (`Test-TrustedGithubUrl`, L1733-1736). ✅ (extra de seguridad)
- Auto-skip kit por `origin == RepoUrl` (L1753-1756). ✅
- Clone shallow a `$env:TEMP\agents-selfupdate-temp` (L1759-1769). ✅
- SHA256 local vs clon (L1779-1785). ✅
- Sobrescribir + re-ejecutar con `@script:PSBoundParameters` + `exit` (L1788-1798). ✅
- Invocado antes del paso 1, gated por `-SkipSelfUpdate` (L2681-2684). ✅

Gaps menores: limpieza de temp en todos los `return` (L1776 borra, L1783 borra, L1794 borra; L1767/1768 no crea temp aún). Sin gap crítico.

**Alternatives considered**: Reimplementar (innecesario, duplicaría lógica probada).

**Impact**: D4 (solo verificación).

---

## R-05 — ¿graphify/tokenslayer ausentes ya se manejan?

**Decision**: Sí. Homogeneizar el patrón y asegurar el reporte (D7).

**Rationale**: Verificado:
- `Configure-Graphify` L2523-2530: si `python -m graphify.serve --help` falla → `Write-Warn` con `uv tool install "graphifyy[mcp]"` y **no registra** (el registro está tras el guard). ✅ RF-07 graphify.
- tokenslayer L449-452: si falta `mcp-server/build/index.js` → `Write-WarnOnce` con instrucciones de clonado+build y no registra. ✅ RF-07 tokenslayer.
- Containment-check L436-445. ✅ RNF-07.

**Alternatives considered**: Ninguna; ya cumple. Solo falta la trazabilidad del estado en el reporte (D7).

**Impact**: D6, D7.

---

## R-06 — Interpolación `{env:VAR}`: ¿string vacío si no está seteada?

**Decision**: Asumido como verdadero (spec) y mitigado por R-01.

**Rationale**: Confirmado en docs: `{env:VARIABLE_NAME}` sustituye variables de entorno; si no está seteada → string vacío. Ya usado con `{env:NVIDIA_API_KEY}`, `{env:DEEPINFRA_API_KEY}` en `opencode.json`.

**Impact**: Refuerza la necesidad del fallback D2.

---

## Resumen de resolución de incógnitas

| Incógnita | Estado |
|-----------|--------|
| Carga de `.env.mcp` por OpenCode | RESUELTA → NO automática asumida; fallback `environment`/ruta real |
| Alcance real del bug de re-resolución | RESUELTA → early-return + no evaluación de `{env:...}` |
| Sync sobrescribe `opencode.json` | CONFIRMADA → `-SkipSync` |
| `Update-Self` existe y cumple | CONFIRMADA → solo endurecer |
| graphify/tokenslayer ausentes | CONFIRMADA → ya manejado, falta reporte |
| `{env:}` vacío si no seteada | CONFIRMADA → fallback |
