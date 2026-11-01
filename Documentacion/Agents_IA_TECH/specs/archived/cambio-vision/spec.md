# Spec: [CAMBIO-VISION] — Reinicio automático al cambio de visión

**Versión**: 1.0
**Fecha**: 2026-09-19
**Estado**: Borrador (fase documental — pendiente `security-auditor` y validación `qa-senior`)
**Autor**: documentador
**Plan base**: plan aprobado 2026-09-19 (5 disparadores definidos por el usuario)

---

## Objetivo

Formalizar el reinicio automático del ciclo del `pensador` cuando el usuario cambia de visión en cualquier punto del proceso, para evitar que los agentes sigan trabajando sobre una visión obsoleta.

La regla actual de una línea (`agents/pensador/spec.md` R13, L19: "SI EL USUARIO CAMBIA DE VISIÓN: Reiniciar el ciclo completo desde el análisis (Paso 2)") se expande aquí en **5 disparadores concretos** con el comportamiento exacto del `pensador` en cada caso, sin contradecir la sección "Replanificar" de `.github/agents/pensador.agent.md` (volver al Constitution Check como puerta de entrada + Paso 2 Análisis como reinicio efectivo — ver RF-06 y § Compatibilidad).

---

## Requisitos Funcionales (RF)

### RF-01: Disparador 1 — Resultado mal → PARAR y replantear
**Descripción**: Si el usuario dice que un resultado está mal, el `pensador` debe PARAR el trabajo en curso y volver a plantear problema + solución (Paso 2 Análisis).
**Criterio**: No se continúa la fase actual ni se hacen ajustes parciales sobre el resultado rechazado; se re-entra al ciclo por RF-06.

### RF-02: Disparador 2 — 3 iteraciones con criterio cambiante → PREGUNTAR por specs
**Descripción**: Si sobre la misma operación el criterio cambia por 3ª vez, el `pensador` NO reinicia directamente: PREGUNTA al usuario si volvemos a las especificaciones.
**Criterio**: La 1ª y 2ª vez con criterio cambiante son replanteo normal dentro de la fase; solo la 3ª dispara la pregunta por specs (ver § Contador de iteraciones).

### RF-03: Disparador 3 — Mejor forma detectada → inicio del diseño + análisis de impacto
**Descripción**: Si aparece una mejor forma de hacer el procedimiento, el `pensador` vuelve al inicio del diseño y realiza un análisis de qué más se afecta (impacto).
**Criterio**: El reinicio incluye un análisis de impacto explícito (artefactos, tasks y decisiones afectadas) antes de re-planificar.

### RF-04: Disparador 4 — Seguridad por cambio → re-validación de `security-auditor`
**Descripción**: Si el requerimiento cambió, `security-auditor` re-valida: las mitigaciones aprobadas pueden haberse invalidado con el cambio.
**Criterio**: Ninguna mitigación de seguridad previa se hereda automáticamente a la nueva visión; cada una se confirma o se descarta explícitamente.

### RF-05: Disparador 5 — Reinicio explícito con confirmación
**Descripción**: Si el usuario dice "volvemos al diseño" (o equivalente explícito), el `pensador` PREGUNTA para confirmar antes de reiniciar; no asume el reinicio.
**Criterio**: Sin confirmación explícita del usuario no hay descarte de la visión actual.

### RF-06: Procedimiento común de reinicio
**Descripción**: Todo reinicio por RF-01..RF-05 sigue este procedimiento único:

1. **Entrada**: Constitution Check ligero (Paso 1, puerta de entrada según `.github/agents/pensador.agent.md` § Replanificar) → **Paso 2 Análisis** (reinicio efectivo según `agents/pensador/spec.md` R13).
2. **Qué se preserva**:
   - Sesión en curso en `Documentacion/<AppName>/sesiones/` (historial, análisis y decisiones previas — nunca se borra sin pasar por el punto 4).
   - Decisiones transversales ya consolidadas en archivos (ADRs, constitution, preferencias, reglas transversales).
3. **Qué se descarta**: plan y specs de la visión vieja (dejan de ser la base de trabajo; quedan referenciados en la sesión como contexto histórico, no como norma vigente).
4. **Pregunta de guardado obligatoria** antes de descartar: "¿Querés guardar esta propuesta?" (regla de persistencia de sesiones, `agents/pensador/spec.md` R11). Solo tras la respuesta del usuario se archiva o se descarta la propuesta vieja.
5. **Registro**: el reinicio y su disparador (RF-01..RF-05) se anotan en `pendientes-implementacion.md` y en la sesión activa.

**Criterio**: Todo reinicio deja traza (disparador + qué se preservó + respuesta a la pregunta de guardado) en la sesión y en pendientes.

---

## Contador de iteraciones (criterio 2 / RF-02)

El `pensador` lleva la cuenta **por operación** (misma operación = mismo resultado/procedimiento retrabajado, no tasks distintas):

| Iteración | Significado | Comportamiento |
|-----------|-------------|----------------|
| 1ª vez que cambia el criterio | Replanteo normal | Se replantea dentro de la fase, sin pregunta especial |
| 2ª vez que cambia el criterio | Replanteo normal | Se replantea dentro de la fase, sin pregunta especial |
| 3ª vez que cambia el criterio | Umbral de visión | **PREGUNTA**: "¿Volvemos a las especificaciones?" — no reinicia directo |

**Reglas del contador**:
- El contador es por operación, no global de la sesión (cada operación nueva empieza en 0).
- Solo cuentan los cambios de criterio del usuario sobre la misma operación (no bugs de implementación ni ajustes menores — ver § Ajuste menor vs cambio de visión).
- Si el usuario responde NO a la pregunta de specs, el contador se congela (no se vuelve a preguntar por cada cambio posterior de esa operación) salvo que el usuario lo pida.
- Si el usuario responde SÍ, se aplica RF-06 y el contador de esa operación se reinicia.

---

## Ajuste menor vs cambio de visión

**Ajuste menor (NO reinicia)** — se resuelve dentro de la fase actual:
- Typo, ortografía, formato, estilo de presentación.
- Preferencia de redacción o de orden que no altera el problema ni la solución.
- Corrección puntual de un dato que no invalida decisiones tomadas.

**Cambio de visión (SÍ reinicia)** — activa RF-01..RF-05:
- El problema a resolver se redefine (disparador 1 o 2).
- El procedimiento elegido se sustituye por otro mejor (disparador 3).
- El requerimiento cambia de modo que invalida supuestos o mitigaciones (disparador 4).
- El usuario pide explícitamente volver al diseño (disparador 5).

**Regla de desempate**: ante duda entre ajuste menor y cambio de visión, el `pensador` pregunta al usuario antes de reiniciar (mismo espíritu que RF-02 y RF-05: no reiniciar por asunción).

---

## Criterios de Aceptación (AC)

| ID | Criterio | Verificación |
|----|----------|--------------|
| AC-01 | Usuario dice que un resultado está mal → el `pensador` PARA y replantea problema + solución (Paso 2) | Revisión de sesión: tras el rechazo no hay continuación de la fase vieja; hay re-entrada por RF-06 |
| AC-02 | 3er cambio de criterio en la misma operación → el `pensador` PREGUNTA si volver a specs (no reinicia directo); 1ª y 2ª fueron replanteo normal | Revisión de sesión: contador por operación visible (1ª, 2ª normales; 3ª con pregunta) |
| AC-03 | Mejor forma detectada → reinicio al inicio del diseño con análisis de impacto explícito | El reinicio incluye lista de artefactos/tasks/decisiones afectadas antes de re-planificar |
| AC-04 | Requerimiento cambiado → `security-auditor` re-valida; ninguna mitigación previa se hereda sin confirmación | Reporte de re-validación: cada mitigación previa marcada como confirmada o descartada |
| AC-05 | "Volvemos al diseño" → el `pensador` pide confirmación y solo reinicia tras el SÍ | Revisión de sesión: sin confirmación no hay descarte de la visión actual |
| AC-06 | Todo reinicio preserva sesión en `sesiones/` + decisiones transversales en archivos, descarta plan/specs viejos solo tras preguntar "¿Querés guardar esta propuesta?", y deja traza del disparador | Revisión de sesión + pendientes: traza completa (disparador + preservado + respuesta de guardado) |
| AC-07 | Un ajuste menor (typo, formato, preferencia) NO dispara reinicio; un cambio de visión SÍ | Auditoría: ajustes menores resueltos in-fase sin RF-06; cambios de visión siempre con RF-06 |

---

## Compatibilidad con la regla vigente del `pensador` (no contradicción)

- `agents/pensador/spec.md` R13 (L19): reiniciar "desde el análisis (Paso 2)" → RF-06 lo implementa como reinicio efectivo.
- `.github/agents/pensador.agent.md` § Replanificar / Enfoque #8 / Reglas del pipeline (L63, L363, L398): volver al "Constitution Check" → RF-06 lo implementa como puerta de entrada ligera previa al Paso 2.
- Ambas reglas se cumplen en orden: **Constitution Check (ligero) → Paso 2 Análisis (reinicio efectivo)**. Esta spec no modifica ninguna de las dos; solo ordena su aplicación en el reinicio por cambio de visión.

---

## Fuera de Alcance

- Modificar el ciclo base del `pensador` (Constitution Check, pipeline Speckit, matriz de delegación) — solo se formaliza la re-entrada.
- Cambios a `constitution.md`, ADRs existentes o specs de otras features.
- Automatización del conteo de iteraciones en tooling (el contador es procedimental del `pensador` en esta versión).
- Resolución de conflictos entre visiones concurrentes de múltiples usuarios.

---

## Dependencias

- `Documentacion/Agents_IA_TECH/agents/pensador/spec.md` (R11 persistencia de sesiones, R13 regla de una línea, R19/L19 + L99)
- `.github/agents/pensador.agent.md` (sección "Replanificar", Enfoque #8, Reglas del pipeline)
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` (entrada `[CAMBIO-VISION]`)
- `Documentacion/<AppName>/sesiones/` (persistencia de sesión y pregunta de guardado)

---

## Referencias

- Entrada `[CAMBIO-VISION]` en `pendientes-implementacion.md` (línea ~309, contexto previo)
- Plan aprobado 2026-09-19 (5 disparadores definidos por el usuario)
- `agents/pensador/spec.md` — REGLA DE ORO ABSOLUTA (L95-L100)
- `.doc_agents/estructura-aplicacion.md` (rutas por app: `sesiones/`, `specs/`)
