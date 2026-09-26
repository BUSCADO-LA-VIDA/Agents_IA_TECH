# Spec: Integración selectiva de ECC como proyecto externo

## User Story
Como mantenedor del kit Agents_IA_TECH, quiero incorporar capacidades de ECC como proyecto externo en `proyect_ext/ECC` sin reemplazar mi flujo Speckit/SSD, para mejorar memoria continua, hooks, AgentShield y catálogo de skills manteniendo mi orquestador `pensador` y Constitución.

## Contexto
ECC es un agent harness con 68 agentes, 292 skills, hooks, rules, workflows y contextos. Mi kit actual tiene pipeline Speckit, Constitución por proyecto, MCPs gestionados y agentes documentales/implementadores. No se busca migrar, sino complementar.

## Requisitos Funcionales
FR-001: Clonar ECC en `C:\Proyectos\Agents_IA_TECH\proyect_ext\ECC` como referencia externa, sin modificar estructura actual.
FR-002: Mapear estructura clave ECC a mi estructura: .agents/agents/skills/commands/rules/hooks/mcp-configs/workflows/contexts.
FR-003: Identificar capacidades ECC no presentes: hooks de sesión, memoria continua, AgentShield, rules siempre cargadas.
FR-004: Definir importación selectiva de rules/common y skills de security/TDD/research.
FR-005: Mantener flujo actual `pensador` -> Speckit -> implementadores.
FR-006: Documentar correspondencias y límites de integración.

## Requisitos No Funcionales
NFR-001: No se modifica código fuente de apps en `src/`.
NFR-002: No se versiona ECC completo, solo referencias y adaptaciones.
NFR-003: Constitución del proyecto se mantiene como fuente de verdad.

## Criterios de Aceptación
SC-001: Carpeta `proyect_ext/ECC` existe y está documentada.
SC-002: Matriz de correspondencia ECC ↔ Agents_IA_TECH creada.
SC-003: Lista de capacidades a importar definida y priorizada.
SC-004: Spec, plan y tasks generados sin ejecutar cambios.
SC-005: Flujo actual no se ve alterado.

## Riesgos
- Duplicación de agentes/orquestadores. Mitigación: ECC como proveedor de capacidades, no orquestador.
- Conflicto de nombres de skills. Mitigación: namespace `ecc-`.
