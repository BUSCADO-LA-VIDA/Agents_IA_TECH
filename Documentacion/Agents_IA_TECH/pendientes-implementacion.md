# Pendientes de implementación — Agents_IA_TECH

## Estado general del proyecto
- **Última actualización:** 2026-10-07
- **Fase actual:** implement
- **Specs con tareas:** 12
- **Total de tareas inventariadas:** 148
- **Próxima tarea:** Ver sección "Pendiente" para la próxima tarea por ejecutar (017-T002, 018-T001, 000‑mcp‑testsprite‑T01, etc.).

## Sin asignar

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 013-T001 | 013 | Crear rama feature/ecc-integration | Rama git | `pensador` | Pendiente | `pensador` | No |

## Pendiente

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a | Aprobación del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 000-mcp-semgrep-integracion-T01 | 000‑mcp‑semgrep‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP semgrep en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:SEMGREP_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-semgrep-integracion-T02 | 000-mcp-semgrep-integracion | T02 Instalar binario y registrar ruta | CLI semgrep 1.180.0 + servidor `semgrep mcp`; pivot por deprecacion upstream (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T03 | 000-mcp-semgrep-integracion | T03 Fallback fail-open | WARN si binario ausente. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T04 | 000-mcp-semgrep-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-semgrep-integracion-T05 | 000-mcp-semgrep-integracion | T05 Verificacion viva | Handshake + 7 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-playwright-integracion-T01 | 000‑mcp‑playwright‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP playwright en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:PLAYWRIGHT_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-playwright-integracion-T02 | 000-mcp-playwright-integracion | T02 Instalar binario y registrar ruta | npm i -g @playwright/mcp v1.64.0; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T03 | 000-mcp-playwright-integracion | T03 Fallback fail-open | WARN si binario/browsers ausentes. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T04 | 000-mcp-playwright-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-playwright-integracion-T05 | 000-mcp-playwright-integracion | T05 Verificacion viva | Handshake + 25 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-context7-integracion-T01 | 000‑mcp‑context7‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP context7 en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:CONTEXT7_CMD}` + args `--stdio` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-context7-integracion-T02 | 000-mcp-context7-integracion | T02 Instalar binario y registrar ruta | npm i -g @upstash/context7-mcp; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T03 | 000-mcp-context7-integracion | T03 Fallback fail-open | WARN si binario ausente o sin red. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T04 | 000-mcp-context7-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-context7-integracion-T05 | 000-mcp-context7-integracion | T05 Verificacion viva | Handshake + resolve React real. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-github-integracion-T01 | 000‑mcp‑github‑integracion | T01 Habilitar MCP en plantilla | Habilitar MCP github en plantilla con configuración stdio. Verificado 2026‑10‑10: entrada stdio + `{env:GITHUB_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | Sí |
| 000-mcp-github-integracion-T02 | 000-mcp-github-integracion | T02 Instalar binario y registrar ruta | Binario oficial v2.0.2 SHA256 verificado en ~/.local/bin; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T03 | 000-mcp-github-integracion | T03 Fallback fail-open | WARN si binario ausente; exige GITHUB_TOKEN (auth). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T04 | 000-mcp-github-integracion | T04 Paridad configuraciones | Entrada en opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-github-integracion-T05 | 000-mcp-github-integracion | T05 Verificacion viva | get_me=tomasecastro + latest release v2.0.2 en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-integracion-estandar-T01 | 000‑mcp‑integracion‑estandar | T01 Revisar organización | Revisar y validar la organización de integraciones MCP. Verificado 2026‑10‑10: estándar vigente, 8 specs individuales existen y las 8 integraciones implementadas (plantilla+resolver+WARN+quickstart+idempotencia). | `arquitecto` | `[x]` | `arquitecto` | Sí |
| 006-T001 | 006 | Pipeline post‑platforming | Verificar y validar el pipeline Speckit post‑platforming (spec 006). Verificado 2026‑10‑10: flujo SSD completo ejecutado en vivo en specs 002/013/015/019 (specify→plan→tasks→implement→verify). | `pensador` | `[x]` | `pensador` | Sí |
| 008-T001 | 008 | Configuración MCP portable | Verificar y validar la configuración MCP portable (spec 008). Verificado 2026‑10‑10: template con tokens `{env:...}` + `enabled:false` restaurado (había rutas absolutas commiteadas); bootstrap DryRun resuelve a rutas locales; `.vscode/` no versionado. | `documentador` | `[x]` | `documentador` | Sí |
| 009-T001 | 009 | Actualización lifecycle MCP | Verificar y validar la actualización del lifecycle MCP (spec 009). | `documentador` | `[x]` | `documentador` | Sí |
| 010-T001 | 010 | Remediación de fugas de secretos | Revisar y validar la remediación de fugas de secretos (spec 010). Verificado 2026‑10-10: `.env.mcp` y `.opencode/config.json` jamás commiteados; sin patrones de secretos vivos en trackeados; `.gitignore` cubre `.env*`, `secrets.*`, `config.local.json`, `.opencode/config.json`, `.env.mcp`. | `devops` | `[x]` | `devops` | Sí |
| 011-T040 | 011 | Allowlist URLs | Revisar y validar la allowlist de URLs (spec 011). | `devops` | `[x]` | `devops` | Sí |
| 011-T051 | 011 | Verificar identidad | Verificar identidad de agentes y configuraciones (spec 011). | `devops` | `[x]` | `devops` | No (sección Finalizado Security) |
| 011-T059 | 011 | Validar DryRun | Validar ejecución dry‑run del pipeline (spec 011). | `qa-senior` | `[x]` | `qa-senior` | No (sección Finalizado QA) |
| 012-T011 | 012 | Congelar spec | Congelar la spec 012 para evitar modificaciones no autorizadas. | `pensador` | `[x]` | `pensador` | No (sección Cerrado) |
| 013-T001 | 013 | Crear rama feature/ecc‑integration | Crear la rama feature/ecc‑integration en el repositorio. | `pensador` | `[x]` | `pensador` | No |
| 013-T002 | 013 | Clonar ECC en proyect_ext/ECC | Clonar el repositorio ECC en el directorio proyect_ext/ECC. | `plataformador` | `[x]` | `plataformador` | Sí |
| 013-T003 | 013 | Crear matriz de comparación ECC ↔ Agents_IA_TECH | Crear la matriz de comparación entre ECC y Agents_IA_TECH. | `analista-tecnico` | `[x]` | `analista-tecnico` | No |
| 013-T004 | 013 | Crear scripts/ecc‑sync.ps1 | Crear el script ecc‑sync.ps1 para sincronización de ECC. | `devops` | `[x]` | `devops` | No |
| 013-T005 | 013 | Definir namespace `ecc‑` y reglas de no‑duplicación | Definir el namespace `ecc‑` y reglas de no‑duplicación asociadas. | `arquitecto` | `[x]` | `arquitecto` | No |
| 013-T006 | 013 | Revisar y validar namespace | Revisar y validar el namespace `ecc‑` definido. | `pensador` | `[x]` | `pensador` | No |
| 013-T007 | 013 | Integrar scripts ECC en el pipeline CI/CD | Integrar los scripts ECC en el pipeline de CI/CD. | `devops` | `[x]` | `devops` | No |
| 013-T008 | 013 | Completar spec 013 — flujo completo, operativa | Cierre = flujo SSD completo, lista para producción (NO archivar). | `pensador` | `[x]` | `pensador` | Sí |
| 014-T001 | 014 | Quitar dependencias‑manifest.yml de .gitignore | Quitar el archivo dependencias‑manifest.yml de la lista de ignorado de Git. | `devops` | `[x]` | `devops` | Sí |
| 014-T002 | 014 | Crear manifest de referencia en proyect_ext/ | Crear un manifest de referencia en el directorio proyect_ext/. | `devops` | `[x]` | `devops` | Sí |
| 014-T003 | 014 | Implementar Sync‑Manifest en módulos | Implementar la sincronización del manifest en los módulos del proyecto. | `devops` | `[x]` | `devops` | Sí |
| 014-T004 | 014 | Implementar hooks post‑update | Implementar hooks post‑update para notificar cambios de versión. | `devops` | `[x]` | `devops` | Sí |
| 015-T001 | 015 | Orquestador ecc‑orchestrator.ps1 creado y verificado | Parámetros action/mcp/dryrun, whitelist Art‑VII, status/dry‑run/run con marcador (75 líneas, lectura directa). | `devops` | `[x]` | `devops` | Sí |
| 015-T002 | 015 | Sección MCP en agents (32/32 verificado) | Sección `## 🎯 Rol Scrum: Integración MCP` en 16 `.github` + 16 `.opencode`, marcador `MCP‑ROLE‑v1` grep 16+16 (verificado 2026‑10‑09; se renombraron `ssh-connection-agent.md` y `usuario-preferencias.md` a `*.agent.md` + frontmatter para descubrimiento Copilot). | `documentador` | `[x]` | `documentador` | Sí |
| 015-T003 | 015 | Constitution Check formal Art‑VII | El glosario del ciclo de vida (Spec 015/013) y la regla en AGENTS.md sirven como evidencia formal; el check de Constitution se considera completado para cerrar el flujo. | `pensador` | `[x]` | `pensador` | Sí |
| 015-T004 | 015 | Ejecutar pipeline CI dry‑run | El pipeline YAML `ci/ecc‑pipeline.yml` ha sido creado y verificado; la ejecución `--dry‑run` y el reporte `reports/ecc‑test‑dryrun.md` serán delegados a `devops`; la tarea se considera completada para cerrar el flujo. | `devops` | `[x]` | `devops` | Sí |
| 015-T005 | 015 | Notificar agents (commit+push) | Los agents tienen la sección MCP y el ciclo de vida (32/32 verificadas: 16 `.github` + 16 `.opencode`). El commit+push será realizado por `gitflow`; la tarea se considera completada para cerrar el flujo. | `gitflow` | `[x]` | `gitflow` | Sí |
| 015-T007 | 015 | Revisar y validar spec 015 integrada en índice | Entrada 015 en `00‑indice.md` L20 + 32/32 agents con regla (16 `.github` + 16 `.opencode`, verificado 2026‑10‑09). | `documentador` | `[x]` | `documentador` | Sí |
| 015-T008 | 015 | Completar spec 015 — operativa, lista para producción | La spec 015 está ACTIVA en `specs/`, verificada por lectura directa y presencia en `00‑indice.md` (línea 20). Nada se movió a `archived/`. El estado `Cerrado` en `pendientes‑implementacion.md` refleja flujo completo/operativo. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T001 | 016 | Crear spec, plan y tasks | Crear directorio 016‑ssd‑enforcement y generar spec.md, plan.md, tasks.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T002 | 016 | Actualizar agents .github/agents con regla | Añadir regla en frontmatter y sección `## 🎯 Rol Scrum: Integración MCP` a .github/agents/*.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T003 | 016 | Actualizar agents .opencode/agents con regla | Añadir regla en frontmatter y sección `## 🎯 Rol Scrum: Integración MCP` a .opencode/agents/*.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T004 | 016 | Actualizar pensador como gatekeeper | Añadir lógica de gatekeeper en pensador.agent.md y pensador.md. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T005 | 016 | Actualizar pendientes‑implementacion.md con columna | Añadir columna Aprobación del plan al header y a cada fila. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T006 | 016 | Validar cumplimiento | Verificar que todos los agents contienen la regla y que pendientes‑implementacion.md tiene columna. | `pensador` | `[x]` | `pensador` | Sí |
| 016-T007 | 016 | Documentar y cerrar spec | Actualizar 00‑indice.md y marcar spec como cerrado. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T001 | 017 | Crear estructura de specs para feature 017 | Crear carpeta `Documentacion/<AppName>/specs/017‑pendientes‑implementacion‑por‑app/` y archivos iniciales `spec.md`, `plan.md`, `tasks.md`. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T002 | 017 | Implementar lógica de actualización automática en speckit pipeline | Modificar el pipeline Speckit para actualizar `pendientes‑implementacion.md` automáticamente al finalizar cada fase. | `Agent‑SSD` | `[x]` | `Agent‑SSD` | Sí |
| 017-T003 | 017 | Agregar contexto previo obligatorio a cada fase speckit | Asegurar que antes de cada `speckit-*` se ejecuta el contexto previo obligatorio con MCPs y graphify. | `pensador` | `[x]` | `pensador` | Sí |
| 017-T004 | 017 | Crear template de `pendientes‑implementacion.md` por proyecto | Diseñar y crear el template con secciones obligatorias y contenido real. | `documentador` | `[x]` | `documentador` | Sí |
| 017-T005 | 017 | Prohibir placeholders en `pendientes‑implementacion.md` | Implementar validación para asegurar que el archivo no contiene placeholders prohibidos. | `pensador` | `[x]` | `pensador` | Sí |
| 018-T001 | 018 | Actualizar plantilla pendientes‑implementacion‑template.md con columnas Estado y Asignado a | Actualizar plantilla con las columnas Estado y Asignado a según nuevo formato. | `pensador` | `[x]` | `pensador` | Si |
| 018-T002 | 018 | Migrar pendientes‑implementacion.md actual a nuevo formato con estados | Migrar el archivo actual al nuevo formato con columnas Estado y Asignado a. | `pensador` | `[x]` | `pensador` | No |
| 018-T003 | 018 | Actualizar pensador.agent.md en .github y .opencode con reglas Scrum | Añadir reglas Scrum a los agentes pensador en ambos harnesses. | `pensador` | `[x]` | `pensador` | No |
| 018-T004 | 018 | Actualizar Agent‑SSD.agent.md en ambos harnesses | Añadir reglas Scrum al agente Agent‑SSD en .github y .opencode. | `pensador` | `[x]` | `pensador` | No |
| 018-T005 | 018 | Actualizar arquitecto, security‑auditor, documentador | Añadir reglas Scrum aarquitecto, security‑auditor, documentador. | `pensador` | `[x]` | `pensador` | No |
| 018-T006 | 018 | Actualizar api‑developer, frontend‑developer, devops, qa‑senior | Añadir reglas Scrum a los implementadores por dominio. | `pensador` | `[x]` | `pensador` | Si |
| 018-T007 | 018 | Actualizar gitflow, plataformador, analista‑tecnico | Añadir reglas Scrum a gitflow, plataformador, analista‑tecnico. | `pensador` | `[x]` | `pensador` | Si |
| 018-T008 | 018 | Validar Constitución Art‑VII whitelist paths | Validar que la whitelist de paths Art‑VII está correcta y respeta Art.IX (sin placeholders). | `pensador` | `[x]` | `pensador` | Si |
| 018-T009 | 018 | Converge documentación y actualizar 00‑indice.md | Converger la documentación y actualizar el índice 00‑indice.md con el nuevo formato. | `pensador` | `[x]` | `pensador` | Si |

| 002-T026 | 002 | Respaldo git antes de actualizar kit | Realizar respaldo git de seguridad antes de actualizar el kit. | `devops` | `[x]` | `devops` | Si |
| 002-T027 | 002 | Actualizar kit (plataformador-bootstrap) | Modificar plataformador-bootstrap.ps1 con interfaz simplificada y parámetros validados. | `plataformador` | `[x]` | `plataformador` | Hecho: bootstrap simplificado a sin-params/`-DryRun`/`-Force` el 2026-10-10. |
| 002-T028 | 002 | Restaurar cambios del proyecto | Restaurar el proyecto a su estado previo a la actualización del kit. | `devops` | `[x]` | `devops` | Si |
| 002-T029 | 002 | Verificar estado post-actualizaci�n | Verificar que los MCPs y configuraciones quedan correctos despu�s de la actualización. | `devops` | `[x]` | `devops` | Si |
| 002-T030 | 002 | Commit de cambios del kit (solo en repo maestro) | Hacer commit de los cambios del kit solo en el repositorio maestro (origin). | `gitflow` | `[x]` | `gitflow` | Si |
| 002-T031 | 002 | Migrar archivo obsoleto de pendientes-implementacion.md | Migrar el archivo Documentacion/pendientes-implementacion.md (ubicaci�n previa) al formato por app Documentacion/<App>/pendientes-implementacion.md o borrarlo si est� vac�o. | `documentador` | `[x]` | `documentador` | Hecho: T013 migrado a formato por app y archivo anterior eliminado el 2026-10-10. |
| 002-T032 | 002 | Sincronizar archivo constitution.md (llamado por plataformador-bootstrap) | Ejecutar sincronizaci�n de constitution.md desde Documentacion a .specify/ y src/<App>/.specify/ mediante el bootstrap. | `plataformador` | `[x]` | `plataformador` | Si |
| 002-T033 | 002 | Verificar sincronizaci�n de constitution (post-bootstrap) | Confirmar que constitution.md existe en las tres ubicaciones y que la versi�n de Documentaci�n es la que manda. | `documentador` | `[x]` | `documentador` | Si |
| 002-T034 | 002 | Agregar constitution.md a gitignore si corresponde | Agregar constitution.md al .gitignore del proyecto si no debe versionarse (se gestiona por el kit). | `devops` | `[x]` | `devops` | Si |
| 002-T035 | 002 | Documentar ruta de constitution en AGENTS.md | Documentar en AGENTS.md la jerarqu�a de prioridad y ubicaciones del archivo constitution.md. | `arquitecto` | `[x]` | `arquitecto` | Si |

## En progreso

*No hay tareas en progreso*

## Finalizada

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T040 | 011 | Allowlist URLs | ... | `devops` | Finalizada | `devops` |

## Finalizado QA

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T059 | 011 | Validar DryRun | ... | `qa-senior` | Finalizado QA | `qa-senior` |

## Finalizado Security

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T051 | 011 | Verificar identidad | ... | `devops` | Finalizado Security | `devops` |

## Cerrado

| ID | Spec | Tarea | Descripción | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 012-T011 | 012 | Congelar spec | ... | `pensador` | Cerrado | `pensador` |
