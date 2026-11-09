<#
.SYNOPSIS
    Valida que el kit no contenga rutas absolutas hardcodeadas en archivos distribuibles.
.DESCRIPTION
    Escanea README.md, AGENTS.md, scripts/, .github/, .opencode/, .doc_agents/, Documentacion/
    buscando patrones de rutas absolutas Windows (C:\Proyectos, D:\), Linux (/home/, /Users/).
    Debe devolver 0 resultados (excepto líneas de comentario con variable $KitPath/$ProjectRoot).
    Excluye el script de validación (plataformador-bootstrap.ps1) que contiene los patrones como strings de detección.
#>

Describe "Kit Portability - No Hardcoded Absolute Paths" {
    $kitRoot = (Split-Path $PSScriptRoot -Parent)
    
    # Archivos y directorios distribuibles del kit
    $distributablePaths = @(
        "$kitRoot\README.md",
        "$kitRoot\AGENTS.md",
        "$kitRoot\scripts\*.ps1",
        "$kitRoot\.github\**\*.md",
        "$kitRoot\.opencode\**\*.md",
        "$kitRoot\.doc_agents\*.md",
        "$kitRoot\Documentacion\**\*.md"
    )

    # Patrones prohibidos (rutas absolutas típicas del autor)
    $forbiddenPatterns = @(
        "C:\\\\Proyectos",      # Rutas Windows del autor
        "D:\\\\",               # Otras unidades Windows
        "/home/",               # Rutas Linux home
        "/Users/"               # Rutas macOS Users
    )

    foreach ($pattern in $forbiddenPatterns) {
        It "No contiene patrón '$pattern' en archivos distribuibles" {
            $matches = @()
            foreach ($path in $distributablePaths) {
                $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue -Recurse
                foreach ($file in $files) {
                    # Excluir el script de validación que contiene los patrones como strings de detección
                    if ($file.Name -eq "plataformador-bootstrap.ps1") { continue }
                    $lines = Select-String -Path $file.FullName -Pattern $pattern -ErrorAction SilentlyContinue
                    foreach ($line in $lines) {
                        # Permitir solo si es comentario con variable $KitPath o $ProjectRoot
                        $lineText = $line.Line.Trim()
                        if (-not ($lineText.StartsWith("#") -and ($lineText -like '*$KitPath*' -or $lineText -like '*$ProjectRoot*'))) {
                            $matches += "$($file.FullName):$($line.LineNumber) → $lineText"
                        }
                    }
                }
            }
            $matches | Should -BeNullOrEmpty -Because "Se encontraron rutas absolutas hardcodeadas no permitidas: $($matches -join '; ')"
        }
    }
}