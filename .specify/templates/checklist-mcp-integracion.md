# Checklist: integración de un MCP en el kit Agents_IA_TECH

Derivada del estandar `000-mcp-integracion-estandar.md`. Copiar a
`Documentacion/Agents_IA_TECH/specs/###-mcp-<nombre>-integracion/checklists/agents-coverage.md`
y completar al cerrar la spec.

> Regla que decide el sentido de cada punto: **si el cruce da cero agentes para un MCP
> instalado, el defecto esta en los agentes, no en el MCP.** No se retira un MCP instalado
> por no estar declarado; se corrigen los agentes.

---

## 1. Configuracion (RF-03)

- [ ] La entrada vive bajo `mcp.servers.<nombre>` en `opencode.json`, no suelta bajo `mcp`.
- [ ] `mcp.timeout` declara `startup`, `catalog` y `execution`.
- [ ] La entrada **no** usa el campo `enabled` (el schema V2 lo rechaza). Si hace falta
      deshabilitar, se usa `disabled: true`.
- [ ] `command` usa rutas absolutas con forward slashes y entry-point JS directo.
      No usa `{env:...}` (bug OpenCode #5299, ver ADR-0009).
- [ ] `.vscode/mcp.json` tiene su entrada bajo `servers` (formato propio de VS Code).
- [ ] El binario existe en disco y responde a `--version`.
- [ ] `opencode.json` valida contra `https://opencode.ai/config.json` con `jsonschema`:
      **0 errores**.

## 2. Agentes afectados (RF-04)

- [ ] Se identifico que agentes usan el MCP: **transversal** o **por rol**.
- [ ] Cada agente afectado tiene la linea del MCP en su seccion `## Uso de MCPs`,
      con el **nombre real de sus herramientas**.
- [ ] El cambio esta replicado en los **dos arneses**:
      `.github/agents/<nombre>.agent.md` y `.opencode/agents/<nombre>.md`.
- [ ] Los bloques MCP de ambos arneses son **identicos**: 0 desajustes.
- [ ] `AGENTS.md` refleja el reparto si el MCP cambia el transversal o la lista por rol.

## 3. Verificacion anti-huerfano (RF-07)

- [ ] **Cobertura**: todo MCP de `opencode.json` aparece en al menos un bloque
      `Uso de MCPs` de agente. Resultado del cruce: ____ de ____.
- [ ] **Sin huerfanos inversos**: ningun agente declara un MCP ausente de `opencode.json`.
- [ ] **Integridad de archivos**: frontmatter intacto, UTF-8 sin BOM, finales de linea
      preservados en los archivos tocados.
- [ ] **Uso real**: al menos una ejecucion del agente que **llama** la herramienta y
      devuelve resultado. Declararlo no basta.

## 4. Cierre

- [ ] `plan.md` documenta el agente orquestador, parametros y un ejemplo de llamada.
- [ ] `quickstart.md` permite validar instalacion y consumo en menos de 5 minutos.
- [ ] Evidencia de la ejecucion real adjunta a la spec.
- [ ] La spec referencia `000-mcp-integracion-estandar.md` y la 020 (RF-05).

---

## Resultado del cruce

| MCP | Agentes que lo declaran | Cantidad |
|---|---|---|
| (completar) | | |

**Veredicto**: [ ] cerrable · [ ] pendiente por falta de cobertura en agentes

---

## Errores frecuentes

| Sintoma | Causa real | Correccion |
|---|---|---|
| El MCP aparece en `opencode.json` pero ningun agente lo usa | Falta RF-04 | Editar los agentes |
| Los agentes no ven el MCP aunque este instalado | Entrada fuera de `mcp.servers`, o con `enabled`, o con `timeout` entero | Corregir a forma V2 |
| MCPs que arrancan bien salen como `Request timed out` | `mcp.timeout.startup` en su default de 30 s | Subir `startup` y medir el arranque real |
| El bloque existe en `.github/` y no en `.opencode/` | Se edito un solo arnes | Replicar y comparar bloques |
| Un agente declara un MCP que no esta instalado | Quedo de una integracion retirada | Quitar la linea del agente |