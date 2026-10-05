# Guía de integración selectiva ECC → Agents_IA_TECH

## 1. Objetivo
Establecer procedimiento controlado para importar de forma selectiva reglas, skills y hooks del proyecto externo ECC ubicado en `proyect_ext/ECC` hacia el kit Agents_IA_TECH manteniendo el flujo Speckit/SSD, la Constitución del proyecto y evitando duplicación de orquestadores. La importación usa namespace `ecc-` obligatorio y se realiza únicamente sobre paths permitidos por Constitución Art.VII.

## 2. Contexto y alcance
ECC es un agent harness con 68 agentes, 292 skills, rules siempre cargadas, hooks de sesión/memoria y AgentShield. Agents_IA_TECH mantiene 16 agentes propios, 29 skills Speckit, hooks mínimos en `.github/hooks/context-mode.json` y reglas documentales sin mecanismo auto-cargable.

Alcance de esta guía:
- Importar rules/common y rules por lenguaje prioritarios.
- Importar skills de seguridad, calidad, contexto y presupuesto de tokens.
- Importar hooks de sesión, persistencia de memoria y pre/post tool use.
- No importar orquestadores ECC ni agentes completos.
- No modificar `src/<App>/`.

Fuera de alcance:
- Migración de ECC completo.
- Reemplazo del orquestador `pensador` y pipeline Speckit.

## 3. Pre-requisitos
- Carpeta `proyect_ext/ECC` presente y clonada.
- Rama de trabajo `feature/ecc-integration` creada.
- Acceso a `.github/`, `.opencode/`, `Documentacion/Agents_IA_TECH/`.
- Revisión de gaps-012-T004.md y priorizacion-012-T005.md.
- Herramientas: PowerShell 7+, git, acceso a scripts de sincronización.

Paths permitidos por Constitución:
- `Documentacion/Agents_IA_TECH/`
- `proyect_ext/ECC/`
- `.opencode/`
- `.github/`

## 4. Principios de namespace y no-duplicación
1. Namespace obligatorio `ecc-` para todo elemento importado.
2. No duplicar Speckit: descartar skills que repliquen flujo especificar/planear/tareas/implementar.
3. Lectura primero: AgentShield y hooks en modo observador mínimo 2 semanas antes de bloquear.
4. No importar agentes ECC completos. Solo skills puntuales sin dependencias de orquestador.
5. Mantener orquestador `pensador` → Speckit → implementadores.

## 5. Procedimiento general
1. Identificar componente ECC candidato en priorizacion-012-T005.md.
2. Validar ausencia en Agents_IA_TECH mediante búsqueda en `.github/skills`, `.opencode/skills`, `Documentacion/`.
3. Crear destino con namespace `ecc-` dentro de path permitido.
4. Copiar contenido fuente desde `proyect_ext/ECC/` sin modificar origen.
5. Adaptar frontmatter y referencias internas al namespace.
6. Registrar en manifiesto de integración `012-ecc-integration/manifiesto-importaciones.md`.
7. Ejecutar validaciones de sección 7.
8. Commit con mensaje convencional `docs(ecc): importar <componente> con namespace ecc-`.

## 6. Importar rules
### 6.1 Rules common siempre cargadas
Origen: `proyect_ext/ECC/rules/common/`
Destino documentación: `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-common/`
Destino referencia operativa: `.github/rules/ecc-common/` si se habilita loader.

Pasos:
```powershell
New-Item -ItemType Directory -Path "Documentacion\Agents_IA_TECH\specs\012-ecc-integration\rules\ecc-common" -Force
Copy-Item "proyect_ext\ECC\rules\common\*.md" "Documentacion\Agents_IA_TECH\specs\012-ecc-integration\rules\ecc-common\"
```
Renombrar archivos a `ecc-<nombre>.md` manteniendo título original.
Actualizar frontmatter con:
```
---
origen: proyect_ext/ECC/rules/common/
namespace: ecc-
tipo: rule
prioridad: 1
fecha_importacion: 2026-10-05
---
```

Rules a importar en prioridad 1:
- security.md → ecc-security.md
- hooks.md → ecc-hooks.md
- coding-style.md → ecc-coding-style.md
- agents.md → ecc-agents.md
- git-workflow.md → ecc-git-workflow.md
- development-workflow.md → ecc-development-workflow.md
- testing.md → ecc-testing.md
- performance.md → ecc-performance.md
- patterns.md → ecc-patterns.md
- code-review.md → ecc-code-review.md

### 6.2 Rules por lenguaje prioritarios
Origen: `proyect_ext/ECC/rules/typescript/`, `proyect_ext/ECC/rules/python/`, `proyect_ext/ECC/rules/react/`
Destino: `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-lang/`
Seleccionar máximo 3 lenguajes principales del kit.
Procedimiento idéntico a 6.1 con prefijo `ecc-<lang>-`.

Validación adicional: comparar con reglas existentes en Documentacion para evitar duplicación de contenido.

## 7. Importar skills
Origen: `proyect_ext/ECC/skills/`
Destinos:
- Copilot: `.github/skills/ecc-<skill>/`
- OpenCode: `.opencode/skills/ecc-<skill>/`

Skills prioritarios según priorizacion-012-T005.md:
- security-scan
- security-bounty-hunter
- skill-scout
- skill-comply
- verification-loop
- context-budget
- token-budget-advisor
- unified-memory
- unified-notifications-ops

Pasos para un skill:
```powershell
$skill = "security-scan"
New-Item -ItemType Directory -Path ".github\skills\ecc-$skill" -Force
Copy-Item "proyect_ext\ECC\skills\$skill\*" ".github\skills\ecc-$skill\" -Recurse
```
Crear `SKILL.md` con frontmatter adaptado:
```
---
name: ecc-security-scan
desc: Escaneo de seguridad proactivo sin dependencias de orquestador ECC
origen: proyect_ext/ECC/skills/security-scan
namespace: ecc-
compatible: github-copilot, opencode
---
```
Repetir para OpenCode en `.opencode/skills/ecc-<skill>/`.
Actualizar `.opencode/config.json` en sección `skills` para listar el nuevo skill si aplica.

Validaciones:
- No contiene referencias a agentes ECC orquestadores.
- SKILL.md contiene descripción, dependencias y ejemplo de uso.
- Nombre empieza con `ecc-`.
- No duplica skill Speckit existente.

## 8. Importar hooks
Origen: `proyect_ext/ECC/hooks/`
Destino: `.github/hooks/ecc/`

Componentes:
- `hooks.json` → `.github/hooks/ecc/hooks.json`
- `hooks.metadata.json` → `.github/hooks/ecc/hooks.metadata.json`
- `memory-persistence/` → `.github/hooks/ecc/memory-persistence/`

Pasos:
```powershell
New-Item -ItemType Directory -Path ".github\hooks\ecc" -Force
Copy-Item "proyect_ext\ECC\hooks\hooks.json" ".github\hooks\ecc\"
Copy-Item "proyect_ext\ECC\hooks\hooks.metadata.json" ".github\hooks\ecc\"
Copy-Item "proyect_ext\ECC\hooks\memory-persistence" ".github\hooks\ecc\" -Recurse
```
Adaptar comandos internos para apuntar a `proyect_ext/ECC/scripts/hooks/` sin modificar origen ECC, usando variables de entorno `ECC_ROOT=C:\Proyectos\Agents_IA_TECH\proyect_ext\ECC`.

Crear archivo de configuración local `.github/hooks/ecc-local.json` con:
```json
{
  "namespace": "ecc-",
  "modo": "observador",
  "hooks_activos": ["SessionStart", "PreToolUse", "PostToolUse"],
  "paths_permitidos": ["Documentacion/Agents_IA_TECH/", ".opencode/", ".github/"]
}
```

No activar hooks PreToolUse/PostToolUse que creen loops con context-mode hasta completar pruebas de idempotencia.

## 9. Validaciones
### 9.1 Validaciones obligatorias antes de commit
- [ ] Namespace `ecc-` presente en nombre de archivo y frontmatter.
- [ ] Origen documentado en frontmatter `origen: proyect_ext/ECC/...`.
- [ ] Path destino dentro de Constitución Art.VII.
- [ ] No se importaron agentes ECC completos.
- [ ] No se duplica Speckit.
- [ ] Archivo de manifiesto actualizado.
- [ ] `git status` muestra solo archivos en paths permitidos.

### 9.2 Validaciones funcionales
- [ ] Flujo Speckit `pensador` → especificar → plan → tareas → implementar sigue ejecutable.
- [ ] Skill importado carga sin error en `.opencode/skills/` y `.github/skills/`.
- [ ] Hooks en modo observador registran eventos sin bloquear sesión.
- [ ] Rules importadas aparecen en índice de documentación.
- [ ] `ecc-sync.ps1 validate` pasa sin errores de duplicación.

### 9.3 Validaciones de seguridad
- [ ] No se copiaron secretos desde ECC.
- [ ] Hooks no ejecutan comandos con privilegios elevados.
- [ ] Skills no contienen código que modifique `src/<App>/`.
- [ ] AgentShield en modo lectura primero, sin bloquear CI.

## 10. Ejemplos concretos
### Ejemplo 1: Importar rule security
Origen: `proyect_ext/ECC/rules/common/security.md`
Destino: `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-common/ecc-security.md`
Acciones:
- Copiar archivo.
- Añadir frontmatter con namespace y fecha.
- Registrar en manifiesto.
- Validar que no existe rule equivalente en Documentacion.

### Ejemplo 2: Importar skill security-scan
Origen: `proyect_ext/ECC/skills/security-scan/`
Destino: `.github/skills/ecc-security-scan/` y `.opencode/skills/ecc-security-scan/`
Acciones:
- Copiar contenido.
- Renombrar SKILL.md con name `ecc-security-scan`.
- Actualizar referencias internas a rutas relativas.
- Añadir entrada en `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/manifiesto-importaciones.md`.

### Ejemplo 3: Importar hooks de sesión
Origen: `proyect_ext/ECC/hooks/hooks.json`
Destino: `.github/hooks/ecc/hooks.json`
Acciones:
- Copiar archivo.
- Crear `ecc-local.json` con modo observador.
- No activar hooks críticos hasta validación de idempotencia.
- Documentar eventos mapeados: SessionStart, PreToolUse, PostToolUse.

## 11. Registro y trazabilidad
Mantener archivo `Documentacion/Agents_IA_TECH/specs/012-ecc-integration/manifiesto-importaciones.md` con tabla:
| Fecha | Tipo | Origen ECC | Destino | Namespace | Validado por |
|---|---|---|---|---|---|

Actualizar en cada importación.

## 12. Rollback
Para revertir importación:
```powershell
git checkout HEAD -- .github/skills/ecc-<skill>
git checkout HEAD -- Documentacion/Agents_IA_TECH/specs/012-ecc-integration/rules/ecc-common/
```
Eliminar entradas de manifiesto y ejecutar `ecc-sync.ps1 validate`.

## 13. Referencias
- spec.md 012-ecc-integration
- plan.md 012-ecc-integration
- tasks.md 012-ecc-integration
- gaps-012-T004.md
- priorizacion-012-T005.md
- Constitución Agents_IA_TECH Art.VII
