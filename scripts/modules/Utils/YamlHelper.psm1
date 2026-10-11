# YamlHelper.psm1 — Subconjunto YAML para manifests del kit (014-manifest).
#
# ALCANCE HONESTO: NO es un parser YAML general. Cubre exactamente lo que usan
# dependencias-manifest.yml (estilo mapa y estilo lista):
#   - mapas con indentación de 2 espacios (`clave:` / `clave: valor`)
#   - listas de mapas (`- nombre: x` + claves hijas indentadas)
#   - escalares: strings con/sin comillas simples/dobles, true/false (bool), int
#   - comentarios de línea (`#...`) y líneas en blanco: SE IGNORAN al leer
#     (por eso Sync-Manifest aplica cambios con cirugía de líneas, jamás
#     re-serializando el archivo: así se preservan comentarios e historial).
# Todo lo demás (tabs, multilínea `|`, anchors, `- clave:` vacía inline)
# NO se soporta y falla explícito con throw (fail-closed).
function Read-Yaml {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Read-Yaml: no existe $Path" }
    $lines = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) -split "`r?`n"
    $root = [ordered]@{}
    $stack = New-Object System.Collections.Generic.List[object]
    $stack.Add([pscustomobject]@{ Indent = -1; Node = $root }) | Out-Null
    # Clave con valor en líneas hijas aún no vista: (nodo, clave, indent).
    $pendingNode = $null
    $pendingKey = ''
    $pendingIndent = -1
    $li = 0
    foreach ($rawLine in $lines) {
        $li++
        if ($rawLine -match '^\s*$') { continue }
        $code = ($rawLine -split '#', 2)[0]
        if ($code -match '^\s*$') { continue }
        if ($code -match "`t") { throw "Read-Yaml ${Path}:$li : tabs no soportados (usar 2 espacios)" }
        $indent = ($code.Length - $code.TrimStart(' ').Length)
        $text = $code.Trim()
        # Resolver pendiente: ¿este renglón es hijo del `clave:` anterior?
        if ($null -ne $pendingNode) {
            if ($indent -gt $pendingIndent) {
                if ($text.StartsWith('- ')) {
                    $container = New-Object System.Collections.ArrayList
                } else {
                    $container = [ordered]@{}
                }
                $pendingNode[$pendingKey] = $container
                $stack.Add([pscustomobject]@{ Indent = $pendingIndent; Node = $container }) | Out-Null
            } else {
                # Sin hijos: mapa vacío.
                $pendingNode[$pendingKey] = [ordered]@{}
            }
            $pendingNode = $null
        }
        while ($stack.Count -gt 0 -and $indent -le $stack[$stack.Count - 1].Indent) {
            $stack.RemoveAt($stack.Count - 1)
        }
        if ($stack.Count -eq 0) { throw "Read-Yaml ${Path}:$li : indentación inválida" }
        $parent = $stack[$stack.Count - 1].Node
        if ($text.StartsWith('- ')) {
            if ($parent -isnot [System.Collections.ArrayList]) {
                throw "Read-Yaml ${Path}:$li : item '-' fuera de lista"
            }
            $rest = $text.Substring(2).Trim()
            if ($rest -eq '') { throw "Read-Yaml ${Path}:$li : '- clave:' vacía inline no soportada" }
            if ($rest -match '^[^:#]+:\s*(.+)$') {
                # Item mapa: `- clave: valor` (+ hijas indentadas).
                $item = [ordered]@{}
                $parent.Add($item) | Out-Null
                Parse-MapLine -Text $rest -Node $item -Where "${Path}:$li"
                $stack.Add([pscustomobject]@{ Indent = $indent; Node = $item }) | Out-Null
            } else {
                # Item escalar (ej. `- (nota)` en componentes_a_copiar).
                $parent.Add($rest) | Out-Null
            }
            continue
        }
        if ($parent -is [System.Collections.ArrayList]) {
            throw "Read-Yaml ${Path}:$li : clave suelta dentro de lista (falta '- ')"
        }
        $m = [regex]::Match($text, '^([^:#]+?):\s*(.*)$')
        if (-not $m.Success) { throw "Read-Yaml ${Path}:$li : línea mapa inválida '$text'" }
        $key = $m.Groups[1].Value.Trim()
        $val = $m.Groups[2].Value.Trim()
        if ($key -eq '') { throw "Read-Yaml ${Path}:$li : clave vacía" }
        if ($val -eq '') {
            $pendingNode = $parent
            $pendingKey = $key
            $pendingIndent = $indent
        } else {
            $parent[$key] = Convert-Scalar $val "${Path}:$li"
        }
    }
    if ($null -ne $pendingNode) {
        $pendingNode[$pendingKey] = [ordered]@{}
    }
    return $root
}

function Parse-MapLine {
    param([string]$Text, [System.Collections.IDictionary]$Node, [string]$Where)
    $m = [regex]::Match($Text, '^([^:#]+?):\s*(.*)$')
    if (-not $m.Success) { throw "Read-Yaml ${Where}: línea mapa inválida '$Text'" }
    $key = $m.Groups[1].Value.Trim()
    $val = $m.Groups[2].Value.Trim()
    if ($key -eq '' -or $val -eq '') { throw "Read-Yaml ${Where}: par clave/valor incompleto '$Text'" }
    $Node[$key] = Convert-Scalar $val $Where
}

function Convert-Scalar {
    param([string]$Val, [string]$Where)
    if ($Val.Length -ge 2 -and (($Val.StartsWith("'") -and $Val.EndsWith("'")) -or ($Val.StartsWith('"') -and $Val.EndsWith('"')))) {
        return $Val.Substring(1, $Val.Length - 2)
    }
    if ($Val -eq 'true') { return $true }
    if ($Val -eq 'false') { return $false }
    if ($Val -match '^[+-]?\d+$') { return [int]$Val }
    if ($Val.StartsWith('|') -or $Val.StartsWith('>')) { throw "Read-Yaml ${Where}: bloques literales no soportados" }
    return $Val
}

function Write-Yaml {
    param([string]$Path, [object]$Data)
    $lines = New-Object System.Collections.Generic.List[string]
    Emit-Node -Data $Data -Indent 0 -Lines $lines
    Set-Content -LiteralPath $Path -Value ($lines -join "`r`n") -Encoding UTF8
}

function Emit-Node {
    param([object]$Data, [int]$Indent, [System.Collections.Generic.List[string]]$Lines)
    $pad = ' ' * $Indent
    if ($Data -is [System.Collections.IDictionary]) {
        foreach ($k in $Data.Keys) {
            $v = $Data[$k]
            if ($v -is [System.Collections.IDictionary] -or $v -is [System.Collections.IList]) {
                $Lines.Add("${pad}${k}:") | Out-Null
                Emit-Node -Data $v -Indent ($Indent + 2) -Lines $Lines
            } else {
                $Lines.Add("${pad}${k}: $(Format-Scalar $v)") | Out-Null
            }
        }
    } elseif ($Data -is [System.Collections.IList]) {
        foreach ($item in $Data) {
            if ($item -is [System.Collections.IDictionary]) {
                $first = $true
                foreach ($k in $item.Keys) {
                    $v = $item[$k]
                    if ($first -and $v -isnot [System.Collections.IDictionary] -and $v -isnot [System.Collections.IList]) {
                        $Lines.Add("${pad}- ${k}: $(Format-Scalar $v)") | Out-Null
                        $first = $false
                    } elseif ($first) {
                        $Lines.Add("${pad}- ${k}:") | Out-Null
                        $first = $false
                        Emit-Node -Data $v -Indent ($Indent + 4) -Lines $Lines
                    } else {
                        if ($v -is [System.Collections.IDictionary] -or $v -is [System.Collections.IList]) {
                            $Lines.Add("${pad}  ${k}:") | Out-Null
                            Emit-Node -Data $v -Indent ($Indent + 4) -Lines $Lines
                        } else {
                            $Lines.Add("${pad}  ${k}: $(Format-Scalar $v)") | Out-Null
                        }
                    }
                }
            } else {
                $Lines.Add("${pad}- $(Format-Scalar $item)") | Out-Null
            }
        }
    } else {
        $Lines.Add("${pad}$(Format-Scalar $Data)") | Out-Null
    }
}

function Format-Scalar {
    param([object]$V)
    if ($null -eq $V) { return '~' }
    if ($V -is [bool]) { return $V.ToString().ToLowerInvariant() }
    if ($V -is [int]) { return "$V" }
    $s = "$V"
    if ($s -eq '' -or $s -match '[:#\[\]\{\},]|^\s|\s$') { return "'" + ($s -replace "'", "''") + "'" }
    return $s
}

Export-ModuleMember -Function Read-Yaml, Write-Yaml
