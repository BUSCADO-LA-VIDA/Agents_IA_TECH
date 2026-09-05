# Limpiar archivos legacy de Documentacion/ raíz
# Estos archivos ya están en Documentacion/Agents_IA_TECH/

Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\capacidad-base.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\idioma.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\preferencias.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\preferencias-git.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\referencias.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\roadmap.md" -Force -ErrorAction SilentlyContinue
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\pendientes-implementacion.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\soluciones-conocidas.md" -Force
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\memoria-proyecto.md" -Force

# Eliminar carpetas legacy vacías
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\arquitectura" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\funcionalidades" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\bitacoras" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "c:\Proyectos\Agents_IA_TECH\Documentacion\agents" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Archivos legacy eliminados. Solo queda Documentacion/00-indice.md (índice repo) y Documentacion/Agents_IA_TECH/ (doc proyecto)."