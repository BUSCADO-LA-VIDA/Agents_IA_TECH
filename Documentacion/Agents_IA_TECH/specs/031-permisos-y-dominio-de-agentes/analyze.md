# Analyze 031 — Consistencia cross-artifact spec.md ↔ plan.md ↔ tasks.md + Constitución

## 1. Objetivo

Verificar que la spec `031-permisos-y-dominio-de-agentes`, su `plan.md` y su `tasks.md` sean consistentes entre sí y con la Constitución del proyecto (Art. III Test-First, Art. IV/VII Simplicidad, Art. V Seguridad, Art. IX Integration-First, Art. X Expansión del Implementador). Este análisis es obligatorio antes del cierre de converge y se ejecuta una vez por spec.

## 2. Metodología

Se aplicó el método de análisis cross-artifact definido en `speckit-analyze`:

1. **Extracción de requisitos**: cada FR y CA de `spec.md` se lista con su campo de verificación concreta.
2. **Mapeo a plan**: cada FR/CA se mapea a una decisión o componente del `plan.md`.
3. **Mapeo a tasks**: cada tarea de `tasks.md` se asigna a uno o más FR/CA.
4. **Constitución Check**: cada artículo aplicable de la Constitución se verifica contra la especificación.
5. **Detección de vacíos**: cualquier FR o CA sin tarea asociada, o cualquier tarea sin requisito de origen, se reporta como hallazgo.

## 3. Matriz de trazabilidad FR → plan → tasks → verificación

| FR | Descripción breve | plan.md | tasks.md | Verificación concreta | Estado |
|----|-------------------|---------|----------|----------------------|--------|
| FR-01 | `tier` canónico por agente | D1, D2 | T01..T10 | VAL-04 = 0 | OK |
| FR-02 | `description` no vacía | D1 | T01..T10 | VAL-03 = 0 | OK |
| FR-03 | Skills resuelven a SKILL.md | D1 | T01..T10 | VAL-05 = 0 | OK |
| FR-04 | Secciones Regla 2 en cada agente | D1, D2 | T01..T10 | VAL-08 = 0 | OK |
| FR-05 | Cobertura MCP en al menos un agente | D1 | T01..T10 | VAL-07 = 0 | OK |
| FR-06 | `pensador` no escribe en `src/`, `scripts/`, `tests/` | D1 | T01 | Inspección + test de contrato | OK |
| FR-07 | `dominio_check` antes de ejecutar/delegar | D1 | T01 | Select-String sobre ambos `pensador` | OK |
| FR-08 | Bloqueo fuera de dominio con 3 opciones | D1 | T01 | Test de contrato sobre el texto | OK |
| FR-09 | Excepción solo por sesión/momento | D1 | T01 | Redacción explícita en ambos arneses | OK |
| FR-10 | Escritura de código delegada a Implementador | D1 | T10 | Matriz §5 + revisión de tasks | OK |
| FR-11 | Operación de servidor delegada a `solucionador` | D1 | T02 | Matriz §5 | OK |
| FR-12 | Autorización escrita antes de operación crítica | D1 | T02 | Registro en `.bootstrap-audit.log` | OK |
| FR-13 | Protocolo `[S]`/`[N]`/`[C]` | D1 | T02 | Texto en ambos `solucionador` | OK |
| FR-14 | `[C]` exige parámetros y segunda confirmación | D1 | T02 | Texto + registro `parametros` | OK |
| FR-15 | Backup y rollback antes de operación destructiva | D1 | T02 | Texto + registro `backup_previo` | OK |
| FR-16 | `rm -rf /`, formateo, pérdida total prohibidos | D1 | T02 | Texto + bloqueo | OK |
| FR-17 | Una sesión SSH por servidor y tarea | D1 | T02 | Registro `sesion_id` único | OK |
| FR-18 | Sesión SSH hasta que el usuario ordene cerrar | D1 | T02 | Registro `sesion_fin` | OK |
| FR-19 | Credenciales provistas por el usuario, no persistidas | D1 | T02 | Texto + ausencia en repo | OK |
| FR-20 | Cambio en un arnés se replica en el otro | D1, D3 | T11 | VAL-01, VAL-06 + revisión | OK |
| FR-21 | Cada agente declara los MCPs que usa | D1 | T01..T10 | VAL-07 | OK |
| FR-22 | Cada agente declara idioma y respeta `idioma.md` | D1 | T01..T10 | VAL-08 (idioma) | OK |
| FR-23 | Edición quirúrgica, no reescritura completa | D2 | T01..T10 | Revisión de diff | OK |
| FR-24 | Validador de solo lectura, exit code 1 si FAIL | D1 | T12 | `tests/validate-agents-skills.Tests.ps1` | OK |

**Resultado FR**: 24/24 mapeados a componente, tarea y verificación concreta. Sin vacíos.

## 4. Matriz de trazabilidad CA → verificación

| CA | Descripción breve | plan.md | tasks.md | Verificación concreta | Estado |
|----|-------------------|---------|----------|----------------------|--------|
| CA-01 | VAL-03 sin violaciones | D1 | T01..T10 | `FAIL` de VAL-03 ausente | OK |
| CA-02 | VAL-04 sin violaciones | D1 | T01..T10 | ídem | OK |
| CA-03 | VAL-05 sin violaciones | D1 | T01..T10 | ídem | OK |
| CA-04 | VAL-07 sin violaciones (`playwright` en `developer`) | D4 | T06, T11 | `tests/agents-parity.ps1` exit 0 | OK |
| CA-05 | `pensador` y `solucionador` VAL-08 = 0 | D1, D2 | T01, T02 | Filtro del reporte por archivo | OK |
| CA-06 | `dominio_check` con 3 opciones exactas | D1 | T01 | `Select-String` sobre ambos `pensador` | OK |
| CA-07 | Protocolo `[S]`/`[N]`/`[C]` presente | D1 | T02 | ídem | OK |
| CA-08 | Prohibiciones absolutas presentes | D1 | T02 | ídem | OK |
| CA-09 | VAL-08 global = 0 (26 agentes) | D2 | T01..T10 | Reporte completo | OK |
| CA-10 | Paridad de secciones de contrato entre arneses | D3 | T11 | `tests/agents-parity.ps1` exit 0 | OK |
| CA-11 | Validador no escribe archivos | D1 | T12 | `git status` limpio tras ejecutar validador | OK |
| CA-12 | Cambio en un arnés sin el otro se detecta | D3 | T11 | Fixture negativo detecta divergencia | OK |

**Resultado CA**: 12/12 verificados y cerrados.

## 5. Constitución Check

| Artículo | Requisito | Cómo lo cumple 031 | Estado |
|----------|-----------|-------------------|--------|
| Art. III — Test-First | Cada FR tiene verificación; CA-09 bloquea el cierre sin nivelación | Matriz §3 y §4; cada FR tiene columna "Verificación concreta" | PASS |
| Art. IV/VII — Simplicidad | Un contrato único en lugar de reglas por agente; sin capa nueva de runtime | §6 matriz de permisos única; validador como única fuente de verdad | PASS |
| Art. V — Seguridad | Protocolo de autorización, prohibiciones absolutas, backup verificado | §6 matriz de permisos; §6.1 prohibiciones absolutas; modelo de datos §10 | PASS |
| Art. IX — Integration-First | Verificación contra archivos reales y el validador, no supuestos | `tests/agents-parity.ps1` + `scripts/validate-agents-skills.ps1` ejecutados sobre árbol real | PASS |
| Art. X — Kit sin `src/` | El dominio del kit se declara explícitamente para cada tier | §5 matriz de roles con dominio del kit declarado por agente | PASS |

**Resultado Constitución**: 5/5 artículos verificados. PASS.

## 6. Detección de vacíos y contradicciones

| Área | Hallazgo | Severidad | Resolución |
|------|----------|-----------|------------|
| CA-04 | En versión previa estaba "diferido por D-08"; ahora se declaró `playwright` en `developer` (decisión B) | Resuelto | D-08 reescrito a decisión B; CA-04 cumple |
| VAL-07 | `playwright` sin agente declarante en medición previa | Resuelto | `developer` declara `playwright` + `browser-qa` |
| `ssh-connection-agent` | Falta `description` en frontmatter de `.opencode` | Resuelto | Agregada en nivelación |
| `plataformador` | ~500 líneas perdidas por reescritura con `write` | Resuelto | Restaurado desde `5513d37` + `Enfoque` + `Constraints` |
| 032 / 033 | Specs hermanos registrados, sin `spec.md` | Pendiente (fuera de 031) | Abordados después del cierre de 031 |

**Resultado vacíos**: 0 hallazgos abiertos. Todas las contradicciones detectadas en versiones previas fueron resueltas.

## 7. Verificación de calidad del contenido

| Criterio | Resultado |
|----------|-----------|
| Sin placeholders (TBD, TODO, pendiente, N/A, XXX, ...) | Verificado: 0 ocurrencias en spec.md, plan.md, tasks.md |
| Sin secciones con solo título | Verificado: todas las secciones tienen contenido real |
| Tablas con filas reales | Verificado: todas las tablas tienen datos, no solo encabezados |
| Listas con items concretos | Verificado: cada lista tiene al menos un item real |
| Contenido mínimo por sección (≥ 3 líneas útiles) | Verificado en spec.md, plan.md, tasks.md |

## 8. Dictamen del análisis

**PASS**. La spec `031-permisos-y-dominio-de-agentes` es consistente interna y externamente:

- Los 24 FR están mapeados a componente, tarea y verificación concreta.
- Los 12 CA están verificados y cerrados (validador: `OK: 8 | WARN: 1 | FAIL: 0`, exit code 0).
- La Constitución se cumple en los 5 artículos aplicables.
- El test de contrato (`tests/agents-parity.ps1`) pasa en verde y su fixture negativo detecta divergencia unilateral.
- No hay placeholders, secciones vacías ni tablas sin filas.

El análisis está listo para pasar a la fase de converge. No se detectaron vacíos ni contradicciones que bloqueen el cierre de 031.
