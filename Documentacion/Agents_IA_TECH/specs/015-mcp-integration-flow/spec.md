# Spec 015 – Flujo transversal de integración y mantenimiento de MCP

## 1. Objetivo
Definir el **estándar transversal** que todo nuevo MCP (MCP = Module, Component, Package, etc.) debe seguir para ser agregado al proyecto Agents_IA_TECH de forma segura, mantenible y consistente. Este spec no cubre la lógica propia de cada MCP (esos pasos son particulares), sino las **etapas obligatorias** que todo MCP debe atravesar, desde su solicitud hasta su validación y puesta en producción.

## 2. Alcance
- **Aplica a**: cualquier nuevo MCP que se integre al proyecto (scripts, skills, rules, hooks, AgentShield, etc.).
- **No aplica a**: la lógica interna de cada MCP (esos pasos son particulares y se documentan en su propio spec).
- **Responsables**: Pensador (Líder/PO), Arquitecto, Security‑Auditor, y los líderes de área correspondientes (api‑developer, frontend‑developer, devops, qa‑senior).

## 2. Etapas obligatorias (flujo estándar)

| Etapa | Descripción | Resultado esperado | Validación |
|------|-------------|-------------------|------------|
| **E‑01 Solicitud y definición** | Se presenta una breve descripción del MCP, su propósito, y los paths (whitelist Art‑VII) que tocará. | `Documentacion/<Proyecto>/specs/<N‑MCP>-solicitud.md` | Revision rápida por Pensador. |
| **E‑02 Actualización de la Constitución (Art‑VII)** | Se añaden o actualizan los paths whitelistados en `constitution.md` Art‑VII si el MCP toca paths nuevos. | `constitution.md` actualizado y pasa Constitution Check. | Constitution Check PASS. |
| **E‑03 Creación de scripts separados** | Se crean dos carpetas/archivos: <br>• `scripts/ecc-orchestrator.<ext>` – orquestador central. <br>• `scripts/ecc-mcp-<nombre>.<ext>` – script esclavo por MCP. | Estructura de carpetas validada por `tree` o `ls`. | Revisión de Arquitecto. |
| **E‑04 Actualización de agents** | Cada agent (`.github/agents/*.md` y `.opencode/agents/*.md`) recibe una sección `🎯 Rol Scrum: Integración MCP` que indica: <br>• Cómo invocar al orquestador (`--action`, `--dry-run`). <br>• Qué parámetros son seguros. <br>• Que no pueden modificar scripts de otros MCP. | Frontmatter/body de los 13 agents actualizados. | Validación de permisos: `git diff` contra plantilla de agente. |
| **E‑05 Pruebas de integración** | Se ejecutan tres tipos de pruebas: <br>1. `dry-run` del orquestador (simula sin tocar recursos). <br>2. Unit‑tests por esclavo (mock del MCP). <br>3. Integración continua (`ci/ecc-pipeline.yml`) que ejecuta el orquestador contra un entorno de test. | Reportes de pruebas en `reports/ecc‑test‑*.md`. | Paso de la pipeline CI. |
| **E‑06 Revisión y aprobación** | Pull‑Request con checklist obligatorio: <br>• Constitución Art‑VII OK. <br>• Scripts separados y versionados. <br>• Agents actualizados. <br>• Pruebas passing. <br>• Firma `git commit -S`. | PR merged a `main` tras aprobación de Pensador + Arquitecto + Security‑Auditor. | Merge approved. |
| **E‑07 “Levantar” y marcación** | El orquestador escribe un marcador `proyect_ext/ECC/.ecc‑levanta` tras un `--run` aprobado. Los agents pueden consultar `ecc-status` para saber si la integración ya está activa. Si el marcador falta, los agents deben negarse a ejecutar acciones que dependan del MCP. | Archivo `.ecc‑levanta` creado y `ecc-status` devuelve “active”. | Comando `ecc-status` devuelve “active”. |
| **E‑08 Mantenimiento a largo plazo** | Cada vez que se modifica el MCP: <br>1. Se crea una nueva versión del script (versionado semver). <br>2. Se actualiza el `CHANGELOG.md` en `scripts/`. <br>3. Se vuelve a ejecutar la pipeline CI. <br>4. Se notifica a los agents afectados para que actualicen su sección de rol. | `CHANGELOG.md` actualizado, pipeline verde, agents notificados. | Revisión trimestral por Pensador. |

## 3. Patrón de scripts: Orquestador ↔ Esclavos
- **Orquestador** (`ecc-orchestrator.<ext>`): <br>• Recibe `--action <tarea>` y `--mcp <nombre>`. <br>• Valida whitelist de paths (Art‑VII). <br>• Llama al script esclavo correspondiente. <br>• Normaliza la salida (código de retorno, JSON resumen). <br>• Escribe el marcador `.ecc‑levanta` si `--run` y `--approved`. <br>• Imprime logs estructurados para que los agents puedan parsearlos.
- **Script esclavo** (`ecc-mcp-<nombre>.<ext>`): <br>• Recibe parámetros estandarizados (`--action`, `--target`, `--dry-run`). <br>• Implementa la lógica concreta del MCP. <br>• Devuelve `exit code` y resumen estructurado. <br>• Nunca toca paths fuera de los whitelistados.

## 4. Actualización de agents (plantilla transversal)
Cada agent debe incluir al final de su frontmatter o cuerpo:

```markdown
## 🎯 Rol Scrum: Integración MCP
- **Namespace**: `ecc‑` (definido en Spec 013, Art‑VII whitelist).  
- **Llamada al orquestador**: `& "scripts/ecc-orchestrator.ps1" --action <tarea> --dry-run`  
- **Parámetros seguros**: `--dry-run` siempre permitido; `--run` requiere aprobación de Pensador.  
- **Responsable**: solo puede ejecutar la tarea que le fue asignada; no puede modificar scripts de otros MCP.  
- **Evidencia**: después de cada ejecución, registrar un `log‑mcp‑<tarea>.md` en `Documentacion/<Proyecto>/seguridad/`.  
- **Prohibido**: mezclar lógica de otro MCP dentro de este agent; si se necesita otra funcionalidad, crear un nuevo esclavo y actualizar el orquestador.
```

## 5. Mantenimiento a largo plazo
- **Versionado semver** de cada script (orquestador y esclavos). <br>
- **CHANGELOG.md** en `scripts/` con entradas por versión. <br>
- **Pipeline CI** (`ci/ecc-pipeline.yml`) que se ejecuta en cada PR y en schedule diario. <br>
- **Revisión trimestral** por Pensador para verificar que los scripts sigan la plantilla, que los agents tengan la sección actualizada y que no haya paths no whitelistados.

## 5. Ubicación del documento
- **Opción A** – Spec 015 independiente: `Documentacion/Agents_IA_TECH/specs/015-mcp-integration-flow/`. <br>
- **Opción B** – Appendice dentro de Spec 013: `Documentacion/Agents_IA_TECH/specs/013-appendice-mcp/`. <br>

Ambas opciones quedan indexadas en `00-indice.md` y son buscables vía `ctx_search`.

## 6. Próximos pasos (después de aprobar este spec)
1. **Crear la estructura de carpetas** `scripts/ecc‑*` y el orquestador inicial. <br>
2. **Actualizar los 13 agents** con la sección `🎯 Rol Scrum: Integración MCP`. <br>
3. **Lanzar la pipeline CI** vacía y añadir las primeras pruebas `dry-run`. <br>
4. **Notificar a todos los agentes** (a través de la sección de “Actualizaciones transversales” del repo) de la nueva norma.

---

## Glosario del ciclo de vida de una spec (vinculante para toda spec futura)

- **Completar / Cerrar una spec**: terminar las 8 etapas (E‑01→E‑08) y todas las tareas (T‑001→T‑008) sin saltar pasos, con Constitution Check PASS, pipeline CI verde, agents actualizados e índice `00-indice.md` actualizado. La spec queda **lista para producción y permanece ACTIVA** en `specs/<id>-<nombre>/` (con sus archivos `spec.md`, `plan.md`, `tasks.md`). En `pendientes-implementacion.md` el estado `Cerrado` significa flujo completo/operativo, nunca eliminada.
- **Archivar una spec**: moverla a `specs/archived/`. Se hace **SOLO** cuando el usuario indica explícitamente que algo **se retira del flujo/proceso** (deprecado, reemplazado por otra spec, cancelado). Ningún T008 puede ordenar archivado salvo que el plan aprobado lo contemple como retiro.
- **Retirar / quitar del flujo o del proceso**: sinónimo operativo de archivar. Requiere instrucción explícita del usuario con motivo documentado (reemplazo, cancelación, deprecación).
- **Operativa / lista para producción**: spec con su T008 verificado, referenciada en `00-indice.md` y recuperable vía `ctx_search`.
- **Regla para redactar T008 futuros**: todo `tasks.md` futuro debe titular su T008 "Completar spec <id> — flujo SSD completo, lista para producción (operativa)", prohibir cualquier `Move-Item` hacia `specs/archived/` y remitir a este glosario. Si algún borrador anterior decía "Cerrar y archivar", se lee corregido conforme a este glosario.

*Fin de Spec 015 – Flujo transversal de integración y mantenimiento de MCP.*