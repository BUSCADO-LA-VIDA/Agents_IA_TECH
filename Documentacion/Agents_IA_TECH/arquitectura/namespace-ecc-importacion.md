# Namespace ecc- para importación selectiva de ECC

## 1. Propósito

Definir el namespace `ecc-` como prefijo obligatorio para todo artefacto importado desde el proyecto externo `proyect_ext/ECC` hacia Agents_IA_TECH. El objetivo es permitir importación selectiva de rules, skills, hooks y componentes de AgentShield sin colisiones de nombres, sin duplicar orquestadores y manteniendo `pensador` como orquestador único del kit.

El namespace aplica a skills globales de `.opencode/skills/` y `.github/skills/`, rules siempre cargadas de OpenCode, hooks de sesión y cualquier comando derivado de ECC. No es un re-branding de ECC, es una capa de aislamiento.

## 2. Alcance

- **Incluye**: `proyect_ext/ECC/rules/common/`, `proyect_ext/ECC/rules/<lenguaje>/`, `proyect_ext/ECC/skills/security-scan/`, `proyect_ext/ECC/skills/skill-scout/`, `proyect_ext/ECC/skills/skill-comply/`, `proyect_ext/ECC/skills/verification-loop/`, `proyect_ext/ECC/hooks/`.
- **Excluye**: agentes ECC completos, workflows declarativos ECC, orquestadores ECC, scripts de migración masiva de MCPs que repliquen `.env.mcp`, contextos/workflows que asuman `agents/` de ECC.
- **Paths de escritura permitidos por Constitución Art.VII**: `Documentacion/Agents_IA_TECH/`, `proyect_ext/ECC/`, `.opencode/`, `.github/`, `README.md`. No se escribe en `src/`.

## 3. Definición del namespace ecc-

Todo artefacto importado lleva prefijo `ecc-` en su identificador público.

| Tipo | Esquema de nombre | Ejemplo |
|------|-------------------|---------|
| Skill | `ecc-<nombre-original>` | `ecc-security-scan`, `ecc-skill-scout`, `ecc-verification-loop` |
| Rule | `ecc-<categoria>-<nombre>` | `ecc-common-no-secrets`, `ecc-typescript-immutable-patterns` |
| Hook | `ecc-<evento>-<origen>` | `ecc-pre-tool-session`, `ecc-post-tool-memory` |
| Command | `ecc-<accion>` | `ecc-security-scan`, `ecc-context-budget` |

El prefijo se aplica en el nombre del archivo, en el `slug` de skill de OpenCode, en el `id` de rule y en la clave de hook de `opencode.json`. El contenido interno de la skill o rule puede mantener referencias a ECC, pero el punto de entrada público es siempre `ecc-`.

## 4. Reglas de naming

### 4.1 Skills
- Nombre de archivo: `.opencode/skills/ecc-<nombre>/SKILL.md`
- Metadata `name` dentro de SKILL.md debe iniciar con `ecc-`.
- No se permiten skills con nombre base sin prefijo, aunque el contenido sea idéntico a ECC.
- La descripción debe indicar origen: `Importado selectivamente desde proyect_ext/ECC/skills/<...>` y fecha de importación.
- Versión: se registra `ecc-version` como referencia de commit de ECC en `memoria-proyecto.md`.

### 4.2 Rules
- Ubicación: `.opencode/rules/ecc-<categoria>/<nombre>.md`
- Identificador único: `ecc-<categoria>-<nombre>`.
- Rules de `proyect_ext/ECC/rules/common/` se mapean a `.opencode/rules/ecc-common/`.
- Rules por lenguaje se mapean a `.opencode/rules/ecc-<lenguaje>/`.
- No se duplican rules existentes en `Documentacion/Agents_IA_TECH/`. Si existe regla equivalente con mismo propósito, se fusiona y se mantiene nombre Agents_IA_TECH, descartando la ECC.

### 4.3 Hooks
- Archivo de configuración: `.opencode/hooks/ecc-<evento>.json`
- El `hook-id` en JSON debe iniciar con `ecc-`.
- Los eventos permitidos son `pre-tool`, `post-tool`, `user-prompted`, `session-start`, `session-end`.
- No se permite hook que invoque agentes ECC directamente. Solo se permiten hooks que escriban a `context-mode` vía `ctx_index` o que actualicen `codebase-memory-mcp`.

### 4.4 Commands
- Slash commands en `.opencode/commands/` con prefijo `ecc-` si derivan de ECC.
- No se crea comando que replique `/plan`, `/specify`, `/tasks` de Speckit.

## 5. Reglas de no-duplicación

1. **Un orquestador**: `pensador` es orquestador único. No se importa ningún agente ECC con capacidad de orquestación. Skills importadas deben ser autónomas y sin dependencias de agentes ECC.
2. **Sin duplicar Speckit**: Skills ECC que repliquen flujo `specify → plan → tasks → implement` se descartan. Speckit es fuente de verdad.
3. **Skills existentes**: Antes de importar una skill ECC, se busca en `.opencode/skills/` si existe skill con funcionalidad equivalente. Si existe, se documenta la equivalencia en `memoria-proyecto.md` y se descarta importación.
4. **Rules existentes**: Se compara con rules de `Documentacion/Agents_IA_TECH/arquitectura/` y `.opencode/rules/`. Duplicados se resuelven por fusión, priorizando reglas del kit.
5. **MCPs**: No se duplica configuración de MCPs. La fuente única es `proyect_ext/ECC/mcp-configs/mcp-servers.json` solo como referencia; la activa es `.env.mcp` gestionada por `update-mcp.ps1`.
6. **Nombres**: No se permite coexistencia de `security-scan` y `ecc-security-scan`. Si se importa, el nombre original queda en `proyect_ext/ECC/` sin moverlo al kit.

## 6. Criterios de exclusión

Se excluye de importación cualquier artefacto que cumpla al menos uno de los siguientes criterios:

- **Orquestación ECC**: Agentes ECC con workflows declarativos, `agents/` completos, `rules/` que asuman `agent:` como actor.
- **Dependencia de contexto ECC**: Skills que requieren `contexts/` o `workflows/` de ECC no materializados en `codebase-memory-mcp` o `graphify`.
- **Colisión de nombre**: Existe skill/rule/hook con mismo propósito y mejor cobertura en Agents_IA_TECH.
- **Violación de paths**: Requiere escritura fuera de whitelist Art.VII: `src/<App>/`, `Documentacion/<OtraApp>/`.
- **Seguridad**: Contiene reglas que permiten secretos, acceso a rutas arbitrarias o ejecución de comandos sin allowlist.
- **Complejidad de integración alta con bajo impacto**: Skills de nicho sin evidencia de uso en el kit.
- **Duplicación de Constitución**: Artefactos que contradigan Principios I-IX, especialmente Art.VII Restricción de Paths y Art.IX Contenido Completo.

Lista de exclusiones confirmadas:
- `proyect_ext/ECC/agents/*` completos → no importar.
- `proyect_ext/ECC/workspaces/*` → no materializar.
- `proyect_ext/ECC/scripts/migration-mcp.ps1` → no ejecutar.
- Skills ECC con dependencias de agentes ECC → descartar.

## 7. Procedimiento de importación selectiva

1. Inventario en `proyect_ext/ECC/` con `plataformador`.
2. Filtrado por criterios de exclusión.
3. Asignación de nombre con prefijo `ecc-`.
4. Copia a ruta destino permitida: `.opencode/skills/ecc-.../`, `.opencode/rules/ecc-.../`, `.opencode/hooks/ecc-.../`.
5. Actualización de `memoria-proyecto.md` con origen, versión ECC y fecha.
6. Registro en `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/` con tarea cerrada.
7. Validación `speckit-analyze` y `qa-senior` sobre artefacto importado.

## 8. Validación con Constitución Art.VII

| Tier agente | Ruta de escritura | Aplica a importación ecc- |
|-------------|-------------------|---------------------------|
| Documental | `Documentacion/Agents_IA_TECH/`, `.github/`, `.opencode/`, `.doc_agents/` | Sí, skills/rules/hooks importadas van a `.opencode/` |
| Documental extendido | `src/<App>/.specify/` | No aplica |
| Implementador | `src/<App>/`, `tests/` | No se importa código a src |
| Tooling | Git | No aplica |
| Plataforma | Diagnóstico | `plataformador` valida paths antes de copiar |

Cualquier intento de escribir fuera de whitelist aborta con ERROR fail-closed.

## 9. Ejemplos concretos

- **Skill importada**: `proyect_ext/ECC/skills/security-scan/` → `.opencode/skills/ecc-security-scan/SKILL.md`
  Contenido encabezado: `Origen: proyect_ext/ECC/skills/security-scan/ commit abc123, importado 2026-10-05, namespace ecc-`.

- **Rule importada**: `proyect_ext/ECC/rules/common/no-secrets.md` → `.opencode/rules/ecc-common/no-secrets.md`
  Identificador: `ecc-common-no-secrets`.

- **Hook importado**: `proyect_ext/ECC/hooks/hooks.json` evento `post-tool` → `.opencode/hooks/ecc-post-tool-memory.json`
  `hook-id`: `ecc-post-tool-memory`.

- **Exclusión**: `proyect_ext/ECC/agents/orchestrator.agent.md` → no se copia, queda solo en `proyect_ext/ECC/`.

## 10. Decisiones y riesgos

- **Decisión**: Namespace obligatorio `ecc-` para toda importación.
- **Riesgo mitigado**: Colisión de nombres y confusión de origen.
- **Riesgo residual**: Acumulación de skills `ecc-` sin uso. Mitigación: revisión trimestral en `roadmap.md` y eliminación de skills con 0 invocaciones registradas en `context-mode`.
- **Dependencia**: `sync-agents.ps1` no debe sobrescribir skills `ecc-` al sincronizar kit transversal. Las skills `ecc-` son locales al proyecto y no se propagan al kit maestro.

## 11. Referencias

- Spec: Integración selectiva de ECC como proyecto externo `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/spec.md`
- Priorización `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/priorizacion-012-T005.md`
- Constitución ` .specify/memory/constitution.md` Art.VII Restricción de Paths
- ADR-0005 Orquestación pensador → Agent-SSD

Última actualización: 2026-10-05
Responsable: arquitecto
