# Hoja de ruta de integración ECC

## Principios
- Mantener flujo Speckit y Constitución como fuente de verdad.
- ECC como proyecto externo en `proyect_ext/ECC`, no reemplazo.
- No duplicar, complementar. Si hay duplicidad, decidir mantener MCP/IA más eficiente.
- Seguridad: comparar AgentShield vs gitleaks + security-scan.

## Estructura actual vs futura

### .github/ y .opencode/
**Actual**: agentes, prompts, skills Speckit.
**Futura**: mantener. Importar skills ECC con namespace `ecc-` en `.github/skills/` y `.opencode/skills/`.
**Modifica**: añadir carpeta `skills/ecc/` con skills importadas selectivamente.
**Mantiene**: agentes `pensador`, `arquitecto`, etc.
**Borra**: nada. Evitar duplicar agentes orquestadores.

### Documentacion/<App>/
**Actual**: specs, ADRs, 00-indice.md, pendientes-implementacion.md.
**Futura**: mantener. Añadir referencia a ECC en `00-indice.md`.
**Modifica**: añadir sección `Integraciones externas` con ECC.
**Mantiene**: todo.

### scripts/
**Actual**: `plataformador-bootstrap.ps1`, `update-mcp.ps1`.
**Futura**: añadir `ecc-sync.ps1` para ciclo de vida ECC.
**Modifica**: `plataformador-bootstrap.ps1` puede invocar `ecc-sync.ps1 -validate`.
**Mantiene**: scripts actuales.

### proyect_ext/
**Actual**: vacío o con dependencias externas.
**Futura**: `proyect_ext/ECC/` clonado, solo lectura.
**Modifica**: crear carpeta y script de sincronización.
**Mantiene**: estructura.

### .env.mcp y .bootstrap-state.json
**Actual**: rutas MCP locales.
**Futura**: mantener. ECC tiene `mcp-configs/`, usar como referencia para estandarizar.
**Modifica**: sincronizar nombres con ECC si aporta estándar.
**Mantiene**: archivos gitignored.

### Seguridad
**Actual**: gitleaks + security-scan.yml + security-auditor.
**Futura**: comparar AgentShield vs gitleaks.
**Decisión**: mantener gitleaks para secretos en repo, añadir AgentShield para escaneo de prompts/hooks/MCP config.
**Modifica**: workflow security-scan para ejecutar AgentShield además de gitleaks.
**Borra**: nada.

### MCPs vs IA
**Mantener MCPs eficientes**:
- `context-mode`, `codebase-memory-mcp`, `graphify`, `markitdown` se mantienen. Son más eficientes que IA pura para memoria y búsqueda.
**Optimizar**:
- Usar hooks ECC para resumir sesiones y reducir tokens.
- Usar skills ECC de research para evitar llamadas IA repetidas.
**Sustituir**:
- Si ECC ofrece MCP de memoria más eficiente, evaluar migración.

### Duplicidades a identificar
- Agentes orquestadores: ECC tiene orquestadores, nosotros tenemos `pensador`. Mantener `pensador`.
- Skills de security: ECC tiene security skills, nosotros tenemos `security-auditor`. Complementar, no reemplazar.
- Rules: ECC `rules/` vs nuestras reglas transversales. Fusionar `rules/common`.

### Roadmap por fases
**Fase 0**: Documentación y matriz.
**Fase 1**: Clonar ECC en proyect_ext, crear ecc-sync.ps1.
**Fase 2**: Importar rules/common y skills selectivos con namespace.
**Fase 3**: Integrar hooks de sesión y AgentShield.
**Fase 4**: Validar flujo Speckit y MCPs.
**Fase 5**: Documentar mantenimiento y actualizaciones.

### Criterios de decisión de duplicidad
1. Si ECC usa IA pura y nosotros tenemos MCP → mantener MCP.
2. Si ECC es más eficiente en tokens → evaluar sustitución.
3. Si funcionalidad es idéntica → mantener la nuestra por Constitución.
