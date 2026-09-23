# ADR-0005: Agente `Agent-SSD` — orquestador del flujo SSD y ejecutor de comandos Speckit

> **Estado**: Aceptado
> **Fecha**: 2026-09-21
> **Decide**: Creación del agente `Agent-SSD` (tier Documental extendido)
> **Relacionado**: ADR-0004 (post-plataformado → speckit), spec 006, reglas-transversales-agentes.md (Regla 4)

---

## 1. Contexto

Al intentar crear constituciones para apps (`src/<App>/.specify/`), el flujo se bloqueó por la restricción de permisos de los agentes documentales:

- Los agentes documentales (`pensador`, `arquitecto`, `documentador`, `security-auditor`) solo pueden escribir en `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md` — **PROHIBIDO `src/`** (incluye `src/<App>/.specify/`).
- El flujo speckit (speckit-constitution, speckit-specify, etc.) escribe en `src/<App>/.specify/` cuando la app vive ahí.
- El `pensador` intentaba ejecutar speckit directamente y se bloqueaba.

**Diagnóstico del usuario (correcto)**:
1. "Implementador es un flujo, no un agente" — el flujo SSD+Speckit no tiene un agente ejecutor propio.
2. Los proyectos son vivos — la constitución se crea Y se actualiza en cualquier momento del ciclo, no solo al inicio.
3. No solo constitution: **cualquier documento de speckit** (constitution, spec, plan, tasks, analyze, converge).

## 2. Decisión

Crear el agente **`Agent-SSD`** — orquestador del flujo SSD con capacidad de documentar y ejecutar Speckit:

| Aspecto | Detalle |
|---------|---------|
| **Nombre** | `Agent-SSD` |
| **Rol** | Orquestador del flujo SSD + ejecutor de comandos Speckit + documentador de artefactos speckit |
| **Modelo mental** | Como `implementador` mantiene el flujo de implementación, `Agent-SSD` mantiene el flujo SSD — si Speckit ejecuta comandos, él los ejecuta (no solapa funcionalidades) |
| **Tier** | Documental **extendido**: escribe en `src/<App>/.specify/` (SOLO esa subcarpeta) + `Documentacion/<AppName>/specs/` + `.github/`, `.opencode/`, `.doc_agents/`, `README.md` |
| **PROHIBIDO** | Código fuente (`src/<App>/` excepto `.specify/`), `tests/`, `Documentacion/<OtraApp>/`, docstrings inline |
| **Skills** | Las 6 speckit: `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-converge`, `speckit-constitution` (+ wizard interactivo) |

### Alternativas evaluadas

| Opción | Descripción | Veredicto |
|--------|-------------|-----------|
| A — Ajustar restricción | Abrir `src/<App>/.specify/` a los 4 documentales | ❌ Debilita gobernanza: cualquiera escribiría constituciones "por fuera" del ciclo |
| B — Nuevo agente | Agente ejecutor dedicado al flujo SSD+Speckit | ✅ Elegida (propuesta del usuario) |
| C — Híbrido | Nuevo agente + documentales intactos | ✅ Es la B con gobernanza preservada — **implementada** |

## 3. Consecuencias

### Positivas
- El bloqueo de permisos se resuelve: `Agent-SSD` SÍ puede escribir en `src/<App>/.specify/`.
- La gobernanza se mantiene: los documentales existentes siguen sin poder tocar `src/`.
- La separación de fases se preserva: orquestador (`pensador`) delega, ejecutor (`Agent-SSD`) ejecuta.
- Los proyectos vivos funcionan: `Agent-SSD` crea/actualiza cualquier documento speckit en cualquier momento del ciclo.
- No solapamiento: si Speckit ejecuta comandos, `Agent-SSD` los ejecuta — sin duplicar funcionalidades.

### Ciclo de retroalimentación Pensador ↔ Agent-SSD (obligatorio)
1. `pensador` delega en `Agent-SSD` (ej: "ejecuta speckit-specify para <app>")
2. `Agent-SSD` ejecuta y documenta
3. `Agent-SSD` **reporta al `pensador`**: artefactos generados + ubicación + siguiente fase
4. `pensador` valida y **continúa el flujo cuando corresponde**: pregunta al usuario la validación de la fase antes de delegar la siguiente
5. `Agent-SSD` **NUNCA auto-continúa** a la siguiente fase
6. En cualquier momento del ciclo, `pensador` puede delegar en `Agent-SSD` crear/actualizar CUALQUIER documento speckit

### Matriz de no solapamiento

| Tarea | Pensador | Agent-SSD | Implementadores |
|-------|:---:|:---:|:---:|
| Constitution Check + orquestar ciclo | ✅ | ❌ | ❌ |
| Ejecutar speckit-specify/plan/tasks/analyze/converge | ❌ delega | ✅ ejecuta | ❌ |
| Crear/actualizar constitution (proyectos vivos) | ❌ delega | ✅ ejecuta | ❌ |
| Escribir en `src/<App>/.specify/` | ❌ | ✅ | ❌ |
| Escribir en `Documentacion/<AppName>/specs/` | ✅ | ✅ | ❌ |
| Implementar código (`speckit-implement`) | ❌ | ❌ | ✅ |

### Excepción kit
En el proyecto kit (sin `src/`), el `pensador` puede ejecutar speckit directamente (los artefactos van a `Documentacion/<AppName>/specs/`, que sí puede escribir).

### Neutras
- 14 agentes en total (13 → 14). Duplicado en ambos harnesses (Regla 3).
- `AGENTS.md` actualizado: 5 tiers (antes 4), nuevo tier "Documental extendido".

## 4. Archivos tocados

| Archivo | Cambio |
|---------|--------|
| `.github/agents/Agent-SSD.agent.md` | **Nuevo** — definición Copilot |
| `.opencode/agents/Agent-SSD.md` | **Nuevo** — definición OpenCode |
| `.github/agents/pensador.agent.md` | Delegación al Agent-SSD (matriz + ciclo de retroalimentación) |
| `.opencode/agents/pensador.md` | Delegación al Agent-SSD (matriz + ciclo de retroalimentación) |
| `AGENTS.md` | Tabla de tiers: 14 agentes, 5 tiers |
| `Documentacion/Agents_IA_TECH/reglas-transversales-agentes.md` | Regla 4: Agent-SSD |
| `.doc_agents/estructura-aplicacion.md` | `.specify/` en `src/<App>/.specify/` (corrección) + sección Agent-SSD |

## 5. Referencias

- ADR-0004: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0004-post-plataformado-speckit.md`
- Spec 006: `Documentacion/Agents_IA_TECH/specs/006-post-platforming-speckit/spec.md`
- Reglas transversales: `Documentacion/Agents_IA_TECH/reglas-transversales-agentes.md` (Regla 4)
- Estructura por app: `.doc_agents/estructura-aplicacion.md`
