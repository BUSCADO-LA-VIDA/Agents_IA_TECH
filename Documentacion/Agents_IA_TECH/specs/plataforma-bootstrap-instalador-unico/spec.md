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
| **RF-12** | **Manejo de huérfanos** | Al sincronizar, detectar **huérfanos** (existen en `.github/` `.opencode/` `.doc_agents/` local pero ya no existen en el clon maestro shallow) y **PREGUNTAR** al usuario por cada caso (o en lote): **¿borrar o conservar?** La implementación siempre queda limpia; la diferencia es si hay respaldo o no. **Borrar**: elimina los huérfanos. **Conservar**: mueve cada huérfano a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` (fuera de los directorios de agentes, preservando la estructura de carpetas donde estaba; si la carpeta del día existe → sufijo de hora) y luego **informa** al usuario qué se movió y dónde quedó. **Alcance**: solo archivos no propios o personalizados que causan conflicto (opción "omitir" = dejarlo en su lugar por ser propio). **Nunca** `Documentacion/<AppName>/`. **Default seguro** (sin flag ni respuesta): **conservar** (jamás auto-borrar). Flag `-OrphanAction Borrar\|Conservar\|Preguntar` para modo no interactivo. En `-DryRun`: solo informa, no borra ni mueve. |
| **RF-13** | **Script standalone de reubicación a `src\` (`relocate-apps-to-src.ps1`)** | Script **NUEVO e independiente** `scripts/relocate-apps-to-src.ps1` (tarea `[RELOCATE]`, decisión 2026-09-19). **Cero cambios al bootstrap en esta tarea** (`plataformador-bootstrap.ps1` intacto; su `Prepare-Apps` sigue en modo tolerante RNF-04: solo informa y respeta la ubicación existente). Funciones: **`Move-AppToSrc`** (mueve una app de la raíz a `src\<App>` con pre-chequeos, log y reporte post-movido) + **`Confirm-AppRelocation`** (confirmación SIEMPRE obligatoria, sin bypass). Flags: **`-AppDirs @()`** (lista de carpetas de app a reubicar; vale para cualquier proyecto, o manifest), **`-DryRun`** (solo previsualiza, cero escrituras), **`-ProjectRoot`** (raíz del proyecto; default: padre de `scripts/`). **SIN flag que saltee la confirmación** (por diseño). **Confirmación**: interactivo → pregunta por app **`[S]í mover / [N]o dejar / [T]odos los restantes / [C]ancelar todo`**; no interactivo (sin consola) → **NO mueve, informa**; `-DryRun` → solo previsualiza. **`.venv`**: se mueve con la app pero se REPORTA como **"a recrear"** con comandos exactos (sus paths absolutos internos quedan rotos); no se recrea solo. **Controles**: pre-chequeos por app (origen existe, destino libre, tamaño informado, git limpio recomendado); log de cada movido (origen → destino + fecha); **rollback manual documentado** (mover de vuelta `src\<App>` → raíz); post-movido advierte **imports/paths/configs + tests** a revisar; **nunca toca `Documentacion/`**. **Punto futuro de integración** (decisión separada, solo tras validación OK): invocar este script desde el bootstrap; hasta entonces se usa standalone. |
| **RF-14** | **Auto-desactivar/reactivar venv + pausar git (`Suspend-AppLocks` + `Restore-AppLocks`)** | Extensión de `[RELOCATE]` (plan aprobado 2026-09-19). Funciones: **`Suspend-AppLocks`** (antes de mover: desactiva el venv en-sesión con confirmación + detiene `git.exe` puntuales con cwd verificado dentro de la app a mover, con confirmación; nunca el proceso `Code`) + **`Restore-AppLocks`** (tras mover: recrea el venv con confirmación si fue movido + activa el nuevo `src\<App>\.venv`; si la app no se movió, reactiva el mismo; git se redescubre solo, se informa). **Cada acción pregunta** (desactivar, pausar, recrear, reactivar); **sin bypass**; **`-Force` no aplica** a estas acciones; **No a todo = avisos** (comportamiento actual, el movido sigue con locks activos bajo responsabilidad del usuario); **`-DryRun` informa, no muta**. **Mutar la sesión del llamante es comportamiento esperado y documentado** (`deactivate`/`Activate.ps1` corren en la misma sesión del script). |
| **RF-15** | **Limpieza de regenerables (`Find-RegenerableDirs` + `Clear-RegenerableDirs`)** | Extensión de `[RELOCATE]` (plan aprobado 2026-09-19; decisión explícita: **`.venv` se ELIMINA por comando, no se mueve**; se recrea después en `src\<App>`). Funciones: **`Find-RegenerableDirs`** (escanea apps candidatas contra allowlist de nombres exactos + mide tamaños) + **`Clear-RegenerableDirs`** (elimina con confirmación global única, log de lo eliminado, sin respaldo por ser regenerables). **Allowlist fija**: Python `__pycache__`, `.pytest_cache`, `*.egg-info`, `.mypy_cache`, `.ruff_cache`, `build`, `dist`; Node `node_modules`, `.next`, `dist`, `build`, `coverage`; general `.cache`; **más `.venv/`** (eliminar, no mover; recrear después en `src\<App>`). **Orden**: pregunta global de limpieza ANTES de las confirmaciones S/N/T/C por app; si dice No → mueve todo (comportamiento anterior). **`.venv` activo en terminal → exigir `deactivate` primero** (ver RF-14, no se duplica). **Tras mover**: informe con comandos de recreación (`python -m venv .venv` + `pip install -r requirements.txt`) en la ruta nueva `src\<App>\`. **Nunca `Documentacion/`**; **`-DryRun` informa, no borra**. |
| **RF-16** | **Registrar tokenslayer como 4º MCP (`Ensure-OpenCodeMcp`)** | Extensión (plan aprobado 2026-09-19; gap detectado en auditoría real de Metatrader: el bootstrap solo registraba 3 MCPs). `Ensure-OpenCodeMcp` registra `tokenslayer` como 4º MCP (`type: local`, `command: [node, <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js]`, `enabled: true`; fuente del binario: entrada `tokenslayer-mcp-server` en `dependencias-manifest.yml`). Si el binario no existe → WARN + instrucciones de compilar (`cd mcp-server && npm install && npm run build`), no falla. Firmas/estilo existentes intactos (`Add-Member -Force`, `Write-*`, `-DryRun` informa). |
| **RF-17** | **Plantilla `.opencode/config.json` (`Ensure-OpenCodeConfig`)** | Extensión (plan aprobado 2026-09-19; gap auditoría Metatrader: sin plantilla versionada). `Ensure-OpenCodeConfig` crea `.opencode/config.json` SOLO si no existe, desde plantilla con PLACEHOLDERS (jamás secrets reales); si existe → no lo toca nunca. El archivo sigue gitignored. Documenta qué keys pone el usuario a mano (API keys / credenciales locales). `-DryRun` informa, no escribe. |
| **RF-18** | **Reorganizar docs sueltas (`Repair-DocStructure`)** | Extensión (plan aprobado 2026-09-19; gap auditoría Metatrader: docs sueltas en raíz fuera de `Documentacion/<App>/`). `Repair-DocStructure` mueve docs sueltas de raíz (`00-indice.md`, `pendientes-*.md`, etc.) a su `Documentacion/<App>/` correspondiente con confirmación por archivo (S/N/T/C como relocate, sin bypass). Archivos >50KB o con tracking vivo (ej. pendientes de 87KB) SOLO se listan, jamás se mueven sin OK explícito individual. Nunca borra. `-DryRun` informa. |

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
8. **Huérfanos**: al sincronizar con huérfanos locales (existen en `.github/` `.opencode/` `.doc_agents/` pero no en el maestro), el script pregunta **¿borrar o conservar?**; con **Borrar** los elimina (limpio sin respaldo), con **Conservar** (default seguro) los mueve a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` preservando estructura e informa qué se movió y dónde; con `-DryRun` solo informa sin borrar ni mover; nunca toca `Documentacion/<AppName>/`.
9. **Reubicación standalone (`relocate-apps-to-src.ps1`)**: con `-DryRun` solo previsualiza (cero escrituras); en modo real interactivo pregunta por app **S/N/T/C** y solo mueve lo confirmado (sin flag de bypass); en modo no interactivo NO mueve e informa; `.venv` se mueve con la app pero se reporta "a recrear" con comandos exactos; cada movido queda en log (origen → destino + fecha) con rollback manual documentado; post-movido advierte imports/paths/configs + tests; nunca toca `Documentacion/`; el bootstrap queda intacto.
10. **Auto-desactivar/reactivar venv + pausar git (`Suspend-AppLocks` + `Restore-AppLocks`)**: cada acción pregunta (desactivar, pausar, recrear, reactivar), sin bypass y `-Force` no aplica; `Suspend-AppLocks` desactiva el venv en-sesión con confirmación y detiene solo `git.exe` puntuales con cwd verificado en la app (nunca `Code`); `Restore-AppLocks` recrea el venv con confirmación si fue movido y activa el nuevo `src\<App>\.venv` (si no se movió, reactiva el mismo); git se redescubre solo y se informa; No a todo = avisos (comportamiento actual); `-DryRun` informa sin mutar; mutar la sesión del llamante (`deactivate`/`Activate.ps1`) es comportamiento esperado y documentado.
11. **Limpieza de regenerables (`Find-RegenerableDirs` + `Clear-RegenerableDirs`)**: pregunta global de limpieza ANTES de las confirmaciones S/N/T/C por app (si dice No → mueve todo, comportamiento anterior); solo nombres exactos de la allowlist fija (Python + Node + general + `.venv/`); `.venv` se ELIMINA por comando, no se mueve, y se recrea después en `src\<App>` (si activo → `deactivate` previo obligatorio, ver RF-14); elimina con log y sin respaldo; tras mover informa comandos de recreación (`python -m venv .venv` + `pip install -r requirements.txt`) en la ruta nueva; nunca toca `Documentacion/`; `-DryRun` informa, no borra.
12. **Tokenslayer 4º MCP (`Ensure-OpenCodeMcp`, RF-16)**: tras el bootstrap, `opencode.json` incluye `tokenslayer` (`type: local`, `command: [node, <repo>/proyect_ext/tokenslayer/mcp-server/build/index.js]`, `enabled: true`); si el binario no existe, avisa WARN con instrucciones de compilar y no falla; firmas/estilo existentes intactos.
13. **Plantilla `.opencode/config.json` (`Ensure-OpenCodeConfig`, RF-17)**: si no existe, se crea desde plantilla con PLACEHOLDERS (sin secrets reales); si existe, no se modifica nunca; el archivo sigue gitignored; `-DryRun` solo informa.
14. **Reorganización de docs sueltas (`Repair-DocStructure`, RF-18)**: con `-DryRun` solo informa; en modo real pide confirmación por archivo (S/N/T/C, sin bypass); archivos >50KB o con tracking vivo (ej. pendientes de 87KB) solo se listan y jamás se mueven sin OK explícito individual; nunca borra nada.

---

## Diagrama Mermaid — Flujo del bootstrap

> Reutilizado del ADR-0003.

```mermaid
flowchart TD
    A[Invocar plataformador-bootstrap.ps1<br/>-DryRun / -Force / -App] --> B[Validar dependencias<br/>quitar o instalar según manifest]

    B --> C[Sync-TransversalKit<br/>clonar repo maestro shallow<br/>copiar .github .opencode .doc_agents<br/>.specify base AGENTS.md opencode.json README]
    C --> C1{NUNCA tocar<br/>Documentacion/&lt;AppName&gt;/}<br/>✓ respeta frontera

    C1 --> C2[Detectar huérfanos<br/>existen local no en maestro<br/>.github .opencode .doc_agents]
    C2 --> C3{¿Huérfanos?}
    C3 -->|No| D[Configurar MCPs<br/>VS Code + OpenCode]
    C3 -->|Sí| C4{¿-OrphanAction?<br/>Preguntar por defecto}
    C4 -->|Preguntar| C5[Preguntar borrar / conservar<br/>default seguro Conservar<br/>omitir = propio en su lugar]
    C4 -->|Borrar| C6[Eliminar huérfanos<br/>limpio sin respaldo]
    C4 -->|Conservar| C7[Mover a revisar_manualmente/yyyymmdd/<br/>estructura original + informar]
    C5 -->|Borrar| C6
    C5 -->|Conservar / Omitir| C7
    C5 -->|DryRun| C8[Solo informa<br/>no borra ni mueve]
    C6 --> D
    C7 --> D
    C8 --> D
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