# Quickstart: Validar auto-creación de dependencias-manifest.yml

## Prerrequisitos
- PowerShell 7+
- Proyecto sin `dependencias-manifest.yml`

## Pasos
1. Ejecutar bootstrap:
   ```powershell
   .\scripts\plataformador-bootstrap.ps1 -RootPath "C:\Proyectos\MiProyecto"
   ```
2. Verificar creación:
   ```powershell
   Test-Path "C:\Proyectos\MiProyecto\dependencias-manifest.yml"
   ```
3. Verificar contenido:
   ```powershell
   Get-Content "C:\Proyectos\MiProyecto\dependencias-manifest.yml"
   ```
   Debe contener secciones `dependencias_externas:` y `aplicaciones:` vacías.

## Resultado esperado
- Archivo creado con esqueleto válido.
- Sin WARN de `Read-DependenciasManifest`.
- `Read-DependenciasManifest` devuelve lista vacía.
