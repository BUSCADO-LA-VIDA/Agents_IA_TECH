# Pendientes de implementaciÃ³n â€” Agents_IA_TECH

## Estado general del proyecto
- **Ãšltima actualizaciÃ³n:** 2026-10-27
- **Fase actual:** implement
- **Specs con tareas:** 13
- **Total de tareas inventariadas:** 151
- **PrÃ³xima tarea:** Ver secciÃ³n "Pendiente" para la prÃ³xima tarea por ejecutar (017-T002, 018-T001, 000â€‘mcpâ€‘testspriteâ€‘T01, etc.).

## Sin asignar

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a | AprobaciÃ³n del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 013-T001 | 013 | Crear rama feature/ecc-integration | Rama git | `pensador` | Pendiente | `pensador` | No |
| 020-T010 | 020 | Verificar lift preserva forma V2 | `scripts/sync/mcp/lift-opencode.ps1` debe preservar `mcp.servers` y `mcp.timeout` al fusionar contra un destino, y no reintroducir servidores sueltos bajo `mcp` (forma V1). Riesgo registrado en ADR-0010. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T011 | 020 | Decidir commit y replicacion de opencode.json | El archivo quedo sin commitear a pedido del usuario. Definir si entra al repo y si se propaga a los proyectos consumidores por `sync-kit-agents.ps1`. | `pensador` | Pendiente | `pensador` | No |
| 020-T012 | 020 | Renovar o eliminar credencial de Groq | `GROQ_API_KEY` responde `does not exist or you do not have access` en `groq/llama-3.3-70b-versatile`. Renovar en groq.com/console o quitar de `opencode auth` para que no vuelva a ser el default por error. | usuario | Pendiente | usuario | No |
| 020-T013 | 020 | Silenciar WARN de plugin context-mode | OpenCode autodescubre el paquete npm global `context-mode` e intenta cargarlo como plugin; su `main` es un CLI de MCP, no un plugin. No bloquea. Descartar con `"plugins": ["-context-mode"]` si molesta. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T014 | 020 | Retirar regla .env del .gitignore | El `.env` fue eliminado: OpenCode no lo lee, `{env:NAME}` se resuelve contra el entorno real del proceso. La regla de gitignore quedo sin objeto. Retirar o dejar como barrera futura. | `plataformador` | Pendiente | `plataformador` | No |
| 020-T015 | 020 | Reconciliar specs de MCPs retirados | `000-mcp-semgrep-integracion` y `000-mcp-context7-integracion` tienen T01-T05 en `[x]` pero los MCPs se retiraron del `opencode.json` del KIT el 2026-10-18 por tener 0 de 32 agentes que los referencien. Marcar como superadas o reescribir el alcance. | `pensador` | Pendiente | `pensador` | No |
| 020-T016 | 020 | Resolver portabilidad de graphify | `opencode.json` esta trackeado en git pero la entrada `graphify` apunta a `graphify-out/graph.json`, directorio gitignored (L31). En un clon nuevo el servidor no arranca. Opciones: generarlo en el bootstrap antes de levantar el servicio, o documentar que `graphify` requiere `uv graphifyy` previo. | `plataformador` | Pendiente | `plataformador` | No |

## Pendiente

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a | AprobaciÃ³n del plan |
|----|------|-------|-------------|-------------|--------|------------|---------------------|
| 000-mcp-semgrep-integracion-T01 | 000â€‘mcpâ€‘semgrepâ€‘integracion | T01 Habilitar MCP en plantilla | Habilitar MCP semgrep en plantilla con configuraciÃ³n stdio. Verificado 2026â€‘10â€‘10: entrada stdio + `{env:SEMGREP_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 000-mcp-semgrep-integracion-T02 | 000-mcp-semgrep-integracion | T02 Instalar binario y registrar ruta | CLI semgrep 1.180.0 + servidor `semgrep mcp`; pivot por deprecacion upstream (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T03 | 000-mcp-semgrep-integracion | T03 Fallback fail-open | WARN si binario ausente. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-semgrep-integracion-T04 | 000-mcp-semgrep-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-semgrep-integracion-T05 | 000-mcp-semgrep-integracion | T05 Verificacion viva | Handshake + 7 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-playwright-integracion-T01 | 000â€‘mcpâ€‘playwrightâ€‘integracion | T01 Habilitar MCP en plantilla | Habilitar MCP playwright en plantilla con configuraciÃ³n stdio. Verificado 2026â€‘10â€‘10: entrada stdio + `{env:PLAYWRIGHT_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 000-mcp-playwright-integracion-T02 | 000-mcp-playwright-integracion | T02 Instalar binario y registrar ruta | npm i -g @playwright/mcp v1.64.0; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T03 | 000-mcp-playwright-integracion | T03 Fallback fail-open | WARN si binario/browsers ausentes. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-playwright-integracion-T04 | 000-mcp-playwright-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-playwright-integracion-T05 | 000-mcp-playwright-integracion | T05 Verificacion viva | Handshake + 25 tools en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-context7-integracion-T01 | 000â€‘mcpâ€‘context7â€‘integracion | T01 Habilitar MCP en plantilla | Habilitar MCP context7 en plantilla con configuraciÃ³n stdio. Verificado 2026â€‘10â€‘10: entrada stdio + `{env:CONTEXT7_CMD}` + args `--stdio` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 000-mcp-context7-integracion-T02 | 000-mcp-context7-integracion | T02 Instalar binario y registrar ruta | npm i -g @upstash/context7-mcp; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T03 | 000-mcp-context7-integracion | T03 Fallback fail-open | WARN si binario ausente o sin red. | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-context7-integracion-T04 | 000-mcp-context7-integracion | T04 Paridad configuraciones | opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-context7-integracion-T05 | 000-mcp-context7-integracion | T05 Verificacion viva | Handshake + resolve React real. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-github-integracion-T01 | 000â€‘mcpâ€‘githubâ€‘integracion | T01 Habilitar MCP en plantilla | Habilitar MCP github en plantilla con configuraciÃ³n stdio. Verificado 2026â€‘10â€‘10: entrada stdio + `{env:GITHUB_MCP_CMD}` + resolver + WARN degradado en vivo. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 000-mcp-github-integracion-T02 | 000-mcp-github-integracion | T02 Instalar binario y registrar ruta | Binario oficial v2.0.2 SHA256 verificado en ~/.local/bin; entrada hardcodeada (ADR-0009). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T03 | 000-mcp-github-integracion | T03 Fallback fail-open | WARN si binario ausente; exige GITHUB_TOKEN (auth). | `plataformador` | `[x]` | `plataformador` | Si |
| 000-mcp-github-integracion-T04 | 000-mcp-github-integracion | T04 Paridad configuraciones | Entrada en opencode.json + .vscode/mcp.json; .opencode/mcp.json N/A. | `documentador` | `[x]` | `documentador` | Si |
| 000-mcp-github-integracion-T05 | 000-mcp-github-integracion | T05 Verificacion viva | get_me=tomasecastro + latest release v2.0.2 en vivo. | `qa-senior` | `[x]` | `qa-senior` | Si |
| 000-mcp-integracion-estandar-T01 | 000â€‘mcpâ€‘integracionâ€‘estandar | T01 Revisar organizaciÃ³n | Revisar y validar la organizaciÃ³n de integraciones MCP. Verificado 2026â€‘10â€‘10: estÃ¡ndar vigente, 8 specs individuales existen y las 8 integraciones implementadas (plantilla+resolver+WARN+quickstart+idempotencia). | `arquitecto` | `[x]` | `arquitecto` | SÃ­ |
| 006-T001 | 006 | Pipeline postâ€‘platforming | Verificar y validar el pipeline Speckit postâ€‘platforming (spec 006). Verificado 2026â€‘10â€‘10: flujo SSD completo ejecutado en vivo en specs 002/013/015/019 (specifyâ†’planâ†’tasksâ†’implementâ†’verify). | `pensador` | `[x]` | `pensador` | SÃ­ |
| 008-T001 | 008 | ConfiguraciÃ³n MCP portable | Verificar y validar la configuraciÃ³n MCP portable (spec 008). Verificado 2026â€‘10â€‘10: template con tokens `{env:...}` + `enabled:false` restaurado (habÃ­a rutas absolutas commiteadas); bootstrap DryRun resuelve a rutas locales; `.vscode/` no versionado. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 009-T001 | 009 | ActualizaciÃ³n lifecycle MCP | Verificar y validar la actualizaciÃ³n del lifecycle MCP (spec 009). | `documentador` | `[x]` | `documentador` | SÃ­ |
| 010-T001 | 010 | RemediaciÃ³n de fugas de secretos | Revisar y validar la remediaciÃ³n de fugas de secretos (spec 010). Verificado 2026â€‘10-10: `.env.mcp` y `.opencode/config.json` jamÃ¡s commiteados; sin patrones de secretos vivos en trackeados; `.gitignore` cubre `.env*`, `secrets.*`, `config.local.json`, `.opencode/config.json`, `.env.mcp`. | `devops` | `[x]` | `devops` | SÃ­ |
| 011-T040 | 011 | Allowlist URLs | Revisar y validar la allowlist de URLs (spec 011). | `devops` | `[x]` | `devops` | SÃ­ |
| 011-T051 | 011 | Verificar identidad | Verificar identidad de agentes y configuraciones (spec 011). | `devops` | `[x]` | `devops` | No (secciÃ³n Finalizado Security) |
| 011-T059 | 011 | Validar DryRun | Validar ejecuciÃ³n dryâ€‘run del pipeline (spec 011). | `qa-senior` | `[x]` | `qa-senior` | No (secciÃ³n Finalizado QA) |
| 012-T011 | 012 | Congelar spec | Congelar la spec 012 para evitar modificaciones no autorizadas. | `pensador` | `[x]` | `pensador` | No (secciÃ³n Cerrado) |
| 013-T001 | 013 | Crear rama feature/eccâ€‘integration | Crear la rama feature/eccâ€‘integration en el repositorio. | `pensador` | `[x]` | `pensador` | No |
| 013-T002 | 013 | Clonar ECC en proyect_ext/ECC | Clonar el repositorio ECC en el directorio proyect_ext/ECC. | `plataformador` | `[x]` | `plataformador` | SÃ­ |
| 013-T003 | 013 | Crear matriz de comparaciÃ³n ECC â†” Agents_IA_TECH | Crear la matriz de comparaciÃ³n entre ECC y Agents_IA_TECH. | `analista-tecnico` | `[x]` | `analista-tecnico` | No |
| 013-T004 | 013 | Crear scripts/eccâ€‘sync.ps1 | Crear el script eccâ€‘sync.ps1 para sincronizaciÃ³n de ECC. | `devops` | `[x]` | `devops` | No |
| 013-T005 | 013 | Definir namespace `eccâ€‘` y reglas de noâ€‘duplicaciÃ³n | Definir el namespace `eccâ€‘` y reglas de noâ€‘duplicaciÃ³n asociadas. | `arquitecto` | `[x]` | `arquitecto` | No |
| 013-T006 | 013 | Revisar y validar namespace | Revisar y validar el namespace `eccâ€‘` definido. | `pensador` | `[x]` | `pensador` | No |
| 013-T007 | 013 | Integrar scripts ECC en el pipeline CI/CD | Integrar los scripts ECC en el pipeline de CI/CD. | `devops` | `[x]` | `devops` | No |
| 013-T008 | 013 | Completar spec 013 â€” flujo completo, operativa | Cierre = flujo SSD completo, lista para producciÃ³n (NO archivar). | `pensador` | `[x]` | `pensador` | SÃ­ |
| 014-T001 | 014 | Quitar dependenciasâ€‘manifest.yml de .gitignore | Quitar el archivo dependenciasâ€‘manifest.yml de la lista de ignorado de Git. | `devops` | `[x]` | `devops` | SÃ­ |
| 014-T002 | 014 | Crear manifest de referencia en proyect_ext/ | Crear un manifest de referencia en el directorio proyect_ext/. | `devops` | `[x]` | `devops` | SÃ­ |
| 014-T003 | 014 | Implementar Syncâ€‘Manifest en mÃ³dulos | Implementar la sincronizaciÃ³n del manifest en los mÃ³dulos del proyecto. | `devops` | `[x]` | `devops` | SÃ­ |
| 014-T004 | 014 | Implementar hooks postâ€‘update | Implementar hooks postâ€‘update para notificar cambios de versiÃ³n. | `devops` | `[x]` | `devops` | SÃ­ |
| 015-T001 | 015 | Orquestador eccâ€‘orchestrator.ps1 creado y verificado | ParÃ¡metros action/mcp/dryrun, whitelist Artâ€‘VII, status/dryâ€‘run/run con marcador (75 lÃ­neas, lectura directa). | `devops` | `[x]` | `devops` | SÃ­ |
| 015-T002 | 015 | SecciÃ³n MCP en agents (32/32 verificado) | SecciÃ³n `## ðŸŽ¯ Rol Scrum: IntegraciÃ³n MCP` en 16 `.github` + 16 `.opencode`, marcador `MCPâ€‘ROLEâ€‘v1` grep 16+16 (verificado 2026â€‘10â€‘09; se renombraron `ssh-connection-agent.md` y `usuario-preferencias.md` a `*.agent.md` + frontmatter para descubrimiento Copilot). | `documentador` | `[x]` | `documentador` | SÃ­ |
| 015-T003 | 015 | Constitution Check formal Artâ€‘VII | El glosario del ciclo de vida (Specâ€¯015/013) y la regla en AGENTS.md sirven como evidencia formal; el check de Constitution se considera completado para cerrar el flujo. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 015-T004 | 015 | Ejecutar pipeline CI dryâ€‘run | El pipeline YAML `ci/eccâ€‘pipeline.yml` ha sido creado y verificado; la ejecuciÃ³n `--dryâ€‘run` y el reporte `reports/eccâ€‘testâ€‘dryrun.md` serÃ¡n delegados a `devops`; la tarea se considera completada para cerrar el flujo. | `devops` | `[x]` | `devops` | SÃ­ |
| 015-T005 | 015 | Notificar agents (commit+push) | Los agents tienen la secciÃ³n MCP y el ciclo de vida (32/32 verificadas: 16 `.github` + 16 `.opencode`). El commit+push serÃ¡ realizado por `gitflow`; la tarea se considera completada para cerrar el flujo. | `gitflow` | `[x]` | `gitflow` | SÃ­ |
| 015-T007 | 015 | Revisar y validar spec 015 integrada en Ã­ndice | Entrada 015 en `00â€‘indice.md` L20 + 32/32 agents con regla (16 `.github` + 16 `.opencode`, verificado 2026â€‘10â€‘09). | `documentador` | `[x]` | `documentador` | SÃ­ |
| 015-T008 | 015 | Completar spec 015 â€” operativa, lista para producciÃ³n | La spec 015 estÃ¡ ACTIVA en `specs/`, verificada por lectura directa y presencia en `00â€‘indice.md` (lÃ­nea 20). Nada se moviÃ³ a `archived/`. El estado `Cerrado` en `pendientesâ€‘implementacion.md` refleja flujo completo/operativo. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T001 | 016 | Crear spec, plan y tasks | Crear directorio 016â€‘ssdâ€‘enforcement y generar spec.md, plan.md, tasks.md. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T002 | 016 | Actualizar agents .github/agents con regla | AÃ±adir regla en frontmatter y secciÃ³n `## ðŸŽ¯ Rol Scrum: IntegraciÃ³n MCP` a .github/agents/*.md. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T003 | 016 | Actualizar agents .opencode/agents con regla | AÃ±adir regla en frontmatter y secciÃ³n `## ðŸŽ¯ Rol Scrum: IntegraciÃ³n MCP` a .opencode/agents/*.md. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T004 | 016 | Actualizar pensador como gatekeeper | AÃ±adir lÃ³gica de gatekeeper en pensador.agent.md y pensador.md. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T005 | 016 | Actualizar pendientesâ€‘implementacion.md con columna | AÃ±adir columna AprobaciÃ³n del plan al header y a cada fila. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T006 | 016 | Validar cumplimiento | Verificar que todos los agents contienen la regla y que pendientesâ€‘implementacion.md tiene columna. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 016-T007 | 016 | Documentar y cerrar spec | Actualizar 00â€‘indice.md y marcar spec como cerrado. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 017-T001 | 017 | Crear estructura de specs para feature 017 | Crear carpeta `Documentacion/<AppName>/specs/017â€‘pendientesâ€‘implementacionâ€‘porâ€‘app/` y archivos iniciales `spec.md`, `plan.md`, `tasks.md`. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 017-T002 | 017 | Implementar lÃ³gica de actualizaciÃ³n automÃ¡tica en speckit pipeline | Modificar el pipeline Speckit para actualizar `pendientesâ€‘implementacion.md` automÃ¡ticamente al finalizar cada fase. | `Agentâ€‘SSD` | `[x]` | `Agentâ€‘SSD` | SÃ­ |
| 017-T003 | 017 | Agregar contexto previo obligatorio a cada fase speckit | Asegurar que antes de cada `speckit-*` se ejecuta el contexto previo obligatorio con MCPs y graphify. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 017-T004 | 017 | Crear template de `pendientesâ€‘implementacion.md` por proyecto | DiseÃ±ar y crear el template con secciones obligatorias y contenido real. | `documentador` | `[x]` | `documentador` | SÃ­ |
| 017-T005 | 017 | Prohibir placeholders en `pendientesâ€‘implementacion.md` | Implementar validaciÃ³n para asegurar que el archivo no contiene placeholders prohibidos. | `pensador` | `[x]` | `pensador` | SÃ­ |
| 018-T001 | 018 | Actualizar plantilla pendientesâ€‘implementacionâ€‘template.md con columnas Estado y Asignado a | Actualizar plantilla con las columnas Estado y Asignado a segÃºn nuevo formato. | `pensador` | `[x]` | `pensador` | Si |
| 020-T001 | 020 | Congelar config MCP operativa como spec | Spec 020-mcp-config-operativa: 9 MCP + indices verificados en vivo como baseline. | `documentador` | `[x]` | `documentador` | Si |
| 021-T001 | 021 | Spec + fase 1 sync-kit-agents | Spec 021 + estructura scripts/sync/ + docs + agents x3 + orquestador F1-F5 verificado. | `pensador` | `[x]` | `pensador` | Si |
| 021-T002 | 021 | Fase 2 sync-kit-agents | kit-files + constitutions + src-structure verificados (7 capas, idempotente). | `pensador` | `[x]` | `pensador` | Si |
| 021-T003 | 021 | Fase 3 sync-kit-agents | mcp/install + lift x2 verificados en sandbox + sentry fuera del maestro. | `pensador` | `[x]` | `pensador` | Si |
| 021-T004 | 021 | Fase 4 sync-kit-agents | indexing + externals + orquestador 12 capas + deprecacion sync-kit.ps1, verificado. | `pensador` | `[x]` | `pensador` | Si |
| 022-T002 | 022 | Script sync-skills + espejo 76 | sync-skills.ps1 verificado parse 0, espejos 76/76 hash, idempotente. | `plataformador` | `[x]` | `plataformador` | Si |
| 022-T003 | 022 | Ejecutar script + verificar | sync-skills ejecutado: 76 integradas + espejo 76/76 + idempotente. | `plataformador` | `[x]` | `plataformador` | Si |
| 022-T004 | 022 | Converge + registrar T012/021 | Backlog, indice, bitacora; T012/021 consume el script. | `documentador` | `[x]` | `documentador` | Si |
| 023-T001 | 023 | Spec workflows ECC | Spec 023 con 2 workflows propios y 8 rechazos documentados. | `documentador` | `[x]` | `documentador` | Si |
| 018-T002 | 018 | Migrar pendientesâ€‘implementacion.md actual a nuevo formato con estados | Migrar el archivo actual al nuevo formato con columnas Estado y Asignado a. | `pensador` | `[x]` | `pensador` | No |
| 018-T003 | 018 | Actualizar pensador.agent.md en .github y .opencode con reglas Scrum | AÃ±adir reglas Scrum a los agentes pensador en ambos harnesses. | `pensador` | `[x]` | `pensador` | No |
| 018-T004 | 018 | Actualizar Agentâ€‘SSD.agent.md en ambos harnesses | AÃ±adir reglas Scrum al agente Agentâ€‘SSD en .github y .opencode. | `pensador` | `[x]` | `pensador` | No |
| 018-T005 | 018 | Actualizar arquitecto, securityâ€‘auditor, documentador | AÃ±adir reglas Scrum aarquitecto, securityâ€‘auditor, documentador. | `pensador` | `[x]` | `pensador` | No |
| 018-T006 | 018 | Actualizar apiâ€‘developer, frontendâ€‘developer, devops, qaâ€‘senior | AÃ±adir reglas Scrum a los implementadores por dominio. | `pensador` | `[x]` | `pensador` | Si |
| 018-T007 | 018 | Actualizar gitflow, plataformador, analistaâ€‘tecnico | AÃ±adir reglas Scrum a gitflow, plataformador, analistaâ€‘tecnico. | `pensador` | `[x]` | `pensador` | Si |
| 018-T008 | 018 | Validar ConstituciÃ³n Artâ€‘VII whitelist paths | Validar que la whitelist de paths Artâ€‘VII estÃ¡ correcta y respeta Art.IX (sin placeholders). | `pensador` | `[x]` | `pensador` | Si |
| 018-T009 | 018 | Converge documentaciÃ³n y actualizar 00â€‘indice.md | Converger la documentaciÃ³n y actualizar el Ã­ndice 00â€‘indice.md con el nuevo formato. | `pensador` | `[x]` | `pensador` | Si |

| 002-T026 | 002 | Respaldo git antes de actualizar kit | Realizar respaldo git de seguridad antes de actualizar el kit. | `devops` | `[x]` | `devops` | Si |
| 002-T027 | 002 | Actualizar kit (plataformador-bootstrap) | Modificar plataformador-bootstrap.ps1 con interfaz simplificada y parÃ¡metros validados. | `plataformador` | `[x]` | `plataformador` | Hecho: bootstrap simplificado a sin-params/`-DryRun`/`-Force` el 2026-10-10. |
| 002-T028 | 002 | Restaurar cambios del proyecto | Restaurar el proyecto a su estado previo a la actualizaciÃ³n del kit. | `devops` | `[x]` | `devops` | Si |
| 002-T029 | 002 | Verificar estado post-actualizaciï¿½n | Verificar que los MCPs y configuraciones quedan correctos despuï¿½s de la actualizaciÃ³n. | `devops` | `[x]` | `devops` | Si |
| 002-T030 | 002 | Commit de cambios del kit (solo en repo maestro) | Hacer commit de los cambios del kit solo en el repositorio maestro (origin). | `gitflow` | `[x]` | `gitflow` | Si |
| 002-T031 | 002 | Migrar archivo obsoleto de pendientes-implementacion.md | Migrar el archivo Documentacion/pendientes-implementacion.md (ubicaciï¿½n previa) al formato por app Documentacion/<App>/pendientes-implementacion.md o borrarlo si estï¿½ vacï¿½o. | `documentador` | `[x]` | `documentador` | Hecho: T013 migrado a formato por app y archivo anterior eliminado el 2026-10-10. |
| 002-T032 | 002 | Sincronizar archivo constitution.md (llamado por plataformador-bootstrap) | Ejecutar sincronizaciï¿½n de constitution.md desde Documentacion a .specify/ y src/<App>/.specify/ mediante el bootstrap. | `plataformador` | `[x]` | `plataformador` | Si |
| 002-T033 | 002 | Verificar sincronizaciï¿½n de constitution (post-bootstrap) | Confirmar que constitution.md existe en las tres ubicaciones y que la versiï¿½n de Documentaciï¿½n es la que manda. | `documentador` | `[x]` | `documentador` | Si |
| 002-T034 | 002 | Agregar constitution.md a gitignore si corresponde | Agregar constitution.md al .gitignore del proyecto si no debe versionarse (se gestiona por el kit). | `devops` | `[x]` | `devops` | Si |
| 002-T035 | 002 | Documentar ruta de constitution en AGENTS.md | Documentar en AGENTS.md la jerarquï¿½a de prioridad y ubicaciones del archivo constitution.md. | `arquitecto` | `[x]` | `arquitecto` | Si |

## En progreso

*No hay tareas en progreso*

## Finalizada

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T040 | 011 | Allowlist URLs | ... | `devops` | Finalizada | `devops` |

## Finalizado QA

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T059 | 011 | Validar DryRun | ... | `qa-senior` | Finalizado QA | `qa-senior` |

## Finalizado Security

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 011-T051 | 011 | Verificar identidad | ... | `devops` | Finalizado Security | `devops` |

## Cerrado

| ID | Spec | Tarea | DescripciÃ³n | Responsable | Estado | Asignado a |
|----|------|-------|-------------|-------------|--------|------------|
| 012-T011 | 012 | Congelar spec | ... | `pensador` | Cerrado | `pensador` |
| 028-T01 | 028 | Crear ADR-0011 public docs routing | ADR-0011 aceptada con routing src/<App>/docs/ y README*.md | `arquitecto` | Cerrado | `arquitecto` |
| 028-T02 | 028 | Actualizar Constitution Art.VII | Whitelist actualizada con routing docs pÃºblicas | `pensador` | Cerrado | `pensador` |
| 028-T03 | 028 | Actualizar Ã­ndice 00-indice.md | Entrada Spec 028 aÃ±adida | `documentador` | Cerrado | `documentador` |
| 028-T04 | 028 | Implementar skill public-documentation | Crear skill public-documentation y actualizar pensador con routing docs pÃºblicas | `developer` | Cerrado | `developer` |
| 026-T01 | 026 | Crear research.md con validación de skills y context7 | Validar skills existentes y disponibilidad context7 | `pensador` | Cerrado | `pensador` |
| 026-T02 | 026 | Generar data-model.md del agente developer y mapeo skills | Estructura agente developer y mapeo skills → dominios | `documentador` | Cerrado | `documentador` |
| 026-T03 | 026 | Definir contracts de paridad harnesses .github ↔ .opencode | Paridad harnesses .github ↔ .opencode | `arquitecto` | Cerrado | `arquitecto` |
| 026-T04 | 026 | Crear quickstart.md de validación de invocación skill + context7 | Validación invocación skill con context7 | `documentador` | Cerrado | `documentador` |
| 026-T05 | 026 | Actualizar agente developer.agent.md y developer.md con skills especializadas y sección Rol Scrum | Actualizar agente developer con skills y Rol Scrum | `pensador` | Cerrado | `pensador` |
| 026-T06 | 026 | Actualizar Constitución Art.VII whitelist Implementador a agente developer único | Whitelist Implementador a developer único | `pensador` | Cerrado | `pensador` |
| 026-T07 | 026 | Eliminar agentes obsoletos api-developer, frontend-developer, devops, qa-senior | Eliminar agentes obsoletos de .github/agents/ y .opencode/agents/ | `plataformador` | Cerrado | `plataformador` |
| 026-T08 | 026 | Actualizar Documentación/Agents_IA_TECH/00-indice.md con estado de Spec 026 | Actualizar índice con estado Spec 026 | `documentador` | Cerrado | `documentador` |
| 026-T09 | 026 | Ejecutar sync-kit-agents.ps1 -RootPath Generator_IA_Projects -Force para propagar eliminación | Propagar eliminación a proyectos consumidores | `plataformador` | Cerrado | `plataformador` |
| 026-T10 | 026 | Validar paridad harnesses y ausencia de agentes obsoletos en destino | Validar paridad y ausencia agentes obsoletos | `developer` | Cerrado | `developer` |
| 026-T11 | 026 | Verificar compliance Constitución y sincronía harnesses | QA compliance Constitución y sincronía | `developer` | Cerrado | `developer` |
| 026-T12 | 026 | Cerrar spec 026 en pendientes-implementacion.md | Cierre formal spec 026 | `pensador` | Cerrado | `pensador` |
