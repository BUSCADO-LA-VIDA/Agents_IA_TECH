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