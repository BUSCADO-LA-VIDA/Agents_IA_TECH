# Spec: `plataformador-bootstrap.ps1` — Instalador/Actualizador Único

> **Estado**: En planificación (fase documental completada parcialmente)
> **Fecha**: 2026-09-17
> **Fuente**: ADR-0003 `arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` (decisión del usuario 2026-09-17)
> **Autor**: `documentador` (fase documental — paso 2º)

---

## Objetivo

Convertir **`plataformador-bootstrap.ps1`** en el **instalador/actualizador único** del ecosistema: un solo script, determinista e idempotente, que lleva cualquier proyecto a la estructura objetivo **sin tocar la documentación propia de cada app** (`Documentacion/<AppName>/`).

El script cubre en un solo flujo: **sync del kit transversal + configuración de MCPs + indexación + preparación de apps + resolución de la app activa + integración de Spec-kit y Graphify + validación**.

> **Principio rector** (del ADR-0003):
> *"El bootstrap es el instalador/actualizador único del ecosistema: un solo script, determinista e idempotente, que lleva cualquier proyecto a la estructura objetivo sin tocar la documentación propia de cada app."*

---

## Decisiones del usuario (NO negociables)

1. **`sync-agents.ps1` → Opción A**: su lógica se absorbe dentro de `plataformador-bootstrap.ps1` como función `Sync-TransversalKit`; `sync-agents.ps1` queda como wrapper que delega.
2. **Repo maestro**: `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`.
3. **Apps como aplicaciones**: `dwxconnect`, `fibonacci-scanner`, `operation_mt5`, `Telegram`, `trading_bot`. **`proyect_ext/spec-kit` queda en la raíz** (es de apoyo, no se mueve a `src\`).
4. **Resolución de app activa**: por **directorio de trabajo actual** + **flag `-App`** (precedencia: `-App` > `cwd`).

---

## Requisitos funcionales

| ID | Requisito | Detalle |
|----|-----------|---------|
| **RF-01** | **Sync kit transversal (`Sync-TransversalKit`)** | Clona el repo maestro de forma **shallow** (`https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`). Copia SOLO los transversales: `.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md` (base), `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`. |
| **RF-02** | **No tocar `Documentacion/<AppName>/`** | La función `Sync-TransversalKit` **NUNCA** copia, sobrescribe ni borra nada dentro de `Documentacion/<AppName>/` de ninguna app. |
| **RF-03** | **Configurar MCPs** | Configura los MCPs (`context-mode`, `codebase-memory-mcp`, `markitdown`) para **VS Code** (`.vscode/mcp.json`) y **OpenCode** (`opencode.json`). |
| **RF-04** | **Indexar** | Crea/actualiza índices de `codebase-memory-mcp` y `context-mode`. |
| **RF-05** | **Preparar apps en `src\AppXXX\`** | Descarga las apps desde sus repos git y las coloca en `src\AppXXX\`. **No mueve `proyect_ext/spec-kit`** (queda en la raíz). |
| **RF-06** | **Crear `.specify` + `Documentacion\<AppName>\` por app** | Para cada app: crea/actualiza su `.specify` (constitución + config particular) y su `Documentacion/<AppName>/` (doc técnica propia). |
| **RF-07** | **Resolver app activa** | Determina la app activa por: **`-App <nombre>`** (precedencia máxima) → **cwd** dentro de una app conocida → si no hay coincidencia, modo **`root`** (kit, sin doc de app). |
| **RF-08** | **Orientar Spec-kit a la app activa** | Deriva las rutas de Spec-kit: `.specify` activo (`<raizApp>/.specify/` o raíz `.specify/`) y `Documentacion/<AppName>/specs/` donde Spec-kit escribe `spec.md`/`plan.md`/`tasks.md`. |
| **RF-09** | **Integrar Graphify** | Instala/configura Graphify descargando desde git, con **validación de URL/licencia**. |
| **RF-10** | **Validar flujo** | Verifica que los MCPs responden y que el flujo se respeta desde la carga de VS Code sin re-ejecutar scripts. |
| **RF-11** | **`sync-agents.ps1` como wrapper** | `sync-agents.ps1` queda como wrapper que delega en `Sync-TransversalKit`, preservando compatibilidad. |

---

## Requisitos no funcionales

| ID | Requisito |
|----|-----------|
| **RNF-01** | **Idempotencia**: repetir el bootstrap no produce cambios ni errores. Toda operación es comprobable (existe? actualizar si difiere). |
| **RNF-02** | **`-DryRun`**: simula antes de escribir (sin efectos). Disponible en `Sync-TransversalKit` y en el bootstrap completo. |
| **RNF-03** | **`-Force`**: fuerza la sobrescritura de transversales. |
| **RNF-04** | **No romper estructura existente**: respeta la ubicación actual de apps (raíz o `src\AppXXX\`). Nunca destruye código, `src/`, `tests/` ni `Documentacion/` de app. |
| **RNF-05** | **No tocar `Documentacion/<AppName>/`** al sincronizar kit (frontera kit ↔ app). |
| **RNF-06** | **Validar URLs/licencias** al descargar desde git (HTTPS/GitHub confiable) y registrar la licencia en `dependencias-manifest.yml`. |
| **RNF-07** | **Modularidad**: funciones modulares para reducir el riesgo de acoplamiento entre responsabilidades. |
| **RNF-08** | **Conventional commits** para toda implementación derivada. |

---

## Criterios de aceptación

1. **Proyecto nuevo**: al ejecutar el bootstrap en un proyecto nuevo, queda con:
   - Kit transversal sincronizado (`.github/`, `.opencode/`, `.doc_agents/`, `.specify`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`).
   - MCPs configurados y respondiendo.
   - Apps descargadas en `src\AppXXX\`.
   - `.specify` por app.
   - `Documentacion/<AppName>/` por app.
   - Spec-kit funcional orientado a la app activa.
2. **Idempotencia**: ejecutar el bootstrap dos veces seguidas produce el mismo estado sin errores ni cambios.
3. **`-DryRun`**: no escribe ningún archivo; solo muestra qué haría.
4. **Frontera respetada**: al sincronizar kit, **nada** dentro de `Documentacion/<AppName>/` se modifica.
5. **Resolución de app activa**: con `-App trading_bot` usa el `.specify` y `Documentacion/trading_bot/specs/`; con `cwd` dentro de `dwxconnect` usa los de `dwxconnect`; sin coincidencia usa `root`.
6. **`proyect_ext/spec-kit`**: permanece en la raíz; no se traslada a `src\`.
7. **`sync-agents.ps1`**: al invocarlo directamente, delega en `Sync-TransversalKit` con el mismo resultado que el bootstrap en su parte de sync.

---

## Diagrama Mermaid — Flujo del bootstrap

> Reutilizado del ADR-0003.

```mermaid
flowchart TD
    A[Invocar plataformador-bootstrap.ps1<br/>-DryRun / -Force / -App] --> B[Validar dependencias<br/>quitar o instalar según manifest]

    B --> C[Sync-TransversalKit<br/>clonar repo maestro shallow<br/>copiar .github .opencode .doc_agents<br/>.specify base AGENTS.md opencode.json README]
    C --> C1{NUNCA tocar<br/>Documentacion/&lt;AppName&gt;/}<br/>✓ respeta frontera

    C1 --> D[Configurar MCPs<br/>VS Code + OpenCode]
    D --> E[Crear/actualizar índices<br/>codebase-memory-mcp + context-mode]

    E --> F[Preparar estructura<br/>apps + proyect_ext + Documentacion/]

    F --> G[Resolver app activa]
    G --> G1{¿-App &lt;nombre&gt;?}
    G1 -->|Sí| G2[app = &lt;nombre&gt;]
    G1 -->|No| G3{¿cwd dentro de<br/>una app conocida?}
    G3 -->|Sí| G4[app = app del cwd]
    G3 -->|No| G5[app = root / kit]

    G2 --> H[Configurar Spec-kit<br/>.specify activo + Documentacion/&lt;App&gt;/specs/]
    G4 --> H
    G5 --> H

    H --> I[Instalar/configurar Graphify<br/>descargar desde git + validar licencia]
    I --> J[Verificar MCPs responden]
    J --> K{¿Flujo válido?}
    K -->|Sí| L[Reiniciar VS Code<br/>✅ Fin]
    K -->|No| M[Registrar fallo en pendientes<br/>y pedir spec a documental]
    M --> K
```

---

## Referencias

- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — ADR fuente de esta spec.
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Tarea `[PLATAFORMA]`.
- `.doc_agents/estructura-aplicacion.md` — Define que el kit se copia y `Documentacion/<AppName>/` NO se copia.
- `dependencias-manifest.yml` — Manifest de herramientas externas (patrón "descargar desde git").
- `sync-agents.ps1` — Queda como wrapper (Opción A).