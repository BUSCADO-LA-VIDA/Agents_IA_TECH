# 📋 Índice del Proyecto
*Última actualización: 2026-07-25*

> Este archivo es la **memoria del proyecto** para los agentes. Lo leen primero para entender el contexto sin escanear todo. Los agentes documentales lo mantienen actualizado automáticamente.

## Stack
- Framework: (kit de agentes — sin framework de aplicación)
- Lenguaje: Markdown / YAML
- Base de datos: (ninguna — es configuración de agentes)
- Infraestructura: GitHub Copilot + OpenCode

## Estructura del proyecto
<!-- Completar con las carpetas principales -->
- `src/` — Código fuente (si aplica)
- `.github/` — Configuración de agentes Copilot
- `.opencode/` — Configuración de agentes OpenCode
- `Documentacion/` — Documentación del proyecto

### Estructura de `Documentacion/`

```
Documentacion/
├── 00-indice.md              ← 📋 Este archivo (índice general)
├── idioma.md                 ← 🌐 Configuración de idioma
├── preferencias.md           ← 👤 Preferencias del usuario
├── preferencias-git.md       ← 🏷️ Preferencias de flujo git
├── referencias.md            ← 📖 Atribución de fuentes externas
├── roadmap.md                ← 🗺️ Backlog de evolutivos
├── pendientes-implementacion.md ← 📋 Puente entre docs y código
├── soluciones-conocidas.md   ← 📚 Soluciones a problemas recurrentes
├── capacidad-base.md         ← 🏗️ Catálogo central del kit de agentes
├── memoria-proyecto.md       ← 🧠 Capacidades instaladas (plataformador)
│
├── agents/                   ← 📐 Specs de cada agente
│   ├── pensador/
│   │   └── spec.md
│   ├── arquitecto/
│   │   └── spec.md
│   ├── documentador/
│   │   └── spec.md
│   ├── security-auditor/
│   │   └── spec.md
│   ├── api-developer/
│   │   └── spec.md
│   ├── frontend-developer/
│   │   └── spec.md
│   ├── devops/
│   │   └── spec.md
│   ├── qa-senior/
│   │   └── spec.md
│   ├── gitflow/
│   │   └── spec.md
│   ├── solucionador/
│   │   └── spec.md
│   └── plataformador/
│       └── spec.md
│
├── bitacoras/                ← 📝 Bitácoras del solucionador
├── adr/                      ← 🏛️ Architectural Decision Records
```

## ADRs activos
<!-- Listar ADRs en Documentacion/adr/ -->
- (ninguno aún)

## Features activas
<!-- Listar specs en Documentacion/specs/ -->
- (ninguna aún)

## Agentes

| Agente | Rol | Estado |
|--------|-----|--------|
| `pensador` | Orquestador del ciclo completo: plan -> confirmar -> ejecutar -> actualizar -> preguntar | ✅ Actualizado 2026-07-24 |
| `arquitecto` | Decisiones de arquitectura, ADRs, patrones | 🟢 Activo |
| `documentador` | Documentación de specs, flujos, ADRs | 🟢 Activo |
| `security-auditor` | Revisión de seguridad en diseños | 🟢 Activo |
| `api-developer` | Implementación backend/API | 🟢 Activo |
| `frontend-developer` | Implementación frontend/UI | 🟢 Activo |
| `devops` | Infraestructura, Docker, CI/CD | 🟢 Activo |
| `qa-senior` | Tests automatizados (unit, integración, E2E) | 🟢 Activo |
| `gitflow` | Git operations, branching, PRs | 🟢 Activo |
| `solucionador` | 🔧 Diagnóstico y solución de problemas via SSH en servidores remotos | 🟢 Activo 2026-07-25 |
| `plataformador` | 🏗️ Auditoría, nivelación y replataformado de proyectos contra capacidad-base | 🟢 Activo 2026-07-25 |

## Convenciones del proyecto
<!-- Completar con reglas específicas del proyecto -->
- ...