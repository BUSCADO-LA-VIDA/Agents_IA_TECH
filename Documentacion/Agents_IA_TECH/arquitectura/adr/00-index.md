# Índice de ADRs — Agents_IA_TECH

> **Última actualización**: 2026-09-25  
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

---

*Mantenido automáticamente por `arquitecto` durante fase Analyze de cada spec.*