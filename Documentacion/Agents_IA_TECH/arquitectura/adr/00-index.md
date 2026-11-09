# Índice de ADRs — Agents_IA_TECH

> **Última actualización**: 2026-11-07  
> **Mantenido por**: `arquitecto` (fase Analyze de cada spec)

---

## Lista de ADRs

| ID | Título | Estado | Fecha | Spec Relacionada |
|----|--------|--------|-------|------------------|
| **ADR-0001** | Ecosistema documentación sin IA | Aceptado | 2026-09-24 | — |
| **ADR-0002** | Flujos kit | Aceptado | 2026-09-24 | — |
| **ADR-0003** | Plataforma bootstrap instalador único | Aceptado | 2026-09-24 | `plataforma-bootstrap-instalador-unico` |
| **ADR-0004** | Post-plataformado Speckit | Aceptado | 2026-09-24 | `006-post-platforming-speckit` |
| **ADR-0005** | Agent-SSD | Aceptado | 2026-09-24 | — |
| **ADR-0006** | MCP token resolution + `.env.mcp` + upgrade tools + self-update + activación kit maestro | Aceptado | 2026-09-24 | `007-mcp-token-resolution` |
| **ADR-0007** | **Bootstrap delega sincronización de dependencias externas en upgrade_framework** | **Aceptado** | **2026-09-25** | **`011-bootstrap-invokes-upgrade-framework`** |
| **ADR-0008** | **Constitution v2.0.0 — tiers, fail-open y contenido completo + corrección de 3 errores factuales** | **Aceptado** | **2026-10-11** | ** constitution v2.0.0** |
| **ADR-0009** | **Rutas MCP hardcodeadas en `opencode.json` (workaround bug OpenCode #5299)** | **Aceptado (temporal)** | **2026-10-11** | **workaround de `007-mcp-token-resolution`** |
| **ADR-0010** | **Forma V2 de `opencode.json` (`mcp.servers` + `mcp.timeout.startup`)** | **Aceptado** | **2026-10-18** | **sin spec de origen: fix en vivo documentado en la bitácora `2026-10-18-opencode-v2-mcp-fix`** |
| **ADR-0011** | **Public Docs Routing (docs públicas a `src/<App>/docs/`, README públicos a `src/<App>/README*.md`)** | **Aceptado (MADR incompleto)** | **2026-10-27** | **`028-public-docs-routing`** |
| **ADR-0012** | **Comparación de transversales por EOL normalizado con veredicto de tres estados (`Equal` / `EolOnly` / `Different`)** | **Aceptado** | **2026-10-27** | **`029-sync-eol-y-force-real`** |
| **ADR-0013** | **Agentes como orquestadores delgados (capacidades de procedimiento a skills) y whitelist de escritura resuelta por `(tier ∩ capa, tipo de proyecto)`** | **Aceptado** | **2026-10-29** | **`030-whitelist-contextual-por-tipo-proyecto`** |
| **ADR-0014** | **Configuración de arneses generada (plantilla + generador dual) y aprovisionamiento externo por tipo con verificación declaración-contra-realidad** | **Aceptado** | **2026-11-07** | **`038-provisionamiento-externo-y-config-generada`** |

> **Estado real de ADR-0011**: el archivo existe y su decisión está aceptada, pero mide 453 bytes / 16 líneas y le faltan las secciones Alternativas consideradas, Guardrails, Spec linking, Diagramas y Plan de implementación que exige la convención de este índice. Se registra como hallazgo abierto del `arquitecto` (analyze de la spec 029, sección 11.3); no se corrigió en esa fase porque su contenido pertenece a la spec 028, ya cerrada.
>
> **Desfase historico sin registrar**: esta tabla no registra las 23 specs previas a la 026 ni los ADR generados fuera de una fase Analyze. La spec 029 lo declaró fuera de alcance (FA-04) y se conserva como deuda documental separada. Las filas de ADR-0010, ADR-0011 y ADR-0012 se agregaron el 2026-10-27 al registrar el ADR de esa spec, no como cierre de esa deuda.

---

## Convenciones

- **Naming**: `adr-XXXX-kebab-case-title.md` (XXXX = número secuencial 4 dígitos)
- **Estado**: `Propuesto` | `Aceptado` | `Rechazado` | `Suplantado` | `Deprecado`
- **Ubicación**: `Documentacion/Agents_IA_TECH/arquitectura/adr/`
- **Plantilla**: Basada en MADR (Markdown Architectural Decision Records)
- **Spec Linking**: Cada ADR incluye sección "Spec linking" con trazabilidad bidireccional a `spec.md`, `plan.md`, `tasks.md`, `analyze.md`

---

## Cómo agregar un nuevo ADR

1. Determinar siguiente número (último + 1)
2. Crear archivo `adr-XXXX-title.md` en esta carpeta
3. Seguir estructura MADR: Contexto → Decisión → Alternativas → Consecuencias → Guardrails → Spec Linking → Diagramas → Plan implementación
4. Actualizar **esta tabla** con la nueva entrada
5. Referenciar ADR en `spec.md` / `plan.md` / `tasks.md` / `analyze.md` de la spec correspondiente

---

## Referencias Cruzadas

| Spec ID | Spec Nombre | ADR(s) Generados |
|---------|-------------|------------------|
| 001 | (legacy) | ADR-0001, ADR-0002 |
| 003 | plataforma-bootstrap-instalador-unico | ADR-0003 |
| 004 | post-platforming-speckit | ADR-0004 |
| 005 | agent-ssd | ADR-0005 |
| 007 | mcp-token-resolution | ADR-0006 |
| **011** | **bootstrap-invokes-upgrade-framework** | **ADR-0007** |
| **constitution** | **v2.0.0 — artículos VII/VIII/IX + corrección de 3 errores factuales** | **ADR-0008** |
| **workaround** | **007-mcp-token-resolution (parcial)** | **ADR-0009** |
| **fix en vivo** | **2026-10-18-opencode-v2-mcp-fix (forma V2 de `opencode.json`, sin spec de origen)** | **ADR-0010** |
| **028** | **public-docs-routing** | **ADR-0011** |
| **029** | **sync-eol-y-force-real** | **ADR-0012** |
| **030** | **whitelist-contextual-por-tipo-proyecto** | **ADR-0013** |
| **038** | **provisionamiento-externo-y-config-generada** | **ADR-0014** |

---

*Mantenido automáticamente por `arquitecto` durante fase Analyze de cada spec.*
