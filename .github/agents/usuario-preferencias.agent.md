---
description: "Use when: applying user preferences for SSH policy, git workflow and documentation format."
tools: [read, search, edit]
user-invocable: true
version: "2.0"
---

# Usuario Preferences (Updated)

## SSH Policy
- Política de SSH: Conectar por SSH cuando el usuario dice "conectate al servidor por ssh"
- Servidor por defecto: `192.168.188.13`
- Usuario por defecto: `root`
- **Sesión persistente**: Mantener la conexión abierta, no solicitar clave cada vez

## Server Configuration
- Servidor SSH: `192.168.188.13` (o el que el usuario indique)
- Usuario: `root`
- **IP variable**: Estar listo para diferentes servidores cuando el usuario los especifique

## Git Preferences
- Preferencia de git: Hacer backup antes de `reset --hard`
- Preferir `git merge --allow-unrelated-histories` o backup manual de directorios

## Documentation Format
- ES para documentación (docs, comentarios en español)
- EN para código (variables, funciones, clases, commits)

## SSH Connection Procedure (Updated)
1. **Primera conexión**: `ssh root@<servidor>` - el usuario provee la clave en la terminal
2. **Sesión mantenida**: Una vez conectada, mantenerla abierta
3. **Múltiples comandos**: Ejecutar varios comandos en la misma sesión sin desconectar
4. **Re-autenticación**: Solo solicitar clave nuevamente si la sesión ha estado inactiva por tiempo prolongado O si el usuario lo solicita explícitamente
5. **Al terminar**: Desconectar voluntariamente o mantener sesión para futuro uso

## Session Management Rules
- **No repetir clave**: Después de la primera conexión exitosa, la sesión permanece activa
- **Solicitar IP**: El usuario indicará qué servidor conectarse si no es el por defecto
- **Timeouts**: Si la sesión está inactiva mucho tiempo, pedir re-autenticación
- **Commands in session**: Ejecutar múltiples comandos dentro de la sesión SSH sin cerrar

## Agent Roles (Updated)
- **Solucionador**: Permisos amplios SSH - puede iniciar, mantener y terminar sesiones
- **Pensador**: Principalmente para auditoría/detección de errores - puede solicitar SSH cuando el contexto diagnóstico lo requiera, pero no debe iniciar conexiones de forma independiente

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
<!-- MCP-ROLE-v1 -->
