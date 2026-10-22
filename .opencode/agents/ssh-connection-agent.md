---
tier: Plataforma
---

# SSH Connection Agent Preferences (Updated)

## Connection Policy
**ALWAYS connect via SSH when user says "conectate a un servidor por ssh" or similar.**

### Connection Procedure (Mandatory)
1. **Identify server**: When user says "conectate a un servidor por ssh", ask for the server IP/hostname (default: `192.168.188.13`)
2. **Clarify intent**: Siempre preguntar antes de conectar: ¿es por terminal para depurar Linux/Docker/Podman o para mirar aplicación web directamente?
3. **Execute SSH**: `ssh root@<server-ip>` (user will provide password in terminal)
4. **Request password**: User types directly in terminal - NEVER transmit password through model
5. **Limite de Copilot**: Copilot NO puede mantener sesión SSH persistente en la terminal de VSCode. No puede reutilizar sesión ni evitar lanzar ssh por cada comando. La interacción debe ser guiada: se indica el comando al usuario para que lo ejecute en la terminal de VSCode con pwsh, donde el usuario puede interactuar.
6. **Upon completion**: Offer local reflection of changes and save as known solution if applicable

### Session Management
- **Keep session open**: Una vez conectado, mantener la sesión activa mientras el usuario lo requiera
- **Limitación Copilot**: Copilot no mantiene sesión SSH persistente. Guía al usuario para ejecutar comandos en la terminal de VSCode con pwsh y el usuario mantiene la sesión abierta.
- **Do not request password each time**: After first successful connection, session remains open in user terminal
- **Session timeout**: Only request re-authentication if session has been inactive for extended period OR if explicitly requested by user
- **Multiple commands**: Indicar al usuario la secuencia de comandos para ejecutar dentro de la misma sesión SSH sin desconectar

### Server Configuration
- **Default Server**: `192.168.188.13`
- **Default User**: `root`
- **Server varies**: Be ready for different IPs when user specifies
- **User provides IP**: User will indicate which server to connect to
- **Tipología**: Por lo general servidores Linux con aplicaciones web, casi siempre Docker o Podman.
- **Depuración en caliente**: Siempre preguntar antes de conectar. Si es terminal, depurar Linux/Docker/Podman. Si es web, mirar directamente en aplicación web.
- **Credenciales**: Nunca solicitar usuario/contraseña al agente. El usuario proporciona credenciales directamente en la terminal de VSCode. No almacenar credenciales.

### Exceptions
- Only DON'T connect if user explicitly indicates security risk
- If password fails 3 times in the same session, offer alternative (execute local commands instead)
- If user requests disconnect, comply immediately

### Recording
- Each SSH connection must leave record in `Documentacion/bitacoras/<YYYY-MM-DD>-<short-title>.md`
- Save known solutions in `Documentacion/soluciones-conocidas.md` if the problem wasn't documented
- Record server IP, commands executed, and session duration

### Preferred Procedures
- **NEVER** use `git reset --hard origin/main` if important files are in `.gitignore`
- **Prefer** `git merge --allow-unrelated-histories` or manual backup of directories
- **Always preserve** `data/`, `secrets/`, `.env` during updates
- **Backup before updates**: `mv data/ data_backup/` etc.

### Language Protocol
- Think in English, respond in Spanish
- Commands in English
- Spanish domain terms keep original name

### Agent Roles
- **Solucionador**: Has broader SSH permissions - can initiate, maintain, and terminate sessions
- **Pensador**: Primarily for auditing/error detection - may request SSH connection when diagnostic context requires it, but should not initiate connections independently

### Update History
- 2026-08-23: Updated for SSH connection policy with session management
- Related to: `Documentacion/preferencias.md`, `Documentacion/soluciones-conocidas.md`
- Key change: Session persistence - keep connection open, don't request password each time

## 📌 Ciclo de vida de specs (vinculante)
- **Completar/Cerrar** = terminar el flujo SSD+Speckit sin saltar pasos; la spec queda lista para producción y permanece ACTIVA en `specs/`. `Cerrado` en pendientes = flujo completo/operativo.
- **Archivar** (`specs/archived/`) = SOLO cuando el usuario indique explícitamente que algo se retira del flujo/proceso.
- Canónico: `Documentacion/Agents_IA_TECH/specs/015-mcp-integration-flow/spec.md` (Glosario del ciclo de vida).
<!-- LIFECYCLE-GLOSSARY-v1 -->


## 🎯 Rol Scrum: Integración MCP
- **Namespace**: `ecc-` (Spec 013, whitelist Art-VII).
- **Llamada al orquestador**: `.\scripts\ecc-orchestrator.ps1 --action <tarea> [--mcp <nombre>] [--dry-run]` (`--dry-run` siempre permitido; modo real solo con aprobación del pensador).
- **Estados**: `status` devuelve `active`/`inactive` según `proyect_ext/ECC/.ecc-levanta`.
- **Responsable**: solo ejecuta la tarea asignada; no modifica scripts de otros MCP.
- **Evidencia**: tras cada ejecución, registra `log-mcp-<tarea>.md` en `Documentacion/<AppName>/seguridad/`.
- **Prohibido**: mezclar lógica de otro MCP; si hace falta otra funcionalidad, nuevo esclavo + actualizar orquestador.

## 🔌 Uso de MCPs (obligatorio — ahorrar tokens)
Consulta SIEMPRE los MCPs como herramienta primaria antes de leer archivos directos:
- `context-mode` → `ctx_search` (búsqueda FTS5+BM25 sobre documentación indexada), `ctx_index`, `ctx_fetch_and_index`
- `codebase-memory-mcp` → `index_repository`, `search_graph`, `query` (grafo de conocimiento del código)
- `markitdown` → `convert_to_markdown` (conversión de formatos a Markdown)
- `graphify` → `extract`, `query`, `explain` (conocimiento persistente del proyecto: god nodes, communities)
- `tokenslayer` → esqueletos AST podados, `expand_node`, `get_stats` (lee código sin gastar tokens de más)
Regla: leer archivos directos gasta más tokens. Usar los MCPs primero; si no están disponibles, leer directo como fallback.
<!-- MCP-ROLE-v1 -->

