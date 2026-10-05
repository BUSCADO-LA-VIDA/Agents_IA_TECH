# Priorización 012-T005 - Importación selectiva ECC: rules, skills, hooks, AgentShield

**Fecha:** 2026-10-05
**Responsable:** pensador
**Origen:** gaps-012-T004.md, inventario proyect_ext/ECC, spec 012-ecc-integration

## Criterios de evaluación

- **Impacto:** Capacidad de cerrar brecha operativa / seguridad / DX. Escala: Muy Alto / Alto / Medio / Bajo
- **Riesgo:** Complejidad de integración, duplicación de orquestador, acoplamiento, superficie de seguridad. Escala: Bajo / Medio / Alto / Crítico
- **Esfuerzo:** Tiempo de adaptación, namespace, pruebas. Escala: Bajo / Medio / Alto

Regla de priorización: Impacto alto + Riesgo bajo/medio + Esfuerzo bajo/medio → Prioridad 1. AgentShield se prioriza por seguridad aunque esfuerzo alto.

## Lista priorizada

### 1. rules/common siempre cargadas
- **Qué:** `proyect_ext/ECC/rules/common/` → `proyect_ext/ECC/rules/common/*.md`
- **Gap cubierto:** No existe mecanismo de rules auto-cargables. ECC tiene rules transversales de seguridad, formato, no-secreto.
- **Impacto:** Muy Alto. Establece guardrails base para todas las sesiones, reduce errores de prompt injection y secretos.
- **Riesgo:** Medio. Necesita namespace `ecc-` y loader compatible con OpenCode. Sin modificación de orquestador.
- **Esfuerzo:** Bajo. Copia selectiva + documento de activación manual. Sin dependencias de runtime.
- **Próximo paso:** Definir loader local `rules/ecc-common/` y lista de reglas activas.

### 2. Hooks de sesión y persistencia de memoria
- **Qué:** `proyect_ext/ECC/hooks/hooks.json`, `hooks.metadata.json`, `memory-persistence/` 
- **Gap cubierto:** Agents_IA_TECH solo tiene `.github/hooks/context-mode.json`. Falta hooks pre-tool/post-tool, user-prompted, persistencia de memoria.
- **Impacto:** Alto. Mejora contexto continuo, reduce re-indexación, habilita triggers de actualización de memoria automática.
- **Riesgo:** Medio. Dependencia de context-mode y formato de hooks de OpenCode. Riesgo de loop de hooks.
- **Esfuerzo:** Medio. Adaptar schemas, mapear eventos, pruebas de idempotencia.
- **Dependencias:** Requiere namespace y validación de no interferencia con Speckit.

### 3. Skills de seguridad y calidad crítica
- **Qué:** `proyect_ext/ECC/skills/security-scan/`, `security-bounty-hunter/`, `security-scan/`, `skill-scout/`, `skill-comply/`, `verification-loop/`
- **Gap cubierto:** Catálogo de skills ECC 292 vs 29 actuales. Seguridad/TDD/research ausente.
- **Impacto:** Alto. Cierra brecha de seguridad proactiva y validación de cambios.
- **Riesgo:** Bajo. Skills son autónomos, ejecución opcional.
- **Esfuerzo:** Medio. Importar 6-8 skills con namespace `ecc-`. Actualizar `.opencode/skills/`.
- **Criterio de selección:** Skills sin dependencias de agentes ECC orquestadores.

### 4. AgentShield integrado como scanner externo
- **Qué:** Integración del comando `/security-scan` y paquete `ecc-agentshield` como herramienta externa de CI/pre-commit.
- **Gap cubierto:** No existe escaneo de hooks, MCP, permisos, secretos específico para agentes.
- **Impacto:** Muy Alto. Reduce riesgo de secretos, permisos excesivos, prompt injection.
- **Riesgo:** Alto. Escáner de seguridad con falsos positivos iniciales. Requiere allowlist y políticas.
- **Esfuerzo:** Alto. Configurar CI, GitHub Action, umbrales, evidencia SARIF, excepción lifecycle.
- **Mitigación:** Uso como modo lectura primero, no bloqueante. Namespace y políticas locales.

### 5. Rules por lenguaje prioritarios
- **Qué:** `rules/typescript/`, `rules/python/`, `rules/react/` → selección de 3 lenguajes principales del kit
- **Gap cubierto:** Rules por lenguaje con convenciones de formato y seguridad ausentes.
- **Impacto:** Medio-Alto. Mejora consistencia de código y seguridad por lenguaje.
- **Riesgo:** Bajo. Rules solo documentación.
- **Esfuerzo:** Medio. Curado de reglas, evitar duplicar reglas existentes en Documentacion.
- **Orden:** TypeScript > Python > React.

### 6. Skills de gestión de contexto y presupuesto de tokens
- **Qué:** `context-budget/`, `token-budget-advisor/`, `unified-memory/`, `unified-notifications-ops/`
- **Gap cubierto:** Falta control de presupuesto de contexto y memoria unificada.
- **Impacto:** Medio. Optimiza costes y evita context rot.
- **Riesgo:** Bajo.
- **Esfuerzo:** Bajo-Medio.

### 7. Hooks Codex y coordinación con AgentShield
- **Qué:** `hooks/codex-hooks.json`
- **Gap cubierto:** Coordinación específica con flujos Codex.
- **Impacto:** Medio. Útil para equipos con Codex.
- **Riesgo:** Medio. Acoplamiento a plataforma externa.
- **Esfuerzo:** Medio.

## Matriz resumen

| Prioridad | Componente | Impacto | Riesgo | Esfuerzo | Justificación |
|-----------|------------|---------|--------|----------|---------------|
| 1 | rules/common | Muy Alto | Medio | Bajo | Guardrails transversales, base de seguridad |
| 2 | Hooks sesión + memoria | Alto | Medio | Medio | Memoria continua, mejora Speckit |
| 3 | Skills seguridad/calidad | Alto | Bajo | Medio | Cierre rápido de brecha crítica |
| 4 | AgentShield integrado | Muy Alto | Alto | Alto | Seguridad proactiva, requiere política |
| 5 | Rules por lenguaje TS/Python/React | Medio-Alto | Bajo | Medio | DX consistente |
| 6 | Skills contexto/presupuesto | Medio | Bajo | Bajo-Medio | Optimización costes |
| 7 | Hooks Codex | Medio | Medio | Medio | Complementario |

## Reglas de importación selectiva

1. **Namespace obligatorio:** `ecc-` para rules/skills/hooks importados.
2. **No importar orquestadores:** No clonar agentes ECC completos. Usar skills puntuales.
3. **Lectura primero:** AgentShield y hooks en modo observador 2 semanas antes de bloquear.
4. **No duplicar Speckit:** Skills que repliquen flujo Speckit se descartan.
5. **Validación Constitución Art.VII:** Solo paths permitidos `Documentacion/Agents_IA_TECH/`, `proyect_ext/ECC/`, `.opencode/`, `.github/`.

## Próximas acciones

- T006: Definir namespace y reglas de no-duplicación
- T007: Escribir guía de integración selectiva con esta priorización
- T008: Actualizar 00-indice.md

## Evidencia

- gaps-012-T004.md líneas 121-137 rules/hooks gap
- inventario proyect_ext/ECC/rules/common/ 12 archivos
- inventario proyect_ext/ECC/hooks/hooks.json
- skills/security-scan/ presente en ECC
