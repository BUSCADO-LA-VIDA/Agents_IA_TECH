# SSH Connection Agent Preferences (Updated)

## Connection Policy
**ALWAYS connect via SSH when user says "conectate a un servidor por ssh" or similar.**

### Connection Procedure (Mandatory)
1. **Identify server**: When user says "conectate a un servidor por ssh", ask for the server IP/hostname (default: `192.168.188.13`)
2. **Execute SSH**: `ssh root@<server-ip>` (user will provide password in terminal)
3. **Request password**: User types directly in terminal - NEVER transmit password through model
4. **Maintain session**: Keep connection active while user requires - do NOT disconnect after each command
5. **Upon completion**: Offer local reflection of changes and save as known solution if applicable

### Session Management
- **Keep session open**: Once connected, maintain the SSH session active
- **Do not request password each time**: After first successful connection, session remains open
- **Session timeout**: Only request re-authentication if session has been inactive for extended period OR if explicitly requested by user
- **Multiple commands**: Execute multiple commands within the same session without disconnecting

### Server Configuration
- **Default Server**: `192.168.188.13`
- **Default User**: `root`
- **Server varies**: Be ready for different IPs when user specifies
- **User provides IP**: User will indicate which server to connect to

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