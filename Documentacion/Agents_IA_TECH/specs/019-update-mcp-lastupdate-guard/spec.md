# Feature Specification: 019-update-mcp-lastupdate-guard — Get-State de update-mcp.ps1 nunca devuelve array ni formas inválidas

**Feature Branch**: `019-update-mcp-lastupdate-guard`

**Created**: 2026-10-09

**Status**: Draft

**Input**: Reporte de usuario aprobado 2026-10-09 — `scripts/update-mcp.ps1` falla con `No se encuentra la propiedad "lastUpdate" en este objeto` en toda ejecución real cuando `.bootstrap-state.json` ya existe (aunque su contenido sea un objeto válido), y el bootstrap invoca al script con un flag muerto `-Quick` que el script no declara.

---

## Problema

`scripts/update-mcp.ps1` (versión vigente de 33 líneas) falla el 100% de las ejecuciones reales cuando `.bootstrap-state.json` ya existe, con el error:

```text
InvalidOperation: scripts/update-mcp.ps1:30:19
$state.lastUpdate=$now.ToString("o")
No se encuentra la propiedad "lastUpdate" en este objeto. Compruebe que la propiedad existe y se puede establecer.
```

Solo sobrevive el primer arranque (archivo inexistente) y la salida temprana `UP_TO_DATE` (archivo fresco, línea 18), porque ambos caminos nunca llegan a la asignación de la línea 30.

### Causa raíz (verificada en vivo)

`Get-State` está escrita así:

```powershell
function Get-State{ if(Test-Path $StateFile){ try{ Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ return $null } } return $null }
```

El `return $null` final **sí emite `$null`** al flujo de salida. Cuando el archivo existe y parsea bien, la función devuelve **dos** valores (objeto parseado + `$null`), que PowerShell empaqueta como `System.Object[]`. Evidencia en vivo (2026-10-09):

```text
tipo: System.Object[]
es-array: True
tiene-prop: False
```

La cadena de fallo: el guard `if(-not $state)` ve un array no vacío (truthy) y no re-inicializa; la lectura `$state.lastUpdate` usa enumeración de miembros y no revienta; la **asignación** `$state.lastUpdate=...` intenta escribir en cada elemento y revienta en el elemento `$null`.

Efecto colateral: con contenido corrupto pero truthy (string/number/array JSON no vacío) ocurre el mismo error, y el archivo jamás puede auto-sanarse porque toda escritura pasa por la línea 30.

### Hallazgos de la validación en vivo (2026-10-09, todos reproducidos)

1. **El guard por tipo `-isnot [PSCustomObject]` NO es fiable** con valores deserializados: un `String` devuelto por `ConvertFrom-Json` (array JSON de un elemento `["x"]` desenvuelto) responde `-is [PSCustomObject] = True` aunque `GetType()` dice `System.String` (verificado: `tipo=System.String isnot=False is=True`). El guard final es **por forma**: exigir la propiedad `lastUpdate` (`$parsed.PSObject.Properties['lastUpdate']`), que sí discrimina en ambas direcciones (falso para primitivas/arrays, verdadero para el objeto válido).
2. **`ConvertFrom-Json` convierte el ISO de `lastUpdate` a `[DateTime]`** (verificado: `prop-tipo: System.DateTime`, cultura del hilo `es-ES`). Entonces `[DateTime]::Parse($state.lastUpdate)` hace doble conversión (DateTime → string invariant `10/09/...` → parse es-ES = 10-sep) y la ventana de 24h **nunca** se cumple: toda corrida hace trabajo completo. El parse debe aceptar `DateTime` directo (FR-002).

### Hallazgo secundario

El bootstrap invoca `& $updateScript -Quick` (cola de `plataformador-bootstrap.ps1`), pero `update-mcp.ps1` no declara `-Quick`. En scripts no-avanzados (sin `[CmdletBinding()]`) el flag desconocido se ignora en silencio (verificado en vivo), así que no rompe nada, pero es lastre de una versión anterior y confunde (la interfaz vigente es sin parámetros / `-DryRun` / `-Force`).

---

## Objetivos

- **Q001**: `Get-State` devuelve siempre `$null` o un objeto con la propiedad `lastUpdate`; jamás un array ni formas primitivas (guard por forma, no por tipo).
- **Q002**: Con archivo corrupto pero truthy, el script re-inicializa el estado y completa (auto-sanado) en vez de reventar.
- **Q003**: Eliminar el flag muerto `-Quick` de la invocación del bootstrap.
- **Q004**: Verificar con ejecución real (archivo stale → verifica + guarda + reporta, exit 0), con archivo envenenado (`["x"]` → re-inicializa + completa) y con archivo fresco (salida temprana `UP_TO_DATE`).
- **Q005**: El parse de `lastUpdate` acepta valor `[DateTime]` directo para que la ventana de 24h funcione (sin doble conversión cultural).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ejecución real con estado existente (Priority: P1)

**Actor**: Usuario / bootstrap (llamada de cola).

**Flujo**: Con `.bootstrap-state.json` existente y viejo (>24h), se ejecuta `pwsh scripts/update-mcp.ps1` y el script verifica rutas, guarda el nuevo `lastUpdate`, imprime el reporte y termina con exit 0.

**Criterio de aceptación**: La ejecución que antes fallaba en la línea 30 ahora completa; el `lastUpdate` del archivo queda con fecha de hoy.

**Acceptance Scenarios**:
1. **Given** `.bootstrap-state.json` existente con `lastUpdate` de hace >24h, **When** se ejecuta `update-mcp.ps1`, **Then** termina con exit 0, el reporte se imprime y `lastUpdate` queda actualizado.
2. **Given** `.bootstrap-state.json` inexistente, **When** se ejecuta `update-mcp.ps1`, **Then** se crea con la fecha actual (comportamiento original preservado).

---

### User Story 2 - Auto-sanado ante estado corrupto (Priority: P2)

**Actor**: Sistema.

**Flujo**: Con `.bootstrap-state.json` corrupto pero truthy (ej. `["x"]`), se ejecuta `update-mcp.ps1` y el script re-inicializa el estado en vez de reventar.

**Criterio de aceptación**: Exit 0 y el archivo queda como objeto válido `{lastUpdate, tools}`.

**Acceptance Scenarios**:
1. **Given** `.bootstrap-state.json` con contenido `["x"]`, **When** se ejecuta `update-mcp.ps1 -Force`, **Then** termina con exit 0 y el archivo queda re-inicializado como objeto válido.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `Get-State` DEBE devolver `$null` cuando el archivo no existe, no parsea, o el valor parseado no trae la propiedad `lastUpdate` (guard por forma: `$parsed.PSObject.Properties['lastUpdate']`); en cualquier otro caso DEBE devolver el objeto tal cual (sin envoltorios).
- **FR-002**: El parse de `lastUpdate` DEBE aceptar valor `[DateTime]` directo (lo que devuelve `ConvertFrom-Json`) sin re-parsearlo, para que la ventana de 24h se evalúe sobre el instante real.
- **FR-003**: El script DEBE completar la escritura de `lastUpdate` (línea 30) en toda ejecución real con estado válido o re-inicializado.
- **FR-004**: La invocación de cola del bootstrap NO DEBE pasar flags inexistentes (`-Quick` se elimina; llamada sin argumentos).
- **FR-005**: El comportamiento `-DryRun`, la salida temprana `UP_TO_DATE` y el formato de reporte `MCP_NAME | ESTADO | VERSION | RUTA | NOTA` NO cambian.

### Key Entities

- **`scripts/update-mcp.ps1`**: Script de ciclo de vida de MCPs (funciones `Get-State`/`Save-State`, guard de 24h).
- **`.bootstrap-state.json`**: Estado runtime gitignored con `lastUpdate` ISO8601 y `tools`.
- **`plataformador-bootstrap.ps1` (cola)**: Invocación `& $updateScript` sin flags muertos.

### Criterios de Éxito *(mandatory)*

#### Resultados Medibles

- **SC-001**: Ejecución real con estado stale termina con exit 0, imprime reporte y actualiza `lastUpdate` (antes: error en línea 30, exit 1).
- **SC-002**: Ejecución con estado envenenado (`["x"]`) termina con exit 0 y deja objeto válido.
- **SC-003**: `Parser::ParseFile` de `update-mcp.ps1` reporta 0 errores.
- **SC-004**: El bootstrap ya no referencia `-Quick` en ninguna invocación.

---

## Edge Cases

- **EC-01**: Archivo con `{}` (objeto vacío): no trae `lastUpdate` → `Get-State` devuelve `$null` → re-inicializa con fecha actual. Completa sin error (auto-sanado, mismo resultado que la asignación directa).
- **EC-02**: Archivo con `[]` (array vacío): es falsy → el guard existente re-inicializa. Sin cambios.
- **EC-03**: Archivo con string/número/array no vacío: `Get-State` devuelve `$null` (FR-001) → re-inicializa. Auto-sanado.
- **EC-04**: Archivo con JSON inválido: `catch` → `$null` → re-inicializa (comportamiento original preservado).

---

## Assumptions

- PowerShell 7+ (`pwsh`). El script es no-avanzado (sin `[CmdletBinding()]`).
- `.bootstrap-state.json` es runtime local gitignored; su esquema válido es objeto con `lastUpdate` y `tools`.
- El fix no cambia el protocolo de 24h ni el formato de reporte (spec 002/009 lo referencian).

---

## Fuera de Alcance

- Reescribir `update-mcp.ps1` más allá del guard de `Get-State` y la llamada del bootstrap.
- Cambiar la ventana de 24h, el inventario `.env.mcp` o el registro de MCPs.
- El error `lastUpdate` en copias del script dentro de proyectos consumidores (cada proyecto se actualiza vía sync del kit).

---

## Dependencias

- `scripts/update-mcp.ps1` — función `Get-State` (línea 9) y llamada de cola del bootstrap (línea ~2888).
- `scripts/plataformador-bootstrap.ps1` — invocación `& $updateScript -Quick` a corregir.
- `.bootstrap-state.json` — archivo de estado del proyecto donde se ejecute.
