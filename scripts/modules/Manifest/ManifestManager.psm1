# ManifestManager.psm1 — Sincroniza versiones del manifest local con la referencia (014-manifest).
#
# REGLAS (FR-003 + RNF):
# - Compara por nombre de herramienta entre <RootPath>/dependencias-manifest.yml
#   (local, esquema lista `- nombre:` o esquema mapa) y la referencia
#   (proyect_ext/dependencias-manifest.yml, esquema mapa con flags `upgrade:`).
# - Por defecto SOLO informa drift (reporte). Con -Apply escribe únicamente los
#   `version_actual:` que difieren y no están pinneados (referencia upgrade:false),
#   con CIRUGÍA DE LÍNEAS sobre el archivo local: comentarios, historial y resto
#   de claves quedan byte-idénticos (jamás se re-serializa el archivo).
# - Herramientas solo-locales se reportan como extra y jamás se tocan.
# - Idempotente: segunda corrida tras -Apply reporta 0 diferencias.
# - -DryRun informa lo que haría sin escribir.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# Logging local: las funciones Write-* del bootstrap NO resuelven dentro del
# ámbito del módulo; se definen aquí para no depender del llamador.
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Warning $Message }
$yamlHelper = Join-Path (Split-Path -Parent $here) 'Utils\YamlHelper.psm1'
if ((Test-Path -LiteralPath $yamlHelper) -and -not (Get-Command Read-Yaml -ErrorAction SilentlyContinue)) {
    Import-Module $yamlHelper -Force
}
$refModule = Join-Path $here 'ManifestReference.psm1'
if ((Test-Path -LiteralPath $refModule) -and -not (Get-Command Get-ManifestReference -ErrorAction SilentlyContinue)) {
    Import-Module $refModule -Force
}

function Ensure-DependenciasManifest {
    param([string]$RootPath = '.')
    $manifest = Join-Path $RootPath 'dependencias-manifest.yml'
    if (Test-Path -LiteralPath $manifest) { return $manifest }
    $reference = Join-Path $RootPath 'proyect_ext\dependencias-manifest.yml'
    if (Test-Path -LiteralPath $reference) {
        Copy-Item -LiteralPath $reference -Destination $manifest -Force
        Write-Info "Ensure-DependenciasManifest: creado desde la referencia $reference"
        return $manifest
    }
    Set-Content -LiteralPath $manifest -Value "dependencias_externas: {}`r`naplicaciones: {}`r`n" -Encoding UTF8
    Write-Warn "Ensure-DependenciasManifest: sin referencia; creado esqueleto mínimo en $manifest"
    return $manifest
}

# Normaliza la sección dependencias_externas (lista `- nombre:` o mapa) a:
# @{ <nombre> = @{ Version='<...>'; Upgrade=$bool|$null } }
function ConvertTo-ToolMap {
    param([object]$Section)
    $map = [ordered]@{}
    if ($null -eq $Section) { return $map }
    if ($Section -is [System.Collections.IDictionary]) {
        foreach ($k in $Section.Keys) {
            $v = $Section[$k]
            $ver = $null; $upg = $null
            if ($v -is [System.Collections.IDictionary]) {
                if ($null -ne $v['version_actual']) { $ver = "$($v['version_actual'])" }
                if ($null -ne $v['upgrade']) { $upg = [bool]$v['upgrade'] }
            } elseif ($null -ne $v) {
                $ver = "$v"
            }
            $map["$k"] = @{ Version = $ver; Upgrade = $upg }
        }
    } elseif ($Section -is [System.Collections.IList]) {
        foreach ($item in $Section) {
            if ($item -is [System.Collections.IDictionary] -and $null -ne $item['nombre']) {
                $ver = $null
                if ($null -ne $item['version_actual']) { $ver = "$($item['version_actual'])" }
                $map["$($item['nombre'])"] = @{ Version = $ver; Upgrade = $null }
            }
        }
    }
    return $map
}

function Sync-Manifest {
    param(
        [string]$RootPath = '.',
        [string]$ReferencePath = '',
        [switch]$Apply,
        [switch]$DryRun
    )
    $localPath = Join-Path $RootPath 'dependencias-manifest.yml'
    if (-not (Test-Path -LiteralPath $localPath)) {
        throw "Sync-Manifest: no existe el manifest local $localPath (crearlo con Ensure-DependenciasManifest primero)"
    }
    $localData = Read-Yaml $localPath
    $refData = Get-ManifestReference -RootPath $RootPath -ReferencePath $ReferencePath
    $report = [pscustomobject]@{
        LocalPath      = $localPath
        Compared       = 0
        Differ         = 0
        MissingLocal   = 0
        Pinned         = 0
        ExtraLocal     = 0
        Applied        = 0
        Details        = New-Object System.Collections.Generic.List[string]
    }
    if ($null -eq $refData) {
        $report.Details.Add('sin-referencia: se omite (fail-open)') | Out-Null
        return $report
    }
    $localMap = ConvertTo-ToolMap $localData['dependencias_externas']
    $refMap = ConvertTo-ToolMap $refData['dependencias_externas']
    $toApply = New-Object System.Collections.Generic.List[object]
    foreach ($tool in @($refMap.Keys)) {
        $report.Compared++
        if (-not $localMap.Contains($tool)) {
            $report.MissingLocal++
            $report.Details.Add("$tool : falta en local (referencia: $($refMap[$tool].Version))") | Out-Null
            continue
        }
        $lv = $localMap[$tool].Version
        $rv = $refMap[$tool].Version
        # Comparación por token canónico: el local puede llevar notas
        # (ej. "0.9.48 (PyPI...)") y la referencia el token limpio ("0.9.48").
        if ((Get-VersionToken $lv) -ne (Get-VersionToken $rv)) {
            if ($refMap[$tool].Upgrade -eq $false) {
                $report.Pinned++
                $report.Details.Add("$tool : difiere pero pinneado (upgrade:false, local=$lv ref=$rv)") | Out-Null
                continue
            }
            $report.Differ++
            $report.Details.Add("$tool : local=$lv -> ref=$rv") | Out-Null
            $toApply.Add([pscustomobject]@{ Tool = $tool; NewVersion = $rv }) | Out-Null
        }
    }
    foreach ($tool in @($localMap.Keys)) {
        if (-not $refMap.Contains($tool)) {
            $report.ExtraLocal++
            $report.Details.Add("$tool : solo-local (se conserva)") | Out-Null
        }
    }
    if ($Apply -and $toApply.Count -gt 0) {
        if ($DryRun) {
            Write-Info "DryRun: aplicaría $($toApply.Count) version(es) en $localPath (sin escribir)."
        } else {
            $report.Applied = Set-ManifestVersions -Path $localPath -Changes $toApply
        }
    }
    foreach ($d in $report.Details) { Write-Host "  - $d" }
    Write-Info ("Sync-Manifest: comparadas={0} difieren={1} faltan-local={2} pinneadas={3} extra-local={4} aplicadas={5}" -f $report.Compared, $report.Differ, $report.MissingLocal, $report.Pinned, $report.ExtraLocal, $report.Applied)
    return $report
}

# Token canónico de versión: primer token tipo versión al inicio
# (ej. "0.9.48 (nota...)" -> "0.9.48", "v1.0.169" -> "v1.0.169").
function Get-VersionToken {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return '' }
    $m = [regex]::Match($Raw.Trim(), '^[vV]?\d[\w.\-]*')
    if ($m.Success) { return $m.Value }
    return $Raw.Trim()
}

# Intenta reescribir el valor de una línea `version_actual:`.
# Devuelve @($true, $nuevaLinea) si aplica; @($false, 'notas') si el valor
# local lleva prosa (fail-closed: no se toca); @($false, 'no') si no es
# línea version_actual.
function Try-UpdateVersionLine {
    param([string]$Line, [string]$NewVersion)
    $code = ($Line -split '#', 2)[0]
    if ($code -notmatch '^(\s*version_actual:\s*)([''"]?)(.*?)(\2)(\s*)$') {
        return @($false, 'no')
    }
    $curRaw = $Matches[3]
    if ((Get-VersionToken $curRaw) -ne $curRaw.Trim()) {
        return @($false, 'notas')
    }
    $tail = ''
    $hashAt = $Line.IndexOf('#')
    if ($hashAt -ge 0) { $tail = ' ' + $Line.Substring($hashAt).TrimEnd() }
    $q = $Matches[2]
    if ($q -eq '' -and $NewVersion -match '\s') { $q = "'" }
    return @($true, ($Matches[1] + $q + $NewVersion + $q + $tail))
}

# Cirugía de líneas: reescribe solo el valor de `version_actual:` dentro del
# bloque de cada herramienta (lista `- nombre:` o mapa `  herramienta:`),
# preservando indentación, comillas, comentarios de fin de línea y todo lo demás.
# Si el valor local lleva prosa/notas más allá del token, NO se auto-sobrescribe
# (se reporta para revisión manual: fail-closed sobre documentación).
function Set-ManifestVersions {
    param([string]$Path, [object]$Changes)
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $applied = 0
    foreach ($ch in $Changes) {
        $tool = [regex]::Escape($ch.Tool)
        $resolved = $false
        # 1) Estilo lista: bloque `- nombre: <tool>`; ventana hasta el próximo
        #    item al mismo indent o una clave raíz (columna 0).
        $idx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^\s*-\s+nombre:\s*$tool\s*(#.*)?$") { $idx = $i; break }
        }
        if ($idx -ge 0) {
            $itemIndent = ($lines[$idx].Length - $lines[$idx].TrimStart(' ').Length)
            for ($j = $idx + 1; $j -lt $lines.Count; $j++) {
                $ln = $lines[$j]
                if ($ln -match '^\s*$') { continue }
                $code = ($ln -split '#', 2)[0]
                if ($code -match '^\s*$') { continue }
                $ind = ($code.Length - $code.TrimStart(' ').Length)
                if ($ind -le $itemIndent) { break }
                $r = Try-UpdateVersionLine -Line $ln -NewVersion $ch.NewVersion
                if ($r[0]) { $lines[$j] = $r[1]; $applied++; $resolved = $true; break }
                if ($r[1] -eq 'notas') {
                    Write-Warn "Sync-Manifest: '$($ch.Tool)' lleva notas locales; no se auto-sobrescribe (revisar manual)."
                    $resolved = $true
                    break
                }
            }
        }
        if (-not $resolved) {
            # 2) Estilo mapa: bloque `  <tool>:`; ventana a mayor indent.
            :scanMap for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^(\s+)${tool}:\s*(#.*)?$") {
                    $itemIndent = ($lines[$i].Length - $lines[$i].TrimStart(' ').Length)
                    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                        $ln = $lines[$j]
                        if ($ln -match '^\s*$') { continue }
                        $code = ($ln -split '#', 2)[0]
                        if ($code -match '^\s*$') { continue }
                        $ind = ($code.Length - $code.TrimStart(' ').Length)
                        if ($ind -le $itemIndent) { break scanMap }
                        $r = Try-UpdateVersionLine -Line $ln -NewVersion $ch.NewVersion
                        if ($r[0]) { $lines[$j] = $r[1]; $applied++; $resolved = $true; break }
                        if ($r[1] -eq 'notas') {
                            Write-Warn "Sync-Manifest: '$($ch.Tool)' lleva notas locales; no se auto-sobrescribe (revisar manual)."
                            $resolved = $true
                            break
                        }
                    }
                    break
                }
            }
        }
        if (-not $resolved) { Write-Warn "Sync-Manifest: no se pudo ubicar version_actual de '$($ch.Tool)' (se omite esa entrada)." }
    }
    if ($applied -gt 0) {
        Set-Content -LiteralPath $Path -Value ($lines -join "`r`n") -Encoding UTF8
        Write-OK "Sync-Manifest: $applied version(es) aplicadas en $Path (resto intacto)."
    }
    return $applied
}

Export-ModuleMember -Function Ensure-DependenciasManifest, Sync-Manifest
