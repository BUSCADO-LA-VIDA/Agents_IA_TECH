# 📐 Estructura Estándar de `Documentacion/`

> **Fuente de verdad** sobre cómo debe organizarse la documentación del proyecto.
> Este archivo es **transversal** — viaja con los agentes a todos los proyectos (carpeta `.doc_agents/`).
> El `plataformador` lo usa para auditar y, si encuentra una estructura distinta, pregunta si reorganizar.
> Los agentes documentales la usan para saber dónde crear cada archivo.

## Regla general

**Cada agente tiene su propia carpeta** dentro de `agents/`. Todo lo que sea específico de un agente va dentro de su carpeta. Nada suelto en la raíz de `Documentacion/`.

## Árbol completo

```
proyecto-raiz/                          ← Proyecto madre (ej: Generator_IA_Projects)
│
├── .github/                            ← ✅ Se copia — Agentes GitHub Copilot
├── .opencode/                          ← ✅ Se copia — Agentes OpenCode
├── .doc_agents/                        ← ✅ Se copia — Docs transversales del kit
│
└── proyectos/                          ← Proyectos hijo (cada uno con su Documentacion/)
    │
    └── <nombre-proyecto>/
        │
        └── Documentacion/              ← ❌ No se copia — Es propia de cada proyecto
            │
            └── <aplicacion>/           ← Una aplicación específica del proyecto
                │                         (puede haber N: Backend/, Frontend/, AppMobile/, etc.)
                │
                ├── 00-indice.md                        ← OBLIGATORIO
                ├── idioma.md                           ← OBLIGATORIO
                ├── preferencias.md                     ← OBLIGATORIO
                ├── preferencias-git.md                 ← RECOMENDADO
                ├── referencias.md                      ← RECOMENDADO
                ├── roadmap.md                          ← RECOMENDADO
                ├── pendientes-implementacion.md        ← OBLIGATORIO
                ├── soluciones-conocidas.md             ← OBLIGATORIO
                │
                ├── arquitectura/                       ← Decisiones de arquitectura
                │   ├── adr/                            ←   ADRs (reemplaza adr/ en raíz)
                │   └── diagramas/                      ←   Diagramas de diseño (Mermaid)
                │
                ├── funcionalidades/                    ← Especificaciones funcionales
                │
                ├── agents/                             ← Documentación de agentes
                │   └── <nombre-del-agente>/
                │       ├── spec.md                     ← OBLIGATORIO si el agente existe
                │       └── ... (archivos propios del agente)
                │
                ├── bitacoras/                          ← RECOMENDADO
                │
                ├── testing/          ← OPCIONAL — solo si hay tests documentados
                ├── seguridad/        ← OPCIONAL — solo si hay auditorías
                └── despliegue/       ← OPCIONAL — solo si hay docs de despliegue
```

## Reglas

1. **Cada cosa en su carpeta de agente** — si un archivo solo lo usa un agente, va dentro de `agents/<agente>/`
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
