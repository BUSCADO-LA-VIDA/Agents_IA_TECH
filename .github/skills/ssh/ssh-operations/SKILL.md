# ssh-operations

## Descripción
Skill reutilizable para operaciones SSH: conexión, política de sesión, configuración de servidor y gestión de permisos. Extraída del procedimiento embebido en `usuario-preferencias` (capa de gobernanza). Este es el procedimiento único y autorizado para conexiones SSH en el kit.

## Responsable
- **Capa de gobernanza:** `usuario-preferencias` (aprueba y supervisa)
- **Ejecución:** `solucionador` (diagnóstico remoto), `plataformador` (nivelación), o cualquier agente con permisos SSH (consultar whitelist por `(tier, proyecto_tipo)` según FR-19)

## Política de SSH (conservada en `usuario-preferencias`)
- **Conectar por SSH** cuando el usuario dice "conectate al servidor por ssh"
- **Servidor por defecto:** `192.168.188.13`
- **Usuario por defecto:** `root`
- **Sesiòn persistente:** Mantener la conexiòn abierta, no solicitar clave cada vez

## Configuraciòn de Servidor
- **Servidor SSH:** `192.168.188.13` (o el que el usuario indique)
- **Usuario:** `root`
- **IP variable:** Estar listo para diferentes servidores cuando el usuario los especifique

## Preferencias de Git (heredadas)
- Hacer backup antes de `reset --hard`
- Preferir `git merge --allow-unrelated-histories` o backup manual de directorios
- **ES** para documentaciòn (docs, comentarios en espaùol)
- **EN** para cùdigo (variables, funciones, clases, commits)

## Procedimiento de Conexión SSH (Actualizado)

### 1. Primera conexiòn: `ssh root@<servidor>`
- El usuario provee la clave en la terminal
- Primera autenticaciòn

### 2. Sesión mantenida
- Una vez conectada, mantenerla abierta
- No solicitar clave nuevamente a menos que sea necesario

### 3. Múltiples comandos
- Ejecutar varios comandos en la misma sesiòn sin desconectar

### 4. Re-autenticaciòn
- Solo solicitar clave nuevamente si la sesiòn ha estado inactiva por tiempo prolongado
- O si el usuario lo solicita explícitamente

### 5. Al terminar
- Desconectar voluntariamente o mantener sesiòn para futuro uso

## Reglas de Sesión
- **No repetir clave:** Despuès de la primera conexiòn exitosa, la sesiòn permanece activa
- **Solicitar IP:** El usuario indicarà quò servidor conectarse si no es el por defecto
- **Timeouts:** Si la sesiòn està inactiva mucho tiempo, pedir re-autenticaciòn
- **Commands in session:** Ejecutar múltiples comandos dentro de la sesiòn SSH sin cerrar

## Roles de Agente (Actualizado)
- **Solucionador:** Permisos amplios SSH - puede iniciar, mantener y terminar sesiones
- **Pensador:** Principalmente para auditorìa/detecciò de errores - puede solicitar SSH cuando el contexto diagnòstico lo requiera, pero no debe iniciar conexiones de forma independiente
- **Demás agentes:** Consultar whitelist por `(tier, proyecto_tipo)` antes de solicitar SSH (FR-19). Si el path no està en su whitelist efectiva, detenerse y delegar.

## Handoff a usuario-preferencias
- Cualquier modificación a la política de SSH, servidores preferidos o preferencias de documentación debe ser gestionada a travès de la capa de gobernanza `usuario-preferencias`.
- El runtime carga `usuario-preferencias` como referencia de política; los agentes invocan la skill `ssh-operations` para la ejecución.

---
**Fuente:** Prodecimiento extraído de `usuario-preferencias.agent.md` y migrado a skill reutilizable por FR-12 y FR-16.
**Validado:** 2026-10-29, Pester 6.2.0 suite 38/38 passing.