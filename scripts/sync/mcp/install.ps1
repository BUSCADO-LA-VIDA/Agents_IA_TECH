#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# [021] scripts/sync/mcp/install.ps1
# [021] Capa "mcp-install" del sync por capas (spec 021-sync-kit-agents, fase 3,
# [021] T009, RF-04/RNF-04 + RF-06). Instalador PORTABLE POR MAQUINA: en el KIT
# [021] se instala, en los proyectos se levanta (nunca se copian binarios).
# [021] NO recibe -StageDir: detecta en la maquina, instala lo ausente
# [021] (fail-open: try/catch + WARN accionable, continua con la siguiente) y
# [021] anota rutas reales resueltas en <Root>/.env.mcp (append idempotente) +
# [021] asegura la regla `.env.mcp` en <Root>/.gitignore (patron
# [021] Add-McpEnvGitignore de scripts/plataformador-bootstrap.ps1:517).
# [021] Comandos verificados (PROHIBIDO inventar URLs/paquetes/nombres):
# [021]   context-mode/codebase-memory-mcp/markitdown/graphify/tokenslayer ->
# [021]   scripts/plataformador-bootstrap.ps1:2939-2954,2992-3006 + `npm ls -g`
# [021]   (context-mode@1.0.169, codebase-memory-mcp@0.11.0) + `pip show`
# [021]   (markitdown-mcp 0.0.1a7 en C:\Python314; el pin 0.0.1a3 del bootstrap
# [021]   esta desactualizado, por eso se instala SIN pin) + `uv tool list`
# [021]   (graphifyy, semgrep) + bitacoras 2026-10-11-mcp-{github,playwright,
# [021]   semgrep,context7}.md. github sin binario -> WARN manual con
# [021]   release+asset documentados, SIN URL construida. semgrep-mcp (wrapper
# [021]   PyPI 0.9.0) DEPRECADO por upstream: NO se instala (bitacora semgrep).
# [021] Emite RESULT:mcp-install:<herramienta>:<ok|instalado|ausente-warn|
# [021] sin-cambios>. -DryRun: CERO escrituras y CERO installs. -Force:
# [021] reinstala/actualiza aunque el binario exista.
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

# [021] Default: raiz del repo (scripts/sync/mcp/ -> 3 niveles arriba).
if (-not $RootPath) { $RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) }
try { $RootPath = [IO.Path]::GetFullPath($RootPath) } catch { Write-Fail "mcp-install: -RootPath invalido ($RootPath): $_"; exit 1 }

# [021] Resuelve un comando en el PATH; devuelve su Source o $null.
function Resolve-OnPath {
    param([string]$Name)
    $c = Get-Command $Name -ErrorAction SilentlyContinue
    if ($c -and $c.Source) { return $c.Source }
    return $null
}

# [021] Sonda un ejecutable con timeout duro (15 s): nunca cuelga el sync.
# [021] Devuelve @{ Exit=; Text= } o $null si timeout/error. Nunca invocar aqui
# [021] subcomandos servidores (p. ej. `semgrep mcp`): solo --version/--help.
# [021] NOTA: el exit code se captura ANTES de truncar la salida: `| Select
# [021] -First N` sobre una salida larga aborta el pipeline y limpia
# [021] $LASTEXITCODE (visto con `python -m graphify.serve --help`).
function Invoke-Probe {
    param([string]$Exe, [string[]]$Arguments)
    $sb = {
        param($e, $a)
        $o = (& $e @a 2>&1)
        $c = $LASTEXITCODE
        $t = (($o | Select-Object -First 3 | Out-String)).Trim()
        [pscustomobject]@{ Exit = $c; Text = "$t" }
    }
    $job = $null
    try {
        $job = Start-Job -ScriptBlock $sb -ArgumentList $Exe, $Arguments
        $null = Wait-Job -Job $job -Timeout 15
        if ($job.State -ne 'Completed') { return $null }
        return Receive-Job -Job $job
    } catch { return $null }
    finally { if ($job) { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } }
}

# [021] Primera linea util de --version (fallbacks -V/--help). $null si nada.
# [021] -Strict: solo FirstArgs (para runners como `node cli.js`, donde los
# [021] fallbacks reportarian la version del runner y confundirian).
function Get-ExeVersion {
    param([string]$Exe, [string[]]$FirstArgs = @(), [switch]$Strict)
    $cands = @()
    if ($FirstArgs.Count -gt 0) { $cands += ,$FirstArgs }
    if (-not $Strict) { $cands += ,@('--version'), ,@('-V'), ,@('--help') }
    foreach ($a in $cands) {
        $r = Invoke-Probe -Exe $Exe -Arguments $a
        if ($r -and $r.Exit -eq 0 -and $r.Text) {
            return ((($r.Text -split "`r?`n") | Where-Object { "$_".Trim() -ne '' } | Select-Object -First 1)).Trim()
        }
    }
    return $null
}

# [021] Ejecuta un instalador (npm/uv/pip) con fail-open. Devuelve $true/$false.
function Invoke-Installer {
    param([string]$Tool, [string]$Exe, [string[]]$Arguments)
    if (-not (Get-Command $Exe -ErrorAction SilentlyContinue)) {
        Write-Warn "mcp-install: '$Exe' no esta en el PATH; no se puede instalar $Tool (instala el gestor y re-ejecuta)."
        return $false
    }
    try {
        $out = & $Exe @Arguments 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { Write-OK "mcp-install: $Tool instalado/actualizado."; return $true }
        Write-Warn "mcp-install: $Tool fallo (exit $LASTEXITCODE; se continua): $($out.Trim())"
        return $false
    } catch {
        Write-Warn "mcp-install: $Tool fallo ($_); se continua (fail-open)."
        return $false
    }
}

# [021] npm root global (para localizar cli.js reales sin inventar rutas).
function Get-NpmRootG {
    try {
        $r = (& npm root -g 2>$null | Out-String).Trim()
        if ($r -and (Test-Path -LiteralPath $r -PathType Container)) { return $r }
    } catch { }
    return (Join-Path $HOME "AppData/Roaming/npm/node_modules")
}

$npmRootG = Get-NpmRootG
$localBin = Join-Path $HOME ".local/bin"

# =============================================================================
# [021] Tabla de herramientas: Deteccion -> Instalacion -> Verificacion.
# [021] Detect devuelve @{ Path=; VerExe=; VerArgs= } o $null. InstallMissing /
# [021] InstallForce devuelven $true si el instalador reporto exito.
# =============================================================================
$tools = @(
    # [021] context-mode: paquete npm "context-mode" (verificado en disco:
    # [021] context-mode.ps1 + context-mode@1.0.169 en `npm ls -g`).
    @{ Key = "context-mode"; Env = "CONTEXT_MODE_CMD";
       Detect = { $p = Resolve-OnPath "context-mode"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "npm install -g context-mode"; HintForce = "npm install -g context-mode@latest";
       InstallMissing = { Invoke-Installer "context-mode" "npm" @("install", "-g", "context-mode") };
       InstallForce = { Invoke-Installer "context-mode" "npm" @("install", "-g", "context-mode@latest") } },
    # [021] codebase-memory-mcp: exe en ~/.local/bin (ver opencode.json del
    # [021] repo) o npm global; comando publicado `npm install -g
    # [021] codebase-memory-mcp` (bootstrap:2940 + npm ls -g 0.11.0).
    @{ Key = "codebase-memory-mcp"; Env = "CODEBASE_MEMORY_CMD";
       Detect = { $e = Join-Path $localBin "codebase-memory-mcp.exe"; if (Test-Path -LiteralPath $e) { return @{ Path = $e; VerExe = $e; VerArgs = @() } }; $p = Resolve-OnPath "codebase-memory-mcp"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "npm install -g codebase-memory-mcp"; HintForce = "npm install -g codebase-memory-mcp@latest";
       InstallMissing = { Invoke-Installer "codebase-memory-mcp" "npm" @("install", "-g", "codebase-memory-mcp") };
       InstallForce = { Invoke-Installer "codebase-memory-mcp" "npm" @("install", "-g", "codebase-memory-mcp@latest") } },
    # [021] markitdown: shim markitdown-mcp via pip (verificado: pip show
    # [021] markitdown-mcp 0.0.1a7 en C:\Python314); se inspecciono el .exe
    # [021] solo para determinar origen pip (no se modifico nada).
    @{ Key = "markitdown"; Env = "MARKITDOWN_CMD";
       Detect = { $p = Resolve-OnPath "markitdown-mcp"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "python -m pip install markitdown-mcp"; HintForce = "python -m pip install --upgrade markitdown-mcp";
       InstallMissing = { Invoke-Installer "markitdown" "python" @("-m", "pip", "install", "markitdown-mcp") };
       InstallForce = { Invoke-Installer "markitdown" "python" @("-m", "pip", "install", "--upgrade", "markitdown-mcp") } },
    # [021] graphify: Rama A del bootstrap (Configure-Graphify): primero el
    # [021] CLI `graphify` en el PATH (paquete PyPI graphifyy, doble-y), luego
    # [021] `python -m graphify.serve --help` exit 0 (bootstrap:2702-2747).
    # [021] Instalacion textual del bootstrap:2954 / upgrade_framework:1233.
    @{ Key = "graphify"; Env = "GRAPHIFY_CMD";
       Detect = {
           $g = Resolve-OnPath "graphify"
           if ($g) { $r = Invoke-Probe -Exe $g -Arguments @("--version"); if ($r -and $r.Exit -eq 0) { return @{ Path = $g; VerExe = $g; VerArgs = @() } } }
           $py = Resolve-OnPath "python"
           if ($py) { $r = Invoke-Probe -Exe $py -Arguments @("-m", "graphify.serve", "--help"); if ($r -and $r.Exit -eq 0) { return @{ Path = $py; VerExe = $py; VerArgs = @() } } }
           $uv = Resolve-OnPath "uv"
           if ($uv) { $r = Invoke-Probe -Exe $uv -Arguments @("tool", "run", "--from", "graphifyy", "python", "-m", "graphify.serve", "--help"); if ($r -and $r.Exit -eq 0) { return @{ Path = $py; VerExe = $uv; VerArgs = @("tool", "run", "--from", "graphifyy", "python", "--version") } } }
           return $null };
       HintMissing = 'uv tool install "graphifyy[mcp]"'; HintForce = 'uv tool install "graphifyy[mcp]" --force';
       InstallMissing = { Invoke-Installer "graphify" "uv" @("tool", "install", "graphifyy[mcp]") };
       InstallForce = { Invoke-Installer "graphify" "uv" @("tool", "install", "graphifyy[mcp]", "--force") } },
    # [021] tokenslayer: build/index.js del clon en el proyecto (bootstrap:
    # [021] 2992-3006 usa `npm --prefix <dir> install` + `run build`).
    @{ Key = "tokenslayer"; Env = "TOKENSLAYER_CMD";
       Detect = { $i = Join-Path $RootPath "proyect_ext/tokenslayer/mcp-server/build/index.js"; if (Test-Path -LiteralPath $i) { return @{ Path = $i; VerExe = ""; VerArgs = @() } }; return $null };
       HintMissing = "npm install + npm run build en proyect_ext/tokenslayer/mcp-server"; HintForce = "npm install + npm run build en proyect_ext/tokenslayer/mcp-server";
       InstallMissing = {
           $d = Join-Path $RootPath "proyect_ext/tokenslayer/mcp-server"
           if (-not (Test-Path -LiteralPath (Join-Path $d "package.json"))) { Write-Warn "mcp-install: tokenslayer sin clon en $d (lo trae upgrade_framework a proyect_ext/); build omitido."; return $false }
           $a = Invoke-Installer "tokenslayer" "npm" @("--prefix", $d, "install"); $b = Invoke-Installer "tokenslayer" "npm" @("--prefix", $d, "run", "build"); return ($a -and $b) };
       InstallForce = {
           $d = Join-Path $RootPath "proyect_ext/tokenslayer/mcp-server"
           if (-not (Test-Path -LiteralPath (Join-Path $d "package.json"))) { Write-Warn "mcp-install: tokenslayer sin clon en $d (lo trae upgrade_framework a proyect_ext/); build omitido."; return $false }
           $a = Invoke-Installer "tokenslayer" "npm" @("--prefix", $d, "install"); $b = Invoke-Installer "tokenslayer" "npm" @("--prefix", $d, "run", "build"); return ($a -and $b) } },
    # [021] github: exe en ~/.local/bin (release oficial github/github-mcp-server
    # [021] v2.0.2, asset Windows_x86_64.zip, SHA256 publicado; procedimiento en
    # [021] bitacora 2026-10-11-mcp-github.md). SIN URL inventada: si falta, el
    # [021] instalador es manual y se informa como WARN accionable.
    @{ Key = "github"; Env = "GITHUB_MCP_CMD";
       Detect = { $e = Join-Path $localBin "github-mcp-server.exe"; if (Test-Path -LiteralPath $e) { return @{ Path = $e; VerExe = $e; VerArgs = @() } }; $p = Resolve-OnPath "github-mcp-server"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "MANUAL: release github/github-mcp-server v2.0.2, asset Windows_x86_64.zip, verificar SHA256 publicado y extraer github-mcp-server.exe a ~/.local/bin (ver Documentacion/Agents_IA_TECH/bitacoras/2026-10-11-mcp-github.md)"; HintForce = "MANUAL: ver bitacora 2026-10-11-mcp-github.md (release v2.0.2, asset Windows_x86_64.zip, ~/.local/bin)";
       InstallMissing = { Write-Warn "mcp-install: github sin instalador automatico (binario de release con SHA256). MANUAL: release github/github-mcp-server v2.0.2, asset Windows_x86_64.zip, verificar SHA256 publicado y extraer github-mcp-server.exe a ~/.local/bin. Procedimiento exacto en Documentacion/Agents_IA_TECH/bitacoras/2026-10-11-mcp-github.md."; return $false };
       InstallForce = { Write-Warn "mcp-install: github sin instalador automatico (ver bitacora 2026-10-11-mcp-github.md: release v2.0.2, asset Windows_x86_64.zip, ~/.local/bin)."; return $false } },
    # [021] playwright: `@playwright/mcp` (bitacora mcp-playwright; en disco
    # [021] 0.0.83 + cli.js real). Browsers ms-playwright ya presentes.
    @{ Key = "playwright"; Env = "PLAYWRIGHT_MCP_CMD";
       Detect = { $c = Join-Path $npmRootG "@playwright/mcp/cli.js"; if (Test-Path -LiteralPath $c) { return @{ Path = $c; VerExe = "node"; VerArgs = @($c, "--version") } }; $p = Resolve-OnPath "playwright-mcp"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "npm install -g @playwright/mcp"; HintForce = "npm install -g @playwright/mcp@latest";
       InstallMissing = { Invoke-Installer "playwright" "npm" @("install", "-g", "@playwright/mcp") };
       InstallForce = { Invoke-Installer "playwright" "npm" @("install", "-g", "@playwright/mcp@latest") } },
    # [021] semgrep: CLI oficial via `uv tool install semgrep` (bitacora
    # [021] mcp-semgrep; en disco semgrep 1.180.0). Servidor = `semgrep mcp`
    # [021] (nunca se ejecuta aqui: levantaria stdio y colgaria la sonda).
    @{ Key = "semgrep"; Env = "SEMGREP_MCP_CMD";
       Detect = { $p = Resolve-OnPath "semgrep"; if ($p) { $r = Invoke-Probe -Exe $p -Arguments @("--version"); if ($r -and $r.Exit -eq 0) { return @{ Path = $p; VerExe = $p; VerArgs = @() } } }; return $null };
       HintMissing = "uv tool install semgrep (NO instalar semgrep-mcp: wrapper DEPRECADO por upstream)"; HintForce = "uv tool install semgrep --force (NO instalar semgrep-mcp: DEPRECADO)";
       InstallMissing = { Invoke-Installer "semgrep" "uv" @("tool", "install", "semgrep") };
       InstallForce = { Invoke-Installer "semgrep" "uv" @("tool", "install", "semgrep", "--force") } },
    # [021] context7: `@upstash/context7-mcp` (bitacora mcp-context7; en disco
    # [021] 4.3.0 + dist/index.js real).
    @{ Key = "context7"; Env = "CONTEXT7_CMD";
       Detect = { $c = Join-Path $npmRootG "@upstash/context7-mcp/dist/index.js"; if (Test-Path -LiteralPath $c) { return @{ Path = $c; VerExe = "node"; VerArgs = @($c, "--version") } }; $p = Resolve-OnPath "context7-mcp"; if ($p) { return @{ Path = $p; VerExe = $p; VerArgs = @() } }; return $null };
       HintMissing = "npm install -g @upstash/context7-mcp"; HintForce = "npm install -g @upstash/context7-mcp@latest";
       InstallMissing = { Invoke-Installer "context7" "npm" @("install", "-g", "@upstash/context7-mcp") };
       InstallForce = { Invoke-Installer "context7" "npm" @("install", "-g", "@upstash/context7-mcp@latest") } }
)

Write-Step "mcp-install: verificando/instalando MCPs de la maquina (RootPath=$RootPath)"

# [021] Rutas resueltas para .env.mcp (solo herramientas detectadas/verificadas).
$resolved = [ordered]@{}

foreach ($t in $tools) {
    try {
        $found = & $t.Detect
        if ($found -and -not $Force) {
            $ver = $null
            if ($t.Key -eq "tokenslayer") { $ver = "build/index.js presente" }
            elseif ($found.VerExe) { $ver = Get-ExeVersion -Exe $found.VerExe -FirstArgs $found.VerArgs -Strict:($found.VerExe -ne $found.Path) }
            if ($ver) { Write-OK "$($t.Key): detectado ($($found.Path)) [$ver]" }
            else { Write-OK "$($t.Key): detectado ($($found.Path)) [version no legible, binario presente]" }
            $resolved[$t.Env] = $found.Path
            Write-Host "RESULT:mcp-install:$($t.Key):ok"
            continue
        }
        if ($found -and $Force) {
            if ($DryRun) {
                Write-Info "DryRun: reinstalaria/actualizaria $($t.Key) con: $($t.HintForce) (sin ejecutar)"
                $resolved[$t.Env] = $found.Path
                Write-Host "RESULT:mcp-install:$($t.Key):sin-cambios"
                continue
            }
            Write-Step "mcp-install: -Force: reinstalando $($t.Key) ($($t.HintForce))"
            $okForce = & $t.InstallForce
            $found2 = & $t.Detect
            if ($okForce -and $found2) {
                $resolved[$t.Env] = $found2.Path
                Write-Host "RESULT:mcp-install:$($t.Key):instalado"
            } else {
                Write-Warn "mcp-install: $($t.Key) no quedo disponible tras -Force (ver WARN anterior)."
                if ($found2) { $resolved[$t.Env] = $found2.Path }
                Write-Host "RESULT:mcp-install:$($t.Key):ausente-warn"
            }
            continue
        }
        # [021] Ausente.
        if ($DryRun) {
            Write-Info "DryRun: instalaria $($t.Key) con: $($t.HintMissing) (sin ejecutar)"
            Write-Host "RESULT:mcp-install:$($t.Key):sin-cambios"
            continue
        }
        Write-Warn "mcp-install: $($t.Key) ausente; instalando ($($t.HintMissing))"
        $okInst = & $t.InstallMissing
        $found3 = & $t.Detect
        if ($okInst -and $found3) {
            $resolved[$t.Env] = $found3.Path
            Write-Host "RESULT:mcp-install:$($t.Key):instalado"
        } else {
            Write-Warn "mcp-install: $($t.Key) sigue ausente tras intentar instalar (accion: $($t.HintMissing))."
            Write-Host "RESULT:mcp-install:$($t.Key):ausente-warn"
        }
    } catch {
        # [021] Fail-open por herramienta: WARN + ausente-warn, sin abortar.
        Write-Warn "mcp-install: $($t.Key) fallo inesperado ($_); se continua con las demas."
        Write-Host "RESULT:mcp-install:$($t.Key):ausente-warn"
        continue
    }
}

# =============================================================================
# [021] Anotar rutas reales en <Root>/.env.mcp (append idempotente
# [021] NOMBRE_CMD=ruta; crea el archivo con header si falta). Cero escrituras
# [021] en -DryRun.
# =============================================================================
function Set-McpEnvEntry {
    param([string]$EnvPath, [string]$Key, [string]$Value)
    $lines = @()
    if (Test-Path -LiteralPath $EnvPath -PathType Leaf) {
        $lines = @(Get-Content -LiteralPath $EnvPath -Encoding UTF8)
    }
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ("(?m)^" + [regex]::Escape($Key) + "=.*$")) { $idx = $i; break }
    }
    if ($idx -ge 0) {
        if ($lines[$idx] -eq "$Key=$Value") { return $false }
        $lines[$idx] = "$Key=$Value"
    } else {
        $lines += "$Key=$Value"
    }
    # [021] Sin NL manual al final: Set-Content ya agrega el terminador; uno
    # [021] manual duplicaria el salto y Get-Content devolveria lineas vacias.
    $lines -join [Environment]::NewLine | Set-Content -LiteralPath $EnvPath -Encoding UTF8
    return $true
}

$envPath = Join-Path $RootPath ".env.mcp"
if ($DryRun) {
    Write-Info "DryRun: anotaria $($resolved.Count) rutas en $envPath (sin escribir)"
    foreach ($k in $resolved.Keys) { Write-Info "DryRun: .env.mcp: $k=$($resolved[$k])" }
    Write-Info "DryRun: aseguraria regla .env.mcp en .gitignore (sin escribir)"
} else {
    try {
        if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
            @("# [021][007-MCP] Rutas MCP resueltas por scripts/sync/mcp/install.ps1 (NO versionar; gitignored).",
              "# Una linea por herramienta: NOMBRE_CMD=ruta. Regenerable re-ejecutando mcp-install.") -join [Environment]::NewLine |
                Set-Content -LiteralPath $envPath -Encoding UTF8
            Write-OK ".env.mcp creado: $envPath"
        }
        $n = 0
        foreach ($k in $resolved.Keys) {
            if (Set-McpEnvEntry -EnvPath $envPath -Key $k -Value $resolved[$k]) { $n++ }
        }
        if ($n -gt 0) { Write-OK ".env.mcp actualizado con $n ruta(s): $envPath" }
        else { Write-Info ".env.mcp ya tenia las rutas resueltas (idempotente)." }
    } catch {
        Write-Warn "mcp-install: no se pudo anotar $envPath ($_); se continua."
    }
    # [021] Patron Add-McpEnvGitignore del bootstrap (bootstrap:517-537).
    try {
        $giPath = Join-Path $RootPath ".gitignore"
        $hasEntry = $false
        if (Test-Path -LiteralPath $giPath -PathType Leaf) {
            $giText = Get-Content -LiteralPath $giPath -Raw -ErrorAction Stop
            if ($giText -match '(?m)^\s*\.env\.mcp\s*$') { $hasEntry = $true }
        }
        if (-not $hasEntry) {
            $entry = [Environment]::NewLine + "# [007-MCP] rutas MCP locales (nunca versionar)" + [Environment]::NewLine + ".env.mcp" + [Environment]::NewLine
            Add-Content -LiteralPath $giPath -Value $entry -Encoding UTF8
            Write-OK ".env.mcp agregado a .gitignore"
        } else {
            Write-Info ".gitignore: regla .env.mcp ya presente (idempotente)."
        }
    } catch {
        Write-Warn "mcp-install: no se pudo asegurar .gitignore con '.env.mcp' ($_); se continua."
    }
}

Show-ExecutionSummary -Title "mcp-install"
