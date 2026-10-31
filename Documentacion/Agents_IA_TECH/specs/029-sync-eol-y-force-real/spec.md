# Spec 029 - Sync honesto: EOL normalizado y `-Force` efectivo

## Objetivo

Eliminar el falso positivo de diferencia por fin de linea (CRLF vs LF) en el motor de sync del kit, hacer que `-Force` llegue de forma explicita a la funcion que copia, y garantizar que `opencode.json` se escriba en LF. El guard que preserva el bloque `mcp` local **no se modifica**: es una mitigacion deliberada de ADR-0006, ADR-0009 y ADR-0010.

## Contexto y problema

`scripts/sync-kit.ps1` decide si copiar un archivo transversal comparando `Get-FileHash` sobre **bytes crudos** (L640-649). En un checkout Windows con `core.autocrlf=true` y `.gitattributes` que fuerza `*.json eol=lf`, el archivo local queda en CRLF tras haber sido reescrito por PowerShell, mientras el clon del maestro llega en LF.

Evidencia medida en este repo (2026-10-27):

| Archivo | Bytes | LF | CRLF |
|---|---:|---:|---:|
| `opencode.json` local | 2.569 | 102 | 102 |
| `opencode.json` del clon maestro | 2.467 | 102 | 0 |

Contenido normalizado: **identico**. `git diff HEAD -- opencode.json`: **vacio**. Aun asi el sync reporta `[SKIP] opencode.json - existe y difiere` en cada corrida, porque el hash de bytes nunca coincide. La diferencia de 102 bytes es exactamente la cantidad de caracteres `\r`.

Tres defectos derivados:

1. **Falso positivo permanente**: el operador no puede distinguir "personalizacion local real" de "solo difiere el EOL". `[OK] sin cambios` nunca aparece para `opencode.json`.
2. **`-Force` no esta declarado**: `Sync-TransversalKit` (L452-458) no recibe `-Force` en su `param`, y el entrypoint (L712) no se lo pasa. Funciona solo por *dynamic scoping* de PowerShell, que lee `$Force` del scope del script. Si el motor se envuelve en un modulo o aparece una variable local homonima, `-Force` deja de tener efecto en silencio.
3. **La escritura reintroduce el defecto**: el guard de `opencode.json` (L651-671) reescribe con `ConvertTo-Json | Set-Content -Encoding UTF8`, que en Windows emite CRLF. Cada merge vuelve a dejar el archivo en CRLF, perpetuando el falso positivo.

## Requisitos funcionales

- **FR-01**: La comparacion de archivos transversales MUST basarse en contenido con fin de linea normalizado (`\r\n` -> `\n`), no en el hash de bytes crudos.
- **FR-02**: La comparacion MUST distinguir tres resultados y reportarlos con mensajes distintos: contenido igual, contenido igual salvo EOL, contenido distinto.
- **FR-03**: `-Force` MUST estar declarado en el `param` de `Sync-TransversalKit` y MUST pasarse explicitamente desde el entrypoint del script.
- **FR-04**: Cuando se escriba `opencode.json`, el resultado MUST usar LF como fin de linea, independientemente de la plataforma.
- **FR-05**: El guard del bloque `mcp` de `opencode.json` MUST conservarse sin cambios de comportamiento: el `mcp` local se preserva y el del maestro se descarta, tal como hoy.
- **FR-06**: `-DryRun` MUST seguir produciendo cero escrituras y cero efectos secundarios.
- **FR-07**: El comportamiento MUST ser identico en Windows y Linux; no se admite dependencia de `[Environment]::NewLine`.
- **FR-08**: `Documentacion/Agents_IA_TECH/specs/002-script-plataforming-sync-kit/spec.md` y la seccion "Politica merge-no-mirror" de `README.md` MUST actualizarse para describir el criterio normalizado y los tres resultados posibles.

## Requisitos no funcionales

- **NFR-01**: La semantica de `-Force` para los demas archivos transversales no cambia: sigue sobrescribiendo cuando el contenido difiere de verdad.
- **NFR-02**: Cero regresiones en el guard de `.opencode/.gitignore`, en la deteccion de huerfanos y en el manejo de `.opencode/config.json`.
- **NFR-03**: El comportamiento es verificable en sandbox sobre `$env:TEMP`, sin tocar el repo real ni requerir red.
- **NFR-04**: La normalizacion de EOL MUST limitarse a `\r\n` -> `\n`. Prohibido colapsar lineas, recortar contenido o reordenar claves de JSON, porque enmascararia cambios reales.

## Criterios de aceptacion

- **CA-01**: Un archivo con contenido identico y EOL distinto (destino CRLF, origen LF) reporta contenido igual, sin exigir `-Force`, y no se reescribe.
- **CA-02**: Un archivo con contenido realmente distinto sigue reportando diferencia y `-Force` lo sobrescribe.
- **CA-03**: El `opencode.json` resultante de un merge tiene 0 ocurrencias de CRLF.
- **CA-04**: Tras un sync completo, `git diff` no muestra cambios espurios en `opencode.json`.
- **CA-05**: `-DryRun` no escribe ningun archivo, verificado por hash antes/despues.
- **CA-06**: El bloque `mcp` local permanece byte-identico antes y despues del merge.
- **CA-07**: `Sync-TransversalKit` declara `-Force` en su firma y el entrypoint se lo pasa; verificable por lectura del codigo.
- **CA-08**: El mismo par de archivos (destino CRLF, origen LF) produce el mismo resultado reportado en Windows y en un entorno Linux; no hay ramas que dependan de `[Environment]::NewLine`.
- **CA-09**: Al cerrar converge, `specs/002-script-plataforming-sync-kit/spec.md` y la seccion "Politica merge-no-mirror" de `README.md` describen el criterio normalizado y los tres resultados; verificable por lectura de ambos archivos.

## Fuera de alcance

- **FA-01**: Modificar el guard del bloque `mcp` para que `-Force` lo pise. Descartado: contradice ADR-0009 (rutas absolutas hardcodeadas) y ADR-0010 R4, y romperia los MCPs de los proyectos consumidores al propagar rutas de otra maquina.
- **FA-02**: Modificar `scripts/plataformador-bootstrap.ps1` o su logica de registro de MCPs.
- **FA-03**: Modificar `.specify/memory/constitution.md` (fuera de la whitelist del tier documental, Art. VII).
- **FA-04**: Resolver el desfase del `00-indice.md` ni del indice de ADRs; se registran como deuda separada.

## Dependencias

| ID | Dependencia | Tipo |
|---|---|---|
| DEP-01 | `scripts/sync-kit.ps1` L640-673 (comparacion y guard de `opencode.json`) | Codigo a modificar |
| DEP-02 | `specs/002-script-plataforming-sync-kit/spec.md` | Contrato a actualizar en converge |
| DEP-03 | `README.md`, seccion "Politica merge-no-mirror" | Documentacion a actualizar en converge |
| DEP-04 | ADR-0006, ADR-0009, ADR-0010 | Restricciones arquitectonicas que acotan el alcance |
| DEP-05 | `.gitattributes` (`*.json text eol=lf`) | Define LF como formato canonico del repo |

## Riesgos

| ID | Riesgo | Mitigacion |
|---|---|---|
| R-01 | Que la normalizacion enmascare cambios reales de contenido | Normalizar solo `\r\n` -> `\n`; prohibido trim o colapso (NFR-04) |
| R-02 | Escribir LF en archivos que requieren CRLF (scripts `.ps1`) | Limitar la escritura LF a `opencode.json` |
| R-03 | El cambio afecta a todos los proyectos consumidores del kit | Cubrir con CA-01..CA-07 antes de propagar por sync |
| R-04 | Dos fuentes de verdad para el criterio (codigo y spec 002) | FR-08 obliga a actualizar spec 002 y README en converge |

## Supuestos

- **A-01**: LF es el formato canonico del repo para JSON y Markdown (`.gitattributes` lo declara), por lo que escribir LF no genera diffs en git.
- **A-02**: El guard del bloque `mcp` responde a una necesidad real vigente (rutas absolutas por maquina), no a una decision caduca. Se verifico contra ADR-0006, ADR-0009 y ADR-0010 el 2026-10-27.
- **A-03**: El operador ejecuta el sync desde PowerShell 7 en Windows, que es el unico entorno soportado por el kit.
