# 📋 Índice del Proyecto
*Última actualización: 2026-08-05*

> Este archivo es la **memoria del proyecto** para los agentes. Lo leen primero para entender el contexto sin escanear todo. Los agentes documentales lo mantienen actualizado automáticamente.

## Stack
- Framework: (kit de agentes — sin framework de aplicación)
- Lenguaje: Markdown / YAML
- Base de datos: (ninguna — es configuración de agentes)
- Infraestructura: GitHub Copilot + OpenCode

## CI/CD (GitHub Actions)
- `agentshield.yml` — Security scan de configs de agentes (`ecc-agentshield`, solo `.github/**`)
- `security-scan.yml` — Detección de secrets (gitleaks) sobre todo el repo (push/PR)
- `spellcheck.yml` — Revisión de ortografía (codespell) sobre `.md`/`.yaml`/`.yml` (push/PR)

## Estructura del proyecto
<!-- Completar con las carpetas principales -->
- `Documentacion/` — Documentación del proyecto (NO se copia entre proyectos)
- `.doc_agents/` — 📐 Documentación transversal del kit de agentes (se copia entre proyectos)
- `.github/` — Configuración de agentes Copilot
- `.opencode/` — Configuración de agentes OpenCode

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
├── arquitectura/             ← 📐 Decisiones de arquitectura
│   ├── adr/                  ←   Registros de decisiones (ADRs)
│   └── diagramas/            ←   Diagramas de diseño (Mermaid)
│
├── funcionalidades/          ← 📋 Especificaciones funcionales
│
├── agents/                   ← 🤖 Docs de cada agente (spec + archivos propios)
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
│       ├── spec.md
│       ├── capacidad-base.md
│       └── memoria-proyecto.md
│
├── bitacoras/                ← 📝 Bitácoras de intervenciones (solucionador)
│
├── testing/         ← 🧪 Opcional — solo si hay tests documentados
├── seguridad/       ← 🔒 Opcional — solo si hay auditorías
└── despliegue/      ← 🚀 Opcional — solo si hay docs de despliegue
```

## ADRs activos
<!-- Listar ADRs en Documentacion/arquitectura/adr/ -->
- (ninguno aún)

## Features activas
<!-- Listar specs en Documentacion/funcionalidades/ -->
- (ninguna aún)

## Agentes

| Agente | Rol | Estado |
|--------|-----|--------|
| `pensador` | Orquestador del ciclo completo: plan -> confirmar -> ejecutar -> actualizar -> preguntar. 🔌 Puede depurar en caliente vía SSH (solo lectura) | ✅ Actualizado 2026-08-19 |
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