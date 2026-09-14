# Spec: Agente `solucionador` - Agents_IA_TECH

> **Propósito**: Agente de **altos privilegios** para diagnóstico y solución de problemas en **servidores remotos vía SSH**. Solo se invoca bajo demanda explícita del usuario a través del `pensador`. **Único en mis agentes** (Specify no tiene esto).

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
    Q -->|Si| R[Guarda bitacora en Documentacion/Agents_IA_TECH/bitacoras/]
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
| 🧠 Corto plazo (bitácora) | `Documentacion/Agents_IA_TECH/bitacoras/<YYYY-MM-DD>-<problema>.md` | Markdown | Cada intervención: problema, comandos ejecutados, outputs, decisiones. |
| 📚 Largo plazo (conocidas) | `Documentacion/Agents_IA_TECH/soluciones-conocidas.md` | Markdown | Problemas recurrentes ya resueltos. Se consulta **siempre primero**. |

## .gitattributes obligatorio

Si al diagnosticar un servidor se modifican archivos locales (Dockerfiles, scripts, configs), verificar que el proyecto tenga `.gitattributes` en la raíz con reglas `text eol=lf` para archivos Linux: `.dockerignore`, `.env.example`, `Dockerfile`, `Dockerfile-*`, `docker-compose.yml`, `init.sh`, `init-freeradius.sh`, `contrib/docker/*.conf`. Si no existe, crearlo o reportarlo.

## Capacidades

- **SSH**: conexión a servidores remotos (lectura + escritura)
- **Navegador**: abrir URLs para verificar soluciones
- **Edición local**: modificar archivos del proyecto (Dockerfiles, configs, scripts)
- **Edición remota**: modificar archivos en el servidor vía SSH
- **Bitácora**: registra cada acción con timestamp

## Reglas de oro

1. **Nunca se invoca solo** — solo el `pensador` o el usuario pueden llamarlo
2. **Siempre consultar `soluciones-conocidas.md` primero**
3. **Preguntar antes de ejecutar cambios destructivos**
4. **Bitácora obligatoria** en `Documentacion/Agents_IA_TECH/bitacoras/`
5. **Ofrecer reflejo local** al finalizar (actualizar código local equivalente)
6. **Ofrecer guardar como solución conocida** si el problema no estaba documentado

## Flujo de contexto (ADR-0002)

> **Fuente de verdad**: `Documentacion/Agents_IA_TECH/`. Los MCPs **optimizan**, NO reemplazan. Diagrama reutilizado del ADR-0002.

**Al iniciar una tarea**, consultar `Documentacion/Agents_IA_TECH/` para saber en qué punto de la solución estamos. Leer al menos:
- `Documentacion/Agents_IA_TECH/00-indice.md` — estado general del proyecto.
- `Documentacion/Agents_IA_TECH/pendientes-implementacion.md` — qué hay que implementar y qué está completado.
- `Documentacion/Agents_IA_TECH/soluciones-conocidas.md` — problemas recurrentes ya resueltos (se consulta **siempre primero**).
- `Documentacion/Agents_IA_TECH/preferencias.md` + `idioma.md` — reglas del usuario e idioma.

**Los MCPs optimizan, NO reemplazan**: `context-mode` (búsqueda FTS5+BM25), `codebase-memory-mcp` (grafo de conocimiento), `markitdown` (conversión de formatos). **Orden de consulta**: primero leer la documentación directa (fuente de verdad), luego usar los MCPs para búsquedas eficientes sobre lo ya leído. Si la documentación cambió → **actualizar memoria/índice** (re-indexar + actualizar `analisis-memoria.md`).

```mermaid
flowchart TD
    A[Agente inicia una tarea] --> B[Consultar Documentacion/Agents_IA_TECH/<br/>fuente de verdad]
    B --> C[Leer 00-indice.md<br/>estado general]
    B --> D[Leer pendientes-implementacion.md<br/>qué falta / qué está hecho]
    B --> E[Leer memoria-proyecto.md<br/>capacidades instaladas]
    B --> F[Leer preferencias.md + idioma.md<br/>reglas del usuario]

    C --> G{¿La documentación<br/>cambió desde el último índice?}
    D --> G
    E --> G
    F --> G

    G -->|Sí| H[Actualizar memoria/índice<br/>re-indexar context-mode + codebase-memory-mcp<br/>actualizar analisis-memoria.md]
    H --> I[Usar MCPs como optimización<br/>búsqueda eficiente sobre doc indexada]
    G -->|No| I

    I --> J[Ejecutar la tarea con contexto<br/>completo y actualizado]
    J --> K{¿La tarea modificó<br/>la documentación?}
    K -->|Sí| L[Actualizar memoria/índice<br/>re-indexar + actualizar analisis-memoria.md]
    K -->|No| M[✅ Fin]
    L --> M
```

## Enfoque de diagnóstico

1. Analiza el problema y determina qué revisar primero
2. Conecta SSH al servidor
3. Explora: logs, configs, servicios, procesos, puertos
4. Loop de retroalimentación hasta encontrar la causa raíz
5. Propone solución al usuario **antes de ejecutar**
6. Ejecuta y verifica (navegador si aplica)
7. Si no funciona → vuelve a diagnosticar
8. Al resolver, ofrece guardar solución y reflejar en código local

## Cuándo invocarlo

- El usuario describe un problema en un servidor remoto
- El usuario dice "conéctate", "soluciona", "depura"
- El `pensador` detecta que requiere acceso SSH con escritura
- Problemas de infraestructura, red, servicios (Apache, daloRADIUS, Docker, etc.)

## Diferencia con Pensador (SSH)

| Pensador | Solucionador |
|----------|--------------|
| SSH **solo lectura** (debug) | SSH **lectura + escritura** (fix) |
| Diagnóstico inicial | Resolución completa |
| "Veamos qué pasa" | "Arreglémoslo" |
| Si hay que modificar → delega a solucionador | Ejecuta la modificación |