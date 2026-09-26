# Plan: Remediación de fuga de secreto

## Resumen
Eliminar API key filtrada de historial Git, limpiar archivos temporales y endurecer gitleaks.

## Fases
1. **Inventario y backup**
   - Listar commits que tocan `temp_opencode_output.txt`
   - Backup del repo local

2. **Limpieza de working tree**
   - Borrar archivo y añadir a `.gitignore`

3. **Reescritura de historial**
   - `git filter-repo --path temp_opencode_output.txt --invert-paths`
   - Verificar con `gitleaks detect`

4. **Hardening**
   - Crear `.gitleaks.toml` con allowlist
   - Actualizar `.gitignore`

5. **Validación**
   - Ejecutar `gitleaks detect --source . --redact --verbose`
   - Push con `--force-with-lease`
   - Confirmar workflow verde

## Entregables
- `.gitignore` actualizado
- `.gitleaks.toml` creado
- Historial sin `temp_opencode_output.txt`
- Reporte de validación

## Riesgos y mitigaciones
- Colaboradores con ramas locales → comunicación previa
- Falsa detección de secretos → revisar allowlist
