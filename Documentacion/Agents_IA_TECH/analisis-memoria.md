# 📝 Archivo de Memoria del Pipeline de Documentación

> **Registro de qué se convirtió, indexó y analizó** en el pipeline de documentación técnica sin IA de entrada.
> **Propósito**: evitar re-analizar lo ya analizado (ahorro de tiempo y tokens).
> **Mantenido por**: `analista_tecnico` (orquesta el pipeline) y agentes documentales.
> **Basado en**: `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` (guardrail 2).

---

## 📊 Estado del pipeline

| Fecha | Proyecto | Convertido a MD (markitdown) | Indexado/Graficado (graphify/codebase-memory-mcp) | Requiere IA | Analizado con IA |
|-------|----------|:---:|:---:|:---:|:---:|
| 2026-09-12 | Agents_IA_TECH | ✅ | ✅ | ❌ | — |

---

## 📋 Registro detallado

### Convertido a MD (markitdown)
- [x] `Documentacion/Agents_IA_TECH/` — documentación del kit ya está en Markdown (no requiere conversión).

### Indexado/Graficado (graphify / codebase-memory-mcp)
- [x] `codebase-memory-mcp` — repositorio indexado (proyecto `C-Proyectos-Agents_IA_TECH`, 13216 nodos / 64097 aristas, 2026-09-12).

### Requiere IA
- [ ] Ninguna documentación del kit requiere IA de entrada por el momento.

---

## 🔄 Cómo actualizar este archivo

1. **Al convertir** documentación con `markitdown` → marcar en la columna "Convertido a MD".
2. **Al indexar/graficar** con `graphify` / `codebase-memory-mcp` → marcar en la columna "Indexado/Graficado".
3. **Si una documentación requiere IA** (imágenes sin OCR, audio sin transcripción) → marcar "Requiere IA" y, si el usuario aprueba el análisis, marcar "Analizado con IA".
4. **Nunca re-analizar** lo ya marcado como analizado.
