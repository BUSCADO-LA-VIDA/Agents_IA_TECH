# Spec: Agente `solucionador`

> **Propósito**: Agente de altos privilegios para diagnóstico y solución de problemas en servidores remotos. Solo se invoca bajo demanda explícita del usuario a través del `pensador`.

## Flujo general

```mermaid
flowchart TD
    A[Usuario: problema en servidor] --> B[pensador invoca solucionador]
    B --> C[Consulta soluciones-conocidas.md]
    C --> D{Match encontrado?}
    D -->|Si| E[Ofrece aplicar solucion conocida]
    E --> F{Usuario confirma?}
    F -->|No| G
    F -->|Si| H[Aplica solucion conocida\nen caliente]
    D -->|No| G[Conecta SSH al servidor]
    G --> I[Explora: logs, servicios,\nprocesos, configs, puertos]
    I --> J[Analiza pistas\ny profundiza]
    J --> K{Encontro\ncausa raiz?}
    K -->|No| I
    K -->|Si| L[Propone plan de solucion\nPREGUNTA antes de ejecutar]
    L --> M{Usuario autoriza?}
    M -->|No| N[Fin - se descarta]
    M -->|Si| O[Ejecuta solucion en caliente]
    O --> P[Navega a URL para verificar]
    P --> Q{Todo OK?}
    Q -->|No| I
    Q -->|Si| R[Guarda bitacora en Documentacion/bitacoras/]
    R --> S{Pregunta: guardar como\nsolucion conocida?}
    S -->|Si| T[Agrega a soluciones-conocidas.md]
    S -->|No| U[Pregunta: reflejar cambios\nen codigo local?]
    T --> U
    U -->|Si| V[Busca archivos locales equivalentes\ny los actualiza]
    U -->|No| W[Fin]
    V --> W
    H --> P
```

## Memorias del agente

| Tipo | Archivo | Formato | Propósito |
|------|---------|---------|-----------|
| 🧠 Corto plazo (bitácora) | `Documentacion/bitacoras/<YYYY-MM-DD>-<problema>.md` | Markdown | Cada intervención: problema, comandos ejecutados, outputs, decisiones. Permite reconstruir toda la sesión. |
| 📚 Largo plazo (conocidas) | `Documentacion/soluciones-conocidas.md` | Markdown | Problemas recurrentes ya resueltos. El agente lo consulta **siempre primero** para ahorrar tokens. |

## Capacidades

- **SSH**: conexión a servidores remotos con credenciales proporcionadas por el usuario
- **Navegador**: abrir URLs para verificar que las soluciones funcionan
- **Edición local**: puede modificar archivos del proyecto (Dockerfiles, configs, scripts, etc.)
- **Edición remota**: puede modificar archivos en el servidor vía SSH
- **Bitácora**: registra automáticamente cada acción con timestamp

## Reglas de oro

1. **Nunca se invoca solo** — solo el `pensador` o el usuario directamente pueden llamarlo
2. **Siempre consultar `soluciones-conocidas.md` primero** — si hay match, ofrecer la solución ya documentada en vez de diagnosticar desde cero
3. **Preguntar antes de ejecutar cambios destructivos** — reinicios, borrados, cambios de config críticos
4. **Bitácora obligatoria** — cada intervención debe quedar registrada en `Documentacion/bitacoras/`
5. **Ofrecer reflejo local** — al finalizar, preguntar si los cambios en caliente deben replicarse en el código fuente local
6. **Ofrecer guardar como solución conocida** — si el problema no estaba documentado, preguntar si agregarlo a `soluciones-conocidas.md`

## Formato de bitácora

```markdown
# Bitácora: <YYYY-MM-DD> - <Título del problema>

**Invocado por**: pensador / usuario
**Servidor**: <IP>
**Problema**: <descripción>

## Diagnóstico
<comandos ejecutados y outputs relevantes>

## Solución aplicada
<qué se cambió, en qué archivos>

## Verificación
<URL navegada, resultado>

## Reflejo local
- [ ] Pendiente / [x] Completado
- Archivos locales modificados: <rutas>
```

## Formato de solución conocida

```markdown
### <YYYY-MM-DD> <Título corto>
- **Síntomas**: <cómo reconocer el problema>
- **Servidor**: <IP>
- **Solución**: <pasos exactos>
- **Archivos locales afectados**: <rutas si aplica>
- **Tags**: `apache`, `radius`, `docker`, etc.
```

## Permisos requeridos

- SSH en servidores remotos
- Navegador web para verificar URLs
- Edición de archivos locales (código fuente, configs)
- Edición de `Documentacion/` (bitácoras, soluciones conocidas)
- Capacidad de invocar subagentes si es necesario

## Enfoque de diagnóstico

El `solucionador` no sigue un checklist fijo. Recibe un problema y él mismo decide la estrategia:

1. **Analiza el problema** y determina qué revisar primero
2. **Conecta SSH** al servidor indicado
3. **Explora**: logs (`/var/log/`, `journalctl`), configs, estado de servicios, procesos, puertos
4. Diagnostica en un **loop de retroalimentación**: revisa → encuentra pistas → profundiza → hasta encontrar la causa raíz
5. **Propone solución** al usuario antes de ejecutar
6. **Ejecuta y verifica** (abriendo navegador si aplica)
7. Si no funciona → vuelve a diagnosticar con la nueva información
8. Al resolver, ofrece guardar la solución y reflejar en código local

El problema puede ser cualquier cosa: Apache caído, daloRADIUS que no responde, error en logs, puerto cerrado, certificado vencido, etc. El solucionador se adapta.

## Cuándo invocarlo

- El usuario describe un problema en un servidor remoto
- El usuario dice "conéctate", "soluciona", "depura", "revisa por qué falla X"
- El `pensador` detecta que el problema requiere acceso SSH a un servidor remoto
- Problemas de infraestructura, red, servicios (Apache, daloRADIUS, Docker, etc.)
