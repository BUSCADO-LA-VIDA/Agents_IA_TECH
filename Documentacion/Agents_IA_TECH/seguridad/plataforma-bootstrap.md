# 🔒 Seguridad del diseño: `plataformador-bootstrap.ps1` — Instalador/Actualizador Único

> Revisión **de seguridad del DISEÑO** del instalador único (`plataformador-bootstrap.ps1`) que integra Spec-kit + MCPs + Graphify, con modelo de apps independientes, `Sync-TransversalKit` (Opción A) y descarga de apps/herramientas desde repos git.
> Enfocada en la **descarga desde git**: validación de URLs, supply chain, licencias, secrets, sobrescritura y ejecución de scripts descargados.
> Fuente: ADR-0003 `arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` y `specs/plataforma-bootstrap-instalador-unico/spec.md`.
> Autor: `security-auditor` (fase documental — paso 3º)

---

## 1. Análisis de riesgos del diseño de descarga desde git

### 1.1 Riesgo de URLs maliciosas / repo comprometido

El bootstrap clona repos **desde URLs definidas en `dependencias-manifest.yml`**. Si una URL apunta a un repo que el atacante controla (repo suplantado, typosquatting, cuenta robada, fork malicioso) o si el manifest se edita/inyecta, el bootstrap descargaría y copiaría código no confiable al proyecto.

**Puntos de validación necesarios:**
- **Solo `https://github.com/<owner>/<repo>`** (HTTPS forzado, nunca `http://`, `git://`, ni URLs arbitrarias/ssh).
- **Verificar el owner conocido** (allowlist de organizaciones/usuarios de confianza: `BUSCADO-LA-VIDA`, `microsoft`, `github`, `DeusData`, `mksglu`, `tomasgraph`, …).
- **Verificar la rama** (`main`/tag) y, si es crítico, **pinned a un commit/tag** (`version_actual` con `git checkout <sha>`), no solo `main` móvil.
- Rechazar el manifest si contiene URLs fuera del allowlist (fail-closed).

### 1.2 Riesgo de supply chain

El bootstrap copia **archivos de repos descargados al proyecto** (`.github/skills/`, `.opencode/`, `.specify/memory/`, `configs`). Si un repo está comprometido, ese "código malicioso en skills, scripts, configs" se integra directamente en el kit y es **cargado por el agente/IDE en cada sesión** (skills, hooks, instructions). Esto es el riesgo más severo porque el contenido no es "datos inertes": **se ejecuta/interpreta** (instrucciones de agentes, hooks `PreToolUse`, comandos de MCPs).

**Puntos de validación:**
- Tratar todo lo descargado como **no confiable** hasta ser revisado (regla de prompt defense del kit).
- No ejecutar scripts (`.ps1`, `.sh`, `.exe`) de repos descargados sin revisión manual.
- Considerar **hashes/pinning** de los artefactos copiados para detectar desvío entre sincronizaciones.
- Auditar los `.github/hooks/*` y skills antes de dejarlos activos (pueden exfiltrar contenido).

### 1.3 Riesgo de licencias

Cada repo/app debe verificarse **antes de integrar** (guardrail 8 del ADR-0001). El manifest ya registra licencias, pero algunas están **pendientes** (p. ej. `graphify`: `⚠️ pendiente de verificar`) y otras son **source-available no-MIT** (ELv2 de `context-mode`). Integrar software sin licencia verificada puede acarrear problemas legales de redistribución.

**Puntos de validación:**
- Toda dependencia debe tener `licencia: <SPDX o nombre>` **verificada** y con fecha, antes de copiarse al kit.
- Bloquear (fail-closed) cualquier repo con licencia `pendiente`/desconocida/prohibitiva.
- Respetar restricciones (ELv2: no SaaS, no quitar avisos; MIT: conservar copyright).

### 1.4 Riesgo de secrets

El bootstrap copia configs que **pueden contener credenciales**: `opencode.json`, `.vscode/mcp.json`, `.opencode/config.json`. El manifest/doc del kit lo advierte explícitamente (`.opencode/config.json` puede contener API key NVIDIA). Si esas configs se clonan y sincronizan (o se suben), se exponen secrets en el repo y/o en cada proyecto.

**Puntos de validación:**
- `opencode.json`/`.vscode/mcp.json` copiados por el kit deben ser **plantillas sin secrets**; las credenciales se inyectan localmente fuera del control de versiones.
- El bootstrap **nunca** debe sobrescribir configs locales que ya contienen credenciales con las del repo (o viceversa) — usar fusión/ignorar.
- Excluir `.opencode/config.json` (y cualquier archivo de secrets) de la copia/sync y del control de versiones.
- No volcar secretos a logs ni a salida del bootstrap (`-Verbose`, stderr).

### 1.5 Riesgo de sobrescritura

El bootstrap nivela estructura y sincroniza transversales. Si copia/mueve mal, puede **sobrescribir `Documentacion/<AppName>/`** (doc propia de cada app, "sagrada" por guardrail 1) o **pisar personalizaciones del usuario** (`.specify` personalizado, configs locales, skills locales, `src/` existente). La resolución de app activa por `cwd`/`-App` añade complejidad: un fallo de rutas podría apuntar a la doc equivocada.

**Puntos de validación:**
- `Sync-TransversalKit` solo copia la lista blanca de transversales y **nunca** entra a `Documentacion/<AppName>/`.
- Por defecto **no sobrescribir** personalizaciones existentes; solo con `-Force` y previa advertencia/diff.
- Idempotencia real: no escribir si ya existe y no difiere.
- Proteger `src/`, `tests/`, `.specify` por app, configs locales de la sobrescritura.

### 1.6 Riesgo de ejecución de scripts descargados

El bootstrap ya usa `Invoke-Expression` (línea 137) y ejecuta binarios (`& <exe>`, `npm`, `pip`, `Start-Process`). Si además **ejecuta scripts descargados de repos** (p. ej. `setup.ps1`, `install.sh`, hooks, binarios de `graphify`), hay **ejecución de código arbitrario** sin revisión. Es el vector más directo para un compromiso total del entorno del usuario.

**Puntos de validación:**
- **No ejecutar scripts descargados sin revisión manual previa.**
- Los binarios de herramientas (spec-kit `specify.exe`, graphify, MCPs) provienen de fuentes verificadas (allowlist + licencia + idealmente hash).
- Evitar `Invoke-Expression` sobre contenido no confiable; usar invocación explícita de rutas/commits pinned.
- Restringir el alcance del script: no pedir elevación (`RunAs`), no tocar fuera del proyecto salvo lo declarado.

---

## 2. Tabla de riesgos → mitigación

| # | Riesgo | Severidad | Mitigación |
|---|--------|:---------:|------------|
| 1 | **URLs maliciosas / repo suplantado** en el manifest | 🟠 Alto | Allowlist estricta (`https://github.com/<owner>/<repo>`), solo HTTPS, owner conocido, rama/tag fijo, `git checkout <sha>` para crítica. Fail-closed ante URLs fuera de allowlist. |
| 2 | **Supply chain**: repo comprometido inyecta código en skills/hooks/configs | 🔴 Crítico | Tratar lo descargado como **no confiable**; no ejecutar scripts descargados sin revisión; auditar skills/hooks antes de activarlos; hashing/pinning de artefactos; prompt defense. |
| 3 | **Licencias** no verificadas o restrictivas | 🟠 Alto | Verificar licencia antes de integrar (guardrail 8 ADR-0001); bloquear `pendiente`/desconocida/prohibitiva; respetar ELv2 (no SaaS, no quitar avisos) y MIT (conservar copyright). |
| 4 | **Secrets** en configs copiadas/sincronizadas | 🔴 Crítico | Configs del kit = plantillas **sin secrets**; credenciales locales fuera de VCS; excluir `.opencode/config.json` y archivos de secrets de la copia/sync; no volcar secrets a logs. |
| 5 | **Sobrescritura** de `Documentacion/<AppName>/` o personalizaciones | 🟠 Alto | `Sync-TransversalKit` copia solo allowlist y nunca entra a `Documentacion/<AppName>/`; no sobrescribir sin `-Force`+diff; idempotencia; proteger `src/`, `tests/`, `.specify`, configs locales. |
| 6 | **Ejecución de scripts descargados** (setup/install/binarios) | 🔴 Crítico | No ejecutar scripts descargados sin revisión; binarios de fuentes verificadas (allowlist+licencia+hash); evitar `Invoke-Expression` sobre contenido no confiable; sin `RunAs`; invocación de rutas pinned. |

---

## 3. Recomendaciones de uso seguro

1. **Validar URLs del manifest**: solo `https://github.com/<owner>/<repo>`, con owner en allowlist de confianza. Rechazar cualquier URL fuera de ese patrón o dueño (fail-closed).
2. **Verificar licencias antes de integrar** (guardrail 8 del ADR-0001): no copiar al kit ninguna dependencia con licencia `pendiente`/desconocida. Registrar fecha y resultado.
3. **No ejecutar scripts de repos descargados** (`setup.ps1`, `install.sh`, hooks, binarios) sin revisión manual previa del contenido.
4. **Usar `-DryRun` antes de aplicar** cualquier sincronización o descarga; revisar qué archivos tocaría (especialmente si algún path cae en `Documentacion/<AppName>/`).
5. **No sobrescribir personalizaciones del usuario**: `.specify` por app, configs locales, skills locales, `src/`/`tests/`. Solo `-Force` y con diff previo.
6. **No exponer credenciales** en configs copiadas: los `opencode.json`/`.vscode/mcp.json` del kit son plantillas; las credenciales se inyectan localmente y fuera de VCS. Excluir `.opencode/config.json`.
7. **Tratar todo lo descargado como no confiable** (prompt defense): validar skills, hooks e instructions antes de dejarlos activos.
8. **Verificar integridad** de herramientas críticas (hash/pinning de versión) y de la fuente antes de clonar/actualizar.

---

## 4. Qué NO hacer (anti-patrones)

- ❌ **NO permitir URLs arbitrarias** en `dependencias-manifest.yml` (nada fuera de `https://github.com/<owner>/<repo>` con owner en allowlist).
- ❌ **NO clonar/descargar sobre `http://`, `git://`, ssh ni protocolos no verificados.**
- ❌ **NO ejecutar scripts descargados de repos** (`setup.ps1`, `install.sh`, hooks, `.exe`) sin revisión manual.
- ❌ **NO usar `Invoke-Expression`** sobre contenido no confiable ni sobre strings construidas desde el manifest.
- ❌ **NO copiar/sincronizar configs que contienen secrets** (`opencode.json` con credenciales, `.opencode/config.json` con API key). El kit solo maneja plantillas sin secrets.
- ❌ **NO volcar secrets a logs**, salida del script ni stderr.
- ❌ **NO sobrescribir `Documentacion/<AppName>/`** en ninguna operación (frontera sagrada, guardrail 1).
- ❌ **NO sobrescribir personalizaciones del usuario** por defecto; sin `-Force` no se pisan.
- ❌ **NO integrar dependencias con licencia `pendiente`/desconocida** (guardrail 8 ADR-0001) — fail-closed.
- ❌ **NO descargar ramas móviles (`main`) para componentes críticos** sin al menos pinning por tag/commit.
- ❌ **NO pedir elevación (`RunAs`)** ni ampliar el alcance del script fuera del proyecto salvo lo estrictamente declarado.

---

## 5. Checklist de seguridad para el bootstrap

- [ ] Todas las URLs del manifest son `https://github.com/<owner>/<repo>` con owner en allowlist de confianza.
- [ ] Solo HTTPS; se rechazan `http://`, `git://`, ssh y URLs arbitrarias (fail-closed).
- [ ] El owner del repo está verificado y no es un fork suplantado/typosquatting.
- [ ] La rama/tag es fija; componentes críticos pinned a commit (`version_actual` con `git checkout <sha>`).
- [ ] `licencia` verificada con fecha para TODAS las dependencias antes de copiarlas al kit (guardrail 8 ADR-0001).
- [ ] Se respetan restricciones de licencia (ELv2: no SaaS/no quitar avisos; MIT: conservar copyright).
- [ ] No se ejecutan scripts descargados de repos sin revisión manual.
- [ ] No se usa `Invoke-Expression` sobre contenido no confiable.
- [ ] Configs del kit (`opencode.json`, `.vscode/mcp.json`) son plantillas **sin secrets**.
- [ ] `.opencode/config.json` y archivos de secrets están **excluidos** de copia/sync y de VCS.
- [ ] No se vuelcan secrets a logs ni a la salida del script.
- [ ] `Sync-TransversalKit` nunca toca `Documentacion/<AppName>/` (guardrail 1).
- [ ] No se sobrescriben personalizaciones por defecto; `-Force` requiere diff/advertencia.
- [ ] Idempotencia: repetir el bootstrap no produce cambios ni errores.
- [ ] `-DryRun` disponible y usado antes de aplicar cambios.
- [ ] El contenido descargado se trata como no confiable (prompt defense) antes de activar skills/hooks/instructions.
- [ ] El script no solicita elevación (`RunAs`) ni amplía su alcance fuera de lo declarado.
- [ ] Integridad verificada (hash/pinning) de herramientas críticas antes de clonar/actualizar.

---

## 6. Conclusión

**No hay vulnerabilidades críticas que bloqueen la adopción del diseño, siempre que se implementen los controles de este documento como requisitos no negociables del ADR-0003 y de la spec.** El diseño es fundamentalmente sólido: usa HTTPS/GitHub, tiene guardrails explícitos (1: frontera `Documentacion/<AppName>/`, 3: validar URLs/licencias), soporta `-DryRun` e idempotencia, y no ejecuta por diseño código fuente de las apps.

Los tres riesgos que deben **tratarse como severidad crítica/alta innegociable** durante la implementación (a cargo de `plataformador`/`devops`/`qa-senior`) son:

1. **Secrets en configs** (riesgo 4) — el kit debe manejar **solo plantillas sin credenciales** y excluir `.opencode/config.json` de la copia y del VCS. Es la mitigación más fácil de violar por descuido.
2. **Ejecución de scripts/binarios descargados** (riesgo 6) — ninguna ejecución de contenido de repos sin revisión; evitar `Invoke-Expression`.
3. **Supply chain de skills/hooks** (riesgo 2) — auditar skills, hooks e instructions de repos antes de dejarlos activos, y tratar todo lo descargado como no confiable.

**Recomendación**: **proceder con la implementación (APROBAR), condicionada a** que:
- los guardrails 1 y 3 se refuercen con **fail-closed** (rechazar URL fuera de allowlist y licencia no verificada);
- el bootstrap maneje **configs sin secrets** y excluya `.opencode/config.json`;
- **no ejecute** scripts descargados sin revisión;
- `qa-senior` valide con `-DryRun` + caso real (p. ej. `C:\Proyectos\Metatrader`) que **no toca `Documentacion/<AppName>/`** (paso 8º del plan) antes del rollout;
- se corra `npx ecc-agentshield scan` (paso 10º) sobre los cambios en `.github/`.

Con esas condiciones en los criterios de aceptación (spec), el diseño puede adoptarse sin bloqueo. Se recomienda además **cerrar la licencia `pendiente` de `graphify`** (guardrail 8) antes de copiarlo al kit, y registrar la atribución en `referencias.md`.

---

## Referencias

- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0003-plataforma-bootstrap-instalador-unico.md` — ADR fuente (guardrails, decisión, plan por fases).
- `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md` — Spec del instalador único.
- `Documentacion/Agents_IA_TECH/arquitectura/adr/adr-0001-ecosistema-documentacion-sin-ia.md` — Guardrail 8 (verificar licencias antes de integrar).
- `Documentacion/Agents_IA_TECH/seguridad/context-mode.md` — Revisión previa del kit (formato y precedente).
- `dependencias-manifest.yml` — Manifest de dependencias externas (URLs, ramas, versiones, licencias).
- `scripts/plataformador-bootstrap.ps1` — Script objetivo (usa `Invoke-Expression`, ejecuta binarios/npm/pip).