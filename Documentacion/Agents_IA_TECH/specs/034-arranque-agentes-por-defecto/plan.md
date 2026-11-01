# Plan 034 — Arranque por defecto con agentes del kit

## 1. Contexto

La spec `034-arranque-agentes-por-defecto` tiene 19 FR, 7 NFR, 5 historias de usuario y 15 criterios de aceptación. El problema medido es que `opencode.json` declara `"default_agent": "build"` (agente incorporado) y `.github/copilot-instructions.md` no contiene regla de arranque, por lo que el kit se monta pero el arnés arranca con su agente nativo.

El problema tiene **dos mitades**. La primera (FR-01..FR-13) es el estado inicial del repositorio maestro. La segunda (FR-14..FR-19) es el **camino de propagación**: un cambio que solo existe en el repo maestro no llega a los proyectos consumidores, porque `scripts/sync-kit.ps1` trata `opencode.json` y `AGENTS.md` con una regla todo-o-nada (`Equal` → OK, si no → SKIP) y no copia `tests/`. Sin la segunda mitad, el arreglo sería manual y volvería a perderse en el próximo proyecto.

Este plan fija **dónde vive cada regla**, **cómo se propaga** y **cómo se verifica** antes de escribir nada, para evitar que la implementación derive en tres contradicciones típicas: duplicar reglas en cada arnés, pisar la elección del usuario, o ampliar permisos sin querer.

## 2. Decisiones del plan (se fijan ahora, no durante la implementación)

### D1 — Dónde vive cada regla de arranque

| Componente | Qué declara | Qué NO debe hacer |
|---|---|---|
| `opencode.json` (raíz) | `default_agent: "pensador"` | No repite la regla; solo declara el valor |
| `AGENTS.md` (raíz) | Regla normativa de arranque para todos los harness + matriz de enrutamiento | No define permisos ni duplica el cuerpo de los agentes |
| `.github/copilot-instructions.md` | Puntero que remite a `AGENTS.md` y recuerda el enrutamiento | No duplica reglas base (restricción ya existente en el archivo) |
| `scripts/plataformador-bootstrap.ps1` | Asegura la clave en cada montaje (idempotente, con backup) | No reescribe `opencode.json` completo ni toca `permission` ni `mcp` |
| `tests/harness-default.ps1` | Verifica FR-01..FR-06 y FR-12 | No escribe archivos del proyecto (solo copias temporales para el fixture) |
| `scripts/validate-agents-skills.ps1` | `VAL-10`: arranque válido, severidad FAIL | No corrige; solo lee y reporta |

**Por qué no puede esperar a tasks:** si la regla se escribe en los dos arneses completos, se duplica y diverge. `AGENTS.md` ya está declarado como fuente de verdad única del kit.

### D2 — Técnica de escritura sobre `opencode.json`

1. Leer el archivo y validar que sea JSON válido. Si no lo es, no escribir y reportar WARN.
2. Copiar a backup (`opencode.json.bak-<timestamp>`) antes de cualquier cambio.
3. Modificar **solo** la clave `default_agent` conservando orden y el resto de claves (`model`, `small_model`, `instructions`, `lsp`, `permission`, `mcp`).
4. Validar el JSON resultante tras escribir; si falla, restaurar el backup.
5. Nunca agregar `default_agent` dos veces: si existe, se actualiza; si no, se inserta una vez.

Justificación: `opencode.json` contiene el bloque `mcp` resuelto localmente, que `sync-kit.ps1` protege con un guard. Reescribir el archivo completo rompería ese contrato.

### D3 — Regla de no intromisión

- Prohibido modificar bloques `permission` de cualquier agente.
- Prohibido modificar frontmatter de agentes (`mode`, `temperature`, `tools`, `user-invocable`).
- Prohibido tocar `mcp.servers`.
- El único archivo de agente que se toca es para **eliminar** `.opencode/agents/pensador/spec.md` (FR-12), que no es un agente.

Justificación: Art. V y Art. VII. La spec 031 acaba de estabilizar los permisos; 034 no debe reabrir esa superficie.

### D4 — Estrategia de verificación

| Nivel | Mecanismo | Cubre |
|---|---|---|
| Contrato | `tests/harness-default.ps1` (PowerShell plano, exit 0/1) | FR-01..FR-06, FR-12 |
| Contrato de sync | `tests/kit-sync-merge.ps1` (fixtures en `$env:TEMP`, carga las funciones por AST) | FR-14, FR-15, FR-16, B-01 |
| Gate del kit | `VAL-10` en `validate-agents-skills.ps1` | FR-01, FR-02, FR-10 |
| Montaje | `plataformador-bootstrap.ps1 -DryRun` | FR-07, FR-08 |
| Inspección | lectura de `AGENTS.md`, `copilot-instructions.md`, `README.md`, `.gitignore` | FR-04, FR-05, FR-13, FR-18 |

`tests/kit-sync-merge.ps1` **no** hace dot-source de `sync-kit.ps1` (lo ejecutaría). Extrae las tres funciones (`Compare-KitFileState`, `Merge-OpenCodeConfig`, `Merge-KitBlock`) con el parser de PowerShell y las evalúa en un scope propio con stubs de `Write-OK`/`Write-Warn`/`Write-Info`. Ventaja: el test también falla si una función se renombra o desaparece. Misma técnica de AST que ya usa `tests/sync-kit-lib.Tests.ps1`.

Se usa PowerShell plano con `exit` y no Pester: la suite `tests/validate-agents-skills.Tests.ps1` ya documentó que Pester 6.2.0 es hostil con este tipo de aserciones (`"$name: texto"` y funciones fuera de `BeforeAll`).

### D5 — `opencode.json` se sincroniza por merge de claves

El archivo tiene claves de **dos dueños**:

| Dueño | Claves | Comportamiento |
|---|---|---|
| Kit | `$schema`, `instructions`, `default_agent` | Se imponen desde el maestro |
| Proyecto | `mcp`, `model`, `small_model`, `permission`, `lsp`, cualquier clave desconocida | Se preservan tal cual están |

Algoritmo del merge (en `sync-kit.ps1`):

1. Si el destino no existe → copiar el del maestro (comportamiento actual).
2. Si `-Force` → **también** merge por claves, no copia bruta: `-Force` cambia la regla de `default_agent` (D-09), no el mecanismo.
3. Leer destino y maestro como JSON. Si el destino no parsea → no escribir + WARN (fail-closed: nunca se destruye un archivo que no se entiende).
4. Reemplazar **solo el valor** de cada clave gestionada, por edición textual del JSON y no re-serializando el objeto: `"$schema"`, `"default_agent"` (escalares entre comillas) e `"instructions"` (array plano de strings). Si la clave no existe, se inserta tras la llave de apertura. Si `instructions` del maestro no es un array de strings, se omite esa clave con WARN.
5. Preservar el resto del archivo **byte a byte**: no se reescribe el JSON completo, así que `mcp`, `permission`, `lsp` y el formato/indentación original quedan intactos y el diff del consumidor se limita a las líneas gestionadas.
6. Backup `opencode.json.bak-<timestamp>` antes de escribir.
7. Validar el JSON resultante con `ConvertFrom-Json`; si falla, restaurar el backup y emitir FAIL.

**Por qué no copia bruta ni SKIP:** copiar pisa el `mcp` resuelto localmente (que es distinto en cada máquina porque contiene rutas absolutas y `{env:...}` resueltos); SKIP deja el `default_agent` viejo para siempre, porque el destino **siempre** difiere del maestro.

### D6 — `AGENTS.md` se sincroniza por bloque delimitado

`AGENTS.md` es la fuente de verdad del kit, pero un proyecto puede agregar reglas propias. La copia completa las destruiría y el SKIP dejaría la regla de arranque sin llegar.

El bloque gestionado se delimita con marcadores HTML, invisibles al render:

```markdown
<!-- KIT-BLOCK:START arranque-por-defecto -->
...
<!-- KIT-BLOCK:END arranque-por-defecto -->
```

| Situación del destino | Acción |
|---|---|
| Marcadores `START` y `END` presentes y ordenados | Reemplazar el contenido entre ambos (marcadores inclusive) por el bloque del maestro |
| Sección `## Arranque por defecto del arnés` presente sin marcadores | Migrar: reemplazar desde ese encabezado hasta el siguiente `^## ` (o EOF) por el bloque del maestro, ya envuelto en marcadores |
| Ni marcadores ni sección | Agregar el bloque al final del archivo, precedido por una línea en blanco |
| Marcadores desordenados, duplicados o sin cierre | No escribir + WARN (fail-closed) |
| `AGENTS.md` destino ausente | Copiar el del maestro |

Regla adicional: el bloque vive en el **maestro** entre marcadores; `sync-kit.ps1` extrae ese bloque del maestro, no una copia hardcodeada. Así el bloque tiene una sola fuente.

### D7 — Whitelist de tests del kit

`tests/` pertenece a las apps (`tests/upgrade_framework.Tests.ps1`, etc.) y no puede copiarse entero. Se sincroniza una **whitelist explícita**:

| Archivo | Cubre |
|---|---|
| `tests/harness-default.ps1` | FR-01..FR-06, FR-12 |
| `tests/kit-sync-merge.ps1` | FR-14, FR-15, FR-16 |
| `tests/agents-parity.ps1` | Paridad `.github/` ↔ `.opencode/` |
| `tests/kb-parity.ps1` | Paridad de la base de conocimiento |
| `tests/mcp-refresh-parity.ps1` | Paridad del refresco de MCP |

Los archivos de la whitelist se copian por nombre exacto, con `Test-Path` previo en el maestro: si falta uno, se omite con INFO, no se crea vacío.

**Por qué whitelist y no directorio:** copiar `tests/` completo pisaría las suites de cada app; no copiar nada deja los tests de contrato del kit sin viajar y el gate del proyecto consumidor no puede reproducirlos.

## 3. Mapeo FR → componente → verificación

| FR | Componente responsable | Verificación |
|---|---|---|
| FR-01 | `opencode.json` | Lectura + `tests/harness-default.ps1` |
| FR-02 | `.opencode/agents/pensador.md` (existencia y `mode: primary`) | Test de contrato |
| FR-03 | `tests/harness-default.ps1` + `VAL-10` | Exit 1 ante fallback |
| FR-04 | `AGENTS.md` | Inspección |
| FR-05 | `.github/copilot-instructions.md` | Inspección + test |
| FR-06 | Test de contrato (comparación de bloques normativos) | Exit 1 si divergen |
| FR-07 | `scripts/plataformador-bootstrap.ps1` | `-DryRun` |
| FR-08 | `scripts/plataformador-bootstrap.ps1` | Revisión + `-DryRun` con valor distinto |
| FR-09 | `git diff` acotado | Sin cambios en `permission` |
| FR-10 | `scripts/validate-agents-skills.ps1` | `VAL-10` en resumen |
| FR-11 | `tests/harness-default.ps1` | Fixture negativo |
| FR-12 | `.opencode/agents/pensador/spec.md` | `Test-Path` negativo |
| FR-13 | `README.md` | Inspección |
| FR-14 | `scripts/sync-kit.ps1` (`Merge-OpenCodeConfig`) | `tests/kit-sync-merge.ps1` (caso 1: `mcp` preservado) |
| FR-15 | `scripts/sync-kit.ps1` (regla de `default_agent`) | `tests/kit-sync-merge.ps1` (4 casos) |
| FR-16 | `scripts/sync-kit.ps1` (`Merge-KitBlock`) + marcadores en `AGENTS.md` | `tests/kit-sync-merge.ps1` (3 casos) |
| FR-17 | `scripts/sync-kit.ps1` (whitelist de tests) | Manifiesto + `-DryRun` |
| FR-18 | `.gitignore` | Inspección |
| FR-19 | `tests/kit-sync-merge.ps1` | Ejecución del test |

## 4. Mapeo CA → verificación

| CA | Verificación |
|---|---|
| CA-01 | `opencode.json` contiene `"default_agent": "pensador"` |
| CA-02 | `.opencode/agents/pensador.md` con `mode: primary` |
| CA-03 | `tests/harness-default.ps1` exit 0 |
| CA-04 | Fixture negativo con `build` → exit 1 |
| CA-05 | Sección "Arranque por defecto del arnés" en `AGENTS.md` |
| CA-06 | `copilot-instructions.md` remite al agente del kit |
| CA-07 | `plataformador-bootstrap.ps1 -DryRun` reporta respeto de la elección |
| CA-08 | `git diff` sin cambios en `permission` |
| CA-09 | `VAL-10` presente y en OK |
| CA-10 | `.opencode/agents/pensador/spec.md` ausente |
| CA-11 | `README.md` con sección de arranque |
| CA-12 | `tests/kit-sync-merge.ps1`: `opencode.json` divergente recibe `default_agent` sin `-Force` y conserva `mcp` |
| CA-13 | `tests/kit-sync-merge.ps1`: `AGENTS.md` local modificado recibe el bloque nuevo y conserva el resto |
| CA-14 | Manifiesto con la whitelist de 5 tests; `-DryRun` los lista; `tests/` del proyecto intacto |
| CA-15 | `.gitignore` con `opencode.json.bak-*` y `AGENTS.md.bak-*` |

## 5. Orden de implementación

### 5.1 Mitad local (FR-01..FR-13) — ya ejecutada

1. `opencode.json` (clave única, reversible).
2. `AGENTS.md` (regla normativa).
3. `.github/copilot-instructions.md` (puntero de enrutamiento).
4. `tests/harness-default.ps1` (verificación primero que el resto del andamiaje).
5. `VAL-10` en el validador.
6. `plataformador-bootstrap.ps1` (aseguramiento en montaje).
7. Higiene: retirar `.opencode/agents/pensador/spec.md`.
8. `README.md` (documentación del arranque).

### 5.2 Mitad de propagación (FR-14..FR-19)

El orden no es arbitrario: primero se prepara la fuente que el sync va a extraer, después el motor, después el test que lo prueba, y al final el gate.

1. Marcadores `KIT-BLOCK` en el `AGENTS.md` del maestro (envuelven la sección existente). Sin esto, `Merge-KitBlock` no tiene qué extraer.
2. `Compare-KitFileState` en `scripts/sync-kit.ps1` (corrige B-01/B-02 de §19.5: sin esto el motor aborta antes de llegar a los archivos de raíz).
3. `Merge-OpenCodeConfig` en `scripts/sync-kit.ps1` (D5).
4. Regla de `default_agent` dentro de `Merge-OpenCodeConfig` (FR-15).
5. `Merge-KitBlock` en `scripts/sync-kit.ps1` (D6).
6. Whitelist de tests en el manifiesto de `sync-kit.ps1` (D7).
7. `.gitignore`: patrones de backup del sync (FR-18).
8. `tests/kit-sync-merge.ps1` con fixtures temporales (FR-19).
9. Gate: `-DryRun` del sync + test de contrato + validador.

## 6. Criterio de aceptación del plan

- Cada FR-01..FR-19 mapeado a un componente concreto y a una verificación ejecutable.
- Cada CA-01..CA-15 tiene verificación concreta, no una afirmación.
- La regla de no intromisión (D3) es verificable con `git diff`.
- La técnica de escritura (D2) protege el bloque `mcp` y permite rollback.
- El merge (D5, D6) es **fail-closed**: JSON inválido o marcadores corruptos → no se escribe nada.
- `-Force` cambia la regla de decisión de `default_agent` (D-09), no el mecanismo: nunca copia bruta.
- Ningún archivo fuera de la whitelist (D7) se copia desde `tests/`.
