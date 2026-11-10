<#
.SYNOPSIS
    Valida que el kit sea portable: ninguna ruta absoluta literal en archivos versionados.
.DESCRIPTION
    Universo de validacion: `git ls-files` (todos los archivos versionados, sin
    allowlist de directorios ni de archivos). Fail-closed: si el universo no se
    puede construir, el test falla.

    Los patrones se construyen por concatenacion de fragmentos a proposito, para
    que ESTE archivo no contenga los literales que persigue y pueda autoincluirse
    en el universo sin excepciones (spec 044, R3).

    Comparacion por grupo:
      - rutas Windows: sin distinguir mayusculas (NTFS no distingue: la misma
        ruta escrita en minusculas apunta al mismo sitio).
      - prefijos POSIX de home: distinguiendo mayusculas (un endpoint de API con
        "users" en minusculas no es una ruta de home; el home de macOS si lo es).
#>

$bs = [string][char]92
$fs = [string][char]47

$forbiddenPatterns = @(
    @{ Pattern = ('C:' + $bs + 'Proyectos');     IgnoreCase = $true },
    @{ Pattern = ('C:' + $fs + 'Proyectos');     IgnoreCase = $true },
    @{ Pattern = ('D:' + $bs + 'Proyectos');     IgnoreCase = $true },
    @{ Pattern = ('D:' + $fs + 'Proyectos');     IgnoreCase = $true },
    @{ Pattern = ('C:' + $bs + 'Users' + $bs);   IgnoreCase = $true },
    @{ Pattern = ('C:' + $fs + 'Users' + $fs);   IgnoreCase = $true },
    @{ Pattern = ('C:' + $bs + 'Python314');     IgnoreCase = $true },
    @{ Pattern = ('C:' + $fs + 'Python314');     IgnoreCase = $true },
    @{ Pattern = ('C:' + $bs + 'Program Files'); IgnoreCase = $true },
    @{ Pattern = ('C:' + $fs + 'Program Files'); IgnoreCase = $true },
    @{ Pattern = ('D:' + $bs);                   IgnoreCase = $true },
    @{ Pattern = ('D:' + $fs);                   IgnoreCase = $true },
    @{ Pattern = ($fs + 'home' + $fs);           IgnoreCase = $false },
    @{ Pattern = ($fs + 'Users' + $fs);          IgnoreCase = $false }
)

Describe 'Portabilidad del kit: rutas absolutas literales' {

    BeforeAll {
        $script:kitRoot = Split-Path $PSScriptRoot -Parent

        function Test-ContentIsText {
            param([string]$Path)
            try {
                $stream = [IO.File]::OpenRead($Path)
                try {
                    $buffer = New-Object byte[] 8192
                    $read = $stream.Read($buffer, 0, $buffer.Length)
                    for ($i = 0; $i -lt $read; $i++) {
                        if ($buffer[$i] -eq 0) { return $false }
                    }
                    return $true
                } finally { $stream.Dispose() }
            } catch { return $false }
        }

        function Get-VersionedFile {
            param([string]$Root)

            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                if (Get-Command git -ErrorAction SilentlyContinue) {
                    Push-Location -LiteralPath $Root
                    try {
                        $tracked = & git ls-files 2>$null
                        if ($LASTEXITCODE -eq 0 -and $tracked) { return @($tracked) }
                    } finally { Pop-Location }
                }

                # Fallback sin git: recorrido completo, sin exclusiones de directorio.
                # Unico filtro admitido: contenido binario (se descarta por contenido).
                return @(
                    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
                        Where-Object { Test-ContentIsText -Path $_.FullName } |
                        ForEach-Object { [IO.Path]::GetRelativePath($Root, $_.FullName) }
                )
            } finally { $ErrorActionPreference = $prevEap }
        }

        function Find-ForbiddenPath {
            param($Corpus, [string]$Pattern, [bool]$IgnoreCase)

            $comparison = if ($IgnoreCase) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
            $hits = [System.Collections.Generic.List[string]]::new()
            foreach ($file in $Corpus) {
                for ($i = 0; $i -lt $file.Lines.Length; $i++) {
                    if ($file.Lines[$i].IndexOf($Pattern, $comparison) -ge 0) {
                        $hits.Add(('{0}:{1} -> {2}' -f $file.Relative, ($i + 1), $file.Lines[$i].Trim()))
                    }
                }
            }
            return $hits.ToArray()
        }

        $script:versionedFiles = @(Get-VersionedFile -Root $script:kitRoot)

        $script:corpus = @()
        foreach ($relative in $script:versionedFiles) {
            $full = Join-Path $script:kitRoot $relative
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            if (-not (Test-ContentIsText -Path $full)) { continue }
            $script:corpus += [pscustomobject]@{
                Relative = $relative
                Lines    = [IO.File]::ReadAllLines($full)
            }
        }
    }

    It 'El universo es el conjunto versionado, sin allowlist, y esta poblado' {
        $script:versionedFiles.Count | Should -BeGreaterThan 100 -Because 'el universo debe cubrir todo el repo versionado'
        $script:versionedFiles | Should -Contain 'tests/validate-no-hardcoded-paths.Tests.ps1' -Because 'el validador se incluye a si mismo'
    }

    It 'El validador no declara listas de rutas (fail-closed por construccion)' {
        $self = Join-Path $script:kitRoot 'tests/validate-no-hardcoded-paths.Tests.ps1'
        $needle = 'distributable' + 'Paths'
        [IO.File]::ReadAllText($self).Contains($needle) | Should -BeFalse -Because 'una lista de rutas es fail-open: cada archivo nuevo quedaria fuera'
    }

    $cases = for ($i = 0; $i -lt $forbiddenPatterns.Count; $i++) {
        @{
            Identifier = ($i + 1)
            Pattern    = $forbiddenPatterns[$i].Pattern
            IgnoreCase = $forbiddenPatterns[$i].IgnoreCase
        }
    }

    It 'No aparece la ruta absoluta literal del grupo <Identifier>' -TestCases $cases {
        param($Identifier, $Pattern, $IgnoreCase)

        $hits = Find-ForbiddenPath -Corpus $script:corpus -Pattern $Pattern -IgnoreCase $IgnoreCase
        $hits | Should -BeNullOrEmpty -Because (("Rutas absolutas literales detectadas (grupo {0}):`n{1}") -f $Identifier, ($hits -join [Environment]::NewLine))
    }
}
