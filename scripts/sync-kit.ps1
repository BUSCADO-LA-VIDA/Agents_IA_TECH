#!/usr/bin/env powershell
#requires -Version 7.0
# scripts/sync-kit.ps1 — Orquestador estable del sync transversal.
# Este archivo es el orquestador principal que coordina todas las capas de sincronización.
# NUNCA contiene lógica de dominio; delega a scripts especializados por capa.
# =============================================================================
# sync-kit.ps1 — Orquestador estable del sync transversal
# =============================================================================
# Orquestador que coordina las capas de sincronización del kit transversal.
# Sincroniza: .github/, .opencode/, .doc_agents/, scripts/, constituciones,
# agentes, habilidades, extras de GitHub, tests y configuración MCP.
# NUNCA toca Documentacion/<AppName>/ (frontera kit <-> app, guardrail 1).
# =============================================================================

# --- Parámetros del script ---
[CmdletBinding()]
param(
    [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
    [string]$RootPath = "",
    [string]$KitPath = "",
    [string]$OrphanAction = "Preguntar",
    [switch]$DryRun,
    [switch]$Force,
    [string]$Only = "",
    [string]$Skip = "",
    [switch]$ListLayers,
    [int]$KeepBackups = 2,
    [switch]$NoPrune
)

# --- Capas del orquestador ---
# Cada capa define: Nombre, Script a invocar, acepta -Force, y si no requiere stage.
# Las capas nuevas reemplazan a las funciones de dominio antiguas.
$script:Layers = @(
    @{
        Name = "kit-files"
        Script = Join-Path $PSScriptRoot "sync/kit-files/sync-kit-files.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "agents-github"
        Script = Join-Path $PSScriptRoot "sync/agents/sync-agents-github.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "agents-opencode"
        Script = Join-Path $PSScriptRoot "sync/agents/sync-agents-opencode.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "agents-vscode"
        Script = Join-Path $PSScriptRoot "sync/agents/sync-agents-vscode.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "docs"
        Script = Join-Path $PSScriptRoot "sync/docs/sync-docs.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "constitutions"
        Script = Join-Path $PSScriptRoot "sync/constitutions/sync-constitutions.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "src-structure"
        Script = Join-Path $PSScriptRoot "sync/src-structure/sync-src-structure.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "mcp-install"
        Script = Join-Path $PSScriptRoot "sync/mcp/install.ps1"
        AcceptsForce = $true
        NoStage = $true
    }
    @{
        Name = "mcp-lift-opencode"
        Script = Join-Path $PSScriptRoot "sync/mcp/lift-opencode.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "mcp-lift-vscode"
        Script = Join-Path $PSScriptRoot "sync/mcp/lift-vscode.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "indexing"
        Script = Join-Path $PSScriptRoot "sync/indexing/run-indexing.ps1"
        AcceptsForce = $false
        NoStage = $true
    }
    @{
        Name = "externals"
        Script = Join-Path $PSScriptRoot "sync/externals/resolve-externals.ps1"
        AcceptsForce = $true
        NoStage = $true
    }
    @{
        Name = "skills"
        Script = Join-Path $PSScriptRoot "sync-skills.ps1"
        AcceptsForce = $true
        NoStage = $true
    }
    @{
        Name = "github-extras"
        Script = Join-Path $PSScriptRoot "sync-github-extras.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "tests-kit"
        Script = Join-Path $PSScriptRoot "sync-tests-kit.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "mcp-graphify"
        Script = Join-Path $PSScriptRoot "sync-mcp-graphify.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
    @{
        Name = "backup-prune"
        Script = Join-Path $PSScriptRoot "sync-backup-prune.ps1"
        AcceptsForce = $true
        NoStage = $false
    }
)

# --- Lógica de filtrado de capas por parámetros ---
# Manejo de -ListLayers: enumerar todas las capas y emitir resultado
if ($ListLayers) {
    [int]$count = 0
    foreach ($layer in $script:Layers) {
        Write-Host "NAME: $($layer.Name), SCRIPT: $($layer.Script)"
        $count = $count + 1
    }
    Write-Host "RESULT:layers:$($count):listado"
    return
}

# Manejo de -Only: solo ejecutar capas especificadas por nombre
if ($PSBoundParameters.ContainsKey('Only')) {
    $requested = $Only -split ',' | ForEach-Object { $_.Trim() }
    $originalCount = $script:Layers.Count
    $script:Layers = $script:Layers | Where-Object { $_.Name -in $requested }
    $removed = $originalCount - $script:Layers.Count
    $missing = @()
    foreach ($name in $requested) {
        if (-not ($script:Layers | Where-Object { $_.Name -eq $name })) {
            $missing += $name
        }
    }
    if ($removed -gt 0 -and $missing.Count -gt 0) {
        Write-Host "[WARN] Capa(s) no encontrada(s) en -Only: $($missing -join ', '). Se continuarán con las capas disponibles."
    } elseif ($removed -gt 0) {
        Write-Host "[OK] Capa(s) filtrada(s) por -Only: $removed"
    }
}

# Manejo de -Skip: excluir capas especificadas por nombre
if ($PSBoundParameters.ContainsKey('Skip')) {
    $excluded = $Skip -split ',' | ForEach-Object { $_.Trim() }
    $originalCount = $script:Layers.Count
    $script:Layers = $script:Layers | Where-Object { $excluded -notcontains $_.Name }
    $removed = $originalCount - $script:Layers.Count
    if ($removed -gt 0) {
        Write-Host "[OK] Capa(s) excluidas por -Skip: $removed"
    }
}

# --- Logging functions ---

function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor DarkYellow }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL]  $Message" -ForegroundColor Red }

function Show-ExecutionSummary {
    param([string]$Title = "RESUMEN DE EJECUCIÓN")
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host "$Title" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host " WARNs: $($uniqueWarns.Count)"
    foreach ($w in $uniqueWarns) { Write-Host "   - $w" }
    Write-Host " ERRORs: $($uniqueErrors.Count)"
    foreach ($e in $uniqueErrors) { Write-Host "   - $e" }
    Write-Host "===============================================================" -ForegroundColor Yellow
}

# --- Seguridad de RepoUrl (Defecto C, F1-STAGE) ---
# Fail-closed: solo https://github.com/<owner en allowlist>/<repo>. Definida localmente
# (misma semántica que plataformador-bootstrap.ps1) para que el orquestador valide
# la URL antes de clonar el maestro sin depender de otros scripts.
$script:TrustedOwners = @('BUSCADO-LA-VIDA')

function Test-TrustedGithubUrl {
    param([string]$Url)
    # Fail-closed hacia arriba: sin URL -> no permitida
    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    if ($Url -notmatch '^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$') {
        return $false
    }
    $owner = $matches[1]
    return $script:TrustedOwners -contains $owner
}

# --- Funciones auxiliares de invocación de capas ---
# Refactor [SC-002]: el orquestador invoca cada capa como proceso hijo vía
# cadena + Invoke-Expression. Estas helpers centralizan esa lógica para que
# las capas que requieren parámetros ad hoc (ej. github-extras con -Kind)
# reaprovechen el mismo patrón sin duplicar el try/catch de captura.

function WriteStep-Capa {
    param([string]$LayerName, [string]$Kind = "")
    if ($Kind) {
        Write-Step "Ejecutando capa: $LayerName (Kind=$Kind)"
    } else {
        Write-Step "Ejecutando capa: $LayerName"
    }
}

function Invoke-CapaHija {
    param($Layer, [string[]]$ArgList)
    if (-not (Test-Path -LiteralPath $Layer.Script -PathType Leaf)) {
        Write-Warn "Script de capa no encontrado: $($Layer.Script), se omite."
        return @()
    }
    $cmd = "& $($Layer.Script) $($ArgList -join ' ') *>&1"
    try {
        $output = Invoke-Expression -Command $cmd 2>&1
        if ($output) {
            return @($output)
        }
    } catch {
        Write-Warn "Capa $($Layer.Name) falló con error: $_"
        $script:Errors.Add("Capa $($Layer.Name) falló: $_") | Out-Null
    }
    return @()
}

# --- Función principal (punto de entrada) ---

function Main-sync-kit {
    param(
        [string]$RepoUrl = "https://github.com/BUSCADO-LA-VIDA/Agents_IA_TECH",
        [string]$RootPath = "",
        [string]$KitPath = "",
        [string]$OrphanAction = "Preguntar",
        [switch]$DryRun,
        [switch]$Force,
        [int]$KeepBackups = 2,
        [switch]$NoPrune
    )

    # a. Inicializa acumuladores
    $script:Warnings  = [System.Collections.Generic.List[string]]::new()
    $script:Errors    = [System.Collections.Generic.List[string]]::new()
    $script:EmittedWarns = [System.Collections.Generic.List[string]]::new()

    # b. Aplica valores por defecto de parámetros
    if (-not $RootPath) {
        $RootPath = (Split-Path -Parent $PSScriptRoot)
    }

    Write-Step "sync-kit: orquestando sincronización en $RootPath"

    # c. STAGE (F1): valida RootPath, resuelve stageKitRoot, asegura .gitignore, reporta capas activas
    if (-not (Test-Path -LiteralPath $RootPath)) {
        Write-Fail "RootPath no existe: $RootPath"
        return $false
    }

    # Asegurar .gitignore en el raíz
    # Regresión corregida (spec 036): el orquestador original sync-kit-agents.ps1 aseguraba
    # las reglas .kit-backup/ y .kit-sync-temp/ (append idempotente). El nuevo script solo
    # creaba .gitignore con "*.retry*" sin agregar esas reglas. Se restaura ese comportamiento.
    $gitignorePath = Join-Path $RootPath ".gitignore"
    $gitignoreRules = @(".kit-backup/", ".kit-sync-temp/")

    if (-not (Test-Path -LiteralPath $gitignorePath -PathType Leaf)) {
        "*.retry*" | Out-File -FilePath $gitignorePath -Encoding utf8 -Force
        Write-OK ".gitignore creado en raíz"
    }

    # Asegurar cada regla de forma idempotente (regex por línea, sin duplicar)
    $gitignoreContent = @()
    if (Test-Path -LiteralPath $gitignorePath -PathType Leaf) {
        $gitignoreContent = Get-Content -LiteralPath $gitignorePath -ErrorAction SilentlyContinue
    }

    foreach ($rule in $gitignoreRules) {
        # Escapar la regla para usarla como patrón regex de línea
        $escapedRule = [regex]::Escape($rule)
        $ruleFound = $false
        foreach ($line in $gitignoreContent) {
            if ($line -match "^$escapedRule\s*$") {
                $ruleFound = $true
                break
            }
        }

        if (-not $ruleFound) {
            if ($DryRun) {
                Write-Info "[DRY-RUN] Se agregaría la regla '$rule' al .gitignore del raíz ($gitignorePath)"
            } else {
                # Agregar la línea y actualizar el contenido en memoria
                Add-Content -LiteralPath $gitignorePath -Value $rule -Encoding utf8
                $gitignoreContent = Get-Content -LiteralPath $gitignorePath -ErrorAction SilentlyContinue
                Write-OK "Regla .gitignore asegurada: $rule"
            }
        }
    }

    # Reportar capas activas (que tienen su script disponible)
    $activeLayers = @()
    foreach ($layer in $script:Layers) {
        if (Test-Path -LiteralPath $layer.Script -PathType Leaf) {
            $activeLayers += $layer.Name
            Write-OK "Capa activa: $($layer.Name) -> $($layer.Script)"
        } else {
            Write-Warn "Capa no disponible: $($layer.Name) -> $($layer.Script) (se omite)"
        }
    }
    Write-OK "Total de capas: $($script:Layers.Count) ($($activeLayers.Count) disponibles)"

    # [SC-002-Defecto C - F1-STAGE] Preparar el StageDir con una copia REAL del repo
    # maestro antes de invocar las capas. Las capas con stage reciben este directorio;
    # si está vacío no pueden sincronizar. Se clona shallow el maestro a -RepoUrl,
    # o se usa el checkout local pasado por -KitPath (sin clonar ni borrar el del usuario).
    $tempDir = Join-Path $env:TEMP "agents-sync-temp"
    $stagePrepFailed = $false

    if ($KitPath) {
        # Fuente LOCAL: usar el checkout del propio maestro como stage. NO se clona,
        # NO se borra el checkout local del usuario (guardrail en la limpieza).
        Write-Info "Sync-kit: StageDir = checkout local del maestro (-KitPath): $KitPath"
        if (-not (Test-Path -LiteralPath $KitPath -PathType Container)) {
            Write-Fail "-KitPath no existe o no es un directorio: $KitPath"
            $stagePrepFailed = $true
        } else {
            $tempDir = $KitPath
        }
    } else {
        # Fuente REMOTA: validar $RepoUrl contra allowlist (fail-closed) y clonar shallow.
        # Seguridad [SC-002]: solo https://github.com/ (Test-TrustedGithubUrl si existe
        # en el contexto; como mínimo se exige el prefijo https://github.com/).
        if (-not (Test-TrustedGithubUrl $RepoUrl)) {
            Write-Fail "[SECURITY] RepoUrl no permitida (fail-closed): $RepoUrl (solo https://github.com/<owner en allowlist>/<repo>)"
            $script:Errors.Add("RepoUrl no permitida: $RepoUrl") | Out-Null
            $stagePrepFailed = $true
        } elseif ($DryRun -and (-not $RepoUrl)) {
            Write-Info "[DRY-RUN] Sin RepoUrl y sin KitPath: no hay stage real; se continúa."
        } elseif (-not $DryRun) {
            Write-Info "Sync-kit: clonando shallow del repo maestro desde $RepoUrl a $tempDir"
            if (Test-Path -LiteralPath $tempDir) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            try {
                $cloneOutput = git clone --depth 1 $RepoUrl $tempDir 2>&1
                if ($LASTEXITCODE -ne 0 -and (Test-Path -LiteralPath $tempDir)) {
                    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Fail "Fallo el clon del repo maestro: $_"
                $script:Errors.Add("Fallo el clon del repo maestro: $_") | Out-Null
                $stagePrepFailed = $true
            }
        } else {
            # DryRun sin KitPath: no clonar, solo reportar el plan.
            Write-Info "[DRY-RUN] No se clona el maestro en dry-run (StageDir se deja vacío)."
        }
    }

    if ($stagePrepFailed) {
        Write-Fail "STAGE (F1) no completado; se aborta la sincronización."
        return $false
    }

    # d. Invoca cada capa activa como proceso hijo
    $resultLines = @()

    # [036-T003-D1] Snapshoteo del conjunto inicial de .kit-backup/ ANTES de invocar
    # las capas (las capas crean backups durante la corrida). Este snapshot es la
    # fuente de verdad que le permite a backup-prune distinguir backups pre-existentes
    # (del llamador) de los generados por esta corrida, y podar solo estos últimos.
    $initialBackupFile = Join-Path $env:TEMP ("agents-sync-initial-backups-{0}.txt" -f ([guid]::NewGuid().ToString("N")))
    $backupRootForSnapshot = Join-Path $RootPath ".kit-backup"
    $initialFolders = @()
    if (Test-Path -Path $backupRootForSnapshot) {
        $initialFolders = @(Get-ChildItem -Path $backupRootForSnapshot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    }
    Set-Content -LiteralPath $initialBackupFile -Value $initialFolders -Encoding utf8
    Write-Info "Snapshot inicial de .kit-backup/ (pre-capa): $($initialFolders.Count) carpeta(s)"

    foreach ($layer in $script:Layers) {
        if (-not (Test-Path -LiteralPath $layer.Script -PathType Leaf)) {
            Write-Warn "Script de capa no encontrado: $($layer.Script), se omite."
            continue
        }

        Write-Step "Ejecutando capa: $($layer.Name)"

        # Construir argumentos comunes.
        # Los switches (-DryRun, -Force) se agregan SOLO cuando estan activos:
        # el orquestador invoca via cadena + Invoke-Expression, y pasar un valor
        # booleano suelto ("True"/"False") a un switch provoca errores de binding
        # posicional (mismo criterio documentado para backup-prune abajo).
        $args = @()
        if ($layer.NoStage) {
            # Capas sin stage: solo pasan root
            $args = @("-RootPath", $RootPath)
        } else {
            # Capas con stage
            if (-not (Test-Path -PathType Leaf $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
            $args = @("-StageDir", $tempDir, "-RootPath", $RootPath)
        }
        if ($DryRun) { $args += "-DryRun" }
        if ($Force) { $args += "-Force" }

        # Propagar a la capa backup-prune (FR-002, FR-003): usa su PROPIO conjunto
        # de argumentos, sin -StageDir ni -Force (la capa no los acepta), con
        # -KeepBackups, -NoPrune y el snapshot inicial del conjunto de .kit-backup/.
        # Los switches (-DryRun, -NoPrune) se agregan SOLO cuando estan activos:
        # el orquestador invoca via cadena + Invoke-Expression, y pasar un valor
        # booleano suelto a un switch provoca errores de binding posicional.
        if ($layer.Name -eq "backup-prune") {
            $args = @("-RootPath", $RootPath)
            if ($DryRun) { $args += "-DryRun" }
            $args += @("-KeepBackups", "$KeepBackups")
            if ($NoPrune) { $args += "-NoPrune" }
            $args += @("-InitialStateFile", $initialBackupFile)
        }

        # [SC-002-Defecto B] La capa github-extras (sync-github-extras.ps1) exige el
        # parámetro obligatorio -Kind (ValidateSet rules|prompts|workflows|copilot).
        # "todo" no es un valor válido, así que se invoca UNA VEZ POR CADA kind,
        # recolectando la salida de cada invocación.
        if ($layer.Name -eq "github-extras") {
            foreach ($kind in @('rules','prompts','workflows','copilot')) {
                WriteStep-Capa -LayerName $layer.Name -Kind $kind
                $kindArgs = $args + @("-Kind", $kind)
                $resultLines += @(Invoke-CapaHija -Layer $layer -ArgList $kindArgs)
            }
            continue
        }

        # Ejecutar el script de la capa como proceso hijo y capturar salida
        $resultLines += @(Invoke-CapaHija -Layer $layer -ArgList $args)
    }

    # e. Ejecuta Show-ExecutionSummary mostrando WARNs y ERRORs contados
    Show-ExecutionSummary -Title "RESUMEN DE LA EJECUCIÓN (sync-kit orchestador)"

    # [036-T003-D1] Superficie la salida recolectada de las capas hijo (FR-016).
    # Incluye las lineas de registro de poda de backup-prune (ruta, tamaño y regla)
    # y los RESULT:<capa>:<estado>, para que los borrados queden reflejados en el
    # resumen de ejecución final del orquestador.
    if ($resultLines.Count -gt 0) {
        Write-Host ""
        Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host " SALIDA DE LAS CAPAS ($($resultLines.Count) líneas)" -ForegroundColor Yellow
        Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
        foreach ($line in $resultLines) {
            Write-Host $line
        }
    }

    # Entrada de resumen: sync-kit-absorbido
    Write-Host "sync-kit-agents.ps1: módulo absorbido por sync-kit.ps1 (ya no es entry point independiente)"

    # Contar y mostrar resumen
    $uniqueWarns = @($script:Warnings | Select-Object -Unique)
    $uniqueErrors = @($script:Errors | Select-Object -Unique)
    Write-Host "---------------------------------------------------------------"
    Write-Host " WARNs emitidos: $($uniqueWarns.Count) | ERRORs capturados: $($uniqueErrors.Count)"

    # [SC-002-Defecto C - F4-VERIFY] Escribir manifiesto .kit-last-sync.json en el
    # root del destino (si no es dry-run) con el resumen de la corrida: herramienta,
    # commit del maestro, fecha, capas activas y líneas RESULT de las capas.
    if (-not $DryRun) {
        try {
            $commit = ""
            if ($tempDir -and (Test-Path -LiteralPath $tempDir)) {
                $commitLine = git -C $tempDir rev-parse --short HEAD 2>$null
                if ($commitLine) {
                    $commit = (($commitLine | Select-Object -First 1) | Out-String).Trim()
                }
            }
            if (-not $commit) { $commit = "desconocido" }
            $manifest = [ordered]@{
                tool    = "sync-kit"
                commit  = $commit
                date    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                KitPath = if ($KitPath) { [IO.Path]::GetFullPath($KitPath) } else { "" }
                layers  = @($activeLayers)
                results = @($resultLines)
            }
            $manifestPath = Join-Path $RootPath ".kit-last-sync.json"
            $manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $manifestPath -Encoding utf8 -Force
            Write-OK "Manifiesto escrito: $manifestPath"
        } catch {
            Write-Warn "No se pudo escribir .kit-last-sync.json: $_"
        }
    }

    # f. Limpieza básica del temp
    # Guardrail [SC-002]: si se usó -KitPath, $tempDir apunta al checkout LOCAL del
    # usuario (maestro) y NO debe borrarse. Solo se limpia el clon temporal.
    if (-not $KitPath -and (Test-Path $tempDir)) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($initialBackupFile -and (Test-Path -LiteralPath $initialBackupFile)) {
        Remove-Item -LiteralPath $initialBackupFile -Force -ErrorAction SilentlyContinue
    }

    return $true
}

# Ejecutar la función principal y salir con código de salida 0
Main-sync-kit -RepoUrl $RepoUrl -RootPath $RootPath -KitPath $KitPath -OrphanAction $OrphanAction -DryRun:$DryRun -Force:$Force -KeepBackups $KeepBackups -NoPrune:$NoPrune
exit 0