# 📚 Documentación Agents_IA_TECH

> **Resumen rápido:** Este repositorio usa una estructura de documentación dual por aplicación. Hay **dos carpetas distintas** para cada proyecto: una **pública** (lo que se publica) y una **interna** (para el equipo/IA).

---

## 🏗️ Dónde se implementa la documentación (vista completa del repo)

> **Regla de oro:** Cada aplicación tiene su propia carpeta de documentación aislada.  
> El kit de agentes (`.github/`, `.opencode/`, `.doc_agents/`) es **transversal y se copia** entre proyectos.  
> `Documentacion/<AppName>/` es **propia de la app** y **NO se copia** entre proyectos.

```text
mi-repo/
├── .github/                 ← Kit transversal (COPIADO entre proyectos)
├── .opencode/               ← Kit transversal (COPIADO entre proyectos)
├── .doc_agents/             ← Kit transversal (COPIADO entre proyectos)
├── .specify/                ← Config speckit base (COPIADO, personalizable)
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
│       │   ├── adr/          ←   ADRs (Architecture Decision Records)
│       │   └── diagramas/    ←   Diagramas Mermaid
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

## 🌐 Dos Carpetas por Aplicación (Pública vs Interna)

### `Documentacion_Publica/` (DENTRO de cada app)
- **Qué es:** Información pública que se publica en repositorios
- **Contenido:** Cómo instalar, capacidades de la herramienta, documentación propia del proyecto Git descargado
- **Visibilidad:** 📢 Pública — se publica
- **Uso:** Usuarios / consumidores de la app
- **¿Parte del producto final?:** ✅ Sí

### `Documentacion/<AppName>/` (EN LA RAÍZ DEL REPO)
- **Qué es:** Documentación técnica interna — **NO se publica**
- **Contenido:** Specs, tareas, ADRs, corrección de errores, día a día del desarrollo
- **Visibilidad:** 🔒 Interna — NO se publica
- **Uso:** IA + equipo de desarrollo
- **¿Parte del producto final?:** ❌ No necesariamente

> **Regla:** Por defecto, lo interno (`Documentacion/<AppName>/`) **no se publica**. Parte puede copiarse a pública cuando el equipo lo decida (ej. specs que pasan a ser parte del producto). Pero por defecto, lo interno (specs, tareas, corrección de errores, bitácoras) **no se publica** en repositorios públicos.

### 📊 Comparativa rápida

| Aspecto | `Documentacion_Publica/` (dentro de la app) | `Documentacion/<AppName>/` (raíz del repo) |
|---------|:---:|:---:|
| **Contenido** | Cómo instalar, capacidades, doc del proyecto Git | Specs, tareas, ADRs, corrección de errores |
| **Visibilidad** | 📢 Pública — se publica | 🔒 Interna — NO se publica |
| **¿Parte del producto final?** | ✅ Sí | ❌ No necesariamente |
| **Uso** | Usuarios / consumidores | IA + equipo de desarrollo |
| **¿Se copia entre proyectos?** | ❌ No (propia de la app) | ❌ No (propia de la app) |

---

## 📂 Estructura de Carpetas (vista local de este repo)

```text
Documentacion/
├── 00-indice.md                ← Índice del kit transversal (siempre igual)
└── Agents_IA_TECH/             ← 📁 Documentación PROPIA de este proyecto
    ├── 00-indice.md            ← Índice de ESTA aplicación
    ├── capacidad-base.md       ← Capacidades heredadas del kit
    ├── memoria-proyecto.md     ← Qué está instalado en este proyecto
    ├── idioma.md               ← Idioma de comunicación
    ├── preferencias.md         ← Preferencias usuario
    ├── referencias.md          ← Fuentes externas
    ├── roadmap.md              ← Backlog evolutivos
    ├── pendientes-implementacion.md ← Puente docs ↔ código (tareas pendientes)
    ├── soluciones-conocidas.md ← Problemas ya resueltos
    ├── specs/                  ← 📋 specs, planes y tasks (speckit)
    ├── arquitectura/adr/       ← 📐 Decisiones de arquitectura (ADRs)
    ├── arquitectura/diagramas/ ← Diagramas Mermaid
    ├── agents/                 ← 🤖 Configuración de agentes
    │   ├── pensador/
    │   ├── arquitecto/
    │   ├── documentador/
    │   ├── security-auditor/
    │   ├── api-developer/
    │   ├── frontend-developer/
    │   ├── devops/
    │   ├── qa-senior/
    │   ├── gitflow/
    │   ├── solucionador/
    │   └── plataformador/
    ├── bitacoras/              ← 📝 Bitácoras intervenciones
    ├── testing/                ← 🧪 Tests documentados (opcional)
    ├── seguridad/              ← 🔒 Auditorías (opcional)
    └── despliegue/             ← 🚀 Docs despliegue (opcional)
```

---

## 🔄 Flujo de Trabajo

```
Plan aprobado → Documentar (Specify + agentes) → Implementar → Gitflow commit
Siempre en ese orden.
```

### Roles Principales

| Agente | Qué hace |
|--------|----------|
| **pensador** | Orquestador: plan → confirmar → documentar → implementar → preguntar |
| **arquitecto** | ADRs, guardrails, diagramas, spec linking |
| **documentador** | Specs, templates, versionado, plan→tasks |
| **security-auditor** | Revisión seguridad, OWASP, secrets |
| **api-developer** | Implementación backend/API |
| **frontend-developer** | Implementación frontend/UI |
| **devops** | Docker, CI/CD, infraestructura |
| **qa-senior** | Tests automatizados, feedback loop |
| **gitflow** | Commits convencionales al final |
| **plataformador** | Auditoría, nivelación, graphify |
| **solucionador** | SSH remoto diagnóstico y fix |

### Persistencia de Sesiones
- El `pensador` guarda análisis/decisiones en `sesiones/`
- Al reiniciar VS Code, lee la última sesión como base
- **Regla:** Pregunta antes de borrar: *"¿Querés guardar esta propuesta?"*

---

## 📦 Qué se Copia vs qué es Propio

> **Kit transversal** = lo que `sync-agents.ps1` copia a **TODOS los proyectos** donde implementas tus agentes. Es lo **común** para todos.  
> **Propio de la app** = lo que NUNCA se copia ni sobrescribe — cada proyecto tiene lo suyo.

### ✅ Kit transversal (se copia a todos los proyectos)

| Elemento | Se copia | Es propio de la app |
|----------|:--------:|:-------------------:|
| `.github/` | ✅ Sí | ❌ No |
| `.opencode/` | ✅ Sí | ❌ No |
| `.doc_agents/` | ✅ Sí | ❌ No |
| `.specify/memory/constitution.md` | ✅ Sí (base) | ⚠️ Personalizable |
| `AGENTS.md` | ✅ Sí | ❌ No |
| `opencode.json` | ✅ Sí | ❌ No |
| `README.md` (instalación del kit) | ✅ Sí | ❌ No |
| `sync-agents.ps1` | ✅ Sí | ❌ No |

### 🔒 Propio de cada app (NUNCA se copia)

| Elemento | Se copia | Es propio de la app |
|----------|:--------:|:-------------------:|
| `Documentacion_Publica/` (dentro de la app) | ❌ **NUNCA** | ✅ **Siempre** |
| `Documentacion/<AppName>/` (raíz del repo) | ❌ **NUNCA** | ✅ **Siempre** |
| `src/`, `tests/` | ❌ No | ✅ Sí |

> **Nota:** Este archivo (`Documentacion/README.md`) es **interno del repo maestro** y **NO se copia** a otros proyectos — es solo la guía de la estructura de documentación.  
> El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`) es **común y se sincroniza** vía `sync-agents.ps1`.  
> `Documentacion/<AppName>/` y `Documentacion_Publica/` **NUNCA se tocan** durante la sincronización.

---

## 🛠️ Primeros Pasos

1. **Leer** `Documentacion/00-indice.md` → Entender la estructura del kit
2. **Leer** `Documentacion/Agents_IA_TECH/00-indice.md` → Contexto de este proyecto
3. **Revisar** `pendientes-implementacion.md` → Qué está pending
4. **Explorar** `specs/` → Specs, planes y tasks activas
5. **Revisar** `arquitectura/adr/` → Decisiones de arquitectura tomadas

---

## 📞 ¿Dudas?

- Revisar `referencias.md` → Proyectos y licencias de referencia
- Revisar `idioma.md` → Configuración de idioma (español latino neutro)
- Revisar `preferencias.md` → Preferencias de usuario y flujo git

---

**última actualización:** 2026-08-31