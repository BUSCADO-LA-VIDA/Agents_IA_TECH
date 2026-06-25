# Agents_IA_TECH 🧠⚡

> **Kit de agentes y skills para GitHub Copilot** — 77 skills especializadas + 7 agentes listos para usar en cualquier proyecto.

**Creado:** 2026-06-25  
**Inspirado en:** [Ponytail](https://github.com/DietrichGebert/ponytail) (código mínimo) + [ECC](https://github.com/affaan-m/ECC) (workflow profesional)

---

## 📖 ¿Qué es esto?

Una carpeta `.github/` portátil que transforma **GitHub Copilot en VS Code** en un equipo de desarrollo con estándares profesionales. Incluye:

- **77 skills** de dominio (arquitectura, seguridad, testing, Docker, APIs, frontend, Python, Java, C#, etc.)
- **7 agentes especializados** con roles definidos (arquitecto, QA, security auditor, devops, etc.)
- **5 prompts** tipo slash command (`/plan`, `/tdd`, `/security-review`, etc.)
- **Reglas base** estilo "Senior Dev Lazy" (Ponytail): código mínimo, reutilización, YAGNI
- **AgentShield** — escaneo de seguridad automático

> ✅ **Funciona con Copilot Chat (Ctrl+Shift+I) en VS Code.**  
> Solo copia la carpeta `.github/` a tu proyecto y ya está todo listo.

---

## 🚀 Instalación

Cada proyecto tiene su propio git. Copias la carpeta `.github/` y cada proyecto queda independiente. Cuando este repo se actualice, puedes descargar los cambios y copiarlos de nuevo.

```bash
# 1. En la raíz de tu proyecto, clona SOLO .github/
git clone https://github.com/TU_USER/Agents_IA_TECH.git /tmp/agents-ia-tech
cp -r /tmp/agents-ia-tech/.github/ .github/
rm -rf /tmp/agents-ia-tech

# 2. ¡Listo! Ya puedes usar los agentes y skills
```

### Mantener actualizado

```bash
# Cuando haya actualizaciones en Agents_IA_TECH
git clone https://github.com/TU_USER/Agents_IA_TECH.git /tmp/agents-ia-tech
cp -r /tmp/agents-ia-tech/.github/ .github/
rm -rf /tmp/agents-ia-tech
# Revisa los cambios con git diff y commitéalos si te sirven
```

> 💡 **Tip:** Si quieres trackear cambios específicos, copia skill por skill en lugar de todo `.github/`.

### Verificar que funciona

1. Abre tu proyecto en **VS Code**
2. Abre **Copilot Chat** (`Ctrl+Shift+I`)
3. Escribe `/` — deberías ver los prompts disponibles: `plan`, `tdd`, `security-review`, `build-fix`, `refactor`
4. En el selector de agente (junto al input de chat), elige un rol como **"Arquitecto"** o **"QA Senior"**

> ℹ️ Si no ves los prompts, asegúrate de que `copilot-instructions.md` esté en `.github/` y que **GitHub Copilot** esté habilitado.

---

## 🏗️ Estructura del Proyecto

```
.github/
├── copilot-instructions.md       ← Reglas base siempre activas
├── progreso-skills.md            ← Estado de todas las skills
├── AGENTS.md                     ← Definición de agentes ECC
├── agents/                       ← 7 agentes especializados
│   ├── arquitecto.agent.md
│   ├── documentador.agent.md
│   ├── security-auditor.agent.md
│   ├── devops.agent.md
│   ├── qa-senior.agent.md
│   ├── api-developer.agent.md
│   └── frontend-developer.agent.md
├── prompts/                      ← Slash commands
│   ├── plan.prompt.md
│   ├── tdd.prompt.md
│   ├── security-review.prompt.md
│   ├── build-fix.prompt.md
│   └── refactor.prompt.md
├── skills/                       ← 77 skills organizadas por dominio
│   ├── api/ (7)
│   ├── arquitectura/ (4)
│   ├── csharp/ (4)
│   ├── docker/ (5)
│   ├── documentacion/ (8)
│   ├── frontend/ (6)
│   ├── java/ (9)
│   ├── python/ (10)
│   ├── seguridad/ (10)
│   └── testing/ (14)
└── workflows/
    └── agentshield.yml           ← Security scan CI
```

---

## 🤖 Agentes — Cómo usarlos

Los **agentes** son roles especializados que puedes seleccionar en Copilot Chat. Cada uno tiene acceso a skills específicas y un enfoque distinto.

### Cómo seleccionar un agente

1. Abre **Copilot Chat** (`Ctrl+Shift+I`)
2. En el **selector de agente** (dropdown junto al campo de texto), elige el rol deseado
3. Haz tu consulta — el agente usará sus skills automáticamente

### Flujo de trabajo: Design-First

```
📝 Arquitecto / Documentador  ──documentan──▶  🐳 DevOps
                                                 🧪 QA Senior
🔒 Security Auditor  ──validan──▶                🌐 API Developer
                                                 ⚛️ Frontend Developer
                    ╰── Solo documentan ──╯       ╰── Solo implementan lo documentado ──╯
```

**Regla de oro:** Si no está documentado, no existe. Los agentes que escriben código **solo implementan lo que ya está documentado**. Si falta documentación, llaman a los agentes de documento para crearla primero.

### Agentes Disponibles

| Agente | Rol | Escribe código | Tools |
|--------|-----|:--------------:|-------|
| 📝 **Documentador** | Documenta especificaciones, flujos de trabajo y requisitos | ❌ | read, search |
| 🏗️ **Arquitecto** | Documenta la arquitectura, crea estructura y define cómo usarla correctamente | ❌ | read, search, agent |
| 🔒 **Security Auditor** | Ejecuta tests de seguridad y auditoría | ❌ | read, search, execute |
| 🐳 **DevOps** | Despliega configuraciones de infraestructura | ✅ | read, search, edit, execute |
| 🧪 **QA Senior** | Diseña y ejecuta tests. Edita y aprende a testear si se le pide | ✅ | read, search, edit, execute |
| 🌐 **API Developer** | Implementa APIs REST, backend, modelos y DBs | ✅ | read, search, edit, execute |
| ⚛️ **Frontend Developer** | Implementa componentes UI, vistas y estilos | ✅ | read, search, edit |

> 💡 Los agentes que **no escriben código** solo documentan, especifican y auditan.  
> Los agentes que **sí escriben código** implementan lo documentado; si algo no está documentado, piden que se documente primero.

### Ejemplos de uso

```
🧑‍💻 "Necesito crear un módulo de facturación"
→ 1. Arquitecto   → documenta arquitectura, estructura, decisiones (ADRs)
→ 2. Documentador → documenta especificaciones y flujos de trabajo
→ 3. API Developer → implementa lo documentado
→ 4. QA Senior     → escribe tests de lo implementado
→ 5. Security Auditor → audita seguridad antes del deploy

🧑‍💻 "Revísame la seguridad antes del deploy"
→ Selecciona agente: Security Auditor
→ Escanea secrets, OWASP, dependencias

🧑‍💻 "Agrega validación al formulario de login"
→ API Developer implementa validación backend
→ Frontend Developer implementa validación frontend
→ Si falta especificación, deriva a Documentador primero
```

---

## 🎯 Prompts (Slash Commands)

Escribe `/` en Copilot Chat para ver los comandos disponibles:

| Prompt | Uso | Lo que hace |
|--------|-----|-------------|
| `/plan` | Feature compleja | Analiza requisitos, genera plan por fases con dependencias y riesgos |
| `/tdd` | Nueva feature o bug fix | Ciclo TDD completo: RED → GREEN → IMPROVE con 80%+ cobertura |
| `/security-review` | Antes de release | Auditoría OWASP Top 10, secrets, dependencias, rate limiting |
| `/build-fix` | Error de build/CI | Diagnostica errores de compilación y los resuelve incrementalmente |
| `/refactor` | Mantenimiento | Identifica código muerto, simplifica, elimina abstracciones innecesarias |

---

## 🧠 Skills por Categoría

Cada skill es un archivo `SKILL.md` con conocimiento experto sobre un tema específico. Las skills se asignan a los agentes según su dominio.

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
| | **Total** | **77** |

> \* La skill `error-handling` aparece en testing (4) y arquitectura también la referencia, total únicos.

---

## 🔒 Seguridad — AgentShield

Incluye **AgentShield** — un escáner de seguridad que se ejecuta automáticamente en CI al modificar `.github/`.

```yaml
# Se ejecuta con cada push que toque .github/
npx ecc-agentshield scan
```

**Qué detecta:**
- 🔑 Secrets hardcodeados (API keys, tokens, passwords)
- ⚙️ Permisos mal configurados
- 🛡️ Vulnerabilidades en configuraciones de agentes

---

## 📦 Cómo implementarlo en tus proyectos

Todos los proyectos siguen el mismo patrón: cada uno con su propio git, `.github/` copiado desde este repo.

```bash
# En cualquier proyecto (nuevo o existente)
git clone https://github.com/TU_USER/Agents_IA_TECH.git /tmp/agents-ia-tech
cp -r /tmp/agents-ia-tech/.github/ .github/
rm -rf /tmp/agents-ia-tech
```

### 🛠️ Personalización

Puedes adaptar el template a tu stack:

1. **Edita `copilot-instructions.md`** — agrega reglas específicas de tu proyecto (convenciones, frameworks, etc.)
2. **Crea skills propias** — agrega carpetas en `.github/skills/<categoria>/<nombre>/SKILL.md`
3. **Crea agentes personalizados** — agrega archivos en `.github/agents/<nombre>.agent.md`
4. **Agrega prompts** — crea archivos en `.github/prompts/<nombre>.prompt.md`

---

## ⚙️ Reglas Base (copilot-instructions.md)

El archivo `copilot-instructions.md` contiene las reglas que Copilot sigue **siempre**, sin importar qué agente esté activo:

| Regla | Descripción |
|-------|-------------|
| 🌐 **Idioma** | Piensa en inglés, responde en español, código en inglés |
| 🏆 **Ponytail Ladder** | ¿Necesita existir? → ¿Ya está en el código? → ¿Stdlib? → ¿Lenguaje nativo? → ¿Dependencia? → ¿Una línea? → Recién ahí escribe |
| 📏 **Code Rules** | Sin abstracciones innecesarias, <50 líneas por función, <400 por archivo, sin mutación in-place |
| 🔍 **TokenSlayer** | Usa `tokenslayer-structural-summary` antes de leer/editar código (ahorra ~90% tokens) |
| 🛡️ **Seguridad** | Checklist pre-commit: secrets, validación, SQLi, XSS, auth, rate limiting |
| 🧪 **Testing** | 80%+ cobertura, 3 capas (Unit → Integration → E2E), AAA structure |
| 🔄 **Workflow** | Research → Plan → TDD → Review → Commit (conventional commits) |

---

## 📋 Flujo de Trabajo Recomendado

```
1. 🔍 Investigación → entender el problema, buscar implementaciones existentes
2. 📋 /plan        → planificar la solución por fases
3. 🧪 /tdd         → escribir tests primero, implementar, refactorizar
4. 🔒 /security-review → auditar seguridad antes de commitear
5. 🔄 /refactor    → limpiar código muerto y simplificar
6. ✅ Commit       → conventional commit + PR summary
```

---

## 🧩 Compatibilidad

| Herramienta | Compatible | Notas |
|-------------|:----------:|-------|
| **VS Code + GitHub Copilot** | ✅ | Experiencia completa: agentes, skills, prompts |
| **Copilot CLI (GitHub CLI)** | ✅ | Vía `AGENTS.md` — subagentes por `runSubagent` |
| **Cursor** | ⚠️ | Skills funcionan, prompts requieren adaptación |
| **Claude Code / Codex** | ⚠️ | Requiere instalar ECC completo: `npx ecc-universal install` |
| **JetBrains AI** | ❌ | No soporta formato `.github/` |

---

## 📚 Recursos

- **[Ponytail](https://github.com/DietrichGebert/ponytail)** — Filosofía de código mínimo (MIT)
- **[ECC](https://github.com/affaan-m/ECC)** — Everything Claude Code — framework de agentes (MIT)
- **[VS Code Copilot](https://code.visualstudio.com/docs/copilot/overview)** — Documentación oficial
- **[Custom Instructions](https://code.visualstudio.com/docs/copilot/customizing-copilot)** — Guía de `copilot-instructions.md`

---

## 🤝 Contribuir

¿Te falta una skill? ¿Un agente nuevo? Las contribuciones son bienvenidas:

1. **Skills**: crea `skills/<categoria>/<nombre>/SKILL.md` — sigue el formato de las existentes
2. **Agentes**: crea `agents/<nombre>.agent.md` con frontmatter YAML
3. **Prompts**: crea `prompts/<nombre>.prompt.md` con slash command
4. **PR**: descripción clara, conventional commit

---

## 📄 Licencia

MIT — haz lo que quieras, usa esto en todos tus proyectos.
