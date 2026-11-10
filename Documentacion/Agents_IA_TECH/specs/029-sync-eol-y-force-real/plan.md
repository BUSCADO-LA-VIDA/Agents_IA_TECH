# Plan 029 - Sync honesto: EOL normalizado y `-Force` efectivo

**Spec**: `Documentacion/Agents_IA_TECH/specs/029-sync-eol-y-force-real/spec.md`
**Fecha**: 2026-10-27
**Estado**: propuesto (pendiente de aprobacion)
**Constitution aplicable**: `.specify/memory/constitution.md` (nivel 1, v2.0.0 con tabla malformada) y `Documentacion/Agents_IA_TECH/.specify/constitution.md` (nivel 2, **v2.1.0**, reconciliada hoy)
**Tier del que escribe este plan**: Documental (`pensador`) -> solo `Documentacion/`. **La implementacion NO la puede hacer el `pensador`**: `scripts/` esta fuera de su whitelist (Art. VII).

---

## 1. Contexto tecnico

### 1.1 Motor real del sync (verificado, no asumido)

Hay **dos** motores de sync en el repo y solo uno esta cableado:

| Motor | Entrypoint | Cableado | Estado |
|---|---|---|---|
| `scripts/sync-kit.ps1` (37.660 B) | `sync-agents.ps1` L47 (`Join-Path $PSScriptRoot "scripts\sync-kit.ps1"`) | **Si** — es el que corre el usuario | Marcado `[021-DEPRECATED]` en L3, pero vivo |
| `scripts/sync-kit-agents.ps1` (19.465 B) + `scripts/sync/*` (13 capas) | ninguno | **No** — cero referencias en `plataformador-bootstrap.ps1`, `sync-agents.ps1` ni `README.md` | Flujo 021 sin cablear |

Consecuencia directa para el plan: **solo `scripts/sync-kit.ps1` produce el defecto reportado hoy**. El flujo 021 queda fuera del alcance por evidencia, no por opinion (ver D-02).

### 1.2 Evidencia medida del defecto (2026-10-27, este repo)

`git ls-files --eol` sobre los transversales que se comparan por hash:

| Archivo | Index | Worktree | Atributo | Lectura |
|---|---|---|---|---|
| `opencode.json` | `lf` | **`crlf`** | `text eol=lf` | El sync lo reescribe en CRLF; git lo normaliza al commitear. `Get-FileHash` nunca coincide |
| `AGENTS.md` | `lf` | **`mixed`** | `text eol=lf` | 1 CRLF suelto: **tambien** falso positivo permanente |
| `.specify/memory/constitution.md` | `lf` | **`mixed`** | `text eol=lf` | 2 CRLF sueltos: **tambien** falso positivo permanente |
| `README.md` | `lf` | `lf` | `text eol=lf` | Sin deriva: reporta `[OK]` |
| `.opencode/.gitignore` | `lf` | `crlf` | *(sin atributo)* | `core.autocrlf=true` produce CRLF en ambos lados: hoy coincide por casualidad del entorno, no por diseno |
| `sync-agents.ps1` | `lf` | `crlf` | *(sin atributo)* | Idem: coincide por `autocrlf`, no se compara por hash de archivo |

Prueba de que la diferencia es **solo** de fin de linea: `git diff --stat` y `git status --porcelain` sobre esos cuatro archivos devuelven **vacio / LIMPIO**. Git normaliza; `Get-FileHash` no.

Medido: `opencode.json` local = 2.569 B / 102 CRLF; normalizado = 2.467 B / 0 CRLF. La diferencia de 102 bytes es exactamente un `\r` por linea.

**El defecto es mas ancho que lo que decia la spec**: no es un archivo, son **tres** silenciados en cada corrida (`opencode.json`, `AGENTS.md`, `.specify/memory/constitution.md`). El fix los resuelve a los tres con el mismo cambio.

### 1.3 Restricciones que acotan el diseno

| Fuente | Restriccion | Efecto en el plan |
|---|---|---|
| ADR-0009 + ADR-0010 R4 | Las rutas de MCP son absolutas y por maquina | El guard del bloque `mcp` **no se toca** (FR-05, FA-01) |
| `.gitattributes` | `*.json text eol=lf`, `*.md text eol=lf` | LF es el formato canonico: escribir LF no genera diff |
| `core.autocrlf=true` en este entorno | Checkout convierte a CRLF lo que no tiene atributo | Explica la asimetria `opencode.json` (atributo) vs `.gitignore` (sin atributo) |
| NFR-04 de la spec | Solo `\r\n` -> `\n` | Nada de trim, colapso de lineas ni reordenar claves |
| `scripts/sync-kit-files.ps1` L8-9 | El flujo 021 **excluye `scripts/sync/`** al copiar `scripts/` | Un helper nuevo en `scripts/sync/lib/` **no viajaria** a los consumidores (ver D-01) |
| PowerShell 7 / `#requires -Version 7.0` | `[Convert]::ToHexString`, ternario `? :`, UTF-8 sin BOM | API disponible sin dependencias |

---

## 2. Decisiones de diseno

### D-01 - El helper va en `scripts/sync-kit-lib.ps1`, no en `scripts/sync/lib/`

`scripts/sync/lib/common.ps1` parece el lugar natural, pero `sync-kit-files.ps1` L8-9 documenta que la capa `kit-files` copia `<Stage>/scripts/` **excluyendo `scripts/sync/`** para no auto-sobrescribirse. Si el helper viviera ahi:

- el flujo 021 jamas lo copiaria a un consumidor;
- un consumidor con `sync-kit.ps1` nuevo (que si viaja, esta en la raiz de `scripts/`) haria dot-source de un archivo inexistente y **moriria** por `$ErrorActionPreference = "Stop"`.

`scripts/sync-kit-lib.ps1` es hermano del motor, viaja con el en cualquier flujo, y no colisiona con la exclusion del 021.

### D-02 - Solo se toca `scripts/sync-kit.ps1` (+ su lib). `scripts/sync/*` queda fuera

Evidencia, no comodidad:

1. El flujo 021 **no esta cableado**: cero invocaciones desde bootstrap, `sync-agents.ps1` o README.
2. Sus capas **no se propagan** (`scripts/sync/` excluido), asi que un fix ahi no llega a ningun consumidor.
3. Tocar 4 archivos de un flujo muerto triplica la superficie de test para beneficio cero hoy.

Se registra como deuda con disparador explicito: **cuando 021 se cablee, `sync-constitutions.ps1` L59-60 y `sync-kit-files.ps1` L117-118 deben adoptar el mismo helper antes de retirar `sync-kit.ps1`** (seccion 12).

### D-03 - Normalizacion a nivel de bytes, no de string

Se normaliza sobre `byte[]` eliminando cada `0x0D` que precede a un `0x0A`:

- no depende de encoding ni del fallback de `Encoding.UTF8.GetString` (que sustituye bytes invalidos y podria colisionar dos binarios distintos);
- es la traduccion literal de NFR-04;
- conserva el BOM como byte: un BOM de un solo lado es **diferencia real**, no ruido de EOL. Se documenta como limite aceptado (T-05).

### D-04 - Tres resultados con dos hashes, en un solo helper

`Compare-KitFileContent` devuelve `'Equal' | 'EolOnly' | 'Different'`:

1. hash normalizado de ambos lados;
2. si difieren -> `'Different'` (no se calcula nada mas);
3. si coinciden -> hash crudo de ambos lados: iguales -> `'Equal'`, distintos -> `'EolOnly'`.

Dos lecturas por archivo en el caso barato, cero archivos temporales, cero escrituras. Satisface FR-01 y FR-02 sin inventar un cuarto estado.

### D-05 - El merge del bloque `mcp` se extrae a la lib **sin cambiar semantica**

`Merge-KitOpencodeJson` reproduce la secuencia exacta de L655-668 (quitar `mcp` del origen, inyectar el del destino, `Write-OK [GUARD]`), pero devolviendo `'Merged' | 'NoLocalMcp' | 'Error'` en vez de escribir directamente. Motivo: FR-05, CA-03 y CA-06 son hoy **no testeables** porque la logica vive dentro de un `foreach` de una funcion que ejecuta el sync al cargarse. Extraerla es la unica forma de cubrirlas con Pester.

Cambio de comportamiento permitido y requerido: la escritura pasa de `ConvertTo-Json | Set-Content -Encoding UTF8` a `Write-KitJsonFile` (LF explicito). El resto del flujo es identico.

### D-06 - La escritura LF se hace con `[IO.File]::WriteAllText` + `UTF8Encoding($false)`

`Set-Content -Encoding UTF8` en PowerShell 7 escribe UTF-8 sin BOM pero **usa `[Environment]::NewLine`** (CRLF en Windows). Por eso el guard reintroduce el defecto en cada merge (FR-04). `WriteAllText` con el texto ya normalizado es la unica forma portable de fijar LF.

Detalle medido: `ConvertTo-Json -Depth 10` sobre `opencode.json` produce 2.466 caracteres contra 2.467 del original — **pierde el `\n` final**. Por eso `Write-KitJsonFile` recorta `\r`/`\n` finales y agrega **exactamente un** `\n`. Sin eso, CA-04 (diff espurio) falla por un byte.

### D-07 - `-Force` y `-DryRun` pasan a ser parametros explicitos

Hoy ambos funcionan por *dynamic scoping*: `Sync-TransversalKit` lee `$Force` y `$DryRun` del scope del script porque no los declara. Basta una variable local homonima en un wrapper para romperlos en silencio. `-DryRun` es el caso peligroso: fallaria hacia "escribir cuando pidieron no escribir".

FR-03 nombra `-Force`. Se declaran **los dos**, porque `-DryRun` es el mismo defecto con peor consecuencia y FR-06 exige que `-DryRun` no escriba nada.

**Riesgo de implementacion**: agregar `[switch]$Force` al `param` **sin** pasar `-Force:$Force` desde L712 convierte `-Force` en no-op (`$Force` pasaria a resolver al parametro local vacio). CA-07 y T-11 existen exactamente para eso.

---

## 3. Diseno del modulo de comparacion

Archivo nuevo: `scripts/sync-kit-lib.ps1` (sin efectos secundarios, apto para dot-source).

```powershell
#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# sync-kit-lib.ps1 - Helpers puros de scripts/sync-kit.ps1 (spec 029)
# Sin efectos secundarios: no ejecuta sync, no escribe al importarse.
# Normalizacion permitida: SOLO \r\n -> \n (NFR-04). No recorta lineas,
# no colapsa vacias, no reordena claves, no toca el BOM.
# =============================================================================

function Get-KitNormalizedBytes {
    param([Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
    if ($null -eq $Bytes -or $Bytes.Length -eq 0) { return ,[byte[]]@() }
    $out = [System.Collections.Generic.List[byte]]::new($Bytes.Length)
    for ($i = 0; $i -lt $Bytes.Length; $i++) {
        if ($Bytes[$i] -eq 13 -and ($i + 1) -lt $Bytes.Length -and $Bytes[$i + 1] -eq 10) { continue }
        $out.Add($Bytes[$i])
    }
    return ,$out.ToArray()
}

function Get-KitContentHash {
    param([Parameter(Mandatory)][string]$Path)
    $raw  = [System.IO.File]::ReadAllBytes($Path)
    $norm = Get-KitNormalizedBytes -Bytes $raw
    $sha  = [System.Security.Cryptography.SHA256]::Create()
    try   { return [System.Convert]::ToHexString($sha.ComputeHash($norm)) }
    finally { $sha.Dispose() }
}

function Compare-KitFileContent {
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)
    # Devuelve 'Equal' | 'EolOnly' | 'Different'
    if ((Get-KitContentHash -Path $Source) -ne (Get-KitContentHash -Path $Destination)) { return 'Different' }
    $rSrc = (Get-FileHash -LiteralPath $Source      -Algorithm SHA256).Hash
    $rDst = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($rSrc -eq $rDst) { return 'Equal' }
    return 'EolOnly'
}

function Write-KitJsonFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Object)
    $text = $Object | ConvertTo-Json -Depth 10
    $text = ($text -replace "`r`n", "`n").TrimEnd([char[]]"`r`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
}

function Merge-KitOpencodeJson {
    param([Parameter(Mandatory)][string]$SourcePath, [Parameter(Mandatory)][string]$DestinationPath)
    # Devuelve 'Merged' | 'NoLocalMcp' | 'Error'. Solo escribe en 'Merged'.
    try {
        $srcJson = Get-Content -LiteralPath $SourcePath      -Raw -ErrorAction Stop | ConvertFrom-Json
        $dstJson = Get-Content -LiteralPath $DestinationPath -Raw -ErrorAction Stop | ConvertFrom-Json
        if ($null -eq $dstJson.mcp -or $null -eq $srcJson) { return 'NoLocalMcp' }
        if ($srcJson.PSObject.Properties["mcp"]) { $srcJson.PSObject.Properties.Remove("mcp") }
        $srcJson | Add-Member -NotePropertyName "mcp" -NotePropertyValue $dstJson.mcp -Force
        Write-KitJsonFile -Path $DestinationPath -Object $srcJson
        return 'Merged'
    } catch { return 'Error' }
}
```

Nota de seguridad del diseno: `Merge-KitOpencodeJson` escribe con el `mcp` del destino y el resto del origen **solo cuando el destino ya tiene bloque `mcp`**. Si el destino no lo tiene, la funcion devuelve `NoLocalMcp` y el llamador cae a `Copy-Item` (L672), que copia el `opencode.json` del maestro **con su bloque `mcp` incluido** — rutas absolutas de otra maquina. Esa rama es comportamiento preexistente (no lo introduce la 029) y contradice el guardrail 1 de ADR-0009; queda registrada como SR-02 en `threat-model.md` y **fuera del alcance de esta spec por FA-01**. El implementador NO debe "arreglarla de paso": requiere spec propia con decision explicita.

---

## 4. Contrato de mensajes (FR-02)

| Resultado | Mensaje exacto | Efecto sobre el archivo |
|---|---|---|
| `Equal` | `[OK]   <label> - sin cambios (contenido identico)` | No se escribe |
| `EolOnly` | `[OK]   <label> - sin cambios (solo difiere el fin de linea; se conserva local)` | No se escribe (CA-01) |
| `Different` | `[WARN] [SKIP] <label> - contenido distinto; usa -Force para sobrescribir (se conserva local)` | No se escribe sin `-Force` |
| `Different` + `-Force` | `[FILE] <label>` (sin cambios) | Se copia (o se mergea si es `opencode.json`) |
| `opencode.json` + `-Force` + `mcp` local | `[OK]   [GUARD] opencode.json: bloque mcp local PRESERVADO (merge con la plantilla del maestro).` | Merge con LF, `mcp` del destino intacto |
| `opencode.json` + `-Force`, merge falla | `[WARN] [GUARD] opencode.json: no se pudo mergear el bloque mcp local (...); se conserva el local sin sobrescribir.` | No se escribe |

Ningun resultado nuevo es ambiguo con `-DryRun`: el `-DryRun` retorna en L508 antes de este bloque, sin cambios.

---

## 5. Cambios por linea

Los numeros son los de `scripts/sync-kit.ps1` al 2026-10-27 (37.660 B). **El implementador debe re-verificarlos antes de editar**; el archivo esta marcado DEPRECATED y puede haber derivado.

| # | Linea | Antes | Despues | FR |
|---|---|---|---|---|
| C-01 | tras L44 | *(nada)* | dot-source fail-closed: `$kitLib = Join-Path $PSScriptRoot "sync-kit-lib.ps1"`; `if (-not (Test-Path -LiteralPath $kitLib)) { throw ... }`; `. $kitLib` | FR-01 |
| C-02 | L453-458 | `param(RepoUrl, RootPath, OrphanAction, KitPath)` | agregar `[switch]$DryRun, [switch]$Force` | FR-03, FR-06 |
| C-03 | L589-601 | `Get-FileHash` crudo x2 para `.opencode/.gitignore` | `Compare-KitFileContent`; `Different` -> guard hold; `EolOnly` -> `Write-Info` y continuar | FR-01 |
| C-04 | L640-649 | hash crudo + `[OK]/[SKIP]` de dos estados | `Compare-KitFileContent` + tres mensajes de la seccion 4. **Sin `switch`**: `continue` dentro de un `switch` en PowerShell afecta al `switch`, no al `foreach` (hazard de implementacion) | FR-01, FR-02 |
| C-05 | L651-671 | merge inline con `Set-Content -Encoding UTF8` | llamada a `Merge-KitOpencodeJson`; `'Merged'` -> `Write-OK [GUARD] ...`; `'Error'` -> `Write-Warn ...`; `'NoLocalMcp'` -> cae a `Copy-Item` | FR-04, FR-05 |
| C-06 | L641-642 | `Get-FileHash $src` sin `-LiteralPath` | desaparece (lo cubre el helper, que usa `-LiteralPath`) | FR-01 |
| C-07 | L712 | `Sync-TransversalKit -RepoUrl ... -OrphanAction ... -KitPath ...` | agregar `-DryRun:$DryRun -Force:$Force` | FR-03, FR-06 |
| C-08 | L20-27 | bloque `# Uso:` | documentar los tres resultados y que `-Force` no pisa el `mcp` local | FR-02, FR-08 |
| C-09 | L3 | marca DEPRECATED | sin cambio (este plan no retira el motor) | — |

Archivo nuevo: `scripts/sync-kit-lib.ps1` (seccion 3).
Archivo nuevo: `tests/sync-kit-lib.Tests.ps1` (seccion 7).

Verificacion de propagacion: `scripts/` es transversal completo (`$transversalDirs` L482) y `sync-kit.ps1` lo copia con `robocopy /E`. `scripts/sync-kit-lib.ps1` viaja sin tocar la lista blanca.

---

## 6. Alternativas descartadas

| Alt. | Idea | Por que no |
|---|---|---|
| A-01 | `-Force` pisa el bloque `mcp` | Contradice ADR-0009 (rutas absolutas) y ADR-0010 R4; propagaria rutas de otra maquina a todos los consumidores. Es FA-01 de la spec |
| A-02 | Normalizar con `git add --renormalize` o `git hash-object --path` | Requiere git y un indice limpio; el sync debe funcionar sin repo git (consumidores sin `.git`) y sin efectos sobre el indice |
| A-03 | Replicar `$Force` por `$script:Force` global | Cambia el mecanismo sin eliminar el acoplamiento implicito; el parametro explicito es mas simple y verificable por AST |
| A-04 | Guard `if (-not $env:SYNCKIT_LIB_ONLY)` para testear `sync-kit.ps1` | Un script que se auto-desactiva por variable de entorno es una trampa de mantenimiento; el helper puro no la necesita |
| A-05 | Reescribir el archivo a LF cuando el resultado es `EolOnly` | CA-01 exige explicitamente "no se reescribe". Ademas generaria escrituras en cada corrida sobre archivos que git normaliza igual |
| A-06 | Normalizar tambien el BOM | NFR-04 limita la normalizacion a `\r\n` -> `\n`; quitar BOM enmascara una diferencia real de encoding |
| A-07 | Usar `Compare-Object` sobre lineas | Mas lento, sensible a encoding y devuelve diferencias por linea, no un veredicto de tres estados |
| A-08 | Arreglar los 4 sitios de `scripts/sync/*` ahora | el flujo 021 no esta cableado y `scripts/sync/` no se propaga (D-02) |

---

## 7. Plan de pruebas

Entorno: **Pester 3.4.0** (el unico instalado). Restricciones reales de esa version: no existe `BeforeAll`; el operador es `Should Be <valor>` (posicional), no `Should -Be`; `$TestDrive` existe pero se prefiere `$env:TEMP` explicito (NFR-03). Patron de referencia: `tests/upgrade_framework.Tests.ps1` (dot-source del modulo bajo prueba, sin ejecutar el CLI).

Archivo: `tests/sync-kit-lib.Tests.ps1`. Hace dot-source **solo** de `scripts/sync-kit-lib.ps1`, por lo que no dispara el sync.

| ID | Escenario | Montaje | Esperado | Cubre |
|---|---|---|---|---|
| T-01 | Byte-identicos | mismo contenido, mismo EOL | `Equal` | CA-01 |
| T-02 | Solo EOL | origen LF (10 lineas), destino CRLF | `EolOnly` | CA-01, FR-01 |
| T-03 | Contenido distinto | +1 clave JSON en el destino | `Different` | CA-02, FR-01 |
| T-04 | EOL mixto | 5 lineas LF + 5 CRLF vs todo LF | `EolOnly` | FR-01 (caso real de `AGENTS.md`) |
| T-05 | BOM de un solo lado | origen con `EF BB BF` | `Different` | Limite de NFR-04 (documentado) |
| T-06 | CR suelto | `\r` sin `\n` vs `\n` | `Different` | NFR-04 (solo `\r\n`) |
| T-07 | Sin efectos secundarios | hash del directorio completo antes/despues de comparar | Igual | NFR-03, FR-06 |
| T-08 | `Write-KitJsonFile` EOL | objeto con 3 claves | 0 `\r\n`, exactamente 1 `\n` final | FR-04, CA-03 |
| T-09 | `Write-KitJsonFile` fidelidad | round-trip de `opencode.json` real | contenido identico al original normalizado | CA-04 |
| T-10 | Merge preserva `mcp` local | origen `mcp=A`, destino `mcp=B` | resultado `mcp=B`, resto del origen | CA-06, FR-05 |
| T-11 | Merge sin `mcp` local | destino sin `mcp` | `NoLocalMcp`, no escribe | FR-05 |
| T-12 | Merge escribe LF | merge exitoso | 0 `\r\n` | CA-03 |
| T-13 | Firma de `Sync-TransversalKit` | AST (`Parser::ParseFile`) sobre `sync-kit.ps1` | declara `DryRun` y `Force` | CA-07 |
| T-14 | Entrypoint propaga `-Force` | AST: `CommandAst` `Sync-TransversalKit` contiene `-Force` | presente | CA-07, FR-03 |
| T-15 | Helper importable sin efectos | dot-source de la lib | no crea ni modifica archivos | NFR-03 |

Verificacion en sandbox (NFR-03, end-to-end, sin red, sobre `$env:TEMP`):

```powershell
$sb = Join-Path $env:TEMP "sync029-sandbox"
Remove-Item $sb -Recurse -Force -ErrorAction SilentlyContinue

# 1) destino con opencode.json en CRLF e identico en contenido
# 2) DryRun: hashes del sandbox antes/despues deben coincidir  -> CA-05
.\scripts\sync-kit.ps1 -RootPath $sb -KitPath $KitPath -DryRun
# 3) sin -Force:            -> "[OK] opencode.json - sin cambios (solo difiere el fin de linea...)"  CA-01
# 4) clave nueva en destino -> "[SKIP] ... contenido distinto"                                         CA-02
# 5) con -Force + mcp local -> "[GUARD] bloque mcp local PRESERVADO" + 0 CRLF + mcp intacto           CA-03, CA-06
# 6) git diff -- opencode.json en el repo real -> vacio                                                CA-04
```

`-KitPath` se usa para no depender de red (valida marcadores de kit: `scripts`, `.github`, `.opencode`, `.doc_agents`, `AGENTS.md`).

---

## 8. Riesgos y mitigaciones

| ID | Riesgo | Prob. | Impacto | Mitigacion |
|---|---|---|---|---|
| RP-01 | Declarar `[switch]$Force` y olvidar `-Force:$Force` en L712: `-Force` se vuelve no-op silencioso | Media | Alto | T-14 (AST) falla si no se propaga; CA-07 |
| RP-02 | `continue` dentro de `switch` dentro de `foreach` sale del `switch`, no del bucle | Media | Alto | C-04 prohibe `switch`; solo `if/elseif/else` + `continue` explicito |
| RP-03 | La normalizacion enmascara un cambio real | Baja | Alto | Solo se quita `0x0D` antes de `0x0A`; T-03/T-05/T-06 verifican los limites |
| RP-04 | `ConvertTo-Json` pierde el `\n` final y genera diff espurio | Alta si se omite | Medio | `Write-KitJsonFile` agrega exactamente un `\n`; T-08/T-09; CA-04 |
| RP-05 | El helper no viaja a un consumidor y el dot-source revienta | Baja | Alto | C-01 falla cerrado con mensaje explicito; el archivo vive en `scripts/`, que se copia completo |
| RP-06 | Alguien "arregla" el guard `mcp` en el mismo PR | Baja | Alto | FA-01 en la spec; T-10/T-11 fijan el comportamiento actual como contrato |
| RP-07 | Los numeros de linea derivaron (archivo DEPRECATED) | Media | Bajo | C-01..C-09 son identificados por contenido y ancla textual; el implementador re-verifica y el plan dice donde |
| RP-08 | Escribir LF en archivos que necesitan CRLF (`.ps1`) | Baja | Medio | FR-04 limita la escritura LF a `opencode.json` via `Write-KitJsonFile`; el resto sigue con `Copy-Item` |

---

## 9. Trazabilidad spec -> plan -> cambio -> test

| FR / CA | Requisito | Cambio | Test |
|---|---|---|---|
| FR-01 | Comparacion con EOL normalizado | C-01, C-03, C-04 | T-01..T-06 |
| FR-02 | Tres resultados con mensajes distintos | C-04 (+ seccion 4) | T-01, T-02, T-03 |
| FR-03 | `-Force` declarado y propagado | C-02, C-07 | T-13, T-14 |
| FR-04 | `opencode.json` escrito en LF | C-05, `Write-KitJsonFile` | T-08, T-12 |
| FR-05 | Guard del bloque `mcp` intacto | C-05, `Merge-KitOpencodeJson` | T-10, T-11 |
| FR-06 | `-DryRun` sin escrituras | C-02, C-07 (sin cambios en L492) | T-07, sandbox paso 2 (CA-05) |
| FR-07 | Identico en Windows y Linux, sin `[Environment]::NewLine` | D-03 (bytes), D-06 (`WriteAllText`) | T-02, T-04, T-06 (sin ramas por plataforma) |
| FR-08 | Spec 002 + README actualizados | converge (`documentador`) | CA-09 por lectura de ambos archivos |
| CA-01 | Igual con EOL distinto, no reescribe | C-04 | T-02, T-04 |
| CA-02 | Distinto real sigue reportando y `-Force` copia | C-04, C-07 | T-03 + sandbox paso 4 |
| CA-03 | `opencode.json` con 0 CRLF | D-06 | T-08, T-12 |
| CA-04 | Sin diff espurio en git | D-06 (newline final) | T-09 + sandbox paso 6 |
| CA-05 | `-DryRun` escribe cero | L492 intacto | sandbox paso 2 |
| CA-06 | `mcp` local byte-identico | C-05 | T-10 |
| CA-07 | Firma + propagacion de `-Force` | C-02, C-07 | T-13, T-14 |
| CA-08 | Paridad Windows/Linux | D-03, D-06 | T-02, T-04 (sin dependencia de plataforma) |
| CA-09 | Spec 002 + README al dia | converge | lectura de ambos archivos |

---

## 10. Artefactos del plan

| Artefacto | Se produce | Razon |
|---|---|---|
| `plan.md` | **Si** (este archivo) | Fase Plan |
| `research.md` | **No** | No quedan incognitas tecnicas: las siete mediciones de la seccion 1.2 las cerraron. El proyecto tampoco lo usa en specs recientes (026, 028) |
| `data-model.md` | **No** | El cambio no introduce entidades ni esquema; opera sobre `byte[]` y un enum de tres valores documentado en la seccion 3 |
| `quickstart.md` | **No** | No hay flujo de usuario nuevo; el procedimiento de verificacion esta en la seccion 7 y es reproducible por copia |
| `contracts/` | **No** | El unico contrato externo es el contrato de mensajes (seccion 4), que se fija con tests AST y de comportamiento, no con un archivo de contrato aparte |

Se documenta la omision para que ningun agente posterior reporte "faltan artefactos" (Art. IX exige contenido real, no archivos vacios).

---

## 11. Orden de ejecucion y delegacion

| Paso | Que | Quien | Puede escribir en |
|---|---|---|---|
| 1 | Crear `scripts/sync-kit-lib.ps1` (seccion 3) | `plataformador` (tier Plataforma, `edit: "*": allow`) | `scripts/` |
| 2 | Aplicar C-01..C-08 a `scripts/sync-kit.ps1` | `plataformador` | `scripts/` |
| 3 | Crear `tests/sync-kit-lib.Tests.ps1` y correrlo | `plataformador` (o `developer` si se le delega) | `tests/` |
| 4 | Verificacion sandbox (seccion 7, pasos 1-6) | `plataformador` | solo `$env:TEMP` y lectura del repo |
| 5 | Analyze (ADRs/threat model del fix) | `arquitecto` + `security-auditor` | `Documentacion/` |
| 6 | Converge: spec 002 + README (FR-08, CA-09) | `documentador` | `Documentacion/`, `README.md` |
| 7 | Commit | `gitflow` | git |

**El `pensador` no puede ejecutar los pasos 1-4**: `scripts/` y `tests/` estan fuera de su whitelist (Art. VII). Se delega, no se auto-eleva.

---

## 12. Deuda derivada (no cubierta por esta spec)

| ID | Deuda | Evidencia | Disparador para retomarla |
|---|---|---|---|
| DD-01 | `.specify/memory/constitution.md` (nivel 1) sigue en v2.0.0 con tabla de 5 columnas / separador de 4 | `edit` denegado: fuera de la whitelist del tier documental y de `Agent-SSD`; solo `plataformador` tiene `edit: "*": allow` | Correr el snippet desde `plataformador`, antes de cualquier `-Force` del bootstrap |
| DD-02 | `sync-constitutions.ps1` L59-60 y `sync-kit-files.ps1` L117-118 tienen el mismo hash crudo | grep de `Get-FileHash` en `scripts/` (7 sitios, 2 son comparaciones defectuosas) | Cuando el flujo 021 se cablee, antes de retirar `sync-kit.ps1` |
| DD-03 | `sync-skills.ps1` L116-117 compara con hash crudo | Impacto: copia redundante (sin perdida de datos ni sobrescritura indebida) | Bajo, oportunista |
| DD-04 | `sync-agents-github/opencode/vscode.ps1` y `sync-src-structure.ps1` guardan hashes crudos en mapas de manifiesto | No son decisiones de escritura, son drift | Revisar solo si el drift reporta falsos positivos |
| DD-05 | Manifiestos con hash crudo: un archivo con EOL distinto figura como "drift" para siempre | Mismo mecanismo que el defecto de la 029 | Misma correccion, cuando se aborde el drift |
| DD-06 | `opencode.json` imprime `[FILE]` antes de saber que solo va a mergear (mensaje poco honesto) | L650 vs L663 | Cosmetico; se puede ajustar a `[MERGE]` en el paso 2 sin cambiar comportamiento |

---

## 13. Criterio de "plan terminado"

- [x] Las siete mediciones de la seccion 1.2 tomadas en este repo, no inferidas
- [x] Motor real identificado por evidencia (`sync-agents.ps1` L47) y descartado el flujo no cableado
- [x] Cada FR de la spec mapeado a un cambio concreto y a un test (seccion 9)
- [x] Alternativas descartadas con la restriccion que las invalida (seccion 6)
- [x] Riesgos con mitigacion verificable, incluidos los dos que romperian `-Force` en silencio (RP-01, RP-02)
- [x] Delegacion explicita con el limite de tier que impide al `pensador` implementar
- [x] Deuda derivada registrada con disparador, no como lista de deseos
