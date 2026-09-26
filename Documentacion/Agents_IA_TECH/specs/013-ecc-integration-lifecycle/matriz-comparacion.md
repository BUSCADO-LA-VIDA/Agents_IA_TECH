# Matriz de comparación ECC ↔ Agents_IA_TECH

| Área | ECC | Agents_IA_TECH actual | Correspondencia | Acción de integración |
|------|-----|----------------------|-----------------|----------------------|
| Orquestación | Agentes ECC con workflows declarativos | pensador + Speckit pipeline | Parcial | Mantener pensador como orquestador superior |
| Agentes | 68 agentes en agents/ | 14 agentes en .github/.opencode | Diferente | Importar selectivo con namespace ecc- |
| Skills | 292 skills | Skills Speckit + globales | Complementario | Importar skills de security/TDD/research |
| Rules | rules/ siempre cargadas | Reglas transversales en Documentacion | Similar | Fusionar rules/common |
| Hooks | hooks/ runtime | Sin hooks de sesión | Nuevo | Adaptar hooks de memoria y AgentShield |
| MCPs | mcp-configs/ | .env.mcp + update-mcp.ps1 | Similar | Referenciar, no duplicar |
| Workflows | workflows/ declarativos | tasks.md + Speckit | Complementario | Mapear workflows a tasks |
| Contextos | contexts/ persistentes | context-mode + codebase-memory | Similar | Integrar como capa adicional |
| Seguridad | AgentShield | gitleaks + security-scan | Complementario | Añadir AgentShield a pipeline |
| Documentación | docs/ | Documentacion/<App>/ | Diferente | Mantener separación por app |

**Conclusión**: ECC aporta hooks, memoria continua, AgentShield y catálogo de skills. No reemplaza Speckit ni Constitución.
