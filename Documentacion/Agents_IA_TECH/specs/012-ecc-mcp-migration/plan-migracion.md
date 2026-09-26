# Plan de migración .env.mcp → mcp-configs/mcp-servers.json

## Objetivo
Adoptar mcp-configs/mcp-servers.json de ECC como fuente única de verdad para MCPs.

## Pasos
1. **Inventario**
   - Leer .env.mcp actual
   - Leer proyect_ext/ECC/mcp-configs/mcp-servers.json

2. **Transformación**
   - Mapear variables .env.mcp a estructura JSON de ECC
   - Generar mcp-servers.json local en proyect_ext/ECC/mcp-configs
   - Mantener compatibilidad con update-mcp.ps1

3. **Validación**
   - Validar que update-mcp.ps1 lee JSON correctamente
   - Probar instalación de MCPs desde JSON
   - Verificar que índices y grafos no se ven afectados

4. **Corte**
   - Deprecar .env.mcp
   - Documentar fuente única

## Criterios de éxito
- update-mcp.ps1 funciona con JSON
- No hay duplicidad de fuentes
- Integración validada
