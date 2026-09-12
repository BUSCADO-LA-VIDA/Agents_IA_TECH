# 🧠 Ecosistema de Documentación Técnica sin IA de Entrada

> **Plan de integración** — Agents_IA_TECH
> **Fecha**: 2026-09-12
> **Estado**: Propuesto / Aprobado para implementación

---

## 🎯 Objetivo

Integrar un **pipeline de herramientas** que generen la documentación técnica de los proyectos **sin usar IA de entrada** (solo herramientas Python y MCP), dejando la IA **solo bajo demanda** y con un **archivo de memoria** para saber qué ya se analizó.

**Principio rector**: *"Al combinar soluciones que no usan IA de entrada ganamos velocidad y eficiencia. El uso de la IA debe ser posterior al uso de las herramientas Python y MCP, y siempre bajo demanda."*

---

## 🧩 Las 4 herramientas del ecosistema

| Herramienta | Tipo | Rol en el pipeline | ¿Usa IA? | Licencia |
|-------------|------|--------------------|:--------:|----------|
| **`markitdown`** (Microsoft) | Python + MCP | **Paso 1**: convierte cualquier formato (PDF, DOCX, PPTX, XLSX, HTML, etc.) a **Markdown**. 100% offline | ❌ No | MIT |
| **`graphify`** | CLI (ya en kit) | **Paso 2**: crea el grafo de conocimiento del proyecto (código + docs + PDFs) | ❌ No | (verificar) |
| **`codebase-memory-mcp`** | MCP | **Paso 2**: grafo de conocimiento del código (bisturí quirúrgico) | ❌ No | (verificar) |
| **`context-mode`** | MCP | **Paso 3**: optimiza la ventana de contexto al consultar la doc generada | ❌ No | ELv2 |

---

## 🔄 El pipeline (sin IA de entrada)

```mermaid
flowchart LR
    A[Doc en formato<br/>PDF/DOCX/PPTX/HTML...] --> B[markitdown<br/>convierte a MD]
    B --> C[MD generado]
    C --> D[graphify<br/>grafo de conocimiento]
    C --> E[codebase-memory-mcp<br/>grafo de código]
    D --> F[Documentación técnica<br/>del proyecto]
    E --> F
    F --> G[context-mode<br/>consulta optimizada]
    G --> H{¿Se necesita<br/>análisis con IA?}
    H -->|Sí, preguntar al usuario| I[IA bajo demanda<br/>+ archivo memoria]
    H -->|No| J[✅ Fin sin IA]
```

### Explicación del flujo

1. **`markitdown`** — Si la documentación del proyecto no está en Markdown (está en PDF, Word, Excel, PowerPoint, HTML, etc.), se convierte primero a MD. Es 100% offline y sin IA.
2. **`graphify`** — Construye el grafo de conocimiento del proyecto (código + documentación + PDFs) para navegar las relaciones.
3. **`codebase-memory-mcp`** — Construye el grafo de conocimiento del código (bisturí quirúrgico para código).
4. **`context-mode`** — Optimiza la ventana de contexto al consultar la documentación generada (indexación FTS5 + BM25).
5. **IA bajo demanda** — Solo si las herramientas sin IA no pudieron analizar algo (ej: imágenes sin OCR, audio sin transcripción), se **pregunta al usuario** si quiere ese análisis con IA.

---

## 📝 El archivo de memoria

Un archivo tipo **`Documentacion/<AppName>/analisis-memoria.md`** que registra:

- Qué documentación ya fue **convertida** a MD (por `markitdown`).
- Qué documentación ya fue **indexada/graficada** (por `graphify` / `codebase-memory-mcp`).
- Qué documentación **requiere IA** (porque las herramientas sin IA no pudieron analizarla) y **si ya fue analizada o no**.
- Evita re-analizar lo ya analizado (ahorro de tiempo y tokens).

---

## 🤖 Nuevo agente: `analista_tecnico`

### Rol

El **`analista_tecnico`** es el agente que orquesta el pipeline de documentación técnica sin IA de entrada. Su principal trabajo es **documentar proyectos** (nuevos o sin documentación), generando ideas nuevas y manteniendo todo ordenado bajo **SSD (Spec-Driven Development)**.

### Características clave

| Característica | Detalle |
|----------------|---------|
| **Invocable por el Pensador** | El `pensador` lo invoca cuando detecta un proyecto nuevo, sin documentación, o que necesita análisis técnico |
| **Retorna al Pensador** | Al terminar su trabajo, **retorna al `pensador`** para que continúe el ciclo (Plan → Documentar → Implementar) |
| **Nombre** | `analista_tecnico` (en minúsculas, con guion bajo, como los demás agentes del kit) |
| **Respeta la estructura SSD** | La documentación que genera queda ordenada bajo el estándar SSD ya establecido en el kit |
| **Llama a otros agentes** | Si hay un agente que ya hace mejor una tarea específica, **lo llama** en lugar de duplicar especificaciones (no duplica trabajo) |
| **Normas establecidas** | Trabaja con las normas y estructura técnica ya definidas en el kit |
| **Sin IA de entrada** | El pipeline base corre sin IA; la IA solo bajo demanda y preguntando al usuario |

### Responsabilidades

| Responsabilidad | Detalle |
|-----------------|---------|
| **Detectar formato** | Al recibir un proyecto, verificar si la doc está en MD o en otro formato |
| **Convertir a MD** | Si no está en MD → ejecutar `markitdown` para generar el MD |
| **Construir grafo** | Ejecutar `graphify` + `codebase-memory-mcp` para crear la documentación técnica |
| **Optimizar consulta** | Usar `context-mode` para consultar la doc sin gastar contexto |
| **Registrar en memoria** | Actualizar el archivo de memoria (qué se convirtió, indexó, analizó) |
| **Preguntar por IA** | Si hay doc que requiere IA (imágenes, audio), **preguntar al usuario** si quiere ese análisis |
| **Delegar a especialistas** | Si la documentación requiere arquitectura, specs, seguridad, etc. → llamar a `arquitecto`, `documentador`, `security-auditor` |
| **Retornar al Pensador** | Al terminar, devolver el control al `pensador` |

### 🔄 Flujo del `analista_tecnico`

El ciclo de trabajo del `analista_tecnico` al recibir un proyecto:

```mermaid
flowchart TD
    A[Pensador invoca<br/>analista_tecnico] --> B[Detectar formato<br/>de la documentación]
    B --> C{¿Está en MD?}
    C -->|No| D[markitdown<br/>convierte a MD]
    C -->|Sí| E[Usar MD directo]
    D --> E
    E --> F[graphify<br/>grafo de conocimiento]
    E --> G[codebase-memory-mcp<br/>grafo de código]
    F --> H[Documentación técnica<br/>del proyecto]
    G --> H
    H --> I[context-mode<br/>consulta optimizada]
    I --> J[Registrar en<br/>analisis-memoria.md]
    J --> K{¿Requiere IA?<br/>imágenes/audio sin analizar}
    K -->|Sí| L[Preguntar al usuario<br/>¿querés análisis con IA?]
    K -->|No| M[Retornar al pensador]
    L -->|Sí| N[IA bajo demanda<br/>+ registrar en memoria]
    L -->|No| M
    N --> M
```

### Integración en la arquitectura existente

```mermaid
flowchart TD
    P[pensador] -->|invoca| AT[analista_tecnico]
    AT -->|convierte a MD| M[markitdown]
    AT -->|grafo| G[graphify]
    AT -->|grafo código| CB[codebase-memory-mcp]
    AT -->|consulta optimizada| CM[context-mode]
    AT -->|delega si aplica| A[arquitecto]
    AT -->|delega si aplica| D[documentador]
    AT -->|delega si aplica| S[security-auditor]
    AT -->|retorna| P
```

---

## 📋 Fases del plan

> **💡 Diagramas como entregables reutilizables**: Los **3 diagramas Mermaid** de este documento (pipeline, flujo del `analista_tecnico`, integración en arquitectura) son **parte del diseño aprobado**. Los agentes de la fase documental deben **reutilizarlos tal cual** (copiarlos a sus specs/ADRs/guías) y **no rediseñarlos desde cero**. Esto evita trabajo duplicado y mantiene consistencia.

### Fase documental

| Orden | Agente | Acción | Diagramas a reutilizar |
|-------|--------|--------|------------------------|
| 1º | `arquitecto` | Definir la arquitectura del pipeline (orden de herramientas, archivo de memoria, rol del `analista_tecnico`) + ADR | **Pipeline** + **Integración en arquitectura** |
| 2º | `documentador` | Crear guías en `MCPs/` para `markitdown`, `codebase-memory-mcp`; actualizar `referencias.md`, `memoria-proyecto.md`, `roadmap.md`, `00-indice.md`, `pendientes-implementacion.md` | **Pipeline** + **Flujo del `analista_tecnico`** |
| 3º | `security-auditor` | Revisión de seguridad de uso (markitdown, codebase-memory-mcp) | **Pipeline** (para evaluar puntos de entrada de datos) |

### Fase implementación

| Orden | Agente | Acción | Diagramas a reutilizar |
|-------|--------|--------|------------------------|
| 4º | `plataformador` | Instalar `markitdown` + `markitdown-mcp`, `codebase-memory-mcp`, configurar `.vscode/mcp.json`, hooks | **Pipeline** |
| 5º | `upgrade_framework` | Registrar `markitdown`, `codebase-memory-mcp` en `dependencias-manifest.yml` | — |
| 6º | `pensador` + documentales | Crear el nuevo agente `analista_tecnico` (spec + `.agent.md`), ajustar specs de agentes para el pipeline | **Flujo del `analista_tecnico`** + **Integración en arquitectura** |
| 7º | `gitflow` | Commits convencionales | — |

### Fase implementación

| Orden | Agente | Acción |
|-------|--------|--------|
| 4º | `plataformador` | Instalar `markitdown` + `markitdown-mcp`, `codebase-memory-mcp`, configurar `.vscode/mcp.json`, hooks |
| 5º | `upgrade_framework` | Registrar `markitdown`, `codebase-memory-mcp` en `dependencias-manifest.yml` |
| 6º | `pensador` + documentales | Crear el nuevo agente `analista_tecnico` (spec + `.agent.md`), ajustar specs de agentes para el pipeline |
| 7º | `gitflow` | Commits convencionales |

---

## ✅ Decisiones confirmadas

| Punto | Decisión |
|-------|----------|
| Nombre del nuevo agente | **`analista_tecnico`** |
| Archivo de memoria | `Documentacion/<AppName>/analisis-memoria.md` |
| Incluir `codebase-memory-mcp` | ✅ Sí |
| Reforzar `graphify` en el pipeline | ✅ Sí |
| Invocable por el Pensador | ✅ Sí |
| Retorna al Pensador al terminar | ✅ Sí |
| Respeta estructura SSD | ✅ Sí |
| Llama a otros agentes (no duplica) | ✅ Sí |
