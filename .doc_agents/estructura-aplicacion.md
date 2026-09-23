# 📐 Estructura de Documentación por Aplicación

> **Regla de oro**: Cada aplicación tiene su propia carpeta de documentación aislada.  
> El kit de agentes (`.github/`, `.opencode/`, `.doc_agents/`) es **transversal y se copia**.  
> `Documentacion/<AppName>/` es **propia de la app** y **NO se copia** entre proyectos.

---

## 🎯 Estructura estándar por aplicación

> ⚠️ **Son DOS carpetas distintas por app**:
> - **`Documentacion_Publica/`** (dentro de cada app) → información **pública**: cómo instalar, capacidades de la herramienta, documentación propia del proyecto Git descargado. Es lo que se publica.
> - **`Documentacion/`** (en la raíz del repo, con subcarpeta por app) → documentación **interna/técnica**: specs, tareas, ADRs, corrección de errores, el día a día del desarrollo. **NO se publica** en repositorios públicos.

```
mi-repo/
├── .github/                 ← Kit transversal (copiado)
├── .opencode/               ← Kit transversal (copiado)
├── .doc_agents/             ← Kit transversal (copiado)
├── <AppName>/.specify/      ← Config speckit de la app (constitution, specs) — [AGENT-SSD] ADR-0005
│
├── <AppName>/               ← Raíz de la aplicación (ej. App-Frontend, App-Backend, Mobile-App)
│   ├── Documentacion_Publica/        ← 📢 PÚBLICA (se publica)
│   │   ├── README.md                 ← Cómo instalar, usar, capacidades
│   │   ├── instalacion.md            ← Guía de instalación
│   │   └── ...                       ← Doc propia del proyecto Git descargado
│   ├── src/                 ← Código fuente de la app
│   ├── tests/               ← Tests de la app
│   └── ...
│
├── Documentacion/           ← 🔒 INTERNA (NO se publica)
│   └── <AppName>/           ← Carpeta de documentación técnica PROPIA de esta app
│       ├── 00-indice.md      ← Índice general de ESTA app
│       ├── idioma.md         ← Configuración de idioma de ESTA app
│       ├── preferencias.md   ← Preferencias del usuario para ESTA app
│       ├── roadmap.md        ← Backlog de evolutivos de ESTA app
│       ├── pendientes-implementacion.md ← Puente docs ↔ código de ESTA app
│       ├── capacidad-base.md ← Capacidad base heredada del kit (referencia)
│       ├── memoria-proyecto.md ← Capacidades instaladas en ESTA app
│       │
│       ├── specs/            ← 📋 speckit ESCRIBE AQUÍ (spec/plan/tasks)
│       │   ├── 001-feature-name/
│       │   │   ├── spec.md
│       │   │   ├── plan.md
│       │   │   ├── tasks.md
│       │   │   └── ...
│       │   └── ...
│       │
│       ├── arquitectura/     ← 📐 Decisiones de arquitectura de ESTA app
│       │   ├── adr/          ← ADRs (Architecture Decision Records)
│       │   └── diagramas/    ← Diagramas Mermaid
│       │
│       ├── agents/           ← 🤖 Configuración de agentes para ESTA app
│       │   ├── pensador/
│       │   │   └── spec.md
│       │   ├── arquitecto/
│       │   │   └── spec.md
│       │   ├── documentador/
│       │   │   └── spec.md
│       │   ├── security-auditor/
│       │   │   └── spec.md
│       │   ├── api-developer/
│       │   │   └── spec.md
│       │   ├── frontend-developer/
│       │   │   └── spec.md
│       │   ├── devops/
│       │   │   └── spec.md
│       │   ├── qa-senior/
│       │   │   └── spec.md
│       │   ├── gitflow/
│       │   │   └── spec.md
│       │   ├── solucionador/
│       │   │   └── spec.md
│       │   └── plataformador/
│       │       ├── spec.md
│       │       ├── capacidad-base.md
│       │       └── memoria-proyecto.md
│       │
│       ├── bitacoras/        ← 📝 Bitácoras de intervenciones (solucionador)
│       │
│       ├── testing/          ← 🧪 Opcional — solo si hay tests documentados
│       ├── seguridad/        ← 🔒 Opcional — solo si hay auditorías
│       └── despliegue/       ← 🚀 Opcional — solo si hay docs de despliegue
```

---

## 🔄 Qué se copia vs qué es propio

| Elemento | Se copia entre proyectos | Es propio de la app |
|----------|:------------------------:|:-------------------:|
| `.github/` | ✅ Sí | ❌ No |
| `.opencode/` | ✅ Sí | ❌ No |
| `.doc_agents/` | ✅ Sí | ❌ No |
| <AppName>/.specify/ (constitution, specs de la app) | ✅ Sí (base) | ⚠️ Personalizable — la escribe Agent-SSD (ADR-0005) |
| `Documentacion_Publica/` (dentro de la app) | ❌ **NUNCA** | ✅ **Siempre** |
| `Documentacion/<AppName>/` (raíz del repo) | ❌ **NUNCA** | ✅ **Siempre** |
| `src/`, `tests/` | ❌ No | ✅ Sí |

---

## 🤖 Comportamiento de los agentes

### Agentes documentales (`pensador`, `arquitecto`, `documentador`, `security-auditor`)
- **Solo escriben en**: `Documentacion/<AppName>/` (documentación **interna**)
- **Leen**: `.doc_agents/` (estructura base), `<AppName>/.specify/` (constitución), `Documentacion/<AppName>/` (contexto app)
- **NUNCA tocan**: `src/` (incluye `<AppName>/.specify/` — esa la escribe `Agent-SSD`), `tests/`, otras apps

### Agentes implementadores (`api-developer`, `frontend-developer`, `devops`, `qa-senior`)
- **Escriben en**: `src/`, `tests/` de SU app
- **Leen**: `Documentacion/<AppName>/pendientes-implementacion.md` (tareas), specs en `Documentacion/<AppName>/specs/`
- **NUNCA escriben en**: `Documentacion/` de otras apps

### Agente `Agent-SSD` (orquestador del flujo SSD — ADR-0005)
- **Rol**: Orquestador del flujo SSD + ejecutor de comandos Speckit + documentador de artefactos speckit. Como `implementador` mantiene el flujo de implementación, `Agent-SSD` mantiene el flujo SSD — si Speckit ejecuta comandos, él los ejecuta (no solapa funcionalidades).
- **Skills**: speckit-specify, speckit-plan, speckit-tasks, speckit-analyze, speckit-converge, speckit-constitution (+ wizard interactivo).
- **Escribe en**: `<AppName>/.specify/` (SOLO esa subcarpeta: constitution, specs), `Documentacion/<AppName>/specs/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`.
- **NUNCA toca**: código fuente (`src/<App>/` excepto `.specify/`), `tests/`, `Documentacion/<OtraApp>/`, docstrings inline.
- **Ciclo con `pensador`**: el `pensador` delega → Agent-SSD ejecuta y documenta → reporta al `pensador` → el `pensador` valida y continúa el flujo cuando corresponde (validación del usuario entre fases). Agent-SSD NUNCA auto-continúa a la siguiente fase.
- **Proyectos vivos**: crea/actualiza CUALQUIER documento speckit en cualquier momento del ciclo (constitution, spec, plan, tasks, analyze, converge).


### Agente `plataformador`
- **Audita**: Estructura completa del repo (todas las apps + kit transversal)
- **Compara contra**: `.doc_agents/capacidad-base.md` (catálogo del kit)
- **Actualiza**: `Documentacion/<AppName>/memoria-proyecto.md` de CADA app
- **Puede copiar**: `.github/`, `.opencode/`, `.doc_agents/`, `.specify/` entre apps si hace falta nivelar

### Agente `solucionador`
- **Escribe bitácoras en**: `Documentacion/<AppName>/bitacoras/` de la app afectada
- **Puede leer**: `Documentacion/<AppName>/soluciones-conocidas.md` y `referencias.md`

---

## 📝 Reglas para `speckit` (specify)

- `speckit-specify` → escribe specs en `Documentacion/<AppName>/specs/<nnn-feature>/spec.md`
- `speckit-plan` → escribe plans en `Documentacion/<AppName>/specs/<nnn-feature>/plan.md`
- `speckit-tasks` → escribe tasks en `Documentacion/<AppName>/specs/<nnn-feature>/tasks.md`
- `speckit-converge` / `speckit-implement` → leen de `Documentacion/<AppName>/specs/...` y escriben en `src/` de la app

---

## 🎨 Ejemplo real: Múltiples apps en un repo

> ⚠️ **Son DOS carpetas distintas por app**:
> - **`Documentacion_Publica/`** (dentro de cada app) → información **pública**: cómo instalar, capacidades de la herramienta, documentación propia del proyecto Git descargado. Es lo que se publica.
> - **`Documentacion/`** (en la raíz del repo, con subcarpeta por app) → documentación **interna/técnica**: specs, tareas, ADRs, corrección de errores, el día a día del desarrollo. **NO se publica** en repositorios públicos.

```
mi-repo/
├── .github/                 ← Kit transversal (copiado)
├── .opencode/               ← Kit transversal (copiado)
├── .doc_agents/             ← Kit transversal (copiado)
├── <AppName>/.specify/      ← Config speckit de la app (constitution, specs) — [AGENT-SSD] ADR-0005
│
├── App-Frontend/            ← App 1
│   ├── Documentacion_Publica/        ← 📢 PÚBLICA (se publica)
│   │   ├── README.md                 ← Cómo instalar, usar, capacidades
│   │   ├── instalacion.md            ← Guía de instalación
│   │   └── ...                       ← Doc propia del proyecto Git descargado
│   ├── src/
│   ├── tests/
│   └── ...
│
├── App-Backend/             ← App 2
│   ├── Documentacion_Publica/        ← 📢 PÚBLICA (se publica)
│   │   ├── README.md
│   │   ├── instalacion.md
│   │   └── ...
│   ├── src/
│   ├── tests/
│   └── ...
│
└── Mobile-App/              ← App 3
    ├── Documentacion_Publica/        ← 📢 PÚBLICA (se publica)
    │   ├── README.md
    │   ├── instalacion.md
    │   └── ...
    ├── src/
    ├── tests/
    └── ...

├── Documentacion/           ← 🔒 INTERNA (NO se publica)
│   ├── <App-Frontend>/            ← Doc técnica PROPIA del frontend
│   │   ├── 00-indice.md      ← Índice general de ESTA app
│   │   ├── idioma.md         ← Configuración de idioma de ESTA app
│   │   ├── preferencias.md   ← Preferencias del usuario para ESTA app
│   │   ├── roadmap.md        ← Backlog de evolutivos de ESTA app
│   │   ├── pendientes-implementacion.md ← Puente docs ↔ código de ESTA app
│   │   ├── capacidad-base.md ← Capacidad base heredada del kit (referencia)
│   │   ├── memoria-proyecto.md ← Capacidades instaladas en ESTA app
│   │   │
│   │   ├── specs/            ← 📋 speckit ESCRIBE AQUÍ (spec/plan/tasks)
│   │   │   ├── 001-feature-name/
│   │   │   │   ├── spec.md
│   │   │   │   ├── plan.md
│   │   │   │   ├── tasks.md
│   │   │   │   └── ...
│   │   │   └── ...
│   │   │
│   │   ├── arquitectura/     ← 📐 Decisiones de arquitectura de ESTA app
│   │   │   ├── adr/          ← ADRs (Architecture Decision Records)
│   │   │   └── diagramas/    ← Diagramas Mermaid
│   │   │
│   │   ├── agents/           ← 🤖 Configuración de agentes para ESTA app
│   │   │   ├── pensador/
│   │   │   │   └── spec.md
│   │   │   ├── arquitecto/
│   │   │   │   └── spec.md
│   │   │   ├── documentador/
│   │   │   │   └── spec.md
│   │   │   ├── security-auditor/
│   │   │   │   └── spec.md
│   │   │   ├── api-developer/
│   │   │   │   └── spec.md
│   │   │   ├── frontend-developer/
│   │   │   │   └── spec.md
│   │   │   ├── devops/
│   │   │   │   └── spec.md
│   │   │   ├── qa-senior/
│   │   │   │   └── spec.md
│   │   │   ├── gitflow/
│   │   │   │   └── spec.md
│   │   │   ├── solucionador/
│   │   │   │   └── spec.md
│   │   │   └── plataformador/
│   │   │       ├── spec.md
│   │   │       ├── capacidad-base.md
│   │   │       └── memoria-proyecto.md
│   │   │
│   │   ├── bitacoras/        ← 📝 Bitácoras de intervenciones (solucionador)
│   │   │
│   │   ├── testing/          ← 🧪 Opcional — solo si hay tests documentados
│   │   ├── seguridad/        ← 🔒 Opcional — solo si hay auditorías
│   │   └── despliegue/       ← 🚀 Opcional — solo si hay docs de despliegue
│   │
│   ├── <App-Backend>/            ← Doc técnica PROPIA del backend
│   │   ├── 00-indice.md      ← Índice general de ESTA app
│   │   ├── idioma.md         ← Configuración de idioma de ESTA app
│   │   ├── preferencias.md   ← Preferencias del usuario para ESTA app
│   │   ├── roadmap.md        ← Backlog de evolutivos de ESTA app
│   │   ├── pendientes-implementacion.md ← Puente docs ↔ código de ESTA app
│   │   ├── capacidad-base.md ← Capacidad base heredada del kit (referencia)
│   │   ├── memoria-proyecto.md ← Capacidades instaladas en ESTA app
│   │   │
│   │   ├── specs/            ← 📋 speckit ESCRIBE AQUÍ (spec/plan/tasks)
│   │   │   ├── 001-feature-name/
│   │   │   │   ├── spec.md
│   │   │   │   ├── plan.md
│   │   │   │   ├── tasks.md
│   │   │   │   └── ...
│   │   │   └── ...
│   │   │
│   │   ├── arquitectura/     ← 📐 Decisiones de arquitectura de ESTA app
│   │   │   ├── adr/          ← ADRs (Architecture Decision Records)
│   │   │   └── diagramas/    ← Diagramas Mermaid
│   │   │
│   │   ├── agents/           ← 🤖 Configuración de agentes para ESTA app
│   │   │   ├── pensador/
│   │   │   │   └── spec.md
│   │   │   ├── arquitecto/
│   │   │   │   └── spec.md
│   │   │   ├── documentador/
│   │   │   │   └── spec.md
│   │   │   ├── security-auditor/
│   │   │   │   └── spec.md
│   │   │   ├── api-developer/
│   │   │   │   └── spec.md
│   │   │   ├── frontend-developer/
│   │   │   │   └── spec.md
│   │   │   ├── devops/
│   │   │   │   └── spec.md
│   │   │   ├── qa-senior/
│   │   │   │   └── spec.md
│   │   │   ├── gitflow/
│   │   │   │   └── spec.md
│   │   │   ├── solucionador/
│   │   │   │   └── spec.md
│   │   │   └── plataformador/
│   │   │       ├── spec.md
│   │   │       ├── capacidad-base.md
│   │   │       └── memoria-proyecto.md
│   │   │
│   │   ├── bitacoras/        ← 📝 Bitácoras de intervenciones (solucionador)
│   │   │
│   │   ├── testing/          ← 🧪 Opcional — solo si hay tests documentados
│   │   ├── seguridad/        ← 🔒 Opcional — solo si hay auditorías
│   │   └── despliegue/       ← 🚀 Opcional — solo si hay docs de despliegue
│   │
│   └── <Mobile-App>/            ← Doc técnica PROPIA del mobile
│       ├── 00-indice.md      ← Índice general de ESTA app
│       ├── idioma.md         ← Configuración de idioma de ESTA app
│       ├── preferencias.md   ← Preferencias del usuario para ESTA app
│       ├── roadmap.md        ← Backlog de evolutivos de ESTA app
│       ├── pendientes-implementacion.md ← Puente docs ↔ código de ESTA app
│       ├── capacidad-base.md ← Capacidad base heredada del kit (referencia)
│       ├── memoria-proyecto.md ← Capacidades instaladas en ESTA app
│       │
│       ├── specs/            ← 📋 speckit ESCRIBE AQUÍ (spec/plan/tasks)
│       │   ├── 001-feature-name/
│       │   │   ├── spec.md
│       │   │   ├── plan.md
│       │   │   ├── tasks.md
│       │   │   └── ...
│       │   └── ...
│       │
│       ├── arquitectura/     ← 📐 Decisiones de arquitectura de ESTA app
│       │   ├── adr/          ← ADRs (Architecture Decision Records)
│       │   └── diagramas/    ← Diagramas Mermaid
│       │
│       ├── agents/           ← 🤖 Configuración de agentes para ESTA app
│       │   ├── pensador/
│       │   │   └── spec.md
│       │   ├── arquitecto/
│       │   │   └── spec.md
│       │   ├── documentador/
│       │   │   └── spec.md
│       │   ├── security-auditor/
│       │   │   └── spec.md
│       │   ├── api-developer/
│       │   │   └── spec.md
│       │   ├── frontend-developer/
│       │   │   └── spec.md
│       │   ├── devops/
│       │   │   └── spec.md
│       │   ├── qa-senior/
│       │   │   └── spec.md
│       │   ├── gitflow/
│       │   │   └── spec.md
│       │   ├── solucionador/
│       │   │   └── spec.md
│       │   └── plataformador/
│       │       ├── spec.md
│       │       ├── capacidad-base.md
│       │       └── memoria-proyecto.md
│       │
│       ├── bitacoras/        ← 📝 Bitácoras de intervenciones (solucionador)
│       │
│       ├── testing/          ← 🧪 Opcional — solo si hay tests documentados
│       ├── seguridad/        ← 🔒 Opcional — solo si hay auditorías
│       └── despliegue/       ← 🚀 Opcional — solo si hay docs de despliegue
```

---

## 📢 Pública vs 🔒 Interna — resumen

| Aspecto | `Documentacion_Publica/` (dentro de la app) | `Documentacion/<AppName>/` (raíz del repo) |
|---------|:---:|:---:|
| **Contenido** | Cómo instalar, capacidades de la herramienta, doc propia del proyecto Git descargado | Specs, tareas, ADRs, corrección de errores, día a día del desarrollo |
| **Visibilidad** | 📢 Pública — se publica | 🔒 Interna — NO se publica |
| **¿Parte del producto final?** | ✅ Sí | ❌ No necesariamente |
| **Uso** | Usuarios / consumidores de la app | IA + equipo de desarrollo |
| **¿Se copia entre proyectos?** | ❌ No (propia de la app) | ❌ No (propia de la app) |

> 💡 **Decisión del equipo**: parte de la documentación interna (`Documentacion/<AppName>/`) puede **copiarse a la pública** (`Documentacion_Publica/`) cuando el equipo lo decide — por ejemplo specs o tareas que pasan a ser parte del producto. Pero por defecto, lo interno (specs, tareas, corrección de errores, bitácoras) **no se publica** en repositorios públicos.

Cada app es **independiente**, tiene su **idioma**, sus **preferencias**, sus **specs**, sus **ADRs**.  
El kit de agentes (`.github/`, `.opencode/`, `.doc_agents/`) es **compartido y sincronizado** vía `sync-agents.ps1`.

Cada app es **independiente**, tiene su **idioma**, sus **preferencias**, sus **specs**, sus **ADRs**.  
El kit de agentes (`.github/`, `.opencode/`, `.doc_agents/`) es **compartido y sincronizado** vía `sync-agents.ps1`.

