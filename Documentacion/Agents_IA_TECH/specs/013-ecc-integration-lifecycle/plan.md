# Plan: Ciclo de vida de integración ECC

## Fases
1. **Preparación**
   - Crear rama feature/ecc-integration
   - Clonar ECC en proyect_ext/ECC

2. **Control de integración**
   - Crear scripts/ecc-sync.ps1 con comandos install/update/validate/uninstall
   - Registrar estado en .ecc-state.json

3. **Validación**
   - Ejecutar validación de flujo Speckit
   - Corregir duplicaciones y namespace

4. **Documentación**
   - Matriz de comparación
   - Guía de mantenimiento

## Entregables
- scripts/ecc-sync.ps1
- .ecc-state.json
- Matriz de comparación
- Rama de prueba
