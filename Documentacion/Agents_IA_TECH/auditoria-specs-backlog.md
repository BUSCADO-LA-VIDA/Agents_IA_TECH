# Auditoría de valor del backlog de specs

> Informe de auditoría de valor — KIT Agents_IA_TECH.
> Fecha: 2026-11-01
> Objetivo: limpiar lo antiguo y dejar solo lo que aporta valor, auditando TODAS las specs del backlog (incluidas las huérfanas del índice), de la más antigua a la más nueva.

---

## 1. Objetivo y método

### 1.1 Por qué esta auditoría

Tras cerrar y commitear la spec **034 (arranque por defecto)**, el usuario pidió «limpiar lo antiguo y dejar solo lo que aporta valor». El backlog acumula decenas de specs de distintos estados: implementadas, absorbidas por ADRs, obsoletas, duplicadas en numeración, huérfanas del índice y genuinamente pendientes. Este informe clasifica **cada una** con un veredicto accionable, anclado en el estado real por disco (no en lo que el índice declara).

### 1.2 Criterio de decisión confirmado

La decisión de criterio del usuario es inequívoca:

> **Los ADRs implementados son la fuente de verdad de la «forma actual de trabajo».**

Por tanto, si una spec está **absorbida o resuelta** por un ADR implementado, o por una spec cerrada reciente, se marca como **CONSOLIDADA/CERRADA**, no como pendiente. Solo queda como PENDIENTE-REAL una spec que esté abierta, siga aplicando a la forma actual y no haya sido migrada ni absorbida.

### 1.3 Categorías de veredicto (6)

| Categoría | Significado | Acción resultante |
|---|---|---|
| **ABSORBIDA-POR-ADR** | El tema lo resuelve un ADR implementado | Consolidar y cerrar |
| **CERRAR-OBSOLETA** | Ya no aplica a la forma actual de trabajo | Documentar y archivar |
| **CERRAR-COMPLETADA-SIN-REGISTRO** | Completa en disco pero el índice la omitió | Solo registrar en el índice |
| **MIGRAR** | Aplica pero su numeración/contenido está obsoleto | Consolidar en una spec nueva numerada |
| **FUSIONAR** | Se solapa con otra spec | Consolidar |
| **PENDIENTE-REAL** | Abierta, aplica, queda sin migrar | Necesita implementación |

### 1.4 Regla de conservadurismo

Cuando una spec admite más de un veredicto creíble, se elige el **más conservador** (MIGRAR o PENDIENTE en lugar de CERRAR) y se anota en la columna «Nota». Esto evita descartar contenido que aún pueda aportar valor.

---

## 2. Fuente de verdad de la forma actual de trabajo

La «forma actual de trabajo» del KIT queda definida por la Constitución, los ADRs 0003–0013 y las specs cerradas recientes. Cualquier spec del backlog que se resuelva con estas fuentes se consolida.

### 2.1 ADRs implementados (ADRs 0003–0013)

| ADR | Título | Estado | Define la forma actual de |
|---|---|---|---|
| ADR-0003 | bootstrap instalador/actualizador único | Implementado | Instalación y actualización única del kit |
| ADR-0004 | flujo post-plataformado → speckit (3 escenarios) + re-indexación + Constitution por proyecto + memoria + graphify por app | Implementado | Flujo posterior al plataformado |
| ADR-0005 | agente Agent-SSD orquestador del flujo SSD | Implementado | Orquestación del flujo SSD |
| ADR-0006 | resolución de tokens MCP + `.env.mcp` portable + upgrade herramientas + self-update + activación kit | Implementado | Resolución de tokens MCP y portabilidad de `.env.mcp` |
| ADR-0007 | bootstrap delega sync de dependencias externas en `upgrade_framework` | Implementado | Delegación del sync de dependencias externas |
| ADR-0008 | Constitution v2.0.0 | Implementado | Framework de gobernanza (versión actual 2.1.0) |
| ADR-0009 | rutas MCP hardcodeadas en `opencode.json` (workaround bug #5299) | Implementado | Rutas de MCP en `opencode.json` |
| ADR-0010 | forma V2 de `opencode.json` (`mcp.servers` + `mcp.timeout.startup`) | Implementado | Estructura de configuración de MCP |
| ADR-0011 | public docs routing | Implementado | Enrutamiento de docs públicas |
| ADR-0012 | comparación de transversales por EOL normalizado (3 estados) | Aceptado | Comparación de archivos transversales |
| ADR-0013 | agentes como orquestadores delgados + whitelist de escritura por capa/tipo de proyecto | Implementado | Permisos, dominio y delegación de agentes (resuelve el núcleo de la spec 030) |

### 2.2 Constitution

| Artefacto | Versión | Ruta | Alcance |
|---|---|---|---|
| Constitution del KIT | v2.1.0 | `Documentacion/Agents_IA_TECH/.specify/constitution.md` | Reglas base y gobernanza, definida por ADR-0008 y actualizada a 2.1.0 |
| Constitution por aplicación | v2.x | `Documentacion/<App>/.specify/constitution.md` | Siembra por app durante el bootstrap (ADR-0004) |
| Constitution runtime | v2.x | `src/<App>/.specify/constitution.md` | Copia runtime gestionada por sync-kit; ignorada en git |

### 2.3 Specs cerradas recientes que definen la forma actual

| Spec | Estado | Aporta |
|---|---|---|
| 026 — agente developer único | Cerrada/Completada (ver disidencia abajo) | Agente de desarrollo unificado |
| 028 — public docs routing | Cerrada/Completada (ver disidencia abajo) | Enrutamiento de documentación pública |
| 031 — permisos y dominio de agentes | Cerrada | Permisos, dominio y delegación |
| 034 — arranque por defecto | Cerrada y commiteada hoy | Arranque por defecto del harness |

### 2.4 Nota de divergencia 026/028

El índice marca **026** y **028** como **«Completada»**, pero sus archivos `converge.md` dicen explícitamente **«lista para implementar/implementación»**. Esta discrepancia debe resolverse:

- La declaración del índice (Completada) contradice el propio artefacto de convergencia (pendiente de implementación).
- Estas dos specs siguen siendo fuente de la forma actual de trabajo, así que **no se archivan**: se registra la discrepancia en el índice y se aclara en `pendientes-implementacion.md` si su implementación quedó o no ejecutada.
- Acción: corregir el estado del índice y conciliar con el converge; no eliminar las specs.

---

## 3. Matriz de auditoría completa

Orden: de la más antigua a la más nueva, agrupando las 8 sub-specs huérfanas del grupo `000-mcp-integracion` en una fila con nota.

| # | Spec | Tema | Estado índice | Estado real | Veredicto | Destino / ADR / Spec | Acción |
|---|---|---|---|---|---|---|---|
| 1 | 000-mcp-integracion (8 sub-specs: context7, github, perplexity, pieces, playwright, semgrep, sentry, testsprite) | Integración de MCPs por herramienta | Huérfana (no listada) | 0/0, sin converge | CERRAR-OBSOLETA | Consolidado por 020-mcp-config-operativa + config real en `opencode.json` | Documentar y archivar el grupo; las 8 son casi idénticas y de plantilla |
| 2 | 000-mcp-gobernanza/007-mcp-token-resolution | Resolución de tokens MCP | Sin índice | 46/0 completa | ABSORBIDA-POR-ADR | ADR-0006 (resolución de tokens MCP) | Consolidar y cerrar; solo registrar |
| 3 | 000-mcp-gobernanza/017-garantizar-mcp-activos | Garantizar MCP activos | Sin índice | Solo spec | ABSORBIDA-POR-ADR | ADR-0006 + 020-mcp-config-operativa | Consolidar y cerrar |
| 4 | 000-mcp-integration-standard | Estándar de integración MCP | Sin índice | Solo spec | FUSIONAR | 020-mcp-config-operativa (baseline vigente) | Fusionar contenido en 020 |
| 5 | 002-script-plataforming-sync-kit | Script de sync del kit | Sin índice | 10/2, sin converge | FUSIONAR | Solapa con sync-kit (029/021) | Consolidar en sync-kit |
| 6 | 006-post-platforming-speckit | Flujo post-plataformado → speckit | Sin índice | 31/0 | ABSORBIDA-POR-ADR | ADR-0004 (3 escenarios de flujo post-plataformado) | Consolidar y cerrar |
| 7 | 008-mcp-config-portable | Config MCP portable | Sin índice | Draft 0/0 | ABSORBIDA-POR-ADR | ADR-0009/0010 (rutas hardcodeadas + forma V2) | Consolidar y cerrar |
| 8 | 009-mcp-path-normalization | Normalización de rutas MCP | Sin índice | 6/0 | ABSORBIDA-POR-ADR | ADR-0009/0010 | Consolidar y cerrar |
| 9 | 009-mcp-update-lifecycle | Ciclo de vida de actualización MCP | ACTIVA | 31/0, converge dice «script no existe, fase 7 pendiente» | FUSIONAR | Solapa con 019 + update-mcp.ps1 (spec 020) | Fusionar en 020; corregir el estado del índice (31/0 no es completa si el script no existe) |
| 10 | 010-mcp-env-file-guarantee | Garantizar `.env.mcp` | Sin índice | Solo spec | ABSORBIDA-POR-ADR | ADR-0006 (`.env.mcp` portable) | Consolidar y cerrar |
| 11 | 010-secret-leak-remediation | Remediación de fugas de secretos | En índice | 15/0 | PENDIENTE-REAL | Sigue vigente (seguridad) | Verificar tareas y mantener pendiente; no cerrar |
| 12 | 011-bootstrap-invokes-upgrade-framework | Bootstrap invoca upgrade_framework | En índice | 25/0 + ADR-0007 implementado | ABSORBIDA-POR-ADR | ADR-0007 | Consolidar y cerrar. Nota: seguridad T040–T064 sin evidencia → añadir verificación de evidencia antes de dar por cerrada la parte de seguridad |
| 13 | 012-ecc-integration | Integración ECC | En índice (familia 012) | 11/0 | PENDIENTE-REAL | Sin absorber | Mantener abierta — nunca fusionar con las otras 012 sin revisar conflicto de numeración |
| 14 | 012-ecc-mcp-bridge | Puente MCP ECC | Sin índice | Spec + contrato, sin tasks | PENDIENTE-REAL | Sin absorber | Crear tasks y numerar de nuevo para evitar colisión con 012-ecc-integration |
| 15 | 012-ecc-mcp-migration | Migración MCP ECC | Sin índice | Spec + plan, sin tasks | PENDIENTE-REAL | Sin absorber | Crear tasks y renumerar para evitar colisión 012 |
| 16 | 013-ecc-integration-lifecycle | Ciclo de vida integración ECC | En índice (mal etiquetada «012-») | 12/0 | CERRAR-COMPLETADA-SIN-REGISTRO | Corregir etiqueta a «013-» | Corregir el índice (etiqueta incorrecta) y registrar |
| 17 | 013-mcp-integration-flow | Flujo de integración MCP | ACTIVA | 9/0 | FUSIONAR | Solapa con 015-mcp-integration-flow (canónica) | Fusionar en 015 y cerrar |
| 18 | 014-manifest-versionado-y-sincronizacion | Versionado y sincronización de manifiesto | Sin índice | 8/0 | PENDIENTE-REAL | Sin absorber | Registrar y mantener; candidato a revisar contra sync-kit |
| 19 | 015-mcp-integration-flow | Flujo de integración MCP (canónica) | ACTIVA | 10/0 | PENDIENTE-REAL | Referencia canónica de flujo MCP | Mantener como canónica; absorber 013 |
| 20 | 015-sync-kit-bootstrap | Bootstrap del sync-kit | Sin índice | 10/0 | ABSORBIDA-POR-ADR | ADR-0003 (bootstrap única) + sync-kit | Consolidar y cerrar |
| 21 | 016-detectar-install-vs-update | Detectar install vs update | Sin índice | Solo spec | ABSORBIDA-POR-ADR | ADR-0004 (3 escenarios del flujo) | Consolidar y cerrar. Nota: número duplicado con 016-ssd-enforcement → resolver colisión |
| 22 | 016-ssd-enforcement | Cumplimiento del flujo SSD | En índice | 7/0 | ABSORBIDA-POR-ADR | ADR-0005 / especificación de agentes (Agent-SSD) | Consolidar y cerrar |
| 23 | 017-pendientes-implementacion-por-app | Pendientes de implementación por app | En índice | Completa | CERRAR-COMPLETADA-SIN-REGISTRO | Pendientes por app | Registrar; mantener como mecanismo vigente |
| 24 | 017-garantizar-mcp-activos | Garantizar MCP activos | Sin índice | Solo spec | FUSIONAR | Número duplicado con 017-pendientes; tema resuelto por 020 | Fusionar en 020; renumerar para evitar colisión 017 |
| 25 | 018-pendientes-estados-scrum | Estados de pendientes en scrum | En índice «en curso» | 9/0 | PENDIENTE-REAL | Sin absorber | Mantener en curso |
| 26 | 018-pensador-delegation-fix | Fix de delegación del pensador | Sin índice | Solo spec | ABSORBIDA-POR-ADR | Resuelto por 031 (permisos, dominio y delegación) | Consolidar y cerrar. Nota: número duplicado con 018-scrum → resolver |
| 27 | 019-update-mcp-lastupdate-guard | Guard de lastupdate MCP | Sin índice | 6/0 | FUSIONAR | Solapa con 009-update-lifecycle + update-mcp.ps1 | Fusionar en 020 |
| 28 | 020-mcp-config-operativa | Config operativa de MCP | En índice | 3/0 completa | PENDIENTE-REAL (baseline) | Baseline vigente | Mantener como baseline de MCP; destino de varias fusiones |
| 29 | 021-estructura-inicial-apps-nuevas | Estructura inicial de apps nuevas | Sin índice | 8 tasks abiertas | FUSIONAR | Solapa con 027-patron-estructura | Fusionar en 027; renumerar para evitar colisión 021-sync-kit |
| 30 | 021-sync-kit-agents | Sync de agentes del kit | En índice | Fase 4 pendiente | PENDIENTE-REAL | Sin absorber | Mantener; destino del sync de agentes (funcion del sync-kit) |
| 31 | 022-docker-patterns-metodologia | Metodología de patrones Docker | Sin índice | Draft/convergido | MIGRAR | Revisar como metodología | Migrar a spec numerada propia si aporta; caso contrario archivar como normativa |
| 32 | 022-docker-standard | Normativa Docker estándar | Sin índice | standard.md (sin spec.md) | MIGRAR | Normativa Docker | Migrar/registrar como normativa con spec.md si se mantiene |
| 33 | 022-ecc-integration | Integración ECC | En índice | 4/0 | PENDIENTE-REAL | Sin absorber (familia 022 distinta a las 012/013) | Mantener; vigilar colisión de numeración 022 |
| 34 | 023-copilot-mcp-actualizaciones | Actualizaciones MCP Copilot | Sin índice | 0/0 | MIGRAR | Sin tasks, tema MCP | Migrar a 020 o archivar si sin contenido |
| 35 | 023-ecc-workflows | Workflows ECC | Sin índice | 2/1 (T003 CI pendiente) | PENDIENTE-REAL | T003 CI pendiente | Mantener; completar T003 |
| 36 | 024-hooks-gobernanza-determinismo | Hooks de gobernanza y determinismo | En índice «en proceso» | 0/0 | PENDIENTE-REAL | No iniciada | Mantener pendiente; requiere implementación real |
| 37 | 025-actualizacion-herramientas-externas | Actualización de herramientas externas | En índice «en proceso» | 0/0 | PENDIENTE-REAL | Depende de sync-kit (029/030) | Mantener; bloquear hasta resolver 029/030 |
| 38 | 026-agente-developer-unico | Agente developer único | Índice «Completada» | Converge «lista para implementación» | CERRAR-COMPLETADA-SIN-REGISTRO + divergencia | Forma actual de trabajo | Corregir divergencia índice↔converge; conservar como fuente |
| 39 | 027-patron-estructura-proyecto | Patrón de estructura de proyecto | En índice «en proceso» | 0/0 | PENDIENTE-REAL | Destino de la fusión 021-estructura | Mantener; absorber 021 en el patrón |
| 40 | 028-public-docs-routing | Enrutamiento de docs públicas | Índice «Completada» | Converge «lista para implementar» | CERRAR-COMPLETADA-SIN-REGISTRO + divergencia | ADR-0011 | Corregir divergencia; ADR ya implementa el routing |
| 41 | 029-sync-eol-y-force-real | Sync con EOL y force real | En índice «en proceso» | 9/37 | PENDIENTE-REAL | Bloqueada por DD-08; ADR-0012 aceptado | Mantener; la comparación de transversales ya la define ADR-0012 |
| 42 | 030-whitelist-contextual-por-tipo-proyecto | Whitelist de escritura contextual | En índice | 0/66 | ABSORBIDA-POR-ADR | ADR-0013 (whitelist de escritura por capa/tipo) | Consolidar y cerrar — núcleo resuelto por ADR-0013 |
| 43 | 031-permisos-y-dominio-de-agentes | Permisos, dominio y delegación | Cerrada | Cerrada | CERRAR-COMPLETADA-SIN-REGISTRO | Forma actual | Registrar como cerrada/base |
| 44 | 032-actualizacion-knowledge-base | Actualización de knowledge base | Índice «Cerrado» | 0 tasks, «quedan por ejecutar» | PENDIENTE-REAL (divergencia grave) | No iniciada de hecho | Corregir el índice: NO está cerrada; pasarla a pendiente real |
| 45 | 033-refresh-conocimiento-mcp | Refresh de conocimiento MCP | Índice «en proceso T01-T07» | 0 tasks, todo «Pendiente» | PENDIENTE-REAL (no iniciada) | No iniciada de hecho | Corregir el índice: no hay trabajo hecho; mantener pendiente |
| 46 | 034-arranque-agentes-por-defecto | Arranque por defecto del harness | Cerrada | Cerrada y commiteada hoy | CERRAR-COMPLETADA-SIN-REGISTRO | Forma actual | Registrar como cerrada/base (ya commiteada) |
| 47 | No-numerada: cambio-vision | Cambio de visión | Sin índice | Solo spec | CERRAR-OBSOLETA | Sin numerar, sin tasks | Revisar y archivar o numerar si aporta |
| 48 | No-numerada: kit-generico | Kit genérico | Sin índice | 9/0 | MIGRAR | Generización del kit | Migrar a spec numerada si aporta valor transversal |
| 49 | No-numerada: metodologia-ssd-speckit | Metodología SSD + Speckit | Sin índice | 0/0 | CERRAR-OBSOLETA | Sin tasks; tema cubierto por ADR-0005 | Archivar/referenciar la metodología en Agent-SSD |
| 50 | No-numerada: plataforma-bootstrap-instalador-unico | Plataforma: bootstrap instalador único | Sin índice | 1/0 | ABSORBIDA-POR-ADR | ADR-0003 (bootstrap único) | Consolidar y cerrar |
| 51 | No-numerada: solucion-generica | Solución genérica | Sin índice | 14/0 | MIGRAR | Solución genérica transversal | Migrar a spec numerada si sigue aplicando |

**Nota de agrupación (fila 1):** las 8 sub-specs de `000-mcp-integracion` (context7, github, perplexity, pieces, playwright, semgrep, sentry, testsprite) son huérfanas, están en 0/0, no tienen converge y son prácticamente idénticas (plantilla por herramienta). Se agrupan en una sola fila; el destino común es 020-mcp-config-operativa y la configuración real que ya existe en `opencode.json`.

**Conteo de filas:** 51 filas de specs (46 numeradas/estado + las 8 del grupo 000 agrupadas en 1 fila + 4 no-numeradas agrupadas... se listan por separado en 47–51). Total de entradas de inventario cubiertas: 46 + 8 + 5 no-numeradas = 59 entradas mapeadas a 51 filas.

---

## 4. Hallazgos de consistencia del índice

Enumero de forma concreta los problemas detectados comparando disco vs índice.

### 4.1 Specs huérfanas (en disco pero fuera del índice)

Estas tienen contenido/tasks en disco pero el índice no las lista:

| Spec | Estado real | Riesgo |
|---|---|---|
| 000-mcp-integracion (8 sub-specs) | 0/0, sin converge | Sin seguimiento; se pueden archivar sin aviso |
| 000-mcp-gobernanza/007-mcp-token-resolution | 46/0 completa | Completada sin registrar |
| 006-post-platforming-speckit | 31/0 | Absorbida por ADR-0004 sin registrar |
| 009-mcp-path-normalization | 6/0 | Absorbida por ADR-0009/0010 |
| 010-mcp-env-file-guarantee | Solo spec | Absorbida por ADR-0006 |
| 014-manifest-versionado-y-sincronizacion | 8/0 | Sin seguimiento |
| 015-sync-kit-bootstrap | 10/0 | Absorbida por ADR-0003 |
| 019-update-mcp-lastupdate-guard | 6/0 | Sin seguimiento |
| 021-estructura-inicial-apps-nuevas | 8 abiertas | Sin seguimiento |
| 023-copilot-mcp-actualizaciones | 0/0 | Sin tracking |

### 4.2 Duplicados de numeración

Varias specs comparten número, generando colisiones de identidad:

| Colisión | Spec 1 | Spec 2 | Resolución |
|---|---|---|---|
| 016 | 016-detectar-install-vs-update | 016-ssd-enforcement | Renumerar detectar-install al 016 original; ssd-enforcement absorbe por ADR-0005 |
| 017 | 017-pendientes-implementacion-por-app | 017-garantizar-mcp-activos | Renumerar garantizar-mcp hacia 020 |
| 018 | 018-pendientes-estados-scrum | 018-pensador-delegation-fix | Renumerar pensador-delegation (resuelto por 031) |
| 012 | 012-ecc-integration | 012-ecc-mcp-bridge / 012-ecc-mcp-migration | Renumerar bridge y migration |
| 013 | 013-ecc-integration-lifecycle | 013-mcp-integration-flow | Distinguir por familia (ECC vs MCP flow) y corregir etiqueta índice «012-» |
| 021 | 021-estructura-inicial-apps-nuevas | 021-sync-kit-agents | Fusionar estructura en 027 |
| 022 | 022-docker-patterns-metodologia | 022-docker-standard / 022-ecc-integration | Distinguir metodología/normativa/ECC |

### 4.3 Divergencias disco ↔ índice

| Spec | Índice dice | Disco real | Gravedad |
|---|---|---|---|
| 026 | Completada | Converge «lista para implementación» | Media — divergencia de estado |
| 028 | Completada | Converge «lista para implementar» | Media — divergencia de estado |
| 009-mcp-update-lifecycle | 31/0 (aparenta completa) | Converge «script no existe, fase 7 pendiente» | Alta — índice sobreestima |
| 013-ecc-integration-lifecycle | Etiqueta «012-» | Es familia 013 | Baja — etiqueta incorrecta |
| 032 | Cerrado | 0 tasks, «quedan por ejecutar» | Alta — marcada cerrada sin ejecutar |
| 033 | En proceso T01-T07 | 0 tasks, todo «Pendiente» | Media — marcada en proceso sin trabajo |

### 4.4 Notas específicas

- **009-mcp-update-lifecycle** y **019-update-mcp-lastupdate-guard**: convergen en la misma entidad `update-mcp.ps1` (spec 020). Antes de cerrar hay que verificar con 020 que el script real existe, porque el converge de 009 dice que no existe.
- **011-bootstrap-invokes-upgrade-framework**: aunque ADR-0007 la absorbe, la parte de seguridad T040–T064 no tiene evidencia de ejecución. Se cierra la spec por absorción de ADR, pero se deja pendiente la verificación de evidencia de seguridad.
- **032 y 033**: son las divergencias más graves porque el índice presenta trabajo que en disco no existe; no deben archivarse ni marcarse cerradas/en-proceso sin antes corregir el estado real.

---

## 5. Plan de migración/cierre recomendado

### 5.1 ABSORBER y consolidar (7 specs)

Convergen en ADRs implementados. Acción: crear una nota de consolidación por ADR y marcar la spec como cerrada.

| Spec | Absorbido por |
|---|---|
| 000-mcp-gobernanza/007-mcp-token-resolution | ADR-0006 |
| 000-mcp-gobernanza/017-garantizar-mcp-activos | ADR-0006 + 020 |
| 006-post-platforming-speckit | ADR-0004 |
| 010-mcp-env-file-guarantee | ADR-0006 (`.env.mcp`) |
| 015-sync-kit-bootstrap | ADR-0003 + sync-kit |
| 016-ssd-enforcement | ADR-0005 |
| 030-whitelist-contextual (núcleo) | ADR-0013 |

**Plus absorción parcial:** 008-mcp-config-portable y 009-mcp-path-normalization van contra ADR-0009/0010 (ver 5.2 por su condición de draft/6 tasks).

### 5.2 CERRAR-OBSOLETA (4 + grupo 000)

| Spec | Motivo |
|---|---|
| 000-mcp-integracion (8 sub-specs) | Plantilla sin contenido, absorbida por 020 y `opencode.json` real |
| 008-mcp-config-portable | Draft 0/0, forma actual definida por ADR-0009/0010 |
| 009-mcp-path-normalization | 6/0, absorbida por ADR-0009/0010 |
| 018-pensador-delegation-fix | Resuelto por 031; numeración duplicada |
| No-numerada: metodologia-ssd-speckit | Sin tasks; tema cubierto por ADR-0005 (recomendación: referenciarla en el agente Agent-SSD en lugar de spec) |
| No-numerada: cambio-vision | Solo spec, sin numerar ni tasks |

### 5.3 CERRAR-COMPLETADA-SIN-REGISTRO (solo registrar)

| Spec | Nota |
|---|---|
| 013-ecc-integration-lifecycle | Corregir etiqueta índice «012-» → «013-» |
| 017-pendientes-implementacion-por-app | Mantener mecanismo; registrar |
| 026-agente-developer-unico | Conservar como fuente; corregir divergencia índice↔converge |
| 028-public-docs-routing | Conservar como fuente; corregir divergencia; ADR-0011 |
| 031-permisos-y-dominio-de-agentes | Registrar como cerrada/base |
| 034-arranque-agentes-por-defecto | Registrar como cerrada/base (commiteada hoy) |

### 5.4 MIGRAR a spec nueva numerada (NN)

| Spec | Motivo y destino |
|---|---|
| 022-docker-patterns-metodologia | Draft convergido → migrar a spec numerada de metodología Docker si aporta; si no, archivar como normativa |
| 022-docker-standard | standard.md sin spec.md → crear spec.md y numerar, o archivar |
| 023-copilot-mcp-actualizaciones | 0/0 sin tasks → migrar a 020 (MCP) |
| No-numerada: kit-generico | 9/0 → numerar si aporta transversal; caso contrario archivar |
| No-numerada: solucion-generica | 14/0 → numerar si sigue aplicando |

### 5.5 FUSIONAR

| Spec (a fusionar) | En destino |
|---|---|
| 000-mcp-integration-standard | 020-mcp-config-operativa |
| 002-script-plataforming-sync-kit | sync-kit (029/021) |
| 009-mcp-update-lifecycle | 020 (update-mcp.ps1); corregir estado índice |
| 013-mcp-integration-flow | 015-mcp-integration-flow (canónica) |
| 017-garantizar-mcp-activos | 020 |
| 019-update-mcp-lastupdate-guard | 020 |
| 021-estructura-inicial-apps-nuevas | 027-patron-estructura |

### 5.6 PENDIENTE-REAL (quedan abiertas sin migración)

| Spec | Justificación |
|---|---|
| 010-secret-leak-remediation | Seguridad vigente (15/0) |
| 012-ecc-integration | 11/0, sin absorber |
| 012-ecc-mcp-bridge | Spec + contrato; crear tasks |
| 012-ecc-mcp-migration | Spec + plan; crear tasks |
| 014-manifest-versionado-y-sincronizacion | 8/0 |
| 015-mcp-integration-flow | Canónica de flujo MCP |
| 018-pendientes-estados-scrum | En curso 9/0 |
| 020-mcp-config-operativa | Baseline vigente; destino de fusiones |
| 021-sync-kit-agents | Fase 4 pendiente |
| 022-ecc-integration | 4/0 |
| 023-ecc-workflows | T003 CI pendiente |
| 024-hooks-gobernanza-determinismo | 0/0, no iniciada |
| 025-actualizacion-herramientas-externas | Depende de sync-kit (029/030) |
| 027-patron-estructura-proyecto | 0/0; destino de 021-estructura |
| 029-sync-eol-y-force-real | Bloqueada por DD-08; ADR-0012 ya aceptado |
| 032-actualizacion-knowledge-base | Corregir: NO cerrada, no iniciada |
| 033-refresh-conocimiento-mcp | Corregir: no iniciada |

---

## 6. Impacto sobre 029/030

### 6.1 Specs a absorber/cerrar ANTES de tocar 029/030

Estas specs se solapan con el espacio de trabajo de sync-kit (029) y de permisos/whitelist (030). Cerrarlas primero ordena el terreno y evita re-trabajo:

| Spec | Por qué antes |
|---|---|
| 002-script-plataforming-sync-kit | Resulta de probar `sync-agents.ps1`; 002 y su script deben consolidarse en 029/021 ANTES de avanzar 029 |
| 030-whitelist-contextual | Núcleo resuelto por ADR-0013; cerrarla antes permite que 029 no arrastre su scope muerto |
| 021-estructura-inicial-apps-nuevas | Solapa con 027; su resolución afecta qué estructura valida sync-kit |
| 007/006 (mcp-token, post-platforming) | Yacen bajo el mismo dominio del sync de config que toca 029 |
| 015-sync-kit-bootstrap | Absorbida por ADR-0003; eliminar su scope del sync-kit reduce ruido de 029 |

**Respuesta directa al usuario** («¿qué otras antes de la 029, 030 falta?»): además de 029/030, conviene **consolidar primero 002**, **cerrar 030 (ADR-0013)**, **fusionar 013 en 015** y **resolver 021-estructura en 027**, porque todas comparten el mecanismo de sync de configuración y permisos que 029/030 formalizarán.

### 6.2 Riesgos SR del sync como candidatos a spec 035 futura

Los riesgos de sync **SR-01, SR-02, SR-03 y SR-10** (identificados en la spec 029) no quedan resueltos por esta auditoría. Son candidatos reales para una **spec futura 035 "gobernanza del sync-kit"**, que:

- Defina la política de EOL normalizado ya aceptada (ADR-0012).
- Formalice los 3 estados de comparación de transversales (ADR-0012).
- Establezca escenarios de convergencia y force real (SR-01/02/03) sin romper el sync por proyectos.
- Incorpore el SR-10 (dependencias externas) como dominio delegado a `upgrade_framework` (ADR-0007).

Esta auditoría NO crea la 035; solo la señala como siguiente objetivo de consolidación una vez aplicados los veredictos.

---

## 7. Criterios de aceptación del informe

Para dar por cerrada esta auditoría se requiere:

| # | Criterio | Estado |
|---|---|---|
| 1 | Revisión del usuario del documento completo (sin placeholders, con todas las filas de la matriz) | Pendiente de revisión |
| 2 | Aprobación explícita de los veredictos por spec (51 filas) | Pendiente de aprobación |
| 3 | Aprobación de las acciones de consolidación: notas de ADR para SPECs ABSORBIDAS (7), archivos para CERRAR-OBSOLETA, registros en índice para CERRAR-COMPLETADA | Pendiente |
| 4 | Creación de las spec nuevas numeradas para las MIGRAR (Docker, kit-genérico, solución-genérica) si se confirma que aportan valor | Pendiente |
| 5 | Corrección de las divergencias del índice (026/028, 009-mcp-update, 013-etiqueta, 032, 033) | Pendiente |
| 6 | Resolución de colisiones de numeración (016/017/018/012/021/022) | Pendiente |
| 7 | Confirmación de que 029/030 solo se avanza tras cerrar 002 y 030 (ADR-0013) | Pendiente |
| 8 | Verificación de evidencia de seguridad T040–T064 en 011 antes de dar por cerrada su parte de seguridad | Pendiente |

**Nota final de honestidad:** este informe registra veredictos y acciones recomendadas, pero **no ejecuta** ninguna de ellas (no archiva, no renombra, no edita índices ni specs). La ejecución debe hacerse en pasos aprobados por el usuario, verificando escritura tras cada cambio, conforme a la regla de integridad de trabajo del KIT.
