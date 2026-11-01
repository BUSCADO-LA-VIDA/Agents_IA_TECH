# Converge 035 — Consolidación del Backlog de Specs

| Campo | Valor |
|---|---|
| **Slug** | `035-consolidacion-backlog` |
| **App** | `Agents_IA_TECH` (proyecto kit, sin `src/` — excepción Constitution Art.II L134) |
| **Fecha** | 2026-11-01 |
| **Fase** | Converge (fase I del plan) |
| **Autor** | `pensador` (orquestador) + ejecución de fases B/C/E/H por subagente de ejecución |
| **Constitution** | `.specify/memory/constitution.md` v2.0.0 |
| **Artefactos** | `spec.md`, `plan.md`, `tasks.md` (pendiente), `checklists/requirements.md`, `NOTA-CONSOLIDACION.md` ×6, `NOTA-ARCHIVO.md` ×7, `VAL-11` en `scripts/validate-agents-skills.ps1` |
| **Origen** | Auditoría `auditoria-specs-backlog.md` (2026-11-01) |

---

## 1. Estado del ciclo

| Fase | Artefacto | Estado | Observaciones |
|---|---|---|---|
| Specify | `spec.md` | ✅ Completo | 10 FR, 4 historias de usuario, 5 SC, edge cases; checklist 20/20 PASS |
| Plan | `plan.md` | ✅ Completo | 9 fases (A-I); Constitution Check PASS; fases A y G pre-ejecutadas, D y F pospuestas según decisión del usuario |
| Implement (fase B) | `00-indice.md` | ✅ Ejecutada | Indexadas 4 completadas sin registro (014, 019, kit-generico, solucion-generica) |
| Implement (fase C) | `NOTA-CONSOLIDACION.md` ×6 + `00-indice.md` | ✅ Ejecutada | Consolidadas absorciones por ADR (007, 017, 006, 010-env, 015-sync, 016-ssd, 030-núcleo) |
| Implement (fase E) | `specs/archived/` + `NOTA-ARCHIVO.md` ×7 | ✅ Ejecutada | 7 obsoletas movidas a `specs/archived/` (git mv, historial preservado) |
| Implement (fase H) | `scripts/validate-agents-skills.ps1` | ✅ Ejecutada | `VAL-11 Coherencia backlog-disco` agregado (FAIL por huérfanas) |
| Implement (fase D) | — | ⏸ **Pospuesta** | Fusiones de contenido (013→015, 009/019→020, 021→027, etc.) pendientes de aprobación puntual por spec |
| Implement (fase F) | — | ⏸ **Pospuesta** | Renumeraciones/migraciones (022-docker, 023-copilot, kit-generico, solucion-generica) pendientes de aprobación |
| Implement (fase A) | `00-indice.md` | ✅ Pre-ejecutada (sesión previa) | Divergencias 032/033/026/028 corregidas |
| Implement (fase G) | `pendientes-implementacion.md` | ✅ Pre-ejecutada | Backlog como segundo control; TRANS-001 + tasks 032/033/026/028 |
| Converge | `converge.md` | ✅ Este archivo | Fase I |
| Indexación | `00-indice.md` | ✅ | Spec 035 registrada; bloque de archivados |

## 2. Cambios producidos

### Fase B — Completadas sin registro indexadas

| Spec | Estado en disco | Acción |
|---|---|---|
| 014-manifest-versionado | 8/0 | Indexada como CERRAR-COMPLETADA-SIN-REGISTRO; nota fase F (revisar contra sync-kit) |
| 019-update-mcp-lastupdate-guard | 6/0 | Indexada como completada; nota de solapamiento con 020 |
| kit-generico | 9/0 | Indexada como completada; nota fase F (renumeración pendiente) |
| solucion-generica | 14/0 | Indexada como completada; nota fase F |

### Fase C — Absorbidas por ADR consolidadas (6 notas)

| Spec | ADR que la absorbe |
|---|---|
| 007-mcp-token-resolution (en `000-mcp-gobernanza`) | ADR-0006 |
| 017-garantizar-mcp-activos (en `000-mcp-gobernanza`) | ADR-0006 + 020 |
| 006-post-platforming-speckit | ADR-0004 |
| 010-mcp-env-file-guarantee | ADR-0006 |
| 015-sync-kit-bootstrap | ADR-0003 + sync-kit |
| 016-ssd-enforcement | ADR-0005 |
| 030-whitelist-contextual (núcleo) | ADR-0013 (núcleo; resto PENDIENTE-REAL, no cerrada por completo) |

### Fase E — Obsoletas archivadas (7 directorios a `specs/archived/`)

| Directorio | Motivo |
|---|---|
| 000-mcp-integracion (8 sub-specs) | Plantilla sin contenido; absorbida por 020 + opencode.json real |
| 000-mcp-integration-standard | Estándar absorbido por 020 |
| 008-mcp-config-portable | Forma actual definida por ADR-0009/0010 |
| 009-mcp-path-normalization | Absorbida por ADR-0009/0010 |
| 018-pensador-delegation-fix | Resuelto por 031; numeración duplicada |
| metodologia-ssd-speckit | Tema cubierto por ADR-0005 |
| cambio-vision | Solo spec, sin numerar ni tasks |

### Fase H — VAL-11 en el validador

`scripts/validate-agents-skills.ps1` incorporó `VAL-11 Coherencia backlog-disco (spec 035)` con severidad FAIL: cruza `specs/*/` contra `00-indice.md` (specs numeradas en disco sin entrada → huérfana). Aditivo (145+/0-), sin tocar VAL-01..VAL-10.

## 3. Gate de cierre

| Check | Resultado |
|---|---|
| `scripts/validate-agents-skills.ps1` | `11 chequeos | OK: 9 | WARN: 1 | FAIL: 1` — VAL-11 presente y operativo |
| VAL-11 | Detecta 7 huérfanas: 002 (fusión D), 013-ecc-lifecycle (etiqueta), 021-estructura (fusión D), 022-docker (migración F), 023-copilot (migración F), 035 (propia), plataforma-bootstrap (absorbida ADR-0003 futura) |
| Especs con NOTA creadas | ✅ 6 consolidación + 7 archivo, todas con contenido real, sin placeholders |
| Movimientos a `specs/archived/` | ✅ `git mv` (historial preservado), sin borrado |
| `git status` | Coherente: staged renames + index edits; `pendientes-implementacion.md` y `auditoria-specs-backlog.md` modificados (sin commit) |

## 4. Hallazgos del ciclo

- **VAL-11 como gate logra su propósito**: detecta las huérfanas restantes que NO corresponden a fases B/C/E. Las 7 reportadas son todas ante fusiones/migraciones pospuestas o absorciones futuras — divergencias **intencionales y documentadas**, no accidentales.
- **`013-ecc-integration-lifecycle`** figura en el índice como «012-» (hallazgo de la auditoría fila 16). No se corrigió en esta fase (depende de la fusión/renumeración F); queda pendiente.
- **`plataforma-bootstrap-instalador-unico`** es candidata a consolidar con ADR-0003 (fase F o iteración dedicada). No se archivó en E porque la auditoría la marcó ABSORBIDA-POR-ADR, no OBSOLETA — pero su entrada de índice quedó pendiente de agregar como huérfana del VAL-11.
- **`030`**: solo su núcleo (whitelist contextual) quedó absorbido por ADR-0013. El resto (skills de agentes, adelgazamiento de cuerpos, 66 tasks) **no se archiva** — es MIGRAR/PENDIENTE-REAL y requiere decisión en fase F futura.

## 5. Limitaciones / pendientes (fases D y F pospuestas)

Por decisión del usuario (2026-11-01), las fusiones de contenido (D) y renumeraciones (F) NO se ejecutaron en esta pasada. Quedan pendientes de aprobación puntual por spec:

| Pendiente | Specs | Necesita |
|---|---|---|
| Fusión D | 013-mcp-flow → 015; 009-update-lifecycle → 020; 019 → 020; 017-mcp → 020; 021-estructura → 027; 000-mcp-standard → 020; 002 → sync-kit | Aprobación spec por spec |
| Migración/renumeración F | 022-docker-patterns, 022-docker-standard, 023-copilot-mcp, kit-generico, solucion-generica | Aprobación de numeración/destino |
| Corrección de etiqueta | 013-ecc-integration-lifecycle (índice «012-») | Con la fusión/renumeración |
| Absorción futura | plataforma-bootstrap-instalador-unico → ADR-0003 | Decisión en fase F |

Estos pendientes están registrados en `00-indice.md` (spec 035) y en `auditoria-specs-backlog.md` §5 como veredictos aún no ejecutados.

## 6. Punto de control

La spec 035 consolida el **punto de la verdad** del backlog: el `00-indice.md` y el `pendientes-implementacion.md` quedan coherentes con el disco para las fases B/C/E ejecutadas, con un gate automático (`VAL-11`) que detecta lo que queda por resolver. Las divergencias restantes (D/F) son intencionales y documentadas.

Desde acá se puede partir en limpio: el backlog ya no miente sobre lo completado, y el `VAL-11` vela por que no vuelva a quedar incoherente en silencio.

---

**No se archiva** la spec 035: permanece ACTIVA en `specs/` hasta completar las fases D/F (ciclo de vida vigente: completar = terminar flujo, no archivar).
