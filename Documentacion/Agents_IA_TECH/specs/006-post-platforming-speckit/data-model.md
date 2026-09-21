# Data Model: post-platforming-speckit

**Fecha**: 2026-09-20
**Autor**: pensador (Phase 1)

## Entidades

### Escenario

Representa el estado del proyecto al iniciar el flujo post-plataformado.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tipo` | enum | `A` (nuevo desde idea) / `B` (existente con docs a migrar) / `C` (existente sin docs) |
| `constitution_especifica` | bool | ¿Existe `.specify/memory/constitution.md` específico del proyecto? |
| `documentacion_previa` | bool | ¿Existe documentación previa en el proyecto? |
| `codigo_existente` | bool | ¿Existe código de app en `src/<App>/`? |

**Reglas de detección**:
- `A` = sin código + sin documentación previa + sin constitution específica
- `B` = con documentación previa (a migrar)
- `C` = con código pero sin documentación previa

### Artefacto speckit

Representa un artefacto del pipeline.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tipo` | enum | `spec` / `plan` / `tasks` / `analyze` / `converge` |
| `ruta` | string | `Documentacion/<App>/specs/<tipo>.md` |
| `estado` | enum | `borrador` / `aprobado` / `implementado` |

**Transición de estados**:
- `borrador` → (validación usuario) → `aprobado`
- `aprobado` → (re-indexación automática) → índices actualizados
- `aprobado` → (implement) → `implementado`

### Índice

Representa un índice de conocimiento.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tipo` | enum | `context-mode` (docs) / `codebase-memory` (código) / `graphify` (grafo) |
| `scope` | string | `src/<App>/` (por app) o raíz (workspace) |
| `ultima_actualizacion` | datetime | Fecha de la última actualización |
| `estado` | enum | `al_dia` / `stale` (del día anterior o más vieja) |

**Regla de frescura**:
- `stale` si `ultima_actualizacion` < (hoy - 1 día)
- Al recibir una petición, si algún índice está `stale` → actualizar automáticamente

### Constitution

Representa la constitution del proyecto.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `ruta` | string | `.specify/memory/constitution.md` |
| `es_plantilla` | bool | ¿Es la plantilla genérica del kit (sin personalizar)? |
| `articulos` | list | 6 artículos (I-VI, con VI=proyect_ext) |

**Regla**: si `es_plantilla` = true → ofrecer Constitution Wizard (RF-14) para generar una específica.

### Grafo por app

Representa el grafo Graphify de una app.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `ruta` | string | `src/<App>/graphify-out/graph.json` |
| `existe` | bool | ¿Existe el grafo? |
| `ultima_actualizacion` | datetime | Fecha de la última extracción |
| `scope` | string | `src/<App>/` (por app) |

**Regla de construcción**:
- `existe` = false → `graphify extract <scope> --code-only`
- `existe` = true + código cambiado → `graphify update <scope>`
- Flag `-GraphifyDeep` → `graphify extract --mode deep` (con LLM)

## Relaciones

- **Escenario** → determina el **flujo speckit** (A/B/C)
- **Artefacto aprobado** → dispara **re-indexación** de Índices
- **Índice stale** → dispara **actualización automática** de memoria
- **Constitution plantilla** → dispara **Constitution Wizard**
- **Grafo por app** → se construye/actualiza según estado
