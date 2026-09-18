# Agents_IA_TECH 🧠⚡

> **Versión del documento:** 2026-09-19 (repo privado solo-git: Credential Manager + sparse-checkout `--no-cone`, temporal en `proyect_ext`, sin herramientas extra)
> **Kit transversal de agentes, skills y prompts para GitHub Copilot (VS Code) y OpenCode** — instalador/actualizador único, 11 agentes, 77 skills, 6 prompts.

**Creado:** 2026-06-25
**Reescritura como guía única de despliegue:** 2026-09-18 (tarea `[README-DESPLIEGUE]`)
**Repo maestro:** `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`
**Inspirado en:** [Ponytail](https://github.com/DietrichGebert/ponytail) (código mínimo) + [ECC](https://github.com/affaan-m/ECC) (workflow profesional)

---

## ⚙️ Qué hace la instalación

El kit es una **capa transversal portable** (no una aplicación): agentes, skills, prompts, reglas base, configuración de MCPs e índices. Se copia/sincroniza entre proyectos. La documentación y el código de cada aplicación viven fuera del kit y nunca se pisan.

El instalador/actualizador único es `scripts/plataformador-bootstrap.ps1` (ADR-0003). `sync-agents.ps1` es un wrapper que delega en su función `Sync-TransversalKit`.

### Qué instala el bootstrap

1. **Kit transversal** (merge desde el repo maestro, clone shallow):
   - `.github/` (agentes Copilot, prompts, skills, `copilot-instructions.md`, hooks, workflows)
   - `.opencode/` (agentes OpenCode, comandos, bin/lib de herramientas)
   - `.doc_agents/` (estructura por aplicación, capacidad base, reglas transversales)
   - `.specify/` base (`memory/constitution.md` — cada app/proyecto puede personalizar el suyo)
   - `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`
2. **MCPs** (VS Code `.vscode/mcp.json` + OpenCode `opencode.json`):
   - `context-mode` (índice FTS5+BM25 de docs, ejecución sandbox)
   - `codebase-memory-mcp` (grafo de conocimiento del código)
   - `markitdown` / `markitdown-mcp` (conversión de documentos a Markdown)
   - `tokenslayer-mcp-server` (esqueletos AST, call graphs, patch estructural)
   - Herramientas de apoyo vía `dependencias-manifest.yml`: `spec-kit` (github/spec-kit), `graphify` (tomasgraph/graphify). Ver `dependencias-manifest.yml` para URLs, versiones y licencias.
3. **Índices**: crea/actualiza índices de `codebase-memory-mcp` + `context-mode` y verifica que los MCPs responden.
4. **Estructura por app** (sin destruir lo existente): prepara `src/<App>/` (objetivo), `proyect_ext/` (herramientas de apoyo), `Documentacion/<AppName>/` por app (specs, ADRs — propia de cada app), resolución de app activa por `-App <nombre>` (precedencia máxima) o directorio de trabajo actual (si no hay coincidencia → modo `root`/kit).

### Qué NO toca nunca

- `Documentacion/<AppName>/` de ninguna app (ni la copia, ni la sobrescribe, ni la borra).
- `src/` y `tests/` de las apps (código fuente).
- `.opencode/config.json` (puede contener credenciales / API keys).
- Clones en `proyect_ext/` (herramientas de apoyo como `spec-kit`, `graphify`, `tokenslayer` — se actualizan por su propio flujo, no por el sync del kit).

### Política merge-no-mirror

- **Merge sin borrado**: el sync copia/actualiza transversales, nunca borra archivos locales que ya no existen upstream.
- **Hash + SKIP sin `-Force`**: si el archivo local es idéntico (hash) se marca SKIP; si difiere y hay personalización local, se conserva salvo que pases `-Force` (sobrescritura).
- **`-DryRun` para previsualizar**: simula todo el flujo sin escribir ningún archivo.
- **Huérfanos** (existen en `.github/` `.opencode/` `.doc_agents/` local pero ya no en el maestro): al sincronizar se **pregunta ¿borrar o conservar?** **Borrar** los elimina (limpio sin respaldo). **Conservar** los mueve a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` (fuera de los dirs de agentes, preservando estructura; si la fecha existe → sufijo hora) e informa qué se movió y dónde. Alcance: solo no-propios o personalizados en conflicto (`omitir` = propio, se deja en su lugar). Nunca `Documentacion/<AppName>/`. **Default seguro: conservar** (jamás auto-borrar). Flag `-OrphanAction Borrar|Conservar|Preguntar` para no interactivo. En `-DryRun` solo se informa.

---

## 🚀 Instalación (primera vez)

### Requisitos

- **PowerShell 7+ obligatorio** (`pwsh ≥ 7`). No funciona en Windows PowerShell 5.1. Compruébalo con `$PSVersionTable.PSVersion`.
- Recomendación (texto — ejecútala manualmente si aplica): `winget install --id Microsoft.PowerShell --source winget`.
- `git` disponible en el PATH. `Node.js ≥ 22.5` para los MCPs npm (`context-mode`, `codebase-memory-mcp`). `Python + pip` para `markitdown`.
- **Repo privado: autenticación obligatoria (solo `git`, sin herramientas extra).** Este kit es de uso privado; el repo maestro es privado. Sin auth, `raw.githubusercontent.com` devuelve **404** y `git clone` pide credenciales. Usa **Git Credential Manager** (incluido en Git para Windows): el primer `git clone` abre el login por navegador una vez y cachea las credenciales. Compruébalo con `git credential-manager --version` (si falta, reinstala Git para Windows con la opción Git Credential Manager).

### Pasos

En la **raíz de tu proyecto** (ej: `C:\Proyectos\Mi-Proyecto\`):

```powershell
# 1. Descargar el instalador único + wrapper desde el repo maestro
# Vía A (recomendada, repo privado, solo git): sparse-checkout en temporal fuera de la raíz
# (trae solo 2 archivos, sin clonar todo; la raíz queda limpia)
# NOTA: --no-cone es obligatorio (los patrones son archivos, no directorios;
# sin él falla con "is not a directory... rerun with --skip-checks")
New-Item -ItemType Directory -Path "proyect_ext" -Force | Out-Null
git clone --depth 1 --filter=blob:none --sparse https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH.git proyect_ext\agents-temp
git -C proyect_ext\agents-temp sparse-checkout set --no-cone scripts/plataformador-bootstrap.ps1 sync-agents.ps1
New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
Copy-Item "proyect_ext\agents-temp\scripts\plataformador-bootstrap.ps1" -Destination "scripts\plataformador-bootstrap.ps1" -Force
Copy-Item "proyect_ext\agents-temp\sync-agents.ps1" -Destination "sync-agents.ps1" -Force
Remove-Item proyect_ext\agents-temp -Recurse -Force
```

> Alternativa válida: usar `$env:TEMP` en vez de `proyect_ext\agents-temp` (ej. `$tmp = Join-Path $env:TEMP "agents-kit-temp"` y operar sobre `$tmp`). Fuera de la raíz en ambos casos; el script hace su trabajo y no queda rastro en el proyecto.

> ⚠️ **Repo privado**: la descarga anónima con `Invoke-WebRequest` directo a `raw.githubusercontent.com` devuelve **404** (GitHub no revela repos privados sin auth). Usa la **Vía A** (el primer `git clone` abre el login por navegador vía Git Credential Manager y cachea). Vía B (misma máquina, sin red): copia local con `Copy-Item "<ruta-maestro>\scripts\plataformador-bootstrap.ps1" -Destination "scripts\"` y `Copy-Item "<ruta-maestro>\sync-agents.ps1" -Destination "."`. Último recurso (PAT manual, no recomendado): `Invoke-WebRequest -Headers @{Authorization="Bearer TU_PAT"} -Uri "<raw-url>" -OutFile ...` (el PAT necesita permiso `repo`; no lo pegues en docs ni scripts versionados).

```powershell
# 2. Previsualizar (recomendado)
.\scripts\plataformador-bootstrap.ps1 -DryRun

# 3. Instalar
.\scripts\plataformador-bootstrap.ps1
```

Variantes:

```powershell
# App activa explícita (si el proyecto tiene varias apps)
.\scripts\plataformador-bootstrap.ps1 -App trading_bot

# Solo sincronizar el kit transversal (equivale a sync-agents)
.\scripts\plataformador-bootstrap.ps1 -SyncOnly
.\sync-agents.ps1

# Forzar sobrescritura de transversales personalizados
.\scripts\plataformador-bootstrap.ps1 -Force
```

### Verificación

1. Abre tu proyecto en **VS Code**. Si el bootstrap reinició VS Code, vuelve a abrirlo.
2. Abre **Copilot Chat** (`Ctrl+Shift+I`), escribe `/` — debes ver `plan`, `tdd`, `security-review`, `build-fix`, `refactor`, `pensar`.
3. En el selector de agente elige un rol (p. ej. **Arquitecto**, **QA Senior**).
4. En **OpenCode** (`opencode` en terminal) comprueba que los agentes responden.
5. Verifica MCPs: `codebase-memory-mcp`, `context-mode`, `markitdown`, `tokenslayer` responden (el bootstrap ya hace esta comprobación al final; si falla, registra el fallo en `pendientes-implementacion.md`).

### Qué esperar al final

- Kit transversal sincronizado (`.github/`, `.opencode/`, `.doc_agents/`, `.specify` base, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`).
- MCPs configurados en `.vscode/mcp.json` + `opencode.json` e índices creados.
- Estructura por app preparada (`src/<App>/`, `Documentacion/<AppName>/` por app si aplica, `proyect_ext/` intacto).
- Spec-kit orientado a la app activa (`.specify` activo + `Documentacion/<App>/specs/`).
- `Documentacion/<AppName>/`, `src/`, `tests/`, `.opencode/config.json` intactos.

---

## 🔄 Actualización

> **Repo privado**: el sync hace `git clone` del maestro. Sin auth configurada (`gh auth login`), el clon pide credenciales o falla. Asegura la autenticación antes de sincronizar.

```powershell
# Previsualizar primero (recomendado)
.\sync-agents.ps1 -DryRun

# Actualizar el kit transversal
.\sync-agents.ps1

# Equivalente directo contra el bootstrap
.\scripts\plataformador-bootstrap.ps1 -SyncOnly

# Si quieres forzar la sobrescritura de personalizaciones locales
.\sync-agents.ps1 -Force

# Huérfanos sin pregunta (no interactivo): Borrar | Conservar | Preguntar (default)
.\sync-agents.ps1 -OrphanAction Conservar
```

### Qué cambia y qué se conserva

- **Cambia**: transversales (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md` base, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`).
- **Se conserva**: `Documentacion/<AppName>/`, `src/`, `tests/`, `.opencode/config.json`, clones en `proyect_ext/`, y tus personalizaciones locales de transversales (salvo `-Force`).
- **Commits sugeridos** (conventional commits):
  - `chore: sync agents from upstream`
  - `chore: sync transversal kit (Sync-TransversalKit)`
  - Con `-Force`: `chore!: force sync transversal kit (overwrites local customizations)`
- **Huérfanos** (qué son): archivos que existen en tu `.github/` `.opencode/` `.doc_agents/` local pero ya no existen en el repo maestro (eliminados upstream). Al sincronizar, el script los detecta y **pregunta por cada caso (o en lote): ¿borrar o conservar?**
  - **Borrar**: elimina los huérfanos, implementación en limpio (sin respaldo).
  - **Conservar**: mueve cada huérfano a `revisar_manualmente\yyyymmdd\<ESTRUCTURA_ORIGINAL>` (fuera de los directorios de agentes, preservando la estructura de carpetas; si la carpeta del día existe, agrega sufijo de hora) e informa qué se movió y dónde quedó. Revísalo ahí y bórralo a mano solo si sobra.
  - Alcance: solo no-propios o personalizados que causan conflicto (`omitir` = dejarlo en su lugar por ser propio). Nunca toca `Documentacion/<AppName>/`.
  - **Default seguro: conservar** (jamás auto-borra). Flag `-OrphanAction Borrar|Conservar|Preguntar` para modo no interactivo. En `-DryRun` solo informa, no borra ni mueve.

---

## 🤖 Agentes (11) — Cómo usarlos

Los **agentes** son roles especializados. Existen en paralelo en `.github/agents/<nombre>.agent.md` (Copilot) y `.opencode/agents/<nombre>.md` (OpenCode). Mantenlos en sync.

### Cómo seleccionar un agente

1. Abre **Copilot Chat** (`Ctrl+Shift+I`).
2. En el **selector de agente** (dropdown junto al campo de texto), elige el rol.
3. Haz tu consulta — el agente usa sus skills automáticamente.

### Flujo Design-First

```text
💭 Duda/Idea ──▶  🧠 Pensador
                        │
                        ├── ❓ ¿Idea completa? → preguntar al usuario
                        │
                        ├──▶  🏗️ Arquitecto (decisiones, ADRs)
                        ├──▶  📝 Documentador (specs, flujos)
                        ├──▶  🔒 Security Auditor (validación diseño)
                        │
                        ├── ❓ ¿Documentado? ¿Implementar? → preguntar al usuario
                        │
                        └──▶  🌐 API Developer + ⚛️ Frontend + 🐳 DevOps + 🧪 QA
                              (solo si el usuario aprueba)
```

**Regla de oro:** Si no está documentado, no existe. Los implementadores **solo implementan lo documentado**. Si falta spec, derivan a un documental y registran la tarea en `pendientes-implementacion.md`.

| Agente | Tier | Rol | Escribe código |
|--------|------|-----|:--------------:|
| 🧠 **pensador** | Documental | Orquesta dudas → documentación → approval gate. Nunca toca código | ❌ |
| 🏗️ **arquitecto** | Documental | Arquitectura, estructura, ADRs | ❌ |
| 📝 **documentador** | Documental | Specs, flujos, requisitos | ❌ |
| 🔒 **security-auditor** | Documental | Auditoría y tests de seguridad | ❌ |
| 🌐 **api-developer** | Implementador | APIs REST, backend, modelos, DBs | ✅ |
| ⚛️ **frontend-developer** | Implementador | Componentes UI, vistas, estilos | ✅ |
| 🐳 **devops** | Implementador | Infraestructura, despliegue | ✅ |
| 🧪 **qa-senior** | Implementador | Tests (diseña y ejecuta) | ✅ |
| 🌊 **gitflow** | Tooling | Operaciones git, branching, PRs, reverts | ✅ (git) |
| 🧰 **solucionador** | Plataforma | Diagnóstico remoto | ✅ |
| 🏭 **plataformador** | Plataforma | Nivelación de proyectos, opera el bootstrap | ✅ |

> 💡 Documentales solo escriben en `Documentacion/<AppName>/`, `.github/`, `.opencode/`, `.doc_agents/`, `README.md`. Implementadores escriben código de app (`src/`, `tests/`).

### Ejemplos de uso

```text
🧑‍💻 "Necesito crear un módulo de facturación"
→ 1. Arquitecto   → arquitectura, estructura, ADRs
→ 2. Documentador → specs y flujos
→ 3. API Developer → implementa lo documentado
→ 4. QA Senior     → tests de lo implementado
→ 5. Security Auditor → audita antes del deploy

🧑‍💻 "¿Cómo manejo autenticación de usuarios externos?"
→ /pensar o agente 🧠 Pensador → analiza, documenta (OAuth2/JWT/SAML → ADR),
  pregunta "¿Querés que lo implemente?" → SÍ: API + Frontend + QA; NO: queda documentado.

🧑‍💻 "Revísame la seguridad antes del deploy"
→ Security Auditor → secrets, OWASP, dependencias.

🧑‍💻 "Agrega validación al formulario de login"
→ API + Frontend implementan; si falta spec, deriva a Documentador primero.
```

---

## 🎯 Prompts (Slash Commands)

Escribe `/` en Copilot Chat:

| Prompt | Uso | Lo que hace |
|--------|-----|-------------|
| `/plan` | Feature compleja | Requisitos → plan por fases con dependencias y riesgos |
| `/tdd` | Nueva feature o bug fix | RED → GREEN → IMPROVE con 80%+ cobertura |
| `/security-review` | Antes de release | OWASP Top 10, secrets, dependencias, rate limiting |
| `/build-fix` | Error de build/CI | Diagnostica y resuelve incrementalmente |
| `/refactor` | Mantenimiento | Código muerto, simplificación, abstracciones innecesarias |
| `/pensar` | Duda de diseño | Analiza la duda, documenta con agentes, pregunta si implementar |

---

## 🧠 Skills por Categoría

Cada skill es un `SKILL.md` con conocimiento experto. Las skills viven solo en `.github/skills/<categoria>/<nombre>/SKILL.md` (sin espejo OpenCode) y se asignan a los agentes según dominio.

| Categoría | Skills | Cantidad |
|-----------|--------|:--------:|
| 📝 **Documentación** | documentation-lookup, code-tour, codebase-onboarding, ADRs, article-writing, knowledge-ops, repo-scan, workspace-surface-audit | 8 |
| 🔒 **Seguridad** | security-review, security-scan, security-bounty-hunter, safety-guard, gateguard, hipaa-compliance, healthcare-phi-compliance, defi-amm-security, llm-trading-agent-security, django-security | 10 |
| 🐳 **Docker** | docker-patterns, kubernetes-patterns, deployment-patterns, flox-environments, uncloud | 5 |
| 🐍 **Python** | python-patterns, python-testing, django-patterns, django-tdd, django-verification, django-celery, fastapi-patterns, pytorch-patterns, mle-workflow, generating-python-installer | 10 |
| ☕ **Java** | java-coding-standards, springboot-patterns, springboot-security, springboot-tdd, springboot-verification, jpa-patterns, quarkus-patterns, quarkus-security, quarkus-tdd | 9 |
| 🔷 **C#/.NET** | dotnet-patterns, csharp-testing, blender-motion-state-inspection, windows-desktop-e2e | 4 |
| 🌐 **API** | api-design, api-connector-builder, backend-patterns, mcp-server-patterns, postgres-patterns, prisma-patterns, redis-patterns | 7 |
| 🧪 **Testing** | tdd-workflow, e2e-testing, verification-loop, browser-qa, benchmark, benchmark-methodology, benchmark-optimization-loop, agent-eval, eval-harness, error-handling, ai-regression-testing, cpp-testing, golang-testing, rust-testing | 14 |
| 🏗️ **Arquitectura** | hexagonal-architecture, coding-standards, production-audit | 4* |
| ⚛️ **Frontend** | frontend-patterns, react-patterns, react-testing, react-performance, laravel-patterns, laravel-security | 6 |
| ✨ **Spec-kit** | speckit-specify, speckit-plan, speckit-tasks, speckit-converge, speckit-implement, speckit-analyze, speckit-checklist | 7 |
| | **Total aprox.** | **77+** |

> \* La skill `error-handling` aparece en testing y arquitectura también la referencia.

### 🛠️ Personalización

1. **Reglas de proyecto**: edita `copilot-instructions.md` (Copilot) / `AGENTS.md` (base común).
2. **Skills propias**: `.github/skills/<categoria>/<nombre>/SKILL.md` siguiendo el formato existente.
3. **Agentes personalizados**: en ambos arneses (`.github/agents/` + `.opencode/agents/`).
4. **Prompts**: `.github/prompts/<nombre>.prompt.md` ↔ `.opencode/commands/<nombre>.md`.

---

## ⚙️ Reglas Base (copilot-instructions.md / AGENTS.md)

`copilot-instructions.md` es el archivo canónico de reglas base (duplicado en `AGENTS.md`). El `opencode.json` apunta a él vía `instructions`.

| Regla | Descripción |
|-------|-------------|
| 🌐 **Idioma** | Piensa en inglés, responde en español, código/docs en inglés |
| 🏆 **Ponytail Ladder** | ¿Necesita existir? → ¿Ya está? → ¿Stdlib? → ¿Nativo? → ¿Dependencia? → ¿Una línea? → recién ahí escribe |
| 📏 **Code Rules** | Sin abstracciones innecesarias, <50 líneas por función, <400 por archivo, sin mutación in-place, nesting ≤ 4 |
| 🛡️ **Seguridad** | Checklist pre-commit: secrets, validación, SQLi, XSS, auth, rate limiting (`npx ecc-agentshield scan`) |
| 🧪 **Testing** | 80%+ cobertura, 3 capas (Unit → Integration → E2E), estructura AAA |
| 🔄 **Workflow** | Research → Plan → TDD → Review → Commit (conventional commits) |
| 📋 **Plan → Document → Implement** | El `pensador` orquesta en ese orden; si cambian las specs, el ciclo se reinicia |

---

## 📋 Flujo de Trabajo Recomendado

```text
1. 🔍 Investigación → entender el problema, buscar implementaciones existentes
2. 📋 /plan        → planificar por fases
3. 🧪 /tdd         → tests primero, implementar, refactorizar
4. 🔒 /security-review → auditar antes de commitear
5. 🔄 /refactor    → limpiar código muerto y simplificar
6. ✅ Commit       → conventional commit + PR summary
```

---

## 📂 Memoria del Proyecto — `Documentacion/<AppName>/` (propia, nunca se copia)

Cada aplicación tiene su carpeta aislada `Documentacion/<AppName>/` (specs, planes, ADRs, memoria). El kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `.specify` base, `AGENTS.md`, `opencode.json`) **se copia/sincroniza** entre proyectos. `Documentacion/<AppName>/` **es propia de cada app y NUNCA se copia** (ver `.doc_agents/estructura-aplicacion.md`).

```text
Documentacion/
├── <AppName>/
│   ├── specs/        ← spec.md, plan.md, tasks.md (Spec-kit escribe aquí)
│   ├── arquitectura/adr/ ← decisiones de la app
│   └── agentes/      ← extensiones de agentes por app
└── Agents_IA_TECH/   ← doc propia de este repo (el kit)
```

Los agentes documentales la usan como contexto **opcional**: si existe `00-indice.md` lo leen, si no, trabajan con el estándar. El sync **nunca** la toca.

---

## 🧩 Compatibilidad

| Herramienta | Compatible | Notas |
|-------------|:----------:|-------|
| **VS Code + GitHub Copilot** | ✅ | Experiencia completa: agentes, skills, prompts |
| **OpenCode** | ✅ | Compatibilidad completa vía `.opencode/` |
| **Copilot CLI (GitHub CLI)** | ✅ | Vía `AGENTS.md` — subagentes por `runSubagent` |
| **Cursor** | ⚠️ | Skills funcionan, prompts requieren adaptación |
| **JetBrains AI** | ❌ | No soporta formato `.github/` |

---

## 🙈 `.gitignore` — qué no se versiona

- Clones de herramientas: `proyect_ext/*` (spec-kit, graphify, tokenslayer y demás descargas).
- MCPs generados con secretos potenciales: `.vscode/mcp.json` (generado por el bootstrap), `.opencode/config.json` (credenciales / API keys — nunca commitear, nunca sobreescribir en sync).
- Secretos en general: `.env`, `*.key`, `*.pem`, tokens.
- Índices locales y cachés (codebase-memory, context-mode) si los generas fuera del repo.

---

## 🔒 Seguridad — AgentShield

Escáner que corre en CI al modificar `.github/`:

```powershell
npx ecc-agentshield scan
```

Detecta secrets hardcodeados (API keys, tokens, passwords), permisos mal configurados y vulnerabilidades en configuraciones de agentes.

---

## 📚 Recursos

- **[Ponytail](https://github.com/DietrichGebert/ponytail)** — Filosofía de código mínimo (MIT)
- **[VS Code Copilot](https://code.visualstudio.com/docs/copilot/overview)** — Documentación oficial
- **[Custom Instructions](https://code.visualstudio.com/docs/copilot/customizing-copilot)** — Guía de `copilot-instructions.md`
- **Repo maestro:** `https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH`
- **ADRs del kit:** `Documentacion/Agents_IA_TECH/arquitectura/adr/` (ver ADR-0003 bootstrap único)
- **Spec del bootstrap:** `Documentacion/Agents_IA_TECH/specs/plataforma-bootstrap-instalador-unico/spec.md`

---

## 🔄 Mantenimiento de este documento

Cuando se actualicen procesos que puedan afectar a este documento (**bootstrap**, **sync**, **MCPs**, **estructura por app**, **agentes/skills/prompts**), **este README debe actualizarse en la misma tarea** para que no quede desactualizado (instalación, verificación, listas de transversales/excluidos, dependencias del manifest).

Punto de control: la tarea `[README-DESPLIEGUE]` en `Documentacion/Agents_IA_TECH/pendientes-implementacion.md`. Toda tarea futura que cambie el despliegue debe referenciarla o crear su sucesora y tocar este archivo en el mismo commit/PR.

---

## 🤝 Contribuir

1. **Skills**: crea `.github/skills/<categoria>/<nombre>/SKILL.md` — sigue el formato existente.
2. **Agentes**: crea el par `.github/agents/<nombre>.agent.md` + `.opencode/agents/<nombre>.md` (sync entre arneses).
3. **Prompts**: crea el par `.github/prompts/<nombre>.prompt.md` ↔ `.opencode/commands/<nombre>.md`.
4. **PR**: descripción clara, conventional commit (`feat`, `fix`, `docs`, `chore`…).

---

## 📄 Licencia

MIT — haz lo que quieras, usa esto en todos tus proyectos.
