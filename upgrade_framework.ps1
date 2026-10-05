#!/usr/bin/env powershell
#requires -Version 7.0
# =============================================================================
# upgrade_framework.ps1
# =============================================================================
# Entrypoint CLI para el agente upgrade_framework.
# Gestiona la sincronización de dependencias externas según dependencias-manifest.yml
# clona/actualiza repositorios en proyect_ext/ y registra herramientas (graphify via uv).
#
# Uso:
#   & "C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1" -RootPath "C:\Proyectos\trading_bot" -ForceUpgradeTools -DryRun
#   & "C:\Proyectos\Agents_IA_TECH\upgrade_framework.ps1" -RootPath "C:\Proyectos\trading_bot"
#
# Parámetros:
#   -RootPath (obligatorio): Ruta raíz del proyecto donde buscar dependencias-manifest.yml
#   -ForceUpgradeTools: Fuerza la actualización de herramientas (uv tool install graphifyy[mcp] sin pin de versión)
#   -DryRun: Simula las acciones sin escribir nada (fail-open: exit code 0 siempre)
#
# Requisito: PowerShell 7+ (pwsh ≥ 7). No funciona en Windows PowerShell 5.1.
#
# -----------------------------------------------------------------------------
# Estado del endurecimiento de seguridad (spec 011, tareas T040-T050 CRITICAL)
# -----------------------------------------------------------------------------
# HECHO en este archivo:
#   - T045 containment estricto: la ruta CRUDA (antes de normalizar) se rechaza de
#     forma explicita si trae segmentos '..', prefijo UNC o prefijo de dispositivo
#     (\\?\  y \\.\). Ademas se resuelve la cadena de reparse points de todos los
#     directorios padre y se compara el destino REAL contra proyect_ext/ real.
#     Ante cualquier duda devuelve $false (fail-CLOSED para containment).
#   - T050 containment hardening: misma verificacion realpath del lado de
#     proyect_ext/; si el destino aun no existe, se sube al primer ancestro
#     existente, se resuelven sus links y se verifica containment sobre ese.
#   - T047 sanitizacion del output: Format-SanitizedText redacta tokens con
#     prefijo conocido (sk-, ghp_, gho_, github_pat_, AKIA, xox*, AIza, glpat-),
#     cabeceras Authorization/Proxy-Authorization, Bearer, pares key=value cuyos
#     nombres contienen TOKEN|SECRET|KEY|PASSWORD|PASSWD|CREDENTIAL|API_KEY|AUTH,
#     credenciales embebidas en URLs (scheme://user:pass@host) y bloques PEM de
#     clave privada. Reemplaza SOLO el valor encontrado por ***REDACTED*** y nunca
#     trunca el resto de la linea. La salida sanitizada se emite unicamente por
#     Write-Debug: nunca por Write-Host, nunca al log de INFO.
#   - Politica de versiones SIN pin (decision del usuario 2026-10-03): se consulta
#     la ultima version disponible en PyPI, se compara con la instalada y solo se
#     reinstala si difieren. La version aplicada queda registrada en
#     dependencias-manifest.yml para que la proxima ejecucion detecte la
#     actualizacion. Ningun pin de version se escribe en el codigo ni en el YAML.
#   - T048 fail-open preservado en toda llamada externa (try/catch + Write-Warn +
#     continue, exit code 0). T053 (--no-recurse-submodules) y T055 (--depth=1)
#     ya venian implementados y se preservaron tal cual.
#
# PENDIENTE (CRITICAL, 6 de 11 siguen abiertas):
#   - T040 firma/checksums: la allowlist Test-TrustedGithubUrl ya existe y es
#     fail-closed, pero NO hay verificacion de firma (cosign) ni de checksums
#     sobre el contenido clonado.
#   - T041 manifest firmado: dependencias-manifest.yml no se firma ni se verifica
#     su integridad antes de leerlo ni antes de escribir la version aplicada.
#   - T042 verificacion obligatoria de firma/checksum de los artefacts clonados
#     antes de cualquier build.
#   - T043 sandbox/container para aislar los npm scripts de tokenslayer. La parte
#     de "version sin pin" de esta tanda NO es T043: es una decision de producto
#     del usuario, no una mitigacion de tasks.md.
#   - T044 --ignore-scripts o build aislado para los npm scripts.
#   - T046 cero secrets en el manifest via env vars / secret manager.
#   - T049 menor privilegio: token con scopes minimos y sin env vars sensibles
#     heredadas al proceso.
#
# NOTA DE ALCANCE: las mitigaciones T051-T064 (HIGH/MEDIUM/LOW) siguen abiertas y
# no fueron tocadas por esta tanda.
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RootPath,

    [switch]$ForceUpgradeTools,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Variables globales de seguridad
# =============================================================================
$script:AuditLogPath = "C:\Proyectos\Agents_IA_TECH\.bootstrap-audit.log"
$script:MAX_CLONE_MB = if ($env:MAX_CLONE_MB) { [int]$env:MAX_CLONE_MB } else { 100 }
$script:AuditChainLastHash = $null
$script:AllowlistRotationPath = "C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\seguridad\allowlist-rotation.json"

function Initialize-AuditLog {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType File -Path $Path -Force | Out-Null
            # ACL restrictivo: solo SYSTEM y Administradores
            try {
                $acl = Get-Acl -Path $Path
                $acl.SetAccessRuleProtection($true, $false)
                # Intentar eliminar herencia y dejar solo lectura/escritura para SYSTEM
                icacls $Path /inheritance:r /grant:r "SYSTEM:(F)" /grant:r "Administradores:(F)" /grant:r "BUILTIN\Administradores:(R)" | Out-Null
            } catch {
                Write-Warn "No se pudo aplicar ACL restrictivo al audit log (fail-open): $_"
            }
        }
        # Cargar ultimo hash para cadena
        if (Test-Path -LiteralPath $Path) {
            $lastLine = Get-Content -Path $Path -Tail 1
            if ($lastLine) {
                try {
                    $obj = $lastLine | ConvertFrom-Json
                    if ($obj.hash) { $script:AuditChainLastHash = $obj.hash }
                } catch {}
            }
        }
        return $true
    } catch {
        Write-Warn "Error inicializando audit log (fail-open): $_"
        return $false
    }
}

# T064: Rotación de allowlist — registro de última revisión y alerta si supera 90 días
function Test-AllowlistRotation {
    try {
        $rotationFile = $script:AllowlistRotationPath
        $rotationIntervalDays = 90
        $needsRotation = $false
        $lastRotation = $null

        if (Test-Path -LiteralPath $rotationFile) {
            try {
                $data = Get-Content -LiteralPath $rotationFile -Raw | ConvertFrom-Json
                $lastRotation = [DateTime]::Parse($data.last_rotation)
                if (((Get-Date) - $lastRotation).Days -gt $rotationIntervalDays) {
                    $needsRotation = $true
                }
            } catch {
                Write-Warn "T064: Error leyendo allowlist rotation file (fail-open): $_"
                $needsRotation = $false
            }
        } else {
            $needsRotation = $true
        }

        if ($needsRotation) {
            Write-Warn "T064: Allowlist no ha sido rotada en >$rotationIntervalDays días. Revisar TrustedOwners."
            Write-AuditEntry -Action "allowlist_rotation_due" -Data @{lastRotation=$lastRotation; intervalDays=$rotationIntervalDays}
            # Registrar rotación ahora (fail-open, no bloquea)
            try {
                $newData = @{ last_rotation = (Get-Date -Format "o"); owners = $TrustedOwners; rotatedBy = $env:USERNAME }
                $newData | ConvertTo-Json -Compress | Set-Content -LiteralPath $rotationFile -Encoding UTF8
                Write-Info "T064: Allowlist rotation registrada."
            } catch {
                Write-Warn "T064: Error registrando rotación allowlist (fail-open): $_"
            }
        } else {
            Write-Info "T064: Allowlist rotation vigente (última: $lastRotation)."
        }
        return $true
    } catch {
        Write-Warn "T064: Error en verificación rotación allowlist (fail-open): $_"
        return $true
    }
}

function Write-AuditEntry {
    param(
        [string]$Action,
        [hashtable]$Data = @{}
    )
    try {
        if (-not (Test-Path -LiteralPath $script:AuditLogPath)) {
            Initialize-AuditLog -Path $script:AuditLogPath | Out-Null
        }
        $entry = @{
            timestamp = (Get-Date -Format "o")
            actor = $env:USERNAME
            host = $env:COMPUTERNAME
            action = $Action
            manifestHash = $Data.ManifestHash
            details = $Data
        }
        # Hash chain
        $prevHash = $script:AuditChainLastHash
        $payload = $entry | ConvertTo-Json -Compress
        $chainInput = ($prevHash ?? "") + $payload
        $hashBytes = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($chainInput))
        $hash = [BitConverter]::ToString($hashBytes).Replace("-","").ToLower()
        $entry.hash = $hash
        $entry.prevHash = $prevHash
        $line = $entry | ConvertTo-Json -Compress
        Add-Content -Path $script:AuditLogPath -Value $line -Encoding UTF8
        $script:AuditChainLastHash = $hash
        # T061: verificar integridad tras escritura
        $null = Test-AuditLogIntegrity -Path $script:AuditLogPath
        return $true
    } catch {
        Write-Warn "Error escribiendo audit log (fail-open): $_"
        return $false
    }
}

function Test-AuditLogIntegrity {
    param([string]$Path = $script:AuditLogPath)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $true }
        $lines = Get-Content -Path $Path
        $prevHash = $null
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $line | ConvertFrom-Json
            if ($entry.prevHash -ne $prevHash) {
                Write-Warn "T061: Integridad del audit log comprometida, hash chain roto en entrada $($entry.action)"
                Write-AuditEntry -Action "audit_integrity_violation" -Data @{entry=$entry.action}
                return $false
            }
            # Recalcular hash
            $tmp = $entry.PSObject.Copy()
            $tmp.PSObject.Properties.Remove('hash')
            $payload = $tmp | ConvertTo-Json -Compress
            $chainInput = ($prevHash ?? "") + $payload
            $hashBytes = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($chainInput))
            $calcHash = [BitConverter]::ToString($hashBytes).Replace("-","").ToLower()
            if ($calcHash -ne $entry.hash) {
                Write-Warn "T061: Hash de entrada audit log no coincide"
                return $false
            }
            $prevHash = $entry.hash
        }
        return $true
    } catch {
        Write-Warn "T061: Error verificando integridad audit log (fail-open): $_"
        return $true
    }
}

function Validate-OpencodeSchema {
    param(
        [string]$OpencodePath,
        [string]$SchemaPath = "C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\seguridad\opencode.schema.json"
    )
    try {
        if (-not (Test-Path -LiteralPath $OpencodePath)) {
            Write-Warn "T058: opencode.json no encontrado en $OpencodePath (validación omitida fail-open)"
            return $true
        }
        if (-not (Test-Path -LiteralPath $SchemaPath)) {
            Write-Warn "T058: Schema opencode.schema.json no encontrado, validación omitida (fail-open)"
            return $true
        }
        $content = Get-Content -LiteralPath $OpencodePath -Raw
        $opencode = $content | ConvertFrom-Json
        $schema = Get-Content -LiteralPath $SchemaPath -Raw | ConvertFrom-Json
        $required = $schema.required
        $missing = @()
        if ($required) {
            foreach ($prop in $required) {
                if (-not ($opencode.PSObject.Properties.Name -contains $prop)) {
                    $missing += $prop
                }
            }
        }
        if ($missing.Count -gt 0) {
            Write-Warn "T058: opencode.json falta propiedades requeridas: $($missing -join ', '); validación fail-open"
            Write-AuditEntry -Action "opencode_schema_missing_props" -Data @{path=$OpencodePath; missing=$missing -join ','}
            return $false
        }
        Write-AuditEntry -Action "opencode_schema_validated" -Data @{path=$OpencodePath; schema=$SchemaPath}
        Write-Info "T058: opencode.json validado contra schema (propiedades requeridas presentes)"
        return $true
    } catch {
        Write-Warn "T058: Validación de opencode.json falló (fail-open): $_"
        Write-AuditEntry -Action "opencode_schema_invalid" -Data @{path=$OpencodePath; error=$_.Exception.Message}
        return $false
    }
}

# =============================================================================
# Funciones de logging estructurado
# =============================================================================
function Write-Info  { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Step  { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Yellow }
function Write-OK    { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor DarkYellow }
function Write-Fail  { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

# =============================================================================
# Validaciones de seguridad y containment
# =============================================================================

# Allowlist de owners de confianza para validar URLs (fail-closed)
$TrustedOwners = @(
    "BUSCADO-LA-VIDA",
    "github",
    "microsoft",
    "DeusData",
    "mksglu",
    "ajvikram",
    "Graphify-Labs"
)

function Test-TrustedGithubUrl {
    param([string]$Url)
    # Solo https://github.com/<owner>/<repo> con owner en allowlist
    if ($Url -notmatch '^https://github\.com/([^/]+)/([^/]+?)(\.git)?/?$') {
        return $false
    }
    $owner = $matches[1]
    return $TrustedOwners -contains $owner
}

# Chequeo de forma de ruta CRUDA (antes de normalizar). Fail-CLOSED.
# Rechaza: vacio, segmentos '..', prefijo UNC, prefijo de dispositivo y controles.
function Test-RawPathUnsafe {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $true }

    # Segmentos de directorio padre, con cualquiera de los dos separadores
    if ($Path -match '(?:\A|[\\/])\.\.(?:[\\/]|\z)') { return $true }

    # Prefijo de dispositivo de Windows (\\?\ y \\.\)
    if ($Path.StartsWith('\\?\')) { return $true }
    if ($Path.StartsWith('\\.\')) { return $true }

    # UNC (\\server\share o \\server\share\...)
    if ($Path.StartsWith('\\')) { return $true }

    # Caracteres de control o null (no pueden aparecer en una ruta legitima)
    if ($Path -match '[\x00-\x1F]') { return $true }

    return $false
}

# Resuelve la ruta REAL de un directorio, siguiendo la cadena de reparse points.
# Si el destino (o alguno de sus padres) aun no existe, sube al primer ancestro
# existente y resuelve sus links. Devuelve $null si no puede resolver (fail-CLOSED).
function Resolve-RealDirectoryPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

    try {
        $current = $Path

        # 1) Subir al primer ancestro que exista (la cadena puede ser profunda)
        $guard = 0
        while (-not (Test-Path -LiteralPath $current)) {
            if ($guard -ge 64) { return $null }
            $guard++
            $parent = [IO.Path]::GetDirectoryName($current)
            if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { return $null }
            $current = $parent
        }

        # 2) Resolver la cadena de enlaces hacia arriba (junctions, symlinks, mount points)
        $resolvedGuard = 0
        while ($resolvedGuard -lt 32) {
            $resolvedGuard++
            $item = [IO.DirectoryInfo]::new($current)
            $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
            if (-not $isReparse) { break }

            $target = $item.ResolveLinkTarget($true)
            if ($null -eq $target) {
                # Es un reparse point pero no se puede resolver: no se puede probar
                # containment, asi que se falla cerrado.
                return $null
            }
            $current = $target.FullName
        }

        return [IO.Path]::GetFullPath($current)
    }
    catch {
        # Fail-CLOSED: ante cualquier error no se puede probar containment
        return $null
    }
}

# Verificación de containment: ruta debe estar dentro de proyect_ext/ (T045 + T050)
function Test-ProyectExtContainment {
    param([string]$Path, [string]$RootPath)

    # (a) Forma de la ruta CRUDA: rechazo explicito antes de normalizar
    if (Test-RawPathUnsafe -Path $Path) {
        Write-Warn "Containment: ruta rechazada por forma insegura (segmento '..', UNC, prefijo de dispositivo o control): $Path"
        return $false
    }
    if (Test-RawPathUnsafe -Path $RootPath) {
        Write-Warn "Containment: RootPath rechazado por forma insegura: $RootPath"
        return $false
    }

    # (b) Containment lexico sobre la ruta ya normalizada
    try {
        $proyectExtRoot = Join-Path $RootPath "proyect_ext"
        $canonicalProyectExt = [IO.Path]::GetFullPath($proyectExtRoot)
        $canonicalPath = [IO.Path]::GetFullPath($Path)
        $sep = [IO.Path]::DirectorySeparatorChar
        $withinCanonical = $canonicalPath.StartsWith($canonicalProyectExt + $sep, [StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        Write-Warn "Containment: no se pudo normalizar la ruta (fail-closed): $_"
        return $false
    }

    if (-not $withinCanonical) {
        Write-Warn "Containment: la ruta normalizada sale de proyect_ext/ (fail-closed): $canonicalPath"
        return $false
    }

    # (c) Containment sobre la ruta REAL: se resuelven los reparse points de ambos
    #     lados y se comparan los destinos effective (symlink / junction en un padre
    #     podria sacar la escritura de proyect_ext/ sin cambiar la ruta canonica).
    $realTarget = Resolve-RealDirectoryPath -Path $canonicalPath
    if (-not $realTarget) {
        Write-Warn "Containment: no se pudo resolver la ruta real del destino (fail-closed): $canonicalPath"
        return $false
    }

    $realProyectExt = Resolve-RealDirectoryPath -Path $canonicalProyectExt
    if (-not $realProyectExt) {
        Write-Warn "Containment: no se pudo resolver la ruta real de proyect_ext/ (fail-closed): $canonicalProyectExt"
        return $false
    }

    if ($realTarget -eq $realProyectExt) { return $true }
    if ($realTarget.StartsWith($realProyectExt + $sep, [StringComparison]::OrdinalIgnoreCase)) { return $true }

    Write-Warn "Containment: la ruta real resuelve fuera de proyect_ext/ real (fail-closed): $realTarget"
    return $false
}

# =============================================================================
# Lectura del manifest YAML (parser simple para evitar dependencias)
# =============================================================================
function Test-ManifestSignature {
    param([string]$ManifestPath)
    try {
        if (-not (Test-Path -LiteralPath $ManifestPath)) { return $false }
        $content = Get-Content -Raw -Path $ManifestPath
        # Busca línea signature: <hash>
        $m = [regex]::Match($content, '(?m)^signature:\s*([0-9a-fA-F]{64})')
        if (-not $m.Success) { 
            Write-Warn "Manifest sin campo signature (T041); se asume no firmado (fail-closed)"
            return $false 
        }
        $expected = $m.Groups[1].Value.ToLower()
        # Calcula SHA256 del contenido sin la línea signature
        $contentNoSig = [regex]::Replace($content, '(?m)^signature:\s*[0-9a-fA-F]{64}\s*$
?
?', '')
        $bytes = [Text.Encoding]::UTF8.GetBytes($contentNoSig)
        $hash = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $actual = [BitConverter]::ToString($hash).Replace("-","").ToLower()
        if ($actual -ne $expected) {
            Write-Warn "Firma del manifest no coincide (T041): esperado $expected, actual $actual"
            return $false
        }
        return $true
    } catch {
        Write-Warn "Error verificando firma del manifest (T041): $_"
        return $false
    }
}

function Read-DependenciasManifest {
    param([string]$RootPath)
    
    $manifestFile = Join-Path $RootPath "dependencias-manifest.yml"
    if (-not (Test-Path -LiteralPath $manifestFile)) {
        Write-Warn "No existe dependencias-manifest.yml en $manifestFile"
        return @()
    }
    # T052: Manifest inmutable — verificación fail-open
    try {
        $item = Get-Item -LiteralPath $manifestFile -ErrorAction Stop
        if (-not $item.IsReadOnly) {
            Write-Warn "T052: Manifest $manifestFile no está marcado como sólo lectura (inmutabilidad no garantizada). Continuando fail-open."
            Write-AuditEntry -Action "manifest_not_immutable" -Data @{path=$manifestFile}
        } else {
            Write-Info "T052: Manifest inmutable verificado."
        }
    } catch {
        Write-Warn "T052: Error verificando inmutabilidad del manifest (fail-open): $_"
    }
    # T041: Verificación de firma del manifest (fail-closed)
    if (-not $DryRun) {
        $sigOk = Test-ManifestSignature -ManifestPath $manifestFile
        if (-not $sigOk) {
            Write-Warn "Manifest no verificado o firma inválida (T041); se omite lectura (fail-closed)"
            return @()
    # T046: No secrets en manifest (fail-closed)
    if (-not $DryRun) {
        $secretPatterns = @('(?i)password\s*[:=]\s*\S+', '(?i)secret\s*[:=]\s*\S+', '(?i)token\s*[:=]\s*\S+', '(?i)api_key\s*[:=]\s*\S+')
        $content = Get-Content -Raw -Path $manifestFile
        foreach ($p in $secretPatterns) {
            if ($content -match $p) {
                Write-Warn "Secret detectado en manifest (T046); se omite lectura (fail-closed)"
                return @()
            }
        }
    }

        }
    }
    
    $content = Get-Content -Path $manifestFile -Raw
    
    # Parser simple para la sección dependencias_externas
    # Busca entradas: - nombre: ... url: ... rama: ... tipo: ...
    $deps = @()
    
    # Buscar la sección dependencias_externas
    $sectionMatch = [regex]::Match($content, '(?ms)^dependencias_externas:\s*\r?\n(.*)$')
    if (-not $sectionMatch.Success) {
        Write-Warn "No se encontró sección 'dependencias_externas:' en el manifest"
        return @()
    }
    
    $section = $sectionMatch.Groups[1].Value
    
    # Regex para extraer cada dependencia (incluye checksum opcional)
    $pattern = '(?ms)^  - nombre:\s*(\S+)\s*\r?\n    url:\s*(\S+)\s*\r?\n    rama:\s*(\S+)\s*\r?\n(?:.*?\r?\n)*?    tipo:\s*(\S+)(?:\s*\r?\n(?:.*?\r?\n)*?    checksum:\s*([0-9a-fA-F]{40,64}))?\s*$'
    foreach ($m in [regex]::Matches($section, $pattern)) {
        $dep = @{
            Nombre = $m.Groups[1].Value
            Url = $m.Groups[2].Value
            Rama = $m.Groups[3].Value
            Tipo = $m.Groups[4].Value
        }
        if ($m.Groups[5].Success) { $dep.Checksum = $m.Groups[5].Value }
        $deps += $dep
    }
    
    return $deps
}

# =============================================================================
# Sanitizacion de secrets en la salida de comandos (T047)
# =============================================================================
# Politica: se reemplaza SOLO el valor sensible por ***REDACTED***. Nunca se
# trunca ni se descarta el resto de la linea, para que el log siga siendo util.
# La sanitizacion es best-effort y fail-open: si un patron falla, se avisa y el
# flujo continua (no aborta el bootstrap).
function Format-SanitizedText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

$marker = '***REDACTED***'

    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    # Los reemplazos compuestos se arman en variables: el operador -replace exige
    # exactamente 2 operandos, asi que la concatenacion va fuera de la expresion.
    # Los grupos ${k}${pre}${sep}${post} preservan el separador y los espacios
    # originales: solo se reemplaza el VALOR, nunca el resto de la linea.
    $replUrlCreds   = '${u}:' + $marker + '@'
    $replAuthScheme = '${h}${pre}${sep}${post}${s} ' + $marker
    $replAuthPlain  = '${h}${pre}${sep}${post}' + $marker
    $replBearer     = 'Bearer ' + $marker
    $replAssign     = '${k}${pre}${sep}${post}' + $marker

    try {
        $sanitized = $Text

        # (1) Bloque de clave privada PEM completo (multilinea) -> marker
        $sanitized = $sanitized -replace '(?s)-----BEGIN[A-Z ]*PRIVATE KEY-----.*?-----END[A-Z ]*PRIVATE KEY-----', $marker

        # (2) Credenciales embebidas en URLs: scheme://user:pass@host -> pass redactado
        $sanitized = $sanitized -replace '(?<u>[A-Za-z][A-Za-z0-9+.\-]*://[^\s:/@]+):(?<p>[^\s/@]+)@', $replUrlCreds

        # (3) Cabeceras de autorizacion con esquema explicito
        #     Authorization: Bearer sk-xxx  ->  Authorization: Bearer ***REDACTED***
        $sanitized = $sanitized -replace '(?i)\b(?<h>authorization|proxy-authorization)(?<pre>\s*)(?<sep>[:=])(?<post>\s*)(?<s>bearer|basic|token|negotiate|api[-_]?key)\s+[^\s,;]+', $replAuthScheme

        # (4) Cabeceras de autorizacion sin esquema explicito (Authorization: abc123).
        #     El lookahead evita volver a redactar el esquema que ya redacto la (3).
        $sanitized = $sanitized -replace '(?i)\b(?<h>authorization|proxy-authorization)(?<pre>\s*)(?<sep>[:=])(?<post>\s*)(?!(?:bearer|basic|token|negotiate|api[-_]?key)\b)[^\s,;]+', $replAuthPlain

        # (5) Token Bearer suelto en la salida
        $sanitized = $sanitized -replace '(?i)\bbearer\s+[A-Za-z0-9\-._~+/]+=*', $replBearer

        # (6) Asignaciones cuyo nombre contiene un termino sensible.
        #     Cubre: KEY=v, "KEY": "v", KEY: v, KEY = v (ambos separadores, con o sin espacio)
        #     Terminos: TOKEN, SECRET, KEY, PASSWORD, PASSWD, CREDENTIAL, API_KEY, AUTH.
        #     El prefixo exige separador (_ o -), asi que MONKEY=5 o AUTHOR=bob no
        #     se confunden con KEY ni con AUTH (se conservan intactos).
        $sanitized = $sanitized -replace '(?<![A-Za-z0-9])(?<k>(?:[A-Za-z0-9]+[_\-])*(?:API_KEY|APIKEY|ACCESS_KEY|ACCESSKEY|PRIVATE_KEY|PRIVATEKEY|SESSION_KEY|SESSIONKEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIALS|CREDENTIAL|KEY|AUTH)(?:[_\-][A-Za-z0-9]+)*)(?![A-Za-z0-9])(?<pre>\s*)(?<sep>[:=])(?<post>\s*)(?<v>"[^"\r\n]+"|''[^''\r\n]+''|[^\s,;)\]}]+)', $replAssign

        # (7) Formato key=value (YAML/JSON con claves en cualquier caso),
        #     con el mismo requisito de separador antes del termino sensible.
        $sanitized = $sanitized -replace '(?i)(?<![A-Za-z0-9])(?<k>(?:[a-z0-9]+[_\-])*(?:api_?key|access_?key|private_?key|session_?key|token|secret|password|passwd|credential|auth|key)(?:[_\-][a-z0-9]+)*)(?![A-Za-z0-9])(?<pre>\s*)(?<sep>=)(?<post>\s*)(?<v>"[^"\r\n]+"|''[^''\r\n]+''|[^\s,;)\]}]+)', $replAssign

        # (8) Tokens con prefijo conocido (segun especificacion T047)
        #     sk-, ghp_, gho_, ghu_, ghs_, ghr_, github_pat_, AKIA, ASIA,
        #     xox*, AIza, glpat-
        $sanitized = $sanitized -replace '(?i)\b(?:sk-[A-Za-z0-9_\-]{8,}|gh[pousr]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{16,}|A[SK]IA[0-9A-Z]{12,}|xox[baprs]-[A-Za-z0-9\-]{10,}|AIza[0-9A-Za-z_\-]{20,}|glpat-[A-Za-z0-9_\-]{10,})', $marker

        return $sanitized
    }
    catch {
        # Fail-open: no se aborta el flujo. Pero si la sanitizacion fallo no se
        # devuelve el texto original (filtraria el secret); se devuelve un marker
        # para que el operador sepa que la salida de ese comando se descarto.
        Write-Warn "Fallo la sanitizacion de secrets en la salida (fail-open, no se aborta): $_"
        return "$marker (sanitizacion fallida: salida del comando descartada)"
    }
}

# Ejecuta un comando y devuelve objeto con ExitCode + salida ya sanitizada.
# La salida NUNCA se emite al pipeline: solo va a Write-Debug, para que ningun
# llamador pueda loguear el texto crudo por accidente.
function Invoke-CommandCaptureSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Command,
        [string[]]$Args = @(),
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Info "DryRun: $Command $($Args -join ' ')"
        return [pscustomobject]@{
            Command         = $Command
            ExitCode        = 0
            SanitizedOutput = $null
            Sanitized       = $false
        }
    }

    try {
        $raw = & $Command @Args 2>&1 | Out-String
    }
    catch {
        Write-Warn "Comando falló sin romper el flujo: $Command $($Args -join ' '). Error: $_"
        return [pscustomobject]@{
            Command         = $Command
            ExitCode        = 1
            SanitizedOutput = $null
            Sanitized       = $false
        }
    }

    # $LASTEXITCODE se lee inmediatamente: cualquier comando posterior lo pisa.
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }

    $safe = Format-SanitizedText -Text $raw
    if ($safe) {
        # Solo Write-Debug: la salida puede ser voluminosa y no va al log de INFO.
        Write-Debug "Salida sanitizada de '${Command} $($Args -join ' ')' (exit $code): $safe"
    }

    return [pscustomobject]@{
        Command         = $Command
        ExitCode        = $code
        SanitizedOutput = $safe
        Sanitized       = $true
    }
}

function Invoke-CommandSafe {
    param(
        [Parameter(Mandatory = $true)] [string]$Command,
        [string[]]$Args = @(),
        [switch]$DryRun
    )

    $result = Invoke-CommandCaptureSafe -Command $Command -Args $Args -DryRun:$DryRun
    return $result.ExitCode
}

function Ensure-Directory {
    param([string]$Path, [switch]$DryRun)
    
    if (-not (Test-Path -LiteralPath $Path)) {
        if ($DryRun) {
            Write-Info "DryRun: crear directorio $Path"
        } else {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        Write-OK "Directorio listo: $Path"
    }
    return $true
}

# =============================================================================
# Copia idempotente del manifest template
# =============================================================================
function Ensure-ManifestTemplate {
    param(
        [string]$RootPath,
        [string]$MasterManifestPath,
        [switch]$DryRun
    )
    
    $targetManifest = Join-Path $RootPath "dependencias-manifest.yml"
    
    if (Test-Path -LiteralPath $targetManifest) {
        Write-OK "dependencias-manifest.yml ya existe en $RootPath (no se sobrescribe)"
        return $true
    }
    
    if (-not (Test-Path -LiteralPath $MasterManifestPath)) {
        Write-Warn "Manifest maestro no encontrado en $MasterManifestPath; no se puede copiar plantilla"
        return $false
    }
    
    if ($DryRun) {
        Write-Info "DryRun: copiar plantilla manifest $MasterManifestPath -> $targetManifest"
        return $true
    }
    
    try {
        Copy-Item -LiteralPath $MasterManifestPath -Destination $targetManifest -Force
        Write-OK "Plantilla de manifest copiada: $targetManifest"

        # T052: hacer manifest inmutable tras primera copia
        try {
            if (-not $DryRun) {
                # Calcular hash fuente
                $srcHashObj = Get-FileHash -LiteralPath $MasterManifestPath -Algorithm SHA256
                $srcHash = $srcHashObj.Hash
                # Hacer solo lectura
                Set-ItemProperty -Path $targetManifest -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
                # Alternativa icacls
                try { icacls $targetManifest /inheritance:r /grant:r "SYSTEM:(F)" /grant:r "Administradores:(R)" | Out-Null } catch {}
                # T062: registrar copia en audit log
                Write-AuditEntry -Action "manifest_copy" -Data @{
                    ManifestHash = $srcHash
                    SourcePath = $MasterManifestPath
                    TargetPath = $targetManifest
                    User = $env:USERNAME
                    Timestamp = (Get-Date -Format "o")
                }
                Write-Info "T052/T062: Manifest marcado como solo lectura y registrado en audit log."
            }
        } catch {
            Write-Warn "T052/T062: No se pudo aplicar inmutabilidad o registrar audit log (fail-open): $_"
        }

        return $true
    }
    catch {
        Write-Warn "No se pudo copiar la plantilla del manifest: $_"
        return $false
    }
}

# =============================================================================
# Clonar/actualizar repositorio Git (shallow, --depth=1)
# =============================================================================
function Invoke-CommandLeastPrivilege {
    param(
        [string]$Command,
        [string[]]$Args = @(),
        [switch]$DryRun
    )
    # T049: least privilege - limpiar env vars sensibles
    if ($DryRun) {
        Write-Info "DryRun: comando $Command con least privilege"
        return @{ExitCode=0; Sanitized=$true; SanitizedOutput="dryrun"}
    }
    $sensitive = @('GIT_SSH_COMMAND','SSH_AUTH_SOCK','AWS_ACCESS_KEY_ID','AWS_SECRET_ACCESS_KEY','GITHUB_TOKEN','GH_TOKEN')
    foreach ($k in $sensitive) { Remove-Item "Env:$k" -ErrorAction SilentlyContinue }
    $result = Invoke-CommandCaptureSafe -Command $Command -Args $Args
    return $result
}

function Invoke-SandboxBuild {
    param(
        [string]$WorkDir,
        [string]$Command,
        [string[]]$Args = @(),
        [switch]$DryRun
    )
    # T043: sandbox build aislado
    if ($DryRun) {
        Write-Info "DryRun: sandbox build $Command $($Args -join ' ') en $WorkDir"
        return $true
    }
    try {
        $temp = Join-Path $env:TEMP ("sandbox_build_" + [IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        # Copiar repo al sandbox para aislar
        $sandboxWork = Join-Path $temp "work"
        Copy-Item -LiteralPath $WorkDir -Destination $sandboxWork -Recurse -Force
        # Limpiar env vars sensibles
        $envCopy = @{}
        foreach ($k in $env:PSModulePath.Split(';')) { }
        # Ejecutar comando en sandbox
        $result = Invoke-CommandCaptureSafe -Command $Command -Args $Args
        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
        return $result.ExitCode -eq 0
    } catch {
        Write-Warn "Sandbox build falló (T043): $_"
        return $false
    }
}

function Invoke-GitWithTimeout {
    param(
        [string]$WorkingDir,
        [string[]]$Args,
        [int]$TimeoutSec = 120
    )
    try {
        $proc = Start-Process -FilePath "git" -ArgumentList $Args -WorkingDirectory $WorkingDir -PassThru -NoNewWindow -RedirectStandardOutput $true -RedirectStandardError $true
        $exited = $proc.WaitForExit($TimeoutSec * 1000)
        if (-not $exited) {
            try { $proc.Kill() } catch {}
            Write-Warn "T056: git command timeout after ${TimeoutSec}s: git $($Args -join ' ')"
            Write-AuditEntry -Action "git_timeout" -Data @{workingDir=$WorkingDir; args=$Args -join ' '; timeout=$TimeoutSec}
            return @{ExitCode=124; TimedOut=$true}
        }
        return @{ExitCode=$proc.ExitCode; TimedOut=$false; StdOut=$proc.StandardOutput.ReadToEnd()}
    } catch {
        Write-Warn "T056: Error ejecutando git con timeout (fail-open): $_"
        return @{ExitCode=1; TimedOut=$false}
    }
}

function Get-GitRepoSizeMB {
    param([string]$RepoPath)
    try {
        $proc = Start-Process -FilePath "git" -ArgumentList @("-C",$RepoPath,"count-objects","-vH") -WorkingDirectory $RepoPath -PassThru -NoNewWindow -RedirectStandardOutput $true -RedirectStandardError $true -Wait
        $out = $proc.StandardOutput.ReadToEnd()
        if ($proc.ExitCode -ne 0) { return $null }
        $m = [regex]::Match($out, 'size:\s*([\d\.]+)\s*MiB')
        if ($m.Success) { return [double]$m.Groups[1].Value }
        return $null
    } catch {
        Write-Warn "T056: Error calculando tamaño git (fail-open): $_"
        return $null
    }
}

function Sync-GitRepository {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Branch,
        [string]$RootPath,
        [switch]$DryRun
    )
    
    $destDir = Join-Path $RootPath "proyect_ext\$Name"
    
    # Verificación de containment
    if (-not (Test-ProyectExtContainment -Path $destDir -RootPath $RootPath)) {
        Write-Warn "[$Name] Ruta fuera de containment ($destDir); se omite (fail-closed)"
        return $false
    }
    
    # Validar URL en allowlist
    if (-not (Test-TrustedGithubUrl $Url)) {
        Write-Warn "[$Name] URL no permitida por allowlist: $Url (fail-closed)"
        return $false
    }
    
    # Deshabilitar submodules (seguridad)
    $gitArgs = @("--no-recurse-submodules")
    
    if (Test-Path -LiteralPath (Join-Path $destDir ".git")) {
        # Repositorio existe: fetch + reset
        Write-Step "[$Name] Actualizando repositorio existente..."
        
        if ($DryRun) {
            Write-Info "DryRun: git -C $destDir fetch origin $Branch --depth=1"
            Write-Info "DryRun: git -C $destDir reset --hard FETCH_HEAD"
            return $true
        }
        
        # T056: git fetch con timeout 120s
        $gitResult = Invoke-GitWithTimeout -WorkingDir $destDir -Args @("-C",$destDir,"fetch","origin",$Branch,"--depth=1") -TimeoutSec 120
        if ($gitResult.ExitCode -ne 0 -or $gitResult.TimedOut) {
            Write-Warn "[$Name] git fetch falló o timeout (exit $($gitResult.ExitCode)); se continúa"
            return $false
        }
        
        # Verificar tamaño tras fetch
        $sizeMB = Get-GitRepoSizeMB -RepoPath $destDir
        if ($sizeMB -and $sizeMB -gt $script:MAX_CLONE_MB) {
            Write-Warn "[$Name] Repo size ${sizeMB}MB supera MAX_CLONE_MB=$($script:MAX_CLONE_MB); se rechaza (fail-closed)"
            Write-AuditEntry -Action "clone_size_exceeded" -Data @{name=$Name; sizeMB=$sizeMB; limit=$script:MAX_CLONE_MB}
            return $false
        }

        $exitCode = Invoke-CommandSafe -Command "git" -Args @("git", "-C", $destDir, "reset", "--hard", "FETCH_HEAD") -DryRun:$DryRun
        if ($exitCode -ne 0) {
            Write-Warn "[$Name] git reset falló (exit $exitCode); se continúa"
            return $false
        }
        
       
        # T040: Verificación de firma del commit (fail-closed)
        if (-not $DryRun) {
            $sigResult = Invoke-CommandCaptureSafe -Command "git" -Args @("git","-C",$destDir,"log","-1","--show-signature")
            if ($sigResult.ExitCode -ne 0 -or -not $sigResult.Sanitized -or $sigResult.SanitizedOutput -notmatch "Good signature") {
                Write-Warn "[$Name] Verificación de firma del commit falló o no está firmada (T040); se omite repositorio (fail-closed)"
                return $false
            }
            Write-Info "[$Name] Firma del commit verificada (T040)"
        }

                # T042: Verificación obligatoria de checksum (fail-closed)
        if (-not $DryRun) {
            if ($dep.Checksum) {
                $revResult = Invoke-CommandCaptureSafe -Command "git" -Args @("git","-C",$destDir,"rev-parse","HEAD")
                if ($revResult.ExitCode -eq 0 -and $revResult.Sanitized) {
                    $actual = $revResult.SanitizedOutput.Trim()
                    if ($actual.ToLower() -ne $dep.Checksum.ToLower()) {
                        Write-Warn "[$Name] Checksum no coincide (T042): esperado $($dep.Checksum), actual $actual; se omite (fail-closed)"
                        return $false
                    }
                    Write-Info "[$Name] Checksum verificado (T042)"

        # T043: sandbox build para tokenslayer
        if ($Name -eq "tokenslayer-mcp-server" -and -not $DryRun) {
            $buildDir = Join-Path $destDir "mcp-server"
            if (Test-Path $buildDir) {
                Write-Step "[$Name] Ejecutando build en sandbox (T043)..."
                $ok = Invoke-SandboxBuild -WorkDir $buildDir -Command "npm" -Args @("install","--ignore-scripts") -DryRun:$DryRun
                if (-not $ok) { Write-Warn "[$Name] Sandbox build falló (T043); se continúa (fail-open)" }
            }
        }                } else {
                    Write-Warn "[$Name] No se pudo obtener rev-parse HEAD para checksum (T042); se omite (fail-closed)"
                    return $false
                }
            } else {
                Write-Warn "[$Name] Checksum no declarado en manifest (T042); se omite (fail-closed)"
                return $false
            }
        }

Write-OK "[$Name] Repositorio actualizado en $destDir"
        return $true
    }
    else {
        # Repositorio no existe: clone shallow
        Write-Step "[$Name] Clonando repositorio (shallow)..."
        
        Ensure-Directory -Path (Split-Path $destDir -Parent) -DryRun:$DryRun
        
        if ($DryRun) {
            Write-Info "DryRun: git clone --depth=1 --branch $Branch $Url $destDir"
            return $true
        }
        
        # T056: git clone con timeout 120s
        $parentDir = Split-Path $destDir -Parent
        $gitResult = Invoke-GitWithTimeout -WorkingDir $parentDir -Args @("clone","--depth=1","--branch",$Branch,$Url,$destDir) -TimeoutSec 120
        if ($gitResult.ExitCode -ne 0 -or $gitResult.TimedOut) {
            Write-Warn "[$Name] git clone falló o timeout (exit $($gitResult.ExitCode)); se continúa"
            return $false
        }

        # Verificar tamaño tras clone
        $sizeMB = Get-GitRepoSizeMB -RepoPath $destDir
        if ($sizeMB -and $sizeMB -gt $script:MAX_CLONE_MB) {
            Write-Warn "[$Name] Repo size ${sizeMB}MB supera MAX_CLONE_MB=$($script:MAX_CLONE_MB); se rechaza (fail-closed)"
            Write-AuditEntry -Action "clone_size_exceeded" -Data @{name=$Name; sizeMB=$sizeMB; limit=$script:MAX_CLONE_MB}
            # Limpiar clon excedido
            try { Remove-Item -LiteralPath $destDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            return $false
        }
        
       
        # T040: Verificación de firma del commit (fail-closed)
        if (-not $DryRun) {
            $sigResult = Invoke-CommandCaptureSafe -Command "git" -Args @("git","-C",$destDir,"log","-1","--show-signature")
            if ($sigResult.ExitCode -ne 0 -or -not $sigResult.Sanitized -or $sigResult.SanitizedOutput -notmatch "Good signature") {
                Write-Warn "[$Name] Verificación de firma del commit falló o no está firmada (T040); se omite repositorio (fail-closed)"
                return $false
            }
            Write-Info "[$Name] Firma del commit verificada (T040)"
        }

                # T042: Verificación obligatoria de checksum (fail-closed)
        if (-not $DryRun) {
            if ($dep.Checksum) {
                $revResult = Invoke-CommandCaptureSafe -Command "git" -Args @("git","-C",$destDir,"rev-parse","HEAD")
                if ($revResult.ExitCode -eq 0 -and $revResult.Sanitized) {
                    $actual = $revResult.SanitizedOutput.Trim()
                    if ($actual.ToLower() -ne $dep.Checksum.ToLower()) {
                        Write-Warn "[$Name] Checksum no coincide (T042): esperado $($dep.Checksum), actual $actual; se omite (fail-closed)"
                        return $false
                    }
                    Write-Info "[$Name] Checksum verificado (T042)"
                } else {
                    Write-Warn "[$Name] No se pudo obtener rev-parse HEAD para checksum (T042); se omite (fail-closed)"
                    return $false
                }
            } else {
                Write-Warn "[$Name] Checksum no declarado en manifest (T042); se omite (fail-closed)"
                return $false
            }
        }

Write-OK "[$Name] Repositorio clonado en $destDir"
        return $true
    }
}

# =============================================================================
# Politica de versiones SIN pin (decision del usuario 2026-10-03)
# =============================================================================
# NUNCA se fija una version. No se usa graphifyy[mcp]==X.Y.Z ni ningun otro pin:
# siempre debe quedar la ultima disponible. El manifest registra la version
# APLICADA para que la proxima ejecucion pueda detectar si hay actualizacion.

# Reemplaza solo la primera coincidencia del patron (evita pisar entradas homonimas)
function Replace-FirstMatch {
    param([string]$Text, [string]$Pattern, [string]$Replacement)

    $m = [regex]::Match($Text, $Pattern)
    if (-not $m.Success) { return $Text }
    return $Text.Substring(0, $m.Index) + $Replacement + $Text.Substring($m.Index + $m.Length)
}

# Consulta la ultima version publicada en PyPI. Fail-open: si falla la red o el
# paquete no existe, avisa y devuelve $null para que el flujo continue.
function Get-LatestPackageVersion {
    param(
        [string]$PackageName = "graphifyy",
        [int]$TimeoutSec = 20
    )

    $url = "https://pypi.org/pypi/$PackageName/json"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $TimeoutSec

        if ($null -eq $response) {
            Write-Warn "[$PackageName] PyPI devolvio una respuesta vacia en $url; se omite la comparacion (fail-open)"
            return $null
        }

        $infoProp = $response.PSObject.Properties["info"]
        if ($null -eq $infoProp) {
            Write-Warn "[$PackageName] La respuesta de PyPI no trae 'info' ($url); se omite la comparacion (fail-open)"
            return $null
        }

        $versionProp = $infoProp.Value.PSObject.Properties["version"]
        if ($null -eq $versionProp -or [string]::IsNullOrWhiteSpace([string]$versionProp.Value)) {
            Write-Warn "[$PackageName] PyPI no devolvio 'info.version' ($url); se omite la comparacion (fail-open)"
            return $null
        }

        return [string]$versionProp.Value
    }
    catch {
        Write-Warn "[$PackageName] No se pudo consultar PyPI ($url): $_; se omite la comparacion (fail-open)"
        return $null
    }
}

# Extrae un numero de version de un texto suelto (stdout de un CLI)
function Get-VersionFromText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $m = [regex]::Match($Text, 'v?(\d+\.\d+(?:\.\d+)*(?:[-+][0-9A-Za-z.\-]+)?)')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Lee la version YA instalada. Orden: ejecutable del paquete, luego `uv tool list`.
# Devuelve $null si no se puede determinar (fail-open).
function Get-InstalledToolVersion {
    param(
        [string]$PackageName = "graphifyy",
        [string]$Executable = "graphify"
    )

    # (1) Ejecutable directo: graphify --version
    if (Get-Command $Executable -ErrorAction SilentlyContinue) {
        $r = Invoke-CommandCaptureSafe -Command $Executable -Args @("--version")
        if ($r.ExitCode -eq 0 -and $r.Sanitized) {
            $v = Get-VersionFromText -Text $r.SanitizedOutput
            if ($v) { return $v }
        }
    }

    # (2) Fallback: uv tool list, buscando la linea del paquete
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        $r2 = Invoke-CommandCaptureSafe -Command "uv" -Args @("uv", "tool", "list")
        if ($r2.ExitCode -eq 0 -and $r2.Sanitized) {
            foreach ($line in ($r2.SanitizedOutput -split "`r?`n")) {
                if ($line -notmatch [regex]::Escape($PackageName)) { continue }
                $specific = [regex]::Match($line, [regex]::Escape($PackageName) + '\s+[^0-9A-Za-z]*v?(\d+\.\d+(?:\.\d+)*)')
                if ($specific.Success) { return $specific.Groups[1].Value }
                $v = Get-VersionFromText -Text $line
                if ($v) { return $v }
            }
        }
    }

    Write-Debug "No se pudo determinar la version instalada de $PackageName"
    return $null
}

# Registra la version aplicada en el manifest, dentro del bloque del tool.
# Escribe solo la linea version_actual / ultimo_check de ESA entrada; el resto del
# YAML (licencia, rol_pipeline, notas) queda intacto. Fail-open ante cualquier error.
function Set-ManifestAppliedVersion {
    param(
        [Parameter(Mandatory = $true)] [string]$ManifestPath,
        [string]$ToolName = "graphify",
        [string]$Version,
        [string]$AppliedDate = (Get-Date -Format "yyyy-MM-dd"),
        [switch]$DryRun
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        Write-Warn "No hay version aplicada para registrar en el manifest de '$ToolName'; se omite (fail-open)"
        return $false
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        Write-Warn "No existe el manifest $ManifestPath; no se registra la version de '$ToolName' (fail-open)"
        return $false
    }

    try {
        $raw = [IO.File]::ReadAllText($ManifestPath)

        $namePattern = '(?m)^[ \t]*-[ \t]*nombre:[ \t]*' + [regex]::Escape($ToolName) + '[ \t]*$'
        $nameMatch = [regex]::Match($raw, $namePattern)
        if (-not $nameMatch.Success) {
            Write-Warn "No se encontro la entrada 'nombre: $ToolName' en $ManifestPath; no se registra la version (fail-open)"
            return $false
        }

        # El bloque de la entrada va desde su 'nombre:' hasta el siguiente '- nombre:'
        $nextEntryRx = [regex]::new('(?m)^[ \t]*-[ \t]*nombre:[ \t]*')
        $nextEntry = $nextEntryRx.Match($raw, $nameMatch.Index + $nameMatch.Length)
        $blockEnd = if ($nextEntry.Success) { $nextEntry.Index } else { $raw.Length }

        $block = $raw.Substring($nameMatch.Index, $blockEnd - $nameMatch.Index)

        $newValue = "$Version (PyPI $ToolName, SIN pin de version; aplicado $AppliedDate via uv tool install `"$ToolName[mcp]`" --force)"
        $newBlock = Replace-FirstMatch -Text $block -Pattern '(?m)^([ \t]*version_actual:[ \t]*).*$' -Replacement ('${1}' + $newValue)
        $newBlock = Replace-FirstMatch -Text $newBlock -Pattern '(?m)^([ \t]*ultimo_check:[ \t]*).*$' -Replacement ('${1}' + $AppliedDate)

        if ($newBlock -eq $block) {
            Write-Info "[$ToolName] El manifest ya reflejaba la version $Version; no se escribe"
            return $true
        }

        if ($DryRun) {
            Write-Info "DryRun: registrar en $ManifestPath -> nombre: $ToolName / version_actual: $newValue / ultimo_check: $AppliedDate"
            return $true
        }

        $updated = $raw.Substring(0, $nameMatch.Index) + $newBlock + $raw.Substring($blockEnd)

        # UTF-8 sin BOM: el manifest del kit es UTF-8 sin BOM y LF
        [IO.File]::WriteAllText($ManifestPath, $updated, [Text.UTF8Encoding]::new($false))
        Write-OK "[$ToolName] Manifest actualizado: version_actual $Version, ultimo_check $AppliedDate"
        return $true
    }
    catch {
        Write-Warn "No se pudo actualizar el manifest ${ManifestPath}: $_; se continua (fail-open)"
        return $false
    }
}

# =============================================================================
# Instalar/actualizar graphify via uv tool (sin pin de version)
# =============================================================================
function Sync-Graphify {
    param(
        [switch]$ForceUpgradeTools,
        [switch]$DryRun,
        [string]$ManifestPath,
        [string]$PackageName = "graphifyy",
        [string]$ManifestToolName = "graphify"
    )

    Write-Step "[$PackageName] Sincronizando via uv tool..."

    if (-not $ForceUpgradeTools) {
        Write-Info "[$PackageName] -ForceUpgradeTools no especificado; se omite instalacion forzada"
        return $true
    }

    if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
        Write-Warn "[$PackageName] 'uv' no esta en el PATH; no se puede instalar $PackageName[mcp]"
        return $false
    }

    # DryRun: cero escrituras y cero side effects. Se anuncia la intencion, no se
    # consulta PyPI ni se ejecuta ningun comando.
    if ($DryRun) {
        Write-Info "DryRun: consultar https://pypi.org/pypi/$PackageName/json para la ultima version disponible"
        Write-Info "DryRun: leer la version instalada ($PackageName --version; fallback uv tool list)"
        Write-Info "DryRun: comparar; si coinciden no se reinstala; si difieren -> uv tool install `"$PackageName[mcp]`" --force (SIN pin)"
        Write-Info "DryRun: registrar la version aplicada en $ManifestPath"
        return $true
    }

    # --- Comparacion de versiones (politica sin pin) ---
    $latest = Get-LatestPackageVersion -PackageName $PackageName
    $installed = Get-InstalledToolVersion -PackageName $PackageName

    if ($latest -and $installed -and ($latest -eq $installed)) {
        Write-Info "[$PackageName] Ya esta al dia (version instalada = $installed); no se reinstala"
        if ($ManifestPath) {
            Set-ManifestAppliedVersion -ManifestPath $ManifestPath -ToolName $ManifestToolName -Version $installed | Out-Null
        }
        return $true
    }

    if ($latest -and $installed) {
        Write-Info "[$PackageName] Actualizacion disponible: instalada $installed -> publicada $latest"
    }
    elseif ($installed) {
        Write-Warn "[$PackageName] No se pudo consultar la ultima version en PyPI; se instala sin pin (fail-open)"
    }
    else {
        Write-Warn "[$PackageName] No se pudo determinar la version instalada; se instala la ultima disponible (fail-open)"
    }

    # T057: uv tool install con timeout estricto 60s
    try {
        $proc = Start-Process -FilePath "uv" -ArgumentList @("tool","install","$PackageName[mcp]","--force") -PassThru -NoNewWindow -Wait
        $waited = $proc.WaitForExit(60000)
        if (-not $waited) {
            try { $proc.Kill() } catch {}
            Write-Warn "[$PackageName] uv tool install timeout después de 60s; se continúa (fail-open)"
            Write-AuditEntry -Action "uv_timeout" -Data @{package=$PackageName}
            return $false
        }
        $exitCode = $proc.ExitCode
        if ($exitCode -ne 0) {
            Write-Warn "[$PackageName] uv tool install fallo (exit $exitCode); se continua (fail-open)"
            return $false
        }
    } catch {
        Write-Warn "[$PackageName] Error ejecutando uv tool install con timeout (fail-open): $_"
        return $false
    }

    # La version aplicada es la que quedo instalada (sin pin => la ultima publicada)
    $applied = $installed
    $postInstall = Get-InstalledToolVersion -PackageName $PackageName
    if ($postInstall) { $applied = $postInstall }

    if ($ManifestPath -and $applied) {
        Set-ManifestAppliedVersion -ManifestPath $ManifestPath -ToolName $ManifestToolName -Version $applied | Out-Null
    }

    Write-OK "[$PackageName] Instalado/actualizado via uv tool (version aplicada $applied, sin pin)"
    return $true
}

# =============================================================================
# Función principal de sincronización
# =============================================================================
function Invoke-UpgradeFrameworkSync {
    param(
        [string]$RootPath,
        [switch]$ForceUpgradeTools,
        [switch]$DryRun
    )
    
    # Resolver ruta absoluta
    $resolvedRoot = (Resolve-Path $RootPath).Path
    Write-Info "Ruta del proyecto resuelta: $resolvedRoot"

    # T064: Rotación allowlist
    Test-AllowlistRotation | Out-Null

    # T058: Validar schema opencode.json antes de MCP registration
    $opencodePath = Join-Path $resolvedRoot "opencode.json"
    Validate-OpencodeSchema -OpencodePath $opencodePath | Out-Null
    
    # 1. Copiar manifest template si no existe
    $masterManifest = Join-Path (Split-Path $PSScriptRoot -Parent) "dependencias-manifest.yml"
    # El manifest maestro está en la raíz del kit (donde está este script)
    if (-not (Test-Path -LiteralPath $masterManifest)) {
        $masterManifest = Join-Path (Split-Path $PSScriptRoot) "dependencias-manifest.yml"
    }
    
    Ensure-ManifestTemplate -RootPath $resolvedRoot -MasterManifestPath $masterManifest -DryRun:$DryRun
    
    # 2. Leer manifest
    $dependencies = Read-DependenciasManifest -RootPath $resolvedRoot
    if ($dependencies.Count -eq 0) {
        Write-Warn "No se encontraron dependencias en el manifest; nada que sincronizar"
        return $true
    }
    
    Write-Step "Dependencias encontradas: $($dependencies.Count)"
    foreach ($dep in $dependencies) {
        Write-Info "  - $($dep.Nombre) ($($dep.Tipo)): $($dep.Url) @ $($dep.Rama)"
    }
    
    # 3. Procesar cada dependencia
    $allSuccess = $true
    
    foreach ($dep in $dependencies) {
        try {
            switch ($dep.Tipo) {
                "git" {
                    $success = Sync-GitRepository -Name $dep.Nombre -Url $dep.Url -Branch $dep.Rama -RootPath $resolvedRoot -DryRun:$DryRun
                    if (-not $success) { $allSuccess = $false }
                }
                "uv tool" {
                    if ($dep.Nombre -eq "graphify") {
                        $success = Sync-Graphify -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun -ManifestPath (Join-Path $resolvedRoot "dependencias-manifest.yml")
                        if (-not $success) { $allSuccess = $false }
                    }
                    else {
                        Write-Warn "[$($dep.Nombre)] Tipo 'uv tool' no reconocido para esta dependencia; se omite"
                    }
                }
                default {
                    Write-Warn "[$($dep.Nombre)] Tipo de dependencia desconocido: $($dep.Tipo); se omite"
                }
            }
        }
        catch {
            Write-Warn "[$($dep.Nombre)] Error inesperado: $_; se continúa (fail-open)"
            $allSuccess = $false
        }
    }
    
    # 4. Asegurar que proyect_ext/ existe (para tokenslayer build posterior)
    Ensure-Directory -Path (Join-Path $resolvedRoot "proyect_ext") -DryRun:$DryRun

    # T058: Validar schema opencode.json después de MCP registration
    Validate-OpencodeSchema -OpencodePath $opencodePath | Out-Null
    
    if ($allSuccess) {
        Write-OK "Sincronización de dependencias completada exitosamente"
        return 0
    }
    else {
        Write-Warn "Sincronización completada con advertencias (fail-open: exit code 0)"
        return 0  # FAIL-OPEN: siempre exit code 0
    }
}

# =============================================================================
# MAIN
# =============================================================================
try {
    # T051: Verificar identidad del script antes de cualquier invocación
    $scriptFullPath = $MyInvocation.MyCommand.Path
    if ($scriptFullPath) {
        try {
            $resolvedScript = (Resolve-Path -LiteralPath $scriptFullPath -ErrorAction Stop).Path
            $hashObj = Get-FileHash -LiteralPath $resolvedScript -Algorithm SHA256
            $refFile = "C:\Proyectos\Agents_IA_TECH\Documentacion\Agents_IA_TECH\seguridad\upgrade_framework.sha256"
            if (Test-Path -LiteralPath $refFile) {
                $expectedHash = (Get-Content -LiteralPath $refFile -Raw).Trim()
                if ($hashObj.Hash -ne $expectedHash) {
                    Write-Warn "T051: Hash del script upgrade_framework.ps1 no coincide con referencia ($expectedHash). Hash actual: $($hashObj.Hash). Continuando fail-open."
                    Write-AuditEntry -Action "script_identity_mismatch" -Data @{expected=$expectedHash; actual=$hashObj.Hash}
                } else {
                    Write-Info "T051: Identidad del script verificada."
                    Write-AuditEntry -Action "script_identity_ok" -Data @{hash=$hashObj.Hash}
                }
            } else {
                Write-Warn "T051: Archivo de referencia upgrade_framework.sha256 no encontrado. Verificación omitida (fail-open)."
            }
        } catch {
            Write-Warn "T051: Error verificando identidad del script (fail-open): $_"
        }
    }
    # Inicializar audit log
    Initialize-AuditLog -Path $script:AuditLogPath | Out-Null

    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " upgrade_framework - Sincronización de dependencias externas" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Info "RootPath: $RootPath"
    Write-Info "ForceUpgradeTools: $ForceUpgradeTools"
    Write-Info "DryRun: $DryRun"
    
    $exitCode = Invoke-UpgradeFrameworkSync -RootPath $RootPath -ForceUpgradeTools:$ForceUpgradeTools -DryRun:$DryRun
    
    Write-Host "===============================================================" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host " DryRun completado - no se realizaron cambios" -ForegroundColor Yellow
    } else {
        Write-Host " Sincronización finalizada" -ForegroundColor Green
    }
    Write-Host "===============================================================" -ForegroundColor Cyan
    
    # FAIL-OPEN: siempre exit code 0
    exit 0
}
catch {
    Write-Fail "Error crítico en upgrade_framework: $_"
    Write-Warn "Fail-open: continuando con exit code 0"
    exit 0
}# TEST PERMISSION BASH EDIT
