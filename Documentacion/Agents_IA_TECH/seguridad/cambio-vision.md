# 🔒 Seguridad del diseño: Reinicio automático al cambio de visión

> Revisión **de seguridad del DISEÑO** de la spec `[CAMBIO-VISION]` (`Documentacion/Agents_IA_TECH/specs/cambio-vision/spec.md`: 6 RFs + 7 ACs, v1.0 2026-09-19).
> Foco: **RF-04 — cambio de requerimiento invalida mitigaciones**. El `documentador` ya creó la spec (5 disparadores + procedimiento común RF-06).
> Complementa: `seguridad/metodologia-ssd.md` (R-2 specs desactualizadas, drift) + `seguridad/tokenslayer.md` + `seguridad/graphify.md` (formato §§1-7 heredado).
> **Fecha**: 2026-09-19 | **Autor**: `security-auditor` (Fase Documental — tarea `[CAMBIO-VISION]`)

---

## 1. Análisis de riesgos

### R-1. Mitigaciones aprobadas invalidadas en silencio — el cambio de visión las hereda sin re-validar

RF-04 exige que `security-auditor` re-valide y que **ninguna mitigación previa se herede automáticamente** (AC-04: cada una marcada como confirmada o descartada). Pero la re-validación es **responsabilidad procedimental del `pensador`** (detectar el disparador 4 y convocar al auditor): no hay gate que impida continuar el ciclo reiniciado con las mitigaciones viejas. Si el `pensador` clasifica el cambio como disparador 1/2/3/5 (o como ajuste menor) en lugar de disparador 4, **RF-04 nunca se ejecuta** y las mitigaciones (allowlist de owners, stdio-only, exclusiones de secrets, pins en manifest) se arrastran a una visión cuyos supuestos ya no las sostienen. Es el riesgo central de esta spec y replica el patrón R-1/R-2 de `metodologia-ssd.md` (gates que pasan con reglas obsoletas). Mitigación: **matriz mitigación↔supuesto** obligatoria en el reporte de re-validación (cada mitigación cita qué supuesto la sostiene; si el supuesto cambió → descartada o re-derivada, nunca "confirmada" por inercia); `pensador` no cierra el reinicio sin reporte AC-04 archivado en la sesión.

### R-2. Descarte de specs viejas borra el "por qué no" — se pierde la memoria de decisiones de seguridad

RF-06 paso 3 descarta "plan y specs de la visión vieja" (quedan "referenciados en la sesión como contexto histórico, no como norma vigente"). Las specs viejas contienen **decisiones de seguridad negativas** (alternativas rechazadas por riesgo: http prohibido, `.venv` no movido sino recreado, `revisar_manualmente/` en `.gitignore`): el "por qué no". Si el descarte se interpreta como archivar-y-olvidar, la nueva visión **reintroduce una alternativa ya rechazada** sin saberlo (ej: vuelve a proponer Graphify por http, o a mover `.venv` en lugar de recrearlo). La sesión como "contexto histórico" es solo lectura pasiva, no gate. Mitigación: antes del descarte, el `pensador` extrae el **registro de decisiones de seguridad** de la visión vieja (lista de "rechazado por riesgo" con motivo) y lo porta a la sesión nueva como **restricciones vigentes salvo re-validación explícita**; nunca se re-propone una alternativa rechazada sin citar y rebatir su motivo original.

### R-3. Re-validación omitida por clasificar mal "ajuste menor" vs "cambio de visión"

La frontera ajuste-menor/visión (§ Ajuste menor vs cambio de visión + AC-07) la aplica el `pensador`, con regla de desempate "ante duda, preguntar". Un cambio de requerimiento real (disparador 4) disfrazado de "corrección puntual de un dato" o "preferencia de redacción" **evita RF-04 y RF-06 completos**: se resuelve in-fase, sin re-validación, sin pregunta de guardado, sin traza. El incentivo a minimizar (prisa, evitar el costo del reinicio) empuja sistemáticamente hacia "ajuste menor". La regla de desempate es procedimental, no verificable. Mitigación: **criterio fail-closed para seguridad**: todo cambio que toque supuestos, mitigaciones, superficies de ataque, dependencias o datos sensibles se clasifica como visión aunque parezca menor; `security-auditor` puede **reclasificar** un "ajuste menor" a disparador 4 a posteriori y forzar RF-04; `qa-senior` audita una muestra de ajustes-menores por ciclo buscando cambios de requerimiento encubiertos.

### R-4. Sesión guardada en disco con secrets pegados — la pregunta de guardado archiva material sensible

RF-06 pasos 2+4 preserva la sesión en `Documentacion/<AppName>/sesiones/` y pregunta "¿Querés guardar esta propuesta?" antes de descartar. Las propuestas viejas pueden contener **secrets pegados** (tokens, API keys, connection strings, `.opencode/config.json`, salidas de MCPs/grafos con literales sensibles — mismo patrón que R-9 de `metodologia-ssd.md` y R-5 de `graphify.md`). Archivar la propuesta "por si acaso" (respuesta SÍ por defecto conservador) **persiste el secret en disco versionable** y lo convierte en contexto histórico consultable en cada reinicio futuro. Mitigación: antes de archivar, barrido de secrets sobre la propuesta (placeholders, `.env`/`*.pem`/`*.key`, `config.json` con keys, tokens en comentarios); si hay hallazgo → sanitizar o no archivar (solo traza del disparador + decisiones, sin contenido); `sesiones/` con material sensible nunca se commitea sin revisión; tratar volcado MCP en sesión como no confiable (prompt defense heredado).

### R-5. Contador de iteraciones evadido — el usuario evita "está mal" y acumula deuda sin disparar RF-02

RF-02 dispara solo al **3er cambio de criterio sobre la misma operación**, y las reglas del contador excluyen "bugs de implementación" y "ajustes menores", congelan tras un NO, y reinician tras un SÍ. Un usuario que reformula cada vez ("no es que esté mal, es que preferiría…", cambiando de operación nominal, o fragmentando el retrabajo en bugs/ajustes) **nunca llega al umbral**: acumula deuda de diseño sin que el `pensador` pregunte por specs. Inversamente, tras un NO el contador congelado permite deriva indefinida sin nueva pregunta. El contador es procedimental del `pensador` (Fuera de Alcance: sin automatización), sin trazabilidad exigible. Mitigación: contador **visible en la sesión** (1ª/2ª/3ª anotadas por operación, AC-02 verificable); el congelamiento tras NO expira si el criterio vuelve a cambiar sobre la misma operación (nueva pregunta, no silencio); `qa-senior` valida AC-02 revisando que la 1ª/2ª fueron replanteo normal y la 3ª preguntó; ante patrón de reformulación evasiva, el `pensador` aplica la regla de desempate (preguntar) aunque el contador formal no haya llegado a 3.

### R-6. Reinicio sin traza exigible — RF-06 paso 5 es solo anotación, no gate

RF-06 paso 5 exige anotar disparador + preservado + respuesta de guardado en `pendientes-implementacion.md` y la sesión (AC-06), pero nada impide que el ciclo reiniciado avance sin esa traza (olvido, prisa). Sin traza, AC-01..AC-07 son **no auditables**: `qa-senior` no puede verificar qué disparador se aplicó ni si RF-04 corrió. Mitigación: **pre-condición de traza**: el `pensador` escribe la entrada de reinicio (disparador RF-0X + qué se preservó + respuesta de guardado + si RF-04 aplica y su reporte) **antes** de re-entrar al Paso 2; `qa-senior` rechaza validaciones AC sin traza completa; la entrada `[CAMBIO-VISION]` en pendientes acumula el historial de reinicios (no solo la fase documental).

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **Mitigaciones invalidadas en silencio** (pensador no convoca RF-04; mitigaciones viejas arrastradas a la nueva visión) | 🔴 Crítico | Matriz mitigación↔supuesto obligatoria en reporte AC-04; sin reporte archivado no se cierra el reinicio |
| 2 | **Descarte borra el "por qué no"** (alternativas rechazadas por riesgo se reintroducen sin saberlo) | 🟠 Alto | Portar registro "rechazado por riesgo + motivo" a la sesión nueva como restricciones vigentes salvo re-validación explícita |
| 3 | **Ajuste menor vs visión mal clasificado** (cambio de requerimiento in-fase evita RF-04/RF-06) | 🟠 Alto | Fail-closed: lo que toque supuestos/mitigaciones/superficie/datos = visión; auditor puede reclasificar a disparador 4; muestreo qa-senior |
| 4 | **Sesión archivada con secrets** (pregunta de guardado persiste tokens/keys en disco versionable) | 🟠 Alto | Barrido de secrets pre-archivo (sanitizar o no archivar); sesiones con sensibles fuera de commits sin revisión; prompt defense en volcados MCP |
| 5 | **Contador evadido** (reformulación continua nunca llega a 3; congelamiento tras NO permite deriva) | 🟡 Medio | Contador visible en sesión (AC-02); congelamiento expira ante nuevo cambio de criterio; regla de desempate ante evasión |
| 6 | **Reinicio sin traza** (paso 5 anotación opcional en la práctica; ACs no auditables) | 🟡 Medio | Pre-condición de traza antes de re-entrar al Paso 2; qa-senior rechaza AC sin traza; historial de reinicios en pendientes |

---

## 3. Recomendaciones de uso seguro para los agentes del kit

1. **Reporte AC-04 obligatorio**: todo reinicio con cambio de requerimiento produce reporte de re-validación (mitigación × {confirmada | descartada | re-derivada} × supuesto que la sostiene) archivado en la sesión; el `pensador` no re-entra al Paso 2 sin él.
2. **Portar el "por qué no"**: al descartar la visión vieja, extraer decisiones de seguridad negativas (alternativa + motivo de rechazo) como restricciones de la visión nueva; re-proponer una alternativa rechazada exige citar y rebatir su motivo.
3. **Fail-closed en la frontera**: ante cualquier cambio que toque supuestos, mitigaciones, dependencias, superficie o datos sensibles → tratar como visión (RF-04/RF-06), aunque parezca redacción o dato puntual.
4. **Higiene de sesiones**: barrido de secrets antes de archivar propuestas; no commitear `sesiones/` con sensibles sin revisión; nunca volcar contenido crudo de grafos/MCPs en docs versionadas.
5. **Contador auditable**: anotar 1ª/2ª/3ª por operación en la sesión; el NO congela pero no amnistía (nuevo cambio de criterio → nueva pregunta); reformulación evasiva → aplicar desempate y preguntar.
6. **Traza primero**: entrada de reinicio (disparador + preservado + guardado + RF-04 sí/no + reporte) escrita antes del Paso 2; historial acumulado en la entrada `[CAMBIO-VISION]` de pendientes.
7. **Constitution check ligero real**: RF-06 paso 1 no es un saludo — valida hash de `.specify/memory/constitution.md` vs inicio del ciclo anterior (patrón R-1 de `metodologia-ssd.md`); si driftó, alertar antes de re-planificar.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO heredar mitigaciones a la nueva visión sin confirmación explícita una por una** (AC-04 no es "siguen valiendo salvo aviso").
- ❌ **NO clasificar como disparador 1/2/3/5 (o ajuste menor) un cambio que invalida supuestos o mitigaciones** — eso es disparador 4.
- ❌ **NO descartar la visión vieja sin extraer su registro "rechazado por riesgo"** a la sesión nueva.
- ❌ **NO re-proponer una alternativa ya rechazada por seguridad sin citar y rebatir su motivo original**.
- ❌ **NO archivar propuestas con secrets pegados** ("guardar por si acaso" no justifica persistir tokens/keys).
- ❌ **NO resolver in-fase como "ajuste menor" nada que toque mitigaciones, superficie, dependencias o datos sensibles**.
- ❌ **NO usar el congelamiento del contador tras un NO como vía libre para deriva indefinida**.
- ❌ **NO re-entrar al Paso 2 sin traza de reinicio escrita** (disparador + preservado + guardado + RF-04).
- ❌ **NO tratar el Constitution check ligero del reinicio como formalidad** — validar hash, no solo invocar.
- ❌ **NO volcar salidas crudas de MCPs/grafos en sesiones versionadas** — prompt defense siempre.

---

## 5. Checklist de seguridad del diseño

- [ ] Reporte AC-04 (matriz mitigación↔supuesto, cada mitigación confirmada/descartada/re-derivada) archivado en sesión antes de re-entrar al Paso 2.
- [ ] Registro "rechazado por riesgo + motivo" de la visión vieja portado como restricciones de la visión nueva.
- [ ] Criterio fail-closed documentado para la frontera ajuste-menor/visión (supuestos/mitigaciones/superficie/datos → visión).
- [ ] `security-auditor` con potestad de reclasificar un "ajuste menor" a disparador 4 y forzar RF-04.
- [ ] Barrido de secrets pre-archivo en la pregunta de guardado; sesiones con sensibles fuera de commits sin revisión.
- [ ] Contador por operación visible en sesión (1ª/2ª/3ª); congelamiento tras NO con expiración ante nuevo cambio.
- [ ] Traza de reinicio (disparador + preservado + guardado + RF-04 sí/no) escrita antes del Paso 2; historial en `[CAMBIO-VISION]`.
- [ ] Constitution check ligero con validación de hash en RF-06 paso 1.
- [ ] `qa-senior` valida los 7 ACs con traza completa + muestreo de ajustes-menores + fixtures de reclasificación (requerimiento encubierto, mitigación arrastrada, alternativa rechazada reintroducida, secret en propuesta archivada, contador evadido).

---

## 6. Conclusión

**No bloquea, CON CONDICIONES.**

La spec `[CAMBIO-VISION]` es sólida en lo procedimental (5 disparadores + RF-06 común + contador + frontera ajuste/visión + compatibilidad sin contradicción con el `pensador`), y RF-04/AC-04 enuncian el principio correcto (nada se hereda sin confirmación). Pero **un riesgo crítico (🔴) debe resolverse en la aplicación** antes de considerar seguro el reinicio:

1. **R-1 Mitigaciones invalidadas en silencio**: la re-validación depende de que el `pensador` clasifique bien el disparador y convoque al auditor — no hay gate. **Requisito innegociable**: reporte AC-04 con matriz mitigación↔supuesto archivado en sesión como pre-condición para re-entrar al Paso 2.

Los riesgos 🟠 (R-2 pérdida del "por qué no", R-3 frontera mal clasificada, R-4 secrets en sesión archivada) son **mitigables con controles de aplicación** (portar restricciones, fail-closed + reclasificación, barrido pre-archivo), y los 🟡 (R-5 contador evadido, R-6 traza no exigible) con disciplina de traza auditable. Todos deben materializarse en la práctica del `pensador`, no solo en esta revisión.

**Recomendación**: **PROCEDER (NO BLOQUEA)**, condicionado a que `qa-senior` valide los 7 ACs exigiendo traza completa por reinicio y cubriendo con fixtures los 6 riesgos (mitigación arrastrada sin reporte, alternativa rechazada reintroducida, requerimiento encubierto como ajuste menor, secret en propuesta archivada, contador evadido, reinicio sin traza).

---

## 7. Referencias

- Spec: `Documentacion/Agents_IA_TECH/specs/cambio-vision/spec.md` (v1.0, 6 RFs + 7 ACs + contador + ajuste-menor-vs-visión)
- Revisiones previas (formato §§1-7): `seguridad/metodologia-ssd.md` (R-1/R-2 gates y drift, R-9 secrets en grafo), `seguridad/graphify.md`, `seguridad/tokenslayer.md`
- `Documentacion/Agents_IA_TECH/agents/pensador/spec.md` (R11 persistencia de sesiones, R13 reinicio desde Paso 2)
- `.github/agents/pensador.agent.md` (§ Replanificar: Constitution Check como puerta + Paso 2 como reinicio efectivo)
- Tarea: `[CAMBIO-VISION]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`

---

**`security-auditor` completado** — Revisión creada en `seguridad/cambio-vision.md`.
