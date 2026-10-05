# ADR-012-ECC-Integration

**Estado:** Aceptada  
**Fecha:** 2026-10-05  
**Autor:** Arquitecto  
**Especificación:** 012-ecc-integration  
**Referencia Constitución:** Art.VII Restricción de Paths por Tier, Art.IX Contenido Completo

## Contexto

Agents_IA_TECH mantiene pipeline Speckit con orquestador `pensador`, 16 agentes propios, 29 skills Speckit y Constitución por proyecto como fuente de verdad. ECC es un agent harness externo con 68 agentes, 292 skills, rules siempre cargadas, hooks de sesión/memoria y AgentShield.

Objetivo: incorporar capacidades ECC como proyecto externo en `proyect_ext/ECC` sin reemplazar flujo Speckit/SSD, manteniendo Constitución y evitando duplicación de orquestadores.

Requisitos de partida de spec.md 012-ecc-integration:
- Clonar ECC en `proyect_ext/ECC` sin modificar estructura actual.
- Mapear estructura clave ECC a estructura del kit.
- Identificar capacidades no presentes: hooks sesión, memoria continua, AgentShield, rules siempre cargadas.
- Definir importación selectiva de rules/common y skills security/TDD/research.
- Mantener flujo `pensador` → Speckit → implementadores.

## Decisión

Se adopta integración selectiva de ECC con las siguientes reglas vinculantes:

1. ECC se mantiene como proyecto externo de referencia en `proyect_ext/ECC`. No se versiona su contenido, solo referencias y adaptaciones en `Documentacion/Agents_IA_TECH/`.
2. Toda importación de componente ECC debe usar namespace obligatorio `ecc-` en nombre de archivo, frontmatter y rutas destino.
3. Solo se importan componentes de tipo rule, skill y hook. No se importan agentes ECC completos ni orquestadores.
4. La importación es selectiva y priorizada según `priorizacion-012-T005.md` y `gaps-012-T004.md`.
5. El orquestador `pensador` y el pipeline Speckit se mantienen como única cadena de gobierno. ECC actúa como proveedor de capacidades, no como orquestador.
6. Toda copia se realiza a paths permitidos por Constitución Art.VII para el tier documental.
7. Modo inicial observador para hooks y AgentShield mínimo 2 semanas antes de activar bloqueos.

## Alternativas consideradas

- **Migración completa a ECC:** Rechazada. Implica reemplazar Speckit, Constitución y orquestador `pensador`. Rompe Art.IV Compatibilidad Copilot/Opencode y Art.III Specification-Driven Development.
- **Importar agentes ECC completos:** Rechazada. Genera duplicación de orquestadores y conflicto de nombres. Violación de principio de modularidad Art.I.
- **Copiar ECC a Documentacion sin namespace:** Rechazada. Imposible distinguir origen, riesgo de colisiones y pérdida de trazabilidad.
- **No integrar:** Rechazada. Deja sin aprovechar hooks de sesión, memoria continua, AgentShield y catálogo de skills de seguridad.

## Namespace ecc-

Regla de nombrado obligatoria para todo elemento importado:

- Prefijo de archivo: `ecc-<nombre-original>.md` o `ecc-<skill>/SKILL.md`
- Frontmatter mínimo:
  ```
  origen: proyect_ext/ECC/...
  namespace: ecc-
  tipo: rule|skill|hook
  fecha_importacion: YYYY-MM-DD
  ```
- Rutas destino:
  - Rules: `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-common/` y `ecc-lang/`
  - Skills: `.github/skills/ecc-<skill>/` y `.opencode/skills/ecc-<skill>/`
  - Hooks: `.github/hooks/ecc/`
- Registro obligatorio en `manifiesto-importaciones.md` con fecha, tipo, origen, destino, namespace y validador.

## Criterios de exclusión

No se importan los siguientes elementos ECC:

1. Agentes completos de ECC. Motivo: evitar duplicación de orquestadores y mantener `pensador` como único coordinador. Lista excluida completa en `gaps-012-T004.md` 68 agentes.
2. Skills que repliquen flujo Speckit: specify, plan, tasks, analyze, converge, implement. Motivo: no duplicar pipeline ya existente.
3. Scripts de orquestación ECC que asuman control de sesión o worktrees fuera de paths permitidos. Motivo: Art.VII restricción de paths.
4. Rules que dupliquen contenido existente en `Documentacion/Agents_IA_TECH/` sin valor añadido. Validación por comparación textual antes de importar.
5. Componentes con dependencias de agentes ECC o referencias a rutas absolutas externas. Motivo: genericidad y ausencia de rutas absolutas.
6. Cualquier componente que requiera escritura en `src/<App>/` por agentes documentales. Motivo: Art.VII tier Documental no escribe código.

Criterio de inclusión:
- Skills de seguridad, calidad, contexto, presupuesto de tokens, verificación.
- Rules common de seguridad, hooks, coding-style, git-workflow, testing.
- Hooks de sesión y persistencia de memoria en modo observador.
- AgentShield en modo lectura.

## Cumplimiento Constitución Art.VII Restricción de Paths por Tier

Tier aplicable a esta integración: Documental y Documental extendido.

Whitelist de escritura vigente:

| Tier | Agentes | Rutas permitidas |
|------|---------|------------------|
| Documental | pensador, arquitecto, documentador, security-auditor | Documentacion/<AppName>/, .github/, .opencode/, .doc_agents/, README.md |
| Documental extendido | Agent-SSD | src/<App>/.specify/, Documentacion/<AppName>/specs/, .github/, .opencode/, .doc_agents/, README.md |
| Implementador | api-developer, frontend-developer, devops, qa-senior | src/<App>/, tests/ |
| Tooling | gitflow | Ramas, commits, PRs |
| Plataforma | solucionador, plataformador | Diagnóstico remoto |

Mapeo de importaciones a rutas permitidas:

- Rules importadas → `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-common/` y `ecc-lang/`. Permitido para Documental.
- Skills importadas → `.github/skills/ecc-*/` y `.opencode/skills/ecc-*/`. Permitido para Documental.
- Hooks importados → `.github/hooks/ecc/`. Permitido para Documental.
- Manifiesto y guía → `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/`. Permitido para Documental.
- Referencia externa → `proyect_ext/ECC/`. Permitido por principio VI Gestión de Dependencias Externas.

No se escribe en `src/<App>/`. No se modifica código de aplicación. No se crean agentes ECC completos. Todo cambio queda dentro de whitelist del tier Documental.

Verificación obligatoria antes de commit:
- git status solo muestra archivos en paths permitidos.
- No existe ruta `Documentacion/<OtraApp>/`.
- No se crean rutas absolutas.

## Consecuencias

Positivas:
- Acceso a rules siempre cargadas y skills de seguridad sin reemplazar Speckit.
- Hooks de sesión y memoria continua disponibles en modo observador.
- Catálogo de skills ECC accesible con trazabilidad de origen vía namespace ecc-.
- Constitución mantenida como fuente de verdad.

Negativas y mitigaciones:
- Riesgo de duplicación de skills. Mitigado por namespace ecc- y validación de no-duplicación antes de importar.
- Sobrecarga de skills. Mitigado por priorización en `priorizacion-012-T005.md`.
- Confusión de orquestadores. Mitigado por criterio de exclusión de agentes ECC completos y documentación de límites.
- Hooks conflictivos con context-mode. Mitigado por modo observador y pruebas de idempotencia.

## Referencias

- spec.md 012-ecc-integration
- plan.md 012-ecc-integration
- tasks.md 012-ecc-integration
- guia-integracion-selectiva.md
- gaps-012-T004.md
- priorizacion-012-T005.md
- Constitución Agents_IA_TECH Art.VII Restricción de Paths por Tier, Art.IX Contenido Completo
- ADR-0005 Orquestación pensador/Agent-SSD
