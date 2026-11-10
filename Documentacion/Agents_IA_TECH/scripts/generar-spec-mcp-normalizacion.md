# Generación de spec desde scripts

## Requisito
Todo lo debe generarse desde `$KitPath\scripts`.

## Script a crear
`$KitPath\scripts\generate-mcp-path-normalization-spec.ps1`

Contenido del script:
```powershell
$specPath = "$KitPath\Documentacion\Agents_IA_TECH\specs\009-mcp-path-normalization\spec.md"
$specContent = @'
# Spec 009 - Normalización de rutas MCP a forward slashes
...
'@
Set-Content -LiteralPath $specPath -Value $specContent -Encoding UTF8
```

## Ejecución
```powershell
pwsh $KitPath\scripts\generate-mcp-path-normalization-spec.ps1
```

## Nota
La generación debe realizarse desde el directorio scripts para mantener la trazabilidad y reproducibilidad en todos los proyectos.
