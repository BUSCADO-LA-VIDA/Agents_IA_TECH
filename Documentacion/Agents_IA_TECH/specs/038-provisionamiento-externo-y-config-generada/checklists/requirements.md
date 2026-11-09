# Checklist de requisitos — Spec 038

**Spec**: `Documentacion/Agents_IA_TECH/specs/038-provisionamiento-externo-y-config-generada/spec.md`
**Validado**: 2026-11-07
**Resultado**: 25/25 ítems conformes. Sin bloqueantes para pasar a `plan.md`.

## Calidad del contenido

| # | Ítem | Resultado | Evidencia |
|---|---|---|---|
| CQ-01 | La spec describe valor y resultado, no implementación | Conforme | Las FR fijan contratos (verbos, forma canónica, estados), no algoritmos; el diseño queda para `plan.md` |
| CQ-02 | El problema está probado con evidencia, no con percepciones | Conforme | Tabla "Problema y evidencia" con siete hechos verificables y su fuente |
| CQ-03 | El alcance y el fuera de alcance están separados | Conforme | Secciones "Alcance" y "Fuera de alcance"; cinco ítems derivados al backlog |
| CQ-04 | No hay placeholders ni secciones vacías | Conforme | Todas las secciones tienen contenido real; ninguna fila de tabla está vacía |
| CQ-05 | Los términos nuevos están definidos | Conforme | Glosario con cinco tipos de aprovisionamiento y su autoridad de versión |
| CQ-06 | Las decisiones del usuario están trazadas | Conforme | Tabla D1–D5 con la consecuencia de cada una |

## Completitud de requisitos

| # | Ítem | Resultado | Evidencia |
|---|---|---|---|
| RC-01 | Cada requisito funcional es verificable | Conforme | FR-01 a FR-17 con criterio observable; los verificables por comando citan exit code o artefacto |
| RC-02 | Existe cobertura de detección de estado | Conforme | FR-03, FR-04, FR-06 |
| RC-03 | Existe cobertura de instalación/actualización | Conforme | FR-07, FR-14, FR-16 |
| RC-04 | Existe cobertura de generación de configuración | Conforme | FR-08, FR-09, FR-10, FR-11 |
| RC-05 | Existe cobertura de diferencias entre arneses | Conforme | FR-09, FR-15, NFR-08 |
| RC-06 | Existe cobertura de aislamiento del clon externo | Conforme | FR-13, FR-14 |
| RC-07 | Los estados posibles están acotados y definidos | Conforme | `ok`, `al-dia`, `desactualizado`, `missing`, `degraded`, `desconocido`, `absent` |
| RC-08 | Los requisitos no funcionales son medibles | Conforme | NFR-01 a NFR-08; NFR-07 con umbral de tiempo explícito |
| RC-09 | Los criterios de éxito son medibles | Conforme | SC-001 a SC-013, cada uno con condición observable |
| RC-10 | Los casos borde tienen comportamiento definido | Conforme | Doce casos con comportamiento esperado, incluidos sin red, shallow y detached |

## Coherencia con el proyecto

| # | Ítem | Resultado | Evidencia |
|---|---|---|---|
| PC-01 | Respeta la constitution vigente | Conforme con acción pendiente | Art. I (herramienta standalone), Art. II (CLI con exit code), Art. V (fail-open con causa, sin secretos), Art. IX (servicios reales). Requiere enmienda MINOR + ADR antes de `plan` |
| PC-02 | No invade el dominio de otro agente | Conforme | La spec define contratos; la implementación de scripts queda para `developer` y `plataformador` |
| PC-03 | No duplica una spec existente | Conforme | 037 cubre `.gitignore`; 036 cubre paridad del motor de sync; 020 cubre operativa MCP. 038 cubre aprovisionamiento y generación |
| PC-04 | No introduce futuro en la spec | Conforme | El versionado semver, la integración controlada (039), los hooks y el instalador único están en backlog |
| PC-05 | El corte con la spec 039 está justificado | Conforme | 038 es configuración y estado; 039 es gobernanza e integración controlada, con threat model propio |
| PC-06 | El idioma respeta `idioma.md` | Conforme | Documentación en español neutral; identificadores, scripts y claves en inglés |
| PC-07 | Los artefactos citados existen o están declarados como nuevos | Conforme | Los existentes verificados en disco; los nuevos figuran con ruta explícita |
| PC-08 | La trazabilidad de evidencia es reproducible | Conforme | Cada hecho de la tabla de evidencia se puede volver a verificar con el comando o la ruta citada |
| PC-09 | Cada inconsistencia tiene spec propia y 038 no la corrige | Conforme | FR-15 declara y valida; la tabla "Inconsistencias declaradas" asigna una spec por inconsistencia (040 a 043) con su motivo de separación |

## Decisión

Ningún ítem quedó en rojo. La única acción previa a `plan.md` es de gobernanza: enmienda MINOR de la constitution y ADR de configuración generada. No es un defecto de la spec; es una dependencia declarada en "Dependencies and assumptions".
