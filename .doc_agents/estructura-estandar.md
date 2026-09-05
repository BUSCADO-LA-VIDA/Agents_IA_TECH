# 📐 Estructura Estándar de `Documentacion/<AppName>/` (por Aplicación)

> **Fuente de verdad** sobre cómo debe organizarse la documentación de CADA aplicación.  
> Este archivo es **transversal** — viaja con los agentes a todos los proyectos (carpeta `.doc_agents/`).  
> El `plataformador` lo usa para auditar cada app y, si encuentra una estructura distinta, pregunta si reorganizar.  
> Los agentes documentales la usan para saber dónde crear cada archivo dentro de `Documentacion/<AppName>/`.

> **⚠️ NOTA IMPORTANTE**: Este archivo reemplaza la versión anterior que usaba terminología "arne" y "harness".  
> La terminología correcta es: **App / Aplicación** (no "arne"), **Kit de Agentes Transversal** (no "harness").

## Regla general

**Cada agente tiene su propia carpeta** dentro de `agents/`. Todo lo que sea específico de un agente va dentro de su carpeta.

**Skills globales ⭐**: Los skills en `.github/skills/` son **compartidos globalmente** (77 skills) — no se duplican por app.  
Cada app usa los mismos skills globales; la configuración específica de la app va en `Documentacion/<AppName>/`.

## Árbol completo por aplicación

```text
<AppName>/                          ← Raíz de la aplicación (ej. App-Frontend, App-Backend)
│
├── Documentacion/
│   └── <AppName>/                  ← 📁 Carpeta PROPIA de esta app (NUNCA se copia entre apps)
│       ├── 00-indice.md            ← OBLIGATORIO - Índice general de ESTA app
│       ├── idioma.md               ← OBLIGATORIO - Config de idioma de ESTA app
│       ├── preferencias.md         ← OBLIGATORIO - Preferencias usuario para ESTA app
│       ├── preferencias-git.md     ← RECOMENDADO - Flujo git de ESTA app
│       ├── referencias.md          ← RECOMENDADO - Fuentes externas de ESTA app
│       ├── roadmap.md              ← RECOMENDADO - Backlog evolutivos de ESTA app
│       ├── pendientes-implementacion.md ← OBLIGATORIO - Puente docs ↔ código de ESTA app
│       ├── soluciones-conocidas.md ← OBLIGATORIO - Soluciones de ESTA app
│       ├── capacidad-base.md       ← OBLIGATORIO - Ref. a `.doc_agents/capacidad-base.md`
│       ├── memoria-proyecto.md     ← OBLIGATORIO - Capacidades instaladas en ESTA app
│       │
│       ├── specs/                  ← OBLIGATORIO* - speckit ESCRIBE AQUÍ (spec/plan/tasks)
│       │   ├── 001-feature-name/
│       │   │   ├── spec.md
│       │   │   ├── plan.md
│       │   │   ├── tasks.md
│       │   │   └── ...
│       │   └── ...
│       │
│       ├── arquitectura/           ← Decisiones de arquitectura de ESTA app
│       │   ├── adr/                ←   ADRs
│       │   └── diagramas/          ←   Diagramas Mermaid
│       │
│       ├── agents/                 ← Documentación de agentes para ESTA app
│       │   └── <nombre-agente>/
│       │       ├── spec.md         ← OBLIGATORIO si el agente existe
│       │       └── ... (archivos propios del agente)
│       │
│       ├── bitacoras/              ← RECOMENDADO - Bitácoras solucionador
│       │
│       ├── testing/                ← OPCIONAL - solo si hay tests documentados
│       ├── seguridad/              ← OPCIONAL - solo si hay auditorías
│       └── despliegue/             ← OPCIONAL - solo si hay docs de despliegue
│
├── src/                            ← Código fuente de la app
├── tests/                          ← Tests de la app
├── .github/                        ← Kit transversal (COPIADO)
├── .opencode/                      ← Kit transversal (COPIADO)
├── .doc_agents/                    ← Kit transversal (COPIADO)
└── .specify/                       ← Config speckit (constitución base + personalizable)
```

## Reglas

1. **Cada característica en su carpeta de agente** — si un archivo solo lo usa un agente, va dentro de `agents/<agente>/`
2. **Nada suelto en la raíz de `Documentacion/<AppName>/`** — los únicos archivos permitidos son los 10 listados arriba (00-indice.md, idioma.md, preferencias.md, preferencias-git.md, referencias.md, roadmap.md, pendientes-implementacion.md, soluciones-conocidas.md, capacidad-base.md, memoria-proyecto.md)
3. **El `00-indice.md` refleja la estructura real** — si se mueve un archivo, se actualiza el índice
4. **`spec.md` siempre en `agents/<agente>/spec.md`** — nunca en la raíz ni en `specs/`
5. **`adr/` va dentro de `arquitectura/adr/`** — nunca en la raíz de la app
6. **`agents/` se nombra en inglés** — nunca `agentes/`
7. **`testing/`, `seguridad/`, `despliegue/` son opcionales** — solo se crean si hay contenido. No se crean automáticamente vacías.
8. **`specs/` es obligatoria si se usa speckit** — speckit escribe spec/plan/tasks aquí
9. **Si una app tiene estructura distinta** → el `plataformador` lo detecta y pregunta
10. **Si hay dudas sobre dónde va algo** → preguntar al usuario, nunca asumir
11. **`Documentacion/<AppName>/` es PROPIA de la app** — NUNCA se copia, sobrescribe ni sincroniza entre apps. El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`) SÍ se sincroniza con `sync-agents.ps1`.

## Qué se copia vs qué es propio de la app

| Elemento | Se copia entre proyectos/apps | Es propio de la app |
|----------|:----------------------------:|:-------------------:|
| `.github/` | ✅ Sí | ❌ No |
| `.opencode/` | ✅ Sí | ❌ No |
| `.doc_agents/` | ✅ Sí | ❌ No |
| `.specify/memory/constitution.md` | ✅ Sí (base) | ⚠️ Personalizable |
| `Documentacion/<AppName>/` | ❌ **NUNCA** | ✅ **Siempre** |
| `src/`, `tests/` | ❌ No | ✅ Sí |

## Historial

| Fecha | Cambio |
|-------|--------|
| 2026-07-25 | Creación del estándar en `.doc_agents/` (versión legacy con terminología "arne") |
| 2026-07-27 | `adr/` movido a `arquitectura/adr/`. Agregadas `arquitectura/`, `funcionalidades/`. |
| 2026-08-30 | **Reestructuración completa**: Terminología "App/Aplicación", separación kit transversal vs doc por app, `specs/` para speckit, referencia a `.doc_agents/`. |

## Reglas

1. **Cada característica en su carpeta de agente** — si un archivo solo lo usa un agente, va dentro de `agents/<agente>/`
2. **Nada suelto en la raíz de la aplicación** — los únicos archivos permitidos dentro de `Documentacion/<aplicacion>/` son los 8 listados arriba
3. **El `00-indice.md` refleja la estructura real** — si se mueve un archivo, se actualiza el índice
4. **`spec.md` siempre en `agents/<agente>/spec.md`** — nunca en la raíz ni en `specs/`
5. **`adr/` va dentro de `arquitectura/adr/`** — nunca en la raíz de la aplicación
6. **`agents/` se nombra en inglés** — nunca `agentes/`
7. **`testing/`, `seguridad/`, `despliegue/` son opcionales** — solo se crean si hay contenido que colocar en ellas. No se crean automáticamente vacías.
8. **Si un proyecto tiene estructura distinta** → el `plataformador` lo detecta y pregunta
9. **Si hay dudas sobre dónde va algo** → preguntar al usuario, nunca asumir

## ¿Se copia entre proyectos?

| Carpeta/Archivo | ¿Se copia? | Descripción |
|-----------------|:----------:|-------------|
| `.github/` | ✅ Sí | Agentes y configuración GitHub Copilot — se copia a cada proyecto hijo |
| `.opencode/` | ✅ Sí | Agentes y configuración OpenCode — se copia a cada proyecto hijo |
| `.doc_agents/` | ✅ Sí | Documentación transversal del kit de agentes — se copia a cada proyecto hijo |
| `Documentacion/` | ❌ No | Es propia de cada proyecto y cada aplicación dentro de él |
| `proyectos/` | ❌ No | Cada proyecto hijo tiene la suya |

## Historial

| Fecha | Cambio |
|-------|--------|
| 2026-07-25 | Creación del estándar en `.doc_agents/` |
| 2026-07-27 | `adr/` movido a `arquitectura/adr/`. Agregadas `arquitectura/`, `funcionalidades/`. `testing/`, `seguridad/`, `despliegue/` pasan a opcionales. Reglas 5-9 nuevas. |
