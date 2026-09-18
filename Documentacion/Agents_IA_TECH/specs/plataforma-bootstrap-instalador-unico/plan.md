# Plan de Implementación: `plataformador-bootstrap.ps1` — Instalador/Actualizador Único

> **Estado**: En planificación
> **Fecha**: 2026-09-17
> **Fuente**: `spec.md` (esta carpeta) + ADR-0003
> **Autor**: `documentador` (fase documental — paso 2º)

---

## Resumen

Plan por fases para implementar el ADR-0003 y la spec de `plataformador-bootstrap.ps1` como instalador/actualizador único del ecosistema. Se sigue el orden sagrado **Plan → Document → Implement** (regla de oro del kit).

---

## Fase 1 — Documental

> El `arquitecto` completó su paso (ADR-0003). El `documentador` (este documento) completa el rol del bootstrap + fusión de `sync-agents.ps1`.

| Orden | Agente | Acción | Estado |
|-------|--------|--------|--------|
| 1º | `arquitecto` | ✅ Crear ADR-0003 (modelo apps + orquestador, resolución app activa, fusión `Sync-TransversalKit`, guardrails, spec linking, diagrama, plan). | ✅ **COMPLETADO (2026-09-17)** |
| 2º | `documentador` | Documentar rol del bootstrap como instalador/actualizador único + spec/plan/tasks + fusión `sync-agents.ps1` (Opción A). Actualizar `00-indice.md`, `referencias.md`, `pendientes-implementacion.md`. | ✅ **COMPLETADO (2026-09-17)** |
| 3º | `security-auditor` | Revisar implicaciones de seguridad (descarga desde git, validación de URLs/licencias, no exponer credenciales). | ⏳ Pendiente |

**Criterio de salida de la fase**: security-auditor completa la revisión y deja registradas sus recomendaciones en `Documentacion/Agents_IA_TECH/seguridad/`.

---

## Fase 2 — Implementación

| Orden | Agente | Acción | Estado |
|-------|--------|--------|--------|
| 4º | `plataformador` | Refactorizar `plataformador-bootstrap.ps1`: agregar `Sync-TransversalKit`, resolución de app activa (`-App` + `cwd`), integración de Spec-kit y Graphify, respetando los guardrails del ADR-0003. | ⏳ Pendiente |
| 5º | `devops` | Convertir `sync-agents.ps1` en wrapper que delega en `Sync-TransversalKit`. | ⏳ Pendiente |
| 6º | `qa-senior` | Probar idempotencia, `-DryRun`, resolución de app activa y no-tocar-`Documentacion/<AppName>/` en un proyecto real (p. ej. `C:\Proyectos\Metatrader`). | ⏳ Pendiente |
| 7º | `gitflow` | Commits convencionales (`feat`, `refactor`, `docs`, `chore`). | ⏳ Pendiente |

**Criterio de salida de la fase**: bootstrap implementado, `sync-agents.ps1` delegando, y tests de `qa-senior` pasando.

---

## Fase 3 — Validación del flujo

| Orden | Acción |
|-------|--------|
| 8º | Ejecutar `.\plataformador-bootstrap.ps1 -DryRun` en `C:\Proyectos\Agents_IA_TECH` y `C:\Proyectos\Metatrader`; verificar que no toca `Documentacion/<AppName>/`. |
| 9º | Ejecutar sin `-DryRun`; verificar Spec-kit orientado a la app activa y Graphify configurado. |
| 10º | Correr `npx ecc-agentshield scan` para validar seguridad de los cambios en `.github/`. |
| 11º | Validar que al cargar VS Code los agentes, MCPs y Spec-kit funcionan sin re-ejecutar scripts (hooks SessionStart, plugin context-mode). |

**Criterio de salida de la fase**: flujo validado end-to-end y sin re-ejecutar scripts.

---

## Dependencias

- `dependencias-manifest.yml` — ya existe con el patrón "descargar desde git".
- `.doc_agents/estructura-aplicacion.md` — define la estructura por app.
- Repo maestro `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| El script crece mucho (854 + sync + resolución + Spec-kit + Graphify) | Funciones modulares + `-DryRun`. |
| Romper estructura existente al nivelar apps | Guardrails del ADR-0003 (respetar ubicación, nunca destruir código). |
| Tocar `Documentacion/<AppName>/` por error de rutas | Guardrail RF-02/RNF-05: validación explícita de la frontera. |
| URL del repo maestro inaccesible | Validar URL antes del clone. |