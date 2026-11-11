# Analyze 045 — Consistencia de artefactos y hallazgos

**Spec**: `spec.md` v2.0.0 · **Plan**: `plan.md` · **Tasks**: `tasks.md` · **Fecha**: 2026-11-11

---

## 1. Cobertura requisito → tarea → criterio

| Requisito | Prioridad | Tarea(s) | Criterio | Estado real |
|---|---|---|---|---|
| RF-01 El registro no declara `PreToolUse` | Must | T004, T004c | AC-1, AC-2 | cumplido |
| RF-02 Se conservan `SessionStart` y `PostToolUse` | Must | T004 | AC-1 | cumplido |
| RF-03 Respaldo y rollback | Must | T004b | AC-3, AC-5 | cumplido |
| RF-04 Razón registrada con evidencia | Must | T001, T002, T003, T010 | AC-5 | cumplido |
| RF-05 La política vive en el generador | Must | T005, T007 | AC-6, AC-9 | **sin implementar** |
| RF-06 El validador vigila la política | Must | T006, T008 | AC-7 | **sin implementar** |
| RF-07 Condición de re-habilitación documentada | Should | T011 | — (documental) | cumplido |

**Requisitos sin tarea**: ninguno.
**Tareas sin requisito**: ninguna. T009b (portabilidad) y T012 (AC-4) son verificaciones transversales, no requisitos nuevos.
**Criterios sin tarea**: ninguno. AC-4 → T012; AC-8 → T009b; AC-9 → T009.

### 1.1 Cobertura de criterios de aceptación

| AC | Verificación asociada | Estado |
|---|---|---|
| AC-1 registro sin `PreToolUse` | T004 | cumplido |
| AC-2 JSON válido | T004c | cumplido |
| AC-3 respaldo con 3 etapas | T004b | cumplido |
| AC-4 lectura > 16 KB no denegada | T012 (manual) | **pendiente por recarga** |
| AC-5 rollback documentado | T010 + spec §6 | cumplido |
| AC-6 generador sin `PreToolUse` | T005, T007 | **pendiente** |
| AC-7 validador alineado | T006, T008 | **pendiente** |
| AC-8 portabilidad 16/16 | T009b | cumplido (última corrida) |
| AC-9 registro ≡ salida del generador | T009 | **pendiente** |

---

## 2. Hallazgos

| ID | Hallazgo | Severidad | Impacto | Tratamiento |
|---|---|---|---|---|
| H1 | `.github/hooks/context-mode.json` **es generado** por `Ensure-ContextHooks` y la retirada se aplicó **editando el archivo** | **Alta** | Un `bootstrap -Force` o un clon nuevo restauran `PreToolUse`; la decisión no es reproducible | RF-05 / T005 + P5 |
| H2 | `validar-mcps.ps1` exige `PreToolUse` y hoy falla en cada corrida | **Alta** | El kit se contradice; se normaliza ignorar el FAIL y eso oculta fallos reales | RF-06 / T006 + P7 |
| H3 | Deriva de versiones esperadas en `validar-mcps.ps1`: `context-mode` 1.0.169 vs 2.1.0; `codebase-memory-mcp` 0.9.0 vs 0.10.8; `markitdown` 0.1.7 vs 0.1.8 | Media | Ruido de `[WARN]` que enmascara el estado real | Fuera de alcance (§3.2 del spec); registrar para spec propia |
| H4 | El reporte original ("todas las herramientas rechazadas", "GitHub Actions") era inexacto | Media | Riesgo de diagnóstico: se persiguió un fallo general inexistente | Documentado en §1.1 del spec; la evidencia manda |
| H5 | El respaldo `.bak-20261109` vive en la misma carpeta que el registro activo | Baja | Solo sería un riesgo si el arnés cargara cualquier `.json` de `.github/hooks/`; la ruta configurada es exacta | Sin acción; se conserva como evidencia (D5) |
| H6 | El generador ordena `PostToolUse` antes de `SessionStart`; el archivo actual tiene ese mismo orden | Baja | AC-9 podría fallar por orden si alguien reordena a mano | La comparación de T009 normaliza claves antes de comparar |
| H7 | `.vscode/mcp.json` no registra `context-mode`, `codebase-memory-mcp` ni `markitdown` (el validador lo reporta) | Media | El arnés VS Code no levanta esos MCP | Spec 046 (G8/G9); no se toca aquí |

---

## 3. Consistencia entre artefactos

| Comprobación | Resultado |
|---|---|
| El slug de la carpeta coincide con el `Feature Branch` del spec | OK: `045-retirar-pretooluse-hook-context-mode` |
| El plan respeta las decisiones D1-D6 del spec | OK |
| Cada tarea del plan aparece en `tasks.md` con su RF | OK |
| Las tareas marcan `[x]` solo con evidencia verificada | OK: T001-T004c y T010-T011 tienen salida real; el resto queda abierto |
| El conteo de tareas de `tasks.md` coincide con su tabla de estado (8/14) | OK |
| La condición de re-habilitación del spec (§7) es la misma que la de D4 del plan | OK |
| El alcance excluye explícitamente H3 y H7 | OK: §3.2 del spec |
| No hay referencias a la ruta vieja en los artefactos nuevos | OK (verificado con `git grep` en T013) |

### 3.1 Coherencia con la Spec 044 y la 046

| Spec | Relación | Sin solapamiento |
|---|---|---|
| 044 | Portabilidad y validador de rutas | La 045 no toca el validador de rutas; solo el de MCPs (bloque 3) |
| 046 | Generación de `opencode.json` y `.mcp.json` | La 045 no toca `opencode.json`; H7 queda en la 046 |

---

## 4. Threat model resumido (STRIDE)

| Categoría | Aplica | Análisis | Mitigación |
|---|---|---|---|
| **S**poofing | No | No hay identidades ni autenticación en el hook | — |
| **T**ampering | **Sí** | `PreToolUse` puede reintroducirse por edición manual, `-Force` o copia de otro repo | T005 (política en el generador) + T006 (guard del validador) + P7 |
| **R**epudiation | **Sí** | Sin registro, "quién quitó la etapa y por qué" se pierde | Spec + bitácora + comentario en el generador |
| **I**nformation disclosure | No | El hook no maneja secretos; el registro solo contiene comandos | — |
| **D**enial of service | **Sí (era el problema)** | `PreToolUse` denegaba lecturas legítimas y bloqueaba el flujo de trabajo | Retirada de la etapa + condición para volver |
| **E**levation of privilege | Bajo | El hook ejecuta el CLI de `context-mode`; retirar una etapa reduce la superficie ejecutada | Se conservan las etapas que no bloquean |

**Riesgo residual**: mientras T005 no esté implementado, el riesgo de reaparición es alto y conocido. Queda declarado, no mitigado.

---

## 5. Veredicto

| Dimensión | Veredicto |
|---|---|
| Consistencia spec ↔ plan ↔ tasks | **PASS** |
| Cobertura RF → tarea → AC | **PASS** (7/7 RF con tarea; 9/9 AC con verificación) |
| Veracidad del estado | **PASS**: 8/14 tareas cerradas con evidencia; las abiertas se declaran abiertas |
| Completitud documental | **PASS**: cinco artefactos con contenido real |
| Implementación | **INCOMPLETA**: falta mover la política al generador y alinearla en el validador |

**Conclusión**: la spec es consistente y honesta, pero **no está terminada**. Quedan dos defectos de diseño abiertos (H1, H2) que un `bootstrap -Force` convierte en regresión inmediata. No debe declararse cerrada hasta que T005-T009 estén en verde y AC-4 se verifique tras la recarga.
