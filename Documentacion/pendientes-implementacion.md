# Pendientes de implementación

> Este archivo es el puente entre documentación y ejecución.

## Preparación del proyecto
- [ ] Verificar estructura del repositorio
- [ ] Configurar herramientas externas y MCPs (VS Code + OpenCode)
- [ ] Indexar código con codebase-memory-mcp
- [ ] Indexar documentación con context-mode
- [ ] Verificar que índices y MCPs funcionan
- [ ] Revisar si hay que reorganizar carpetas o nombres

## T-I2: Arquitecto - speckit-analyze + ADR Management + Guardrails + Spec Linking
- [x] Agregar skill `speckit-analyze` a arquitecto (ambos harnesses)
- [x] Sección "ADR Management": creación/actualización ADRs en `Documentacion/<app>/specs/adr/`
- [x] Sección "Guardrails": patrones, límites, dependencias permitidas
- [x] Sección "Spec Linking": traceabilidad bidireccional spec.md↔plan.md↔tasks.md↔ADRs
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I3: Documentador - speckit-converge + Flujos/Templates + Versionado + 00-indice.md
- [x] Agregar skill `speckit-converge` a documentador (ambos harnesses)
- [x] Sección "Flujos y Templates": generación/actualización en `Documentacion/<app>/specs/`
- [x] Sección "Versionado": semver en cabecera de cada artefacto
- [x] Sección "00-indice.md": actualización automática en converge
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I4: Security-Auditor - speckit-analyze + Threat Model + Security-Risk Tags + Art.V Validation
- [x] Agregar skill `speckit-analyze` a security-auditor (ambos harnesses)
- [x] Sección "Threat Model": STRIDE por feature en fase analyze
- [x] Sección "Security-Risk Tags": etiquetado `security-risk:` en tasks.md
- [x] Sección "Art.V Validation": checklist Constitution Art.V
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I5: API Developer - speckit-implement + Expertise + Trigger
- [x] Agregar skill `speckit-implement` a api-developer (ambos harnesses)
- [x] Sección "Expertise": backend, APIs, DB, auth, migraciones, caching, colas, testing, observabilidad
- [x] Sección "Trigger": `domain: backend` / `domain: api`
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I6: Frontend Developer - speckit-implement + Expertise + Trigger
- [x] Agregar skill `speckit-implement` a frontend-developer (ambos harnesses)
- [x] Sección "Expertise": UI, state management, componentes, accesibilidad WCAG, performance, testing
- [x] Sección "Trigger": `domain: frontend` / `domain: ui`
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I7: DevOps (implementador) - speckit-implement + Expertise + Trigger
- [x] Agregar skill `speckit-implement` a devops (ambos harnesses)
- [x] Sección "Expertise": CI/CD, infraestructura, contenedores, observabilidad, GitOps, seguridad, networking
- [x] Sección "Trigger": `domain: devops` / `domain: infra`
- [x] Frontmatter: version 2.0 + skills actualizadas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I9: Gitflow - speckit-implement + speckit-converge + Trigger
- [x] Agregar skills `speckit-implement` + `speckit-converge` a gitflow (ambos harnesses)
- [x] Sección "Triggers": speckit-implement → branch feature/<task-id>, PR; speckit-converge → merge, tag semver, changelog
- [x] Frontmatter: version 2.0 + skills declaradas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I10: Plataformador - speckit-analyze + Trigger
- [x] Agregar skill `speckit-analyze` a plataformador (ambos harnesses)
- [x] Sección "Triggers": nivelación (sync-agents, constitution drift) + diagnóstico remoto (health checks, codebase-memory)
- [x] Frontmatter: version 2.0 + skills declaradas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I11: Upgrade-Framework - speckit-plan + speckit-implement + Trigger
- [x] Agregar skills `speckit-plan` + `speckit-implement` a upgrade-framework (ambos harnesses)
- [x] Sección "Triggers": speckit-plan → detect versión obsoleta, plan migración tasks.md `domain: upgrade`; speckit-implement → ejecutar migración
- [x] Frontmatter: version 2.0 + skills declaradas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I12: Analista-Tecnico - speckit-specify + speckit-analyze + Trigger
- [x] Agregar skills `speckit-specify` + `speckit-analyze` a analista-tecnico (ambos harnesses)
- [x] Sección "Triggers": speckit-specify → investigación técnica previa; speckit-analyze → POCs, evaluación librerías
- [x] Frontmatter: version 2.0 + skills declaradas
- [x] Sync OK (diff solo frontmatter harness-specific)

## T-I13: Solucionador - speckit-analyze + speckit-implement + Trigger
- [x] Agregar skills `speckit-analyze` + `speckit-implement` a solucionador (ambos harnesses)
- [x] Sección "Triggers": speckit-analyze → RCA incidentes producción; speckit-implement → hotfixes fast-track
- [x] Frontmatter: version 2.0 + skills declaradas
- [x] Sync OK (diff solo frontmatter harness-specific)
