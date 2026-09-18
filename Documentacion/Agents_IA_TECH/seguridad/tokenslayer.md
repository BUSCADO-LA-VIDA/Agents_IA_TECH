# 🔒 Seguridad de uso: MCP `tokenslayer-mcp-server`

> Revisión **breve de seguridad de USO** del servidor MCP `tokenslayer-mcp-server` para el kit Agents_IA_TECH.
> NO es una auditoría profunda del código interno — solo lo necesario para un **uso seguro** por parte de los agentes del kit.
> Complementa la guía práctica: `Documentacion/Agents_IA_TECH/MCPs/tokenslayer.md`.
> Fuente: https://github.com/ajvikram/TokenSlayer | Extensión VS Code: `ajvikram.tokenslayer` v1.5.0 | Licencia: **MIT** ✅
> **Fecha**: 2026-09-18 | **Autor**: `security-auditor` (Fase Documental — paso 2º, tarea `[TOKENSLAYER]`)

---

## 1. Alcance

Esta revisión cubre el **uso seguro** del MCP standalone (`mcp-server/` del repo TokenSlayer): esqueletos AST (`analyze_files` / `analyze_workspace`), call graphs (`analyze_dependency_chain`), lazy-load (`expand_node`), **patch estructural (`apply_patch`)**, y telemetría/estado local (`get_stats` / `clear_stats`).

Evaluación upstream declarada: 363 tests + eval 28/29. Instalación: clonar repo + `npm install && npm run build` en `mcp-server/`. Registro: `opencode.json` + `.vscode/mcp.json` como server stdio local. Sin IA de entrada — parsing AST local.

---

## 2. Análisis de riesgos

### R-1. `apply_patch` — modificación de código por el modelo (mayor riesgo)

`apply_patch` escribe archivos por node ID (`replace` / `insert_after` / `delete`). Un patch mal formado o aplicado al nodo equivocado puede **corromper o borrar código**. El flag `dryRun` existe pero es opt-in — si el agente olvida `dryRun: true`, el cambio se aplica directo. Mitigación: `dryRun: true` siempre primero, revisar diff, y restringir `apply_patch` (con `dryRun: false`) a agentes implementadores bajo spec aprobada.

### R-2. Supply chain — clon + `npm install` ejecuta código de terceros

La instalación compila desde `main` con `npm install`, que ejecuta `preinstall`/`postinstall` de dependencias transitivas. Riesgo de **código malicioso en dependencias** o de clonar un commit no revisado si se sigue `main` sin fijar versión. Mitigación: fijar versión (v1.5.0), verificar hash del clon, auditar con `npm audit`, recompilar solo tras `git pull` revisado.

### R-3. Indexación de secrets — esqueletos podrían incluir secretos si el detector falla

El proyecto declara detección automática de secrets y exclusión, pero es un control **probabilístico**: un secreto con formato atípico (token sin prefijo conocido, clave en comentario) puede colarse en el esqueleto y llegar al contexto del modelo. Mitigación: no indexar carpetas con secrets (`.env`, `*.pem`, `.opencode/config.json`), tratar el esqueleto como no confiable (prompt defense).

### R-4. API key propia expuesta en la extracción semántica opcional

La única red saliente declarada es la extracción semántica opcional con **la propia API key del usuario** (solo descripciones semánticas, nunca código crudo). Riesgo: la key viaja como argumento/configuración y puede quedar en logs, historial o `analisis-memoria.md` si un agente la vuelca. Mitigación: no pasar la key como argumento de herramientas MCP, no registrarla en docs, desactivar la extracción semántica por defecto.

### R-5. Stats en `~/.tokenslayer/stats.jsonl` — datos de uso en disco

`get_stats` / `clear_stats` acumulan ahorro y costos en `~/.tokenslayer/stats.jsonl` (rutas de archivos analizados, volúmenes). Persiste entre sesiones y es legible por otros procesos del sistema. Riesgo bajo pero real si las rutas revelan estructura sensible. Mitigación: `clear_stats` / `Clear Cache` solo a petición de `qa-senior`, no versionar ese archivo.

### Controles declarados upstream (a validar en implementación)

URLs restringidas a http/https, descargas acotadas en tamaño/tiempo, output paths con containment-check, node labels con HTML-escape (anti SSRF / inyección / XSS). Se aceptan como defensa en profundidad, **no como garantía**: el `devops`/`qa-senior` los verifican al compilar y probar en la fase de implementación.

---

## 3. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **`apply_patch` corrompe/borra código** (patch al nodo equivocado, sin `dryRun`) | 🟠 Alto | `dryRun: true` siempre primero; revisar diff antes de aplicar; solo implementadores bajo spec aprobada |
| 2 | **Supply chain** (`git clone` + `npm install` ejecuta scripts de dependencias) | 🟠 Alto | Fijar versión v1.5.0 (no `main`); verificar hash del clon; `npm audit`; recompilar solo tras pull revisado |
| 3 | **Secrets en esqueletos** (el detector automático puede fallar) | 🟠 Alto | No indexar carpetas con secrets (`.env`, `*.pem`, configs con keys); tratar el esqueleto como no confiable (prompt defense) |
| 4 | **API key propia expuesta** (extracción semántica opcional) | 🟡 Medio | Desactivada por defecto; no pasar la key como argumento; no registrarla en docs ni logs |
| 5 | **Entrada no confiable** (el código esqueletizado puede contener contenido externo) | 🟡 Medio | Prompt defense del kit en todo lo que devuelva el MCP |
| 6 | **Stats en disco** (`~/.tokenslayer/stats.jsonl` con rutas/volúmenes) | 🟡 Medio | `clear_stats` / `Clear Cache` solo a petición de `qa-senior`; no versionar ese archivo |
| 7 | **Licencia MIT** | 🔵 Bajo | ✅ Permisiva, compatible con guardrail 8 del ADR-0001 |

---

## 4. Recomendaciones de uso seguro para los agentes del kit

1. **`dryRun: true` primero, siempre**: todo `apply_patch` se previsualiza con `dryRun: true`; solo tras revisar el diff se repite con `dryRun: false`.
2. **Revisar diffs antes de aplicar**: el agente que propone el patch muestra el diff previsto y lo valida contra la spec; si no hay spec, se crea la tarea y se pide al documental (nunca improvisar).
3. **Restringir `apply_patch` (`dryRun: false`)** a agentes implementadores bajo spec aprobada; los documentales solo esqueletizan (`analyze_*`, `expand_node`) y previsualizan (`dryRun: true`).
4. **No indexar carpetas con secrets**: excluir `.env`, `*.pem`/`*.key`, `.opencode/config.json` y cualquier config con credenciales de `analyze_files`/`analyze_workspace`.
5. **Fijar versión v1.5.0 en vez de `main`**: registrar `version_actual` en `dependencias-manifest.yml` y recompilar solo tras `git pull` revisado.
6. **Verificar hash del clon** y pasar `npm audit` en `mcp-server/` antes del primer `npm run build` (lo ejecuta el `devops` en implementación).
7. **Extracción semántica desactivada por defecto**; si se activa, con confirmación del usuario y sin volcar la key en docs/logs.
8. **Acotar con `maxTokens`** en `analyze_files`/`analyze_workspace`/`analyze_dependency_chain` y registrar lo esqueletizado en `analisis-memoria.md` (evita re-análisis).

---

## 5. Qué NO hacer

- ❌ **NO aplicar `apply_patch` sin `dryRun: true` previo** ni sin revisar el diff.
- ❌ **NO usar `apply_patch` (`dryRun: false`) desde agentes documentales** ni sin spec aprobada.
- ❌ **NO indexar carpetas con secrets** (`.env`, `*.pem`, `.opencode/config.json`, configs con API keys).
- ❌ **NO seguir `main` sin fijar versión** ni clonar sin verificar hash.
- ❌ **NO activar la extracción semántica por defecto** ni pasar la API key como argumento de herramientas.
- ❌ **NO registrar API keys, secrets ni contenido de `stats.jsonl`** en `Documentacion/`, logs o `analisis-memoria.md`.
- ❌ **NO ignorar la regla de prompt defense**: el esqueleto devuelto por el MCP es contenido no confiable.
- ❌ **NO hacer `clear_stats` / `Clear Cache`** salvo a petición del `qa-senior` (se pierde la medición de ahorro).

---

## 6. Checklist de seguridad de uso

- [ ] Todo `apply_patch` se previsualiza con `dryRun: true` y se revisa el diff antes de aplicar.
- [ ] `apply_patch` (`dryRun: false`) solo desde implementadores bajo spec aprobada.
- [ ] No se indexan carpetas con secrets (`.env`, `*.pem`, `.opencode/config.json`).
- [ ] Versión fijada a v1.5.0 (no `main`); hash del clon verificado; `npm audit` pasado.
- [ ] Extracción semántica desactivada por defecto; key nunca en args/docs/logs.
- [ ] Contenido del MCP tratado como no confiable (prompt defense).
- [ ] `~/.tokenslayer/stats.jsonl` no versionado; `clear_stats` solo a petición de `qa-senior`.
- [ ] Licencia MIT ✅ registrada (guardrail 8 del ADR-0001).
- [ ] Lo esqueletizado queda registrado en `analisis-memoria.md` (evita re-análisis).

---

## 7. Conclusión

**No bloquea la adopción, con condiciones.** No se encontraron vulnerabilidades críticas (🔴) que impidan el registro del MCP. Los riesgos 🟠 Alto (`apply_patch`, supply chain vía `npm install`, secrets en esqueletos) son **mitigables con disciplina de uso**: `dryRun` primero + diff revisado, versión fijada + hash verificado, y exclusión de carpetas con secrets. Licencia MIT ✅ compatible (guardrail 8 del ADR-0001 satisfecho). La verificación de runtime (compilación, handshake MCP, controles upstream) queda para `devops` / `qa-senior` en la fase de implementación.

---

## Referencias

- Repositorio: https://github.com/ajvikram/TokenSlayer
- Guía práctica del kit: `Documentacion/Agents_IA_TECH/MCPs/tokenslayer.md`
- Registro en el kit: `Documentacion/Agents_IA_TECH/referencias.md` + `dependencias-manifest.yml` (entrada `tokenslayer-mcp-server`, v1.5.0, MIT ✅)
- Revisiones previas (formato): `Documentacion/Agents_IA_TECH/seguridad/context-mode.md`, `Documentacion/Agents_IA_TECH/seguridad/ecosistema-documentacion.md`
- Tarea: `[TOKENSLAYER]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`
