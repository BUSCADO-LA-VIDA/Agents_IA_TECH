## T026 – Respaldo git antes de actualizar kit
- **Descripción**: Ejecutar `git stash push -m "Backup antes de actualizar kit"` o guardar el hash del commit actual con `git log --oneline -1` para respaldar los cambios locales antes de actualizar el kit.
- **Comando**: `git stash push -m "Backup antes de actualizar kit"` o `git log --oneline -1`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: Ninguna.

## T027 – Actualizar kit (plataformador-bootstrap)
- **Descripción**: Ejecutar `.\\scripts\\plataformador-bootstrap.ps1 -Force` para actualizar el kit completo, o `.\\scripts\\sync-kit.ps1 -Force` para solo transversales. Interfaz simplificada (FR-014): sin parámetros (todo), `-DryRun` (demo), `-Force` (sobrescribe + upgrade de herramientas).
- **Comando**: `.\\scripts\\plataformador-bootstrap.ps1 -Force`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T026. El respaldo git debe realizarse antes.

## T036 – Simplificar interfaz del bootstrap (002-SIMPLE)
- **Descripción**: Reducir `scripts/plataformador-bootstrap.ps1` a sin parámetros / `-DryRun` / `-Force` con defaults fijos y seguros. Eliminar ramas `-VerifyOnly`/`-SyncOnly` y flags `-SkipInstall`, `-NoRestart`, `-SkipIndexing`, `-App`/`-Apps`, `-RepoUrl`, `-ManifestPath`, `-OrphanAction`, `-GraphifyScope`/`-GraphifyDeep`, `-SkipSelfUpdate`, `-SkipSync`. Modo kit seguro AUTOMÁTICO (detecta checkout maestro por origin y omite el sync, antes `-SkipSync`). `-Force` incluye upgrade de herramientas externas (antes `-ForceUpgradeTools`). Reorientar `sync-agents.ps1` a invocar `scripts/sync-kit.ps1` directo (el bootstrap ya no expone `-SyncOnly`). Actualizar docs vivas (README, quickstart, mantenimiento, ecosistema).
- **Comando**: Verificación con `[System.Management.Automation.Language.Parser]::ParseFile` (0 errores) + `.\\scripts\\plataformador-bootstrap.ps1 -DryRun` (13 pasos, 0 errores) + `.\\sync-agents.ps1 -DryRun` (delega al motor).
- **Estado**: `[x]` Completado (2026-10-08: parser 0 errores; DryRun completo en el KIT con paso 3 auto-omitido por checkout maestro y 0 errores; sync-agents -DryRun delega al motor correctamente).
- **Dependencias**: Ninguna.

## T037 – Fuente local del kit para el sync (002-KITPATH)
- **Descripción**: Agregar `-KitPath <ruta-kit-local>` a `scripts/sync-kit.ps1` para sincronizar desde un checkout local (rama + cambios sin pushear) en vez de clonar GitHub. Fail-closed: solo directorios locales con marcadores (`scripts/`, `.github/`, `.opencode/`, `.doc_agents/`, `AGENTS.md`); jamás URLs ni el propio destino; el directorio temporal solo se borra si es clon propio. Solo `-Force` controla sobrescritura (igual que en modo GitHub).
- **Comando**: `pwsh scripts/sync-kit.ps1 -KitPath C:\\Proyectos\\Agents_IA_TECH -RootPath <proyecto> -Force`
- **Estado**: `[x]` Completado (2026-10-08: DryRun + sync real con `-Force` en proyecto consumidor; `scripts/ecc-orchestrator.ps1` entregado; los 10 scripts con hash idéntico al KIT; `.github/agents/pensador.agent.md` y `AGENTS.md` con hash idéntico; `Documentacion/<AppName>/` intacta; 0 errores).
- **Dependencias**: T036.

## T028 – Restaurar cambios del proyecto
- **Descripción**: Ejecutar `git stash pop` para restaurar los cambios locales, o `git checkout <commit-anterior>` para volver al estado previo.
- **Comando**: `git stash pop` o `git checkout <commit-anterior>`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T027. La actualización del kit debe completarse antes de restaurar.

## T029 – Verificar estado post-actualización
- **Descripción**: Ejecutar `git status` para verificar que el proyecto queda con: KIT actualizado, estructura por apps creada y código sin tocar. Revisar que no haya conflictos inesperados en archivos de código (src/, tests/).
- **Comando**: `git status`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T028. Los cambios deben restaurarse antes de verificar.

## T030 – Commit de cambios del kit (solo en repo maestro)
- **Descripción**: En el repositorio maestro (Agents_IA_TECH), hacer commit de los archivos del kit actualizados: `.github/`, `.opencode/`, `scripts/`, `AGENTS.md`, `opencode.json`, `.env.mcp`, `.specify/`. NOTA: Los proyectos consumidores NO hacen commit de estos archivos, solo su código.
- **Comando**: `git add .github/ .opencode/ .doc_agents/ scripts/ AGENTS.md opencode.json .env.mcp .specify/ && git commit -m "feat: actualizar kit Agents_IA_TECH a versión"`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T029. La verificación post-actualización debe completarse antes del commit.

## T031 – Migrar archivo obsoleto de pendientes-implementacion.md (T013)
- **Descripción**: Detectar y migrar el archivo `Documentacion/pendientes-implementacion.md` (ubicación previa a la migración por app) al formato por app `Documentacion/<App>/pendientes-implementacion.md` o borrarlo si está vacío. Ver tarea T013.
- **Comando**: Revisar y migrar contenido según sea necesario.
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T030. La verificación post-actualización debe completarse antes de la migración.

## T032 – Sincronizar archivo constitution.md (llamado por plataformador-bootstrap)
- **Descripción**: El script `.\\scripts\\sync-constitution.ps1` es invocado automáticamente por `.\\scripts\\plataformador-bootstrap.ps1 -Force` durante el flujo de actualización del kit. **PRIORIDAD: La versión en `Documentacion\\<App>\\.specify\\constitution.md` es la que manda y siempre se actualiza primero**. El flujo del bootstrap es:
  1. Ejecutar `.\\scripts\\plataformador-bootstrap.ps1 -Force` (Task T027)
  2. El bootstrap detecta y ejecuta `.\\scripts\\sync-constitution.ps1 -App <NombreApp>` internamente
  3. El script copia la versión Documentacion a:
     - `.specify\\memory\\constitution.md` (raíz del proyecto - usada por Constitution Check y speckit-constitution)
     - `src\\<App>\\.specify\\constitution.md` (acceso del agente Agent-SSD dentro de su whitelist)
  - El script se puede ejecutar también de forma independiente: `.\\scripts\\sync-constitution.ps1 -App trading_bot`
- **Comando**: `.\\scripts\\plataformador-bootstrap.ps1 -Force` (llamada interna que incluye la sincronización de constitution)
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T029. La verificación post-actualización debe completarse antes de la sincronización.

## T033 – Verificar sincronización de constitution (post-bootstrap)
- **Descripción**: Confirmar que el archivo constitution.md existe en las tres ubicaciones esperadas después de ejecutar `.\\scripts\\plataformador-bootstrap.ps1 -Force` (Task T027). **La versión en `Documentacion\\<App>\\.specify\\constitution.md` debe ser la idéntica a `.specify\\memory\\constitution.md` (raíz)** y a `src\\<App>\\.specify\\constitution.md` (acceso agente), ya que el bootstrap sincronizó desde Documentacion hacia estas ubicaciones. Comparar hash y reportar diferencias si el bootstrap no las igualó.
- **Comando**: `Get-FileHash -Path ".specify\\memory\\constitution.md"` y `Get-FileHash -Path "Documentacion\\<App>\\.specify\\constitution.md"` y `Get-FileHash -Path "src\\<App>\\.specify\\constitution.md"`
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T032. La sincronización (ejecutada por el bootstrap en T027) debe completarse antes de la verificación.

## T034 – Agregar constitution.md a gitignore si corresponde
- **Descripción**: Si el archivo constitution.md no debe versionarse en el repositorio del proyecto (porque se despliega a PRO y se gestiona por este kit), **agregarlo al `.gitignore` después de haber verificado que la sincronización T032 ha puesto la versión correcta en la raíz**. NOTA: Esto asegura que el archivo no aparezca en `git status` ni en commits, pero seguirá existiendo en el sistema de archivos gracias al script de sincronización, y la versión Documentacion (que manda) se mantiene actualizada por el bootstrap.
- **Comando**: Agregar la línea `.specify\\memory\\constitution.md` al archivo `.gitignore` del proyecto.
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T032 y T033. La sincronización y verificación deben completarse antes de decidir sobre el gitignore.

## T035 – Documentar ruta de constitution en AGENTS.md
- **Descripción**: Agregar una sección al `AGENTS.md` del proyecto que indique la ubicación del archivo constitution.md y su propósito: "El archivo constitution.md tiene prioridad en `Documentacion/<App>/.specify/constitution.md` (versión que manda). Esta versión se sincroniza automáticamente a `.specify/memory/constitution.md` (raíz) mediante el script `sync-constitution.ps1` al ejecutar la actualización del kit (`plataformador-bootstrap.ps1 -Force`). No se versiona en git porque se despliega a PRO, pero está respaldado por la sincronización del kit, siendo la versión Documentacion la que manda."
- **Comando**: Agregar la sección correspondiente al `AGENTS.md` del proyecto.
- **Estado**: `[ ]` Pendiente
- **Dependencias**: T032 y T034. La sincronización y la decisión sobre gitignore deben completarse antes de documentar.

---

### 📋 Propósito de la sincronización de constitution.md

Este conjunto de tasks (T032-T035) aborda la necesidad de tener el archivo constitution.md disponible en múltiples ubicaciones, con una **jerarquía clara de prioridad**:

**Prioridad: `Documentacion/<App>/.specify/constitution.md` es la versión que manda.**

1. **`Documentacion/<App>/.specify/constitution.md`** (versión que manda - documentación por app):
   - Es la **fuente de verdad** y la versión que siempre se actualiza primero
   - No se sube a git (el proyecto no versiona este archivo)
   - El script `sync-constitution.ps1`, **invocado por el `plataformador-bootstrap.ps1 -Force`**, toma esta versión y la distribuye a las demás ubicaciones
   - **El usuario quiere esto para tener el archivo respaldado fuera del código desplegado a PRO**
   - **Siempre se actualiza primero** cuando se ejecuta la sincronización del kit (a través del bootstrap)

2. **`.specify/memory/constitution.md`** (raíz del proyecto):
   - Ubicación oficial que busca el `Constitution Check` y `speckit-constitution`
   - Usado por el orquestador `pensador` para validar principios y whitelists
   - **Siempre se actualiza DESPUÉS** de la versión Documentacion (el/bootstrap script copia desde Documentacion a esta ubicación)
   - **No se recomienda poner en `.gitignore`** si el proyecto necesita que el check funcione, ya que el `plataformador-bootstrap.ps1` la actualizará desde Documentacion en cada ejecución del kit

3. **`src/<App>/.specify/constitution.md`** (acceso agente):
   - Copia dentro de la whitelist de `Agent-SSD` (`src/<App>/.specify/`)
   - Permite al agente leer la constitución sin violar restricciones de tier
   - **No es código desplegado a PRO** - es un archivo de configuración para agentes
   - El script/bootstrap crea esta copia para que Agent-SSD pueda acceder a ella

### Flujo de trabajo recomendado:

```powershell
# Después de actualizar el kit en un proyecto consumidor:

# Paso 1: Actualizar kit (bootstrap incluye sincronización de constitution)
.\scripts\plataformador-bootstrap.ps1 -Force
# Esto ejecuta T027 y, internamente, llama a sync-constitution.ps1 para sincronizar
# la versión Documentacion/<App>/.specify/constitution.md (la que manda) a:
#   - .specify/memory/constitution.md (raíz)
#   - src/<App>/.specify/constitution.md (agente)

# Paso 2: Verificar que la sincronización fue exitosa (Task T033)
# Después del bootstrap, las tres ubicaciones deben tener el mismo contenido:
#   .specify/memory/constitution.md
#   Documentacion/<App>/.specify/constitution.md (versión que manda)
#   src/<App>/.specify/constitution.md

# Paso 3: Decidir sobre gitignore
# Si el archivo no debe versionarse en git:
# - La versión Documentacion seguirá actualizándose automáticamente cada vez que se ejecute el bootstrap
# - Agregar .specify\memory\constitution.md al .gitignore si se desea,
#   sabiendo que el bootstrap la re-sincronizará desde Documentacion en cada ejecución

# Paso 4: Documentar en AGENTS.md
# (Task T035 - documentar que el bootstrap sincroniza y Documentacion es la versión que manda)
```

### Nota sobre la creación y invocación del script

La spec 002 documenta los requirements y tasks para la sincronización de constitution.md. El script real `scripts/sync-constitution.ps1` debe crearse en el repositorio `Agents_IA_TECH` siguiendo la lógica documentada en T032. La lógica crítica del script es:

1. **Cuando es llamado por `plataformador-bootstrap.ps1 -Force`** (forma principal de invocación):
   - El bootstrap toma `Documentacion/<App>/.specify/constitution.md` (versión que manda)
   - La copia a `.specify/memory/constitution.md` (raíz - para el check)
   - La copia a `src/<App>/.specify/constitution.md` (para acceso agente)

2. **Cuando se ejecuta de forma independiente `.\\scripts\\sync-constitution.ps1 -App <Nombre>`**:
   - Mismo comportamiento: Documentacion es la versión que manda
   - Si Documentacion no existe, toma la raíz como respaldo inicial, pero en futuras ejecuciones del bootstrap, el usuario debe actualizar el Documentacion y el script la sincronizará hacia afuera

El script puede ejecutarse con `-App <Nombre>` o `-All` para todos los apps, y su invocación principal y recomendada es a través del `plataformador-bootstrap.ps1` durante la actualización del kit.

**Importante**: Si el archivo `Documentacion/<App>/.specify/constitution.md` no existe, el script debe crear una copia del `.specify/memory/constitution.md` de la raíz como respaldo inicial, pero en futuras ejecuciones del bootstrap, el usuario debe actualizar el Documentacion y el script la sincronizará hacia afuera.

El script aún no se ha creado en el repositorio (pendiente de ejecución por el usuario o automatización posterior), pero las tasks T032-T035 documentan qué debe hacer y cómo encaja en el flujo general de actualización del kit, con la prioridad clara de que **Documentacion es la versión que manda** y que el **plataformador-bootstrap.ps1 es quien la invoca** durante la actualización del kit.