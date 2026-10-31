# Plan 031 — Permisos, dominio y delegación de agentes

## Contexto
Spec `031-permisos-y-dominio-de-agentes` definida (24 FR, 7 NFR, 7 US, 12 CA). La nivelación de los 13 agentes a la estructura de Regla 2 ya está ejecutada y verificada (validador: `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0; 20/20 tests del validador). Quedan pendientes el test de contrato (CA-10/CA-12) y el cierre de converge.

## Decisiones del plan (se fijan ahora, no en implementación)

### D1 — Dónde vive cada regla
| Componente | Qué declara | Qué no debe duplicar |
|---|---|---|
| `agent.md` (`.github/` y `.opencode/`) | Dominio de escritura, prohibiciones absolutas, `[S]/[N]/[C]`, sesión SSH única, enfoque, constraints, idioma, MCPs, skills | No repite lógica del validador ni del bootstrap |
| Skill (`SKILL.md`) | Procedimiento reutilizable (ej. `threat-modeling`, `browser-qa`, `ssh-operations`) | No define dominio de agente; solo cómo se ejecuta |
| Validador `scripts/validate-agents-skills.ps1` | Fuente de verdad de conformidad: VAL-01..VAL-09 | No escribe archivos; solo lee y reporta |
| `permission` del bootstrap (`opencode.json` + frontmatter `permission`) | Whitelist de edición/bash/skill por agente | Materializado por el `plataformador`; no se edita a mano |

**Por qué no puede esperar a tasks:** si se define durante la implementación, aparecen las contradicciones de 030 (ej. `terminal`/`execute` sin acotar, `developer` tocando `.github/`). Este plan fija el contrato antes de tocar cualquier archivo nuevo.

### D2 — Técnica de nivelación aplicada
- Ningún agente se reescribe completo con `write`. Se usa edición quirúrgica (`edit`) o restauración de versión completa (`5513d37` para `plataformador`) + adición de las secciones faltantes (`Enfoque`, `Constraints`).
- Resultado: 13 agentes × 2 arneses con cuerpos idénticos línea por línea; solo difiere el frontmatter nativo de cada arnés.
- Estado: **completado y verificado** (VAL-08 = 0).

### D3 — Test de contrato (CA-10/CA-12)
- Qué compara: para cada agente, sección por sección de Regla 2 (introducción, skills, enfoque, MCPs, idioma, constraints) debe existir en ambos arneses con contenido equivalente; `tier`, `description` y conjunto de `skills` idénticos.
- Cómo falla: si falta una sección, si `tier`/`description`/`skills` difieren, o si el cuerpo no es equivalente línea por línea (ignorando solo el frontmatter nativo del arnés).
- Fixture negativo: modificar una sección en un solo arnés debe hacer fallar el test (detecta divergencia unilateral).

### D4 — playwright (decisión B, ya aplicada)
- Declarado en `developer` junto a la skill `browser-qa`. Cierra VAL-07. No se crea excepción versionada; el MCP se mantiene registrado y cubierto.

## Mapeo FR → componente → verificación

| FR | Componente responsable | Verificación |
|---|---|---|
| FR-01 (tier canónico) | frontmatter de cada agente | VAL-04 = 0 |
| FR-02 (description no vacía) | frontmatter de cada agente | VAL-03 = 0 |
| FR-03 (skills resuelven) | SKILL.md de cada skill declarada | VAL-05 = 0 |
| FR-04 (secciones Regla 2) | cuerpo de cada agent.md | VAL-08 = 0 |
| FR-05 (cobertura MCP) | sección MCPs de al menos un agente | VAL-07 = 0 |
| FR-06 (pensador no toca src/) | dominio del pensador | inspección + test de contrato |
| FR-07 (dominio_check) | sección dominio_check en ambos pensador | Select-String |
| FR-08 (bloqueo fuera de dominio + 3 opciones) | texto de dominio_check | test de contrato sobre el texto |
| FR-09 (excepción solo por sesión) | redacción en ambos pensador | inspección |
| FR-10..FR-24 (otros) | solucionador, plataformador, developer, etc. | verificación por archivo |

## Criterio de aceptación del plan
Cada FR-01..FR-24 mapeado a un componente y a una verificación concreta; el test de contrato existe y pasa en verde con la paridad actual.
