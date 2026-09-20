# 🔒 Seguridad del diseño: descontaminación del kit maestro — solución genérica (`[SOLUCION-GENERICA]`, RF-S1..RF-S7)

> Revisión **de seguridad del DISEÑO** de la descontaminación del kit maestro a genérico/parametrizado (cero dominio concreto + cero absolutas en versionados; ejemplos `MiApp`/`AppFoo`; hallazgos modo-real anonimizados a `AppXXX`; historial conservado).
> Enfocada en: **(1) URLs de repos ajenos/privados en el manifest (clonado ciego), (2) rutas absolutas del autor versionadas (exfiltración + DoS de configuración), (3) `opencode.json` versionado con paths inexistentes en terceros, (4) borrado amplio "todo lo que no es nuestro" (pérdida de datos; fail-closed), (5) anonimización `AppXXX` que destruye trazabilidad técnica necesaria**.
> Fuente: `Documentacion/Agents_IA_TECH/specs/solucion-generica/spec.md` (RF-S1..RF-S7, 8 ACs) + `pendientes-implementacion.md` (tarea `[SOLUCION-GENERICA]`, plan aprobado 2026-09-19).
> Fecha: 2026-09-19 | Autor: `security-auditor` (fase documental — tarea `[SOLUCION-GENERICA]`)

---

## 1. Alcance

Esta revisión cubre **solo el diseño** aprobado en la spec (lista cerrada de 8 artefactos: ADR-0003, spec/tasks plataforma, pendientes, bootstrap L40/L57/L1993, manifest, README, agentes `.github/` ↔ `.opencode/`, `opencode.json`). No re-audita supply chain/licencias (cubierto por `plataforma-bootstrap.md`, `graphify.md`, `tokenslayer.md`), ni blindaje `.git`/matriz `.opencode` (spec `kit-generico`, `blindaje-git.md`), ni huérfanos (spec `[HUERFANOS]`, `huerfanos.md`), ni relocate (spec `[RELOCATE]`). Verificación por **lectura directa** (`Select-String` + `Get-Content`) del estado actual pre-descontaminación — es decir, de lo que la spec ordena quitar — sin ejecutar scripts.

Hallazgos verificados hoy (pre-RF, son la deuda que RF-S1..RF-S7 deben eliminar):

- **Manifest** (`dependencias-manifest.yml` L101-140): 5 apps concretas **activas** (los 5 nombres de dominio del proyecto, lista en `specs/solucion-generica/spec.md` RF-S1) con URLs `https://github.com/tomasecastro/<repo>` (owner `tomasecastro` = cuenta personal del autor, repos **privados o ajenos al consumidor del kit**). Coexiste un placeholder comentado `apps_manifiesto` (L142-161, todo `TBD`, NO activo) que es el formato que RF-S5 quiere como único contenido.
- **Bootstrap** (`scripts/plataformador-bootstrap.ps1`): L40 `-Apps` default con la lista fija de 5 dominios; L57 `$KnownApps` fijo con los mismos 5; allowlist `$TrustedOwners` (L61-69) incluye `tomasecastro` y el owner muerto `tomasgraph`. `Prepare-Apps` (L2044+) itera sobre lista conocida (L1766/L1789 `foreach ($known in $KnownApps)`).
- **`opencode.json`** (versionado): 5 comandos MCP con **rutas absolutas del autor** — `C:/Users/tomas/...` (context-mode L65, codebase-memory L72, markitdown L79), `C:/Proyectos/Agents_IA_TECH/...` (tokenslayer L87), `C:\Python314\...` + `C:\Proyectos\Agents_IA_TECH\graphify-out\graph.json` (graphify L94/97). Mismo patrón duplicado en el bootstrap (L280/L285/L890/L930/L955/L971/L1026/L1041).
- **Anonimización**: la spec decide registrar hallazgos modo-real como `AppXXX` (spec §Decisiones-2, pendientes `[SOLUCION-GENERICA]` T-D).

---

## 2. Análisis de riesgos

### R-1. URLs de repos ajenos/privados en el manifest del kit (clonado ciego por terceros)

El manifest es la **lista de cosas que el bootstrap descarga y ejecuta**. Con 5 entradas activas apuntando a `tomasecastro/*` (repos personales, licencia `🔒 pendiente de verificar`, L106/L114/L122/L130/L138), cualquier tercero que use el kit clona por defecto código **que no es suyo, sin licencia verificada (guardrail 8 incumplido) y potencialmente privado** (si el repo es privado el clon falla o — peor — pide credenciales que el usuario pega en un flujo no diseñado para secrets). Es el riesgo mayor del paquete: **supply chain + clonado ciego + secreto accidental**. Mitigación (ya en spec): RF-S5 (manifest sin apps activas, solo formato + ejemplo comentado — el bloque L142-161 ya existe como modelo), RF-S3 (sin lista fija; descubrir `src/*` o flag explícito), y fail-closed en URLs (solo `github.com` + owner en allowlist, heredado de `plataforma-bootstrap.md`). Condición adicional: la allowlist del bootstrap debe **salir `tomasecastro`/`tomasgraph`** al descontaminar (hoy L63/L68 los legitiman), o el fail-closed sigue aceptando URLs del autor.

### R-2. Rutas absolutas del autor en archivos versionados (exfiltran usuario/estructura; rompen reuso)

`C:/Users/tomas/...` revela **nombre de usuario del SO + layout de disco** del autor a todo clonador (exfiltración pasiva de PII/estructura, útil para phishing dirigido o path-guessing). `C:/Proyectos/...` y `C:\Python314\...` asumen un disco y un intérprete que no existen en destino. Mitigación (ya en spec): RF-S2 (cero absolutas en versionados; relativas o tokens) + RF-S6 (plantilla con tokens + re-resolución en runtime local, jamás commiteada) + RF-S7 (grep anti-regresión sobre `git ls-files`). Condición adicional: el test debe cubrir **ambas barras** (`C:\` y `C:/`, la spec ya lo exige en RF-S2/AC-2) y el universo debe ser `git ls-files` (no el workdir, que incluye `.opencode/config.json` local con secrets legítimos no versionados).

### R-3. `opencode.json` versionado con paths inexistentes → DoS de configuración en terceros

Hoy un clonador hereda 5 comandos MCP que apuntan a rutas que **no existen en su máquina** (`C:/Users/tomas/...`, `C:/Proyectos/...`). El fallo es al arrancar el harness: MCPs caídos, errores opacos, usuario que "arregla" pegando sus propias absolutas y las commitea (re-contaminación). Es un **DoS de configuración auto-perpetuante**. Mitigación (ya en spec): RF-S6 (tokens + re-resolución en bootstrap; rutas reales solo en runtime local) + AC-6 (`Parser`/JSON válido antes y después). Condición adicional: la plantilla debe **arrancar degradada con WARN** (MCP deshabilitado + mensaje "ejecuta el bootstrap"), nunca con `enabled: true` apuntando a token sin resolver; y `permission.bash` (`pip install *`, `python *` en allow) no debe ampliarse al re-resolver.

### R-4. Borrado amplio ("todo lo que no es nuestro") = pérdida de datos; fail-closed exigible

La spec lo prohíbe explícitamente (RF-S4) y reutiliza los guards de `kit-generico` RF-B1..B4 (`blindaje-git.md`): destructivas solo sobre allowlist de descarga/instalación, lo no listado se conserva + aviso. Riesgo residual específico de esta tarea: al **quitar** `$KnownApps`/listas fijas (RF-S3), una rutina que antes iteraba "lo conocido" puede degenerar en "todo menos lo sagrado" (denylist abierta) si el `devops` implementa el descubrimiento `src/*` sin allowlist de-borrado aparejada. El `Remove-Item -LiteralPath $full -Force` de huérfanos (bootstrap L1277) opera sobre lista cerrada del detector — correcto hoy — pero cualquier reescritura RF-S3/S4 debe mantener esa propiedad. Condición: AC-4 verificable por código (ninguna rutina destructiva opera por exclusión abierta) + fixture "fuera de allowlist → conservado + aviso".

### R-5. Anonimización `AppXXX` que destruye trazabilidad técnica necesaria (conteos, locks)

Anonimizar el **nombre** de la app (dominio → `AppXXX`) es correcto para privacidad; anonimizar el **resto del hallazgo** (conteos de archivos, tamaños, PIDs, rutas de lock, hashes) destruiría la utilidad diagnóstica (ej.: la discrepancia de conteo 259-vs-37 en `[RELOCATE]` solo es investigable con números reales). Mitigación (ya acotada en spec): la decisión solo anonimiza el nombre (spec §Decisiones-2: "hallazgos modo-real anonimizados a `AppXXX`"), y la evidencia histórica se conserva intacta (spec §Fuera de alcance + Decisión-3, exclusiones explícitas del grep RF-S1/RF-S7). Condición: el `devops`/`qa-senior` deben mantener **números, rutas relativas, hashes y logs** verbatim al anonimizar; y el test RF-S7 debe excluir por **ruta** (`testing/`, notas de historial, evidencia de incidentes — AC-1) no por patrón de contenido, para no blanquear una re-contaminación real fuera de esas rutas.

---

## 3. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación (spec ya la trae + condición del auditor) |
|---|--------|:---------:|------------------------------------------------------|
| 1 | **Clonado ciego de repos ajenos/privados** (5 apps `tomasecastro/*` activas, sin licencia) | 🔴 Alto | RF-S5 (manifest solo formato + ejemplo comentado) + RF-S3 (sin lista fija) + fail-closed URLs; **condición**: sacar `tomasecastro`/`tomasgraph` de `$TrustedOwners` |
| 2 | **Absolutas del autor versionadas** (PII `Users/tomas` + layout; rompen reuso) | 🟠 Alto | RF-S2 (relativas/tokens) + RF-S6 (plantilla) + RF-S7 (grep `git ls-files`, ambas barras) |
| 3 | **`opencode.json` DoS de configuración** (MCPs a paths inexistentes; re-contaminación al "arreglar") | 🟠 Alto | RF-S6 (tokens + re-resolución) + AC-6 (JSON válido); **condición**: plantilla degradada con WARN, nunca `enabled` a token sin resolver; no ampliar `permission.bash` |
| 4 | **Borrado por exclusión abierta** tras quitar `$KnownApps` (pérdida de datos) | 🟠 Alto | RF-S4 (allowlist + fail-closed, hereda `kit-generico` RF-B1..B4) + AC-4 por código + fixture conservado+aviso; **condición**: no introducir `Remove-Item -Recurse` sobre raíz salvo allowlist validada |
| 5 | **Anonimización que borra trazabilidad** (conteos/locks/hashes) | 🟡 Medio | Decisiones 2+3 (solo el nombre → `AppXXX`; historial intacto; exclusiones por ruta en RF-S7/AC-1); **condición**: números y rutas relativas verbatim |
| 6 | **Re-contaminación futura** (el autor vuelve a pegar absolutas/dominio) | 🟡 Medio | RF-S7 (anti-regresión QA/CI, ambos sentidos AC-7) |
| 7 | **Licencias `🔒 pendiente`** en las 5 apps eliminadas del manifest | 🔵 Bajo | Al salir del manifest activo, el guardrail 8 se evalúa en cada proyecto consumidor, no en el kit; sin acción en esta tarea |

---

## 4. Recomendaciones para la implementación (`devops` / `qa-senior`)

1. **Manifest**: borrar la sección `aplicaciones:` activa (L100-140) y dejar SOLO el bloque de formato + ejemplo comentado (promover L142-161, con `url: TBD` y `destino: src/<app>`); conservar la entrada del historial `[2026-09-17]` como evidencia (no reescribir historial).
2. **Bootstrap**: L40 `-Apps` → `@()`; L57 eliminar `$KnownApps` y sus 4 usos (L107/L1757-1758/L1766/L1789) sustituyendo por descubrimiento `src/*` + flag; L61-69 sacar `tomasecastro` y `tomasgraph` de `$TrustedOwners`; absolutas L280/L285/L890/L930/L955/L971/L1026/L1041 → relativas/tokens con re-resolución en runtime.
3. **`opencode.json`**: plantilla con tokens (`__NODE__`, `<tu-proyecto>`, etc.), MCPs sin ruta real con `enabled: false` + WARN "ejecuta el bootstrap"; el bootstrap re-resuelve a rutas reales solo en local (jamás commiteadas).
4. **Borrado**: verificar AC-4 por código antes de cerrar T-I (ninguna destructiva por exclusión; `Remove-Item` solo sobre `$full` validado por allowlist + containment-check, patrón ya existente en L1263-1277).
5. **Anonimización**: `AppXXX` solo para el nombre; conteos, tamaños, hashes, rutas relativas y logs se conservan verbatim.
6. **Anti-regresión** (RF-S7/AC-7): grep dominio (los 5 nombres de dominio del proyecto, lista en `specs/solucion-generica/spec.md` RF-S1) + absolutas (`C:\Proyectos`, `C:/Users`, variantes) sobre `git ls-files`, exclusiones por ruta explícita (`testing/`, historial, incidentes), PASS en limpio + FAIL provocado con fixture señuelo.

---

## 5. Qué NO hacer

- ❌ **NO clonar/ejecutar nada de `tomasecastro/*`** desde el kit maestro; esas URLs salen del manifest activo en esta tarea.
- ❌ **NO commitear rutas absolutas** (`C:\…`, `C:/…`, `/Users/…`, `/home/…`) en ningún archivo versionado; rutas reales solo en runtime local.
- ❌ **NO versionar `opencode.json` con paths reales** ni con `enabled: true` apuntando a tokens sin resolver.
- ❌ **NO introducir borrado por exclusión** ("todo menos X") al quitar `$KnownApps`; solo allowlist de descarga/instalación + fail-closed.
- ❌ **NO anonimizar números/logs/hashes** al pasar hallazgos a `AppXXX`; solo el nombre.
- ❌ **NO reescribir historial** (testing reports, notas, incidentes) para "limpiar" el grep; son exclusiones explícitas, no deuda.
- ❌ **NO ampliar `permission.bash`** (`pip install *`, `python *` en allow) como parte de la re-resolución de MCPs.
- ❌ **NO loguear ni versionar contenido de `.opencode/config.json`** durante la re-resolución (hereda `blindaje-git.md` §1.1).

---

## 6. Checklist de seguridad

- [ ] Manifest del kit: cero apps concretas activas; solo formato + ejemplo comentado; historial conservado.
- [ ] `tomasecastro` y `tomasgraph` fuera de `$TrustedOwners` (fail-closed ya no los acepta).
- [ ] `-Apps` default `@()`; `$KnownApps` y lista fija eliminados (`Select-String` 0 matches); descubrimiento `src/*` o flag.
- [ ] Cero absolutas en versionados (`git ls-files`, ambas barras, 0 matches); relativas o tokens.
- [ ] `opencode.json` versionado sin absolutas; plantilla degradada con WARN; re-resolución solo en local; JSON válido antes/después.
- [ ] Ninguna rutina destructiva por exclusión abierta; fixture fuera-de-allowlist → conservado + aviso (AC-4).
- [ ] Hallazgos modo-real anonimizados solo en el nombre (`AppXXX`); números/logs/hashes verbatim.
- [ ] Test RF-S7 existe, PASS en limpio y FAIL con señuelo (ambos sentidos), exclusiones solo por ruta.
- [ ] `permission.bash` sin ampliaciones; `.opencode/config.json` ni logueado ni versionado.

---

## 7. Conclusión

**No bloquea la descontaminación, con condiciones.** Los 5 riesgos están cubiertos por el diseño RF-S1..RF-S7; el auditor añade 4 condiciones innegociables para la fase de implementación: **(1)** sacar `tomasecastro`/`tomasgraph` de `$TrustedOwners` (si no, el fail-closed sigue legitimando URLs del autor); **(2)** plantilla `opencode.json` degradada con WARN, nunca `enabled` a token sin resolver, sin ampliar `permission.bash`; **(3)** AC-4 verificable por código + fixture (ninguna destructiva por exclusión tras quitar `$KnownApps`); **(4)** anonimización solo del nombre, con números/logs/hashes verbatim y exclusiones del grep por ruta. Verificación de runtime (grep 0-matches, `Prepare-Apps` sin lista, manifest válido, anti-regresión ambos sentidos) queda para `qa-senior` (T-V1..T-V3).

---

## Referencias

- Spec: `Documentacion/Agents_IA_TECH/specs/solucion-generica/spec.md` (RF-S1..RF-S7, 8 ACs)
- Tarea: `[SOLUCION-GENERICA]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`
- Estado pre-descontaminación verificado por lectura: `dependencias-manifest.yml` (L100-140 apps activas, L142-161 placeholder), `scripts/plataformador-bootstrap.ps1` (L40 `-Apps`, L57 `$KnownApps`, L61-69 `$TrustedOwners`, L280-1041 absolutas), `opencode.json` (L65-97 absolutas)
- Revisiones previas (formato §§1-7): `seguridad/blindaje-git.md`, `seguridad/tokenslayer.md`, `seguridad/plataforma-bootstrap.md`
