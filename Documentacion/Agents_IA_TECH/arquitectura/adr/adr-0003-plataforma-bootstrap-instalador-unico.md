# ADR-0003: Plataforma Bootstrap — Instalador/Actualizador Único (Spec-kit + MCPs + Graphify)

> **Estado**: Aceptado
> **Fecha**: 2026-09-17
> **Decisión**: Unificar la instalación/actualización de Spec-kit, MCPs y Graphify en un único instalador `plataformador-bootstrap.ps1`, con modelo de apps independientes + orquestador, resolución de app activa por directorio de trabajo + flag `-App`, y absorción de la lógica de `sync-agents.ps1` como función `Sync-TransversalKit` (Opción A).
> **Autor**: `arquitecto` (Fase Documental — paso 1º)
> **Fuente del plan**: Plan aprobado por el usuario (2026-09-17) — Spec-kit + MCPs + Graphify en todos los proyectos

---

## Contexto y problema

El usuario administra **múltiples proyectos y apps independientes** (`dwxconnect`, `fibonacci-scanner`, `operation_mt5`, `Telegram`, `trading_bot`), cada una con su propio `.specify` (constitución y config particular), su `Documentacion/<AppName>/` (specs, ADRs, agents — **propia de la app**), y que **comparten un kit transversal** (`.github/`, `.opencode/`, `.doc_agents/`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`).

Hoy existen **dos scripts con responsabilidades superpuestas pero desconectadas**:

- **`plataformador-bootstrap.ps1`** (854 líneas): valida/quita dependencias, configura MCPs (VS Code + OpenCode), crea/actualiza índices (`codebase-memory-mcp` + `context-mode`), verifica MCPs, prepara estructura y reinicia VS Code.
- **`sync-agents.ps1`** (158 líneas): clona el repo maestro (shallow) y sincroniza SOLO el kit transversal, **nunca** `Documentacion/<AppName>/`.

Además, hay que integrar **Spec-kit** (CLI `specify` v1.0.0 en `C:\Users\tomas\.local\bin\specify.exe`) y **Graphify**, que deben instalarse y configurarse por proyecto y por app.

**Problemas concretos que motivan este ADR:**

1. **Dos puntos de entrada**: el usuario debe recordar cuándo correr `bootstrap` y cuándo `sync-agents`, y en qué orden — propenso a olvidos e inconsistencias.
2. **Spec-kit no está integrado en el flujo de bootstrap**: no hay un mecanismo que determine qué `.specify` y qué `Documentacion/<AppName>/` debe usar Spec-kit según la app activa.
3. **El kit transversal se copia entre proyectos pero la doc de app NO** — el bootstrap debe respetar esa frontera sin romperla.
4. **Descarga desde git** (`dependencias-manifest.yml` ya define el patrón "descargar desde git" para spec-kit, graphify, markitdown) requiere validación de URLs/licencias para evitar dependencias rotas o inseguras.
5. **La estructura difiere entre proyectos** (p. ej. `C:\Proyectos\Metatrader` tiene las apps en la raíz y `src\` vacía; el proyecto actual `Agents_IA_TECH` tiene la doc del kit en raíz) — el bootstrap debe ser **tolerante a esa variación** y nivelar hacia una estructura objetivo sin romper lo existente.

**Principio rector** (del plan aprobado):
> *"El bootstrap es el instalador/actualizador único del ecosistema: un solo script, determinista e idempotente, que lleva cualquier proyecto a la estructura objetivo sin tocar la documentación propia de cada app."*

---

## Decisión

Adoptar **`plataformador-bootstrap.ps1` como instalador/actualizador único** del ecosistema, bajo el siguiente modelo de arquitectura:

### 1. Modelo de apps independientes + orquestador

Cada app (`dwxconnect`, `fibonacci-scanner`, `operation_mt5`, `Telegram`, `trading_bot`) es una **aplicación independiente** con:

- Su propio `.specify` (constitución + configuración particular).
- Su propia `Documentacion/<AppName>/` (specs, ADRs, agents — **propia, no se copia**).

`trading_bot` **orquesta/consume** a las demás (lee sus datos, las invoca), pero sigue siendo una **app independiente** con su propio `.specify` y su propia doc. No es un "monolito padre": es un **orquestador entre pares**.

```
                    ┌─────────────────────────────┐
                    │  trading_bot  (orquestador)  │
                    │  .specify + Documentacion/   │
                    └──────┬──────┬──────┬─────────┘
              consume/    │      │      │
              invoca      ▼      ▼      ▼
                   ┌───────┐ ┌─────────┐ ┌────────────┐
                   │ dwxconnect │ operation_mt5 │ fibonacci-scanner │
                   └───────┘ └─────────┘ └────────────┘
                         ┌─────────┐
                         │ Telegram │  (app independiente más)
                         └─────────┘
```

### 2. Estructura objetivo

```
repo/
├── .github/                 ← kit transversal (copiado por Sync-TransversalKit)
├── .opencode/               ← kit transversal (copiado)
├── .doc_agents/             ← kit transversal (copiado)
├── .specify/                ← config speckit base (copiado, personalizable)
├── AGENTS.md, opencode.json, README.md, sync-agents.ps1 (wrapper)  ← kit transversal
│
├── src/AppXXX/              ← APPs (dwxconnect, fibonacci-scanner, operation_mt5, Telegram, trading_bot)
├── proyect_ext/             ← herramientas de apoyo (spec-kit, graphify) — NO se mueve a src\
│
├── Documentacion/           ← 🔒 INTERNA
│   ├── <dwxconnect>/        ← doc técnica PROPIA de la app
│   ├── <fibonacci-scanner>/ ← doc técnica PROPIA de la app
│   ├── ...                  ← una carpeta por app
│   └── <Agents_IA_TECH>/    ← doc del kit (este repo)
│
└── dependencias-manifest.yml ← manifest de herramientas externas
```

> **Nota de tolerancia**: `src\AppXXX\` es la **estructura objetivo**, pero el bootstrap **no fuerza** mover apps que ya viven en la raíz (p. ej. `C:\Proyectos\Metatrader`). Nivela de forma **idempotente**: respeta la ubicación existente, prepara estructura si falta, y nunca destruye código.

### 3. Mecanismo de resolución de rutas de Spec-kit por app activa

El bootstrap determina la **app activa** mediante dos señales (en orden de precedencia):

1. **Flag `-App <nombre>`** (precedencia máxima): resolución explícita.
2. **Directorio de trabajo actual (cwd)**: si el `cwd` (o un ancestro) está dentro de una app conocida, esa es la app activa.

La app activa define el par de rutas que usa Spec-kit:
- **`.specify` activo** → `<raizApp>/.specify/` (o `.specify/` de la raíz si la app no tiene el suyo).
- **`Documentacion/<AppName>/` activo** → `<raizRepo>/Documentacion/<AppName>/specs/` (donde Spec-kit escribe `spec.md`, `plan.md`, `tasks.md`).

```
Resolver-AppActiva:
  si  -App <nombre>          → app = <nombre>
  sino si cwd ∈ <app conocida> → app = <app del cwd>
  sino                          → app = "root" (kit, sin doc de app)

Derivar-rutas(app):
  specify_path      = <raizApp>/.specify/              (o raíz/.specify/ si no existe)
  doc_espec_path    = <raizRepo>/Documentacion/<app>/specs/
```

### 4. Fusión de `sync-agents.ps1` (Opción A)

La lógica de sincronización del kit transversal se **absorbe** dentro de `plataformador-bootstrap.ps1` como función **`Sync-TransversalKit`**:

- Clona el repo maestro (`https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`) de forma **shallow**.
- Copia SOLO los transversales: `.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md` (base), `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`.
- **NUNCA toca** `Documentacion/<AppName>/` de ninguna app.
- Soporta `-DryRun` (simula) y `-Force` (fuerza sobrescritura).

`sync-agents.ps1` queda como **wrapper** que delega en `Sync-TransversalKit`, preservando compatibilidad para quien lo invoque directamente.

---

## Consecuencias

### Positivas

- **Un solo punto de entrada**: `plataformador-bootstrap.ps1` cubre sync del kit + MCPs + índices + Spec-kit + Graphify. El usuario corre un solo script.
- **Determinista e idempotente**: repetir la ejecución no rompe nada; los mismos pasos producen el mismo resultado.
- **Apps aisladas y reutilizables**: cada app tiene su `.specify` y doc propia; `trading_bot` las consume como orquestador sin acoplarlas.
- **Resolución de app activa clara**: el usuario elige con `-App` o por directorio; el bootstrap sabe qué `.specify` y qué `Documentacion/<AppName>/` usar.
- **Frontera kit ↔ app respetada**: la sincronización nunca pisa la doc de app, preservando el principio de `estructura-aplicacion.md`.
- **Nivelación tolerante**: apps en raíz o en `src\AppXXX\` se manejan sin destruir estructura existente.
- **Espec-kit integrado**: la CLI `specify` se configura y se orienta a la app activa en el mismo flujo.

### Negativas / Trade-offs

- **Complejidad del script**: `plataformador-bootstrap.ps1` crece mucho (854 + lógica de sync + resolución de app + Spec-kit + Graphify), lo que aumenta el riesgo de bugs y hace más difícil su mantenimiento.
- **Riesgo de romper la estructura existente**: al fusionar dos scripts y nivelar apps, un error de rutas podría tocar `Documentacion/<AppName>/` o mover archivos de forma incorrecta — por eso los guardrails son obligatorios.
- **Acoplamiento entre responsabilidades**: sync, MCPs, índices y Spec-kit en un solo script implican que un fallo en un módulo afecta el flujo completo (mitigable con funciones modulares y `-DryRun`).
- **Dependencia del repo maestro**: si la URL `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH` cambia o no es accesible, la sincronización falla (mitigable validando la URL antes del clone).

---

## Guardrails (restricciones que el código/agentes deben cumplir)

> Definidos por el `arquitecto` para la fase de implementación. Todo agente que implemente este ADR debe respetarlos.

1. **`Documentacion/<AppName>/` es sagrada**: al sincronizar el kit transversal (función `Sync-TransversalKit`), **NUNCA** se copia, sobrescribe ni borra nada dentro de `Documentacion/<AppName>/`. Solo se copian los transversales listados.
2. **No mover `proyect_ext/spec-kit`**: `proyect_ext/` aloja herramientas de apoyo (spec-kit, graphify) y **permanece en la raíz**; **no** se traslada a `src\`. `src\AppXXX\` es solo para las apps.
3. **Validar URLs y licencias al descargar desde git**: antes de clonar o descargar una herramienta, validar que la URL sea HTTPS/GitHub confiable y registrar la **licencia** en `dependencias-manifest.yml`. No descargar herramientas sin origen verificado.
4. **Resolución de app activa predecible**: la precedencia es `-App` > `cwd`. Nunca se infiere la app activa de forma ambigua; si no hay coincidencia, se usa el modo `root` (kit) sin doc de app.
5. **Idempotencia**: repetir el bootstrap no debe producir cambios ni errores. Toda operación debe ser comprobable (existe? actualizar si difiere).
6. **`-DryRun` siempre disponible**: la función `Sync-TransversalKit` y el bootstrap completo deben soportar `-DryRun` para simular antes de escribir.
7. **No romper estructura existente**: al nivelar apps, se **respeta la ubicación actual** (raíz o `src\AppXXX\`). Nunca se destruye código, `src/`, `tests/` ni `Documentacion/` de app.
8. **Idioma de contenido**: contenido técnico del ADR en inglés; títulos y resúmenes en español/inglés según `Documentacion/Agents_IA_TECH/idioma.md`.
9. **Frontera de responsabilidad**: `plataformador-bootstrap.ps1` no modifica código fuente de apps; solo prepara estructura, configura MCPs/índices/Spec-kit/Graphify y sincroniza el kit transversal.
10. **Conventional commits**: toda implementación que derive de este ADR debe usar commits convencionales (`feat`, `fix`, `refactor`, `docs`, `chore`).

---

## Spec linking (trazabilidad)

| Artefacto | Relación con este ADR |
|-----------|----------------------|
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` | ADR previo del pipeline de herramientas sin IA; este ADR integra esas herramientas (Spec-kit, Graphify, MCPs) en el bootstrap. |
| `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0002-flujos-kit.md` | ADR de flujos (contexto + actualización de herramientas); el bootstrap automatiza la instalación/configuración de esas herramientas. |
| `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` | Tareas del plan aprobado (Spec-kit + MCPs + Graphify) de las que deriva este ADR. |
| `.doc_agents/estructura-aplicacion.md` | Define que el kit se copia y `Documentacion/<AppName>/` NO se copia; este ADR implementa esa frontera en el bootstrap. |
| `.doc_agents/capacidad-base.md` | Catálogo del kit transversal que `Sync-TransversalKit` sincroniza. |
| `dependencias-manifest.yml` | Manifest de herramientas externas (spec-kit, graphify, markitdown) que el bootstrap descarga/valida y registra. |
| `scripts/plataformador-bootstrap.ps1` | Script objetivo que implementa este ADR (instalador/actualizador único + `Sync-TransversalKit`). |
| `sync-agents.ps1` | Queda como wrapper que delega en `Sync-TransversalKit` (Opción A). |
| `Documentacion/Agents_IA_TECH/agents/plataformador/spec.md` | Spec del agente que opera el bootstrap y valida la estructura. |

---

## Diagrama Mermaid — Flujo del bootstrap como instalador/actualizador único

> Flujo: sync kit → config MCPs → indexar → preparar apps → resolver app activa → validar flujo.

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

## Plan de implementación por fases

### Fase documental (siguiente paso: `documentador`)

| Orden | Agente | Acción |
|-------|--------|--------|
| 1º | `arquitecto` | ✅ **Este ADR** (instalador único, apps + orquestador, resolución de app activa, fusión `Sync-TransversalKit`, guardrails, spec linking, diagrama, plan). |
| 2º | `documentador` | Documentar el flujo del bootstrap en las specs de `plataformador` y actualizar `00-indice.md` y `memoria-proyecto.md`. Reutilizar el diagrama Mermaid. |
| 3º | `security-auditor` | Revisar implicaciones de seguridad (descarga desde git, validación de URLs/licencias, no exponer credenciales). |

### Fase implementación

| Orden | Agente | Acción |
|-------|--------|--------|
| 4º | `plataformador` | Refactorizar `plataformador-bootstrap.ps1`: agregar `Sync-TransversalKit`, resolución de app activa (`-App` + `cwd`), integración de Spec-kit y Graphify, respetando todos los guardrails. |
| 5º | `devops` | Convertir `sync-agents.ps1` en wrapper que delega en `Sync-TransversalKit`. |
| 6º | `qa-senior` | Probar idempotencia, `-DryRun`, resolución de app activa y no-tocar-`Documentacion/<AppName>/` en un proyecto real (p. ej. `C:\Proyectos\Metatrader`). |
| 7º | `gitflow` | Commits convencionales. |

### Fase validación

| Orden | Acción |
|-------|--------|
| 8º | Ejecutar `.\plataformador-bootstrap.ps1 -DryRun` en `C:\Proyectos\Agents_IA_TECH` y `C:\Proyectos\Metatrader`; verificar que no toca `Documentacion/<AppName>/`. |
| 9º | Ejecutar sin `-DryRun`; verificar Spec-kit orientado a la app activa y Graphify configurado. |
| 10º | Correr `npx ecc-agentshield scan` para validar seguridad de los cambios en `.github/`. |

---

## Referencias

- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` — Pipeline de documentación sin IA.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0002-flujos-kit.md` — Flujos del kit (contexto + actualización de herramientas).
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — Puente docs ↔ código (tarea Spec-kit + MCPs + Graphify).
- `.doc_agents/estructura-aplicacion.md` — Estructura de documentación por aplicación (kit se copia, doc de app no).
- `scripts/plataformador-bootstrap.ps1` — Script objetivo del instalador único.
- `sync-agents.ps1` — Wrapper que delega en `Sync-TransversalKit`.
- `dependencias-manifest.yml` — Manifest de herramientas externas (patrón "descargar desde git").