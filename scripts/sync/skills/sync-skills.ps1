#!/usr/bin/env pwsh
#requires -Version 7.0
# =============================================================================
# [022] scripts/sync/skills/sync-skills.ps1
# [022] Integración ECC por copia + espejo por harness (spec 022-ecc-integration).
# [022] Modelo: externo (proyect_ext/, gitignored) = caché; contenido integrado viaja en git.
# [022] RF-01: por cada SKILL.md del kit con contraparte ECC se conserva la fachada
# [022]   SSD y se anexa debajo el contenido ECC con tag de trazabilidad (HEAD + fecha).
# [022]   Sin -Force omite las ya integradas al HEAD vigente (idempotente).
# [022] RF-02: espeja .github/skills -> .opencode/skills (misma ruta relativa;
# [022]   copia solo si el hash difiere; deriva inversa = WARN sin borrar).
# [022] RF-03: verifica/repara .github/rules/ecc-{common,python}/ desde ECC
# [022]   rules/{common,python}/ con tag de origen. Emite
# [022]   RESULT:skills:integradas=.. omitidas=.. espejadas=.. derivas=.. en stdout.
# =============================================================================

[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/../lib/common.ps1"
Initialize-SyncLog

# [022] Raiz del repo: scripts/sync/skills -> sync -> scripts -> root.
if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "sync-skills: -RootPath invalido ($RootPath): $_"; exit 1 }

$EccSkills = Join-Path $RootPath "proyect_ext/ECC/skills"
$GhSkills = Join-Path $RootPath ".github/skills"
$OcSkills = Join-Path $RootPath ".opencode/skills"
$GhRules = Join-Path $RootPath ".github/rules"
$EccRules = Join-Path $RootPath "proyect_ext/ECC/rules"

# [022] HEAD corto del caché ECC para el tag de trazabilidad ("desconocido" si git falla).
$EccHead = "desconocido"
try {
    $gitOut = git -C (Join-Path $RootPath "proyect_ext/ECC") rev-parse --short HEAD 2>$null
    if ($gitOut) { $EccHead = ([string]$gitOut).Trim() }
    if (-not $EccHead) { $EccHead = "desconocido" }
} catch { $EccHead = "desconocido" }
$Fecha = (Get-Date).ToString('yyyy-MM-dd')

Write-Step "sync-skills: integrando ECC ($EccHead)"
if ($DryRun) { Write-Info "sync-skills: modo DryRun (sin escrituras)." }

$integradas = 0; $omitidas = 0; $espejadas = 0; $derivas = 0

if (-not (Test-Path -LiteralPath $EccSkills -PathType Container)) {
    Write-Fail "sync-skills: no existe el cache ECC ($EccSkills); nada que integrar."
    Show-ExecutionSummary -Title "sync-skills"
    exit 1
}
if (-not (Test-Path -LiteralPath $GhSkills -PathType Container)) {
    Write-Fail "sync-skills: no existe $GhSkills; nada que integrar/espejar."
    Show-ExecutionSummary -Title "sync-skills"
    exit 1
}

# =============================================================================
# [022] RF-01 — Integración con copia y tag.
# [022] Por cada SKILL.md del kit con contraparte proyect_ext/ECC/skills/<nombre>/SKILL.md:
# [022] quita secciones viejas (integrada previa o puntero viejo), conserva la fachada
# [022] (TrimEnd) y anexa el bloque con tag del HEAD vigente + contenido ECC verbatim.
# [022] Sin -Force: omite si el tag del HEAD vigente ya está. Fail-open por skill.
# =============================================================================
# [022] NOTA: el check omite el ")" final a propósito: el bloque anexado (y las 76
# [022] fachadas ya integradas) usan el formato "(integrada <HEAD>, <fecha>)" con la
# [022] fecha DENTRO del paréntesis, por lo que el literal "(integrada <HEAD>)" del
# [022] diseño nunca matchea (verificado: Contains()=False sobre api-design). El prefijo
# [022] sin ")" sí matchea al HEAD vigente y preserva la idempotencia (RF-01/SC-03).
$tagActual = "## Profundidad ECC (integrada $EccHead"
$rxIntegradaPrevia = "(?s)\r?\n---\r?\n\r?\n## Profundidad ECC.*\z"
$rxPunteroViejo = "(?s)\r?\n## Profundidad ECC\r?\nDetalle tecnico completo.*\z"

$fachadas = Get-ChildItem -LiteralPath $GhSkills -Recurse -File -Filter "SKILL.md" | Sort-Object FullName
foreach ($f in $fachadas) {
    $nombre = $f.Directory.Name
    $eccFile = Join-Path $EccSkills (Join-Path $nombre "SKILL.md")
    # [022] Sin contraparte ECC (p. ej. speckit-* propias del kit): se deja intacta.
    if (-not (Test-Path -LiteralPath $eccFile -PathType Leaf)) { continue }
    try {
        $texto = [IO.File]::ReadAllText($f.FullName)
        if ((-not $Force) -and $texto.Contains($tagActual)) { $omitidas++; continue }
        $eccTexto = [IO.File]::ReadAllText($eccFile)
        $base = [regex]::Replace($texto, $rxIntegradaPrevia, "")
        $base = [regex]::Replace($base, $rxPunteroViejo, "")
        $base = $base.TrimEnd()
        # [022] Bloque anexado: cabecera CRLF (convención del kit) + contenido ECC verbatim.
        $bloque = "`r`n---`r`n`r`n## Profundidad ECC (integrada $EccHead, $Fecha)`r`n`r`n" + '> Fuente: `proyect_ext/ECC/skills/' + $nombre + '/SKILL.md` (cache de descarga, no se sincroniza). Contenido copiado al KIT: viaja en git a los demas proyectos.' + "`r`n`r`n" + $eccTexto.TrimStart()
        if ($DryRun) { Write-Info "DryRun: integraria $($f.FullName) (ECC $nombre @ $EccHead)."; $integradas++; continue }
        [IO.File]::WriteAllText($f.FullName, $base + $bloque, [Text.UTF8Encoding]::new($false))
        Write-OK "integrada $nombre ($EccHead)."
        $integradas++
    } catch {
        Write-Warn "sync-skills: RF-01 omitida para $nombre (fail-open): $_"
    }
}

# =============================================================================
# [022] RF-02 — Espejo .github/skills -> .opencode/skills (misma ruta relativa).
# [022] Crea directorios y copia solo si el hash difiere. Deriva inversa
# [022] (.opencode sin par en .github): WARN, nunca borrar. Fail-open por archivo.
# =============================================================================
$origenes = Get-ChildItem -LiteralPath $GhSkills -Recurse -File | Sort-Object FullName
foreach ($o in $origenes) {
    try {
        $rel = [IO.Path]::GetRelativePath($GhSkills, $o.FullName)
        $dest = Join-Path $OcSkills $rel
        $copiar = $true
        if (Test-Path -LiteralPath $dest -PathType Leaf) {
            $h1 = (Get-FileHash -LiteralPath $o.FullName -Algorithm SHA256).Hash
            $h2 = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
            $copiar = ($h1 -ne $h2)
        }
        if (-not $copiar) { continue }
        if ($DryRun) { Write-Info "DryRun: espejaria $rel (.github -> .opencode)."; $espejadas++; continue }
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir -PathType Container)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -LiteralPath $o.FullName -Destination $dest -Force
        Write-OK "espejada $rel."
        $espejadas++
    } catch {
        Write-Warn "sync-skills: RF-02 omitido para $($o.FullName) (fail-open): $_"
    }
}
if (Test-Path -LiteralPath $OcSkills -PathType Container) {
    $espejos = Get-ChildItem -LiteralPath $OcSkills -Recurse -File | Sort-Object FullName
    foreach ($m in $espejos) {
        $rel = [IO.Path]::GetRelativePath($OcSkills, $m.FullName)
        $par = Join-Path $GhSkills $rel
        if (-not (Test-Path -LiteralPath $par -PathType Leaf)) {
            Write-Warn "sync-skills: deriva inversa $rel (existe en .opencode sin par en .github; no se borra)."
            $derivas++
        }
    }
}

# =============================================================================
# [022] RF-03 — Rules con tag: .github/rules/ecc-<Dst>/ desde ECC rules/<Src>/.
# [022] Copia si falta el archivo o si no lleva tag 'KIT ECC-integrado', anteponiendo
# [022] tag de origen (+ alias de agente propio solo si la fuente menciona
# [022] security-reviewer; precedente: solo security.md lo lleva). Fail-open por archivo.
# =============================================================================
$pares = @(@{ Src = "common"; Dst = "ecc-common" }, @{ Src = "python"; Dst = "ecc-python" })
$aliasSeguridad = '<!-- KIT: en este repo `security-reviewer` = `security-auditor` (agente propio). -->'
foreach ($par in $pares) {
    $srcDir = Join-Path $EccRules $par.Src
    $dstDir = Join-Path $GhRules $par.Dst
    if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) {
        Write-Warn "sync-skills: RF-03 sin fuente ECC ($srcDir); se omite el par $($par.Src)->$($par.Dst)."
        continue
    }
    $fuentes = Get-ChildItem -LiteralPath $srcDir -File | Sort-Object Name
    foreach ($s in $fuentes) {
        try {
            $dest = Join-Path $dstDir $s.Name
            $conTag = $false
            if (Test-Path -LiteralPath $dest -PathType Leaf) {
                $conTag = ([IO.File]::ReadAllText($dest)).Contains("KIT ECC-integrado")
            }
            if ($conTag) { continue }
            $srcTexto = [IO.File]::ReadAllText($s.FullName)
            $cabecera = "<!-- KIT ECC-integrado $EccHead ${Fecha}: copiado de proyect_ext/ECC/rules/$($par.Src)/ (cache, no se sincroniza). Viaja en git. -->" + "`r`n"
            if ($srcTexto.Contains("security-reviewer")) { $cabecera += $aliasSeguridad + "`r`n" }
            if ($DryRun) { Write-Info "DryRun: copiaria rules $($par.Dst)/$($s.Name) (ECC rules/$($par.Src)/)."; continue }
            if (-not (Test-Path -LiteralPath $dstDir -PathType Container)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            [IO.File]::WriteAllText($dest, $cabecera + $srcTexto, [Text.UTF8Encoding]::new($false))
            Write-OK "rules $($par.Dst)/$($s.Name) copiado."
        } catch {
            Write-Warn "sync-skills: RF-03 omitido para $($par.Dst)/$($s.Name) (fail-open): $_"
        }
    }
}

Write-Host "RESULT:skills:integradas=$integradas omitidas=$omitidas espejadas=$espejadas derivas=$derivas"
Show-ExecutionSummary -Title "sync-skills"
